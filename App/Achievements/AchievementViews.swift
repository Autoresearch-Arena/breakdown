// Author: Claude Opus 5.5 High
// Date: 23-November-2026
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

    var body: some View {
        // Read once per render: the progress the collections' rows count from.
        let progress = book.currentProgress()
        NavigationStack {
            List {
                ForEach(AchievementGroup.allCases, id: \.self) { group in
                    Section {
                        ForEach(Achievements.inGroup(group)) { a in
                            entry(a, progress: progress)
                        }
                    } header: {
                        Text(verbatim: group.title)
                    } footer: {
                        if group == AchievementGroup.allCases.last {
                            Text(verbatim: AchievementWords.footer)
                        }
                    }
                }
            }
            .navigationTitle(Text(verbatim: AchievementWords.listTitle))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { onClose() } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size (TrickShotList's rule).
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 560)
        #endif
        .onAppear { newOnOpen = book.listOpened() }
    }

    /// An earned row pushes its page; an unearned row is plain text (not a disabled button), so VoiceOver reads it.
    @ViewBuilder
    private func entry(_ a: Achievement, progress: AchievementProgress) -> some View {
        let row = AchievementRow(achievement: a, earned: book.earned(a.id), isNew: newOnOpen.contains(a.id),
                                 drawing: book.drawings[a.id], drawingPending: book.drawingPending(a.id),
                                 count: book.progress(of: a, in: progress), items: progress.items(a.progress),
                                 stacked: typeSize.isAccessibilitySize)
        if book.earned(a.id) != nil {
            NavigationLink {
                AchievementDetail(model: model, achievement: a, onClose: onClose)
            } label: { row }
        } else {
            row
        }
    }
}

