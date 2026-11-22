// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 16 and 17. Each level now chooses its shot its own way,
//          not only with its own hand (OpponentStyle): easy always goes for the pot that looks easiest by eye, lined
//          up by the ghost-ball rule with no trial solves, never plays a deliberate safety and never plans the cue
//          ball; medium runs the full search but plays safe only when no pot gives its hand even a one-in-four chance;
//          hard keeps 0.6.6's search unchanged (safe below an even chance). Easy's wobble grew from 1.0 to 1.25 degrees
//          because dropping its safeties makes it stronger at the same wobble (reasoning at aimNoiseDegrees). A plain
//          hit when no pot is on is its own plan kind (.hit), not called a safety. At the table the computer starts
//          thinking as soon as its turn is known, while the ruling card before it is still up (MatchMode's
//          upcomingComputerDecision gives the table that card will leave), and it plays through the model's staged
//          stroke (stageComputerStroke: the aim swings to its choice, the cue draws back a beat, then it strikes)
//          instead of striking in the same frame.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 table-opponent stream, plans/22-Nov-2026-v074-glow-up-plan.md
//          feature R: the computer now plays bumper pool and five-pin too. OpponentPlanner.plan hands those two games
//          to BumperPoolPlanner and FivePinPlanner before anything pool-specific runs, so eight-ball and nine-ball
//          plan exactly as before. OpponentPlan.Kind gains .cup, .advance, .pins and .concede (with CupRoute) for
//          their "Why that shot"; OpponentSnapshot gains noiseSeed (the seed the stroke's real noise will be drawn
//          from, so the new search can test its candidates against other draws, never that one); OpponentNoise gains
//          a per-game scale (tableNoiseScale, every game at 1 for now); Slots is internal and parallel(_:_:) runs any
//          batch of solves across the cores; MatchOpponent keeps the handle of the task that runs the planner and
//          cancels it in cancel(), so an abandoned think stops at its next phase instead of running on.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 1 and 2. Ball in hand behind the head line: eight-ball now fouls a first hit on a ball that also
//          started behind the line unless the cue ball crossed it first, so every direct shot (straight pots, banks,
//          placements, safeties, easy's look and the plain full hit) leaves such balls out (directTargets); when every
//          legal ball is behind the line, the last-resort stroke is a kick off the foot cushion, which crosses the line
//          before the hit. And an abandoned think stops early: the pool search checks Task.isCancelled after its sweep
//          and before its ball-in-hand fallback and returns a cheap plan the token then discards (MatchOpponent.cancel
//          cancels the task, and leaving a match calls it).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens review: planFrom also checks Task.isCancelled
//          before its sweep, so a ball-in-hand think cancelled during its refine no longer runs the whole search when
//          it falls through to planFrom.)
// PURPOSE: The computer opponent for eight-ball and nine-ball (plans/21-Nov-2026-rules-games-plan.md package 5), and
//          since 0.7.4 the entry point for bumper pool and five-pin (BumperPoolPlanner, FivePinPlanner and their
//          shared search, TableOpponentSearch, each in its own file under App/Match).
//          Two halves:
//            OpponentPlanner (pure, runs on a background task): given the layout, the MatchState, the rules and the
//              solver's parameters, it picks a stroke the way a player would, by trying shots on the real solver.
//              1. Candidates: each ball the shooter may hit first (EightBallRules.legalBalls, NineBallRules.lowestBall)
//                 into each edge pocket straight (TableLines.potAim, the ghost-ball rule), plus one-cushion banks
//                 (the pocket mirrored across the cushion line, the object ball sent at the mirror image).
//              2. A coarse sweep per candidate: five aims a quarter degree apart (the aim nudge's own step) times three
//                 speeds, each solved with the event budget the judge uses (EightBallJudge.sweepEventBudget), read with
//                 ShotFacts and ruled by the match's own rules. A trial "keeps" when the rules let the shooter stay.
//              3. Score: the aim window (the unbroken run of aims that keep the table; the best few candidates get
//                 their edges measured by an outward search and bisection), weighted up when the cue ball finishes
//                 with a clear pot on a next legal ball, and strongly when the pot wins the game.
//              4. Safety: when no window is wide enough for the level's own aim to make it at least half the time,
//                 the legal stroke (no foul, no loss, turn passes) that leaves the other player the smallest
//                 estimated aim window is played instead; soft full and half-ball hits on each legal ball join the
//                 trials for this.
//              5. Ball in hand: the cue ball is placed behind the ghost ball of the easiest pots (checked with
//                 NextShot.placement, so the spot is legal), each placement's pot is swept, and the best is played.
//              6. The break (full rack): the break panel's own defaults. Choices: spot the 8 always (keeps the turn
//                 on an opened rack); take a bad break's table when a pot is there to make, else ask for a re-rack.
//            MatchOpponent (main actor): watches the match every frame (MatchMode.update), starts the planner on a
//              background task when it is the computer's turn and the balls are at rest (the table never freezes;
//              "Thinking..." shows meanwhile), drops a result if the turn, table or match changed, waits while the
//              menu is open, then plays it through the model like a player would: places the cue ball, makes the
//              call, and strikes with seeded noise on aim, speed and tip. The noise is drawn from a seed made of the
//              rack's seed, the match's shot count and the seat, all of which are saved, so a saved match replays the
//              same. Keeps the last stroke (OpponentShot) for the ruling card's "Why that shot".
//          The levels (BreakdownRules.ComputerLevel) differ in how they choose (OpponentStyle, see Edited above) and
//          in the noise added before the strike.
// SRP/DRY check: Pass - the ghost-ball geometry and the clear-path test are TableLines', legality is the rules'
//          (EightBallRules, NineBallRules, MatchRules.applying), the shot reading is ShotFacts, placement legality is
//          NextShot.placement, the event budget, the shape cut limit and the aim search limit are EightBallJudge's
//          named constants. The judge's own window search (searchSide/windows) is private to the puzzle mode and typed
//          on its situations and TrickSettings, so the window here is measured with this file's own outward search,
//          which needs a single input (aim) at a fixed speed. The words are OpponentWords'.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import Observation

// MARK: - Levels: seeded noise

/// How a level chooses its stroke (bug plan item 17).
enum OpponentStyle: Equatable, Sendable {
    /// Easy: the pot that looks easiest, by eye; no trial solves, no safety, no thought for the cue ball.
    case bestLookingPot
    /// Medium: the full search, but a safety only when no pot is reasonable for its hand (reasonableChanceWidth).
    case safeOnlyWhenNothingOn
    /// Hard: the full search as built in 0.6.6, a safety whenever no pot gives its hand an even chance.
    case fullSearch
}

extension ComputerLevel {
    var style: OpponentStyle {
        switch self {
        case .easy: return .bestLookingPot
        case .medium: return .safeOnlyWhenNothingOn
        case .hard: return .fullSearch
        }
    }

    /// One standard deviation of the aim error, degrees. Anchored on the shot panel's finest aim nudge, a quarter of a
    /// degree (ShowpieceModel.nudgeAim): hard is half a nudge, medium two nudges, easy five.
    ///
    /// Easy is tuned so it loses to a careful beginner. The chance of making a pot with aim error of standard
    /// deviation s is erf(h / (s * sqrt 2)), where h is the pot's half-window (windowEstimate). The pots an ordinary
    /// table offers run from about a metre each way (half-window about 0.2 degrees, the review's own figure) to a
    /// ball half a metre out with the cue ball close (about 0.55 degrees). A careful beginner lines up on the aim
    /// guide, so their error is mostly the stroke's drift, about medium's half a degree: they make about 31 percent
    /// of the long pot and 73 percent of the short one. At 1.0 degree easy made about 16 and 42 percent; now that it
    /// never gives up a turn on purpose (no safeties) that was close enough to the beginner's pace to win a fair share
    /// of racks. At 1.25 degrees it makes about 13 and 34 percent, under half the beginner's rate on every pot, so
    /// over a rack that needs eight pots and the 8 the beginner wins most games, while easy still drops a short
    /// straight pot one time in three and so never feels hopeless. Not yet checked by playing whole games.
    var aimNoiseDegrees: Double {
        switch self {
        case .easy: return 1.25
        case .medium: return 0.5
        case .hard: return 0.125
        }
    }

    /// One standard deviation of the speed error, as a share of the intended speed. Doubling per level like the aim:
    /// a practised stroke repeats its pace to a few percent, a casual one to about an eighth.
    var speedNoiseShare: Double {
        switch self {
        case .easy: return 0.12
        case .medium: return 0.06
        case .hard: return 0.03
        }
    }

