// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: Your shot is plain and disabled during the
//          computer's turn on iPhone and iPad).
// Edited: Claude Opus 5.5 High, 21-November-2026 (Replay moved into the scrub row beside the speed menu, so Physics
//          Lens, Ride and Your shot share one centred row instead of leaving Your shot alone on a second row).
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (fewer rows over the table on a phone: play and pause sit in the
//          scrub row, speed is a small menu instead of four segments, and the scrub row steps aside while aiming).
// Edited: Claude Opus 5.5 High, 20-November-2026 (a Ride toggle beside the Lens: the replay camera rides behind the
//          cue ball and the ball it hits; in every layout, including the largest text sizes).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the Lens is named clearly: its button reads "Physics Lens" wherever
//          that fits and falls back to "Lens", decided by the same one measurement that picks one row or two; VoiceOver
//          always says "Physics Lens". Existing strings only.)
// PURPOSE: The playback controls, built from standard parts: system buttons in Liquid Glass, SF Symbols with the
//          standard replace and bounce symbol effects, a segmented picker for speed (a menu at the largest text
//          sizes), and two toggle-style buttons (Lens, Your shot) whose label never changes, so nothing beside them
//          can shift. The small pieces (PlayPauseButton, SpeedPicker, ReplayButton) are also used by the Mac toolbar
//          (ToggleButton is the iPhone and iPad version of the Lens and Your shot toggles; the Mac toolbar uses the
//          system's own toggle buttons). PlaybackControls lays them out at the bottom of the screen, or in the side
//          column on a phone turned sideways; on the Mac it shows only the scrub bar because the toolbar has the buttons.
//          Writes to the model only through its own play, rate, Lens and replay methods.
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (compact: regular-size buttons for a narrow column, used by the iPhone Duo's panel.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 8: the scrub
//          row (play and pause, the scrub bar, speed and Replay with the Lens) no longer steps aside for Your shot
//          whenever one of the shots struck at this table is on screen (ShowpieceModel.playerShotOnScreen). It sits as a
//          slim row under the shot panel, so watching your own shot slowly in the Lens no longer means closing the
//          panel, replaying and opening it again. On a still table it still gives the panel its place.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream: What if sits beside Replay in the scrub row (and
//          after the time on the Mac; a worded full-width row in the stacked buttons at the accessibility text sizes); the speed list starts with Auto, which hands the pace back to the paced replay
//          (it used to drop that choice silently); Replay's hint no longer promises slow motion while Ride is on.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream what-if, bugs 12 and 31 of
//          plans/22-Nov-2026-phone-bug-hunt.md: the speed button in the scrub row says Auto with its own short catalog
//          key, so a long translation of the menu's Auto no longer squeezes the scrub bar; the list row and VoiceOver
//          keep the full word. The What if button keeps its slot in the scrub row, so the bar never changes width.)
// SRP/DRY check: Pass - split out of ShowpieceView, which had separate chip and round-button builders; one
//          ToggleButton now serves both iPhone and iPad toggles.
import SwiftUI

enum PlaybackSpeed {
    static let rates: [Double] = [0.1, 0.25, 0.5, 1.0]
    static func label(_ r: Double) -> String { r.formatted(.number.precision(.fractionLength(0...2))) + "×" }
}

// MARK: Pieces

struct PlayPauseButton: View {
    let model: ShowpieceModel
    /// Stretch the label to the full row (the stacked layout at the largest text sizes).
    var fill = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let isPlaying = model.playing && model.time < model.duration
        Button { model.togglePlay() } label: {
            Label {
                Text(isPlaying ? "Pause" : "Play")
            } icon: {
                // The standard replace effect morphs play into pause; the system skips it under Reduce Motion.
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(maxWidth: fill ? .infinity : nil)
        }
        .animation(reduceMotion ? nil : .default, value: isPlaying)
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
        .accessibilityHint("Plays or pauses the replay")
    }
}

struct ReplayButton: View {
    let model: ShowpieceModel
    var fill = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            model.replay(withLens: true)
        } label: {
            Label("Replay", systemImage: "arrow.counterclockwise")
                // Bounce once per tap; with Reduce Motion the trigger never changes, so nothing moves.
                .symbolEffect(.bounce, value: reduceMotion ? 0 : taps)
            }
        // With Ride on the replay rides behind the cue ball at the chosen pace, so slow motion is not promised then.
        .accessibilityHint(model.rideOn ? String(localized: "Starts the shot again with the Lens on")
                                        : String(localized: "Starts the shot again in slow motion with the Lens on"))
    }
}

