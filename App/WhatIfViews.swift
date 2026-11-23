// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream whatif item 6: the stubs filled in.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif-review: the click haptic follows WhatIfFork.clicks, so
//          closing the card no longer ticks.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream what-if, plans/22-Nov-2026-v076-phone-plan.md, bugs 25,
//          27, 28 and 31 of plans/22-Nov-2026-phone-bug-hunt.md: on a phone held upright the card has a compact form
//          whose height never changes as the player nudges or switches setting (header, setting picker, the section's
//          nudge rows with room kept for the tallest section, a two-line result that opens on tap into a fixed room that
//          scrolls, and Play both, Split and Keep in one row of icon-and-short-word buttons); during a guided Lens replay
//          it folds further to header, result and buttons. Nudge rows put their label on its own line above minus,
//          readout and plus, and the readout may shrink a little. The scrub row's What if button keeps its slot (shown
//          or hidden by opacity), so the scrub bar never changes width. The picker falls back to a menu when its
//          segments do not fit.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, plans/22-Nov-2026-phone-ui-plan.md Part 3: on the
//          upright phone the what-if is two pieces instead of the card. WhatIfPhonePanel takes the aiming panel's place
//          in the bottom bar, regular glass sized to its content: the title with Reset, Keep this one (the white capsule,
//          when the mode can retry with it) and Close, the setting picker, and the chosen setting's nudge rows (room kept
//          for the tallest setting, so the table does not reframe between settings). WhatIfPhoneBlurb is the result as a
//          docked blurb: the sentences folded to two lines, the rest behind a tap, with Play both and Where they part
//          as its two small buttons. The card's close button is glass instead of bordered. The text rules (full and
//          short result) are shared statics, so card, panel and blurb say the same words. The card is unchanged elsewhere.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan Part 3: WhatIfPhoneBlurb is now an anchored blurb,
//          not a docked one. ShowpieceView mounts it as a full-stage layer; it sits above or below where the two
//          futures part (or the other cue ball's rest), keeps its place for the whole result, and a violet leader that
//          follows the camera joins it to that point. Same words and buttons as before.)
// PURPOSE: The what-if replay's controls. WhatIfButton is the entry in the playback row beside Replay (a branch
//          symbol), shown only while model.whatIf.canOpen and the what-if is not already up. WhatIfCard is the card in
//          the card slot (below the table on a phone, in the notebook on iPad, Mac and the open Duo, so nothing covers
//          the table): the title and a fixed line, a segmented choice of Aim, Power, Spin (follow or draw, and side)
//          and, for a raised cue, Cue angle; each setting a row of two glass buttons with the offset between them
//          ("0.25° left"), adjustable by VoiceOver; Reset; the sentences about the other future (WhatIfWords); Play
//          both, Where they part, and Keep this one only when the mode can retry with it (absent otherwise, not
//          disabled); and Close. On a phone held upright the compact form (see WhatIfCard.compactCard) keeps one
//          steady height so the table never reframes between nudges. A selection haptic on each click when Vibration
//          is on. Nothing plays by itself. ShowpieceView and NotebookPanel mount both (the foundation's mounts);
//          PlaybackControls places the button.
//          On the upright phone the card gives way to two pieces: WhatIfPhonePanel (the nudge controls, in the aiming
//          panel's place) and WhatIfPhoneBlurb (the result, an anchored blurb at the point where the two futures part,
//          not docked).
// SRP/DRY check: Pass - the card follows TableClearedCard's glass card and ComparisonCard's close button; the words are
//          WhatIfWords, the state WhatIfFork. Nothing else draws what-if controls. The compact form reuses the same
//          header, picker, rows and actions as the full one; only their arrangement and the result's room differ.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// The "What if" entry beside Replay; shown only while model.whatIf.canOpen and not already showing.
struct WhatIfButton: View {
    let model: ShowpieceModel
    /// Stretch the label to the full row (the stacked buttons at the accessibility text sizes).
    var fill = false
    /// Keep the button's slot while it is not offered (0.7.6, bug 31): in the scrub row it is drawn invisible and
    /// disabled instead of removed, so the scrub bar beside it never changes width as shots come to rest or the card
    /// opens. In a match, which never offers a what-if, no slot is kept, so the bar has the room. The stacked rows at
    /// the accessibility text sizes leave this off: a whole empty row there would cost the table its height.
    var reserveSlot = false

