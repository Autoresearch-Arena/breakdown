// swift-tools-version: 6.2
// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (a fourth module, BreakdownRules: the rules of the match games,
//          pure Swift on top of LensModel and Timeline. It joins the BreakdownCore library product, so the app's Xcode
//          project, which links that product, needs no change; the tests depend on it too.)
// PURPOSE: BreakdownCore is the pure-Swift heart of the game: the engine-agnostic event model
//          (BreakdownLensModel), the recorded timeline, its playback evaluator and the shared reading of a shot
//          (BreakdownTimeline), the event-driven billiards solver (BreakdownPhysics) and the match rules
//          (BreakdownRules: eight-ball's shared types, the match state, rulings and the rules protocol). No UI or
//          RealityKit imports, so every test runs with the package test command on the Mac. BreakProbe is a small dev
//          tool that prints a break and authors the trick shots.
// SRP/DRY check: Pass - one package, four single-purpose modules, layered LensModel <- Timeline <- Physics, and
//          LensModel <- Timeline <- Rules (the rules read recorded shots and never solve one).
import PackageDescription

let package = Package(
    name: "BreakdownCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BreakdownCore",
                 targets: ["BreakdownLensModel", "BreakdownTimeline", "BreakdownPhysics", "BreakdownRules"]),
        .executable(name: "BreakProbe", targets: ["BreakProbe"]),
    ],
    targets: [
        .target(name: "BreakdownLensModel"),
        .target(name: "BreakdownTimeline", dependencies: ["BreakdownLensModel"]),
        .target(name: "BreakdownPhysics", dependencies: ["BreakdownLensModel", "BreakdownTimeline"]),
        .target(name: "BreakdownRules", dependencies: ["BreakdownLensModel", "BreakdownTimeline"]),
        .executableTarget(name: "BreakProbe", dependencies: ["BreakdownPhysics", "BreakdownTimeline", "BreakdownLensModel"]),
        .testTarget(name: "BreakdownCoreTests",
                    dependencies: ["BreakdownPhysics", "BreakdownTimeline", "BreakdownLensModel", "BreakdownRules"]),
    ],
    swiftLanguageModes: [.v6]
)
