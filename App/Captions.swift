// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (jaw and knuckle hits get their own caption: "Off the jaw" or "Clipped the point").
// Edited: Claude Haiku 5.5 High, 20-November-2026 (every sentence is a whole localized string, so translators can reorder it; numbers are formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (no more thinning to one caption per quarter second: every
//          captioned event is kept, so the rack explosion's dozen hits survive for PacePlan to choose beats from;
//          speed gates lowered so second-wave rack hits are captioned while dribbles still are not).
// Edited: Claude Opus 5.5 High, 21-November-2026 (off the standard cloth, when a surface also changes the cushions, the strike caption adds how much speed its rails give back).
// Edited: Claude Opus 5.5 High, 21-November-2026 (playing surfaces: make(from:surface:) takes the surface the shot was
//          solved on. Off cloth, the cue-strike caption adds a sentence comparing that surface's friction (or, on the
//          Moon, its gravity) with cloth's and saying how much farther or shorter a ball skids and rolls; the
//          skid-turns-into-roll caption names the surface, its sliding friction and gravity, and the skid's real length
//          in seconds read from the timeline. On cloth the wording is unchanged; that caption's equation is now the
//          skid-time formula on every surface.)
// PURPOSE: Turns solver events into the plain-language captions and equations the Physics Lens shows. Every
//          number in a caption is read from the recorded event (pillar one: nothing is drawn that the solver
//          did not compute). Every event that clears its speed gate gets a caption, sorted by time; choosing which
//          ones the replay stops on is PacePlan's job. Words the player reads go through String(localized:) so they
//          land in the string catalog. Surface numbers are read from PlaySurface.parameters, the same values the
//          solver was given, and every ratio is worked out from them, never typed in.
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: captions for a ball thrown back by a post and for a pin
//          knocked down, both with the speeds read from the event).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the two generation-two event kinds, rim skip and settled in
//          contact, are named in the switch and get no caption yet; the solver work that records them adds the words.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the solver's new physics gets its words: "Too fast for the pocket"
//          on a rim skip, "Wedged and settled" when the jam guard brings a group to rest, "The rail pushes it into the
//          cloth" on a generation-two rail hit (its bed impulse), and three cue-strike captions on generation two:
//          a miscue, "Side spin pushes the cue ball off line" and "Off-centre hits are slower". Every number is read
//          from the event; the off-centre share and the speed lost are worked out from the event's own spin, speed and
//          impulse with the same formula the solver used, and shown only where those numbers are a level strike's.)
// SRP/DRY check: Pass - caption selection and wording only; display lives in the view.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

enum CaptionAccent { case strike, impact, cushion, friction, pocket }

struct Caption: Identifiable, Equatable {
    let id: Int
    let time: Double
    let title: String
    let detail: String
    let equation: String
    let accent: CaptionAccent
    let importance: Double
}

enum CaptionEngine {
    /// The numbers a caption needs about the surface the shot was solved on, next to cloth's for comparison.
    private struct SurfaceFacts {
        let surface: PlaySurface
        let p: PoolParameters
        let cloth: PoolParameters
        /// The Moon (or any surface) with cloth's friction and a different gravity: gravity is the whole story.
        var gravityOnly: Bool {
            p.gravity != cloth.gravity && p.slidingFriction == cloth.slidingFriction
                && p.rollingResistance == cloth.rollingResistance
        }
    }

    /// `surface` is the one the timeline was solved on (ShowpieceModel.physicsSurface), so the numbers explained are
    /// the numbers used.
    static func make(from timeline: Timeline, surface: PlaySurface) -> [Caption] {
        let facts = SurfaceFacts(surface: surface, p: surface.parameters, cloth: PlaySurface.cloth.parameters)
        var all: [Caption] = []
        for (index, e) in timeline.events.enumerated() {
            if let c = caption(for: e, id: index, timeline: timeline, facts: facts) { all.append(c) }
        }
        // All of them, in clock order. Events arrive sorted already; the explicit sort with the event index as the
        // tie-break keeps simultaneous rack hits in one fixed order whatever the solver's ordering guarantees.
        // The id stays the event's index: the on-table marker finds its ball through it.
        return all.sorted { ($0.time, $0.id) < ($1.time, $1.id) }
    }

