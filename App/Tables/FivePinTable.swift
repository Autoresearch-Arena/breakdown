// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (filled in from the groundwork stub: the regulation carom table with no
//          pockets, 61.5 mm balls, the five-pin castle at 66 mm, the regulation start, an opening two-cushion shot and
//          the Blender-made pins.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-rules) - the red pin's, the yellow's and the red ball's
//          numbers now come from FivePinRules (BreakdownRules), which scores the game, so the two cannot disagree.
// PURPOSE: Five-pin billiards (Italian "cinque birilli"): a carom table with no
//          pockets, five small turned pins standing in a cross (the "castle") on the centre spot, four white and the
//          red one in the middle, two cue balls (white and yellow) and a red object ball. A player strikes their own
//          ball onto the opponent's ball, which should then topple pins. The table and its props are built here; the
//          scoring is FivePinRules' (BreakdownRules).
//          Facts:
//            - Table: playing surface 2.84 x 1.42 m (plus or minus 5 mm), cushion nose to cushion nose.
//            - Pins: round, 25 mm high, 7 mm across at the base and at the head, 10 mm at the widest part; four white
//              and a red centre pin.
//            - Castle: the red pin on the centre spot, the four white pins 66 mm from it, two along the long string and
//              two across it (the space of a ball between two pins).
//            - Balls: 61.5 mm, 205 to 220 g. The cue ball is white, the opponent's yellow, the object ball red.
//            - Start: the red ball on the "mouche mi-haute" (the spot in the middle of the upper half, three quarters
//              of the way up), the opponent's yellow on the "mouche haute" 10 cm from the upper short cushion, the
//              starting player's white placed freely, entirely inside the lower half.
//            - Estimates (named as such below): the pins' mass (from the Blender model's volume, 1.07 cm3, in turned
//              hardwood or plastic, about 1 g) and their bounce.
//          Pin contact radius: the solver treats a pin as an upright cylinder of radius r that a ball touches when its
//          centre is R + r from the pin's axis. A 61.5 mm ball's centre (30.75 mm up) is ABOVE the 25 mm pin, so the
//          first touch is between the ball's lower surface and the pin's head; worked through the real profile in
//          make_five_pin.py (contact_radius), the touch comes at 33.15 mm from the axis, so r = 2.4 mm, not the
//          10 mm belly. The drawn pin keeps its true shape.
//          Ball slots: index 0 is the white cue ball, index 1 the yellow (the opponent's ball) and index 3 the red (the
//          object ball); every other slot is off the table. Since 0.7.0 they are drawn as plain white, yellow and red
//          balls with no number (TableBallSet.fivePin, drawn by BallTextures; corrected by Claude Opus 5.5 High,
//          21-November-2026, look stream).
//          Opening shot: the white at the edge of its half strikes the yellow a cut on its lower side, so the yellow
//          goes off the short cushion, then the far long cushion, into the castle (two cushions, clear of the red).
//          The aim was tuned on a step-by-step copy of the solver's sliding, rolling, cushion and ball-ball laws; the
//          working window there is about a sixth of a degree wide, so the exact solver may need the aim nudged.
//          Props: Tools/blender/make_five_pin.py makes App/Models/FivePin.usdz (one white and one red pin, each at its
//          own origin); makeProps clones them into the "pin-<k>" holders TableScene topples. Plain code-built pins
//          stand in until the model loads (or if it is missing). Small white spots mark the pin and ball spots.
// SRP/DRY check: Pass - this table's data and props only; the solver features (pins, pockets off) live in BreakdownCore,
//          the dispatch in TableKind.swift, the shared prop helpers (load, dress, plain pins) in TableProps.swift; the
//          pin's shape lives in the Blender script, whose PIN_HEIGHT and SWIFT_CONTACT_R must equal pinHeight and
//          pinContactRadius here.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import RealityKit

enum FivePinTable: TableDefinition {
    /// Playing surface between the cushion noses: 2.84 x 1.42 m.
    static let tableSize = (length: 2.84, width: 1.42)
    /// 61.5 mm carom balls.
    static let ballRadius = 0.0615 / 2
    /// 205 to 220 g: the middle of the range.
    static let ballMass = 0.210
    /// A carom table: no pockets, the cushions run every side.
    static let pocketsEnabled = false
    static let posts: [Post] = []
    static let bedHoles: [BedHole] = []

    // MARK: Pins

    /// 25 mm tall; equal to PIN_HEIGHT in make_five_pin.py. A ball whose lowest point is higher
    /// than this passes over.
    static let pinHeight = 0.025
    /// The effective contact radius against a 61.5 mm ball (see the header); equal to SWIFT_CONTACT_R in
    /// make_five_pin.py, which recomputes it from the drawn profile and fails if the two drift apart.
    static let pinContactRadius = 0.0024
    /// Estimated: 1.07 cm3 (the model's volume) of turned hardwood or plastic, about 1 g.
    static let pinMass = 0.001
    /// Centre-to-centre distance from the red pin to each white pin: 66 mm.
    static let pinSpacing = 0.066
    /// The red pin is pin 0, on the centre spot; the white pins are 1 to 4.
    static let redPinIndex = FivePinRules.redPin

    /// The centre spot, where the red pin stands.
    static var castleCentre: Vec2 { Vec2(tableSize.length / 2, tableSize.width / 2) }

