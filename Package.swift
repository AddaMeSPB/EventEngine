// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "EventEngine",
    platforms: [.macOS(.v12)],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.62.1"),
//        .package(path: "../AddaSharedModels"),
//        .package(url: "https://github.com/AddaMeSPB/AddaSharedModels.git", from: "1.1.1"),
        .package(url: "https://github.com/AddaMeSPB/AddaSharedModels.git", branch: "route"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "APNS", package: "apns")
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
