// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The solver numbers of the three other tables (bumper pool, five-pin billiards, bar billiards), in the one
//          place both the app and the package's dev tool read (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 4 item
//          4: a shot of the day can be on another table, so BreakProbe has to solve it there and "BreakProbe verify" has
//          to play it there). Before 0.7.10 these numbers lived only in the app's table files (App/Tables), which the
//          package cannot see, so no authored shot could be checked off the pool table. Moved here unchanged, with their
//          reasons; the app's BumperPoolTable, FivePinTable and BarBilliardsTable now read every number from here and
//          keep their looks and props. Same pattern as TableSurfaces.swift (the surfaces' numbers).
//          AuthoredTable is the package's name for a table: an authored shot (AuthoredDaily, AuthoredTrick) names its
//          table with it, and the app maps it to its own TableKind by the raw value (the same strings).
//          Units: metres, kilograms; positions on the solver's plan (x along the length from 0 to L, y across from 0 to
//          W, origin at a corner of the playing surface between the cushion noses). Bed hole j is pocket index 6 + j.
//          Order of application, as the app's ShowpieceModel.solverCopy: the table first, then the surface.
// SRP/DRY check: Pass - numbers only, moved from App/Tables (nothing else holds them); the rules that score these tables
//          are BreakdownRules' (the ball and peg numbers are read from there, as the app's files did). The package
//          tests' TableRulesFixtures keep hand-built TableSpecs for the rules tests; AuthoredDailyTests checks they
//          agree with these.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

/// The table an authored shot is played on. Raw values are the app's TableKind raw values.
public enum AuthoredTable: String, CaseIterable, Sendable {
    case standard, bumperPool, fivePin, barBilliards

    /// Write this table into the parameters. The standard table leaves them untouched, so a pool shot hashes exactly as
    /// it always did.
    public func apply(to p: inout PoolParameters) {
        switch self {
        case .standard:
            return
        case .bumperPool:
            p.tableLength = AuthoredTables.BumperPool.size.length
            p.tableWidth = AuthoredTables.BumperPool.size.width
            p.ballRadius = AuthoredTables.BumperPool.ballRadius
            p.ballMass = AuthoredTables.BumperPool.ballMass
            p.pocketsEnabled = false
            p.posts = AuthoredTables.BumperPool.posts
            p.pins = []
            p.bedHoles = AuthoredTables.BumperPool.bedHoles
        case .fivePin:
            p.tableLength = AuthoredTables.FivePin.size.length
            p.tableWidth = AuthoredTables.FivePin.size.width
            p.ballRadius = AuthoredTables.FivePin.ballRadius
            p.ballMass = AuthoredTables.FivePin.ballMass
            p.pocketsEnabled = false
            p.posts = []
            p.pins = AuthoredTables.FivePin.pins
            p.bedHoles = []
        case .barBilliards:
            p.tableLength = AuthoredTables.BarBilliards.size.length
            p.tableWidth = AuthoredTables.BarBilliards.size.width
            p.ballRadius = AuthoredTables.BarBilliards.ballRadius
            p.ballMass = AuthoredTables.BarBilliards.ballMass
            p.pocketsEnabled = false
            p.posts = []
            p.pins = AuthoredTables.BarBilliards.pins
            p.bedHoles = AuthoredTables.BarBilliards.bedHoles
        }
    }

    /// Default parameters with this table written in (no surface).
    public var parameters: PoolParameters {
        var p = PoolParameters()
        apply(to: &p)
        return p
    }

    /// The table's own start layout (sixteen positions); nil for the pool table, which racks instead.
    public var startLayout: [Vec2]? {
        switch self {
        case .standard: return nil
        case .bumperPool: return AuthoredTables.BumperPool.startLayout
        case .fivePin: return AuthoredTables.FivePin.startLayout
        case .barBilliards: return AuthoredTables.BarBilliards.startLayout
        }
    }
}

public enum AuthoredTables {
    private static let inch = 0.0254

    // MARK: Bumper pool

