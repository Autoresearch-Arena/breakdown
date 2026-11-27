// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the thumb dock: the title row says only what
//          is being played (design language, "Upright iPhone": "never who is up or the score"). The first minute is
//          "Break" (wave 2 note 6: the hand-over too, as the notebook's top bar does), then the trick shot's, the
//          lesson's or the Behind the 8-ball situation's own name with no difficulty after it, the shot of the day's
//          title, the match's game ("Eight-ball"), or "Free play". Ride's status words, a frozen hit's words and the
//          opening's story moved to the dock's word strip (PhoneStatusWords, PhoneDock.swift); the match's turn and
//          score are the dock's scoreboard.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: a frozen
//          hit's status line, right after the ride's.)
// PURPOSE: What the upright phone's title row says (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The title row", and
//          plans/26-Nov-2026-ui-rethink-plan.md package 6): the name of the thing being played, one line. Words only;
//          PhoneTitleRow draws them. `isStatus` and `detail` are kept for callers (always false and nil now).
//          PhoneTitle.match(_:) (MatchPhoneBlurbs.swift) names the match's game.
// SRP/DRY check: Pass - checked NotebookPanel's top bar (the same order of cases, but it names the mode, "Trick shots",
//          where the phone names the item, as the design language's examples do), DailyShot.title, MatchWords.title and
//          ShotPanel.actionWord (Break); no new words but "Free play", which is the notebook's existing key.
import Foundation

/// The title row's words. MainActor because it reads the model; the match extension inherits that.
@MainActor
enum PhoneTitle {
    /// One title: the main words and, optionally, a detail drawn after them in the secondary colour.
    struct Line: Equatable {
        let title: String
        var detail: String?
        /// Status words: read as a status, and not a button that opens the idea. No longer produced (package 6).
        var isStatus = false

        /// The whole line as VoiceOver reads it.
        var spoken: String { detail.map { "\(title), \($0)" } ?? title }
    }

    /// The line for the screen as it is now: always a name.
    static func line(for model: ShowpieceModel) -> Line? {
        // The first minute, and the opening's story when it is watched again: "Break" on every device.
        if model.openingStage != .none || (model.stage != .explore && model.stage != .lead) {
            return Line(title: breakTitle)
        }
        if model.match != nil, let words = PhoneTitle.match(model) { return Line(title: words) }
        // 0.7.10 daily: played as a trick shot, named as itself.
        if DailyMode.showing(model) { return Line(title: DailyShot.title) }
        let trick = model.trickMode
        if trick.isActive, let shot = trick.current { return Line(title: shot.title) }
        let lessons = model.lessonMode
        if lessons.isActive, let lesson = lessons.current { return Line(title: lesson.title) }
        let eightBall = model.eightBallMode
        if eightBall.isActive, let situation = eightBall.current { return Line(title: situation.title) }
        return Line(title: String(localized: "Free play"))
    }

    /// "Break" as a title. Its own key: the same English word is the aiming panel's button, which may translate
    /// differently.
    static var breakTitle: String {
        String(localized: "Title: Break", defaultValue: "Break",
               comment: "Title row on the phone while a racked table waits for its break; one short word")
    }

    /// The title opens the idea (the trick's, the lesson's or the situation's story) in the dock's sheet when there is
    /// one to open.
    static func hasIdea(_ model: ShowpieceModel) -> Bool {
        model.openingStage == .none
            && (model.trickMode.isActive || model.lessonMode.isActive || model.eightBallMode.isActive)
    }
}
