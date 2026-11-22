// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 foundation, docs/v07-contracts.md section 1.3: the two
//          declarations the equipment stream fills for the automatic cue pick (plan item 57): CueKind, every cue that
//          has art in art/equipment, and CueChoice, the cue picked for a shot with the reason it was picked. Nothing
//          reads them yet; the house cue and every solve are unchanged.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment, plan item 57: the six cues the other developer
//          modelled are listed with their weights and lengths, read from the art (each .blend's collection carries its
//          design weight in ounces; lengths are the exported models' own). CueProfile gains `length`, `kind`,
//          `profile(for:)`, `choice(isBreak:elevation:tipUp:tipSide:)` (the automatic pick: break cue for a break,
//          jump cue for a jump, massé cue for a steep massé, house cue otherwise) and `power(forLaunchSpeed:)` (the
//          inverse of launchSpeed, for converting an authored house-cue power). The house cue, `selected` and
//          `launchSpeed` are untouched: the house cue still solves bit for bit as before.)
// PURPOSE: The cue as numbers (plans/21-Nov-2026-stroke-and-power-plan.md). Power in Breakdown means how hard the
//          player swings, not how fast the ball leaves, so the cue's weight matters: the same swing sends the ball
//          faster with a heavier cue. The model's power value stays exactly what it has always been, the launch speed
//          of a centre hit with the house cue ("house-cue-equivalent launch speed"), so every authored shot, every
//          saved setting and every solve with the house cue is unchanged bit for bit. This file says what that number
//          becomes for another cue (launchSpeed) and what swing it stands for (swing, the tip's speed), and gives each
//          cue its comfortable top swing, where the calm zone of the power bar ends (StrokeModel).
//          The cues (one per model in art/equipment, exported by Tools/blender/export_equipment.py and drawn by
//          CueRig): the house cue, a heavier break cue, a short light jump cue, a short heavy massé cue, and two plain
//          playing cues (rosewood and cobalt) that the pick never chooses but that are listed with their weights so the
//          set is complete. The game picks the cue for each shot itself (CueProfile.choice) and the stance card names
//          the pick (StanceWords.cueLine); the model holds the pick (ShowpieceModel.cueChoice, cueInHand) and every
//          launch goes through cueInHand.launchSpeed(forPower:).
//          The pick applies to free play and matches. Authored shots (trick shots, Behind the 8-Ball, lessons) were
//          measured with the house cue: their windows hold only for it, so those modes keep the house cue
//          (CueChoice.standard), or convert their authored power with power(forLaunchSpeed:) if they ever hand a
//          player another cue, so the ball leaves exactly as authored.
// SRP/DRY check: Pass - checked PoolParameters (cueMass, shaftEndMass, tipGrip and ballMass are read from it, not
//          retyped), PlayerShotSpeed (the house cue's comfortable top swing is derived from the break range there),
//          PowerWords (the plain words stay there; this file has numbers only), StanceWords (the pick's indicator line
//          lives there) and CueRig (draws the picked cue's model; only the kind crosses over).
import BreakdownPhysics
import Foundation

/// Every cue the game can hand the player: one per cue modelled in art/equipment (the Blender files). The game picks
/// the cue for each shot itself and says so (the Boss's decision: cues are only ever added, the pick is automatic,
/// with a clear indicator). Raw values are stored and compared, so never rename one; append new cues at the end.
/// The house cue's raw value is CueProfile's existing house id, so a profile's id can be its kind's raw value.
enum CueKind: String, CaseIterable, Codable, Sendable {
    /// The house maple cue: every shot that needs nothing special (house-maple.blend).
    case house
    /// The heavy break cue (oxblood-break.blend). Named breakCue because `break` is a Swift keyword.
    case breakCue = "break"
    /// The short, light jump cue (amber-jump.blend).
    case jump
    /// The short, heavier massé cue (masse-cue.blend).
    case masse
    /// A plain playing cue: rosewood butt, a lighter butt than the house cue (rosewood-four-point.blend).
    case rosewoodFourPoint
    /// A plain playing cue with a low-deflection carbon shaft (cobalt.blend).
    case cobalt
}

/// The cue the game picked for the next shot, and why. The equipment stream writes the pick (CueProfile.choice) and the
/// indicator line on the stance card; the model holds the current one (ShowpieceModel.cueChoice).
struct CueChoice: Equatable, Codable, Sendable {
    /// Why this cue: the reason the indicator line names.
    enum Reason: String, CaseIterable, Codable, Sendable {
        /// Nothing special about the shot: the house cue.
        case standard
        /// A break from the rack: the break cue.
        case breakShot
        /// The cue ball is to jump: the jump cue.
        case jump
        /// A steeply raised cue with side spin, to curve the ball: the massé cue.
        case steepMasse
    }

