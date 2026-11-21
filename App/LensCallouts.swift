// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The Physics Lens, explained once. The first time the Lens is on screen with the player in charge (the
//          opening has handed over, the menu is shut, the shot is in the player's hands), three short callouts appear
//          one at a time, each pointing at the thing it names:
//            1. the orange path: a ball skidding over the cloth,
//            2. the blue path: a ball rolling,
//            3. the bar: drag it to move through the shot in time.
//          Next moves on, Got it on the last one finishes; finishing (or closing early) is remembered under
//          LensCallouts.seenKey, and Options can clear it ("Show the Lens tips again", beside the aiming tips button).
//          LensCalloutLayer - over the table on every screen but the folding phone's open one. Callouts 1 and 2 draw a
//            thin pointer from the bubble to a stretch of path of their colour that the Lens is showing right now
//            (found in the recorded timeline, the newest long enough stretch, so the brightest part of the trail);
//            callout 3 sits just above the measured control strip with an arrow down to the bar, or by the side
//            column with an arrow toward it where the controls live there.
//          LensCalloutCard - the same three steps as a card in the folding phone's panel, where nothing may cover the
//            table; the bar is in that panel, below the card.
// SRP/DRY check: Pass - checked LensLayer (draws the trails; its trailHold and trailFadeEnd decide which stretch is
//          bright, read here, not copied), LensLegendChip (the colour key; these callouts teach it once and then the
//          chip carries on), ShotPanel's one-time aiming hint (the pattern for "shown once, remembered, Options can bring
//          it back") and GhostOverlay (the same projection through AimProjector).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

enum LensCallouts {
    /// Stored true once the three callouts have been seen; Options sets it back to false.
    static let seenKey = "lensTipsSeen"
    static let count = 3

    /// The Lens is on screen and the player is in charge: not under the menu, not while the opening or the player's
    /// first break tells its story, and not mid-way through the opening's own stages.
    @MainActor static func due(_ model: ShowpieceModel) -> Bool {
        model.lensOn && !model.menuOpen && model.stage == .explore && model.openingStage == .none
    }

    static func text(step: Int) -> String {
        switch step {
        case 0: return String(localized: "Orange path: the ball is skidding. It slides over the cloth and its spin has not caught up yet.")
        case 1: return String(localized: "Blue path: the ball is rolling. The cloth has matched its spin to its speed.")
        default: return String(localized: "Drag the bar to move through the shot in time, forwards or back.")
        }
    }

    static func symbol(step: Int) -> String {
        switch step {
        case 0, 1: return "scribble.variable"
        default: return "slider.horizontal.below.rectangle"
        }
    }
}

// MARK: Over the table

