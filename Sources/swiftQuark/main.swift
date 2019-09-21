import Clibusb
import Foundation

assert(libusb_init(nil) == 0)

print("swiftQuark v0.1")
print("Author: Matteo Pacini <m@matteopacini.me>\n")

NintendoSwitch.shared()?.loop() ?? {
    print("Coud not find a Nintendo Switch.")
    print("Make sure it is connected and that Goldleaf is running.")
    libusb_exit(nil)
    exit(1)
}()

NintendoSwitch.shared()?.release()
libusb_exit(nil)
exit(0)
