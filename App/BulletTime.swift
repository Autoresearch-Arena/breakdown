// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Bullet time on the hit, the run (plans/23-Nov-2026-bullet-time-plan.md, version 0.7.7). Once in a while, on
//          a rare or powerful ball-to-ball hit in ordinary play (Lens off, Ride not riding), the clock eases down as the
//          ball arrives, stops on the touch for a moment of real time while the camera swings round the two balls and
//          the contact drawing hangs between them, then lets go and speeds back up. This class owns that beat:
//            armed      decided at the strike (arm): the moment is known, and as the clock nears it playback eases down
//                       to an eighth of the chosen speed; the clock is capped at the contact (cap), so the frame that
//                       reaches it crosses the contact event once and the ordinary playback plays its click and tap;
//            holding    the clock stands on the contact for holdSeconds of real time (shorter under Reduce Motion): a
//                       firm haptic, one VoiceOver sentence and the status words (statusWords) at its first frame; the
//                       counter only runs while playing, so a pause (or the menu) pauses the freeze;
//            releasing  the words go, playback eases back up to full speed over releaseClock of clock, and the camera
//                       hands back to the table camera over cameraBackSeconds of real time;
//            done       finished, or ended early (a scrub, a replay, a new shot, the Lens, Ride, leaving the table, the
//                       option): the camera then eases itself back (BulletTimeCamera).
//          No sound is added anywhere: the contact's own click comes from the ordinary playback as the clock crosses it.
//          Integration: ShowpieceModel owns one (bulletTime). finishStrike calls arm(...) last; advance calls frame(...)
//          every frame before its stage switch and multiplies its playback rate by rateFactor(at:) in the plain
//          explore step; step() caps the clock with cap(clock:version:); scrub(to:) calls cancel(); startHighlightRack
//          calls startRack(). TableStage hands `cue` to TableScene each frame (camera, glassy balls, the contact
//          drawing). PhoneTitle, ShowpieceView's header and NotebookPanel's top bar show `statusWords`.
//          Also here: BulletGate (what the model says about the table at the strike), BulletCue (what the scene reads)
//          and BulletWords (the status lines and the spoken sentence).
// SRP/DRY check: Pass - checked PacePlan (the guided Lens hold: its own real-time counter, only with the Lens on; this
//          is a separate, shorter hold that never runs with it), RideStage and ShowpieceModel's ride acts (the ride
//          holds the clock inside its own acts, only with Ride on), SoundBoard.follow (its playback-or-jump allowance
//          is reproduced here exactly, because this must agree with it on what a jump is) and Haptics (the haptic is a
//          new entry point there, freeze(strength:), not a new feel cue). The trigger is BulletTimePick's, the
//          rationing BulletTimeBudget's.
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import Observation
import SwiftUI

/// What the model knows about the table when a shot is struck, for arm(...). The model fills it.
struct BulletGate: Equatable {
    /// True when a freeze could play at all: the opening is over, no lesson, drill, match clock or what-if fork, Ride
    /// not riding, the Lens neither in nor coming.
    let open: Bool
    /// The computer played this shot in a match or table game.
    let computerShot: Bool
    /// Free play is on the table, meaning exactly what the model's break counter means (no match, no authored mode, no
    /// drill), so the first-free-play-break rule never reads a count it does not belong to.
    let freePlay: Bool
    /// Free-play breaks struck this session, this one included.
    let freePlayBreaks: Int
}

/// What the scene reads each frame while a freeze holds or lets go.
struct BulletCue: Equatable {
    let moment: BulletMoment
    /// 0 to 1 through the freeze, real time; 1 once letting go.
    let hold: Double
    /// 0 during the freeze, then 0 to 1 over BulletTime.cameraBackSeconds of real time.
    let release: Double
    /// Reduce Motion as it was when the freeze began: the camera then stays still.
    let reduceMotion: Bool

    /// True while the contact drawing should show (it fades out by itself once this turns false).
    var drawing: Bool { release < 0.5 }

    /// How glassy a ball is drawn, 0 (solid) to 0.6: the two touching balls turn about two-thirds opaque so the lines
    /// through them read (TableScene multiplies 0.55 by it, as it does the melt), easing in over the first part of the
    /// freeze and back out with the release.
    func glass(for ball: Int) -> Float {
        guard ball == moment.striker || ball == moment.object else { return 0 }
        return Float(0.6 * (1 - min(1, max(0, release))) * min(1, max(0, hold / 0.15)))
    }
}

@MainActor
@Observable
final class BulletTime {
    /// Real seconds the clock stands still on the hit, and the shorter freeze under Reduce Motion.
    static let holdSeconds = 1.8
    static let reducedHoldSeconds = 1.2
    /// Clock seconds before the contact over which playback eases down, and after it over which it eases back up.
    static let approachClock = 0.12
    static let releaseClock = 0.3
    /// The slowest playback, as a share of the chosen speed, at the contact.
    static let slowest = 0.125
    /// Real seconds the camera takes to hand back to the table camera after the freeze.
    static let cameraBackSeconds = 0.6
    /// Launch with -noBulletTime (store screenshot runs) and nothing ever freezes.
    static let disabledByLaunch = ProcessInfo.processInfo.arguments.contains("-noBulletTime")

