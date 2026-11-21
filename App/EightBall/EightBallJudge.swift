// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the judge builder's pass: the skeleton's neutral verdict replaced by the
//          whole of design sections 1 and 2, the success-window sweep, the named style points, the "On a real table"
//          lines and the DEBUG self checks.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (a raised jump or massé stroke is a punch that stops at the strike, so
//          the authored jumps are no longer called double hits; the self checks run from -eightJudgeCheck in any build.)
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (the judge now runs on a background task, called by EightBallMode;
//          the sweep's solves carry an event budget, so a steep jump that jams the cue ball against a ball fails in a
//          fraction of a second instead of grinding to the solver's guard for five; the escape check prints each
//          judgement's time.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the scratch, first-contact, rail-after-contact and ball-off-the-table
//          checks now read the shared ShotFacts (BreakdownTimeline) with the same tie window and rail threshold, so
//          the judge and the match rules read a shot one way; verdicts are unchanged. The eight-ball group, pocket,
//          call, foul and loss types moved to the BreakdownRules module, hence its import.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the clear-path test and the first-ball ray scan moved to
//          App/TableLines.swift, shared with the spoken table; the two private helpers here now call it. Same numbers.)
// PURPOSE: Judges one Behind the 8-Ball attempt (docs/2026-11-21-behind-the-eight-ball-design.md, sections 1 and 2)
//          from its recording, the stroke as struck and the situation's start, and nothing else.
//          - Fouls (1.3): scratch (pocketed or off the table), wrong ball first (a tie inside sameInstant counts the
//            legal ball first), no ball hit, no rail after contact, object ball off the table, cue or bridge touching
//            a ball, double hit, scooped jump. The last three cannot be seen in the recording (the solver strikes in an
//            instant and draws no cue), so they are worked out from the stroke and the start: the cue's body and the
//            bridge head against the balls at the strike, the tip's follow-through against the cue ball's recorded
//            path, and the cue angle and tip height for any shot whose cue ball left the cloth.
//          - Loss of game on the 8 (1.4), as one explicit matrix: off the table, on a foul, too early, wrong pocket.
//          - Made as called (2.2): no foul, no loss, a ball you may call, in the pocket you called.
//          - Difficulty (2.3), only for a make: the stroke is solved again with aim, speed, side and (for a raised cue)
//            elevation nudged one at a time outward from the player's own value; each window is the unbroken range
//            that still makes it legally. Tightness is how many halvings separate each window from the same window of
//            the reference shot (a slow straight-in corner shot, object ball halfway), summed; the bands give 1-5. The
//            sides of every window are searched in parallel (DispatchQueue.concurrentPerform) to keep the verdict
//            quick, and each sweep solve stops at sweepEventBudget events (a jam counts as a miss); the reference windows are solved once per surface and cached.
//            Caps, in this order: measured, then within one of the matched escape's authored rating (or at most the
//            situation's top rating for a route nobody authored) only when the live surface is the situation's own,
//            then minus one in the outer part of a window, then 1...5, then a fluke forces 1.
//          - Style (2.4): hard technique, two techniques in one, threaded within a quarter of a ball's width, shape on
//            your next ball (a clear, easy-enough line, which most passing strokes of the sweep must also leave), and
//            for the game. Zeroed by a foul, a near-edge stroke or a fluke.
//          - Flukes (2.5): the called ball dropped after more contacts than any authored route with that ball gives it.
//          - Safety (2.6): a legal declared safety that leaves the opponent no straight line to any of their balls.
//          - The matched escape: the authored route (solved once on the situation's own cloth and cached) with the
//            same call, the same rails before contact, the same take-off and curve, and the same first ball.
//          - Analysis (what the Physics Lens shows to explain a rating) is kept for the last few recordings:
//            analysis(for:), factorLines(_:).
//          - The "On a real table" card: realTableLines(for:played:surface:) turns an escape's RealTableCard and the
//            real numbers (aim, cue angle, m/s, tip offsets, and the cloth's friction and cushion numbers when the
//            surface is not plain cloth) into label / words / number rows the views lay out side by side;
//            cardEscape(for:in:) picks which escape the card describes.
//          Every threshold is a named constant at the top so the situations can be tuned against it.
//          Called by EightBallMode once per attempt that started from the situation's own setup, on a background
//          task: it reads nothing on the main actor, and its caches are behind a lock.
// SRP/DRY check: Pass - judging only. Reads pockets through TrickShotJudge.pocket(of:in:), re-solves exactly as
//          ShowpieceModel.solve does (TableKind.standard.apply, then PlaySurface.apply, then PoolSolver.simulate on a
//          NextShot.shot input), reads the cloth numbers through RealTableNumbers / PlaySurface.parameters, and leaves
//          the total and the medal to EightBallVerdict. The geometry here (cue body, bridge head, follow-through) is new:
//          nothing else in the app judges a stroke against the balls behind it.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

enum EightBallJudge {

    // MARK: Tunable numbers (named so the situations can be tuned against them without touching the logic)

    static let ballRadius = PoolParameters().ballRadius

    /// Two first contacts of the cue ball closer in time than this are "at the same instant": the legal ball counts
    /// as first (design 1.3 rule 2; the solver has exact times, so this stands in for "one solver step").
    /// The value lives in ShotFacts (1e-5 seconds), the shared reading of a shot, so the match rules use the same one.
    static let sameInstant = ShotFacts.sameInstant
    /// A cushion contact counts as "reaching a rail" only if the ball has moved at least this far from where it
    /// started (a ball frozen on a rail that is pushed into it has not left the rail and come back). 0.002 m, kept in
    /// ShotFacts for the same reason.
    static let railMoveMinimum = ShotFacts.railMoveMinimum

    /// Double hit. After the strike the cue tip carries on at this share of the cue ball's launch speed (a cue about
    /// three times the ball's mass and a lively tip give roughly 0.44), for followThrough metres, and then stays put
    /// for cueHold seconds (not on a raised jump or massé stroke, a punch that stops at the strike). If the cue ball comes back within the tip's reach in that time, the tip touched it twice.
    static let cueFollowRatio = 0.44
    static let followThrough = 0.03
    static let cueHold = 0.10
    /// Balls closer than this (surface to surface) are frozen together: the double-hit rule does not apply.
    static let frozenGap = 0.0005
    /// How far into the cue ball the tip must reach to count as a touch (keeps rounding from calling a foul).
    static let doubleHitOverlap = 0.0005

    /// Scoop. A cue ball whose lowest point rose at least this high before its first contact has jumped.
    static let jumpMinHeight = 0.01
    /// A jump is legal only with the cue raised at least this much (the sine of 12 degrees)...
    static let minimumJumpElevation = 0.2079
    /// ...and with the tip striking at or above the ball's equator (this much below it is tolerated, metres).
    static let scoopTolerance = 0.0

    /// The cue's body, from the tip back: its length and its radius at the tip and at the butt.
    static let cueLength = 1.45
    static let cueTipRadius = 0.0065
    static let cueButtRadius = 0.0145
    /// The bridge head (CueRig.bridgeSetback): how far behind the cue ball's centre it stands, and its footprint.
    static let bridgeSetback = 0.30
    static let bridgeHeadHalfWidth = 0.07
    static let bridgeHeadHalfDepth = 0.02

    /// Style: threaded is passing a ball it never touched with less than a quarter of a ball's width between them.
    static let threadGap = 0.5 * ballRadius
    /// The cue ball's heading must turn at least this much (degrees) before its first contact to count as a curve;
    /// this much or more is a massé rather than a swerve.
    static let curveMinimum = 4.0
    static let masseCurve = 25.0
    /// Shape: the next shot's cut may be at most this (degrees), a side pocket must be entered within this of square.
    static let shapeMaxCut = 60.0
    static let sidePocketMaxAngle = 55.0
    /// Shape: at least this share of the sweep's passing strokes must also leave shape.
    static let shapeMajority = 0.5
    /// Safety: directions tried from the cue ball for a straight line to the opponent's balls (a quarter degree).
    static let safetyDirections = 1440

    /// Window sweep: how far each input may be pushed. Aim in degrees either side; speed is the shot panel's range;
    /// the tip must stay on the ball (ShowpieceModel.tipLimit); elevation is a sine.
    static let aimLimit = 4.0
    static let speedRange = 0.5...8.0
    static let tipLimit = 0.02
    static let elevationRange = 0.01...0.95
    /// The first nudge of each input, then each nudge is growth times the last (or, when the first already fails,
    /// growth times smaller), up to maxNudges, then bisections between the last pass and the first fail. Worst case
    /// 11 solves a side; the sides run in parallel.
    static let firstNudge: [Window.Input: Double] = [.aim: 0.03, .speed: 0.03, .side: 0.0005, .elevation: 0.01]
    static let growth = 2.5
    static let maxNudges = 7
    static let bisections = 3
    /// A sweep solve that needs more events than this is counted as a miss. An escape shot settles in tens of
    /// events. A steep jump that lands the cue ball wedged against a ball can instead spin out to the solver's
    /// 60,000-event guard (about five seconds each in Release, seen on point-blank's jump), and such a solve is cut
    /// off a fraction of a second into the shot, so it was never a make: with this budget every authored escape
    /// scores exactly as it did without it. The margin is wide on both sides (normal solves measured at about 10 to
    /// 60 events, the jam at the full 60,000), so this number is not delicate.
    static let sweepEventBudget = 2_000
    /// The stroke is "near the edge" when it sits within this share of the half-window from a failing edge.
    static let edgeShare = 0.25
    /// The reference shot has no elevation window; a raised stroke's elevation window is measured against this width.
    static let referenceElevationWidth = 0.25
    /// The reference shot: the object ball referenceLeg metres from the foot-right corner on its diagonal, the cue ball
    /// as far again behind it, struck slowly with a touch of draw so the cue ball never follows it in.
    static let referenceLeg = 0.6
    static let referenceSpeed = 1.5
    static let referenceTipUp = -0.007
    /// Tightness (halvings summed over the inputs) to difficulty points: up to each bound, the point at that index + 1.
    /// The design's first guess was 0 / 2 / 4 / 6 and says to set the bands by solving the authored routes. Measured
    /// in this solver, every input of a one-rail kick to pocket on the design's first layout is 3 to 6 halvings tighter
    /// than the reference (side spin and speed matter far more on a kick than on a slow straight shot), summing to 13
    /// to 19, which saturated those bands at 5. These provisional bands put those kicks at 4 and 5 and a straight-in
    /// shot at 1; retune them with checkAuthoredEscapes() once the situations exist.
    static let tightnessBands = [0.05, 6.0, 10.0, 14.0]

    // MARK: What the judge measured (for the Physics Lens)

    /// One success window: the unbroken range of an input around the player's value that still makes it legally.
    struct Window: Equatable, Sendable {
        enum Input: String, CaseIterable, Sendable { case aim, speed, side, elevation }
        var input: Input
        var value: Double
        var low: Double
        var high: Double
        /// True when the search reached its limit on that side without a failure (not a real edge).
        var lowOpen: Bool
        var highOpen: Bool
        var width: Double { high - low }
    }

    /// The measured factors that explain a rating (design 2.3's list); they never add points on their own.
    struct Factors: Equatable, Sendable {
        var firstContact: Int?
        var railsBeforeContact = 0
        /// Rails the called ball took before it dropped (or stopped).
        var calledBallRails = 0
        /// The ball that first touched the called ball (0 is the cue ball), and every ball that touched it.
        var calledFirstToucher: Int?
        var calledTouches: Set<Int> = []
        /// Degrees between the striking ball's path and the called ball's path off the hit.
        var cutAngle: Double?
        /// Metres the cue ball travelled to its first contact, and the called ball from its first touch.
        var cueTravel = 0.0
        var objectTravel: Double?
        /// The smallest gap (surface to surface, metres) the cue ball or the called ball passed a ball it never touched.
        var narrowestGap: Double?
        /// How high the cue ball's lowest point rose before its first contact, and the balls it flew over.
        var jumpHeight = 0.0
        var blockersCleared: [Int] = []
        var elevationDegrees = 0.0
        /// How far the cue ball's heading turned before its first contact, degrees (positive is to the left).
        var curveDegrees = 0.0

        var jumped: Bool { jumpHeight >= EightBallJudge.jumpMinHeight }
        var curved: Bool { abs(curveDegrees) >= EightBallJudge.curveMinimum }
    }

    /// Everything measured for one judged recording.
    struct Analysis: Equatable, Sendable {
        var factors: Factors
        /// The player's windows and the reference shot's, on the same surface (empty unless the shot was made).
        var windows: [Window] = []
        var referenceWindows: [Window] = []
        /// Halvings summed over the inputs, and the rating they give before any cap.
        var tightness: Double?
        var measuredDifficulty: Int?
        /// The techniques the shot actually used.
        var techniques: [EightBallEscapeKind] = []

        /// The range of speeds that would still have made it, m/s.
        var speedWindow: ClosedRange<Double>? {
            windows.first { $0.input == .speed }.map { $0.low...$0.high }
        }
    }

    // MARK: Judge

    /// Judge one attempt.
    /// - timeline: the attempt's recording (ShotAttempt.timeline), solved on `surface`.
    /// - call: what the player called before the shot.
    /// - situation: the situation it was played from (its setup is the attempt's start).
    /// - settings: the stroke as struck (aim degrees, speed m/s, tip offsets, elevation as a sine; nil is level).
    /// - surface: the surface the recording was solved on (window sweeps re-solve on the same one).
    /// - attempt: the try number, 1-based: 1 is the first try, 2 and 3 cost a point each, above 3 is practice.
    static func judge(timeline: Timeline, call: EightBallCall, situation: EightBallSituation, settings: TrickSettings,
                      surface: PlaySurface, attempt: Int) -> EightBallVerdict {
        var v = EightBallVerdict.neutral(call: call, tryNumber: attempt)
        let start = situation.setup
        guard start.count == 16, timeline.ballCount == 16 else { return v }

        // The same recording, call and stroke judged again (the mode re-reading it) costs nothing.
        let key = MemoKey(timeline: timeline.contentHash, surface: surface, situation: situation.id, call: call,
                          settings: settings)
        if let cached = memo.verdict(key) {
            var c = cached
            c.tryNumber = attempt
            return c
        }

        let legal = Set(situation.legalBalls)
        let o = outcome(timeline, call: call, situation: situation, settings: settings)
        v.fouls = o.fouls
        v.loss = o.loss
        v.madeAsCalled = o.made

        let factors = measure(timeline, start: start, settings: settings, calledBall: call.ball, legal: legal)
        var analysis = Analysis(factors: factors)
        analysis.techniques = techniques(factors, calledBall: call.ball).sorted { $0.rawValue < $1.rawValue }
        let authored = authoredRoutes(situation)
        v.matchedEscape = match(Route(factors), call: call, settings: settings, among: authored, in: situation)

        if v.legal, call == .safety { v.safetyLeftHooked = opponentHooked(after: timeline, situation: situation) }

        if o.made {
            // Difficulty: the windows around the player's own stroke against the reference shot's on this surface.
            var inputs: [Window.Input] = [.aim, .speed, .side]
            if (settings.elevation ?? 0) > 0 { inputs.append(.elevation) }
            let sweep = playerWindows(inputs, settings: settings, call: call, situation: situation, surface: surface)
            let reference = referenceWindows(on: surface)
            let tight = tightness(sweep.windows, against: reference)
            let measured = difficultyPoints(tightness: tight)
            analysis.windows = sweep.windows
            analysis.referenceWindows = reference
            analysis.tightness = tight
            analysis.measuredDifficulty = measured
            v.nearEdge = sweep.windows.contains { isNearEdge($0, reference: reference) }
            v.fluke = isFluke(Route(factors), calledBall: call.ball, among: authored, in: situation)

            // Caps in the stated order (design 2.3, README): authored +-1 or top rating only on the situation's cloth.
            var d = measured
            if surface == situation.surface {
                if let id = v.matchedEscape, let e = situation.escapes.first(where: { $0.id == id }) {
                    d = min(max(d, e.rating - 1), e.rating + 1)
                } else {
                    d = min(d, situation.topRating)
                }
            }
            if v.nearEdge { d -= 1 }
            d = min(max(d, 1), EightBallVerdict.maxDifficulty)
            if v.fluke { d = 1 }
            v.difficulty = d

            if !v.nearEdge && !v.fluke {
                v.style = stylePoints(factors, techniques: Set(analysis.techniques), timeline: timeline,
                                      call: call, situation: situation, sweepShapes: sweep.shapes)
            }
        }

        v.line = sentence(v, outcome: o, call: call, legal: legal)
        memo.store(v, analysis: analysis, for: key)
        return v
    }

    /// What was measured for a recording judged recently (nil once it has dropped out of the small cache).
    static func analysis(for timeline: Timeline) -> Analysis? { memo.analysis(timeline.contentHash) }

    // MARK: Fouls, loss, made (design 1.3, 1.4, 2.2)

    private struct Outcome {
        var fouls: [EightBallFoul] = []
        var loss: EightBallLoss?
        var made = false
        /// Where the called ball dropped, if it did (any pocket).
        var calledBallPocket: Int?
    }

    /// The rules part of the verdict. Also the pass test of every window-sweep solve, so it must stay cheap.
    private static func outcome(_ tl: Timeline, call: EightBallCall, situation s: EightBallSituation,
                                settings: TrickSettings) -> Outcome {
        var o = Outcome()
        let start = s.setup
        let legal = Set(s.legalBalls)
        var found = Set<EightBallFoul>()

        // The plain facts (scratch, first contact, rail after contact, balls off the table) come from the shared
        // reading of a shot, ShotFacts, with this judge's own tie window and rail threshold.
        let facts = shotFacts(tl, start: start)
        if facts.cueBallScratched { found.insert(.scratch) }
        let first = firstContact(facts, legal: legal)
        if let f = first {
            if !legal.contains(f.ball) { found.insert(.wrongBallFirst) }
            if !facts.railOrPocketAfterContact { found.insert(.noRailAfterContact) }
        } else {
            found.insert(.noBallHit)
        }
        if !facts.objectBallsOffTable.isEmpty { found.insert(.objectBallOffTable) }
        if cueOrBridgeTouches(start: start, settings: settings, bridge: s.usesBridge) {
            found.insert(.cueOrBridgeTouchedBall)
        }
        if doubleHit(tl, start: start, settings: settings, first: first) { found.insert(.doubleHit) }
        if scooped(tl, settings: settings, before: first?.time ?? tl.duration) { found.insert(.illegalJump) }
        o.fouls = EightBallFoul.allCases.filter { found.contains($0) }

        // Loss of game on the 8, one case at a time. The 8 on a foul (any foul, a scratch included) comes before
        // too early and wrong pocket; a declared safety that drops the 8 is a wrong pocket (it was not called).
        if NextShot.isOnTable(start[8]) {
            if tl.flewOffTable(8) {
                o.loss = .eightOffTable
            } else if let k = TrickShotJudge.pocket(of: 8, in: tl) {
                if !o.fouls.isEmpty {
                    o.loss = .eightOnFoul
                } else if !s.onTheEight {
                    o.loss = .eightEarly
                } else if !(call.ball == 8 && call.pocket?.rawValue == k) {
                    o.loss = .eightWrongPocket
                }
            }
        }

        if let b = call.ball, let p = call.pocket {
            o.calledBallPocket = TrickShotJudge.pocket(of: b, in: tl)
            o.made = o.fouls.isEmpty && o.loss == nil && legal.contains(b) && o.calledBallPocket == p.rawValue
        }
        return o
    }

    /// The shared reading of this recording (BreakdownTimeline/ShotFacts.swift), with the cue ball as ball 0 and this
    /// judge's tie window and rail threshold (the same numbers ShotFacts uses by default).
    private static func shotFacts(_ tl: Timeline, start: [Vec2]) -> ShotFacts {
        ShotFacts(timeline: tl, start: start, cueBall: 0, sameInstant: sameInstant, railMoveMinimum: railMoveMinimum)
    }

    /// The object ball the cue ball reached first, and when. Contacts within sameInstant of the first are a tie, and a
    /// legal ball among them counts as first (the rules' answer when the order cannot be told). ShotFacts does the
    /// reading; this keeps the tuple the double-hit and scoop checks take.
    private static func firstContact(_ facts: ShotFacts, legal: Set<Int>) -> (ball: Int, time: Double)? {
        facts.firstContact(preferring: legal).map { (ball: $0.ball, time: $0.time) }
    }

    /// The cue's own frame for a stroke: the solver's (Simulation.applyRaisedStrike): d the aim on the table, e and c
    /// the sine and cosine of the cue's raise, cue the direction it travels, up and right the tip-offset axes.
    private struct StrikeFrame {
        let d: Vec2
        let e: Double
        let c: Double
        let cue: Vec3
        let up: Vec3
        let right: Vec3
    }

    private static func frame(_ s: TrickSettings) -> StrikeFrame {
        let a = s.aim * Double.pi / 180
        let d = Vec2(cos(a), sin(a))
        let e = min(max(s.elevation ?? 0, 0), 0.995)
        let c = (1 - e * e).squareRoot()
        return StrikeFrame(d: d, e: e, c: c, cue: Vec3(c * d.x, c * d.y, -e), up: Vec3(e * d.x, e * d.y, c),
                           right: Vec3(d.y, -d.x, 0))
    }

    /// Where the tip meets the cue ball (table metres, height above the cloth), for a ball resting at `p`.
    private static func contactPoint(_ p: Vec2, _ s: TrickSettings, _ f: StrikeFrame) -> Vec3 {
        let r = ballRadius
        let depth = max(r * r - s.tipUp * s.tipUp - s.tipSide * s.tipSide, 0).squareRoot()
        return Vec3(p.x, p.y, r) - f.cue * depth + f.up * s.tipUp + f.right * s.tipSide
    }

    /// Cue or bridge touching a ball at the strike (rule 5). The cue is a tapered rod from the tip back along its
    /// own line; the bridge head (only in a situation that uses the bridge) stands bridgeSetback behind the cue ball.
    private static func cueOrBridgeTouches(start: [Vec2], settings s: TrickSettings, bridge: Bool) -> Bool {
        let r = ballRadius
        let f = frame(s)
        let tip = contactPoint(start[0], s, f)
        let others = (1..<start.count).filter { NextShot.isOnTable(start[$0]) }
        var t = 0.0
        while t <= cueLength {
            let q = tip - f.cue * t
            let rod = cueTipRadius + (cueButtRadius - cueTipRadius) * t / cueLength
            for b in others where (Vec3(start[b].x, start[b].y, r) - q).length < r + rod { return true }
            t += 0.004
        }
        guard bridge else { return false }
        let head = start[0] - f.d * bridgeSetback
        let across = f.d.perp
        for b in others {
            let rel = start[b] - head
            let along = max(abs(rel.dot(f.d)) - bridgeHeadHalfDepth, 0)
            let side = max(abs(rel.dot(across)) - bridgeHeadHalfWidth, 0)
            if (along * along + side * side).squareRoot() < r { return true }
        }
        return false
    }

    /// Double hit (rule 6): the tip follows through at cueFollowRatio of the launch speed for followThrough metres
    /// (never below the cloth), then holds for cueHold seconds; if the recorded cue ball comes back within its reach,
    /// the tip touched it twice. Not applied when the cue ball starts frozen to the ball it hits first.
    private static func doubleHit(_ tl: Timeline, start: [Vec2], settings s: TrickSettings,
                                  first: (ball: Int, time: Double)?) -> Bool {
        let r = ballRadius
        if let hit = first, (start[hit.ball] - start[0]).length < 2 * r + frozenGap { return false }
        guard s.power > 0 else { return false }
        // A cue raised to a legal jump angle is played as a short punch that stops at the strike. The solver's launch
        // already folds in the squeeze between tip, ball and cloth and the ball's bounce off the bed, so there is no
        // separate follow-through for it to meet. The rule applies to cues below that angle.
        if (s.elevation ?? 0) >= minimumJumpElevation { return false }
        let f = frame(s)
        let tip0 = contactPoint(start[0], s, f)
        let speed = cueFollowRatio * s.power
        let reach = f.e > 1e-9 ? min(followThrough, tip0.z / f.e) : followThrough
        let end = min(reach / speed + cueHold, tl.duration)
        let step = 0.0005
        var t = step
        while t <= end {
            let st = tl.state(ball: 0, at: t)
            if st.pocketed { break }
            let tip = tip0 + f.cue * min(speed * t, reach)
            let centre = Vec3(st.position.x, st.position.y, r + st.height)
            if (centre - tip).length < r - doubleHitOverlap { return true }
            t += step
        }
        return false
    }

    /// Scooped jump (rule 7): the cue ball left the cloth before its first contact, but the cue was raised less than
    /// minimumJumpElevation or the tip struck below the ball's equator (the cue got under the ball instead of
    /// driving it down). Every scoop is a foul, since a simulation cannot tell an accident from intent.
    private static func scooped(_ tl: Timeline, settings s: TrickSettings, before end: Double) -> Bool {
        guard maxHeight(tl, ball: 0, until: end) >= jumpMinHeight else { return false }
        let f = frame(s)
        let r = ballRadius
        let depth = max(r * r - s.tipUp * s.tipUp - s.tipSide * s.tipSide, 0).squareRoot()
        let aboveCentre = f.e * depth + f.c * s.tipUp
        return f.e < minimumJumpElevation || aboveCentre < -scoopTolerance
    }

    /// The highest a ball's lowest point rose above the cloth before `end`, sampled through its airborne segments.
    private static func maxHeight(_ tl: Timeline, ball: Int, until end: Double) -> Double {
        var top = 0.0
        for seg in tl.segments[ball] where seg.phase == .airborne && seg.t0 < end {
            let t1 = min(seg.t1.isFinite ? seg.t1 : end, end)
            for i in 0...20 {
                let t = seg.t0 + (t1 - seg.t0) * Double(i) / 20
                top = max(top, tl.state(ball: ball, at: t).height)
            }
        }
        return top
    }

    // MARK: Measuring the shot (the Lens factors, the route, the techniques)

    private static func measure(_ tl: Timeline, start: [Vec2], settings: TrickSettings, calledBall: Int?,
                                legal: Set<Int>) -> Factors {
        var f = Factors()
        let r = ballRadius
        let first = firstContact(shotFacts(tl, start: start), legal: legal)
        f.firstContact = first?.ball
        let cueEnd = first?.time ?? tl.duration
        f.railsBeforeContact = tl.events.filter { e in
            e.kind == .cushion && e.edge == .rail && e.balls.first?.ball == 0 && e.time < cueEnd
        }.count
        f.jumpHeight = maxHeight(tl, ball: 0, until: cueEnd)
        f.elevationDegrees = asin(min(max(settings.elevation ?? 0, 0), 1)) * 180 / Double.pi
        f.curveDegrees = curve(tl)
        f.cueTravel = travel(tl, ball: 0, from: 0, to: cueEnd)

        // Who touched whom over the whole shot (a "blocker" for the gap is a ball the mover never touched).
        var touched: [Int: Set<Int>] = [:]
        for e in tl.events where e.kind == .ballBall && e.balls.count == 2 {
            let a = e.balls[0].ball, b = e.balls[1].ball
            touched[a, default: []].insert(b)
            touched[b, default: []].insert(a)
        }

        var calledFrom = 0.0, calledTo = 0.0
        if let c = calledBall, c > 0, c < 16, NextShot.isOnTable(start[c]) {
            let end = tl.pocketTime[c] ?? tl.duration
            let hits = tl.events.filter { e in
                e.kind == .ballBall && e.time <= end && e.balls.contains { $0.ball == c }
            }.sorted { $0.time < $1.time }
            f.calledTouches = Set(hits.compactMap { e in e.balls.first { $0.ball != c }?.ball })
            if let h = hits.first, let striker = h.balls.first(where: { $0.ball != c }),
               let struck = h.balls.first(where: { $0.ball == c }) {
                f.calledFirstToucher = striker.ball
                let vin = striker.velocityBefore, vout = struck.velocityAfter
                if vin.length > 1e-6, vout.length > 1e-6 {
                    let cosine = min(max(vin.dot(vout) / (vin.length * vout.length), -1), 1)
                    f.cutAngle = acos(cosine) * 180 / Double.pi
                }
                f.objectTravel = travel(tl, ball: c, from: h.time, to: end)
                calledFrom = h.time
                calledTo = end
            }
            f.calledBallRails = tl.events.filter { e in
                e.kind == .cushion && e.edge == .rail && e.balls.first?.ball == c && e.time < end
            }.count
        }

        // The narrowest gap past a ball it never touched, for the cue ball before its first contact and the called
        // ball on its way to the pocket; the balls the cue ball flew over on the way.
        var narrowest: Double?
        var cleared = Set<Int>()
        func scan(_ mover: Int, from t0: Double, to t1: Double) {
            guard t1 > t0 else { return }
            let blockers = (1..<16).filter { b in
                b != mover && NextShot.isOnTable(start[b]) && !(touched[mover]?.contains(b) ?? false)
            }
            guard !blockers.isEmpty else { return }
            let steps = min(1500, max(20, Int((t1 - t0) / 0.003)))
            for i in 0...steps {
                let t = t0 + (t1 - t0) * Double(i) / Double(steps)
                let m = tl.state(ball: mover, at: t)
                if m.pocketed { break }
                let pm = Vec3(m.position.x, m.position.y, r + m.height)
                for b in blockers {
                    let o = tl.state(ball: b, at: t)
                    if o.pocketed { continue }
                    let gap = (pm - Vec3(o.position.x, o.position.y, r + o.height)).length - 2 * r
                    if gap < (narrowest ?? .infinity) { narrowest = gap }
                    if mover == 0, m.height > 0.002, (m.position - o.position).length < 2 * r { cleared.insert(b) }
                }
            }
        }
        scan(0, from: 0, to: cueEnd)
        if let c = calledBall, calledTo > calledFrom { scan(c, from: calledFrom, to: calledTo) }
        f.narrowestGap = narrowest.map { max($0, 0) }
        f.blockersCleared = cleared.sorted()
        return f
    }

    /// How far the cue ball's heading turned before it first met a cushion or a ball (or stopped), degrees.
    private static func curve(_ tl: Timeline) -> Double {
        let firstEvent = tl.events.first { e in
            (e.kind == .cushion || e.kind == .ballBall) && e.balls.contains { $0.ball == 0 }
        }
        let stopped = tl.segments[0].first { $0.phase == .stationary || $0.phase == .spinning }?.t0
        let end = firstEvent?.time ?? stopped ?? tl.duration
        guard end > 2e-4 else { return 0 }
        let v0 = tl.state(ball: 0, at: 1e-4).velocity
        let v1 = tl.state(ball: 0, at: end - 1e-4).velocity
        guard v0.length > 1e-4, v1.length > 1e-4 else { return 0 }
        let cross = v0.x * v1.y - v0.y * v1.x
        return atan2(cross, v0.dot(v1)) * 180 / Double.pi
    }

    /// Distance a ball covered on the cloth between two times, metres.
    private static func travel(_ tl: Timeline, ball: Int, from t0: Double, to t1: Double) -> Double {
        guard t1 > t0 else { return 0 }
        let steps = min(1000, max(10, Int((t1 - t0) / 0.01)))
        var total = 0.0
        var last = tl.state(ball: ball, at: t0).position
        for i in 1...steps {
            let p = tl.state(ball: ball, at: t0 + (t1 - t0) * Double(i) / Double(steps)).position
            total += (p - last).length
            last = p
        }
        return total
    }

    /// The techniques a shot used, read from what happened (design 2.4): a kick (a rail before contact), a bank (the
    /// called ball took a rail), a jump, a curve (massé or swerve by how far it turned), a combination (another ball
    /// drove the called ball) or a carom (the cue ball reached the called ball after glancing off another).
    private static func techniques(_ f: Factors, calledBall: Int?) -> Set<EightBallEscapeKind> {
        var k = Set<EightBallEscapeKind>()
        if f.railsBeforeContact > 0 { k.insert(.kick) }
        if f.calledBallRails > 0 { k.insert(.bank) }
        if f.jumped { k.insert(.jump) }
        if f.curved { k.insert(abs(f.curveDegrees) >= masseCurve ? .masse : .swerve) }
        if let c = calledBall, let first = f.firstContact, first != c, let toucher = f.calledFirstToucher {
            k.insert(toucher == 0 ? .carom : .combination)
        }
        return k
    }

    // MARK: Routes: the matched escape and flukes

    /// What makes two shots the same route, whatever the exact numbers.
    private struct Route: Equatable, Sendable {
        var rails: Int
        var jumped: Bool
        var curved: Bool
        var firstContact: Int?
        var calledTouches: Set<Int>

        init(_ f: Factors) {
            rails = f.railsBeforeContact
            jumped = f.jumped
            curved = f.curved
            firstContact = f.firstContact
            calledTouches = f.calledTouches
        }
    }

    /// Every authored escape played on the situation's own cloth, measured once and cached by situation id.
    private static func authoredRoutes(_ s: EightBallSituation) -> [(escape: EightBallEscape, route: Route)] {
        if let cached = memo.routes(s.id) {
            return cached.compactMap { pair in
                s.escapes.first { $0.id == pair.id }.map { (escape: $0, route: pair.route) }
            }
        }
        let legal = Set(s.legalBalls)
        let pairs: [(id: String, route: Route)] = s.escapes.map { e in
            let tl = solve(s.setup, e.settings, on: s.surface)
            let f = measure(tl, start: s.setup, settings: e.settings, calledBall: e.call.ball, legal: legal)
            return (id: e.id, route: Route(f))
        }
        memo.storeRoutes(pairs, for: s.id)
        return pairs.compactMap { pair in
            s.escapes.first { $0.id == pair.id }.map { (escape: $0, route: pair.route) }
        }
    }

    /// The authored escape this shot played: the same call, the same rails before contact, the same take-off and
    /// curve, the same first ball; the nearest aim among several. Kisses on the way do not change the route.
    private static func match(_ r: Route, call: EightBallCall, settings: TrickSettings,
                              among authored: [(escape: EightBallEscape, route: Route)],
                              in s: EightBallSituation) -> String? {
        let same = authored.filter { a in
            a.escape.call == call && a.route.rails == r.rails && a.route.jumped == r.jumped
                && a.route.curved == r.curved && a.route.firstContact == r.firstContact
        }
        func gap(_ e: EightBallEscape) -> Double {
            var d = abs(e.settings.aim - settings.aim).truncatingRemainder(dividingBy: 360)
            if d > 180 { d = 360 - d }
            return d
        }
        return same.min { gap($0.escape) < gap($1.escape) }?.escape.id
    }

    /// A fluke: the called ball was touched by more balls than one before it dropped (a kiss or a carom on the way),
    /// and no authored route for that ball has it touched by those same balls (kisses need not be called, so it still
    /// counts as made).
    private static func isFluke(_ r: Route, calledBall: Int?, among authored: [(escape: EightBallEscape, route: Route)],
                                in s: EightBallSituation) -> Bool {
        guard let c = calledBall, r.calledTouches.count > 1 else { return false }
        return !authored.contains { a in a.escape.call.ball == c && a.route.calledTouches.isSuperset(of: r.calledTouches) }
    }

    // MARK: Difficulty: the success windows (design 2.3)

    /// The same solve the app does (ShowpieceModel.solve): the standard table's numbers, then the surface's, written
    /// into the parameters of a NextShot.shot from the start. The seed only matters for a rack, so any fixed one does.
    static func solve(_ start: [Vec2], _ s: TrickSettings, on surface: PlaySurface) -> Timeline {
        PoolSolver.simulate(shotInput(start, s, on: surface))
    }

    /// A sweep solve: the same solve within sweepEventBudget events, nil when a jam used the budget up.
    private static func sweepSolve(_ start: [Vec2], _ s: TrickSettings, on surface: PlaySurface) -> Timeline? {
        PoolSolver.simulate(shotInput(start, s, on: surface), eventBudget: sweepEventBudget)
    }

    private static func shotInput(_ start: [Vec2], _ s: TrickSettings, on surface: PlaySurface) -> ShotInput {
        var p = PoolParameters()
        TableKind.standard.apply(to: &p)
        surface.apply(to: &p)
        let a = s.aim * Double.pi / 180
        return NextShot.shot(from: start, direction: Vec2(cos(a), sin(a)), speed: s.power, tipUp: s.tipUp,
                             tipSide: s.tipSide, seed: 1, parameters: p, elevation: s.elevation ?? 0)
    }

    /// The player's windows, plus whether each passing solve of the sweep also left shape.
    private static func playerWindows(_ inputs: [Window.Input], settings: TrickSettings, call: EightBallCall,
                                      situation: EightBallSituation, surface: PlaySurface)
        -> (windows: [Window], shapes: [Bool]) {
        let passes: @Sendable (TrickSettings) -> (Bool, Bool?) = { t in
            guard let tl = sweepSolve(situation.setup, t, on: surface) else { return (false, nil) }
            guard outcome(tl, call: call, situation: situation, settings: t).made else { return (false, nil) }
            return (true, leavesShape(after: tl, situation: situation))
        }
        return windows(inputs, around: settings, passes: passes)
    }

    /// The reference shot (a slow straight-in corner shot, object ball halfway), as a one-ball situation of its own.
    static var referenceSituation: (situation: EightBallSituation, settings: TrickSettings) {
        let hole = Vec2(2.54, 0)
        let inward = Vec2(-1, 1).normalized
        var setup = [Vec2](repeating: NextShot.offTable, count: 16)
        setup[0] = hole + inward * (2 * referenceLeg)
        setup[1] = hole + inward * referenceLeg
        let s = EightBallSituation(id: "reference", number: 0, title: "reference", story: "", setup: setup,
                                   group: .solids, surface: .cloth, escapes: [], lesson: "", taughtBy: [])
        return (s, TrickSettings(aim: -45, power: referenceSpeed, tipUp: referenceTipUp, tipSide: 0))
    }

    /// The reference shot's aim, speed and side windows on a surface, solved once per surface and kept.
    static func referenceWindows(on surface: PlaySurface) -> [Window] {
        if let cached = memo.reference(surface) { return cached }
        let ref = referenceSituation
        let call = EightBallCall.ball(1, pocket: .footRight)
        let passes: @Sendable (TrickSettings) -> (Bool, Bool?) = { t in
            guard let tl = sweepSolve(ref.situation.setup, t, on: surface) else { return (false, nil) }
            return (outcome(tl, call: call, situation: ref.situation, settings: t).made, nil)
        }
        let w = windows([.aim, .speed, .side], around: ref.settings, passes: passes).windows
        memo.storeReference(w, for: surface)
        return w
    }

    private static func value(_ input: Window.Input, _ s: TrickSettings) -> Double {
        switch input {
        case .aim: return s.aim
        case .speed: return s.power
        case .side: return s.tipSide
        case .elevation: return s.elevation ?? 0
        }
    }

    private static func setting(_ input: Window.Input, _ s: TrickSettings, _ v: Double) -> TrickSettings {
        var t = s
        switch input {
        case .aim: t.aim = v
        case .speed: t.power = v
        case .side: t.tipSide = v
        case .elevation: t.elevation = v > 0 ? v : nil
        }
        return t
    }

    /// How far each input may go, always containing the player's own value.
    private static func bounds(_ input: Window.Input, _ s: TrickSettings) -> ClosedRange<Double> {
        let v = value(input, s)
        let range: ClosedRange<Double>
        switch input {
        case .aim: range = (v - aimLimit)...(v + aimLimit)
        case .speed: range = speedRange
        case .side:
            let r = max(tipLimit * tipLimit - s.tipUp * s.tipUp, 0).squareRoot()
            range = -r...r
        case .elevation: range = elevationRange
        }
        return min(range.lowerBound, v)...max(range.upperBound, v)
    }

    private struct SideResult: Sendable {
        var edge: Double
        var open: Bool
        var shapes: [Bool]
    }

    /// One side of one window: nudge outward (each nudge growth times the last) until a solve fails or the limit is
    /// reached, then bisect between the last pass and the first fail; the edge is the middle of what is left.
    /// When the very first nudge already fails, the window is tighter than it: the nudge shrinks (each growth times
    /// smaller, up to maxNudges times) until one passes, so a tight window is measured rather than reported at the
    /// search's floor. That keeps the search scale-free: a kick's hundredth of a degree and a straight shot's degree
    /// are both found to the same relative precision.
    private static func searchSide(_ input: Window.Input, direction: Double, from s: TrickSettings,
                                   passes: @Sendable (TrickSettings) -> (Bool, Bool?)) -> SideResult {
        let v = value(input, s)
        let b = bounds(input, s)
        let room = direction > 0 ? b.upperBound - v : v - b.lowerBound
        var shapes: [Bool] = []
        guard room > 0 else { return SideResult(edge: 0, open: true, shapes: shapes) }
        var lastPass = 0.0
        var firstFail: Double?
        var nudge = min(firstNudge[input] ?? 0.01, room)
        // Tight window: shrink the first nudge until it passes; the smallest failing nudge is the bracket's far end.
        var first = passes(setting(input, s, v + direction * nudge))
        var shrinks = 0
        while !first.0 && shrinks < maxNudges {
            firstFail = nudge
            nudge /= growth
            shrinks += 1
            first = passes(setting(input, s, v + direction * nudge))
        }
        if first.0 {
            lastPass = nudge
            if let shape = first.1 { shapes.append(shape) }
            if shrinks == 0 && nudge >= room { return SideResult(edge: room, open: true, shapes: shapes) }
        } else {
            firstFail = nudge   // even the floor failed: the edge lies between the stroke itself and the floor
        }
        // The first nudge passed outright: widen from it until a nudge fails or the limit is reached.
        for _ in 0..<(first.0 && shrinks == 0 ? maxNudges - 1 : 0) {
            nudge *= growth
            let off = min(nudge, room)
            let r = passes(setting(input, s, v + direction * off))
            if r.0 {
                lastPass = off
                if let shape = r.1 { shapes.append(shape) }
                if off >= room { return SideResult(edge: room, open: true, shapes: shapes) }
            } else {
                firstFail = off
                break
            }
        }
        guard var fail = firstFail else { return SideResult(edge: lastPass, open: true, shapes: shapes) }
        for _ in 0..<bisections {
            let mid = (lastPass + fail) / 2
            let r = passes(setting(input, s, v + direction * mid))
            if r.0 {
                lastPass = mid
                if let shape = r.1 { shapes.append(shape) }
            } else {
                fail = mid
            }
        }
        return SideResult(edge: (lastPass + fail) / 2, open: false, shapes: shapes)
    }

    /// Every side of every input searched in parallel (the solver is a pure function, so order cannot change an
    /// answer), then put back together as windows.
    private static func windows(_ inputs: [Window.Input], around s: TrickSettings,
                                passes: @escaping @Sendable (TrickSettings) -> (Bool, Bool?))
        -> (windows: [Window], shapes: [Bool]) {
        let jobs: [(input: Window.Input, direction: Double)] = inputs.flatMap { i in
            [(input: i, direction: -1.0), (input: i, direction: 1.0)]
        }
        let slots = Slots<SideResult>(jobs.count)
        DispatchQueue.concurrentPerform(iterations: jobs.count) { i in
            slots.set(i, searchSide(jobs[i].input, direction: jobs[i].direction, from: s, passes: passes))
        }
        let results = slots.values
        var out: [Window] = []
        var shapes: [Bool] = []
        for (n, input) in inputs.enumerated() {
            guard let lo = results[2 * n], let hi = results[2 * n + 1] else { continue }
            let v = value(input, s)
            out.append(Window(input: input, value: v, low: v - lo.edge, high: v + hi.edge, lowOpen: lo.open,
                              highOpen: hi.open))
            shapes += lo.shapes + hi.shapes
        }
        return (out, shapes)
    }

    /// Halvings from the reference window down to the player's, summed over the inputs (never negative per input).
    private static func tightness(_ player: [Window], against reference: [Window]) -> Double {
        var total = 0.0
        for w in player {
            let ref = w.input == .elevation ? referenceElevationWidth
                : (reference.first { $0.input == w.input }?.width ?? w.width)
            guard ref > 0 else { continue }
            total += max(0, log2(ref / max(w.width, 1e-9)))
        }
        return total
    }

    /// The bands: looser than the reference 1, then one point per band of tightnessBands, more than the last 5.
    static func difficultyPoints(tightness t: Double) -> Int {
        for (i, bound) in tightnessBands.enumerated() where t <= bound { return i + 1 }
        return tightnessBands.count + 1
    }

    /// The stroke sits within edgeShare of the half-window from a failing edge. A window open on one side (the search
    /// found no failure there) has no real half-width, so the reference shot's half-width for that input stands in.
    private static func isNearEdge(_ w: Window, reference: [Window]) -> Bool {
        let half: Double
        if !w.lowOpen && !w.highOpen {
            half = w.width / 2
        } else {
            let ref = w.input == .elevation ? referenceElevationWidth
                : (reference.first { $0.input == w.input }?.width ?? w.width)
            half = min(ref, w.width) / 2
        }
        guard half > 0 else { return false }
        if !w.lowOpen && w.value - w.low < edgeShare * half { return true }
        if !w.highOpen && w.high - w.value < edgeShare * half { return true }
        return false
    }

    // MARK: Style (design 2.4)

    private static func stylePoints(_ f: Factors, techniques: Set<EightBallEscapeKind>, timeline: Timeline,
                                    call: EightBallCall, situation s: EightBallSituation,
                                    sweepShapes: [Bool]) -> [EightBallStylePoint] {
        var points: [EightBallStylePoint] = []
        if f.jumped || f.curved || f.railsBeforeContact >= 2 { points.append(.hardTechnique) }
        if techniques.count >= 2 { points.append(.stacked) }
        if let g = f.narrowestGap, g < threadGap { points.append(.threaded) }
        // Shape must come from the stroke, not a lucky bounce: most passing strokes of the sweep leave it too.
        if leavesShape(after: timeline, situation: s) {
            let share = sweepShapes.isEmpty ? 1
                : Double(sweepShapes.filter { $0 }.count) / Double(sweepShapes.count)
            if share >= shapeMajority { points.append(.shape) }
        }
        let rest = NextShot.layout(after: timeline)
        let groupLeft = s.group.balls.contains { NextShot.isOnTable(rest[$0]) }
        if call.ball == 8 || !groupLeft { points.append(.forTheGame) }
        return Array(points.prefix(EightBallVerdict.maxStyle))
    }

    /// Shape: the cue ball is still up and has a makeable shot on your next ball (or the 8 once your group is gone).
    /// "Makeable" stands in for the design's "its own window at least as wide as the reference shot's": a clear
    /// path from the cue ball to the ghost ball and from the ball to a pocket, a cut of at most shapeMaxCut, a side
    /// pocket entered within sidePocketMaxAngle of square, and distance times distance over the cut's cosine no
    /// more than the reference shot's (window width goes roughly as one over that product). No solve needed.
    private static func leavesShape(after tl: Timeline, situation s: EightBallSituation) -> Bool {
        guard tl.pocketTime[0] == nil, !tl.flewOffTable(0) else { return false }
        let rest = NextShot.layout(after: tl)
        guard NextShot.isOnTable(rest[8]) else { return false }   // the 8 is down: the game is over
        var targets = s.group.balls.filter { NextShot.isOnTable(rest[$0]) }
        if targets.isEmpty { targets = [8] }
        return targets.contains { makeable(ball: $0, in: rest) }
    }

    private static func makeable(ball b: Int, in rest: [Vec2]) -> Bool {
        let r = ballRadius
        let cue = rest[0], obj = rest[b]
        let others = (1..<rest.count).filter { $0 != b && NextShot.isOnTable(rest[$0]) }
        let maxCut = cos(shapeMaxCut * Double.pi / 180)
        let side = cos(sidePocketMaxAngle * Double.pi / 180)
        for (k, hole) in PoolParameters().pocketCenters.enumerated() {
            let toPocket = hole - obj
            let d2 = toPocket.length
            guard d2 > 1e-6 else { continue }
            let line = toPocket.normalized
            if k >= 4 && abs(line.y) < side { continue }
            let ghost = obj - line * (2 * r)
            let toGhost = ghost - cue
            let d1 = toGhost.length
            guard d1 > 1e-6 else { continue }
            let cut = toGhost.normalized.dot(line)
            guard cut >= maxCut, d1 * d2 / cut <= referenceLeg * referenceLeg else { continue }
            if clear(cue, ghost, past: others, in: rest) && clear(obj, hole, past: others, in: rest) { return true }
        }
        return false
    }

    /// No ball's centre within a ball's width of the segment from a to b. The test itself now lives in TableLines,
    /// shared with the spoken table and the aim actions.
    private static func clear(_ a: Vec2, _ b: Vec2, past balls: [Int], in rest: [Vec2]) -> Bool {
        TableLines.clear(from: a, to: b, past: balls, in: rest, radius: ballRadius)
    }

    // MARK: Safety (design 2.6)

    /// True when no straight line from the resting cue ball reaches one of the opponent's legal balls first (their
    /// group, or the 8 once their group is gone), tried every 360 / safetyDirections degrees.
    private static func opponentHooked(after tl: Timeline, situation s: EightBallSituation) -> Bool {
        let rest = NextShot.layout(after: tl)
        var targets = s.group.other.balls.filter { NextShot.isOnTable(rest[$0]) }
        if targets.isEmpty, NextShot.isOnTable(rest[8]) { targets = [8] }
        guard !targets.isEmpty else { return false }
        return !hasStraightLine(from: rest[0], to: Set(targets), in: rest)
    }

    private static func hasStraightLine(from cue: Vec2, to targets: Set<Int>, in rest: [Vec2]) -> Bool {
        let balls = (1..<rest.count).filter { NextShot.isOnTable(rest[$0]) }
        for i in 0..<safetyDirections {
            let a = Double(i) * 2 * Double.pi / Double(safetyDirections)
            let d = Vec2(cos(a), sin(a))
            // The first ball along this direction (shared ray scan in TableLines).
            if let n = TableLines.firstBall(from: cue, direction: d, among: balls, in: rest, radius: ballRadius),
               targets.contains(n.ball) { return true }
        }
        return false
    }

    // MARK: The card's sentence

    private static func sentence(_ v: EightBallVerdict, outcome o: Outcome, call: EightBallCall,
                                 legal: Set<Int>) -> String {
        if let loss = v.loss { return loss.title }
        if let foul = v.fouls.first { return String(localized: "Foul: \(foul.title).") }
        if v.madeAsCalled {
            if v.fluke { return String(localized: "It counts, but that kiss was luck.") }
            if v.nearEdge { return String(localized: "Made, but only just.") }
            return String(localized: "Made as called.")
        }
        switch call {
        case .safety:
            return v.safetyLeftHooked ? String(localized: "Good safety. They have no clear shot.")
                                      : String(localized: "Legal safety, but they can still see a ball.")
        case .ball(let b, _):
            if !legal.contains(b) { return String(localized: "Legal hit, but that ball isn't yours to call.") }
            if o.calledBallPocket != nil {
                return String(localized: "Your ball went in another pocket. 1 point for getting out.")
            }
            return String(localized: "Legal hit, but it didn't drop. 1 point for getting out.")
        }
    }

    // MARK: The Physics Lens lines

    /// Plain lines that explain a rating from the measured factors (design 2.3's list), for the Lens or the card.
    static func factorLines(_ a: Analysis) -> [String] {
        let f = a.factors
        var out: [String] = []
        switch f.railsBeforeContact {
        case 0: break
        case 1: out.append(String(localized: "1 rail before the hit."))
        default: out.append(String(localized: "\(f.railsBeforeContact) rails before the hit."))
        }
        switch f.calledBallRails {
        case 0: break
        case 1: out.append(String(localized: "Your ball took 1 rail."))
        default: out.append(String(localized: "Your ball took \(f.calledBallRails) rails."))
        }
        if let cut = f.cutAngle { out.append(String(localized: "Cut angle \(number(cut, 0))°.")) }
        out.append(String(localized: "Cue ball travelled \(number(f.cueTravel, 2)) m to the hit."))
        if let o = f.objectTravel { out.append(String(localized: "Your ball travelled \(number(o, 2)) m.")) }
        if let g = f.narrowestGap, g < 2 * ballRadius {
            out.append(String(localized: "Narrowest gap \(number(g * 1000, 0)) mm."))
        }
        if f.jumped {
            out.append(String(localized: "Jumped \(number(f.jumpHeight * 100, 1)) cm high, cue raised \(number(f.elevationDegrees, 0))°."))
            for b in f.blockersCleared { out.append(String(localized: "Cleared the \(b).")) }
        }
        if f.curved { out.append(String(localized: "Curved \(number(abs(f.curveDegrees), 0))°.")) }
        if let s = a.speedWindow {
            out.append(String(localized: "Speeds that work: \(number(s.lowerBound, 1)) to \(number(s.upperBound, 1)) m/s."))
        }
        if let t = a.tightness, t > 0.05 {
            out.append(String(localized: "About \(number(pow(2, t), 0)) times tighter than a plain straight-in shot."))
        }
        return out
    }

    // MARK: On a real table (design 4.1)

    /// One row of the "On a real table" card: what it is about, the plain words, and the real number beside them.
    struct RealTableLine: Identifiable, Equatable, Sendable {
        enum Kind: String, Sendable { case aim, cue, speed, spin, miss, cloth }
        let kind: Kind
        let label: String
        let words: String
        let number: String?
        var id: String { kind.rawValue }
    }

    /// The escape the card describes: the one the shot matched, else the one with the same call, else the top-rated.
    static func cardEscape(for verdict: EightBallVerdict?, in s: EightBallSituation) -> EightBallEscape? {
        if let id = verdict?.matchedEscape, let e = s.escapes.first(where: { $0.id == id }) { return e }
        if let c = verdict?.call, let e = s.escapes.first(where: { $0.call == c }) { return e }
        return s.escapes.max { $0.rating < $1.rating }
    }

    /// The card's rows for an escape. Pass `played` (the stroke the player struck) only when the shot matched this
    /// escape, so the numbers are the player's own; otherwise the escape's authored stroke is shown. `surface` is the
    /// cloth it was played on: its friction and cushion numbers get a row of their own unless it is plain cloth.
    static func realTableLines(for escape: EightBallEscape, played: TrickSettings? = nil,
                               surface: PlaySurface) -> [RealTableLine] {
        let card = escape.card
        let n = RealTableNumbers(settings: played ?? escape.settings, surface: surface)
        var rows: [RealTableLine] = []

        rows.append(RealTableLine(kind: .aim, label: String(localized: "Aim"), words: card.aim,
                                  number: String(localized: "\(number(n.aimDegrees, 1))° on the table")))

        let raised = n.elevationDegrees >= 0.5
        let angle = number(n.elevationDegrees, 0)
        let cueNumber: String
        switch (escape.usesBridge, raised) {
        case (true, true): cueNumber = String(localized: "On the bridge, raised \(angle)°")
        case (true, false): cueNumber = String(localized: "On the bridge, level")
        case (false, true): cueNumber = String(localized: "Raised \(angle)°")
        case (false, false): cueNumber = String(localized: "Level")
        }
        rows.append(RealTableLine(kind: .cue, label: String(localized: "Cue"), words: card.cue, number: cueNumber))

        let speedWords = card.speed.isEmpty ? feel(speed: n.speed) : card.speed
        rows.append(RealTableLine(kind: .speed, label: String(localized: "Speed"), words: speedWords,
                                  number: String(localized: "\(number(n.speed, 1)) m/s")))

        if let spin = spinWords(up: n.tipUp, side: n.tipSide) {
            rows.append(RealTableLine(kind: .spin, label: String(localized: "Tip"), words: spin,
                                      number: String(localized: "\(signed(n.tipUp * 1000)) mm up, \(signed(n.tipSide * 1000)) mm right")))
        }

        if !card.commonMiss.isEmpty {
            rows.append(RealTableLine(kind: .miss, label: String(localized: "What goes wrong"), words: card.commonMiss,
                                      number: nil))
        }

        if surface != .cloth {
            let base = PlaySurface.cloth.parameters
            let clothWords: String
            switch surface {
            case .tournament:
                clothWords = String(localized: "Slick cloth: draw and curves take late, and balls run long.")
            case .diveBar:
                clothWords = String(localized: "Sticky felt and dead rails: draw dies early and kicks come up short, so hit harder.")
            default:
                clothWords = surface.summary
            }
            let here = String(localized: "Sliding \(number(n.slidingFriction, 2)), rolling \(number(n.rollingResistance, 3)), cushions \(number(n.cushionRestitution, 2))")
            let usual = String(localized: "standard cloth \(number(base.slidingFriction, 2)), \(number(base.rollingResistance, 3)), \(number(base.cushionRestitution, 2))")
            rows.append(RealTableLine(kind: .cloth, label: surface.title, words: clothWords,
                                      number: String(localized: "\(here) (\(usual))")))
        }
        return rows
    }

    /// A felt comparison for a launch speed, for an escape whose card leaves its speed words empty.
    static func feel(speed: Double) -> String {
        switch speed {
        case ..<1.0: return String(localized: "A gentle roll.")
        case ..<2.0: return String(localized: "About a firm lag.")
        case ..<3.5: return String(localized: "A medium stroke.")
        case ..<5.0: return String(localized: "A firm hit.")
        case ..<6.5: return String(localized: "A hard hit.")
        default: return String(localized: "A break-speed hit.")
        }
    }

    /// Where to strike the cue ball, in whole sentences (no glued halves for the translators); nil through the middle.
    private static func spinWords(up: Double, side: Double) -> String? {
        let t = 0.002
        let high = up > t, low = up < -t, right = side > t, left = side < -t
        switch (high, low, right, left) {
        case (true, _, true, _): return String(localized: "Strike high and right: follow with right side.")
        case (true, _, _, true): return String(localized: "Strike high and left: follow with left side.")
        case (_, true, true, _): return String(localized: "Strike low and right: draw with right side.")
        case (_, true, _, true): return String(localized: "Strike low and left: draw with left side.")
        case (true, _, _, _): return String(localized: "Strike above centre for follow.")
        case (_, true, _, _): return String(localized: "Strike below centre for draw.")
        case (_, _, true, _): return String(localized: "Strike right of centre for right side.")
        case (_, _, _, true): return String(localized: "Strike left of centre for left side.")
        default: return nil
        }
    }

    private static func number(_ x: Double, _ digits: Int) -> String {
        x.formatted(.number.precision(.fractionLength(digits)))
    }

    private static func signed(_ x: Double) -> String {
        let text = number(x, 0)
        return x >= 0.5 ? "+" + text : text
    }

    // MARK: Memory (the reference windows per surface, the authored routes, the last few verdicts)

    private struct MemoKey: Hashable {
        let timeline: UInt64
        let surface: PlaySurface
        let situation: String
        let callBall: Int
        let callPocket: Int
        let aim, power, tipUp, tipSide, elevation: Double

        init(timeline: UInt64, surface: PlaySurface, situation: String, call: EightBallCall, settings s: TrickSettings) {
            self.timeline = timeline
            self.surface = surface
            self.situation = situation
            callBall = call.ball ?? -1
            callPocket = call.pocket?.rawValue ?? -1
            aim = s.aim; power = s.power; tipUp = s.tipUp; tipSide = s.tipSide; elevation = s.elevation ?? 0
        }
    }

    /// Shared, lock-guarded caches. The judge runs on a background task and its sweep solves on worker threads.
    private final class Memo: @unchecked Sendable {
        private let lock = NSLock()
        private var referenceBySurface: [PlaySurface: [Window]] = [:]
        private var routesBySituation: [String: [(id: String, route: Route)]] = [:]
        private var verdicts: [MemoKey: EightBallVerdict] = [:]
        private var verdictOrder: [MemoKey] = []
        private var analyses: [UInt64: Analysis] = [:]
        private var analysisOrder: [UInt64] = []
        private let keep = 8

        func reference(_ s: PlaySurface) -> [Window]? { lock.withLock { referenceBySurface[s] } }
        func storeReference(_ w: [Window], for s: PlaySurface) { lock.withLock { referenceBySurface[s] = w } }
        func routes(_ id: String) -> [(id: String, route: Route)]? { lock.withLock { routesBySituation[id] } }
        func storeRoutes(_ r: [(id: String, route: Route)], for id: String) { lock.withLock { routesBySituation[id] = r } }
        func verdict(_ k: MemoKey) -> EightBallVerdict? { lock.withLock { verdicts[k] } }
        func analysis(_ h: UInt64) -> Analysis? { lock.withLock { analyses[h] } }

        func store(_ v: EightBallVerdict, analysis a: Analysis, for k: MemoKey) {
            lock.withLock {
                if verdicts[k] == nil { verdictOrder.append(k) }
                verdicts[k] = v
                if verdictOrder.count > keep { verdicts[verdictOrder.removeFirst()] = nil }
                if analyses[k.timeline] == nil { analysisOrder.append(k.timeline) }
                analyses[k.timeline] = a
                if analysisOrder.count > keep { analyses[analysisOrder.removeFirst()] = nil }
            }
        }
    }

    private static let memo = Memo()

    /// Result slots for the parallel sweep, each written once under the lock.
    private final class Slots<T>: @unchecked Sendable {
        private var items: [T?]
        private let lock = NSLock()
        init(_ n: Int) { items = [T?](repeating: nil, count: n) }
        func set(_ i: Int, _ v: T) { lock.withLock { items[i] = v } }
        var values: [T?] { lock.withLock { items } }
    }
}

// MARK: - Self checks (run only by the -eightJudgeCheck launch flag; the project defines no DEBUG condition)

extension EightBallJudge {
    /// Focused checks of the judge on small hand-made tables, plus the scoring arithmetic of design 2.7. Returns one
    /// line per check ("PASS ..." or "FAIL ..."), and the time a full judgement of a made shot took. Not wired to
    /// anything; call it from a debug launch flag or the debugger.
    static func selfCheck() -> [String] {
        var out: [String] = []
        func check(_ name: String, _ ok: Bool, _ detail: String = "") {
            out.append((ok ? "PASS " : "FAIL ") + name + (detail.isEmpty ? "" : " (" + detail + ")"))
        }
        let r = ballRadius
        let ref = referenceSituation
        let cue = ref.situation.setup[0], spot = ref.situation.setup[1]
        func table(_ balls: [Int: Vec2], cue c: Vec2? = nil, group: EightBallGroup = .solids,
                   bridge: Bool = false) -> EightBallSituation {
            var setup = [Vec2](repeating: NextShot.offTable, count: 16)
            setup[0] = c ?? cue
            for (k, p) in balls { setup[k] = p }
            let escapes: [EightBallEscape] = bridge ? [EightBallEscape(
                id: "A", title: "bridge", kind: .bridge, alsoUses: [], rails: 0, settings: ref.settings,
                call: .ball(1, pocket: .footRight), usesBridge: true, rating: 1,
                card: RealTableCard(aim: "", cue: "", speed: "", commonMiss: "",
                                    numbers: RealTableNumbers(settings: ref.settings, surface: .cloth)))] : []
            return EightBallSituation(id: "check-\(balls.keys.sorted())-\(bridge)", number: 0, title: "check",
                                      story: "", setup: setup, group: group, surface: .cloth, escapes: escapes,
                                      lesson: "", taughtBy: [])
        }
        func run(_ s: EightBallSituation, _ call: EightBallCall, _ st: TrickSettings) -> EightBallVerdict {
            judge(timeline: solve(s.setup, st, on: .cloth), call: call, situation: s, settings: st, surface: .cloth,
                  attempt: 1)
        }
        let far: [Int: Vec2] = [2: Vec2(0.5, 0.25), 9: Vec2(0.45, 1.0), 10: Vec2(0.9, 1.1), 8: Vec2(0.25, 0.6)]
        let call1 = EightBallCall.ball(1, pocket: .footRight)

        // 1. A plain straight-in make (and the time a full judgement takes, sweep and all).
        var balls = far; balls[1] = spot
        let made = table(balls)
        let t0 = Date()
        let v1 = run(made, call1, ref.settings)
        let ms = Date().timeIntervalSince(t0) * 1000
        check("straight-in make", v1.madeAsCalled && v1.legal && (1...5).contains(v1.difficulty),
              "fouls \(v1.fouls.map(\.rawValue)) difficulty \(v1.difficulty) total \(v1.total)")
        out.append("TIME full judgement of a make: \(Int(ms)) ms")
        let refW = referenceWindows(on: .cloth)
        check("reference windows", refW.count == 3 && refW.allSatisfy { $0.width > 0 },
              refW.map { "\($0.input.rawValue) \($0.low)...\($0.high)" }.joined(separator: ", "))

        // 2. The same shot called in another pocket: a legal miss, 1 point.
        let v2 = run(made, .ball(1, pocket: .footLeft), ref.settings)
        check("wrong pocket called is a legal miss", !v2.madeAsCalled && v2.legal && v2.total == 1)

        // 3. An opponent ball on the spot: wrong ball first.
        var b3 = far; b3[9] = spot; b3[1] = Vec2(0.8, 0.2)
        let v3 = run(table(b3), call1, ref.settings)
        check("wrong ball first", v3.fouls.contains(.wrongBallFirst) && v3.total == 0)

        // 4. A soft stroke away from every ball: no ball hit.
        let v4 = run(made, call1, TrickSettings(aim: 90, power: 0.3, tipUp: 0, tipSide: 0))
        check("no ball hit", v4.fouls.contains(.noBallHit) && !v4.fouls.contains(.noRailAfterContact))

        // 5. The 8 on the spot while you still have balls: hitting it first and dropping it loses the game.
        var b5 = far; b5[8] = spot; b5[1] = Vec2(0.8, 0.2)
        let v5 = run(table(b5), call1, ref.settings)
        check("8 dropped early on a foul loses", v5.loss == .eightOnFoul && v5.total == 0,
              "loss \(v5.loss?.rawValue ?? "none")")

        // 6. On the 8, called and made: made as called, and it is for the game.
        let b6: [Int: Vec2] = [8: spot, 9: Vec2(0.45, 1.0), 10: Vec2(0.9, 1.1)]
        let v6 = run(table(b6), .ball(8, pocket: .footRight), ref.settings)
        check("8 made as called wins", v6.madeAsCalled && v6.loss == nil
              && (v6.nearEdge || v6.style.contains(.forTheGame)), "style \(v6.style.map(\.rawValue))")
        let v6b = run(table(b6), .ball(8, pocket: .footLeft), ref.settings)
        check("8 in an uncalled pocket loses", v6b.loss == .eightWrongPocket)

        // 7. Double hit: a full stun hit with the object ball half a centimetre away; frozen balls are exempt.
        let mid = Vec2(1.0, 0.635)
        let stun = TrickSettings(aim: 0, power: 1.0, tipUp: 0, tipSide: 0)
        let near = run(table([1: mid + Vec2(2 * r + 0.005, 0), 9: Vec2(0.3, 1.1), 8: Vec2(0.3, 0.2)], cue: mid),
                       .ball(1, pocket: .footRight), stun)
        check("double hit at close range", near.fouls.contains(.doubleHit), "fouls \(near.fouls.map(\.rawValue))")
        let frozen = run(table([1: mid + Vec2(2 * r + 0.0001, 0), 9: Vec2(0.3, 1.1), 8: Vec2(0.3, 0.2)], cue: mid),
                         .ball(1, pocket: .footRight), stun)
        check("frozen balls are not a double hit", !frozen.fouls.contains(.doubleHit))

        // 8. A ball right behind the cue ball under a level cue: the cue touches it.
        // The aim is down the diagonal toward the foot-right corner, so "behind" is back up it.
        let behind = Vec2(-1, 1).normalized
        var b8 = balls; b8[2] = cue + behind * 0.15
        let v8 = run(table(b8), call1, ref.settings)
        check("cue touches a ball behind", v8.fouls.contains(.cueOrBridgeTouchedBall))
        let raisedOver = run(table(b8), call1, TrickSettings(aim: -45, power: 1.0, tipUp: 0, tipSide: 0, elevation: 0.6))
        check("a raised cue clears it", !raisedOver.fouls.contains(.cueOrBridgeTouchedBall))
        // ...and a ball under the bridge head in a bridge situation.
        var b8b = balls; b8b[2] = cue + behind * bridgeSetback
        let v8b = run(table(b8b, bridge: true), call1, TrickSettings(aim: -45, power: 1.0, tipUp: 0, tipSide: 0,
                                                                      elevation: 0.6))
        check("bridge touches a ball", v8b.fouls.contains(.cueOrBridgeTouchedBall))

        // 9. Jumps: a shallow cue that hops the ball is a scoop; a properly raised one is legal.
        let clearTable = table([1: Vec2(2.3, 1.1), 9: Vec2(0.3, 1.1), 8: Vec2(0.3, 0.2)], cue: mid)
        let scoop = run(clearTable, .ball(1, pocket: .footLeft), TrickSettings(aim: 180, power: 8, tipUp: 0, tipSide: 0,
                                                                         elevation: 0.2))
        let scoopTl = solve(clearTable.setup, TrickSettings(aim: 180, power: 8, tipUp: 0, tipSide: 0, elevation: 0.2), on: .cloth)
        let rose = maxHeight(scoopTl, ball: 0, until: scoopTl.duration)
        check("shallow hop is a scoop", rose < jumpMinHeight || scoop.fouls.contains(.illegalJump),
              "rose \(rose) m, fouls \(scoop.fouls.map(\.rawValue))")
        let jump = run(clearTable, .ball(1, pocket: .footLeft), TrickSettings(aim: 180, power: 4, tipUp: 0, tipSide: 0,
                                                                        elevation: 0.5))
        check("raised jump is legal", !jump.fouls.contains(.illegalJump))

        // 10. Safety: a cue ball walled in by your own balls leaves them hooked; in the open it does not.
        var wall: [Int: Vec2] = [9: Vec2(2.3, 1.1), 8: Vec2(0.3, 0.2)]
        for k in 1...6 {
            let a = Double(k) * Double.pi / 3
            wall[k] = mid + Vec2(cos(a), sin(a)) * (2 * r + 0.001)
        }
        let walled = table(wall, cue: mid)
        let still = solve(walled.setup, TrickSettings(aim: 0, power: 0, tipUp: 0, tipSide: 0), on: .cloth)
        check("walled in is hooked", opponentHooked(after: still, situation: walled))
        let inOpen = table([1: Vec2(0.3, 1.1), 9: Vec2(2.3, 1.1), 8: Vec2(0.3, 0.2)], cue: mid)
        let still2 = solve(inOpen.setup, TrickSettings(aim: 0, power: 0, tipUp: 0, tipSide: 0), on: .cloth)
        check("in the open is not hooked", !opponentHooked(after: still2, situation: inOpen))

        // 11. The scoring arithmetic of design 2.7.
        var e1 = EightBallVerdict.neutral(call: call1, tryNumber: 1)
        e1.madeAsCalled = true; e1.difficulty = 3; e1.style = [.shape]
        check("kick rated 3 with shape scores 9", e1.total == 9 && e1.medal == .bronze)
        var e2 = EightBallVerdict.neutral(call: .ball(8, pocket: .footRight), tryNumber: 1)
        e2.madeAsCalled = true; e2.difficulty = 5; e2.style = [.hardTechnique, .threaded, .forTheGame]
        check("massé for the game scores 13, gold", e2.total == 13 && e2.medal == .gold)
        e2.tryNumber = 2
        check("the same on the second try scores 12, silver", e2.total == 12 && e2.medal == .silver)
        var e3 = EightBallVerdict.neutral(call: call1, tryNumber: 1)
        e3.loss = .eightWrongPocket
        check("8 in the wrong pocket scores 0", e3.total == 0 && e3.medal == nil)
        check("difficulty bands", difficultyPoints(tightness: 0) == 1 && difficultyPoints(tightness: 3) == 2
              && difficultyPoints(tightness: 8) == 3 && difficultyPoints(tightness: 12) == 4
              && difficultyPoints(tightness: 16) == 5)

        // 12. The real-table card: the four rows always, the cloth row off plain cloth.
        let esc = EightBallEscape(id: "A", title: "kick", kind: .kick, alsoUses: [], rails: 1, settings: ref.settings,
                                  call: call1, usesBridge: false, rating: 3,
                                  card: RealTableCard(aim: "aim", cue: "cue", speed: "", commonMiss: "miss",
                                                      numbers: RealTableNumbers(settings: ref.settings, surface: .cloth)))
        let plain = realTableLines(for: esc, surface: .cloth)
        let bar = realTableLines(for: esc, surface: .diveBar)
        check("real-table rows", plain.contains { $0.kind == .speed } && !plain.contains { $0.kind == .cloth }
              && bar.contains { $0.kind == .cloth })
        return out
    }

    /// Every authored escape of every situation played on its own cloth and judged: it should be made as called (or
    /// a legal safety) with no foul, matched to itself, rated near its authored rating. One line per escape.
    static func checkAuthoredEscapes() -> [String] {
        var out: [String] = []
        for s in EightBallSituations.all {
            for e in s.escapes {
                let tl = solve(s.setup, e.settings, on: s.surface)
                let t0 = Date()
                let v = judge(timeline: tl, call: e.call, situation: s, settings: e.settings, surface: s.surface,
                              attempt: 1)
                let ms = Int(Date().timeIntervalSince(t0) * 1000)
                let ok = v.legal && (e.call == .safety || v.madeAsCalled)
                let tight = analysis(for: tl)?.tightness.map { String(format: "%.1f", $0) } ?? "-"
                out.append((ok ? "PASS " : "FAIL ") + "\(s.id) \(e.id): fouls \(v.fouls.map(\.rawValue)) loss "
                           + "\(v.loss?.rawValue ?? "none") made \(v.madeAsCalled) matched \(v.matchedEscape ?? "none") "
                           + "difficulty \(v.difficulty) (authored \(e.rating), tightness \(tight)) "
                           + "style \(v.style.map(\.rawValue)) "
                           + "total \(v.total) near edge \(v.nearEdge) fluke \(v.fluke) judged in \(ms) ms")
            }
        }
        return out
    }
}

