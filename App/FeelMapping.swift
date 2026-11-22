// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (sound plan packages 1 to 4: every cue now carries the table point it
//          happened at, for panning; new kinds for a pin knocked down, a post, a jump landing, a ball leaving the table,
//          a rim skip, a miscue, balls settling in contact, the knocks of a ball settling in a pocket, and three match
//          moments (foul, turn change, win); the pocket's settling knocks are timed from the ball's entry speed.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 36: two made-it moments, madeIt and madeItBig, for a
//          lesson passed, the stop shot's exercise made, a trick shot made and a medal won; madeItBig for a gold medal and
//          the sixth lesson. GameMoment.medal(_:) picks between them for a medal. Ordinary voices on every surface.)
// PURPOSE: One pure place that turns the recorded impacts crossed in a frame into "feel cues" (what kind of
//          thump or click, how strong, how long after the first, and where on the table). SoundBoard and Haptics
//          both read these cues, so sight, sound and touch are all driven by the same recorded number and can never
//          disagree. The break drops about thirty contacts at the same instant; this file collapses them into one
//          sharp crack plus a few quieter scatter clicks, instead of thirty overlapping sounds. No audio or haptic
//          framework is imported here, so the mapping is easy to log, reason about and test. Match screens use
//          GameMoment (through SoundBoard.play(_:)) for the three moments that are not table impacts; the lesson,
//          trick-shot and Behind the 8-Ball screens use it for the two made-it moments, from the same place that starts
//          their success glow (LessonTableLayer, TrickTableLayer, EightBallTableLayer).
// SRP/DRY check: Pass - mapping only; SoundBoard makes noise and Haptics makes touch. Replaces the strength
//          formula that used to live inside SoundBoard. Physical constants (ball mass, gravity, pocket size) are read
//          from PoolParameters, not copied.
import BreakdownLensModel
import BreakdownPhysics
import Foundation

/// What a cue sounds and feels like.
enum FeelKind: String, Sendable {
    case crack      // the break: the rack bursting apart
    case click      // ball meets ball
    case tock       // the cue tip meeting the cue ball
    case cushion    // ball meets rail (or a pocket jaw or knuckle)
    case pocket     // ball drops over the edge of a pocket
    case knock      // the ball knocking inside the pocket as it settles (back wall, landing, bounces)
    case pin        // a standing pin knocked over
    case post       // ball meets a fixed round post
    case landing    // a jumping ball coming down on the bed
    case offTable   // a ball that flew off the table hitting the floor
    case rimSkip    // a ball rattling across a hole too fast to drop
    case miscue     // the cue tip slipping off the ball
    case settle     // a wedged group of balls brought to rest touching
    case foul       // match moment: a foul was called
    case turnChange // match moment: the other player is up
    case win        // match moment: the match is won
    case madeIt     // a lesson passed, a trick shot made, a medal won
    case madeItBig  // the bigger one: a gold medal, the sixth lesson

    /// True for sounds of the table itself (they come from a point on the table and stop the title music); false for
    /// the game's own moments, which are the game speaking, centred, and only dip the music.
    var isTableSound: Bool {
        switch self {
        case .foul, .turnChange, .win, .madeIt, .madeItBig: return false
        default: return true
        }
    }
}

/// One thing to play: a kind, a strength from 0 to 1, a small delay after the frame's first cue, and where on the
/// table it happened (table metres; nil for the match moments, which play centred).
struct FeelCue: Equatable, Sendable {
    var kind: FeelKind
    var strength: Double
    var delay: Double
    var point: Vec2? = nil
}

/// The moments a screen can sound, through SoundBoard.play(_:). Each plays its voice and its haptic together (the two
/// made-it moments have no haptic pattern of their own: Haptics explains why).
enum GameMoment: Sendable {
    case foul, turnChange, win
    /// A lesson passed, the stop shot's exercise made, a trick shot made, a medal won: played from the same change
    /// that starts the screen's success glow, so the sound lands with the light.
    case madeIt
    /// The bigger made-it: a gold medal, and the sixth lesson (the end of the path).
    case madeItBig

