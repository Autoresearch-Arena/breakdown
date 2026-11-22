// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: 21-November-2026 by Claude Opus 5.5 High - filled in the real English bar-billiards table (was the
//          groundwork's placeholder stub): league playing area, nine bed holes, three skittles, the 1 7/8 inch balls,
//          the start from the D with the red on its spot, a default shot into a 50 hole, and the turned-wood skittles
//          from Tools/blender/make_bar_billiards.py.
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-rules) - the hole values, the red ball's number and the
//          black skittle's number now come from BarBilliardsRules (BreakdownRules), which scores the game, so the
//          table and the scoring read one copy.
// PURPOSE: Bar billiards (the English pub game) as a place to play and watch the physics. No edge pockets: the
//          cushions run round all four sides, and nine scoring holes are cut into the bed. Seen from the player's end
//          (plan x = 0, where the D is): a diamond of four holes in the middle (200 nearest the player, a 50 each
//          side, 100 behind), then a row of five near the far cushion (30, 20, 10, 20, 30). Three turned wooden
//          skittles ("mushrooms") stand guard: a black one just in front of the 200 hole and two white ones level with
//          the 100 hole, one each side. Each skittle is a Pin, so the first ball to touch it knocks it down (in the
//          real game a white one down loses the break and the black one loses the whole score; scoring comes later
//          and is not built here). Balls: seven white and one red, smaller than pool balls. A break starts with a
//          white from the D and the red on its spot; the other six whites wait in the return tray (off the table).
//          Ball indices used: 0 = the white being played (the cue ball, drawn white), 3 = the red (ball 3 is the
//          solid red in BallTextures' palette), all others off the table.
//          Plan frame (App/Tables/README.md): x along the length from the player's cushion (0) to the far cushion (L),
//          y across. Bed hole j is pocket 6 + j, in the order of `bedHoles` below. Pin k is "pin-<k>": 0 black, 1 and 2
//          white.
//          Facts: playing area about 80 cm by 138 to 144 cm inside the cushions (this layout: 1.42 x 0.80 m); nine holes
//          worth 10 to 200, a far row of 30, 20, 10, 20, 30 and a diamond with the 200 nearest the player, the 50s at
//          the sides and the 100 at the back; balls 1 7/8 inch (47.6 mm), seven white and one red; white skittles level
//          with the 100 hole, 17.8 cm (7 in) from its centre; the black skittle's back edge 0.6 cm from the 200 hole's
//          front edge. Hole centres from the far cushion: row at 90 mm, 100 at 330, 50s at 520 and 250 mm off centre,
//          200 at 700; row holes 150 and 300 mm off centre. D centre 300 mm from the front cushion, red spot 229 mm in
//          front of that. Hole lining rings 55 mm inside. Skittles 3 inch (76 mm) tall with a 9 mm stalk under a
//          19.5 mm domed cap that clears the top of a ball. Positions vary a little between makers.
//          Estimates: ball mass from a pool ball's phenolic density at 47.6 mm (about 98 g); a turned beech skittle of
//          this shape weighs about 25 g.
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the default shot plays at 1.4 m/s, since on the
//          default generation-two physics a 2 m/s ball skips over the 50 hole.)
// SRP/DRY check: Pass - this table's data and props only; the solver features (posts, pins, bed holes, pockets off)
//          live in BreakdownCore, the dispatch in TableKind.swift, shared prop helpers (plainPin, loadModel, dress) in
//          TableProps.swift, which this file reuses rather than copying.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import RealityKit

enum BarBilliardsTable: TableDefinition {
    /// Playing surface between the cushion noses: 1.42 m by 0.80 m (league layout,
    /// inside the minimum of 78.7 cm by 138.4 to 143.5 cm).
    static let tableSize = (length: 1.42, width: 0.80)
    /// 1 7/8 inch (47.625 mm) balls (47.6 mm in the league-scale layout).
    static let ballRadius: Double = 0.0238125
    /// Estimate: a 57.15 mm, 170 g pool ball's density at 47.625 mm, 0.170 x (47.625 / 57.15)^3.
    static let ballMass: Double = 0.170 * pow(47.625 / 57.15, 3.0)
    static let pocketsEnabled = false

