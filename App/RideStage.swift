// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The Ride hand-over's shared pieces (plans/22-Nov-2026-ride-handover-plan.md, 0.7.6 stream ride). A ride is
//          a short scene in acts, each named in the title row's status slot, with the clock held still while the camera
//          moves so the player never watches two things change at once:
//            mount     the clock held at the strike; the overhead view stays a moment (a ring pulses on the ball about
//                      to be struck, its path dotted to the first ball it hits), then the camera comes down to the
//                      ball, turning about it with the ball pinned on screen, to look down that path from behind.
//            roll      the clock runs; the chase view (ShotCamera) with a thin ring on the ridden ball.
//            hold      the clock held on one of the ride's two beats: the first contact (the hit) and the struck
//                      ball's pocket or stop. The hit's explanation holds with Continue, as a guided replay's does.
//            dismount  the clock held where the rise begins; the camera rises to the overhead view.
//            landed    the ride is over for this shot; the ordinary table view, the clock runs on.
//            rewind    after a trick shot's Watch it: "Now the same shot, slowed down", the clock runs back to the
//                      start while the Lens comes in, then the slow Lens replay starts (the intro's rewind).
//          This file holds the act names (RideAct), what the camera reads each frame (RideCue), the ride's two beats
//          (RideBeats, read once per recording from RidePlan and the captions), the status words (RideWords), the
//          once-only tip's memory (RideTip) and the camera facing the title-row map reads (RideLive).
//          Integration: ShowpieceModel owns the act and its progress (rideAct, rideCue, rideStatus) and advances them in
//          advance(); TableStage hands model.rideCue to TableScene.rideCue each frame, which passes it to ShotCamera;
//          TableScene writes RideLive after the camera moves; RideOverlay (rings, dotted path) and RideMap (the small
//          table map) read the model and RideLive.
// SRP/DRY check: Pass - checked ShowpieceModel's Stage (the opening's stages; a ride lives inside .explore, so its acts
//          are a separate enum), PacePlan (a guided replay's beats; the ride's two beats are not a pace plan, they are
//          held by the ride's own act so a ride never turns the phone layout into a guided Lens replay), TableWords
//          (ball names, reused for the status) and GameSettings (the ride's one remembered flag is kept here, next to
//          the only code that reads it).
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import simd

/// Where a ride is (see the file header). `.none` when no hand-over is running: Ride off, or a ride the model has not
/// started (the opening's slow replay rides without acts, exactly as in 0.7.5).
enum RideAct: Equatable, Sendable {
    case none, mount, roll, hold, dismount, landed, rewind
}

/// What the camera reads from the ride's acts each frame. The clock comes separately (ShotCamera.clock); together they
/// fix the picture, so scrubbing to a time always shows the same camera (the acts the scrub lands in are roll or
/// landed, which depend on the clock alone).
struct RideCue: Equatable, Sendable {
    var act: RideAct
    /// 0 to 1 through the mount or the dismount (real time while the clock is held); 0 in every other act.
    var progress: Double

    /// True when the camera follows the acts (a hand-over ride); false for none and rewind, where ShotCamera keeps
    /// its 0.7.5 behaviour (the rise as a function of the clock alone).
    var handOver: Bool {
        switch act {
        case .mount, .roll, .hold, .dismount, .landed: return true
        case .none, .rewind: return false
        }
    }
}

/// How long the acts that hold the clock take, in real seconds (ShowpieceModel runs them; ShotCamera's self-test steps
/// through them at these lengths).
enum RideTiming {
    /// The mount: a beat on the overhead view, the orbit down, a still beat behind the ball (ShotCamera.mountWeight).
    static let mount = 1.6
    /// The first ride ever mounts more slowly, so the move can be followed the first time (plan work package 9).
    static let firstMount = 2.4
    /// The rise back to the table view.
    static let dismount = 1.3
    /// The rewind before a trick shot's slow Lens replay, as long as the intro's own rewind.
    static let rewind = 1.0
    /// A held beat with nothing to read (no card, Explanations off, or the struck ball simply stopping): long enough to
    /// see the moment, short enough not to feel stuck.
    static let stillHold = 1.0
}

/// One moment a ride stops on. `caption` is nil for a stop with nothing to read (the struck ball coming to rest).
struct RideBeat: Equatable {
    let time: Double
    let caption: Caption?
}

