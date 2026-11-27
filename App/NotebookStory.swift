// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 9, the Physics Lens notebook,
//          plans/26-Nov-2026-ui-rethink-plan.md and 26-Nov-2026-design-language.md:
//          - one current moment (ShowpieceModel.currentMoment, below) lights the row here, puts the bare figure beside
//            the ball on the table (LeaderState in CaptionViews) and marks the reel's tick (currentBeatIndex, for
//            App/Kit/ShotReel.swift). In a guided replay the row follows the moment at once (the model already holds
//            each beat for its reading time), so the three agree exactly; outside guided pacing the 0.7.10 reading
//            floor still keeps the row from changing faster than its short form can be read (ActiveProbe);
//          - repeats fold into one row: every caption with the same heading that is neither a paced beat nor a pot is
//            one quiet row, "The path bends, 7 times, up to 15°", which opens to each one on a tap (StoryRows.make
//            step 2). On purpose across the whole shot and across balls (the older fold took only neighbours about the
//            same ball, which left the break's bends as a column of rows): the folded row names no ball, and each
//            one's ball is in its own row once opened, or in the sentence when the moment lights it. A break's burst
//            of hits still folds as before;
//          - pots and paced beats are the bold headline rows (heading in paper); every other row is quiet (label size,
//            paper2), so the story reads down the bold rows;
//          - the kit and the tokens: the section label for "Step by step", a Chip with its meaning-colour dot for a
//            row's figure, the inline figure face for times in s (NumberStyle.time, never "sec"), a sunken lit row with
//            the meaning colour only on its leading bar, Theme.Space and Theme.Corner throughout.
//          Done when the opening break's notebook fits one screen without scrolling past repeats.)
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

// MARK: The one current moment (UI rethink package 9)

extension ShowpieceModel {
    /// The ONE current moment of the Physics Lens: the caption the table is showing now (activeCaption: the held beat,
    /// or the latest beat at or before the clock in a guided replay). Everything that marks "now" reads this, so they
    /// always agree: the notebook's lit row (NotebookStory), the bare figure and ring beside the ball (LeaderState in
    /// CaptionViews) and the reel's marked tick (currentBeatIndex). Whether each one is SHOWN (the Lens up, the menu
    /// shut, the tips not up) is each view's own business; which moment it is, is decided here only.
    func currentMoment() -> Caption? { activeCaption() }

    /// The index in pacePlan.beats of the current moment when it is one of the paced beats, else nil. For the shot reel
    /// (App/Kit/ShotReel.swift): its tick at pacePlan.beats[currentBeatIndex()] is the one to mark as current, the same
    /// moment the notebook's lit row and the figure on the table show.
    func currentBeatIndex() -> Int? {
        guard let id = currentMoment()?.id else { return nil }
        return pacePlan.beats.firstIndex { $0.caption.id == id }
    }
}

// MARK: The notebook's story

struct NotebookStory: View {
    let model: ShowpieceModel
    let leader: LeaderState
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @Environment(\.notebookRoomy) private var roomy
    /// The caption lit now: the current moment (ShowpieceModel.currentMoment), kept between moments, or the one tapped.
    @State private var activeID: Int?
    /// 0.7.10 words: the caption whose full text is open (a tap on the lit row); nil shows every row's short form.
    @State private var openedID: Int?
    /// The folded groups opened to their every member: bursts of hits and repeated headings, by the group's key
    /// (StoryRow.groupKey).
    @State private var openGroups: Set<Int> = []
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

    /// 0.7.10 words: the least time, real seconds, a caption stays lit while an unguided replay runs, so its short form
    /// can be read (plan Part B): a third of a second a word, never under two seconds. Words are counted by spaces; for
    /// languages written without them (Japanese, Chinese) about six characters stand for a word, as in PacePlan.
    static func minimumLit(_ caption: Caption) -> Double {
        let text = caption.readingText
        let words = Double(text.split(whereSeparator: \.isWhitespace).count)
        return max(2, max(words, Double(text.count) / 6) / 3)
    }

    private var captions: [Caption] { Self.hasShot(model) ? model.captions : [] }

