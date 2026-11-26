// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day's score (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1 item 5), one pure function
//          and its two halves. Try points: 1000 for a make on the first try, then 800, 600, 400 and 200 for the fifth;
//          nothing without a make. Precision points, only on the try that made it: 199 minus the distance from the white
//          ball's resting place to the mark, counted in whole half-centimetres (rounded down), never below zero. So the
//          best score is 1199. Ties are left to the board.
//          Read by DailyMode (after a make) and the tests (DailyScoreTests).
// SRP/DRY check: Pass - arithmetic only; whether a try made it is TrickShotJudge's, the distance DailyMode's.
import Foundation

enum DailyScore {
    /// Try points by the try that made it, first to fifth.
    static let pointsByTry = [1000, 800, 600, 400, 200]
    /// Precision points for a white ball resting exactly on the mark.
    static let precisionMaximum = 199
    /// One step of precision: half a centimetre, in metres.
    static let precisionStep = 0.005
    /// The best score there is: a first-try make that stops on the mark.
    static var maximum: Int { pointsByTry[0] + precisionMaximum }

    /// Try points for a make on `attempt` (1 to 5); 0 for no make or a try number outside the five.
    static func tryPoints(madeOnTry attempt: Int?) -> Int {
        guard let attempt, attempt >= 1, attempt <= pointsByTry.count else { return 0 }
        return pointsByTry[attempt - 1]
    }

    /// Precision points for a resting place `distance` metres from the mark. A distance that cannot be measured (not a
    /// number, or no mark to measure from: pass .infinity) earns none; a negative one is treated as on the mark.
    static func precisionPoints(distance: Double) -> Int {
        guard distance.isFinite else { return 0 }
        let steps = (max(0, distance) / precisionStep).rounded(.down)
        // Compared as a Double first, so a huge distance never overflows the Int conversion.
        guard steps < Double(precisionMaximum) else { return 0 }
        return precisionMaximum - Int(steps)
    }

    /// The day's score: try points plus precision points, both only for a make; 0 when the day was never made.
    static func score(madeOnTry attempt: Int?, distance: Double) -> Int {
        guard tryPoints(madeOnTry: attempt) > 0 else { return 0 }
        return tryPoints(madeOnTry: attempt) + precisionPoints(distance: distance)
    }
}
