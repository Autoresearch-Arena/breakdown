// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The what-if replay's words (spec 4.3; plans/22-Nov-2026-v075-whatif-and-gaps-plan.md stream whatif item 4):
//          at most four plain sentences about the other future, each a whole String(localized:) sentence so translators
//          can reorder it, with every number formatted for the player's language and passed in as text.
//            1. the change ("This version is aimed 0.25 degrees further left."), or the list of changes, and when the
//               other future's cue had to rise to clear a ball, which ball;
//            2. what happened differently at the hit, from TimelineFork's departure (the struck ball leaves further left
//               or right, faster or slower, or the cue ball comes off wider or narrower), or which ball the cue ball now
//               meets first, misses or reaches;
//            3. the outcome, from the retry comparison of the two attempts (which balls now drop or stay out, where the
//               cue ball stops, or "Same result" when nothing that matters moved);
//            4. for an aim or side change only, how a few millimetres at the first hit grew into centimetres at the
//               finish, when the gap grew more than tenfold.
//          Plus the trick-shot verdict line, the several-changes line, the card's fixed line and each control's short
//          offset readout ("0.25° left", "10% harder"). The words describe the other future as "this version": nothing
//          here says a second try was played (ShotComparison.describe's "This time / Last time" wording is not reused).
//          Ball names come from TableWords.ballName with the attempt's table; left and right follow ShotComparison
//          (anticlockwise on the table plan is the shooter's left). Read by WhatIfViews (the card) and WhatIfFork (the
//          spoken outcome line).
// SRP/DRY check: Pass - checked ShotComparison (its landmark and list are reused; describe is not), RetryWords (the
//          retry card's one sentence about a second try), TableWords.ballName (ball names) and CueAngleMenu.words (the
//          cue angle readout); the what-if's own sentences exist nowhere else.
import BreakdownLensModel
import BreakdownTimeline
import Foundation

@MainActor
enum WhatIfWords {
    // MARK: Fixed lines

    static var title: String { String(localized: "What if") }
    /// Under the card's title.
    static func fixedLine(changes: Int) -> String {
        changes > 1 ? String(localized: "Same stroke, more than one setting changed.")
                    : String(localized: "Same stroke, one setting changed.")
    }
    static var prompt: String { String(localized: "Move one setting to see the other future.") }
    static var tooLong: String { String(localized: "This version runs too long to show.") }
    static var several: String { String(localized: "With more than one change, this can't say which one did it.") }
    static var working: String { String(localized: "Working out the other future") }

    // MARK: Numbers in the player's language

    private static func number(_ x: Double, digits: ClosedRange<Int>) -> String {
        x.formatted(.number.precision(.fractionLength(digits)))
    }

    /// A ball inside a sentence, named the way the attempt's table names it.
    private static func name(_ ball: Int, _ a: ShotAttempt) -> String {
        TableWords.ballName(ball, cueBall: a.cueBall, table: a.table)
    }

    private static func names(_ balls: [Int], _ a: ShotAttempt) -> String {
        ShotComparison.list(balls.map { name($0, a) })
    }

    /// Percent of the power range between two powers (the bar's own scale, so "10% harder" is a tenth of the bar).
    private static func powerPercent(_ before: Double, _ after: Double, range: ClosedRange<Double>) -> Double {
        let width = range.upperBound - range.lowerBound
        return width > 0 ? abs(after - before) / width * 100 : 0
    }

    // MARK: The control names and readouts

    /// The control's name on the card and to VoiceOver.
    static func label(_ c: WhatIfFork.Control) -> String {
        switch c {
        case .aim: return String(localized: "Aim")
        case .power: return String(localized: "Power")
        case .tipUp: return String(localized: "Follow or draw")
        case .tipSide: return String(localized: "Side")
        case .elevation: return String(localized: "Cue angle")
        }
    }

    static func sectionLabel(_ s: WhatIfFork.Section) -> String {
        switch s {
        case .aim: return String(localized: "Aim")
        case .power: return String(localized: "Power")
        case .spin: return String(localized: "Spin")
        case .cueAngle: return String(localized: "Cue angle")
        }
    }

    /// The control inside a list of changes ("This version changes the aim and the power.").
    private static func listName(_ c: WhatIfFork.Control) -> String {
        switch c {
        case .aim: return String(localized: "the aim")
        case .power: return String(localized: "the power")
        case .tipUp: return String(localized: "the follow or draw")
        case .tipSide: return String(localized: "the side spin")
        case .elevation: return String(localized: "the cue angle")
        }
    }

