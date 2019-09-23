import Foundation
import Clibusb

final class USB {

    static let instance = USB()

    private init() {
        assert(libusb_init(nil) == 0)
    }

    deinit {
        libusb_exit(nil)
    }

}

// MARK: - Error

extension USB {

    enum Error: Int, Swift.Error {
        case other = -99
        case unknown = -1000
    }

}

// MARK: - Device

extension USB {
    
    class Device {

        fileprivate let device: OpaquePointer
        fileprivate let descriptor: libusb_device_descriptor
        fileprivate var openHandle: OpaquePointer?
        fileprivate var claimedInterface: Int32?
        
        fileprivate init(device: OpaquePointer,
                         descriptor: libusb_device_descriptor) {
            self.device = device
            self.descriptor = descriptor
        }

        deinit {
            if let interface = claimedInterface {
                assert(libusb_release_interface(openHandle, interface) == 0)
            }
            if let handle = openHandle {
                libusb_close(handle)
            }
        }

        var vendorId: UInt16 { descriptor.idVendor }
        var productId: UInt16 { descriptor.idProduct }

    }
    
}

// MARK: - List All Devices

extension USB {

    func devices() throws -> [USB.Device] {
        var devices: UnsafeMutablePointer<OpaquePointer?>?
        let count = Int(libusb_get_device_list(nil, &devices))
        guard count >= 0 else {
            throw USB.Error(rawValue: count) ?? USB.Error.unknown
        }
        defer { libusb_free_device_list(devices, 0)}
        return try (0..<count).compactMap {
            devices?[$0]
        }.map { device in
            var descriptor = libusb_device_descriptor()
            let result = Int(libusb_get_device_descriptor(device, &descriptor))
            guard result == 0 else {
                throw USB.Error(rawValue: result) ?? USB.Error.unknown
            }
            return USB.Device(device: device, descriptor: descriptor)
        }
    }

}

// MARK: - Device Open / Close

extension USB.Device {

    func open() throws {
        guard openHandle == nil else {
            return
        }
        let result = Int(libusb_open(device, &openHandle))
        guard result == 0 else {
            throw USB.Error(rawValue: result) ?? USB.Error.unknown
        }
    }

    func close() throws {
        guard openHandle != nil else {
            return
        }
        libusb_close(openHandle)
        openHandle = nil
    }

}

// MARK: - Device Configuration

extension USB.Device {

    var configuration: Int32 {
        get {
            guard openHandle != nil else { return -1 }
            var config: Int32 = 0
            assert(libusb_get_configuration(openHandle, &config) == 0)
            return config
        }
        set {
            guard openHandle != nil else { return }
            assert(libusb_set_configuration(openHandle, newValue) == 0)
        }
    }

}

// MARK: - Device Claim Interface

extension USB.Device {

    func claimInterface(_ value: Int32) throws {
        guard openHandle != nil, claimedInterface == nil else {
            return
        }
        let result = Int(libusb_claim_interface(openHandle, value))
        guard result == 0 else {
            throw USB.Error(rawValue: result) ?? USB.Error.unknown
        }
        claimedInterface = value
    }

}

// MARK: = Device Read / Write

extension USB.Device {

    func read(size: Int, fromEndpoint: UInt8) -> Data? {
        guard openHandle != nil else {
            return nil
        }
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        var read: Int32 = 0
        let res = libusb_bulk_transfer(openHandle,
                             fromEndpoint,
                             data,
                             Int32(size),
                             &read,
                             0)

        guard res == 0 else {
            return nil
        }
        return Data(bytes: data, count: Int(read))
    }

    func write(data: inout Data,
               withPadding: Bool = true,
               transferSizeForPadding: Int = 0,
               toEndpoint: UInt8) {
        guard openHandle != nil else {
            return
        }
        if withPadding {
            let padding = transferSizeForPadding - data.count
            let actualPadding = (0...padding).map { _ in UInt8(0) }
            data.append(contentsOf: actualPadding)
        }
        var written: Int32 = 0
        let res = libusb_bulk_transfer(openHandle,
                             toEndpoint,
                             data.withUnsafeMutableBytes {
                                $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                             },
                             withPadding ?
                                Int32(transferSizeForPadding) :
                                Int32(data.count),
                             &written,
                             0)
        assert(res == 0)
    }

}

// MARK: - Nintendo Switch

extension USB.Device {

    var isNintendoSwitch: Bool {
        vendorId == Goldleaf.vendorId &&
        productId == Goldleaf.productId
    }

}
