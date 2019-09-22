import Foundation

extension URL {
    
    var driveName: String {
        let name = absoluteString
            .replacingOccurrences(of: "file://", with: "")
            .replacingOccurrences(of: "/Volumes/", with: "")
        guard name != "/" /* root drive */ else {
            return "Root"
        }
        return name.replacingOccurrences(of: "/", with: "")
    }

    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self,
                                                             includingPropertiesForKeys: nil,
                                                             options: [.skipsHiddenFiles]).filter{ $0.isDirectory }) ?? []
    }
    
    var files: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self,
                                                             includingPropertiesForKeys: nil,
                                                             options: [.skipsHiddenFiles]).filter{ !$0.isDirectory }) ?? []
    }
    
    var fileSize: Int64 {
        let attributes = (try? FileManager.default.attributesOfItem(atPath: path)) ?? [:]
        return (attributes[.size] as? Int64) ?? 0
    }
    
}
