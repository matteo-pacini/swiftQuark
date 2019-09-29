import Foundation

// MARK: - Response
enum Response {
    case success
    case failure(Int32)

    var code: Int32 {
        switch self {
        case .success:
            return 0
        case let .failure(code):
            return code
        }
    }

}

// MARK: - Operator
infix operator <<

func << (lhs: inout Data, response: Response) {
    lhs.write(magic: .GLCO)
    lhs.write(int32: response.code)
}

func << (lhs: inout Data, int: Int) {
    lhs.write(int: Int32(int))
}

func << (lhs: inout Data, int32: Int32) {
    lhs.write(int: int32)
}

func << (lhs: inout Data, int64: Int64) {
    lhs.write(int: int64)
}

func << (lhs: inout Data, string: String) {
    lhs.write(string: string)
}

// MARK: - Read

extension Data {
    
    /// Reads a Goldleaf magic number from the data.
    /// The first 4 bytes of the data are then removed.
    mutating func readMagic() -> Goldleaf.Magic? {
        let data = subdata(in: startIndex..<startIndex.advanced(by: 4))
        let magic = Goldleaf.Magic(rawValue: String(data: data, encoding: .utf8)!)
        removeSubrange(startIndex..<startIndex.advanced(by: 4))
        return magic
    }
    
    /// Reads a Goldleaf command from the data.
    /// The first 4 bytes are then removed.
    mutating func readCommand() -> Goldleaf.Command? {
        let commandId = readi32()
        return Goldleaf.Command(rawValue: commandId)
    }
    
    /// Reads a UTF16-LE encoded string from the data.
    /// 4+sizeof(string) bytes are then removed.
    mutating func readString(cleanGibberish: Bool = true) -> String {
        let size = Int(readi32() * 2)
        let stringData = subdata(in: startIndex..<startIndex.advanced(by: size))
        let string = String(data: stringData, encoding: .utf16LittleEndian)!
        removeSubrange(startIndex..<startIndex.advanced(by: size))
        return cleanGibberish ? string.replacingOccurrences(of: ":/", with: "/") : string
    }
    
    /// Reads a 32-bit integer from the data.
    /// The first 4 bytes of the data are then removed.
    mutating func readi32() -> Int32 {
        return readi()
    }
    
    /// Reads a 64-bit integer from the data.
    /// The first 4 bytes of the data are then removed.
    mutating func readi64() -> Int64 {
        return readi()
    }
    
    mutating fileprivate func readi<T>() -> T where T: FixedWidthInteger {
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
    
    /// Writes a Goldleaf magic number to the data.
    fileprivate mutating func write(magic: Goldleaf.Magic) {
        debugPrint("Writing magic: \(magic)")
        append(contentsOf: magic.data)
    }
    
    /// Writes Goldleaf output magic number and result code to the data.
    mutating func writeResponse(code: Int32 = 0) {
        write(magic: .GLCO)
        write(int32: code)
    }
    
    mutating fileprivate func write<T>(int: T) where T: FixedWidthInteger {
        debugPrint("Writing \(String(describing: T.self)): \(int)")
        let data = Swift.withUnsafeBytes(of: int.littleEndian) { ( ptr: UnsafeRawBufferPointer) in
            [UInt8](ptr)
        }
        append(contentsOf: data)
    }
    
    /// Writes a 32-bit integer to the data.
    mutating func write(int32: Int32) {
        write(int: int32)
    }
    
    /// Writes a 64-bit integer to the data.
    mutating func write(int64: Int64) {
        write(int: int64)
    }
    
    /// Writes sizeof(string) and the string itself to the data in UTF16-LE format.
    mutating func write(string: String) {
        debugPrint("Writing string: \"\(string)\"")
        write(int: Int32(string.count))
        append(contentsOf: string.data(using: .utf16LittleEndian)!)
    }
}
