// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console: one name, "Your strike",
//          before and after a shot, set in the serif title with "Step by step" as a quiet worded button; the four lead
//          figures are the kit's figure tiles (lead size, four in a row on a wide console, two by two otherwise, one a
//          row at the accessibility sizes) and the physics a sunken strip, both always the live figures with no chips;
//          planned against delivered lives only in the "Last shot" card (LastShotSection): the delivered figure in paper,
//          an up or down arrow and the worded difference in paper2 ("2.61 m/s, 0.13 under"). The bands no longer draw
//          their own surfaces: in the notebook the console's one panel holds them, on the phone the sheet does.)
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
    /// The upright phone's sheet: two by two, the control figure size, no heading.
    var compact = false
    /// The notebook's heading row and plain sentence above the bands; `onSteps` opens the commentary ("Step by step").
    var heading = false
    var onSteps: (() -> Void)? = nil
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.palette) private var palette
    /// The panel's width, measured, which picks four tiles a row or two (the parent's width never depends on it).
    @State private var width: CGFloat = 0

    var body: some View {
        let reading = StrikeReading.current(model)
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            if heading { headingRow(reading) }
            if let reading {
                StrikeLeadBand(model: model, reading: reading, columns: columns, size: compact ? 0 : 1, framed: !compact)
                StrikePhysicsLine(reading: reading, framed: !compact)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    /// Four tiles a row where each keeps about 150 points (the upright iPad's full-width console), else two by two;
    /// one a row at the accessibility text sizes.
    private var columns: Int {
        if typeSize.isAccessibilitySize { return 1 }
        if compact { return 2 }
        return width >= 640 ? 4 : 2
    }

    // MARK: Heading

    @ViewBuilder
    private func headingRow(_ reading: StrikeReading.Reading?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                // One name before and after a shot (UI rethink package 4).
                KitCardTitle(StrikeWords.liveHeading, style: .title)
                Spacer(minLength: Theme.Space.xs)
                if let onSteps {
                    QuietButton(StrikeWords.stepsLabel, systemImage: "list.bullet", action: onSteps)
                        // The quiet button keeps its 44-point hit area without pushing the sentence down by all of it.
                        .padding(.vertical, -Theme.Space.sm)
                }
            }
            // The plain sentence: the spin and the cut in words before a shot, the biggest difference after it.
            if let reading {
                Text(verbatim: reading.comparison.map(StrikeWords.playedSentence) ?? StrikeWords.plainSentence(reading.shown))
                    .font(Theme.body)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let figures = reading?.shown, figures.miscue {
                Label { Text(verbatim: StrikeWords.miscueLine) } icon: {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(palette.warning)
                }
                .font(Theme.body)
                .foregroundStyle(palette.paper)
                .fixedSize(horizontal: false, vertical: true)
            }
            if model.cueAngleLockedByMode && !model.racked {
                Text(verbatim: StrikeWords.lockedByMode)
                    .font(Theme.body)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension StrikeReading.Reading {
    /// The figures the panel shows: the live plan, or what the stroke delivered while that shot is being watched.
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

/// The four lead figures as the kit's figure tiles: the cut on the first ball in line (typeable), the speed the ball
/// leaves at, top or back spin, side spin. Always one figure each, never a planned-against-delivered chip (the "Last
/// shot" card holds that). `size` 1 is the lead figure size, 0 the control size (the phone's sheet). `framed` puts the
/// section label ("WHAT THE BALL GETS") above the tiles.
struct StrikeLeadBand: View {
    let model: ShowpieceModel
    let reading: StrikeReading.Reading
    let columns: Int
    var size: CGFloat = 1
    var framed = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
            if framed { BandCaption(text: StrikeWords.ballGetsCaption) }
            grid
        }
    }

    private var figureSize: Theme.FigureSize { size >= 0.9 ? .lead : .control }

    /// One row of four, two rows of two, or one a row (FigureTileRow stacks them at the accessibility sizes).
    @ViewBuilder private var grid: some View {
        switch columns {
        case 4:
            FigureTileRow { cutTile; leavesTile; topSpinTile; sideSpinTile }
        case 2:
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                FigureTileRow { cutTile; leavesTile }
                FigureTileRow { topSpinTile; sideSpinTile }
            }
        default:
            VStack(alignment: .leading, spacing: Theme.Space.sm) { cutTile; leavesTile; topSpinTile; sideSpinTile }
        }
    }

    /// The cut, typeable where the model lets the player set it: a tap opens the exact entry.
    private var cutTile: some View {
        let f = reading.shown
        let label = f.cut == nil ? StrikeWords.cutOnLabel(ball: nil) : StrikeWords.cutOnLabel(ball: f.cutBall)
        let figure = f.cut.map(StrikeWords.degreesFigure) ?? FigureText(number: "–", unit: "")
        return TypeableFigure(model: model, kind: .cut, spokenLabel: label,
                              spokenValue: StrikeSpoken.tile(.cut, .live(f), differs: false)) {
            FigureTile(label: label, figure: figure, note: StrikeWords.turnLine(f.turnDegrees), size: figureSize,
                       editable: StrikeEntry.Kind.cut.isOpen(model))
        }
    }

    private var leavesTile: some View {
        let f = reading.shown
        return FigureTile(label: StrikeWords.leavesShortLabel, figure: StrikeWords.speedFigure(f.leaves),
                          note: StrikeWords.fromSwing(f.swing), size: figureSize,
                          spoken: StrikeSpoken.tile(.leaves, .live(f), differs: false))
    }

    private var topSpinTile: some View {
        let f = reading.shown
        return FigureTile(label: StrikeWords.topSpinLabel(f.topSpin), figure: StrikeWords.spinFigure(f.topSpin),
                          size: figureSize, spoken: StrikeSpoken.tile(.topSpin, .live(f), differs: false))
    }

    private var sideSpinTile: some View {
        let f = reading.shown
        return FigureTile(label: StrikeWords.sideSpinLabel(f.sideSpin), figure: StrikeWords.spinFigure(f.sideSpin),
                          size: figureSize, spoken: StrikeSpoken.tile(.sideSpin, .live(f), differs: false))
    }
}

// MARK: The physics

/// Push, force and energy on one sunken strip (two lines when narrow, one a row at the accessibility sizes), in the
/// inline figure. Always the figures of the strike shown, never a difference (the "Last shot" card holds that).
/// `framed` leads the strip with its caption ("THE PHYSICS").
struct StrikePhysicsLine: View {
    let reading: StrikeReading.Reading
    var framed = true
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.palette) private var palette

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Theme.Space.xs) { caption; items }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.sm) { caption.fixedSize(); items }
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        caption
                        HStack(spacing: Theme.Space.md) { items }
                    }
                    // A slim column: push and energy share a line, the force (with its contact time) has its own.
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        caption
                        HStack(spacing: Theme.Space.md) { pushItem; Spacer(minLength: 0); energyItem }
                        forceItem
                    }
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        caption
                        VStack(alignment: .leading, spacing: Theme.Space.xxs) { items }
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Space.sm)
        .padding(.vertical, Theme.Space.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The sunken strip: set into the panel, no edge, small corners.
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
    }

    @ViewBuilder private var caption: some View {
        if framed { BandCaption(text: StrikeWords.physicsCaption) }
    }

    @ViewBuilder private var items: some View {
        pushItem
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        forceItem
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        energyItem
    }

    private var pushItem: some View {
        item(.push, label: StrikeWords.pushLabel, figure: StrikeWords.pushFigure(reading.shown.push),
             spokenLabel: StrikeWords.pushLabel)
    }

    private var forceItem: some View {
        item(.force, label: StrikeWords.forceShortLabel, figure: StrikeWords.forceFigure(reading.shown.force),
             note: StrikeWords.forceOver, spokenLabel: StrikeWords.forceLabel)
    }

    private var energyItem: some View {
        item(.energy, label: StrikeWords.energyLabel, figure: StrikeWords.energyFigure(reading.shown.energy),
             spokenLabel: StrikeWords.energyLabel)
    }

    private func item(_ figure: StrikeComparison.Figure, label: String, figure text: FigureText, note: String? = nil,
                      spokenLabel: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            Text(verbatim: label)
                .font(Theme.label)
                .foregroundStyle(palette.paper2)
            KitFigure(text, size: .inline)
            if let note {
                Text(verbatim: note).font(Theme.caption).foregroundStyle(palette.paper2)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spokenLabel))
        .accessibilityValue(Text(verbatim: StrikeSpoken.tile(figure, .live(reading.shown), differs: false)))
    }
}

