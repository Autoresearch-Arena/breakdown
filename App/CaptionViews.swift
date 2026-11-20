// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (follows the Options: no card at all with explanations off, the
//          equation only with Show the maths on; the slot under the title takes no room unless a card can show, so
//          the warm table gets the whole screen).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the table fills the screen: the caption slot, its invisible sizer and
//          the "Explanations appear here" placeholder are gone. On a phone held upright the card now floats as a compact
//          glass card over the table's top edge, takes no room from the table, and is simply absent when there is
//          nothing to say; its glass carries a dark tint so it reads over the Lens grid. New LensLegendChip: the Lens
//          colour key as a small glass chip for the title row, with Dynamic Type and one spoken sentence.)
// PURPOSE: The caption and equation card, the Lens colour key chip, and the thin leader line and highlight ring that tie
//          the card to the ball it describes. The card is a Liquid Glass panel (floating over the top edge of the table
//          on a phone held upright, in the side column everywhere else: ShowpieceView decides where). The ring position is the ball's place
//          on the table, read from the recorded timeline and projected to the screen by the 3D view each frame, so no
//          model change was needed. Reads the model; writes nothing to it.
// SRP/DRY check: Pass - split out of ShowpieceView. Wording stays in Captions.swift; colours come from Palette.
import BreakdownLensModel
import BreakdownTimeline
import RealityKit
import SwiftUI

// MARK: Card

/// The words of one caption, laid out.
private struct CaptionContent: View {
    let caption: Caption
    var accent: Color
    @AppStorage(GameSettings.mathsKey) private var maths = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if maths {
                Text(caption.equation)
                    .font(Theme.equation)
                    .foregroundStyle(accent)
            }
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
    @AppStorage(GameSettings.mathsKey) private var maths = false
    /// Inner padding of the glass card: compact, because on a phone it floats over the table's top edge.
    static let padding: CGFloat = 10

    var body: some View {
        let accent = palette.color(for: caption.accent)
        CaptionContent(caption: caption, accent: accent)
            .padding(.leading, 4)
            .padding(Self.padding)
            // Liquid Glass tinted toward the room colour: over the bright Lens grid and trails plain clear glass lets
            // the lines show through the words, so the tint keeps the text readable. Reduce Transparency still turns
            // it solid (the system does that for every glass surface).
            .glassEffect(.regular.tint(palette.ground.opacity(0.55)), in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .leading) {
                Capsule().fill(accent).frame(width: 3).padding(.vertical, 12).padding(.leading, 5)
            }
        // One spoken sentence per caption; the equation is read last because it is decoration for most listeners.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption.title). \(caption.detail)")
        .accessibilityValue(maths ? caption.equation : "")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// The caption for the moment on screen, or nothing at all: when there is nothing to say no card and no placeholder
/// shows, and on a phone the table underneath is simply uncovered. Reads the clock itself so the rest of the screen
/// does not redraw every frame. Never measured for framing: the card floats over the table and never shrinks it.
struct CaptionArea: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// The most height the card may take before it scrolls (large text sizes).
    let maxHeight: CGFloat

    @AppStorage(GameSettings.explanationsKey) private var explanations = true

    var body: some View {
        let showing = explanations && !model.menuOpen && model.melt > 0.4 && model.activeCaption() != nil
        // A ZStack rather than a Group so the view (and the onChange below) exists even when no card shows.
        ZStack(alignment: .top) {
            if showing, let caption = model.activeCaption() {
                FittingScroll(maxHeight: maxHeight) {
                    CaptionCard(caption: caption)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { leader.card = $0 }
                }
                .transition(.opacity)
                .id(caption.id)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.activeCaption()?.id)
        // With no card on screen the leader must not keep the last card's place: CaptionLeader hides the ring for any
        // ball inside that rectangle, so a stale one (explanations switched off, say) would swallow rings near the top.
        .onChange(of: showing) { _, now in if !now { leader.card = .zero } }
    }
}

// MARK: Lens colour key

/// What the Lens colours mean, as a small glass chip for the title row: an amber line for a ball sliding, a cyan line
/// for a ball rolling. It replaces the baked 3D legend that used to take a band of height off the table. Text follows
/// Dynamic Type; when one row does not fit beside the back button the two entries stack. Spoken as one sentence.
struct LensLegendChip: View {
    @Environment(\.palette) private var palette

    private func entry(_ name: LocalizedStringKey, _ color: Color) -> some View {
        HStack(spacing: 6) {
            // A short glowing line, like the trail it stands for.
            Capsule().fill(color).frame(width: 16, height: 3).shadow(color: color.opacity(0.8), radius: 3)
            Text(name).font(Theme.label).lineLimit(1)
        }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { entry("Sliding", palette.slide); entry("Rolling", palette.accent) }
            VStack(alignment: .leading, spacing: 4) { entry("Sliding", palette.slide); entry("Rolling", palette.accent) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(palette.ground.opacity(0.4)), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lens colours: amber lines show a ball sliding, cyan lines a ball rolling")
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
        guard model.melt > 0.4, !model.menuOpen, let caption = model.activeCaption(), let world = Self.anchor(of: caption, in: model),
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
