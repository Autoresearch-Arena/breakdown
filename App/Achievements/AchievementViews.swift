// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 9's leftover note: the Lens is named by its one
//          name, "Physics Lens", where a player reads it.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 7, "The front door and the sheets", layout only:
//          the list is the kit's SheetPage (ground, serif title, cyan Done top right) with one panel group per section
//          under its section label and the rows drawn as the design's list rows (sunken strip, small corners: the
//          tick or the achievement's symbol leading, name in heading paper, the date or "Not earned yet" and the
//          sentence or hint in paper2, the count, the drawing or dots trailing, a paper3 chevron on earned rows); an
//          unearned row's name is paper3, never the system's grey. The detail is a pushed page on the ground with the
//          kit's primary button for "Watch it in the Lens"; the end note's button is the kit's secondary button and
//          the note's card is the panel surface. What the rows say and do is unchanged.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 10, "Achievements and sharing", proposed by
//          package 10 for this file's owner: a summary band heads the list (earned of total, what is new since the
//          last visit, the latest one earned); an unearned row is one line under its name, the real target
//          (AchievementWords.target, the judge's own thresholds), with "Not earned yet" for VoiceOver; every row opens
//          its page; an unearned page says how to earn it and offers "Try it" (AchievementTryIt), which closes the list
//          and sets up the table.)
// PURPOSE: Every view of 0.7.7's achievements (plans/23-Nov-2026-achievements-plan.md, new file 7):
//          - AchievementList, the page the menu opens (a sheet on phones, a page of the notebook on the open Duo, iPad and
//            Mac): five sections, every achievement always listed. An earned one shows its symbol lit, its name, the date,
//            its sentence and, on the trailing side, a small drawing of the player's own shot that earned it (solved
//            again off the main thread when the list first opens) or, for a collection, its progress dots; an unearned one
//            is dimmed, with its hint and, for a collection, "4 of 6". A dot marks what is new since the list was last
//            opened. Earned rows push AchievementDetail; unearned rows are plain text rows.
//          - AchievementDetail: the bigger drawing (or the collection's progress picture), the name, the sentence, the
//            date, and "Watch it in the Lens", which solves the kept shot, closes the page and hands the replay to the
//            model (ShowpieceModel.watchAchievementShot).
//          - AchievementProgressPicture: a collection's items, each ticked or empty (small dots in a row, a labelled grid
//            on the page).
//          - AchievementToast: the small note when one is earned, and the end note after an achievement's replay with its
//            one "Achievements" button. One view for every layout: a Blurb sized to its words on the upright phone
//            (never a card), a slim glass card in the sideways column, the notebook and the big window. It only draws what
//            the book says is showing: no timer and no announcement here, so a turn or a fold neither restarts nor
//            repeats a note.
//          Mounted by ShowpieceView (the upright phone's chrome, the side column, the big window's bottom stack, the page
//          sheet), NotebookPanel (its cards and its page) and TitleScreen (its own sheet).
// SRP/DRY check: Pass - checked TableList and TrickShotList (the list's NavigationStack, Close and the Mac's minimum
//          size are their pattern), TrickPathThumb (the drawing, reused), Blurb and BlurbButton (the upright phone's text,
//          reused), glassCard (the cards' glass) and HighlightCard (a card that replays a shot; this note never offers a
//          replay itself). Words come from AchievementWords; state from AchievementBook.
import SwiftUI

// MARK: The list

struct AchievementList: View {
    let model: ShowpieceModel
    let onClose: () -> Void
    /// The ids that were new when this visit opened the list: their dots show for this visit (the book has already
    /// marked them seen, so they go next time).
    @State private var newOnOpen: Set<String> = []
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages

    private var book: AchievementBook { model.achievements }

    /// The most recently earned achievement's name, for the summary band; nil before anything is earned.
    private var latestName: String? {
        Achievements.all
            .compactMap { a in book.earned(a.id).map { (a, $0.date) } }
            .max { $0.1 < $1.1 }?.0.name
    }