/// A button that stays on or off. Its label is constant, so its width never changes; state is shown by the tint
/// and spoken as a toggle with an on or off value.
struct ToggleButton: View {
    let title: LocalizedStringKey
    let symbol: String
    let isOn: Bool
    var fill = false
    let action: () -> Void
    @Environment(\.palette) private var palette

    private var button: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .lineLimit(1)
                .fixedSize(horizontal: !fill, vertical: false)
                .frame(maxWidth: fill ? .infinity : nil)
        }
        .tint(isOn ? palette.accent : nil)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }

    var body: some View {
        #if os(iOS)
        // Floating over the scene: switched on is a solid accent glass button with dark text, off is plain glass.
        if isOn {
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
        #else
        button
        #endif
    }
}

struct SpeedPicker: View {
    let model: ShowpieceModel
    /// A menu instead of a segmented control, for the largest text sizes and for narrow toolbars.
    var asMenu = false

    private var selection: Binding<Double?> {
        // Auto (nil) while the replay paces itself; a fixed speed hands the pace to the player, and Auto hands it back.
        Binding(get: { model.chosenRate }, set: { if let r = $0 { model.setRate(r) } else { model.setAutoRate() } })
    }

    private var picker: some View {
        Picker("Speed", selection: selection) {
            Text(String(localized: "Auto")).tag(Double?.none)
            ForEach(PlaybackSpeed.rates, id: \.self) { r in
                Text(PlaybackSpeed.label(r)).tag(Optional(r))
            }
        }
    }

    /// The speed button's label while the replay paces itself.
    static var autoShort: String {
        String(localized: "Speed: Auto", defaultValue: "Auto",
               comment: "Short label on the speed button beside the scrub bar while the replay sets its own pace; one short word")
    }

    var body: some View {
        Group {
            if asMenu {
                // A small button that names the current speed ("Auto" while the opening paces itself) and opens the list.
                Menu {
                    picker.pickerStyle(.inline)
                } label: {
                    // Its own key (0.7.6, bug 12): one short word in every language, where the list row's Auto may be
                    // a long one ("Automatisch").
                    Text(model.chosenRate.map(PlaybackSpeed.label) ?? Self.autoShort)
                        .lineLimit(1)
                        .monospacedDigit()
                }
                .menuIndicator(.hidden)
            } else {
                picker.pickerStyle(.segmented)
            }
        }
        .accessibilityLabel("Playback speed")
        .accessibilityValue(model.chosenRate.map(PlaybackSpeed.label) ?? String(localized: "Automatic"))
    }
}

// MARK: The bar

