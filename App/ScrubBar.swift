// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The scrub bar: a custom control (the impact ticks are the point of it) that behaves like a standard one.
//          It has a 44 point tall hit area, a thumb that grows under the pointer, a light haptic tick each time the
//          playhead crosses a recorded impact while you drag, and full VoiceOver support (a name, a spoken value,
//          swipe up and down to step, and "next impact" and "previous impact" actions). Reads the model's clock and
//          the recorded events; the only thing it writes is ShowpieceModel.scrub(to:).
// SRP/DRY check: Pass - split out of ShowpieceView; tick colours come from Palette (the same ones the captions use).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct ScrubBar: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var dragging = false
    /// Counts impacts crossed during a drag; the haptic fires whenever it changes.
    @State private var crossings = 0

    private let hitHeight: CGFloat = 44   // Apple's minimum touch target
    private let railHeight: CGFloat = 6
    private let thumb: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            track(width: max(1, geo.size.width))
        }
        .frame(height: hitHeight)
        .sensoryFeedback(.impact(weight: .light), trigger: crossings)
        // VoiceOver: one adjustable element instead of a canvas it cannot read.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback position")
        .accessibilityValue(spokenValue)
        .accessibilityAdjustableAction { direction in
            let step = model.duration / 20
            switch direction {
            case .increment: model.scrub(to: model.time + step)
            case .decrement: model.scrub(to: model.time - step)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Next impact") { if let t = impact(after: model.time) { model.scrub(to: t) } }
        .accessibilityAction(named: "Previous impact") { if let t = impact(before: model.time) { model.scrub(to: t) } }
    }


    /// The rail, the ticks, the filled part and the thumb, with the drag gesture on top.
    private func track(width w: CGFloat) -> some View {
        let d = max(model.duration, 0.001)
        let x: CGFloat = w * CGFloat(min(1, max(0, model.time / d)))
        let thumbScale: CGFloat = dragging ? 1.25 : (hovering ? 1.15 : 1)
        let thumbX: CGFloat = min(max(0, x - thumb / 2), w - thumb)
        return ZStack(alignment: .leading) {
            Capsule().fill(palette.track).frame(height: railHeight)
            ticks(duration: d)
            Capsule().fill(palette.accent).frame(width: max(railHeight, x), height: railHeight)
            Circle()
                .fill(.white)
                .frame(width: thumb, height: thumb)
                .shadow(color: palette.accent.opacity(0.8), radius: 4)
                .scaleEffect(thumbScale)
                .animation(reduceMotion ? nil : .snappy(duration: 0.15), value: thumbScale)
                .offset(x: thumbX)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        #if os(macOS)
        .pointerStyle(dragging ? .grabActive : .grabIdle)
        #endif
        .gesture(drag(width: w, duration: d))
    }

    /// Dragging anywhere on the bar moves the playhead there; each recorded impact crossed ticks the haptic.
    private func drag(width w: CGFloat, duration d: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                dragging = true
                let fraction: Double = Double(min(max(0, g.location.x), w) / w)
                let target: Double = fraction * d
                if impactsBetween(model.time, target) { crossings += 1 }
                model.scrub(to: target)
            }
            .onEnded { _ in dragging = false }
    }

    // MARK: Ticks

    private func ticks(duration d: Double) -> some View {
        Canvas { ctx, size in
            for e in model.timeline.events {
                var color: Color
                var h: CGFloat = 8
                switch e.kind {
                case .ballBall: color = palette.impact
                case .cushion: color = palette.cushion
                case .pocket: color = palette.pocket; h = 14
                case .cueStrike: color = palette.strike; h = 14
                case .phaseTransition: continue
                }
                let x = size.width * (e.time / d)
                let rect = CGRect(x: x - 0.75, y: (size.height - h) / 2, width: 1.5, height: h)
                ctx.fill(Path(rect), with: .color(color.opacity(0.85)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Impact lookups (also used by VoiceOver)

    private var impactTimes: [Double] {
        model.timeline.events.compactMap { $0.kind == .phaseTransition ? nil : $0.time }
    }

    private func impactsBetween(_ a: Double, _ b: Double) -> Bool {
        let lo = min(a, b), hi = max(a, b)
        return impactTimes.contains { $0 > lo && $0 <= hi }
    }

    private func impact(after t: Double) -> Double? { impactTimes.first { $0 > t + 0.001 } }
    private func impact(before t: Double) -> Double? { impactTimes.last { $0 < t - 0.001 } }

    private var spokenValue: String {
        String(format: "%.1f of %.1f seconds", model.time, model.duration)
    }
}

/// The elapsed and total time next to the scrub bar, in digits that do not jitter.
struct TimeReadout: View {
    let model: ShowpieceModel

    var body: some View {
        Text(String(format: "%.1f / %.1f s", model.time, model.duration))
            .font(Theme.number)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
            .accessibilityHidden(true)   // the scrub bar already speaks it
    }
}
