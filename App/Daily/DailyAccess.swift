// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day for a player who does not see the screen or does not use touch
//          (plans/25-Nov-2026-everyone-can-play-plan.md, Parts B5 and D2):
//          - DailyWords.resultSpoken: the result as one sentence, said once when the day finishes (DailyMode.noteTry
//            hands it to ShotNarration, the game's one speaker, so it joins the shot's own summary instead of cutting
//            it off): made on which try, how far from the mark, the score and the streak. Built only from the result
//            card's own lines, so the spoken result and the card never disagree and no new sentence needs translating.
//          - DailyController: what a game controller's spare buttons do once the day is finished, so the shot can be
//            played from the menu row to a shared result with a controller alone: the Options button shares the
//            result, a press of the left stick opens the board (when the board is connected and not hidden). Read by
//            GameControllerInput; nothing here touches the controller itself.
// SRP/DRY check: Pass - checked DailyViews (DailyWords' lines, reused as they are; the card's Share and Board buttons
//          call the same DailyShare.share and DailyMode.openBoard), ControllerInput (its button map stays there; this
//          only answers what the two spare buttons mean on the shot of the day) and TableAccessLayer (ShotNarration).
import Foundation

extension DailyWords {
    /// The finished day in one sentence: "Made it on try 2. 4.5 cm from the mark. Score: 1103. Streak: 3."
    static func resultSpoken(_ day: DailyRecord.Day, streak: Int) -> String {
        var parts = [resultTitle(day)]
        if day.made, let d = day.distance { parts.append(fromMark(d) + ".") }
        parts.append(scoreSpoken(day.score) + ".")
        parts.append(streakSpoken(streak) + ".")
        return parts.joined(separator: " ")
    }
}

@MainActor
enum DailyController {
    /// True while the shot of the day is on the table and its day is finished: the result card is up, with Share and
    /// (when connected) Board.
    static func resultShowing(_ model: ShowpieceModel) -> Bool {
        DailyMode.showing(model) && model.dailyMode.finished
    }

    /// The Options button on the finished day: share the result, as the card's Share does. False when it is not the
    /// finished daily, so the button keeps its usual job.
    static func share(_ model: ShowpieceModel) -> Bool {
        guard resultShowing(model) else { return false }
        DailyShare.share(model: model)
        return true
    }

    /// A press of the left stick on the finished day: open the board, as the card's Board does. False when it is not
    /// the finished daily or the board is not there (not connected yet, or hidden), so the press keeps its usual job.
    static func board(_ model: ShowpieceModel) -> Bool {
        guard resultShowing(model), !GameSettings.boardHidden, let open = model.dailyMode.openBoard else { return false }
        open()
        return true
    }
}
