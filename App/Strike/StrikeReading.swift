// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The strike panel's link to the game (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stages 2 to 4).
//          - ShowpieceModel.plannedStrike: the figures (StrikeFigures) of the strike the controls are set to now, built
//            exactly as fireStroke builds the strike (aim, launch speed for the cue in hand, tip, the struck cue angle
//            strikeElevation, the striking ball) on the table and physics generation the next solve uses.
//          - StrikeReading.comparison(for:): planned against delivered for a played attempt. The delivered strike is the
//            attempt's own CueStrike (the drift already applied); the planned one is the same strike with the stroke's
//            aim error turned back and the tip put back where the player set it. The struck cue angle is the same in
//            both (the clearing raise is not the stroke's error), so it never shows as a difference.
//          - StrikeMemory: the control values at the moment the last strike was recorded (written by one marked line in
//            ShowpieceModel.finishStrike). While the controls still read exactly so, the panel shows planned against
//            delivered for that shot; the first touch of any control turns it back to the live plan.
//          - The cue angle's lock: cueAngleLockedByMode (a trick shot or a Behind the 8-Ball situation sets its own
//            angle; wave 2's daily shot adds itself here, one line) and cueAngleIsPlayers, read by the model's
//            activeElevation setter, the Pencil (StrokeGesture.raisedCueOpen), the dial, the typed entry and the hint.
//          - StylusPresence: whether the Pencil has touched the table on this device (set by StrokeGesture), for the
//            hint's Pencil line.
//          - ShootSide and the shootSide environment value: which bottom corner Shoot sits in. Right by default; the
//            left-handed option (wave 2, Everyone can play) flips it with one .environment(\.shootSide, .left).
// SRP/DRY check: Pass - checked ShowpieceModel (fireStroke/shootNow's strike construction, mirrored here, not changed;
//          ControlValues reused for "nothing touched since"), StrokeGesture.raisedCueOpen (its rule moved here so the
//          Pencil and the panel share one), AimGeometry (launchParameters is private there; the same two lines here).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Observation
import SwiftUI

// MARK: The cue angle's owner

extension ShowpieceModel {
    /// True while the mode on the table sets the cue angle itself, so the player may see it but not change it: a trick
    /// shot or a Behind the 8-Ball situation (each authored answer was measured with exactly its own angle).
    /// WAVE 2 HOOK: a mode that sets its own angle (the daily shot) adds itself here with one `||` line; the Pencil,
    /// the dial, the menu, the typed entry, the sliders and the hint's Pencil line all follow.
    var cueAngleLockedByMode: Bool {
        trickMode.isActive || eightBallMode.isActive
    }

    /// True when the next shot's cue angle is the player's to set: a shot (a break is always level), no mode setting
    /// its own angle, and no lesson step holding the angle.
    var cueAngleIsPlayers: Bool {
        !racked && !cueAngleLockedByMode && openControls.contains(.elevation)
    }

    /// The parameters the strike is worked out with: the table's (ball size and mass, the cue's mass, the grip) at the
    /// generation the next solve uses. The cloth does not change the launch, so the surface is left out (as in
    /// AimGeometry's launch).
    var strikeParameters: PoolParameters {
        var p = physicsTable.parameters
        p.modelGeneration = activeModelGeneration
        return p
    }

    /// The figures of the strike the controls are set to now: the same strike fireStroke would solve before the
    /// stroke's drift (aim, launch speed for the cue in hand, tip, the struck cue angle, the striking ball). Nil with
    /// no full layout or no striking ball on the table.
    var plannedStrike: StrikeFigures? {
        guard layout.count == 16, layout.indices.contains(strikeBall), NextShot.isOnTable(layout[strikeBall]) else {
            return nil
        }
        let strike = CueStrike(direction: aimDirection, speed: cueInHand.launchSpeed(forPower: activePower),
                               tipUp: activeTipUp, tipSide: activeTipSide, elevation: strikeElevation,
                               ballIndex: strikeBall)
        return StrikeFigures.make(strike: strike, swing: CueProfile.swing(forPower: activePower),
                                  parameters: strikeParameters, layout: layout, table: timeline.table)
    }
}

// MARK: Planned against delivered

enum StrikeReading {
    /// What the panel shows: the live plan, or the last shot's plan beside what the stroke delivered.
    enum Reading: Equatable {
        case live(StrikeFigures)
        case played(StrikeComparison)
    }