    /// The short offset beside a control: how far it is from the real shot ("0.25° left", "10% harder", "2.5 mm lower",
    /// "30° up"), or "As played" at the real setting.
    static func readout(_ c: WhatIfFork.Control, real: ShotAttempt, value: Double) -> String {
        let before = real.value(of: c.comparison)
        if c == .elevation {
            return CueAngleMenu.words(degrees: Double(CueAngleMenu.nearestAngle(toSine: value)))
        }
        guard value != before else { return String(localized: "As played") }
        let d = value - before
        switch c {
        case .aim:
            let deg = number(abs(d), digits: 0...2)
            return d > 0 ? String(localized: "\(deg)° left") : String(localized: "\(deg)° right")
        case .power:
            let pct = (powerPercent(before, value, range: real.powerRange) / 100)
                .formatted(.percent.precision(.fractionLength(0)))
            return d > 0 ? String(localized: "\(pct) harder") : String(localized: "\(pct) softer")
        case .tipUp:
            let mm = number(abs(d) * 1000, digits: 0...1)
            return d > 0 ? String(localized: "\(mm) mm higher") : String(localized: "\(mm) mm lower")
        case .tipSide:
            let mm = number(abs(d) * 1000, digits: 0...1)
            return d > 0 ? String(localized: "\(mm) mm right") : String(localized: "\(mm) mm left")
        case .elevation:
            return ""
        }
    }

    // MARK: Line 1, the change

    /// One sentence naming the one change, or the list of changes; with the ball the cue rose to clear.
    static func change(_ r: WhatIfFork.Result, real: ShotAttempt) -> [String] {
        let nudged = r.steps.nudged
        let alt = r.alternate
        var out: [String] = []
        if nudged.count == 1, let c = nudged.first {
            let before = real.value(of: c.comparison), after = alt.value(of: c.comparison)
            let d = after - before
            switch c {
            case .aim:
                let deg = number(abs(d), digits: 0...2)
                out.append(d > 0 ? String(localized: "This version is aimed \(deg) degrees further left.")
                                 : String(localized: "This version is aimed \(deg) degrees further right."))
            case .power:
                let pct = number(powerPercent(before, after, range: real.powerRange), digits: 0...0)
                out.append(d > 0 ? String(localized: "This version is struck \(pct) percent harder.")
                                 : String(localized: "This version is struck \(pct) percent softer."))
            case .tipUp:
                let mm = number(abs(d) * 1000, digits: 0...1)
                out.append(d < 0
                    ? String(localized: "This version strikes \(mm) millimetres lower on the cue ball, for more draw.")
                    : String(localized: "This version strikes \(mm) millimetres higher on the cue ball, for more follow."))
            case .tipSide:
                let mm = number(abs(d) * 1000, digits: 0...1)
                out.append(d < 0
                    ? String(localized: "This version strikes \(mm) millimetres further left on the cue ball.")
                    : String(localized: "This version strikes \(mm) millimetres further right on the cue ball."))
            case .elevation:
                let angle = CueAngleMenu.nearestAngle(toSine: after)
                if angle == 0 {
                    out.append(String(localized: "This version strikes with a level cue."))
                } else {
                    let deg = Double(angle).formatted(.number.precision(.fractionLength(0)))
                    out.append(d > 0 ? String(localized: "This version raises the cue to \(deg) degrees.")
                                     : String(localized: "This version lowers the cue to \(deg) degrees."))
                }
            }
        } else if nudged.count > 1 {
            out.append(String(localized: "This version changes \(ShotComparison.list(nudged.map(listName)))."))
        }
        if let b = r.raisedOver {
            out.append(String(localized: "The cue had to rise to clear \(name(b, real))."))
        }
        return out
    }

    // MARK: Line 2, at the hit

    /// Hit-level degrees and speeds smaller than these are not worth a sentence: a tenth of a degree, two centimetres a
    /// second.
    static let turnWorthSaying = 0.1
    static let speedWorthSaying = 0.02

    /// What happened differently at the cue ball's first contact, or which ball it now meets first; nil when nothing
    /// at the hit is worth saying.
    static func atTheHit(_ r: WhatIfFork.Result, real: ShotAttempt) -> String? {
        let alt = r.alternate
        let striker = name(real.cueBall, real)
        let before = real.facts.firstContact?.ball, after = alt.facts.firstContact?.ball
        switch (before, after) {
        case (nil, nil):
            return nil
        case (let b?, nil):
            return String(localized: "In this version \(striker) misses \(name(b, real)).")
        case (nil, let a?):
            return String(localized: "In this version \(striker) reaches \(name(a, real)).")
        case (let b?, let a?) where b != a:
            return String(localized: "In this version \(striker) meets \(name(a, real)) first, not \(name(b, real)).")
        default:
            break
        }
        guard let d = r.fork.departure else { return nil }
        let object = name(d.objectBall, real)
        if abs(d.objectTurn) >= turnWorthSaying {
            let deg = number(abs(d.objectTurn), digits: 1...1)
            return d.objectTurn > 0 ? String(localized: "At the hit, \(object) leaves \(deg) degrees further left.")
                                    : String(localized: "At the hit, \(object) leaves \(deg) degrees further right.")
        }
        if abs(d.objectSpeedChange) >= speedWorthSaying {
            let v = number(abs(d.objectSpeedChange), digits: 2...2)
            return d.objectSpeedChange > 0
                ? String(localized: "At the hit, \(object) leaves \(v) metres per second faster.")
                : String(localized: "At the hit, \(object) leaves \(v) metres per second slower.")
        }
        if abs(d.strikerSpreadChange) >= turnWorthSaying {
            let deg = number(abs(d.strikerSpreadChange), digits: 1...1)
            return d.strikerSpreadChange > 0
                ? String(localized: "After the hit, \(striker) comes off \(deg) degrees wider.")
                : String(localized: "After the hit, \(striker) comes off \(deg) degrees narrower.")
        }
        return nil
    }