    /// One standard deviation of the tip's miss of its intended contact point, metres. Doubling per level again; the
    /// easy level's 4 mm is about a seventh of the ball's radius, so its unintended side spin is visible but it does
    /// not miscue.
    var tipNoise: Double {
        switch self {
        case .easy: return 0.004
        case .medium: return 0.002
        case .hard: return 0.001
        }
    }
}

/// SplitMix64: a small, well-mixed generator whose whole state is one number. Each noise draw starts a fresh one from
/// its own seed, so the noise is a pure function of the seed (nothing advances across calls, nothing to save).
struct OpponentRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in (0, 1]: the top 53 bits plus one, over 2^53. Never zero, so the logarithm below stays finite.
    mutating func unit() -> Double { (Double(next() >> 11) + 1) / 9_007_199_254_740_992.0 }

    /// A standard normal draw (Box-Muller), clamped to three standard deviations so no single stroke is absurd.
    mutating func gaussian() -> Double {
        let g = (-2 * log(unit())).squareRoot() * cos(2 * Double.pi * unit())
        return min(max(g, -3), 3)
    }
}

/// What the computer's hand adds to one stroke: aim in degrees, speed as a share, tip offsets in metres.
struct OpponentNoise: Equatable, Sendable {
    var aimDegrees: Double
    var speedShare: Double
    var tipUp: Double
    var tipSide: Double

    static let none = OpponentNoise(aimDegrees: 0, speedShare: 0, tipUp: 0, tipSide: 0)

    /// The noise for one stroke at `level`, drawn from `seed` alone.
    static func draw(level: ComputerLevel, seed: UInt64) -> OpponentNoise {
        var r = OpponentRandom(seed: seed)
        let aim = r.gaussian() * level.aimNoiseDegrees
        let speed = r.gaussian() * level.speedNoiseShare
        let up = r.gaussian() * level.tipNoise
        let side = r.gaussian() * level.tipNoise
        return OpponentNoise(aimDegrees: aim, speedShare: speed, tipUp: up, tipSide: side)
    }

    /// How much shakier (above 1) or steadier (below 1) the computer's hand is on one game than the level says.
    /// The tuning knob for a table where a level proves too strong or too weak against a person-like hand, so the
    /// table itself never has to change. Every game is at 1 for now: no self-play run has asked for anything else
    /// (BreakdownTests/TableOpponentTests.testSelfPlay is the check). A game missing from the table is at 1.
    static let tableNoiseScale: [MatchKind: Double] = [:]

    /// The scale for one game (1 when the game is not listed).
    static func tableScale(_ kind: MatchKind) -> Double { tableNoiseScale[kind] ?? 1 }

    /// The noise for one stroke at `level` on game `kind`: draw(level:seed:) with every part scaled by the game's
    /// tableScale. At a scale of exactly 1 the numbers are identical to draw(level:seed:), so the pool games are
    /// unchanged by going through here.
    static func draw(level: ComputerLevel, seed: UInt64, kind: MatchKind) -> OpponentNoise {
        let n = draw(level: level, seed: seed)
        let k = tableScale(kind)
        return OpponentNoise(aimDegrees: n.aimDegrees * k, speedShare: n.speedShare * k, tipUp: n.tipUp * k,
                             tipSide: n.tipSide * k)
    }

    /// The seed of one stroke: the rack's seed (saved with the match), the match's shot count (saved) and the seat,
    /// mixed with two odd constants and one SplitMix step so neighbouring shots draw unrelated noise.
    static func seed(rackSeed: UInt64, shotCount: Int, seat: Int) -> UInt64 {
        let mixed = rackSeed
            ^ (UInt64(truncatingIfNeeded: shotCount) &* 0xD1B5_4A32_D192_ED03)
            ^ (UInt64(truncatingIfNeeded: seat) &* 0xABC9_8388_FB8F_AC03)
        var r = OpponentRandom(seed: mixed)
        return r.next()
    }
}

// MARK: - What the planner works with and returns

/// One stroke: the cue's direction (degrees counter-clockwise from the long axis, as ShowpieceModel.aimDegrees), the
/// launch speed (m/s) and the tip offsets (metres).
struct OpponentStroke: Equatable, Sendable {
    var aimDegrees: Double
    var speed: Double
    var tipUp: Double = 0
    var tipSide: Double = 0

    var direction: Vec2 {
        let a = aimDegrees * Double.pi / 180
        return Vec2(cos(a), sin(a))
    }

    /// The stroke as the computer's hand delivers it: the noise added, the speed kept in `speeds`, the tip kept
    /// within `tipLimit` of the middle of the ball.
    func with(_ n: OpponentNoise, speeds: ClosedRange<Double>, tipLimit: Double) -> OpponentStroke {
        var up = tipUp + n.tipUp, side = tipSide + n.tipSide
        let reach = (up * up + side * side).squareRoot()
        if reach > tipLimit, reach > 0 { up *= tipLimit / reach; side *= tipLimit / reach }
        return OpponentStroke(aimDegrees: aimDegrees + n.aimDegrees,
                              speed: min(max(speed * (1 + n.speedShare), speeds.lowerBound), speeds.upperBound),
                              tipUp: up, tipSide: side)
    }
}

/// A shot the computer might play: one legal ball into one pocket, straight or off one cushion.
struct OpponentCandidate: Equatable, Sendable {
    var ball: Int
    /// Solver pocket index, 0 to 5 (the same numbering as EightBallPocket's raw values).
    var pocket: Int
    /// The cushion banked off (0 head, 1 foot, 2 right, 3 left, as TableLines.Heading's rails); nil for straight in.
    var bankRail: Int?
    /// The ghost-ball aim, degrees.
    var aimDegrees: Double
    /// The estimated launch speed (launchSpeed), m/s.
    var speed: Double
    /// The aim window the geometry predicts, degrees (windowEstimate); used to rank candidates before solving.
    var estimate: Double
    /// Every leg of the path is free of other balls.
    var clear: Bool
}

/// The computer's decision for one stroke, before its hand's noise.
struct OpponentPlan: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case pot(ball: Int, pocket: Int, bankRail: Int?)
        /// A safety, played off `ball` (nil when the stroke touched nothing in the planner's trial).
        case safety(ball: Int?)
        /// No pot was on and no safety was chosen: a plain full hit on the nearest legal ball (nil when none).
        case hit(ball: Int?)
        case breakShot
        /// Bumper pool: the stroke, struck perfectly, drops `ball` (one of the computer's own) in its own cup.
        /// `marked` when that ball is the side's marked ball; `route` is how it got there (BumperPoolPlanner).
        case cup(ball: Int, marked: Bool, route: CupRoute)
        /// Bumper pool: no cup shot was likely enough, so the stroke rolls its balls nearer its cup; `ball` is the one
        /// it struck.
        case advance(ball: Int)
        /// Five-pin: the points the stroke is expected to make on an average stroke of the computer's hand
        /// (`expected`, the shooter's points less the other player's, averaged over the noise check), the points it
        /// makes for itself struck perfectly (`clean`, 0 when even that fouls), and whether its ball meets a cushion
        /// before the other ball (`kick`).
        case pins(expected: Double, clean: Int, kick: Bool)
        /// Five-pin: nothing scored often enough; the stroke that gives the least away.
        case concede
    }

    /// Bumper pool: how a cup shot reaches the cup, from the noise-free trial's cushion and bumper touches by the
    /// dropped ball before it dropped (TableTrial.railsBeforeDrop and postsBeforeDrop).
    enum CupRoute: Equatable, Sendable {
        case straight, cushion, bumper, cushionAndBumper

        init(rails: Int, posts: Int) {
            switch (rails > 0, posts > 0) {
            case (false, false): self = .straight
            case (true, false): self = .cushion
            case (false, true): self = .bumper
            case (true, true): self = .cushionAndBumper
            }
        }
    }

    var kind: Kind
    var stroke: OpponentStroke
    /// Where to put the cue ball first (ball in hand); nil to play it where it lies.
    var placement: Vec2?
    /// The call for a game with calls (eight-ball); nil otherwise.
    var call: EightBallCall?
    /// The measured aim window of the pot, degrees; nil for a safety and the break.
    var window: Double?
    /// Most of the strokes that made the pot also left the cue ball a clear pot on a next legal ball. On five-pin
    /// (.pins, hard only) it means the stroke, struck perfectly, leaves the computer's own ball clear of the castle,
    /// which its value asked for (FivePinPlanner.leaveWeight).
    var leavesNextShot = false
    /// A safety: the aim window the other player was estimated to be left, degrees (0: no clear pot at all).
    var leftOpponent: Double?
}

