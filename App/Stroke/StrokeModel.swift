// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (integration: authored modes keep the cue's full calm zone with a
//          short bridge finger, found by the first test run).
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: a stance factor beside the bridge one. zones and delivery take
//          the player's Stance (App/Stroke/Reach.swift): each rung lowers the comfortable top swing and multiplies the
//          wander, the rest caps the swing low and stays steady. In trick shots, situations and lessons the stance
//          never lowers the calm top and its wobble goes in before the saturating cap, so authoredAimBound still holds;
//          StrokeDelivery keeps the stance it was played from, for the retry comparison.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, items 3, 4 and 5 of plans/21-Nov-2026-bugs-after-0-6-6-plan.md:
//          the break has its own calm zone a little over half-way up the break range (breakHandStroke), so an ordinary
//          or tapped break is never warm; a finger that stays inside the drawn groove counts as straight (the groove's
//          half-width comes off the wander first, StrokeRecord.grooveHalfWidth) and plays exactly as the keys do; a
//          bridge longer than the automatic one now raises the calm top as the square root of its length, as the stroke
//          plan promised, except on the rest, whose stroke the rest rung sets; strikeZones is the one rule for the
//          zones of a strike in any mode, used by the delivery and the power bar alike.)
// PURPOSE: Swinging hard costs control (plans/21-Nov-2026-stroke-and-power-plan.md). Pure numbers, no views:
//          - StrokeZones: where the calm zone of the power bar ends, from the cue's comfortable top swing, the
//            bridge length, the stance and whether the stroke is a break.
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
//          - The groove: how wide it is drawn and how much of a finger's wander it forgives (grooveHalfWidth,
//            beyondGroove), in one place for the drawing, the texture and the drift.
//          Everything is deterministic: the same stroke, power, bridge and cue always give the same delivery, so a
//          retry with the same input repeats exactly and the retry comparison stays honest.
// SRP/DRY check: Pass - checked StrokeTracker (it measures the wander; the groove the wander is judged against is
//          defined here once), CueProfile (swing and comfortable top swing come from there), Simulation.swift's
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
    /// The drawn groove's half-width as a share of this stroke's on-screen length (StrokeModel.grooveShare): a finger
    /// that stays within it is on the groove, and that much of the wander is not counted. The default is the steady
    /// stroke's share, which is the groove's width on any stroke long enough that the drawing's floor does not widen it.
    var grooveHalfWidth: Double = StrokeModel.steadyWander
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
    /// Metres of real rear-hand travel in a break stroke. A break is struck with the whole body, not the forearm
    /// alone: the shoulder opens and the weight moves forward onto the front foot as the arm comes through, so the
    /// rear hand travels the forearm's quarter metre (handStroke) and nearly twice as much again. From v^2 = 2 a L at
    /// the same comfortable acceleration, a break's calm top is the ordinary one times sqrt(0.70 / 0.25) = 1.67: with
    /// the house cue and the automatic bridge about 11.7 m/s of ball speed, a little over half-way up the break range
    /// (7 to 16). The default break (11 m/s) and anything softer is calm; only a deliberately hard break is warm.
    static let breakHandStroke = 0.70
    /// How much higher a break's calm top sits than an ordinary stroke's (breakHandStroke gives the reason).
    static var breakCalmFactor: Double { (breakHandStroke / handStroke).squareRoot() }
    /// Wander is measured over the last third of the finger's stroke (StrokeTracker), standing for the last third of
    /// the real stroke, the part that steers the tip into the ball.
    static let measuredShare = 1.0 / 3.0
    /// Metres of rear-hand wobble per unit of measured wander: the same share of the real hand's last third.
    static var wobblePerWander: Double { handStroke * measuredShare }
    /// The wander of a good, human stroke: a finger that stays within one fiftieth of its stroke's length of the groove.
    /// The groove is drawn this wide either side of its centre line (StrokeGesture), so "on the groove" means within
    /// it, and the fixed drift of a keyboard, controller or VoiceOver player is this stroke's: an even match with a
    /// touch player who keeps the finger in the groove.
    static let steadyWander = 0.02
    /// On-screen points: the narrowest the groove is ever drawn either side of its centre line, so it can still be
    /// seen on a short stroke (the drawing and the texture in StrokeGesture use the same floor).
    static let grooveFloor = 3.0

    // MARK: The groove

    /// On-screen points either side of the groove's centre line for a stroke of this on-screen length: the steady
    /// stroke's share of the length, never under the floor. The one width the groove is drawn, felt and judged by.
    static func grooveHalfWidth(strokeLength: Double) -> Double {
        max(grooveFloor, steadyWander * max(strokeLength, StrokeTracker.shortestStroke))
    }

    /// The groove's half-width as a share of the stroke's on-screen length, the unit the wander is measured in
    /// (StrokeTracker.wander divides the sideways offset by the same length). On a short stroke the drawing's floor
    /// makes this wider than steadyWander, and the finger is forgiven exactly what it can see.
    static func grooveShare(strokeLength: Double) -> Double {
        guard strokeLength > 0 else { return steadyWander }
        return grooveHalfWidth(strokeLength: strokeLength) / strokeLength
    }

    /// The wander past the groove's edge, signed like the wander: zero for a finger that stayed inside the groove,
    /// which is a straight stroke as far as the cue is concerned.
    static func beyondGroove(_ wander: Double, halfWidth: Double) -> Double {
        let off = abs(wander) - max(0, halfWidth)
        guard off > 0 else { return 0 }
        return wander < 0 ? -off : off
    }

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

    /// The calm zone for a cue, a bridge, a stance and a break. The backswing cannot run longer than the cue's travel
    /// through the bridge, and from v^2 = 2 a L a swing reached over a shorter stroke tops out lower, as the square
    /// root of the length. So a bridge shorter than the automatic one lowers the calm top and a longer one raises it
    /// the same way, up to the longest bridge in range (sqrt(0.35 / 0.20) = 1.32): the trade the stroke plan promised,
    /// a long bridge lets you swing harder before the warm zone while each wobble moves the tip further (lever). The
    /// rest gets no raise: the cue rides on the rest's fixed head, and how hard a stroke over it can go is the rest
    /// rung's own swing factor (Reach), stated against the cue's comfortable top. The stance (Reach) scales the top by
    /// its swing factor: a stretched, twisted or seated body, or a rest, cannot swing as hard as a square stance before
    /// control goes. A break's top is raised by breakCalmFactor (the whole body drives a break). No stance (nil) is
    /// the square stance, factor one; isBreak false is an ordinary stroke.
    static func zones(cue: CueProfile, bridge: Double, stance: Stance? = nil, isBreak: Bool = false) -> StrokeZones {
        let length = min(max(bridge, 0), bridgeRange.upperBound)
        let ratio = (length / automaticBridge).squareRoot()
        let reach = stance?.rung == .rest ? min(1, ratio) : ratio
        var calm = cue.comfortableTopSwing * reach
        if isBreak { calm *= breakCalmFactor }
        guard let stance else { return StrokeZones(calmTopSwing: calm) }
        return StrokeZones(calmTopSwing: calm * stance.swingFactor)
    }

    /// The zones a strike in the mode on the table is judged by: the one rule the delivery and the power bar share, so
    /// the bar's calm mark is where the strike's calm zone ends. In a trick shot, situation or lesson a short bridge
    /// finger does not lower the calm top and the stance never moves it: every authored answer was made at a power
    /// inside the cue's own calm zone, and a shortened zone would put the hardest of them (The Called Break) in the
    /// warm part, where drift is uncapped and the shot could no longer be made. (The rest rung, the lowest cap of
    /// all, is exactly the trick shots that need the mechanical bridge.)
    static func strikeZones(cue: CueProfile, bridge: Double, stance: Stance?, authored: Bool,
                            isBreak: Bool = false) -> StrokeZones {
        zones(cue: cue, bridge: authored ? max(bridge, automaticBridge) : bridge, stance: authored ? nil : stance,
              isBreak: isBreak)
    }

    /// The lever from rear hand to tip: tip-to-bridge over bridge-to-hand.
    static func lever(bridge: Double) -> Double { bridge / max(1e-6, tipToRearHand - bridge) }

    // MARK: The delivery

    /// Rear-hand wobble, metres, signed (positive: the hand to the shooter's right). Two parts added together:
    ///  - The steady stroke's: steadyWander times wobblePerWander times warmth, so nothing in the calm zone and, past
    ///    it, the strain every stroke shows. Its side is fixed: under strain a right-handed stroke's elbow swings out
    ///    and the rear hand drifts right. This is all a keyboard, controller or VoiceOver stroke has, and all a finger
    ///    has that stayed inside the drawn groove: a finger on the groove plays exactly as the keys do.
    ///  - A finger stroke's own: the wander past the groove's edge (beyondGroove: the groove's half-width comes off
    ///    first), steadied by the rhythm, times wobblePerWander, times (1 + warmth). In a trick shot, situation or
    ///    lesson that part is capped smoothly below authoredWobbleCap in the calm zone (it rises with the wander but
    ///    never reaches the cap) and only its warm part is uncapped.
    ///  `stanceWobble` (Stance.wobbleFactor, one for a square stance) multiplies the wander itself, before the
    ///  authored modes' saturating cap, so an awkward stance reaches the cap sooner but never passes it.
    static func wobble(swing: Double, zones: StrokeZones, record: StrokeRecord?, authored: Bool,
                       stanceWobble: Double = 1) -> Double {
        let warmth = zones.warmth(swing: swing)
        let steady = steadyWander * stanceWobble * wobblePerWander * warmth
        guard let r = record else { return steady }
        let w = beyondGroove(r.wander, halfWidth: r.grooveHalfWidth) * r.rhythm * stanceWobble
        let plain = w * wobblePerWander
        if !authored { return plain * (1 + warmth) + steady }
        // Saturating calm part: cap * x / (1 + x), x the wander past the groove in units of a steady stroke. Zero at
        // zero, rising with the wander, always below the cap; signed like the wander.
        let x = abs(w) / steadyWander
        let calm = authoredWobbleCap * x / (1 + x) * (w < 0 ? -1 : 1)
        return calm + plain * warmth + steady
    }

    /// The delivery for one strike. `power` is the model's power (house-cue-equivalent launch speed), `fraction` where
    /// it sits on the power bar (0 to 1), `record` the finger stroke if one was made for this power, `stance` where the
    /// player stood and leaned (nil: a square stance, as before the reach work), `isBreak` true for a rack break (its
    /// own calm zone, breakHandStroke).
    static func delivery(power: Double, fraction: Double, record: StrokeRecord?, bridge: Double, cue: CueProfile,
                         authored: Bool, stance: Stance? = nil, isBreak: Bool = false) -> StrokeDelivery {
        let swing = CueProfile.swing(forPower: power)
        // The zones by the mode's rule (strikeZones). The lever still uses the real bridge; authoredWobbleCap already
        // allows for the longest one. The stance's wobble factor goes in before the saturating cap (wobble), so the
        // bound still holds on every rung.
        let zones = strikeZones(cue: cue, bridge: bridge, stance: stance, authored: authored, isBreak: isBreak)
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
