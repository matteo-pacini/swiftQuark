import Clibusb
import Foundation

final class NintendoSwitch {
    
    // MARK: Static Properties
    
    private static let vendorId: UInt16 = 0x057E
    private static let productId: UInt16 = 0x3000
    private static let readEndpoint: UInt8 = 0x81
    private static let writeEndpoint: UInt8 = 0x1
    private static let interfaceNumber: Int32 = 0
    private static let configuration: Int32 = 1
    private static let bulkReadSize: Int32 = 0x1000
    
    private static var sharedInstance: NintendoSwitch?
    
    // MARK: Properties
        
    private let device: OpaquePointer
    private var fileSystemSnapshot: FileSystemSnapshot?
    
    // MARK: - Lifecycle
    
    static func shared() -> NintendoSwitch? {
        guard let device = libusb_open_device_with_vid_pid(nil,
                                                           vendorId,
                                                           productId) else {
            return nil
        }
        guard let instance = sharedInstance else {
            sharedInstance = NintendoSwitch(device: device)
            return sharedInstance
        }
        return instance
    }
    
    private init?(device: OpaquePointer) {
        self.device = device
        guard libusb_set_configuration(device, NintendoSwitch.configuration) == 0,
              libusb_claim_interface(device, NintendoSwitch.interfaceNumber) == 0 else {
            return nil
        }
    }
    
    func release() {
        debugPrint("Releasing interface \(NintendoSwitch.interfaceNumber)...")
        assert(libusb_release_interface(device, NintendoSwitch.interfaceNumber) == 0)
        debugPrint("Closing USB device...")
        libusb_close(device)
        NintendoSwitch.sharedInstance = nil
    }
    
}

// MARK: - Read

extension NintendoSwitch {
    
    private func readData() -> Data? {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(NintendoSwitch.bulkReadSize))
        var actualLength: Int32 = 0
        let res = libusb_bulk_transfer(device,
                             NintendoSwitch.readEndpoint,
                             data,
                             NintendoSwitch.bulkReadSize,
                             &actualLength,
                             0)
            
        guard res == 0 else {
            return nil
        }
        return Data(bytes: data, count: Int(actualLength))
    }
    
}

// MARK: - Write

extension NintendoSwitch {
    
    func write(data: inout Data, withPadding: Bool = true) {
        if withPadding {
            let padding = Int(NintendoSwitch.bulkReadSize) - data.count
            let actualPadding = (0...padding).map { _ in UInt8(0) }
            data.append(contentsOf: actualPadding)
        }
        var actualLength: Int32 = 0
        let res = libusb_bulk_transfer(device,
                             NintendoSwitch.writeEndpoint,
                             data.withUnsafeMutableBytes { $0 },
                             withPadding ? NintendoSwitch.bulkReadSize : Int32(data.count),
                             &actualLength,
                             0)
            
        guard res == 0 else {
            debugPrint("Could not send data to the console")
            return
        }
        debugPrint("Sent \(actualLength) bytes")
    }
    
}

// MARK: - Loop

extension NintendoSwitch {
    