    /// The castle: 0 the red pin on the centre spot, 1 and 2 the white pins along the long string (toward x = 0, then
    /// toward x = L), 3 and 4 across it (toward y = 0, then toward y = W).
    static var pins: [Pin] {
        let c = castleCentre, s = pinSpacing
        let spots = [c, Vec2(c.x - s, c.y), Vec2(c.x + s, c.y), Vec2(c.x, c.y - s), Vec2(c.x, c.y + s)]
        return spots.map { Pin(center: $0, radius: pinContactRadius, mass: pinMass, height: pinHeight) }
    }

    // MARK: Balls and the start

    /// Ball slots: 0 is the white cue ball (drawn ivory), 1 the opponent's yellow (drawn yellow), 3 the red object
    /// ball (drawn red). The lower half (x < L/2) is the white's half; the upper end (x = L) is the yellow's.
    static let opponentBallIndex = FivePinRules.playerBalls[1]
    static let redBallIndex = FivePinRules.redBall

    /// "Mouche mi-haute": the red ball's spot, in the middle of the upper half.
    static var redSpot: Vec2 { Vec2(tableSize.length * 0.75, tableSize.width / 2) }
    /// "Mouche haute": the yellow's spot on the long string, 10 cm from the upper short cushion.
    static var opponentSpot: Vec2 { Vec2(tableSize.length - 0.10, tableSize.width / 2) }
    /// The white is placed freely, wholly inside the lower half: here at the half's edge, 20 cm from the near long
    /// cushion, where the opening shot below plays from.
    static var cueStart: Vec2 { Vec2(tableSize.length / 2 - 0.04, 0.20) }

    /// Sixteen positions, index 0 the cue ball, unused balls at NextShot.offTable.
    static var startLayout: [Vec2] {
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[0] = cueStart
        l[opponentBallIndex] = opponentSpot
        l[redBallIndex] = redSpot
        return l
    }

    /// The white cuts the yellow on its lower side; the yellow runs off the short cushion and the far long cushion into
    /// the castle (see the header: tuned on a copy of the solver's laws, the exact window may sit a little off).
    static let defaultShot = (aimDegrees: 19.14, power: 4.0)

    // MARK: Looks and props

    /// Lacquered turned pins: an ivory white and a deep red, with a clear coat as real lacquered pins have.
    static let whitePinLook = TablePartLook(color: (0.93, 0.91, 0.86), roughness: 0.35, clearcoat: 0.6)
    static let redPinLook = TablePartLook(color: (0.72, 0.07, 0.06), roughness: 0.35, clearcoat: 0.6)
    /// The small white spots stuck on the cloth.
    static let spotLook = TablePartLook(color: (0.92, 0.92, 0.90), roughness: 0.85)

    /// Part name to finish, for the props and the Blender model's named parts.
    static let partLooks: [String: TablePartLook] = [
        "FivePinPinWhite": whitePinLook,
        "FivePinPinRed": redPinLook,
        "FivePinSpot": spotLook,
    ]

    /// The pins (plain cylinders at once, the turned Blender pins when the model has loaded) and the cloth spots.
    @MainActor static func makeProps(_ context: TablePropsContext) -> Entity {
        let props = Entity()
        props.name = "FivePinProps"
        let frame = context.frame

        // Spots: one under each pin (shows once the pin is down) and the red and yellow balls' spots. Each is a disc
        // 0.3 mm thick, so it sits just on the cloth without fighting it for depth.
        let spotMaterial = TableProps.material(spotLook)
        let spotSpots = context.table.pins.map(\.center) + [redSpot, opponentSpot]
        for (i, p) in spotSpots.enumerated() {
            let disc = ModelEntity(mesh: .generateCylinder(height: 0.0003, radius: 0.004), materials: [spotMaterial])
            disc.name = "FivePinSpot-\(i)"
            disc.position = frame.world(p, height: 0.00015)
            props.addChild(disc)
        }

        // Pins: holders named "pin-<k>" with their origin at the pin's base centre (what TableScene topples), each
        // starting with a plain cylinder until the model's turned pin replaces it.
        let holders: [Entity] = context.table.pins.enumerated().map { k, pin in
            let look = k == redPinIndex ? redPinLook : whitePinLook
            let holder = TableProps.plainPin(index: k, pin, frame: frame, look: look)
            props.addChild(holder)
            return holder
        }

        TableProps.loadModel(named: "FivePin", looks: partLooks, into: props, lightSource: context.lightSource) { model in
            guard let white = model.findEntity(named: "FivePinPinWhite"),
                  let red = model.findEntity(named: "FivePinPinRed") else {
                // Not the expected parts: keep the plain pins and hide whatever loaded.
                model.isEnabled = false
                return
            }
            for (k, holder) in holders.enumerated() {
                let part = (k == redPinIndex ? red : white).clone(recursive: true)
                // The part is authored at its own origin (base centre on y = 0, standing along +Y), so it sits at the
                // holder's origin with no offset of its own.
                part.transform = Transform()
                for child in Array(holder.children) { child.removeFromParent() }
                holder.addChild(part)
            }
            // The originals stand at the model's origin (the middle of the table); only the clones are wanted.
            white.removeFromParent()
            red.removeFromParent()
        }
        return props
    }
}
