import Foundation

// MARK: - Loop

private var cachedSubdirectories: [URL]?
private var cachedFiles: [URL]?
private var mappedFile: Data?
private var mappedFileURL: URL?

func loop(nintendoSwitch: USB.Device?) throws {
    while true {
        debugPrint("Waiting for data...")

        guard var data = nintendoSwitch?.read(size: Int(Goldleaf.bulkTransferSize),
                                              fromEndpoint: Goldleaf.readEndpoint) else {
            break
        }

        guard let _ = data.readMagic() else {
            print("Received invalid magic")
            break
        }

        guard let command = data.readCommand() else {
            print("Received invalid command")
            break
        }

        var outBuffer = Data()

        switch command {

        case .getDriveCount:
            debugPrint("getDriveCount -> \(Int32(FileSystem.drives.count))")
            outBuffer << .success
            outBuffer << Int32(FileSystem.drives.count)

        case .getDriveInfo:
            let index = data.readi32()
            let drive = FileSystem.drives[Int(index)]
            debugPrint("getDriveInfo -> \([drive.driveName, drive.path])")

            outBuffer << .success
            outBuffer << drive.driveName
            outBuffer << drive.path
            outBuffer << 0
            outBuffer << 0

        case .getSpecialPathCount:
            debugPrint("getSpecialPathCount -> \(Int32(FileSystem.specialPaths.count))")
            outBuffer << .success
            outBuffer << Int32(FileSystem.specialPaths.count)

        case .getSpecialPath:
            let index = data.readi32()
            let path = FileSystem.specialPaths[Int(index)]
            debugPrint("getSpecialPath -> \([path.lastPathComponent, path.path])")

            outBuffer << .success
            outBuffer << path.lastPathComponent
            outBuffer << path.path

        case .getDirectoryCount:
            let string = data.readString()
            debugPrint("getDirectoryCount -> \(string)")

            let url = URL(string: "file://\(string)")!
            cachedSubdirectories = url.subDirectories

            outBuffer << .success
            outBuffer << Int32(cachedSubdirectories!.count)

        case .getDirectory:
            let _ = data.readString()
            let index = data.readi32()
            let url = cachedSubdirectories![Int(index)]

            print("getDirectory -> \(url.path)")

            outBuffer << .success
            outBuffer << url.lastPathComponent

        case .getFileCount:
            let string = data.readString()
            let url = URL(string: "file://\(string)")!
            cachedFiles = url.files

            print("getFileCount -> \(string)")
            outBuffer << .success
            outBuffer << Int32(cachedFiles!.count)

        case .getFile:
            let _ = data.readString()
            let index = data.readi32() // is this needed?
            let url = cachedFiles![Int(index)]
            print("getFile -> \(url.path)")

            outBuffer << .success
            outBuffer << url.lastPathComponent

        case .statPath:
            let string = data.readString()
            let url = URL(string: "file://\(string)".replacingOccurrences(of: " ", with: "%20"))!
            debugPrint("statPath -> \(string)")

            outBuffer.writeResponse()

            if url.isDirectory {
                outBuffer << 2
                outBuffer << Int64(0)
            } else {
                outBuffer << 1
                outBuffer << Int64(url.fileSize)
            }

        case .readFile:
            let string = data.readString()
            let offset = data.readi64()
            let length = data.readi64()
            let url = URL(string: "file://\(string)".replacingOccurrences(of: " ", with: "%20"))!

            debugPrint("readFile(\(string), \(offset), \(length))")

            if url != mappedFileURL {
                debugPrint("readFile - Setting mappedFile and mappedFileURL")
                mappedFileURL = url
                mappedFile = try! Data(contentsOf: url, options: .mappedIfSafe)
            }

            let startIndex = mappedFile!.startIndex.advanced(by: Int(offset))
            let endIndex =  startIndex.advanced(by: Int(length))

            var readData = mappedFile!.subdata(in: startIndex..<endIndex)

            outBuffer << .success
            outBuffer << Int64(readData.count)
            nintendoSwitch?.write(data: &outBuffer,
                                  withPadding: true,
                                  transferSizeForPadding: Int(Goldleaf.bulkTransferSize),
                                  toEndpoint: Goldleaf.writeEndpoint)
            nintendoSwitch?.write(data: &readData,
                                  withPadding: false,
                                  toEndpoint: Goldleaf.writeEndpoint)
            continue

        case .delete:
            let _ = data.readi32()
            let path = data.readString()
            do {
                try FileManager.default.removeItem(atPath: path)
                outBuffer << .success
            } catch {
                outBuffer << .failure(1)
            }

        default:
            fatalError("Command \(command) not implemented!")
            break
        }

        nintendoSwitch?.write(data: &outBuffer,
                              withPadding: true,
                              transferSizeForPadding: Int(Goldleaf.bulkTransferSize),
                              toEndpoint: Goldleaf.writeEndpoint)

    }
}
