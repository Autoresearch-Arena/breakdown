// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: One clock for the 3D scene's own easing (Lens clips, 0.7.7, plans/23-Nov-2026-clips-plan.md, Step 1).
//          A few parts of the scene ease in wall time rather than in shot time: the camera's eased framing rectangles
//          and its launch pull-back (TableCamera), the opening's lamp shot, the Ride camera's half-second engage
//          (ShotCamera), the moment framing's gate (MomentFrame), the hand zoom's ease (TableZoom), the held hit's
//          drawing fade (LensLayer) and Ride's faint table floor (TableScene). They all read SceneClock.now instead of
//          the device clock directly.
//          In the live game SceneClock.now IS the device clock (ProcessInfo.systemUptime), so nothing changes.
//          The clip renderer (ClipRenderer) draws a second, offscreen copy of the table one frame at a time, as fast as
//          the device can, so its clock must not be the device's: it pins virtual time (frame number / 30) around its
//          own scene's apply and updateCamera with SceneClock.pinned(at:), and every wall-clock ease in that scene then
//          runs on the clip's clock. The same shot always makes the same film, however fast the device draws it.
//          Why this cannot disturb the live table: everything here is on the main actor and pinned(at:) is synchronous,
//          so the live scene never runs inside a pinned scope (it runs in its own frame callback, between the clip's
//          frames, when the pin has already been put back).
// SRP/DRY check: Pass - checked the scene files for any other clock (no Date, CACurrentMediaTime or ContinuousClock in
//          TableScene, TableCamera, ShotCamera, LensLayer, CueRig, TableDetail, MomentFrame, TableZoom, TableBuilder or
//          CameraFraming); real gestures (StrokeGesture, TableZoom.takeDoubleTap) keep reading the device clock.
import Foundation

@MainActor
enum SceneClock {
    /// The virtual time pinned by the clip renderer, nil in the live game.
    private static var pinnedNow: TimeInterval?

    /// The scene's clock in seconds: the pinned clip time while a clip frame is being placed, else the device's
    /// uptime (what every one of these reads used before 0.7.7).
    static var now: TimeInterval { pinnedNow ?? ProcessInfo.processInfo.systemUptime }

    /// Runs `body` with the scene clock reading `t`, then puts back whatever it read before (nested pins unwind in
    /// order). Synchronous on purpose: nothing else on the main actor can run inside it.
    static func pinned<T>(at t: TimeInterval, _ body: () throws -> T) rethrows -> T {
        let old = pinnedNow
        pinnedNow = t
        defer { pinnedNow = old }
        return try body()
    }
}
