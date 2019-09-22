// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftQuark",
    platforms: [
        .macOS(.v10_12)
    ],
    dependencies: [
        
    ],
    targets: [
        .systemLibrary(name: "Clibusb",
            pkgConfig: "libusb-1.0",
            providers: [
                .brew(["libusb"]),
                .apt(["libusb-1.0-0-dev"])
            ]),
        .target(
            name: "swiftQuark",
            dependencies: ["Clibusb"])
    ],
    swiftLanguageVersions: [.version("5")]
)
