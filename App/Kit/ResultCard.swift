// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: The result card (design language, "Result card"), shown when a try ends in any mode. In order: the verdict
//          word in the heading style, coloured only when it means something (a foul or a miss in warning, pocketed or
//          passed in pocket gold, anything else paper); the one real-unit figure that matters at the lead size, its
//          unit grey on the same baseline, with an optional caption under it; the score, with its breakdown behind a
//          worded "More"; then the button row: "Try again" secondary, "Next" primary at the bottom right, "Share"
//          quiet on the left. The verdict word is the mode's own (each mode words its result), the tone says its
//          colour. Every piece but the verdict is optional.
// SRP/DRY check: Pass - checked the trick, drill, lesson and daily result views (each draws its own verdict, figure
//          and buttons on glass); this is the one card they move to in package 5. Surface, status line, disclosure
//          and buttons come from the kit; the figure arrives written by NumberStyle.
import SwiftUI

/// What a result's verdict word means, which sets its colour.
enum ResultTone: Sendable {
    /// A foul or a miss: warning.
    case foul
    /// A ball pocketed: pocket gold.
    case pocketed
    /// A drill or a lesson step passed: pocket gold.
    case passed
    /// Anything else (a try that simply ended): paper.
    case plain
}

struct ResultCard: View {
    let verdict: String
    let tone: ResultTone
    /// The one figure that matters (NumberStyle), and the caption under it ("Cue ball came back").
    let figure: NumberStyle.Reading?
    let figureCaption: String?
    /// The score as written ("820"), its caption word, and what made it up (shown behind "More").
    let score: String?
    let scoreLabel: String
    let scoreBreakdown: [KitStatusItem]
    let tryAgain: KitAction?
    let next: KitAction?
    let share: KitAction?

    @Environment(\.palette) private var palette

    init(verdict: String, tone: ResultTone = .plain, figure: NumberStyle.Reading? = nil, figureCaption: String? = nil,
         score: String? = nil, scoreLabel: String = String(localized: "Score"), scoreBreakdown: [KitStatusItem] = [],
         tryAgain: KitAction? = nil, next: KitAction? = nil, share: KitAction? = nil) {
        self.verdict = verdict
        self.tone = tone
        self.figure = figure
        self.figureCaption = figureCaption
        self.score = score
        self.scoreLabel = scoreLabel
        self.scoreBreakdown = scoreBreakdown
        self.tryAgain = tryAgain
        self.next = next
        self.share = share
    }

    private var verdictColour: Color {
        switch tone {
        case .foul: return palette.warning
        case .pocketed, .passed: return palette.pocket
        case .plain: return palette.paper
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(verdict)
                .font(Theme.heading)
                .foregroundStyle(verdictColour)
                .accessibilityAddTraits(.isHeader)
            if let figure {
                leadFigure(figure)
            }
            if let score {
                scoreBlock(score)
            }
            if tryAgain != nil || next != nil || share != nil {
                KitButtonRow(primary: next, secondary: tryAgain, quiet: share)
                    .padding(.top, Theme.Space.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .accessibilityElement(children: .contain)
    }

    private func leadFigure(_ reading: NumberStyle.Reading) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
            KitFigure(reading, size: .lead)
            if let figureCaption {
                Text(figureCaption)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
            }
        }
        // One element: "Cue ball came back, 12 cm".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(figureCaption ?? verdict)
        .accessibilityValue(reading.text)
    }

    @ViewBuilder
    private func scoreBlock(_ score: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            KitStatusLine(items: [KitStatusItem(scoreLabel, figure: score)])
            if !scoreBreakdown.isEmpty {
                MoreDisclosure {
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        ForEach(scoreBreakdown) { part in
                            HStack(alignment: .firstTextBaseline) {
                                Text(part.label)
                                    .font(Theme.caption)
                                    .foregroundStyle(palette.paper2)
                                Spacer(minLength: Theme.Space.sm)
                                KitFigure(number: part.figure, unit: part.unit, size: .inline)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(Theme.Space.sm)
                    .background(palette.panelSunken, in: Theme.Corner.tileShape)
                }
            }
        }
    }
}

#Preview("Result card, every tone") {
    KitPreviewStage(device: .big) {
        ResultCard(verdict: "Foul", tone: .foul, figure: NumberStyle.speed(metresPerSecond: 2.613),
                   figureCaption: "Cue ball speed", tryAgain: KitAction("Try again") {}, next: KitAction("Next") {})
        ResultCard(verdict: "Pocketed", tone: .pocketed, figure: NumberStyle.distance(metres: 0.124),
                   figureCaption: "Cue ball came back", score: "820",
                   scoreBreakdown: [KitStatusItem("Pocketed", figure: "500"),
                                    KitStatusItem("Draw", figure: "320")],
                   tryAgain: KitAction("Try again") {}, next: KitAction("Next") {},
                   share: KitAction("Share", systemImage: "square.and.arrow.up") {})
        ResultCard(verdict: "Passed", tone: .passed, figure: NumberStyle.angle(degrees: 1.46),
                   figureCaption: "Aim error", next: KitAction("Next") {})
        ResultCard(verdict: "Try over", figure: NumberStyle.time(seconds: 3.2), tryAgain: KitAction("Try again") {})
    }
}

#Preview("Result card, phone") {
    KitPreviewStage(device: .phone) {
        ResultCard(verdict: "Pocketed", tone: .pocketed, figure: NumberStyle.speed(metresPerSecond: 11.42),
                   score: "640", scoreBreakdown: [KitStatusItem("Speed", figure: "11.4", unit: "m/s")],
                   tryAgain: KitAction("Try again") {}, next: KitAction("Next") {}, share: KitAction("Share") {})
    }
}
