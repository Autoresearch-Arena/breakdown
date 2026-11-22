// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the power readout and its spoken value carry a plain word before the
//          number, soft to hard or break, from PowerWords).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the tip travel is the model's own model.tipLimit, an instance value
//          per mode, in place of the old fixed ShowpieceModel.tipLimit.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, package 5: minus and plus buttons beside the
//          power bar, so power can be set with single taps instead of a drag or a pull-back.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: both gauges take the open controls and the lesson's target
//          bands (ShotControls, LessonZones from Lessons.swift). A band is drawn where the shot works: across the cue-ball
//          picture for tip height, down it for side, a rectangle for both, and a stretch of the power bar. A locked
//          control is dimmed, shows a lock and tells VoiceOver "Locked for this step" (lockedForStep, shared with the
//          shot panel's sliders and the cue-angle menu). The model refuses the change anyway; this is what is seen.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: the power bar shows the swing ("firm · swing 2.6 m/s",
//          StrokeWords) with the ball's speed spoken and in the help; a calm zone and a warm zone on the bar, a mark at
//          the calm zone's top (model.strokeZones, which moves with the bridge finger) and the warm part tinted, so
//          the player sees where a harder swing starts to cost control.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the cue-ball picture is to scale, so the dot's
//          reach and the dashed miscue ring sit where the default physics puts them: the ring at the miscue limit,
//          about half the radius, the dot a tenth of the radius beyond it.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, gauges-pointer stream, items 1 and 11 of
//          plans/21-Nov-2026-bugs-after-0-6-6-plan.md: the power bar's calm mark carries a short label, "Calm zone ends",
//          the first three times the mark shows, so the white line is explained where it is seen. While a lesson marks a
//          tip band, the centre snap is off (it swallowed part of the stop band) and a dot let go inside a band, or
//          touching it, settles on the band's middle, so a band narrower than the dot can still be hit. While a lesson
//          marks a power band, a tap of minus or plus (and a VoiceOver adjust) moves a third of that band, never more
//          than the usual step, so the window cannot be stepped over. The help names the cue in hand (model.cueInHand).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hooks, 0.7.0 item 46: the tip picture's spoken value, band status and actions
//          come from TipAccessActions, and the power value adds the lesson's band, TableWords.powerBandLine.)
// PURPOSE: The two small gauges beside the table in the shot panel. TipPicker is a picture of the cue ball: touch or
//          drag on it to place the cue tip (up for follow, down for draw, left and right for side spin), with a faint
//          ring marking how far from the middle the tip can go before the cue would slip off. PowerGauge is a bar
//          that shows the strike power as a number and a fill; it moves while the player pulls back on the table, and
//          it can also be touched or dragged directly. Both write only the model's "active" values (break values while
//          the balls are racked, shot values afterwards), so the sliders in the fine-controls sheet and these gauges
//          always agree. Both are 44 points or more in every direction, scale with the text size, and speak a value
//          and offer actions to VoiceOver, so they are usable without touching the picture.
// SRP/DRY check: Pass - checked ShotPanel's slider rows, which stay as the accessible fallback; these are the new
//          touch-first versions of the same three values (power, tip height, tip side), not a second copy of the logic.
import SwiftUI

// MARK: Cue ball picture

struct TipPicker: View {
    let model: ShowpieceModel
    /// Which controls are open (a lesson's guided tries close some); tip height and side are this picture's two.
    var open: ShotControls = .all
    /// The lesson's target bands, if any: tip height across, side down.
    var zones: LessonZones? = nil
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 52

    /// The picture is the cue ball to scale. The dot travels as far as the mode's tip travel (model.tipLimit) as a
    /// share of the ball's radius, and the dashed ring sits at the miscue limit (model.miscueLimit), where the tip slips
    /// on the default physics: about half the radius, a little inside the dot's reach.
    private func share(_ metres: Double) -> CGFloat {
        CGFloat(min(max(metres / model.cueBallRadius, 0.1), 0.95))
    }