    /// Bumper pool: a small table with no edge pockets; one cup (a hole in the bed) near the middle of each end, two
    /// rubber bumpers flanking each cup and a cross of eight bumpers in the centre. Facts: playing surface 45.5 x 30 in,
    /// twelve 2 in rubber bumpers, balls 2-1/8 in, cup liners 2.488 in outside, 2.178 to 2.188 in inside. Estimates
    /// (named as such below): the cup's distance from the end cushion, the bumper spacing, the start spots and the
    /// bumper height.
    public enum BumperPool {
        /// Playing surface between the cushion noses: 45.5 x 30 in.
        public static let size = (length: 45.5 * inch, width: 30.0 * inch)
        /// 2-1/8 in bumper pool balls.
        public static let ballRadius = 2.125 * inch / 2
        /// A 2-1/4 in, 170 g pool ball scaled by volume to 2-1/8 in: 170 g * (2.125 / 2.25)^3 = 143 g.
        public static let ballMass = 0.143

        /// 2 in rubber ring: the contact radius is the ring's outer radius (RING_R in make_bumper_pool.py).
        public static let bumperRadius = 1.0 * inch
        /// Top of the chrome cap above the cloth, estimated (about 1.9 in); POST_H in make_bumper_pool.py. A ball must
        /// jump clear of this to pass over.
        public static let bumperHeight = 0.048
        /// Lively moulded rubber: livelier than a cushion and a touch grippier.
        public static let bumperRestitution = 0.80
        public static let bumperFriction = 0.20

        /// Middle of the table.
        public static var middle: Vec2 { Vec2(size.length / 2, size.width / 2) }
        /// Cross arm spacing from the middle (estimate). One arm lies on the cups' line, so a straight shot down the
        /// middle meets a bumper; the open middle is reached between neighbouring inner bumpers on the diagonals, whose
        /// rubber is 2 * (0.082 / sqrt 2 - 0.0254) = 65 mm apart against a 54 mm ball. The outer four sit about 4 in
        /// further out on each arm.
        static let crossInner = 0.082
        static let crossOuter = 0.180
        /// The two bumpers flanking each cup: offset across from the cup's line and a little toward the middle, so they
        /// guard its mouth but leave room to roll in (estimate).
        static let guardAcross = 0.075
        static let guardToward = 0.020

        /// Twelve bumpers: 0 to 3 guard the cups (two at the x = 0 end, then two at the far end), 4 to 7 the cross's
        /// inner ring (along the length, then across), 8 to 11 its outer ring.
        public static var posts: [Post] {
            let c = middle, L = size.length
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

        /// Cup centre from the end cushion nose, on the table's long centre line (estimate, about 5.5 in).
        public static let cupInset = 0.140
        /// The hole cut in the bed: the liner's outside, 2.488 in (LINER_OUTER_R in make_bumper_pool.py).
        public static let cupRadius = 2.488 * inch / 2
        /// The liner's opening is only 2.188 in for a 2.125 in ball, so the ball has to be nearly centred over the cup
        /// before it drops: capture well inside the drawn hole.
        public static let cupCapture = 0.018

        /// Bed hole 0 (pocket index 6) at the x = 0 end, bed hole 1 (pocket index 7) at the far end.
        public static var bedHoles: [BedHole] {
            [cupInset, size.length - cupInset].map {
                BedHole(center: Vec2($0, size.width / 2), radius: cupRadius, captureRadius: cupCapture)
            }
        }

        /// Five balls a side, each set racked around the cup at its own end and played toward the far cup: near end
        /// (x = 0): the marked ball (the cue ball) directly in front of cup 0, the other four two either side of that
        /// cup; far end the same round cup 1. Each side's ball numbers are BumperPoolRules.sides', so the rack and the
        /// rules agree. The spots are estimates.
        public static var startLayout: [Vec2] {
            var l = [Vec2](repeating: NextShot.offTable, count: 16)
            let L = size.length, midY = size.width / 2
            let markedX = cupInset + 0.080          // in front of the cup, toward the middle
            let sideOffsets = [-0.260, -0.170, 0.170, 0.260]
            let near = BumperPoolRules.sides[0], far = BumperPoolRules.sides[1]
            l[near[0]] = Vec2(markedX, midY)
            l[far[0]] = Vec2(L - markedX, midY)
            for (i, dy) in sideOffsets.enumerated() {
                l[near[1 + i]] = Vec2(cupInset, midY + dy)
                l[far[1 + i]] = Vec2(L - cupInset, midY + dy)
            }
            return l
        }
    }

