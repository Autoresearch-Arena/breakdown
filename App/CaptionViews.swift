// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 4: CaptionLeader gains showChip (the ring
//          stays, its title chip goes on the upright phone, where the anchored explanation blurb carries the title) and
//          shares its ring radius (CaptionLeader.ringRadius) with that blurb; the worked equation line moves onto Caption
//          (Caption.equationLine) so the phone's blurb shows the same line; the Lens key's glowing entries become
//          LensKeyEntry, shared by LensLegendChip and the phone's one-line Lens key blurb. Nothing changes on the other
//          layouts.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 coordinator: wires the Ride hand-over in).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream figures: the caption's physics figures (Caption.figures)
//          as a row of compact tiles under the title line, each number large in rounded monospaced digits in the colour
//          of the Lens mark it describes, its label small under it. The phone strip keeps the row's place in its fixed
//          room in all three of its layouts (the card, the hidden sizer and the layout twin), so the room's height never
//          changes and the pages are cut for the room the row leaves; the side-column card shows the same row. The title
//          chip on the table adds the lead figure after the title when both fit on one line, in its tile's colour
//          (LeaderState.figure). VoiceOver reads the figures after the detail, label then value. displayedCaption keeps
//          the figures. New words: the spoken unit names.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream card, plans/22-Nov-2026-v076-phone-plan.md, bugs #1, #2,
//          #3, #8, #9, #11, #59, #60: the phone's CaptionStrip is a fixed room (equation line when the replay has
//          headline beats or Show the maths is on, the title line with Continue at its end, four detail lines, capped)
//          that nothing inside may overflow; a caption longer than the room is split into pages at sentence ends,
//          reported to the model (setHoldPages) and turned by Continue or small page dots; Continue keeps its room for
//          the whole guided replay; the worked equation is decided by the caption, one line, shrinking to fit; the strip
//          reports its glass to leader.card. The ring and title chip: a Throw caption marks the thrown ball, the chip is
//          kept above the card, never on the ring (above or below it when neither side fits) and capped to the stage's
//          width on two lines. CaptionArea reports only the part of its card the side column shows. displayedCaption
//          keeps the caption's sentences. One new phrase, the page dots' spoken "Page %lld of %lld".)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts items 4 and 12, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md:
//          ContinueButton is internal, so the notebook shows it for a held moment too; LeaderState.stageRect, the
//          table's own frame, bounds the on-table caption chip, so on the open Duo the chip stays on the table half.)
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
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the Lens key's spoken sentence says magenta, the sliding
//          colour now, not amber.)
// PURPOSE: The caption and equation card, the fixed-height caption strip, the Continue button for guided pacing, the
//          Physics Lens key chip, and the highlight ring, on-table title chip and thin leader line that tie the words to
//          the ball they describe. On a phone held upright the words sit in CaptionStrip under the table (ShowpieceView
//          puts it above the controls); everywhere else the card sits in the side column (CaptionArea). The ring
//          position is the ball's place on the table, read from the recorded timeline and projected to the screen by
//          the 3D view each frame. Reads the model; writes to it only through nextBeat() (the Continue button).
//          The player's stroke lines are drawn by CaptionLeader too: it already holds the per-frame projection.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (a figure's unit prints in the shown language, UnitSymbol in
//          NumberStyle.swift: Russian м/с, Arabic م/ث, matching the sentences beside it.)
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
        let sentence = CaptionEngine.strokeSentence(aimError: stroke.aimError)
        // The sentences carry over with the stroke's own added as the last one (0.7.6): without them the phone card
        // could not page the strike caption, the one most often too long for its room.
        return Caption(id: c.id, time: c.time, title: c.title,
                       detail: c.detail + " " + sentence,
                       equation: c.equation, accent: c.accent, importance: c.importance, worked: c.worked,
                       sentences: (c.sentences.isEmpty ? [c.detail] : c.sentences) + [sentence],
                       figures: c.figures)
    }

    /// True when `caption` is the caption of one of this replay's headline beats (0.7.6, #60): its worked equation shows
    /// whether or not the hold is still on, so the equation line never drops out of a caption still on screen.
    func isHeadline(_ caption: Caption) -> Bool {
        holdingHeadline || pacePlan.beats.contains { $0.headline && $0.caption.id == caption.id }
    }

    /// The replay on screen has a headline beat: the phone's strip keeps the equation's line for the whole replay, so
    /// its room does not change from caption to caption.
    var hasHeadlineBeats: Bool { pacePlan.beats.contains { $0.headline } }
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
    /// The caption is a headline beat's (model.isHeadline): the equation shows with its numbers even with Show the
    /// maths off. (The phone's strip lays its own lines out since 0.7.6; this view is the side column's and the
    /// notebook-free card's.)
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
            // The physics figures (0.7.6), only when the caption has some: this card keeps its natural height.
            if let caption, !caption.figures.isEmpty {
                CaptionFigureRow(figures: caption.figures)
                    .padding(.vertical, 2)
            }
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
        caption.equationLine
    }

    /// What VoiceOver reads for a caption's words (0.7.6): the title, the detail, then each figure, label then value
    /// ("Launch speed, 5.1 metres per second."). The tiles themselves are hidden from VoiceOver, so nothing is read twice.
    static func spokenLabel(_ caption: Caption) -> String {
        let figures = caption.figures.map { "\($0.label), \($0.spoken)." }
        return (["\(caption.title). \(caption.detail)"] + figures).joined(separator: " ")
    }
}

