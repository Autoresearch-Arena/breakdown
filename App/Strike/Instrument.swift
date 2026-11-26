// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The aiming panel's shared instrument kit (plans/26-Nov-2026-aiming-panel-redesign-plan.md, step 2), so the
//          tip picture, the power bar and the cue-angle dial stop looking like three different apps and every figure on
//          the panel is drawn one way:
//            - InstrumentHandle: the one drag handle (a cyan disc with a dark ring and a soft halo, brighter while it is
//              dragged; the power bar's thumb is the same handle in paper white).
//            - FigureLine: a figure's number with its unit at about 55 percent of its size, grey, on the same baseline
//              (Theme.figure / Theme.unit), cyan when it is something the player sets, paper white when it is a result,
//              with the dotted underline that says "tap to type this" (DottedUnderline).
//            - Readout: a label, a FigureLine, an optional word on the baseline ("firm", "below"), and an optional
//              planned→delivered form after a shot ("10.0 → 14.0 mm below", the arrow and new figure in the delta
//              yellow).
//            - TypeableFigure: makes a figure a button that opens the typed entry (StrikeEntryField) in a popover, while
//              the model lets the player change that value; one VoiceOver element reading label then spoken value.
//            - DeltaChip: the signed yellow pill under a figure the stroke changed ("+4.8 vs 11.9 planned"), always
//              worded so planned against delivered is never told by colour alone.
//            - BandCaption, bandSurface and HairlineRule: the flat band background with its tracked upper-case caption
//              and the 1-point rule between columns (glass stays on the window chrome and the chips over the table).
//          Read by StrikePanel (the lead band and the physics line), ShotPanel (the What-you-set band), TipPicker,
//          PowerGauge (AimGauges.swift), CueAngleDial and BridgeControl (StrikeEntry.swift). Colours from Palette
//          (accent only for what moves, paper for results, delta only for planned against delivered).
// SRP/DRY check: Pass - checked NumberTile (the notebook's glass tile, kept for NotebookNumbers), StrikePanel's old
//          EditableTile (its popover button moves here as TypeableFigure, so the tiles and the controls share it), the
//          handles TipPicker, PowerGauge and CueAngleDial each drew by hand (now this one), and Surfaces.glassCard (glass;
//          these bands are flat on purpose).
import SwiftUI

// MARK: Sizes

/// The band's small buttons: 52 points on a touch screen (over the 44-point minimum), 40 under a Mac's pointer, where
/// the band is short and nothing is touched.
enum InstrumentSize {
    #if os(macOS)
    static let button: CGFloat = 40
    static let stepperHeight: CGFloat = 36
    static let stepperWidth: CGFloat = 48
    #else
    static let button: CGFloat = 52
    static let stepperHeight: CGFloat = 48
    static let stepperWidth: CGFloat = 60
    #endif
}

// MARK: The handle

/// The one drag handle every aiming control draws: a disc with a dark ring and a soft halo.
struct InstrumentHandle: View {
    enum Style { case accent, paper }
    var diameter: CGFloat = 26
    var style: Style = .accent
    /// Brighter halo while the finger or pointer is on it.
    var active = false
    @Environment(\.palette) private var palette

    var body: some View {
        Circle()
            .fill(style == .accent ? palette.accent : palette.paper)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.75), lineWidth: max(1.5, diameter * 0.09)))
            .frame(width: diameter, height: diameter)
            .background {
                Circle()
                    .fill(palette.accent.opacity(active ? 0.30 : 0.14))
                    .frame(width: diameter * 1.7, height: diameter * 1.7)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: Figures

/// The dotted underline under a figure a tap types into: round dots in the figure's own colour.
struct DottedUnderline: View {
    var color: Color
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            p.move(to: CGPoint(x: 1, y: size.height / 2)); p.addLine(to: CGPoint(x: size.width - 1, y: size.height / 2))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 5]))
        }
        .frame(height: 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// What a figure is to the player: something they set (cyan), a result that follows (paper white), or a delivered
/// figure that differs from the plan (delta yellow).
enum FigureRole { case set, result, delta }

/// A figure's number with its unit, smaller and grey, on the same baseline.
struct FigureLine: View {
    let figure: FigureText
    var size: CGFloat
    var role: FigureRole = .result
    /// Draws the dotted underline under the number.
    var editable = false
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.14) {
            Text(verbatim: figure.number)
                .font(Theme.figure(size: size))
                .foregroundStyle(color)
                .overlay(alignment: .bottom) {
                    if editable { DottedUnderline(color: color).offset(y: max(4, size * 0.16)) }
                }
            if !figure.unit.isEmpty {
                Text(verbatim: figure.unit)
                    .font(Theme.unit(size: size))
                    .foregroundStyle(.secondary)
            }
        }
        // One line at the ordinary sizes; at the accessibility sizes nothing shrinks (0.7.10 everyone), it wraps.
        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
        .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
    }

    private var color: Color {
        switch role {
        case .set: return palette.accent
        case .result: return palette.paper
        case .delta: return palette.delta
        }
    }
}

