// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The caption and equation card, and the thin leader line and highlight ring that tie it to the ball it
//          describes. The card is a Liquid Glass panel kept off the action (under the title on a phone held upright,
//          in the side column everywhere else: ShowpieceView decides where). The ring position is the ball's place
//          on the table, read from the recorded timeline and projected to the screen by the 3D view each frame, so no
//          model change was needed. Reads the model; writes nothing to it.
//          Package 4 (0.4.0): CaptionSlot reserves a fixed slot for the card on a phone held upright (sized to the tallest
//          caption by an invisible sizer) so the camera frames the table below it instead of under it; the card is a
//          little tighter (12 point padding) to give the table more room.
// SRP/DRY check: Pass - split out of ShowpieceView. Wording stays in Captions.swift; colours come from Palette.
import BreakdownLensModel
import BreakdownTimeline
import RealityKit
import SwiftUI

// MARK: Card

/// The words of one caption, laid out. Shared by the real card and by the hidden sizer that measures the tallest
/// caption, so the slot reserved for captions is exactly as tall as the tallest card will be.
private struct CaptionContent: View {
    let caption: Caption
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(caption.equation)
                .font(Theme.equation)
                .foregroundStyle(accent)
            Text(caption.title)
                .font(Theme.heading)
            Text(caption.detail)
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CaptionCard: View {
    let caption: Caption
    @Environment(\.palette) private var palette
    /// Inner padding of the glass card; the sizer adds the same so both measure alike.
    static let padding: CGFloat = 12

    var body: some View {
        let accent = palette.color(for: caption.accent)
        CaptionContent(caption: caption, accent: accent)
        .glassCard(cornerRadius: 20, padding: Self.padding)
        .overlay(alignment: .leading) {
            Capsule().fill(accent).frame(width: 3).padding(.vertical, 14).padding(.leading, 5)
        }
        // One spoken sentence per caption; the equation is read last because it is decoration for most listeners.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption.title). \(caption.detail)")
        .accessibilityValue(caption.equation)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// The caption for the moment on screen, or nothing. Reads the clock itself so the rest of the screen does not
/// redraw every frame.
struct CaptionArea: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// In the side column there is always room, so an empty column says what will appear there.
    let showsPlaceholder: Bool
    /// The most height the card may take before it scrolls (large text sizes).
    let maxHeight: CGFloat

    var body: some View {
        Group {
            if model.melt > 0.4, let caption = model.activeCaption() {
                FittingScroll(maxHeight: maxHeight) {
                    CaptionCard(caption: caption)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { leader.card = $0 }
                }
                .transition(.opacity)
                .id(caption.id)
            } else if showsPlaceholder {
                Text("Captions appear here, with the equation behind each moment, as the shot plays.")
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.activeCaption()?.id)
    }
}

/// The caption's place on a phone held upright: a slot under the title row whose height is the height of the TALLEST
/// caption of the shot (measured by laying every caption out, invisibly), capped at `maxHeight` for the largest text
/// sizes, where the card scrolls instead. The slot is the same height whichever caption is showing, so the screen is
/// laid out once and the camera can frame the table in the space below it: the card never lands on the table, and the
/// table never jumps as captions change. The real card sits at the top of the slot.
struct CaptionSlot: View {
    let model: ShowpieceModel
    let leader: LeaderState
    let maxHeight: CGFloat
    /// Height of the tallest caption laid out at the slot's width, from the sizer. Zero until the first layout.
    @State private var tallest: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    /// At the accessibility text sizes the controls already fill most of a phone, so the card gets a smaller cap
    /// (it scrolls) to leave the table some room.
    private var cap: CGFloat { typeSize.isAccessibilitySize ? maxHeight * 0.5 : maxHeight }

    var body: some View {
        ZStack(alignment: .top) {
            // The sizer is what gives the slot its height. A plain frame(maxHeight:) would not do: it expands to the
            // whole offer, so the measured height is applied as an exact frame instead.
            CaptionSizer(captions: model.captions)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tallest = $0 }
            // With the Lens up and nothing to say right now (paused at the end, say) the slot shows a quiet hint instead
            // of a blank hole; on the warm table the slot stays empty because the camera has not reserved it there.
            if model.melt > 0.4 {
                CaptionArea(model: model, leader: leader, showsPlaceholder: true, maxHeight: cap)
            }
        }
        .frame(height: min(tallest, cap), alignment: .top)
    }
}

/// Every caption laid out at the card's width and thrown away: only its height counts. Taking the tallest child
/// makes the ZStack around it exactly as tall as the tallest card. Hidden from the eye and from VoiceOver.
private struct CaptionSizer: View, Equatable {
    let captions: [Caption]

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(captions) { c in
                CaptionContent(caption: c, accent: .clear)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(CaptionCard.padding)
            }
        }
        .hidden()
        .accessibilityHidden(true)
    }
}