    private var offered: Bool { model.whatIf.canOpen && !model.whatIf.isShowing }

    var body: some View {
        if offered {
            button
        } else if reserveSlot && model.match == nil {
            button
                .opacity(0)
                .disabled(true)
                .accessibilityHidden(true)
        }
    }

    private var button: some View {
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

/// The what-if card in the card slot; shown only while model.whatIf.isShowing.
struct WhatIfCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    /// Phone held upright during a guided Lens replay (ShowpieceView's bottom stack sets it): the card folds to its
    /// header, the result line and the buttons, as the mode cards fold to theirs (bug 28).
    @Environment(\.lensReplayCompact) private var lensReplayCompact
    /// In the notebook (iPad, Mac, the open folding phone) the card keeps its full form beside the table.
    @Environment(\.inlinePages) private var inlinePages
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    /// The compact form's result opened to all its sentences (a tap on the result line); closed again on every open.
    @State private var resultOpen = false

    private var fork: WhatIfFork { model.whatIf }

    /// The compact form: a phone held upright (narrow and tall size classes, outside the notebook), where the card sits
    /// under the table and every point of its height is taken from the table; and any guided Lens replay that slims
    /// the cards. Sideways the card is in the side column beside the table, where its height costs the table nothing.
    private var compact: Bool {
        if lensReplayCompact { return true }
        #if os(iOS)
        return !inlinePages && horizontalSizeClass == .compact && verticalSizeClass == .regular
        #else
        return false
        #endif
    }

    var body: some View {
        // The haptic sits on the always-present Group, so each click (or Reset) fires it once; a close, which also
        // zeroes the steps, does not.
        Group {
            if fork.isShowing, let real = fork.real {
                if compact { compactCard(real, slim: lensReplayCompact) } else { card(real) }
            }
        }
        .sensoryFeedback(trigger: fork.clicks) { _, _ in GameSettings.hapticsOn ? .selection : nil }
        .onChange(of: fork.isShowing) { _, showing in if !showing { resultOpen = false } }
    }

    // MARK: The full card (notebook, side column)

    private func card(_ real: ShotAttempt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: false)
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

    // MARK: The compact card (a phone held upright)

    /// One steady height whatever the player does short of opening the result: the header keeps Reset (disabled at
    /// the played shot) so its row never grows, the nudge area keeps room for the tallest section, the result keeps
    /// two lines, and the button row is always there with Play both and Split (disabled until there is something to
    /// play or a parting point). `slim` (a guided Lens replay) leaves out the picker and the rows: the player is
    /// watching then, and the explanation strip above needs the room.
    private func compactCard(_ real: ShotAttempt, slim: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(compact: true)
            if !slim {
                sectionPicker
                nudgeArea(real)
            }
            compactResult(real)
            compactButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .accessibilityElement(children: .contain)
        .transition(.opacity)
    }

    /// Every section's rows laid over each other, only the chosen one visible: the area is as tall as the tallest
    /// section (Spin's two rows), so switching from Aim to Spin does not reframe the table. The others are invisible,
    /// untouchable and silent to VoiceOver.
    private func nudgeArea(_ real: ShotAttempt) -> some View { WhatIfNudgeArea(model: model, real: real) }

    /// The short result: the trick verdict and the outcome (or the prompt, the working line, the too-long line), in a
    /// room of two lines. A tap opens all the sentences in a fixed room of five lines that scrolls, so nudging while it
    /// is open does not change the card's height either; another tap closes it. VoiceOver always reads every sentence.
    private func compactResult(_ real: ShotAttempt) -> some View {
        let full = fullText(real)
        let short = shortText(real)
        let canOpen = fork.result != nil
        return HStack(alignment: .top, spacing: 8) {
            Group {
                if resultOpen && canOpen {
                    // The room is a blank five-line text; the sentences scroll inside it, laid over it.
                    Text(verbatim: " ")
                        .font(Theme.body)
                        .lineLimit(5, reservesSpace: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0)
                        .overlay(alignment: .topLeading) {
                            ScrollView {
                                Text(full)
                                    .font(Theme.body)
                                    .foregroundStyle(palette.paper.opacity(fork.solving ? 0.6 : 1))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .scrollBounceBehavior(.basedOnSize)
                        }
                } else {
                    Text(short)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper.opacity(fork.solving ? 0.6 : 1))
                        .lineLimit(2, reservesSpace: true)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { if canOpen { resultOpen.toggle() } }
            // The spinner's room is kept, so the line never re-wraps when a solve starts or lands.
            ZStack {
                ProgressView().controlSize(.small).opacity(fork.showSpinner ? 1 : 0)
                Image(systemName: resultOpen ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.paper.opacity(0.7))
                    .opacity(canOpen && !fork.showSpinner ? 1 : 0)
            }
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
            .onTapGesture { if canOpen { resultOpen.toggle() } }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fork.showSpinner ? WhatIfWords.working : full)
    }

    /// Play both, Split and Keep in one row, icon and a short word each; icons alone when even that does not fit (the
    /// largest text sizes). Play both and Split stay in the row, disabled until there is a result (or a parting point),
    /// so the row is there from the moment the card opens; Keep comes only when the mode can retry with it, as in the
    /// full card. The full names stay as their VoiceOver labels.
    private var compactButtons: some View {
        ViewThatFits(in: .horizontal) {
            compactButtonRow(words: true)
            compactButtonRow(words: false)
        }
        .controlSize(.regular)
    }

    private func compactButtonRow(words: Bool) -> some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            compactButton(String(localized: "Short: Play both", defaultValue: "Play both",
                                 comment: "Short label on the what-if card's button that plays the shot and the other version together; one or two short words"),
                          full: String(localized: "Play both"), symbol: "play.fill", words: words) { fork.playBoth() }
                .buttonStyle(.glass)
                .disabled(fork.result == nil)
                .accessibilityHint(String(localized: "Plays your shot again with the other future rolling beside it"))
            compactButton(String(localized: "Short: Where they part", defaultValue: "Split",
                                 comment: "Short label on the what-if card's button that jumps the replay to the moment the two versions of the shot part ways; one short word"),
                          full: String(localized: "Where they part"), symbol: "diamond", words: words) {
                fork.jumpToParting()
            }
            .buttonStyle(.glass)
            .disabled(fork.result?.fork.marker == nil)
            if fork.canKeep {
                compactButton(String(localized: "Short: Keep this one", defaultValue: "Keep",
                                     comment: "Short label on the what-if card's button that sets up the next try with this version's settings; one short word"),
                              full: String(localized: "Keep this one"), symbol: "checkmark", words: words) { fork.keep() }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                    .accessibilityHint(String(localized: "Sets up your next try with this version's settings"))
            }
        }
    }

    private func compactButton(_ short: String, full: String, symbol: String, words: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if words {
                    Label(short, systemImage: symbol).lineLimit(1)
                } else {
                    Label(short, systemImage: symbol).labelStyle(.iconOnly)
                }
            }
            .font(.headline)
            .fixedSize()
            .frame(minHeight: CallMetrics.buttonHeight)
        }
        .accessibilityLabel(full)
    }

    private func fullText(_ real: ShotAttempt) -> String { Self.fullText(fork, real: real) }
    private func shortText(_ real: ShotAttempt) -> String { Self.shortText(fork, real: real) }

    /// Every sentence about the other future, or the one line that stands in for them. Shared with the upright phone's
    /// result blurb (WhatIfPhoneBlurb).
    static func fullText(_ fork: WhatIfFork, real: ShotAttempt) -> String {
        if let r = fork.result { return WhatIfWords.sentences(r, real: real).joined(separator: " ") }
        return standIn(fork)
    }

    /// What matters most: the trick verdict and the outcome; the change itself is already on the nudge row.
    static func shortText(_ fork: WhatIfFork, real: ShotAttempt) -> String {
        guard let r = fork.result else { return standIn(fork) }
        return ([WhatIfWords.verdict(r)].compactMap { $0 } + [WhatIfWords.outcome(r, real: real)]).joined(separator: " ")
    }

    /// Before there is a result: too long to show, the prompt, or working it out.
    static func standIn(_ fork: WhatIfFork) -> String {
        if fork.tooLong { return WhatIfWords.tooLong }
        if fork.steps.isZero { return WhatIfWords.prompt }
        return WhatIfWords.working
    }

    // MARK: Shared parts

    /// The title row. The compact form keeps Reset in the row at all times (disabled at the played shot), so the row's
    /// height never changes when it would otherwise appear.
    private func header(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch").foregroundStyle(palette.whatIf).accessibilityHidden(true)
            Text(WhatIfWords.title).font(Theme.heading).lineLimit(1).accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if compact || !fork.steps.isZero {
                Button { fork.reset() } label: {
                    Label(String(localized: "Reset"), systemImage: "arrow.uturn.backward").font(.subheadline).lineLimit(1)
                }
                .buttonStyle(.glass)
                .disabled(fork.steps.isZero)
                .accessibilityHint(String(localized: "Puts every setting back to the shot you played"))
            }
            Button { fork.close() } label: {
                Image(systemName: "xmark").frame(width: 30, height: 30)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "Close"))
        }
    }

    private var sectionPicker: some View { WhatIfSectionPicker(fork: fork) }

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