    var body: some View {
        // Grows with text size for easy touching but stops at 72 points: past that it would crowd out the table.
        let size = min(max(44, side), 72)
        let radius = size / 2
        let limit = radius * share(model.tipLimit)
        let ring = radius * share(model.miscueLimit)
        let up = model.activeTipUp / model.tipLimit
        let across = model.activeTipSide / model.tipLimit
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 1.0), Color(white: 0.80)], center: .init(x: 0.38, y: 0.32),
                                     startRadius: 1, endRadius: radius * 1.3))
                .overlay(Circle().strokeBorder(.black.opacity(0.35), lineWidth: 1))
            // Cross hairs through the middle: where "centre" is.
            Path { p in
                p.move(to: CGPoint(x: radius - limit * 0.6, y: radius)); p.addLine(to: CGPoint(x: radius + limit * 0.6, y: radius))
                p.move(to: CGPoint(x: radius, y: radius - limit * 0.6)); p.addLine(to: CGPoint(x: radius, y: radius + limit * 0.6))
            }
            .stroke(.black.opacity(0.18), lineWidth: 1)
            Circle().strokeBorder(.black.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(width: ring * 2, height: ring * 2)
            // A lesson's target band: where on the cue ball the shot works, clipped to the reachable disc.
            if let band = tipBand(radius: radius, limit: limit) {
                Path(band)
                    .fill(palette.accent.opacity(0.30 * (zones?.strength ?? 1)))
                    .overlay { Path(band).stroke(palette.accent.opacity(0.9 * (zones?.strength ?? 1)), lineWidth: 1) }
                    .clipShape(Circle().inset(by: radius - limit))
                    .allowsHitTesting(false)
            }
            // The chalked tip. Drawn dark with a pale rim so it reads on the white ball in every appearance.
            Circle()
                .fill(palette.accent)
                .overlay(Circle().strokeBorder(.black.opacity(0.7), lineWidth: 1.5))
                .frame(width: Self.dot, height: Self.dot)
                .offset(x: CGFloat(across) * limit, y: CGFloat(-up) * limit)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                // Locked in this lesson step: the touch does nothing (the model would refuse the change too).
                guard tipOpen else { return }
                // Touch position relative to the middle, as a fraction of the reachable disc, then clamped to the disc.
                var x = Double((value.location.x - radius) / limit)
                var y = Double(-(value.location.y - radius) / limit)
                let len = (x * x + y * y).squareRoot()
                if len > 1 { x /= len; y /= len }
                // A tiny region around the middle snaps to exactly centre so "centre" is easy to hit, but never while a
                // lesson marks a tip band: the stop band sits a couple of millimetres below centre, inside this region.
                if len < Self.centreSnap, !hasTipBand { x = 0; y = 0 }
                // Only the open one of the two moves when a lesson has opened just one: the other stays where it was set.
                if open.contains(.tipSide) { model.activeTipSide = x * model.tipLimit }
                if open.contains(.tipUp) { model.activeTipUp = y * model.tipLimit }
            }
            .onEnded { _ in
                guard tipOpen else { return }
                // The dot is drawn `dot` points wide; in metres of tip travel, half of that is how far outside a band
                // the dot's centre can be while the dot still visibly overlaps it.
                settleInBand(tolerance: Double(Self.dot / 2 / max(1, limit)) * model.tipLimit)
            })
        .accessibilityElement()
        .accessibilityLabel("Cue tip position")
        .accessibilityHint("Drag on the ball to place the tip. Or use the actions.")
        .accessibilityAddTraits(.allowsDirectInteraction)
        // Access stream hook (0.7.0 item 46): the spoken amount and band, fine steps, band-aware quick actions and
        // Into the marked band, none while locked (TableAccessLayer.swift).
        .modifier(TipAccessActions(model: model, open: open, zones: zones))
        .help("Cue tip: drag to choose follow, draw or side")
        .lockedForStep(!tipOpen)
    }

    /// True when at least one of the picture's two values may change in this step.
    private var tipOpen: Bool { open.contains(.tipUp) || open.contains(.tipSide) }

    /// The chalked tip's drawn width, points: big enough to see under a fingertip's edge on the 52-point picture.
    private static let dot: CGFloat = 13
    /// The centre snap's reach, as a share of the dot's travel: about two millimetres of tip on the default physics,
    /// a fingertip's wobble on the picture, so "centre" is easy to hit outside a lesson band.
    private static let centreSnap = 0.12

    /// True while the lesson marks a tip band (height, side or both).
    private var hasTipBand: Bool { zones?.tipUp != nil || zones?.tipSide != nil }

    /// A dot let go inside a lesson's tip band, or touching it (within `tolerance` metres), settles on the band's
    /// middle, for each banded value this step lets the player change. The bands are a few millimetres wide, narrower
    /// than the dot itself, so a finger that lands the dot on the band has done what the lesson asks; the middle is
    /// where the shot works best. A dot that ends off the band is left exactly where it was put.
    private func settleInBand(tolerance: Double) {
        guard let z = zones else { return }
        let upBand = open.contains(.tipUp) ? z.tipUp : nil
        let sideBand = open.contains(.tipSide) ? z.tipSide : nil
        guard upBand != nil || sideBand != nil else { return }
        func touches(_ value: Double, _ band: ClosedRange<Double>) -> Bool {
            value >= band.lowerBound - tolerance && value <= band.upperBound + tolerance
        }
        // Both marked values must be on their bands (a rectangle on the picture) before either moves.
        if let band = upBand, !touches(model.activeTipUp, band) { return }
        if let band = sideBand, !touches(model.activeTipSide, band) { return }
        if let band = upBand { model.activeTipUp = (band.lowerBound + band.upperBound) / 2 }
        if let band = sideBand { model.activeTipSide = (band.lowerBound + band.upperBound) / 2 }
    }

    /// The band to draw, in the picture's own points: the marked tip-height range across the whole ball, the marked
    /// side range down it, or the rectangle where both meet. Nil when nothing is marked.
    private func tipBand(radius: CGFloat, limit: CGFloat) -> CGRect? {
        guard let z = zones, z.tipUp != nil || z.tipSide != nil else { return nil }
        let travel = model.tipLimit
        // Metres to points: the dot moves `limit` points for `travel` metres; up is toward the top of the picture.
        func x(_ m: Double) -> CGFloat { radius + CGFloat(min(max(m / travel, -1), 1)) * limit }
        func y(_ m: Double) -> CGFloat { radius - CGFloat(min(max(m / travel, -1), 1)) * limit }
        let left = z.tipSide.map { x($0.lowerBound) } ?? 0
        let right = z.tipSide.map { x($0.upperBound) } ?? radius * 2
        let top = z.tipUp.map { y($0.upperBound) } ?? 0
        let bottom = z.tipUp.map { y($0.lowerBound) } ?? radius * 2
        return CGRect(x: left, y: top, width: max(1, right - left), height: max(1, bottom - top))
    }

    /// "follow, left" and so on; "centre" when the tip is in the middle.
    static func spoken(up: Double, side: Double) -> String {
        let v = up < -0.002 ? ShotPanel.shownWord("draw") : (up > 0.002 ? ShotPanel.shownWord("follow") : nil)
        let h = side < -0.002 ? ShotPanel.shownWord("left") : (side > 0.002 ? ShotPanel.shownWord("right") : nil)
        switch (v, h) {
        case (nil, nil): return ShotPanel.shownWord("centre")
        case let (v?, nil): return v
        case let (nil, h?): return h
        case let (v?, h?): return String(localized: "\(v), \(h)")
        }
    }
}

