// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The strike panel (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 2): a grid of number tiles
//          (NumberTile, the tile NotebookNumbers draws) showing the strike the player is about to make, in real units,
//          changing live as they aim, set the power, move the tip or raise the cue: swing, the speed the ball leaves
//          at, the push, the force (about, over the tip's contact time), the energy, top or back spin, side spin, the
//          tip's height and side, the cue angle, the cut on the first ball in line, and the bridge. After a shot, until
//          the first control moves, each tile whose figure the stroke changed shows two: the planned one dimmed, the
//          delivered one bright, and the error in plain units under it ("0.4° left", "2 mm left"); tiles that did not
//          differ show one figure (StrikeReading.current decides which reading shows).
//          The Swing, Tip, Cue angle, Cut and Bridge tiles open a small number field with a stepper (StrikeEntryField)
//          when tapped, writing through the same model setters as the gauges, so the gauges move with them; a tile the
//          model will not let the player change now (a lesson step, the computer's turn, a mode's own cue angle) is not
//          tappable. The Bridge tile is what lets a single finger set everything the second finger's bridge sets
//          (stage 3 item 6).
//          Shown in the notebook beside the table on iPad, Mac and the open folding phone (StrikeSlot), and in a sheet
//          over the lower half on the upright phone (StrikeSheet). Never over the table.
// SRP/DRY check: Pass - checked NotebookNumbers (its tile lifted into NumberTile and reused here), FineControls (the
//          sliders stay for the upright phone and VoiceOver; the setters are shared), StrikeFigures/StrikeReading (all
//          numbers come from there; nothing is worked out in this view).
import SwiftUI

struct StrikePanel: View {
    let model: ShowpieceModel
    /// The upright phone's sheet: slightly narrower tiles.
    var compact = false
    @Environment(\.palette) private var palette

