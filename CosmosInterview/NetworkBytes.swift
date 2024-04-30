//
//  NetworkBytes.swift
//  PacketTunnel
//
//  Created by Horgan, Luke on 11/15/23.
//

import Foundation

func to8BitStr(_ num:UInt8) -> String {
    let binStr = String(num, radix: 2)
    let padding = String(repeating: "0", count: 8-binStr.count)
    return padding + binStr
}


class NetworkBytes {
    private var bytes: DataWrapper
    private let offset: Int
    
    init(_ data: DataWrapper, offset: Int = 0) {
        self.bytes = data
        self.offset = offset
    }
    
    init(bytes _bytes: NetworkBytes, offset _offset: Int = 0) {
        bytes = _bytes.asData()
        offset = _bytes.getOffset() + _offset
    }
    
    func getOffset() -> Int {
        return offset
    }
    
    subscript(index: Data.Index) -> UInt8 {
        get {
            return bytes[index + offset]
        }
        set {
            bytes[index + offset] = newValue
        }
    }
    
    var count: Int {
        return bytes.count - offset
    }
    
    func asData() -> DataWrapper {
        return bytes
    }
    
    // todo, this is a mess, only used by tcpoptions to get data
    func subrange(startByte: Int, endByte: Int) -> Data {
        var uint8s:[UInt8] = []
        
        for i in startByte...endByte {
            uint8s.append(self[i])
        }
        
        return Data(uint8s)
    }
    
    /**
        Returns -1 if more than 64 bits are requested
     */
    func getIntValue(startBitIdx:Int, endBitIdx:Int) -> Int {
        if(endBitIdx - startBitIdx + 1 > 64) {
            return -1
        }
        
        // startBitIdx: The index of the first bit that we want to read
        // endBitIdx: The index of the last bit that we want to read
        
        let startByteIdx = startBitIdx / 8 // startByteIdx is 1/8 startBitIdx, rounded down
        let endByteIdx = endBitIdx / 8 // Ditto
        
        var value = 0 // Here, we accumulate the integer value of the bits we are reading
        
        var currentEndBitIdx = 7 // the index of the last bit of the byte we are currently examining
        // This is relative to the byte itself, so it only goes from 0 to 7.
        // To start with, this represents the last bit of the first byte (ie the byte at startByteIdx)
        // that we are reading from.
        // If we are extracting bits spanning multiple bytes, then this value must be 7.  Why?  Say
        // the first bit we are reading is at index 4 in the 5th byte of the underlying Data object,
        // and we are reading up to bit 3 in the 8 byte of the underlying Data object.  Then, we know
        // that we need to read bits 4, 5, 6, and 7 in byte 5.  We worry about the other parts later.

        let currentStartBitIdx = startBitIdx % 8 // get the index of the bit relative to the current byte
        
        if endByteIdx == startByteIdx {
            // If endByteIdx == startByteIdx, then we are only reading from one byte.
            // In that case, the currentEndBitIdx isn't necessarily 7, since we might
            // not actually read to the end of said byte.
            currentEndBitIdx = endBitIdx % 8
        }
        
        var leftShift = (endBitIdx - startBitIdx) - (currentEndBitIdx - currentStartBitIdx)
        var bits = Int((self[startByteIdx] << currentStartBitIdx) >> (7 - currentEndBitIdx + currentStartBitIdx)) << leftShift
        // 1) self[startByteIdx] << currentStartBitIdx -- 0 out the leading bits that we don't care about
        // For instance, if our first byte 11010011, and startBitIdx is 3, then we want to read 10011, and trim off
        // 110.  Left shifting by 3 accomplishes this.
        // 2) >> (7 - currentEndBitIdx + currentStartBitIdx) -- Right shifting by currentStartBitIdx just puts the bits
        // back in the position they were in before our left shift.  So, in the example above, we really had 10011000 after
        // our left shift.  Right shifting by currentStartBitIdx (ie 3) gives us 00010011.  That's what the +currentStartBitIdx
        // is for.  Now, we also want to trim any bits at the end that we don't care about.  Say currentEndBitIdx is 5.  That means we
        // want 000100, but not the 11 at the end.  That is, we need to right shift by 2, ie 7-currentEndBitIdx.
        // 3) << leftShift -- Now we just need to left shift the bits that we've isolated by the appropriate amount.
        // For example, if we have 27 bits total, and we've isolated 6 bits from this first byte, then we need to left shift by
        // 27-6=21 bits.  (endBitIdx - startBitIdx + 1) gives us the total number of bits we are reading. (currentEndBitIdx - currentStartBitIdx + 1), ie the 27.
        // gives us the length of the bits we have isolated so far, ie the 6.  Note that the +1s cancel, which is how we get the declaration of leftShift.
        
        value = value | bits // "or" our isolated bits into value
        
        if startByteIdx + 1 <= endByteIdx - 1 {
            // We want to loop over the "in between bytes", only the full ones to keep things simple.
            // If we're reading from bytes 3 to bytes 6, bytes 3 and 6 themselves might be partial, ie we only
            // read the end of byte 3 and the beginning of byte 6.  But bytes 4 and 5 and guaranteed to contain
            // their full 8 bits, which makes reading them much less annoying!
            for i in startByteIdx+1...endByteIdx-1 {
                leftShift -= 8 // We have read out an entire byte's worth of bits, so we need to left shift 8 places less than before.
                bits = Int(self[i]) << leftShift
                value = value | bits
            }
        }
        
        if endByteIdx != startByteIdx {
            // here, we read in the last byte, if it isn't the same as the first byte
            // (which would happen if endBitIdx and startBitIdx both belonged to the
            // same byte)
            currentEndBitIdx = endBitIdx % 8
            bits = Int(self[endByteIdx] >> (7 - currentEndBitIdx)) // We know that we want the leading bits of the byte, since this is the last byte.
            // We just need to get rid of any bits that fall after currentEndBitIdx.
            value = value | bits
        }
        
        return value
    }
    
