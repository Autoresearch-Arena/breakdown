// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 24-November-2026 (0.7.8 jump replay: the blurb reports where it sits to leader.blurb, so the jump's side view keeps clear of it.)
// PURPOSE: The explanation on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The Blurb" and Part 4
//          step 4). Two views, both used only by ShowpieceView's upright layout:
//          PhoneExplanationBlurb - the caption of the moment on screen (model.displayedCaption, the same words the
//            notebook's card and the old strip showed) as one small anchored Blurb above or below its moment, in place
//            of CaptionStrip's fixed room. Its title carries the lead figure in bold monospaced white, the other
//            figures are chips, then the plain sentence (three lines, the "more" dot when words are folded away), then
//            the worked equation only with Show the maths on or on a headline beat. BlurbPlacement picks the side
//            (below first: the moment framing puts the moment at about 35 per cent of the table area's height while
//            explanations can show on the Lens, see MomentFrame.blurbShare), keeps it clear of the ring and the lead
//            figure, and a white leader (BlurbLeader) joins it to the ring. The leader and the figure beside the ring
//            follow the ring every frame in their own small layer (RingMarks), so the blurb itself is not redrawn
//            per frame. A blurb never moves during a beat: its place is worked out when
//            its caption arrives and kept, and is worked out again only when it opens or folds, when the table area
//            changes, or when the ring itself would come under it (the ball rolled there between beats). With no anchor
//            or no room either side it sits at the top or bottom edge of the table area, away from the ring, with no
//            leader. Tapping it opens it in place; a held beat stays held while it is open (the replay is paused for
//            reading and resumed when it folds), and Continue or Play folds it again. The lead figure is also written
//            beside the ring, on the table, in its Lens mark's colour (magenta sliding, cyan rolling, the event
//            colours otherwise). VoiceOver reads the whole blurb, folded or not.
//          PhoneLensKeyBlurb - the Lens colour key as a one-line docked blurb, "Sliding" and "Rolling" with their
//            glowing lines (dashed sliding with Differentiate Without Colour), only while the Lens is on. It replaces
//            LensLegendChip in the title row on this layout only.
//          Reads the model, the leader (ring point, from TableStage's per-frame projection) and the Options switches
//          (Explanations, Show the maths). Writes the model only through `playing` (pause for reading, resume) and
//          setHoldPages (one page: this blurb never pages), MomentFrame.blurbShare and leader.blurb (0.7.8: where it sits,
//          so the jump's side view keeps clear of it). Never writes leader.card: the
//          ring hides itself under a reported card, and this blurb sits right beside its ring.
// SRP/DRY check: Pass - checked CaptionViews.swift (CaptionStrip and CaptionArea are the other layouts' cards; the
//          caption, its figures and its equation line come from there and Captions.swift, not rebuilt here; the Lens
//          key's entries are LensKeyEntry, shared with LensLegendChip), App/Phone/Blurb.swift (the look and the fold)
//          and App/Phone/BlurbPlacement.swift (the side and the frame). The ring stays CaptionLeader's.
import Foundation
import SwiftUI

// MARK: The explanation, anchored to its moment

