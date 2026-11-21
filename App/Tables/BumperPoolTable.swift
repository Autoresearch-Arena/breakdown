// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (filled in from the groundwork stub: real table size, 2-1/8 in balls,
//          no edge pockets, two cups in the bed, twelve rubber bumpers, the five-and-five start, an opening bank shot and
//          the Blender-made bumpers and cup liners.)
// PURPOSE: Bumper pool: a small rectangular table with no edge pockets; one cup (a hole in the bed) near the middle of
//          each end, two rubber bumpers flanking each cup and a cross of eight bumpers in the centre (two per arm, one
//          arm in line with the cups, an open middle just wide enough for a ball). Each side has five balls; the marked
//          one starts directly in front of the cup at its end, two more either side of that cup, and all five are
//          played toward the cup at the far end. Only the place to play is built here; scoring comes later.
//          Facts: two bumpers flank each cup and eight form the centre cross; five red and five white balls, one of each
//            marked; the marked ball starts directly in front of its cup, two more either side of the cup on the marks;
//            the opening shot banks off the shooter's right-hand cushion. Playing surface 45.5 x 30 in. Twelve 2 in
//            rubber bumpers. Balls 2-1/8 in (54 mm), mass scaled from a 170 g, 2-1/4 in pool ball by volume (about
//            143 g). Cup liners 2.488 in outside, 2.178 to 2.188 in inside, 3/4 in deep.
//            Estimates (named as such below): the cup's distance from the end cushion, the bumper spacing in the
//            cross and beside the cups, the start spots and the bumper height.
//          Props: Tools/blender/make_bumper_pool.py makes App/Models/BumperPool.usdz (one bumper in three parts and one
//          cup liner, each at its own origin); makeProps clones them onto the solved posts and holes. Plain code-built
//          posts stand in until the model loads (or if it is missing).
// SRP/DRY check: Pass - this table's data and props only; the solver features (posts, bed holes, pockets off) live in
//          BreakdownCore, the dispatch in TableKind.swift, the shared prop helpers (load, dress, plain posts) in
//          TableProps.swift; the bumper and liner geometry lives in the Blender script, whose RING_R, POST_H and
//          LINER_OUTER_R must equal bumperRadius, bumperHeight and cupRadius here.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import RealityKit

enum BumperPoolTable: TableDefinition {
    private static let inch = 0.0254

    /// Playing surface between the cushion noses: 45.5 x 30 in.
    static let tableSize = (length: 45.5 * inch, width: 30.0 * inch)
    /// 2-1/8 in bumper pool balls.
    static let ballRadius = 2.125 * inch / 2
    /// A 2-1/4 in, 170 g pool ball scaled by volume to 2-1/8 in: 170 g * (2.125 / 2.25)^3 = 143 g.
    static let ballMass = 0.143
    /// Bumper pool has no edge pockets: the cushions run every side.
    static let pocketsEnabled = false

    // MARK: Bumpers (posts)

    /// 2 in rubber ring: the contact radius is the ring's outer radius.
    /// Equal to RING_R in make_bumper_pool.py.
    static let bumperRadius = 1.0 * inch
    /// Top of the chrome cap above the cloth, estimated (about 1.9 in); equal to POST_H in make_bumper_pool.py.
    /// A ball must jump clear of this to pass over.
    static let bumperHeight = 0.048
    /// Lively moulded rubber: livelier than a cushion and a touch grippier.
    static let bumperRestitution = 0.80
    static let bumperFriction = 0.20

    /// Middle of the table.
    private static var middle: Vec2 { Vec2(tableSize.length / 2, tableSize.width / 2) }
    /// Cross arm spacing from the middle (estimate). One arm lies on the cups' line, so a straight
    /// shot down the middle meets a bumper; the open middle is reached between neighbouring inner bumpers on the
    /// diagonals, whose rubber is 2 * (0.082 / sqrt 2 - 0.0254) = 65 mm apart against a 54 mm ball ("just large
    /// enough to allow a ball to pass through"). The outer four sit about 4 in further out on each arm.
    private static let crossInner = 0.082
    private static let crossOuter = 0.180
    /// The two bumpers flanking each cup: offset across from the cup's line and a little toward the middle, so they
    /// guard its mouth but leave room to roll in (estimate).
    private static let guardAcross = 0.075
    private static let guardToward = 0.020

    /// Twelve bumpers: 0 to 3 guard the cups (two at the x = 0 end, then two at the far end), 4 to 7 the cross's
    /// inner ring (along the length, then across), 8 to 11 its outer ring.
    static var posts: [Post] {
        let c = middle, L = tableSize.length
        var centres: [Vec2] = []
        for x in [cupInset + guardToward, L - cupInset - guardToward] {
            centres.append(Vec2(x, c.y - guardAcross))
            centres.append(Vec2(x, c.y + guardAcross))
        }
        for d in [crossInner, crossOuter] {
            centres.append(Vec2(c.x - d, c.y))   // the arm in line with the cups
            centres.append(Vec2(c.x + d, c.y))
            centres.append(Vec2(c.x, c.y - d))   // the arm across the table
            centres.append(Vec2(c.x, c.y + d))
        }
        return centres.map {
            Post(center: $0, radius: bumperRadius, restitution: bumperRestitution, friction: bumperFriction,
                 height: bumperHeight)
        }
    }

    static let pins: [Pin] = []

    // MARK: Cups (bed holes)

    /// Cup centre from the end cushion nose, on the table's long centre line (estimate, about 5.5 in).
    private static let cupInset = 0.140
    /// The hole cut in the bed: the liner's outside, 2.488 in; equal to LINER_OUTER_R in
    /// make_bumper_pool.py.
    static let cupRadius = 2.488 * inch / 2
    /// The liner's opening is only 2.188 in for a 2.125 in ball, so the ball has to be nearly centred over the cup
    /// before it drops: capture well inside the drawn hole.
    static let cupCapture = 0.018