extension Caption {
    /// The equation as shown: with the event's own numbers when the caption has them, else the bare formula. One place
    /// for the side card, the phone strip and the upright phone's explanation blurb (PhoneExplanation.swift).
    var equationLine: String { worked.isEmpty ? equation : worked }
}

// MARK: Physics figures (0.7.6)

extension CaptionFigure {
    /// The value with its unit said in words, for VoiceOver (a symbol such as "m/s" is not read as the unit's name).
    var spoken: String {
        switch unit {
        case "m/s": return "\(value) " + String(localized: "metres per second")
        case "%": return "\(value) " + String(localized: "percent")
        case "°": return "\(value) " + String(localized: "degrees")
        case "cm": return "\(value) " + String(localized: "centimetres")
        case "s": return "\(value) " + String(localized: "seconds")
        default: return text
        }
    }
}

/// A caption's figures as a row of compact tiles: always three equal columns, the empty ones blank, so the row is the
/// same height and every tile the same width whatever the caption holds. With no figures it is a blank band of exactly
/// the row's height, which is how the phone strip's sizer and layout twin reserve its place. Hidden from VoiceOver: the
/// card's own spoken label reads the figures after the detail.
struct CaptionFigureRow: View {
    let figures: [CaptionFigure]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<CaptionEngine.maxFigures, id: \.self) { i in
                if figures.indices.contains(i) {
                    FigureTile(figure: figures[i])
                } else {
                    // A blank tile of the same build keeps the column and the row's height.
                    FigureTile(figure: nil).hidden()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }
}

/// One figure: the number large in rounded monospaced digits with its unit smaller on the same baseline, both in the
/// colour of the Lens mark the number describes, the label small underneath, on a faint wash of that colour. The number
/// and unit are one Text (an AttributedString with two fonts) so they shrink together when a column is narrow, never
/// wrapping or cutting the number. nil draws the same build blank.
private struct FigureTile: View {
    let figure: CaptionFigure?
    @Environment(\.palette) private var palette

    private var reading: AttributedString {
        var number = AttributedString(figure?.value ?? " ")
        number.font = Theme.figure
        // The degree and percent signs hug their number, as in the figure's own text; other units sit after a no-break
        // space.
        let unit = figure?.unit ?? " "
        var tail = AttributedString(unit == "°" || unit == "%" ? unit : "\u{00A0}" + UnitSymbol.shown(unit))
        tail.font = Theme.figureUnit
        return number + tail
    }

    var body: some View {
        let color = figure.map { palette.color(for: $0.mark) } ?? .clear
        VStack(alignment: .leading, spacing: 1) {
            Text(reading)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(verbatim: figure?.label ?? " ")
                .font(Theme.figureLabel)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.14), in: .rect(cornerRadius: 10, style: .continuous))
    }
}

private extension View {
    /// Keeps room for exactly `lines` lines (blank or not) when given; natural height when nil.
    @ViewBuilder func reservedLines(_ lines: Int?) -> some View {
        if let lines { lineLimit(lines, reservesSpace: true) } else { self }
    }

    /// The caption card's glass and accent bar, shared by the side-column card and the strip under the table.
    func captionGlass(accent: Color, palette: Palette) -> some View {
        captionGlassPadding().captionGlassSurface(accent: accent)
    }

    /// The card's inner padding alone (the accent bar's room on the leading side), so the strip's hidden sizer and
    /// layout twin measure exactly the room the real card's words get (0.7.6).
    func captionGlassPadding() -> some View {
        self.padding(.leading, 4).padding(CaptionCard.padding)
    }

