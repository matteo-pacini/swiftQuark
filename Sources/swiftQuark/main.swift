import Clibusb
import Foundation
#if os(Linux)
import Glibc
#endif

print("swiftQuark v0.1")
print("Author: Matteo Pacini <m@matteopacini.me>\n")

#if os(Linux)
if getuid() != 0 {
    print("USB device access requires root privileges on Linux.")
    print("Try running swiftQuark with sudo.")
    exit(1)
}
#endif

do {

    let nintendoSwitch = try USB.instance.devices()
        .filter { $0.isNintendoSwitch }
        .first

    try nintendoSwitch?.open() ?? {
        print("Coud not find a Nintendo Switch.")
        print("Make sure it is connected and that Goldleaf is running.")
        exit(1)
    }()

    nintendoSwitch?.configuration = Goldleaf.configuration
    try nintendoSwitch?.claimInterface(Goldleaf.interfaceNumber)

    try loop(nintendoSwitch: nintendoSwitch)

    exit(0)

} catch {
    debugPrint(error)
    print("A USB error occurred: \(error.localizedDescription).")
}
