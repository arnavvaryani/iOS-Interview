//
//  Bytes.swift
//  PacketTunnel
//
//  Created by Horgan, Luke on 11/28/23.
//

import Foundation

/**
 Just a wrapper around a Swift data object. Data is a value type, not a reference type. DataWrapper is a class,
 however, so it *is* a reference type. This comes with various efficency benefits that matter when you're handling.
 thousands of packets per second.
 */
class DataWrapper {
    var data: Data

    init(_ data: Data) {
        self.data = data
    }
    
    var count: Int {
        return data.count
    }

    func append(_ newData: Data) {
        data.append(newData)
    }
    
    subscript(index: Data.Index) -> UInt8 {
        get {
            return data[index]
        }
        set {
            data[index] = newValue
        }
    }
}
