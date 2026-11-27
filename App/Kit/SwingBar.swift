// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, part C review: the hatch's drawing takes
//          plain values instead of reading the view inside the renderer.)
// PURPOSE: UI rethink package 3 (the component kit), part C: the one swing bar, the same design on every device
//          (plans/26-Nov-2026-design-language.md, "Swing bar"). From the top:
//            1. the header: "Swing", the swing figure in the control figure size (cyan, because the player sets it;
//               typeable on the big screens, a button that opens the strike panel on the phone when the caller gives
//               onFigureTap), the zone word ("firm") in paper2, and on the right the calm limit in words and m/s
//               ("calm limit 5.3 m/s"). When the row is too narrow the calm limit drops to its own line;
//            2. the bar: a cyan fill on a sunken track with a hairline edge, the stretch past the calm limit always drawn
//               as a hatched zone with a paper mark where it starts, a lesson's target band, the delivered tick after a
//               shot (paper, with a dark edge) and the paper handle at the fill's end. A drag anywhere sets the swing;
//            3. the scale: whole metres per second, labels thinned so none touch (PowerGauge.labelledMarks in
//               AimGauges.swift, the same thinning the big bar uses), the unit after the last label.
//          The phone gets the same parts at a smaller bar height. It is a drop-in for PowerGauge (AimGauges.swift) and
//          PhonePowerBar (Phone/PhoneAimPanel.swift): the same inputs (the ShowpieceModel, the open controls, a
//          lesson's zones), the same model calls (powerFraction, powerRange, activePower, strokeZones, cueInHand), the
//          same VoiceOver element ("Power", the spoken swing, the lesson band line, a tenth of the bar per swipe or a
//          third of the lesson band), the same help text and the same lock for a closed step. Packages 4 and 6 switch
//          those two files over to it; this file does not touch them.
//          Differences from the two old bars, on purpose (the design language): no warming gradient and no warm wash
//          (cyan means "you can act here", and there is no red role), the calm limit is always drawn and labelled (the
//          old bars labelled it the first three showings only), and planned against delivered shows only as the tick
//          on the bar; the worded difference lives in the "Last shot" card, never beside the live figure.
// SRP/DRY check: Pass - reuses PowerGauge.labelledMarks for the scale, StrikeWords (swing label, speed figure, calm
//          limit, "as planned"), StrikeSpoken, StrokeWords and TableWords for the spoken value, PowerWords for the zone
//          word, FigureLine and TypeableFigure and InstrumentHandle (Strike/Instrument.swift), lockedForStep
//          (AimGauges.swift), and Theme's tokens for every size, gap, corner and colour. The fraction helpers are
//          reimplemented because the old bars keep theirs private.
import SwiftUI

struct SwingBar: View {
    let model: ShowpieceModel
    /// Which controls are open (a lesson's guided tries close some). The bar answers only while .power is open.
    var open: ShotControls = .all
    /// The lesson's target bands, if any: the power band is drawn over the bar.
    var zones: LessonZones? = nil
    /// The layout it sits in. Nil follows the old bars' rule: the big screens' inline pages (iPad, Mac, the open
    /// folding phone) get the big bar, everything else the phone bar.
    var device: Theme.Device? = nil
    /// A tap on the swing figure (the phone opens the strike panel with it, PhonePowerBar's onFigureTap). Nil: on the
    /// big screens the figure is typeable (TypeableFigure), on the phone it is plain.
    var onFigureTap: (() -> Void)? = nil
    /// After a shot, the tick where the stroke's swing landed when it differs from the plan.
    var showsDelivered = true

