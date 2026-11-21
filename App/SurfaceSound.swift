// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: How each playing surface sounds (sound plan package 3): the colour of a ball rolling across it, how harsh a
//          skid is, and the tone of the rail thud and of a jump landing on it. SoundBoard picks the rail and landing
//          voices by tone and RollingVoices shapes its filtered noise from the rolling numbers. Read once a frame from
//          the surface the model reports (ShowpieceModel's physicsSurface, passed in SoundBoard.follow).
//          The Moon: decided by the Boss on 21-Nov-2026, no special sound, no rumble and no silence gimmick. It uses
//          exactly the cloth row; only its physics (six times longer rolls, high jumps) changes what is heard.
//          The rolling numbers are by-ear starting points with a stated reason each, to be tuned when the Boss listens;
//          nothing here is a measurement. Levels are player volumes (0 to 1) on the shared mix, where the hardest ball
//          click sits at about 0.75 and the break at 1.
// SRP/DRY check: Pass - checked PlaySurface (owns the physics numbers; this reads its cushion bounce rather than
//          repeating it) and PlaySurfaceLook (the picture of each surface, nothing about sound).
import BreakdownPhysics

/// The tone of a hard contact on a surface: bright (a hard bed rings), standard (cloth over slate), dull (a soft bed
/// swallows the ring). SoundBoard builds the rail and landing voices once per tone.
enum BedTone: Hashable, Sendable, CaseIterable {
    case bright, standard, dull
}

struct SurfaceSound: Equatable, Sendable {
    /// Loudness of a ball rolling at full speed (2 m/s), as a player volume.
    let rollLevel: Double
    /// Centre of the band of noise a ball rolling at full speed makes, hertz (it drops toward half of this as the ball
    /// slows, and with slow motion).
    let rollCutoff: Double
    /// How much harsher a skidding (sliding) ball sounds than a rolling one: the share of the rolling level added as
    /// scratchy crackle while the ball slides.
    let slideGrit: Double
    /// The tone of a jump landing on this bed.
    let bed: BedTone
    /// The tone of the rail thud.
    let rail: BedTone

    init(_ surface: PlaySurface) {
        let roll: (level: Double, cutoff: Double, grit: Double, bed: BedTone)
        switch surface {
        case .cloth, .moon:
            // The reference: a soft woollen hush centred low in the speech band. The Moon is cloth (Boss decision).
            roll = (0.32, 900, 0.6, .standard)
        case .tournament:
            // Tight napless worsted: smoother and a touch brighter and quieter than the standard cloth.
            roll = (0.28, 1_050, 0.5, .standard)
        case .diveBar:
            // Napped, dirty felt: a coarser, darker rumble, and a skid that drags.
            roll = (0.36, 700, 0.8, .standard)
        case .ice:
            // Hard and smooth: a thin, high hiss; a skid on ice is a scrape, so the grit is high.
            roll = (0.24, 2_600, 0.9, .bright)
        case .glass:
            // Hard and ringing: the brightest roll of all (the plan: "glass is bright").
            roll = (0.34, 3_200, 0.8, .bright)
        case .rubber:
            // Soft and grippy: a dull hum; it barely skids, so little grit.
            roll = (0.2, 500, 0.4, .dull)
        case .cork:
            // Soft grain: low and quiet.
            roll = (0.18, 450, 0.35, .dull)
        case .carpet:
            // Thick pile soaks up the sound: quieter and darker than any cloth.
            roll = (0.14, 400, 0.3, .dull)
        case .sand:
            // The plan: "sand is nearly silent and dull": a faint low shush of a ball ploughing.
            roll = (0.06, 250, 0.2, .dull)
        }
        rollLevel = roll.level
        rollCutoff = roll.cutoff
        slideGrit = roll.grit
        bed = roll.bed
        // The rail thud follows the rubber first: lively cushions (bounce 0.88 or more, the tournament cloth's 0.9) ring
        // brighter and dead ones (0.7 or less, the dive bar's 0.65) thud dull, since rubber that returns less of the
        // ball's speed also damps its own ring faster. The standard cushions' 0.85 sits between, so on every other
        // surface the bed under the ball decides, as it does for a landing.
        let bounce = surface.parameters.cushionRestitution
        if bounce >= 0.88 { rail = .bright } else if bounce <= 0.7 { rail = .dull } else { rail = roll.bed }
    }
}