/// A label, a figure and an optional word on the figure's baseline; after a shot, optionally the planned figure, an
/// arrow and the delivered one in the delta yellow ("10.0 → 14.0 mm below").
struct Readout: View {
    var label: String? = nil
    let figure: FigureText
    var size: CGFloat
    var role: FigureRole = .set
    var editable = false
    /// A word after the unit, on the same baseline ("firm", "below").
    var trailing: String? = nil
    /// After a shot, when the delivered figure differs: `figure` is then the planned one and this the delivered.
    var delivered: FigureText? = nil
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label {
                Text(verbatim: label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            }
            HStack(alignment: .firstTextBaseline, spacing: size * 0.18) {
                if let delivered {
                    // Planned in its own colour, then the arrow and the delivered figure in yellow: the arrow and the
                    // order say which is which, not the colour alone.
                    Text(verbatim: figure.number).font(Theme.figure(size: size)).foregroundStyle(palette.accent)
                    Text(verbatim: "→").font(Theme.unit(size: size)).foregroundStyle(palette.delta)
                    FigureLine(figure: delivered, size: size, role: .delta)
                } else {
                    FigureLine(figure: figure, size: size, role: role, editable: editable)
                }
                if let trailing {
                    Text(verbatim: trailing)
                        .font(Theme.unit(size: size).weight(.regular))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
        }
    }
}

/// The yellow pill under a figure the stroke changed. Its text always names the plan ("+4.8 vs 11.9 planned").
struct DeltaChip: View {
    let text: String
    @Environment(\.palette) private var palette

    var body: some View {
        Text(verbatim: text)
            .font(.footnote.monospaced().weight(.semibold))
            .foregroundStyle(palette.delta)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(palette.delta.opacity(0.15), in: .rect(cornerRadius: 6, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: Typing an exact value

/// A figure that opens the typed entry (StrikeEntryField) in a popover when tapped, while the model lets the player
/// change it. VoiceOver reads it as one button: the label, then the figure in spoken units. A figure the model holds
/// (a lesson step, the computer's turn, a mode's own angle) is plain text, not a button.
struct TypeableFigure<Content: View>: View {
    let model: ShowpieceModel
    let kind: StrikeEntry.Kind
    let spokenLabel: String
    let spokenValue: String
    @ViewBuilder var content: Content
    @State private var open = false

    var body: some View {
        let enabled = kind.isOpen(model)
        Button { open = true } label: { content.contentShape(Rectangle()) }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .hoverHighlight(.fill(cornerRadius: 10))
            .accessibilityLabel(Text(verbatim: spokenLabel))
            .accessibilityValue(Text(verbatim: spokenValue))
            .accessibilityHint(enabled ? StrikeWords.typeFigureHint : "")
            .popover(isPresented: $open) {
                StrikeEntryField(model: model, kind: kind)
                    .presentationCompactAdaptation(.popover)
            }
    }
}

// MARK: Bands

/// A band's caption: small, bold, upper case, tracked, grey. A heading for VoiceOver.
struct BandCaption: View {
    let text: String
    var body: some View {
        Text(verbatim: text)
            .font(Theme.groupCaption)
            .tracking(Theme.groupCaptionTracking)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The 1-point rule between a band's columns (vertical) or rows (horizontal).
struct HairlineRule: View {
    var vertical = true
    @Environment(\.palette) private var palette
    var body: some View {
        Rectangle()
            .fill(palette.rule)
            .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
            .accessibilityHidden(true)
    }
}

private struct BandSurface: ViewModifier {
    var ledger: Bool
    var padding: EdgeInsets
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ledger ? palette.ledger : palette.band, in: .rect(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(palette.rule, lineWidth: 1))
    }
}

extension View {
    /// The flat band surface: an opaque rounded rectangle with a hairline edge. `ledger` takes the darker tone (the
    /// physics line).
    func bandSurface(ledger: Bool = false, padding: EdgeInsets = EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18))
        -> some View {
        modifier(BandSurface(ledger: ledger, padding: padding))
    }
}
