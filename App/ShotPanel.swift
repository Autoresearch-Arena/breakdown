// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (a Try again button beside Shoot once a shot of yours has played out:
//          the balls go back where it started with the same settings, and the last try stays on the table as a ghost).
// PURPOSE: The player's panel, now small enough to leave the table alone. The aiming itself happens on the table
//          (AimOverlay: drag to swing the line, pull back from the cue ball to set power). This panel is only what has
//          to sit beside it: a picture of the cue ball to touch for tip placement (TipPicker), the power gauge
//          (PowerGauge), the Break or Shoot button, and a More menu (fine controls, aim at the nearest ball, re-rack,
//          show the hint again). One row on a phone and in a wide column, two rows when space or text size demands it.
//          The first time it opens it also shows a short hint that explains the gestures; the hint is dismissed with
//          its own button, or by the first pull or shot, and never comes back unless asked for (stored as aimHintSeen).
//          The sliders did not go away: "Fine controls" opens them in a sheet, labelled and with spoken values, so
//          VoiceOver, keyboard and switch users have a complete route that does not need the picture of the table.
//          Break and Shoot call the same model methods as before.
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo: the fine controls open inside the side panel instead of
//          in a sheet, so nothing covers the table.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the power slider's readout says the power in a word beside the number,
//          from PowerWords.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (free play finished, rules plan package 2: the cue-angle control
//          (CueAngleMenu, the one the Behind the 8-Ball card uses) sits in the panel wherever the model opens the
//          raised cue (free play and matches), with a matching slider in the fine controls; the More menu gains Move
//          cue ball, Undo last shot and the rack choice in free play; Shoot waits while the cue ball is lifted, while a
//          shot is being solved, and in a match until the call is made; the tip sliders use the model's own tip
//          travel (model.tipLimit) instead of the old fixed value.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the gesture hint no longer caps the text size; it scrolls inside its
//          own height at the largest sizes instead.)
// SRP/DRY check: Pass - checked the 0.3.0 panel, whose slider row is kept (now only in the sheet) and whose model
//          calls are unchanged; the break-or-shot choice is hidden behind the model's active values, so this file
//          has one set of controls, not two.
import SwiftUI

