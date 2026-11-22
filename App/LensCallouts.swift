// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 44
//          and 53: the tips use the Lens key's own words, amber and cyan, and with Differentiate Without Colour on
//          "dashed amber" and "solid cyan", matching the trails and LensLegendChip; they no longer appear over a finished
//          break or on a lesson's key moment, but on the first guided hold of a Lens replay the player started
//          (model.lensReplayStartedByPlayer and model.holding), and while they show the beat holds
//          (model.holdForTips) and the caption card, strip and ring stand back (CaptionViews reads the same flag).)
// PURPOSE: The Physics Lens, explained once. The first time the player starts a Lens replay of their own (Replay with
//          the Lens, Watch it in the Lens) and the replay stops on its first beat, three short callouts appear one at a
//          time, each pointing at the thing it names:
//            1. the amber path (dashed amber with Differentiate Without Colour): a ball sliding over the cloth,
//            2. the cyan path (solid cyan): a ball rolling,
//            3. the bar: drag it to move through the shot in time.
//          The beat holds while they are up (model.holdForTips), so the trails they point at stay fresh. Next moves on,
//          Got it on the last one finishes; finishing (or closing early) is remembered under LensCallouts.seenKey, and
//          Options can clear it ("Show the Lens tips again", beside the aiming tips button).
//          Other screens' cards that should stand back while the tips show read model.holdForTips (the trick-shot and
//          lesson cards belong to other files; the Behind the 8-Ball card does it in EightBallViews).
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

    /// The Lens is up and nothing covers it, outside the opening's own story. Once the tips have started they stay
    /// while this holds, even if the player scrubs off the beat, so a half-read tip never vanishes under a finger.
    @MainActor static func visible(_ model: ShowpieceModel) -> Bool {
        model.lensOn && !model.menuOpen && model.stage == .explore && model.openingStage == .none
    }

    /// When the tips start: the first guided hold of a Lens replay the player started themselves. Not the opening's
    /// replay, not a lesson's or trick shot's own replay (their cards are on screen), and not a finished break whose
    /// trails have faded: a hold is always mid-replay, on a beat, with its trails fresh.
    @MainActor static func due(_ model: ShowpieceModel) -> Bool {
        visible(model) && model.lensReplayStartedByPlayer && model.holding
    }

    /// The tip's words. `withoutColour` (Differentiate Without Colour) names each line's shape as well, the way the
    /// trails and the Lens key draw it then: sliding dashed, rolling solid. The colour words are the key's own, amber
    /// and cyan.
    static func text(step: Int, withoutColour: Bool) -> String {
        switch (step, withoutColour) {
        case (0, false): return String(localized: "Amber path: the ball is sliding. Its spin has not caught up with its speed yet, so it skids over the cloth.")
        case (0, true): return String(localized: "Dashed amber path: the ball is sliding. Its spin has not caught up with its speed yet, so it skids over the cloth.")
        case (1, false): return String(localized: "Cyan path: the ball is rolling. The cloth has matched its spin to its speed.")
        case (1, true): return String(localized: "Solid cyan path: the ball is rolling. The cloth has matched its spin to its speed.")
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
    /// The tips have begun on a hold; they stay up until finished, closed, or the Lens goes away.
    @State private var started = false
    @State private var cameraBox = AimProjector.CameraBox()
    /// Where the bubble is, in this layer's own space, so the pointer can leave from it.
    @State private var bubbleFrame: CGRect = .zero

    private static let space = "lensCallouts"

    /// This layer's tips are on screen now (on the folding phone's open screen the panel's card shows them instead).
    private var showing: Bool {
        !seen && !inlinePages && LensCallouts.visible(model) && (started || LensCallouts.due(model))
    }

    var body: some View {
        // A ZStack that always exists, so the hold flag is kept in step even when nothing is drawn.
        ZStack {
            if showing {
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
        .lensTipsHold(model: model, showing: showing, owns: !inlinePages, started: $started)
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
    @State private var started = false

    private var showing: Bool {
        !seen && inlinePages && LensCallouts.visible(model) && (started || LensCallouts.due(model))
    }

    var body: some View {
        ZStack {
            if showing {
                // The bar is in this panel, below the card.
                LensCalloutBubble(step: $step, seen: $seen, arrow: step == 2 ? .down : nil)
                    .transition(.opacity)
            }
        }
        .lensTipsHold(model: model, showing: showing, owns: inlinePages, started: $started)
    }
}

// MARK: Holding the beat

private extension View {
    /// Keeps the model's hold in step with the tips: while they show, the beat they appeared on does not run out
    /// (model.holdForTips) and other cards stand back; when they finish, close or the Lens goes away, the hold runs on.
    /// `owns`: only the copy that can show on this screen writes the flag (the layer over the table, or the card in the
    /// folding phone's panel), so the hidden copy never clears what the shown one set.
    func lensTipsHold(model: ShowpieceModel, showing: Bool, owns: Bool, started: Binding<Bool>) -> some View {
        self
            .onChange(of: showing, initial: true) { _, now in
                if now { started.wrappedValue = true }
                if owns, model.holdForTips != now { model.holdForTips = now }
            }
            // Leaving the Lens (or the menu covering it) ends this round: next time the tips wait for a new hold.
            .onChange(of: LensCallouts.visible(model)) { _, now in
                if !now { started.wrappedValue = false }
            }
            .onDisappear {
                if owns, model.holdForTips { model.holdForTips = false }
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
    /// Names each path's shape as well as its colour when colour alone may not tell them apart.
    @Environment(\.accessibilityDifferentiateWithoutColor) private var withoutColour

    private var last: Bool { step + 1 >= LensCallouts.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: LensCallouts.symbol(step: step))
                    .font(.title3)
                    .foregroundStyle(step == 0 ? palette.slide : palette.accent)
                    .accessibilityHidden(true)
                Text(LensCallouts.text(step: step, withoutColour: withoutColour))
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