// MARK: The notebook's slot

/// The slot beside or under the table that used to hold the commentary alone (NotebookPanel). While the player is
/// aiming ("Aim" open, the balls at rest or before any shot) it shows "Your strike": the heading, the sentence and the
/// live figures; while the balls move it gives way to the commentary, as before; once a shot has played out the strike
/// returns with the "Last shot" card under it, and "Step by step" in the heading row brings the commentary back for
/// reading (with a "Your strike" link back). With Explanations off the commentary is never drawn and the slot keeps the
/// strike throughout. During the opening the slot keeps the commentary's own rule, so the first minute stays calm.
struct StrikeSlot: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// "Aim" is open: the player is aiming (NotebookPanel's showShotPanel). Closed, the slot is the commentary.
    let aiming: Bool
    /// The player asked for the commentary after the shot (owned by NotebookPanel, which lays the column out by it);
    /// back to the strike with each new recording.
    @Binding var showSteps: Bool
    /// The most height the strike's heading and figures may take before they scroll (the rest goes to the controls).
    var strikeMaxHeight: CGFloat = .infinity
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The strike's own height (heading, sentence and figures), measured inside the scroll view (strike(steps:)).
    @State private var strikeNatural: CGFloat = 0
    /// The "Last shot" card is open; closed again with each new recording.
    @State private var lastShotOpen = false

    /// True when the slot shows the strike at all: "Aim" is open, outside the opening. NotebookPanel reads it to keep
    /// the slot when Explanations is off. With "Aim" closed the numbers strip shows instead.
    static func shows(_ model: ShowpieceModel, aiming: Bool) -> Bool { aiming && model.openingStage == .none }

    /// True when the slot is drawing the strike now (not the commentary): NotebookPanel then hands the leftover height
    /// to the controls instead of to the slot.
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
                // The first minute, or "Aim" closed: the commentary's own rule.
                if explanations { NotebookStory(model: model, leader: leader) } else { Color.clear }
            } else if !explanations {
                strike(steps: false)
            } else if NotebookStory.hasShot(model) && !model.aimReady {
                // The balls are moving (or the replay is being read): the commentary, as before.
                NotebookStory(model: model, leader: leader)
            } else if NotebookStory.hasShot(model) && showSteps {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    QuietButton(StrikeWords.liveHeading, systemImage: "chevron.left") { showSteps = false }
                    NotebookStory(model: model, leader: leader)
                }
            } else {
                strike(steps: NotebookStory.hasShot(model))
            }
        }
        .onChange(of: model.timelineVersion) { _, _ in showSteps = false; lastShotOpen = false }
    }

    /// The strike's heading and figures, at their own height up to strikeMaxHeight, scrolling past it (the largest text
    /// sizes); before any shot the surface and table card follows, as the commentary's empty page used to show.
    /// One scroll view, always there and only scrolling when the content is taller than the cap, keeps one identity, so
    /// the measurement settles once (a switch between a plain and a scrolling branch remade StrikePanel and froze the
    /// slot at the cap, 0.8.1).
    private func strike(steps: Bool) -> some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                StrikePanel(model: model, heading: true, onSteps: steps && explanations ? { showSteps = true } : nil)
                // The shot just played, planned against delivered, in its own card under the live figures (the live
                // figures never swap to it).
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
        .scrollBounceBehavior(.basedOnSize)
        // Its own height up to the cap; before the first measurement nothing (it is measured in the same pass).
        // UI rethink package 4 follow-up: it may also be squeezed below that (minHeight 0), so the console under it
        // keeps its whole height and Shoot never scrolls out of sight; the figures scroll instead.
        .frame(minHeight: 0, idealHeight: min(strikeNatural, strikeMaxHeight), maxHeight: min(strikeNatural, strikeMaxHeight))
    }
}

