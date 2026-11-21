// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the strip under the table hugs its words: the room stays reserved
//          for the camera, title and three lines, but the glass card is only as tall as the caption and sits on the
//          controls; nothing is drawn before the first caption; a longer one grows upward instead of moving the table).
// Edited: Claude Opus 5.5 High, 21-November-2026 (all caption glass is plain system Liquid Glass: no dark tint on the
//          card or the Lens key, only a faint colour tint on the on-table label, no drawn outline).
// Edited: Claude Opus 5.5 High, 20-November-2026 (follows the Options: no card at all with explanations off, the
//          equation only with Show the maths on; the slot under the title takes no room unless a card can show, so
//          the warm table gets the whole screen).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the table fills the screen: the caption slot, its invisible sizer and
//          the "Explanations appear here" placeholder are gone. On a phone held upright the card now floats as a compact
//          glass card over the table's top edge, takes no room from the table, and is simply absent when there is
//          nothing to say; its glass carries a dark tint so it reads over the Lens grid. New LensLegendChip: the Lens
//          colour key as a small glass chip for the title row, with Dynamic Type and one spoken sentence.)
// Edited: Claude Opus 5.5 High, 20-November-2026 (event-paced replay and the table uncovered: on a phone held upright
//          the explanation is a CaptionStrip of fixed, reserved height above the controls instead of a card over the
//          table, keeping the last caption between beats; a Continue button (existing string) ends a guided hold, in
//          the strip and under the side-column card; the highlighted ball gets its caption's short title as a glass
//          chip beside the ring, flipped to stay on screen; the leader line is drawn only where the card is beside the
//          table; LensLegendChip is headed "Physics Lens" so the blueprint view is always named. No new strings.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan package 5: LeaderState.topClear, the bottom of the title
//          row, which TableStage sets every frame; the on-table chip is kept below it, so near the top pockets in the
//          Lens it no longer crowds the top controls.)
// PURPOSE: The caption and equation card, the fixed-height caption strip, the Continue button for guided pacing, the
//          Physics Lens key chip, and the highlight ring, on-table title chip and thin leader line that tie the words to
//          the ball they describe. On a phone held upright the words sit in CaptionStrip under the table (ShowpieceView
//          puts it above the controls); everywhere else the card sits in the side column (CaptionArea). The ring
//          position is the ball's place on the table, read from the recorded timeline and projected to the screen by
//          the 3D view each frame. Reads the model; writes to it only through nextBeat() (the Continue button).
// SRP/DRY check: Pass - split out of ShowpieceView. Wording stays in Captions.swift; colours come from Palette.
import BreakdownLensModel
import BreakdownTimeline
import RealityKit
import SwiftUI

// MARK: Card

/// The words of one caption, laid out. Two shapes: natural (the side column, which scrolls and may grow) and reserved
/// (the strip under the table on a phone held upright, which must keep one height whatever the caption says).
private struct CaptionContent: View {
    /// nil only in the reserved shape before the first caption of a replay: the same lines, blank.
    let caption: Caption?
    var accent: Color
    /// Reserved shape: every line keeps its room even when empty or short, so the strip's height never changes from
    /// caption to caption (the camera frames the table above the strip, so a height change would make the table jump).
    var reserved = false
    @AppStorage(GameSettings.mathsKey) private var maths = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if maths {
                Text(verbatim: caption?.equation ?? " ")
                    .font(Theme.equation)
                    .foregroundStyle(accent)
                    .reservedLines(reserved ? 1 : nil)
            }
            Text(verbatim: caption?.title ?? " ")
                .font(Theme.heading)
                .reservedLines(reserved ? 1 : nil)
            Text(verbatim: caption?.detail ?? " ")
                .font(Theme.body)
                .reservedLines(reserved ? 3 : nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    /// Keeps room for exactly `lines` lines (blank or not) when given; natural height when nil.
    @ViewBuilder func reservedLines(_ lines: Int?) -> some View {
        if let lines { lineLimit(lines, reservesSpace: true) } else { self }
    }

    /// The caption card's glass and accent bar, shared by the side-column card and the strip under the table.
    func captionGlass(accent: Color, palette: Palette) -> some View {
        self
            .padding(.leading, 4)
            .padding(CaptionCard.padding)
            // Plain system Liquid Glass, untinted, like every other panel in the app (the Boss: "all of it should be
            // liquid glass, Apple native"). The card now sits below the table, not over the Lens grid, so the system's
            // own glass keeps the words readable; Reduce Transparency still turns it solid.
            .glassEffect(.regular, in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .leading) {
                Capsule().fill(accent).frame(width: 3).padding(.vertical, 12).padding(.leading, 5)
            }
    }
}

/// While guided pacing holds the replay on a beat for reading: the button that moves on to the next beat now.
/// Uses the existing "Continue" string; at the accessibility text sizes only its arrow shows (VoiceOver still reads
/// "Continue") so it does not squeeze the caption's words.
private struct ContinueButton: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    private var button: some View {
        Button { model.nextBeat() } label: {
            Label("Continue", systemImage: "forward.fill")
                .lineLimit(1)
                .fixedSize()
        }
        .buttonStyle(.glassProminent)
        .tint(palette.accent)
        .foregroundStyle(palette.ground)
        // No Return shortcut: the trick-shot card already owns the default action and both can be up at once.
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            button.labelStyle(.iconOnly)
        } else {
            button.labelStyle(.titleAndIcon)
        }
    }
}

