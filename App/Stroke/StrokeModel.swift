// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (integration: authored modes keep the cue's full calm zone with a
//          short bridge finger, found by the first test run).
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: a stance factor beside the bridge one. zones and delivery take
//          the player's Stance (App/Stroke/Reach.swift): each rung lowers the comfortable top swing and multiplies the
//          wander, the rest caps the swing low and stays steady. In trick shots, situations and lessons the stance
//          never lowers the calm top and its wobble goes in before the saturating cap, so authoredAimBound still holds;
//          StrokeDelivery keeps the stance it was played from, for the retry comparison.)
// PURPOSE: Swinging hard costs control (plans/21-Nov-2026-stroke-and-power-plan.md). Pure numbers, no views:
//          - StrokeZones: where the calm zone of the power bar ends, from the cue's comfortable top swing and the
//            bridge length.
//          - StrokeRecord: a measured finger stroke (how far it wandered off the groove, how steady its rhythm was,
//            where the bridge finger rested, the trace), made by StrokeTracker.
//          - StrokeDelivery: what the stroke did to the strike: a small aim error and a small tip-placement error,
//            applied to the CueStrike before it is solved. Kept on the shot's attempt with the stroke it came from.
//          - StrokeModel.delivery: the curve. Drift is a sideways wobble of the rear hand; the cue turns about the
//            bridge, so the tip moves by the wobble times tip-to-bridge over bridge-to-hand and the cue's direction
//            turns by the wobble over bridge-to-hand (the lever in the cues-and-bridges plan). Past the calm zone the
//            wobble grows as the square of the swing over the calm limit: to reach a faster swing in the same stroke
//            length the arm accelerates harder, as the square of the speed (v^2 = 2 a L), and a push's sideways error
//            grows in proportion to how hard it pushes. So the drift grows faster than the speed.
//          Everything is deterministic: the same stroke, power, bridge and cue always give the same delivery, so a
//          retry with the same input repeats exactly and the retry comparison stays honest.
// SRP/DRY check: Pass - checked CueProfile (swing and comfortable top swing come from there), Simulation.swift's
//          strike (the miscue limit is PoolParameters.miscueOffsetLimit, not recomputed here), ShotComparison (the
//          0.15 degree aim threshold for "worth saying" is reused by StrokeWords, not here) and CueRig (the mechanical
//          bridge's 0.30 m setback, restated below because CueRig is a main-actor type).
import BreakdownLensModel
import BreakdownPhysics
import Foundation

/// A measured finger stroke, as the model needs it for the next strike.
struct StrokeRecord: Equatable, Sendable {
    /// Sideways wander off the groove over the last third of the stroke, as a share of the stroke's on-screen length,
    /// signed: positive is the finger to the shooter's right of the groove.
    var wander: Double
    /// Steadiness from practice strokes: 1 with no practice or an uneven rhythm, down to 2/3 when the final stroke
    /// keeps the practice rhythm (StrokeTracker.rhythmFactor).
    var rhythm: Double
    /// Metres from the bridge finger to the cue ball, clamped to StrokeModel.bridgeRange; nil when no second finger
    /// rested on the cloth (the automatic bridge is used).
    var bridge: Double?
    /// The power (house-cue-equivalent launch speed) this stroke set. A later change of power by any other route (the
    /// bar, a slider, the keys) means this stroke is no longer the one being played, and the fixed drift applies.
    var power: Double
    /// The finger's path on the cloth, table metres, for the faint trace in the replay.
    var trace: [Vec2]
    /// The stroke's shape for the drill card: x is the share of the stroke's length behind the start, y the sideways
    /// offset as a share of that length (positive right). Device-independent.
    var shape: [Vec2]
    /// Back-and-forth strokes made before the final one (they do not shoot).
    var practiceStrokes: Int
}

/// The calm zone of the power bar.
struct StrokeZones: Equatable, Sendable {
    /// The top of the calm zone, metres per second of tip speed (swing).
    let calmTopSwing: Double

    /// How far past the calm zone a swing is: 0 inside it, then (swing / calm top)^2 - 1, so 0 at the edge and growing
    /// faster than the swing (the curve's reason is in the file header).
    func warmth(swing: Double) -> Double {
        guard calmTopSwing > 0, swing > calmTopSwing else { return 0 }
        let r = swing / calmTopSwing
        return r * r - 1
    }

    /// The top of the calm zone as a power setting (house-cue-equivalent launch speed), for the power bar.
    var calmTopPower: Double { CueProfile.power(forSwing: calmTopSwing) }
}

/// What the stroke did to one strike. Applied before solving; kept on the attempt.
struct StrokeDelivery: Equatable, Sendable {
    /// Radians the cue's direction turned, positive counter-clockwise on the table plan (to the shooter's left).
    var aimError: Double
    /// Metres the tip landed to the right (+) or left (-) of where it was aimed on the cue ball.
    var tipSideError: Double
    /// The swing, metres per second of tip speed, and the calm top it was judged against.
    var swing: Double
    var calmTopSwing: Double
    /// True at nine tenths of the power bar or more: the result line says "Full power".
    var fullPower: Bool
    /// The bridge length used, metres.
    var bridge: Double
    /// The finger stroke this came from; nil for the fixed drift (keyboard, controller, VoiceOver, sliders).
    var record: StrokeRecord?
    /// True when the drift alone carried an offset that was inside the tip's grip past it (generation two only):
    /// the stroke made the miscue. Set by the model, which knows the physics generation.
    var pushedPastGrip = false
    /// Where the player stood and leaned for this strike (Reach); nil when no stance was worked out (a strike with no
    /// cue ball on the table to stand behind). The retry comparison names a change of stance from it.
    var stance: Stance? = nil