struct PhoneExplanationBlurb: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// Where blurbs may go, in StageSpace: under the title row (or the lowest docked blurb), above the control bar.
    let tableArea: CGRect

    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Where a caption's blurb was put: its frame in StageSpace and the side of the ring it took (nil: at an edge of
    /// the table area, no anchor or no room either side). Kept for the whole beat (see PURPOSE).
    fileprivate struct Placed: Equatable {
        let caption: Int
        let frame: CGRect
        let side: BlurbPlacement.Side?
    }

    @State private var placed: Placed? = nil
    /// The blurb's measured size (it follows its words, and grows when opened).
    @State private var size: CGSize = .zero
    /// This layer's top-left corner in StageSpace: everything is worked out in StageSpace and drawn shifted by it.
    @State private var origin: CGPoint = .zero
    /// The lead figure's measured size, for its place beside the ring (measured by RingMarks).
    @State private var figureSize: CGSize = .zero
    /// The caption on screen has a lead figure written beside its ring, which the blurb must keep clear of too.
    @State private var hasFigure = false
    /// True while the blurb is folded (the Blurb's own fold switch, owned here so a held beat can wait for it).
    @State private var folded = true
    /// This view paused the replay so an opened blurb could be read on a held beat; it resumes it on folding.
    @State private var pausedForReading = false

    /// The lead figure's distance from the ring, and its least distance from the table area's side.
    fileprivate static let figureGap: CGFloat = 6
    fileprivate static let edgeGap: CGFloat = 8
    /// The ring's box is widened by this much when the blurb keeps clear of it (its stroke and a little air).
    private static let ringPad: CGFloat = 4
    /// Where the moment is framed while explanations can show: about a third of the way down the table area, so the
    /// blurb (below first) has the larger part of the room (Part 3, "Placement").
    static let momentShare = 0.35

    /// The caption to explain now, under the same gate as the other layouts' cards: Explanations on, the Lens up, the
    /// menu closed, and the Lens tips not showing (they are the one thing to read while up).
    private var caption: Caption? {
        guard explanations, model.lensOn, !model.menuOpen, !model.holdForTips else { return nil }
        return model.displayedCaption()
    }

    /// The moment framing should leave room below the moment. Set as soon as explanations can show on the Lens, not
    /// only once a caption is up: the camera glides in before its beat, and a share that changed after the blurb was
    /// placed would pull the moment away from its frozen blurb. (Off the moment, the framing is whole and this has no
    /// effect; see MomentFrame.)
    private var framesForBlurb: Bool { explanations && model.lensOn && !model.menuOpen }

    var body: some View {
        // Read once per body: the caption is worked out from the clock. The ring is NOT read here (it changes every
        // frame while the ball or the camera moves); RingMarks reads it, so only that small layer redraws per frame.
        let caption = self.caption
        let shown = caption.flatMap { c in placed?.caption == c.id ? placed : nil }
        ZStack(alignment: .topLeading) {
            // Fills the stage so the offsets below are from its corner; never takes a touch (aiming passes through).
            Color.clear.allowsHitTesting(false)
            if let caption {
                RingMarks(leader: leader, figure: FlightShape.isTakeOff(caption, in: model.timeline) ? nil : caption.figures.first,
                          placed: shown, origin: origin,
                          tableArea: tableArea, figureSize: $figureSize, onRingMoved: { ringMoved(to: $0) })
                blurb(caption)
                    // The words keep the reader's direction; only the placement is in screen points.
                    .environment(\.layoutDirection, layoutDirection)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { new in
                        size = new
                        place(caption.id, keepSide: true)
                    }
                    // Offered the table area's width less its margins; the blurb takes only what its words need.
                    .frame(width: max(0, tableArea.width - 2 * BlurbPlacement.margin), alignment: .topLeading)
                    .offset(x: (shown?.frame.minX ?? 0) - origin.x, y: (shown?.frame.minY ?? 0) - origin.y)
                    // Unseen and silent until it has a place, so it never flashes at the corner.
                    .opacity(shown == nil ? 0 : 1)
                    .accessibilityHidden(shown == nil)
                    .id(caption.id)
                    .transition(Blurb.transition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Placed in screen points from the 3D projection, which does not mirror for right-to-left languages.
        .environment(\.layoutDirection, .leftToRight)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .named(StageSpace.name)).origin } action: { origin = $0 }
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: caption?.id)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: placed)
        .onChange(of: caption?.id, initial: true) { _, id in captionChanged(to: id) }
        // The table area moved (a docked blurb came or went, the bar grew): the blurb is placed again, same side first.
        .onChange(of: tableArea) { _, _ in if let id = placed?.caption { place(id, keepSide: true) } }
        // Open: hold the beat for reading. Folded: let it run on, if this view held it.
        .onChange(of: folded) { _, isFolded in foldChanged(isFolded) }
        // Continue or Play folds an opened blurb (Part 3: "tap again or play to close").
        .onChange(of: model.playing) { _, playing in
            if playing, !folded {
                pausedForReading = false
                folded = true
            }
        }
        // Where the blurb sits (0.7.8): the jump's side view keeps clear of it (CaptionLeader.flightCenter).
        .onChange(of: shown?.frame ?? .zero, initial: true) { _, frame in
            if leader.blurb != frame { leader.blurb = frame }
        }
        .onChange(of: framesForBlurb, initial: true) { _, on in
            MomentFrame.blurbShare = on ? Self.momentShare : 0.5
        }
        .onDisappear {
            if leader.blurb != .zero { leader.blurb = .zero }
            MomentFrame.blurbShare = 0.5
            if pausedForReading, model.holding { model.playing = true }
            pausedForReading = false
        }
        .allowsHitTesting(caption != nil)
    }

    // MARK: The blurb

    private func blurb(_ caption: Caption) -> Blurb {
        let showsEquation = maths || model.isHeadline(caption)
        let equation = caption.equationLine
        return Blurb(title: caption.title.isEmpty ? nil : caption.title,
                     figure: caption.figures.first,
                     // The lead figure is in the title; the others are chips (at most two more).
                     chips: Array(caption.figures.dropFirst()),
                     sentence: caption.detail.isEmpty ? nil : caption.detail,
                     equation: showsEquation && !equation.isEmpty ? equation : nil,
                     folded: $folded)
    }

    // MARK: Placement (all in StageSpace)

    /// The lead figure's top-left corner: right of the ring, level with it; left of it when the right side runs out.
    fileprivate static func figureOrigin(ring: CGPoint, figureSize: CGSize, tableArea: CGRect) -> CGPoint {
        let r = CaptionLeader.ringRadius
        var x = ring.x + r + figureGap
        if x + figureSize.width > tableArea.maxX - edgeGap {
            x = ring.x - r - figureGap - figureSize.width
        }
        return CGPoint(x: x, y: ring.y - figureSize.height / 2)
    }

    /// What the blurb must never cover: the ring (with its stroke) and, when there is one, the lead figure beside it.
    private func keepClear(ring: CGPoint, figure: Bool) -> CGRect {
        let r = CaptionLeader.ringRadius + Self.ringPad
        let box = CGRect(x: ring.x - r, y: ring.y - r, width: 2 * r, height: 2 * r)
        guard figure, figureSize.width > 0 else { return box }
        let at = Self.figureOrigin(ring: ring, figureSize: figureSize, tableArea: tableArea)
        return box.union(CGRect(origin: at, size: figureSize))
    }

    /// Works out the blurb's place for caption `id`. keepSide: try the side it already has for this caption first
    /// (an opened blurb stays on its side of the ring); otherwise below first.
    private func place(_ id: Int, keepSide: Bool) {
        guard size.width > 0, size.height > 0, tableArea.height > 0 else { return }
        let ring = leader.ring
        let current = placed?.caption == id ? placed : nil
        let preferred: BlurbPlacement.Side = keepSide ? (current?.side ?? .below) : .below
        let next: Placed
        if let ring,
           let anchored = BlurbPlacement.anchored(anchor: ring, size: size, tableArea: tableArea,
                                                  keepClear: keepClear(ring: ring, figure: hasFigure),
                                                  preferred: preferred) {
            next = Placed(caption: id, frame: anchored.frame, side: anchored.side)
        } else {
            // No anchor, or no room either side: at the edge of the table area farther from the ring (the top when
            // there is no ring), at the left margin, with no leader.
            let gap = BlurbPlacement.dockSpacing
            let atBottom = ring.map { $0.y < tableArea.midY } ?? false
            let top = atBottom ? max(tableArea.minY + gap, tableArea.maxY - gap - size.height) : tableArea.minY + gap
            let frame = BlurbPlacement.dockedFrames(sizes: [size], top: top, area: tableArea)[0]
            next = Placed(caption: id, frame: frame, side: nil)
        }
        if placed != next { placed = next }
    }

    /// The ring moved. An anchored blurb stays put (the leader stretches) unless the ring would now be under it; a
    /// blurb waiting at an edge tries again for an anchor.
    private func ringMoved(to ring: CGPoint?) {
        guard let ring, let current = placed, current.caption == caption?.id else { return }
        if current.side == nil {
            place(current.caption, keepSide: false)
        } else if keepClear(ring: ring, figure: false).intersects(current.frame) {
            place(current.caption, keepSide: true)
        }
    }

    /// A new caption (or none): folded, placed afresh (below first), any reading pause let go, and the model told this
    /// caption is one page (the old strip could page a caption; this blurb never does, so no stale pages remain).
    private func captionChanged(to id: Int?) {
        if pausedForReading {
            pausedForReading = false
            if model.holding { model.playing = true }
        }
        if !folded { folded = true }
        guard let id else { return }
        hasFigure = caption?.figures.isEmpty == false
        model.setHoldPages(caption: id, weights: [1])
        place(id, keepSide: false)
    }

    /// Opened on a held beat of the ordinary table: pause, so the hold's reading time stops running while the player
    /// reads (the hold counts only while playing). Folded again: play on, if this view was the one that paused.
    private func foldChanged(_ isFolded: Bool) {
        if !isFolded {
            if model.holding, model.playing, model.stage == .explore {
                model.playing = false
                pausedForReading = true
            }
        } else if pausedForReading {
            pausedForReading = false
            if model.holding { model.playing = true }
        }
    }
}