    /// The freeze's length for a Reduce Motion setting.
    static func holdLength(reduceMotion: Bool) -> Double { reduceMotion ? reducedHoldSeconds : holdSeconds }

    /// Where the run is (see the file header).
    enum Phase: Equatable { case idle, armed, holding, releasing, done }

    /// The moment on screen, set for the freeze only (not the approach or the let-go). Observed: the status slots read
    /// it through statusWords.
    private(set) var shown: BulletMoment?

    /// The status line for the title row, the header or the notebook while the clock stands still; nil otherwise.
    var statusWords: String? { shown.map { BulletWords.status($0.kind) } }

    // Not observed: they change every frame, and the scene reads them every frame anyway.
    @ObservationIgnored private var moment: BulletMoment?
    /// The model's timelineVersion the moment was armed for: any other recording ends it.
    @ObservationIgnored private var version = -1
    @ObservationIgnored private(set) var phase: Phase = .idle
    @ObservationIgnored private var holdElapsed = 0.0
    @ObservationIgnored private var releaseElapsed = 0.0
    @ObservationIgnored private var holdLength = BulletTime.holdSeconds
    @ObservationIgnored private var reduceMotionAtFreeze = false
    /// The clock at the last frame() call, and how far forward the next call may find it and still call it playback.
    @ObservationIgnored private var lastClock = 0.0
    @ObservationIgnored private var lastAllowance = Double.infinity
    @ObservationIgnored private var budget = BulletTimeBudget()
    /// What happens at the freeze's first frame: the haptic and the VoiceOver sentence. Tests replace it with a recorder.
    @ObservationIgnored var effects: @MainActor (BulletMoment) -> Void = { BulletTime.playEffects($0) }

    /// The real effects: a firm buzz scaled by the speed into the hit (Haptics.freeze honours the Vibration option and
    /// does nothing without an engine), and one announcement for VoiceOver.
    static func playEffects(_ m: BulletMoment) {
        Haptics.shared.freeze(strength: min(1, m.incomingSpeed / 4))
        AccessibilityNotification.Announcement(BulletWords.spoken(m.kind)).post()
    }

    /// A fresh rack, a new table, a match or a mode: the rack's big cut is available again.
    func startRack() {
        budget.startRack()
    }

    /// The model's hook at the strike (finishStrike, last). Ends anything running, notes the shot, then arms the moment
    /// BulletTimePick finds if the gate is open, the option is on, the launch flag is absent and the budget agrees.
    /// The budget is asked last, so a freeze that cannot play never uses up a cut or sets the hardest break.
    func arm(timeline: Timeline, facts: ShotFacts?, captions: [Caption], isBreak: Bool, version: Int, gate: BulletGate) {
        cancel()
        budget.noteShot()
        guard gate.open, GameSettings.bulletTimeOn, !Self.disabledByLaunch, let facts,
              let m = BulletTimePick.pick(timeline: timeline, facts: facts, captions: captions, isBreak: isBreak),
              budget.shouldPlay(m, computerShot: gate.computerShot, freePlay: gate.freePlay,
                                freePlayBreaks: gate.freePlayBreaks) else { return }
        arm(moment: m, version: version)
    }

    /// Arm a known moment for a recording (also the tests' way in). No option, launch flag or budget check here.
    /// The first frame() after arming can never read as a jump (lastAllowance is infinite), in the app or in a test
    /// that arms at clock 0 and calls frame at 0.5.
    func arm(moment m: BulletMoment, version v: Int) {
        moment = m
        version = v
        phase = .armed
        holdElapsed = 0
        releaseElapsed = 0
        lastClock = 0
        lastAllowance = .infinity
        if shown != nil { shown = nil }
    }

    /// End it at once for this recording (a scrub; frame() uses it for everything else). The camera eases itself back.
    func cancel() {
        phase = .done
        if shown != nil { shown = nil }
    }

    /// The most the clock may reach this step: the contact's time while armed or holding for this recording and the
    /// clock has not passed it, so the frame that reaches it lands exactly on it; infinity otherwise. The clock only
    /// moves forward through it, so the ordinary playback crosses the contact event exactly once.
    func cap(clock: Double, version v: Int) -> Double {
        guard let m = moment, v == version, phase == .armed || phase == .holding, clock <= m.time + 1e-9 else {
            return .infinity
        }
        return m.time
    }

    /// The share of the chosen playback speed at this clock: 1 when idle or done; easing down to `slowest` over the
    /// last approachClock before the contact while armed; easing back up over releaseClock after it while letting go.
    func rateFactor(at clock: Double) -> Double {
        guard let m = moment else { return 1 }
        switch phase {
        case .armed:
            return Self.slowest + (1 - Self.slowest) * Self.smooth((m.time - clock) / Self.approachClock)
        case .holding:
            return Self.slowest
        case .releasing:
            return Self.slowest + (1 - Self.slowest) * Self.smooth((clock - m.time) / Self.releaseClock)
        case .idle, .done:
            return 1
        }
    }