    var kind: FeelKind {
        switch self {
        case .foul: return .foul
        case .turnChange: return .turnChange
        case .win: return .win
        case .madeIt: return .madeIt
        case .madeItBig: return .madeItBig
        }
    }

    /// The strength each moment plays at (it picks the voice's strength layer and the haptic's intensity). A turn
    /// change happens every few shots, so it is the softest; a foul must be noticed; a win is the one big moment. A
    /// made-it sits in the third of the four layers (VoiceBook.strengths), a little darker than its big one, which
    /// plays in the top layer like a win.
    var strength: Double {
        switch self {
        case .foul: return 0.6
        case .turnChange: return 0.35
        case .win: return 0.9
        case .madeIt: return 0.6
        case .madeItBig: return 0.9
        }
    }

    /// The made-it moment for a Behind the 8-Ball medal: the big one for gold, the ordinary one for silver and bronze
    /// (and for no medal, which never celebrates, so it is never asked for).
    static func medal(_ medal: EightBallMedal?) -> GameMoment {
        medal == .gold ? .madeItBig : .madeIt
    }
}

enum FeelMapping {
    /// Cues below this strength are inaudible and unfelt, so they are dropped.
    static let floor = 0.05
    /// A burst of at least this many ball contacts, led by a hard one, is the break.
    static let crackMinContacts = 3
    static let crackMinStrength = 0.8
    /// Most scatter clicks that follow a crack, and most rail thumps or ball clicks per frame.
    static let maxScatter = 3
    static let maxPerKind = 2

    /// The standard table's numbers (ball mass, gravity, pocket size) for the cues worked out from physics below.
    /// Deliberately the standard ones whatever the surface: the Boss decided the Moon plays the ordinary voices.
    private static let table = PoolParameters()

    /// Impulse (newton-seconds) to a 0...1 strength. The recorded impulses span about 0.002 to 2.2, so the
    /// curve is compressed (power 0.6) to keep light contacts audible and hard ones from all sounding the same.
    static func strength(impulse: Double) -> Double {
        pow(min(1, max(0, impulse) / 2.0), 0.6)
    }

    /// Ball speed (m/s) to a 0...1 strength: 2 m/s and up is full strength, the same full scale the pocket has always
    /// used (a firm shot; a hard break sends balls off faster, and they are all simply "full").
    static func strength(speed: Double) -> Double {
        min(1, max(0, speed) / 2.0)
    }

    /// The speed a ball came into a pocket or across a hole: the recorded entry when the solver gives one (generation
    /// two), else the ball's speed just before the event.
    static func entrySpeed(_ e: LensEvent) -> Double {
        if let entry = e.entry { return entry.speed }
        return e.balls.first?.velocityBefore.length ?? 0
    }

    /// A ball dropping is recorded with no impulse, so its strength comes from the speed it arrived at.
    static func pocketStrength(_ e: LensEvent) -> Double {
        guard !e.balls.isEmpty else { return 0.6 }
        return max(0.4, strength(speed: entrySpeed(e)))
    }

    // MARK: Pocket settling knocks

    /// How far below the cloth the bottom of a pocket is, metres. Assumed one ball diameter: the ball drops out of
    /// sight into the liner or net and lands there. Stated as an assumption, not a measurement.
    static var pocketDepth: Double { 2 * table.ballRadius }
    /// Bounce of a ball on the soft bottom of a pocket (leather or net). Assumed 0.4, well under the slate's 0.5:
    /// the liner gives. It sets how fast the knocks die away.
    static let pocketBottomBounce = 0.4