    /// No drift at all: applying it changes nothing.
    var isZero: Bool { aimError == 0 && tipSideError == 0 }
    /// Past the calm zone.
    var warm: Bool { swing > calmTopSwing }
    /// The trace to draw in the replay (empty for the fixed drift).
    var trace: [Vec2] { record?.trace ?? [] }

    /// Turn the strike's direction by the aim error and move its side offset by the tip error. Exactly nothing for a
    /// zero delivery, so a calm keyboard shot is bit for bit the shot it always was. The side offset is kept within
    /// nine tenths of the radius: a tip cannot land further out than the ball's face it can still reach, and past
    /// the grip limit the solver's miscue rule (generation two) already takes over long before that.
    func apply(to strike: inout CueStrike, ballRadius: Double) {
        guard !isZero else { return }
        if aimError != 0 {
            let c = cos(aimError), s = sin(aimError)
            let d = strike.direction
            strike.direction = Vec2(d.x * c - d.y * s, d.x * s + d.y * c)
        }
        if tipSideError != 0 {
            let limit = 0.9 * ballRadius
            strike.tipSide = min(max(strike.tipSide + tipSideError, -limit), limit)
        }
    }
}

enum StrokeModel {
    /// Metres from the cue's tip to the rear hand: the 1.47 m cue (CueRig's model, tip to butt) held about a quarter
    /// of its length from the butt, where a player's rear hand sits on the wrap.
    static let tipToRearHand = 1.10
    /// Metres from the bridge hand to the cue ball when no second finger sets it: an ordinary hand bridge, a little
    /// over a hand's span behind the ball.
    static let automaticBridge = 0.20
    /// Metres: the mechanical bridge's head stands this far behind the cue ball (CueRig.bridgeSetback; restated here
    /// because CueRig is a main-actor type and this file is not).
    static let mechanicalBridge = 0.30
    /// The bridge finger's sensible range, metres: shorter than a hand's width the bridge hand would sit on the ball;
    /// longer than a full stretch over the cloth no player reaches.
    static let bridgeRange = 0.10...0.35
    /// Metres of real rear-hand travel in a full stroke: a forearm's swing from the elbow, about a quarter metre.
    static let handStroke = 0.25
    /// Wander is measured over the last third of the finger's stroke (StrokeTracker), standing for the last third of
    /// the real stroke, the part that steers the tip into the ball.
    static let measuredShare = 1.0 / 3.0
    /// Metres of rear-hand wobble per unit of measured wander: the same share of the real hand's last third.
    static var wobblePerWander: Double { handStroke * measuredShare }
    /// The wander of a good, human stroke: a finger that stays within one fiftieth of its stroke's length of the groove.
    /// The groove is drawn this wide (StrokeGesture), so "on the groove" means within it, and the fixed drift of a
    /// keyboard, controller or VoiceOver player is this stroke's: an even match with a touch player who keeps the
    /// finger in the groove.
    static let steadyWander = 0.02

    // MARK: The bound that keeps authored shots makeable

    /// The largest aim error, radians, any calm stroke may make in a trick shot, a Behind the 8-Ball situation or a
    /// lesson: a hundredth of a degree.
    /// Checked against the measured windows (TrickShots.swift and EightBallSituations.swift comments, 21-Nov-2026):
    /// the tightest aim window is Behind the 8-Ball's escape at -133.25 to -133.19 degrees, a half-width of 0.03
    /// degrees, then The Called Break's 0.10; a hundredth is a third of the tightest. The tip error that comes with it
    /// is at most this angle times the longest bridge, 1.745e-4 x 0.35 = 0.061 mm, against tip windows measured on a
    /// 0.5 mm grid whose single-point ("only") windows are taken as a quarter of a millimetre either side: under a
    /// quarter of the finest. Power is never drifted, so the speed windows are untouched. Every authored solution and
    /// window sits inside the calm zone (the hardest, The Called Break, 6.45 m/s with its window to 6.60, against the
    /// calm top of 7.0 with the house cue and automatic or mechanical bridge), so the warm part adds nothing there.
    static let authoredAimBound = 0.01 * Double.pi / 180
    /// The rear-hand wobble that makes authoredAimBound at the longest bridge (the hand closest to it), so no bridge
    /// in range can exceed the bound.
    static var authoredWobbleCap: Double { authoredAimBound * (tipToRearHand - bridgeRange.upperBound) }

    // MARK: Zones

