// swift-tools-version: 6.2
// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: BreakdownCore is the pure-Swift heart of the game: the engine-agnostic event model
//          (BreakdownLensModel), the recorded timeline and playback evaluator (BreakdownTimeline) and the
//          event-driven billiards solver (BreakdownPhysics). No UI or RealityKit imports, so every test
//          runs with the package test command on the Mac. BreakProbe is a small dev tool that prints a break.
// SRP/DRY check: Pass - one package, three single-purpose modules, layered LensModel <- Timeline <- Physics.
import PackageDescription

let package = Package(
    name: "BreakdownCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BreakdownCore", targets: ["BreakdownLensModel", "BreakdownTimeline", "BreakdownPhysics"]),
        .executable(name: "BreakProbe", targets: ["BreakProbe"]),
    ],
    targets: [
        .target(name: "BreakdownLensModel"),
        .target(name: "BreakdownTimeline", dependencies: ["BreakdownLensModel"]),
        .target(name: "BreakdownPhysics", dependencies: ["BreakdownLensModel", "BreakdownTimeline"]),
        .executableTarget(name: "BreakProbe", dependencies: ["BreakdownPhysics", "BreakdownTimeline", "BreakdownLensModel"]),
        .testTarget(name: "BreakdownCoreTests", dependencies: ["BreakdownPhysics", "BreakdownTimeline", "BreakdownLensModel"]),
    ],
    swiftLanguageModes: [.v6]
)