    var kind: CueKind
    var reason: Reason

    init(kind: CueKind, reason: Reason) {
        self.kind = kind
        self.reason = reason
    }

    /// The house cue for an ordinary shot: what every shot used before the pick existed.
    static let standard = CueChoice(kind: .house, reason: .standard)
}

struct CueProfile: Equatable, Sendable {
    /// A fixed identifier, never shown: saved choices and comparisons use it. It is the cue's CueKind raw value.
    let id: String
    /// The cue's name as the player reads it, translated.
    let name: String
    /// Kilograms: the whole cue, which carries the stroke's momentum into the ball.
    let cueMass: Double
    /// Kilograms: the effective mass of the shaft's last few centimetres, which sets side-spin deflection.
    let shaftEndMass: Double
    /// Friction of the chalked tip on the ball; the miscue limit follows from it.
    let tipGrip: Double
    /// Share of the closing speed the tip gives back at contact (0 dead, 1 perfectly springy).
    let tipRestitution: Double
    /// Metres per second of tip speed: the hardest swing a player makes with this cue before control starts to
    /// suffer. The calm zone of the power bar ends here (StrokeModel.zones).
    let comfortableTopSwing: Double
    /// Metres from the tip's striking face to the end of the butt: the exported model's own length (CueRig draws
    /// it; Reach.clearingElevation checks the whole of it for balls underneath).
    let length: Double

    /// The kind this profile describes (the id is the kind's raw value).
    var kind: CueKind { CueKind(rawValue: id) ?? .house }

    /// The ball the cue strikes, kilograms, from the physics parameters: every cue hits the same ball.
    static let ballMass = PoolParameters().ballMass

    /// Ball launch speed per metre per second of tip speed for a level centre hit: (1 + e) m / (m + M), the
    /// momentum and restitution of a cue of mass m striking a free ball of mass M (cues-and-bridges plan).
    var launchPerSwing: Double { Self.launchPerSwing(cueMass: cueMass, tipRestitution: tipRestitution) }

    static func launchPerSwing(cueMass: Double, tipRestitution: Double) -> Double {
        (1 + tipRestitution) * cueMass / (cueMass + ballMass)
    }

    /// True for the house cue: its power needs no conversion at all.
    var isHouse: Bool { id == Self.houseID }

    // MARK: The house cue

    private static let houseID = "house"

    /// The house cue's tip restitution. PoolParameters has no tip restitution (the solver works from launch speed and
    /// never needs one), so the value is stated here: a leather tip on a resin ball gives back about three quarters of
    /// the closing speed. It changes no solve and no shot: between cues it cancels in the ratio launchSpeed uses, and
    /// for the house cue launchSpeed does not multiply at all. It sets only the scale of the swing readout. Check:
    /// with it the house factor is (1.75 x 0.54) / (0.54 + 0.17) = 1.331, so the top of the break range (16 m/s of ball
    /// speed) is a swing of about 12 m/s, the top of the ordinary range (13 m/s) about 9.8 m/s, both the speeds of a
    /// very hard human stroke, and a soft roll at 1 m/s is a swing of 0.75 m/s.
    static let houseTipRestitution = 0.75

    /// The house cue's length, metres: house-maple.blend's cue runs 1.47 m tip to butt (a 58-inch cue), the same as
    /// the old code-built cue, so StrokeModel.tipToRearHand's grip still fits it.
    static let houseLength = 1.47

    /// The house cue, read from the physics parameters so the cue and the solver can never disagree. Its comfortable
    /// top swing is the swing that launches the softest break (PlayerShotSpeed.rackBreak's lower edge): everything
    /// softer than a break is a controlled stroke, and every authored trick shot and Behind the 8-Ball escape, the
    /// hardest at 6.45 m/s with a window to 6.60, lies inside it (StrokeModel's bound check).
    static let house: CueProfile = {
        let p = PoolParameters()
        let factor = launchPerSwing(cueMass: p.cueMass, tipRestitution: houseTipRestitution)
        return CueProfile(id: houseID, name: String(localized: "House cue"), cueMass: p.cueMass,
                          shaftEndMass: p.shaftEndMass, tipGrip: p.tipGrip, tipRestitution: houseTipRestitution,
                          comfortableTopSwing: PlayerShotSpeed.rackBreak.lowerBound / factor, length: houseLength)
    }()

