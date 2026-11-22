// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 foundation, docs/v07-contracts.md section 1.3: the two
//          declarations the equipment stream fills for the automatic cue pick (plan item 57): CueKind, every cue that
//          has art in art/equipment, and CueChoice, the cue picked for a shot with the reason it was picked. Nothing
//          reads them yet; the house cue and every solve are unchanged.)
// PURPOSE: The cue as numbers (plans/21-Nov-2026-stroke-and-power-plan.md). Power in Breakdown means how hard the
//          player swings, not how fast the ball leaves, so the cue's weight matters: the same swing sends the ball
//          faster with a heavier cue. The model's power value stays exactly what it has always been, the launch speed
//          of a centre hit with the house cue ("house-cue-equivalent launch speed"), so every authored shot, every
//          saved setting and every solve with the house cue is unchanged bit for bit. This file says what that number
//          becomes for another cue (launchSpeed) and what swing it stands for (swing, the tip's speed), and gives each
//          cue its comfortable top swing, where the calm zone of the power bar ends (StrokeModel).
//          Only the house cue exists today. The equipment work (plans/21-Nov-2026-cues-and-bridges-plan.md) adds its
//          cues to `all` and makes one of them `selected`; this is the one place they plug in, and nothing else needs
//          to know which cue is in the player's hands.
// SRP/DRY check: Pass - checked PoolParameters (cueMass, shaftEndMass, tipGrip and ballMass are read from it, not
//          retyped), PlayerShotSpeed (the house cue's comfortable top swing is derived from the break range there) and
//          PowerWords (the plain words stay there; this file has numbers only).
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
    /// A fixed identifier, never shown: saved choices and comparisons use it.
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

    /// The house cue, read from the physics parameters so the cue and the solver can never disagree. Its comfortable
    /// top swing is the swing that launches the softest break (PlayerShotSpeed.rackBreak's lower edge): everything
    /// softer than a break is a controlled stroke, and every authored trick shot and Behind the 8-Ball escape, the
    /// hardest at 6.45 m/s with a window to 6.60, lies inside it (StrokeModel's bound check).
    static let house: CueProfile = {
        let p = PoolParameters()
        let factor = launchPerSwing(cueMass: p.cueMass, tipRestitution: houseTipRestitution)
        return CueProfile(id: houseID, name: String(localized: "House cue"), cueMass: p.cueMass,
                          shaftEndMass: p.shaftEndMass, tipGrip: p.tipGrip, tipRestitution: houseTipRestitution,
                          comfortableTopSwing: PlayerShotSpeed.rackBreak.lowerBound / factor)
    }()

    /// Every cue the player can pick. The equipment work appends its cues here.
    static let all: [CueProfile] = [house]

    /// The cue in the player's hands. Always the house cue until the equipment work adds a choice; it then reads the
    /// stored choice here, and every caller (the strike, the readout, the zones) follows.
    static var selected: CueProfile { house }

    // MARK: Power, swing and launch

    /// The ball's launch speed for a power setting with this cue. Power is house-cue-equivalent launch speed, so for
    /// another cue it is scaled by that cue's launch per swing over the house cue's. For the house cue the power is
    /// returned untouched: not multiplied by a ratio that happens to be one, so the strike is bit for bit what it was.
    func launchSpeed(forPower power: Double) -> Double {
        if isHouse { return power }
        return power * (launchPerSwing / Self.house.launchPerSwing)
    }

    /// The swing a power setting stands for, metres per second of tip speed: the power over the house cue's launch per
    /// swing. The same for every cue, because power is the swing measured in house-cue units.
    static func swing(forPower power: Double) -> Double { power / house.launchPerSwing }

    /// The power setting that is a given swing (the inverse of swing(forPower:)).
    static func power(forSwing swing: Double) -> Double { swing * house.launchPerSwing }
}
