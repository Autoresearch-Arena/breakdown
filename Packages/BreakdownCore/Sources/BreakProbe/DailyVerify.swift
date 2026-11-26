// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The Shot of the day bank's part of "BreakProbe verify" (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1
//          item 8). Plays every entry of AuthoredDaily exactly as the app carries it: its own layout and answer, on its
//          own surface (the cloth's numbers written into the chosen physics generation, as EBSituationSpec.parameters
//          does for the escapes), seed 1, judged with trickFailure, the test the trick shots were authored against and
//          the goal the app's TrickShotJudge applies. A side-spin entry's answer must also keep its strong-side rule.
//          The bank as a whole must hold together: ids unique, no two neighbours of the same family (the last and the
//          first included, since the list wraps), and every window wide enough to divide by (the judge's advice ranks
//          each setting's miss against its window).
//          For each entry it also prints where the answer leaves the white ball and, when the entry writes a mark, how
//          far that resting place is from it: an entry with no written mark is scored against that very resting place
//          in the app (DailyShot.answerRest), so these lines are what a later authoring pass writes in as marks.
//          Returns the number of failures; ContentVerify.runContentVerify adds them to its own and its exit status.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: each entry is played on its own table as well as its
//          surface; the bank must hold the weekly rhythm (a whole number of weeks, each day's kind of shot, a mark on
//          every entry, a leave ball on the table), and every answer must still stop within a centimetre of its mark.)
// SRP/DRY check: Pass - reuses simulate, probeStrike, probeGoal, trickFailure and generationParameters (TrickSearch and
//          ContentVerify); the bank's numbers are the package library's (AuthoredDaily), never copied here.
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// An entry's physics: the chosen generation with the entry's own table, then its own cloth, written in (0.7.10 bank:
/// the table first, the app's ShowpieceModel.solverCopy order).
func dailyParameters(_ e: AuthoredDailyShot, generation: Int) -> PoolParameters {
    var p = generationParameters(generation)
    e.table.apply(to: &p)
    e.surface.apply(to: &p)
    return p
}

/// What is wrong with the bank as a list (not any one answer): duplicate ids, neighbours of one family, a window of
/// zero. Empty when it holds together.
func dailyBankProblems(_ bank: [AuthoredDailyShot]) -> [String] {
    var out: [String] = []
    var seen = Set<String>()
    for e in bank where !seen.insert(e.id).inserted { out.append("the id \(e.id) is used twice") }
    if bank.count > 1 {
        for i in bank.indices {
            let next = bank[(i + 1) % bank.count]
            if bank[i].family == next.family {
                out.append("\(bank[i].id) and \(next.id) are neighbours of one family (\(next.family.rawValue))")
            }
        }
    }
    for e in bank where !(e.window.aim > 0 && e.window.power > 0 && e.window.tipUp > 0) {
        out.append("\(e.id): a window of zero for aim, power or tip height")
    }
    // 0.7.10 bank: the weekly rhythm. A whole number of weeks, so it holds when the list wraps; every place on its day's
    // kind of shot (AuthoredDaily.fits); every entry with a mark; a leave ball that is really on the table.
    if bank.count % 7 != 0 { out.append("the bank holds \(bank.count) shots, not a whole number of weeks") }
    for (i, e) in bank.enumerated() {
        let day = AuthoredDaily.weekday(ofIndex: i)
        if !AuthoredDaily.fits(e, on: day) {
            out.append("\(e.id) (day \(i + 1), a \(day)) does not fit its day: \(e.family.rawValue) on \(e.table.rawValue), \(e.surface.rawValue)")
        }
        if e.mark == nil { out.append("\(e.id): no mark") }
        if let l = e.leave, !(e.layout.indices.contains(l) && NextShot.isOnTable(e.layout[l])) {
            out.append("\(e.id): its leave ball \(l) is not on the table")
        }
    }
    return out
}

/// Plays every daily entry on `generation`; prints a line each and returns how many failed.
func runDailyVerify(generation: Int) -> Int {
    let bank = AuthoredDaily.all
    print("== the shot of the day bank (\(bank.count) shots)")
    struct Row: Sendable { let why: String?; let rest: Vec2?; let markGap: Double? }
    let rows = parallelMap(bank.count) { i -> Row in
        let e = bank[i]
        let tl = simulate(e.layout, probeStrike(e.answer), parameters: dailyParameters(e, generation: generation))
        // Where the answer leaves the white ball (nil when it dropped, which trickFailure reports as a scratch).
        let rest: Vec2? = tl.pocketTime[0] == nil ? tl.state(ball: 0, at: tl.duration).position : nil
        var gap: Double? = nil
        if let r = rest, let m = e.mark { gap = (r - m).length }
        if let why = trickFailure(probeGoal(e.goal), tl) { return Row(why: why, rest: rest, markGap: gap) }
        // The strong-side rule (the app's TrickShotJudge checks it from the stroke): the answer must keep it.
        if let need = e.strongSide, !(e.answer.tipSide * need > 0 && abs(e.answer.tipSide) >= abs(need) - 1e-6) {
            return Row(why: "the answer breaks its own strong-side rule", rest: rest, markGap: gap)
        }
        return Row(why: nil, rest: rest, markGap: gap)
    }
    var failures = 0
    for (e, row) in zip(bank, rows) {
        var place = row.rest.map { String(format: "; the white ball rests at (%.4f, %.4f)", $0.x, $0.y) } ?? ""
        if let gap = row.markGap { place += String(format: ", %.1f cm from the written mark", gap * 100) }
        else if e.mark == nil { place += " (no written mark: the app scores against this resting place)" }
        // 0.7.10 bank: every mark is the answer's own resting place (Stop Dead's is its circle's centre), so the answer
        // must still stop within a centimetre of it; further means the physics moved and the mark wants writing again.
        var why = row.why
        if why == nil, let gap = row.markGap, gap > 0.01 {
            why = String(format: "the answer now stops %.1f cm from its mark", gap * 100)
        }
        if let why { failures += 1; print("FAIL daily \(e.id): \(why)\(place)") }
        else { print("PASS daily \(e.id)\(place)") }
    }
    for problem in dailyBankProblems(bank) {
        failures += 1
        print("FAIL daily bank: \(problem)")
    }
    return failures
}
