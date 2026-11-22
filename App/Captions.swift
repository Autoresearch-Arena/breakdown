// Author: Claude Sonnet 5.5 Medium
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream card: every caption fills Caption.sentences with the
//          pieces its detail is joined from, in order (the spin, rail-spin, surface and bend helpers hand back their
//          sentences one by one), so the phone card can page a long caption at sentence ends; every detail is byte for
//          byte what it was. The off-centre worked line's 2.5 follows the player's number style (#61).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 foundation: Caption.sentences, the detail's sentences one by
//          one, for the phone card's pages; filled in by stream card).
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 7 and 8. Balls are named the way the table they were solved on names them (TableWords.ballName with
//          the striking ball: "A white hits the post", "The yellow drops in"), so bumper pool, five-pin and bar
//          billiards never read "the cue ball" or "the 3 ball"; the pool table's words are unchanged. A drop into a
//          bed hole says "Into the hole" on bar billiards and "Into the cup" on bumper pool (and "Too fast for the
//          hole" or "the cup" on a skip), a bar-billiards peg knocked over is "Peg down" with what that peg costs
//          (BarBilliardsRules.blackPeg tells the black from the whites), a bumper-pool post is "the bumper", and the
//          side-spin strike title says "the ball" off the pool table. And a cue strike that leaves the ball at
//          walking pace or less (0.05 m/s, a still table) gets no caption at all.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F7:
//          make takes the solved table and the striking ball, unused until the rules-lens stream names balls by table.)
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
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 4,
//          22, 24, 26, 27, 29 and 55:
//          - the strike's spin words come from the recorded spin against the direction of travel (draw, stun, follow,
//            natural roll, overspin, and which side), on every strike caption, never "spin over 20 means backspin";
//          - a raised strike gets its own caption with the cue's angle and its speed along its own line, split into
//            the part across the cloth and the part down into the slate, and what the slate gave back; one that did
//            not hop reads its angle from the solved strike, which make(from:surface:strike:) now takes;
//          - jumps: take-off (with the top of the flight and its clearance over the ball it passes), landing and
//            flying off the table are captioned from the recorded vertical speeds and segment heights;
//          - a path that bends while the ball slides (a masse, a curve after a cut) is named: which way and how many
//            degrees, from the sliding segment's own constant acceleration;
//          - throw: when friction at a ball-to-ball contact sends a ball at rest off the line of centres by half a
//            degree or more, the caption says so, which way and by how much, from the recorded departure;
//          - rails say what they did to the spin (came in rolling, left with almost no topspin);
//          - surfaces compare what a rail keeps at a stated pace (RailKeep, the solver's rail routine worked through
//            for a rolling ball) instead of the raw restitution, and a ratio that rounds to one says "the same as on
//            cloth";
//          - the jam's energy is printed in microjoules, millijoules or joules, whichever reads sensibly;
//          - every caption whose equation can be filled with the event's own numbers carries that worked line
//            (Caption.worked), shown on the opening's headline beats even with Show the maths off;
//          - strokeSentence: the line the Lens adds to the strike caption when the player's stroke turned the cue.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-pacing, plans/22-Nov-2026-v074-glow-up-plan.md G1: the
//          bend lookup is readable as bendEvents(in:), so PacePlan, the trick signatures and the highlight judge find
//          the event that ends a bent slide from this one place. No wording changed.)
// PURPOSE: Turns solver events into the plain-language captions and equations the Physics Lens shows. Every
//          number in a caption is read from the recorded event (pillar one: nothing is drawn that the solver
//          did not compute). Every event that clears its speed gate gets a caption, sorted by time; choosing which
//          ones the replay stops on is PacePlan's job. Words the player reads go through String(localized:) so they
//          land in the string catalog. Surface numbers are read from PlaySurface.parameters, the same values the
//          solver was given, and every ratio is worked out from them, never typed in. Exactly one caption per event:
//          its id is the event's index, which PacePlan, the on-table marker and the caption tests rely on, so extra
//          things to say about one event (throw, a bend, the rail's effect on spin) are sentences inside that
//          event's caption, never a second caption. Also holds RailKeep (what a rail gives back at a stated pace),
//          read by the notebook and the Behind the 8-Ball card too.
// SRP/DRY check: Pass - caption selection and wording only; display lives in the view. RailKeep restates the
//          solver's rail routine (BreakdownPhysics Impacts.rail, internal to the package, so the app cannot call it)
//          for the one case the words need; the reason and the risk are in its own comment.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
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
    /// The equation with this event's own numbers put in ("p = m · v = 0.170 kg · 6.20 m/s = 1.05 kg·m/s"), or empty
    /// when the equation has nothing from the event to fill in. Shown on the headline beats even with Show the maths
    /// off (CaptionViews), and in place of the bare equation whenever Show the maths is on.
    var worked: String = ""
    /// The detail's whole sentences in order (0.7.6), each one complete and translated on its own, so a phone card can
    /// split a long explanation into pages at sentence ends. `detail` stays exactly these joined by spaces. Empty means
    /// "not split yet": a view then treats the whole detail as one sentence.
    var sentences: [String] = []
}

extension Caption {
    /// A caption built from its sentences (0.7.6): `detail` is exactly `pieces` joined by single spaces, which is how
    /// every detail was built before, so the text is unchanged and `sentences` always matches it. Declared in an
    /// extension so the memberwise initialiser stays available.
    init(id: Int, time: Double, title: String, pieces: [String], equation: String, accent: CaptionAccent,
         importance: Double, worked: String = "") {
        self.init(id: id, time: time, title: title, detail: pieces.joined(separator: " "), equation: equation,
                  accent: accent, importance: importance, worked: worked, sentences: pieces)
    }
}

// MARK: What a rail keeps

/// What a rail gives back, as the share of its speed a ball keeps, worked out with the solver's own rail rules.
///
/// Why a copy: the solver's rail routine (Impacts.rail in BreakdownPhysics) is internal to the package and the app
/// cannot call it, and no public helper for it exists in this batch's contract (docs/v07-contracts.md). So the one
/// case the words need, a ball ROLLING straight into a rail at `pace`, is worked through here with exactly the steps
/// and the same public PoolParameters numbers that routine uses. If the solver's rail changes (a coupled rail, a new
/// restitution curve), this copy must change with it; the CaptionEngineTests check pins it to the flat-wall answer at
/// generation one, and the rail-share test pins it between the bare restitution and one.
enum RailKeep {
    /// The pace the notebook, the cards and the surface sentence state: 2 m/s, a firm ordinary shot. A pace has to be
    /// named because the rail's bounce falls with speed (railRestitutionSlope); a number without one would be untrue
    /// for most shots.
    static let pace = 2.0

