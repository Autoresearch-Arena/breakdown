// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: What the upright phone's title row says (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The title row"): the
//          first of Ride's status words while a ride speaks, the opening's status while the intro tells its story, the
//          match's turn and score, the trick shot's name with its difficulty after it in the secondary colour ("The
//          Called Break · Hard"), the lesson's name, the Behind the 8-Ball situation's name, or "Break" on a racked
//          table. Nil when there is nothing to name (the title slot is then empty). Words only; PhoneTitleRow draws them.
//          The match's line comes from PhoneTitle.match(_:), an extension written beside the match views (another
//          file), so this file never learns how a match is scored.
// SRP/DRY check: Pass - checked ShowpieceModel.stageTitle (the opening's status, reused as is), RideTitleChip (the
//          ride's words come from model.rideStatus, reused), TrickShotCard's and LessonCard's headers (their name and
//          difficulty strings are reused: TrickDifficulty.label and the existing "Lesson %lld: %@" key).
import Foundation

/// The title row's words. MainActor because it reads the model; the match extension inherits that.
@MainActor
enum PhoneTitle {
    /// One title: the main words and, optionally, a detail drawn after them in the secondary colour.
    struct Line: Equatable {
        let title: String
        var detail: String?
        /// Status words (Ride, the opening): read as a status, and not a button that opens the idea.
        var isStatus = false

        /// The whole line as VoiceOver reads it.
        var spoken: String { detail.map { "\(title), \($0)" } ?? title }
    }

    /// The line for the screen as it is now, or nil for an empty title.
    static func line(for model: ShowpieceModel) -> Line? {
        // A ride names its acts while it speaks (it replaces the title for those few seconds).
        if let status = model.rideStatus { return Line(title: status, isStatus: true) }
        // The opening's story ("The break", "Hold on", "Slow motion") while the intro runs.
        if model.stage != .explore && model.stage != .lead {
            let words = model.stageTitle
            if !words.isEmpty { return Line(title: words, isStatus: true) }
        }
        // A match: whose turn and the score (written beside the match views).
        if model.match != nil, let words = PhoneTitle.match(model) { return Line(title: words) }
        let trick = model.trickMode
        if trick.isActive, let shot = trick.current {
            return Line(title: shot.title, detail: shot.difficulty.label)
        }
        let lessons = model.lessonMode
        if lessons.isActive, let lesson = lessons.current {
            return Line(title: String(localized: "Lesson \(lesson.number): \(lesson.title)"))
        }
        let eightBall = model.eightBallMode
        if eightBall.isActive, let situation = eightBall.current { return Line(title: situation.title) }
        // A racked table waiting for its break: the first minute, and every fresh rack in free play.
        if model.racked { return Line(title: breakTitle) }
        return nil
    }

    /// "Break" as a title. Its own key: the same English word is the aiming panel's button, which may translate
    /// differently.
    static var breakTitle: String {
        String(localized: "Title: Break", defaultValue: "Break",
               comment: "Title row on the phone while a racked table waits for its break; one short word")
    }
}