    @Environment(\.palette) private var palette
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.dynamicTypeSize) private var typeSize

    // Sizes that follow the reader's text size. The bar's height is a drawing size, not a gap, so it is its own value.
    @ScaledMetric(relativeTo: .body) private var phoneBarHeight: CGFloat = 20
    #if os(macOS)
    @ScaledMetric(relativeTo: .body) private var bigBarHeight: CGFloat = 32
    #else
    @ScaledMetric(relativeTo: .body) private var bigBarHeight: CGFloat = 36
    #endif
    /// The swing figure's size: the control figure, scaled as Title is.
    @ScaledMetric(relativeTo: .title) private var figureSize: CGFloat = Theme.FigureSize.control.baseSize
    /// The caption's size at the reader's text size, so the scale's labels thin out further as they grow.
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = Theme.captionBaseSize

    /// Power change per VoiceOver swipe outside a lesson band: a tenth of the range (the old bars' adjust step).
    private static let adjustStep = 0.1
    /// The scale's tick length, points (a drawing size, like the old bars' 6).
    private static let tickLength: CGFloat = 6
    /// The hatch's stripe spacing and width, points.
    private static let stripeSpacing: CGFloat = 9
    private static let stripeWidth: CGFloat = 1.5

    private var resolvedDevice: Theme.Device { device ?? (inlinePages ? .big : .phone) }
    private var barHeight: CGFloat { resolvedDevice == .phone ? phoneBarHeight : bigBarHeight }

    var body: some View {
        let reading = StrikeReading.current(model)
        let comparison = reading?.comparison
        let swing = CueProfile.swing(forPower: model.activePower)
        // Where the stroke's swing landed, in the bar's own terms: the live swing moved by the stroke's difference, as
        // PowerGauge's big bar drew it.
        let delivered = showsDelivered
            ? comparison.flatMap { $0.differs(.swing) ? swing + ($0.delivered.swing - $0.planned.swing) : nil }
            : nil
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            header(swing: swing, reading: reading, comparison: comparison)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                bar(delivered: delivered)
                scale
            }
            .modifier(SwingBarAccess(model: model, zones: zones, open: open, bandStep: bandStep,
                                     adjustStep: Self.adjustStep, onFigureTap: onFigureTap))
            // Only the bar is locked for a step that closes the swing, as PowerGauge's big bar was: the figure stays
            // bright, and the phone's tap through to the strike panel still works.
            .disabled(!open.contains(.power))
            .lockedForStep(!open.contains(.power))
        }
    }

    // MARK: Header

    /// "Swing 2.40 m/s firm ... calm limit 5.3 m/s" on one line, or the calm limit on its own line when that is too wide.
    private func header(swing: Double, reading: StrikeReading.Reading?, comparison: StrikeComparison?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                figureGroup(swing: swing, reading: reading, comparison: comparison)
                Spacer(minLength: Theme.Space.xs)
                calmWords
            }
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                figureGroup(swing: swing, reading: reading, comparison: comparison)
                calmWords
            }
        }
    }

    private func figureGroup(swing: Double, reading: StrikeReading.Reading?, comparison: StrikeComparison?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            Text(verbatim: StrikeWords.swingLabel)
                .font(Theme.label)
                .foregroundStyle(palette.paper2)
                // The figure speaks "Swing" itself (its button or its combined element).
                .accessibilityHidden(true)
            figure(swing: swing, reading: reading)
            Text(verbatim: zoneWord(comparison))
                .font(Theme.label)
                .foregroundStyle(palette.paper2)
                .lineLimit(1)
                .layoutPriority(-1)
        }
        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
    }

    /// The swing figure: typeable on the big screens, a button on the phone when the caller opens something with it,
    /// otherwise plain. Always cyan (the player sets it), with the dotted mark only where a tap types a value.
    @ViewBuilder private func figure(swing: Double, reading: StrikeReading.Reading?) -> some View {
        let moved = reading?.comparison?.differs(.swing) == true
        let spoken = reading.map { StrikeSpoken.tile(.swing, $0, differs: moved) } ?? StrikeSpoken.speed(swing)
        if let onFigureTap {
            Button(action: onFigureTap) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
                    FigureLine(figure: StrikeWords.speedFigure(swing), size: figureSize, role: .set)
                    // More behind it: the strike panel.
                    Image(systemName: "chevron.up.circle")
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: StrikeWords.swingLabel))
            .accessibilityValue(Text(verbatim: spoken))
        } else if resolvedDevice != .phone {
            TypeableFigure(model: model, kind: .swing, spokenLabel: StrikeWords.swingLabel, spokenValue: spoken) {
                FigureLine(figure: StrikeWords.speedFigure(swing), size: figureSize, role: .set,
                           editable: StrikeEntry.Kind.swing.isOpen(model))
                    // Room for the dotted mark under the number.
                    .padding(.bottom, Theme.Space.xxs)
            }
        } else {
            FigureLine(figure: StrikeWords.speedFigure(swing), size: figureSize, role: .set)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: StrikeWords.swingLabel))
                .accessibilityValue(Text(verbatim: spoken))
        }
    }

    /// The plain word for the swing ("firm"), and "as planned" after a shot whose swing landed as set.
    private func zoneWord(_ c: StrikeComparison?) -> String {
        let word = PowerWords.word(speed: model.cueInHand.launchSpeed(forPower: model.activePower), racked: model.racked)
        guard let c, !c.differs(.swing) else { return word }
        return word + " · " + StrikeWords.asPlanned
    }

    /// "calm limit 5.3 m/s", always shown while the calm zone ends inside the bar. Read by the bar's own element.
    @ViewBuilder private var calmWords: some View {
        if calmFraction < 1 {
            Text(verbatim: StrikeWords.calmLimit(model.strokeZones.calmTopSwing))
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
                .lineLimit(1)
                .fixedSize()
                .accessibilityHidden(true)
        }
    }

    // MARK: The bar

    /// The track, the hatch past the calm limit, the cyan fill, a lesson's band, the calm mark, the delivered tick and
    /// the handle. A drag anywhere on it (and a generous margin around it, so the touch area is at least 44 points
    /// tall) sets the swing.
    private func bar(delivered: Double?) -> some View {
        let h = barHeight
        let fraction = CGFloat(model.powerFraction)
        let calm = CGFloat(calmFraction)
        let strength = zones?.strength ?? 1
        let reach = max(0, (Theme.Size.minHit - h) / 2)
        return GeometryReader { geo in
            let w = max(1, geo.size.width)
            ZStack(alignment: .leading) {
                // The sunken track.
                Capsule()
                    .fill(palette.panelSunken)
                    .overlay(Capsule().strokeBorder(palette.rule, lineWidth: Theme.Size.hairline))
                // Past the calm limit: the hatched zone (a harder swing drifts more there), always drawn.
                if calm < 1 {
                    hatch(height: h)
                        .frame(width: w * (1 - calm), height: h)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0,
                                                          bottomTrailingRadius: Theme.Corner.capsule(height: h),
                                                          topTrailingRadius: Theme.Corner.capsule(height: h)))
                        .offset(x: w * calm)
                        .allowsHitTesting(false)
                }
                // The swing: a plain cyan fill.
                Capsule()
                    .fill(palette.accent)
                    .frame(width: max(h, w * fraction), height: h)
                // A lesson's target band: the stretch of the bar where the shot works.
                if let band = zones?.power {
                    let lo = share(band.lowerBound), hi = share(band.upperBound)
                    Capsule()
                        .strokeBorder(palette.paper.opacity(0.95 * strength), lineWidth: Theme.Size.editableUnderline)
                        .background(Capsule().fill(palette.paper.opacity(0.25 * strength)))
                        .frame(width: max(Theme.Space.xxs, w * (hi - lo)), height: h + Theme.Space.xs)
                        .offset(x: w * lo)
                        .allowsHitTesting(false)
                }
                // Where the calm zone ends.
                if calm < 1 {
                    Rectangle()
                        .fill(palette.paper.opacity(0.85))
                        .frame(width: 2, height: h + Theme.Space.sm)
                        .offset(x: w * calm - 1)
                        .allowsHitTesting(false)
                }
                // Where the stroke's swing landed, after a shot (paper with a dark edge, so it reads on the fill).
                if let delivered {
                    Rectangle()
                        .fill(palette.paper)
                        .overlay(Rectangle().strokeBorder(palette.ground.opacity(0.6), lineWidth: Theme.Size.hairline))
                        .frame(width: 4, height: h + Theme.Space.xs)
                        .offset(x: w * swingShare(delivered) - 2)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                InstrumentHandle(diameter: h + Theme.Space.xxs, style: .paper)
                    .position(x: min(max(w * fraction - h / 2, h / 2), w - h / 2), y: h / 2)
            }
            .frame(height: h)
            .contentShape(Rectangle().inset(by: -reach))
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                guard open.contains(.power) else { return }
                model.powerFraction = Double(value.location.x / w)
            })
        }
        .frame(height: h)
        // The drag margin reaches past the bar; keep it clear of whatever sits above and below.
        .padding(.vertical, min(reach, Theme.Space.xs))
    }

    /// Diagonal stripes in paper, faint, the height of the bar.
    private func hatch(height: CGFloat) -> some View {
        // Plain values into the renderer, so the drawing closure holds nothing of the view.
        let stripe = palette.paper.opacity(0.16)
        let spacing = Self.stripeSpacing, lineWidth = Self.stripeWidth
        return Canvas { ctx, size in
            var stripes = Path()
            var x = -size.height
            while x < size.width {
                stripes.move(to: CGPoint(x: x, y: size.height))
                stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += spacing
            }
            ctx.stroke(stripes, with: .color(stripe), lineWidth: lineWidth)
        }
    }

    // MARK: The scale

    /// Whole metres per second from the soft end to the cue's top swing, the unit after the last label. Every whole
    /// number keeps its tick; only the labels PowerGauge.labelledMarks picks are written.
    private var scale: some View {
        let r = swingRange
        let low = Int(r.lowerBound.rounded(.up))
        let marks = Array(low...max(low, Int(r.upperBound.rounded(.down))))
        // labelledMarks keeps labels a fixed distance apart, worked out for the default caption size. At a larger text
        // size the labels are wider, so the positions it sees are shrunk by the same ratio: it then thins further.
        let squeeze = min(1, Theme.captionBaseSize / max(1, captionSize))
        return GeometryReader { geo in
            let width = geo.size.width
            let labelled = PowerGauge.labelledMarks(marks, width: width * squeeze) {
                width * squeeze * swingShare(Double($0))
            }
            ZStack(alignment: .topLeading) {
                ForEach(marks, id: \.self) { n in
                    let x = width * swingShare(Double(n))
                    let last = n == marks.last
                    VStack(spacing: Theme.Space.xxs) {
                        Rectangle().fill(palette.paper3).frame(width: Theme.Size.hairline, height: Self.tickLength)
                        Text(verbatim: last ? "\(StrikeWords.number(Double(n), decimals: 0)) \(UnitSymbol.shown("m/s"))"
                                            : StrikeWords.number(Double(n), decimals: 0))
                            .font(Theme.caption.monospacedDigit())
                            .foregroundStyle(palette.paper3)
                            .fixedSize()
                            .opacity(labelled.contains(n) ? 1 : 0)
                    }
                    // Centred on its mark; the first and last held inside the bar's width.
                    .alignmentGuide(.leading) { d in -min(max(x - d.width / 2, 0), max(0, width - d.width)) }
                }
            }
        }
        .frame(height: Self.tickLength + Theme.Space.xxs + captionSize * 1.3)
        .accessibilityHidden(true)
    }

    // MARK: Fractions

    /// The swing range the bar spans, metres per second: the soft end's and the cue's top swing.
    private var swingRange: ClosedRange<Double> {
        let r = model.powerRange
        return CueProfile.swing(forPower: r.lowerBound)...CueProfile.swing(forPower: r.upperBound)
    }

    /// A swing as a share of the bar.
    private func swingShare(_ swing: Double) -> CGFloat {
        let r = swingRange
        return CGFloat(min(max((swing - r.lowerBound) / max(0.0001, r.upperBound - r.lowerBound), 0), 1))
    }

    /// A launch speed (the lesson's band is in these) as a share of the bar.
    private func share(_ speed: Double) -> CGFloat {
        let r = model.powerRange
        return CGFloat(min(max((speed - r.lowerBound) / max(0.0001, r.upperBound - r.lowerBound), 0), 1))
    }

    /// Where the calm zone ends on the bar, 0 to 1 (1: the whole bar is calm, so no hatch and no mark).
    private var calmFraction: Double {
        let r = model.powerRange
        let top = model.strokeZones.calmTopPower
        return min(1, max(0, (top - r.lowerBound) / max(0.0001, r.upperBound - r.lowerBound)))
    }

    /// While a lesson marks a power band and power may change: a third of that band's share of the bar, so no single
    /// swipe can jump over the window. Nil with no band.
    private var bandStep: Double? {
        guard open.contains(.power), let band = zones?.power else { return nil }
        let width = Double(share(band.upperBound) - share(band.lowerBound))
        return width > 0 ? width / 3 : nil
    }
}

