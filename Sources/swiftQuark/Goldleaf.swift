import Foundation

enum Goldleaf {

    static let vendorId: UInt16 = 0x057E
    static let productId: UInt16 = 0x3000
    static let readEndpoint: UInt8 = 0x81
    static let writeEndpoint: UInt8 = 0x1
    static let interfaceNumber: Int32 = 0
    static let configuration: Int32 = 1
    static let bulkTransferSize: Int32 = 0x1000

    enum Magic: String {

        case GLCI
        case GLCO
        
        var data: Data { self.rawValue.data(using: .utf8)! }
    }

    enum Command: Int32 {
        case invalid = -1
        case getDriveCount = 0
        case getDriveInfo = 1
        case statPath = 2
        case getFileCount = 3
        case getFile = 4
        case getDirectoryCount = 5
        case getDirectory = 6
        case readFile = 7
        case writeFile = 8
        case create = 9
        case delete = 10
        case rename = 11
        case getSpecialPathCount = 12
        case getSpecialPath = 13
        case selectFile = 14
        case startup = 15
    }

}
