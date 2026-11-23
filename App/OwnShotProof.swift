// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, new file 2): the proof behind a player's own
//          saved shot. OwnShotProof solves the saved strike exactly as the model would (ShowpieceModel.solverCopy on
//          the shot's own table, cloth and physics generation, then PoolSolver.simulate), judges that solve against the
//          shot's goal with the trick-shot judge (so "it still makes it" means exactly what "made it" means for the
//          player), measures how forgiving the shot is (each of aim, power, tip height and side pushed either way from
//          the saved strike until the goal fails: doubling, then four halvings), and arms Watch it so the next strike
//          plays the saved stroke bit for bit (through the model's kept strike, the what-if's Keep route).
//          OwnShotSignature picks the held moments of a saved shot's slow Lens replay from the recording alone (the cue
//          ball's first contact, then the last ball down: its bank, else its drop), so TrickSignature can call it with
//          no actor hop.
//          Everything but `arm` is pure and nonisolated: OwnShotShelf runs the solves on detached background tasks with
//          Sendable values only (OwnShot, ShotInput, Timeline). `arm` reads the shelf and writes the model, so it is
//          main-actor; TrickShotMode.watch() calls it right before shootNow (hook T2).
// SRP/DRY check: Pass - checked ShowpieceModel (solverCopy and the kept strike are reused, not copied), TrickShotJudge
//          (failure() is the one goal test), TrickPathCache (the same one-solve-per-shot, off-main pattern) and
//          TrickSignature / ShotMoments (the finders are reused; only the choice of moments for an unauthored shot is
//          new here).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

enum OwnShotProof {
    /// The saved strike (or a changed copy of it) solved on the shot's own table, surface and generation, exactly as
    /// the model's prepare and solve would. Nil when this build does not know the shot's table or surface.
    nonisolated static func solve(_ own: OwnShot, input: ShotInput? = nil) -> Timeline? {
        guard let table = own.table, let surface = own.surface else { return nil }
        return PoolSolver.simulate(ShowpieceModel.solverCopy(input ?? own.input, table: table, surface: surface,
                                                             generation: own.generation))
    }

    /// The attempt the model would record for that solve, for the judge. The judge reads only the recording here
    /// (a saved shot's goal has no side rule, which is the one part read from the settings).
    nonisolated static func attempt(_ own: OwnShot, input: ShotInput, timeline: Timeline) -> ShotAttempt {
        let s = own.solution
        return ShotAttempt(isBreak: false, breakSeed: 0, start: own.start, timeline: timeline, aim: s.aim,
                           power: s.power, powerRange: PlayerShotSpeed.ordinary, tipUp: s.tipUp, tipSide: s.tipSide,
                           elevation: s.elevation ?? 0, seed: input.seed, input: input,
                           surface: own.surface ?? .cloth, table: own.table ?? .standard, generation: own.generation)
    }

    /// True when `input`, struck on the shot's own table and cloth, still meets the shot's goal.
    nonisolated static func passes(_ own: OwnShot, input: ShotInput) -> Bool {
        guard let tl = solve(own, input: input) else { return false }
        return TrickShotJudge.failure(own.goal, attempt(own, input: input, timeline: tl)) == nil
    }

    /// True when the saved strike still meets the goal.
    nonisolated static func holds(_ own: OwnShot) -> Bool { check(own).holds }

    /// The same, also giving the solve, so one solve feeds both the check and the list's drawing.
    nonisolated static func check(_ own: OwnShot) -> (holds: Bool, timeline: Timeline?) {
        let input = own.input
        guard let tl = solve(own, input: input) else { return (false, nil) }
        return (TrickShotJudge.failure(own.goal, attempt(own, input: input, timeline: tl)) == nil, tl)
    }

    // MARK: How forgiving

    /// The four settings the window measures, with the first step and the furthest push tried each way. Steps are
    /// fine enough to find the tightest authored windows (0.1 degree of aim); the caps are well past the most
    /// forgiving (1.6 degrees), so a very easy shot is not measured for ever.
    private enum Control: CaseIterable {
        case aim, power, tipUp, tipSide

        var step: Double {
            switch self {
            case .aim: return 0.05          // degrees
            case .power: return 0.05        // metres per second
            case .tipUp, .tipSide: return 0.0005   // metres
            }
        }

        var cap: Double {
            switch self {
            case .aim: return 4
            case .power: return 3
            case .tipUp: return 0.02
            case .tipSide: return 0.012
            }
        }
    }

    /// The slowest launch the measurement pushes power down to: a stroke softer than this is no stroke.
    private static let minimumSpeed = 0.1
    /// How far off centre the measurement moves the tip, as a share of the ball's radius: the miscue limit's
    /// neighbourhood, past which no player's stroke is a fair comparison.
    private static let tipLimitShare = 0.8

