import Foundation

// MARK: - Loop

extension NintendoSwitch {
    
    func loop() {
        while true {
            debugPrint("Waiting for data...")

            guard var data = readData() else {
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
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(FileSystem.drives.count))
    
            case .getDriveInfo:
                let index = data.readi32()
                let drive = FileSystem.drives[Int(index)]
                debugPrint("getDriveInfo -> \([drive.driveName, drive.path])")
                
                outBuffer.writeResponse()
                outBuffer.write(string: drive.driveName)
                outBuffer.write(string: drive.path)
                outBuffer.write(int32: 0)
                outBuffer.write(int32: 0)

            case .getSpecialPathCount:
                debugPrint("getSpecialPathCount -> \(Int32(FileSystem.specialPaths.count))")
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(FileSystem.specialPaths.count))
                
            case .getSpecialPath:
                let index = data.readi32()
                let path = FileSystem.specialPaths[Int(index)]
                debugPrint("getSpecialPath -> \([path.lastPathComponent, path.path])")
              
                outBuffer.writeResponse()
                outBuffer.write(string: path.lastPathComponent)
                outBuffer.write(string: path.path)
                
            case .getDirectoryCount:
                let string = data.readString()
                debugPrint("getDirectoryCount -> \(string)")
                
                let url = URL(string: "file://\(string)")!
                cachedSubdirectories = url.subDirectories
            
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(cachedSubdirectories!.count))
                
            case .getDirectory:
                let _ = data.readString()
                let index = data.readi32() 
                let url = cachedSubdirectories![Int(index)]
                                    
                print("getDirectory -> \(url.path)")
                
                outBuffer.writeResponse()
                outBuffer.write(string: url.lastPathComponent)
            
            case .getFileCount:
                let string = data.readString()
                let url = URL(string: "file://\(string)")!
                cachedFiles = url.files
                
                print("getFileCount -> \(string)")
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(cachedFiles!.count))
                
            case .getFile:
                let _ = data.readString()
                let index = data.readi32() // is this needed?
                let url = cachedFiles![Int(index)]
                print("getFile -> \(url.path)")
                
                outBuffer.writeResponse()
                outBuffer.write(string: url.lastPathComponent)
                
            case .statPath:
                let string = data.readString()
                let url = URL(string: "file://\(string)".replacingOccurrences(of: " ", with: "%20"))!
                debugPrint("statPath -> \(string)")
                
                outBuffer.writeResponse()

                if url.isDirectory {
                    outBuffer.write(int32: 2)
                    outBuffer.write(int64: 0)
                } else {
                    outBuffer.write(int32: 1)
                    outBuffer.write(int64: url.fileSize)
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
                    mappedFile = try! Data(contentsOf: url, options: .mappedRead)
                }
                
                let startIndex = mappedFile!.startIndex.advanced(by: Int(offset))
                let endIndex =  startIndex.advanced(by: Int(length))
                
                var readData = mappedFile!.subdata(in: startIndex..<endIndex)
                
                outBuffer.writeResponse()
                outBuffer.write(int64: Int64(readData.count))
                write(data: &outBuffer)
                write(data: &readData, withPadding: false)
                continue

            default:
                fatalError("Command \(command) not implemented!")
                break
            }
            
            write(data: &outBuffer)

        }
    }
    
}