    var body: some View {
        // Read once per render: the progress the collections' rows count from.
        let progress = book.currentProgress()
        NavigationStack {
            SheetPage(title: AchievementWords.listTitle, onDone: onClose) {
                AchievementSummaryBand(earned: book.earnedCount, total: book.total, new: newOnOpen.count,
                                       latest: latestName)
                ForEach(AchievementGroup.allCases, id: \.self) { group in
                    SheetGroup(group.title) {
                        ForEach(Achievements.inGroup(group)) { a in
                            entry(a, progress: progress)
                        }
                    }
                }
            } footer: {
                Text(verbatim: AchievementWords.footer)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frontDoorSheetRoot()
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size (TrickShotList's rule).
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 560)
        #endif
        .onAppear { newOnOpen = book.listOpened() }
    }

    /// Every row pushes its page: an earned one its shot and "Watch it", an unearned one how to earn it and "Try it".
    @ViewBuilder
    private func entry(_ a: Achievement, progress: AchievementProgress) -> some View {
        let earned = book.earned(a.id)
        let row = AchievementRow(achievement: a, earned: earned, isNew: newOnOpen.contains(a.id),
                                 drawing: book.drawings[a.id], drawingPending: book.drawingPending(a.id),
                                 count: book.progress(of: a, in: progress), items: progress.items(a.progress),
                                 stacked: typeSize.isAccessibilitySize, opens: true)
        NavigationLink {
            AchievementDetail(model: model, achievement: a, onClose: onClose)
                .frontDoorPushedPage(title: a.name, onDone: onClose)
        } label: { row }
            .buttonStyle(.plain)
    }
}

/// One row of the list, in the design's list row form.
private struct AchievementRow: View {
    let achievement: Achievement
    let earned: AchievementRecord.Earned?
    let isNew: Bool
    let drawing: TrickPath?
    let drawingPending: Bool
    /// "4 of 6" for a collection; nil for a single thing.
    let count: (done: Int, total: Int)?
    /// The collection's items for its dots (empty for a single thing).
    let items: [AchievementProgressItem]
    /// Accessibility text sizes: the drawing goes above the words, full width.
    let stacked: Bool
    /// The row opens the achievement's page (earned rows): a chevron says so.
    let opens: Bool
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()
    /// The leading column and the drawing follow the reader's text size, as the kit's list row's do.
    @ScaledMetric(relativeTo: .headline) private var leadingWidth: CGFloat = 28
    @ScaledMetric(relativeTo: .headline) private var thumbWidth: CGFloat = 72

    init(achievement: Achievement, earned: AchievementRecord.Earned?, isNew: Bool, drawing: TrickPath?,
         drawingPending: Bool, count: (done: Int, total: Int)?, items: [AchievementProgressItem], stacked: Bool,
         opens: Bool) {
        self.achievement = achievement
        self.earned = earned
        self.isNew = isNew
        self.drawing = drawing
        self.drawingPending = drawingPending
        self.count = count
        self.items = items
        self.stacked = stacked
        self.opens = opens
    }

    var body: some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    trailing(fullWidth: true)
                    words
                }
            } else {
                HStack(alignment: .center, spacing: Theme.Space.sm) {
                    words
                    Spacer(minLength: 0)
                    trailing(fullWidth: false)
                    if opens {
                        Image(systemName: "chevron.right")
                            .font(Theme.caption.weight(.semibold))
                            .foregroundStyle(palette.paper3)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(.vertical, Theme.Space.sm)
        .padding(.horizontal, Theme.Space.md)
        .frame(maxWidth: .infinity, minHeight: Theme.Size.minHit, alignment: .leading)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
        .contentShape(Theme.Corner.tileShape)
        // One element: the name, then earned and when, then the sentence or the target, then the count; an unearned row
        // adds "Not earned yet" as its value. The drawing and the dots are hidden (TrickPathThumb already is).
        .accessibilityElement(children: .combine)
        .accessibilityValue(earned == nil ? Text(verbatim: AchievementWords.notEarned) : Text(verbatim: ""))
    }

    private var words: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
            // Leading: the achievement's own symbol, cyan once earned (the list row's "done" mark), paper3 before.
            Image(systemName: achievement.symbol)
                .font(Theme.heading)
                .fontWeight(.medium)
                .foregroundStyle(earned != nil ? palette.accent : palette.paper3)
                .frame(width: leadingWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    Text(verbatim: achievement.name)
                        .font(Theme.heading)
                        .foregroundStyle(earned != nil ? palette.paper : palette.paper3)
                        .fixedSize(horizontal: false, vertical: true)
                    if isNew {
                        // New since the list was last opened: a small cyan dot, the selected-state colour.
                        Circle().fill(palette.accent)
                            .frame(width: Theme.Space.xs, height: Theme.Space.xs)
                            .accessibilityHidden(true)
                    }
                }
                if let earned {
                    Text(verbatim: AchievementWords.earnedOn(earned.date))
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper2)
                    Text(verbatim: achievement.sentence)
                        .font(bodyFont)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // UI rethink package 10: one line, the real target. It wraps only at the accessibility sizes (the
                    // row stacks there); "Not earned yet" is said by VoiceOver (the row's value) and shown by the dim
                    // symbol and name.
                    Text(verbatim: AchievementWords.target(achievement))
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper2)
                        .lineLimit(stacked ? nil : 1)
                        .minimumScaleFactor(stacked ? 1 : 0.85)
                        .fixedSize(horizontal: false, vertical: stacked)
                }
                if let count {
                    Text(verbatim: AchievementWords.progress(done: count.done, total: count.total))
                        .font(Theme.inlineFigure)
                        .foregroundStyle(earned != nil ? palette.paper : palette.paper2)
                }
            }
        }
    }

    private var bodyFont: Font { device.current == .phone ? Theme.bodyCompact : Theme.body }

    /// The kept shot's drawing (or its room while it is solved), else a collection's dots, else nothing.
    @ViewBuilder
    private func trailing(fullWidth: Bool) -> some View {
        if earned?.shot != nil, let drawing {
            if fullWidth {
                TrickPathThumb(path: drawing).frame(maxWidth: .infinity)
            } else {
                TrickPathThumb(path: drawing)
                    .frame(width: thumbWidth, height: thumbWidth / 2)
                    .clipShape(Theme.Corner.tileShape)
            }
        } else if earned?.shot != nil, drawingPending {
            Color.clear
                .aspectRatio(2, contentMode: .fit)
                .frame(width: fullWidth ? nil : thumbWidth, height: fullWidth ? nil : thumbWidth / 2)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .accessibilityHidden(true)
        } else if !items.isEmpty {
            AchievementProgressPicture(items: items, compact: true)
                .frame(width: fullWidth ? nil : thumbWidth)
        }
    }
}

