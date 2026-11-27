// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: LastShotSection, a "Last shot" row under the
//          live figures that opens planned against delivered for the shot just played; the live figures no longer swap.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 upright iPad and phone: StrikeSlot scrolls in one scroll view
//          of its own, not FittingScroll, whose branch switch remade the panel at two columns and froze the slot about
//          70 points tall; the cut's sub-line clears its dotted underline; the phone sheet is as tall as its figures.)
// PURPOSE: The strike panel (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 2; laid out as
//          plans/26-Nov-2026-aiming-panel-redesign-plan.md, step 4): the strike the player is about to make, in real
//          units, changing live as they aim, set the power, move the tip or raise the cue. Read first, in two bands:
//            - What the ball gets (StrikeLeadBand): the cut on the first ball in line, the speed the ball leaves at,
//              top or back spin and side spin, four large white figures, four columns on a wide panel (the upright
//              iPad), two by two on the Mac, the open folding phone and the upright phone's sheet, one a row at the
//              accessibility text sizes (nothing shrinks). The cut is typeable (dotted underline).
//            - The physics (StrikePhysicsLine): push, force (≈, over 1 ms of tip contact) and energy on one quiet line.
//          The set figures (swing, tip, cue angle, bridge) are no longer tiles: each is printed once, on its control
//          (ShotPanel's What-you-set band). Above the bands, in the notebook only, the heading row ("Your strike", or
//          "Your stroke" after a shot, with "Step by step ›" as a text button) and the plain sentence (StrikeWords).
//          After a shot, until the first control moves (StrikeReading.current), each figure shows what the stroke
//          delivered; under a figure that moved, a DeltaChip in the delta yellow ("+4.8 vs 11.9 planned"); under one
//          that did not, a small "as planned". VoiceOver reads each column as one element, label then the figure in
//          spoken units, planned then delivered after a shot (StrikeSpoken).
//          Shown in the notebook beside or under the table on iPad, Mac and the open folding phone (StrikeSlot), and in
//          a short opaque sheet over the lower part of the upright phone (StrikeSheet). Never over the table.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md
//          Part D items 3 and 4: spoken units; one figure a row at the accessibility text sizes.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign: the twelve-tile grid and its even-row
//          stretch are gone; the lead band and the physics line replace them; the slot's segmented picker becomes the
//          heading row's "Step by step ›" link, its state lifted to NotebookPanel so the notebook can hand the
//          leftover height to the controls band while the strike shows; the phone's sheet is opaque, about 270
//          points, with no repeated title.)
// SRP/DRY check: Pass - checked NotebookNumbers (keeps NumberTile), the instrument kit (FigureLine, DeltaChip,
//          TypeableFigure, bandSurface: reused, not redrawn here), StrikeFigures/StrikeReading (all numbers come from
//          there; nothing is worked out in this view) and StrikeWords/StrikeSpoken (every word and spoken value).
import SwiftUI