    /// The knocks a ball makes settling in a pocket after it drops, as (delay after the drop, strength), timed from
    /// the entry speed `v` (m/s):
    /// 1. A ball fast enough reaches the back of the pocket before it has fallen below the rim and knocks it. It
    ///    crosses about one capture radius in `r / v` seconds, and falls one ball radius in sqrt(2R / g) seconds, so
    ///    the back-wall knock happens only when r / v is the shorter of the two: above about 0.85 m/s on a corner.
    /// 2. Every ball then lands on the pocket bottom after falling `pocketDepth`: sqrt(2h / g) seconds, at speed
    ///    sqrt(2gh).
    /// 3. It bounces: each bounce lasts 2 e^k v_land / g and is e^k as strong, so the knocks come quicker and softer,
    ///    the rattle of a ball settling. Bounces shorter than a hundredth of a second blur into one sound and stop.
    /// Strengths go through the same impulse curve as every other hit (impulse = mass x speed change).
    static func pocketKnocks(entrySpeed v: Double) -> [(delay: Double, strength: Double)] {
        let g = table.gravity, m = table.ballMass, e = pocketBottomBounce
        var out: [(delay: Double, strength: Double)] = []
        let backDistance = table.cornerCaptureRadius
        let dropOneRadius = (2 * table.ballRadius / g).squareRoot()
        if v > 0, backDistance / v < dropOneRadius {
            out.append((backDistance / v, strength(impulse: m * v * (1 + e))))
        }
        let fall = (2 * pocketDepth / g).squareRoot()
        let landSpeed = (2 * g * pocketDepth).squareRoot()
        var at = fall
        var speed = landSpeed
        for _ in 0..<4 {
            let s = strength(impulse: m * speed * (1 + e))
            guard s >= floor else { break }
            out.append((at, s))
            speed *= e
            let flight = 2 * speed / g
            guard flight >= 0.01 else { break }
            at += flight
        }
        return out
    }

    // MARK: A ball leaving the table

    /// Height of the bed above the floor, metres: the middle of the usual 0.74 to 0.79 m. Sets how long a ball that
    /// flies off the table falls before the floor thud, and how hard it lands.
    static let bedHeight = 0.76
    /// Bounce of a ball on a hard floor, assumed the same as on slate (0.5). Used for the floor impulse.
    static let floorBounce = 0.5

    /// The floor thud of a ball that left the table: after the fall time sqrt(2h / g), with the impulse of the landing.
    static var offTableThud: (delay: Double, strength: Double) {
        let g = table.gravity
        let v = (2 * g * bedHeight).squareRoot()
        return ((2 * bedHeight / g).squareRoot(), strength(impulse: table.ballMass * v * (1 + floorBounce)))
    }

    // MARK: The mapping