    /// The share (0 to 1) of its speed a ball rolling straight into a rail at `pace` m/s keeps coming off it.
    static func share(at pace: Double = RailKeep.pace, parameters p: PoolParameters) -> Double {
        guard pace > 0 else { return 0 }
        // Generation 1, the flat wall (Impacts.cushion): head on, a rolling ball has no sideways slip and the
        // vertical friction is dropped, so exactly the restitution comes back.
        guard p.usesGenerationTwo else { return p.cushionRestitution }
        let m = p.ballMass, r = p.ballRadius, inertia = p.inertia
        // The rail along y with its inward normal n = +x; the ball comes in along -x, rolling (omega = (-vy, vx) / R).
        let s = p.railContactSine, c = p.railContactCosine
        let v = Vec3(-pace, 0, 0)
        let omega = Vec3(0, -pace / r, 0)
        // 1. Geometry: the nose touches above the centre, so the contact normal tilts down into the cloth.
        let normal = Vec3(c, 0, -s)
        let rc = Vec3(-r * c, 0, r * s)
        // 2. The rail impact: restitution falling with the speed into the rail, clamped as the solver clamps it.
        let vIn = max(0, -v.dot(normal))
        let e = min(p.cushionRestitution, max(p.railRestitutionFloor, p.cushionRestitution - p.railRestitutionSlope * vIn))
        let jn = (1 + e) * m * vIn
        let u = v + omega.cross(rc)
        let ut = u - normal * u.dot(normal)
        let slip = ut.length
        func energy(_ v: Vec3, _ w: Vec3) -> Double { 0.5 * m * v.lengthSquared + 0.5 * inertia * w.lengthSquared }
        let before = energy(v, omega)
        func resolve(_ scale: Double) -> (v: Vec3, w: Vec3) {
            var f = Vec3.zero
            if slip > 1e-12 && jn > 0 {
                // Coulomb, capped by the impulse that stops the slip on a fixed surface (2 m |u| / 7).
                let jf = min(2 * m * slip / 7, p.cushionFriction * jn) * scale
                f = ut * (-jf / slip)
            }
            let impulse = normal * jn + f
            var nv = v + impulse * (1 / m)
            var nw = omega + rc.cross(impulse) * (1 / inertia)
            // 3. The bed: the cloth stops the downward speed with no bounce, its friction acting on the contact point
            // under the ball (Impacts.slate with restitution zero).
            if nv.z < 0 {
                let jb = m * -nv.z
                let under = Vec2(nv.x - r * nw.y, nv.y + r * nw.x)
                let sl = under.length
                if sl > 1e-12 {
                    let jf = min(2 * m * sl / 7, p.slateFriction * jb)
                    let fx = under.x * (-jf / sl), fy = under.y * (-jf / sl)
                    nv = Vec3(nv.x + fx / m, nv.y + fy / m, 0)
                    nw = Vec3(nw.x + r * fy / inertia, nw.y - r * fx / inertia, nw.z)
                } else {
                    nv = Vec3(nv.x, nv.y, 0)
                }
            }
            // The ball always leaves the rail's line moving away from it.
            if nv.x < 0 { nv = Vec3(0, nv.y, nv.z) }
            return (nv, nw)
        }
        // The solver's energy guard: halve the rail's friction until kinetic plus spin energy does not rise.
        var best = resolve(1)
        for scale in [0.5, 0.25, 0.0] {
            if energy(best.v, best.w) <= before * (1 + 1e-12) { break }
            best = resolve(scale)
        }
        return Vec2(best.v.x, best.v.y).length / pace
    }

    /// The share as a whole percentage, for the words.
    static func percent(at pace: Double = RailKeep.pace, parameters p: PoolParameters) -> Int {
        Int((share(at: pace, parameters: p) * 100).rounded())
    }
}

enum CaptionEngine {
    /// How a caption names this recording's balls (0.7.5): the way the table it was solved on names them, with the
    /// ball the cue struck as that table's "cue ball" (TableWords.ballName: pool names on the pool table, colours on
    /// the small tables). Each name is a whole phrase, so a translator can reorder the sentence around it.
    private struct BallNames {
        let table: TableKind
        let striker: Int
        func callAsFunction(_ ball: Int) -> String { TableWords.ballName(ball, cueBall: striker, table: table) }
    }

    /// The numbers a caption needs about the surface the shot was solved on, next to cloth's for comparison, and
    /// (0.7.5) the table it was solved on with the names that table gives its balls.
    private struct SurfaceFacts {
        let surface: PlaySurface
        let p: PoolParameters
        let cloth: PoolParameters
        let names: BallNames
        var table: TableKind { names.table }
        /// The Moon (or any surface) with cloth's friction and a different gravity: gravity is the whole story.
        var gravityOnly: Bool {
            p.gravity != cloth.gravity && p.slidingFriction == cloth.slidingFriction
                && p.rollingResistance == cloth.rollingResistance
        }
    }