// MARK: The last shot

/// The "Last shot" card (UI rethink package 4, from package 1's section): the shot just played, planned against
/// delivered. Its title row opens it; open, the plain sentence (the biggest difference), then one row per figure the
/// stroke changed: the figure's name, the delivered figure in paper, an up or down arrow and the worded difference in
/// paper2 ("2.61 m/s  ↓ 0.13 under"). Never a hue of its own; the live figures above always describe the next shot.
/// A sunken strip set into the console's panel, so it reads as a card of its own without a second panel edge.
struct LastShotSection: View {
    let model: ShowpieceModel
    let comparison: StrikeComparison
    @Binding var open: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Button { open.toggle() } label: {
                HStack(spacing: Theme.Space.xs) {
                    Text(verbatim: StrikeWords.lastShotLabel)
                        .font(Theme.heading)
                        .foregroundStyle(palette.paper)
                    Spacer(minLength: Theme.Space.xs)
                    Image(systemName: open ? "chevron.up" : "chevron.down")
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper3)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: Theme.Size.minHit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue(Text(open ? String(localized: "Shown") : String(localized: "Hidden")))
            if open {
                Text(verbatim: StrikeWords.playedSentence(comparison))
                    .font(Theme.body)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    ForEach(rows, id: \.label) { row in
                        LastShotRow(row: row)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Space.sm)
        .padding(.vertical, Theme.Space.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
        .animation(Theme.Motion.standard, value: open)
    }

    /// One row per figure the stroke changed, in the panel's order. Spin and the tip read as sizes (their labels say
    /// which way), so their differences are differences of size.
    private var rows: [LastShotRow.Row] {
        let c = comparison, p = c.planned, d = c.delivered
        var out: [LastShotRow.Row] = []
        func add(_ f: StrikeComparison.Figure, label: String, figure: FigureText, planned a: Double?, delivered b: Double?,
                 decimals: Int, scale: Double = 1) {
            guard c.differs(f), let a, let b else { return }
            out.append(LastShotRow.Row(label: label, figure: figure, delta: (b - a) * scale, decimals: decimals,
                                       spoken: StrikeSpoken.tile(f, .played(c), differs: true)))
        }
        if let cut = d.cut {
            add(.cut, label: StrikeWords.cutLabel, figure: StrikeWords.degreesFigure(cut), planned: p.cut, delivered: d.cut,
                decimals: 1)
        }
        if c.differs(.aim) && !c.differs(.cut) {
            // The aim turned but the cut printed the same: the turn itself, as the shooter sees it ("0.4° left").
            out.append(LastShotRow.Row(label: StrikeWords.aimTab, figure: FigureText(number: StrikeWords.aimError(c.aimError),
                                                                                    unit: ""),
                                       delta: nil, decimals: 1,
                                       spoken: StrikeSpoken.tile(.aim, .played(c), differs: true)))
        }
        add(.swing, label: StrikeWords.swingLabel, figure: StrikeWords.speedFigure(d.swing), planned: p.swing,
            delivered: d.swing, decimals: 2)
        add(.leaves, label: StrikeWords.leavesShortLabel, figure: StrikeWords.speedFigure(d.leaves), planned: p.leaves,
            delivered: d.leaves, decimals: 2)
        add(.topSpin, label: StrikeWords.topSpinLabel(d.topSpin), figure: StrikeWords.spinFigure(d.topSpin),
            planned: abs(p.topSpin), delivered: abs(d.topSpin), decimals: 1)
        add(.sideSpin, label: StrikeWords.sideSpinLabel(d.sideSpin), figure: StrikeWords.spinFigure(d.sideSpin),
            planned: abs(p.sideSpin), delivered: abs(d.sideSpin), decimals: 1)
        add(.tipUp, label: StrikeWords.tipUpLabel(d.tipUp), figure: StrikeWords.millimetresFigure(d.tipUp),
            planned: abs(p.tipUp), delivered: abs(d.tipUp), decimals: 1, scale: 1000)
        add(.tipSide, label: StrikeWords.tipSideLabel(d.tipSide), figure: StrikeWords.millimetresFigure(d.tipSide),
            planned: abs(p.tipSide), delivered: abs(d.tipSide), decimals: 1, scale: 1000)
        add(.push, label: StrikeWords.pushLabel, figure: StrikeWords.pushFigure(d.push), planned: p.push,
            delivered: d.push, decimals: 2)
        add(.force, label: StrikeWords.forceShortLabel, figure: StrikeWords.forceFigure(d.force), planned: p.force,
            delivered: d.force, decimals: 0)
        add(.energy, label: StrikeWords.energyLabel, figure: StrikeWords.energyFigure(d.energy), planned: p.energy,
            delivered: d.energy, decimals: 2)
        return out
    }
}

/// One row of the "Last shot" card: name, delivered figure, arrow and worded difference; one VoiceOver element that says
/// planned then delivered.
private struct LastShotRow: View {
    struct Row {
        let label: String
        let figure: FigureText
        /// Delivered minus planned in the figure's shown unit; nil for a row that is words only (the aim's turn).
        let delta: Double?
        let decimals: Int
        let spoken: String
    }

    let row: Row
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            Text(verbatim: row.label)
                .font(Theme.label)
                .foregroundStyle(palette.paper2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: Theme.Space.xs)
            if row.figure.unit.isEmpty {
                Text(verbatim: row.figure.number).font(Theme.label).foregroundStyle(palette.paper)
            } else {
                KitFigure(row.figure, size: .inline)
            }
            if let delta = row.delta {
                Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                Text(verbatim: StrikeWords.differenceWords(delta, decimals: row.decimals))
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: row.label))
        .accessibilityValue(Text(verbatim: row.spoken))
    }
}

