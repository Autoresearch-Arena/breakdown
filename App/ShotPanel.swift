// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
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
// SRP/DRY check: Pass - checked the 0.3.0 panel, whose slider row is kept (now only in the sheet) and whose model
//          calls are unchanged; the break-or-shot choice is hidden behind the model's active values, so this file
//          has one set of controls, not two.
import SwiftUI

struct ShotPanel: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool
    @AppStorage("aimHintSeen") private var hintSeen = false
    @State private var slidersOpen = false
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
        }
        .tint(palette.accent)
        // Test hook: launch with -aimDemoSheet to open the fine controls straight away.
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-aimDemoSheet") { slidersOpen = true } }
        .sheet(isPresented: $slidersOpen) {
            FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
        }
    }

    // MARK: Layouts

    private var oneRow: some View {
        HStack(spacing: 10) {
            TipPicker(model: model)
            PowerGauge(model: model).frame(minWidth: 84)
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
                Spacer(minLength: 0)
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
        .disabled(!model.aimReady)
        .accessibilityHint(model.racked ? "Plays your own break" : "Plays your shot")
    }

    private var moreMenu: some View {
        Menu {
            Button { slidersOpen = true } label: { Label("Fine controls", systemImage: "slider.horizontal.3") }
            if !model.racked {
                Button { model.aimAtNearestBall() } label: { Label("Aim at nearest ball", systemImage: "scope") }
                Button { model.rerack() } label: { Label("Re-rack for a break", systemImage: "triangle") }
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
            Text("Drag on the table to aim. Pull back from the white ball to set power, then click \(model.racked ? "Break" : "Shoot"). Arrow keys fine-tune.")
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            #else
            Text("Drag on the table to aim. Pull back from the white ball to set power, then tap \(model.racked ? "Break" : "Shoot").")
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
        // The hint is a one-off aid, not content: capped below the accessibility sizes so it cannot push the table
        // off the screen. VoiceOver and the sliders still carry the full explanation.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// Height of the main buttons: the glass button adds padding, so this lands on 44 points or more on a touch screen.
    #if os(iOS)
    private static let buttonHeight: CGFloat = 30
    #else
    private static let buttonHeight: CGFloat = 0
    #endif

    static func tipWord(_ v: Double) -> String { v < -0.002 ? "draw" : (v > 0.002 ? "follow" : "centre") }
    static func sideWord(_ v: Double) -> String { v < -0.002 ? "left" : (v > 0.002 ? "right" : "centre") }
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
                              range: model.powerRange, readout: String(format: "%.1f m/s", model.activePower))
                    SliderRow(label: "Cue tip", value: Binding(get: { model.activeTipUp }, set: { model.activeTipUp = $0 }),
                              range: -ShowpieceModel.tipLimit...ShowpieceModel.tipLimit, readout: ShotPanel.tipWord(model.activeTipUp))
                    SliderRow(label: "Side", value: Binding(get: { model.activeTipSide }, set: { model.activeTipSide = $0 }),
                              range: -ShowpieceModel.tipLimit...ShowpieceModel.tipLimit, readout: ShotPanel.sideWord(model.activeTipSide))
                    Button {
                        sheetOpen = false
                        if model.fire() { isOpen = false }
                    } label: {
                        Text(model.racked ? "Break" : "Shoot").frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                    .controlSize(.large)
                    .disabled(!model.aimReady)
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
                    .accessibilityValue(String(format: "%.1f degrees", model.aimDegrees))
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
