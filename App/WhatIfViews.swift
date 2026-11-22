// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream whatif item 6: the stubs filled in.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif-review: the click haptic follows WhatIfFork.clicks, so
//          closing the card no longer ticks.)
// PURPOSE: The what-if replay's controls. WhatIfButton is the entry in the playback row beside Replay (a branch
//          symbol), shown only while model.whatIf.canOpen and the what-if is not already up. WhatIfCard is the card in
//          the card slot (below the table on a phone, in the notebook on iPad, Mac and the open Duo, so nothing covers
//          the table): the title and a fixed line, a segmented choice of Aim, Power, Spin (follow or draw, and side)
//          and, for a raised cue, Cue angle; each setting a row of two glass buttons with the offset between them
//          ("0.25° left"), adjustable by VoiceOver; Reset; the sentences about the other future (WhatIfWords); Play
//          both, Where they part, and Keep this one only when the mode can retry with it (absent otherwise, not
//          disabled); and Close. A selection haptic on each click when Vibration is on. Nothing plays by itself.
//          ShowpieceView and NotebookPanel mount both (the foundation's mounts); PlaybackControls places the button.
// SRP/DRY check: Pass - the card follows TableClearedCard's glass card and ComparisonCard's close button; the words are
//          WhatIfWords, the state WhatIfFork. Nothing else draws what-if controls.
import SwiftUI

/// The "What if" entry beside Replay; shown only while model.whatIf.canOpen and not already showing.
struct WhatIfButton: View {
    let model: ShowpieceModel
    /// Stretch the label to the full row (the stacked buttons at the accessibility text sizes).
    var fill = false

    var body: some View {
        if model.whatIf.canOpen && !model.whatIf.isShowing {
            Button { model.whatIf.open() } label: {
                Label(WhatIfWords.title, systemImage: "arrow.triangle.branch")
                    .frame(maxWidth: fill ? .infinity : nil)
            }
            #if os(iOS)
            .frame(minWidth: 44, minHeight: 44)
            #endif
            .accessibilityLabel(WhatIfWords.title)
            .accessibilityHint(String(localized: "Shows what a small change to this shot would have done"))
        }
    }
}

/// The what-if card in the card slot; shown only while model.whatIf.isShowing.
struct WhatIfCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    private var fork: WhatIfFork { model.whatIf }

    var body: some View {
        // The haptic sits on the always-present Group, so each click (or Reset) fires it once; a close, which also
        // zeroes the steps, does not.
        Group {
            if fork.isShowing, let real = fork.real { card(real) }
        }
        .sensoryFeedback(trigger: fork.clicks) { _, _ in GameSettings.hapticsOn ? .selection : nil }
    }

    private func card(_ real: ShotAttempt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Text(WhatIfWords.fixedLine(changes: fork.steps.nudged.count))
                .font(Theme.body)
                .foregroundStyle(palette.paper.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            sectionPicker
            ForEach(fork.controls(in: fork.section), id: \.self) { c in
                NudgeRow(model: model, control: c, real: real)
            }
            sentences(real)
            buttons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .accessibilityElement(children: .contain)
        .transition(.opacity)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch").foregroundStyle(palette.whatIf).accessibilityHidden(true)
            Text(WhatIfWords.title).font(Theme.heading).accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if !fork.steps.isZero {
                Button { fork.reset() } label: {
                    Label(String(localized: "Reset"), systemImage: "arrow.uturn.backward").font(.subheadline).lineLimit(1)
                }
                .buttonStyle(.glass)
                .accessibilityHint(String(localized: "Puts every setting back to the shot you played"))
            }
            Button { fork.close() } label: {
                Image(systemName: "xmark").frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "Close"))
        }
    }

    @ViewBuilder
    private var sectionPicker: some View {
        let sections = fork.sections
        if sections.count > 1 {
            Picker(String(localized: "Setting"), selection: Binding(get: { fork.section }, set: { fork.section = $0 })) {
                ForEach(sections, id: \.self) { s in Text(WhatIfWords.sectionLabel(s)).tag(s) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    @ViewBuilder
    private func sentences(_ real: ShotAttempt) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Group {
                if let r = fork.result {
                    Text(WhatIfWords.sentences(r, real: real).joined(separator: " "))
                } else if fork.tooLong {
                    Text(WhatIfWords.tooLong)
                } else if fork.steps.isZero {
                    Text(WhatIfWords.prompt)
                } else {
                    Text(WhatIfWords.working)
                }
            }
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(fork.solving ? 0.6 : 1))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            if fork.showSpinner {
                ProgressView().controlSize(.small).accessibilityLabel(WhatIfWords.working)
            }
        }
    }

    private var buttons: some View {
        CardButtonRow {
            if fork.result != nil {
                Button { fork.playBoth() } label: {
                    Label(String(localized: "Play both"), systemImage: "play.fill").font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityHint(String(localized: "Plays your shot again with the other future rolling beside it"))
                if fork.result?.fork.marker != nil {
                    Button { fork.jumpToParting() } label: {
                        Label(String(localized: "Where they part"), systemImage: "diamond").font(.headline).lineLimit(1)
                            .frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                }
            }
            // Present only when the mode can retry with it: absent, not disabled, otherwise.
            if fork.canKeep {
                Button { fork.keep() } label: {
                    Label(String(localized: "Keep this one"), systemImage: "checkmark").font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .accessibilityHint(String(localized: "Sets up your next try with this version's settings"))
            }
        }
    }
}

/// One setting's row: a button each way with the offset between them, one adjustable element for VoiceOver.
private struct NudgeRow: View {
    let model: ShowpieceModel
    let control: WhatIfFork.Control
    let real: ShotAttempt
    @Environment(\.palette) private var palette

    private var fork: WhatIfFork { model.whatIf }

    /// The click each button gives: the left button is the shooter's left for aim and side (aim left is anticlockwise,
    /// a positive aim step; side left is a negative tip step), and less for power, tip height and the cue angle.
    private var leftDelta: Int { control == .aim ? 1 : -1 }
    private var rightDelta: Int { -leftDelta }
    private var symbols: (left: String, right: String) {
        switch control {
        case .aim, .tipSide: return ("chevron.left", "chevron.right")
        case .power, .tipUp, .elevation: return ("minus", "plus")
        }
    }

    private var readout: String {
        guard let v = fork.value(control) else { return "" }
        return WhatIfWords.readout(control, real: real, value: v)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(WhatIfWords.label(control))
                .font(Theme.label)
                .foregroundStyle(palette.paper.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 4)
            step(symbols.left, delta: leftDelta)
            Text(readout)
                .font(Theme.number)
                .foregroundStyle(fork.steps[control] == 0 ? palette.paper.opacity(0.7) : palette.whatIf)
                .lineLimit(1)
                .frame(minWidth: 84)
            step(symbols.right, delta: rightDelta)
        }
        // One adjustable element: VoiceOver swipes up for the right-hand button, down for the left-hand one.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WhatIfWords.label(control))
        .accessibilityValue(readout)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: fork.nudge(control, by: rightDelta)
            case .decrement: fork.nudge(control, by: leftDelta)
            @unknown default: break
            }
        }
    }

    private func step(_ symbol: String, delta: Int) -> some View {
        Button { fork.nudge(control, by: delta) } label: {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .disabled(!fork.canStep(control, by: delta))
    }
}
