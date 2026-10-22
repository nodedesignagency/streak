// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StreakCelebration",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "StreakCelebration", targets: ["StreakCelebration"]),
    ],
    targets: [
        .target(name: "StreakCelebration"),
        .testTarget(name: "StreakCelebrationTests", dependencies: ["StreakCelebration"]),
    ]
)
