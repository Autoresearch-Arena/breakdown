// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike: the placeholder line "Once the balls move..." is
//          removed; the notebook's slot shows the strike panel while aiming (StrikeSlot) and this view while the balls move.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 words, plans/25-Nov-2026-fewer-words-and-honest-claims-plan.md
//          Parts A and B. Fewer words, never moving fast: the lit row shows its heading, its lead figure as a chip and
//          the caption's short sentence (Caption.short); a tap on it opens the full text and the equation in place, a
//          second tap folds it, and a held beat waits while it is open. Dimmed rows show the heading and the chip only.
//          The lit row changes no faster than its short form can be read (a third of a second a word, never under two
//          seconds) while the replay runs; with Reduce Motion on the list never scrolls by itself. A break's burst of
//          hits is one row ("The break: 41 ball hits") that opens to every hit on a tap. Two captions in a row with the
//          same heading about the same ball are one row, the second a short line under the first. Before the first
//          shot the detailed surface card is drawn here only; NotebookNumbers leaves its own card out then (row 3).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts items 6 and 7, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md:
//          during the opening (and its hand-over) the story shows only its one line, not the surface card's friction
//          constants and rail percentage, so the first screen is a racked table and one instruction; the Lens colour
//          key left this header for its own row under the notebook's top bar (NotebookPanel), shown with the Lens up
//          whether Explanations is on or off.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (renamed NotebookStory, file NotebookStory.swift (it was DuoStory, DuoStory.swift): it is the notebook's
//          commentary on every big screen now, not only across a folding phone's hinge. On a big screen
//          (notebookRoomy) each sentence is set a size larger for reading at arm's length or at a desk; rows brighten
//          under a pointer; and the Mac and an iPad keyboard can step to the next or previous moment from the Playback
//          menu (MacChrome), which moves the lit row here like a tap.)
// PURPOSE: The notebook's live commentary: every explained moment of the shot on screen, in clock order, as a list
//          that fills the side panel. Each row is a caption with the time it happens: the lit one (the moment on the
//          table) shows its title, its lead figure and its short sentence, and opens to the whole sentence and the
//          equation on a tap; the rest are dimmed to their title and figure, and tapping one jumps the replay to that
//          moment. A burst of hits (a break) is folded into one row, and a caption that repeats the one above it about
//          the same ball is a line under it (StoryRows). The lit row also gives the thin leader line to the ball it
//          describes its starting rectangle (the same job CaptionArea does in the other layouts), so the line crosses
//          the fold from the words to the table. Captions are the ones the Physics Lens already uses (CaptionEngine),
//          read from the model; nothing here is worked out again, so every number on the panel is a number the solver
//          produced.
//          Follows the Explanations option: with it off the list is not drawn.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - display only. Wording is Captions.swift (the short form included), the clock and the jump are
//          ShowpieceModel, the beats PacePlan; the lit row is found by a probe view so the list itself redraws only when
//          the lit caption changes, not every frame. StoryRows only groups captions that already exist; it writes none.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct NotebookStory: View {
    let model: ShowpieceModel
    let leader: LeaderState
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @Environment(\.notebookRoomy) private var roomy
    /// The caption lit now: the one the table is showing, or the one just tapped.
    @State private var activeID: Int?
    /// 0.7.10 words: the caption whose full text is open (a tap on the lit row); nil shows every row's short form.
    @State private var openedID: Int?
    /// 0.7.10 words: the bursts opened to their every hit, by the burst row's key (StoryRow.burstKey).
    @State private var openBursts: Set<Int> = []
    /// 0.7.10 words: this list paused a held beat so an opened row could be read; folding it plays on.
    @State private var pausedForReading = false

    /// True once a shot with a real strike is on the timeline. Before the first shot (and on a trick shot that has not been
    /// watched) the recording is only the balls at rest, and its one caption would read "0.0 metres per second".
    static func hasShot(_ model: ShowpieceModel) -> Bool {
        for e in model.timeline.events where e.kind == .cueStrike {
            if let b = e.balls.first, b.velocityAfter.length > 0.05 { return true }
        }
        return false
    }

    /// 0.7.10 words: the least time, real seconds, a caption stays lit while the replay runs, so its short form can be
    /// read (plan Part B): a third of a second a word, never under two seconds. Words are counted by spaces; for
    /// languages written without them (Japanese, Chinese) about six characters stand for a word, as in PacePlan.
    static func minimumLit(_ caption: Caption) -> Double {
        let text = caption.readingText
        let words = Double(text.split(whereSeparator: \.isWhitespace).count)
        return max(2, max(words, Double(text.count) / 6) / 3)
    }

    private var captions: [Caption] { Self.hasShot(model) ? model.captions : [] }

    var body: some View {
        if explanations {
            VStack(alignment: .leading, spacing: 8) {
                header
                if captions.isEmpty {
                    // Before any shot: what is coming, and the surface and table it will be played on. While the opening
                    // runs (the first minute's break and hand-over) only the one line shows: the numbers wait until the
                    // player is playing, so nothing competes with the hand-over's one instruction.
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // 0.7.10 strike: the placeholder line is gone. While the player aims the notebook's slot
                            // shows the strike panel here instead (StrikeSlot, App/Strike/StrikePanel.swift); this empty
                            // page is left for the first minute and for "Your shot" closed before any shot.
                            // 0.7.10 words: only before a shot, so the surface card is drawn once, never twice.
                            if model.openingStage == .none && !Self.hasShot(model) {
                                NotebookSurfaceCard(model: model, detailed: true)
                            }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    list
                }
            }
            .frame(minHeight: 120, alignment: .top)
            .background { ActiveProbe(model: model, activeID: $activeID) }
            // With no lit row, or the Lens down, the leader must not keep an old rectangle: CaptionLeader hides the
            // ring of any ball inside it.
            .onChange(of: showsLeader) { _, now in if !now { leader.card = .zero } }
            // 0.7.10 words: a new lit moment starts on its short form; a pause made for reading ends with it.
            .onChange(of: activeID) { _, _ in
                openedID = nil
                resumeIfPaused()
            }
            // Continue or Play moves on, so an opened row folds and the reading pause is forgotten.
            .onChange(of: model.playing) { _, playing in
                if playing, openedID != nil {
                    pausedForReading = false
                    openedID = nil
                }
            }
            // A new recording: every burst folds again.
            .onChange(of: model.timelineVersion) { _, _ in openBursts = [] }
            .onDisappear {
                leader.card = .zero
                resumeIfPaused()
            }
        }
    }

    private var showsLeader: Bool { model.lensOn && activeID != nil }

    /// The list's heading. The Lens colour key is not here: it has its own row under the panel's top bar, so it shows
    /// with Explanations off too (NotebookPanel, 0.7.5).
    private var header: some View {
        Text("Step by step")
            .font(Theme.label)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var list: some View {
        // The rows, built once per redraw (the list redraws when the lit caption or the recording changes, not per frame).
        let beats = Set(model.pacePlan.beats.map(\.caption.id))
        let rows = StoryRows.make(captions, timeline: model.timeline, beats: beats, open: openBursts)
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(rows) { r in
                        row(r, lit: activeID.map { r.contains($0) } ?? false).id(r.id)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The rows above and below the visible ones fade out, so a row cut by the edge reads as "more", not as a glitch.
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.05),
                                       .init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .onChange(of: activeID) { _, id in
                // 0.7.10 words: with Reduce Motion on the list never scrolls by itself (plan Part B, step 4); the reader
                // scrolls it.
                guard let id, !reduceMotion, let target = rows.first(where: { $0.contains(id) }) else { return }
                withAnimation(.smooth(duration: 0.35)) { proxy.scrollTo(target.id, anchor: .center) }
            }
        }
    }

    // MARK: Opening a row (0.7.10 words)

    /// True when the caption has more to read than its short form.
    private static func opens(_ caption: Caption) -> Bool {
        !caption.short.isEmpty && caption.short != caption.detail
    }

    /// The lit row tapped: its full text opens in place, or folds again. Opened on a held beat, the replay waits while it
    /// is read (the hold's clock only runs while playing); folded, it plays on if this list paused it.
    private func toggleOpen(_ caption: Caption) {
        guard Self.opens(caption) else { return }
        let opening = openedID != caption.id
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { openedID = opening ? caption.id : nil }
        if opening {
            if model.holding, model.playing {
                model.playing = false
                pausedForReading = true
            }
        } else {
            resumeIfPaused()
        }
    }

    private func resumeIfPaused() {
        guard pausedForReading else { return }
        pausedForReading = false
        if model.holding { model.playing = true }
    }

    /// Lights a row's caption and jumps the replay to it (the tap the list always had).
    private func jump(to caption: Caption) {
        activeID = caption.id
        model.scrub(to: caption.time)
    }

    // MARK: A row

    @ViewBuilder
    private func row(_ r: StoryRow, lit: Bool) -> some View {
        if let burst = r.burst {
            burstRow(r, burst: burst, lit: lit)
        } else {
            captionRow(r, lit: lit)
        }
    }

    /// One caption (with any repeats folded under it as short lines). Lit: heading, chip, the lit caption's short
    /// sentence, and once opened its full text and equation. Dimmed: heading and chip only.
    private func captionRow(_ r: StoryRow, lit: Bool) -> some View {
        let lead = r.captions[0]
        // The caption whose words show: the lit one when the lit moment is one of this row's repeats.
        let shown = lit ? (r.captions.first { $0.id == activeID } ?? lead) : lead
        let opened = lit && openedID == shown.id
        let accent = palette.color(for: lead.accent)
        let headline = model.isHeadline(shown)
        return Button {
            if lit { toggleOpen(shown) } else { jump(to: lead) }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Capsule().fill(accent.opacity(lit ? 1 : 0.35)).frame(width: 3)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verbatim: lead.title)
                            .font(Theme.heading)
                            .foregroundStyle(lit ? Color.primary : Color.secondary)
                        if let figure = shown.figures.first { chip(figure, lit: lit) }
                        Spacer(minLength: 4)
                        Text(verbatim: Self.timeText(lead.time))
                            .font(Theme.number)
                            .foregroundStyle(.secondary)
                    }
                    // A repeat of the heading about the same ball: one short line each (plain text: a button inside the
                    // row's own button would not take its taps reliably; the replay lights it when it comes).
                    ForEach(r.captions.dropFirst(), id: \.id) { again in
                        repeatLine(again, lit: lit && again.id == activeID)
                    }
                    if lit {
                        Text(verbatim: opened ? shown.detail : shown.readingText)
                            // A size up on a big screen, read from further away than a phone; the folding phone keeps its own.
                            .font(roomy ? Theme.copy : Theme.body)
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        // The equation belongs to the full text; a headline beat's worked line shows as it always has.
                        if (opened && maths) || headline {
                            Text(verbatim: shown.equationLine)
                                .font(Theme.equation)
                                .foregroundStyle(accent)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(accent.opacity(lit ? 0.14 : 0), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // A plain row has no shape of its own, so under a pointer it gets a faint fill to show it can be clicked.
        .hoverHighlight(.fill(cornerRadius: 12))
        .background { leaderSource(lit: lit) }
        .accessibilityElement(children: .ignore)
        // The whole detail is read, folded or not; the figures after it, label then value.
        .accessibilityLabel(Text(verbatim: Self.spoken(shown)))
        .accessibilityValue(maths || headline ? shown.equationLine : "")
        .accessibilityHint(lit && Self.opens(shown)
                           ? Text(opened ? String(localized: "Shows less") : String(localized: "Shows more"))
                           : Text("Jumps the replay to this moment"))
        .accessibilityAddTraits(lit ? [.isButton, .isSelected] : .isButton)
    }

    /// What VoiceOver reads for a caption: the title, the whole detail, then each figure, label then value, as the
    /// caption card reads it (CaptionViews' spoken label, private there).
    private static func spoken(_ c: Caption) -> String {
        (["\(c.title). \(c.detail)"] + c.figures.map { "\($0.label), \($0.spoken)." }).joined(separator: " ")
    }

    /// "Again at 0.84 s: 5°": a caption with the row's heading about the same ball, folded under it (Part A row 2).
    private func repeatLine(_ again: Caption, lit: Bool) -> some View {
        let what = again.figures.first?.text ?? again.readingText
        return Text(String(localized: "Again at \(Self.timeText(again.time)): \(what)"))
            .font(Theme.label)
            .foregroundStyle(lit ? Color.primary : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A break's burst of hits as one row ("The break: 41 ball hits"); a tap opens it to every hit, and again folds it.
    private func burstRow(_ r: StoryRow, burst: StoryRow.Burst, lit: Bool) -> some View {
        let accent = palette.color(for: CaptionAccent.impact)
        let open = openBursts.contains(r.burstKey)
        let title = burst.isBreak ? String(localized: "The break: \(burst.hits) ball hits")
                                  : String(localized: "\(burst.hits) ball hits at once")
        return Button {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
                if open { openBursts.remove(r.burstKey) } else { openBursts.insert(r.burstKey) }
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Capsule().fill(accent.opacity(lit ? 1 : 0.35)).frame(width: 3)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: open ? "chevron.down" : "chevron.right")
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(verbatim: title)
                        .font(Theme.heading)
                        .foregroundStyle(lit ? Color.primary : Color.secondary)
                    Spacer(minLength: 4)
                    Text(verbatim: Self.timeText(r.captions[0].time))
                        .font(Theme.number)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(accent.opacity(lit ? 0.14 : 0), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight(.fill(cornerRadius: 12))
        .background { leaderSource(lit: lit) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityHint(open ? Text(String(localized: "Shows less")) : Text(String(localized: "Shows every hit")))
        .accessibilityAddTraits(lit ? [.isButton, .isSelected] : .isButton)
    }

    /// The figure the heading is about, as a small chip in its Lens mark's colour (0.7.10 words: the short form's one
    /// figure). Read by VoiceOver with the row's label, so it is hidden here.
    private func chip(_ figure: CaptionFigure, lit: Bool) -> some View {
        let colour = palette.color(for: figure.mark)
        return Text(verbatim: figure.text)
            .font(Theme.number)
            .foregroundStyle(colour.opacity(lit ? 1 : 0.7))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(colour.opacity(lit ? 0.16 : 0.08), in: .capsule)
            .accessibilityHidden(true)
    }

    /// The lit row is where the leader line starts, in the stage's own coordinates (the line crosses the fold).
    @ViewBuilder
    private func leaderSource(lit: Bool) -> some View {
        if lit {
            Color.clear.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
                if model.lensOn { leader.card = frame }
            }
        }
    }

    /// "0.42 sec": the moment's time on the shot's clock, in the player's units.
    private static func timeText(_ t: Double) -> String {
        Measurement(value: t, unit: UnitDuration.seconds)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.locale(AppLocale.numbers).precision(.fractionLength(2))).locale(AppLocale.numbers))
    }
}

// MARK: Rows (0.7.10 words)

/// One row of the commentary: a caption with any repeats folded under it, or a burst of hits folded into one line.
struct StoryRow: Identifiable, Equatable {
    /// A burst of ball hits close together in time (a break): how many there were, and whether it is the shot's first
    /// (so the row can call it the break).
    struct Burst: Equatable {
        let hits: Int
        let isBreak: Bool
    }

    /// The first caption's id; a burst's row is the negative of its key less one, so it never meets a caption's id
    /// when the burst is open and its hits are rows of their own beside it.
    let id: Int
    /// The captions the row stands for, in clock order: the lead and its repeats, or the burst's folded hits.
    let captions: [Caption]
    var burst: Burst? = nil
    /// A burst opened to its every hit: those rows draw the hits, so this one stands for none of them.
    var isOpen = false

    /// What opens a burst: its first folded hit's caption id.
    var burstKey: Int { captions.first?.id ?? id }

    /// True when caption `id` is drawn by this row (a closed burst stands for all its hits, an open one for none).
    func contains(_ captionID: Int) -> Bool {
        guard !(burst != nil && isOpen) else { return false }
        return captions.contains { $0.id == captionID }
    }
}

/// Groups the captions into the commentary's rows. Pure: a function of the captions, the recording (only to read each
/// caption's event: what kind it is and which ball it is about), the beats and which bursts are open.
enum StoryRows {
    /// Hits this close in time (shot-clock seconds) to the hit before belong to one burst: a rack opening up makes dozens
    /// within a few tenths of a second, while two hits of an ordinary shot are usually much further apart.
    static let burstGap = 0.3
    /// The fewest folded hits worth folding: fewer than this are simply listed.
    static let burstMinimum = 6

    static func make(_ captions: [Caption], timeline: Timeline, beats: Set<Int>, open: Set<Int>) -> [StoryRow] {
        func event(_ c: Caption) -> LensEvent? { timeline.events.indices.contains(c.id) ? timeline.events[c.id] : nil }
        func isHit(_ c: Caption) -> Bool { event(c)?.kind == .ballBall }

        // 1. Bursts: runs of ball hits, each within burstGap of the hit before (other moments in between do not break
        //    a run). The beats stay rows of their own, so a burst folds only the hits that are not beats, and is
        //    folded only when there are at least burstMinimum of those.
        var burstOf: [Int: Int] = [:]          // caption id -> burst index
        var bursts: [[Caption]] = []
        var lastHit = -Double.infinity
        for c in captions where isHit(c) {
            if bursts.isEmpty || c.time - lastHit > burstGap { bursts.append([]) }
            bursts[bursts.count - 1].append(c)
            burstOf[c.id] = bursts.count - 1
            lastHit = c.time
        }
        let firstHit = captions.first(where: isHit)?.id
        var rows: [StoryRow] = []
        var placed = Set<Int>()
        for c in captions {
            if let k = burstOf[c.id], !beats.contains(c.id) {
                let folded = bursts[k].filter { !beats.contains($0.id) }
                if folded.count >= burstMinimum {
                    let key = folded[0].id
                    if !placed.contains(k) {
                        placed.insert(k)
                        let isBreak = firstHit.map { first in bursts[k].contains { $0.id == first } } ?? false
                        rows.append(StoryRow(id: -key - 1, captions: folded,
                                             burst: StoryRow.Burst(hits: bursts[k].count, isBreak: isBreak),
                                             isOpen: open.contains(key)))
                    }
                    // Open: every hit is its own row under the burst's; closed, the burst's row stands for them.
                    if open.contains(key) { rows.append(StoryRow(id: c.id, captions: [c])) }
                    continue
                }
            }
            rows.append(StoryRow(id: c.id, captions: [c]))
        }

        // 2. Repeats (Part A row 2): a row whose caption has the same heading as the row above and is about the same
        //    ball is folded under it as a short line, not a new block. Captions.swift still makes one caption per event.
        func ball(_ c: Caption) -> Int? { event(c)?.balls.first?.ball }
        var merged: [StoryRow] = []
        for r in rows {
            if r.burst == nil, r.captions.count == 1, let last = merged.last, last.burst == nil,
               let lead = last.captions.first, let c = r.captions.first,
               lead.title == c.title, let b = ball(c), ball(lead) == b {
                merged[merged.count - 1] = StoryRow(id: last.id, captions: last.captions + [c])
            } else {
                merged.append(r)
            }
        }
        return merged
    }
}

/// Reads the clock for the list: re-evaluated every frame (it reads the model's time) but writes only when the caption
/// on the table changes, so the list and its rows are not redrawn sixty times a second. Before the first caption of a
/// replay nothing is lit; between captions the last one stays lit, as the strip under the table does on a phone.
/// 0.7.10 words: while the replay runs, a lit caption stays lit for at least NotebookStory.minimumLit of real time, so
/// no text changes faster than it can be read; a newer moment waits its turn (the latest one wins). Paused or scrubbed,
/// the lit row follows the clock at once.
private struct ActiveProbe: View {
    let model: ShowpieceModel
    @Binding var activeID: Int?
    /// When the lit caption last changed here, real time.
    @State private var litAt = Date.distantPast
    /// A newer moment waiting for the lit one's reading time to run out.
    @State private var pending: Int?

    var body: some View {
        let now = model.activeCaption()?.id
        let beforeFirst = model.captions.first.map { model.time < $0.time } ?? true
        return Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: now, initial: true) { _, id in
                if let id { offer(id) } else if beforeFirst { activeID = nil; pending = nil }
            }
            // The clock moved: a waiting moment is lit once the lit one has been up long enough.
            .onChange(of: model.time) { _, _ in
                if let p = pending, readyToChange { light(p) }
            }
            // Paused (or the replay ended): the waiting moment is lit now, so the list matches the still table.
            .onChange(of: model.playing) { _, playing in
                if !playing, let p = pending { light(p) }
            }
            .onChange(of: model.timelineVersion) { _, _ in
                activeID = nil
                pending = nil
                litAt = .distantPast
            }
    }

    /// A new moment on the table: lit at once when paused or when the lit one has been read, otherwise kept waiting.
    private func offer(_ id: Int) {
        guard id != activeID else { pending = nil; return }
        if !model.playing || readyToChange { light(id) } else { pending = id }
    }

    /// The lit caption has been up for its reading time (or nothing is lit, or it is not in this recording).
    private var readyToChange: Bool {
        guard let current = activeID, let c = model.captions.first(where: { $0.id == current }) else { return true }
        return Date().timeIntervalSince(litAt) >= NotebookStory.minimumLit(c)
    }

    private func light(_ id: Int) {
        activeID = id
        litAt = Date()
        pending = nil
    }
}
