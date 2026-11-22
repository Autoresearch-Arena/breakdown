// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The shared vocabulary of 0.7.4's "worth watching" moments (plans/22-Nov-2026-v074-glow-up-plan.md, F2):
//          the kinds of remarkable moment a shot can have, how strong each is, which are rare, which authored trick
//          shot teaches each, and one moment of a recording (its kind, the events a guided Lens replay holds on, and
//          the ball it is about). Frozen for the release: ShotHighlightJudge finds these, the model offers them, the
//          match card and the Table cleared card replay them, and TrickSignature uses the same event-index idea.
// SRP/DRY check: Pass - checked Captions (event indices are Caption.id there too), TrickShots (the trick ids named
//          here are its ids) and LensEvent (no kind of remarkable moment existed before). Types only, no logic.
import Foundation

/// The remarkable moments a shot can have, offered for a Lens replay. Raw values are stable keys.
enum HighlightKind: String, CaseIterable, Sendable {
    case breakShot, jump, curve, throwIn, combination, kick, bank, multiPot, drawBack, stopDead, rimSkip, bumperCup, redPinAlone

    /// Strength, for the best shot of a rack and for choosing between kinds in one shot: higher wins.
    var rank: Int {
        switch self {
        case .jump: return 12
        case .curve: return 11
        case .throwIn: return 10
        case .combination: return 9
        case .kick: return 8
        case .bumperCup, .redPinAlone: return 7
        case .bank: return 6
        case .multiPot: return 5
        case .drawBack: return 4
        case .stopDead: return 3
        case .rimSkip: return 2
        case .breakShot: return 1
        }
    }

    /// Rare kinds are offered every time they happen; the rest at most once per rack (free play) or match.
    var isRare: Bool { [.jump, .curve, .throwIn, .combination, .kick].contains(self) }

    /// The authored trick shot that teaches this kind, or nil.
    var trickID: String? {
        switch self {
        case .jump: return "jump-over"
        case .curve: return "masse-curve"
        case .throwIn: return "throw-it"
        case .combination: return "combo-chain"
        case .kick: return "two-rail-kick"
        case .bank: return "cross-bank"
        case .multiPot: return "follow-train"
        case .drawBack: return "bridge-draw"
        case .stopDead: return "stop-dead"
        case .breakShot, .rimSkip, .bumperCup, .redPinAlone: return nil
        }
    }
}

/// One remarkable moment of a recorded shot.
struct ShotHighlight: Equatable, Sendable {
    let kind: HighlightKind
    /// Indices into the recording's Timeline.events for the replay to hold on: clock order, at most two, each with a
    /// caption (Caption.id is the event index).
    let signatureEvents: [Int]
    /// The ball the moment is about (the close-up and the card's wording follow it).
    let ball: Int
}
