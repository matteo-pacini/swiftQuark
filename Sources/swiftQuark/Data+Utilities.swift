import Foundation

// MARK: - Read

extension Data {
    
    mutating func readStringU16LE() -> String {
        let size = Int(readi32() * 2)
        let stringData = subdata(in: startIndex..<startIndex.advanced(by: size))
        let string = String(data: stringData, encoding: .utf16LittleEndian)!
        removeSubrange(startIndex..<startIndex.advanced(by: size))
        return string
    }
    
    mutating func readi32() -> Int32 {
        return readi()
    }
    
    mutating func readi64() -> Int64 {
        return readi()
    }
    
    mutating private func readi<T>() -> T where T: FixedWidthInteger {
        let bytes = T.bitWidth / 8
        let range = startIndex..<startIndex.advanced(by: bytes)
        let value = withUnsafeBytes { ptr in
            ptr.load(as: T.self)
        }
        removeSubrange(range)
        return value
    }

}

// MARK: - Write

extension Data {
    
    mutating private func write<T>(int: T) where T: FixedWidthInteger {
        debugPrint("Sending \(String(describing: T.self)): \(int)")
        let data = Swift.withUnsafeBytes(of: int.littleEndian) { ( ptr: UnsafeRawBufferPointer) in
            [UInt8](ptr)
        }
        append(contentsOf: data)
    }
    
    mutating func write(int32: Int32) {
        write(int: int32)
    }
    
    mutating func write(int64: Int64) {
        write(int: int64)
    }
    
    mutating func write(string: String) {
        debugPrint("Sending string: \"\(string)\"")
        write(int: Int32(string.count))
        append(contentsOf: string.data(using: .utf16LittleEndian)!)
    }
}