    /// Collapse the events crossed in one frame into the cues to play. Events of any order are accepted.
    static func cues(for events: [LensEvent]) -> [FeelCue] {
        var out: [FeelCue] = []

        // Ball contacts, strongest first.
        let contacts = events.filter { $0.kind == .ballBall }
            .map { (s: strength(impulse: $0.normalImpulse), at: $0.point) }
            .sorted { $0.s > $1.s }
        if let lead = contacts.first, contacts.count >= crackMinContacts, lead.s >= crackMinStrength {
            out.append(FeelCue(kind: .crack, strength: lead.s, delay: 0, point: lead.at))
            // The scattering balls: a few quieter clicks trailing the crack by a few hundredths of a second.
            for (i, c) in contacts.dropFirst().prefix(maxScatter).enumerated() where c.s * 0.6 >= floor {
                out.append(FeelCue(kind: .click, strength: c.s * 0.6, delay: 0.018 * Double(i + 1), point: c.at))
            }
        } else {
            for (i, c) in contacts.prefix(maxPerKind).enumerated() where c.s >= floor {
                out.append(FeelCue(kind: .click, strength: c.s, delay: 0.012 * Double(i), point: c.at))
            }
        }

        // Rails, jaws and knuckles; posts have their own voice.
        let cushions = events.filter { $0.kind == .cushion }
        for (i, e) in cushions.filter({ $0.edge != .post })
            .sorted(by: { $0.normalImpulse > $1.normalImpulse }).prefix(maxPerKind).enumerated() {
            let s = strength(impulse: e.normalImpulse)
            if s >= floor { out.append(FeelCue(kind: .cushion, strength: s, delay: 0.015 * Double(i), point: e.point)) }
        }
        for (i, e) in cushions.filter({ $0.edge == .post })
            .sorted(by: { $0.normalImpulse > $1.normalImpulse }).prefix(maxPerKind).enumerated() {
            let s = strength(impulse: e.normalImpulse)
            if s >= floor { out.append(FeelCue(kind: .post, strength: s, delay: 0.015 * Double(i), point: e.point)) }
        }

        // The cue tip: a clean tock, or the scrape of a miscue when the tip slipped off.
        if let cue = events.first(where: { $0.kind == .cueStrike }) {
            let s = strength(impulse: cue.normalImpulse)
            out.append(FeelCue(kind: cue.miscue == true ? .miscue : .tock, strength: s, delay: 0, point: cue.point))
        }

        // The strongest drop of the frame, then its settling knocks timed from the entry speed.
        if let pocket = events.filter({ $0.kind == .pocket }).max(by: { pocketStrength($0) < pocketStrength($1) }) {
            out.append(FeelCue(kind: .pocket, strength: pocketStrength(pocket), delay: 0, point: pocket.point))
            for k in pocketKnocks(entrySpeed: entrySpeed(pocket)) {
                out.append(FeelCue(kind: .knock, strength: k.strength, delay: k.delay, point: pocket.point))
            }
        }

        // A ball rattling across a hole too fast to drop: as strong as the speed it came in at.
        if let skip = events.filter({ $0.kind == .rimSkip }).max(by: { entrySpeed($0) < entrySpeed($1) }) {
            let s = max(0.2, strength(speed: entrySpeed(skip)))
            out.append(FeelCue(kind: .rimSkip, strength: s, delay: 0, point: skip.point))
        }

        // Pins knocked over: as strong as the ball that hit them.
        for (i, e) in events.filter({ $0.kind == .pinDown }).prefix(maxPerKind).enumerated() {
            let s = max(0.2, strength(speed: e.balls.first?.velocityBefore.length ?? 0))
            out.append(FeelCue(kind: .pin, strength: s, delay: 0.02 * Double(i), point: e.point))
        }

        // Jumps: a landing on the bed (impulse = mass x the vertical speed change, down plus back up), and a ball that
        // flew off the table, heard when it hits the floor after its fall.
        let flights = events.filter { $0.kind == .phaseTransition }
        if let land = flights.filter({ $0.flight == .landing })
            .max(by: { $0.verticalSpeedDown < $1.verticalSpeedDown }) {
            let s = strength(impulse: table.ballMass * (land.verticalSpeedDown + land.verticalSpeedUp))
            if s >= floor { out.append(FeelCue(kind: .landing, strength: s, delay: 0, point: land.point)) }
        }
        if let gone = flights.first(where: { $0.flight == .offTable }) {
            let thud = offTableThud
            out.append(FeelCue(kind: .offTable, strength: thud.strength, delay: thud.delay, point: gone.point))
        }

        // A jam brought to rest: as strong as a ball carrying the energy taken out would be at that speed. A ball
        // rolling at v carries 0.7 m v^2 (translation plus rolling spin), so v = sqrt(E / 0.7 m). Never loud: it is
        // the sound of balls easing into each other, capped at a soft 0.5.
        if let jam = events.filter({ $0.kind == .settledInContact }).max(by: { ($0.energyRemoved ?? 0) < ($1.energyRemoved ?? 0) }) {
            let v = (max(0, jam.energyRemoved ?? 0) / (0.7 * table.ballMass)).squareRoot()
            let s = min(0.5, max(0.1, strength(speed: v)))
            out.append(FeelCue(kind: .settle, strength: s, delay: 0, point: jam.point))
        }
        return out
    }
}