    /// No fixed posts: the skittles fall when touched, so they are pins.
    static let posts: [Post] = []

    // MARK: Holes

    /// Drawn hole radius: the 55 mm inner diameter of a hole lining ring.
    private static let holeRadius = 0.0275
    /// A ball drops once its centre is 22 mm inside the hole's centre: well over the hole, not just touching the rim
    /// (a ball's own radius is 23.8 mm, the hole's 27.5 mm).
    private static let holeCapture = 0.022
    private static var L: Double { tableSize.length }
    private static var W: Double { tableSize.width }

    /// Hole centre from its distance to the far cushion and its offset across from the centre line (as the league
    /// layout measures them).
    private static func hole(fromFar d: Double, across a: Double) -> BedHole {
        BedHole(center: Vec2(L - d, W / 2 + a), radius: holeRadius, captureRadius: holeCapture)
    }

    /// Order (bed hole j is pocket 6 + j): 0 = 200, 1 = 100, 2 and 3 = the 50s, 4 to 8 = the far row 30, 20, 10, 20, 30.
    /// Hole values (BarBilliardsRules.holeValues): [200, 100, 50, 50, 30, 20, 10, 20, 30].
    static let bedHoles: [BedHole] = [
        hole(fromFar: 0.700, across: 0),          // 200, nearest the player, behind the black skittle
        hole(fromFar: 0.330, across: 0),          // 100, back of the diamond, between the white skittles
        hole(fromFar: 0.520, across: -0.250),     // 50
        hole(fromFar: 0.520, across: 0.250),      // 50
        hole(fromFar: 0.090, across: -0.300),     // 30
        hole(fromFar: 0.090, across: -0.150),     // 20
        hole(fromFar: 0.090, across: 0),          // 10
        hole(fromFar: 0.090, across: 0.150),      // 20
        hole(fromFar: 0.090, across: 0.300),      // 30
    ]
    /// The points each hole scores, in `bedHoles` order; owned by the rules that score them.
    static let holeValues = BarBilliardsRules.holeValues

    // MARK: Skittles

    /// Contact radius of the skittle's stalk at ball-centre height; the model's stalk (make_bar_billiards.py,
    /// SKITTLE_STALK_R) is exactly this.
    private static let skittleRadius = 0.009
    /// The cap's radius in the model, used to keep the black skittle's cap clear of the 200 hole.
    private static let skittleCapRadius = 0.0195
    /// 3 inch mushroom; a ball flying higher than this passes over.
    private static let skittleHeight = 0.076
    /// Estimate for turned beech of this shape.
    private static let skittleMass = 0.025
    /// Wood on phenolic, a little softer than the default pin knock.
    private static let skittleRestitution = 0.7
    /// Pin index of the black skittle (the others are white).
    static let blackPin = BarBilliardsRules.blackPeg

    private static func skittle(_ c: Vec2) -> Pin {
        Pin(center: c, radius: skittleRadius, mass: skittleMass, restitution: skittleRestitution, height: skittleHeight)
    }

    /// 0: black, in front of the 200 hole with its back edge 6 mm from the hole's front edge.
    /// 1 and 2: white, level with the 100 hole, 178 mm (7 in) either side of its centre.
    static let pins: [Pin] = [
        skittle(Vec2(bedHoles[0].center.x - holeRadius - 0.006 - skittleCapRadius, W / 2)),
        skittle(Vec2(bedHoles[1].center.x, W / 2 - 0.178)),
        skittle(Vec2(bedHoles[1].center.x, W / 2 + 0.178)),
    ]

    // MARK: Start and default shot