    /// A ball's name as a player would say it. Each form is a whole phrase, so a translator can reorder it.
    private static func name(_ ball: Int) -> String {
        ball == 0 ? String(localized: "the cue ball") : String(localized: "the \(ball) ball")
    }

    /// A number with the decimal places asked for, written the way the player's language writes numbers.
    private static func f(_ x: Double, _ digits: Int = 1) -> String {
        String(format: "%.\(digits)f", locale: Locale.current, x)
    }

    /// A friction number with its meaningful digits (0.2, 0.025, 0.0025), in the player's number style.
    private static func coefficient(_ x: Double) -> String {
        x.formatted(.number.precision(.significantDigits(1...2)))
    }

    /// A "times as far" ratio: one decimal below 10 (8, 6.1, 0.4), whole numbers above (12).
    private static func ratio(_ x: Double) -> String {
        x < 10 ? x.formatted(.number.precision(.fractionLength(0...1))) : x.formatted(.number.precision(.fractionLength(0)))
    }

    /// The extra sentence on the cue-strike caption off cloth. Skid distance goes as 1 / (sliding friction * g) and
    /// roll distance as 1 / (rolling resistance * g) (Simulation.makeSegment: the decelerations are mu * g and c_r * g),
    /// so the ratios to cloth are worked out from the solver's own numbers. Nil on cloth.
    private static func surfaceSentence(_ s: SurfaceFacts) -> String? {
        guard s.surface != .cloth else { return nil }
        let skid = (s.cloth.slidingFriction * s.cloth.gravity) / (s.p.slidingFriction * s.p.gravity)
        let roll = (s.cloth.rollingResistance * s.cloth.gravity) / (s.p.rollingResistance * s.p.gravity)
        if s.gravityOnly {
            // Same friction numbers, weaker gravity: the friction force is the friction number times the weight, and
            // the weight is mass times g, so both distances grow by the same ratio of gravities.
            return String(localized: "On the Moon the friction numbers are the same as on cloth, but gravity is \(f(s.p.gravity)) m/s² instead of \(f(s.cloth.gravity)). Friction pushes back with the friction number times the ball's weight, and weight is mass times gravity, so a ball skids about \(ratio(skid)) times as far before it rolls and rolls about \(ratio(roll)) times as far.")
        }
        let friction = String(localized: "On \(s.surface.title) the sliding friction is \(coefficient(s.p.slidingFriction)) and the rolling resistance \(coefficient(s.p.rollingResistance)) (cloth: \(coefficient(s.cloth.slidingFriction)) and \(coefficient(s.cloth.rollingResistance))), so a ball skids about \(ratio(skid)) times as far before it rolls and rolls about \(ratio(roll)) times as far.")
        // The real cloths also change the rails (fresh rubber on the tournament table, dead rubber in the bar).
        guard s.p.cushionRestitution != s.cloth.cushionRestitution else { return friction }
        let rails = String(localized: "The cushions give back \(coefficient(s.p.cushionRestitution)) of the speed driven into them (standard table: \(coefficient(s.cloth.cushionRestitution))).")
        return friction + " " + rails
    }

    /// How long the ball skidded before this sliding-to-rolling event: the sliding segment the solver closed at the
    /// event's time (Simulation.restart sets its end to exactly that time), from its start. Its start is the strike or
    /// the last impact that set the ball skidding again. Nil if no such segment is recorded.
    private static func skidDuration(ball: Int, endingAt t: Double, in timeline: Timeline) -> Double? {
        guard timeline.segments.indices.contains(ball) else { return nil }
        guard let seg = timeline.segments[ball].last(where: { $0.phase == .sliding && abs($0.t1 - t) < 1e-9 }) else {
            return nil
        }
        return t - seg.t0
    }

