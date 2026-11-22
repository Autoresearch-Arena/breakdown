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
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: the panel hands the model's open controls and the lesson's
//          target bands (ShotControls, LessonZones) to the tip picture, the power gauge and the cue-angle menu; a
//          locked control is dimmed with a lock mark and VoiceOver hears "Locked for this step"; Aim at nearest ball
//          and the fine-control sliders respect the same locks; the free-play items stay out of a lesson.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: the fine-controls power slider reads the ball's speed,
//          "firm · ball 3.4 m/s" (StrokeWords.ballReadout), beside the power bar's swing, so the number is on hand.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: the equipment card (EquipmentCard, App/Stroke/StanceViews.swift)
//          sits at the top of the panel, beside the tip and power controls, when the stance is not a square one; in the
//          notebook it is one of the notebook's cards instead, so it is never shown twice. The fine controls read the
//          bridge's length (BridgeReadout) under the power slider.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 1, 2, 5, 12,
//          13 and 16: the one-time hint is the first instruction for the input in use (FirstInstruction) and stays
//          hidden during the hand-over, so one line teaches; Break and Shoot go through the model's fireStroke and are
//          disabled with the reason while a stroke would be refused (strokeRefusal); a refused stroke's reason shows
//          on the panel as one line, pulsing each time (lastRefusal, refusalSerial); on the computer's turn the
//          person's controls are greyed out with a line saying whose turn it is (personControlsLive); the cue-angle
//          control writes through activeElevation, where a lesson's lock applies; the fine controls gain a bridge
//          slider beside the bridge readout.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 4: the fine controls' Cue tip and Side readouts show the signed millimetres beside the word
//          (tipReadout: "follow, +8.5 mm"), so the judge's millimetre advice can be followed; the readout column is wider
//          to hold them. tipWord and sideWord are unchanged. Review fix: a value a hair below zero no longer reads
//          "-0.0 mm".)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Bumped by each refusal to pulse its line (a symbol bounce; nothing moves under Reduce Motion).
    @State private var refusalPulse = 0

    var body: some View {
        VStack(spacing: 8) {
            // The hand-over card already says the one thing to do; the hint waits until after it (item 1).
            if !hintSeen && model.openingStage != .handOver { hint }
            // Why the last stroke was refused, or that the computer is playing (items 2 and 16).
            statusLine
            // The stance, when it is not a square one. The notebook shows it among its cards (NotebookPanel).
            if !inlinePages { EquipmentCard(model: model, embedded: true) }
            Group {
                if typeSize.isAccessibilitySize {
                    stacked
                } else {
                    ViewThatFits(in: .horizontal) { oneRow; twoRows }
                }
            }
            // The computer's turn: the person's controls stay visible but greyed out and still (item 16).
            .disabled(!model.personControlsLive)
            .opacity(model.personControlsLive ? 1 : 0.45)
            if slidersOpen && inlinePages {
                FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
                    .frame(height: 340)
                    .transition(.opacity)
            }
        }
        .tint(palette.accent)
        .animation(reduceMotion ? nil : .snappy, value: model.personControlsLive)
        // Each refusal pulses the line once, even the same reason twice in a row (refusalSerial), and is spoken.
        .onChange(of: model.refusalSerial) { _, _ in
            if let reason = model.lastRefusal {
                AccessibilityNotification.Announcement(reason.sentence).post()
                if !reduceMotion { refusalPulse += 1 }
            }
        }
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
            TipPicker(model: model, open: open, zones: zones)
            PowerGauge(model: model, open: open, zones: zones).frame(minWidth: 84)
            cueAngle
            tryAgainButton
            fireButton
            moreMenu
        }
    }

    private var twoRows: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                TipPicker(model: model, open: open, zones: zones)
                PowerGauge(model: model, open: open, zones: zones)
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
                TipPicker(model: model, open: open, zones: zones)
                PowerGauge(model: model, open: open, zones: zones)
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

    /// Which controls are open now and the lesson's target bands, if any (everything open, nothing marked, outside a
    /// lesson's guided tries). Handed to each control so it can dim itself and draw its band.
    private var open: ShotControls { model.openControls }
    private var zones: LessonZones? { model.lessonZones }

    private var fireButton: some View {
        Button {
            hintSeen = true
            // A break hands the screen to its replay, so the panel closes; a shot keeps it open; a refusal says why.
            if model.fireStroke() == .breakStruck { isOpen = false }
        } label: {
            Text(model.racked ? "Break" : "Shoot")
                .font(.headline)
                .lineLimit(1)
                .frame(minWidth: 48, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)   // dark text: white on bright cyan is too faint
        .controlSize(.regular)
        // Disabled while a stroke would be refused (the replay still playing, a ruling or choice waiting, no call and no
        // suggestion, the computer's turn, a solve in flight); the reason is the hint, so VoiceOver hears why.
        .disabled(model.strokeRefusal != nil)
        .accessibilityHint(model.strokeRefusal?.sentence
                           ?? (model.racked ? String(localized: "Plays your own break") : String(localized: "Plays your shot")))
    }

    /// One line above the controls: on the computer's turn, that it is its turn; otherwise the reason the last stroke
    /// was refused, until the next stroke is accepted (the model clears it). Nothing when there is nothing to say.
    @ViewBuilder private var statusLine: some View {
        // personControlsLive is false on the computer's turn or while a solve is in flight; without the solve it is the
        // computer's turn (read this way so no comparison with a case named "none" can be taken for an optional's).
        let computer = !model.personControlsLive && !model.isSolving
        if let text = computer ? Optional(ShotRefusal.notYourTurn.sentence) : model.lastRefusal?.sentence {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: computer ? "cpu" : "exclamationmark.circle")
                    .foregroundStyle(computer ? palette.accent : palette.slide)
                    .symbolEffect(.bounce, value: refusalPulse)
                    .accessibilityHidden(true)
                Text(text)
                    .font(Theme.body)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .transition(.opacity)
        }
    }

    /// True in plain free play: no match, no trick shot, no Behind the 8-Ball situation on the table.
    private var freePlay: Bool {
        model.match == nil && !model.trickMode.isActive && !model.eightBallMode.isActive && !model.lessonMode.isActive
    }

    /// The raised cue, where the model allows it (free play and matches) and for a shot rather than the break.
    @ViewBuilder private var cueAngle: some View {
        if model.elevationAllowed && !model.racked {
            // Through activeElevation, where a lesson's lock applies like power, tip and aim (item 12).
            CueAngleMenu(sine: Binding(get: { model.activeElevation }, set: { model.activeElevation = $0 }),
                         minHeight: Self.buttonHeight, zone: zones?.cueAngles,
                         zoneStrength: zones?.strength ?? 1, locked: !open.contains(.elevation))
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
                    .disabled(!open.contains(.aim))
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

    /// The one-time hint: the first instruction for the input in use. Dismissed by its own button; also marked seen by
    /// the first pull or shot.
    private var hint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.draw").font(.title3).foregroundStyle(palette.accent).accessibilityHidden(true)
            // The same one instruction the hand-over card gives, for the input in use (FirstInstruction).
            Text(FirstInstruction.line(for: model.inputInUse))
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
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

    /// The fine controls' tip and side readout (0.7.5): the word the player sees and the signed offset in millimetres,
    /// "follow, +8.5 mm", "left, −3.0 mm", "centre, 0.0 mm", so a judge's "about 2 millimetres lower" can be set by
    /// eye. Tenths of a millimetre, in the player's number style. tipWord and sideWord are left exactly as they are:
    /// the retry comparison (ShotAttempt) reads them as fixed identifiers.
    static func tipReadout(_ metres: Double, vertical: Bool) -> String {
        let word = shownWord(vertical ? tipWord(metres) : sideWord(metres))
        // Rounded to the tenth first, so a value a hair either side of zero reads "0.0" with no sign. A hair below zero
        // rounds to negative zero, which the number formatter writes as "-0.0"; the == 0 test is true for it, and
        // assigning a plain 0 drops the sign bit.
        var tenths = (metres * 10_000).rounded() / 10
        if tenths == 0 { tenths = 0 }
        let mm = tenths.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always(includingZero: false)))
        return String(localized: "\(word), \(mm) mm")
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
                    // A lesson's locked controls are greyed out here too (the model refuses the change anyway).
                    let open = model.openControls
                    if model.racked {
                        SliderRow(label: "Aim", value: $model.aimOffset, range: -ShowpieceModel.breakAimLimit...ShowpieceModel.breakAimLimit,
                                  readout: String(format: "%+.0f mm", model.aimOffset * 1000))
                    } else {
                        aimRow.disabled(!open.contains(.aim)).lockedForStep(!open.contains(.aim))
                    }
                    SliderRow(label: "Power", value: Binding(get: { model.activePower }, set: { model.activePower = $0 }),
                              range: model.powerRange, readout: StrokeWords.ballReadout(power: model.activePower, racked: model.racked, cue: model.cueInHand))
                        .disabled(!open.contains(.power)).lockedForStep(!open.contains(.power))
                    // The bridge's length: read here, set on the table by a resting second finger, or here with the
                    // slider (item 5). The rest fixes its own length, so the slider waits while the rest is in use.
                    BridgeReadout(model: model)
                    SliderRow(label: "Bridge",
                              value: Binding(get: { model.strokeBridge ?? StrokeModel.automaticBridge },
                                             set: { model.strokeBridge = $0 }),
                              range: StrokeModel.bridgeRange,
                              readout: Measurement(value: ((model.strokeBridge ?? StrokeModel.automaticBridge) * 100).rounded(),
                                                   unit: UnitLength.centimeters)
                                  .formatted(.measurement(width: .abbreviated, usage: .asProvided)))
                        .disabled(model.restInUse)
                    SliderRow(label: "Cue tip", value: Binding(get: { model.activeTipUp }, set: { model.activeTipUp = $0 }),
                              range: -model.tipLimit...model.tipLimit,
                              readout: ShotPanel.tipReadout(model.activeTipUp, vertical: true))
                        .disabled(!open.contains(.tipUp)).lockedForStep(!open.contains(.tipUp))
                    SliderRow(label: "Side", value: Binding(get: { model.activeTipSide }, set: { model.activeTipSide = $0 }),
                              range: -model.tipLimit...model.tipLimit,
                              readout: ShotPanel.tipReadout(model.activeTipSide, vertical: false))
                        .disabled(!open.contains(.tipSide)).lockedForStep(!open.contains(.tipSide))
                    if model.elevationAllowed && !model.racked {
                        // Degrees on the slider, the sine in the model (the solver's unit). The top is the last angle
                        // the cue-angle menu offers, short of where the cue rig stops pitching the cue.
                        SliderRow(label: "Cue angle",
                                  value: Binding(get: { asin(min(max(model.activeElevation, 0), 0.995)) * 180 / .pi },
                                                 set: { model.activeElevation = $0 < 0.5 ? 0 : sin($0 * .pi / 180) }),
                                  range: 0...Double(CueAngleMenu.angles.last ?? 80),
                                  readout: CueAngleMenu.words(degrees: asin(min(max(model.activeElevation, 0), 0.995)) * 180 / .pi))
                        .disabled(!open.contains(.elevation)).lockedForStep(!open.contains(.elevation))
                    }
                    Button {
                        sheetOpen = false
                        if model.fireStroke() == .breakStruck { isOpen = false }
                    } label: {
                        Text(ShotPanel.actionWord(racked: model.racked)).frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                    .controlSize(.large)
                    .disabled(model.strokeRefusal != nil)
                    .accessibilityHint(model.strokeRefusal?.sentence ?? "")
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
    /// Wide enough for the tip and side readouts' word and millimetres ("follow, +8.5 mm", 0.7.5).
    @ScaledMetric(relativeTo: .caption) private var readoutWidth = 112

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