/// What the planner needs, all plain values, so it can run on a background task.
struct OpponentSnapshot: Sendable {
    var layout: [Vec2]
    var state: MatchState
    var rules: any MatchRules
    /// The solver's parameters exactly as the model solves a match shot (ShowpieceModel.matchSolveParameters).
    var parameters: PoolParameters
    var level: ComputerLevel
    /// True when the balls are still in the rack (the next stroke is the break).
    var racked: Bool
    /// The seed the stroke's real noise will be drawn from (OpponentNoise.seed of the rack, the shot count and the
    /// seat; MatchOpponent.update sets it). The bumper-pool and five-pin search draws its noise samples from seeds
    /// mixed out of this one (TableOpponentSearch.sampleSeeds) and never from this seed itself, so it cannot plan
    /// around the very wobble its hand is about to deal. Last, with a default, so every existing caller is unchanged.
    var noiseSeed: UInt64 = 0
}

/// What the background task hands back: a stroke to play, or the answer to a pending choice.
enum OpponentWork: Equatable, Sendable {
    case stroke(OpponentPlan)
    case answer(MatchChoiceAnswer)
}

/// One stroke the computer played, kept for the ruling card's "Why that shot".
struct OpponentShot: Equatable, Sendable {
    var seat: PlayerID
    var level: ComputerLevel
    var plan: OpponentPlan
    var noise: OpponentNoise
}

/// One solved try of a stroke, as the rules read it.
struct OpponentTrial: Equatable, Sendable {
    var stroke: OpponentStroke
    /// Legal, and the shooter stays at the table (or has won).
    var keeps = false
    var wins = false
    /// It kept the table and the cue ball stopped with a clear pot on a next legal ball.
    var nextClear = false
    /// Legal as a safety: no foul, no game over, and the turn passes.
    var safetyLegal = false
    /// The aim window the other player is estimated to be left, degrees (meaningful when safetyLegal).
    var leftOpponent = 0.0
    /// The first ball the cue ball touched; nil when it touched none (or the solve jammed).
    var firstBall: Int?
    /// The solve used up its event budget (a jam): counted as a miss.
    var jammed = false
}

// MARK: - The planner

enum OpponentPlanner {
    // MARK: Named numbers

    /// The sweep's aim step, degrees: the shot panel's own nudge (ShowpieceModel.nudgeAim moves a quarter degree), so
    /// the computer tries the aims a player can set.
    static let aimStep = 0.25
    /// Five aims, centred on the ghost-ball aim: two steps either side cover the cut-induced throw and the
    /// ghost-ball rule's error on ordinary cuts (both a fraction of a degree).
    static let aimOffsets: [Double] = [-2, -1, 0, 1, 2].map { $0 * aimStep }
    /// Speeds tried, as multiples of launchSpeed's estimate. The estimate leaves out the energy lost in the sliding
    /// phase and in the collision, so it is a floor; the sweep goes up from it.
    static let speedFactors: [Double] = [1.0, 1.4, 2.0]
    /// The object ball should still be rolling at this speed, m/s, when it reaches the pocket: a margin for the
    /// estimate, and slow enough that the newer pockets (which refuse fast balls) still take it.
    static let arrivalSpeed = 0.4
    /// Cuts thinner than this (80 degrees) are not tried: the object ball leaves with under a fifth of the cue
    /// ball's speed and the tiniest aim error turns the hit into a miss.
    static let maxCutSine = sin(80 * Double.pi / 180)
    /// How many candidates are swept: the easiest straight pots, then the easiest clear banks. Eight plus three keeps
    /// one think to about two hundred budgeted solves, a second or two on a phone across its cores.
    static let straightKeep = 8
    static let bankKeep = 3
    /// How many of the best swept candidates get their window edges measured precisely.
    static let refineKeep = 3
    /// A bank's contact with the cushion must be at least this far from every pocket centre, metres: closer, the
    /// ball meets a jaw rather than the flat cushion. Twice the corner pocket's capture radius covers the jaw.
    static func bankPocketClearance(_ p: PoolParameters) -> Double { 2 * p.cornerCaptureRadius }
    /// The z-score for an even chance: a window of width w centred on the aim makes a shot with Gaussian aim error
    /// of standard deviation s half the time when w / 2 = 0.6745 s, so w = 1.349 s.
    static let evenChanceWidth = 1.349
    /// Medium's "something reasonable is on": a window that its own aim makes one time in four. erf(x) = 0.25 at
    /// x = 0.2253, so w / 2 = 0.2253 * sqrt 2 * s = 0.3186 s and w = 0.637 s. Below that a club player stops going
    /// for it and plays safe; above it, they shoot.
    static let reasonableChanceWidth = 0.637
    /// Easy's pace: the middle of the sweep's speeds (speedFactors), a firm hit that covers the losses the estimate
    /// leaves out, without a search choosing the speed for it.
    static var easyPaceFactor: Double { speedFactors[1] }
    /// The window score's weights: a clear next shot adds up to half again (shape matters, but making the ball
    /// matters more), a game-winning pot counts three times (nothing after it matters).
    static let nextShotWeight = 0.5
    static let winningWeight = 3.0
    /// Ball in hand: the cue ball is tried this far behind the ghost ball, metres (close enough for a wide window,
    /// far enough for a normal bridge), straight on and this many degrees off the line (so the cue ball goes
    /// somewhere after the hit instead of stopping on the object ball's old line).
    static let placementDistances = [0.25, 0.45]
    static let placementAngles = [0.0, 20.0, -20.0]
    static let placementKeep = 4
    /// The break: the break panel's own starting settings (ShowpieceModel.power and tipHeight), straight at the apex.
    static let breakSpeed = 11.0
    static let breakTipUp = -0.006
    /// Every pot is struck with the judge's reference touch of draw (EightBallJudge.referenceTipUp, 7 mm below
    /// centre), so the cue ball does not follow the object ball into the pocket on a straight shot.
    static let potTipUp = EightBallJudge.referenceTipUp

    /// A pot stroke at this aim and speed.
    static func potStroke(_ aim: Double, _ speed: Double) -> OpponentStroke {
        OpponentStroke(aimDegrees: aim, speed: speed, tipUp: potTipUp)
    }

    // MARK: Entry points

    /// The stroke to play now, the level's own way (OpponentStyle).
    static func plan(_ s: OpponentSnapshot) -> OpponentPlan {
        // Bumper pool and five-pin have their own planners, chosen by the rules value (never by TableKind, whose
        // props side belongs to the main actor). This comes first: their fresh state says isBreak, but neither game
        // has a pool break, and nothing below is meant for them.
        if s.rules is BumperPoolRules { return BumperPoolPlanner.plan(s) }
        if s.rules is FivePinRules { return FivePinPlanner.plan(s) }
        if s.state.isBreak && s.racked {
            return OpponentPlan(kind: .breakShot, stroke: OpponentStroke(aimDegrees: 0, speed: breakSpeed,
                                                                          tipUp: breakTipUp))
        }
        if s.level.style == .bestLookingPot {
            // Ball in hand: the cue ball goes behind the easiest-looking pot (the geometry's best placement), as a
            // beginner would put it, and that pot is shot.
            let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
            if s.state.ballInHand != .none, let first = placements(s).first, s.layout.indices.contains(cueBall) {
                var l = s.layout
                l[cueBall] = first.spot
                // easyPlan looks at the table afresh from there, so it may shoot another ball than the one the spot
                // was chosen for if that one now looks easier: still a pot picked by eye, which is easy's way.
                return easyPlan(s, layout: l, placement: first.spot)
            }
            return easyPlan(s, layout: s.layout, placement: nil)
        }
        if s.state.ballInHand != .none, let placed = planWithPlacement(s) { return placed }
        return planFrom(s, layout: s.layout, placement: nil)
    }

    /// The answer to the pending choice: spot the 8 (the turn stays on an opened rack); take a bad break's table when
    /// there is a pot to make (always with ball in hand), otherwise ask for it racked again.
    static func answer(_ s: OpponentSnapshot) -> MatchChoiceAnswer {
        guard let pending = s.state.pendingChoice else { return .acceptTable }
        switch pending.choice {
        case .spotEightOrRerack:
            return .spotEight
        case .acceptTableOrRerack:
            if s.state.ballInHand != .none { return .acceptTable }
            // Easy takes the table whenever it sees a pot to go for (it judges by eye, as it shoots); the others when
            // their search finds a pot at least as wide as their own shooting threshold.
            if s.level.style == .bestLookingPot {
                if case .pot = easyPlan(s, layout: s.layout, placement: nil).kind { return .acceptTable }
                return .rerack
            }
            let p = planFrom(s, layout: s.layout, placement: nil)
            if case .pot = p.kind, (p.window ?? 0) >= threshold(s.level) { return .acceptTable }
            return .rerack
        }
    }

