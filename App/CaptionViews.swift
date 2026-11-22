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
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, package 4: with Differentiate Without Colour on,
//          the Lens key draws sliding as a dashed line and rolling as a solid one, matching the trails, and says so.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 4,
//          53 and 55: (4) when the player's own stroke turned the cue, the Lens draws the line they aimed along (faint,
//          dashed) beside the line the cue really took (bright) from the cue ball out to its first contact, labelled
//          "Your aim" and "Your stroke", and the strike caption gains a sentence saying how far and which way
//          (LensStroke, ShowpieceModel.displayedCaption); (53) while the Lens tips are up the caption card, strip and
//          on-table ring stand back (model.holdForTips), so the tips are the one thing on screen; (55) the equation line
//          shows the event's own numbers (Caption.worked) on the opening's headline beats (model.holdingHeadline) even
//          with Show the maths off, and whenever Show the maths is on.)
// PURPOSE: The caption and equation card, the fixed-height caption strip, the Continue button for guided pacing, the
//          Physics Lens key chip, and the highlight ring, on-table title chip and thin leader line that tie the words to
//          the ball they describe. On a phone held upright the words sit in CaptionStrip under the table (ShowpieceView
//          puts it above the controls); everywhere else the card sits in the side column (CaptionArea). The ring
//          position is the ball's place on the table, read from the recorded timeline and projected to the screen by
//          the 3D view each frame. Reads the model; writes to it only through nextBeat() (the Continue button).
//          The player's stroke lines are drawn by CaptionLeader too: it already holds the per-frame projection.
// SRP/DRY check: Pass - split out of ShowpieceView. Wording stays in Captions.swift; colours come from Palette. The
//          stroke lines reuse LeaderState's projection rather than a second per-frame overlay.
import BreakdownLensModel
import BreakdownTimeline
import RealityKit
import SwiftUI

// MARK: The player's stroke in the Lens

/// The player's stroke on the shot on screen, as the Lens draws it: where the cue ball was struck from, the line the
/// cue really took, the line the player aimed along, and how far to draw them. Read from the attempt (its StrokeDelivery
/// says how far the stroke turned the cue) and the recording (its cue-strike event's normal is the struck direction,
/// because StrokeDelivery.apply turned the strike before it was solved). Nothing is drawn that was not recorded.
struct LensStroke: Equatable {
    let from: Vec2
    let struck: Vec2
    let aimed: Vec2
    /// Metres along both lines: out to where the cue ball made its first contact, so the gap between their far ends is
    /// the miss the stroke made there.
    let length: Double
    /// StrokeDelivery.aimError, radians, positive counter-clockwise (to the shooter's left).
    let aimError: Double
    /// Clock time of that first contact; the lines then fade over the same seconds a trail does.
    let until: Double

    /// Smallest gap between the two lines' far ends worth drawing, metres. A millimetre at the first ball moves the
    /// contact point by a fifty-seventh of a ball's width, which turns a cut by about a degree: enough to miss a long
    /// pot, so it is worth showing; anything finer is two lines drawn on top of each other.
    static let minimumGap = 0.001
    /// The shortest and longest lines drawn, metres: under 30 cm (a contact right in front of the ball) the two lines
    /// cannot be told apart at the far end; past 2 m (the cue ball ran a table length untouched) they leave the cloth.
    static let lengthRange = 0.3...2.0