/// The bar and its scale as one adjustable VoiceOver element, with the old bars' label, value, steps and help.
private struct SwingBarAccess: ViewModifier {
    let model: ShowpieceModel
    let zones: LessonZones?
    let open: ShotControls
    let bandStep: Double?
    let adjustStep: Double
    let onFigureTap: (() -> Void)?

    func body(content: Content) -> some View {
        let fraction = model.powerFraction
        let warm = model.activePower > model.strokeZones.calmTopPower
        // The spoken value already says when the swing is past the calm limit (StrokeWords.spoken's warm), as before.
        let value = TableWords.joined(
            String(localized: "\(String(format: "%.0f", locale: AppLocale.numbers, fraction * 100)) percent, \(StrokeWords.spoken(power: model.activePower, racked: model.racked, warm: warm, cue: model.cueInHand))"),
            TableWords.powerBandLine(model, zones: zones))
        return content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Power"))
            .accessibilityValue(value)
            .accessibilityAdjustableAction { direction in
                // A tenth of the bar per swipe, or the lesson band's finer step while one is up.
                let swipe = min(adjustStep, bandStep ?? adjustStep)
                switch direction {
                case .increment: model.powerFraction += swipe
                case .decrement: model.powerFraction -= swipe
                @unknown default: break
                }
            }
            .accessibilityActions {
                // The phone's strike panel, reachable from the bar as PhonePowerBar offered it.
                if let onFigureTap {
                    Button(StrikeWords.liveHeading) { onFigureTap() }
                }
            }
            .help(Text(verbatim: StrokeWords.ballReadout(power: model.activePower, racked: model.racked, cue: model.cueInHand) + " · "
                       + String(localized: "Cue: \(model.cueInHand.name). Pull back from the cue ball on the table, or drag here.")))
    }
}

#Preview("Swing bar, big") {
    SwingBar(model: ShowpieceModel(), device: .big)
        .padding(Theme.Space.lg)
        .frame(width: Theme.Size.sideColumn)
        .background(Palette(contrast: .standard).panel)
}

#Preview("Swing bar, phone") {
    SwingBar(model: ShowpieceModel(), device: .phone, onFigureTap: {})
        .padding(Theme.Space.md)
        .frame(width: 375)
        .background(Palette(contrast: .standard).panel)
}

#Preview("Swing bar, lesson band, locked") {
    SwingBar(model: ShowpieceModel(), open: [.aim], zones: LessonZones(power: 2.0...3.0), device: .big)
        .padding(Theme.Space.lg)
        .frame(width: Theme.Size.sideColumn)
        .background(Palette(contrast: .standard).panel)
}