    /// The reading for the panel now. Planned against delivered while the last recorded strike is the one on screen and
    /// no control has moved since it was struck; otherwise the live plan; nil when there is nothing to strike.
    @MainActor
    static func current(_ model: ShowpieceModel) -> Reading? {
        if let attempt = model.currentAttempt, StrikeMemory.shared.isUntouched(model) {
            return .played(comparison(for: attempt))
        }
        return model.plannedStrike.map { .live($0) }
    }

    /// Planned against delivered for a played attempt. The delivered strike is the attempt's input strike (the stroke's
    /// drift is already in it); the planned one turns the aim error back and puts the tip where the player set it.
    static func comparison(for attempt: ShotAttempt) -> StrikeComparison {
        let delivered = attempt.input.strike
        var planned = delivered
        if let stroke = attempt.stroke, !stroke.isZero {
            // StrokeDelivery.apply turned the direction by +aimError; turn it back.
            let c = cos(-stroke.aimError), s = sin(-stroke.aimError)
            let d = delivered.direction
            planned.direction = Vec2(d.x * c - d.y * s, d.x * s + d.y * c)
        }
        planned.tipUp = attempt.tipUp
        planned.tipSide = attempt.tipSide
        var p = attempt.table.parameters
        p.modelGeneration = attempt.generation
        // The swing is the stroke's own when there was one (it is what the player swung), else the power's.
        let swing = attempt.stroke?.swing ?? CueProfile.swing(forPower: attempt.power)
        let table = attempt.timeline.table
        return StrikeComparison(
            planned: StrikeFigures.make(strike: planned, swing: swing, parameters: p, layout: attempt.start, table: table),
            delivered: StrikeFigures.make(strike: delivered, swing: swing, parameters: p, layout: attempt.start,
                                          table: table))
    }
}

extension StrikeReading {
    /// The upright phone's explanation of the strike itself (the caption of the cue-strike event) with one more line
    /// when the stroke changed the strike: the largest error only (StrikeWords.largestErrorLine). Any other caption, or
    /// a strike the stroke did not change, keeps its sentence as it was. Nil when there is nothing to say.
    @MainActor
    static func withPhoneLine(_ detail: String, caption: Caption, model: ShowpieceModel) -> String? {
        let base = detail.isEmpty ? nil : detail
        let events = model.timeline.events
        guard events.indices.contains(caption.id), events[caption.id].kind == .cueStrike,
              let attempt = model.currentAttempt, attempt.timeline.events.count == events.count,
              let line = StrikeWords.largestErrorLine(comparison(for: attempt)) else { return base }
        return [base, line].compactMap { $0 }.joined(separator: " ")
    }
}

/// The control values when the last strike was recorded, and the recording it belongs to. Written once per strike by
/// ShowpieceModel.finishStrike (one marked line); read by StrikeReading.current. Observed, so the panel switches from
/// "planned against delivered" back to the live plan the moment a control moves.
@MainActor
@Observable
final class StrikeMemory {
    static let shared = StrikeMemory()

    private(set) var controls: ShowpieceModel.ControlValues?
    private(set) var timelineVersion = -1

    /// Called right after a strike's attempt is recorded, with the controls as they stood for it.
    func struck(controls: ShowpieceModel.ControlValues, timelineVersion: Int) {
        self.controls = controls
        self.timelineVersion = timelineVersion
    }

    /// True while the recording on screen is the last one struck and every control still reads as it did then.
    func isUntouched(_ model: ShowpieceModel) -> Bool {
        guard let controls, timelineVersion == model.timelineVersion else { return false }
        return controls == model.controlValues
    }
}

// MARK: The Pencil

/// Whether the Pencil has touched the table on this device. Set by StrokeGesture on the first Pencil event; kept on the
/// device, so the hint's Pencil line shows from the next launch on as well. Read by StrikeHint.
@MainActor
@Observable
final class StylusPresence {
    static let shared = StylusPresence()
    static let key = "pencilSeen"

    private(set) var seen = UserDefaults.standard.bool(forKey: StylusPresence.key)

    /// A Pencil event arrived. Writes only the first time, so the stroke's every-frame events cost nothing.
    func noteSeen() {
        guard !seen else { return }
        seen = true
        UserDefaults.standard.set(true, forKey: Self.key)
    }
}

// MARK: Which hand

/// The bottom corner Shoot sits in on the big-screen shot panel: nearest a right hand by default.
enum ShootSide: Sendable {
    case right, left
}

extension EnvironmentValues {
    /// Which bottom corner Shoot takes on the big-screen shot panel (ShotPanel's roomy layouts). WAVE 2 HOOK: the
    /// left-handed option sets `.environment(\.shootSide, .left)` on the panel; nothing else needs to change.
    @Entry var shootSide: ShootSide = .right
}