    /// One frame (the model calls it every frame the table runs, before its stage switch). Returns true while the
    /// freeze holds the clock.
    /// - dt: real seconds this frame (already clamped to a twentieth by the model).
    /// - rate: the speed the player chose (chosenRate ?? 1), for the playback allowance.
    /// - allowed: the model's every-frame gate (ordinary table stage, option on, no guided replay, no ride, no Lens
    ///   coming, no what-if); false ends the freeze at once.
    @discardableResult
    func frame(_ dt: Double, clock: Double, playing: Bool, rate: Double, version v: Int, allowed: Bool) -> Bool {
        guard let m = moment, phase == .armed || phase == .holding || phase == .releasing else { return false }
        // Another recording on the table, or the gate closed: over.
        if v != version || !allowed { cancel(); return false }
        // A jump of the clock (a scrub, a replay, a skip): over. The test is SoundBoard.follow's own: the model clamps
        // every step to a twentieth of a second, so a forward step up to that ceiling times the rate, with half again
        // for a rate that changed within the frame, is playback. The ceiling, never this frame's dt: the step being
        // checked was taken with the previous frame's dt, and a long frame followed by a short one is not a jump.
        if clock < lastClock - 1e-9 || clock > lastClock + lastAllowance { cancel(); return false }
        let allowance = max(1, rate) * (1.0 / 20.0) * 1.5 + 1e-4
        defer { lastClock = clock; lastAllowance = allowance }
        switch phase {
        case .armed:
            guard clock >= m.time - 1e-9 else { return false }
            // The clock already past the contact (a skip to the result, a forward scrub inside the allowance): never
            // freeze late. On the contact but paused: wait.
            if clock > m.time + 1e-6 { phase = .done; return false }
            guard playing else { return false }
            reduceMotionAtFreeze = TableCamera.reduceMotion
            holdLength = Self.holdLength(reduceMotion: reduceMotionAtFreeze)
            phase = .holding
            holdElapsed = 0
            shown = m
            effects(m)
            return true
        case .holding:
            if playing { holdElapsed += dt }
            if holdElapsed >= holdLength {
                phase = .releasing
                releaseElapsed = 0
                shown = nil
                return false
            }
            return true
        case .releasing:
            releaseElapsed += dt
            // Done once the camera is home and either the clock is back to full speed or it stopped (a shot that ends,
            // or a pause, inside the let-go must not leave a cue standing).
            if releaseElapsed >= Self.cameraBackSeconds, clock >= m.time + Self.releaseClock || !playing {
                phase = .done
            }
            return false
        case .idle, .done:
            return false
        }
    }

    /// The scene's view of the run: non-nil while holding or letting go.
    var cue: BulletCue? {
        guard let m = moment else { return nil }
        switch phase {
        case .holding:
            return BulletCue(moment: m, hold: min(1, holdElapsed / holdLength), release: 0,
                             reduceMotion: reduceMotionAtFreeze)
        case .releasing:
            return BulletCue(moment: m, hold: 1, release: min(1, releaseElapsed / Self.cameraBackSeconds),
                             reduceMotion: reduceMotionAtFreeze)
        case .idle, .armed, .done:
            return nil
        }
    }

    /// The 0-to-1 smoothstep, clamped.
    private static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }
}

/// Bullet time's words (as RideWords are the ride's): a short status line per kind for the title row, the header or
/// the notebook, and the one sentence VoiceOver hears as the clock stops. No numbers, names or brands.
enum BulletWords {
    static func status(_ kind: BulletKind) -> String {
        switch kind {
        case .hardBreak:
            return String(localized: "All the speed goes into the rack",
                          comment: "Status line in the title row while a hard break is frozen at the moment the cue ball meets the rack; keep it short, one line")
        case .jumpHit:
            return String(localized: "Down from the jump, onto the ball",
                          comment: "Status line in the title row while a jump shot is frozen as the jumping ball meets its ball; keep it short, one line")
        case .curveHit:
            return String(localized: "The curve ends on the ball",
                          comment: "Status line in the title row while a curving (masse) shot is frozen at its hit; keep it short, one line")
        case .kiss:
            return String(localized: "The kiss that sends it in",
                          comment: "Status line in the title row while frozen on the touch between two balls that decides a pocket; keep it short, one line")
        case .bigCut:
            return String(localized: "A thin cut that still sends it in",
                          comment: "Status line in the title row while a thin cut is frozen at the hit, just before the struck ball drops; keep it short, one line")
        }
    }

    /// One localized sentence with one placeholder (the status line), never two pieces joined, so every language
    /// orders it its own way.
    static func spoken(_ kind: BulletKind) -> String {
        let words = status(kind)
        return String(localized: "\(words). Time stops at the hit. The dashed line is the push between the centres, the finer line is the tangent, and the arrows share out the speed.",
                      comment: "Spoken by VoiceOver when the clock stops on a hit; the placeholder is one of the short status lines (for example 'The kiss that sends it in')")
    }
}
