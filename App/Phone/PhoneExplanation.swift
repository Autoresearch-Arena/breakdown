// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the thumb dock: the explanation no longer sits
//          on the table. PhoneExplanationBlurb is one of the dock's word sources: its Blurb hands the caption's words
//          to the word strip (title, lead figure and short sentence in two lines, "More" for the rest) and the
//          pull-up sheet (chips, the full text, the equation, the jump's side view). Its placement beside the ring,
//          the leader line and the moment framing's room below the moment are gone (MomentFrame.blurbShare stays at
//          the middle, 0.5); opening the sheet still holds a held beat for reading, through the blurb's fold switch.
//          On the table only the ring (CaptionLeader) and the bare lead figure beside it remain, drawn by
//          PhoneRingFigure, so no caption sits on the ball it describes. The jump's side view is a picture, not
//          words, so it stays on screen during the jump: CaptionLeader draws it beside the flight (showFlight), clear
//          of the dock; the sheet's card shows it as well. PhoneLensKeyBlurb is gone: the Physics Lens
//          key is the strip's control line and the sheet's first card, with a route to the full key (wave 2 note 43).)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike, plan stage 4 item 2: the strike's blurb gains one
//          line when planned and delivered differ, the largest error only, StrikeReading.withPhoneLine.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 words, plans/25-Nov-2026-fewer-words-and-honest-claims-plan.md
//          Part B: the blurb shows the caption's short form folded (title, lead figure, chips, Caption.short, whole and
//          wrapped) and its full text once opened by a tap; the worked equation waits for the opened blurb unless it is
//          a headline beat's.)
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9: the jump's side view sits inside its blurb here
//          (FlightInBlurb), under the figures.)
// Edited: Claude Opus 5.5 Medium, 24-November-2026 (0.7.8 jump replay: the blurb reports where it sits to leader.blurb.)
// PURPOSE: The explanation on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3, and
//          plans/26-Nov-2026-ui-rethink-plan.md package 6). Two views, both used only by ShowpieceView's upright layout:
//          PhoneExplanationBlurb - the caption of the moment on screen (model.displayedCaption, the same words the
//            notebook shows) as a Blurb in the dock's word sources: its title, its lead figure, its other figures as
//            chips, the short sentence folded and the detail once opened, the worked equation with Show the maths on
//            or on a headline beat, and the jump's side view (FlightInBlurb) as its picture. The sheet opening the
//            blurb (its fold switch) holds a held beat while it is read and lets it run on when it folds; Continue or
//            Play folds it. A new caption starts folded and tells the model it is one page (setHoldPages).
//          PhoneRingFigure - over the table: the caption's lead figure written beside its ring (right of it, left when
//            the right side runs out), in its Lens mark's colour with a dark shadow so it reads on any cloth. The one
//            small bare figure the design language allows on the cloth; never words. Redrawn per frame in its own
//            small layer, as the ring moves.
//          Reads the model, the leader (ring point) and the Options switches (Explanations, Show the maths). Writes the
//          model only through `playing` (pause for reading, resume) and setHoldPages, MomentFrame.blurbShare (back to
//          0.5).
// SRP/DRY check: Pass - checked CaptionViews.swift (the caption, its figures and its equation line come from there and
//          Captions.swift, not rebuilt here; the ring stays CaptionLeader's), App/Phone/Blurb.swift (the words' look) and
//          App/Phone/PhoneWords.swift (the strip and the sheet).
import Foundation
import SwiftUI

// MARK: The explanation, a word source of the dock

struct PhoneExplanationBlurb: View {
    let model: ShowpieceModel
    let leader: LeaderState

    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @AppStorage(GameSettings.mathsKey) private var maths = false

    /// True while the blurb is folded (the Blurb's fold switch, owned here so a held beat can wait for it; the dock's
    /// sheet opens it).
    @State private var folded = true
    /// This view paused the replay so an opened explanation could be read on a held beat; it resumes it on folding.
    @State private var pausedForReading = false

    /// The caption to explain now, under the same gate as the other layouts' cards: Explanations on, the Lens up, the
    /// menu closed, and the Lens tips not showing (they are the one thing to read while up).
    static func caption(_ model: ShowpieceModel, explanations: Bool) -> Caption? {
        guard explanations, model.lensOn, !model.menuOpen, !model.holdForTips else { return nil }
        return model.displayedCaption()
    }

    var body: some View {
        let caption = Self.caption(model, explanations: explanations)
        Group {
            if let caption { blurb(caption).id(caption.id) }
        }
        .onChange(of: caption?.id, initial: true) { _, id in captionChanged(to: id, caption: caption) }
        // Open: hold the beat for reading. Folded: let it run on, if this view held it.
        .onChange(of: folded) { _, isFolded in foldChanged(isFolded) }
        // Continue or Play folds an opened explanation (Part 3: "tap again or play to close").
        .onChange(of: model.playing) { _, playing in
            if playing, !folded {
                pausedForReading = false
                folded = true
            }
        }
        .onAppear {
            // Nothing of the explanation sits on the table any more: the moment is framed in the middle (a jump's
            // share still scales it up, leaving room for the side view below). leader.blurb is the dock's now
            // (PhoneDock reports its frame there, for the jump's side view to keep clear of).
            MomentFrame.blurbShare = 0.5
        }
        .onDisappear {
            if pausedForReading, model.holding { model.playing = true }
            pausedForReading = false
        }
    }