    // MARK: Line 3, the outcome

    /// Which balls now drop or stay out, where the cue ball stops, or "Same result". Never empty.
    static func outcome(_ r: WhatIfFork.Result, real: ShotAttempt) -> String {
        let c = r.comparison, alt = r.alternate
        let before = Set(c.pottedBefore), after = Set(c.pottedNow)
        let gained = after.subtracting(before).sorted(), lost = before.subtracting(after).sorted()
        // One ball or several: whole sentences each, so every language can agree its verb with the subject.
        if !gained.isEmpty && lost.isEmpty {
            return gained.count == 1 ? String(localized: "This time \(names(gained, real)) drops.")
                                     : String(localized: "This time \(names(gained, real)) drop.")
        }
        if gained.isEmpty && !lost.isEmpty {
            return lost.count == 1 ? String(localized: "This time \(names(lost, real)) stays out.")
                                   : String(localized: "This time \(names(lost, real)) stay out.")
        }
        if !gained.isEmpty {
            return gained.count == 1
                ? String(localized: "This time \(names(gained, real)) drops instead of \(names(lost, real)).")
                : String(localized: "This time \(names(gained, real)) drop instead of \(names(lost, real)).")
        }
        let striker = name(real.cueBall, real)
        if real.cueBallScratched != alt.cueBallScratched {
            return alt.cueBallScratched ? String(localized: "This time \(striker) drops.")
                                        : String(localized: "This time \(striker) stays out.")
        }
        guard let shift = c.cueBallFinishShift, shift > RetryComparison.nearSameSpot else {
            return String(localized: "Same result: the shot has room for a change this size.")
        }
        // Where it stops, in a player's words, on the pool table (the landmarks are its pockets and ends).
        if real.table == .standard {
            let table = real.timeline.table
            let here = ShotComparison.landmark(alt.cueRest, table)
            if here != ShotComparison.landmark(real.cueRest, table) {
                return String(localized: "This time \(striker) stops \(here).")
            }
        }
        let cm = number(shift * 100, digits: 0...0)
        return String(localized: "The result is the same, but \(striker) stops \(cm) centimetres away.")
    }

    // MARK: Line 4, a small change grows

    /// For an aim or side change: "At the first hit the two cue balls were 3 millimetres apart; they stop 40
    /// centimetres apart." Only on the pool table, with a shared first contact, when the gap grew more than tenfold.
    static func growth(_ r: WhatIfFork.Result, real: ShotAttempt) -> String? {
        guard real.table == .standard, r.steps.nudged == [.aim] || r.steps.nudged == [.tipSide],
              r.fork.departure != nil, let gap = r.fork.firstContactGap, gap >= 0.0001,
              r.fork.finishGap > 10 * gap else { return nil }
        let mm = (gap * 1000).formatted(.number.precision(.significantDigits(1...2)))
        let cm = number(r.fork.finishGap * 100, digits: 0...0)
        return String(localized: "At the first hit the two cue balls were \(mm) millimetres apart; they stop \(cm) centimetres apart.")
    }

    // MARK: The trick verdict

    static func verdict(_ r: WhatIfFork.Result) -> String? {
        guard let passes = r.passes else { return nil }
        if passes { return String(localized: "This version makes the shot.") }
        return r.realPasses == true ? String(localized: "This version misses the shot.")
                                    : String(localized: "This version still misses.")
    }

    // MARK: All of it

    /// The card's sentences in order: the change, the hit, the outcome, the growth, the verdict, and the several-
    /// changes line. At most four about the shot itself.
    static func sentences(_ r: WhatIfFork.Result, real: ShotAttempt) -> [String] {
        var out = change(r, real: real)
        if let hit = atTheHit(r, real: real) { out.append(hit) }
        out.append(outcome(r, real: real))
        if let g = growth(r, real: real) { out.append(g) }
        if let v = verdict(r) { out.append(v) }
        if case .severalChanges = r.comparison.key { out.append(several) }
        return out
    }
}
