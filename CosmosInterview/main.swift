import Foundation

// Example 1:
let data1 = DataWrapper(Data([1, 2, 3, 4]))
let bytes1 = NetworkBytes(data1)
print(bytes1.getIntValue(startBitIdx: 0, endBitIdx: 31))

// Example 2
let data2 = DataWrapper(Data([]))
let bytes2 = NetworkBytes(data2)
bytes2.setBytes(values: [(1, 8), (2, 8), (3, 8), (4, 8)], startByteIdx: 0)
print(bytes2.getIntValue(startBitIdx: 0, endBitIdx: 31))
