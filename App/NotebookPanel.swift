// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the folding phone's panel becomes the notebook of every big screen:
//          renamed NotebookPanel in NotebookPanel.swift (it was DuoPanel in DuoPanel.swift), shown beside or under the table on iPad and Mac windows as well as
//          across the hinge. The page switch (How to play, Options, Tables) is handed in by ShowpieceView so the Help
//          menu can open it; on the Mac the main menu's Options opens the Settings window instead of a page. The column
//          rule is ScreenLayout.panelColumns: a hinge keeps its original rule, a wide window's panel gets two columns
//          once each column is readable. The aiming controls (tip and power) moved from the top of the panel to its
//          lower edge, above the playback controls, so on a big screen one hand aims on the table while the other
//          thumb sets tip and power. Without a hinge the panel's reading text steps up a size (notebookRoomy), for
//          arm's length on an iPad and desk distance on a Mac. In a match the top bar names the game.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons stream, hook lines: the lesson list is a page of the panel,
//          the lesson card is one of its cards, a lesson counts as a mode on the table (its details replace the numbers)
//          and the top bar says Lessons while one is up.)
// PURPOSE: The notebook: the side of the screen that is not the table, on the open folding phone (across the hinge) and
//          on every screen big enough for the table plus a readable column (an iPad either way up, a large iPad split or
//          Stage Manager window, a Mac window). The table fills the other side and nothing is drawn over it: no title
//          row, no menu, no list, no sheet. This panel holds everything else, as a full-height notebook:
//            - a top bar: back to the main menu, what you are playing, the surface picker;
//            - the mode's own cards (comparison, trick shot, Behind the 8-Ball) and the mode's details
//              (NotebookDossier);
//            - the live commentary: every explained moment of the shot, in order, with the one on the table lit
//              (NotebookStory);
//            - the numbers of the shot, the surface and the table (NotebookNumbers);
//            - at the lower edge, the aiming controls (tip, power, Shoot) and the playback controls.
//          Menus and lists that are sheets on a phone (the main menu, Trick shots, Behind the 8-Ball, How to play,
//          Options, Tables, the fine controls) are pages of this panel instead, so the whole table stays in view beside
//          them. The environment value inlinePages tells those views to stay out of sheets here.
//          A short and wide panel (the phone propped like a laptop, the band under the table on an iPad held upright)
//          or a wide one on a large window splits into two columns: cards and controls on one side, the commentary and
//          numbers on the other.
// SRP/DRY check: Pass - layout and page switching only. The words are in NotebookStory and NotebookDossier, the numbers
//          in NotebookNumbers, the split rules in NotebookGeometry; every card, list and menu is the same view the other
//          screens use, embedded.
import BreakdownRules
import SwiftUI

extension EnvironmentValues {
    /// True in the notebook (the folding phone's open screen, and iPad and Mac windows big enough for it): lists, menus
    /// and option sheets appear as pages of the panel instead of sheets over the table.
    @Entry var inlinePages: Bool = false
    /// True when the notebook is on a big screen (no hinge): its reading text is a size larger, read from further away.
    @Entry var notebookRoomy: Bool = false
}

/// The pages that replace play in the notebook (and are sheets elsewhere): How to play, Options, Tables.
enum NotebookPage: String, Identifiable {
    case howTo, options, tables
    var id: String { rawValue }
}

/// Game names the notebook's top bar and the Mac's Game menu share. The three table games reuse the tables' own names.
enum NotebookWords {
    static func gameName(_ kind: MatchKind) -> String {
        switch kind {
        case .eightBall: return String(localized: "Eight-ball")
        case .nineBall: return String(localized: "Nine-ball")
        case .bumperPool: return String(localized: "Bumper pool")
        case .fivePin: return String(localized: "Five-pin billiards")
        case .barBilliards: return String(localized: "Bar billiards")
        }
    }
}

struct NotebookPanel: View {
    /// The stored switch behind the View menu's "Show Notebook" (on by default).
    static let shownKey = "notebookPanelShown"

