// Author: Claude Opus 5.5 High
// Edited: GPT 6.2 Sol, 21-November-2026 (draw-massé carom lesson).
// Date: 20-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (every line of advice is a String(localized:) key; a scratch adds its
//          sentence as one placeholder line, not by joining two strings)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 trick-shots stream: the strong-side rule of the two side-spin
//          shots (TrickGoal.side), checked first from the stroke's settings, with its own line of advice.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 2 to 4: one cue-angle check for trick shots and lessons, run before the ranking of aim, power and tip,
//          so a level cue at the massé or the jump is told to raise the cue instead of "so close" or aim advice (a
//          lesson passes its own band of marked angles, a trick its band of offered angles that make it); "too full" and
//          "too thin" only for a direct shot (never with a raised cue, or when the cue ball meets a cushion before its
//          first ball); the draw, follow and side advice names the gap in millimetres.)
// PURPOSE: Decides whether a player's attempt at a trick shot made it, and if not, says in one sentence what to change.
//          It reads only the attempt's own recording (which balls dropped and in which pocket, which ball the cue ball
//          touched first, whether a ball banked, where the cue ball stopped, whether it scratched) and the settings the
//          player struck with, and compares them with the shot's authored solution (TrickShots). A shot that needs a
//          raised cue, struck at the wrong cue angle, is first told to raise or lower the cue (cueAngleLine), since the
//          ranking below does not weigh the angle. Otherwise the advice comes from whichever setting is furthest off
//          measured against that setting's skill window: an aim error is told as "too thin" or "too thick" (a direct
//          shot only) and "aim a touch left or right"; a tip error as more or less draw or follow, or side, with the
//          gap in millimetres; a power error as harder or softer. For the stop-dead shot the cue ball's resting place
//          decides it: rolled on means strike lower, came back means strike higher. Lessons (LessonMode) are judged
//          here too, each passing its own band of marked cue angles.
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
    enum Failure: Equatable {
        case scratch, missedFirstBall, missedCarom, notBanked, ballStayedUp(Int), wrongPocket(Int), cueZone
        /// A side-spin shot struck without its strong side (TrickGoal.side). `restHeld` is true when everything else in
        /// the goal held, so the card can say the ball went in but not the way the shot asks.
        case notEnoughSide(restHeld: Bool)
    }

    static func failure(_ goal: TrickGoal, _ attempt: ShotAttempt) -> Failure? {
        // The strong-side rule is read from the stroke's own settings and checked first: without the side, whatever the
        // balls did, it was not this shot. Same side of centre as the rule, and at least as much (a hair of rounding
        // allowed, so a player who sets exactly the rule's value is not refused).
        if let need = goal.side, !(attempt.tipSide * need > 0 && abs(attempt.tipSide) >= abs(need) - 1e-6) {
            var rest = goal
            rest.side = nil
            return .notEnoughSide(restHeld: failure(rest, attempt) == nil)
        }
        let tl = attempt.timeline
        if let first = goal.firstHit, attempt.firstStruck != first { return .missedFirstBall }
        if let second = goal.secondHit {
            let contacts = tl.events.lazy
                .filter { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }
                .compactMap { $0.balls.first { $0.ball != 0 }?.ball }
            guard contacts.dropFirst().first == second else { return .missedCarom }
        }
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

    /// Made it, or the one thing to change. `cueAngles` is the band of cue angles, whole degrees, in which the shot
    /// works: a lesson passes its own marked band (Lesson.cueAngles); nil uses the shot's own (TrickShot.cueAngles), or
    /// a few degrees either side of the answer's angle when it has none.
    static func verdict(for shot: TrickShot, attempt: ShotAttempt, cueAngles: ClosedRange<Int>? = nil) -> TrickVerdict {
        guard let fail = failure(shot.goal, attempt) else { return TrickVerdict(made: true, line: shot.praise) }
        return TrickVerdict(made: false, line: advice(shot, attempt, fail, cueAngles: cueAngles ?? shot.cueAngles))
    }

    // MARK: The cue angle (0.7.5)

    /// Slack either side of a band of whole-degree menu angles: the menu sets exact angles, so half a degree only
    /// absorbs rounding (a sine read back through asin), as LessonMode's own check did before 0.7.5.
    static let bandSlack = 0.5
    /// Slack either side of the answer's own angle when no band is known: a few degrees, under one of the menu's fine
    /// steps (5 degrees up to 30), so only an angle clearly off the answer is told to change.
    static let answerSlack = 3.0

    /// The cue's angle above the table in degrees, from the sine the solver and ShotAttempt use. Clamped at the rig's
    /// limit (sine 0.995, ShowpieceModel.maxElevation) so a stray value never asks asin for more than one.
    static func degrees(ofSine s: Double) -> Double { asin(min(max(s, 0), 0.995)) * 180 / Double.pi }

    /// The one cue-angle check for trick shots and lessons (0.7.5; before, only LessonMode had it, so a level cue at the
    /// massé was told "So close" or to aim better). Only for a shot whose answer raises the cue, and never for a break
    /// (struck level). Below the band: raise it; above: lower it; inside: nil, and the other settings decide.
    static func cueAngleLine(_ shot: TrickShot, _ a: ShotAttempt, band: ClosedRange<Int>?) -> String? {
        guard !shot.isBreak, !a.isBreak, let want = shot.solution.elevation, want > 0 else { return nil }
        let struck = degrees(ofSine: a.elevation)
        let low: Double, high: Double
        if let band {
            low = Double(band.lowerBound) - bandSlack
            high = Double(band.upperBound) + bandSlack
        } else {
            let answer = degrees(ofSine: want)
            low = answer - answerSlack
            high = answer + answerSlack
        }
        // The two lines are the ones LessonMode used before 0.7.5, kept word for word (they are already translated).
        if struck < low { return String(localized: "Raise the cue more. A level cue cannot do this one.") }
        if struck > high { return String(localized: "The cue is too steep. Lower it a little.") }
        return nil
    }

    // MARK: Advice

    private static func advice(_ shot: TrickShot, _ a: ShotAttempt, _ fail: Failure, cueAngles: ClosedRange<Int>?) -> String {
        let sol = shot.solution, win = shot.window
        // The cue angle first: the ranking below weighs only aim, power and tip, so a stroke at the wrong angle would
        // otherwise be told it was nearly there, or to aim differently, when no aim makes it.
        if let angle = cueAngleLine(shot, a, band: cueAngles) { return angle }
        // A side-spin shot struck without its side: that is the one thing to change, whatever else happened.
        if case .notEnoughSide(let restHeld) = fail {
            let want = (shot.goal.side ?? sol.tipSide) > 0 ? String(localized: "right") : String(localized: "left")
            return restHeld
                ? String(localized: "In, but without the strong side this shot is about. Strike further to the \(want) of the cue ball.")
                : String(localized: "Not enough \(want) side. Strike further to the \(want) of the cue ball.")
        }
        // The stop shot is all about strike height: where the cue ball finished says which way to go.
        if fail == .cueZone, let zone = shot.goal.cueZone {
            let along = (a.cueRest - zone.centre).dot(strikeDirection(shot, a))
            return along > 0 ? String(localized: "The cue ball rolled on after the hit. Strike a little lower.")
                             : String(localized: "The cue ball came back. Strike a little higher, nearer the middle.")
        }
        // A scratch adds one sentence in front of the advice. The whole sentence is one translatable line, so no
        // translation has to glue two halves together.
        func note(_ text: String) -> String {
            fail == .scratch ? String(localized: "The cue ball went in too. \(text)") : text
        }
        // Each setting's miss measured in its own window: the largest is the one to fix first.
        var errors: [(kind: String, size: Double, signed: Double)] = [
            ("aim", abs(angleGap(a.aim, sol.aim, isBreak: shot.isBreak)) / win.aim, angleGap(a.aim, sol.aim, isBreak: shot.isBreak)),
            ("power", abs(a.power - sol.power) / win.power, a.power - sol.power),
            ("tipUp", abs(a.tipUp - sol.tipUp) / win.tipUp, a.tipUp - sol.tipUp),
        ]
        if win.tipSide > 0 { errors.append(("tipSide", abs(a.tipSide - sol.tipSide) / win.tipSide, a.tipSide - sol.tipSide)) }
        let worst = errors.max { $0.size < $1.size }!
        if fail == .missedCarom && worst.size <= 1 {
            return String(localized: "You hit the 4. Raise the cue and keep the low, off-centre hit to bend back toward the 9.")
        }
        guard worst.size > 1 else {
            return note(String(localized: "So close. Every setting is nearly there: same again, a fraction more care on the aim."))
        }
        switch worst.kind {
        case "aim":
            let amount = worst.size > 4 ? String(localized: "well") : String(localized: "a touch")
            // Positive gap: the player aimed further counter-clockwise (left) than the answer, so go right.
            let way = worst.signed > 0 ? String(localized: "right") : String(localized: "left")
            if fail == .missedFirstBall, let first = shot.goal.firstHit {
                return note(String(localized: "The cue ball has to reach the \(first) first. Aim \(amount) \(way)."))
            }
            if let thick = tooThick(shot, a) {
                let thickness = thick ? String(localized: "full") : String(localized: "thin")
                return note(String(localized: "You hit it too \(thickness). Aim \(amount) \(way)."))
            }
            return note(String(localized: "Not quite the line. Aim \(amount) \(way)."))
        case "power":
            return note(worst.signed < 0 ? String(localized: "Not enough pace. Pull back further to hit it harder.")
                                         : String(localized: "Too much pace. Pull back less to hit it softer."))
        case "tipUp":
            // The gap to the answer in millimetres on the cue ball (0.7.5), rounded to the half millimetre the fine
            // controls and the spoken tip use (TableWords.millimetres), so the player knows how far to move the dot.
            let mm = TableWords.millimetres(worst.signed)
            if sol.tipUp < -0.003 {
                return note(worst.signed > 0 ? String(localized: "Not enough draw. Strike about \(mm) millimetres lower on the cue ball.")
                                             : String(localized: "Too much draw. Strike about \(mm) millimetres higher."))
            }
            if sol.tipUp > 0.003 {
                return note(worst.signed < 0 ? String(localized: "Not enough follow. Strike about \(mm) millimetres higher on the cue ball.")
                                             : String(localized: "Too much follow. Strike about \(mm) millimetres lower."))
            }
            return note(worst.signed > 0
                        ? String(localized: "Strike about \(mm) millimetres lower, nearer the middle of the cue ball.")
                        : String(localized: "Strike about \(mm) millimetres higher, nearer the middle of the cue ball."))
        default:
            let mm = TableWords.millimetres(worst.signed)
            // Positive side is right-hand spin. When the answer has none, any side the player added is the problem.
            if abs(sol.tipSide) < 0.002 {
                return note(String(localized: "The side spin bent it off line. Strike about \(mm) millimetres nearer the middle of the cue ball."))
            }
            let want = sol.tipSide > 0 ? String(localized: "right") : String(localized: "left")
            if (sol.tipSide > 0) == (worst.signed < 0) {
                return note(String(localized: "Not enough \(want) side. Strike about \(mm) millimetres further to the \(want) of the cue ball."))
            }
            return note(String(localized: "Too much side. Strike about \(mm) millimetres nearer the middle."))
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
    /// cannot be told (a break, or no first ball named) or when "full" and "thin" would mean nothing (0.7.5): the cue's
    /// line only says how full the hit is when the cue ball runs straight down it to the ball. A raised cue bends or
    /// lifts the path (the massé, the jump, the carom), and a cue ball that meets a cushion before its first ball (a
    /// kick) arrives from somewhere else entirely; both are told only to aim left or right.
    private static func tooThick(_ shot: TrickShot, _ a: ShotAttempt) -> Bool? {
        guard shot.solution.elevation == nil, !cushionBeforeFirstContact(a),
              case .layout(let start) = shot.setup, let first = shot.goal.firstHit ?? shot.goal.drops.first?.ball,
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

    /// True when the attempt's own recording has the cue ball meeting a cushion before it first touches a ball (or at
    /// all, when it touches none): a kick, where the cue's line does not run to the ball.
    static func cushionBeforeFirstContact(_ a: ShotAttempt) -> Bool {
        let cue = a.cueBall
        let firstContact = a.timeline.events
            .first { $0.kind == .ballBall && $0.balls.contains { $0.ball == cue } }?.time ?? .infinity
        return a.timeline.events.contains { $0.kind == .cushion && $0.time < firstContact && $0.balls.first?.ball == cue }
    }
}
