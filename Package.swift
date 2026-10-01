// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "wifi-mob",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "WiFiCat",
            path: "Sources/WiFiCat"
        ),
        .testTarget(
            name: "WiFiCatTests",
            dependencies: ["WiFiCat"],
            path: "Tests/WiFiCatTests"
        ),
    ]
)