    /// The bridge length to use: the bridge finger's when one rested on the cloth, clamped to the range; the
    /// mechanical bridge's setback for a shot played off it; otherwise the automatic hand bridge.
    static func bridgeLength(finger: Double?, mechanical: Bool) -> Double {
        if mechanical { return mechanicalBridge }
        guard let f = finger else { return automaticBridge }
        return min(max(f, bridgeRange.lowerBound), bridgeRange.upperBound)
    }

    /// The calm zone for a cue, a bridge and a stance. A bridge shorter than the automatic one caps the comfortable
    /// swing: the backswing cannot run longer than the cue's travel through the bridge, and from v^2 = 2 a L a swing
    /// reached over a shorter stroke tops out lower, as the square root of the length. A longer bridge does not raise
    /// it past the cue's own comfortable top. The stance (Reach) scales it down again by its swing factor: a stretched,
    /// twisted or seated body, or a rest, cannot swing as hard as a square stance before control goes. No stance (nil)
    /// is the square stance, factor one, so every caller that does not pass one is unchanged bit for bit.
    static func zones(cue: CueProfile, bridge: Double, stance: Stance? = nil) -> StrokeZones {
        let cap = min(1, (max(bridge, 0) / automaticBridge).squareRoot())
        let calm = cue.comfortableTopSwing * cap
        guard let stance else { return StrokeZones(calmTopSwing: calm) }
        return StrokeZones(calmTopSwing: calm * stance.swingFactor)
    }

    /// The lever from rear hand to tip: tip-to-bridge over bridge-to-hand.
    static func lever(bridge: Double) -> Double { bridge / max(1e-6, tipToRearHand - bridge) }

    // MARK: The delivery

    /// Rear-hand wobble, metres, signed (positive: the hand to the shooter's right).
    ///  - A finger stroke: its wander (steadied by the rhythm) times wobblePerWander, times (1 + warmth), so the calm
    ///    zone has the plain wander and the warm zone multiplies it by (swing / calm top)^2. In a trick shot,
    ///    situation or lesson the calm part is capped smoothly below authoredWobbleCap (it rises with the wander but
    ///    never reaches the cap) and only the warm part is uncapped.
    ///  - No finger stroke: the steady stroke's wobble times warmth alone, so nothing in the calm zone. Its side is
    ///    fixed: under strain a right-handed stroke's elbow swings out and the rear hand drifts right.
    ///  `stanceWobble` (Stance.wobbleFactor, one for a square stance) multiplies the wander itself, before the
    ///  authored modes' saturating cap, so an awkward stance reaches the cap sooner but never passes it.
    static func wobble(swing: Double, zones: StrokeZones, record: StrokeRecord?, authored: Bool,
                       stanceWobble: Double = 1) -> Double {
        let warmth = zones.warmth(swing: swing)
        guard let r = record else { return steadyWander * stanceWobble * wobblePerWander * warmth }
        let w = r.wander * r.rhythm * stanceWobble
        let plain = w * wobblePerWander
        if !authored { return plain * (1 + warmth) }
        // Saturating calm part: cap * x / (1 + x), x the wander in units of a steady stroke. Zero at zero, rising with
        // the wander, always below the cap; signed like the wander.
        let x = abs(w) / steadyWander
        let calm = authoredWobbleCap * x / (1 + x) * (w < 0 ? -1 : 1)
        return calm + plain * warmth
    }

    /// The delivery for one strike. `power` is the model's power (house-cue-equivalent launch speed), `fraction` where
    /// it sits on the power bar (0 to 1), `record` the finger stroke if one was made for this power, `stance` where the
    /// player stood and leaned (nil: a square stance, as before the reach work).
    static func delivery(power: Double, fraction: Double, record: StrokeRecord?, bridge: Double, cue: CueProfile,
                         authored: Bool, stance: Stance? = nil) -> StrokeDelivery {
        let swing = CueProfile.swing(forPower: power)
        // In a trick shot, situation or lesson a short bridge finger does not lower the calm top: every authored
        // answer was made at a power inside the cue's own calm zone, and a shortened zone would put the hardest of
        // them (The Called Break) in the warm part, where drift is uncapped and the shot could no longer be made.
        // The lever still uses the real bridge; authoredWobbleCap already allows for the longest one.
        // The stance is held to the same rule for the same reason: there it never lowers the calm top (the rest rung,
        // the lowest cap of all, is exactly the trick shots that need the mechanical bridge), and its wobble factor
        // goes in before the saturating cap (wobble), so the bound still holds on every rung.
        let zones = zones(cue: cue, bridge: authored ? max(bridge, automaticBridge) : bridge,
                          stance: authored ? nil : stance)
        let e = wobble(swing: swing, zones: zones, record: record, authored: authored,
                       stanceWobble: stance?.wobbleFactor ?? 1)
        // The rear hand to the right turns the cue about the bridge: the tip goes left and the cue points left
        // (counter-clockwise on the table plan, a positive aim error).
        let aim = e / max(1e-6, tipToRearHand - bridge)
        let tip = -e * lever(bridge: bridge)
        return StrokeDelivery(aimError: aim, tipSideError: tip, swing: swing, calmTopSwing: zones.calmTopSwing,
                              fullPower: fraction >= 0.9, bridge: bridge, record: record, stance: stance)
    }
}
