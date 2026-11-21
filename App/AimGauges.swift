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

    /// The dot may travel to 70% of the ball's radius at full tip offset; the ring drawn there is the miscue limit.
    private let reach: CGFloat = 0.7

    var body: some View {
        // Grows with text size for easy touching but stops at 72 points: past that it would crowd out the table.
        let size = min(max(44, side), 72)
        let radius = size / 2
        let limit = radius * reach
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
                .frame(width: limit * 2, height: limit * 2)
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
                .frame(width: 13, height: 13)
                .offset(x: CGFloat(across) * limit, y: CGFloat(-up) * limit)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged { value in
            // Locked in this lesson step: the touch does nothing (the model would refuse the change too).
            guard tipOpen else { return }
            // Touch position relative to the middle, as a fraction of the reachable disc, then clamped to the disc.
            var x = Double((value.location.x - radius) / limit)
            var y = Double(-(value.location.y - radius) / limit)
            let len = (x * x + y * y).squareRoot()
            if len > 1 { x /= len; y /= len }
            // A tiny region around the middle snaps to exactly centre so "centre" is easy to hit.
            if len < 0.12 { x = 0; y = 0 }
            // Only the open one of the two moves when a lesson has opened just one: the other stays where it was set.
            if open.contains(.tipSide) { model.activeTipSide = x * model.tipLimit }
            if open.contains(.tipUp) { model.activeTipUp = y * model.tipLimit }
        })
        .accessibilityElement()
        .accessibilityLabel("Cue tip position")
        .accessibilityValue(Self.spoken(up: model.activeTipUp, side: model.activeTipSide))
        .accessibilityHint("Drag on the ball to place the tip. Or use the actions.")
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityAction(named: "Follow") { model.activeTipUp = model.tipLimit * 0.6 }
        .accessibilityAction(named: "Draw") { model.activeTipUp = -model.tipLimit * 0.6 }
        .accessibilityAction(named: "Left spin") { model.activeTipSide = -model.tipLimit * 0.6 }
        .accessibilityAction(named: "Right spin") { model.activeTipSide = model.tipLimit * 0.6 }
        .accessibilityAction(named: "Centre") { model.activeTipUp = 0; model.activeTipSide = 0 }
        .help("Cue tip: drag to choose follow, draw or side")
        .lockedForStep(!tipOpen)
    }

    /// True when at least one of the picture's two values may change in this step.
    private var tipOpen: Bool { open.contains(.tipUp) || open.contains(.tipSide) }

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

    var body: some View {
        let fraction = model.powerFraction
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Power").font(Theme.label).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(PowerWords.readout(speed: model.activePower, racked: model.racked))
                    .font(Theme.number)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(spacing: 6) {
                // One-finger power without a drag: a tap a step down, a tap a step up (accessibility plan, package 5).
                stepButton(-Self.tapStep, systemImage: "minus", label: "Less power")
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
                    }
                    .contentShape(Rectangle().inset(by: -16))
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        guard open.contains(.power) else { return }
                        model.powerFraction = Double(value.location.x / max(1, geo.size.width))
                    })
                }
                .frame(height: barHeight)
                stepButton(Self.tapStep, systemImage: "plus", label: "More power")
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Power")
        .accessibilityValue(String(localized: "\(String(format: "%.0f", locale: Locale.current, fraction * 100)) percent, \(PowerWords.spoken(speed: model.activePower, racked: model.racked))"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.powerFraction += 0.1
            case .decrement: model.powerFraction -= 0.1
            @unknown default: break
            }
        }
        .help("Strike power. Pull back from the cue ball on the table, or drag here.")
        .disabled(!open.contains(.power))
        .lockedForStep(!open.contains(.power))
    }

    /// A launch speed as a share of the bar, 0 at its soft end, 1 at its hard end (the gauge's own fraction).
    private func powerFraction(_ speed: Double) -> CGFloat {
        let r = model.powerRange
        return CGFloat(min(max((speed - r.lowerBound) / (r.upperBound - r.lowerBound), 0), 1))
    }

    /// The hard end of the bar: a warm red that still reads on glass.
    private static let hot = Color(red: 1.0, green: 0.30, blue: 0.25)

    /// Power change per tap of the step buttons: a twentieth of the range, fine enough to set a soft roll by
    /// tapping and coarse enough to cross the bar in a handful of taps. (VoiceOver's adjust keeps its tenth.)
    private static let tapStep = 0.05

    /// A small round minus or plus button beside the bar. Each tap is one step; nothing repeats while held.
    private func stepButton(_ step: Double, systemImage: String, label: LocalizedStringKey) -> some View {
        Button { model.powerFraction += step } label: {
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
