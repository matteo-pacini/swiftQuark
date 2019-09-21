import Clibusb
import Foundation

assert(libusb_init(nil) == 0)
defer {
    NintendoSwitch.shared()?.release()
    libusb_exit(nil)
}

NintendoSwitch.shared()?.loop()