    /// The stroke to draw now, or nil: only in the Lens, only for one of the player's own strokes that the drift turned,
    /// and only while that very recording is on screen (the attempt's recording matches the one being played).
    @MainActor static func onScreen(_ model: ShowpieceModel) -> LensStroke? {
        guard model.lensOn, !model.menuOpen, let attempt = model.currentAttempt, let d = attempt.stroke,
              d.aimError != 0 else { return nil }
        let tl = model.timeline
        guard attempt.timeline.events.count == tl.events.count, attempt.timeline.duration == tl.duration,
              let strike = tl.events.first(where: { $0.kind == .cueStrike }), let ball = strike.balls.first?.ball,
              ball < tl.ballCount else { return nil }
        let struck = strike.normal.normalized
        guard struck.length > 0.5 else { return nil }
        // The aimed line: the struck one turned back by the drift (StrokeDelivery.apply turned it by +aimError).
        let c = cos(-d.aimError), s = sin(-d.aimError)
        let aimed = Vec2(struck.x * c - struck.y * s, struck.x * s + struck.y * c)
        // Out to the cue ball's first contact with anything (a ball, a rail, a jaw); phase changes are not contacts.
        let first = tl.events.first {
            $0.time > strike.time && $0.kind != .phaseTransition && $0.balls.contains { $0.ball == ball }
        }
        let until = first?.time ?? tl.duration
        let reach = (tl.state(ball: ball, at: until).position - strike.point).length
        let length = min(lengthRange.upperBound, max(lengthRange.lowerBound, reach))
        guard length * abs(sin(d.aimError)) >= minimumGap else { return nil }
        return LensStroke(from: strike.point, struck: struck, aimed: aimed, length: length, aimError: d.aimError,
                          until: until)
    }

    /// How strongly to draw the lines at clock `t`: full until a trail's hold after the first contact, then fading out
    /// with the trails (LensLayer's own hold and fade, read, not copied; LensLayer is main-actor, hence the mark).
    @MainActor func opacity(at t: Double) -> Double {
        let age = t - until
        if age <= LensLayer.trailHold { return 1 }
        if age >= LensLayer.trailFadeEnd { return 0 }
        return 1 - (age - LensLayer.trailHold) / (LensLayer.trailFadeEnd - LensLayer.trailHold)
    }
}