    /// The narrowest measured window this level shoots at rather than playing safe: hard, the width its aim makes
    /// half the time (evenChanceWidth); medium, one time in four (reasonableChanceWidth); easy, any pot at all (it
    /// never plays a deliberate safety, so its threshold is zero).
    static func threshold(_ level: ComputerLevel) -> Double {
        switch level.style {
        case .bestLookingPot: return 0
        case .safeOnlyWhenNothingOn: return reasonableChanceWidth * level.aimNoiseDegrees
        case .fullSearch: return evenChanceWidth * level.aimNoiseDegrees
        }
    }

    // MARK: Legal balls

    /// The balls the shooter may hit first: the eight-ball rules' legal set, or nine-ball's lowest ball.
    static func legalTargets(rules: any MatchRules, state: MatchState) -> [Int] {
        if let eight = rules as? EightBallRules { return eight.legalBalls(in: state).sorted() }
        if let nine = rules as? NineBallRules { return nine.lowestBall(in: state).map { [$0] } ?? [] }
        return []
    }

    /// The legal balls the cue ball may hit first straight from where it will be played. With ball in hand behind the
    /// head line, a ball that also starts behind the line (on the line counts as behind, NextShot.headLineX) may only be
    /// hit first after the cue ball has crossed the line (EightBallRules.hitBehindHeadLine), which no direct shot
    /// here does, so those balls are left out of the pots, banks, placements, safeties and easy's look; the fallback
    /// still reaches them with a kick off the foot cushion when nothing else is left. Any other ball in hand, or none,
    /// leaves `targets` as they are.
    static func directTargets(_ s: OpponentSnapshot, _ targets: [Int], layout: [Vec2]) -> [Int] {
        guard s.state.ballInHand == .behindHeadLine else { return targets }
        let line = NextShot.headLineX(parameters: s.parameters)
        return targets.filter { t in
            !(layout.indices.contains(t) && NextShot.isOnTable(layout[t]) && layout[t].x <= line)
        }
    }

    // MARK: Geometry

    /// The aim window a pot gives, degrees, from the geometry alone. An aim error d turns the cue ball's path, which
    /// moves the contact point sideways by d1 * d; the object ball's path turns by that over 2R / cos(cut); it still
    /// drops while that turn keeps it within the pocket's capture radius over d2. So the half-window is
    /// capture * 2R * cos(cut) / (d1 * d2), the "one over d1 * d2 / cos" rule the judge's shape test leans on.
    /// Capped at the judge's whole aim search (twice EightBallJudge.aimLimit).
    static func windowEstimate(cueTravel d1: Double, objectTravel d2: Double, cosCut: Double, capture: Double,
                               radius r: Double) -> Double {
        let cap = 2 * EightBallJudge.aimLimit
        guard d1 > 1e-6, d2 > 1e-6 else { return cap }
        let half = capture * 2 * r * max(cosCut, 0) / (d1 * d2)
        return min(2 * half * 180 / Double.pi, cap)
    }

    /// The launch speed for a pot, m/s, from the cloth's rolling resistance: the object ball must leave fast enough
    /// to roll its path (through a cushion, which keeps `restitution` of its speed, for a bank) and still be moving at
    /// arrivalSpeed; the cue ball must reach the contact with that speed over cos(cut); a centre-struck ball slides
    /// first and rolls on at five sevenths of its launch speed, so the launch is seven fifths of the rolling speed.
    static func launchSpeed(cueTravel d1: Double, before d2a: Double, after d2b: Double, restitution e: Double?,
                            cosCut: Double, parameters p: PoolParameters) -> Double {
        let decel2 = 2 * p.rollingResistance * p.gravity
        var object = (arrivalSpeed * arrivalSpeed + decel2 * d2b).squareRoot()
        if let e, e > 0 { object = ((object / e) * (object / e) + decel2 * d2a).squareRoot() }
        let atContact = object / max(cosCut, 0.2)
        let rolling = (atContact * atContact + decel2 * d1).squareRoot()
        return rolling * 7 / 5
    }

    /// The launch speed that rolls a ball `distance` metres from a standstill on this cloth (seven fifths of the
    /// rolling speed that covers it). Used for the safety strokes.
    static func rollingLaunch(distance: Double, parameters p: PoolParameters) -> Double {
        (2 * p.rollingResistance * p.gravity * distance).squareRoot() * 7 / 5
    }

    private static func onTable(_ layout: [Vec2], except skip: [Int]) -> [Int] {
        layout.indices.filter { !skip.contains($0) && NextShot.isOnTable(layout[$0]) }
    }

    private static func degrees(_ v: Vec2) -> Double { atan2(v.y, v.x) * 180 / Double.pi }

    private static func rotated(_ v: Vec2, degrees a: Double) -> Vec2 {
        let r = a * Double.pi / 180
        return Vec2(v.x * cos(r) - v.y * sin(r), v.x * sin(r) + v.y * cos(r))
    }

    // MARK: Candidates

    /// Every straight pot and one-cushion bank of the `targets` balls into the edge pockets, easiest first (clear
    /// paths before blocked ones, then by the window estimate). Pots thinner than maxCutSine are left out.
    static func candidates(layout: [Vec2], cueBall: Int, targets: [Int], parameters p: PoolParameters)
        -> [OpponentCandidate] {
        let spec = p.tableSpec
        guard layout.indices.contains(cueBall), NextShot.isOnTable(layout[cueBall]) else { return [] }
        let cue = layout[cueBall]
        let r = p.ballRadius
        let pockets = min(TableSpec.edgePocketCount, spec.pockets.count)
        let minCos = (1 - maxCutSine * maxCutSine).squareRoot()
        var out: [OpponentCandidate] = []
        for t in targets where layout.indices.contains(t) && NextShot.isOnTable(layout[t]) {
            let obj = layout[t]
            let others = onTable(layout, except: [t, cueBall])
            for k in 0..<pockets {
                let hole = spec.pockets[k]
                let capture = k < spec.pocketCaptureRadius.count ? spec.pocketCaptureRadius[k] : r
                // Straight in: the ghost-ball aim.
                if let a = TableLines.potAim(ball: t, pocket: k, cueBall: cueBall, in: layout, table: spec),
                   a.cutSine <= maxCutSine {
                    let d1 = (a.ghost - cue).length, d2 = (hole - obj).length
                    let cosCut = (1 - a.cutSine * a.cutSine).squareRoot()
                    out.append(OpponentCandidate(
                        ball: t, pocket: k, bankRail: nil, aimDegrees: degrees(a.ghost - cue),
                        speed: launchSpeed(cueTravel: d1, before: 0, after: d2, restitution: nil, cosCut: cosCut,
                                           parameters: p),
                        estimate: windowEstimate(cueTravel: d1, objectTravel: d2, cosCut: cosCut, capture: capture,
                                                 radius: r),
                        clear: a.clear))
                }
                // One cushion: mirror the pocket across the cushion line the ball's centre touches (a radius in from
                // each cushion nose), and send the object ball at the mirror image.
                let rails: [(alongX: Bool, line: Double)] = [(true, r), (true, spec.length - r), (false, r),
                                                            (false, spec.width - r)]
                for (railIndex, rail) in rails.enumerated() {
                    let holeCoord = rail.alongX ? hole.x : hole.y
                    // A pocket in this very cushion has no bank off it.
                    if abs(holeCoord - rail.line) < 3 * r { continue }
                    let image = rail.alongX ? Vec2(2 * rail.line - hole.x, hole.y) : Vec2(hole.x, 2 * rail.line - hole.y)
                    let toImage = image - obj
                    let across = rail.alongX ? toImage.x : toImage.y
                    guard abs(across) > 1e-6 else { continue }
                    // Where along the unfolded path the ball meets the cushion line.
                    let s = ((rail.alongX ? rail.line - obj.x : rail.line - obj.y)) / across
                    guard s > 0, s < 1 else { continue }
                    let bounce = obj + toImage * s
                    guard spec.pockets.allSatisfy({ ($0 - bounce).length > bankPocketClearance(p) }) else { continue }
                    let line = toImage.normalized
                    let ghost = obj - line * (2 * r)
                    let toGhost = ghost - cue
                    guard toGhost.length > 1e-6 else { continue }
                    let cosCut = toGhost.normalized.dot(line)
                    guard cosCut >= minCos else { continue }
                    let free = TableLines.clear(from: cue, to: ghost, past: others, in: layout, radius: r)
                        && TableLines.clear(from: obj, to: bounce, past: others, in: layout, radius: r)
                        && TableLines.clear(from: bounce, to: hole, past: others, in: layout, radius: r)
                    let d2 = toImage.length
                    out.append(OpponentCandidate(
                        ball: t, pocket: k, bankRail: railIndex, aimDegrees: degrees(toGhost),
                        speed: launchSpeed(cueTravel: toGhost.length, before: d2 * s, after: d2 * (1 - s),
                                           restitution: p.cushionRestitution, cosCut: cosCut, parameters: p),
                        estimate: windowEstimate(cueTravel: toGhost.length, objectTravel: d2, cosCut: cosCut,
                                                 capture: capture, radius: r),
                        clear: free))
                }
            }
        }
        // Clear first, then the widest predicted window; the ball and pocket numbers break ties so the order (and so
        // every plan) is the same on every run.
        return out.sorted { a, b in
            if a.clear != b.clear { return a.clear }
            if a.estimate != b.estimate { return a.estimate > b.estimate }
            if a.ball != b.ball { return a.ball < b.ball }
            if a.pocket != b.pocket { return a.pocket < b.pocket }
            return (a.bankRail ?? -1) < (b.bankRail ?? -1)
        }
    }