    /// The window, measured as the plan's Decision 5 says: for each setting, each way, the furthest push (doubling from
    /// the first step, then four halvings between the last pass and the first fail) that still makes the shot; the
    /// smaller side is kept. A side with no room to move (the tip already at its limit, power already at the floor) is
    /// left out; a setting with no passing push either way gets half its first step. About ninety solves at most.
    /// `build` is the app's CFBundleVersion, passed in so tests can pass a fixed string. Call off the main actor.
    nonisolated static func measureWindow(_ own: OwnShot, build: String) -> OwnWindow {
        let base = own.input
        let radius = (own.table ?? .standard).parameters.ballRadius
        let tipLimit = OwnShotProof.tipLimitShare * radius

        // Room to move from the saved value in the direction of `sign` before a limit stops it.
        func room(_ c: Control, _ sign: Double) -> Double {
            switch c {
            case .aim: return .infinity
            case .power: return sign > 0 ? .infinity : base.strike.speed - OwnShotProof.minimumSpeed
            case .tipUp: return tipLimit - sign * base.strike.tipUp
            case .tipSide: return tipLimit - sign * base.strike.tipSide
            }
        }

        // The saved input with one setting moved by `delta` (in that setting's units). Everything else is unchanged:
        // positions, seed, elevation and the other settings.
        func moved(_ c: Control, by delta: Double) -> ShotInput {
            var i = base
            switch c {
            case .aim:
                let r = delta * Double.pi / 180
                let d = base.strike.direction
                // Rotate the unit direction; assigned directly, as the saved one is (CueStrike's init is not used).
                i.strike.direction = Vec2(d.x * cos(r) - d.y * sin(r), d.x * sin(r) + d.y * cos(r))
            case .power:
                i.strike.speed = max(OwnShotProof.minimumSpeed, base.strike.speed + delta)
            case .tipUp:
                i.strike.tipUp = min(max(base.strike.tipUp + delta, -tipLimit), tipLimit)
            case .tipSide:
                i.strike.tipSide = min(max(base.strike.tipSide + delta, -tipLimit), tipLimit)
            }
            return i
        }

        // The furthest passing push one way, or nil when that way has no room for even the first step.
        func half(_ c: Control, _ sign: Double) -> Double? {
            let limit = min(c.cap, room(c, sign))
            guard limit >= c.step else { return nil }
            var pass = 0.0
            var d = c.step
            while d <= limit && OwnShotProof.passes(own, input: moved(c, by: sign * d)) {
                pass = d
                d *= 2
            }
            if d <= limit {
                // The first fail is at d and the last pass at `pass`: narrow the edge between them.
                for _ in 0..<4 {
                    let mid = (pass + d) / 2
                    if OwnShotProof.passes(own, input: moved(c, by: sign * mid)) { pass = mid } else { d = mid }
                }
            }
            return pass > 0 ? pass : c.step / 2
        }

        func width(_ c: Control) -> Double {
            let sides = [half(c, 1), half(c, -1)].compactMap { $0 }
            return sides.min() ?? c.step / 2
        }

        return OwnWindow(aim: width(.aim), power: width(.power), tipUp: width(.tipUp), tipSide: width(.tipSide),
                         build: build)
    }

    // MARK: Watch it

    /// Watch it for a saved shot: arm the exact strike so the next shootNow plays it. Does nothing for an authored
    /// shot. Called by TrickShotMode.watch() right before model.shootNow(), after loadStart has put the solution in the
    /// controls, so the kept controls match and shootNow uses the kept input (no stroke drift, the saved seed). The
    /// attempt it records keeps shootNow's own serial seed in `seed`; `input.seed` is the saved one and alone drives
    /// the solve.
    @MainActor static func arm(_ shot: TrickShot, model: ShowpieceModel) {
        guard OwnShot.isOwnID(shot.id), let own = OwnShotShelf.shared.shot(id: shot.id) else { return }
        model.pendingStroke = nil
        model.keptStrike = ShowpieceModel.KeptStrike(input: own.input, delivery: nil, controls: model.controlValues)
    }
}

/// The held moments of a saved shot's guided Lens replay. Plain (nonisolated) like TrickSignature, which calls it: it
/// reads only the recording, never the shelf, so there is no actor hop and no shared copy to keep in step.
enum OwnShotSignature {
    /// The cue ball's first contact, then, for the last object ball to drop in this recording, its cushion after its
    /// last contact when it banked, else its drop. At most two, each captioned (ShotMoments.signature). Empty for an
    /// id that is not a saved shot's, as TrickSignature gave every unknown id before 0.7.7.
    static func events(forOwn id: String, in timeline: Timeline, captions: [Caption]) -> [Int] {
        guard OwnShot.isOwnID(id) else { return [] }
        let m = ShotMoments(timeline: timeline, captions: captions)
        let first = m.firstContact(of: TrickSignature.cueBall)
        let events = timeline.events
        let lastDrop = events.indices.last { i in
            events[i].kind == .pocket && events[i].balls.first?.ball != TrickSignature.cueBall
        }
        let ball = lastDrop.flatMap { events[$0].balls.first?.ball }
        let second = ball.flatMap { m.railAfterLastContact(of: $0) } ?? lastDrop
        let found = m.signature([first, second])
        return found.isEmpty ? m.signature([first]) : found
    }
}