    /// The D spot, 300 mm from the player's cushion on the centre line, and the red spot 229 mm in front of it
    /// (league layout). The scratch re-spot (L/4, W/2) = (0.355, 0.40) is clear of every hole and skittle.
    private static let dSpot = Vec2(0.300, W / 2)
    private static let redSpot = Vec2(0.300 + 0.229, W / 2)
    /// Ball 3 is drawn solid red; it stands in for the game's one red ball.
    static let redBall = BarBilliardsRules.redBall

    /// Sixteen positions: a white (index 0, the cue ball) on the D spot and the red on its spot; the other six whites
    /// are in the return tray, so off the table, as at the start of a real break.
    static var startLayout: [Vec2] {
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[0] = dSpot
        l[redBall] = redSpot
        return l
    }

    /// Plain ball from the D straight into the left 50 hole (as the player looks up the table), passing well clear of
    /// the red (95 mm) and the black skittle (150 mm). A straight centre-ball shot needs no throw or swerve to land, so
    /// it reliably pots. On the default physics (generation two, since 21-Nov-2026) a ball crossing a hole too fast
    /// skips over it, and 2 m/s skipped this one. Checked on a temporary copy of this table in BreakProbe at 0.6 to
    /// 2.0 m/s on every surface: 1.4 m/s drops on every surface but sand (where the ball dies short below 1.6 m/s) and
    /// the Moon (where almost every pace skips), so 1.4 it is.
    static let defaultShot: (aimDegrees: Double, power: Double) = (
        aimDegrees: atan2(bedHoles[2].center.y - dSpot.y, bedHoles[2].center.x - dSpot.x) * 180 / Double.pi,
        power: 1.4
    )

    // MARK: Look and props

    /// White enamelled turned wood. The black skittle uses `blackSkittleLook` on the same part.
    static let partLooks: [String: TablePartLook] = [
        "BarBilliardsSkittle": TablePartLook(color: (0.93, 0.92, 0.88), roughness: 0.35, clearcoat: 0.6,
                                             clearcoatRoughness: 0.15),
    ]
    private static let blackSkittleLook = TablePartLook(color: (0.04, 0.04, 0.045), roughness: 0.3, clearcoat: 0.7,
                                                        clearcoatRoughness: 0.1)

    /// The three skittles. Each "pin-<k>" holder is made at once (with a plain cylinder, so the table works even
    /// before or without the model); when BarBilliards.usdz has loaded, the turned skittle is cloned into every holder,
    /// painted white or black, and the cylinder goes. TableScene topples the holders; nothing here animates.
    @MainActor static func makeProps(_ context: TablePropsContext) -> Entity {
        let props = Entity()
        props.name = "BarBilliardsProps"
        let fallbackName = "BarBilliardsSkittleFallback"
        let whiteLook = partLooks["BarBilliardsSkittle"] ?? blackSkittleLook
        var holders: [Entity] = []
        for (k, pin) in context.table.pins.enumerated() {
            let holder = TableProps.plainPin(index: k, pin, frame: context.frame,
                                             look: k == blackPin ? blackSkittleLook : whiteLook)
            for child in holder.children { child.name = fallbackName }
            props.addChild(holder)
            holders.append(holder)
        }
        let pinHolders = holders  // an immutable copy for the load callback (Swift 6 captures)
        TableProps.loadModel(named: "BarBilliards", looks: partLooks, into: props,
                             lightSource: context.lightSource) { model in
            guard let skittle = model.findEntity(named: "BarBilliardsSkittle") else {
                NSLog("BarBilliardsTable: BarBilliardsSkittle is missing from the model; keeping the plain pins")
                return
            }
            for (k, holder) in pinHolders.enumerated() {
                let copy = skittle.clone(recursive: true)
                // The part is authored with its base centre at its own origin, standing along +Y.
                copy.transform = Transform.identity
                for child in Array(holder.children) where child.name == fallbackName { child.removeFromParent() }
                holder.addChild(copy)
                if k == blackPin { TableProps.dress(holder, looks: ["BarBilliardsSkittle": blackSkittleLook]) }
            }
            skittle.removeFromParent()
        }
        return props
    }
}