/// What follows the ring every frame, kept apart from the blurb so only this small layer redraws while the ball or the
/// camera moves: the lead figure written beside the ring (content, never glass, in its Lens mark's colour with a dark
/// shadow so it reads on any cloth) and the white leader from the ring's edge to the blurb's near edge (only while the
/// blurb is anchored). Reports each move of the ring to the blurb, which decides whether to move. Never takes touches;
/// VoiceOver skips it (the blurb says everything).
private struct RingMarks: View {
    let leader: LeaderState
    let figure: CaptionFigure?
    /// The blurb's place for this caption (nil until placed).
    let placed: PhoneExplanationBlurb.Placed?
    /// The layer's top-left corner in StageSpace.
    let origin: CGPoint
    let tableArea: CGRect
    @Binding var figureSize: CGSize
    let onRingMoved: (CGPoint?) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        let ring = leader.ring
        ZStack(alignment: .topLeading) {
            Color.clear
            if let ring {
                if let figure {
                    let at = PhoneExplanationBlurb.figureOrigin(ring: ring, figureSize: figureSize, tableArea: tableArea)
                    Text(verbatim: figure.text)
                        .font(Theme.blurbFigure)
                        .foregroundStyle(palette.color(for: figure.mark))
                        .shadow(color: .black.opacity(0.85), radius: 2)
                        .lineLimit(1)
                        .fixedSize()
                        .onGeometryChange(for: CGSize.self) { $0.size } action: { figureSize = $0 }
                        .offset(x: at.x - origin.x, y: at.y - origin.y)
                        .opacity(figureSize.width > 0 ? 1 : 0)
                }
                if let placed, let side = placed.side, let line = Self.leaderLine(ring: ring, frame: placed.frame, side: side) {
                    BlurbLeader(from: local(line.from), to: local(line.to))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: ring) { _, now in onRingMoved(now) }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The leader's two ends: from the ring's edge (not its centre, so it never crosses the ball) to the blurb's near
    /// edge at the ring's x, kept off the blurb's rounded corners. Nil when the two are too close for a line.
    static func leaderLine(ring: CGPoint, frame: CGRect, side: BlurbPlacement.Side) -> (from: CGPoint, to: CGPoint)? {
        let inset = min(BlurbPlacement.leaderInset, frame.width / 2)
        let to = CGPoint(x: min(max(ring.x, frame.minX + inset), frame.maxX - inset),
                         y: side == .below ? frame.minY : frame.maxY)
        let dx = to.x - ring.x, dy = to.y - ring.y
        let length = hypot(dx, dy)
        let r = CaptionLeader.ringRadius
        guard length > r + 2 else { return nil }
        return (CGPoint(x: ring.x + dx / length * r, y: ring.y + dy / length * r), to)
    }

    /// A StageSpace point in this layer's own space.
    private func local(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x - origin.x, y: p.y - origin.y) }
}

// MARK: The Lens key, docked

/// The Lens colour key on the upright phone: one line, "Sliding" and "Rolling" with their glowing lines, as a docked
/// blurb at the top of ShowpieceView's dock, only while the Lens is on. Spoken as one sentence, the same words as
/// LensLegendChip's.
struct PhoneLensKeyBlurb: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    /// With Differentiate Without Colour on, the Lens draws sliding dashed and rolling solid; the key shows the same.
    @Environment(\.accessibilityDifferentiateWithoutColor) private var withoutColour

    var body: some View {
        if model.lensOn {
            Blurb(accessibilityText: withoutColour
                    ? String(localized: "Lens lines: dashed magenta lines show a ball sliding, solid cyan lines a ball rolling")
                    : String(localized: "Lens colours: magenta lines show a ball sliding, cyan lines a ball rolling")) {
                HStack(spacing: 12) {
                    LensKeyEntry(name: "Sliding", color: palette.slide, dashed: withoutColour)
                    LensKeyEntry(name: "Rolling", color: palette.accent)
                }
                .fixedSize()
            }
            .transition(Blurb.transition)
        }
    }
}
