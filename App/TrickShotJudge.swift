// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: Decides whether a player's attempt at a trick shot made it, and if not, says in one sentence what to change.
//          It reads only the attempt's own recording (which balls dropped and in which pocket, which ball the cue ball
//          touched first, whether a ball banked, where the cue ball stopped, whether it scratched) and the settings the
//          player struck with, and compares them with the shot's authored solution (TrickShots). The advice comes from
//          whichever setting is furthest off measured against that setting's skill window: an aim error is told as
//          "too thin" or "too thick" and "aim a touch left or right"; a tip error as more or less draw or follow, or
//          side; a power error as harder or softer. For the stop-dead shot the cue ball's resting place decides it:
//          rolled on means strike lower, came back means strike higher.
//          Left and right follow the same convention as the retry comparison (ShotComparison): counter-clockwise on the
//          table plan is to the shooter's left as they look down the cue.
//          Used by TrickShotMode after every attempt that started from the trick's own layout.
// SRP/DRY check: Pass - checked ShotAttempt (firstStruck, cueBallScratched, cueRest are reused, not repeated) and
//          ShotComparison (compares two attempts with each other; this compares one attempt with the answer). The
//          dev search tool (BreakProbe TrickSearch) has its own copy of the goal test on purpose: the package must not
//          depend on app files.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// The outcome of one attempt: made or not, and the one line the card shows.
struct TrickVerdict: Equatable {
    let made: Bool
    let line: String
}

enum TrickShotJudge {
    /// The pocket a ball dropped in during a recording, or nil.
    static func pocket(of ball: Int, in tl: Timeline) -> Int? {
        tl.events.first { $0.kind == .pocket && $0.balls.first?.ball == ball }?.pocket
    }

    /// True when the recording meets every part of the goal (the cue ball must never scratch).
    static func passes(_ goal: TrickGoal, _ attempt: ShotAttempt) -> Bool {
        failure(goal, attempt) == nil
    }

    /// What part of the goal failed first, or nil when it all held.
    enum Failure: Equatable { case scratch, missedFirstBall, notBanked, ballStayedUp(Int), wrongPocket(Int), cueZone }

    static func failure(_ goal: TrickGoal, _ attempt: ShotAttempt) -> Failure? {
        let tl = attempt.timeline
        if let first = goal.firstHit, attempt.firstStruck != first { return .missedFirstBall }
        for d in goal.drops {
            guard let k = pocket(of: d.ball, in: tl) else { return .ballStayedUp(d.ball) }
            if let want = d.pocket, want != k { return .wrongPocket(d.ball) }
        }
        if let b = goal.bank {
            let drop = tl.pocketTime[b] ?? -1
            let banked = tl.events.contains { $0.kind == .cushion && $0.edge == .rail && $0.time < drop && $0.balls.first?.ball == b }
            if !banked { return .notBanked }
        }
        if attempt.cueBallScratched { return .scratch }
        if let zone = goal.cueZone, (attempt.cueRest - zone.centre).length > zone.radius { return .cueZone }
        return nil
    }

    /// Made it, or the one thing to change.
    static func verdict(for shot: TrickShot, attempt: ShotAttempt) -> TrickVerdict {
        guard let fail = failure(shot.goal, attempt) else { return TrickVerdict(made: true, line: shot.praise) }
        return TrickVerdict(made: false, line: advice(shot, attempt, fail))
    }

    // MARK: Advice

