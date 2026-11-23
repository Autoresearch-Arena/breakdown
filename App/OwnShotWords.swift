// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, new file 4): every word of the feature in
//          one place. The buttons (Make it again, Play it now, their Mac menu forms), their VoiceOver hints, the shelf's
//          title and footers, a row's status lines, Rename and Delete with the delete question, the controller mapping
//          row, and the challenge's own words: the goal in a sentence that names every ball and pocket ("Pot the 3
//          into the foot-left corner pocket and the 6 into the left side pocket. Touch the 3 first."), the card's
//          first line, the idea (the highlight's physics line for a named kind, else a plain one), the praise, and the
//          default name. Every line is a whole sentence or a whole label in the string catalog
//          (String(localized:comment:)), never glued from halves; lists are joined by the system's list format in the
//          game's own language (AppLocale.numbers). The player's own names are shown as typed and never looked up.
//          Plain (nonisolated) so OwnShot's pure functions and the controller's nonisolated mapping can read it.
//          No people, brands or sources: physics words and plain shot names only.
// SRP/DRY check: Pass - reuses the catalog's existing words rather than adding copies: "the %lld" (MatchWords),
//          TableGameWords.ball for the small tables' balls, TableWords.holePhrase for pockets and bed holes,
//          HighlightWords' titles and lines for named kinds, PlaySurface.title, TableKind.title and "Cancel". Only the
//          words this feature is the first to say are new.
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

enum OwnShotWords {
    // MARK: Buttons and hints

    static var makeItAgain: String {
        String(localized: "Make it again", comment: "Button: saves the shot just played as the player's own challenge. Short.")
    }
    static var playItNow: String {
        String(localized: "Play it now", comment: "Button: sets up the shot the player just saved. Short.")
    }
    static var makeItAgainMac: String {
        String(localized: "Make It Again", comment: "Mac Playback menu item, title case.")
    }
    static var playItNowMac: String {
        String(localized: "Play It Now", comment: "Mac Playback menu item, title case.")
    }
    static var saveHint: String {
        String(localized: "Saves the balls as they stood before this shot as a challenge of your own, in Trick shots.",
               comment: "VoiceOver hint.")
    }
    static var playHint: String {
        String(localized: "Sets up your saved shot so you can make it again.", comment: "VoiceOver hint.")
    }
    static var fullHint: String {
        String(localized: "Your shots is full. Delete one in Trick shots to save another.",
               comment: "Hint on a disabled button. \"Your shots\" is the shelf's name.")
    }
    static var savedAnnouncement: String {
        String(localized: "Saved to Your shots, in Trick shots.", comment: "Spoken to VoiceOver after saving.")
    }

    // MARK: The shelf

    static var shelfTitle: String {
        String(localized: "Your shots", comment: "Section title in the Trick shots list: challenges the player saved.")
    }
    static var emptyFooter: String {
        String(localized: "After a shot that drops a ball, Make it again keeps it here as a challenge of your own.",
               comment: "Footer of an empty section.")
    }
    static var footer: String {
        String(localized: "The game kept your stroke, so Watch it plays the way it went.",
               comment: "Section footer. \"Watch it\" is the trick card's button.")
    }
    static var madeAgain: String { String(localized: "Made again", comment: "Row status.") }
    static var notMadeYet: String { String(localized: "Not made again yet", comment: "Row status.") }
    static var checking: String {
        String(localized: "Checking the saved stroke…",
               comment: "Row status while the game replays the stroke in the background.")
    }
    static var changed: String {
        String(localized: "The saved stroke no longer makes it in this version. The shot may still be possible.",
               comment: "Row and card note after a physics update.")
    }
    static var unplayable: String {
        String(localized: "This version cannot set up this shot.",
               comment: "Row note for a shot saved on a table this version lacks.")
    }
    static var rename: String { String(localized: "Rename", comment: "Row action.") }
    static var delete: String { String(localized: "Delete", comment: "Row action.") }
    static var nameField: String {
        String(localized: "Name", comment: "Text field placeholder when renaming a saved shot.")
    }
    static var save: String { String(localized: "Save", comment: "Confirms a rename.") }
    /// The catalog's existing "Cancel" (no new key).
    static var cancel: String { String(localized: "Cancel") }
    static var deleteQuestion: String {
        String(localized: "Delete this shot?", comment: "Question shown inside the row before a saved shot is deleted.")
    }
    static var deleteDetail: String {
        String(localized: "It is removed from Your shots for good.", comment: "Line under that question, inside the row.")
    }
    static func options(_ name: String) -> String {
        String(localized: "Options for \(name)",
               comment: "VoiceOver label of a row's options button; %@ is the shot's name.")
    }

    // MARK: The challenge

    static var praise: String {
        String(localized: "Made it again: the same balls in the same pockets.",
               comment: "Shown when the player makes their saved shot.")
    }
    static var plainIdea: String {
        String(localized: "Same start, same stroke, same result: there is no luck in the physics, so your own stroke is the answer.",
               comment: "The idea line for a saved shot that was not a named kind.")
    }
    static var origin: String {
        String(localized: "Your own shot, saved from free play.", comment: "First sentence on a saved shot's card.")
    }

