// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// PURPOSE: The iPhone Duo's own layout for the open screen. The table fills one whole panel (before the fold) and
//          nothing is drawn over it: no title row, no menu, no list, no sheet. Everything else lives in this panel, the
//          one after the fold, which is a full-height notebook instead of a few cards in a corner:
//            - a top bar: back to the main menu, what you are playing, the surface and table picker;
//            - the mode's own cards (comparison, trick shot, Behind the 8-Ball), the aiming panel, and the mode's
//              details (DuoDossier);
//            - the live commentary: every explained moment of the shot, in order, with the one on the table lit
//              (DuoStory);
//            - the numbers of the shot, the surface and the table (DuoNumbers);
//            - the playback controls.
//          Menus and lists that are sheets on every other screen (the main menu, Trick shots, Behind the 8-Ball,
//          How to play, Options, the fine controls) are pages of this panel instead, so the whole table stays in view
//          beside them. The environment value inlinePages tells those views to stay out of sheets on this screen.
//          When the phone is propped like a laptop the panel is short and wide, and the play page splits into two
//          columns (controls and cards on one side, the commentary and numbers on the other).
// SRP/DRY check: Pass - layout and page switching only. The words are in DuoStory and DuoDossier, the numbers in
//          DuoNumbers; every card, list and menu is the same view the other screens use, embedded.
import SwiftUI

extension EnvironmentValues {
    /// True on a folding phone's open screen: lists, menus and option sheets appear as pages of the side panel
    /// instead of sheets over the table.
    @Entry var inlinePages: Bool = false
}

struct DuoPanel: View {
    let model: ShowpieceModel
    let leader: LeaderState
    @Binding var showShotPanel: Bool
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How to play and Options are pages here, not sheets; the main menu opens them through these closures.
    @State private var infoPage: InfoPage?
    /// The natural height of the cards block, so the commentary is shown only when there is room left for it.
    @State private var cardsHeight: CGFloat = 0
    /// Measured heights of the controls and the numbers strip (they grow when their buttons wrap onto two rows).
    @State private var controlsMeasured: CGFloat = 0
    @State private var numbersMeasured: CGFloat = 0
    @AppStorage(GameSettings.explanationsKey) private var explanations = true

    private enum InfoPage { case howTo, options, tables }

    var body: some View {
        GeometryReader { geo in
            page(size: geo.size)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(palette.ground)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: pageKey)
    }

    /// Which page shows, for the cross-fade between them.
    private var pageKey: String {
        if let infoPage { return "info-\(infoPage)" }
        if model.trickMode.listOpen { return "trickList" }
        if model.eightBallMode.listOpen { return "eightList" }
        return model.menuOpen ? "menu" : "play"
    }

    private var infoBinding: Binding<Bool> {
        Binding(get: { infoPage != nil }, set: { if !$0 { infoPage = nil } })
    }

    // MARK: Pages

    @ViewBuilder
    private func page(size: CGSize) -> some View {
        if let infoPage {
            switch infoPage {
            case .howTo: HowToPlaySheet(isOpen: infoBinding)
            case .options: OptionsSheet(isOpen: infoBinding)
            case .tables: TableList(model: model, onChosen: { showShotPanel = true }, onClose: { self.infoPage = nil })
            }
        } else if model.trickMode.listOpen {
            TrickShotList(mode: model.trickMode)
        } else if model.eightBallMode.listOpen {
            EightBallList(mode: model.eightBallMode)
        } else if model.menuOpen {
            TitleScreen(model: model, onPlay: { showShotPanel = true },
                        onHowTo: { infoPage = .howTo }, onOptions: { infoPage = .options },
                        onTables: { infoPage = .tables })
        } else {
            play(size: size)
        }
    }

    /// True while a trick shot or a Behind the 8-Ball situation is on the table: its details replace the numbers.
    private var modeActive: Bool {
        model.trickMode.isActive || model.eightBallMode.isActive
    }