    /// The candidates worth solving: the easiest clear straight pots (or, when none is clear, the easiest few of
    /// any), then the easiest clear banks.
    static func shortlist(_ all: [OpponentCandidate]) -> [OpponentCandidate] {
        let straight = all.filter { $0.bankRail == nil }
        var picked = Array(straight.filter(\.clear).prefix(straightKeep))
        if picked.isEmpty { picked = Array(straight.prefix(straightKeep / 2)) }
        picked += all.filter { $0.bankRail != nil && $0.clear }.prefix(bankKeep)
        return picked
    }

    // MARK: Trials

    private struct Job: Sendable {
        var layout: [Vec2]
        var stroke: OpponentStroke
        var call: EightBallCall?
    }

    /// Solve one stroke within the judge's event budget and read it as the rules would.
    static func trial(_ s: OpponentSnapshot, layout: [Vec2], stroke: OpponentStroke, call: EightBallCall?)
        -> OpponentTrial {
        var t = OpponentTrial(stroke: stroke)
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        let input = NextShot.shot(from: layout, direction: stroke.direction, speed: stroke.speed, tipUp: stroke.tipUp,
                                  tipSide: stroke.tipSide, seed: 1, parameters: s.parameters, ballIndex: cueBall)
        guard let tl = PoolSolver.simulate(input, eventBudget: EightBallJudge.sweepEventBudget) else {
            t.jammed = true
            return t
        }
        let facts = ShotFacts(timeline: tl, start: layout, cueBall: cueBall)
        let shooter = s.state.turn
        t.firstBall = facts.firstContact?.ball
        let ruling = s.rules.ruling(for: facts, call: s.rules.usesCalls ? call : nil, in: s.state)
        t.wins = ruling.result?.winner == shooter
        t.keeps = !ruling.fouled && (t.wins || (ruling.result == nil && !ruling.turnPasses))
        if t.keeps, !t.wins {
            let after = s.rules.applying(ruling, facts: facts, to: s.state)
            t.nextClear = hasClearPot(rest: facts.resting, cueBall: cueBall,
                                      targets: legalTargets(rules: s.rules, state: after), parameters: s.parameters)
        }
        // The same recording read as a declared safety (eight-ball calls it; nine-ball has no calls).
        let safe = s.rules.usesCalls ? s.rules.ruling(for: facts, call: .safety, in: s.state) : ruling
        if !safe.fouled, safe.result == nil, safe.turnPasses {
            t.safetyLegal = true
            let after = s.rules.applying(safe, facts: facts, to: s.state)
            let theirBall = s.rules.cueBall(for: after.turn, in: after)
            t.leftOpponent = bestWindow(rest: facts.resting, cueBall: theirBall,
                                        targets: legalTargets(rules: s.rules, state: after), parameters: s.parameters)
        }
        return t
    }

    /// Solve many strokes at once across the cores (the solver is a pure function, so the order cannot change any
    /// answer); results come back in the jobs' order.
    private static func run(_ s: OpponentSnapshot, _ jobs: [Job]) -> [OpponentTrial] {
        guard !jobs.isEmpty else { return [] }
        let slots = Slots<OpponentTrial>(jobs.count)
        DispatchQueue.concurrentPerform(iterations: jobs.count) { i in
            slots.set(i, trial(s, layout: jobs[i].layout, stroke: jobs[i].stroke, call: jobs[i].call))
        }
        return slots.values.enumerated().map { $0.element ?? OpponentTrial(stroke: jobs[$0.offset].stroke) }
    }

    /// True when the cue ball is up and has a clear pot, cut no thinner than the judge's shape limit
    /// (EightBallJudge.shapeMaxCut), on one of `targets`.
    static func hasClearPot(rest: [Vec2], cueBall: Int, targets: [Int], parameters p: PoolParameters) -> Bool {
        guard rest.indices.contains(cueBall), NextShot.isOnTable(rest[cueBall]) else { return false }
        let maxSine = sin(EightBallJudge.shapeMaxCut * Double.pi / 180)
        let spec = p.tableSpec
        for t in targets {
            for k in 0..<min(TableSpec.edgePocketCount, spec.pockets.count) {
                if let a = TableLines.potAim(ball: t, pocket: k, cueBall: cueBall, in: rest, table: spec),
                   a.clear, a.cutSine <= maxSine { return true }
            }
        }
        return false
    }

    /// The widest aim window (windowEstimate) any clear straight pot on `targets` gives from where the cue ball
    /// rests; 0 when there is none (the player is hooked or has no clear pot). A cue ball that is off the table
    /// counts as the widest possible (whoever plays next has it in hand).
    static func bestWindow(rest: [Vec2], cueBall: Int, targets: [Int], parameters p: PoolParameters) -> Double {
        guard rest.indices.contains(cueBall), NextShot.isOnTable(rest[cueBall]) else {
            return 2 * EightBallJudge.aimLimit
        }
        let spec = p.tableSpec
        var best = 0.0
        for t in targets {
            for k in 0..<min(TableSpec.edgePocketCount, spec.pockets.count) {
                guard let a = TableLines.potAim(ball: t, pocket: k, cueBall: cueBall, in: rest, table: spec),
                      a.clear else { continue }
                let capture = k < spec.pocketCaptureRadius.count ? spec.pocketCaptureRadius[k] : p.ballRadius
                let w = windowEstimate(cueTravel: (a.ghost - rest[cueBall]).length,
                                       objectTravel: (spec.pockets[k] - rest[t]).length,
                                       cosCut: (1 - a.cutSine * a.cutSine).squareRoot(), capture: capture,
                                       radius: p.ballRadius)
                best = max(best, w)
            }
        }
        return best
    }

    // MARK: Sweeping and scoring

    /// A candidate after its sweep.
    struct Assessment: Equatable, Sendable {
        var candidate: OpponentCandidate
        var speed: Double
        /// The aims that bound the window (degrees, absolute); from the sweep, then from the measured edges.
        var low: Double
        var high: Double
        var nextShare: Double
        var wins: Bool
        var window: Double { high - low }
        var aim: Double { (low + high) / 2 }
        var score: Double {
            window * (1 + OpponentPlanner.nextShotWeight * nextShare) * (wins ? OpponentPlanner.winningWeight : 1)
        }
    }

    /// The speeds a candidate is swept at.
    static func speeds(for c: OpponentCandidate) -> [Double] {
        speedFactors.map { min(max(c.speed * $0, PlayerShotSpeed.ordinary.lowerBound), PlayerShotSpeed.ordinary.upperBound) }
    }

    /// Read a candidate's sweep (speeds outer, aims inner, as the jobs were made). The best speed is the one with
    /// the longest unbroken run of aims that keep the table; a tie goes to the run through the ghost-ball aim, then to
    /// the slower speed. Each aim in the run stands for one step's slice, so a run of n aims is n steps wide. Nil when
    /// no trial kept the table.
    static func assess(_ c: OpponentCandidate, trials: [OpponentTrial]) -> Assessment? {
        let sp = speeds(for: c)
        let n = aimOffsets.count
        guard trials.count == sp.count * n else { return nil }
        var best: (speed: Int, from: Int, to: Int, centred: Bool)?
        for si in 0..<sp.count {
            var i = 0
            while i < n {
                guard trials[si * n + i].keeps else { i += 1; continue }
                var j = i
                while j + 1 < n && trials[si * n + j + 1].keeps { j += 1 }
                let centred = i <= n / 2 && n / 2 <= j
                if let b = best {
                    let longer = j - i > b.to - b.from
                    let sameButCentred = j - i == b.to - b.from && centred && !b.centred
                    if longer || sameButCentred { best = (si, i, j, centred) }
                } else {
                    best = (si, i, j, centred)
                }
                i = j + 1
            }
        }
        guard let b = best else { return nil }
        let run = (b.from...b.to).map { trials[b.speed * n + $0] }
        let next = Double(run.filter(\.nextClear).count) / Double(run.count)
        return Assessment(candidate: c, speed: sp[b.speed],
                          low: c.aimDegrees + aimOffsets[b.from] - aimStep / 2,
                          high: c.aimDegrees + aimOffsets[b.to] + aimStep / 2,
                          nextShare: next, wins: run.contains(where: \.wins))
    }