    // MARK: The other cues (art/equipment)

    /// The house cue's design weight in ounces, from house-maple.blend's collection (target_mass_oz = 19). The other
    /// cues' weights are read from their own files in the same unit and scaled against it, so the house cue keeps the
    /// solver's exact 0.54 kg (19 oz is 0.5386 kg, within half a percent of it) and every other cue stands in the
    /// art's own ratio to it.
    private static let houseOunces = 19.0

    /// A cue other than the house cue: the house cue's tip (the same chalked leather on every model in the art, so the
    /// same grip and the same restitution) and the house cue's comfortable top swing. The comfortable top swing is the
    /// player's arm, not the cue: power is swing speed on one scale whatever is in the hand, so the calm zone ends at
    /// the same swing and a different cue shows only in how fast the ball leaves.
    private static func cue(_ kind: CueKind, name: String, ounces: Double, shaftEndMass: Double,
                            length: Double) -> CueProfile {
        CueProfile(id: kind.rawValue, name: name, cueMass: house.cueMass * ounces / houseOunces,
                   shaftEndMass: shaftEndMass, tipGrip: house.tipGrip, tipRestitution: house.tipRestitution,
                   comfortableTopSwing: house.comfortableTopSwing, length: length)
    }

    /// The break cue: oxblood-break.blend, 21 oz (0.597 kg) and 1.47 m. Two ounces over the house cue, so the same
    /// swing sends the ball about 2 percent faster ((1.75 x 0.597 / 0.767) / 1.331 = 1.023). Its shaft and tip are
    /// the house cue's shape (the art turns them from the same profile), so the same end mass.
    static let breakCue = cue(.breakCue, name: String(localized: "Break cue"), ounces: 21,
                              shaftEndMass: house.shaftEndMass, length: 1.47)

    /// The jump cue: amber-jump.blend, 10 oz (0.284 kg) and 1.05 m, short so the butt clears the player's body when
    /// the cue is raised steeply. Light, so the same swing sends the ball about 18 percent slower
    /// ((1.75 x 0.284 / 0.454) / 1.331 = 0.822): a jump is a short, fast stab. The shaft is the house cue's taper.
    static let jump = cue(.jump, name: String(localized: "Jump cue"), ounces: 10,
                          shaftEndMass: house.shaftEndMass, length: 1.05)

    /// The massé cue: masse-cue.blend, 24 oz (0.682 kg) and 1.26 m, short and heavy so a steep stroke stays steady.
    /// The same swing sends the ball about 5 percent faster ((1.75 x 0.682 / 0.852) / 1.331 = 1.052). Its tip and
    /// ferrule are broad (7.6 mm radius against the house cue's 6.4 mm, measured on the model), and a shaft end's
    /// mass goes with its cross-section, so its end mass is the house cue's times (7.6 / 6.4)^2 = 1.41.
    static let masse = cue(.masse, name: String(localized: "Massé cue"), ounces: 24,
                           shaftEndMass: house.shaftEndMass * (7.6 / 6.4) * (7.6 / 6.4), length: 1.26)

    /// A plain playing cue: rosewood-four-point.blend, 18 oz (0.512 kg) and 1.47 m, one ounce under the house cue
    /// (the same swing sends the ball about 1 percent slower). Same shaft and tip as the house cue.
    static let rosewoodFourPoint = cue(.rosewoodFourPoint, name: String(localized: "Rosewood cue"), ounces: 18,
                                       shaftEndMass: house.shaftEndMass, length: 1.47)

    /// A plain playing cue: cobalt.blend, 19.5 oz (0.554 kg) and 1.47 m, with a carbon shaft. Its art and the cue
    /// plan describe a lightweight shaft nose; with no measured figure for this fictional cue the end mass is set to
    /// three quarters of the house cue's, a game-design value (not measured) that makes it the low-deflection cue of
    /// the set: side spin pushes the ball off line about a quarter less.
    static let cobalt = cue(.cobalt, name: String(localized: "Cobalt cue"), ounces: 19.5,
                            shaftEndMass: house.shaftEndMass * 0.75, length: 1.47)

    /// Every cue, in CueKind's order: the house cue first, then the four the pick or the plain set adds.
    static let all: [CueProfile] = CueKind.allCases.map { CueProfile.profile(for: $0) }

