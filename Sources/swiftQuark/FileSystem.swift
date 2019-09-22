import Foundation

enum FileSystem {
    
    static let drives: [URL] =
        (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                               options: .skipHiddenVolumes) ?? [])
    
    static let specialPaths: [URL] = [
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    ].compactMap { $0 }
        
   
}
