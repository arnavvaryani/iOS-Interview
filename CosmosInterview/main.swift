import Foundation

//Both these examples (1 and 2) print the same value - 16909060

// Example 1:
//[1,2,3,4]'s binary representation is written together in decimal format
let data1 = DataWrapper(Data([1, 2, 3, 4]))
let bytes1 = NetworkBytes(data1)
print(bytes1.getIntValue(startBitIdx: 0, endBitIdx: 31))

// Example 2
let data2 = DataWrapper(Data([]))
let bytes2 = NetworkBytes(data2)
//Same values are being set as above [1,2,3,4] using setBytes func, here for eg. (1,8) - 1 is the value and 8 is length of bit same applies to all
bytes2.setBytes(values: [(1, 8), (2, 8), (3, 8), (4, 8)], startByteIdx: 0)
//Hence same output printed
print(bytes2.getIntValue(startBitIdx: 0, endBitIdx: 31))
 