    @ViewBuilder
    private func play(size: CGSize) -> some View {
        if size.width > 560, size.width > size.height * 1.25 {
            twoColumns(size)
        } else {
            oneColumn(size)
        }
    }

    /// The cards that belong to the mode on the table, the aiming panel, and the mode's details.
    private var cards: some View {
        VStack(spacing: 10) {
            ComparisonCard(model: model)
            TrickShotCard(model: model)
            EightBallCard(model: model)
            if showShotPanel {
                ShotPanel(model: model, isOpen: $showShotPanel).glassCard().transition(.opacity)
            }
            DuoDossier(model: model)
        }
        .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
    }

    private var showsNumbers: Bool { !modeActive && !showShotPanel && !typeSize.isAccessibilitySize }

    /// The open phone read like a book: top bar, cards, the commentary taking all the room left, the numbers, the controls.
    /// The cards come first and keep all the height they need; the commentary gets what remains, and is left out (so the
    /// cards are not squeezed) when less than a few rows' worth remains, as while aiming a trick shot.
    private func oneColumn(_ size: CGSize) -> some View {
        // The fixed parts: padding, top bar, controls (the scrub row steps aside while aiming), the numbers, the gaps.
        let controlsHeight: CGFloat = controlsMeasured > 0 ? controlsMeasured : (showShotPanel ? 36 : 90)
        let numbersHeight: CGFloat = showsNumbers ? (numbersMeasured > 0 ? numbersMeasured : 128) : 0
        let gaps = CGFloat(showsNumbers ? 4 : 3) * 12
        let free = size.height - 32 - 40 - controlsHeight - numbersHeight - gaps
        let storyMinimum: CGFloat = 140
        let showsStory = explanations && free - cardsHeight >= storyMinimum
        let cardsMax = max(120, showsStory ? free - storyMinimum : free)
        let overflows = cardsHeight > cardsMax
        return VStack(spacing: 12) {
            DuoTopBar(model: model)
            FittingScroll(maxHeight: cardsMax) {
                cards.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardsHeight = $0 }
            }
            .fadesAtBottom(overflows)
            if showsStory {
                DuoStory(model: model, leader: leader).frame(maxHeight: .infinity)
            } else {
                Spacer(minLength: 0)
            }
            if showsNumbers {
                DuoNumbers(model: model)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { numbersMeasured = $0 }
            }
            PlaybackControls(model: model, shotPanelOpen: $showShotPanel, compact: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsMeasured = $0 }
        }
        // Slightly narrower side padding than the other layouts: the trick-shot and 8-ball cards keep their buttons on
        // one row only if the column is a few points wider.
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
    }

    /// Short and wide (the phone propped like a laptop): controls and cards on the leading side, the commentary and
    /// the numbers on the other.
    private func twoColumns(_ size: CGSize) -> some View {
        // Padding, top bar, the controls (two rows in this narrow column) and the gaps are fixed; the cards take the rest.
        let cardsMax = max(120, size.height - 28 - 40 - (showShotPanel ? 80 : 130) - 30)
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                DuoTopBar(model: model)
                FittingScroll(maxHeight: cardsMax) {
                    cards.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardsHeight = $0 }
                }
                .fadesAtBottom(cardsHeight > cardsMax)
                Spacer(minLength: 0)
                PlaybackControls(model: model, shotPanelOpen: $showShotPanel, compact: true)
            }
            .frame(width: size.width * 0.44)
            VStack(spacing: 10) {
                DuoStory(model: model, leader: leader)
                    .frame(maxHeight: .infinity)
                if showsNumbers { DuoNumbers(model: model) }
            }
        }
        .padding(14)
    }
}

// MARK: Top bar

/// The title row that used to sit over the table: back to the menu, what is being played, and the surface picker.
private struct DuoTopBar: View {
    let model: ShowpieceModel

    /// The opening's own status while it tells its story, else the mode on the table.
    private var title: String {
        if model.stage != .explore && model.stage != .lead { return model.stageTitle }
        if model.trickMode.isActive { return String(localized: "Trick shots") }
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