    func loop() {
        while true {
            debugPrint("Waiting for data...")
            guard var data = readData() else {
                break
            }
            guard let magic = data.readMagic() else {
                print("Received invalid magic")
                break
            }
            debugPrint("Received magic: \(magic).")
            guard let command = data.readCommand() else {
                print("Received invalid command")
                break
            }
            debugPrint("Received command: \(command).")
            var outBuffer = Data()

            switch command {

            case .getDriveCount:
                debugPrint("getDriveCount -> \(Int32(FileSystemSnapshot.drives.count))")
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(FileSystemSnapshot.drives.count))
                write(data: &outBuffer)
    
            case .getDriveInfo:
                let index = data.readi32()
                let drive = FileSystemSnapshot.drives[Int(index)]
                debugPrint("getDriveInfo -> \([drive.label, drive.path])")
                
                outBuffer.writeResponse()
                outBuffer.write(string: drive.label)
                outBuffer.write(string: drive.path)
                outBuffer.write(int32: 0)
                outBuffer.write(int32: 0)
                write(data: &outBuffer)

            case .getSpecialPathCount:
                debugPrint("getSpecialPathCount -> \(Int32(FileSystemSnapshot.specialPaths.count))")
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(FileSystemSnapshot.specialPaths.count))
                write(data: &outBuffer)
                
            case .getSpecialPath:
                let index = data.readi32()
                let path = FileSystemSnapshot.specialPaths[Int(index)]
                debugPrint("getSpecialPath -> \([path.label, path.path])")
              
                outBuffer.writeResponse()
                outBuffer.write(string: path.label)
                outBuffer.write(string: path.path)
                write(data: &outBuffer)
                
            case .getDirectoryCount:
                let string = data.readString()
                var cleanString = string
                    .replacingOccurrences(of: ":/", with: "")
                    .replacingOccurrences(of: " ", with: "%20")
                if cleanString.last != "/" { cleanString.append("/") }
                let url = URL(string: "file://\(cleanString)")!
                
                debugPrint("getDirectoryCount -> \(url)")
                    
                fileSystemSnapshot = FileSystemSnapshot(location: url)
            
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(fileSystemSnapshot!.directories().count))
                write(data: &outBuffer)
                
            case .getDirectory:
                let _ = data.readString() // is this needed?
                let index = data.readi32()
                let directory = fileSystemSnapshot!.directories()[Int(index)]
                                    
                print("getDirectory -> \(directory)")
                
                outBuffer.writeResponse()
                outBuffer.write(string: directory.lastPathComponent)
                write(data: &outBuffer)
            
            case .getFileCount:
                print("getFileCount -> \(Int32(fileSystemSnapshot!.files().count))")
                outBuffer.writeResponse()
                outBuffer.write(int32: Int32(fileSystemSnapshot!.files().count))
                write(data: &outBuffer)
                
            case .getFile:
                let _ = data.readString() // is this needed?
                let index = data.readi32()
                let file = fileSystemSnapshot!.files()[Int(index)]
                print("getFile -> \(file)")
                
                outBuffer.writeResponse()
                outBuffer.write(string: file.lastPathComponent)
                write(data: &outBuffer)
                
            case .statPath:
                let string = data.readString()
                let path = string
                    .replacingOccurrences(of: "file://", with: "")
                    .replacingOccurrences(of: ":/", with: "")
                let attributes =
                    (try? FileManager.default
                         .attributesOfItem(atPath: path)) ?? [:]
                debugPrint("statPath -> \(path)")
                
                outBuffer.writeResponse()

                if (attributes[.type] as? String) == FileAttributeType.typeDirectory.rawValue {
                    outBuffer.write(int32: 2)
                    outBuffer.write(int64: 0)
                } else {
                    outBuffer.write(int32: 1)
                    let size = (attributes[.size] as? Int64) ?? 0
                    outBuffer.write(int64: size)
                }
                write(data: &outBuffer)
                
            case .readFile:
                let string = data.readString()
                             .replacingOccurrences(of: " ", with: "%20")
                let offset = data.readi64()
                let length = data.readi64()
                let url = URL(string: string)!
                debugPrint("readFile(\(string), \(offset), \(length))")
                
                let mappedData = try! Data(contentsOf: url, options: .mappedRead)
                let startIndex =
                    mappedData.startIndex.advanced(by: Int(offset))
                let endIndex =  startIndex.advanced(by: Int(length))
                
                var readData = mappedData.subdata(in: startIndex..<endIndex)
                
                outBuffer.writeResponse()
                outBuffer.write(int64: Int64(readData.count))
                write(data: &outBuffer)
                write(data: &readData, withPadding: false)

            default:
                fatalError("Command \(command) not implemented!")
                break
            }

        }
    }
    
}
