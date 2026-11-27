// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console: the reel shows only after a
//          shot; while aiming it folds into the kit's "Last shot" button, which leads the tab row (the slim reel stays
//          under the open console while the player's own shot is still rolling, item 8). The Lens, Ride and Aim tabs
//          ("Your shot" is renamed "Aim") are the kit's capsules, cyan when on and the secondary surface when off, right
//          aligned, on every device the Mac included, so the modes have one place; they come after the first shot (until
//          then only Aim, and only while the controls are closed, so they can always be opened again). The Mac's reel
//          carries play, speed and Replay itself now its window toolbar no longer does.)
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
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit, part C: the scrub row is
//          the shot reel (App/Kit/ShotReel.swift): play, the track, the time in s, the speed pill and Replay in that
//          order, 52 points high on the big screens and 44 on a phone, a panel on the big screens and glass on a phone.
//          What if keeps its slot after Replay as the reel's accessory. The Mac keeps the track, the time and What if
//          only (its window toolbar carries play, speed and Replay). PlaybackControls keeps its initialisers, the slim row
//          under the open shot panel while the player's own shot is on screen, compact mode, and the Lens, Ride and Your
//          shot buttons exactly as they were. The pieces below (PlayPauseButton, ReplayButton, ToggleButton,
//          SpeedPicker, PlaybackSpeed) stay here: the Mac toolbar and the phone strip use them too.)
// SRP/DRY check: Pass - split out of ShowpieceView, which had separate chip and round-button builders; one
//          ToggleButton now serves both iPhone and iPad toggles. The scrub row is ShotReel, drawn once in App/Kit.
import SwiftUI

enum PlaybackSpeed {
    static let rates: [Double] = [0.1, 0.25, 0.5, 1.0]
    static func label(_ r: Double) -> String { r.formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(0...2))) + "×" }
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

/// A button that stays on or off: a tab. Its label is constant, so its width never changes; state is shown by the fill
/// and spoken as a toggle with an on or off value. `title` is already localized. UI rethink package 4: on the big
/// screens and the fold's panel the kit's capsules (the cyan primary when on, the secondary surface when off); on the
/// phone, where the row floats over the 3D table, the off state is the kit's glass capsule (the design language keeps
/// glass for controls over the table) and the on state the cyan primary.
struct ToggleButton: View {
    let title: String
    let symbol: String
    let isOn: Bool
    var fill = false
    let action: () -> Void
    private var deviceReader = KitDeviceReader()

    init(title: String, symbol: String, isOn: Bool, fill: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.isOn = isOn
        self.fill = fill
        self.action = action
    }