    /// Measure one assessment's window edges precisely: from the middle of its run, outward in steps that start at a
    /// fifth of the sweep step and double until a stroke fails or the judge's aim limit is reached, then three
    /// bisections between the last pass and the first fail (the judge's own search shape, for one input).
    private static func refine(_ a: Assessment, _ s: OpponentSnapshot, layout: [Vec2], call: EightBallCall?)
        -> Assessment {
        let centre = a.aim
        let slots = Slots<Double>(2)
        DispatchQueue.concurrentPerform(iterations: 2) { side in
            let dir = side == 0 ? -1.0 : 1.0
            func keeps(_ off: Double) -> Bool {
                trial(s, layout: layout, stroke: potStroke(centre + dir * off, a.speed), call: call).keeps
            }
            var lastPass = 0.0
            var fail: Double?
            var step = aimStep / 5
            while step <= EightBallJudge.aimLimit {
                if keeps(step) { lastPass = step; step *= 2 } else { fail = step; break }
            }
            guard var f = fail else { slots.set(side, lastPass); return }
            for _ in 0..<3 {
                let mid = (lastPass + f) / 2
                if keeps(mid) { lastPass = mid } else { f = mid }
            }
            slots.set(side, (lastPass + f) / 2)
        }
        let v = slots.values
        var out = a
        out.low = centre - (v[0] ?? 0)
        out.high = centre + (v[1] ?? 0)
        return out
    }

    /// The call a pot needs in a game with calls (eight-ball): its ball in its pocket.
    private static func call(for c: OpponentCandidate, rules: any MatchRules) -> EightBallCall? {
        guard rules.usesCalls, let pocket = EightBallPocket(rawValue: c.pocket) else { return nil }
        return .ball(c.ball, pocket: pocket)
    }

    private static func potPlan(_ a: Assessment, rules: any MatchRules, placement: Vec2?) -> OpponentPlan {
        let c = a.candidate
        return OpponentPlan(kind: .pot(ball: c.ball, pocket: c.pocket, bankRail: c.bankRail),
                            stroke: potStroke(a.aim, a.speed), placement: placement,
                            call: call(for: c, rules: rules), window: a.window, leavesNextShot: a.nextShare >= 0.5)
    }

    // MARK: Safety

    /// Soft strokes for a safety on each legal ball the cue ball can see: a full hit and a half-ball hit either side
    /// (aimed a radius off the ball's centre, a 30 degree cut), each at the speed that rolls one and two table widths,
    /// enough to reach a cushion from most of the bed without leaving the table wide open.
    private static func safetyJobs(_ s: OpponentSnapshot, layout: [Vec2], cueBall: Int, targets: [Int]) -> [Job] {
        guard layout.indices.contains(cueBall), NextShot.isOnTable(layout[cueBall]) else { return [] }
        let p = s.parameters, r = p.ballRadius, cue = layout[cueBall]
        let soft = [rollingLaunch(distance: p.tableWidth, parameters: p),
                    rollingLaunch(distance: 2 * p.tableWidth, parameters: p)]
        let call: EightBallCall? = s.rules.usesCalls ? .safety : nil
        var jobs: [Job] = []
        for t in targets where layout.indices.contains(t) && NextShot.isOnTable(layout[t]) {
            let obj = layout[t]
            guard TableLines.clear(from: cue, to: obj, past: onTable(layout, except: [t, cueBall]), in: layout,
                                   radius: r) else { continue }
            let d = (obj - cue).normalized
            let across = Vec2(-d.y, d.x)
            for side in [-1.0, 0, 1] {
                let aim = degrees(obj + across * (side * r) - cue)
                for v in soft { jobs.append(Job(layout: layout, stroke: OpponentStroke(aimDegrees: aim, speed: v), call: call)) }
            }
        }
        return jobs
    }

    /// The legal safety that leaves the other player the smallest window; the first such trial wins a tie, so the
    /// choice is the same on every run. Nil when no trial was a legal safety.
    static func pickSafety(_ trials: [OpponentTrial]) -> OpponentTrial? {
        var best: OpponentTrial?
        for t in trials where t.safetyLegal && !t.jammed {
            if best == nil || t.leftOpponent < best!.leftOpponent { best = t }
        }
        return best
    }

    // MARK: Planning from a layout

    /// The full search from one layout: sweep the shortlist and the safeties together, measure the best windows,
    /// then pot when the best window is wide enough for this level, otherwise play safe.
    static func planFrom(_ s: OpponentSnapshot, layout: [Vec2], placement: Vec2?) -> OpponentPlan {
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        let targets = legalTargets(rules: s.rules, state: s.state)
        // Already abandoned before the sweep starts: no sweep at all. This is the path a ball-in-hand think takes when
        // it is cancelled after its own sweep check (during its refine): planWithPlacement then falls through to here,
        // and without this check the whole search would run before the next check.
        if Task.isCancelled {
            return fallback(s, layout: layout, cueBall: cueBall, targets: targets, placement: placement)
        }
        // Only balls the cue ball may hit first straight from here (all of them, unless the ball in hand is behind
        // the head line); the fallback below keeps the whole legal list for its kick.
        let direct = directTargets(s, targets, layout: layout)
        let picked = shortlist(candidates(layout: layout, cueBall: cueBall, targets: direct, parameters: s.parameters))
        var jobs: [Job] = []
        for c in picked {
            let callC = call(for: c, rules: s.rules)
            for v in speeds(for: c) {
                for off in aimOffsets {
                    jobs.append(Job(layout: layout, stroke: potStroke(c.aimDegrees + off, v), call: callC))
                }
            }
        }
        // The safety strokes go after every candidate's sweep, so candidate i's trials are slice i of the first part.
        jobs += safetyJobs(s, layout: layout, cueBall: cueBall, targets: direct)
        let trials = run(s, jobs)
        // The sweep is the long part. If the think was abandoned meanwhile (the match left, a rematch), skip the
        // refine pass: the plain fallback is returned at once and MatchOpponent's token drops it anyway.
        if Task.isCancelled {
            return fallback(s, layout: layout, cueBall: cueBall, targets: targets, placement: placement)
        }
        let per = speedFactors.count * aimOffsets.count
        var assessed: [Assessment] = []
        for (i, c) in picked.enumerated() {
            if let a = assess(c, trials: Array(trials[(i * per)..<((i + 1) * per)])) { assessed.append(a) }
        }
        let top = assessed.sorted { $0.score > $1.score }.prefix(refineKeep)
        let refined = top.map { refine($0, s, layout: layout, call: call(for: $0.candidate, rules: s.rules)) }
        let best = refined.max { $0.score < $1.score }
        if let b = best, b.window >= threshold(s.level) { return potPlan(b, rules: s.rules, placement: placement) }
        if let safe = pickSafety(trials) {
            return OpponentPlan(kind: .safety(ball: safe.firstBall), stroke: safe.stroke, placement: placement,
                                call: s.rules.usesCalls ? .safety : nil, leftOpponent: safe.leftOpponent)
        }
        if let b = best { return potPlan(b, rules: s.rules, placement: placement) }
        // Nothing made it and nothing was a legal safety: a plain full hit on the nearest legal ball, the stroke most
        // likely to be legal.
        return fallback(s, layout: layout, cueBall: cueBall, targets: targets, placement: placement)
    }

