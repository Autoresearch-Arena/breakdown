// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// PURPOSE: The scrub bar: a custom control (the impact ticks are the point of it) that behaves like a standard one.
//          It has a 44 point tall hit area, a thumb that grows under the pointer, a light haptic tick each time the
//          playhead crosses a recorded impact while you drag, and full VoiceOver support (a name, a spoken value,
//          swipe up and down to step, and "next impact" and "previous impact" actions). Reads the model's clock and
//          the recorded events; the only thing it writes is ShowpieceModel.scrub(to:).
// Edited: Claude Opus 5.5 High, 21-November-2026 (a pin knocked down on another table ticks like an impact).
// Edited: Claude Opus 5.5 High, 21-November-2026 (generation-two kinds: a jam brought to rest ticks like an impact, a
//          ball skipping over a hole gets a short tick in the pocket colour).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream: while a what-if shows, a violet diamond marks
//          where the two futures part, with a VoiceOver action "Where they part"; the impact tick's haptic respects
//          Vibration off; the Mac's time readout writes its decimals the way the player's language does.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif-review: Next impact, Previous impact and Where they part
//          are one list of named actions instead of two mechanisms side by side; same names, same jumps.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream what-if, bug 30 of plans/22-Nov-2026-phone-bug-hunt.md:
//          the parting diamond draws over the playhead, so it stays visible when Where they part lands on it.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, foundation: phoneStyle for the upright phone's
//          strip (PhoneStrip): unplayed rail white at 25 per cent, played rail white, no accent glow on the knob, and a
//          2-point white tick at each explained moment (the captions) instead of the coloured impact ticks, because on
//          the phone cyan and magenta mean only rolling and sliding. Touch area, haptics and VoiceOver are unchanged.)
// SRP/DRY check: Pass - split out of ShowpieceView; tick colours come from Palette (the same ones the captions use).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct ScrubBar: View {
    let model: ShowpieceModel
    /// The upright phone's look (PhoneStrip): white rail, white knob, a tick at each explained moment. Off everywhere
    /// else, which keeps the coloured impact ticks and the accent fill.
    var phoneStyle = false
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
        // Vibration off silences the tick (GameSettings.hapticsOn); nil plays nothing.
        .sensoryFeedback(trigger: crossings) { _, _ in GameSettings.hapticsOn ? .impact(weight: .light) : nil }
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
        // The named actions in one list, so the what-if's conditional one sits beside the impact jumps rather than in a
        // second mechanism next to them.
        .accessibilityActions {
            Button("Next impact") { if let t = impact(after: model.time) { model.scrub(to: t) } }
            Button("Previous impact") { if let t = impact(before: model.time) { model.scrub(to: t) } }
            // The what-if's parting point (0.7.5): the same jump as the card's Where they part.
            if partingTime != nil {
                Button(String(localized: "Where they part")) { model.whatIf.jumpToParting() }
            }
        }
    }

    /// Where the what-if's two futures part, while one shows (the fork's marker); nil otherwise.
    private var partingTime: Double? {
        guard model.whatIf.isShowing else { return nil }
        return model.whatIf.result?.fork.marker?.time
    }


    /// The rail, the ticks, the filled part and the thumb, with the drag gesture on top.
    private func track(width w: CGFloat) -> some View {
        let d = max(model.duration, 0.001)
        let x: CGFloat = w * CGFloat(min(1, max(0, model.time / d)))
        let thumbScale: CGFloat = dragging ? 1.25 : (hovering ? 1.15 : 1)
        let thumbX: CGFloat = min(max(0, x - thumb / 2), w - thumb)
        return ZStack(alignment: .leading) {
            Capsule().fill(phoneStyle ? Color.white.opacity(0.25) : palette.track).frame(height: railHeight)
            if !phoneStyle { ticks(duration: d) }
            Capsule().fill(phoneStyle ? Color.white : palette.accent).frame(width: max(railHeight, x), height: railHeight)
            // The phone's moment ticks go over the played rail, which is white too; their dark edge keeps them apart.
            if phoneStyle { momentTicks(duration: d) }
            Circle()
                .fill(.white)
                .frame(width: thumb, height: thumb)
                .shadow(color: phoneStyle ? Color.black.opacity(0.5) : palette.accent.opacity(0.8), radius: 4)
                .scaleEffect(thumbScale)
                .animation(reduceMotion ? nil : .snappy(duration: 0.15), value: thumbScale)
                .offset(x: thumbX)
            // Over the playhead (0.7.6, bug 30): Where they part puts the playhead exactly on the diamond, and drawn
            // under it the mark the player jumped to vanished the moment they got there.
            partingMark(width: w, duration: d)
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
                case .ballBall, .pinDown, .settledInContact: color = palette.impact
                case .cushion: color = palette.cushion
                case .pocket: color = palette.pocket; h = 14
                case .rimSkip: color = palette.pocket       // a near miss at a hole: the pocket colour, short tick
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

    /// The phone's ticks: one 2-point mark at each explained moment (each caption's time), white with a dark edge so
    /// it reads on the played and the unplayed rail alike.
    private func momentTicks(duration d: Double) -> some View {
        Canvas { ctx, size in
            let h: CGFloat = 12
            for c in model.captions {
                let x = size.width * CGFloat(min(1, max(0, c.time / d)))
                let rect = CGRect(x: x - 1, y: (size.height - h) / 2, width: 2, height: h)
                ctx.fill(Path(rect.insetBy(dx: -0.5, dy: -0.5)), with: .color(.black.opacity(0.45)))
                ctx.fill(Path(rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The what-if's diamond on the bar at the parting time, in the what-if violet with a dark edge (0.7.5).
    @ViewBuilder
    private func partingMark(width w: CGFloat, duration d: Double) -> some View {
        if let t = partingTime {
            let size: CGFloat = 10
            let x = w * CGFloat(min(1, max(0, t / d)))
            Rectangle()
                .fill(palette.whatIf)
                .frame(width: size, height: size)
                .overlay(Rectangle().stroke(.black.opacity(0.55), lineWidth: 1))
                .rotationEffect(.degrees(45))
                .offset(x: min(max(0, x - size / 2), w - size))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
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
        String(localized: "\(String(format: "%.1f", locale: Locale.current, model.time)) of \(String(format: "%.1f", locale: Locale.current, model.duration)) seconds")
    }
}

/// The elapsed and total time next to the scrub bar, in digits that do not jitter.
struct TimeReadout: View {
    let model: ShowpieceModel

    var body: some View {
        // Formatted for the player's language, so the decimal mark is theirs (0.7.5).
        Text(verbatim: "\(Self.seconds(model.time)) / \(Self.seconds(model.duration)) s")
            .font(Theme.number)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
            .accessibilityHidden(true)   // the scrub bar already speaks it
    }

    private static func seconds(_ t: Double) -> String { t.formatted(.number.precision(.fractionLength(1))) }
}
