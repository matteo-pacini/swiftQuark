import Foundation

final class MappedFile {

    enum Error: Swift.Error {
        case open(Int32)
        case fstat(Int32)
        case mmap(Int32)
    }

    private var fd: Int32
    private var fileSize: off_t
    private var f: UnsafeMutableRawPointer

    lazy var data: Data = {
        return Data(bytesNoCopy: f, count: Int(fileSize), deallocator: .none)
    }()

    init(url: URL) throws {
        fd = open(url.path, O_RDONLY)
        guard fd >= 0 else { throw Error.open(errno) }
        var s = stat()
        guard fstat(fd, &s) >= 0 else {
            close(fd)
            throw Error.fstat(errno)
        }
        fileSize = s.st_size
        f = mmap(nil, Int(fileSize), PROT_READ, MAP_PRIVATE, fd, 0)
        guard f != MAP_FAILED else {
            close(fd)
            throw Error.mmap(errno)
        }
    }

    deinit {
        munmap(f, Int(fileSize))
        close(fd)
    }

}