struct StrikePanel: View {
    let model: ShowpieceModel
    /// The upright phone's sheet: two by two, no band surfaces (the sheet is the surface), smaller figures.
    var compact = false
    /// The notebook's heading row and plain sentence above the bands; `onSteps` opens the commentary ("Step by step").
    var heading = false
    var onSteps: (() -> Void)? = nil
    @Environment(\.notebookRoomy) private var roomy
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title2) private var headingSize: CGFloat = 22
    @ScaledMetric(relativeTo: .callout) private var sentenceSize: CGFloat = 16
    /// The panel's width, measured, which picks four columns or two (the parent's width never depends on it).
    @State private var width: CGFloat = 0
    @Environment(\.palette) private var palette

    var body: some View {
        let reading = StrikeReading.current(model)
        VStack(alignment: .leading, spacing: compact ? 12 : 8) {
            if heading { headingRow(reading) }
            if let reading {
                StrikeLeadBand(model: model, reading: reading, columns: columns, size: leadScale, framed: !compact)
                StrikePhysicsLine(reading: reading, framed: !compact)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    /// Four columns where each keeps about 150 points (the upright iPad's full-width panel), else two by two; one a
    /// row at the accessibility text sizes.
    private var columns: Int {
        if typeSize.isAccessibilitySize { return 1 }
        if compact { return 2 }
        return width >= 660 ? 4 : 2
    }

    /// How large the lead figures are, as a share of the full-width size: full across four columns, smaller two by
    /// two, smaller again on the folding phone's half and the phone's sheet.
    private var leadScale: CGFloat {
        if compact || !roomy { return 0.62 }
        return columns == 4 ? 1 : 0.66
    }

    // MARK: Heading

    /// The "Step by step" link's height: a 44-point touch target on a touch screen, a line's height under a pointer.
    #if os(macOS)
    private static let linkHeight: CGFloat = 28
    #else
    private static let linkHeight: CGFloat = 44
    #endif

    @ViewBuilder
    private func headingRow(_ reading: StrikeReading.Reading?) -> some View {
        let played = reading?.comparison
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: played == nil ? StrikeWords.liveHeading : StrikeWords.playedStrokeHeading)
                    .font(.system(size: headingSize, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if let onSteps {
                    Button(action: onSteps) {
                        HStack(spacing: 4) {
                            Text(verbatim: StrikeWords.stepsLabel)
                            Image(systemName: "chevron.right").imageScale(.small).accessibilityHidden(true)
                        }
                        .font(.system(size: sentenceSize, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(minHeight: Self.linkHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hoverHighlight(.fill(cornerRadius: 8))
                }
            }
            // The plain sentence: the spin and the cut in words before a shot, the biggest difference after it.
            if let reading {
                Text(verbatim: played.map(StrikeWords.playedSentence) ?? StrikeWords.plainSentence(reading.shown))
                    .font(.system(size: sentenceSize))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let figures = reading?.shown, figures.miscue {
                Label { Text(verbatim: StrikeWords.miscueLine) } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(palette.warning)
                }
                .font(.system(size: sentenceSize))
                .fixedSize(horizontal: false, vertical: true)
            }
            if model.cueAngleLockedByMode && !model.racked {
                Text(verbatim: StrikeWords.lockedByMode)
                    .font(.system(size: sentenceSize))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension StrikeReading.Reading {
    /// The figures the panel shows: the live plan, or what the stroke delivered.
    var shown: StrikeFigures {
        switch self {
        case .live(let f): return f
        case .played(let c): return c.delivered
        }
    }

    /// The comparison, after a shot.
    var comparison: StrikeComparison? {
        if case .played(let c) = self { return c }
        return nil
    }
}

// MARK: What the ball gets

/// The four lead figures: the cut, the speed the ball leaves at, top or back spin, side spin. Columns split by hairline
/// rules, no boxes. `size` scales the full-width figure size (46 points at the default text size).
struct StrikeLeadBand: View {
    let model: ShowpieceModel
    let reading: StrikeReading.Reading
    let columns: Int
    var size: CGFloat = 1
    /// On a band surface with its caption (the notebook); the phone's sheet draws neither.
    var framed = true
    @ScaledMetric(relativeTo: .largeTitle) private var figureBase: CGFloat = 46
    @ScaledMetric(relativeTo: .subheadline) private var labelSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) private var subSize: CGFloat = 13
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 6) {
            if framed { BandCaption(text: StrikeWords.ballGetsCaption) }
            grid
        }
        if framed { content.bandSurface(padding: EdgeInsets(top: 12, leading: 18, bottom: 10, trailing: 18)) } else { content }
    }

    /// One row of four, two rows of two with a rule between them, or one a row.
    @ViewBuilder private var grid: some View {
        let cells = [cell(.cut), cell(.leaves), cell(.topSpin), cell(.sideSpin)]
        switch columns {
        case 4:
            HStack(alignment: .top, spacing: 16) {
                cells[0]; HairlineRule(); cells[1]; HairlineRule(); cells[2]; HairlineRule(); cells[3]
            }
            .fixedSize(horizontal: false, vertical: true)
        case 2:
            VStack(spacing: 6) {
                HStack(alignment: .top, spacing: 16) { cells[0]; HairlineRule(); cells[1] }
                    .fixedSize(horizontal: false, vertical: true)
                HairlineRule(vertical: false)
                HStack(alignment: .top, spacing: 16) { cells[2]; HairlineRule(); cells[3] }
                    .fixedSize(horizontal: false, vertical: true)
            }
        default:
            VStack(alignment: .leading, spacing: 12) { cells[0]; cells[1]; cells[2]; cells[3] }
        }
    }

    private enum Lead { case cut, leaves, topSpin, sideSpin }

    @ViewBuilder
    private func cell(_ lead: Lead) -> some View {
        let f = reading.shown
        let c = reading.comparison
        switch lead {
        case .cut:
            let differs = c.map { $0.differs(.cut) || $0.differs(.aim) } ?? false
            let label = f.cut == nil ? StrikeWords.cutOnLabel(ball: nil) : StrikeWords.cutOnLabel(ball: f.cutBall)
            let figure = f.cut.map(StrikeWords.degreesFigure) ?? FigureText(number: "–", unit: "")
            TypeableFigure(model: model, kind: .cut, spokenLabel: label,
                           spokenValue: StrikeSpoken.tile(.cut, reading, differs: differs)) {
                column(label: label, figure: figure, editable: StrikeEntry.Kind.cut.isOpen(model)) {
                    if let c {
                        below(chip: differs ? cutChip(c) : nil)
                    } else {
                        sub(StrikeWords.turnLine(f.turnDegrees))
                    }
                }
            }
        case .leaves:
            plain(.leaves, label: StrikeWords.leavesShortLabel, figure: StrikeWords.speedFigure(f.leaves),
                  sub: StrikeWords.fromSwing(f.swing), decimals: 2, magnitude: false)
        case .topSpin:
            plain(.topSpin, label: StrikeWords.topSpinLabel(f.topSpin), figure: StrikeWords.spinFigure(f.topSpin),
                  sub: nil, decimals: 1, magnitude: true)
        case .sideSpin:
            plain(.sideSpin, label: StrikeWords.sideSpinLabel(f.sideSpin), figure: StrikeWords.spinFigure(f.sideSpin),
                  sub: nil, decimals: 1, magnitude: true)
        }
    }

    /// A lead column that is a result only (not typeable): one VoiceOver element, label then spoken value.
    private func plain(_ figure: StrikeComparison.Figure, label: String, figure text: FigureText, sub line: String?,
                       decimals: Int, magnitude: Bool) -> some View {
        let c = reading.comparison
        let differs = c?.differs(figure) == true
        return column(label: label, figure: text, editable: false) {
            if let c {
                below(chip: differs ? chip(figure, c, decimals: decimals, magnitude: magnitude) : nil)
            } else {
                sub(line)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityValue(Text(verbatim: StrikeSpoken.tile(figure, reading, differs: differs)))
    }

    /// Label, figure, and the line under it; every column keeps three lines so the rows line up.
    private func column<Below: View>(label: String, figure: FigureText, editable: Bool,
                                     @ViewBuilder below: () -> Below) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: label)
                .font(.system(size: labelSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.8)
            FigureLine(figure: figure, size: figureBase * size, role: .result, editable: editable)
                // The dotted underline hangs max(4, 16 %) of the figure under the number (FigureLine); the line under
                // the figure starts clear of it.
                .padding(.bottom, editable ? max(4, figureBase * size * 0.16) + 6 : 0)
            below()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The sub-line under a live figure (or an empty line, so the column keeps its height).
    private func sub(_ line: String?, secondary: Bool = false) -> some View {
        Text(verbatim: line ?? " ")
            .font(.system(size: subSize))
            .foregroundStyle(secondary ? HierarchicalShapeStyle.secondary : HierarchicalShapeStyle.tertiary)
            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.8)
    }

    /// After a shot: the delta chip, or "as planned".
    @ViewBuilder private func below(chip: String?) -> some View {
        if let chip {
            DeltaChip(text: chip)
        } else {
            sub(StrikeWords.asPlanned, secondary: true)
        }
    }

    /// The chip for a figure that moved: the signed difference and the planned figure, both as the figure shows them
    /// (spin as a size, without its sign, because the label says which way).
    private func chip(_ f: StrikeComparison.Figure, _ c: StrikeComparison, decimals: Int, magnitude: Bool) -> String? {
        guard let a = StrikeComparison.value(f, of: c.planned), let b = StrikeComparison.value(f, of: c.delivered) else {
            return nil
        }
        let shownA = magnitude ? abs(a) : a, shownB = magnitude ? abs(b) : b
        return StrikeWords.deltaChip(StrikeWords.signed(shownB - shownA, decimals: decimals),
                                     planned: StrikeWords.number(shownA, decimals: decimals))
    }

    /// The cut's chip: the change in the cut where there is one, else the aim's turn ("0.4° left") against the plan.
    private func cutChip(_ c: StrikeComparison) -> String {
        let planned = c.planned.cut.map(StrikeWords.degrees) ?? "–"
        if c.differs(.cut), let a = c.planned.cut, let b = c.delivered.cut {
            return StrikeWords.deltaChip(StrikeWords.signed(b - a, decimals: 1) + "°", planned: planned)
        }
        return StrikeWords.deltaChip(StrikeWords.aimError(c.aimError), planned: planned)
    }
}

// MARK: The physics

/// Push, force and energy on one quiet line (two when narrow, one a row at the accessibility sizes). After a shot each
/// figure is the delivered one, followed by its signed change in the delta yellow when it moved.
struct StrikePhysicsLine: View {
    let reading: StrikeReading.Reading
    var framed = true
    @ScaledMetric(relativeTo: .callout) private var figureSize: CGFloat = 16
    @ScaledMetric(relativeTo: .callout) private var labelSize: CGFloat = 14
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.palette) private var palette

    var body: some View {
        let content = Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { BandCaption(text: StrikeWords.physicsCaption); items }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        BandCaption(text: StrikeWords.physicsCaption).fixedSize()
                        items
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        BandCaption(text: StrikeWords.physicsCaption)
                        HStack(spacing: 14) { items }
                    }
                    // A slim column: push and energy share a line, the force (with its contact time) has its own.
                    VStack(alignment: .leading, spacing: 4) {
                        BandCaption(text: StrikeWords.physicsCaption)
                        HStack(spacing: 14) { pushItem; Spacer(minLength: 0); energyItem }
                        forceItem
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        BandCaption(text: StrikeWords.physicsCaption)
                        VStack(alignment: .leading, spacing: 4) { items }
                    }
                }
            }
        }
        if framed {
            content.bandSurface(ledger: true, padding: EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
        } else {
            content
        }
    }

    @ViewBuilder private var items: some View {
        pushItem
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        forceItem
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        energyItem
    }

    private var pushItem: some View {
        item(.push, label: StrikeWords.pushLabel, figure: StrikeWords.pushFigure(reading.shown.push), decimals: 2,
             spokenLabel: StrikeWords.pushLabel)
    }

    private var forceItem: some View {
        item(.force, label: StrikeWords.forceShortLabel, figure: StrikeWords.forceFigure(reading.shown.force),
             decimals: 0, note: StrikeWords.forceOver, spokenLabel: StrikeWords.forceLabel)
    }

    private var energyItem: some View {
        item(.energy, label: StrikeWords.energyLabel, figure: StrikeWords.energyFigure(reading.shown.energy),
             decimals: 2, spokenLabel: StrikeWords.energyLabel)
    }

    private func item(_ figure: StrikeComparison.Figure, label: String, figure text: FigureText, decimals: Int,
                      note: String? = nil, spokenLabel: String) -> some View {
        let c = reading.comparison
        let differs = c?.differs(figure) == true
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: label)
                .font(.system(size: labelSize))
                .foregroundStyle(.secondary)
            FigureLine(figure: text, size: figureSize, role: .result)
            if let note {
                Text(verbatim: note).font(.system(size: labelSize * 0.8)).foregroundStyle(.secondary)
            }
            if differs, let c, let a = StrikeComparison.value(figure, of: c.planned),
               let b = StrikeComparison.value(figure, of: c.delivered) {
                // The change, signed, in yellow; VoiceOver hears planned then delivered (the element's value).
                Text(verbatim: StrikeWords.signed(b - a, decimals: decimals))
                    .font(.system(size: labelSize * 0.85, design: .monospaced).weight(.semibold))
                    .foregroundStyle(palette.delta)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spokenLabel))
        .accessibilityValue(Text(verbatim: StrikeSpoken.tile(figure, reading, differs: differs)))
    }
}

// MARK: The notebook's slot

/// The slot beside or under the table that used to hold the commentary alone (NotebookPanel). While the player is
/// aiming ("Your shot" open, the balls at rest or before any shot) it shows the strike panel's heading, sentence and two
/// bands; while the balls move it gives way to the commentary, as before; once a shot has played out the panel returns
/// with planned against delivered, and "Step by step ›" in the heading row brings the commentary back for reading (with
/// a "‹ Your strike" link back). With Explanations off the commentary is never drawn and the slot keeps the strike
/// throughout. During the opening the slot keeps the commentary's own rule, so the first minute stays one instruction
/// beside a racked table.
struct StrikeSlot: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// "Your shot" is open: the player is aiming (NotebookPanel's showShotPanel). Closed, the slot is the commentary.
    let aiming: Bool
    /// The player asked for the commentary after the shot (owned by NotebookPanel, which lays the column out by it);
    /// back to the strike with each new recording.
    @Binding var showSteps: Bool
    /// The most height the strike's heading and bands may take before they scroll (the rest goes to the controls).
    var strikeMaxHeight: CGFloat = .infinity
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The strike's own height (heading, sentence and bands), measured inside the scroll view (strike(steps:)).
    @State private var strikeNatural: CGFloat = 0
    /// The "Last shot" section is open; closed again with each new recording.
    @State private var lastShotOpen = false

    /// True when the slot shows the strike at all: "Your shot" is open, outside the opening. NotebookPanel reads it to
    /// keep the slot when Explanations is off. With "Your shot" closed the numbers strip shows instead.
    static func shows(_ model: ShowpieceModel, aiming: Bool) -> Bool { aiming && model.openingStage == .none }

    /// True when the slot is drawing the strike panel now (not the commentary): NotebookPanel then hands the leftover
    /// height to the controls band instead of to the slot.
    @MainActor
    static func showsStrike(_ model: ShowpieceModel, aiming: Bool, explanations: Bool, showSteps: Bool) -> Bool {
        guard shows(model, aiming: aiming) else { return false }
        if !explanations { return true }
        if NotebookStory.hasShot(model) && !model.aimReady { return false }
        return !(NotebookStory.hasShot(model) && showSteps)
    }

    var body: some View {
        Group {
            if !Self.shows(model, aiming: aiming) {
                // The first minute, or "Your shot" closed: the commentary's own rule.
                if explanations { NotebookStory(model: model, leader: leader) } else { Color.clear }
            } else if !explanations {
                strike(steps: false)
            } else if NotebookStory.hasShot(model) && !model.aimReady {
                // The balls are moving (or the replay is being read): the commentary, as before.
                NotebookStory(model: model, leader: leader)
            } else if NotebookStory.hasShot(model) && showSteps {
                VStack(alignment: .leading, spacing: 8) {
                    Button { showSteps = false } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").imageScale(.small).accessibilityHidden(true)
                            Text(verbatim: StrikeWords.liveHeading)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    NotebookStory(model: model, leader: leader)
                }
            } else {
                strike(steps: NotebookStory.hasShot(model))
            }
        }
        .onChange(of: model.timelineVersion) { _, _ in showSteps = false; lastShotOpen = false }
    }

    /// The strike's heading and bands, at their own height up to strikeMaxHeight, scrolling past it (the largest text
    /// sizes); before any shot the surface and table card follows, as the commentary's empty page used to show.
    /// Not FittingScroll: its two branches (plain, or in a scroll view) are two identities, so switching between them
    /// remade StrikePanel, whose column count comes from its measured width and starts at two columns. Two by two is
    /// taller, so the remade panel measured past the cap, which picked the scroll branch, which remade it again: the
    /// slot froze at the cap (about 70 points taller than the four-column strike, an empty gap on the upright iPad)
    /// and the controls band under it lost that height. One scroll view, always there and only scrolling when the
    /// content is taller than the cap, keeps one identity, so the measurement settles once.
    private func strike(steps: Bool) -> some View {
        let fits = strikeNatural <= strikeMaxHeight
        return ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                StrikePanel(model: model, heading: true, onSteps: steps && explanations ? { showSteps = true } : nil)
                // UI rethink package 1: the shot just played, planned against delivered, in its own section under the
                // live figures (the live figures no longer swap to it once the next shot can be aimed).
                if model.aimReady, let last = StrikeReading.lastShot(model) {
                    LastShotSection(model: model, comparison: last, open: $lastShotOpen)
                }
                if !NotebookStory.hasShot(model) {
                    NotebookSurfaceCard(model: model, detailed: true)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { strikeNatural = $0 }
        }
        .scrollDisabled(fits)
        .scrollBounceBehavior(.basedOnSize)
        // Its own height up to the cap; before the first measurement nothing (it is measured in the same pass).
        .frame(height: min(strikeNatural, strikeMaxHeight))
    }
}