struct CaptionCard: View {
    let caption: Caption
    @Environment(\.palette) private var palette
    @AppStorage(GameSettings.mathsKey) private var maths = false
    /// Inner padding of the glass card.
    static let padding: CGFloat = 10

    var body: some View {
        let accent = palette.color(for: caption.accent)
        CaptionContent(caption: caption, accent: accent)
            .captionGlass(accent: accent, palette: palette)
        // One spoken sentence per caption; the equation is read last because it is decoration for most listeners.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption.title). \(caption.detail)")
        .accessibilityValue(maths ? caption.equation : "")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Wide layout (Mac, iPad, landscape side column): the caption for the moment on screen, or nothing at all, with a
/// Continue button under it while guided pacing holds on a beat. Reads the clock itself so the rest of the screen does
/// not redraw every frame. The column scrolls, so here the card keeps its natural height.
struct CaptionArea: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// The most height the card may take before it scrolls (large text sizes).
    let maxHeight: CGFloat

    @AppStorage(GameSettings.explanationsKey) private var explanations = true

    var body: some View {
        let showing = explanations && !model.menuOpen && model.lensOn && model.activeCaption() != nil
        // A ZStack rather than a Group so the view (and the onChange below) exists even when no card shows.
        ZStack(alignment: .top) {
            if showing, let caption = model.activeCaption() {
                VStack(alignment: .trailing, spacing: 8) {
                    FittingScroll(maxHeight: maxHeight) {
                        CaptionCard(caption: caption)
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { leader.card = $0 }
                    }
                    if model.holding { ContinueButton(model: model).transition(.opacity) }
                }
                .transition(.opacity)
                .id(caption.id)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.activeCaption()?.id)
        .animation(.easeOut(duration: 0.2), value: model.holding)
        // With no card on screen the leader must not keep the last card's place: CaptionLeader hides the ring for any
        // ball inside that rectangle, so a stale one (explanations switched off, say) would swallow rings near the top.
        .onChange(of: showing) { _, now in if !now { leader.card = .zero } }
        // Turning the device to the upright layout removes this view without the onChange above firing.
        .onDisappear { leader.card = .zero }
    }
}

/// Phone held upright: the explanation in a strip of FIXED height directly above the playback controls, so it never
/// covers the table. ShowpieceView puts it inside the measured bottom stack, so the camera frames the table above it;
/// because its height is reserved (title one line, detail four lines, equation one line with Show the maths on) the
/// table moves once when the Lens comes up and never again from caption to caption. Between captions the last one
/// stays (guided pacing keeps a caption until the next beat anyway); before the first one the card is blank. At the
/// accessibility text sizes a long detail scrolls inside the same height instead of growing it.
/// Deliberately does NOT write leader.card: the card is far below the table, and the leader draws no line to it here.
struct CaptionStrip: View {
    let model: ShowpieceModel
    /// Cap on the reserved height (the accessibility text sizes would otherwise reserve half the screen).
    let maxHeight: CGFloat

    @Environment(\.palette) private var palette
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @State private var shown: Caption?
    /// Height of the blank reserved lines at the current text size, measured from a hidden copy.
    @State private var reservedHeight: CGFloat = 0

    var body: some View {
        let active = model.lensOn ? model.activeCaption() : nil
        let caption = active ?? shown
        let accent = palette.color(for: caption?.accent ?? .impact)
        let height = min(reservedHeight, maxHeight)
        // The room is reserved (so the camera frames the table above it and the table never jumps between captions),
        // but the glass is not: the card hugs its words and sits at the bottom of the room, right on the controls, so
        // a short caption is a short card and nothing is drawn at all before the first one. A caption longer than the
        // room grows upward over the rails rather than pushing the table. (The Boss: the old fixed card covered the
        // table and left a lot of empty glass.)
        ZStack(alignment: .bottom) {
            if let caption {
                HStack(alignment: .bottom, spacing: 8) {
                    // At the accessibility text sizes a long detail scrolls inside the cap instead of growing.
                    FittingScroll(maxHeight: maxHeight) {
                        CaptionContent(caption: caption, accent: accent)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(caption.title). \(caption.detail)")
                    .accessibilityValue(maths ? caption.equation : "")
                    .accessibilityAddTraits(.updatesFrequently)
                    if model.holding { ContinueButton(model: model).transition(.opacity) }
                }
                .captionGlass(accent: accent, palette: palette)
                .transition(.opacity)
                .id(caption.id)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .bottom)
        // The hidden sizer: same fonts and spacing as the real lines plus the card's padding, every line reserved,
        // never drawn or spoken.
        .background(alignment: .bottom) {
            CaptionContent(caption: nil, accent: accent, reserved: true)
                .padding(.vertical, CaptionCard.padding)
                .fixedSize(horizontal: false, vertical: true)
                .hidden()
                .accessibilityHidden(true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { reservedHeight = $0 }
        }
        .animation(.smooth(duration: 0.3), value: caption?.id)
        .animation(.smooth(duration: 0.25), value: model.holding)
        // Remember the newest caption so it stays up between beats instead of leaving a blank card.
        .onChange(of: active?.id) { _, _ in
            if model.lensOn, let now = model.activeCaption() { shown = now }
        }
        .onAppear { if model.lensOn { shown = model.activeCaption() } }
    }
}

// MARK: Lens colour key

/// The Lens named and explained, as a small glass chip for the title row: the name "Physics Lens" as a heading, then
/// an amber line for a ball sliding and a cyan line for a ball rolling. Whenever the blueprint view is up the player
/// can read what it is and what its colours mean. It replaces the baked 3D legend that used to take a band of height
/// off the table. Text follows Dynamic Type; when one row does not fit beside the back button the pieces stack, and
/// as a last resort the heading drops so the row is never squeezed. Spoken as one sentence (label unchanged).
struct LensLegendChip: View {
    @Environment(\.palette) private var palette

    private func entry(_ name: LocalizedStringKey, _ color: Color) -> some View {
        HStack(spacing: 6) {
            // A short glowing line, like the trail it stands for.
            Capsule().fill(color).frame(width: 16, height: 3).shadow(color: color.opacity(0.8), radius: 3)
            Text(name).font(Theme.label).lineLimit(1)
        }
    }

    private var heading: some View {
        Text("Physics Lens")
            .font(Theme.label.weight(.bold))
            .foregroundStyle(palette.accent)
            .lineLimit(1)
    }

    private var entries: some View {
        HStack(spacing: 12) { entry("Sliding", palette.slide); entry("Rolling", palette.accent) }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { heading; entries }
            VStack(alignment: .leading, spacing: 4) { heading; entries }
            VStack(alignment: .leading, spacing: 4) { heading; entry("Sliding", palette.slide); entry("Rolling", palette.accent) }
            VStack(alignment: .leading, spacing: 4) { entry("Sliding", palette.slide); entry("Rolling", palette.accent) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lens colours: amber lines show a ball sliding, cyan lines a ball rolling")
    }
}

// MARK: Leader line, ring and on-table label

/// The coordinate space shared by the 3D view, the caption card and the leader overlay.
enum StageSpace { static let name = "stage" }

/// Where the highlighted ball is on screen, what its caption is called, and where the caption card is, in StageSpace.
@MainActor
@Observable
final class LeaderState {
    var ring: CGPoint?
    var accent: CaptionAccent = .impact
    /// The current caption's short title, drawn as a chip beside the ring (already localized by Captions.swift).
    var title: String?
    var card: CGRect = .zero
    /// Bottom edge of the title row (StageSpace); the chip beside the ring stays below it.
    var topClear: CGFloat = 0

    /// Called by the 3D view every frame. Finds the ball the current caption is about, asks the view to project it
    /// to the screen, and keeps the previous point when the move is under half a point (so a still frame costs nothing).
    /// Every write is guarded by a comparison: this runs per frame, and an @Observable write redraws its readers.
    func refresh(model: ShowpieceModel, project: (SIMD3<Float>) -> CGPoint?) {
        // Same gate as the caption card and strip (the Lens is up), so a ring never shows without its words.
        guard model.lensOn, !model.menuOpen, let caption = model.activeCaption(), let world = Self.anchor(of: caption, in: model),
              let point = project(world) else {
            if ring != nil { ring = nil }
            if title != nil { title = nil }
            return
        }
        if accent != caption.accent { accent = caption.accent }
        if title != caption.title { title = caption.title }
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

/// A ring around the ball, the caption's short title as a small glass chip beside it, and (only when the card sits
/// beside the table, in the wide layout) a thin line back to the card. Decoration only: hidden from VoiceOver (the
/// card or strip already speaks the caption) and never takes touches, so aiming drags pass straight through.
struct CaptionLeader: View {
    let leader: LeaderState
    /// Draw the line to the card. Off on a phone held upright, where the card is a strip far below the table.
    var showLine = true
    @Environment(\.palette) private var palette
    @Environment(\.layoutDirection) private var layoutDirection
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The chip's measured size, for keeping it on screen.
    @State private var chipSize: CGSize = .zero

    private let ringRadius: CGFloat = 20
    /// Gap between the ring and the chip, and the least distance the chip keeps from the screen's edges.
    private let gap: CGFloat = 8

    /// The ring point, unless the ball is under the card: a ring drawn over the card would strike through its words.
    private var visibleRing: CGPoint? {
        guard let ring = leader.ring else { return nil }
        let card = leader.card
        if !card.isEmpty, card.insetBy(dx: -ringRadius, dy: -ringRadius).contains(ring) { return nil }
        return ring
    }

    /// Where the chip's centre goes: to the right of the ring, flipped to the left when that would leave the screen
    /// or land on the card, then clamped so it is always fully visible. Vertically centred on the ball.
    private func chipCenter(ring: CGPoint, in size: CGSize) -> CGPoint {
        let w = chipSize.width, h = chipSize.height
        let right = CGPoint(x: ring.x + ringRadius + gap + w / 2, y: ring.y)
        let left = CGPoint(x: ring.x - ringRadius - gap - w / 2, y: ring.y)
        func fits(_ c: CGPoint) -> Bool {
            let rect = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
            let onScreen = rect.minX >= gap && rect.maxX <= size.width - gap
            return onScreen && (leader.card.isEmpty || !leader.card.intersects(rect))
        }
        var c = fits(right) || !fits(left) ? right : left
        c.x = min(max(c.x, gap + w / 2), max(gap + w / 2, size.width - gap - w / 2))
        let top = max(gap, leader.topClear + gap) + h / 2
        c.y = min(max(c.y, top), max(top, size.height - gap - h / 2))
        return c
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    guard let ring = visibleRing else { return }
                    let color = palette.color(for: leader.accent)
                    let card = leader.card
                    // Line from the nearest point on the card's edge to the ring's edge, unless the ball sits under the card.
                    if showLine, !card.isEmpty, !card.contains(ring) {
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
                // The chip is a SwiftUI view, not drawn in the Canvas, because a Canvas cannot host Liquid Glass.
                if explanations, let ring = visibleRing, let title = leader.title {
                    let color = palette.color(for: leader.accent)
                    Text(verbatim: title)
                        .font(Theme.label)
                        .lineLimit(1)
                        .fixedSize()
                        // The words keep the player's reading direction; only the placement is in screen points.
                        .environment(\.layoutDirection, layoutDirection)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        // System glass; the caption's colour shows only as a faint tint, so it reads as native glass.
                        .glassEffect(.regular.tint(color.opacity(0.15)), in: .capsule)
                        .onGeometryChange(for: CGSize.self) { $0.size } action: { chipSize = $0 }
                        .position(chipCenter(ring: ring, in: geo.size))
                        // A new caption's chip fades in at its own ball rather than sliding across the table; an
                        // opacity fade is also what Reduce Motion asks for.
                        .id(title)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: leader.title)
        }
        // The ring and chip are placed in screen points from the 3D projection, which does not mirror for
        // right-to-left languages, so this layer is laid out left to right whatever the language.
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