    private func blurb(_ caption: Caption) -> Blurb {
        // 0.7.10 words: the maths-on equation belongs to the full text, so the folded short form leaves it for the
        // sheet; a headline beat's worked equation still shows, as it always has.
        let hasShort = !caption.short.isEmpty
        let showsEquation = model.isHeadline(caption) || (maths && (!hasShort || !folded))
        let equation = caption.equationLine
        return Blurb(title: caption.title.isEmpty ? nil : caption.title,
                     figure: caption.figures.first,
                     // The lead figure is in the title; the others are chips (at most two more).
                     chips: Array(caption.figures.dropFirst()),
                     // 0.7.10 words + strike: the short sentence folded, the detail once opened; the strike's own
                     // explanation gains one line when the stroke changed the strike (StrikeReading.withPhoneLine).
                     sentence: StrikeReading.withPhoneLine(hasShort ? caption.short : caption.detail, caption: caption, model: model),
                     fullSentence: hasShort && !caption.detail.isEmpty
                         ? StrikeReading.withPhoneLine(caption.detail, caption: caption, model: model) : nil,
                     equation: showsEquation && !equation.isEmpty ? equation : nil,
                     // A jump's side view (0.7.9): in the sheet's card, under the figures.
                     picture: AnyView(FlightInBlurb(leader: leader, captionID: caption.id)),
                     folded: $folded)
    }

    /// A new caption (or none): folded, any reading pause let go, and the model told this caption is one page (the
    /// old strip could page a caption; this one never does, so no stale pages remain).
    private func captionChanged(to id: Int?, caption: Caption?) {
        if pausedForReading {
            pausedForReading = false
            if model.holding { model.playing = true }
        }
        if !folded { folded = true }
        guard let id else { return }
        model.setHoldPages(caption: id, weights: [1])
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

// MARK: The bare figure beside the ring

/// Over the table: the caption's lead figure beside its ring, the one bare figure the cloth carries on the upright
/// phone. Reads the ring every frame in this small layer only. Never takes touches; VoiceOver skips it (the dock's
/// word strip says everything).
struct PhoneRingFigure: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// The table's room in StageSpace (under the title row, above the dock), so the figure never crosses either.
    let tableArea: CGRect

    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @Environment(\.palette) private var palette
    /// This layer's top-left corner in StageSpace: everything is worked out in StageSpace and drawn shifted by it.
    @State private var origin: CGPoint = .zero
    @State private var figureSize: CGSize = .zero

    /// The figure's distance from the ring, and its least distance from the table area's side.
    private static let figureGap: CGFloat = Theme.Space.xs
    private static let edgeGap: CGFloat = Theme.Space.xs

    var body: some View {
        let caption = PhoneExplanationBlurb.caption(model, explanations: explanations)
        // A jump's take-off is shown by its side view, not a figure.
        // While a jump's side view is up (CaptionLeader draws it beside the flight) the figure steps aside, so the two
        // never land on each other; the side view carries the jump's own figures.
        let figure = leader.flight != nil ? nil
            : caption.flatMap { c in FlightShape.isTakeOff(c, in: model.timeline) ? nil : c.figures.first }
        let ring = leader.ring
        ZStack(alignment: .topLeading) {
            Color.clear
            if let figure, let ring {
                let at = Self.figureOrigin(ring: ring, figureSize: figureSize, tableArea: tableArea)
                Text(verbatim: figure.text)
                    .font(Theme.inlineFigure)
                    .foregroundStyle(palette.color(for: figure.mark))
                    .shadow(color: palette.ground.opacity(0.85), radius: 2)
                    .lineLimit(1)
                    .fixedSize()
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { figureSize = $0 }
                    .offset(x: at.x - origin.x, y: at.y - origin.y)
                    .opacity(figureSize.width > 0 && tableArea.contains(CGPoint(x: at.x, y: at.y)) ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Placed in screen points from the 3D projection, which does not mirror for right-to-left languages.
        .environment(\.layoutDirection, .leftToRight)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .named(StageSpace.name)).origin } action: { origin = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The figure's top-left corner: right of the ring, level with it; left of it when the right side runs out.
    static func figureOrigin(ring: CGPoint, figureSize: CGSize, tableArea: CGRect) -> CGPoint {
        let r = CaptionLeader.ringRadius
        var x = ring.x + r + figureGap
        if x + figureSize.width > tableArea.maxX - edgeGap {
            x = ring.x - r - figureGap - figureSize.width
        }
        return CGPoint(x: x, y: ring.y - figureSize.height / 2)
    }
}

// MARK: The jump's side view

/// The jump's side view inside its explanation blurb on the upright phone (0.7.9): the same drawing as the floating
/// panel elsewhere (FlightSideView, inline style), as wide as the blurb and 88 points tall. Nothing at all for a
/// caption about no jump. Reads leader.flight itself, so only this small view redraws as the ball flies, never the
/// blurb's words.
private struct FlightInBlurb: View {
    let leader: LeaderState
    let captionID: Int
    static let height: CGFloat = 88
    @Environment(\.palette) private var palette
    @State private var width: CGFloat = 0

    var body: some View {
        if let sketch = leader.flight, sketch.captionID == captionID {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: Self.height)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                .overlay(alignment: .topLeading) {
                    if width > 60 {
                        FlightSideView(sketch: sketch, accent: palette.color(for: CaptionAccent.impact),
                                       size: CGSize(width: width, height: Self.height), style: .inline)
                            // Drawn in screen terms and mirrored by the sketch itself, whatever the reading direction.
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                .accessibilityHidden(true)
        }
    }
}
