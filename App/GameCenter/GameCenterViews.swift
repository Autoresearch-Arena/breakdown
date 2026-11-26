// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The Board button for the daily shot's result card (0.7.10, Shot of the day plan stage 3; the card itself is
//          App/Daily/DailyViews.swift, written in parallel, and wave 2's wiring builder puts this button on it). Press
//          it and GameCenter opens today's board, signing in first the very first time. It is not drawn at all with
//          "Hide the board" on (GameSettings.hideBoardKey, read live through @AppStorage, so switching the option
//          hides it at once) or under a test launch. While a sign-in is under way it is dimmed; when the player pressed
//          it and the sign-in did not work, one short line under it says where to sign in. The caller gives it its
//          button style, so it matches the card's other buttons.
//          Also the words for it (GameCenterWords), each through String(localized:); the new English lines are in
//          localization/pending/v0710-gamecenter.json with all eleven translations. No brand names in what the player
//          reads: the button says "Board".
// SRP/DRY check: Pass - checked App/Daily (written in parallel; its result card keeps its own Watch and Share buttons)
//          and ShotPanel's buttons (the caller's style is used, none is copied here). No GameKit here: GameCenter.swift
//          is the only file that imports it.
import SwiftUI

/// Today's board. Draws nothing when the board is hidden.
struct BoardButton: View {
    @AppStorage(GameSettings.hideBoardKey) private var hidden = false

    var body: some View {
        if !hidden && GameCenter.enabled {
            let center = GameCenter.shared
            VStack(spacing: 6) {
                Button {
                    center.showBoard()
                } label: {
                    Label(GameCenterWords.board, systemImage: "list.number")
                }
                .disabled(center.state == .signingIn)
                .accessibilityHint(GameCenterWords.boardHint)
                if center.state == .unavailable {
                    Text(GameCenterWords.signInNeeded)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// The Board button's words.
enum GameCenterWords {
    /// The button: the daily board.
    static var board: String {
        String(localized: "Board", comment: "Button on the daily shot's result card: opens today's scoreboard of every player's score")
    }

    /// VoiceOver's hint on the button.
    static var boardHint: String {
        String(localized: "Shows today's scores from players everywhere.",
               comment: "VoiceOver hint on the Board button of the daily shot")
    }

    /// Under the button when the player pressed it and the sign-in did not work.
    static var signInNeeded: String {
        String(localized: "The board needs you signed in on this device. Sign in from Settings, then try again.",
               comment: "Shown under the Board button when signing in to the scoreboard service failed or was declined")
    }
}
