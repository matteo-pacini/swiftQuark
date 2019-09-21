import Foundation

struct File {

    let label: String
    let path: String
    
    init(url: URL) {
        path = url.absoluteString
                  .replacingOccurrences(of: "file://", with: "")
        label = path == "/" ? 
            "Root" :
            path.replacingOccurrences(of: "/Volumes/", with: "")
                .replacingOccurrences(of: "/", with: "")
    }
    
    init(label: String, path: String) {
        self.label = label
        self.path = path
    }

}

struct FileSystemSnapshot {
    
    static let drives: [File] =
        (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                               options: .skipHiddenVolumes) ?? [])
        .map { File(url: $0) }
    
    static let specialPaths: [File] = [
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first.map { File(label: "Downloads",
                                                                                                 path: $0.absoluteString) }
    ].compactMap { $0 }
        
    let location: URL
    private var cachedDirectories: [URL]?
    private var cachedFiles: [URL]?
    
    init(location: URL) {
        self.location = location
    }
    
    mutating func directories() -> [URL] {
        guard let cachedDirectories = cachedDirectories else {
            self.cachedDirectories =
            ((try? FileManager.default.contentsOfDirectory(at: location,
                                                         includingPropertiesForKeys: [.isDirectoryKey],
                                                         options: .skipsHiddenFiles)) ?? [])
            .filter { $0.hasDirectoryPath }
            return self.cachedDirectories!
        }
        return cachedDirectories
    }
    
    mutating func files() -> [URL] {
        guard let cachedFiles = cachedFiles else {
            self.cachedFiles =
            ((try? FileManager.default.contentsOfDirectory(at: location,
                                                           includingPropertiesForKeys: [.isDirectoryKey],
                                                           options: .skipsHiddenFiles)) ?? [])
            .filter { !$0.hasDirectoryPath }
            return self.cachedFiles!
        }
        return cachedFiles
    }
}