    // MARK: Five-pin billiards

    /// Five-pin billiards (Italian "cinque birilli"): a carom table with no pockets, five small pins in a cross (the
    /// castle) on the centre spot, a white and a yellow cue ball and a red object ball. Facts: playing surface 2.84 x
    /// 1.42 m; pins 25 mm high; the four white pins 66 mm from the red centre pin; balls 61.5 mm, 205 to 220 g.
    /// Estimates: the pins' mass (about 1 g) and their bounce.
    public enum FivePin {
        /// Playing surface between the cushion noses: 2.84 x 1.42 m.
        public static let size = (length: 2.84, width: 1.42)
        /// 61.5 mm carom balls.
        public static let ballRadius = 0.0615 / 2
        /// 205 to 220 g: the middle of the range.
        public static let ballMass = 0.210

        /// 25 mm tall (PIN_HEIGHT in make_five_pin.py). A ball whose lowest point is higher than this passes over.
        public static let pinHeight = 0.025
        /// The effective contact radius against a 61.5 mm ball: a ball's centre (30.75 mm up) is above the 25 mm pin, so
        /// the first touch is between the ball's lower surface and the pin's head, 33.15 mm from the axis, so r = 2.4 mm
        /// (SWIFT_CONTACT_R in make_five_pin.py, which recomputes it from the drawn profile).
        public static let pinContactRadius = 0.0024
        /// Estimated: 1.07 cm3 (the model's volume) of turned hardwood or plastic, about 1 g.
        public static let pinMass = 0.001
        /// Centre-to-centre distance from the red pin to each white pin: 66 mm.
        public static let pinSpacing = 0.066

        /// The centre spot, where the red pin stands.
        public static var castleCentre: Vec2 { Vec2(size.length / 2, size.width / 2) }

        /// The castle: 0 the red pin on the centre spot (FivePinRules.redPin), 1 and 2 the white pins along the long
        /// string (toward x = 0, then toward x = L), 3 and 4 across it (toward y = 0, then toward y = W).
        public static var pins: [Pin] {
            let c = castleCentre, s = pinSpacing
            let spots = [c, Vec2(c.x - s, c.y), Vec2(c.x + s, c.y), Vec2(c.x, c.y - s), Vec2(c.x, c.y + s)]
            return spots.map { Pin(center: $0, radius: pinContactRadius, mass: pinMass, height: pinHeight) }
        }

        /// "Mouche mi-haute": the red ball's spot, in the middle of the upper half.
        public static var redSpot: Vec2 { Vec2(size.length * 0.75, size.width / 2) }
        /// "Mouche haute": the yellow's spot on the long string, 10 cm from the upper short cushion.
        public static var opponentSpot: Vec2 { Vec2(size.length - 0.10, size.width / 2) }
        /// The white is placed freely, wholly inside the lower half: here at the half's edge, 20 cm from the near long
        /// cushion.
        public static var cueStart: Vec2 { Vec2(size.length / 2 - 0.04, 0.20) }

        /// Sixteen positions: 0 the white cue ball, FivePinRules.playerBalls[1] the yellow, FivePinRules.redBall the
        /// red; every other slot off the table.
        public static var startLayout: [Vec2] {
            var l = [Vec2](repeating: NextShot.offTable, count: 16)
            l[0] = cueStart
            l[FivePinRules.playerBalls[1]] = opponentSpot
            l[FivePinRules.redBall] = redSpot
            return l
        }
    }

    // MARK: Bar billiards