    var body: some View {
        if explanations {
            VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                header
                if captions.isEmpty {
                    // Before any shot: what is coming, and the surface and table it will be played on. While the opening
                    // runs (the first minute's break and hand-over) only the one line shows: the numbers wait until the
                    // player is playing, so nothing competes with the hand-over's one instruction.
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Space.sm) {
                            // 0.7.10 strike: while the player aims the notebook's slot shows the strike panel instead
                            // (StrikeSlot, App/Strike/StrikePanel.swift); this empty page is left for the first minute
                            // and for "Your shot" closed before any shot. Only before a shot, so the surface card is
                            // drawn once, never twice.
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
            // A new recording: every folded group folds again.
            .onChange(of: model.timelineVersion) { _, _ in openGroups = [] }
            .onDisappear {
                leader.card = .zero
                resumeIfPaused()
            }
        }
    }

    private var showsLeader: Bool { model.lensOn && activeID != nil }

    /// The list's heading, in the kit's section style. The Lens colour key is not here: it has its own row under the
    /// panel's top bar, so it shows with Explanations off too (NotebookPanel, 0.7.5).
    private var header: some View {
        SectionLabel(String(localized: "Step by step"))
    }

    private var list: some View {
        // The rows, built once per redraw (the list redraws when the lit caption or the recording changes, not per frame).
        let beats = Set(model.pacePlan.beats.map(\.caption.id))
        let rows = StoryRows.make(captions, timeline: model.timeline, beats: beats, open: openGroups)
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    ForEach(rows) { r in
                        row(r, lit: activeID.map { r.contains($0) } ?? false).id(r.id)
                    }
                }
                .padding(.vertical, Theme.Space.xxs)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The rows above and below the visible ones fade out, so a row cut by the edge reads as "more", not as a glitch.
            // The stops are a mask's alpha, not colours on screen.
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .black, location: 0.05), // design-lint: allow mask alpha, not a colour shown
                                       .init(color: .black, location: 0.9), // design-lint: allow mask alpha, not a colour shown
                                       .init(color: .clear, location: 1)],
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
        withAnimation(reduceMotion ? nil : Theme.Motion.standard) { openedID = opening ? caption.id : nil }
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

    /// A folded group opened to its every member, or folded again.
    private func toggleGroup(_ key: Int) {
        withAnimation(reduceMotion ? nil : Theme.Motion.standard) {
            if openGroups.contains(key) { openGroups.remove(key) } else { openGroups.insert(key) }
        }
    }

    // MARK: A row

    @ViewBuilder
    private func row(_ r: StoryRow, lit: Bool) -> some View {
        if let burst = r.burst {
            groupRow(r, title: burst.isBreak ? String(localized: "The break: \(burst.hits) ball hits")
                                             : String(localized: "\(burst.hits) ball hits at once"),
                     accent: palette.contact, lit: lit, hint: String(localized: "Shows every hit"))
        } else if let fold = r.fold {
            foldRow(r, fold: fold, lit: lit)
        } else {
            captionRow(r, lit: lit)
        }
    }

    /// One caption. Lit: heading, figure chip, the short sentence, and once opened its full text and equation. Dimmed:
    /// heading and chip only. A pot or a paced beat is a headline row (bold heading in paper); every other caption is a
    /// quiet row (label size, paper2), so the story reads down the bold rows.
    private func captionRow(_ r: StoryRow, lit: Bool) -> some View {
        let shown = r.captions[0]
        let opened = lit && openedID == shown.id
        let accent = palette.color(for: shown.accent)
        let headline = model.isHeadline(shown)
        return Button {
            if lit { toggleOpen(shown) } else { jump(to: shown) }
        } label: {
            rowFrame(accent: accent, lit: lit) {
                titleLine(Text(verbatim: shown.title), figure: shown.figures.first, time: shown.time,
                          bold: r.isHeadline, lit: lit)
                if lit { litWords(shown, opened: opened, headline: headline) }
            }
        }
        .buttonStyle(.plain)
        // A plain row has no shape of its own, so under a pointer it gets a faint fill to show it can be clicked.
        .hoverHighlight(.fill(cornerRadius: Theme.Corner.small))
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

    /// A heading repeated through the shot, folded into one quiet row: "The path bends, 7 times, up to 15°". A tap opens
    /// it to each one (their own rows below it) and again folds it. When the moment on the table is one of them the row
    /// lights with that one's figure and short sentence; its full text is a tap away on its own row once the group is
    /// open (an open group's members light instead of it), so a tap here always means the group.
    private func foldRow(_ r: StoryRow, fold: StoryRow.Fold, lit: Bool) -> some View {
        let lead = r.captions[0]
        let shown = lit ? (r.captions.first { $0.id == activeID } ?? lead) : lead
        let accent = palette.color(for: lead.accent)
        let open = openGroups.contains(r.groupKey)
        let summary = Self.foldSummary(lead.title, fold: fold)
        return Button { toggleGroup(r.groupKey) } label: {
            rowFrame(accent: accent, lit: lit) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    disclosure(open)
                    titleLine(Text(verbatim: summary), figure: lit ? shown.figures.first : nil, time: lead.time,
                              bold: false, lit: lit)
                }
                if lit { litWords(shown, opened: false, headline: model.isHeadline(shown)) }
            }
        }
        .buttonStyle(.plain)
        .hoverHighlight(.fill(cornerRadius: Theme.Corner.small))
        .background { leaderSource(lit: lit) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: lit ? summary + ". " + Self.spoken(shown) : summary))
        .accessibilityHint(Text(open ? String(localized: "Shows less") : String(localized: "Shows each one")))
        .accessibilityAddTraits(lit ? [.isButton, .isSelected] : .isButton)
    }

    /// "The path bends, 7 times, up to 15°": the heading, how many, and the largest of their lead figures when they
    /// share one unit; without a figure, the heading and how many.
    static func foldSummary(_ title: String, fold: StoryRow.Fold) -> String {
        if let most = fold.most {
            return String(localized: "\(title), \(fold.count) times, up to \(most.text)",
                          comment: "A heading repeated through a shot, folded into one row of the Physics Lens notebook: the heading, how many times, and the largest figure (\"The path bends, 7 times, up to 15°\").")
        }
        return String(localized: "\(title), \(fold.count) times",
                      comment: "A heading repeated through a shot, folded into one row of the Physics Lens notebook, without a figure (\"Wedged and settled, 2 times\").")
    }

    /// A break's burst of hits as one quiet row ("The break: 41 ball hits"); a tap opens it to every hit, and again
    /// folds it.
    private func groupRow(_ r: StoryRow, title: String, accent: Color, lit: Bool, hint: String) -> some View {
        let open = openGroups.contains(r.groupKey)
        return Button { toggleGroup(r.groupKey) } label: {
            rowFrame(accent: accent, lit: lit) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    disclosure(open)
                    titleLine(Text(verbatim: title), figure: nil, time: r.captions[0].time, bold: false, lit: lit)
                }
            }
        }
        .buttonStyle(.plain)
        .hoverHighlight(.fill(cornerRadius: Theme.Corner.small))
        .background { leaderSource(lit: lit) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityHint(open ? Text(String(localized: "Shows less")) : Text(hint))
        .accessibilityAddTraits(lit ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Row parts

    /// A row's frame: a 3 point leading bar in the moment's meaning colour (the only colour on the row), the content,
    /// and, when lit, the sunken strip behind it. The bar is faint on a dimmed row.
    private func rowFrame<Content: View>(accent: Color, lit: Bool, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.sm) {
            Capsule().fill(accent.opacity(lit ? 1 : 0.35)).frame(width: Theme.Space.chipDot)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Theme.Space.xs)
        .padding(.horizontal, Theme.Space.xs)
        .background(lit ? palette.panelSunken : .clear, in: Theme.Corner.tileShape)
        .contentShape(Rectangle())
    }

    /// The heading line: the title (bold paper on a headline row, label-size paper2 on a quiet one, paper when lit),
    /// the figure as a chip with its meaning-colour dot, and the time in s at the end.
    private func titleLine(_ title: Text, figure: CaptionFigure?, time: Double, bold: Bool, lit: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            title
                .font(bold ? Theme.heading : Theme.label)
                .foregroundStyle(bold || lit ? palette.paper : palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
            if let figure {
                Chip(value: figure.text, dot: palette.color(for: figure.mark))
                    .opacity(lit ? 1 : 0.8)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: Theme.Space.xxs)
            KitFigure(NumberStyle.time(seconds: time), size: .inline, color: palette.paper2)
                .fixedSize()
                .accessibilityHidden(true)
        }
    }

    /// The lit row's words: its short sentence (the whole detail once opened) and, opened with Show the maths on or on
    /// a headline beat, the worked equation.
    @ViewBuilder
    private func litWords(_ shown: Caption, opened: Bool, headline: Bool) -> some View {
        Text(verbatim: opened ? shown.detail : shown.readingText)
            // A size up on a big screen, read from further away than a phone; the folding phone's panel keeps the
            // upright phone's body size.
            .font(roomy ? Theme.body : Theme.bodyCompact)
            .foregroundStyle(palette.paper)
            .fixedSize(horizontal: false, vertical: true)
        // The equation belongs to the full text; a headline beat's worked line shows as it always has.
        if (opened && maths) || headline {
            Text(verbatim: shown.equationLine)
                .font(Theme.equation)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The chevron of a folded group: right when folded, down when open.
    private func disclosure(_ open: Bool) -> some View {
        Image(systemName: open ? "chevron.down" : "chevron.right")
            .font(Theme.caption.weight(.semibold))
            .foregroundStyle(palette.paper3)
            .accessibilityHidden(true)
    }

    /// What VoiceOver reads for a caption: the title, the whole detail, then each figure, label then value, as the
    /// caption card reads it (CaptionViews' spoken label, private there).
    private static func spoken(_ c: Caption) -> String {
        (["\(c.title). \(c.detail)"] + c.figures.map { "\($0.label), \($0.spoken)." }).joined(separator: " ")
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
}

// MARK: Rows

/// One row of the commentary: a caption, a burst of hits folded into one line, or a heading repeated through the shot
/// folded into one line.
struct StoryRow: Identifiable, Equatable {
    /// A burst of ball hits close together in time (a break): how many there were, and whether it is the shot's first
    /// (so the row can call it the break).
    struct Burst: Equatable {
        let hits: Int
        let isBreak: Bool
    }

    /// A heading repeated through the shot (UI rethink package 9): how many captions carry it, and the largest of their
    /// lead figures when they all share one unit (nil when they have none, or mixed units).
    struct Fold: Equatable {
        let count: Int
        let most: CaptionFigure?
    }

    /// A single caption's row is its caption's id; a folded group's row is the negative of its key less one, so it
    /// never meets a caption's id when the group is open and its members are rows of their own beside it.
    let id: Int
    /// The captions the row stands for, in clock order: one caption, or the group's folded members.
    let captions: [Caption]
    var burst: Burst? = nil
    var fold: Fold? = nil
    /// A folded group opened to its every member: those rows draw the members, so this one stands for none of them.
    var isOpen = false
    /// A pot or a paced beat (UI rethink package 9): drawn as a bold headline row. Never a folded group.
    var isHeadline = false

    /// What opens a folded group: its first member's caption id.
    var groupKey: Int { captions.first?.id ?? id }

    /// True when caption `id` is drawn by this row (a closed group stands for all its members, an open one for none).
    func contains(_ captionID: Int) -> Bool {
        guard !((burst != nil || fold != nil) && isOpen) else { return false }
        return captions.contains { $0.id == captionID }
    }
}

/// Groups the captions into the commentary's rows. Pure: a function of the captions, the recording (only to read each
/// caption's event: what kind it is), the beats and which groups are open.
enum StoryRows {
    /// Hits this close in time (shot-clock seconds) to the hit before belong to one burst: a rack opening up makes dozens
    /// within a few tenths of a second, while two hits of an ordinary shot are usually much further apart.
    static let burstGap = 0.3
    /// The fewest folded hits worth folding as a burst: fewer than this are simply listed.
    static let burstMinimum = 6
    /// The fewest captions with one heading worth folding into one row: two (a heading said twice is a repeat).
    static let foldMinimum = 2

    static func make(_ captions: [Caption], timeline: Timeline, beats: Set<Int>, open: Set<Int>) -> [StoryRow] {
        func event(_ c: Caption) -> LensEvent? { timeline.events.indices.contains(c.id) ? timeline.events[c.id] : nil }
        func isHit(_ c: Caption) -> Bool { event(c)?.kind == .ballBall }
        func isPot(_ c: Caption) -> Bool { event(c)?.kind == .pocket }
        // Headline rows: what the replay stops on, and every ball that drops. They are never folded.
        func isHeadline(_ c: Caption) -> Bool { beats.contains(c.id) || isPot(c) }

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
        var inBurst = Set<Int>()
        var burstRows: [Int: StoryRow] = [:]   // burst index -> its row, placed at its first folded hit
        for (k, members) in bursts.enumerated() {
            let folded = members.filter { !beats.contains($0.id) }
            guard folded.count >= burstMinimum else { continue }
            let key = folded[0].id
            let isBreak = firstHit.map { first in members.contains { $0.id == first } } ?? false
            burstRows[k] = StoryRow(id: -key - 1, captions: folded,
                                    burst: StoryRow.Burst(hits: members.count, isBreak: isBreak),
                                    isOpen: open.contains(key))
            inBurst.formUnion(folded.map(\.id))
        }

        // 2. Repeats (UI rethink package 9): every caption not in a burst and not a headline row, grouped by its
        //    heading; a heading carried by foldMinimum or more is one row at its first member's place. Captions.swift
        //    still makes one caption per event; this only groups them.
        var byTitle: [String: [Caption]] = [:]
        for c in captions where !inBurst.contains(c.id) && !isHeadline(c) { byTitle[c.title, default: []].append(c) }
        let folds = byTitle.filter { $0.value.count >= foldMinimum }
        var foldOf: [Int: String] = [:]
        for (title, members) in folds { for c in members { foldOf[c.id] = title } }

        // 3. The rows, in clock order of each row's first caption; an open group's members follow its row.
        var rows: [StoryRow] = []
        var placedBursts = Set<Int>(), placedFolds = Set<String>()
        for c in captions {
            if inBurst.contains(c.id), let k = burstOf[c.id], let burstRow = burstRows[k] {
                if !placedBursts.contains(k) {
                    placedBursts.insert(k)
                    rows.append(burstRow)
                    if burstRow.isOpen { rows += burstRow.captions.map { StoryRow(id: $0.id, captions: [$0]) } }
                }
                continue
            }
            if let title = foldOf[c.id], let members = folds[title] {
                if !placedFolds.contains(title) {
                    placedFolds.insert(title)
                    let key = members[0].id
                    let isOpen = open.contains(key)
                    rows.append(StoryRow(id: -key - 1, captions: members,
                                         fold: StoryRow.Fold(count: members.count, most: largest(members)),
                                         isOpen: isOpen))
                    if isOpen { rows += members.map { StoryRow(id: $0.id, captions: [$0]) } }
                }
                continue
            }
            rows.append(StoryRow(id: c.id, captions: [c], isHeadline: isHeadline(c)))
        }
        return rows
    }

    /// The largest lead figure of a folded heading's captions, when every one that has a lead figure shares its unit
    /// (the path bends in °, the rail's speed in m/s); nil when none has one or the units differ.
    static func largest(_ members: [Caption]) -> CaptionFigure? {
        let leads = members.compactMap { $0.figures.first }
        guard let unit = leads.first?.unit, leads.allSatisfy({ $0.unit == unit }) else { return nil }
        return leads.max { abs($0.amount) < abs($1.amount) }
    }
}

/// Reads the clock for the list: re-evaluated every frame (it reads the model's time through currentMoment) but writes
/// only when the lit caption changes, so the list and its rows are not redrawn sixty times a second. UI rethink
/// package 9: the lit row follows the one current moment (ShowpieceModel.currentMoment), the one the figure on the
/// table and the reel's marked tick show. In a guided replay that moment is a paced beat the model already holds for
/// its reading time, so the row follows it at once and the three agree exactly. Outside guided pacing (a speed the
/// player picked, Ride, the opening's own stages) the moments can come faster than they can be read, so there, while
/// the replay runs, a lit caption stays lit for at least NotebookStory.minimumLit of real time and a newer moment waits
/// its turn (0.7.10 words, plan Part B: no text changes faster than it can be read; the latest one wins). Paused or
/// scrubbed, the lit row follows the moment at once. Before the first caption of a replay nothing is lit; between
/// moments the last one stays lit.
private struct ActiveProbe: View {
    let model: ShowpieceModel
    @Binding var activeID: Int?
    /// When the lit caption last changed here, real time.
    @State private var litAt = Date.distantPast
    /// A newer moment waiting for the lit one's reading time to run out (outside guided pacing only).
    @State private var pending: Int?

    var body: some View {
        let now = model.currentMoment()?.id
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

    /// A new current moment: lit at once in a guided replay, when paused, or when the lit one has been read; otherwise
    /// kept waiting.
    private func offer(_ id: Int) {
        guard id != activeID else { pending = nil; return }
        if model.guided || !model.playing || readyToChange { light(id) } else { pending = id }
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