/// One row of the list.
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
    @Environment(\.palette) private var palette

    /// The drawing's width in a row.
    static let thumbWidth: CGFloat = 64

    var body: some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 8) {
                    trailing(fullWidth: true)
                    words
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    words
                    Spacer(minLength: 0)
                    trailing(fullWidth: false)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        // One element: the name, then earned and when (or not yet), then the sentence or the hint, then the count. The
        // drawing and the dots are hidden (TrickPathThumb already is).
        .accessibilityElement(children: .combine)
    }

    private var words: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: achievement.symbol)
                .font(.title3)
                .foregroundStyle(earned != nil ? palette.accent : Color.secondary)
                .frame(minWidth: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(verbatim: achievement.name)
                        .font(Theme.heading)
                        .foregroundStyle(earned != nil ? Color.primary : Color.secondary)
                    if isNew {
                        Circle().fill(palette.accent).frame(width: 7, height: 7).accessibilityHidden(true)
                    }
                }
                if let earned {
                    Text(verbatim: AchievementWords.earnedOn(earned.date))
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                    Text(verbatim: achievement.sentence)
                        .font(Theme.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(verbatim: AchievementWords.notEarned)
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                    Text(verbatim: achievement.hint)
                        .font(Theme.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let count {
                    Text(verbatim: AchievementWords.progress(done: count.done, total: count.total))
                        .font(Theme.label)
                        .monospacedDigit()
                        .foregroundStyle(earned != nil ? palette.accent : Color.secondary)
                }
            }
        }
    }

    /// The kept shot's drawing (or its room while it is solved), else a collection's dots, else nothing.
    @ViewBuilder
    private func trailing(fullWidth: Bool) -> some View {
        if earned?.shot != nil, let drawing {
            if fullWidth {
                TrickPathThumb(path: drawing).frame(maxWidth: .infinity)
            } else {
                TrickPathThumb(path: drawing).frame(width: Self.thumbWidth, height: Self.thumbWidth / 2)
            }
        } else if earned?.shot != nil, drawingPending {
            Color.clear
                .aspectRatio(2, contentMode: .fit)
                .frame(width: fullWidth ? nil : Self.thumbWidth, height: fullWidth ? nil : Self.thumbWidth / 2)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .accessibilityHidden(true)
        } else if !items.isEmpty {
            AchievementProgressPicture(items: items, compact: true)
                .frame(width: fullWidth ? nil : Self.thumbWidth)
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

    private var book: AchievementBook { model.achievements }
    private var earned: AchievementRecord.Earned? { book.earned(achievement.id) }
    private var hasShot: Bool { earned?.shot != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                picture
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: achievement.symbol)
                        .font(.title2)
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                    Text(verbatim: achievement.name)
                        .font(Theme.sectionTitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                Text(verbatim: achievement.sentence)
                    .font(Theme.copy)
                    .fixedSize(horizontal: false, vertical: true)
                if let earned {
                    Text(verbatim: AchievementWords.earnedOn(earned.date))
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                }
                if hasShot {
                    watchButton
                    if book.changedPhysics.contains(achievement.id) {
                        Text(verbatim: AchievementWords.playedAgain)
                            .font(Theme.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(verbatim: AchievementWords.noSingleShot)
                        .font(Theme.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(Text(verbatim: achievement.name))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // Opened before the rows' solves reached this one (or straight after the end note opened the list): start them.
        .onAppear { if hasShot, book.drawings[achievement.id] == nil { book.startDrawings() } }
    }

    /// The kept shot drawn large at the table's own aspect, its room while it is solved, or a collection's picture.
    @ViewBuilder
    private var picture: some View {
        if hasShot {
            if let drawing = book.drawings[achievement.id] {
                TrickPathThumb(path: drawing).frame(maxWidth: .infinity)
            } else if book.drawingPending(achievement.id) {
                Color.clear
                    .aspectRatio(2, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay { ProgressView() }
                    .accessibilityHidden(true)
            }
        } else if achievement.progress != .none {
            AchievementProgressPicture(items: book.currentProgress().items(achievement.progress), compact: false)
        }
    }

    /// "Watch it in the Lens": solve first (a spinner on the button meanwhile, off the main thread), then close the page,
    /// and only then start the replay. The order matters: in the notebook the panel shows a set page whatever the menu
    /// is doing, so a page left set would hide the replay's words and controls.
    private var watchButton: some View {
        Button {
            watch()
        } label: {
            HStack(spacing: 8) {
                if solving {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "eye")
                }
                Text("Watch it in the Lens")
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)
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

// MARK: A collection's progress picture

struct AchievementProgressPicture: View {
    let items: [AchievementProgressItem]
    /// Small dots only (a list row); otherwise a grid of the items with their names (the page).
    let compact: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        if compact {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(8), spacing: 4), count: 6), alignment: .leading,
                      spacing: 4) {
                ForEach(items) { item in
                    Circle()
                        .fill(item.done ? palette.accent : Color.clear)
                        .overlay(Circle().stroke(item.done ? palette.accent : palette.track, lineWidth: 1))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityHidden(true)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10, alignment: .leading)], alignment: .leading,
                      spacing: 10) {
                ForEach(items) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: item.done ? "checkmark.circle.fill" : (item.symbol ?? "circle"))
                            .foregroundStyle(item.done ? palette.accent : Color.secondary)
                            .accessibilityHidden(true)
                        Text(verbatim: item.name)
                            .font(Theme.body)
                            .foregroundStyle(item.done ? Color.primary : Color.secondary)
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
                earnedContent(a)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 18, padding: 12)
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
                HStack(alignment: .center, spacing: 12) {
                    endedContent(a, sentence: sentence)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: sentence))
                    Spacer(minLength: 0)
                    // A side offer, not the card's main button: a plain bordered button.
                    Button { book.openList() } label: {
                        Text(verbatim: AchievementWords.listTitle).font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
                .glassCard(cornerRadius: 18, padding: 12)
            }
        }
    }

    /// The symbol in the accent colour, the caption "Achievement earned" and the name.
    private func earnedContent(_ a: Achievement) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: a.symbol)
                .font(.title3)
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: AchievementWords.earnedCaption)
                    .font(Theme.label)
                    .foregroundStyle(.secondary)
                Text(verbatim: a.name)
                    .font(Theme.blurbTitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The symbol and "That was your Bank shot."
    private func endedContent(_ a: Achievement, sentence: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: a.symbol)
                .font(.title3)
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            Text(verbatim: sentence)
                .font(Theme.blurbTitle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
