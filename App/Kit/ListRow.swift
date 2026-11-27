// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3 review: the leading mark's test is a pattern
//          match, so the case named none is never taken for Optional's none.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-design-language.md, "List row").
//          ListRow is the one row of every list (trick shots, behind the 8-ball, lessons, drills; package 5 fills them
//          in): a leading mark (the item's number in paper2, a cyan tick once done, or a pocket-gold medal), then the
//          title (heading, paper) and one line (body, paper2: Body on big screens, Subheadline on the upright phone),
//          then a meta line holding the difficulty slot (the caller passes DifficultyDots, which another builder owns)
//          and the best result (caption, paper2); trailing, a small picture slot (the start layout's table drawing,
//          clipped to small corners) and a chevron in paper3. The row text is never tinted: only the leading tick takes
//          cyan and the medal pocket gold, both because they mean something.
//          The row sits on a sunken strip (panelSunken, small corners) at least 44 points tall. It is not a button: the
//          caller wraps it in a Button or NavigationLink, which supplies the trait; VoiceOver reads the row as one
//          element (number or state, title, line, difficulty, best).
//          Slots: ListRow<Difficulty, Picture>; inits without a difficulty or a picture are provided (EmptyView).
//          Read by the later packages' lists (TrickShotViews, EightBallViews, LessonViews, DailyMenuRow).
// SRP/DRY check: Pass - checked the mode lists' own rows (TrickShotViews, EightBallViews, LessonViews each drew one,
//          with tinted titles; package 5 moves them here), ProgressChip (the menu's count, a different row's job) and
//          FigureTile. DifficultyDots belongs to another builder of this package, hence the generic slot.
import SwiftUI

/// One list row: leading mark, title, line, meta (difficulty and best), picture, chevron.
struct ListRow<Difficulty: View, Picture: View>: View {
    /// The leading mark.
    enum Leading: Equatable, Sendable {
        /// The item's number in the list (paper2).
        case number(Int)
        /// Done: a cyan tick.
        case done
        /// A medal earned: pocket gold.
        case medal
        /// No mark.
        case none
    }

    let leading: Leading
    /// The title, already localised, sentence case.
    let title: String
    /// One line under the title, already localised; nil for none.
    var line: String? = nil
    /// The best result so far, already written with its unit ("Best 4.2 cm"); nil for none.
    var best: String? = nil
    /// Draws the chevron (off when the row opens nothing, or a menu draws its own).
    var showsChevron = true
    @ViewBuilder var difficulty: Difficulty
    @ViewBuilder var picture: Picture

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    private var device = KitDeviceReader()
    // The leading column and the picture follow the reader's text size.
    @ScaledMetric(relativeTo: .headline) private var leadingWidth: CGFloat = 28
    @ScaledMetric(relativeTo: .headline) private var pictureWidth: CGFloat = 72