// MARK: Leader line and ring

/// The coordinate space shared by the 3D view, the caption card and the leader overlay.
enum StageSpace { static let name = "stage" }

/// Where the highlighted ball is on screen, and where the caption card is, both in StageSpace.
@MainActor
@Observable
final class LeaderState {
    var ring: CGPoint?
    var accent: CaptionAccent = .impact
    var card: CGRect = .zero

    /// Called by the 3D view every frame. Finds the ball the current caption is about, asks the view to project it
    /// to the screen, and keeps the previous point when the move is under half a point (so a still frame costs nothing).
    func refresh(model: ShowpieceModel, project: (SIMD3<Float>) -> CGPoint?) {
        guard model.melt > 0.4, let caption = model.activeCaption(), let world = Self.anchor(of: caption, in: model),
              let point = project(world) else {
            if ring != nil { ring = nil }
            return
        }
        accent = caption.accent
        if let old = ring, hypot(old.x - point.x, old.y - point.y) < 0.5 { return }
        ring = point
    }

    /// The ball a caption is about, in the 3D scene's world space: the ball's own place at the playback time, or the
    /// place of the event itself when that ball is gone (pocketed) or the event has no ball.
    private static func anchor(of caption: Caption, in model: ShowpieceModel) -> SIMD3<Float>? {
        let timeline = model.timeline
        guard timeline.events.indices.contains(caption.id) else { return nil }
        let event = timeline.events[caption.id]
        let frame = TableFrame(timeline.table)
        // For a collision, follow the faster ball: that is the one the caption's words are about.
        let ball = event.balls.max { $0.velocityBefore.length < $1.velocityBefore.length }?.ball
        if event.kind != .pocket, let ball, ball < timeline.ballCount {
            let s = timeline.state(ball: ball, at: model.time)
            if !s.pocketed { return frame.world(s.position, height: frame.ballRadius) }
        }
        return frame.world(event.point, height: frame.ballRadius)
    }
}

/// A ring around the ball and a thin line back to the card. Decoration only: hidden from VoiceOver and never takes touches.
struct CaptionLeader: View {
    let leader: LeaderState
    @Environment(\.palette) private var palette

    private let ringRadius: CGFloat = 20

    var body: some View {
        Canvas { ctx, _ in
            guard let ring = leader.ring else { return }
            let color = palette.color(for: leader.accent)
            let card = leader.card
            // A ring drawn over the card would strike through its words. When the ball is hidden behind the card
            // (the phone layout puts the card across the top of the table) there is nothing useful to draw.
            if !card.isEmpty, card.insetBy(dx: -ringRadius, dy: -ringRadius).contains(ring) { return }
            // Line from the nearest point on the card's edge to the ring's edge, unless the ball sits under the card.
            if !card.isEmpty, !card.contains(ring) {
                let from = CGPoint(x: min(max(ring.x, card.minX), card.maxX), y: min(max(ring.y, card.minY), card.maxY))
                let dx = ring.x - from.x, dy = ring.y - from.y
                let len = max(0.001, hypot(dx, dy))
                if len > ringRadius {
                    let end = CGPoint(x: ring.x - dx / len * ringRadius, y: ring.y - dy / len * ringRadius)
                    var line = Path()
                    line.move(to: from); line.addLine(to: end)
                    ctx.stroke(line, with: .color(color.opacity(0.6)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            }
            let rect = CGRect(x: ring.x - ringRadius, y: ring.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2)
            ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
