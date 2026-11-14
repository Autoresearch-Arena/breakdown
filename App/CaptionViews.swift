// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The caption and equation card, and the thin leader line and highlight ring that tie it to the ball it
//          describes. The card is a Liquid Glass panel kept off the action (under the title on a phone held upright,
//          in the side column everywhere else: ShowpieceView decides where). The ring position is the ball's place
//          on the table, read from the recorded timeline and projected to the screen by the 3D view each frame, so no
//          model change was needed. Reads the model; writes nothing to it.
// SRP/DRY check: Pass - split out of ShowpieceView. Wording stays in Captions.swift; colours come from Palette.
import BreakdownLensModel
import BreakdownTimeline
import RealityKit
import SwiftUI

// MARK: Card

struct CaptionCard: View {
    let caption: Caption
    @Environment(\.palette) private var palette

    var body: some View {
        let accent = palette.color(for: caption.accent)
        VStack(alignment: .leading, spacing: 4) {
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
        .glassCard(cornerRadius: 20, padding: 14)
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