extension ShowpieceModel {
    /// The caption the Lens shows now: the model's own (activeCaption), with one sentence added to the strike's
    /// caption when the player's stroke turned the cue (the lines CaptionLeader draws are explained in words there).
    func displayedCaption() -> Caption? {
        guard let c = activeCaption() else { return nil }
        guard timeline.events.indices.contains(c.id), timeline.events[c.id].kind == .cueStrike,
              let stroke = LensStroke.onScreen(self) else { return c }
        return Caption(id: c.id, time: c.time, title: c.title,
                       detail: c.detail + " " + CaptionEngine.strokeSentence(aimError: stroke.aimError),
                       equation: c.equation, accent: c.accent, importance: c.importance, worked: c.worked)
    }
}

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
    /// A headline beat of the opening is held (model.holdingHeadline): the equation shows with its numbers even with
    /// Show the maths off. (The strip reserves the equation's line only with Show the maths on, so on such a beat a
    /// longer card grows upward over the rails, as any long caption does, instead of moving the table.)
    var headline = false
    @AppStorage(GameSettings.mathsKey) private var maths = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if maths || headline {
                Text(verbatim: caption.map { CaptionContent.equationLine($0) } ?? " ")
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

    /// The equation as shown: with the event's own numbers when the caption has them, else the bare formula. Also what
    /// VoiceOver reads as the card's value, so the screen and the voice agree.
    static func equationLine(_ caption: Caption) -> String {
        caption.worked.isEmpty ? caption.equation : caption.worked
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
    /// A headline beat is held: the worked equation shows even with Show the maths off (CaptionContent.headline).
    var headline = false
    @Environment(\.palette) private var palette
    @AppStorage(GameSettings.mathsKey) private var maths = false
    /// Inner padding of the glass card.
    static let padding: CGFloat = 10

    var body: some View {
        let accent = palette.color(for: caption.accent)
        CaptionContent(caption: caption, accent: accent, headline: headline)
            .captionGlass(accent: accent, palette: palette)
        // One spoken sentence per caption; the equation is read last because it is decoration for most listeners.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption.title). \(caption.detail)")
        .accessibilityValue(maths || headline ? CaptionContent.equationLine(caption) : "")
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
        // While the Lens tips are up the card stands back, so the tips are the one thing to read (item 53).
        let current = model.holdForTips ? nil : model.displayedCaption()
        let showing = explanations && !model.menuOpen && model.lensOn && current != nil
        // A ZStack rather than a Group so the view (and the onChange below) exists even when no card shows.
        ZStack(alignment: .top) {
            if showing, let caption = current {
                VStack(alignment: .trailing, spacing: 8) {
                    FittingScroll(maxHeight: maxHeight) {
                        CaptionCard(caption: caption, headline: model.holdingHeadline)
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { leader.card = $0 }
                    }
                    if model.holding { ContinueButton(model: model).transition(.opacity) }
                }
                .transition(.opacity)
                .id(caption.id)
            }
        }
        .animation(.easeOut(duration: 0.2), value: current?.id)
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
        // While the Lens tips are up the strip stands back (its room stays reserved, so the table does not move).
        let active = model.lensOn && !model.holdForTips ? model.displayedCaption() : nil
        let caption = model.holdForTips ? nil : (active ?? shown)
        let headline = model.holdingHeadline
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
                        CaptionContent(caption: caption, accent: accent, headline: headline)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(caption.title). \(caption.detail)")
                    .accessibilityValue(maths || headline ? CaptionContent.equationLine(caption) : "")
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
            if model.lensOn, let now = model.displayedCaption() { shown = now }
        }
        .onAppear { if model.lensOn { shown = model.displayedCaption() } }
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
    /// With Differentiate Without Colour on, the Lens draws sliding dashed and rolling solid; the key shows the same.
    @Environment(\.accessibilityDifferentiateWithoutColor) private var withoutColour

    /// `dashed`: the sliding entry when shape must carry the meaning (Differentiate Without Colour).
    private func entry(_ name: LocalizedStringKey, _ color: Color, dashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            // A short glowing line, like the trail it stands for: three dashes or one solid stroke.
            Group {
                if dashed {
                    HStack(spacing: 2) { ForEach(0..<3, id: \.self) { _ in Capsule().fill(color).frame(width: 4, height: 3) } }
                        .frame(width: 16)
                } else {
                    Capsule().fill(color).frame(width: 16, height: 3)
                }
            }
            .shadow(color: color.opacity(0.8), radius: 3)
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
        HStack(spacing: 12) { entry("Sliding", palette.slide, dashed: withoutColour); entry("Rolling", palette.accent) }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { heading; entries }
            VStack(alignment: .leading, spacing: 4) { heading; entries }
            VStack(alignment: .leading, spacing: 4) { heading; entry("Sliding", palette.slide, dashed: withoutColour); entry("Rolling", palette.accent) }
            VStack(alignment: .leading, spacing: 4) { entry("Sliding", palette.slide, dashed: withoutColour); entry("Rolling", palette.accent) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(withoutColour
            ? Text("Lens lines: dashed amber lines show a ball sliding, solid cyan lines a ball rolling")
            : Text("Lens colours: amber lines show a ball sliding, cyan lines a ball rolling"))
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
    /// The player's stroke lines on screen (StageSpace), or nil (LensStroke.onScreen decides when).
    var stroke: StrokeMarks?

    /// The two stroke lines projected to the screen: from the cue ball out along the aimed line and the struck line.
    struct StrokeMarks: Equatable {
        var from: CGPoint
        var aimedEnd: CGPoint
        var struckEnd: CGPoint
        /// 0 to 1, in steps of a twentieth, so a fade writes (and redraws) at most twenty times.
        var opacity: Double
    }

    /// Called by the 3D view every frame. Finds the ball the current caption is about, asks the view to project it
    /// to the screen, and keeps the previous point when the move is under half a point (so a still frame costs nothing).
    /// Every write is guarded by a comparison: this runs per frame, and an @Observable write redraws its readers.
    func refresh(model: ShowpieceModel, project: (SIMD3<Float>) -> CGPoint?) {
        // The stroke lines first: they do not depend on a caption being up.
        let marks = Self.strokeMarks(model: model, project: project)
        if stroke != marks { stroke = marks }
        // Same gate as the caption card and strip (the Lens is up, the tips are not), so a ring never shows without
        // its words.
        guard model.lensOn, !model.menuOpen, !model.holdForTips, let caption = model.activeCaption(),
              let world = Self.anchor(of: caption, in: model), let point = project(world) else {
            if ring != nil { ring = nil }
            if title != nil { title = nil }
            return
        }
        if accent != caption.accent { accent = caption.accent }
        if title != caption.title { title = caption.title }
        if let old = ring, hypot(old.x - point.x, old.y - point.y) < 0.5 { return }
        ring = point
    }

    /// The stroke lines for this frame: both lines lie on the cloth (2 mm up, under the balls and the Lens trails'
    /// glow), projected with the same projection as the ring. Nil when there is nothing to draw or a point is behind
    /// the camera.
    private static func strokeMarks(model: ShowpieceModel, project: (SIMD3<Float>) -> CGPoint?) -> StrokeMarks? {
        guard let s = LensStroke.onScreen(model) else { return nil }
        let opacity = (s.opacity(at: model.time) * 20).rounded() / 20
        guard opacity > 0 else { return nil }
        let frame = TableFrame(model.timeline.table)
        let lift: Float = 0.002
        guard let from = project(frame.world(s.from, height: lift)),
              let aimed = project(frame.world(s.from + s.aimed * s.length, height: lift)),
              let struck = project(frame.world(s.from + s.struck * s.length, height: lift)) else { return nil }
        // Whole points: sub-point camera jitter must not rewrite the marks every frame.
        func snap(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x.rounded(), y: p.y.rounded()) }
        return StrokeMarks(from: snap(from), aimedEnd: snap(aimed), struckEnd: snap(struck), opacity: opacity)
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

    /// The player's stroke (item 4): the aimed line faint and dashed, the line the cue really took bright and solid,
    /// both from the cue ball, each labelled at its far end. The labels are pushed apart across the two ends, so they
    /// never sit on each other however small the gap.
    private func drawStroke(_ m: LeaderState.StrokeMarks, in ctx: inout GraphicsContext) {
        let o = m.opacity
        var aimed = Path(); aimed.move(to: m.from); aimed.addLine(to: m.aimedEnd)
        var struck = Path(); struck.move(to: m.from); struck.addLine(to: m.struckEnd)
        ctx.stroke(aimed, with: .color(palette.paper.opacity(0.6 * o)),
                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 5]))
        ctx.stroke(struck, with: .color(.black.opacity(0.35 * o)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        ctx.stroke(struck, with: .color(palette.paper.opacity(o)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        // Which way to push each label: away from the other line's end; if the ends sit on one point, across the line.
        var nx = m.aimedEnd.x - m.struckEnd.x, ny = m.aimedEnd.y - m.struckEnd.y
        var len = hypot(nx, ny)
        if len < 1 {
            nx = -(m.struckEnd.y - m.from.y); ny = m.struckEnd.x - m.from.x
            len = max(1, hypot(nx, ny))
        }
        nx /= len; ny /= len
        let push: CGFloat = 14
        let aimedAt = CGPoint(x: m.aimedEnd.x + nx * push, y: m.aimedEnd.y + ny * push)
        let struckAt = CGPoint(x: m.struckEnd.x - nx * push, y: m.struckEnd.y - ny * push)
        ctx.draw(Text(verbatim: String(localized: "Your aim")).font(Theme.label)
                    .foregroundStyle(palette.paper.opacity(0.75 * o)), at: aimedAt, anchor: .center)
        ctx.draw(Text(verbatim: String(localized: "Your stroke")).font(Theme.label.weight(.semibold))
                    .foregroundStyle(palette.paper.opacity(o)), at: struckAt, anchor: .center)
    }

    var body: some View {
        GeometryReader { geo in
            // Read here, in the body, so the layer redraws when the stroke marks change (as the ring does below).
            let marks = leader.stroke
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    if let marks { drawStroke(marks, in: &ctx) }
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
