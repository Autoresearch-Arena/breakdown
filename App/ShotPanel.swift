// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The player's panel: a break while the rack is full, then shot after shot from wherever the balls came to
//          rest. It does exactly what it did before the glow-up (the same sliders write the same model values, Break
//          and Shoot call the same model methods) but is now built from standard parts: system sliders with spoken
//          values, bordered circle buttons for the fine-aim nudges, and prominent glass buttons for Break and Shoot.
//          At the largest text sizes each row stacks its name over its slider. The aiming redesign (drag on the table)
//          is a later package; the sliders stay until then.
// SRP/DRY check: Pass - split out of ShowpieceView; the slider row is one component, used six times.
import SwiftUI

struct ShotPanel: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        content.tint(palette.accent)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            if model.racked {
                SliderRow(label: "Aim", value: $model.aimOffset, range: -0.03...0.03,
                          readout: String(format: "%+.0f mm", model.aimOffset * 1000))
                SliderRow(label: "Power", value: $model.power, range: 7...13,
                          readout: String(format: "%.1f m/s", model.power))
                SliderRow(label: "Cue tip", value: $model.tipHeight, range: -0.02...0.02, readout: Self.tipWord(model.tipHeight))
                Button("Break") { isOpen = false; model.breakNow() }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .accessibilityHint("Plays your own break")
            } else {
                aimRow
                SliderRow(label: "Power", value: $model.shotPower, range: 0.5...8,
                          readout: String(format: "%.1f m/s", model.shotPower))
                SliderRow(label: "Cue tip", value: $model.shotTipUp, range: -0.02...0.02, readout: Self.tipWord(model.shotTipUp))
                SliderRow(label: "Side", value: $model.shotTipSide, range: -0.02...0.02, readout: Self.sideWord(model.shotTipSide))
                shotButtons
            }
        }
    }

    /// Aim at nearest and Re-rack beside the main action when there is room; stacked when text is large.
    private var shotButtons: some View {
        let nearest = Button("Aim at nearest") { model.aimAtNearestBall() }.buttonStyle(.bordered)
        let rerack = Button("Re-rack") { model.rerack() }.buttonStyle(.bordered)
        let shoot = Button("Shoot") { model.shootNow() }
            .buttonStyle(.glassProminent)
            .foregroundStyle(palette.ground)   // dark text: white on bright cyan is too faint
            .accessibilityHint("Plays your shot")
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { nearest; rerack; Spacer(minLength: 0); shoot }
            VStack(spacing: 8) {
                HStack(spacing: 8) { nearest; rerack; Spacer(minLength: 0) }
                shoot.frame(maxWidth: .infinity)
            }
        }
        .controlSize(.regular)
        .padding(.top, 8)
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
                Button { model.aimDegrees -= 0.25 } label: { Image(systemName: "minus").frame(width: 30, height: 30) }
                    .accessibilityLabel("Aim left a little")
                Slider(value: $model.aimDegrees, in: -180...180) { Text("Aim") }
                    .labelsHidden()   // the Mac draws a slider's label unless told not to; the row already shows it
                    .accessibilityValue(String(format: "%.1f degrees", model.aimDegrees))
                Button { model.aimDegrees += 0.25 } label: { Image(systemName: "plus").frame(width: 30, height: 30) }
                    .accessibilityLabel("Aim right a little")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
        }
    }

    static func tipWord(_ v: Double) -> String { v < -0.002 ? "draw" : (v > 0.002 ? "follow" : "centre") }
    static func sideWord(_ v: Double) -> String { v < -0.002 ? "left" : (v > 0.002 ? "right" : "centre") }
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