    /// Degrees from a sine (the solver records turns as sines; it has no trigonometry, the app does).
    private static func degrees(fromSine s: Double) -> Double {
        asin(min(1, max(-1, abs(s)))) * 180 / Double.pi
    }

    /// The generation-two cue-strike captions, or nil when none applies (generation 1, or a plain centre hit), in which
    /// case the usual strike caption is used. One caption per strike, in this order: a miscue, a visible push off line
    /// from side spin (half a degree or more), a noticeably slower off-centre hit (tip 15 percent of the radius or more
    /// out, which costs about four percent of the speed).
    private static func strikeCaption(for e: LensEvent, id: Int, timeline: Timeline, facts: SurfaceFacts) -> Caption? {
        guard let sine = e.deflectionSine else { return nil }       // generation 1 records no deflection
        let b = e.balls[0]
        let speed = b.velocityAfter.length
        let turn = degrees(fromSine: sine)
        if e.miscue == true {
            let mu = facts.p.tipGrip
            let limit = mu / (1 + mu * mu).squareRoot() * 100
            return Caption(id: id, time: e.time, title: String(localized: "Miscue"),
                           detail: String(localized: "The tip met the ball more than \(f(limit, 0)) percent of its radius from the centre, past where the tip can grip, and slid off. The ball leaves at only \(f(speed)) m/s, \(f(turn)) degrees off the line of the cue."),
                           equation: "b / R > μ / √(1 + μ²)", accent: .strike, importance: 1e9)
        }
        if turn >= 0.5 {
            // Positive sine: turned counter-clockwise, to the left of the cue, which is what a hit right of centre does.
            let detail = sine > 0
                ? String(localized: "Hit right of centre, the ball is pushed to the left, away from the side the tip struck: it leaves \(f(turn)) degrees off the line of the cue, at \(f(speed)) m/s. Side spin always costs a little aim.")
                : String(localized: "Hit left of centre, the ball is pushed to the right, away from the side the tip struck: it leaves \(f(turn)) degrees off the line of the cue, at \(f(speed)) m/s. Side spin always costs a little aim.")
            return Caption(id: id, time: e.time, title: String(localized: "Side spin pushes the cue ball off line"),
                           detail: detail, equation: "tan α = (5/2)·x·√(1 − x²) / (1 + m/mₑ + (5/2)·x²)",
                           accent: .strike, importance: 1e9)
        }
        // A level strike launches at exactly the recorded speed with impulse m * speed, and its spin is
        // 5/2 * speed * b / R^2 (Simulation.applyStrike), so b / R = spin * R / (5/2 * speed). A raised strike's
        // recorded velocity is after the slate, so its implied mass would not be the ball's: then no caption.
        guard speed > 0.05 else { return nil }
        let m = facts.p.ballMass
        guard abs(e.normalImpulse / speed - m) <= 1e-6 * m else { return nil }
        let R = timeline.table.ballRadius
        let x = b.omegaAfter.length * R / (2.5 * speed)
        guard x >= 0.15 else { return nil }
        let M = facts.p.cueMass
        let factor = (M + m) / (M + m + 2.5 * M * x * x)
        return Caption(id: id, time: e.time, title: String(localized: "Off-centre hits are slower"),
                       detail: String(localized: "The tip met the ball \(f(x * 100, 0)) percent of its radius from the centre, so part of the cue's push went into spin instead of speed. It leaves at \(f(speed)) m/s, \(f((1 - factor) * 100, 0)) percent slower than a centre hit with the same stroke."),
                       equation: "v = v₀ · (M + m) / (M + m + (5/2)·M·(b/R)²)", accent: .strike, importance: 1e9)
    }