    /// A plain full hit on the nearest legal ball at the speed that rolls two table widths. In a game with calls it
    /// is called as Safety: not a planned safety, but the one legal call for a stroke that aims at no pocket.
    /// With ball in hand behind the head line and every legal ball behind the line too (directTargets is empty), a
    /// full hit would foul, so the nearest legal ball is kicked off the foot cushion instead: aimed at its mirror image
    /// across the line the cue ball's centre meets that cushion on (a radius in from the nose, as the bank candidates
    /// mirror), so the cue ball crosses the head line on its way up the table and meets the ball coming back. Struck to
    /// roll the whole unfolded path plus two table widths, so after the hit some ball still reaches a rail.
    private static func fallback(_ s: OpponentSnapshot, layout: [Vec2], cueBall: Int, targets: [Int],
                                 placement: Vec2?) -> OpponentPlan {
        let p = s.parameters
        let cue = layout.indices.contains(cueBall) ? layout[cueBall] : Vec2(p.tableLength / 4, p.tableWidth / 2)
        let up = targets.filter { layout.indices.contains($0) && NextShot.isOnTable(layout[$0]) }
        func nearest(_ balls: [Int]) -> Int? { balls.min { (layout[$0] - cue).length < (layout[$1] - cue).length } }
        let call: EightBallCall? = s.rules.usesCalls ? .safety : nil
        let plain = rollingLaunch(distance: 2 * p.tableWidth, parameters: p)
        if let near = nearest(directTargets(s, up, layout: layout)) {
            return OpponentPlan(kind: .hit(ball: near),
                                stroke: OpponentStroke(aimDegrees: degrees(layout[near] - cue), speed: plain),
                                placement: placement, call: call, leftOpponent: nil)
        }
        if let near = nearest(up) {
            let image = Vec2(2 * (p.tableLength - p.ballRadius) - layout[near].x, layout[near].y)
            let pace = PlayerShotSpeed.ordinary
            let speed = rollingLaunch(distance: (image - cue).length + 2 * p.tableWidth, parameters: p)
            return OpponentPlan(kind: .hit(ball: near),
                                stroke: OpponentStroke(aimDegrees: degrees(image - cue),
                                                       speed: min(max(speed, pace.lowerBound), pace.upperBound)),
                                placement: placement, call: call, leftOpponent: nil)
        }
        // Nothing legal on the table at all (it cannot happen in a real game): straight up the table.
        return OpponentPlan(kind: .hit(ball: nil), stroke: OpponentStroke(aimDegrees: 0, speed: plain),
                            placement: placement, call: call, leftOpponent: nil)
    }

    // MARK: Easy: the best-looking pot

    /// Easy's stroke: the pot that looks easiest, by eye. That is the first straight pot of `candidates` (clear paths
    /// first, then the widest window the geometry predicts; banks are a planned shot, not a look), lined up by the
    /// ghost-ball rule and struck at easyPaceFactor times the estimated speed with the usual touch of draw. No trial
    /// solves, no thought for where the cue ball ends up, never a deliberate safety. With no straight pot on at all
    /// it simply hits the nearest legal ball (fallback, kind .hit).
    static func easyPlan(_ s: OpponentSnapshot, layout: [Vec2], placement: Vec2?) -> OpponentPlan {
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        let targets = legalTargets(rules: s.rules, state: s.state)
        // Easy looks only at balls it may hit first straight (directTargets); the fallback keeps the whole list.
        let all = candidates(layout: layout, cueBall: cueBall, targets: directTargets(s, targets, layout: layout),
                             parameters: s.parameters)
        guard let c = all.first(where: { $0.bankRail == nil }) else {
            return fallback(s, layout: layout, cueBall: cueBall, targets: targets, placement: placement)
        }
        let pace = PlayerShotSpeed.ordinary
        let speed = min(max(c.speed * easyPaceFactor, pace.lowerBound), pace.upperBound)
        return OpponentPlan(kind: .pot(ball: c.ball, pocket: c.pocket, bankRail: nil),
                            stroke: potStroke(c.aimDegrees, speed), placement: placement,
                            call: call(for: c, rules: s.rules), window: nil, leavesNextShot: false)
    }

    // MARK: Ball in hand

    /// A place for the cue ball and the pot it sets up.
    struct Placement: Equatable, Sendable {
        var spot: Vec2
        var ball: Int
        var pocket: Int
        var estimate: Double
    }

    /// The best legal places for the cue ball: behind the ghost ball of each legal ball's pot into each pocket, at
    /// placementDistances and placementAngles, legal by NextShot.placement (behind the head line when the ball in
    /// hand says so) with both legs clear; the best spot per ball and pocket, the widest predicted windows first.
    static func placements(_ s: OpponentSnapshot) -> [Placement] {
        let p = s.parameters, spec = p.tableSpec, r = p.ballRadius
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        let behind = s.state.ballInHand == .behindHeadLine
        var best: [Placement] = []
        // Behind the head line, a ball also behind it cannot be potted straight from a spot there (directTargets).
        let targets = directTargets(s, legalTargets(rules: s.rules, state: s.state), layout: s.layout)
        for t in targets where s.layout.indices.contains(t) && NextShot.isOnTable(s.layout[t]) {
            let obj = s.layout[t]
            let others = onTable(s.layout, except: [t, cueBall])
            for k in 0..<min(TableSpec.edgePocketCount, spec.pockets.count) {
                let hole = spec.pockets[k]
                let back = (obj - hole).normalized
                let ghost = obj + back * (2 * r)
                guard TableLines.clear(from: obj, to: hole, past: others, in: s.layout, radius: r) else { continue }
                let capture = k < spec.pocketCaptureRadius.count ? spec.pocketCaptureRadius[k] : r
                var here: Placement?
                for d in placementDistances {
                    for a in placementAngles {
                        let spot = ghost + rotated(back, degrees: a) * d
                        guard NextShot.placement(of: spot, cueBall: cueBall, among: s.layout, behindHeadLine: behind,
                                                 parameters: p) == .legal,
                              TableLines.clear(from: spot, to: ghost, past: others, in: s.layout, radius: r)
                        else { continue }
                        let e = windowEstimate(cueTravel: d, objectTravel: (hole - obj).length,
                                               cosCut: cos(a * Double.pi / 180), capture: capture, radius: r)
                        if here == nil || e > here!.estimate { here = Placement(spot: spot, ball: t, pocket: k, estimate: e) }
                    }
                }
                if let h = here { best.append(h) }
            }
        }
        return Array(best.sorted { a, b in
            if a.estimate != b.estimate { return a.estimate > b.estimate }
            if a.ball != b.ball { return a.ball < b.ball }
            return a.pocket < b.pocket
        }.prefix(placementKeep))
    }

    /// Ball in hand: sweep the straight pot each of the best placements sets up and play the best if its window is
    /// wide enough; otherwise play the full search from the best placement. Nil when no placement is legal and clear
    /// (the stroke is then planned from where the cue ball lies).
    private static func planWithPlacement(_ s: OpponentSnapshot) -> OpponentPlan? {
        let spots = placements(s)
        guard let first = spots.first else { return nil }
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        var tries: [(layout: [Vec2], candidate: OpponentCandidate, spot: Vec2)] = []
        for pl in spots {
            var l = s.layout
            l[cueBall] = pl.spot
            let c = candidates(layout: l, cueBall: cueBall, targets: [pl.ball], parameters: s.parameters)
                .first { $0.pocket == pl.pocket && $0.bankRail == nil }
            if let c { tries.append((l, c, pl.spot)) }
        }
        var jobs: [Job] = []
        for t in tries {
            let callC = call(for: t.candidate, rules: s.rules)
            for v in speeds(for: t.candidate) {
                for off in aimOffsets {
                    jobs.append(Job(layout: t.layout, stroke: potStroke(t.candidate.aimDegrees + off, v), call: callC))
                }
            }
        }
        let trials = run(s, jobs)
        // Abandoned during the placements' sweep: stop here with the cheapest plan from the best spot (no refine, no
        // full search after it); the token drops it.
        if Task.isCancelled {
            var l = s.layout
            l[cueBall] = first.spot
            return fallback(s, layout: l, cueBall: cueBall, targets: legalTargets(rules: s.rules, state: s.state),
                            placement: first.spot)
        }
        let per = speedFactors.count * aimOffsets.count
        var scored: [(a: Assessment, index: Int)] = []
        for (i, t) in tries.enumerated() {
            if let a = assess(t.candidate, trials: Array(trials[(i * per)..<((i + 1) * per)])) { scored.append((a, i)) }
        }
        if let top = scored.max(by: { $0.a.score < $1.a.score }) {
            let t = tries[top.index]
            let a = refine(top.a, s, layout: t.layout, call: call(for: t.candidate, rules: s.rules))
            if a.window >= threshold(s.level) { return potPlan(a, rules: s.rules, placement: t.spot) }
        }
        var l = s.layout
        l[cueBall] = first.spot
        return planFrom(s, layout: l, placement: first.spot)
    }

    /// Result slots for the parallel solves, each written once under the lock. Internal since 0.7.4 so the bumper-pool
    /// and five-pin search can share it (through parallel(_:_:)).
    final class Slots<T: Sendable>: @unchecked Sendable {
        private var items: [T?]
        private let lock = NSLock()
        init(_ n: Int) { items = [T?](repeating: nil, count: n) }
        func set(_ i: Int, _ v: T) { lock.withLock { items[i] = v } }
        var values: [T?] { lock.withLock { items } }
    }