struct PlaybackControls: View {
    let model: ShowpieceModel
    @Binding var shotPanelOpen: Bool
    /// Regular-size buttons, so Lens, Ride and Your shot share one row in a narrow column (the iPhone Duo's panel).
    var compact = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 8) {
            // While aiming on a still table the shot panel takes this place. Whenever a shot struck at this table is on
            // screen the row stays, slim, under the panel, so the player can replay and scrub their own shot (item 8).
            if !shotPanelOpen {
                scrubRow
            } else if model.playerShotOnScreen {
                scrubRow.controlSize(.small)
            }
            #if os(iOS)
            buttons   // on the Mac these live in the window toolbar
            #endif
        }
    }

    private var scrubRow: some View {
        HStack(spacing: 10) {
            #if os(iOS)
            PlayPauseButton(model: model).labelStyle(.iconOnly).buttonBorderShape(.circle)
                .buttonStyle(.plain).frame(minWidth: 44, minHeight: 44)
            #endif
            ScrubBar(model: model)
            #if os(iOS)
            // On a phone the speed lives here, where the time read-out was: one fewer row over the table.
            SpeedPicker(model: model, asMenu: true).fixedSize().buttonStyle(.plain).frame(minHeight: 44)
            // Replay lives in the scrub row too (it is a playback control), so the button row below has room for
            // Physics Lens, Ride and Your shot on one line instead of leaving Your shot alone on a second row.
            ReplayButton(model: model).labelStyle(.iconOnly).buttonStyle(.plain).frame(minWidth: 44, minHeight: 44)
            // What if, beside Replay: only after the player's own shot has come to rest (invisible otherwise, its
            // slot kept so the scrub bar does not change width; 0.7.6, bug 31). At the accessibility text sizes it is a
            // worded full-width row in the stacked buttons instead.
            if !typeSize.isAccessibilitySize {
                WhatIfButton(model: model, reserveSlot: true).labelStyle(.iconOnly).buttonStyle(.plain)
            }
            #else
            if !typeSize.isAccessibilitySize { TimeReadout(model: model) }
            WhatIfButton(model: model, reserveSlot: true).labelStyle(.iconOnly).buttonStyle(.plain)
            #endif
        }
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: Buttons (iPhone and iPad)

    /// The Lens toggle. `full` picks the clear name "Physics Lens"; the short "Lens" is the fallback for tight rows.
    /// Not a ViewThatFits of its own: inside a row it would always be offered the whole width (the Spacer gives way)
    /// and pick the long name, which would make the outer ViewThatFits think one row fits when it does not. Instead
    /// `buttons` lists long and short versions of each layout and one measurement chooses.
    private func lens(full: Bool, fill: Bool = false) -> some View {
        ToggleButton(title: full ? "Physics Lens" : "Lens", symbol: "viewfinder", isOn: model.lensOn, fill: fill) {
            model.setLens(!model.lensOn)
        }
        .accessibilityLabel("Physics Lens")
    }

    /// Ride: the replay camera chases the cue ball. Named "Ride" on the button and spoken in full. (Its old hint said
    /// it hands over to the ball it hits; it no longer does, and no new string is wanted, so the hint is gone.)
    private func ride(fill: Bool = false) -> some View {
        ToggleButton(title: "Ride", symbol: "video", isOn: model.rideOn, fill: fill) { model.setRide(!model.rideOn) }
            .accessibilityLabel("Ride camera")
    }

    /// The computer is thinking or shooting (0.7.5, L-A): Your shot is drawn plain and cannot be pressed, so it never
    /// looks like the person's turn while it is not.
    private var computersTurn: Bool { model.computerTurnStage != .none }

    private var shot: some View {
        ToggleButton(title: "Your shot", symbol: "target", isOn: shotPanelOpen && !computersTurn) { shotPanelOpen.toggle() }
            .disabled(computersTurn)
    }

    private var buttons: some View {
        GlassEffectContainer(spacing: 8) {
            Group {
                if typeSize.isAccessibilitySize {
                    stacked
                } else {
                    // Widest first: the full Lens name on one row, the short name on one row, then the same on two.
                    ViewThatFits(in: .horizontal) {
                        oneRow(fullLens: true)
                        oneRow(fullLens: false)
                        twoRows(fullLens: true)
                        twoRows(fullLens: false)
                    }
                }
            }
            .buttonStyle(.glass)
            .controlSize(compact ? .regular : .large)
        }
    }

    private func oneRow(fullLens: Bool) -> some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            lens(full: fullLens)
            ride()
            shot
            Spacer(minLength: 0)
        }
    }

    /// Narrow columns (a phone turned sideways, a small window) and narrow phones.
    private func twoRows(fullLens: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                lens(full: fullLens)
                ride()
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) { Spacer(minLength: 0); shot; Spacer(minLength: 0) }
        }
    }

    /// Largest text sizes: everything full width, one control per row, with words on every button.
    private var stacked: some View {
        VStack(spacing: 8) {
            // A full-width row: the long name nearly always fits; the short one is the fallback at the very largest sizes.
            ViewThatFits(in: .horizontal) {
                lens(full: true, fill: true)
                lens(full: false, fill: true)
            }
            ride(fill: true)
            ToggleButton(title: "Your shot", symbol: "target", isOn: shotPanelOpen && !computersTurn, fill: true) { shotPanelOpen.toggle() }
                .disabled(computersTurn)
            // The what-if entry with its words, where the scrub row's icon-only buttons are hardest to read.
            WhatIfButton(model: model, fill: true)
        }
    }
}