/// The setting picker: segments when they all fit, a menu of the same choices when they do not (the fourth segment,
/// Cue angle, was cut short in several languages and in the side column; bug 27). Nothing with a single setting.
/// Shared by the card and the upright phone's nudge panel.
private struct WhatIfSectionPicker: View {
    let fork: WhatIfFork

    var body: some View {
        let sections = fork.sections
        if sections.count > 1 {
            ViewThatFits(in: .horizontal) {
                picker(sections).pickerStyle(.segmented)
                picker(sections).pickerStyle(.menu)
            }
        }
    }

    private func picker(_ sections: [WhatIfFork.Section]) -> some View {
        Picker(String(localized: "Setting"), selection: Binding(get: { fork.section }, set: { fork.section = $0 })) {
            ForEach(sections, id: \.self) { s in Text(WhatIfWords.sectionLabel(s)).tag(s) }
        }
        .labelsHidden()
    }
}

/// Every section's rows laid over each other, only the chosen one visible: the area is as tall as the tallest section
/// (Spin's two rows), so switching from Aim to Spin does not reframe the table. The others are invisible, untouchable
/// and silent to VoiceOver. Shared by the compact card and the upright phone's nudge panel (`onGlass`: the rows' step
/// buttons are drawn as content on the panel's glass, PhonePanelControl, instead of glass buttons).
private struct WhatIfNudgeArea: View {
    let model: ShowpieceModel
    let real: ShotAttempt
    var onGlass = false

