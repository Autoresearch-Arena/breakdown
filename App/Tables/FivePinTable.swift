// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (filled in from the groundwork stub: the regulation carom table with no
//          pockets, 61.5 mm balls, the five-pin castle at 66 mm, the regulation start, an opening two-cushion shot and
//          the Blender-made pins.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-rules) - the red pin's, the yellow's and the red ball's
//          numbers now come from FivePinRules (BreakdownRules), which scores the game, so the two cannot disagree.
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 polish P3: the pins and the castle read from the playing
//          camera on a phone. Brighter, higher-contrast pin finishes (a near-white and a clear red), the code-built
//          stand-in pins drawn at the pin's true 10 mm width instead of the 4.8 mm contact width, and a faint castle
//          mark on the cloth: a thin ring just outside the outer pins and a soft disc under each pin, a translucent
//          lightening of whatever surface is down. Visual only: pins, positions, radii, heights and every parameter are
//          as they were, so every five-pin shot solves exactly as before.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: the solver numbers (size, balls, posts, pins, holes,
//          start) moved unchanged to the package, BreakdownAuthored/AuthoredTables.swift (AuthoredTables.FivePin), and are read
//          from there, so BreakProbe can solve and check a shot of the day on this table; looks and props stay here.)
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
//          pinContactRadius here. The castle mark's flat mesh is built with TableMeshes' MeshBuilder (read, not copied).
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import RealityKit

enum FivePinTable: TableDefinition {
    // 0.7.10 bank: every solver number below is read from the package (BreakdownAuthored, AuthoredTables.FivePin),
    // where it moved unchanged with its reasons, so BreakProbe solves and checks a shot of the day on this table with
    // the very same numbers. This file keeps the looks, the castle mark and the props.
    private typealias Numbers = AuthoredTables.FivePin

    /// Playing surface between the cushion noses: 2.84 x 1.42 m.
    static let tableSize = Numbers.size
    /// 61.5 mm carom balls.
    static let ballRadius = Numbers.ballRadius
    /// 205 to 220 g: the middle of the range.
    static let ballMass = Numbers.ballMass
    /// A carom table: no pockets, the cushions run every side.
    static let pocketsEnabled = false
    static let posts: [Post] = []
    static let bedHoles: [BedHole] = []

    // MARK: Pins

    /// 25 mm tall; equal to PIN_HEIGHT in make_five_pin.py.
    static let pinHeight = Numbers.pinHeight
    /// The effective contact radius against a 61.5 mm ball (see the header); equal to SWIFT_CONTACT_R in
    /// make_five_pin.py.
    static let pinContactRadius = Numbers.pinContactRadius
    /// Estimated: about 1 g.
    static let pinMass = Numbers.pinMass
    /// Centre-to-centre distance from the red pin to each white pin: 66 mm.
    static let pinSpacing = Numbers.pinSpacing
    /// The red pin is pin 0, on the centre spot; the white pins are 1 to 4.
    static let redPinIndex = FivePinRules.redPin

    /// The centre spot, where the red pin stands.
    static var castleCentre: Vec2 { Numbers.castleCentre }

    /// The castle: 0 the red pin on the centre spot, 1 and 2 along the long string, 3 and 4 across it.
    static var pins: [Pin] { Numbers.pins }

    // MARK: Balls and the start

    /// Ball slots: 0 is the white cue ball (drawn ivory), 1 the opponent's yellow (drawn yellow), 3 the red object
    /// ball (drawn red). The lower half (x < L/2) is the white's half; the upper end (x = L) is the yellow's.
    static let opponentBallIndex = FivePinRules.playerBalls[1]
    static let redBallIndex = FivePinRules.redBall

    /// "Mouche mi-haute": the red ball's spot, in the middle of the upper half.
    static var redSpot: Vec2 { Numbers.redSpot }
    /// "Mouche haute": the yellow's spot on the long string, 10 cm from the upper short cushion.
    static var opponentSpot: Vec2 { Numbers.opponentSpot }
    /// The white's start at the edge of its half, 20 cm from the near long cushion, where the opening shot plays from.
    static var cueStart: Vec2 { Numbers.cueStart }

    /// Sixteen positions, index 0 the cue ball, unused balls at NextShot.offTable.
    static var startLayout: [Vec2] { Numbers.startLayout }

    /// The white cuts the yellow on its lower side; the yellow runs off the short cushion and the far long cushion into
    /// the castle (see the header: tuned on a copy of the solver's laws, the exact window may sit a little off).
    static let defaultShot = (aimDegrees: 19.14, power: 4.0)

    // MARK: Looks and props

