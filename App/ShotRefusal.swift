// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Why the game refused a stroke (plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 2 and 13; contract
//          docs/v07-contracts.md section 1.1). Before 0.7.0 a refused stroke simply did nothing: the contact click played,
//          nothing was struck and nothing said why. Every place that refuses a stroke now names its reason with one of
//          these codes; the model keeps the last one (ShowpieceModel.lastRefusal) and the shot card shows its one-line
//          sentence. Each case below names the guard in today's code that refuses for that reason, so the list matches
//          the code rather than a guess. Pure value type: no state, no isolation, safe from any thread.
//          Strings: every sentence goes through String(localized:) (localization/pending/v07-base.json).
// SRP/DRY check: Pass - checked ShowpieceModel.fire/breakNow/shootNow, MatchMode.readyToShoot, StrokeGesture.begin and
//          StrokeTracker (the guards named below); nothing else in the app names a refusal. The card that shows the
//          sentence is the menu stream's (ShotPanel); the model only stores the code.
import Foundation

enum ShotRefusal: String, CaseIterable, Sendable {
    /// Eight-ball after the break with no call made and no suggestion to fall back on (MatchMode.readyToShoot:
    /// `!mustCall || currentCall != nil`). With a suggestion the model plays it instead of refusing (item 13).
    case noCall
    /// The finger pushed forward before drawing the cue back far enough (StrokeTracker.minimumBackswing; item 2 makes
    /// the push wait for a real backswing).
    case backswingTooShort
    /// A lifted ball sits where it may not go, so it cannot be put down before the strike (ShowpieceModel.fire:
    /// `placingCueBall, !confirmCueBallPlacement()`).
    case ballInHandNotPlaced
    /// The match has a result (MatchMode.readyToShoot: `!state.isOver`).
    case gameOver
    /// The computer's turn, and the computer is not the one acting (MatchMode.personMayAct).
    case notYourTurn
    /// The shot on screen is still playing, so the balls on screen are not the ones the next shot starts from
    /// (ShowpieceModel.aimReady, checked by StrokeGesture.begin).
    case replayPlaying
    /// A match choice is waiting for its answer: accept the table, spot the 8 or re-rack (MatchMode.readyToShoot:
    /// `state.pendingChoice == nil`).
    case choicePending
    /// The last match shot has been ruled and its card is still up, or the device is being handed over
    /// (MatchMode.readyToShoot: `phase == .aiming`).
    case rulingPending
    /// The last stroke is still being worked out on the background task (ShowpieceModel.fire: `!isSolving`).
    case stillSolving

    /// The one line the shot card shows (and the screen reader speaks) for this refusal.
    var sentence: String {
        switch self {
        case .noCall: return String(localized: "Call your shot first.")
        case .backswingTooShort: return String(localized: "Draw the cue back further before you push through.")
        case .ballInHandNotPlaced: return String(localized: "Put the ball down on a free spot first.")
        case .gameOver: return String(localized: "This game is over.")
        case .notYourTurn: return String(localized: "It's the computer's turn.")
        case .replayPlaying: return String(localized: "Wait for the balls to stop.")
        case .choicePending: return String(localized: "Answer the question on the card first.")
        case .rulingPending: return String(localized: "Read the ruling card first.")
        case .stillSolving: return String(localized: "Still working out the last shot.")
        }
    }
}