    /// The highlight's title for a named kind ("A bank shot"), else "Saved shot" and its number.
    static func defaultName(kind: HighlightKind?, number: Int) -> String {
        if let kind { return HighlightWords.title(kind) }
        return String(localized: "Saved shot \(number)", comment: "Default name of a saved shot; %lld counts saved shots.")
    }

    /// One ball inside a sentence, as that table's own words name it: "the 3" on the pool table; the small tables'
    /// colours (bumper pool's marked white, bar billiards' red or a white, five-pin's white, yellow and red).
    static func ball(_ b: Int, table: TableKind) -> String {
        switch table {
        case .standard: return String(localized: "the \(b)")
        case .bumperPool: return TableGameWords.ball(b, kind: .bumperPool)
        case .barBilliards: return TableGameWords.ball(b, kind: .barBilliards)
        case .fivePin: return TableGameWords.ball(b, kind: .fivePin)
        }
    }

    /// One ball and the pocket or hole it must drop into: "the 3 into the foot-left corner pocket".
    static func into(_ d: OwnDrop, table: TableKind) -> String {
        let hole = TableWords.holePhrase(d.pocket, table: table.parameters.tableSpec, kind: table)
        return String(localized: "\(ball(d.ball, table: table)) into \(hole)",
                      comment: "One ball and the pocket or hole it must drop into, e.g. \"the 3 into the foot-left corner pocket\". Items are joined into a list. Translations may reorder with %1$@ / %2$@.")
    }

    /// The goal in words, every pocket named so nothing depends on seeing the rings: which balls into which pockets,
    /// the ball to touch first (unless it is the one ball potted, when saying it adds nothing), and the bank.
    static func goalLine(_ own: OwnShot) -> String {
        let table = own.table ?? .standard
        let list = own.drops.map { into($0, table: table) }.formatted(.list(type: .and).locale(AppLocale.numbers))
        var sentences = [String(localized: "Pot \(list).",
                                comment: "%@ is a list such as \"the 3 into the foot-left corner pocket and the 6 into the left side pocket\".")]
        if let first = own.firstHit, !(own.drops.count == 1 && own.drops[0].ball == first) {
            sentences.append(String(localized: "Touch \(ball(first, table: table)) first.",
                                    comment: "%@ is a ball, e.g. \"the 3\": the cue ball must touch it first."))
        }
        if let bank = own.bank {
            let line = String(localized: "\(ball(bank, table: table)) must come off a cushion on the way.",
                              comment: "%@ is a ball, e.g. \"the 6\": it must bank in. Sentence start; capitalise as the language needs.")
            sentences.append(capitalised(line))
        }
        return sentences.joined(separator: " ")
    }

    /// The card's first line: where the shot came from, then the goal.
    static func hook(_ own: OwnShot) -> String { origin + " " + goalLine(own) }

    /// The one idea: the named kind's physics line ("The ball left the cushion at its mirror angle, into the pocket."),
    /// else the plain line.
    static func idea(_ own: OwnShot) -> String { own.kind.map(HighlightWords.line) ?? plainIdea }

    /// The cloth and the table when they are not the defaults ("Surface: Ice · Table: Bumper pool"), else nil.
    static func detail(_ own: OwnShot) -> String? {
        var parts: [String] = []
        if let s = own.surface, s != .cloth {
            parts.append(String(localized: "Surface: \(s.title)", comment: "Detail line; %@ is a playing surface name."))
        }
        if let t = own.table, t != .standard {
            parts.append(String(localized: "Table: \(t.title)", comment: "Detail line; %@ is a table name."))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The line a row shows under its goal about its saved stroke this run, or nil when there is nothing to say.
    static func proofLine(_ own: OwnShot, proof: OwnShotCheck?) -> String? {
        if own.trickShot == nil { return unplayable }
        switch proof {
        case .checking?: return checking
        case .changed?: return changed
        case .holds?, nil: return nil
        }
    }

    /// A shelf row read as one element: the name, the goal, made again or not, the cloth and table when not the
    /// defaults, and the stroke's note. One line each, so VoiceOver pauses between them (the name is not a sentence,
    /// so the parts are not glued with full stops).
    static func spokenRow(_ own: OwnShot, proof: OwnShotCheck?) -> String {
        var lines = [own.name, own.made ? madeAgain : notMadeYet, goalLine(own)]
        if let detail = detail(own) { lines.append(detail) }
        if let note = proofLine(own, proof: proof) { lines.append(note) }
        return lines.joined(separator: "\n")
    }

    // MARK: The controller

    static var leftStickControl: String { String(localized: "Left stick click", comment: "Controller mapping, How to play.") }
    static var leftStickAction: String {
        String(localized: "Saves the shot just played as a challenge of your own (Make it again), where the controller has this button.",
               comment: "Controller mapping, How to play.")
    }

    // MARK: Pieces

    /// The first letter in upper case, in the game's language: the bank sentence starts with a ball phrase that is
    /// lower case inside other sentences ("the 6").
    private static func capitalised(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased(with: AppLocale.numbers) + String(s.dropFirst())
    }
}