    func getStrValue(startBitIdx:Int, endBitIdx:Int) -> String {
        let startByteIdx = startBitIdx / 8
        let endByteIdx = endBitIdx / 8
        
        var value = ""
        
        var currentEndBitIdx = 7
        let currentStartBitIdx = startBitIdx % 8
        if endByteIdx == startByteIdx {
            currentEndBitIdx = endBitIdx % 8
        }
        var bits = (self[startByteIdx] << currentStartBitIdx) >> (7 - currentEndBitIdx + currentStartBitIdx)
        value += to8BitStr(bits).suffix(currentEndBitIdx - currentStartBitIdx + 1)
        
        if startByteIdx + 1 <= endByteIdx - 1 {
            for i in startByteIdx+1...endByteIdx-1 {
                bits = UInt8(self[i])
                value += to8BitStr(bits)
            }
        }
        
        if endByteIdx != startByteIdx {
            currentEndBitIdx = endBitIdx % 8
            bits = UInt8(self[endByteIdx] >> (7 - currentEndBitIdx))
            value += to8BitStr(bits).suffix(currentEndBitIdx + 1)
        }
        
        return value
    }
    
    func setBytes(values: [(Int, Int)], startByteIdx: Int = 0) {
        //currentLength accumulates bits until it has a total of 32 bits
        var currentLength = 0
        var currentLine = 0
        var byteIdx = offset + startByteIdx
        var leftShift = 32
        
        //var vals:Int = []
        //After having a total of 32 bits, it is converted into type UInt32
        for (value, length) in values {
            currentLength += length
            leftShift -= length
            currentLine = (value << (leftShift)) | currentLine
            if currentLength == 32 {
                var currentLine32 = UInt32(bigEndian: UInt32(currentLine))
                
                //This checks if there are enough bytes to add the new data, if it doesn't it adds 0's.
                
                // make sure we have enough bytes to overwrite!
                let zerosToAppendCount = byteIdx - bytes.count + 4
                if zerosToAppendCount > 0 {
                    let zeros = Data(repeating: 0x00, count: zerosToAppendCount) // todo: check what happens if "count" <= 0
                    //To-do answer: The app crashes if count <= 0, it doesn't add 0's correctly and causes issues when replacing bytes
                    bytes.append(zeros)
                }
                
                //This replaces the existing bytes with the bytes present in currentLine32
                withUnsafeBytes(of: &currentLine32) {
                    bytes.data.replaceSubrange(byteIdx..<byteIdx+4, with: $0)
                }
                
                //Resets so that the next values can be processed
                byteIdx += 4
                currentLength = 0
                currentLine = 0
                leftShift = 32
            }
        }
    }
}