    init(leading: Leading, title: String, line: String? = nil, best: String? = nil, showsChevron: Bool = true,
         @ViewBuilder difficulty: () -> Difficulty, @ViewBuilder picture: () -> Picture) {
        self.leading = leading
        self.title = title
        self.line = line
        self.best = best
        self.showsChevron = showsChevron
        self.difficulty = difficulty()
        self.picture = picture()
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.sm) {
            if hasLeadingMark {
                leadingMark
                    .frame(width: leadingWidth, alignment: .center)
            }
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(verbatim: title)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                if let line {
                    Text(verbatim: line)
                        .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                        .foregroundStyle(palette.paper2)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                }
                if hasMeta {
                    HStack(alignment: .center, spacing: Theme.Space.xs) {
                        difficulty
                        if let best {
                            Text(verbatim: best)
                                .font(Theme.caption.monospacedDigit())
                                .foregroundStyle(palette.paper2)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if Picture.self != EmptyView.self, !typeSize.isAccessibilitySize {
                // The start layout's table drawing, at a table's proportions, clipped to small corners. At the
                // accessibility sizes it gives its room to the words.
                picture
                    .frame(width: pictureWidth, height: pictureWidth * 0.55)
                    .clipShape(Theme.Corner.tileShape)
                    .accessibilityHidden(true)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(palette.paper3)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Theme.Space.sm)
        .padding(.horizontal, Theme.Space.md)
        .frame(maxWidth: .infinity, minHeight: Theme.Size.minHit, alignment: .leading)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
        .contentShape(Theme.Corner.tileShape)
        .accessibilityElement(children: .combine)
    }

    /// True when the row draws a leading mark. A pattern match rather than `leading != .none`, so the case named none
    /// can never be read as Optional's none.
    private var hasLeadingMark: Bool {
        if case .none = leading { return false }
        return true
    }

    /// True when the meta line has anything to show.
    private var hasMeta: Bool { Difficulty.self != EmptyView.self || best != nil }

    @ViewBuilder private var leadingMark: some View {
        switch leading {
        case .number(let n):
            Text(verbatim: n.formatted(.number.locale(AppLocale.numbers)))
                .font(Theme.heading.monospacedDigit())
                .foregroundStyle(palette.paper2)
        case .done:
            Image(systemName: "checkmark")
                .font(Theme.heading)
                .foregroundStyle(palette.accent)
                .accessibilityLabel(Text(verbatim: String(localized: "List row: done", defaultValue: "Done",
                                                          comment: "VoiceOver for the tick at the start of a list row whose item is done.")))
        case .medal:
            Image(systemName: "medal")
                .font(Theme.heading)
                .foregroundStyle(palette.pocket)
                .accessibilityLabel(Text(verbatim: String(localized: "List row: medal", defaultValue: "Medal earned",
                                                          comment: "VoiceOver for the medal at the start of a list row whose medal is earned.")))
        case .none:
            EmptyView()
        }
    }
}

extension ListRow where Difficulty == EmptyView {
    /// A row with no difficulty.
    init(leading: Leading, title: String, line: String? = nil, best: String? = nil, showsChevron: Bool = true,
         @ViewBuilder picture: () -> Picture) {
        self.init(leading: leading, title: title, line: line, best: best, showsChevron: showsChevron,
                  difficulty: { EmptyView() }, picture: picture)
    }
}

extension ListRow where Picture == EmptyView {
    /// A row with no picture.
    init(leading: Leading, title: String, line: String? = nil, best: String? = nil, showsChevron: Bool = true,
         @ViewBuilder difficulty: () -> Difficulty) {
        self.init(leading: leading, title: title, line: line, best: best, showsChevron: showsChevron,
                  difficulty: difficulty, picture: { EmptyView() })
    }
}

extension ListRow where Difficulty == EmptyView, Picture == EmptyView {
    /// A row with neither a difficulty nor a picture.
    init(leading: Leading, title: String, line: String? = nil, best: String? = nil, showsChevron: Bool = true) {
        self.init(leading: leading, title: title, line: line, best: best, showsChevron: showsChevron,
                  difficulty: { EmptyView() }, picture: { EmptyView() })
    }
}

#Preview("List rows") {
    let palette = Palette(contrast: .standard)
    // Stand-ins for the slots: the real dots are DifficultyDots and the real picture the start layout's drawing.
    let dots = HStack(spacing: Theme.Space.xxs) {
        ForEach(0..<5, id: \.self) { i in
            Circle().fill(i < 3 ? palette.paper : palette.paper3).frame(width: 6, height: 6)
        }
    }
    let table = Rectangle().fill(Color(red: 0.11, green: 0.45, blue: 0.30))
    VStack(spacing: Theme.Space.xs) {
        ListRow(leading: .number(1), title: "Stop shot", line: "Hit the cue ball dead centre and it stops.",
                difficulty: { dots }, picture: { table })
        ListRow(leading: .done, title: "Follow", line: "Hit above centre and it rolls on.", best: "Best 4.2 cm",
                difficulty: { dots }, picture: { table })
        ListRow(leading: .medal, title: "A long-rail snooker", line: "Get out off one cushion.", best: "Best 2 tries",
                picture: { table })
        ListRow(leading: .none, title: "No mark, no picture", line: "Words only.")
    }
    .padding(Theme.Space.lg)
    .background(palette.panel)
    .background(palette.ground)
}
