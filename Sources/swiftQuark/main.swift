import Clibusb
import Foundation

print("swiftQuark v0.1")
print("Author: Matteo Pacini <m@matteopacini.me>\n")

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

    loop(nintendoSwitch: nintendoSwitch)

    exit(0)

} catch {
    print("A USB error occurred: \(error.localizedDescription).")
}