    /// Run `body` for 0..<n across the cores and return the results in index order. The solver and the rules are
    /// pure, so running them in parallel cannot change any answer, only how soon it comes. concurrentPerform returns
    /// only after every iteration has run, so every slot is filled; the count check below says so out loud.
    static func parallel<T: Sendable>(_ n: Int, _ body: @Sendable (Int) -> T) -> [T] {
        guard n > 0 else { return [] }
        let slots = Slots<T>(n)
        DispatchQueue.concurrentPerform(iterations: n) { i in slots.set(i, body(i)) }
        let out = slots.values.compactMap { $0 }
        precondition(out.count == n, "OpponentPlanner.parallel: an iteration left its slot empty")
        return out
    }
}

// MARK: - The opponent at the table (main actor)

@MainActor
@Observable
final class MatchOpponent {
    /// True while the planner works on a background task. The match card says "Thinking..." meanwhile, and the model
    /// reads it for its computer-turn stage (.thinking), which can now begin while the ruling card is still up.
    private(set) var thinking = false
    /// The computer's last stroke, for "Why that shot" on the ruling card that follows it (and in the turn banner
    /// once a routine ruling has settled by itself).
    private(set) var lastShot: OpponentShot?

    /// Bumped by every think started and every cancel: a result that comes back with an older token is dropped.
    @ObservationIgnored private var token = 0
    /// A finished plan waiting to be played (the ruling card may still be up, the menu open, or the replay running).
    @ObservationIgnored private var ready: (key: TurnKey, work: OpponentWork)?
    /// The turn whose stroke the model is staging (the aim swinging, the cue drawing back): nothing is planned again
    /// for it while the model stages or strikes it.
    @ObservationIgnored private var stagedKey: TurnKey?
    /// The detached task that runs the planner for the think in flight. Its handle is kept so cancel() can cancel it:
    /// a detached task does not inherit cancellation from the task that awaits it, so cancelling only the awaiting
    /// task would leave the planner running. The bumper-pool and five-pin search checks Task.isCancelled between its
    /// phases and returns early; the token still drops whatever comes back.
    @ObservationIgnored private var thinkTask: Task<OpponentWork, Never>?

    /// What a plan was made for. A plan is played only while all of this is still the same.
    struct TurnKey: Equatable, Sendable {
        var shotCount: Int
        var turn: PlayerID
        var choice: PendingChoice?
        var ballInHand: BallInHand
        var layout: [Vec2]
    }

    /// Called every frame by MatchMode.update while the match is aiming or a ruling card is up. Thinking starts as
    /// soon as the computer's next decision is known (MatchMode.upcomingComputerDecision): during the ruling card it
    /// plans on the table the card's dismissal will put on, so by the time the card goes the plan is often ready.
    /// The plan is only played once the match is aiming on that very table with the balls at rest.
    func update(_ match: MatchMode) {
        let model = match.model
        guard model.match === match, let d = match.upcomingComputerDecision else { return }
        let key = TurnKey(shotCount: match.state.shotCount, turn: match.state.turn, choice: match.state.pendingChoice,
                          ballInHand: match.state.ballInHand, layout: d.layout)
        if let staged = stagedKey {
            // The model is staging or striking this turn's stroke: nothing to do until it is struck (the phase then
            // leaves aiming and this is no longer called) or dropped (then it is planned again below).
            if staged == key, model.computerTurnStage == .staging || model.computerTurnStage == .striking { return }
            stagedKey = nil
        }
        if let r = ready {
            // The table moved on since this was planned (an answer on the card, a re-rack): drop it and think again.
            guard r.key == key else { ready = nil; return }
            guard d.dueNow, !model.menuOpen, model.aimReady, !model.isSolving else { return }
            ready = nil
            perform(r.work, seat: d.seat, level: d.level, match: match, key: key)
            return
        }
        // While aiming the table on screen is the one played from, so it must be at rest; during the ruling card the
        // snapshot is the card's next table, whatever the screen is replaying.
        guard !thinking, !model.isSolving, !d.dueNow || model.aimReady else { return }
        thinking = true
        token += 1
        let t = token
        // The seed perform(_:) will draw this stroke's noise from: the same rack seed, shot count and seat (the key
        // above pins the shot count and seat, so the two agree whenever the plan is played).
        let snapshot = OpponentSnapshot(layout: d.layout, state: match.state, rules: match.rules,
                                        parameters: model.matchSolveParameters, level: d.level, racked: d.racked,
                                        noiseSeed: Self.strokeSeed(match, seat: d.seat))
        let choosing = match.state.pendingChoice != nil
        // A pure function of the snapshot, so it runs off the main actor (ShowpieceModel.strike and EightBallMode's
        // Scoring phase use the same pattern): the table keeps drawing while the computer thinks.
        let think = Task.detached(priority: .userInitiated) {
            choosing ? OpponentWork.answer(OpponentPlanner.answer(snapshot))
                     : OpponentWork.stroke(OpponentPlanner.plan(snapshot))
        }
        thinkTask = think
        Task { [weak self] in
            let work = await think.value
            self?.finish(work, key: key, token: t)
        }
    }

    /// Forget any think in flight or waiting (a rematch, the match left), and stop the planner that runs it.
    func cancel() {
        token += 1
        thinkTask?.cancel()
        thinkTask = nil
        thinking = false
        ready = nil
        stagedKey = nil
    }

    private func finish(_ work: OpponentWork, key: TurnKey, token t: Int) {
        guard t == token else { return }
        thinkTask = nil
        thinking = false
        ready = (key, work)
    }

    /// The seed of the computer's next stroke at `seat`: the rack's seed (saved), the match's shot count (saved) and
    /// the seat. One place, read by update (the planner's snapshot) and perform (the real noise).
    private static func strokeSeed(_ match: MatchMode, seat: PlayerID) -> UInt64 {
        OpponentNoise.seed(rackSeed: match.setup.rackSeed, shotCount: match.state.shotCount, seat: seat.index)
    }

    /// Play the plan through the match and the model, as a player's taps would: the answer at once; a stroke by
    /// making the call, then handing it to the model to stage (the model places the cue ball, swings the aim, draws
    /// the cue back for a beat and strikes, setting MatchMode.computerActing itself around the strike).
    private func perform(_ work: OpponentWork, seat: PlayerID, level: ComputerLevel, match: MatchMode, key: TurnKey) {
        match.computerActing = true
        defer { match.computerActing = false }
        switch work {
        case .answer(let a):
            match.answer(a)
        case .stroke(let plan):
            let model = match.model
            // The game's noise scale is 1 for every game today, which leaves the numbers exactly as draw(level:seed:)
            // gives them (OpponentNoise.draw(level:seed:kind:)).
            let noise = OpponentNoise.draw(level: level, seed: Self.strokeSeed(match, seat: seat),
                                           kind: match.rules.kind)
            if match.mustCall {
                match.setCall(plan.call ?? .safety)
                // A call the rules refuse (it cannot happen for a planned pot, but the turn must never stall): safety.
                if match.currentCall == nil { match.setCall(.safety) }
            }
            // The planner's speeds are launch speeds solved with the house cue, whose launch speed equals its power
            // (CueProfile.house), so they are handed to the model as the power, as 0.6.6's playComputerStroke took
            // them.
            let staged: Bool
            if case .breakShot = plan.kind {
                let reach = model.layout.count > 1 ? (model.layout[1] - model.layout[0]).length : 0
                let offset = tan(noise.aimDegrees * Double.pi / 180) * reach
                let s = plan.stroke.with(OpponentNoise(aimDegrees: 0, speedShare: noise.speedShare, tipUp: noise.tipUp,
                                                       tipSide: noise.tipSide),
                                         speeds: PlayerShotSpeed.rackBreak, tipLimit: model.tipLimit)
                staged = model.stageComputerStroke(placement: nil, aimDegrees: 0, breakAimOffset: offset,
                                                   power: s.speed, tipUp: s.tipUp, tipSide: s.tipSide)
            } else {
                let s = plan.stroke.with(noise, speeds: PlayerShotSpeed.ordinary, tipLimit: model.tipLimit)
                staged = model.stageComputerStroke(placement: plan.placement, aimDegrees: s.aimDegrees,
                                                   breakAimOffset: 0, power: s.speed, tipUp: s.tipUp,
                                                   tipSide: s.tipSide)
            }
            if staged {
                lastShot = OpponentShot(seat: seat, level: level, plan: plan, noise: noise)
                stagedKey = key
            } else {
                // Not staged (the model refused the stroke); the next frame plans again from the table as it is.
                NSLog("MatchOpponent: the model did not stage the planned stroke; planning again")
            }
        }
    }
}
