// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The words of 0.7.4's "worth watching" invitation (plans/22-Nov-2026-v074-glow-up-plan.md, stream
//          watch-invite, G3 and G4): for each remarkable kind of shot (HighlightKind) a short title that names it and
//          one line that names the physics, in generic terms only (no people, brands or sources, and no praise: naming
//          the physics is the praise). Also the hint under "Watch it in the Lens", "Watch your best shot" on the Table
//          cleared card, and the line on the card at the end of Watch the intro. Read by HighlightCard and IntroEndCard
//          (FreePlayViews.swift), TableClearedCard and the match card's Lens offer (MatchViews.swift).
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 9's leftover note: the Lens is named by its one
//          name, "Physics Lens", where a player reads it.)
// SRP/DRY check: Pass - checked MatchWords, OpponentWords, TableGameWords and CaptionEngine (none names a kind of
//          remarkable shot; the captions explain single events, these name the whole moment). Strings only, all through
//          String(localized:), so Xcode extracts them; the existing "Watch it in the Lens", "Try the trick shot",
//          "Close", "Trick shots", "Practice" and "Table cleared" keys are reused by the views, not repeated here.
import Foundation

enum HighlightWords {
    /// The card's title: what kind of shot it was.
    static func title(_ k: HighlightKind) -> String {
        switch k {
        case .breakShot: return String(localized: "Your break")
        case .jump: return String(localized: "The cue ball jumped")
        case .curve: return String(localized: "The path curved")
        case .throwIn: return String(localized: "Thrown in")
        case .combination: return String(localized: "A combination")
        case .kick: return String(localized: "A kick")
        case .bank: return String(localized: "A bank shot")
        case .multiPot: return String(localized: "Two at once")
        case .drawBack: return String(localized: "Drawn back")
        case .stopDead: return String(localized: "Stopped dead")
        case .rimSkip: return String(localized: "Too fast for the pocket")
        case .bumperCup: return String(localized: "Off a bumper")
        case .redPinAlone: return String(localized: "The red pin alone")
        }
    }

    /// The card's line: the physics that made the moment, in one sentence.
    static func line(_ k: HighlightKind) -> String {
        switch k {
        case .breakShot:
            return String(localized: "Watch the cue ball hand its speed to the rack, ball to ball.")
        case .jump:
            return String(localized: "A downward hit bounced it off the slate and over the ball in the way.")
        case .curve:
            return String(localized: "While the ball slid, the cloth pulled it along the slip of its spin, not along its motion.")
        case .throwIn:
            return String(localized: "Friction at the contact dragged the ball off the line of centres.")
        case .combination:
            return String(localized: "One ball passed its speed through another, along the line of centres.")
        case .kick:
            return String(localized: "The cue ball found its ball off the cushion, like light off a mirror.")
        case .bank:
            return String(localized: "The ball left the cushion at its mirror angle, into the pocket.")
        case .multiPot:
            return String(localized: "One stroke, more than one ball down.")
        case .drawBack:
            return String(localized: "Backspin outlasted the hit and pulled the cue ball back.")
        case .stopDead:
            return String(localized: "The spin ran out exactly at contact, so all the speed went on.")
        case .rimSkip:
            return String(localized: "The ball crossed the hole faster than it could fall in.")
        case .bumperCup:
            return String(localized: "A bumper turned the ball into the cup.")
        case .redPinAlone:
            return String(localized: "Only the red pin fell.")
        }
    }

    /// VoiceOver's hint on "Watch it in the Lens" for a shot (the break keeps its own existing hint).
    static var watchHint: String { String(localized: "Replays the shot slowly with the physics drawn on the table") }

    /// The Table cleared card's button that replays the rack's best remarkable shot.
    static var watchBest: String { String(localized: "Watch your best shot") }

    /// The card at the end of Watch the intro, above Trick shots and Practice.
    static var introEnd: String { String(localized: "Every trick shot can be watched like this: the answer, then the Physics Lens.") }
}
