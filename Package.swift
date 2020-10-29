// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "EventEngine",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.32.0"),
        .package(url: "https://github.com/AddaMeSPB/AddaAPIGatewayModels.git", from: "1.0.17"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaAPIGatewayModels", package: "AddaAPIGatewayModels"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "APNS", package: "apns")
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