// MARK: One achievement's page

struct AchievementDetail: View {
    let model: ShowpieceModel
    let achievement: Achievement
    /// Closes the whole list (sets the page to nil).
    let onClose: () -> Void
    /// True while "Watch it in the Lens" solves the kept shot.
    @State private var solving = false
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()

    init(model: ShowpieceModel, achievement: Achievement, onClose: @escaping () -> Void) {
        self.model = model
        self.achievement = achievement
        self.onClose = onClose
    }

    private var book: AchievementBook { model.achievements }
    private var earned: AchievementRecord.Earned? { book.earned(achievement.id) }
    private var hasShot: Bool { earned?.shot != nil }
    private var bodyFont: Font { device.current == .phone ? Theme.bodyCompact : Theme.body }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                picture
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                    Image(systemName: achievement.symbol)
                        .font(Theme.title)
                        .fontWeight(.medium)
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                    Text(verbatim: achievement.name)
                        .font(Theme.title)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                if let earned {
                    Text(verbatim: achievement.sentence)
                        .font(bodyFont)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: AchievementWords.earnedOn(earned.date))
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper2)
                } else {
                    // UI rethink package 10: not earned yet. The real target, how to earn it, then "Try it".
                    Text(verbatim: AchievementWords.target(achievement))
                        .font(bodyFont)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: achievement.hint)
                        .font(bodyFont)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let place = AchievementTryIt.place(achievement, progress: book.currentProgress(), model: model) {
                        PrimaryButton(AchievementWords.tryIt, systemImage: "play", fullWidth: true) {
                            // Close the list first, as Watch it does, so nothing sits over the table it sets up.
                            onClose()
                            AchievementTryIt.start(place, model: model)
                        }
                        .accessibilityHint(Text(verbatim: AchievementWords.tryItHint))
                    }
                }
                if hasShot {
                    watchButton
                    if book.changedPhysics.contains(achievement.id) {
                        Text(verbatim: AchievementWords.playedAgain)
                            .font(bodyFont)
                            .foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if earned != nil {
                    Text(verbatim: AchievementWords.noSingleShot)
                        .font(bodyFont)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.Space.pageMargin(device.current))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Opened before the rows' solves reached this one (or straight after the end note opened the list): start them.
        .onAppear { if hasShot, book.drawings[achievement.id] == nil { book.startDrawings() } }
    }

    /// The kept shot drawn large at the table's own aspect, its room while it is solved, or a collection's picture.
    @ViewBuilder
    private var picture: some View {
        if hasShot {
            if let drawing = book.drawings[achievement.id] {
                TrickPathThumb(path: drawing)
                    .frame(maxWidth: .infinity)
                    .clipShape(Theme.Corner.tileShape)
            } else if book.drawingPending(achievement.id) {
                Color.clear
                    .aspectRatio(2, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay { ProgressView().tint(palette.paper2) }
                    .accessibilityHidden(true)
            }
        } else if achievement.progress != .none {
            AchievementProgressPicture(items: book.currentProgress().items(achievement.progress), compact: false)
                .kitPanel()
        }
    }

    /// "Watch it in the Physics Lens": solve first (a spinner on the button meanwhile, off the main thread), then close
    /// the page, and only then start the replay. The order matters: in the notebook the panel shows a set page whatever the menu
    /// is doing, so a page left set would hide the replay's words and controls.
    private var watchButton: some View {
        Button {
            watch()
        } label: {
            HStack(spacing: Theme.Space.xs) {
                if solving {
                    ProgressView().controlSize(.small).tint(palette.ground)
                } else {
                    Image(systemName: "eye").fontWeight(.medium)
                }
                Text("Watch it in the Physics Lens")
            }
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: true))
        .disabled(solving)
        .accessibilityHint(Text(verbatim: HighlightWords.watchHint))
    }

    private func watch() {
        guard !solving else { return }
        solving = true
        let id = achievement.id
        Task { @MainActor in
            let replay = await book.replayShot(id)
            solving = false
            guard let replay else { return }
            onClose()
            model.watchAchievementShot(replay.attempt, signature: replay.signature, id: id)
        }
    }
}