    /// Bar billiards (the English pub game): no edge pockets, nine scoring holes in the bed and three turned skittles.
    /// Facts: playing area about 80 cm by 138 to 144 cm (this layout 1.42 x 0.80 m); holes worth 10 to 200, a far row of
    /// 30, 20, 10, 20, 30 and a diamond with the 200 nearest the player, the 50s at the sides and the 100 at the back;
    /// balls 1 7/8 inch; white skittles level with the 100 hole, 17.8 cm from its centre; the black skittle's back edge
    /// 0.6 cm from the 200 hole's front edge. Hole centres from the far cushion: row at 90 mm, 100 at 330, 50s at 520
    /// and 250 mm off centre, 200 at 700; row holes 150 and 300 mm off centre. D centre 300 mm from the front cushion,
    /// red spot 229 mm in front of that. Hole lining rings 55 mm inside. Skittles 3 inch tall with a 9 mm stalk under a
    /// 19.5 mm domed cap. Estimates: ball mass (about 98 g) and skittle mass (about 25 g).
    public enum BarBilliards {
        /// Playing surface between the cushion noses: 1.42 m by 0.80 m.
        public static let size = (length: 1.42, width: 0.80)
        /// 1 7/8 inch (47.625 mm) balls.
        public static let ballRadius: Double = 0.0238125
        /// Estimate: a 57.15 mm, 170 g pool ball's density at 47.625 mm, 0.170 x (47.625 / 57.15)^3.
        public static let ballMass: Double = 0.170 * pow(47.625 / 57.15, 3.0)

        /// Drawn hole radius: the 55 mm inner diameter of a hole lining ring.
        public static let holeRadius = 0.0275
        /// A ball drops once its centre is 22 mm inside the hole's centre: well over the hole, not just touching the
        /// rim (a ball's own radius is 23.8 mm, the hole's 27.5 mm).
        public static let holeCapture = 0.022
        static var L: Double { size.length }
        static var W: Double { size.width }

        /// Hole centre from its distance to the far cushion and its offset across from the centre line.
        static func hole(fromFar d: Double, across a: Double) -> BedHole {
            BedHole(center: Vec2(L - d, W / 2 + a), radius: holeRadius, captureRadius: holeCapture)
        }

        /// Order (bed hole j is pocket 6 + j): 0 = 200, 1 = 100, 2 and 3 = the 50s, 4 to 8 = the far row 30, 20, 10,
        /// 20, 30 (BarBilliardsRules.holeValues).
        public static let bedHoles: [BedHole] = [
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

        /// Contact radius of the skittle's stalk at ball-centre height (SKITTLE_STALK_R in make_bar_billiards.py).
        public static let skittleRadius = 0.009
        /// The cap's radius in the model, used to keep the black skittle's cap clear of the 200 hole.
        public static let skittleCapRadius = 0.0195
        /// 3 inch mushroom; a ball flying higher than this passes over.
        public static let skittleHeight = 0.076
        /// Estimate for turned beech of this shape.
        public static let skittleMass = 0.025
        /// Wood on phenolic, a little softer than the default pin knock.
        public static let skittleRestitution = 0.7

        static func skittle(_ c: Vec2) -> Pin {
            Pin(center: c, radius: skittleRadius, mass: skittleMass, restitution: skittleRestitution,
                height: skittleHeight)
        }

        /// 0 (BarBilliardsRules.blackPeg): black, in front of the 200 hole with its back edge 6 mm from the hole's front
        /// edge. 1 and 2: white, level with the 100 hole, 178 mm (7 in) either side of its centre.
        public static let pins: [Pin] = [
            skittle(Vec2(bedHoles[0].center.x - holeRadius - 0.006 - skittleCapRadius, W / 2)),
            skittle(Vec2(bedHoles[1].center.x, W / 2 - 0.178)),
            skittle(Vec2(bedHoles[1].center.x, W / 2 + 0.178)),
        ]

        /// The D spot, 300 mm from the player's cushion on the centre line, and the red spot 229 mm in front of it.
        public static var dSpot: Vec2 { Vec2(0.300, W / 2) }
        public static var redSpot: Vec2 { Vec2(0.300 + 0.229, W / 2) }

        /// A white (index 0, the cue ball) on the D spot and the red (BarBilliardsRules.redBall) on its spot; the other
        /// six whites wait in the return tray, off the table, as at the start of a real break.
        public static var startLayout: [Vec2] {
            var l = [Vec2](repeating: NextShot.offTable, count: 16)
            l[0] = dSpot
            l[BarBilliardsRules.redBall] = redSpot
            return l
        }
    }
}