    var body: some View {
        let reading = StrikeReading.current(model)
        VStack(alignment: .leading, spacing: 10) {
            header(reading)
            if let reading {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 96 : 108), spacing: 8)], spacing: 8) {
                    tiles(reading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Header

    @ViewBuilder
    private func header(_ reading: StrikeReading.Reading?) -> some View {
        let played: Bool = { if case .played = reading { return true }; return false }()
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: played ? StrikeWords.playedHeading : StrikeWords.liveHeading)
                .font(Theme.label)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            if played {
                Text(verbatim: StrikeWords.playedKey)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let figures = reading?.shown, figures.miscue {
                Label { Text(verbatim: StrikeWords.miscueLine) } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(palette.slide)
                }
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            }
            if model.cueAngleLockedByMode && !model.racked {
                Text(verbatim: StrikeWords.lockedByMode)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Tiles

    @ViewBuilder
    private func tiles(_ reading: StrikeReading.Reading) -> some View {
        let f = reading.shown
        let c = reading.comparison
        tile(.swing, value: StrikeWords.speed(f.swing), label: StrikeWords.swingLabel, c, planned: { StrikeWords.speed($0.swing) },
             edit: .swing)
        tile(.leaves, value: StrikeWords.speed(f.leaves), label: StrikeWords.leavesLabel, c,
             planned: { StrikeWords.speed($0.leaves) })
        tile(.push, value: StrikeWords.push(f.push), label: StrikeWords.pushLabel, c, planned: { StrikeWords.push($0.push) })
        tile(.force, value: StrikeWords.force(f.force), label: StrikeWords.forceLabel, c,
             planned: { StrikeWords.force($0.force) })
        tile(.energy, value: StrikeWords.energy(f.energy), label: StrikeWords.energyLabel, c,
             planned: { StrikeWords.energy($0.energy) })
        tile(.topSpin, value: StrikeWords.spin(f.topSpin), label: StrikeWords.topSpinLabel(f.topSpin), c,
             planned: { StrikeWords.spin($0.topSpin) })
        tile(.sideSpin, value: StrikeWords.spin(f.sideSpin), label: StrikeWords.sideSpinLabel(f.sideSpin), c,
             planned: { StrikeWords.spin($0.sideSpin) })
        tile(.tipUp, value: StrikeWords.millimetres(f.tipUp), label: StrikeWords.tipUpLabel(f.tipUp), c,
             planned: { StrikeWords.millimetres($0.tipUp) }, edit: .tipUp)
        tile(.tipSide, value: StrikeWords.millimetres(f.tipSide), label: StrikeWords.tipSideLabel(f.tipSide), c,
             planned: { StrikeWords.millimetres($0.tipSide) }, edit: .tipSide)
        tile(.cueAngle, value: StrikeWords.degrees(f.cueAngle), label: StrikeWords.cueAngleLabel, c,
             planned: { StrikeWords.degrees($0.cueAngle) }, edit: .cueAngle)
        cutTile(f, c)
        bridgeTile
    }

    /// One figure's tile: the delivered figure bright and the planned one dimmed above it when they differ, with the
    /// error under the label; otherwise the one figure. `edit` makes it a button that opens the typed entry.
    @ViewBuilder
    private func tile(_ figure: StrikeComparison.Figure, value: String, label: String, _ c: StrikeComparison?,
                      planned: (StrikeFigures) -> String, edit: StrikeEntry.Kind? = nil) -> some View {
        let differs = c?.differs(figure) == true
        let numberTile = NumberTile(value: value, label: Text(verbatim: label),
                                    planned: differs ? c.map { planned($0.planned) } : nil,
                                    note: c.flatMap { StrikeWords.note(figure, $0) },
                                    large: true, editable: edit.map { $0.isOpen(model) } ?? false)
        if let edit {
            EditableTile(model: model, kind: edit, tile: numberTile)
        } else {
            numberTile
        }
    }

    /// The cut on the first ball in line ("–" with none). After a shot its note is the aim's error, which is what moved
    /// the cut (or would have, with no ball in line).
    @ViewBuilder
    private func cutTile(_ f: StrikeFigures, _ c: StrikeComparison?) -> some View {
        let dash = "–"
        let differs = c.map { $0.differs(.cut) || $0.differs(.aim) } ?? false
        let note: String? = c.flatMap { $0.differs(.aim) ? StrikeWords.note(.aim, $0) : StrikeWords.note(.cut, $0) }
        let numberTile = NumberTile(value: f.cut.map(StrikeWords.degrees) ?? dash,
                                    label: Text(verbatim: f.cut == nil ? StrikeWords.cutOnLabel(ball: nil)
                                                                       : StrikeWords.cutOnLabel(ball: f.cutBall)),
                                    planned: differs ? c.map { $0.planned.cut.map(StrikeWords.degrees) ?? dash } : nil,
                                    note: note, large: true, editable: StrikeEntry.Kind.cut.isOpen(model))
        EditableTile(model: model, kind: .cut, tile: numberTile)
    }

    /// The bridge the next stroke is played off: set on the table by a resting second finger, or typed here.
    private var bridgeTile: some View {
        EditableTile(model: model, kind: .bridge,
                     tile: NumberTile(value: StrikeWords.centimetres(model.strokeBridgeLength),
                                      label: Text(verbatim: StrikeWords.bridgeLabel), large: true,
                                      editable: StrikeEntry.Kind.bridge.isOpen(model)))
    }
}

extension StrikeReading.Reading {
    /// The figures a tile shows as its main value: the live plan, or what the stroke delivered.
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

/// A tile that opens its typed entry in a popover when tapped, while the model lets the player change that value.
private struct EditableTile: View {
    let model: ShowpieceModel
    let kind: StrikeEntry.Kind
    let tile: NumberTile
    @State private var open = false

    var body: some View {
        let enabled = kind.isOpen(model)
        Button { open = true } label: { tile }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .hoverHighlight(.fill(cornerRadius: 14))
            .accessibilityHint(enabled ? StrikeWords.typeHint : "")
            .popover(isPresented: $open) {
                StrikeEntryField(model: model, kind: kind)
                    .presentationCompactAdaptation(.popover)
            }
    }
}

// MARK: The notebook's slot

/// The slot beside the table that used to hold the commentary alone (NotebookPanel). While the player is aiming (the
/// balls at rest, or before any shot) it shows the strike panel; while the balls move it gives way to the commentary,
/// as before; once a shot has played out the panel returns with planned against delivered, and a small switch brings
/// the commentary back for reading ("Step by step"). With Explanations off the commentary is never drawn and the slot
/// keeps the strike panel throughout. During the opening the slot keeps the commentary's own rule, so the first
/// minute stays one instruction beside a racked table.
struct StrikeSlot: View {
    let model: ShowpieceModel
    let leader: LeaderState
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The player asked for the commentary after the shot; back to the strike with each new recording.
    @State private var showSteps = false

    /// True when the slot shows the strike at all (outside the opening). NotebookPanel reads it to keep the slot when
    /// Explanations is off.
    static func shows(_ model: ShowpieceModel) -> Bool { model.openingStage == .none }

    var body: some View {
        Group {
            if !Self.shows(model) {
                // The first minute: the commentary's own rule (it draws nothing until the balls move).
                if explanations { NotebookStory(model: model, leader: leader) } else { Color.clear }
            } else if !explanations {
                strike
            } else if NotebookStory.hasShot(model) && !model.aimReady {
                // The balls are moving (or the replay is being read): the commentary, as before.
                NotebookStory(model: model, leader: leader)
            } else if NotebookStory.hasShot(model) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker(selection: $showSteps) {
                        Text(verbatim: StrikeWords.liveHeading).tag(false)
                        Text(verbatim: StrikeWords.stepsLabel).tag(true)
                    } label: { EmptyView() }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    if showSteps { NotebookStory(model: model, leader: leader) } else { strike }
                }
            } else {
                strike
            }
        }
        .onChange(of: model.timelineVersion) { _, _ in showSteps = false }
    }

    /// The strike panel, scrolling inside the room it is given; before any shot the surface and table card follows it,
    /// as the commentary's empty page used to show.
    private var strike: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StrikePanel(model: model)
                if !NotebookStory.hasShot(model) {
                    NotebookSurfaceCard(model: model, detailed: true)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: The upright phone's sheet

/// The strike panel on the upright phone (stage 4): opened by a tap on the swing figure in the aiming panel, as a
/// sheet over the lower half, so the table stays in view above it. The table can still be touched to aim while it is
/// open, and the tiles follow.
struct StrikeSheet: View {
    let model: ShowpieceModel
    @Binding var isOpen: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            ScrollView {
                StrikePanel(model: model, compact: true).padding(16)
            }
            .navigationTitle(StrikeWords.liveHeading)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(StrikeWords.doneWord) { isOpen = false } }
            }
        }
        .tint(palette.accent)
        .presentationDetents([.medium])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }
}