    let model: ShowpieceModel
    let leader: LeaderState
    @Binding var showShotPanel: Bool
    /// How to play, Options or Tables while one is open; owned by ShowpieceView so the Help menu reaches it.
    @Binding var page: NotebookPage?
    /// True across a folding phone's hinge, where the panel's original column rule and text sizes stay as designed.
    let onHinge: Bool
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if os(macOS)
    @Environment(\.openSettings) private var openSettings
    #endif
    /// The natural height of the cards block, so the commentary is shown only when there is room left for it.
    @State private var cardsHeight: CGFloat = 0
    /// Measured height of the lower edge (aiming controls and playback controls) and of the numbers strip; both grow
    /// when their buttons wrap onto two rows.
    @State private var bottomMeasured: CGFloat = 0
    @State private var numbersMeasured: CGFloat = 0
    @AppStorage(GameSettings.explanationsKey) private var explanations = true

    var body: some View {
        GeometryReader { geo in
            content(size: geo.size)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(palette.ground)
        .environment(\.notebookRoomy, !onHinge)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: pageKey)
    }

    /// Which page shows, for the cross-fade between them.
    private var pageKey: String {
        if let page { return "info-\(page.rawValue)" }
        if model.trickMode.listOpen { return "trickList" }
        if model.lessonMode.listOpen { return "lessonList" }
        if model.eightBallMode.listOpen { return "eightList" }
        return model.menuOpen ? "menu" : "play"
    }

    private var pageBinding: Binding<Bool> {
        Binding(get: { page != nil }, set: { if !$0 { page = nil } })
    }

    // MARK: Pages

    @ViewBuilder
    private func content(size: CGSize) -> some View {
        if let page {
            switch page {
            case .howTo: HowToPlaySheet(isOpen: pageBinding)
            case .options: OptionsSheet(isOpen: pageBinding)
            case .tables: TableList(model: model, onChosen: { showShotPanel = true }, onClose: { self.page = nil })
            }
        } else if model.trickMode.listOpen {
            TrickShotList(mode: model.trickMode)
        } else if model.lessonMode.listOpen {
            LessonList(mode: model.lessonMode)
        } else if model.eightBallMode.listOpen {
            EightBallList(mode: model.eightBallMode)
        } else if model.menuOpen {
            TitleScreen(model: model, onPlay: { showShotPanel = true },
                        onHowTo: { page = .howTo }, onOptions: { openOptions() },
                        onTables: { page = .tables })
        } else {
            play(size: size)
        }
    }

    /// Options: the Mac's own Settings window (the app menu's Settings, Command-comma), a page of the panel elsewhere.
    private func openOptions() {
        #if os(macOS)
        openSettings()
        #else
        page = .options
        #endif
    }

    /// True while a trick shot or a Behind the 8-Ball situation is on the table: its details replace the numbers.
    private var modeActive: Bool {
        model.trickMode.isActive || model.eightBallMode.isActive || model.lessonMode.isActive
    }

    @ViewBuilder
    private func play(size: CGSize) -> some View {
        if ScreenLayout.panelColumns(for: size, onHinge: onHinge) == 2 {
            twoColumns(size)
        } else {
            oneColumn(size)
        }
    }

    /// The cards that belong to the mode on the table and the mode's details.
    private var cards: some View {
        VStack(spacing: 10) {
            ComparisonCard(model: model)
            OpeningCard(model: model)
            LensCalloutCard(model: model)
            TrickShotCard(model: model)
            LessonCard(model: model)
            EightBallCard(model: model)
            PlayCards(model: model)
            NotebookDossier(model: model)
        }
    }