    /// Bed hole 0 (pocket index 6) at the x = 0 end, bed hole 1 (pocket index 7) at the far end.
    static var bedHoles: [BedHole] {
        [cupInset, tableSize.length - cupInset].map {
            BedHole(center: Vec2($0, tableSize.width / 2), radius: cupRadius, captureRadius: cupCapture)
        }
    }

    // MARK: Start and opening shot

    /// Five balls a side, each set racked around the cup at its own end and played toward the far cup:
    ///   near end (x = 0): ball 0 the marked ball (the cue ball) directly in front of cup 0, balls 1 to 4 two either
    ///   side of that cup; far end: ball 9 the marked ball in front of cup 1, balls 10 to 13 either side of it.
    /// Balls 5 to 8, 14 and 15 are off the table. The spots are estimates.
    static var startLayout: [Vec2] {
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        let L = tableSize.length, midY = tableSize.width / 2
        let markedX = cupInset + 0.080          // in front of the cup, toward the middle
        let sideOffsets = [-0.260, -0.170, 0.170, 0.260]
        l[0] = Vec2(markedX, midY)
        l[9] = Vec2(L - markedX, midY)
        for (i, dy) in sideOffsets.enumerated() {
            l[1 + i] = Vec2(cupInset, midY + dy)
            l[10 + i] = Vec2(L - cupInset, midY + dy)
        }
        return l
    }

    /// The real opening shot: the marked ball banks off the shooter's right-hand cushion (plan y = 0 for a player at
    /// the x = 0 end) toward the far cup, where it meets the bumper guarding that cup. Aimed at the far cup's mirror
    /// image in the cushion (41.6 degrees below +x), opened half a degree so the ball meets the guard bumper fully
    /// rather than grazing it: a straight-line trace puts the bounce off the y = 0 cushion near the middle of the
    /// table and the hit on post 2 about 2 cm off its centre line. 2.2 m/s carries it the length of the table.
    static let defaultShot = (aimDegrees: 319.5, power: 2.2)

    // MARK: Looks

    private static let chrome = TablePartLook(color: (r: 0.86, g: 0.87, b: 0.89), roughness: 0.14, metallic: 1)
    /// White moulded rubber ring.
    private static let rubber = TablePartLook(color: (r: 0.92, g: 0.91, b: 0.87), roughness: 0.78)
    /// The two cups are coloured, one per side: red at the x = 0 end, white at the far end.
    private static let redCup = TablePartLook(color: (r: 0.70, g: 0.08, b: 0.07), roughness: 0.35, clearcoat: 0.6)
    private static let whiteCup = TablePartLook(color: (r: 0.93, g: 0.92, b: 0.89), roughness: 0.35, clearcoat: 0.6)

    /// Part name to finish, for the Blender model's named parts (the liner's default is the red cup; the far cup's
    /// copy is re-dressed white in makeProps).
    static let partLooks: [String: TablePartLook] = [
        "BumperPoolBase": chrome,
        "BumperPoolCap": chrome,
        "BumperPoolRing": rubber,
        "BumperPoolCupLiner": redCup,
    ]

    // MARK: Props

    private static let bumperParts = ["BumperPoolBase", "BumperPoolRing", "BumperPoolCap"]

    /// Twelve bumpers named "post-<k>" and a liner in each cup. Plain white cylinders stand in at once; when the
    /// Blender model has loaded, each is replaced by a clone of the modelled bumper, and the liners are added.
    @MainActor static func makeProps(_ context: TablePropsContext) -> Entity {
        let props = Entity()
        props.name = "BumperPoolProps"
        let posts = context.table.posts, holes = context.table.bedHoles, frame = context.frame
        for (k, post) in posts.enumerated() {
            props.addChild(TableProps.plainPost(index: k, post, frame: frame, look: rubber))
        }
        TableProps.loadModel(named: "BumperPool", looks: partLooks, into: props,
                             lightSource: context.lightSource) { model in
            let parts = bumperParts.compactMap { model.findEntity(named: $0) }
            let liner = model.findEntity(named: "BumperPoolCupLiner")
            // Each part was authored at its own origin, so a clone only needs the post's (or cup's) position.
            if parts.count == bumperParts.count {
                for (k, post) in posts.enumerated() {
                    props.findEntity(named: "post-\(k)")?.removeFromParent()
                    let bumper = Entity()
                    bumper.name = "post-\(k)"
                    bumper.position = frame.world(post.center)
                    for part in parts {
                        let copy = part.clone(recursive: true)
                        copy.transform = Transform()
                        bumper.addChild(copy)
                    }
                    props.addChild(bumper)
                }
            }
            if let liner {
                for (j, hole) in holes.enumerated() {
                    // The copy keeps its part name (so dress finds it); the holder carries the cup's name and place.
                    let cup = Entity()
                    cup.name = "BumperPoolCup-\(j)"
                    cup.position = frame.world(hole.center)
                    let copy = liner.clone(recursive: true)
                    copy.transform = Transform()
                    cup.addChild(copy)
                    if j % 2 == 1 { TableProps.dress(cup, looks: ["BumperPoolCupLiner": whiteCup]) }
                    props.addChild(cup)
                }
            }
            // The copies go straight under the props; the originals sit at the model's origin (the table's centre,
            // in the middle of the cross), so take them out and let the emptied model be added harmlessly.
            for part in parts { part.removeFromParent() }
            liner?.removeFromParent()
        }
        return props
    }
}
