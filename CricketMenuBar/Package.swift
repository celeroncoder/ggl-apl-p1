// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CricketMenuBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CricketMenuBar", targets: ["CricketMenuBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "8.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CricketMenuBar",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            path: "Sources/CricketMenuBar",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CricketMenuBarTests",
            dependencies: ["CricketMenuBar"]
        ),
    ]
)