// MARK: Power

struct PowerGauge: View {
    let model: ShowpieceModel
    /// Which controls are open (a lesson's guided tries close some).
    var open: ShotControls = .all
    /// The lesson's target bands, if any: the power band is drawn over the bar.
    var zones: LessonZones? = nil
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 12
    /// How many times the calm mark has been shown with its label (item 1). Stored on the device, so the label stops
    /// for good after the first few showings; the store-picture scripts can pin it (key in calmLabelKey).
    @AppStorage(PowerGauge.calmLabelKey) private var calmLabelShows = 0
    /// True while this showing of the gauge carries the label. Decided once per appearance (or when the mark first
    /// appears during one), never while the body is being drawn.
    @State private var labelsCalm = false

    /// The stored count behind the calm mark's label.
    static let calmLabelKey = "calmMarkLabelShows"
    /// Showings of the calm mark that carry its label: enough for a newcomer to read it over the hand-over, the first
    /// break and the first shot after it (the first three times the shot panel shows the mark), after which the mark
    /// alone is familiar and the label would only take room from the panel.
    static let calmLabelShowings = 3

    var body: some View {
        let fraction = model.powerFraction
        let calm = calmFraction
        let warm = model.activePower > model.strokeZones.calmTopPower
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Power").font(Theme.label).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(StrokeWords.readout(power: model.activePower, racked: model.racked))
                    .font(Theme.number)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(spacing: 6) {
                // One-finger power without a drag: a tap a step down, a tap a step up (accessibility plan, package 5).
                stepButton(-1, systemImage: "minus", label: "Less power")
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.track)
                        // The gradient spans the whole bar and a capsule-shaped mask reveals the part below the power
                        // level, so the fill gets warmer as power rises instead of squashing the colours into the fill.
                        Capsule()
                            .fill(LinearGradient(colors: [palette.accent, palette.slide, Self.hot], startPoint: .leading, endPoint: .trailing))
                            .mask(alignment: .leading) { Capsule().frame(width: max(barHeight, geo.size.width * fraction)) }
                        // A lesson's target band: the stretch of the bar where the shot works.
                        if let band = zones?.power {
                            let lo = powerFraction(band.lowerBound), hi = powerFraction(band.upperBound)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(palette.paper.opacity(0.95 * (zones?.strength ?? 1)), lineWidth: 1.5)
                                .background(RoundedRectangle(cornerRadius: 3).fill(palette.paper.opacity(0.25 * (zones?.strength ?? 1))))
                                .frame(width: max(4, geo.size.width * (hi - lo)), height: barHeight + 6)
                                .offset(x: geo.size.width * lo)
                                .allowsHitTesting(false)
                        }
                        // The warm zone: past the calm top a faint warm wash over the track, and a thin mark where the
                        // calm zone ends (the stroke plan: past it, a harder swing drifts more).
                        if calm < 1 {
                            Capsule()
                                .fill(Self.hot.opacity(0.16))
                                .frame(width: geo.size.width * (1 - calm))
                                .offset(x: geo.size.width * calm)
                                .allowsHitTesting(false)
                            Rectangle()
                                .fill(palette.paper.opacity(0.75))
                                .frame(width: 2, height: barHeight + 6)
                                .offset(x: geo.size.width * calm - 1)
                                .allowsHitTesting(false)
                        }
                    }
                    .contentShape(Rectangle().inset(by: -16))
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        guard open.contains(.power) else { return }
                        model.powerFraction = Double(value.location.x / max(1, geo.size.width))
                    })
                }
                .frame(height: barHeight)
                // The calm mark's label, the first few times the mark shows (item 1): a small caret under the mark and
                // "Calm zone ends" centred on it, slid back inside the bar if it would hang over an end. Laid over the
                // bar rather than in the layout, so it measures against the bar's own width and the bar and buttons stay
                // exactly where they always are.
                .overlay(alignment: .topLeading) {
                    if labelsCalm, calm < 1 {
                        GeometryReader { geo in
                            let markX = geo.size.width * calm
                            ZStack(alignment: .topLeading) {
                                Image(systemName: "arrowtriangle.up.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)
                                    .offset(x: markX - 3, y: barHeight + 4)
                                Text("Calm zone ends")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .fixedSize()
                                    // The guide is minus the label's left edge: centred on the mark, then held inside
                                    // the bar's width.
                                    .alignmentGuide(.leading) { d in
                                        -min(max(markX - d.width / 2, 0), max(0, geo.size.width - d.width))
                                    }
                                    .offset(y: barHeight + 10)
                            }
                        }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
                stepButton(1, systemImage: "plus", label: "More power")
            }
            // Room under the bar for the calm mark's label while it shows. The bar sits in the middle of the 44-point
            // step buttons, so the label first falls beside them; this keeps its lower half clear of whatever the shot
            // panel puts under the gauge.
            if labelsCalm, calm < 1 {
                Color.clear.frame(height: Self.calmLabelRoom).accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .onAppear { noteCalmMark() }
        .onChange(of: calm < 1) { noteCalmMark() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Power")
        // The lesson's power band, when one is marked, after the value (access stream hook, 0.7.0 item 46).
        .accessibilityValue(TableWords.joined(String(localized: "\(String(format: "%.0f", locale: Locale.current, fraction * 100)) percent, \(StrokeWords.spoken(power: model.activePower, racked: model.racked, warm: warm))"),
                                              TableWords.powerBandLine(model, zones: zones)))
        .accessibilityAdjustableAction { direction in
            // A tenth of the bar per swipe, or the lesson band's finer step while one is up (see tapStep).
            let swipe = min(Self.adjustStep, bandStep ?? Self.adjustStep)
            switch direction {
            case .increment: model.powerFraction += swipe
            case .decrement: model.powerFraction -= swipe
            @unknown default: break
            }
        }
        .help(Text(verbatim: StrokeWords.ballReadout(power: model.activePower, racked: model.racked) + " · "
                   + String(localized: "Cue: \(model.cueInHand.name). Pull back from the cue ball on the table, or drag here.")))
        .disabled(!open.contains(.power))
        .lockedForStep(!open.contains(.power))
    }

    /// Decide whether this showing of the gauge labels the calm mark: only while the mark is on the bar, only for the
    /// first calmLabelShowings showings, and counted once per showing. Called from onAppear and when the mark first
    /// appears (a break hands over to a shot, whose calm zone ends inside the bar), never from the body itself.
    private func noteCalmMark() {
        guard !labelsCalm, calmFraction < 1, calmLabelShows < Self.calmLabelShowings else { return }
        labelsCalm = true
        calmLabelShows += 1
    }

    /// Extra height under the bar row while the calm label shows, points. At the default text size the label's line
    /// (caption2, about 13 points tall) starts 10 points below the bar's lower edge, and that edge is 16 points above
    /// the 44-point buttons' lower edge, so the line runs about 7 points past the row; this plus the stack's own 6-point
    /// gap keeps it inside the gauge.
    private static let calmLabelRoom: CGFloat = 8

    /// A launch speed as a share of the bar, 0 at its soft end, 1 at its hard end (the gauge's own fraction).
    private func powerFraction(_ speed: Double) -> CGFloat {
        let r = model.powerRange
        return CGFloat(min(max((speed - r.lowerBound) / (r.upperBound - r.lowerBound), 0), 1))
    }

    /// Where the calm zone ends on the bar, 0 to 1 (1: the whole bar is calm, so no mark is drawn).
    private var calmFraction: Double {
        let range = model.powerRange
        let top = model.strokeZones.calmTopPower
        return min(1, max(0, (top - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    /// The hard end of the bar: a warm red that still reads on glass.
    private static let hot = Color(red: 1.0, green: 0.30, blue: 0.25)

    /// Power change per tap of the step buttons: a twentieth of the range, fine enough to set a soft roll by
    /// tapping and coarse enough to cross the bar in a handful of taps.
    private static let tapStep = 0.05
    /// Power change per VoiceOver swipe outside a lesson band: a tenth of the range, so the bar is crossed in ten swipes.
    private static let adjustStep = 0.1

    /// While a lesson marks a power band and power may change: a third of that band's share of the bar, so at least
    /// three taps land inside it and no single tap can jump from one side of the window to the other (the follow
    /// lesson's window is narrower than the usual step, finding 60). Nil with no band, or a band of no width.
    private var bandStep: Double? {
        guard open.contains(.power), let band = zones?.power else { return nil }
        let width = Double(powerFraction(band.upperBound) - powerFraction(band.lowerBound))
        return width > 0 ? width / 3 : nil
    }

    /// A small round minus or plus button beside the bar (`direction` -1 or +1). Each tap is one step, the usual step
    /// or a lesson band's finer one, whichever is smaller; nothing repeats while held.
    private func stepButton(_ direction: Double, systemImage: String, label: LocalizedStringKey) -> some View {
        Button { model.powerFraction += direction * min(Self.tapStep, bandStep ?? Self.tapStep) } label: {
            Image(systemName: systemImage).font(Theme.label).frame(width: 30, height: 30)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.regular)   // 30 points plus the bordered circle lands on 44 or more (as ShotPanel's nudge buttons)
        .help(Text(label))
        // The whole gauge is one adjustable element for VoiceOver already; these are for touch and pointer.
        .accessibilityHidden(true)
    }
}

// MARK: Locked for this step

extension View {
    /// A shot control a lesson has locked for this step: dimmed, a small lock at its corner, and VoiceOver told why it
    /// does not respond. Used by the gauges here, the shot panel's sliders and the cue-angle menu.
    @ViewBuilder func lockedForStep(_ locked: Bool) -> some View {
        if locked {
            self.opacity(0.45)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .accessibilityHint(String(localized: "Locked for this step"))
        } else {
            self
        }
    }
}
