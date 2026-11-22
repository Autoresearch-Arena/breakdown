// swift-tools-version: 6.2
// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (a fourth module, BreakdownRules: the rules of the match games,
//          pure Swift on top of LensModel and Timeline. It joins the BreakdownCore library product, so the app's Xcode
//          project, which links that product, needs no change; the tests depend on it too.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 38: a fifth module, BreakdownAuthored,
//          the one library of authored answers (trick shots, lessons, Behind the 8-Ball escapes) and the playing
//          surfaces' numbers. It joins the BreakdownCore library product, so the app reads it with no project change;
//          BreakProbe and the tests read it too, so no copy of an authored number exists anywhere else.)
// PURPOSE: BreakdownCore is the pure-Swift heart of the game: the engine-agnostic event model
//          (BreakdownLensModel), the recorded timeline, its playback evaluator and the shared reading of a shot
//          (BreakdownTimeline), the event-driven billiards solver (BreakdownPhysics) and the match rules
//          (BreakdownRules: eight-ball's shared types, the match state, rulings and the rules protocol), and the authored
//          answers library (BreakdownAuthored: trick shots, lessons, escapes, surfaces). No UI or
//          RealityKit imports, so every test runs with the package test command on the Mac. BreakProbe is a small dev
//          tool that prints a break and authors the trick shots.
// SRP/DRY check: Pass - one package, five single-purpose modules, layered LensModel <- Timeline <- Physics,
//          LensModel <- Timeline <- Rules (the rules read recorded shots and never solve one), and Physics + Rules <-
//          Authored (data only: it names strokes, calls and surfaces, and solves nothing).
import PackageDescription

let package = Package(
    name: "BreakdownCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BreakdownCore",
                 targets: ["BreakdownLensModel", "BreakdownTimeline", "BreakdownPhysics", "BreakdownRules",
                           "BreakdownAuthored"]),
        .executable(name: "BreakProbe", targets: ["BreakProbe"]),
    ],
    targets: [
        .target(name: "BreakdownLensModel"),
        .target(name: "BreakdownTimeline", dependencies: ["BreakdownLensModel"]),
        .target(name: "BreakdownPhysics", dependencies: ["BreakdownLensModel", "BreakdownTimeline"]),
        .target(name: "BreakdownRules", dependencies: ["BreakdownLensModel", "BreakdownTimeline"]),
        .target(name: "BreakdownAuthored",
                dependencies: ["BreakdownLensModel", "BreakdownTimeline", "BreakdownPhysics", "BreakdownRules"]),
        .executableTarget(name: "BreakProbe",
                          dependencies: ["BreakdownPhysics", "BreakdownTimeline", "BreakdownLensModel", "BreakdownRules",
                                         "BreakdownAuthored"]),
        .testTarget(name: "BreakdownCoreTests",
                    dependencies: ["BreakdownPhysics", "BreakdownTimeline", "BreakdownLensModel", "BreakdownRules",
                                   "BreakdownAuthored"]),
    ],
    swiftLanguageModes: [.v6]
)