    /// The card's glass and accent bar alone, without the padding.
    func captionGlassSurface(accent: Color) -> some View {
        self
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
/// "Continue") so it does not squeeze the caption's words. Internal: the notebook's lower edge shows it too (0.7.5).
struct ContinueButton: View {
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
        .accessibilityLabel(CaptionContent.spokenLabel(caption))
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
    /// The part of the screen the side column's scroll area shows (StageSpace), or zero outside a scroll area. The card
    /// the leader is told about is only the part of it inside this, so a card scrolled out of sight neither hides rings
    /// nor draws a line off the edge of the column (0.7.6, #11).
    var viewport: CGRect = .zero

    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The card's whole frame (StageSpace), as last laid out.
    @State private var cardFrame: CGRect = .zero

    // While the Lens tips are up the card stands back, so the tips are the one thing to read (item 53).
    private var current: Caption? { model.holdForTips ? nil : model.displayedCaption() }
    private var showing: Bool { explanations && !model.menuOpen && model.lensOn && current != nil }

    /// Tells the leader where the visible part of the card is (nothing when it is scrolled away or not showing).
    private func publish() {
        guard showing, !cardFrame.isEmpty else { return }
        let visible = viewport.isEmpty ? cardFrame : cardFrame.intersection(viewport)
        let card = visible.isNull || visible.height < 1 ? .zero : visible
        if leader.card != card { leader.card = card }
    }

    var body: some View {
        // Read once per body: the caption is worked out from the clock.
        let current = self.current
        let showing = explanations && !model.menuOpen && model.lensOn && current != nil
        // A ZStack rather than a Group so the view (and the onChange below) exists even when no card shows.
        ZStack(alignment: .top) {
            if showing, let caption = current {
                VStack(alignment: .trailing, spacing: 8) {
                    FittingScroll(maxHeight: maxHeight) {
                        // The equation is decided by the caption, not by the hold, so it does not drop out of a caption
                        // still on screen when the hold ends (#60).
                        CaptionCard(caption: caption, headline: model.isHeadline(caption))
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: {
                                cardFrame = $0
                                publish()
                            }
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
        // The column scrolled or resized: the visible part of the card changed even if the card did not move in it.
        .onChange(of: viewport) { _, _ in publish() }
        // Turning the device to the upright layout removes this view without the onChange above firing.
        .onDisappear { leader.card = .zero }
    }
}

// MARK: Pages of a long caption (0.7.6)

/// How a caption is cut into pages for the phone's fixed room: whole sentences, packed greedily. Pure text work; the
/// heights come from hidden copies the strip measures (CaptionStrip), so every language and text size is measured, not
/// guessed.
enum CaptionPaging {
    /// The most sentences measured together as one page. A page of more than this many is never formed (the room holds
    /// four lines; eight sentences would be under half a line each).
    static let maxSpan = 8

    /// The caption's sentences, each with the space that followed it, so the chunks put back together are exactly the
    /// detail. Caption.sentences are the whole translated pieces the detail was joined from; a piece that holds two
    /// sentences ("... m/s. Its momentum is ...") is cut again at its sentence ends, so a page can end between them.
    static func chunks(of caption: Caption) -> [String] {
        let pieces = caption.sentences.isEmpty ? [caption.detail] : caption.sentences
        var out: [String] = []
        for (k, piece) in pieces.enumerated() {
            var parts = splitSentences(piece)
            // The detail joins its pieces with one space: it goes on the end of the piece's last sentence.
            if k < pieces.count - 1, !parts.isEmpty { parts[parts.count - 1] += " " }
            out += parts
        }
        return out
    }

    /// Sentence ends followed by a space ("." "!" "?", the Arabic question mark, the danda), and the full-width ones that
    /// need no space after them (Chinese and Japanese).
    private static let ends: Set<Character> = [".", "!", "?", "؟", "।"]
    private static let wideEnds: Set<Character> = ["。", "！", "？"]

    /// `s` cut after each sentence end, each part keeping the spaces after it, so the parts joined are `s` again. A
    /// point inside a number ("2.4") has no space after it and is not an end; a point followed by a lower-case word is
    /// an abbreviation carrying on, not an end.
    static func splitSentences(_ s: String) -> [String] {
        let chars = Array(s)
        var out: [String] = []
        var current = ""
        var i = 0
        while i < chars.count {
            let c = chars[i]
            current.append(c)
            i += 1
            if wideEnds.contains(c) {
                while i < chars.count, chars[i].isWhitespace { current.append(chars[i]); i += 1 }
                if i < chars.count { out.append(current); current = "" }
            } else if ends.contains(c), i < chars.count, chars[i].isWhitespace {
                var j = i
                while j < chars.count, chars[j].isWhitespace { j += 1 }
                if j < chars.count, !chars[j].isLowercase {
                    current.append(contentsOf: chars[i..<j])
                    i = j
                    out.append(current)
                    current = ""
                }
            }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }

    /// The words of chunks `r`, as one paragraph, without the trailing space.
    static func text(_ chunks: [String], _ r: Range<Int>) -> String {
        var s = chunks[r].joined()
        while let last = s.last, last.isWhitespace { s.removeLast() }
        return s
    }

    /// How much reading a page holds, for sharing the hold's reading time between pages: its word count, or its
    /// characters over six where words are not separated by spaces (Chinese, Japanese), whichever is more.
    static func weight(_ text: String) -> Double {
        let words = Double(text.split(whereSeparator: \.isWhitespace).count)
        return max(words, Double(text.count) / 6)
    }

    /// Every run of two to maxSpan chunks: the ones whose height decides where a page ends.
    static func spans(count n: Int) -> [Range<Int>] {
        var out: [Range<Int>] = []
        for s in 0..<max(0, n) {
            var e = s + 2
            while e <= min(n, s + maxSpan) { out.append(s..<e); e += 1 }
        }
        return out
    }

    /// Pages packed greedily: each page takes the next sentence, then as many more as still fit `room` points high.
    /// A single sentence taller than the room is a page of its own (it scrolls inside the room). Nil while a height it
    /// needs is not measured yet, so a half-measured caption is never reported as pages.
    static func pages(count n: Int, room: CGFloat, height: (Range<Int>) -> CGFloat?) -> [Range<Int>]? {
        guard n > 0 else { return nil }
        var out: [Range<Int>] = []
        var start = 0
        while start < n {
            var end = start + 1
            while end < n, end - start < maxSpan {
                guard let h = height(start..<(end + 1)) else { return nil }
                if h > room + 0.5 { break }
                end += 1
            }
            out.append(start..<end)
            start = end
        }
        return out
    }
}

/// The hidden copies the strip measures its pages with: every run of sentences that could be one page, laid out as the
/// page would be (same font, same width), each reporting its height (written only when it changes). Their words and
/// width stay the same while a caption is up, so SwiftUI keeps their layout from frame to frame.
private struct SpanMeasurer: View {
    let texts: [String]
    let width: CGFloat
    @Binding var heights: [String: CGFloat]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(texts, id: \.self) { t in
                Text(verbatim: t)
                    .font(Theme.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: width, alignment: .leading)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h in
                        if heights[t] != h { heights[t] = h }
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .hidden()
        .accessibilityHidden(true)
    }
}

/// Small dots beside the caption's title, one per page, the current one in the caption's colour. Each is a button that
/// shows its page (VoiceOver: "Page 2 of 3"). Always the same width, so the title beside them never re-wraps.
private struct PageDots: View {
    let count: Int
    let page: Int
    let accent: Color
    let onPage: (Int) -> Void
    @Environment(\.palette) private var palette

    /// The room the dots keep on the title line whenever the caption could have pages.
    static let width: CGFloat = 48

    var body: some View {
        HStack(spacing: 0) {
            if count > 1 {
                ForEach(0..<count, id: \.self) { i in
                    Button { onPage(i) } label: {
                        Circle()
                            .fill(i == page ? accent : palette.paper.opacity(0.35))
                            .frame(width: 6, height: 6)
                            // The touch area is the dot's share of the row, as tall as the title line.
                            .frame(width: Self.width / CGFloat(max(count, 3)), height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Page \(i + 1) of \(count)"))
                    .accessibilityAddTraits(i == page ? .isSelected : [])
                }
            }
        }
        .frame(width: Self.width)
    }
}

/// The strip's title line: the caption's title (up to two lines), the page dots' room when the caption could have
/// pages, and Continue at the trailing end. Shared by the real card, its hidden layout twin and the sizer, so all three
/// lay the line out identically.
private struct StripTitleRow: View {
    enum ContinueState { case hidden, waiting, live }

    let model: ShowpieceModel
    let title: String
    let dotsRoom: Bool
    var pageCount = 1
    var page = 0
    var accent: Color = .clear
    var onPage: (Int) -> Void = { _ in }
    /// Continue keeps its room in every state: gone (no guided replay), faded and disabled (guided, not holding), live.
    let continueState: ContinueState
    /// What VoiceOver reads for the whole card (title, detail, equation); nil in the hidden copies.
    var speech: (label: String, value: String)?
    /// The sizer keeps two title lines whatever the title: beside the dots and Continue the title column is narrow,
    /// and an ordinary English title ("The cue hands over its speed") already takes two lines there.
    var reserveTwoLines = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(verbatim: title)
                .font(Theme.heading)
                .lineLimit(2, reservesSpace: reserveTwoLines)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The card is read as one sentence here: the page text and equation are hidden from VoiceOver, so the
                // whole detail is read whatever page is on screen.
                .accessibilityLabel(speech?.label ?? title)
                .accessibilityValue(speech?.value ?? "")
                .accessibilityAddTraits(.updatesFrequently)
                .accessibilityHidden(speech == nil)
            if dotsRoom {
                PageDots(count: pageCount, page: page, accent: accent, onPage: onPage)
            }
            ContinueButton(model: model)
                .opacity(continueState == .live ? 1 : (continueState == .waiting ? 0.35 : 0))
                .disabled(continueState != .live)
                .accessibilityHidden(continueState == .hidden)
        }
    }
}

/// Phone held upright: the explanation in a room of FIXED height directly above the scrolling cards, pinned under the
/// table (ShowpieceView), so the camera frames the table above it and nothing in it ever covers the table (0.7.6). The
/// room: the worked-equation line (whenever Show the maths is on or the replay has headline beats), the title line with
/// Continue at its trailing end, the row of physics figures (0.7.6, always reserved, blank for a caption without
/// figures), and four lines of detail at the current text size, capped at a share of the screen.
/// A caption longer than its four lines is split into pages at sentence ends; the model shares the hold's reading time
/// between the pages, Continue turns them, and small dots beside the title show and pick them. A single sentence taller
/// than the room scrolls inside it. Between captions the last one stays; before the first the room is blank. While a
/// guided replay plays the glass fills the room so Continue never moves under the thumb; otherwise it hugs its words
/// at the bottom of the room. The glass's frame goes to leader.card, so the ring hides under it and the title chip
/// stays above it (#1).
struct CaptionStrip: View {
    let model: ShowpieceModel
    let leader: LeaderState
    /// Cap on the reserved height (the accessibility text sizes would otherwise reserve half the screen).
    let maxHeight: CGFloat

    @Environment(\.palette) private var palette
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @State private var shown: Caption?
    /// Height of the blank room at the current text size, measured from a hidden copy (StripSizer).
    @State private var reservedHeight: CGFloat = 0
    /// The size left for the detail's words in the room with this caption's title line, from the hidden layout twin.
    @State private var detailRoom: CGSize = .zero
    /// Measured heights of runs of sentences at the detail's width (SpanMeasurer), keyed by their words.
    @State private var spanHeights: [String: CGFloat] = [:]
    /// A page the player picked with a dot while no hold was running, for that caption only.
    @State private var loose: LoosePage?
    /// The glass frame this strip last gave the leader, so clearing never wipes a frame another card has written since.
    @State private var reportedCard: CGRect = .zero

    /// Detail lines in the room at any text size (the cap may take some back at the largest sizes).
    static let detailLines = 4
    /// The strip's worked equation: a smaller serif than the side card's, on one line, shrinking to fit (#60).
    static var equationFont: Font { .system(.callout, design: .serif, weight: .medium).italic() }

    private struct LoosePage: Equatable { let caption: Int; let page: Int }
    private struct PageReport: Equatable { let caption: Int; let weights: [Double]; let holding: Bool }

    /// One caption cut into pages for the room as it is now.
    private struct PageLayout {
        let chunks: [String]
        /// Nil until every height it needs is measured (or when the caption is one sentence): then the whole detail shows.
        let pages: [Range<Int>]?
        /// Every run of sentences the measurer must lay out, each once.
        let spanTexts: [String]
        var count: Int { pages?.count ?? 1 }
        func text(_ i: Int, detail: String) -> String {
            guard let pages, pages.indices.contains(i) else { return detail }
            return CaptionPaging.text(chunks, pages[i])
        }
        var weights: [Double] {
            guard let pages else { return [1] }
            return pages.map { CaptionPaging.weight(CaptionPaging.text(chunks, $0)) }
        }
    }

    private func pageLayout(for caption: Caption) -> PageLayout {
        let chunks = CaptionPaging.chunks(of: caption)
        guard chunks.count > 1 else { return PageLayout(chunks: chunks, pages: nil, spanTexts: []) }
        var seen = Set<String>()
        let spanTexts = CaptionPaging.spans(count: chunks.count).map { CaptionPaging.text(chunks, $0) }
            .filter { seen.insert($0).inserted }
        let room = detailRoom.height
        let pages = room > 0
            ? CaptionPaging.pages(count: chunks.count, room: room) { spanHeights[CaptionPaging.text(chunks, $0)] }
            : nil
        return PageLayout(chunks: chunks, pages: pages, spanTexts: spanTexts)
    }

    /// The page on screen: the model's while a hold runs with these pages, a page the player picked, the last page once
    /// a guided hold has let go (so the words do not jump back to the start after Continue), otherwise the first.
    private func pageIndex(for caption: Caption, count: Int, guided: Bool, holding: Bool) -> Int {
        guard count > 1 else { return 0 }
        if holding, model.holdPageCount > 1 { return min(model.holdPage, count - 1) }
        if let loose, loose.caption == caption.id { return min(loose.page, count - 1) }
        return guided && !holding ? count - 1 : 0
    }

    /// A tapped page dot: during a hold the model moves its reading clock to that page; otherwise the strip just shows it.
    private func turn(to i: Int, caption: Caption) {
        if model.holding, model.holdPageCount > 1 {
            model.showHoldPage(i)
        } else {
            loose = LoosePage(caption: caption.id, page: i)
        }
    }

    private func report(card frame: CGRect) {
        reportedCard = frame
        if leader.card != frame { leader.card = frame }
    }

    private func clearCard() {
        if leader.card == reportedCard { leader.card = .zero }
        reportedCard = .zero
    }

    var body: some View {
        // While the Lens tips are up the strip stands back (its room stays reserved, so the table does not move).
        let active = model.lensOn && !model.holdForTips ? model.displayedCaption() : nil
        let caption = model.holdForTips ? nil : (active ?? shown)
        // One decision for the equation's line, handed to the sizer, the twin and the card alike, so the room and the
        // card never disagree (#2, #60): kept for the whole replay when it has headline beats or the maths is on.
        let reserveEquation = maths || model.hasHeadlineBeats
        let showsEquation = maths || (caption.map { model.isHeadline($0) } ?? false)
        let accent = palette.color(for: caption?.accent ?? .impact)
        let room = min(reservedHeight, maxHeight)
        let guided = model.guided
        let holding = model.holding
        let layout = caption.map { pageLayout(for: $0) }
        let count = layout?.count ?? 1
        let index = caption.map { pageIndex(for: $0, count: count, guided: guided, holding: holding) } ?? 0
        // The dots' room depends only on the caption (more than one sentence), never on how it was paged, so the title's
        // width and the detail's room cannot change because of the pages they decide.
        let dotsRoom = (layout?.chunks.count ?? 0) > 1
        // A ride's held hit is not guided pacing but still waits on Continue (0.7.6 Ride hand-over).
        let continueState: StripTitleRow.ContinueState = holding ? .live : (guided ? .waiting : .hidden)
        ZStack(alignment: .bottom) {
            if let caption {
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        if reserveEquation {
                            // A blank line of the same font underneath keeps the line's height when the equation shrinks.
                            ZStack(alignment: .leading) {
                                Text(verbatim: " ").font(Self.equationFont).hidden()
                                Text(verbatim: showsEquation ? CaptionContent.equationLine(caption) : " ")
                                    .font(Self.equationFont)
                                    .foregroundStyle(accent)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            .accessibilityHidden(true)
                        }
                        StripTitleRow(model: model, title: caption.title, dotsRoom: dotsRoom, pageCount: count,
                                      page: index, accent: accent, onPage: { turn(to: $0, caption: caption) },
                                      continueState: continueState,
                                      speech: (label: CaptionContent.spokenLabel(caption),
                                               value: showsEquation ? CaptionContent.equationLine(caption) : ""))
                        // The physics figures: the row's place is in the room whether or not this caption has any, so
                        // the words below start at the same height on every caption and the measured pages fit.
                        CaptionFigureRow(figures: caption.figures)
                        // The page's words; a page that is one sentence too tall for the room scrolls inside it.
                        // Before the twin has measured, the room itself caps the words, so nothing grows over the table.
                        FittingScroll(maxHeight: detailRoom.height > 0 ? detailRoom.height
                                                 : (room > 0 ? room : .greatestFiniteMagnitude)) {
                            Text(verbatim: layout?.text(index, detail: caption.detail) ?? caption.detail)
                                .font(Theme.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentTransition(.opacity)
                        }
                        .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    // A new caption cross-fades inside the same glass.
                    .id(caption.id)
                    .transition(.opacity)
                }
                .captionGlassPadding()
                // Guided: the glass is the whole room, so Continue and the dots stay put from page to page.
                .frame(height: guided && room > 0 ? room : nil, alignment: .top)
                .captionGlassSurface(accent: accent)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { report(card: $0) }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: room, maxHeight: room, alignment: .bottom)
        // The hidden sizer: the blank room, every line reserved, never drawn or spoken.
        .background(alignment: .bottom) {
            StripSizer(model: model, reserveEquation: reserveEquation)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { reservedHeight = $0 }
        }
        // The hidden layout twin: this caption's equation and title lines in the room, measuring what is left for the
        // words (a two-line title leaves less).
        .background(alignment: .bottom) {
            if let caption {
                VStack(alignment: .leading, spacing: 3) {
                    if reserveEquation { Text(verbatim: " ").font(Self.equationFont).lineLimit(1) }
                    StripTitleRow(model: model, title: caption.title, dotsRoom: dotsRoom, continueState: .hidden)
                    CaptionFigureRow(figures: [])
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onGeometryChange(for: CGSize.self) { $0.size } action: { detailRoom = $0 }
                }
                .captionGlassPadding()
                .frame(height: room)
                .hidden()
                .accessibilityHidden(true)
            }
        }
        // The hidden copies the pages are measured with.
        .background(alignment: .topLeading) {
            if let layout, !layout.spanTexts.isEmpty, detailRoom.width > 0 {
                SpanMeasurer(texts: layout.spanTexts, width: detailRoom.width, heights: $spanHeights)
            }
        }
        .animation(.smooth(duration: 0.3), value: caption?.id)
        .animation(.smooth(duration: 0.25), value: holding)
        .animation(.smooth(duration: 0.25), value: guided)
        .animation(.easeOut(duration: 0.2), value: index)
        // The model learns how the caption was split (one weight per page), again whenever a hold starts on it, so the
        // hold's reading time is shared out between its pages and Continue turns them. Never from the body itself.
        .onChange(of: caption.map { PageReport(caption: $0.id, weights: layout?.weights ?? [1], holding: holding) },
                  initial: true) { _, pages in
            if let pages { model.setHoldPages(caption: pages.caption, weights: pages.weights) }
        }
        .onChange(of: caption?.id) { _, _ in
            loose = nil
            // Keep only the current caption's measurements once they pile up over many shots.
            if spanHeights.count > 200 {
                let keep = Set(layout?.spanTexts ?? [])
                spanHeights = spanHeights.filter { keep.contains($0.key) }
            }
        }
        .onChange(of: holding) { _, _ in loose = nil }
        .onChange(of: caption == nil) { _, none in if none { clearCard() } }
        .onDisappear { clearCard() }
        // Remember the newest caption so it stays up between beats instead of leaving a blank card.
        .onChange(of: active?.id) { _, _ in
            if model.lensOn, let now = model.displayedCaption() { shown = now }
        }
        .onAppear { if model.lensOn { shown = model.displayedCaption() } }
    }
}

/// The strip's blank room at the current text size: the equation line when it is reserved, two title lines beside
/// Continue's room, the figure row (0.7.6), and CaptionStrip.detailLines lines of detail, plus the card's padding. A one-line title leaves the
/// words a little more (the layout twin measures it). Hidden and never spoken.
private struct StripSizer: View {
    let model: ShowpieceModel
    let reserveEquation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if reserveEquation { Text(verbatim: " ").font(CaptionStrip.equationFont).lineLimit(1) }
            StripTitleRow(model: model, title: " ", dotsRoom: false, continueState: .hidden, reserveTwoLines: true)
            CaptionFigureRow(figures: [])
            Text(verbatim: " ")
                .font(Theme.body)
                .lineLimit(CaptionStrip.detailLines, reservesSpace: true)
        }
        .captionGlassPadding()
        .fixedSize(horizontal: false, vertical: true)
        .hidden()
        .accessibilityHidden(true)
    }
}

// MARK: Lens colour key

/// The Lens named and explained, as a small glass chip for the title row: the name "Physics Lens" as a heading, then
/// a magenta line for a ball sliding and a cyan line for a ball rolling. Whenever the blueprint view is up the player
/// can read what it is and what its colours mean. It replaces the baked 3D legend that used to take a band of height
/// off the table. Text follows Dynamic Type; when one row does not fit beside the back button the pieces stack, and
/// as a last resort the heading drops so the row is never squeezed. Spoken as one sentence (label unchanged).
struct LensLegendChip: View {
    @Environment(\.palette) private var palette
    /// With Differentiate Without Colour on, the Lens draws sliding dashed and rolling solid; the key shows the same.
    @Environment(\.accessibilityDifferentiateWithoutColor) private var withoutColour

    /// `dashed`: the sliding entry when shape must carry the meaning (Differentiate Without Colour).
    private func entry(_ name: LocalizedStringKey, _ color: Color, dashed: Bool = false) -> some View {
        LensKeyEntry(name: name, color: color, dashed: dashed)
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
            ? Text("Lens lines: dashed magenta lines show a ball sliding, solid cyan lines a ball rolling")
            : Text("Lens colours: magenta lines show a ball sliding, cyan lines a ball rolling"))
    }
}

/// One entry of the Lens colour key: a short glowing line like the trail it stands for (three dashes, or one solid
/// stroke), then its word. Shared by LensLegendChip (the title-row chip on the other layouts) and PhoneLensKeyBlurb (the
/// upright phone's one-line docked key), so both draw the key the same way.
struct LensKeyEntry: View {
    let name: LocalizedStringKey
    let color: Color
    /// The sliding entry when shape must carry the meaning (Differentiate Without Colour): dashed, as the trail is.
    var dashed = false

    var body: some View {
        HStack(spacing: 6) {
            LensTrailMark(color: color, dashed: dashed)
            Text(name).font(Theme.label).lineLimit(1)
        }
    }
}

/// A short glowing line like a Lens trail, 16 points long: one solid stroke, or three dashes when shape must carry the
/// meaning (Differentiate Without Colour, sliding). The Lens key's entries and the upright phone's Lens tips draw it.
struct LensTrailMark: View {
    let color: Color
    var dashed = false

    var body: some View {
        Group {
            if dashed {
                HStack(spacing: 2) { ForEach(0..<3, id: \.self) { _ in Capsule().fill(color).frame(width: 4, height: 3) } }
                    .frame(width: 16)
            } else {
                Capsule().fill(color).frame(width: 16, height: 3)
            }
        }
        .shadow(color: color.opacity(0.8), radius: 3)
        .accessibilityHidden(true)
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
    /// The current caption's lead figure (0.7.6), shown after the title in the chip when both fit on one line.
    var figure: CaptionFigure?
    var card: CGRect = .zero
    /// Bottom edge of the title row (StageSpace); the chip beside the ring stays below it.
    var topClear: CGFloat = 0
    /// The table's own frame (StageSpace), reported by ShowpieceView's stage on change. The chip beside the ring stays
    /// inside it, so on the open Duo it never crosses the hinge onto the words half. Zero until measured, then the
    /// whole overlay is used (0.7.5 layouts item 12).
    var stageRect: CGRect = .zero
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
            if figure != nil { figure = nil }
            return
        }
        if accent != caption.accent { accent = caption.accent }
        if title != caption.title { title = caption.title }
        let lead = caption.figures.first
        if figure != lead { figure = lead }
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
        // For a collision, follow the faster ball: that is the one the caption's words are about. Except a Throw caption
        // (CaptionEngine gives one exactly when throwFacts finds a throw): its words are about the ball that was at rest
        // and was dragged off the line of centres, so the ring and title go on that one (#8).
        let ball = CaptionEngine.throwFacts(event)?.object
            ?? event.balls.max { $0.velocityBefore.length < $1.velocityBefore.length }?.ball
        if event.kind != .pocket, let ball, ball < timeline.ballCount {
            let s = timeline.state(ball: ball, at: model.time)
            // At the ball's centre wherever it is: a flying ball's ring rides with it, not on the dot under it.
            if !s.pocketed { return frame.world(s.position, height: frame.ballRadius + Float(s.height)) }
        }
        return frame.world(event.point, height: frame.ballRadius)
    }
}

/// A ring around the ball, the caption's short title as a small glass chip beside it (not on the upright phone, see
/// showChip), and (only when the card sits beside the table, in the wide layout) a thin line back to the card. Decoration only: hidden from VoiceOver (the
/// card or strip already speaks the caption) and never takes touches, so aiming drags pass straight through.
struct CaptionLeader: View {
    let leader: LeaderState
    /// Draw the line to the card. Off on a phone held upright, where the card is a strip far below the table.
    var showLine = true
    /// Draw the caption's title chip beside the ring. Off on the upright phone (phone UI plan): the anchored explanation
    /// blurb carries the title there, and the chip repeated it and collided with it. The ring and the stroke lines stay.
    var showChip = true
    @Environment(\.palette) private var palette
    @Environment(\.layoutDirection) private var layoutDirection
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The chip's measured size, for keeping it on screen.
    @State private var chipSize: CGSize = .zero
    /// The chip title's width on one line, measured from a hidden copy, so the chip is only as wide as its words.
    @State private var titleWidth: CGFloat = 0
    /// The lead figure's width on one line (0.7.6), measured the same way, to decide whether it fits after the title.
    @State private var figureWidth: CGFloat = 0

    /// The ring's radius. Shared with the upright phone's explanation blurb, which keeps clear of the ring.
    static let ringRadius: CGFloat = 20
    private var ringRadius: CGFloat { Self.ringRadius }
    /// Gap between the ring and the chip, and the least distance the chip keeps from the screen's edges.
    private let gap: CGFloat = 8
    /// Space between the title and the lead figure in the chip.
    private let figureSpacing: CGFloat = 6

    /// The ring point, unless the ball is under the card: a ring drawn over the card would strike through its words.
    private var visibleRing: CGPoint? {
        guard let ring = leader.ring else { return nil }
        let card = leader.card
        if !card.isEmpty, card.insetBy(dx: -ringRadius, dy: -ringRadius).contains(ring) { return nil }
        return ring
    }

    /// "The table": the stage's frame (leader.stageRect), the whole screen on a phone, the table half on the open Duo
    /// and beside the notebook, so the chip never sits on the words; before it is measured, the whole overlay.
    private func stageBounds(_ size: CGSize) -> CGRect {
        leader.stageRect.isEmpty ? CGRect(origin: .zero, size: size) : leader.stageRect
    }

    /// Where the chip's centre goes (0.7.6, #1 and #59): to the right of the ring, else to its left, else above it, else
    /// below it, whichever first lies wholly on the table, under the title row, above a card that runs across the
    /// table below the ring (the phone's strip), clear of the card and clear of the ring itself. Beside the ring it is
    /// level with the ball, moved up or down only as far as the limits ask. If nothing fits (a tiny stage), the place
    /// that covers the least of the ring, held inside the limits. Never on top of the ball it names.
    private func chipCenter(ring: CGPoint, in size: CGSize) -> CGPoint {
        let w = chipSize.width, h = chipSize.height
        let bounds = stageBounds(size)
        let card = leader.card
        let top = max(bounds.minY + gap, leader.topClear + gap)
        var bottom = bounds.maxY - gap
        // A card across the table's width below the ring (the strip under an upright phone's table): the chip stays
        // above its top. A card beside the table (the side column) does not overlap it sideways and sets no limit.
        if !card.isEmpty, card.minX < bounds.maxX, card.maxX > bounds.minX, card.minY > ring.y {
            bottom = min(bottom, card.minY - gap)
        }
        let minX = bounds.minX + gap, maxX = bounds.maxX - gap
        func clampX(_ x: CGFloat) -> CGFloat { min(max(x, minX + w / 2), max(minX + w / 2, maxX - w / 2)) }
        func clampY(_ y: CGFloat) -> CGFloat { min(max(y, top + h / 2), max(top + h / 2, bottom - h / 2)) }
        func rect(_ c: CGPoint) -> CGRect { CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h) }
        let ringBox = CGRect(x: ring.x - ringRadius, y: ring.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2)
        func fits(_ c: CGPoint) -> Bool {
            let r = rect(c)
            return r.minX >= minX - 0.5 && r.maxX <= maxX + 0.5 && r.minY >= top - 0.5 && r.maxY <= bottom + 0.5
                && !r.intersects(ringBox) && (card.isEmpty || !card.intersects(r))
        }
        let level = clampY(ring.y)
        let right = CGPoint(x: ring.x + ringRadius + gap + w / 2, y: level)
        let left = CGPoint(x: ring.x - ringRadius - gap - w / 2, y: level)
        let above = CGPoint(x: clampX(ring.x), y: ring.y - ringRadius - gap - h / 2)
        let below = CGPoint(x: clampX(ring.x), y: ring.y + ringRadius + gap + h / 2)
        for c in [right, left, above, below] where fits(c) { return c }
        func covered(_ c: CGPoint) -> CGFloat {
            let i = rect(c).intersection(ringBox)
            return i.isNull ? 0 : i.width * i.height
        }
        let held = [above, below, right, left].map { CGPoint(x: clampX($0.x), y: clampY($0.y)) }
        return held.min { covered($0) < covered($1) } ?? above
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
                if showChip, explanations, let ring = visibleRing, let title = leader.title {
                    let color = palette.color(for: leader.accent)
                    // At most the stage's width less the edge gaps and the chip's own padding; a longer title (a long
                    // translation, a large text size) wraps onto a second line instead of running off the screen (#59).
                    let cap = max(40, stageBounds(geo.size).width - 2 * gap - 20)
                    let figure = leader.figure
                    let titleRoom = titleWidth.rounded(.up) + 1
                    // The lead figure (0.7.6) joins the title only when both fit on one line inside the cap; otherwise it
                    // is left off rather than wrapped, and the card's tile still shows it.
                    let withFigure = figure != nil && titleWidth > 0 && figureWidth > 0
                        && titleRoom + figureSpacing + figureWidth.rounded(.up) + 1 <= cap
                    HStack(spacing: figureSpacing) {
                        Text(verbatim: title)
                            .font(Theme.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            // Its own one-line width when that fits, the cap otherwise (measured below, so a short title
                            // keeps a short chip).
                            .frame(width: titleWidth > 0 ? min(titleRoom, cap) : nil)
                            .fixedSize(horizontal: false, vertical: true)
                        if withFigure, let figure {
                            // The same number as the card's tile, in the tile's colour.
                            Text(verbatim: figure.text)
                                .font(Theme.figureChip)
                                .foregroundStyle(palette.color(for: figure.mark))
                                .lineLimit(1)
                                .fixedSize()
                        }
                    }
                    .background {
                        Text(verbatim: title)
                            .font(Theme.label)
                            .lineLimit(1)
                            .fixedSize()
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { titleWidth = $0 }
                    }
                    .background {
                        // The figure measured on its own line, in the font the chip draws it with.
                        Text(verbatim: figure?.text ?? "")
                            .font(Theme.figureChip)
                            .lineLimit(1)
                            .fixedSize()
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { figureWidth = $0 }
                    }
                    // The words keep the player's reading direction (the figure follows the title in it); only the
                    // placement is in screen points.
                    .environment(\.layoutDirection, layoutDirection)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    // System glass; the caption's colour shows only as a faint tint, so it reads as native glass.
                    .glassEffect(.regular.tint(color.opacity(0.15)), in: .capsule)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { chipSize = $0 }
                    .position(chipCenter(ring: ring, in: geo.size))
                    // A new caption's chip fades in at its own ball rather than sliding across the table; an
                    // opacity fade is also what Reduce Motion asks for.
                    .id(title + (figure?.text ?? ""))
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