    /// The profile of a kind of cue.
    static func profile(for kind: CueKind) -> CueProfile {
        switch kind {
        case .house: return house
        case .breakCue: return breakCue
        case .jump: return jump
        case .masse: return masse
        case .rosewoodFourPoint: return rosewoodFourPoint
        case .cobalt: return cobalt
        }
    }

    /// The default cue, which BreakdownTests/StrokeTests asserts is the house cue with a launch speed bit-identical to
    /// the power. The cue for a given shot is the model's cueInHand (profile(for: cueChoice.kind)), not this.
    static var selected: CueProfile { house }

    // MARK: The automatic pick

    /// The least cue angle (sine) at which a raised cue with little side is played with the jump cue: sin 30 degrees.
    /// Every authored jump lies above it (Jump the Blocker's window starts at sine 0.50, the jump lesson is struck at
    /// 40 degrees, the Behind the 8-Ball jumps at sines 0.70 to 0.85), while a cue raised only to clear a ball in the
    /// way (Reach's clearing angle, typically a few degrees) or a jacked-up stroke stays with the house cue.
    static let jumpElevation = 0.5
    /// The least cue angle (sine) at which a raised cue with side is played with the massé cue: sin 20 degrees. The
    /// authored curves lie above it (the curve lesson at 25 degrees, The Massé's window from sine 0.38, the Behind the
    /// 8-Ball curves at 0.40 and more), while a swerve, a gentle bend off a slightly raised cue, stays with the house
    /// cue.
    static let masseElevation = sin(20 * Double.pi / 180)
    /// The least side offset (metres) that makes a raised stroke a massé rather than a jump: a tenth of the pool
    /// ball's radius (2.9 mm). Below it a raised cue drives the ball into the slate with no worthwhile curve (the
    /// jumps are authored within half a millimetre of centre); the authored curves use 3 mm and more.
    static let masseSide = 0.1 * PoolParameters().ballRadius

    /// The cue for a strike: the break cue for a break, the massé cue for a steeply raised cue with side, the jump
    /// cue for a steeply raised cue without side, the house cue for everything else. `elevation` is the sine of the
    /// cue's angle above the table (the strike's own: the player's angle or the clearing angle, whichever is larger),
    /// `tipUp` and `tipSide` the contact offsets in metres. A break is struck level (the model passes elevation 0), so
    /// it is decided first. A pure rule: the model applies it in free play and matches; authored modes keep the house
    /// cue (see the file header).
    static func choice(isBreak: Bool, elevation: Double, tipUp: Double, tipSide: Double) -> CueChoice {
        if isBreak { return CueChoice(kind: .breakCue, reason: .breakShot) }
        if elevation >= masseElevation && abs(tipSide) >= masseSide {
            return CueChoice(kind: .masse, reason: .steepMasse)
        }
        // tipUp does not change the pick: a jump is struck at or a little below centre and a massé anywhere off
        // centre, so the side offset alone tells the two apart. It is taken so the pick can grow without a new call.
        if elevation >= jumpElevation { return CueChoice(kind: .jump, reason: .jump) }
        return .standard
    }

    // MARK: Power, swing and launch

    /// The ball's launch speed for a power setting with this cue. Power is house-cue-equivalent launch speed, so for
    /// another cue it is scaled by that cue's launch per swing over the house cue's. For the house cue the power is
    /// returned untouched: not multiplied by a ratio that happens to be one, so the strike is bit for bit what it was.
    func launchSpeed(forPower power: Double) -> Double {
        if isHouse { return power }
        return power * (launchPerSwing / Self.house.launchPerSwing)
    }

    /// The power setting that launches the ball at `speed` with this cue: the inverse of launchSpeed(forPower:). An
    /// authored power (a house-cue launch speed) played with another cue needs this power for the ball to leave
    /// exactly as authored; for the house cue it is the speed itself, untouched.
    func power(forLaunchSpeed speed: Double) -> Double {
        if isHouse { return speed }
        return speed * (Self.house.launchPerSwing / launchPerSwing)
    }

    /// The swing a power setting stands for, metres per second of tip speed: the power over the house cue's launch per
    /// swing. The same for every cue, because power is the swing measured in house-cue units.
    static func swing(forPower power: Double) -> Double { power / house.launchPerSwing }

    /// The power setting that is a given swing (the inverse of swing(forPower:)).
    static func power(forSwing swing: Double) -> Double { swing * house.launchPerSwing }
}