    private static func caption(for e: LensEvent, id: Int, timeline: Timeline, facts: SurfaceFacts) -> Caption? {
        switch e.kind {
        case .cueStrike:
            if let special = strikeCaption(for: e, id: id, timeline: timeline, facts: facts) { return special }
            let b = e.balls[0]
            let spin = b.omegaAfter.length
            let speed = f(b.velocityAfter.length)
            let base = spin > 20
                ? String(localized: "The cue sends the ball off at \(speed) metres per second. Hitting below centre adds backspin, which the ball carries with it.")
                : String(localized: "The cue sends the ball off at \(speed) metres per second. Its momentum is mass times speed.")
            // Off cloth, one more sentence: what this surface's numbers do to the skid and the roll that follow.
            let detail = surfaceSentence(facts).map { base + " " + $0 } ?? base
            return Caption(id: id, time: e.time, title: String(localized: "The cue hands over its speed"), detail: detail,
                           equation: "p = m · v", accent: .strike, importance: 1e9)
        case .ballBall:
            guard e.balls.count == 2 else { return nil }
            let a = e.balls[0], b = e.balls[1]
            let (mover, other) = a.velocityBefore.length >= b.velocityBefore.length ? (a, b) : (b, a)
            let before = a.energyBefore + b.energyBefore
            // 0.4 m/s keeps the second wave through the rack (balls already moving pass the energy on) while
            // two balls nudging each other at walking pace stay quiet.
            guard mover.velocityBefore.length > 0.4, before > 0 else { return nil }
            let share = (other.energyAfter / before) * 100
            let keep = (mover.energyAfter / before) * 100
            let detail = String(localized: "\(name(mover.ball).capitalizedFirst) was moving at \(f(mover.velocityBefore.length)) m/s. Energy handed off: \(f(share, 0)) percent goes to \(name(other.ball)), \(f(keep, 0)) percent stays, and the rest is lost as heat and sound.")
            return Caption(id: id, time: e.time, title: String(localized: "Energy handed off"), detail: detail,
                           equation: "J = (1 + e) · m · v⊥ / 2", accent: .impact, importance: e.normalImpulse)
        case .cushion where e.edge == .post:
            // A post on another table (a bumper): it throws the ball back like a cushion, with its own bounce.
            let b = e.balls[0]
            let vin = b.velocityBefore.length
            guard vin > 0.5 else { return nil }
            let kept = (b.velocityAfter.dot(e.normal) / max(1e-9, -b.velocityBefore.dot(e.normal))) * 100
            return Caption(id: id, time: e.time, title: String(localized: "The post throws it back"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) hits the post at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into it."),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse)
        case .pinDown:
            // A standing pin knocked over: the ball pays a little speed for it.
            let b = e.balls[0]
            return Caption(id: id, time: e.time, title: String(localized: "Pin down"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) knocks the pin over at \(f(b.velocityBefore.length)) m/s and rolls on at \(f(b.velocityAfter.length)) m/s."),
                           equation: "J = (1 + e) · m·mₚ / (m + mₚ) · v⊥", accent: .impact, importance: e.normalImpulse + 1)
        case .cushion where e.edge != .rail:
            // A pocket jaw or knuckle: the ball reached the mouth and was turned away (or rattled). Worth saying even
            // when slow, because it is the answer to "why didn't that go in?".
            let b = e.balls[0]
            let part = e.edge == .knuckle ? String(localized: "the point of the pocket") : String(localized: "the pocket's jaw")
            let title = e.edge == .knuckle ? String(localized: "Clipped the point") : String(localized: "Off the jaw")
            return Caption(id: id, time: e.time, title: title,
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) catches \(part) at \(f(b.velocityBefore.length)) m/s and is turned away from the hole. A little more to the middle of the pocket and it drops."),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse + 0.5)
        case .cushion:
            let b = e.balls[0]
            let vin = b.velocityBefore.length
            guard vin > 0.8 else { return nil }
            let kept = (b.velocityAfter.dot(e.normal) / max(1e-9, -b.velocityBefore.dot(e.normal))) * 100
            if let bed = e.bedImpulse, bed > 0 {
                // Generation 2: the nose meets the ball above its centre (sine of the tilt (h - R) / R), so part of
                // the rail's push goes down into the cloth; the event carries the impulse the cloth took.
                return Caption(id: id, time: e.time, title: String(localized: "The rail pushes it into the cloth"),
                               detail: String(localized: "\(name(b.ball).capitalizedFirst) hits the rail at \(f(vin)) m/s. The rail's nose is above the ball's centre, so it pushes down as well as back: the cloth takes \(f(bed * 1000, 0)) millinewton-seconds of that push, and its grip changes the spin the ball carries away. It keeps \(f(kept, 0)) percent of its speed straight into the rail."),
                               equation: "sin θ = (h − R) / R", accent: .cushion, importance: e.normalImpulse)
            }
            return Caption(id: id, time: e.time, title: String(localized: "The cushion pushes back"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) hits the rail at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into the rail. Sideways speed is trimmed by friction."),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse)
        case .phaseTransition:
            guard e.phaseFrom == .sliding, e.phaseTo == .rolling else { return nil }
            let b = e.balls[0]
            let v = b.velocityAfter.length
            guard v > 0.7 else { return nil }
            let detail: String
            if facts.surface == .cloth {
                detail = String(localized: "Friction with the cloth slowed \(name(b.ball)) and spun it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.")
            } else {
                // The skid's real length, from the recording. The solver always closes the sliding segment at this
                // event, so the nil case should not happen; if it did, no caption beats a made-up number.
                guard let skid = skidDuration(ball: b.ball, endingAt: e.time, in: timeline) else { return nil }
                let secs = f(skid, skid < 1 ? 2 : 1)
                let mu = coefficient(facts.p.slidingFriction), g = f(facts.p.gravity)
                detail = facts.gravityOnly
                    ? String(localized: "On the Moon, the same sliding friction as cloth (\(mu)) under only \(g) m/s² of gravity took \(secs) seconds to slow \(name(b.ball)) and spin it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.")
                    : String(localized: "On \(facts.surface.title), sliding friction of \(mu) under gravity of \(g) m/s² took \(secs) seconds to slow \(name(b.ball)) and spin it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.")
            }
            // Skid time: the slip at the contact point closes at 7/2 * mu * g, so it is gone after 2 * slip / (7 mu g).
            return Caption(id: id, time: e.time, title: String(localized: "Skid turns into roll"), detail: detail,
                           equation: "t = 2·Δv / (7·μ·g)", accent: .friction, importance: v * 0.12)
        case .pocket:
            let b = e.balls[0]
            return Caption(id: id, time: e.time, title: String(localized: "Pocketed"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) drops in at \(f(b.velocityBefore.length)) m/s."),
                           equation: "ΔKE → 0", accent: .pocket, importance: 3)
        case .rimSkip:
            // Generation 2: the ball crossed the hole too fast to fall far enough to catch the far edge (the solver's
            // test: the fall g t^2 / 2 during the crossing time t was under a third of the radius).
            let b = e.balls[0]
            let vin = e.entry?.speed ?? b.velocityBefore.length
            return Caption(id: id, time: e.time, title: String(localized: "Too fast for the pocket"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) reaches the hole at \(f(vin)) m/s, too fast to drop: it is across before gravity can pull it far enough down to catch the far edge, and it carries on at \(f(b.velocityAfter.length)) m/s."),
                           equation: "h = g · t² / 2", accent: .pocket, importance: 2.5)
        case .settledInContact:
            // The jam guard (any generation): wedged balls chattering in bounces too small to see were brought to rest
            // touching; the event carries the energy taken out. One ball means it chattered between rubber faces.
            guard let first = e.balls.first else { return nil }
            let mj = f((e.energyRemoved ?? 0) * 1000, 1)
            let detail = e.balls.count == 1
                ? String(localized: "\(name(first.ball).capitalizedFirst) was wedged against the rubber, bouncing in place in bounces too small to see. It is brought to rest, and the \(mj) millijoules those bounces would have turned into heat are taken out at once.")
                : String(localized: "\(e.balls.count) balls were wedged together, bouncing off each other in bounces too small to see. They are brought to rest touching, and the \(mj) millijoules those bounces would have turned into heat are taken out at once.")
            return Caption(id: id, time: e.time, title: String(localized: "Wedged and settled"), detail: detail,
                           equation: "ΔE = E_before − E_after", accent: .impact, importance: 1)
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