/// The ride's two beats (plan work package 6): the first contact and the struck ball's pocket, or its stop when
/// nothing drops. Every other beat of the shot is skipped while riding. Read once per recording.
enum RideBeats {
    /// - plan: the recording's RidePlan (contact time, first struck ball, the rise).
    /// - captions: the recording's captions (Caption.id is the event index).
    static func make(plan: RidePlan, timeline tl: Timeline, captions: [Caption]) -> [RideBeat] {
        guard plan.rideable, let contact = plan.contactTime else { return [] }
        let cue = plan.cueBall
        func caption(ofEvent i: Int?) -> Caption? { i.flatMap { ev in captions.first { $0.id == ev } } }
        // The hit: the first ball-to-ball event the struck ball is in (the same event RidePlan reads its time from).
        let hit = tl.events.firstIndex { $0.kind == .ballBall && $0.balls.contains { $0.ball == cue } }
        var beats = [RideBeat(time: contact, caption: caption(ofEvent: hit))]
        // The struck ball's end: only when it really travels (RidePlan.objectBall), and before the camera rises, so
        // the hold is seen from the ride. A break's apex ball barely moves, so a break holds the hit alone.
        if let b = plan.objectBall {
            let pocket = tl.events.firstIndex { $0.kind == .pocket && $0.balls.contains { $0.ball == b } }
            let end = tl.pocketTime[b] ?? plan.objectSpan.upperBound
            if end > contact + 0.05, end < plan.riseStart - 1e-6 {
                beats.append(RideBeat(time: end, caption: tl.pocketTime[b] != nil ? caption(ofEvent: pocket) : nil))
            }
        }
        return beats
    }

    /// Where the first struck ball drops, as a hole on the table (nil when it stays up). For the map's ringed pocket.
    static func targetHole(plan: RidePlan, timeline tl: Timeline) -> Vec2? {
        guard let b = plan.firstStruck,
              let e = tl.events.first(where: { $0.kind == .pocket && $0.balls.contains { $0.ball == b } }) else { return nil }
        return tl.table.holeCenter(pocket: e.pocket)
    }
}

/// The ride's words for the title row's status slot.
enum RideWords {
    /// "Riding with the cue ball", "Riding with the yellow": the ball's own name on that table (TableWords, the names
    /// the captions use, so the article comes with the name).
    static func riding(ball: Int, table: TableKind) -> String {
        let name = TableWords.ballName(ball, cueBall: ball, table: table)
        return String(localized: "Riding with \(name)",
                      comment: "Status in the title row while the camera rides with the struck ball; the argument is the ball's name with its article, for example 'the cue ball'")
    }

    static var backToTable: String {
        String(localized: "Back to the table", comment: "Status in the title row while the ride camera rises back to the table view")
    }

    static var slowedDown: String {
        String(localized: "Now the same shot, slowed down",
               comment: "Status in the title row while a trick shot's answer rewinds before its slow Physics Lens replay")
    }

    static var tip: String {
        String(localized: "Tap Ride again for the table view",
               comment: "Shown once in the title row's status, the first time the player rides a shot")
    }
}

/// The once-only tip (plan work package 9): the first ride ever has a longer mount and says how to leave it. Kept in
/// UserDefaults under its own key, like the Lens tips.
enum RideTip {
    static let key = "rideTipShown"

    static var shown: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// What the scene knows that the title-row map needs: which way the camera faces on the table while it rides, and
/// whether the table view is upright (the map is drawn the way the overhead view shows the table). Written by
/// TableScene right after the camera moves each frame; read by RideMap inside its own per-frame redraw. Not observed
/// on purpose: it changes every frame and only views that redraw every frame read it.
@MainActor
final class RideLive {
    static let shared = RideLive()

    /// The camera's look direction in table coordinates (x along the length, y across), unit length; nil while the
    /// ride has no say over the view or the view looks straight down.
    private(set) var facing: Vec2?
    /// True when the table view is taller than wide (an upright phone): the overhead view then runs the table's long
    /// side up the screen.
    private(set) var portrait = true

    private init() {}

    /// - forward: the camera's world look direction this frame. World (x, z) is table (x, -y) (TableFrame.world).
    func update(flying: Bool, forward: SIMD3<Float>, portrait: Bool) {
        self.portrait = portrait
        let flat = Vec2(Double(forward.x), Double(-forward.z))
        facing = flying && flat.length > 1e-4 ? flat.normalized : nil
    }
}
