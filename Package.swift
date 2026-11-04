// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MatrixRain",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MatrixRain", targets: ["MatrixRain"])],
    targets: [
        .target(name: "RainCore"),
        .target(name: "MatrixRainUI", dependencies: ["RainCore"]),
        .executableTarget(name: "MatrixRain", dependencies: ["MatrixRainUI"]),
        .testTarget(name: "RainCoreTests", dependencies: ["RainCore"]),
        .executableTarget(name: "NativeChecks", dependencies: ["MatrixRainUI", "RainCore"], path: "Tests/NativeChecks")
    ]
)
