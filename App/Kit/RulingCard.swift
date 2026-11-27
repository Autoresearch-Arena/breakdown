// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: The ruling card (design language, "Ruling card"), shown in the table games after a shot is judged. The
//          verdict word in the heading style: "Foul" in warning, "Legal" in paper, "Loss of turn" in paper2. Then one
//          line saying what happens next ("Ball in hand for the computer"), then the reason behind a worded "More".
//          The three verdicts and their words are fixed by the design language, so the card owns them; the next step
//          and the reason are the game's own words. The table marks the ruling itself (the ball-in-hand area ringed
//          in paper); that mark is not part of this card.
// SRP/DRY check: Pass - checked the match views (EightBall, Match), which word and colour each ruling in place, the
//          foul in the old sliding colour; this is the one ruling card they move to. Surface and disclosure come from
//          the kit.
import SwiftUI

/// The three rulings a judged shot can get.
enum RulingVerdict: Sendable, CaseIterable {
    case foul
    case legal
    case lossOfTurn

    /// The verdict word, in the shown language.
    var word: String {
        switch self {
        case .foul: return String(localized: "Foul")
        case .legal: return String(localized: "Legal", comment: "Ruling card verdict: the shot broke no rule.")
        case .lossOfTurn: return String(localized: "Loss of turn",
                                        comment: "Ruling card verdict: no foul, but the other player is up next.")
        }
    }
}

struct RulingCard: View {
    let ruling: RulingVerdict
    /// One line: what happens next ("Ball in hand for the computer"). Already localized.
    let nextStep: String
    /// Why, behind "More" ("The cue ball touched no ball first"). Already localized; nil hides "More".
    let reason: String?

    @Environment(\.palette) private var palette
    private var deviceReader = KitDeviceReader()
    private var device: Theme.Device { deviceReader.current }

    init(_ ruling: RulingVerdict, nextStep: String, reason: String? = nil) {
        self.ruling = ruling
        self.nextStep = nextStep
        self.reason = reason
    }

    private var verdictColour: Color {
        switch ruling {
        case .foul: return palette.warning
        case .legal: return palette.paper
        case .lossOfTurn: return palette.paper2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(ruling.word)
                .font(Theme.heading)
                .foregroundStyle(verdictColour)
                .accessibilityAddTraits(.isHeader)
            Text(nextStep)
                .font(device == .phone ? Theme.bodyCompact : Theme.body)
                .foregroundStyle(palette.paper)
                .fixedSize(horizontal: false, vertical: true)
            if let reason {
                MoreDisclosure {
                    Text(reason)
                        .font(device == .phone ? Theme.bodyCompact : Theme.body)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .accessibilityElement(children: .contain)
    }
}

#Preview("Ruling card, every ruling") {
    KitPreviewStage(device: .big) {
        RulingCard(.foul, nextStep: "Ball in hand for the computer",
                   reason: "The cue ball touched no ball first.")
        RulingCard(.legal, nextStep: "You are still up.")
        RulingCard(.lossOfTurn, nextStep: "The computer is up next.",
                   reason: "Nothing was pocketed, so the turn passes.")
    }
}

#Preview("Ruling card, phone") {
    KitPreviewStage(device: .phone) {
        RulingCard(.foul, nextStep: "Ball in hand for you", reason: "The 8 ball went down early.")
    }
}
