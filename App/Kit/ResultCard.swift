// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink wave 2 note 15: the card also takes a corner word beside
//          the verdict, the judge's lines under it, a status line, the extra actions under "More" and an optional
//          section of the mode's own, so every mode's result (ModeResultCard) is this one card.)
// PURPOSE: The result card (design language, "Result card"), shown when a try ends in any mode. In order: the verdict
//          word in the heading style, coloured only when it means something (a foul or a miss in warning, pocketed or
//          passed in pocket gold, anything else paper), with an optional corner word on its right; the judge's lines
//          in body paper; the one real-unit figure that matters at the lead size, its unit grey on the same baseline,
//          with an optional caption under it; a status line; the score, with its breakdown behind a worded "More"; an
//          optional section of the mode's own; then the button row: "Try again" secondary, "Next" primary at the
//          bottom right, "Share" quiet on the left, any other actions under a worded "More". The verdict word is the
//          mode's own (each mode words its result), the tone says its colour. Every piece but the verdict is optional.
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

struct ResultCard<Extra: View>: View {
    let verdict: String
    let tone: ResultTone
    /// A short word on the right of the verdict ("Try 2 of 3", "Gold medal", a trick's title), paper2; nil for none.
    let corner: String?
    /// The judge's line(s) under the verdict, body paper ("Ball hit the cushion first.").
    let lines: [String]
    /// The one figure that matters (NumberStyle), and the caption under it ("Cue ball came back").
    let figure: NumberStyle.Reading?
    let figureCaption: String?
    /// Status figures on one line under the figure (tries left, a streak).
    let status: [KitStatusItem]
    /// The score as written ("820"), its caption word, and what made it up (shown behind "More").
    let score: String?
    let scoreLabel: String
    let scoreBreakdown: [KitStatusItem]
    let tryAgain: KitAction?
    let next: KitAction?
    let share: KitAction?
    /// The actions beyond those three, in the button row's worded "More" menu.
    let more: [KitAction]
    /// A mode's own section above the buttons (8-ball's "On a real table", a match's points).
    let extra: Extra

    @Environment(\.palette) private var palette
    private var deviceReader = KitDeviceReader()

    init(verdict: String, tone: ResultTone = .plain, corner: String? = nil, lines: [String] = [],
         figure: NumberStyle.Reading? = nil, figureCaption: String? = nil, status: [KitStatusItem] = [],
         score: String? = nil, scoreLabel: String = String(localized: "Score"), scoreBreakdown: [KitStatusItem] = [],
         tryAgain: KitAction? = nil, next: KitAction? = nil, share: KitAction? = nil, more: [KitAction] = [],
         @ViewBuilder extra: () -> Extra) {
        self.verdict = verdict
        self.tone = tone
        self.corner = corner
        self.lines = lines
        self.figure = figure
        self.figureCaption = figureCaption
        self.status = status
        self.score = score
        self.scoreLabel = scoreLabel
        self.scoreBreakdown = scoreBreakdown
        self.tryAgain = tryAgain
        self.next = next
        self.share = share
        self.more = more
        self.extra = extra()
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
            verdictLine
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(verbatim: line)
                    .font(deviceReader.current == .phone ? Theme.bodyCompact : Theme.body)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let figure {
                leadFigure(figure)
            }
            if !status.isEmpty {
                KitStatusLine(items: status)
            }
            if let score {
                scoreBlock(score)
            }
            extra
            if tryAgain != nil || next != nil || share != nil || !more.isEmpty {
                KitButtonRow(primary: next, secondary: tryAgain, quiet: share, more: more)
                    .padding(.top, Theme.Space.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .accessibilityElement(children: .contain)
    }

    /// The verdict in its colour, the corner word on its right; one header for VoiceOver.
    private var verdictLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
            Text(verbatim: verdict)
                .font(Theme.heading)
                .foregroundStyle(verdictColour)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Space.xs)
            if let corner {
                Text(verbatim: corner)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func leadFigure(_ reading: NumberStyle.Reading) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
            KitFigure(reading, size: .lead)
            if let figureCaption {
                Text(verbatim: figureCaption)
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
                                Text(verbatim: part.label)
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

extension ResultCard where Extra == EmptyView {
    /// A result with no section of its own.
    init(verdict: String, tone: ResultTone = .plain, corner: String? = nil, lines: [String] = [],
         figure: NumberStyle.Reading? = nil, figureCaption: String? = nil, status: [KitStatusItem] = [],
         score: String? = nil, scoreLabel: String = String(localized: "Score"), scoreBreakdown: [KitStatusItem] = [],
         tryAgain: KitAction? = nil, next: KitAction? = nil, share: KitAction? = nil, more: [KitAction] = []) {
        self.init(verdict: verdict, tone: tone, corner: corner, lines: lines, figure: figure,
                  figureCaption: figureCaption, status: status, score: score, scoreLabel: scoreLabel,
                  scoreBreakdown: scoreBreakdown, tryAgain: tryAgain, next: next, share: share, more: more,
                  extra: { EmptyView() })
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
