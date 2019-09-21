import Foundation

// MARK: - Read

extension Data {
    
    mutating func readMagic() -> Goldleaf.Magic? {
        let data = subdata(in: startIndex..<startIndex.advanced(by: 4))
        let magic = Goldleaf.Magic(rawValue: String(data: data, encoding: .utf8)!)
        removeSubrange(startIndex..<startIndex.advanced(by: 4))
        return magic
    }
    
    mutating func readCommand() -> Goldleaf.Command? {
        let commandId = readi32()
        return Goldleaf.Command(rawValue: commandId)
    }
    
}

// MARK: - Write

extension Data {
    
    mutating func write(magic: Goldleaf.Magic) {
        debugPrint("Sending magic: \(magic)")
        append(contentsOf: magic.data)
    }
    
}