// MARK: The summary band (UI rethink package 10)

/// The list's first group: how many are earned of how many (the control figure), what is new since the last visit
/// (a cyan dot, the list's own "new" mark) and the latest one earned; before anything is earned, one line on what the
/// list is for. One element for VoiceOver.
private struct AchievementSummaryBand: View {
    let earned: Int
    let total: Int
    let new: Int
    let latest: String?
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
                Text(verbatim: AchievementWords.summaryFigure(earned: earned, total: total))
                    .font(Theme.controlFigure)
                    .foregroundStyle(palette.paper)
                Text(verbatim: AchievementWords.summaryEarned)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
            }
            if let line = AchievementWords.summaryNew(new) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    Circle().fill(palette.accent)
                        .frame(width: Theme.Space.xs, height: Theme.Space.xs)
                    Text(verbatim: line)
                        .font(Theme.label)
                        .foregroundStyle(palette.paper)
                }
            }
            if let latest {
                Text(verbatim: AchievementWords.summaryLatest(name: latest))
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(verbatim: AchievementWords.summaryNone)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: AchievementWords.summarySpoken(earned: earned, total: total, new: new,
                                                                         latest: latest)))
    }
}

// MARK: A collection's progress picture

struct AchievementProgressPicture: View {
    let items: [AchievementProgressItem]
    /// Small dots only (a list row); otherwise a grid of the items with their names (the page).
    let compact: Bool
    @Environment(\.palette) private var palette

    /// The dot's size in a row: two base steps.
    private static let dot: CGFloat = Theme.Space.xs

