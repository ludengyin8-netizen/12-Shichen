// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "SHICHEN",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15)
    ],
    products: [
        .library(name: "SHICHENApp", targets: ["SHICHENApp"]),
    ],
    dependencies: [
        // SwiftAA astronomical library (main branch to pick latest compatible version)
        .package(url: "https://github.com/onekiloparsec/SwiftAA.git", .branch("main"))
    ],
    targets: [
        .target(
            name: "SHICHENApp",
            dependencies: [
                .product(name: "SwiftAA", package: "SwiftAA")
            ],
            path: "Sources/SHICHENApp"
        ),
        .testTarget(
            name: "SHICHENAppTests",
            dependencies: ["SHICHENApp"],
            path: "Tests/SHICHENAppTests"
        )
    ]
)
