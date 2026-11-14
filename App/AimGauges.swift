// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
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
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 52

    /// The dot may travel to 70% of the ball's radius at full tip offset; the ring drawn there is the miscue limit.
    private let reach: CGFloat = 0.7

    var body: some View {
        // Grows with text size for easy touching but stops at 72 points: past that it would crowd out the table.
        let size = min(max(44, side), 72)
        let radius = size / 2
        let limit = radius * reach
        let up = model.activeTipUp / ShowpieceModel.tipLimit
        let across = model.activeTipSide / ShowpieceModel.tipLimit
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
            // Touch position relative to the middle, as a fraction of the reachable disc, then clamped to the disc.
            var x = Double((value.location.x - radius) / limit)
            var y = Double(-(value.location.y - radius) / limit)
            let len = (x * x + y * y).squareRoot()
            if len > 1 { x /= len; y /= len }
            // A tiny region around the middle snaps to exactly centre so "centre" is easy to hit.
            if len < 0.12 { x = 0; y = 0 }
            model.activeTipSide = x * ShowpieceModel.tipLimit
            model.activeTipUp = y * ShowpieceModel.tipLimit
        })
        .accessibilityElement()
        .accessibilityLabel("Cue tip position")
        .accessibilityValue(Self.spoken(up: model.activeTipUp, side: model.activeTipSide))
        .accessibilityHint("Drag on the ball to place the tip. Or use the actions.")
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityAction(named: "Follow") { model.activeTipUp = ShowpieceModel.tipLimit * 0.6 }
        .accessibilityAction(named: "Draw") { model.activeTipUp = -ShowpieceModel.tipLimit * 0.6 }
        .accessibilityAction(named: "Left spin") { model.activeTipSide = -ShowpieceModel.tipLimit * 0.6 }
        .accessibilityAction(named: "Right spin") { model.activeTipSide = ShowpieceModel.tipLimit * 0.6 }
        .accessibilityAction(named: "Centre") { model.activeTipUp = 0; model.activeTipSide = 0 }
        .help("Cue tip: drag to choose follow, draw or side")
    }

    /// "follow, left" and so on; "centre" when the tip is in the middle.
    static func spoken(up: Double, side: Double) -> String {
        let v = up < -0.002 ? "draw" : (up > 0.002 ? "follow" : nil)
        let h = side < -0.002 ? "left" : (side > 0.002 ? "right" : nil)
        switch (v, h) {
        case (nil, nil): return "centre"
        case let (v?, nil): return v
        case let (nil, h?): return h
        case let (v?, h?): return "\(v), \(h)"
        }
    }
}

// MARK: Power

struct PowerGauge: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 12

    var body: some View {
        let fraction = model.powerFraction
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Power").font(Theme.label).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(String(format: "%.1f m/s", model.activePower))
                    .font(Theme.number)
                    .foregroundStyle(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.track)
                    // The gradient spans the whole bar and a capsule-shaped mask reveals the part below the power
                    // level, so the fill gets warmer as power rises instead of squashing the colours into the fill.
                    Capsule()
                        .fill(LinearGradient(colors: [palette.accent, palette.slide, Self.hot], startPoint: .leading, endPoint: .trailing))
                        .mask(alignment: .leading) { Capsule().frame(width: max(barHeight, geo.size.width * fraction)) }
                }
                .contentShape(Rectangle().inset(by: -16))
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    model.powerFraction = Double(value.location.x / max(1, geo.size.width))
                })
            }
            .frame(height: barHeight)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Power")
        .accessibilityValue(String(format: "%.0f percent, %.1f metres per second", fraction * 100, model.activePower))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.powerFraction += 0.1
            case .decrement: model.powerFraction -= 0.1
            @unknown default: break
            }
        }
        .help("Strike power. Pull back from the cue ball on the table, or drag here.")
    }

    /// The hard end of the bar: a warm red that still reads on glass.
    private static let hot = Color(red: 1.0, green: 0.30, blue: 0.25)
}