    var body: some View {
        if compact {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(Self.dot), spacing: Theme.Space.xxs), count: 6),
                      alignment: .leading, spacing: Theme.Space.xxs) {
                ForEach(items) { item in
                    Circle()
                        .fill(item.done ? palette.accent : Color.clear)
                        .overlay(Circle().stroke(item.done ? palette.accent : palette.paper3, lineWidth: Theme.Size.hairline))
                        .frame(width: Self.dot, height: Self.dot)
                }
            }
            .accessibilityHidden(true)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: Theme.Space.sm, alignment: .leading)],
                      alignment: .leading, spacing: Theme.Space.sm) {
                ForEach(items) { item in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                        Image(systemName: item.done ? "checkmark.circle" : (item.symbol ?? "circle"))
                            .fontWeight(.medium)
                            .foregroundStyle(item.done ? palette.accent : palette.paper3)
                            .accessibilityHidden(true)
                        Text(verbatim: item.name)
                            .font(Theme.body)
                            .foregroundStyle(item.done ? palette.paper : palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(item.done ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: The note

/// Where the note sits: a Blurb on the upright phone, a slim glass card everywhere else.
enum AchievementToastStyle { case blurb, card }

/// The small note when an achievement is earned, and the end note after an achievement's replay. Nothing (no height)
/// when neither shows.
struct AchievementToast: View {
    let model: ShowpieceModel
    let style: AchievementToastStyle
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var book: AchievementBook { model.achievements }

    /// What shows: the end note first, else the note.
    private enum Shown: Equatable {
        case earned(Achievement)
        case replayEnded(Achievement)

        var key: String {
            switch self {
            case .earned(let a): return "earned-\(a.id)"
            case .replayEnded(let a): return "ended-\(a.id)"
            }
        }
    }

    private var shown: Shown? {
        if let id = book.shownReplayEnd, let a = Achievements.achievement(id: id) { return .replayEnded(a) }
        if let id = book.shownToast, let a = Achievements.achievement(id: id) { return .earned(a) }
        return nil
    }

    var body: some View {
        let current = shown
        Group {
            if let current {
                // Upright, the blurb sits at the trailing edge under the docked blurbs (over the far rail's corner, never
                // the middle of the table). The frame is inside the condition, so nothing at all is laid out (no
                // stack spacing either) while no note shows.
                note(current)
                    .frame(maxWidth: .infinity, alignment: style == .blurb ? .trailing : .leading)
                    .id(current.key)
                    .transition(reduceMotion ? .opacity : Blurb.transition)
            }
        }
        // Its own animation: the parents' animations are keyed to other values.
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth, value: current?.key)
    }

    @ViewBuilder
    private func note(_ s: Shown) -> some View {
        switch s {
        case .earned(let a):
            switch style {
            case .blurb:
                Blurb(accessibilityText: AchievementWords.toastSpoken(name: a.name)) { earnedContent(a) }
            case .card:
                // UI rethink package 7: a card in the panel beside the table is the panel surface, not glass.
                earnedContent(a)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .kitPanel()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: AchievementWords.toastSpoken(name: a.name)))
            }
        case .replayEnded(let a):
            let sentence = AchievementWords.replayEnded(name: a.name)
            switch style {
            case .blurb:
                Blurb(accessibilityText: sentence,
                      buttons: [BlurbButton(AchievementWords.listTitle) { book.openList() }]) {
                    endedContent(a, sentence: sentence)
                }
            case .card:
                HStack(alignment: .center, spacing: Theme.Space.sm) {
                    endedContent(a, sentence: sentence)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: sentence))
                    Spacer(minLength: 0)
                    // A side offer, not the card's main action: the kit's secondary button.
                    SecondaryButton(AchievementWords.listTitle) { book.openList() }
                }
                .kitPanel()
            }
        }
    }

    /// The symbol in the accent colour, the caption "Achievement earned" and the name.
    private func earnedContent(_ a: Achievement) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.sm) {
            Image(systemName: a.symbol)
                .font(Theme.heading)
                .fontWeight(.medium)
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(verbatim: AchievementWords.earnedCaption)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                Text(verbatim: a.name)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The symbol and "That was your Bank shot."
    private func endedContent(_ a: Achievement, sentence: String) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.sm) {
            Image(systemName: a.symbol)
                .font(Theme.heading)
                .fontWeight(.medium)
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            Text(verbatim: sentence)
                .font(Theme.label)
                .foregroundStyle(palette.paper)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