    private var button: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .lineLimit(1)
                .fixedSize(horizontal: !fill, vertical: false)
                .frame(maxWidth: fill ? .infinity : nil)
        }
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }

    var body: some View {
        if isOn {
            button.buttonStyle(PrimaryButtonStyle(fullWidth: fill))
        } else if deviceReader.current == .phone {
            button.buttonStyle(GlassControlStyle())
        } else {
            button.buttonStyle(SecondaryButtonStyle(fullWidth: fill))
        }
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
    /// The folding phone's panel: the reel and buttons at the fold panel's size.
    var compact = false
    @Environment(\.dynamicTypeSize) private var typeSize
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var widthClass
    @Environment(\.verticalSizeClass) private var heightClass
    #endif

    var body: some View {
        let shot = NotebookStory.hasShot(model)
        // While aiming the reel folds into "Last shot", except while the player's own shot is still rolling, when the
        // slim reel stays under the console so it can be scrubbed and slowed (item 8).
        let folded = shot && shotPanelOpen && !(model.playerShotOnScreen && !model.aimReady)
        VStack(spacing: Theme.Space.sm) {
            if shot && !folded {
                scrubRow(slim: shotPanelOpen)
            }
            tabs(lastShot: folded, all: shot && model.openingStage == .none)
        }
        .kitDevice(device)
    }

    /// The shot reel (App/Kit/ShotReel.swift) with What if after Replay: play, the track, the time, speed and Replay.
    private func scrubRow(slim: Bool) -> some View {
        ShotReel(model: model, device: device, slim: slim) {
            // What if, beside Replay: only after the player's own shot has come to rest (invisible otherwise, its slot
            // kept so the track does not change width; 0.7.6, bug 31). At the accessibility text sizes it is a worded
            // full-width row in the stacked tabs instead.
            if !typeSize.isAccessibilitySize {
                WhatIfButton(model: model, reserveSlot: true).labelStyle(.iconOnly).buttonStyle(.plain)
            }
        }
    }

    /// Which layout the reel and tabs sit in: the folding phone's panel in compact mode, a phone when either size class
    /// is compact (upright or sideways, or a narrow iPad window), otherwise the big screens (always on the Mac).
    private var device: Theme.Device {
        if compact { return .foldPanel }
        #if os(iOS)
        return widthClass == .compact || heightClass == .compact ? .phone : .big
        #else
        return .big
        #endif
    }

    // MARK: The tabs

    /// The Lens toggle. `full` picks the clear name "Physics Lens"; the short "Lens" is the fallback for tight rows.
    /// Not a ViewThatFits of its own: inside a row it would always be offered the whole width and pick the long name,
    /// which would make the outer ViewThatFits think one row fits when it does not. `tabs` lists long and short
    /// versions of each layout and one measurement chooses.
    private func lens(full: Bool, fill: Bool = false) -> some View {
        ToggleButton(title: full ? String(localized: "Physics Lens") : String(localized: "Lens"), symbol: "viewfinder",
                     isOn: model.lensOn, fill: fill) {
            model.setLens(!model.lensOn)
        }
        .accessibilityLabel("Physics Lens")
    }

    /// Ride: the replay camera chases the cue ball. Named "Ride" on the button and spoken in full.
    private func ride(fill: Bool = false) -> some View {
        ToggleButton(title: String(localized: "Ride"), symbol: "video", isOn: model.rideOn, fill: fill) {
            model.setRide(!model.rideOn)
        }
        .accessibilityLabel("Ride camera")
    }

    /// The computer is thinking or shooting (0.7.5, L-A): Aim is drawn off and cannot be pressed, so it never looks like
    /// the person's turn while it is not.
    private var computersTurn: Bool { model.computerTurnStage != .none }

    /// Aim (UI rethink package 4, renamed from "Your shot"): opens and closes the console's controls.
    private func aim(fill: Bool = false) -> some View {
        ToggleButton(title: StrikeWords.aimTab, symbol: "target", isOn: shotPanelOpen && !computersTurn, fill: fill) {
            shotPanelOpen.toggle()
        }
        .disabled(computersTurn)
    }

    /// The reel folded while aiming: the kit's secondary "Last shot", which replays the last shot with the Lens.
    private func lastShotButton(fill: Bool = false) -> some View {
        LastShotReelButton(device: device) { model.replay(withLens: true) }
            .frame(maxWidth: fill ? .infinity : nil)
    }

    /// `all`: the Lens, Ride and Aim (after the first shot, outside the opening). Before that only Aim, and only while
    /// the controls are closed, so the first minute stays calm and the controls can always be opened again.
    @ViewBuilder
    private func tabs(lastShot: Bool, all: Bool) -> some View {
        if all || lastShot {
            Group {
                if typeSize.isAccessibilitySize {
                    stacked(lastShot: lastShot, all: all)
                } else {
                    // Widest first: the full Lens name on one row, the short name on one row, then the same on two.
                    ViewThatFits(in: .horizontal) {
                        oneRow(fullLens: true, lastShot: lastShot, all: all)
                        oneRow(fullLens: false, lastShot: lastShot, all: all)
                        twoRows(fullLens: true, lastShot: lastShot, all: all)
                        twoRows(fullLens: false, lastShot: lastShot, all: all)
                    }
                }
            }
        } else if !shotPanelOpen && !computersTurn {
            HStack(spacing: Theme.Space.xs) {
                Spacer(minLength: 0)
                aim()
            }
        }
    }

    /// "Last shot" on the leading side, the tabs on the trailing side (the primary side).
    private func oneRow(fullLens: Bool, lastShot: Bool, all: Bool) -> some View {
        HStack(spacing: Theme.Space.xs) {
            if lastShot { lastShotButton() }
            Spacer(minLength: 0)
            if all {
                lens(full: fullLens)
                ride()
                aim()
            }
        }
    }

    /// Narrow columns (a phone turned sideways, a small window, the side column with a long translation).
    private func twoRows(fullLens: Bool, lastShot: Bool, all: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            if lastShot {
                HStack(spacing: Theme.Space.xs) { lastShotButton(); Spacer(minLength: 0) }
            }
            if all {
                HStack(spacing: Theme.Space.xs) {
                    Spacer(minLength: 0)
                    lens(full: fullLens)
                    ride()
                }
                HStack(spacing: Theme.Space.xs) { Spacer(minLength: 0); aim() }
            }
        }
    }

    /// Largest text sizes: everything full width, one control per row, with words on every button.
    private func stacked(lastShot: Bool, all: Bool) -> some View {
        VStack(spacing: Theme.Space.xs) {
            if lastShot { lastShotButton(fill: true) }
            if all {
                // A full-width row: the long name nearly always fits; the short one is the fallback at the very largest.
                ViewThatFits(in: .horizontal) {
                    lens(full: true, fill: true)
                    lens(full: false, fill: true)
                }
                ride(fill: true)
                aim(fill: true)
                // The what-if entry with its words, where the reel's icon-only buttons are hardest to read.
                WhatIfButton(model: model, fill: true)
            }
        }
    }
}
