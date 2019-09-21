import Foundation

extension FileManager {
    
    static var mountedVolumes: [URL] {
        let manager = FileManager.default
        let urls =
        manager.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                  options: .skipHiddenVolumes)
        return urls ?? []
    }
    
    static var specialPaths: [(String, URL)] {
        [
            ("Downloads", FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!)
        ]
    }
    
}