// MARK: The upright phone's sheet

/// The strike's figures on the upright phone: opened by a tap on the swing figure in the aiming panel, as a short opaque
/// sheet over the bottom of the screen, so the table and the aim line stay in view above it. What the ball gets, two by
/// two, and the physics line only: the phone's aiming panel already carries the set figures. The table can still be
/// touched to aim while it is open, and the figures follow.
struct StrikeSheet: View {
    let model: ShowpieceModel
    @Binding var isOpen: Bool
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The sheet's content, measured (0 until measured): the sheet is as tall as its figures, and at most about half an
    /// upright phone.
    @State private var contentHeight: CGFloat = 0

    /// Its own height while that is under 420 points (about half the phone); 270 before the first measurement.
    private var detent: PresentationDetent {
        contentHeight > 0 ? .height(min(contentHeight, 420)) : .height(270)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                HStack(alignment: .firstTextBaseline) {
                    // One name everywhere (UI rethink package 4).
                    Text(verbatim: StrikeWords.liveHeading)
                        .font(Theme.heading)
                        .foregroundStyle(palette.paper)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: Theme.Space.xs)
                    QuietButton(StrikeWords.doneWord) { isOpen = false }
                }
                BandCaption(text: StrikeWords.ballGetsCaption)
                StrikePanel(model: model, compact: true)
            }
            .padding(.horizontal, Theme.Space.md)
            .padding(.top, Theme.Space.xs)
            .padding(.bottom, Theme.Space.md)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .tint(palette.accent)
        // Opaque: the house panel, no table showing through behind the figures.
        .presentationBackground(palette.panel)
        .presentationDetents(typeSize.isAccessibilitySize ? [.medium, .large] : [detent, .medium])
        .presentationBackgroundInteraction(.enabled(upThrough: typeSize.isAccessibilitySize ? .medium : detent))
        .kitDevice(.phone)
    }
}
