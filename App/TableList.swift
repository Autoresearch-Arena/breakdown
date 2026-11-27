// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 7, "The front door and the sheets": the page is
//          the kit's SheetPage (ground, serif title, cyan Done top right) and each table is a full-width panel card:
//          its picture, its name, its one sentence and one line of its real figures (bed in m, ball in mm, its
//          pockets, cups, holes or pins: TableFiguresLine, through NumberStyle), with a cyan tick on the table on
//          screen. Every card opens a table page: the pool table's own page (TablePage, here) with Play, which does
//          what tapping it used to (playTable); a table with a game of its own opens TableGamePage as before, on the
//          ground, with Done top right like every pushed page.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, plans/25-Nov-2026-front-door-and-table-view-plan.md
//          Stage 1 step 4: tables are shown, not listed. The page is four pictures of the tables side by side (two by
//          two on a phone), each the real table drawn by the table builder (TablePortraits), with its name under it and
//          a tick on the one on screen. The one-line description and the game's line are each picture's VoiceOver hint.
//          What a tap does is unchanged: the pool table plays at once, the others open their game's page.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream model-flow items 6 and 12: the ticked row is the table actually on screen (model.tableOnScreen), so
//          none is ticked while a trick shot, lesson, situation, the stroke drill or a match is up; the Mac minimum
//          size applies only in a sheet, not as a page of the notebook.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens) - bumper pool, five-pin and bar billiards are games
//          now: each entry also names its game and opens that game's page (TableGamePage: a match for two, bar
//          billiards alone, practice on the table, and How to play). The pool table still plays at once, as before.
// PURPOSE: The list of tables, opened from the main menu ("Tables"): the pool table, bumper pool, five-pin billiards
//          and bar billiards, each with its plain one-line description. Choosing one plays it as the game
//          (ShowpieceModel.playTable): any trick shot or Behind the 8-Ball situation ends, the table changes and its
//          start layout is on screen, ready to shoot. A table is a different game, not a different felt, so it lives
//          here, away from the Surface button (which now only picks what the bed is made of). On the folding phone's open
//          screen this is a page of the side panel, not a sheet over the table.
// SRP/DRY check: Pass - display and one model call. Titles, summaries and symbols come from TableKind.
import BreakdownRules
import SwiftUI

struct TableList: View {
    let model: ShowpieceModel
    /// Called after a table is chosen (the menu opens the aiming controls, as Free play does).
    let onChosen: () -> Void
    let onClose: () -> Void
    @Environment(\.palette) private var palette
    /// True when shown as a page of the notebook rather than a sheet (NotebookPanel sets it).
    @Environment(\.inlinePages) private var inlinePages

    /// The table on the screen right now, or nil while a trick shot, lesson, situation, the stroke drill or a match is
    /// up (the model's one answer, which the Mac's Game > Tables reads too).
    private var current: TableKind? { model.tableOnScreen }

    var body: some View {
        NavigationStack {
            SheetPage(title: String(localized: "Tables"), onDone: onClose) {
                ForEach(TableKind.allCases) { kind in
                    NavigationLink {
                        page(kind)
                    } label: {
                        TableCard(kind: kind, onScreen: kind == current)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(kind == current ? .isSelected : [])
                }
            }
            .frontDoorSheetRoot()
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's minimum size only: as a notebook page a fixed minimum pushed the list past the panel (0.7.5).
        .frame(minWidth: inlinePages ? nil : 420, minHeight: inlinePages ? nil : 420)
        #endif
    }

    /// The table's page: its game's page for a table with a game of its own, the pool table's own page otherwise.
    @ViewBuilder private func page(_ kind: TableKind) -> some View {
        if let game = kind.matchKind {
            // A table with a game of its own: its page offers the match, practice and the rules.
            TableGamePage(model: model, table: kind, game: game) {
                onChosen()
                onClose()
            }
            // The same title the page gives itself (the table's name), and Done top right as on every pushed page.
            .frontDoorPushedPage(title: kind.title, onDone: onClose)
        } else {
            TablePage(kind: kind) {
                model.playTable(kind)
                onChosen()
                onClose()
            }
            .frontDoorPushedPage(title: kind.title, onDone: onClose)
        }
    }
}

// MARK: One table's card

/// UI rethink package 7: one table as a full-width panel card: the picture, then the name (with a cyan tick when it is
/// the table on screen), its one sentence and its figures. The picture sits beside the words, and above them at the
/// accessibility text sizes. VoiceOver reads the name, the sentence, the game it plays and the figures.
private struct TableCard: View {
    let kind: TableKind
    let onScreen: Bool
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    private var device = KitDeviceReader()
    /// The picture's width beside the words; it follows the reader's text size.
    @ScaledMetric(relativeTo: .headline) private var pictureWidth: CGFloat = 112

    init(kind: TableKind, onScreen: Bool) {
        self.kind = kind
        self.onScreen = onScreen
    }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Theme.Space.sm) {
                    picture.frame(maxWidth: .infinity)
                    words
                }
            } else {
                HStack(alignment: .center, spacing: Theme.Space.md) {
                    picture.frame(width: pictureWidth)
                    words
                    Image(systemName: "chevron.right")
                        .font(Theme.caption.weight(.semibold))
                        .foregroundStyle(palette.paper3)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .overlay {
            // The table on screen: the selected state's one cyan edge.
            if onScreen {
                Theme.Corner.cardShape.strokeBorder(palette.accent, lineWidth: Theme.Size.editableUnderline)
            }
        }
        .contentShape(Theme.Corner.cardShape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: kind.title))
        .accessibilityValue(Text(verbatim: TableFigures.line(kind).spoken))
        .accessibilityHint(Text(verbatim: TableListWords.hint(kind)))
    }

    private var picture: some View {
        TablePortrait(kind: kind)
            .clipShape(Theme.Corner.tileShape)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                Text(verbatim: kind.title)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                if onScreen {
                    Image(systemName: "checkmark")
                        .font(Theme.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                }
            }
            Text(verbatim: kind.summary)
                .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
            TableFiguresLine(kind: kind)
                .padding(.top, Theme.Space.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: The pool table's page

/// UI rethink package 7: the page a table with no game of its own opens (the pool table): its picture large, its
/// sentence, its figures and Play, which puts it on the table ready to shoot, as tapping it in the list used to.
private struct TablePage: View {
    let kind: TableKind
    let onPlay: @MainActor () -> Void
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()

    init(kind: TableKind, onPlay: @escaping @MainActor () -> Void) {
        self.kind = kind
        self.onPlay = onPlay
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                TablePortrait(kind: kind)
                    .clipShape(Theme.Corner.tileShape)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(verbatim: kind.summary)
                        .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    TableFiguresLine(kind: kind)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .kitPanel()
                PrimaryButton(String(localized: "Tables: play this table", defaultValue: "Play",
                                     comment: "The main button on a table's page: puts this table on screen, ready to shoot. A game, never media playback."),
                              fullWidth: true, action: onPlay)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(Theme.Space.pageMargin(device.current))
        }
    }
}

/// The Tables page's VoiceOver words.
enum TableListWords {
    /// The table's one-line description, then the game it plays (what the old list showed under each name).
    static func hint(_ kind: TableKind) -> String {
        guard let game = kind.matchKind else { return kind.summary }
        return [kind.summary, TableGameWords.gameLine(game)].joined(separator: " ")
    }
}
