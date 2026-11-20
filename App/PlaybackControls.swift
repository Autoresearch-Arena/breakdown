// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (fewer rows over the table on a phone: play and pause sit in the
//          scrub row, speed is a small menu instead of four segments, and the scrub row steps aside while aiming).
// Edited: Claude Opus 5.5 High, 20-November-2026 (a Ride toggle beside the Lens: the replay camera rides behind the
//          cue ball and the ball it hits; in every layout, including the largest text sizes).
// PURPOSE: The playback controls, built from standard parts: system buttons in Liquid Glass, SF Symbols with the
//          standard replace and bounce symbol effects, a segmented picker for speed (a menu at the largest text
//          sizes), and two toggle-style buttons (Lens, Your shot) whose label never changes, so nothing beside them
//          can shift. The small pieces (PlayPauseButton, SpeedPicker, ReplayButton) are also used by the Mac toolbar
//          (ToggleButton is the iPhone and iPad version of the Lens and Your shot toggles; the Mac toolbar uses the
//          system's own toggle buttons). PlaybackControls lays them out at the bottom of the screen, or in the side
//          column on a phone turned sideways; on the Mac it shows only the scrub bar because the toolbar has the buttons.
//          Writes to the model only through its own play, rate, Lens and replay methods.
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
        .accessibilityHint("Starts the shot again in slow motion with the Lens on")
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
        // Nothing is selected while the cold open paces itself; the first tap hands the pace to the player.
        Binding(get: { model.chosenRate }, set: { if let r = $0 { model.setRate(r) } })
    }

    private var picker: some View {
        Picker("Speed", selection: selection) {
            ForEach(PlaybackSpeed.rates, id: \.self) { r in
                Text(PlaybackSpeed.label(r)).tag(Optional(r))
            }
        }
    }

    var body: some View {
        Group {
            if asMenu {
                // A small button that names the current speed ("Auto" while the opening paces itself) and opens the list.
                Menu {
                    picker.pickerStyle(.inline)
                } label: {
                    Text(model.chosenRate.map(PlaybackSpeed.label) ?? "Auto")
                        .lineLimit(1)
                        .monospacedDigit()
                }
                .menuIndicator(.hidden)
            } else {
                picker.pickerStyle(.segmented)
            }
        }
        .accessibilityLabel("Playback speed")
        .accessibilityValue(model.chosenRate.map(PlaybackSpeed.label) ?? "Automatic")
    }
}

// MARK: The bar

struct PlaybackControls: View {
    let model: ShowpieceModel
    @Binding var shotPanelOpen: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 8) {
            // While aiming, the shot panel takes this place; the scrub row comes back when the panel closes.
            if !shotPanelOpen { scrubRow }
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
            #else
            if !typeSize.isAccessibilitySize { TimeReadout(model: model) }
            #endif
        }
        .padding(.leading, 8)
        .padding(.trailing, 20)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: Buttons (iPhone and iPad)

    private var lens: some View {
        ToggleButton(title: "Lens", symbol: "viewfinder", isOn: model.lensOn) { model.setLens(!model.lensOn) }
    }

    /// Ride: the replay camera follows the balls at table height. Named "Ride" on the button and spoken in full.
    private func ride(fill: Bool = false) -> some View {
        ToggleButton(title: "Ride", symbol: "video", isOn: model.rideOn, fill: fill) { model.setRide(!model.rideOn) }
            .accessibilityLabel("Ride camera")
            .accessibilityHint("During a replay the camera rides behind the cue ball and the ball it hits, in slow motion at the contact")
    }

    private var shot: some View {
        ToggleButton(title: "Your shot", symbol: "target", isOn: shotPanelOpen) { shotPanelOpen.toggle() }
    }

    private var buttons: some View {
        GlassEffectContainer(spacing: 8) {
            Group {
                if typeSize.isAccessibilitySize {
                    stacked
                } else {
                    ViewThatFits(in: .horizontal) {
                        oneRow
                        twoRows
                        threeRows
                    }
                }
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }

    private var oneRow: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            lens
            ride()
            ReplayButton(model: model).labelStyle(.iconOnly).buttonBorderShape(.circle)
            shot
        }
    }

    private var twoRows: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                lens
                ride()
                ReplayButton(model: model).labelStyle(.iconOnly).buttonBorderShape(.circle)
            }
            HStack(spacing: 8) { Spacer(minLength: 0); shot }
        }
    }

    /// Narrow columns (a phone turned sideways, a small window) use the same two rows.
    private var threeRows: some View { twoRows }

    /// Largest text sizes: everything full width, one control per row, with words on every button.
    private var stacked: some View {
        VStack(spacing: 8) {
            ToggleButton(title: "Lens", symbol: "viewfinder", isOn: model.lensOn, fill: true) { model.setLens(!model.lensOn) }
            ride(fill: true)
            ReplayButton(model: model, fill: true)
            ToggleButton(title: "Your shot", symbol: "target", isOn: shotPanelOpen, fill: true) { shotPanelOpen.toggle() }
        }
    }
}
