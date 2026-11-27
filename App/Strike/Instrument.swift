// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console: the editable mark is the
//          kit's KitEditableMark (1.5 points, always cyan; DottedUnderline is gone); the delta role and Readout's
//          planned-to-delivered form are gone, since planned against delivered lives only in the "Last shot" card;
//          BandCaption is the kit's section label; bandSurface is the panel (or, for the ledger, the sunken strip) with
//          Theme's corners; the handle's ring and the chip's corners take tokens.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: the difference chip is paper2 on a sunken chip,
//          the delivered figure paper; the delta yellow is retired.)
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
            .overlay(Circle().strokeBorder(palette.ground.opacity(0.75), lineWidth: max(1.5, diameter * 0.09)))
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

/// What a figure is to the player: something they set (cyan) or a result that follows (paper). UI rethink package 4:
/// the delta role went with the delta yellow; a delivered figure is a result, in paper, inside the "Last shot" card.
enum FigureRole { case set, result }

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
                    // The kit's editable mark: 1.5 points, dotted, always cyan (its only meaning).
                    if editable { KitEditableMark().offset(y: max(Theme.Space.xxs, size * 0.16)) }
                }
            if !figure.unit.isEmpty {
                Text(verbatim: figure.unit)
                    .font(Theme.unit(size: size))
                    .foregroundStyle(palette.paper2)
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
        }
    }
}

/// A label, a figure and an optional word on the figure's baseline ("6.3 mm below"). UI rethink package 4: always the
/// live figure; the planned-to-delivered form went to the "Last shot" card.
struct Readout: View {
    var label: String? = nil
    let figure: FigureText
    var size: CGFloat
    var role: FigureRole = .set
    var editable = false
    /// A word after the unit, on the same baseline ("firm", "below").
    var trailing: String? = nil
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
            if let label {
                Text(verbatim: label)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper2)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            }
            HStack(alignment: .firstTextBaseline, spacing: size * 0.18) {
                FigureLine(figure: figure, size: size, role: role, editable: editable)
                if let trailing {
                    Text(verbatim: trailing)
                        .font(Theme.label)
                        .foregroundStyle(palette.paper2)
                        .fixedSize()
                }
            }
            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
        }
    }
}

/// The worded difference chip ("+4.8 vs 11.9 planned"): paper2 on a sunken chip, no hue of its own. UI rethink package
/// 4: no longer drawn under the live figures; kept for any caller that words a plan beside a figure.
struct DeltaChip: View {
    let text: String
    @Environment(\.palette) private var palette

    var body: some View {
        Text(verbatim: text)
            .font(Theme.inlineFigure)
            .foregroundStyle(palette.paper2)
            .padding(.horizontal, Theme.Space.chipHorizontal)
            .padding(.vertical, Theme.Space.chipVertical)
            // The kit's chip surface: sunken, small corners, no edge.
            .background(palette.panelSunken, in: Theme.Corner.tileShape)
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
            .hoverHighlight(.fill(cornerRadius: Theme.Corner.small))
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

/// A band's caption ("WHAT THE BALL GETS"): the kit's section label (caption, bold, upper case, tracked, paper2), a
/// heading for VoiceOver.
struct BandCaption: View {
    let text: String
    var body: some View {
        SectionLabel(text)
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
            .frame(width: vertical ? Theme.Size.hairline : nil, height: vertical ? nil : Theme.Size.hairline)
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
            // UI rethink package 4: the house panel (hairline edge, medium corners), or for the ledger the sunken strip
            // (no edge, small corners), as the design language's surfaces say.
            .background(ledger ? palette.panelSunken : palette.panel,
                        in: RoundedRectangle(cornerRadius: ledger ? Theme.Corner.small : Theme.Corner.medium, style: .continuous))
            .overlay {
                if !ledger { Theme.Corner.cardShape.strokeBorder(palette.rule, lineWidth: Theme.Size.hairline) }
            }
    }
}

extension View {
    /// The flat band surface: an opaque rounded rectangle with a hairline edge. `ledger` takes the darker tone (the
    /// physics line).
    func bandSurface(ledger: Bool = false,
                     padding: EdgeInsets = EdgeInsets(top: Theme.Space.md, leading: Theme.Space.md,
                                                      bottom: Theme.Space.md, trailing: Theme.Space.md))
        -> some View {
        modifier(BandSurface(ledger: ledger, padding: padding))
    }
}