// MARK: The last shot

/// The shot just played, planned against delivered (UI rethink package 1): a "Last shot" row that opens the lead band and
/// the physics line for that shot, under the live figures. The live figures always describe the next shot.
struct LastShotSection: View {
    let model: ShowpieceModel
    let comparison: StrikeComparison
    @Binding var open: Bool
    @ScaledMetric(relativeTo: .callout) private var labelSize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { open.toggle() } label: {
                HStack(spacing: 6) {
                    Text(verbatim: StrikeWords.lastShotLabel)
                    Image(systemName: open ? "chevron.down" : "chevron.right").imageScale(.small)
                        .accessibilityHidden(true)
                }
                .font(.system(size: labelSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(open ? .isSelected : [])
            if open {
                let reading = StrikeReading.Reading.played(comparison)
                Text(verbatim: StrikeWords.playedSentence(comparison))
                    .font(.system(size: labelSize))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                StrikeLeadBand(model: model, reading: reading, columns: 2, size: 0.62)
                StrikePhysicsLine(reading: reading)
            }
        }
    }
}

// MARK: The upright phone's sheet

/// The strike panel on the upright phone (stage 4): opened by a tap on the swing figure in the aiming panel, as a short
/// opaque sheet (about 270 points) over the bottom of the screen, so the table and the aim line stay in view above it.
/// What the ball gets, two by two, and the physics line only: the phone's aiming panel already carries the set figures.
/// The table can still be touched to aim while it is open, and the figures follow.
struct StrikeSheet: View {
    let model: ShowpieceModel
    @Binding var isOpen: Bool
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The sheet's content, measured (0 until measured): the sheet is as tall as its figures, so the physics line is
    /// never cut off at the bottom (a fixed 270 points was about 25 short), and at most about half an upright phone.
    @State private var contentHeight: CGFloat = 0

    /// Its own height while that is under 420 points (about half the phone); 270 before the first measurement.
    private var detent: PresentationDetent {
        contentHeight > 0 ? .height(min(contentHeight, 420)) : .height(270)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    BandCaption(text: StrikeWords.ballGetsCaption)
                    Spacer(minLength: 8)
                    Button(StrikeWords.doneWord) { isOpen = false }
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                StrikePanel(model: model, compact: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 16)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .tint(palette.accent)
        // Opaque: no table showing through behind the figures.
        .presentationBackground(palette.band)
        .presentationDetents(typeSize.isAccessibilitySize ? [.medium, .large] : [detent, .medium])
        .presentationBackgroundInteraction(.enabled(upThrough: typeSize.isAccessibilitySize ? .medium : detent))
    }
}