    /// Lacquered turned pins with a clear coat as real lacquered pins have. 0.7.5: a near-white and a clear, deep red
    /// (the red channel up, green and blue held low so it never drifts toward orange); the old ivory and dark red sank
    /// into the cloth from the playing camera on a phone. These looks reach both the plain stand-ins and the turned
    /// Blender pins (partLooks dresses the loaded model).
    static let whitePinLook = TablePartLook(color: (0.98, 0.97, 0.95), roughness: 0.3, clearcoat: 0.6)
    static let redPinLook = TablePartLook(color: (0.86, 0.04, 0.06), roughness: 0.3, clearcoat: 0.6)
    /// The small white spots stuck on the cloth.
    static let spotLook = TablePartLook(color: (0.92, 0.92, 0.90), roughness: 0.85)

    // MARK: The castle mark (drawing only)

    /// The plain stand-in pins are drawn this wide (half of the pin's 10 mm widest part), not at pinContactRadius, which
    /// is the solver's contact distance and only 4.8 mm across: too thin to see before the turned pins load. Drawing
    /// only; the solver keeps pinContactRadius.
    static let drawnPinRadius: Float = 0.005
    /// The castle ring's inner and outer radius about the centre spot, metres: just outside the outer pins (66 mm out,
    /// 5 mm wide), 4 mm wide so it is still a line, not a band, on a phone across the whole table.
    static let castleRingRadii: (inner: Float, outer: Float) = (0.082, 0.086)
    /// The soft disc under each pin, radius in metres: wider than the white spot (4 mm) so the five spots read as a
    /// cross even with the pins standing on them.
    static let castleSpotRadius: Float = 0.011
    /// How strongly the mark lightens the surface under it: faint, a tone above the cloth, never a bright line.
    static let castleMarkOpacity: Float = 0.2
    /// The mark lies this far above the cloth: above the cloth's own face, below the tops of the white spots (0.3 mm), so
    /// the spots still show on top of it.
    static let castleMarkHeight: Float = 0.00025

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

        // The castle mark under everything else that stands in the castle (0.7.5): one translucent mesh, so it
        // lightens whichever surface is down by the same small step.
        if let mark = castleMark(around: castleCentre, spots: context.table.pins.map(\.center), frame: frame) {
            props.addChild(mark)
        }

        // Pins: holders named "pin-<k>" with their origin at the pin's base centre (what TableScene topples), each
        // starting with a plain cylinder until the model's turned pin replaces it. The cylinder is drawn at the pin's
        // true width (drawnPinRadius); the copy it is built from is for drawing only and never reaches the solver.
        let holders: [Entity] = context.table.pins.enumerated().map { k, pin in
            let look = k == redPinIndex ? redPinLook : whitePinLook
            var drawn = pin
            drawn.radius = Double(drawnPinRadius)
            let holder = TableProps.plainPin(index: k, drawn, frame: frame, look: look)
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

    /// The faint castle mark: a thin ring around the castle and a soft disc under each pin spot, flat on the cloth, in
    /// one mesh with one translucent material (the spots' own near-white at castleMarkOpacity), so it reads as the
    /// surface a tone lighter on cloth, ice or cork alike. No glow and no shadow of its own (it lies flat). Nil only if
    /// the mesh cannot be made, and then the table simply has no mark.
    @MainActor private static func castleMark(around centre: Vec2, spots: [Vec2], frame: TableFrame) -> ModelEntity? {
        var mesh = MeshBuilder()
        let up = SIMD3<Float>(0, 1, 0)
        let h = castleMarkHeight
        // A point on the cloth at `radius` from `c`, `angle` radians round from the table's length.
        func at(_ c: Vec2, _ radius: Float, _ angle: Float) -> SIMD3<Float> {
            frame.world(Vec2(c.x + Double(radius * cos(angle)), c.y + Double(radius * sin(angle))), height: h)
        }
        // The ring: a strip of quads between the inner and outer circle. MeshBuilder turns each triangle to face up
        // from the normals, so the order round the circle does not matter.
        let ringSegments = 96
        var inner: [UInt32] = [], outer: [UInt32] = []
        for i in 0...ringSegments {
            let a = Float(i) / Float(ringSegments) * 2 * Float.pi
            inner.append(mesh.vertex(at(centre, castleRingRadii.inner, a), up, .zero))
            outer.append(mesh.vertex(at(centre, castleRingRadii.outer, a), up, .zero))
        }
        for i in 0..<ringSegments { mesh.quad(inner[i], outer[i], outer[i + 1], inner[i + 1]) }
        // A disc under each pin: a fan round its centre.
        let discSegments = 32
        for spot in spots {
            let middle = mesh.vertex(frame.world(spot, height: h), up, .zero)
            var rim: [UInt32] = []
            for i in 0...discSegments {
                rim.append(mesh.vertex(at(spot, castleSpotRadius, Float(i) / Float(discSegments) * 2 * Float.pi), up, .zero))
            }
            for i in 0..<discSegments { mesh.tri(middle, rim[i], rim[i + 1]) }
        }
        guard let resource = mesh.resource() else { return nil }
        var material = TableProps.material(spotLook)
        material.blending = .transparent(opacity: .init(floatLiteral: castleMarkOpacity))
        let entity = ModelEntity(mesh: resource, materials: [material])
        entity.name = "FivePinCastleMark"
        return entity
    }
}