    private static func advice(_ shot: TrickShot, _ a: ShotAttempt, _ fail: Failure) -> String {
        let sol = shot.solution, win = shot.window
        // The stop shot is all about strike height: where the cue ball finished says which way to go.
        if fail == .cueZone, let zone = shot.goal.cueZone {
            let along = (a.cueRest - zone.centre).dot(strikeDirection(shot, a))
            return along > 0 ? "The cue ball rolled on after the hit. Strike a little lower."
                             : "The cue ball came back. Strike a little higher, nearer the middle."
        }
        let scratchNote = fail == .scratch ? "The cue ball went in too. " : ""
        // Each setting's miss measured in its own window: the largest is the one to fix first.
        var errors: [(kind: String, size: Double, signed: Double)] = [
            ("aim", abs(angleGap(a.aim, sol.aim, isBreak: shot.isBreak)) / win.aim, angleGap(a.aim, sol.aim, isBreak: shot.isBreak)),
            ("power", abs(a.power - sol.power) / win.power, a.power - sol.power),
            ("tipUp", abs(a.tipUp - sol.tipUp) / win.tipUp, a.tipUp - sol.tipUp),
        ]
        if win.tipSide > 0 { errors.append(("tipSide", abs(a.tipSide - sol.tipSide) / win.tipSide, a.tipSide - sol.tipSide)) }
        let worst = errors.max { $0.size < $1.size }!
        guard worst.size > 1 else {
            return scratchNote + "So close. Every setting is nearly there: same again, a fraction more care on the aim."
        }
        switch worst.kind {
        case "aim":
            let amount = worst.size > 4 ? "well" : "a touch"
            // Positive gap: the player aimed further counter-clockwise (left) than the answer, so go right.
            let way = worst.signed > 0 ? "right" : "left"
            if fail == .missedFirstBall, let first = shot.goal.firstHit {
                return scratchNote + "The cue ball has to reach the \(first) first. Aim \(amount) \(way)."
            }
            if let thick = tooThick(shot, a) {
                return scratchNote + "You hit it too \(thick ? "full" : "thin"). Aim \(amount) \(way)."
            }
            return scratchNote + "Not quite the line. Aim \(amount) \(way)."
        case "power":
            return scratchNote + (worst.signed < 0 ? "Not enough pace. Pull back further to hit it harder."
                                                   : "Too much pace. Pull back less to hit it softer.")
        case "tipUp":
            if sol.tipUp < -0.003 {
                return scratchNote + (worst.signed > 0 ? "Not enough draw. Strike lower on the cue ball."
                                                      : "Too much draw. Strike a little higher.")
            }
            if sol.tipUp > 0.003 {
                return scratchNote + (worst.signed < 0 ? "Not enough follow. Strike higher on the cue ball."
                                                      : "Too much follow. Strike a little lower.")
            }
            return scratchNote + "Strike nearer the middle of the cue ball."
        default:
            // Positive side is right-hand spin.
            let want = sol.tipSide > 0 ? "right" : "left"
            if (sol.tipSide > 0) == (worst.signed < 0) {
                return scratchNote + "Not enough \(want) side. Strike further to the \(want) of the cue ball."
            }
            return scratchNote + "Too much side. Strike a little nearer the middle."
        }
    }

    /// How far the attempt's aim is from the answer: degrees for a shot (wrapped to -180...180), millimetres turned
    /// into the same units as the window for the break (the window is in metres there, so the raw gap is used).
    private static func angleGap(_ a: Double, _ b: Double, isBreak: Bool) -> Double {
        if isBreak { return a - b }
        var d = a - b
        while d > 180 { d -= 360 }
        while d < -180 { d += 360 }
        return d
    }

    /// The direction the cue ball was sent, on the table plan.
    private static func strikeDirection(_ shot: TrickShot, _ a: ShotAttempt) -> Vec2 {
        if case .rack = shot.setup { return Vec2(1, 0) }
        let r = a.aim * Double.pi / 180
        return Vec2(cos(r), sin(r))
    }

    /// True when the attempt struck the first object ball fuller than the answer does, false when thinner; nil when it
    /// cannot be told (a break, or no first ball named).
    private static func tooThick(_ shot: TrickShot, _ a: ShotAttempt) -> Bool? {
        guard case .layout(let start) = shot.setup, let first = shot.goal.firstHit ?? shot.goal.drops.first?.ball,
              NextShot.isOnTable(start[first]) else { return nil }
        let toBall = (start[first] - start[0]).normalized
        func offset(_ deg: Double) -> Double {
            let r = deg * Double.pi / 180
            let d = Vec2(cos(r), sin(r))
            // Sideways distance of the ball's centre from the cue's line, in units of the line length: 0 is full.
            return abs(d.x * toBall.y - d.y * toBall.x)
        }
        return offset(a.aim) < offset(shot.solution.aim)
    }
}