struct LensCalloutLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @AppStorage(LensCallouts.seenKey) private var seen = false
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var cameraBox = AimProjector.CameraBox()
    /// Where the bubble is, in this layer's own space, so the pointer can leave from it.
    @State private var bubbleFrame: CGRect = .zero

    private static let space = "lensCallouts"

    var body: some View {
        if !seen && !inlinePages && LensCallouts.due(model) {
            TimelineView(.animation) { _ in
                GeometryReader { geo in
                    let origin = geo.frame(in: .named(StageSpace.name)).origin
                    ZStack {
                        Canvas { ctx, size in drawPointer(&ctx, size: size) }
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                        placedBubble(size: geo.size, origin: origin)
                    }
                }
            }
            .coordinateSpace(name: Self.space)
            .ignoresSafeArea()
            .transition(.opacity)
            .animation(reduceMotion ? nil : .snappy, value: step)
        }
    }

    // MARK: The bubble

    /// The bubble below the title row for the two paths; just above the controls (or beside them) for the bar.
    @ViewBuilder
    private func placedBubble(size: CGSize, origin: CGPoint) -> some View {
        let chrome = bridge.chrome
        let bar = step == 2
        // StageSpace edges turned into this layer's own coordinates (the layer runs under the safe areas).
        let top = CGFloat(chrome.headerBottom ?? chrome.safe.top + 44) - origin.y + 12
        let controlsTop = chrome.controlsTop.map { CGFloat($0) - origin.y }
        // The bar: just above the control strip; where the controls live in the side column, near the bottom corner
        // on the column's side.
        let bottom = controlsTop.map { size.height - $0 + 12 } ?? CGFloat(chrome.safe.bottom) + 24
        let arrow: LensCalloutBubble.Arrow? = bar ? (controlsTop == nil ? .side : .down) : nil
        LensCalloutBubble(step: $step, seen: $seen, arrow: arrow)
            .frame(maxWidth: 420)
            .padding(.horizontal, 16)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { bubbleFrame = $0 }
            .padding(.top, bar ? 0 : max(0, top))
            .padding(.bottom, bar ? max(12, bottom) : 0)
            .frame(width: size.width, height: size.height,
                   alignment: bar ? (controlsTop == nil ? .bottomTrailing : .bottom) : .top)
    }

    // MARK: The pointer

    private func drawPointer(_ ctx: inout GraphicsContext, size: CGSize) {
        guard step < 2, bubbleFrame.width > 0,
              let point = target(phase: step == 0 ? .sliding : .rolling),
              let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table)),
              let end = proj.screen(point, height: 0.001)
        else { return }
        let colour = step == 0 ? palette.slide : palette.accent
        // From the bubble's nearest edge, so the line never crosses its own words.
        let start = CGPoint(x: min(max(end.x, bubbleFrame.minX + 24), bubbleFrame.maxX - 24),
                            y: end.y > bubbleFrame.midY ? bubbleFrame.maxY : bubbleFrame.minY)
        var line = Path()
        line.move(to: start)
        line.addLine(to: end)
        ctx.stroke(line, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        ctx.stroke(line, with: .color(colour), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        let r: CGFloat = 9
        let ring = Path(ellipseIn: CGRect(x: end.x - r, y: end.y - r, width: r * 2, height: r * 2))
        ctx.stroke(ring, with: .color(colour), lineWidth: 2.5)
    }

    /// A point on a stretch of path in the given phase that the Lens is drawing brightly at this moment: among the
    /// stretches already reached by the clock, the longest one still inside the trail's fade (LensLayer.trailFadeEnd),
    /// else the longest of all. The point is a little behind the newest end of the stretch, where it is brightest.
    /// Stretches shorter than two ball widths are passed over: a pointer at a dot teaches nothing.
    private func target(phase: MotionPhase) -> Vec2? {
        let tl = model.timeline
        let now = model.time
        let minimum = tl.table.ballRadius * 4
        var fresh: (point: Vec2, length: Double)?
        var any: (point: Vec2, length: Double)?
        for ball in tl.segments.indices where ball < tl.pocketTime.count {
            for seg in tl.segments[ball] where seg.phase == phase && seg.t0 < now {
                let end = min(seg.t1, now, tl.pocketTime[ball] ?? .infinity)
                guard end > seg.t0 else { continue }
                let length = (tl.state(ball: ball, at: end).position - tl.state(ball: ball, at: seg.t0).position).length
                guard length >= minimum else { continue }
                let point = tl.state(ball: ball, at: end - min(LensLayer.trailHold * 0.25, (end - seg.t0) / 2)).position
                if length > (any?.length ?? 0) { any = (point, length) }
                if now - end <= LensLayer.trailFadeEnd, length > (fresh?.length ?? 0) { fresh = (point, length) }
            }
        }
        return (fresh ?? any)?.point
    }
}

// MARK: In the folding phone's panel

struct LensCalloutCard: View {
    let model: ShowpieceModel
    @AppStorage(LensCallouts.seenKey) private var seen = false
    @Environment(\.inlinePages) private var inlinePages
    @State private var step = 0

    var body: some View {
        if !seen && inlinePages && LensCallouts.due(model) {
            // The bar is in this panel, below the card.
            LensCalloutBubble(step: $step, seen: $seen, arrow: step == 2 ? .down : nil)
                .transition(.opacity)
        }
    }
}

// MARK: The bubble itself

/// One callout: its symbol and sentence, which of the three it is, an arrow toward the bar on the last, Not now, and
/// Next (Got it on the last). Shared by the layer over the table and the panel card.
struct LensCalloutBubble: View {
    enum Arrow { case down, side }
    @Binding var step: Int
    @Binding var seen: Bool
    let arrow: Arrow?
    @Environment(\.palette) private var palette

    private var last: Bool { step + 1 >= LensCallouts.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: LensCallouts.symbol(step: step))
                    .font(.title3)
                    .foregroundStyle(step == 0 ? palette.slide : palette.accent)
                    .accessibilityHidden(true)
                Text(LensCallouts.text(step: step))
                    .font(Theme.body)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                if let arrow {
                    // Points at the bar: down to the strip under the table, or toward the side column.
                    Image(systemName: arrow == .down ? "arrow.down" : "arrow.forward")
                        .font(.headline)
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                }
                Text(String(localized: "\(step + 1) of \(LensCallouts.count)"))
                    .font(Theme.label)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button(String(localized: "Not now")) { seen = true; step = 0 }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                Button(last ? String(localized: "Got it") : String(localized: "Next")) {
                    if last { seen = true; step = 0 } else { step += 1 }
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .controlSize(.small)
            }
        }
        .glassCard(cornerRadius: 20, padding: 12)
        .accessibilityElement(children: .contain)
    }
}
