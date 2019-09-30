import Foundation

enum FileSystem {

    #if os(Linux)
    static let drives: [URL] = [
        URL(string: "file:///") /* root drive */
    ].compactMap { $0 }
    #else
    static let drives: [URL] =
        (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                               options: .skipHiddenVolumes) ?? [])
    #endif
    
    static let specialPaths: [URL] = [
        FileManager.default.urls(for: .userDirectory, in: .userDomainMask).first,
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    ].compactMap { $0 }
        
   
}