struct ShotPanel: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool
    @AppStorage("aimHintSeen") private var hintSeen = false
    @State private var slidersOpen = false
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 8) {
            if !hintSeen { hint }
            if typeSize.isAccessibilitySize {
                stacked
            } else {
                ViewThatFits(in: .horizontal) { oneRow; twoRows }
            }
            if slidersOpen && inlinePages {
                FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
                    .frame(height: 340)
                    .transition(.opacity)
            }
        }
        .tint(palette.accent)
        // Test hook: launch with -aimDemoSheet to open the fine controls straight away.
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-aimDemoSheet") { slidersOpen = true } }
        // On a folding phone the sliders open inside the panel (below), so no sheet covers the table.
        .sheet(isPresented: Binding(get: { slidersOpen && !inlinePages }, set: { if !inlinePages { slidersOpen = $0 } })) {
            FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
        }
    }

    // MARK: Layouts

    private var oneRow: some View {
        HStack(spacing: 10) {
            TipPicker(model: model)
            PowerGauge(model: model).frame(minWidth: 84)
            cueAngle
            tryAgainButton
            fireButton
            moreMenu
        }
    }

    private var twoRows: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                TipPicker(model: model)
                PowerGauge(model: model)
            }
            HStack(spacing: 10) {
                moreMenu
                cueAngle
                Spacer(minLength: 0)
                tryAgainButton
                fireButton
            }
        }
    }

    /// Largest text: the picture and gauge share a row, the buttons take the next, so the table keeps its room.
    private var stacked: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                TipPicker(model: model)
                PowerGauge(model: model)
            }
            HStack(spacing: 10) {
                moreMenu
                cueAngle
                tryAgainButton
                fireButton.frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Pieces

    private var fireButton: some View {
        Button {
            hintSeen = true
            if model.fire() { isOpen = false }
        } label: {
            Text(model.racked ? "Break" : "Shoot")
                .font(.headline)
                .lineLimit(1)
                .frame(minWidth: 48, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)   // dark text: white on bright cyan is too faint
        .controlSize(.regular)
        // While the last shot is still playing the guide is hidden; touching the table jumps to its end.
        .disabled(!canFire)
        .accessibilityHint(needsCall ? String(localized: "Make your call first")
                                     : (model.racked ? String(localized: "Plays your own break") : String(localized: "Plays your shot")))
    }

    /// A match that wants a call (eight-ball after the break) and has none yet.
    private var needsCall: Bool { (model.match?.mustCall ?? false) && model.match?.currentCall == nil }

    /// Shoot is offered once the balls on screen are where the next shot starts, the cue ball is not lifted, no shot
    /// is being solved, and any call the match wants has been made.
    private var canFire: Bool { model.aimReady && !model.placingCueBall && !model.isSolving && !needsCall }

    /// True in plain free play: no match, no trick shot, no Behind the 8-Ball situation on the table.
    private var freePlay: Bool {
        model.match == nil && !model.trickMode.isActive && !model.eightBallMode.isActive
    }

    /// The raised cue, where the model allows it (free play and matches) and for a shot rather than the break.
    @ViewBuilder private var cueAngle: some View {
        if model.elevationAllowed && !model.racked {
            CueAngleMenu(sine: $model.shotElevation, minHeight: Self.buttonHeight)
                .controlSize(.regular)
        }
    }

    /// The words for each free-play rack.
    static func rackName(_ rack: FreePlayRack) -> String {
        switch rack {
        case .fifteen: return String(localized: "Fifteen-ball triangle")
        case .nineBall: return String(localized: "Nine-ball diamond")
        case .placeBalls: return String(localized: "No rack: place the balls")
        }
    }

    /// Back to where the last shot started, same settings, with the last try kept as a ghost to compare against.
    /// Only there once a shot of the player's own has played out, so it never jumps in mid-shot.
    @ViewBuilder private var tryAgainButton: some View {
        if model.canTryAgain {
            Button {
                hintSeen = true
                model.tryAgain()
            } label: {
                Label("Try again", systemImage: "arrow.uturn.backward")
                    .font(.headline)
                    .lineLimit(1)
                    .frame(minHeight: Self.buttonHeight)
            }
            .buttonStyle(.glass)
            .controlSize(.regular)
            .accessibilityHint("Puts the balls back where your last shot started, with the same aim, power and spin")
            .transition(.opacity)
        }
    }

    private var moreMenu: some View {
        Menu {
            Button { slidersOpen = true } label: { Label("Fine controls", systemImage: "slider.horizontal.3") }
            if !model.racked {
                Button { model.aimAtNearestBall() } label: { Label("Aim at nearest ball", systemImage: "scope") }
            }
            if freePlay {
                // Practice players move the cue ball all the time: the same placement state as ball in hand.
                Button { model.beginPlacingCueBall() } label: { Label("Move cue ball", systemImage: "hand.raised") }
                    .disabled(!model.aimReady || model.placingCueBall)
                Button { model.undoLastShot() } label: { Label("Undo last shot", systemImage: "arrow.uturn.backward.circle") }
                    .disabled(!model.canUndo)
                    .keyboardShortcut("z", modifiers: .command)
                Picker(selection: Binding(get: { model.freePlayRack }, set: { model.setFreePlayRack($0) })) {
                    ForEach(FreePlayRack.allCases, id: \.self) { rack in Text(ShotPanel.rackName(rack)).tag(rack) }
                } label: {
                    Label("Rack", systemImage: "triangle")
                }
                .pickerStyle(.menu)
                if !model.racked {
                    Button { model.rerack() } label: { Label("Re-rack for a break", systemImage: "triangle") }
                }
            }
            if hintSeen {
                Button { hintSeen = false } label: { Label("Show the hint again", systemImage: "questionmark.circle") }
            }
        } label: {
            Label("More shot options", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
                .frame(minWidth: 30, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
    }

    /// The one-time hint. Dismissed by its own button; also marked seen by the first pull or shot.
    private var hint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.draw").font(.title3).foregroundStyle(palette.accent).accessibilityHidden(true)
            #if os(macOS)
            Text(String(localized: "Drag on the table to aim. Pull back from the white ball to set power, then click \(ShotPanel.actionWord(racked: model.racked)). Arrow keys fine-tune."))
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            #else
            Text(String(localized: "Drag on the table to aim. Pull back from the white ball to set power, then tap \(ShotPanel.actionWord(racked: model.racked))."))
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            #endif
            Spacer(minLength: 0)
            Button { hintSeen = true } label: {
                Image(systemName: "xmark").frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Dismiss hint")
        }
        // The hint follows every text size, the largest included; past a few lines it scrolls inside its own height
        // instead of pushing the table off the screen (accessibility plan, package 5; was a text-size cap). 150 points
        // is about three lines of body text at the largest accessibility size, the most the panel can give it.
        .scrollsWhenTaller(than: 150)
    }

    /// Height of the main buttons: the glass button adds padding, so this lands on 44 points or more on a touch screen.
    #if os(iOS)
    private static let buttonHeight: CGFloat = 30
    #else
    private static let buttonHeight: CGFloat = 0
    #endif

    static func tipWord(_ v: Double) -> String { v < -0.002 ? "draw" : (v > 0.002 ? "follow" : "centre") }
    static func sideWord(_ v: Double) -> String { v < -0.002 ? "left" : (v > 0.002 ? "right" : "centre") }

    /// The words the player actually sees for a tip or side setting. tipWord and sideWord return fixed identifiers for
    /// comparisons; this turns one of those into its translated word for the screen and for the retry comparison.
    static func shownWord(_ word: String) -> String {
        switch word {
        case "draw": return String(localized: "draw")
        case "follow": return String(localized: "follow")
        case "left": return String(localized: "left")
        case "right": return String(localized: "right")
        default: return String(localized: "centre")
        }
    }

    /// The word on the main shot button: Break for the opening rack, Shoot after that.
    static func actionWord(racked: Bool) -> String {
        racked ? String(localized: "Break") : String(localized: "Shoot")
    }
}

// MARK: Fine controls (the sliders, in a sheet)

/// Every value the gestures set, as standard labelled sliders. The complete accessible route into the shot: it needs
/// no picture of the table, no drag and no pointer. Also handy on a Mac for typing a precise value with the keyboard.
private struct FineControls: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool
    @Binding var sheetOpen: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if model.racked {
                        SliderRow(label: "Aim", value: $model.aimOffset, range: -ShowpieceModel.breakAimLimit...ShowpieceModel.breakAimLimit,
                                  readout: String(format: "%+.0f mm", model.aimOffset * 1000))
                    } else {
                        aimRow
                    }
                    SliderRow(label: "Power", value: Binding(get: { model.activePower }, set: { model.activePower = $0 }),
                              range: model.powerRange, readout: PowerWords.readout(speed: model.activePower, racked: model.racked))
                    SliderRow(label: "Cue tip", value: Binding(get: { model.activeTipUp }, set: { model.activeTipUp = $0 }),
                              range: -model.tipLimit...model.tipLimit, readout: ShotPanel.shownWord(ShotPanel.tipWord(model.activeTipUp)))
                    SliderRow(label: "Side", value: Binding(get: { model.activeTipSide }, set: { model.activeTipSide = $0 }),
                              range: -model.tipLimit...model.tipLimit, readout: ShotPanel.shownWord(ShotPanel.sideWord(model.activeTipSide)))
                    if model.elevationAllowed && !model.racked {
                        // Degrees on the slider, the sine in the model (the solver's unit). The top is the last angle
                        // the cue-angle menu offers, short of where the cue rig stops pitching the cue.
                        SliderRow(label: "Cue angle",
                                  value: Binding(get: { asin(min(max(model.shotElevation, 0), 0.995)) * 180 / .pi },
                                                 set: { model.shotElevation = $0 < 0.5 ? 0 : sin($0 * .pi / 180) }),
                                  range: 0...Double(CueAngleMenu.angles.last ?? 80),
                                  readout: CueAngleMenu.words(degrees: asin(min(max(model.shotElevation, 0), 0.995)) * 180 / .pi))
                    }
                    Button {
                        sheetOpen = false
                        if model.fire() { isOpen = false }
                    } label: {
                        Text(ShotPanel.actionWord(racked: model.racked)).frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                    .controlSize(.large)
                    .disabled(!model.aimReady || model.placingCueBall || model.isSolving)
                    .padding(.top, 12)
                }
                .padding(16)
            }
            .navigationTitle("Fine controls")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { sheetOpen = false } } }
        }
        .tint(palette.accent)
        // Half height leaves the table in view above it, and the table stays touchable while the sheet is half open.
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 360)
        #endif
    }

    /// The aim row has nudge buttons either side of its slider, so it gets two lines: name and value, then the control.
    private var aimRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Aim").font(Theme.label).foregroundStyle(.secondary).accessibilityHidden(true)
                Spacer()
                Text(String(format: "%+.1f°", model.aimDegrees)).font(Theme.number).accessibilityHidden(true)
            }
            HStack(spacing: 8) {
                Button { model.aimDegrees -= 0.25 } label: { Image(systemName: "minus").frame(width: Self.nudgeSize, height: Self.nudgeSize) }
                    .accessibilityLabel("Aim right a little")
                Slider(value: $model.aimDegrees, in: -180...180) { Text("Aim") }
                    .labelsHidden()   // the Mac draws a slider's label unless told not to; the row already shows it
                    .accessibilityValue(String(localized: "\(String(format: "%.1f", locale: Locale.current, model.aimDegrees)) degrees"))
                Button { model.aimDegrees += 0.25 } label: { Image(systemName: "plus").frame(width: Self.nudgeSize, height: Self.nudgeSize) }
                    .accessibilityLabel("Aim left a little")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
        }
    }

    /// Icon frame for the nudge buttons: the bordered circle adds a little around it, so this lands on 44 points or
    /// more on a touch screen. The pointer on the Mac does not need it.
    #if os(iOS)
    private static let nudgeSize: CGFloat = 30
    #else
    private static let nudgeSize: CGFloat = 20
    #endif
}

/// One labelled slider: name, system slider, and a readout in digits that do not jitter. The readout is also what
/// VoiceOver says as the slider's value, in place of the default percentage.
private struct SliderRow: View {
    let label: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let readout: String
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .caption) private var labelWidth = 64
    @ScaledMetric(relativeTo: .caption) private var readoutWidth = 72

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        name
                        Spacer()
                        readoutText
                    }
                    slider
                }
            } else {
                HStack(spacing: 8) {
                    name.frame(width: labelWidth, alignment: .leading)
                    slider
                    readoutText.frame(width: readoutWidth, alignment: .trailing)
                }
            }
        }
        .frame(minHeight: 44)
    }

    private var name: some View {
        Text(label).font(Theme.label).foregroundStyle(.secondary).accessibilityHidden(true)
    }

    private var readoutText: some View {
        Text(readout).font(Theme.number).accessibilityHidden(true)
    }

    private var slider: some View {
        Slider(value: $value, in: range) { Text(label) }
            .labelsHidden()
            .accessibilityValue(readout)
    }
}