    /// The panel's lower edge: the aiming controls (tip picture, power gauge, Shoot) while "Your shot" is open, and the
    /// playback controls. At the bottom so a thumb reaches them while the other hand aims on the table.
    private var lowerEdge: some View {
        VStack(spacing: 10) {
            if showShotPanel {
                ShotPanel(model: model, isOpen: $showShotPanel).glassCard().transition(.opacity)
            }
            PlaybackControls(model: model, shotPanelOpen: $showShotPanel, compact: true)
        }
        .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bottomMeasured = $0 }
    }

    /// The lower edge's height before it has been measured once: the playback controls alone (90), or with the shot
    /// panel's two rows and its glass card (about 180).
    private var bottomHeight: CGFloat {
        bottomMeasured > 0 ? bottomMeasured : (showShotPanel ? 180 : 90)
    }

    private var showsNumbers: Bool { !modeActive && !showShotPanel && !typeSize.isAccessibilitySize }

    /// One column, read like a book: top bar, cards, the commentary taking all the room left, the numbers, then the
    /// aiming and playback controls at the lower edge. The cards come first and keep all the height they need; the
    /// commentary gets what remains, and is left out (so the cards are not squeezed) when less than a few rows' worth
    /// remains, as while aiming a trick shot.
    private func oneColumn(_ size: CGSize) -> some View {
        // The fixed parts: padding (32), top bar (40), the lower edge, the numbers, the gaps between blocks.
        let numbersHeight: CGFloat = showsNumbers ? (numbersMeasured > 0 ? numbersMeasured : 128) : 0
        let gaps = CGFloat(showsNumbers ? 4 : 3) * 12
        let free = size.height - 32 - 40 - bottomHeight - numbersHeight - gaps
        let storyMinimum: CGFloat = 140
        let showsStory = explanations && free - cardsHeight >= storyMinimum
        let cardsMax = max(120, showsStory ? free - storyMinimum : free)
        let overflows = cardsHeight > cardsMax
        return VStack(spacing: 12) {
            NotebookTopBar(model: model)
            FittingScroll(maxHeight: cardsMax) {
                cards.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardsHeight = $0 }
            }
            .fadesAtBottom(overflows)
            if showsStory {
                NotebookStory(model: model, leader: leader).frame(maxHeight: .infinity)
            } else {
                Spacer(minLength: 0)
            }
            if showsNumbers {
                NotebookNumbers(model: model)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { numbersMeasured = $0 }
            }
            lowerEdge
        }
        // Slightly narrower side padding than the other layouts: the trick-shot and 8-ball cards keep their buttons on
        // one row only if the column is a few points wider.
        .padding(.horizontal, onHinge ? 10 : 16)
        .padding(.vertical, 16)
    }

    /// Two columns: the top bar, cards and the controls on the leading side, the commentary and the numbers on the
    /// other. Used when the panel is short and wide (the folding phone propped like a laptop, the band under the table
    /// on an iPad held upright) or wide enough for two readable columns (a large Mac window, a 13-inch iPad sideways).
    private func twoColumns(_ size: CGSize) -> some View {
        // Padding (28), top bar (40), the lower edge and the gaps (30) are fixed; the cards take the rest.
        let cardsMax = max(120, size.height - 28 - 40 - bottomHeight - 30)
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                NotebookTopBar(model: model)
                FittingScroll(maxHeight: cardsMax) {
                    cards.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardsHeight = $0 }
                }
                .fadesAtBottom(cardsHeight > cardsMax)
                Spacer(minLength: 0)
                lowerEdge
            }
            // Half the panel on a big screen, where the controls column holds the aiming controls too; the folding
            // phone keeps the share it was laid out with.
            .frame(width: size.width * (onHinge ? 0.44 : 0.5))
            VStack(spacing: 10) {
                NotebookStory(model: model, leader: leader)
                    .frame(maxHeight: .infinity)
                if showsNumbers { NotebookNumbers(model: model) }
            }
        }
        .padding(14)
    }
}

// MARK: Top bar

/// The title row that would sit over the table on a phone: back to the menu, what is being played, the surface picker.
private struct NotebookTopBar: View {
    let model: ShowpieceModel

    /// The opening's own status while it tells its story, else the game or mode on the table.
    private var title: String {
        if model.stage != .explore && model.stage != .lead { return model.stageTitle }
        if let match = model.match { return NotebookWords.gameName(match.rules.kind) }
        if model.trickMode.isActive { return String(localized: "Trick shots") }
        if model.lessonMode.isActive { return String(localized: "Lessons") }
        if model.eightBallMode.isActive { return String(localized: "Behind the 8-Ball") }
        return String(localized: "Free play")
    }

    var body: some View {
        HStack(spacing: 12) {
            MenuBackButton(model: model)
            Text(verbatim: title)
                .font(Theme.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            SurfaceMenuButton(model: model)
        }
    }
}

private extension View {
    /// When a block is taller than its room and scrolls, its last lines fade out to say there is more.
    func fadesAtBottom(_ overflows: Bool) -> some View {
        mask {
            LinearGradient(stops: [.init(color: .black, location: 0),
                                   .init(color: .black, location: overflows ? 0.9 : 1),
                                   .init(color: overflows ? .clear : .black, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}
