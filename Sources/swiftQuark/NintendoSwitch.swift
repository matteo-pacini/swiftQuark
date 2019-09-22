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
    private static let bulkTransferSize: Int32 = 0x1000
    
    private static var sharedInstance: NintendoSwitch?
    
    // MARK: Properties
        
    private let device: OpaquePointer
    var cachedSubdirectories: [URL]?
    var cachedFiles: [URL]?
    var mappedFile: Data?
    var mappedFileURL: URL?
    
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
    
    func readData() -> Data? {
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(NintendoSwitch.bulkTransferSize))
        var actualLength: Int32 = 0
        let res = libusb_bulk_transfer(device,
                             NintendoSwitch.readEndpoint,
                             data,
                             NintendoSwitch.bulkTransferSize,
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
            let padding = Int(NintendoSwitch.bulkTransferSize) - data.count
            let actualPadding = (0...padding).map { _ in UInt8(0) }
            data.append(contentsOf: actualPadding)
        }
        var actualLength: Int32 = 0
        let res = libusb_bulk_transfer(device,
                             NintendoSwitch.writeEndpoint,
                             data.withUnsafeMutableBytes {
                                $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                             },
                             withPadding ?
                                NintendoSwitch.bulkTransferSize :
                                Int32(data.count),
                             &actualLength,
                             0)
            
        guard res == 0 else {
            debugPrint("Could not send data to the console")
            return
        }
        debugPrint("Sent \(actualLength) bytes")
    }
    
}