    /// `surface` is the one the timeline was solved on (ShowpieceModel.physicsSurface), so the numbers explained are
    /// the numbers used. `strike` is the strike that was solved (the model's input for this recording), when known: the
    /// cue's angle of a raised strike that did not make the ball hop is in no event, so it is read from there.
    /// `table` is the table the timeline was solved on and `striker` the ball the cue struck: balls are named the way
    /// that table names them, with the striker as its cue ball. Without a striker, the ball the recording's own cue
    /// strike moved is used (ball 0 when there is none). A trick shot or a situation is solved on the pool table, so
    /// it keeps the pool names.
    static func make(from timeline: Timeline, surface: PlaySurface, strike: CueStrike? = nil,
                     table: TableKind = .standard, striker: Int? = nil) -> [Caption] {
        let struck = striker ?? timeline.events.first { $0.kind == .cueStrike }?.balls.first?.ball ?? 0
        let facts = SurfaceFacts(surface: surface, p: surface.parameters, cloth: PlaySurface.cloth.parameters,
                                 names: BallNames(table: table, striker: struck))
        // Bends are found per sliding segment, then said in the caption of the event that ends each one.
        let bendsAt = bendEvents(in: timeline)
        var all: [Caption] = []
        for (index, e) in timeline.events.enumerated() {
            if let c = caption(for: e, id: index, timeline: timeline, facts: facts, bends: bendsAt[index] ?? [],
                               strike: strike) {
                all.append(c)
            }
        }
        // All of them, in clock order. Events arrive sorted already; the explicit sort with the event index as the
        // tie-break keeps simultaneous rack hits in one fixed order whatever the solver's ordering guarantees.
        // The id stays the event's index: the on-table marker finds its ball through it.
        return all.sorted { ($0.time, $0.id) < ($1.time, $1.id) }
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

    /// True when `ratio` would print a ratio as "1": one decimal below 10, so anything from 0.95 up to 1.05.
    private static func roundsToOne(_ x: Double) -> Bool { abs(x - 1) < 0.05 }

    /// Degrees from a sine (the solver records turns as sines; it has no trigonometry, the app does).
    private static func degrees(fromSine s: Double) -> Double {
        asin(min(1, max(-1, abs(s)))) * 180 / Double.pi
    }

    /// Signed angle from `a` to `b` in degrees, positive counter-clockwise on the table plan (to the left of `a`).
    static func signedDegrees(from a: Vec2, to b: Vec2) -> Double {
        atan2(a.x * b.y - a.y * b.x, a.dot(b)) * 180 / Double.pi
    }

    // MARK: Surfaces

    /// The extra sentence on the cue-strike caption off cloth. Skid distance goes as 1 / (sliding friction * g) and
    /// roll distance as 1 / (rolling resistance * g) (Simulation.makeSegment: the decelerations are mu * g and c_r * g),
    /// so the ratios to cloth are worked out from the solver's own numbers. Nil on cloth. A ratio that would print as
    /// "1" is said as "the same as on cloth" (tournament cloth shares the standard cloth's sliding friction, so "skids
    /// about 1 times as far" was true but read as a mistake).
    /// Handed back as its sentences, in order (empty on cloth or when there is nothing to say), so each one is a piece of
    /// the strike caption's Caption.sentences; the caption joins them with spaces exactly as before (0.7.6).
    private static func surfaceSentences(_ s: SurfaceFacts) -> [String] {
        guard s.surface != .cloth else { return [] }
        let skid = (s.cloth.slidingFriction * s.cloth.gravity) / (s.p.slidingFriction * s.p.gravity)
        let roll = (s.cloth.rollingResistance * s.cloth.gravity) / (s.p.rollingResistance * s.p.gravity)
        if s.gravityOnly {
            // Same friction numbers, weaker gravity: the friction force is the friction number times the weight, and
            // the weight is mass times g, so both distances grow by the same ratio of gravities.
            return [String(localized: "On the Moon the friction numbers are the same as on cloth, but gravity is \(f(s.p.gravity)) m/s² instead of \(f(s.cloth.gravity)). Friction pushes back with the friction number times the ball's weight, and weight is mass times gravity, so a ball skids about \(ratio(skid)) times as far before it rolls and rolls about \(ratio(roll)) times as far.")]
        }
        let mu = coefficient(s.p.slidingFriction), cr = coefficient(s.p.rollingResistance)
        let muCloth = coefficient(s.cloth.slidingFriction), crCloth = coefficient(s.cloth.rollingResistance)
        let friction: String?
        switch (roundsToOne(skid), roundsToOne(roll)) {
        case (false, false):
            friction = String(localized: "On \(s.surface.title) the sliding friction is \(mu) and the rolling resistance \(cr) (cloth: \(muCloth) and \(crCloth)), so a ball skids about \(ratio(skid)) times as far before it rolls and rolls about \(ratio(roll)) times as far.")
        case (true, false):
            friction = String(localized: "On \(s.surface.title) the sliding friction is \(mu) and the rolling resistance \(cr) (cloth: \(muCloth) and \(crCloth)), so a ball skids the same distance as on cloth before it rolls, then rolls about \(ratio(roll)) times as far.")
        case (false, true):
            friction = String(localized: "On \(s.surface.title) the sliding friction is \(mu) and the rolling resistance \(cr) (cloth: \(muCloth) and \(crCloth)), so a ball skids about \(ratio(skid)) times as far before it rolls, then rolls the same distance as on cloth.")
        case (true, true):
            // Nothing to say about skid or roll; the rails below (if they differ) carry the sentence alone.
            friction = nil
        }
        // The real cloths also change the rails (fresh rubber on the tournament table, dead rubber in the bar). Said as
        // what a rolling ball keeps at the stated pace, worked out with the solver's rail rules, not as the raw
        // restitution, which the tilted nose and the speed-dependent bounce no longer make equal to what a ball keeps.
        let here = RailKeep.percent(parameters: s.p), standard = RailKeep.percent(parameters: s.cloth)
        let rails: String? = here == standard ? nil
            : String(localized: "A ball rolling straight into a rail at \(f(RailKeep.pace, 0)) m/s keeps \(here) percent of its speed here (standard table: \(standard) percent).")
        return [friction, rails].compactMap { $0 }
    }

    /// How long the ball skidded before this sliding-to-rolling event: the sliding segment the solver closed at the
    /// event's time (Simulation.restart sets its end to exactly that time), from its start. Its start is the strike or
    /// the last impact that set the ball skidding again. Nil if no such segment is recorded.
    private static func skidSegment(ball: Int, endingAt t: Double, in timeline: Timeline) -> BallSegment? {
        guard timeline.segments.indices.contains(ball) else { return nil }
        return timeline.segments[ball].last(where: { $0.phase == .sliding && abs($0.t1 - t) < 1e-9 })
    }

    // MARK: Spin words

    /// How a ball's spin compares with natural rolling along its direction of travel.
    enum SpinState: Equatable {
        case back, stun, partial, rolling, over
    }

    /// The topspin part of `omega` along the direction of `velocity`, as a share of a rolling ball's spin (1 is natural
    /// roll, 0 a stunned ball, negative backspin). In the solver's convention a rolling ball spins at
    /// (-vy / R, vx / R), so the share is omega . (-dy, dx) * R / |v|. Nil when the ball is barely moving: then there
    /// is no direction of travel to compare with.
    static func rollShare(omega: Vec3, velocity: Vec2, radius: Double) -> Double? {
        let speed = velocity.length
        guard speed > 0.05 else { return nil }
        let d = velocity * (1 / speed)
        return (omega.x * -d.y + omega.y * d.x) * radius / speed
    }

    /// The words' bands. A sixth either side of zero and of one: inside them a player cannot tell the ball from a
    /// stunned or a rolling one by what it does next, and the band keeps a near-roll from flipping between words.
    static func spinState(_ share: Double) -> SpinState {
        if share < -0.15 { return .back }
        if share <= 0.15 { return .stun }
        if share < 0.85 { return .partial }
        if share <= 1.15 { return .rolling }
        return .over
    }

    /// Side spin, as the surface speed it gives (|omega_z| R) against the travel speed: below this share nothing at a
    /// rail or a hit shows it, so it is not named. Positive omega_z (counter-clockwise from above) is what a hit right
    /// of centre gives (Simulation.applyStrike: omega_z = k * tipSide), so it is called right-hand side spin.
    static let sideWorthSaying = 0.15

    /// The strike's spin in words, from the recorded spin against the recorded direction of travel. `side` adds the
    /// side-spin sentence (left off where the caption is already about side spin). Its sentences in order, empty when the
    /// ball barely moves (0.7.6: pieces of Caption.sentences, joined with spaces exactly as before).
    private static func strikeSpinSentences(_ b: ImpactBall, radius R: Double, side: Bool = true) -> [String] {
        guard let share = rollShare(omega: b.omegaAfter, velocity: b.velocityAfter, radius: R) else { return [] }
        var parts: [String] = []
        let pct = f(abs(share) * 100, 0)
        switch spinState(share) {
        case .back: parts.append(String(localized: "It leaves with backspin (draw): \(pct) percent of a rolling ball's spin, turning backwards."))
        case .stun: parts.append(String(localized: "It leaves with almost no topspin or backspin (stun): it slides until the cloth spins it up."))
        case .partial: parts.append(String(localized: "It leaves with topspin (follow): \(pct) percent of a rolling ball's spin."))
        case .rolling: parts.append(String(localized: "It leaves already spinning like a rolling ball (natural roll)."))
        case .over: parts.append(String(localized: "It leaves with more topspin than a rolling ball (\(pct) percent): the cloth pulls it faster until it rolls."))
        }
        if side, abs(b.omegaAfter.z) * R >= sideWorthSaying * b.velocityAfter.length {
            parts.append(b.omegaAfter.z > 0
                         ? String(localized: "It also carries right-hand side spin, which shows at the next rail.")
                         : String(localized: "It also carries left-hand side spin, which shows at the next rail."))
        }
        return parts
    }

    /// What a rail did to the spin: the state the ball came in with, then the state it leaves with, each against its
    /// own direction of travel (a ball that came in rolling and kept its spin leaves with backspin, because its
    /// direction has turned round), and how much side spin it kept. Its sentences in order, empty when there is
    /// nothing to say (0.7.6).
    private static func railSpinSentences(_ b: ImpactBall, radius R: Double) -> [String] {
        var parts: [String] = []
        if let inShare = rollShare(omega: b.omegaBefore, velocity: b.velocityBefore, radius: R) {
            switch spinState(inShare) {
            case .back: parts.append(String(localized: "It came in with backspin."))
            case .stun: parts.append(String(localized: "It came in sliding, with almost no spin."))
            case .partial: parts.append(String(localized: "It came in with some topspin, less than rolling."))
            case .rolling: parts.append(String(localized: "It came in rolling."))
            case .over: parts.append(String(localized: "It came in with more topspin than rolling."))
            }
        }
        if let outShare = rollShare(omega: b.omegaAfter, velocity: b.velocityAfter, radius: R) {
            switch spinState(outShare) {
            case .back: parts.append(String(localized: "It leaves with backspin, which the cloth must wear off before it rolls."))
            case .stun: parts.append(String(localized: "It leaves with almost no topspin or backspin."))
            case .partial: parts.append(String(localized: "It leaves with some topspin, less than rolling."))
            case .rolling: parts.append(String(localized: "It leaves rolling."))
            case .over: parts.append(String(localized: "It leaves with more topspin than rolling."))
            }
        }
        // Side spin: only when it came in with enough to matter, and said as the share kept.
        let sideIn = abs(b.omegaBefore.z) * R
        if sideIn >= sideWorthSaying * max(0.05, b.velocityBefore.length) {
            let kept = b.omegaAfter.z * b.omegaBefore.z > 0 ? abs(b.omegaAfter.z) / abs(b.omegaBefore.z) : 0
            parts.append(String(localized: "It keeps \(f(min(kept, 1) * 100, 0)) percent of its side spin."))
        }
        return parts
    }

    // MARK: Bends

    /// Smallest bend worth naming, degrees. A path that turns less than this drifts sideways by under a ball's width over
    /// a metre (sin 2 degrees x 1 m is 35 mm against a 57 mm ball), which reads as straight on a phone; the strike's
    /// half-degree squirt has its own caption already.
    static let bendWorthSaying = 2.0
    /// A sliding ball slower than this, m/s, is crawling to a stop: its direction swinging round is the ball stopping,
    /// not a curve, so no bend is named for a segment whose speed dips below it.
    static let bendMinimumSpeed = 0.15

    /// How far a sliding segment's path turned, degrees, positive to the left (counter-clockwise on the table plan),
    /// or nil when it did not bend enough to name or the ball nearly stopped on the way. Inside a sliding segment the
    /// acceleration is constant (cloth friction along the fixed slip direction, Simulation.makeSegment), so the
    /// velocity is v0 + a t and the turn is the angle between its first and last values.
    static func bend(of seg: BallSegment) -> Double? {
        guard seg.phase == .sliding, seg.t1.isFinite, seg.t1 > seg.t0 else { return nil }
        let T = seg.t1 - seg.t0
        let v0 = seg.velocity0, a = seg.acceleration
        let v1 = v0 + a * T
        // The slowest moment: where d|v|^2/dt = 0, t* = -(v0 . a) / |a|^2, held inside the segment.
        let aa = a.lengthSquared
        let tStar = aa > 1e-18 ? min(T, max(0, -v0.dot(a) / aa)) : 0
        guard (v0 + a * tStar).length >= bendMinimumSpeed, v1.length >= bendMinimumSpeed else { return nil }
        let turn = signedDegrees(from: v0, to: v1)
        return abs(turn) >= bendWorthSaying ? turn : nil
    }

    /// Every bend, keyed by the index of the event that ended its sliding segment (the event at the segment's end time
    /// that names the ball), with the ball and the signed degrees. When the slide ended in the skid turning into roll,
    /// that event is chosen even if another event names the ball at the same instant, because the skid-to-roll caption
    /// reads its own bend from the segment (so the two agree, and the bend is said once). A bend whose event earns no
    /// caption (a rail touch under the rail's speed gate) is not said. Read by make(from:surface:strike:) for the words,
    /// and by PacePlan, TrickSignature and ShotHighlightJudge (0.7.4) to find the event a bend's beat is held on.
    static func bendEvents(in timeline: Timeline) -> [Int: [(ball: Int, degrees: Double)]] {
        var out: [Int: [(ball: Int, degrees: Double)]] = [:]
        for ball in timeline.segments.indices {
            for seg in timeline.segments[ball] {
                guard let turn = bend(of: seg) else { continue }
                let atEnd: (LensEvent) -> Bool = { abs($0.time - seg.t1) < 1e-9 && $0.balls.contains { $0.ball == ball } }
                let toRoll = timeline.events.firstIndex {
                    atEnd($0) && $0.kind == .phaseTransition && $0.flight == .none && $0.phaseFrom == .sliding
                        && $0.phaseTo == .rolling
                }
                guard let i = toRoll ?? timeline.events.firstIndex(where: atEnd) else { continue }
                out[i, default: []].append((ball: ball, degrees: turn))
            }
        }
        return out
    }

    private static func bendSentence(ball: Int, degrees turn: Double, names name: BallNames) -> String {
        turn > 0
            ? String(localized: "While \(name(ball)) slid, its path bent \(f(abs(turn), 0)) degrees to the left: the cloth pulls along the slip of the ball's bottom, not along its motion.")
            : String(localized: "While \(name(ball)) slid, its path bent \(f(abs(turn), 0)) degrees to the right: the cloth pulls along the slip of the ball's bottom, not along its motion.")
    }

    // MARK: Throw

    /// A ball at rest knocked off the line of centres by friction at the contact.
    struct ThrowFacts: Equatable {
        /// The ball that was at rest and was struck.
        let object: Int
        /// Unit vectors: the line of centres (from the striking ball to it) and the way it really left.
        let lineOfCentres: Vec2
        let departure: Vec2
        /// Signed, positive counter-clockwise from the line of centres (to the left as seen along it).
        let degrees: Double
        /// Its speed along the line of centres and across it, m/s, for the worked equation.
        let along: Double
        let across: Double
    }

    /// Smallest throw worth saying or drawing, degrees: the same half degree the aim guide's fork uses for squirt
    /// (AimGeometry.fork), so the two ways the game says "the ball did not go where the line points" agree.
    static let throwWorthSaying = 0.5
    /// A ball moving slower than this before the contact counts as at rest: only then does the line of centres say
    /// exactly where it would go without friction.
    static let restSpeed = 0.05

    /// The throw at a ball-to-ball contact, or nil when no ball was at rest, the struck ball barely moved, or the
    /// throw is under half a degree. Read from the event alone: the normal is the line of centres (pointing from the
    /// first ball listed to the second) and the struck ball's velocity after is its real departure.
    static func throwFacts(_ e: LensEvent) -> ThrowFacts? {
        guard e.kind == .ballBall, e.balls.count == 2 else { return nil }
        let a = e.balls[0], b = e.balls[1]
        // The ball at rest is the object; the line of centres points into it.
        let object: ImpactBall
        let n: Vec2
        if b.velocityBefore.length < restSpeed, a.velocityBefore.length >= restSpeed {
            object = b
            n = e.normal.normalized
        } else if a.velocityBefore.length < restSpeed, b.velocityBefore.length >= restSpeed {
            object = a
            n = (-e.normal).normalized
        } else {
            return nil
        }
        let out = object.velocityAfter
        guard out.length > restSpeed, n.length > 0.5 else { return nil }
        let turn = signedDegrees(from: n, to: out)
        guard abs(turn) >= throwWorthSaying, abs(turn) < 45 else { return nil }
        return ThrowFacts(object: object.ball, lineOfCentres: n, departure: out.normalized, degrees: turn,
                          along: out.dot(n), across: abs(out.dot(n.perp)))
    }

    // MARK: Energy

    /// An energy in the unit that reads sensibly: microjoules under a millijoule, millijoules under a joule, joules
    /// above, each with two significant figures. (Nine microjoules printed as millijoules to one decimal read "0.0".)
    static func energyPhrase(_ joules: Double) -> String {
        let x = max(0, joules)
        func sig(_ v: Double) -> String { v.formatted(.number.precision(.significantDigits(1...2))) }
        if x < 1e-3 { return String(localized: "\(sig(x * 1e6)) microjoules") }
        if x < 1 { return String(localized: "\(sig(x * 1e3)) millijoules") }
        return String(localized: "\(sig(x)) joules")
    }

    // MARK: The stroke (item 4)

    /// The line the Lens adds to the strike caption when the player's stroke turned the cue off the aimed line
    /// (CaptionViews shows it with the two lines it draws at the cue ball). `aimError` is StrokeDelivery.aimError,
    /// radians, positive counter-clockwise (to the shooter's left).
    static func strokeSentence(aimError: Double) -> String {
        let deg = f(abs(aimError) * 180 / Double.pi, 2)
        return aimError > 0
            ? String(localized: "Your stroke turned the cue \(deg) degrees to the left of where you aimed: the faint line is your aim, the bright one the cue's real line.")
            : String(localized: "Your stroke turned the cue \(deg) degrees to the right of where you aimed: the faint line is your aim, the bright one the cue's real line.")
    }

    // MARK: The cue strike

    /// The take-off event a raised strike made at the same instant, when the slate threw the struck ball up.
    private static func strikeTakeOff(_ e: LensEvent, ball: Int, in timeline: Timeline) -> LensEvent? {
        timeline.events.first {
            $0.kind == .phaseTransition && $0.flight == .takeOff && abs($0.time - e.time) < 1e-9
                && $0.balls.first?.ball == ball
        }
    }

    /// A raised strike. Simulation.applyRaisedStrike drives the ball along the cue's own line at speed v: v cos e across
    /// the cloth and v sin e down into the slate. The take-off event it records carries both: the ball's horizontal
    /// velocity before the slate (velocityBefore) and the downward speed (verticalSpeedDown), so v and the angle come
    /// back exactly as sqrt(h^2 + d^2) and atan2(d, h), with no mass assumed.
    private static func raisedCaption(_ e: LensEvent, takeOff: LensEvent, id: Int, R: Double) -> Caption? {
        guard let t = takeOff.balls.first else { return nil }
        let across = t.velocityBefore.length, down = takeOff.verticalSpeedDown
        let along = (across * across + down * down).squareRoot()
        guard along > 0.01 else { return nil }
        let angle = atan2(down, across) * 180 / Double.pi
        var pieces = [String(localized: "The cue, raised \(f(angle, 0)) degrees, drives the ball at \(f(along)) m/s along its own line: \(f(across)) m/s across the cloth and \(f(down)) m/s down into the slate. The slate throws it back up at \(f(takeOff.verticalSpeedUp)) m/s, so it leaves the cloth.")]
        pieces += strikeSpinSentences(e.balls[0], radius: R)
        return Caption(id: id, time: e.time, title: String(localized: "The cue comes down on the ball"), pieces: pieces,
                       equation: "v↓ = v · sin θ", accent: .strike, importance: 1e9,
                       worked: "v↓ = \(f(along, 2)) m/s · sin \(f(angle, 0))° = \(f(down, 2)) m/s")
    }

    /// The generation-two cue-strike captions for a level strike, or nil when none applies (generation 1, or a plain
    /// centre hit), in which case the usual strike caption is used. One caption per strike, in this order: a miscue, a
    /// visible push off line from side spin (half a degree or more), a noticeably slower off-centre hit (tip 15 percent
    /// of the radius or more out, which costs about four percent of the speed). The last two also name the spin.
    private static func strikeCaption(for e: LensEvent, id: Int, timeline: Timeline, facts: SurfaceFacts) -> Caption? {
        guard let sine = e.deflectionSine else { return nil }       // generation 1 records no deflection
        let b = e.balls[0]
        let speed = b.velocityAfter.length
        let turn = degrees(fromSine: sine)
        let R = timeline.table.ballRadius
        if e.miscue == true {
            let mu = facts.p.tipGrip
            let limit = mu / (1 + mu * mu).squareRoot() * 100
            return Caption(id: id, time: e.time, title: String(localized: "Miscue"),
                           pieces: [String(localized: "The tip met the ball more than \(f(limit, 0)) percent of its radius from the centre, past where the tip can grip, and slid off. The ball leaves at only \(f(speed)) m/s, \(f(turn)) degrees off the line of the cue.")],
                           equation: "b / R > μ / √(1 + μ²)", accent: .strike, importance: 1e9)
        }
        if turn >= 0.5 {
            // Positive sine: turned counter-clockwise, to the left of the cue, which is what a hit right of centre does.
            var pieces = [sine > 0
                ? String(localized: "Hit right of centre, the ball is pushed to the left, away from the side the tip struck: it leaves \(f(turn)) degrees off the line of the cue, at \(f(speed)) m/s. Side spin always costs a little aim.")
                : String(localized: "Hit left of centre, the ball is pushed to the right, away from the side the tip struck: it leaves \(f(turn)) degrees off the line of the cue, at \(f(speed)) m/s. Side spin always costs a little aim.")]
            // The caption is about side spin already; the spin sentence adds the topspin or backspin it carries.
            pieces += strikeSpinSentences(b, radius: R, side: false)
            // Off the pool table there is no "cue ball": each player strikes a ball of their own (0.7.5).
            let title = facts.table == .standard ? String(localized: "Side spin pushes the cue ball off line")
                                                 : String(localized: "Side spin pushes the ball off line")
            return Caption(id: id, time: e.time, title: title,
                           pieces: pieces, equation: "tan α = (5/2)·x·√(1 − x²) / (1 + m/mₑ + (5/2)·x²)",
                           accent: .strike, importance: 1e9)
        }
        // A level strike launches at exactly the recorded speed with impulse m * speed, and its spin is
        // 5/2 * speed * b / R^2 (Simulation.applyStrike), so b / R = spin * R / (5/2 * speed). The ball's mass must
        // match the event's (a pool ball on a pool table) or the share would be mis-stated: then no caption.
        guard speed > 0.05 else { return nil }
        let m = facts.p.ballMass
        guard abs(e.normalImpulse / speed - m) <= 1e-6 * m else { return nil }
        let x = b.omegaAfter.length * R / (2.5 * speed)
        guard x >= 0.15 else { return nil }
        let M = facts.p.cueMass
        let factor = (M + m) / (M + m + 2.5 * M * x * x)
        var pieces = [String(localized: "The tip met the ball \(f(x * 100, 0)) percent of its radius from the centre, so part of the cue's push went into spin instead of speed. It leaves at \(f(speed)) m/s, \(f((1 - factor) * 100, 0)) percent slower than a centre hit with the same stroke.")]
        // So Follow and Draw still name the spin they teach beside the speed it cost.
        pieces += strikeSpinSentences(b, radius: R)
        // The 2.5 is written in the player's number style like every other number on the line (#61: "2.5 · 0,57" read
        // as two different styles in one equation).
        return Caption(id: id, time: e.time, title: String(localized: "Off-centre hits are slower"), pieces: pieces,
                       equation: "v = v₀ · (M + m) / (M + m + (5/2)·M·(b/R)²)", accent: .strike, importance: 1e9,
                       worked: "v = v₀ · (\(f(M, 2)) + \(f(m, 2))) / (\(f(M, 2)) + \(f(m, 2)) + \(f(2.5)) · \(f(M, 2)) · \(f(x, 2))²) = \(f(factor, 2)) · v₀")
    }

    // MARK: Flight

    /// The airborne segment that starts at `t` for `ball`.
    private static func flightSegment(ball: Int, startingAt t: Double, in timeline: Timeline) -> BallSegment? {
        guard timeline.segments.indices.contains(ball) else { return nil }
        return timeline.segments[ball].first { $0.phase == .airborne && abs($0.t0 - t) < 1e-9 }
    }

    /// The top of a flight: the highest the ball's lowest point gets above the cloth during the segment (the parabola
    /// h0 + vz t - g t^2 / 2 peaks at t = vz / g, held inside the segment), and how closely it passes over the ball it
    /// flies across. The clearance is the smallest gap between the two balls' surfaces while the flying ball is over
    /// that ball (centres less than a diameter apart across the cloth), sampled through the flight; nil when it passes
    /// over no ball, or touches one (then the solver records a ball-ball contact, captioned on its own).
    private static func flightTop(_ seg: BallSegment, ball: Int, in timeline: Timeline) -> (peak: Double, over: (ball: Int, gap: Double)?) {
        let g = -seg.verticalAcceleration
        let T = seg.t1.isFinite ? seg.t1 - seg.t0 : 0
        var tPeak = 0.0
        if g > 0, seg.verticalVelocity0 > 0 { tPeak = min(T, seg.verticalVelocity0 / g) }
        let peak = seg.kinematics(at: seg.t0 + tPeak).height
        guard T > 0 else { return (peak: peak, over: nil) }
        let R = timeline.table.ballRadius
        let steps = 80
        var best: (ball: Int, gap: Double)?
        for other in 0..<timeline.ballCount where other != ball {
            var smallest = Double.infinity
            var passesOver = false
            for i in 0...steps {
                let t = seg.t0 + T * Double(i) / Double(steps)
                let fly = seg.kinematics(at: t)
                let o = timeline.state(ball: other, at: t)
                if o.pocketed { continue }
                let across = (fly.position - o.position).length
                guard across < 2 * R else { continue }
                passesOver = true
                let up = fly.height - o.height
                smallest = min(smallest, (across * across + up * up).squareRoot() - 2 * R)
            }
            if passesOver, smallest > 0, smallest < (best?.gap ?? .infinity) { best = (ball: other, gap: smallest) }
        }
        return (peak: peak, over: best)
    }

    private static func flightCaption(_ e: LensEvent, id: Int, timeline: Timeline, facts: SurfaceFacts) -> Caption? {
        /// The table's name for a ball (0.7.5).
        func name(_ ball: Int) -> String { facts.names(ball) }
        guard let b = e.balls.first else { return nil }
        let ball = b.ball
        switch e.flight {
        case .takeOff:
            let up = e.verticalSpeedUp, down = e.verticalSpeedDown
            var pieces = [String(localized: "\(name(ball).capitalizedFirst) hits the slate going down at \(f(down)) m/s and bounces up at \(f(up)) m/s, so it leaves the cloth.")]
            var worked = ""
            if let seg = flightSegment(ball: ball, startingAt: e.time, in: timeline) {
                let top = flightTop(seg, ball: ball, in: timeline)
                pieces.append(String(localized: "At the top of its flight its lowest point is \(f(top.peak * 100)) cm above the cloth."))
                if let over = top.over {
                    pieces.append(String(localized: "It passes over \(name(over.ball)) with \(f(over.gap * 100)) cm to spare."))
                }
                let g = -seg.verticalAcceleration
                if g > 0 { worked = "h = v↑² / (2·g) = \(f(up, 2))² / (2 · \(f(g, 2))) = \(f(up * up / (2 * g) * 100)) cm" }
            }
            return Caption(id: id, time: e.time, title: String(localized: "Off the slate"), pieces: pieces,
                           equation: "h = v↑² / (2·g)", accent: .impact, importance: 2, worked: worked)
        case .landing:
            // How far it flew: the airborne segment that ends here, from its start to here, across the cloth.
            let seg: BallSegment? = timeline.segments.indices.contains(ball)
                ? timeline.segments[ball].last(where: { $0.phase == .airborne && abs($0.t1 - e.time) < 1e-9 }) : nil
            let flown = seg.map { ($0.kinematics(at: $0.t1).position - $0.position0).length } ?? 0
            let down = e.verticalSpeedDown, up = e.verticalSpeedUp
            let detail = e.phaseTo == .airborne
                ? String(localized: "\(name(ball).capitalizedFirst) comes down \(f(flown * 100, 0)) cm from where it left the cloth, at \(f(down)) m/s, and the slate sends it back up at \(f(up)) m/s.")
                : String(localized: "\(name(ball).capitalizedFirst) comes down \(f(flown * 100, 0)) cm from where it left the cloth, at \(f(down)) m/s, and stays on the cloth.")
            // The slate's bounce number as the solver had it; the worked line only when it agrees with the recorded
            // speeds (a bounce too small to hop is absorbed, Impacts.slate, and then there is no rise to work out).
            let e0 = facts.p.slateRestitution
            let bounces = e.phaseTo == .airborne && abs(e0 * down - up) <= 0.02 * max(up, 1e-9)
            return Caption(id: id, time: e.time, title: String(localized: "Lands"), pieces: [detail],
                           equation: "v↑ = e · v↓", accent: .impact, importance: 2,
                           worked: bounces ? "v↑ = \(f(e0, 2)) · \(f(down, 2)) m/s = \(f(up, 2)) m/s" : "")
        case .offTable:
            return Caption(id: id, time: e.time, title: String(localized: "Off the table"),
                           pieces: [String(localized: "\(name(ball).capitalizedFirst) sails over the cushion \(f(e.height * 100)) cm above the cloth at \(f(b.velocityBefore.length)) m/s and leaves the table.")],
                           equation: "h > h_nose", accent: .cushion, importance: 3)
        case .none:
            return nil
        }
    }

    // MARK: Every event

    private static func caption(for e: LensEvent, id: Int, timeline: Timeline, facts: SurfaceFacts,
                                bends: [(ball: Int, degrees: Double)], strike: CueStrike?) -> Caption? {
        let R = timeline.table.ballRadius
        /// The table's name for a ball (0.7.5): every sentence below names its balls through this.
        func name(_ ball: Int) -> String { facts.names(ball) }
        /// The bend sentences for this event, appended to its caption's sentences (a slide that ended in a hit or at a
        /// rail). The caption joins them with spaces, as before.
        func withBends(_ pieces: [String]) -> [String] {
            pieces + bends.map { bendSentence(ball: $0.ball, degrees: $0.degrees, names: facts.names) }
        }
        switch e.kind {
        case .cueStrike:
            guard let b = e.balls.first else { return nil }
            // A strike that leaves the ball at walking pace or less moved nothing worth a caption: a still table (a
            // zero-speed strike the opening or a replay can record) must not say "the cue sends the ball off at 0.0".
            // Checked before the raised and special strikes, which would otherwise caption it too.
            guard b.velocityAfter.length > 0.05 else { return nil }
            if e.miscue != true, let up = strikeTakeOff(e, ball: b.ball, in: timeline),
               let raised = raisedCaption(e, takeOff: up, id: id, R: R) { return raised }
            // A raised strike that did not hop: the slate took the push down without a bounce, so no event carries the
            // angle; the solved strike does (its elevation is the sine of the cue's angle).
            if e.miscue != true, let s = strike, s.elevation > 0, s.ballIndex == b.ball {
                let angle = asin(min(1, s.elevation)) * 180 / Double.pi
                var pieces = [String(localized: "The cue, raised \(f(angle, 0)) degrees, drives the ball down into the slate as well as forward. The push down is too small to make it hop, so the cloth takes it and the ball leaves at \(f(b.velocityAfter.length)) m/s across the cloth.")]
                pieces += strikeSpinSentences(b, radius: R)
                return Caption(id: id, time: e.time, title: String(localized: "The cue comes down on the ball"),
                               pieces: pieces, equation: "v↓ = v · sin θ", accent: .strike, importance: 1e9)
            }
            if let special = strikeCaption(for: e, id: id, timeline: timeline, facts: facts) { return special }
            let speed = b.velocityAfter.length
            var pieces = [String(localized: "The cue sends the ball off at \(f(speed)) metres per second. Its momentum is mass times speed.")]
            pieces += strikeSpinSentences(b, radius: R)
            // Off cloth, one more sentence: what this surface's numbers do to the skid and the roll that follow.
            pieces += surfaceSentences(facts)
            // The worked momentum only where the event's own impulse is this ball's mass times its speed (a level strike
            // with a pool ball); another table's ball or a strike the slate changed would make the line untrue.
            let m = facts.p.ballMass
            let consistent = speed > 0 && abs(e.normalImpulse - m * speed) <= 1e-6 * max(m * speed, 1e-9)
            return Caption(id: id, time: e.time, title: String(localized: "The cue hands over its speed"), pieces: pieces,
                           equation: "p = m · v", accent: .strike, importance: 1e9,
                           worked: consistent ? "p = m · v = \(f(m, 3)) kg · \(f(speed, 2)) m/s = \(f(m * speed, 2)) kg·m/s" : "")
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
            var pieces = [String(localized: "\(name(mover.ball).capitalizedFirst) was moving at \(f(mover.velocityBefore.length)) m/s. Energy handed off: \(f(share, 0)) percent goes to \(name(other.ball)), \(f(keep, 0)) percent stays, and the rest is lost as heat and sound.")]
            // The worked impulse: (1 + e) m v_perp / 2 with v_perp the closing speed along the line of centres. Shown
            // only when it agrees with the recorded impulse (a contact in the air is solved in 3D and need not).
            let n = e.normal.normalized
            let closing = (a.velocityBefore - b.velocityBefore).dot(n)
            let eBB = facts.p.ballBallRestitution, m = facts.p.ballMass
            let J = (1 + eBB) * m * closing / 2
            var worked = abs(J - e.normalImpulse) <= 0.02 * max(e.normalImpulse, 1e-9) && closing > 0
                ? "J = (1 + \(f(eBB, 2))) · \(f(m, 3)) kg · \(f(closing, 2)) m/s / 2 = \(f(J, 3)) N·s" : ""
            var title = String(localized: "Energy handed off")
            var equation = "J = (1 + e) · m · v⊥ / 2"
            if let t = throwFacts(e) {
                // Throw: friction at the contact sent the struck ball off the line of centres.
                pieces.append(t.degrees > 0
                    ? String(localized: "Friction between the balls dragged \(name(t.object)) \(f(abs(t.degrees))) degrees to the left of the line of centres: that is throw, and it is why a soft cut aimed on the line misses.")
                    : String(localized: "Friction between the balls dragged \(name(t.object)) \(f(abs(t.degrees))) degrees to the right of the line of centres: that is throw, and it is why a soft cut aimed on the line misses."))
                title = String(localized: "Throw")
                equation = "tan θ = v⊥ / v∥"
                worked = "tan θ = \(f(t.across, 3)) / \(f(t.along, 3)) → θ = \(f(abs(t.degrees)))°"
            }
            return Caption(id: id, time: e.time, title: title, pieces: withBends(pieces), equation: equation,
                           accent: .impact, importance: e.normalImpulse, worked: worked)
        case .cushion where e.edge == .post:
            // A post on another table (a bumper): it throws the ball back like a cushion, with its own bounce.
            let b = e.balls[0]
            let vin = b.velocityBefore.length
            guard vin > 0.5 else { return nil }
            let kept = (b.velocityAfter.dot(e.normal) / max(1e-9, -b.velocityBefore.dot(e.normal))) * 100
            // Bumper pool calls its posts bumpers (0.7.5); any other table with posts keeps the plain word.
            let bumper = facts.table == .bumperPool
            let title = bumper ? String(localized: "The bumper throws it back") : String(localized: "The post throws it back")
            let detail = bumper
                ? String(localized: "\(name(b.ball).capitalizedFirst) hits the bumper at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into it.")
                : String(localized: "\(name(b.ball).capitalizedFirst) hits the post at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into it.")
            return Caption(id: id, time: e.time, title: title, pieces: withBends([detail]),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse)
        case .pinDown:
            // A standing pin knocked over: the ball pays a little speed for it.
            let b = e.balls[0]
            let equation = "J = (1 + e) · m·mₚ / (m + mₚ) · v⊥"
            if !timeline.table.pins.isEmpty, !timeline.table.bedHoles.isEmpty {
                // Bar billiards (pins and holes in the bed): its pins are pegs that must not fall, so the caption
                // says what this one costs. The black peg is told apart by its index (BarBilliardsRules.blackPeg).
                let cost = e.feature == BarBilliardsRules.blackPeg
                    ? String(localized: "The black peg down costs the whole score.")
                    : String(localized: "A white peg down costs the points of this break.")
                let detail = String(localized: "\(name(b.ball).capitalizedFirst) knocks the peg over at \(f(b.velocityBefore.length)) m/s and rolls on at \(f(b.velocityAfter.length)) m/s.")
                return Caption(id: id, time: e.time, title: String(localized: "Peg down"), pieces: [detail, cost],
                               equation: equation, accent: .impact, importance: e.normalImpulse + 1)
            }
            return Caption(id: id, time: e.time, title: String(localized: "Pin down"),
                           pieces: [String(localized: "\(name(b.ball).capitalizedFirst) knocks the pin over at \(f(b.velocityBefore.length)) m/s and rolls on at \(f(b.velocityAfter.length)) m/s.")],
                           equation: equation, accent: .impact, importance: e.normalImpulse + 1)
        case .cushion where e.edge != .rail:
            // A pocket jaw or knuckle: the ball reached the mouth and was turned away (or rattled). Worth saying even
            // when slow, because it is the answer to "why didn't that go in?".
            let b = e.balls[0]
            let part = e.edge == .knuckle ? String(localized: "the point of the pocket") : String(localized: "the pocket's jaw")
            let title = e.edge == .knuckle ? String(localized: "Clipped the point") : String(localized: "Off the jaw")
            return Caption(id: id, time: e.time, title: title,
                           pieces: withBends([String(localized: "\(name(b.ball).capitalizedFirst) catches \(part) at \(f(b.velocityBefore.length)) m/s and is turned away from the hole. A little more to the middle of the pocket and it drops.")]),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse + 0.5)
        case .cushion:
            let b = e.balls[0]
            let vin = b.velocityBefore.length
            guard vin > 0.8 else { return nil }
            let inward = max(1e-9, -b.velocityBefore.dot(e.normal))
            let outward = b.velocityAfter.dot(e.normal)
            let kept = (outward / inward) * 100
            let spin = railSpinSentences(b, radius: R)
            if let bed = e.bedImpulse, bed > 0 {
                // Generation 2: the nose meets the ball above its centre (sine of the tilt (h - R) / R), so part of
                // the rail's push goes down into the cloth; the event carries the impulse the cloth took.
                let pieces = [String(localized: "\(name(b.ball).capitalizedFirst) hits the rail at \(f(vin)) m/s. The rail's nose is above the ball's centre, so it pushes down as well as back, and the cloth takes \(f(bed * 1000, 0)) millinewton-seconds of that push. It keeps \(f(kept, 0)) percent of its speed straight into the rail.")] + spin
                let nose = facts.p.cushionNoseHeight
                return Caption(id: id, time: e.time, title: String(localized: "The rail pushes it into the cloth"),
                               pieces: withBends(pieces), equation: "sin θ = (h − R) / R", accent: .cushion,
                               importance: e.normalImpulse,
                               worked: "sin θ = (\(f(nose * 1000)) − \(f(R * 1000))) mm / \(f(R * 1000)) mm = \(f(facts.p.railContactSine, 2))")
            }
            let pieces = [String(localized: "\(name(b.ball).capitalizedFirst) hits the rail at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into the rail. Sideways speed is trimmed by friction.")] + spin
            return Caption(id: id, time: e.time, title: String(localized: "The cushion pushes back"), pieces: withBends(pieces),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse,
                           worked: "v⊥′ = −\(f(outward / inward, 2)) · \(f(inward, 2)) m/s = −\(f(outward, 2)) m/s")
        case .phaseTransition:
            // Jumps first: take-off, landing and flying off the table are phase changes that carry a flight mark.
            if e.flight != .none { return flightCaption(e, id: id, timeline: timeline, facts: facts) }
            guard e.phaseFrom == .sliding, e.phaseTo == .rolling, let b = e.balls.first else { return nil }
            let v = b.velocityAfter.length
            // A bent path is worth naming even when the ball rolls on slowly (a masse often does). Read straight from
            // the sliding segment that closes here, the same source the tests restate.
            let seg = skidSegment(ball: b.ball, endingAt: e.time, in: timeline)
            let bend = seg.flatMap { Self.bend(of: $0) }
            guard v > 0.7 || bend != nil else { return nil }
            let detail: String
            if facts.surface == .cloth {
                detail = String(localized: "Friction with the cloth slowed \(name(b.ball)) and spun it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.")
            } else {
                // The skid's real length, from the recording. The solver always closes the sliding segment at this
                // event, so the nil case should not happen; if it did, no caption beats a made-up number.
                guard let seg else { return nil }
                let skid = e.time - seg.t0
                let secs = f(skid, skid < 1 ? 2 : 1)
                let mu = coefficient(facts.p.slidingFriction), g = f(facts.p.gravity)
                detail = facts.gravityOnly
                    ? String(localized: "On the Moon, the same sliding friction as cloth (\(mu)) under only \(g) m/s² of gravity took \(secs) seconds to slow \(name(b.ball)) and spin it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.")
                    : String(localized: "On \(facts.surface.title), sliding friction of \(mu) under gravity of \(g) m/s² took \(secs) seconds to slow \(name(b.ball)) and spin it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.")
            }
            // Skid time: the slip at the contact point closes at 7/2 * mu * g, so it is gone after 2 * slip / (7 mu g).
            // Worked from the segment's own start: the contact point's slip v + omega x (0, 0, -R), across the cloth.
            var worked = ""
            if let seg {
                let slip = Vec2(seg.velocity0.x - R * seg.omega0.y, seg.velocity0.y + R * seg.omega0.x).length
                let mu = facts.p.slidingFriction, g = facts.p.gravity
                let t = 2 * slip / (7 * mu * g)
                // Shown only when it matches the recorded skid (it should exactly: the solver ends the segment there).
                if abs(t - (seg.t1 - seg.t0)) <= 0.01 * max(t, 1e-6) {
                    worked = "t = 2 · \(f(slip, 2)) m/s / (7 · \(coefficient(mu)) · \(f(g, 2)) m/s²) = \(f(t, 2)) s"
                }
            }
            if let bend {
                // The bend first, then the skid's own sentence (the detail reads exactly as it did when joined by hand).
                return Caption(id: id, time: e.time, title: String(localized: "The path bends"),
                               pieces: [bendSentence(ball: b.ball, degrees: bend, names: facts.names), detail],
                               equation: "t = 2·Δv / (7·μ·g)", accent: .friction, importance: max(v, 0.7) * 0.12,
                               worked: worked)
            }
            return Caption(id: id, time: e.time, title: String(localized: "Skid turns into roll"), pieces: [detail],
                           equation: "t = 2·Δv / (7·μ·g)", accent: .friction, importance: v * 0.12, worked: worked)
        case .pocket:
            let b = e.balls[0]
            let speed = f(b.velocityBefore.length)
            // A hole in the bed (pocket index past the edge pockets): bar billiards calls it a hole, bumper pool a cup.
            if e.pocket >= TableSpec.edgePocketCount {
                let hole = facts.table == .barBilliards
                return Caption(id: id, time: e.time,
                               title: hole ? String(localized: "Into the hole") : String(localized: "Into the cup"),
                               pieces: withBends([hole
                                   ? String(localized: "\(name(b.ball).capitalizedFirst) drops into the hole at \(speed) m/s.")
                                   : String(localized: "\(name(b.ball).capitalizedFirst) drops into the cup at \(speed) m/s.")]),
                               equation: "ΔKE → 0", accent: .pocket, importance: 3)
            }
            return Caption(id: id, time: e.time, title: String(localized: "Pocketed"),
                           pieces: withBends([String(localized: "\(name(b.ball).capitalizedFirst) drops in at \(speed) m/s.")]),
                           equation: "ΔKE → 0", accent: .pocket, importance: 3)
        case .rimSkip:
            // Generation 2: the ball crossed the hole too fast to fall far enough to catch the far edge (the solver's
            // test: the fall g t^2 / 2 during the crossing time t was under a third of the radius).
            let b = e.balls[0]
            let vin = e.entry?.speed ?? b.velocityBefore.length
            // A pocket on the pool table; a hole in the bed is bar billiards' hole or bumper pool's cup.
            let bed = e.pocket >= TableSpec.edgePocketCount
            let cup = bed && facts.table != .barBilliards
            let title = !bed ? String(localized: "Too fast for the pocket")
                : cup ? String(localized: "Too fast for the cup") : String(localized: "Too fast for the hole")
            let detail = cup
                ? String(localized: "\(name(b.ball).capitalizedFirst) reaches the cup at \(f(vin)) m/s, too fast to drop: it is across before gravity can pull it far enough down to catch the far edge, and it carries on at \(f(b.velocityAfter.length)) m/s.")
                : String(localized: "\(name(b.ball).capitalizedFirst) reaches the hole at \(f(vin)) m/s, too fast to drop: it is across before gravity can pull it far enough down to catch the far edge, and it carries on at \(f(b.velocityAfter.length)) m/s.")
            return Caption(id: id, time: e.time, title: title, pieces: withBends([detail]),
                           equation: "h = g · t² / 2", accent: .pocket, importance: 2.5)
        case .settledInContact:
            // The jam guard (any generation): wedged balls chattering in bounces too small to see were brought to rest
            // touching; the event carries the energy taken out. One ball means it chattered between rubber faces.
            guard let first = e.balls.first else { return nil }
            let energy = energyPhrase(e.energyRemoved ?? 0)
            let detail = e.balls.count == 1
                ? String(localized: "\(name(first.ball).capitalizedFirst) was wedged against the rubber, bouncing in place in bounces too small to see. It is brought to rest, and the \(energy) those bounces would have turned into heat are taken out at once.")
                : String(localized: "\(e.balls.count) balls were wedged together, bouncing off each other in bounces too small to see. They are brought to rest touching, and the \(energy) those bounces would have turned into heat are taken out at once.")
            return Caption(id: id, time: e.time, title: String(localized: "Wedged and settled"), pieces: [detail],
                           equation: "ΔE = E_before − E_after", accent: .impact, importance: 1)
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