    var body: some View {
        let fork = model.whatIf
        ZStack(alignment: .topLeading) {
            ForEach(fork.sections, id: \.self) { s in
                let chosen = s == fork.section
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fork.controls(in: s), id: \.self) { c in
                        NudgeRow(model: model, control: c, real: real, onGlass: onGlass)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .opacity(chosen ? 1 : 0)
                .allowsHitTesting(chosen)
                .disabled(!chosen)
                .accessibilityHidden(!chosen)
            }
        }
    }
}

/// One setting's row: its name on its own line, then a button each way with the offset between them; one adjustable
/// element for VoiceOver. The name sits above (0.7.6, bug 27) so a long name ("Nachläufer oder Rückläufer") and a long
/// readout ("2,5 mm más arriba") never share one line and cut each other to an ellipsis, in a narrow side column too.
private struct NudgeRow: View {
    let model: ShowpieceModel
    let control: WhatIfFork.Control
    let real: ShotAttempt
    /// On the upright phone's nudge panel: the step buttons are content on the panel's glass, not glass themselves.
    var onGlass = false
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

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
        VStack(alignment: .leading, spacing: 4) {
            Text(WhatIfWords.label(control))
                .font(Theme.label)
                .foregroundStyle(palette.paper.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                step(symbols.left, delta: leftDelta)
                // The readout fills the room between the buttons. One line, shrinking a little when long; at the
                // accessibility text sizes it may take two lines instead, with the room for both kept, so the row's
                // height does not change from one click to the next.
                Text(readout)
                    .font(Theme.number)
                    .foregroundStyle(fork.steps[control] == 0 ? palette.paper.opacity(0.7) : palette.whatIf)
                    .multilineTextAlignment(.center)
                    .lineLimit(typeSize.isAccessibilitySize ? 2 : 1, reservesSpace: true)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                step(symbols.right, delta: rightDelta)
            }
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

    @ViewBuilder
    private func step(_ symbol: String, delta: Int) -> some View {
        if onGlass {
            // On the phone's glass panel: a plain button on a faint circle, 44 to touch (no glass on glass).
            Button { fork.nudge(control, by: delta) } label: {
                Image(systemName: symbol)
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .modifier(PhonePanelControl(shape: .circle))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!fork.canStep(control, by: delta))
        } else {
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
}

// MARK: The upright phone

/// The what-if's nudge controls on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, "The aiming panel": "its
/// nudge controls take the panel's place, sized to their content"). ShowpieceView shows it in the bottom bar's glass
/// container instead of PhoneAimPanel while model.whatIf.isShowing. One regular glass shape, the controls drawn on it as
/// content: the title with Reset, Keep this one (the white capsule, only when the mode can retry with it) and Close;
/// the setting picker; the chosen setting's nudge rows, with room kept for the tallest setting so the table does not
/// reframe as the player switches. The result is not here: it is WhatIfPhoneBlurb, anchored over the table. A selection
/// haptic on each click when Vibration is on, as the card.
struct WhatIfPhonePanel: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    private var fork: WhatIfFork { model.whatIf }

    var body: some View {
        Group {
            if fork.isShowing, let real = fork.real {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    WhatIfSectionPicker(fork: fork)
                    WhatIfNudgeArea(model: model, real: real, onGlass: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: PhoneAimPanel.corner, style: .continuous))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(WhatIfWords.title)
            }
        }
        .sensoryFeedback(trigger: fork.clicks) { _, _ in GameSettings.hapticsOn ? .selection : nil }
    }

    /// The title, then Reset, Keep and Close at the right. When the row does not fit (a long language, large text) the
    /// title steps out first (VoiceOver still hears it on the panel), then the buttons stack.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { title; Spacer(minLength: 0); buttons }
            HStack(spacing: 8) { Spacer(minLength: 0); buttons }
            VStack(alignment: .trailing, spacing: 8) { buttons }.frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var title: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.branch").foregroundStyle(palette.whatIf).accessibilityHidden(true)
            Text(WhatIfWords.title).font(Theme.phoneTitle).lineLimit(1).accessibilityAddTraits(.isHeader)
        }
        .fixedSize()
    }

    @ViewBuilder private var buttons: some View {
        Button { fork.reset() } label: {
            Text(String(localized: "Reset"))
                .font(Theme.phoneControl).lineLimit(1)
                .padding(.horizontal, 14).frame(minHeight: 44)
                .modifier(PhonePanelControl(shape: .capsule))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .disabled(fork.steps.isZero)
        .opacity(fork.steps.isZero ? 0.45 : 1)
        .accessibilityHint(String(localized: "Puts every setting back to the shot you played"))
        // Present only when the mode can retry with it: absent, not disabled, otherwise (as the card).
        if fork.canKeep {
            Button { fork.keep() } label: {
                Text(String(localized: "Keep this one"))
                    .font(Theme.phoneControl).lineLimit(1)
                    .padding(.horizontal, 16).frame(minHeight: 44)
                    .foregroundStyle(palette.ground)
                    .background(.white, in: .capsule)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .fixedSize()
            .accessibilityHint(String(localized: "Sets up your next try with this version's settings"))
        }
        Button { fork.close() } label: {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .modifier(PhonePanelControl(shape: .circle))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Close"))
    }
}

/// The what-if's result on the upright phone (plans/22-Nov-2026-phone-ui-plan.md Part 3, "The aiming panel": "its result
/// is an anchored blurb"): every sentence about the other future, folded to two lines (the verdict and the outcome come
/// first, so the fold keeps what matters most), the rest behind a tap. Play both and Where they part are its two small
/// buttons once there is a result (Where they part only with a parting point). Before a result it says the prompt, that
/// it is working, or that the shot is too long to show. It is anchored, as PhoneExplanationBlurb is, to where the two
/// futures part (the violet diamond WhatIfOverlay draws), or with no parting point to where the other cue ball comes to
/// rest; with neither (or no room either side) it sits at the top of the table area with no leader. A violet leader
/// joins it to its anchor and follows the camera every frame; the blurb itself never moves during a beat (its place is
/// worked out only for a new result, when it opens or folds, or when the table area changes). A full-stage layer that
/// takes touches only on the blurb; nothing while the what-if is not showing.
struct WhatIfPhoneBlurb: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    /// Where blurbs may go, in StageSpace: under the title row (or the lowest docked blurb), above the control bar.
    let tableArea: CGRect

    @Environment(\.palette) private var palette
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Where the blurb was put for a result: its frame in StageSpace, the side of the anchor it took (nil: docked at
    /// the top of the table area, no leader) and the leader's end on its near edge. Kept for the whole beat.
    private struct Placed: Equatable {
        let version: Int
        let frame: CGRect
        let side: BlurbPlacement.Side?
        let leaderTo: CGPoint
    }

    @State private var placed: Placed? = nil
    /// The blurb's measured size (it follows its words, and grows when opened).
    @State private var size: CGSize = .zero
    /// This layer's top-left corner in StageSpace, and its size (the projection's screen).
    @State private var origin: CGPoint = .zero
    @State private var layerSize: CGSize = .zero
    @State private var cameraBox = AimProjector.CameraBox()

    /// Marks on the cloth sit just above it, as WhatIfOverlay draws them, so the leader meets the diamond exactly.
    private static let onCloth: Float = 0.001
    /// What the blurb keeps clear of around its anchor: the diamond is 12 points across, plus a little air.
    private static let clearSide: CGFloat = 24

    private var fork: WhatIfFork { model.whatIf }

    var body: some View {
        let shown = placed?.version == fork.resultVersion ? placed : nil
        ZStack(alignment: .topLeading) {
            // Fills the stage so the offsets below are from its corner; never takes a touch (aiming passes through).
            Color.clear.allowsHitTesting(false)
            if fork.isShowing, let real = fork.real {
                if let shown, shown.side != nil {
                    // Re-projected every frame so the leader follows the camera while the blurb stays put.
                    TimelineView(.animation) { _ in
                        if let anchor = anchorPoint() {
                            BlurbLeader(from: local(anchor), to: local(shown.leaderTo), colour: palette.whatIf)
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                Blurb(sentence: WhatIfCard.fullText(fork, real: real), foldedLines: 2, buttons: buttons)
                    .opacity(fork.solving ? 0.6 : 1)
                    // The words keep the reader's direction; only the placement is in screen points.
                    .environment(\.layoutDirection, layoutDirection)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { new in
                        size = new
                        place(keepSide: true)
                    }
                    // Offered the table area's width less its margins; the blurb takes only what its words need.
                    .frame(width: max(0, tableArea.width - 2 * BlurbPlacement.margin), alignment: .topLeading)
                    .offset(x: (shown?.frame.minX ?? 0) - origin.x, y: (shown?.frame.minY ?? 0) - origin.y)
                    // Unseen and silent until it has a place, so it never flashes at the corner.
                    .opacity(shown == nil ? 0 : 1)
                    .accessibilityHidden(shown == nil)
                    .transition(Blurb.transition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Placed in screen points from the 3D projection, which does not mirror for right-to-left languages.
        .environment(\.layoutDirection, .leftToRight)
        // The same screen WhatIfOverlay projects onto (it ignores the safe area too), so the anchor is the diamond.
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
            origin = frame.origin
            layerSize = frame.size
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: fork.isShowing)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: placed)
        // A new result (or the first words): placed afresh, below its anchor first.
        .onChange(of: fork.resultVersion) { _, _ in place(keepSide: false) }
        // The table area moved (a docked blurb came or went, the bar grew): placed again, same side first.
        .onChange(of: tableArea) { _, _ in place(keepSide: true) }
        // Closed: forget the place, so the next what-if never opens at a stale spot.
        .onChange(of: fork.isShowing) { _, showing in if !showing { placed = nil } }
    }

    private var buttons: [BlurbButton] {
        guard fork.result != nil else { return [] }
        var list = [BlurbButton(String(localized: "Play both"),
                                hint: String(localized: "Plays your shot again with the other future rolling beside it")) {
            fork.playBoth()
        }]
        if fork.result?.fork.marker != nil {
            list.append(BlurbButton(String(localized: "Where they part")) { fork.jumpToParting() })
        }
        return list
    }

    // MARK: Placement (all in StageSpace)

    /// The anchor on screen, in StageSpace: the parting marker, or with none the other cue ball's rest (unless it
    /// dropped); nil with neither, or when the table is not up or the point is behind the camera. Projected exactly
    /// as WhatIfOverlay.draw projects the diamond.
    private func anchorPoint() -> CGPoint? {
        guard let r = fork.result, layerSize.width > 0, layerSize.height > 0 else { return nil }
        let point = r.fork.marker?.point ?? (r.alternate.cueBallScratched ? nil : r.alternate.cueRest)
        guard let point, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: layerSize,
                                      frame: TableFrame(model.timeline.table)),
              let screen = proj.screen(point, height: Self.onCloth)
        else { return nil }
        return CGPoint(x: screen.x + origin.x, y: screen.y + origin.y)
    }

    /// Works out the blurb's place for the result on screen. keepSide: try the side it already has first (an opened
    /// blurb stays on its side of the anchor); otherwise below first.
    private func place(keepSide: Bool) {
        guard fork.isShowing, size.width > 0, size.height > 0, tableArea.height > 0 else { return }
        let version = fork.resultVersion
        let current = placed?.version == version ? placed : nil
        let preferred: BlurbPlacement.Side = keepSide ? (current?.side ?? .below) : .below
        let next: Placed
        if let anchor = anchorPoint(),
           let anchored = BlurbPlacement.anchored(
               anchor: anchor, size: size, tableArea: tableArea,
               keepClear: CGRect(x: anchor.x - Self.clearSide / 2, y: anchor.y - Self.clearSide / 2,
                                 width: Self.clearSide, height: Self.clearSide),
               preferred: preferred) {
            next = Placed(version: version, frame: anchored.frame, side: anchored.side, leaderTo: anchored.leaderTo)
        } else {
            // No anchor, or no room either side: at the top of the table area, at the left margin, with no leader.
            let frame = BlurbPlacement.dockedFrames(sizes: [size], top: tableArea.minY + BlurbPlacement.dockSpacing,
                                                    area: tableArea)[0]
            next = Placed(version: version, frame: frame, side: nil, leaderTo: .zero)
        }
        if placed != next { placed = next }
    }

    /// A StageSpace point in this layer's own space.
    private func local(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x - origin.x, y: p.y - origin.y) }
}
