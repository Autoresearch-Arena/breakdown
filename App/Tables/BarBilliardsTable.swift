// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: 21-November-2026 by Claude Opus 5.5 High - filled in the real English bar-billiards table (was the
//          groundwork's placeholder stub): league playing area, nine bed holes, three skittles, the 1 7/8 inch balls,
//          the start from the D with the red on its spot, a default shot into a 50 hole, and the turned-wood skittles
//          from Tools/blender/make_bar_billiards.py.
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-rules) - the hole values, the red ball's number and the
//          black skittle's number now come from BarBilliardsRules (BreakdownRules), which scores the game, so the
//          table and the scoring read one copy.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: the solver numbers (size, balls, posts, pins, holes,
//          start) moved unchanged to the package, BreakdownAuthored/AuthoredTables.swift (AuthoredTables.BarBilliards), and are read
//          from there, so BreakProbe can solve and check a shot of the day on this table; looks and props stay here.)
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
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import RealityKit

enum BarBilliardsTable: TableDefinition {
    // 0.7.10 bank: every solver number below is read from the package (BreakdownAuthored, AuthoredTables.BarBilliards),
    // where it moved unchanged with its reasons, so BreakProbe solves and checks a shot of the day on this table with
    // the very same numbers. This file keeps the looks and the props.
    private typealias Numbers = AuthoredTables.BarBilliards

    /// Playing surface between the cushion noses: 1.42 m by 0.80 m.
    static let tableSize = Numbers.size
    /// 1 7/8 inch (47.625 mm) balls.
    static let ballRadius: Double = Numbers.ballRadius
    /// Estimate: about 98 g.
    static let ballMass: Double = Numbers.ballMass
    static let pocketsEnabled = false

    /// No fixed posts: the skittles fall when touched, so they are pins.
    static let posts: [Post] = []

    // MARK: Holes

    /// Order (bed hole j is pocket 6 + j): 0 = 200, 1 = 100, 2 and 3 = the 50s, 4 to 8 = the far row 30, 20, 10, 20, 30.
    static let bedHoles: [BedHole] = Numbers.bedHoles
    /// The points each hole scores, in `bedHoles` order; owned by the rules that score them.
    static let holeValues = BarBilliardsRules.holeValues

    // MARK: Skittles

    /// Contact radius of the skittle's stalk at ball-centre height; the model's stalk (make_bar_billiards.py,
    /// SKITTLE_STALK_R) is exactly this.
    static let skittleRadius = Numbers.skittleRadius
    /// Pin index of the black skittle (the others are white).
    static let blackPin = BarBilliardsRules.blackPeg

    /// 0: black, in front of the 200 hole. 1 and 2: white, level with the 100 hole either side of it.
    static let pins: [Pin] = Numbers.pins

    // MARK: Start and default shot

    /// The D spot, 300 mm from the player's cushion on the centre line.
    private static let dSpot = Numbers.dSpot
    /// Ball 3 is drawn solid red; it stands in for the game's one red ball.
    static let redBall = BarBilliardsRules.redBall

    /// A white on the D spot and the red on its spot; the other six whites off the table.
    static var startLayout: [Vec2] { Numbers.startLayout }

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
