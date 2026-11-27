// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 8, the open folding phone: across the hinge the
//          table half draws marks only, so the panel's top line (TableMarksLine, under the top bar) says what they mean:
//          the ringed ball ("3 ball, solid"), the fork's two lines with the turn, the bridge, the last try's ring, the
//          answer's path, the what-if and the every-surface fan; it is measured into every height budget, so Shoot stays in sight, and left
//          out of the calm first minute. The top bar runs Back, title, Zoom, Share, Menu (the design's order), its title
//          gives way before the worded buttons do (it drops on the fold's narrow panel, then the buttons go to icons),
//          and "Behind the 8-ball" is the menu's sentence-case name. Margins stay Theme.Space.pageMargin(.foldPanel).)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 4 follow-up: reelOnStage moves the reel and the
//          Physics Lens, Ride and Aim tabs to the stage under the table beside a big screen's column, so the column holds
//          the whole console: the strike's figures and Shoot no longer scroll out of sight.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console: the notebook is one column
//          on every big screen (two only across a folding phone's hinge, as designed), so the upright iPad has no empty
//          second column; while "Your strike" shows, it and the controls are one console card (the kit's panel) that
//          takes all the height left, with the reel or its "Last shot" button and the Physics Lens, Ride and Aim tabs
//          under it; the first minute (the hand-over) is the top bar titled "Break" and one calm card (the sentence, the
//          tip picture, the swing and Break), no story, no reel, no tabs; margins and gaps are Theme's; the kit's device
//          is set here (.big, or .foldPanel across the hinge); the fade mask's black stops carry the lint's allow mark.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: the strike column's height budget uses the
//          measured hint, status and playback heights, so the controls never ride over the strike's physics band.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: the numbers strip keeps no room before a shot while it
//          has nothing to draw.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike, plans/25-Nov-2026-strike-panel-and-controls-plan.md
//          stage 2: the commentary's place holds StrikeSlot, which shows the strike panel while aiming and the commentary
//          while the balls move; the slot stays with Explanations off, outside the opening.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: the status names the shot of the day, not Trick shots.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: the top
//          bar's title reads a frozen hit's status line for the length of the freeze.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 achievements hooks, plans/23-Nov-2026-achievements-plan.md:
//          the Achievements page (a new NotebookPage case), the menu's Achievements row opening it, and the achievement
//          note first among the cards, on the panel's half; each marked "// 0.7.7 achievements:".)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 every-world: EveryWorldCard right after WhatIfCard, so the
//          every-surface fan's words live in the notebook and the table half shows only its lines and tags.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 coordinator: wires the Ride hand-over in).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts review: the notebook's Continue waits for the opening
//          to end, so the first minute's notebook stays its one line; the opening's holds end by themselves.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts items 4, 7, 8 and 9, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md:
//          Continue for a held Lens moment sits at the top of the lower edge, above the playback controls (on the
//          words half of the open Duo), so a guided replay can be moved on here as on a phone; the Lens colour key has
//          its own row under the top bar in both layouts, shown whenever the Lens is up (Explanations on or off), and
//          its height is taken out of the one-column budget; the panel clips to its frame, so nothing it holds draws
//          over the table; and in two columns, when the story would leave the second column empty (Explanations off),
//          the cards move there, above the numbers when they show, instead of leaving a blank half.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F11:
//          WhatIfCard first among the cards, so a what-if lives in the notebook and never covers the table.)
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
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hook: the stroke's cards (the hard shot's result line
//          and the straight-stroke drill) among the mode's cards, so the drill is a card of the notebook beside the
//          table and nothing covers it.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: the equipment card (the stance, App/Stroke/StanceViews.swift)
//          is one of the cards while "Your shot" is open; the shot panel in the lower edge leaves it out here.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 1, 18 and 53:
//          the menu page asks before a new match replaces the saved one (the pending request is handed in by
//          ShowpieceView, the same one the Mac's Game menu sets); How to play teaches the stroke for the input in use;
//          the line See the contact leaves on arrival is one of the cards.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 13: while the strike shows (StrikeSlot.showsStrike) the column runs top bar, cards (capped), the
//          strike's heading, sentence and two bands at their own height, then the controls band taking all the height
//          left, the hint line and the scrubber; the slot's "Step by step" state lives here so the column can be laid
//          out by it. The shot panel draws its own flat band in the notebook, so it is no longer put on a glass card.)
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
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: the round glass share
//          button (ClipShareButton) sits before the Surface button in the top bar whenever a clip is offered.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md
//          Part B: the top bar's zoom button (TableZoomMenuButton) beside the Surface button, so the table zooms
//          without a pinch or a double tap.)
// SRP/DRY check: Pass - layout and page switching only. The words are in NotebookStory and NotebookDossier, the numbers
//          in NotebookNumbers, the split rules in NotebookGeometry; every card, list and menu is the same view the other
//          screens use, embedded.
import BreakdownLensModel
import BreakdownPhysics
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
    // 0.7.7 achievements: achievements, the list of things done (AchievementList).
    case howTo, options, tables, achievements
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
    /// A new match waiting for a yes because it would replace the saved one (owned by ShowpieceView).
    @Binding var pendingMatch: MatchStartRequest?
    /// True across a folding phone's hinge, where the panel's original column rule and text sizes stay as designed.
    let onHinge: Bool
    /// The reel and the Physics Lens, Ride and Aim tabs sit on the stage under the table instead of in this column
    /// (the panel beside the table on a big screen, as mockup-aiming-ipad.png draws it), so the column is the console.
    var reelOnStage = false
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
    /// UI rethink package 1: the shot panel's status and hint lines, and the playback controls, measured, for the strike
    /// column's height budget (they were guessed, and the guess fell short in a narrow Mac window).
    @State private var shotChromeMeasured: CGFloat = 0
    @State private var playbackMeasured: CGFloat = 0
    @State private var numbersMeasured: CGFloat = 0
    /// Measured height of the Lens colour key's row (0.7.5); it wraps onto more lines at large text sizes.
    @State private var keyMeasured: CGFloat = 0
    /// UI rethink package 8: measured height of the table marks' line across the hinge (0 while it is not shown).
    @State private var marksMeasured: CGFloat = 0
    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    /// The strike slot's "Step by step": the commentary asked for after a shot (StrikeSlot's binding).
    @State private var showSteps = false

    var body: some View {
        GeometryReader { geo in
            content(size: geo.size)
                .frame(width: geo.size.width, height: geo.size.height)
                // Nothing the panel holds may draw past its edge onto the table beside it (a list page's minimum
                // frame, a card mid-transition): the table half is the table's alone (0.7.5 layouts item 8).
                .clipped()
        }
        .background(palette.ground)
        .environment(\.notebookRoomy, !onHinge)
        // UI rethink package 4: the kit's buttons, cards and reel size themselves for this panel.
        .kitDevice(onHinge ? .foldPanel : .big)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: pageKey)
        // UI rethink package 8: the marks line comes and goes with the marks (aiming, a retry's ghost).
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: markParts.map(\.id))
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
            case .howTo: HowToPlaySheet(isOpen: pageBinding, input: model.inputInUse)
            case .options: OptionsSheet(isOpen: pageBinding)
            case .tables: TableList(model: model, onChosen: { showShotPanel = true }, onClose: { self.page = nil })
            // 0.7.7 achievements: the Achievements page.
            case .achievements: AchievementList(model: model, onClose: { self.page = nil })
            }
        } else if model.trickMode.listOpen {
            TrickShotList(mode: model.trickMode)
        } else if model.lessonMode.listOpen {
            LessonList(mode: model.lessonMode)
        } else if model.eightBallMode.listOpen {
            EightBallList(mode: model.eightBallMode)
        } else if model.menuOpen {
            // 0.7.7 achievements: onAchievements opens the Achievements page.
            TitleScreen(model: model, onPlay: { showShotPanel = true },
                        onHowTo: { page = .howTo }, onOptions: { openOptions() },
                        onTables: { page = .tables }, onAchievements: { page = .achievements },
                        pendingMatch: $pendingMatch)
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

    /// UI rethink package 4: the first minute, while the controls are open at the hand-over.
    private var calm: Bool { model.openingStage == .handOver && showShotPanel }

    @ViewBuilder
    private func play(size: CGSize) -> some View {
        if calm {
            calmColumn
        } else {
            playColumns(size: size)
        }
    }

    /// The first minute (principle 7, calm first): the top bar, titled "Break", and one card beside the table with the
    /// sentence, the tip picture, the swing in m/s and Break (ShotPanel's calm console). No story, no reel, no tabs:
    /// they come after the first shot lands.
    private var calmColumn: some View {
        VStack(spacing: gap) {
            NotebookTopBar(model: model)
            ShotPanel(model: model, isOpen: $showShotPanel)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, margin)
        .padding(.vertical, Theme.Space.md)
    }

    /// The kit's device for this panel: the fold's panel across a hinge, the big screens otherwise.
    private var device: Theme.Device { onHinge ? .foldPanel : .big }
    /// The side margin and the gap between blocks, from Theme (24 and 16 on iPad and Mac, 20 and 16 on the fold).
    private var margin: CGFloat { Theme.Space.pageMargin(device) }
    private var gap: CGFloat { Theme.Space.cardGap(device) }

    @ViewBuilder
    private func playColumns(size: CGSize) -> some View {
        // 0.8.1: while "Your shot" is open the panel is one column at every width. Two columns put the controls card
        // under an empty half and squeezed the strike's tiles into the other half (the Boss, 26-Nov-2026: "you're
        // wasting space"); in one column the tiles run the full width and the controls take their one wide row.
        if ScreenLayout.panelColumns(for: size, onHinge: onHinge) == 2 && !StrikeSlot.shows(model, aiming: showShotPanel) {
            twoColumns(size)
        } else if StrikeSlot.showsStrike(model, aiming: showShotPanel, explanations: explanations, showSteps: showSteps) {
            strikeColumn(size)
        } else {
            oneColumn(size)
        }
    }

    /// The cards that belong to the mode on the table and the mode's details.
    private var cards: some View {
        VStack(spacing: Theme.Space.sm) {
            // 0.7.7 achievements: the achievement note, first card, on the panel's half (nothing over the table).
            AchievementToast(model: model, style: .card)
            WhatIfCard(model: model)
            // 0.7.7 every-world: the every-surface fan's card (only one of the two shows).
            EveryWorldCard(model: model)
            ComparisonCard(model: model)
            OpeningCard(model: model)
            LensCalloutCard(model: model)
            TrickShotCard(model: model)
            LessonCard(model: model)
            EightBallCard(model: model)
            PlayCards(model: model)
            StrokeCards(model: model)
            // What See the contact stopped on (RetryWords).
            ContactArrivalLine(model: model)
            if showShotPanel { EquipmentCard(model: model) }
            NotebookDossier(model: model)
        }
    }

    /// The panel's lower edge outside the strike column: Continue while a guided Lens replay holds a moment, the
    /// console's controls on their own panel while "Aim" is open, then the reel and the tabs. At the bottom so a thumb
    /// reaches them while the other hand aims on the table.
    private func lowerEdge() -> some View {
        VStack(spacing: Theme.Space.sm) {
            continueRow
            if showShotPanel {
                // The console's controls on their own panel (the strike column puts them in the console card instead).
                ShotPanel(model: model, isOpen: $showShotPanel,
                          onChromeHeight: { h in if abs(h - shotChromeMeasured) > 0.5 { shotChromeMeasured = h } })
                    .transition(.opacity)
            }
            if !reelOnStage { reelAndTabs }
        }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: showShotPanel)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: showsContinue)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bottomMeasured = $0 }
    }

    /// Continue for a held Lens moment: the notebook has no caption strip with its own Continue, and the story's rows
    /// only jump the clock (0.7.5 layouts item 4). Not while the opening runs (review fix).
    @ViewBuilder private var continueRow: some View {
        if showsContinue {
            HStack {
                Spacer(minLength: 0)
                ContinueButton(model: model)
            }
            .transition(.opacity)
        }
    }

    /// The reel (only after a shot; a "Last shot" button while aiming) and the Physics Lens, Ride and Aim tabs, which
    /// PlaybackControls holds back until the first shot.
    private var reelAndTabs: some View {
        PlaybackControls(model: model, shotPanelOpen: $showShotPanel, compact: onHinge)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { playbackMeasured = $0 }
    }

    /// The lower edge's height before it has been measured once: the reel and tabs alone (about 110), or with the
    /// console's controls (about 520), plus about one button's row (50) while Continue shows.
    private var bottomHeight: CGFloat {
        bottomMeasured > 0 ? bottomMeasured : (showShotPanel ? 520 : 110) + (showsContinue ? 50 : 0)
    }

    /// Continue shows on the lower edge while a guided replay holds a moment, except during the opening (review fix).
    private var showsContinue: Bool { model.holding && model.openingStage == .none }

    /// The Lens colour key, in its own row directly under the top bar whenever the Lens is up, whether Explanations is
    /// on or off (it used to sit in the story's header, so it vanished with the story). Measured for the height budgets.
    @ViewBuilder
    private var keyRow: some View {
        if model.lensOn {
            LensLegendChip()
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { keyMeasured = $0 }
                .transition(.opacity)
        }
    }

    /// The key row's height in a budget: nothing with the Lens down; before the first measurement, one chip row (34).
    private var keyHeight: CGFloat {
        model.lensOn ? (keyMeasured > 0 ? keyMeasured : 34) : 0
    }

    /// UI rethink package 8: what the marks on the table half mean, only across the hinge (elsewhere the layers still
    /// label the cloth themselves) and only when there is a mark to explain.
    private var markParts: [TableMarksWords.Part] {
        onHinge ? TableMarksWords.parts(model: model, aiming: showShotPanel, aimGuide: aimGuide) : []
    }

    /// The table marks' line, directly under the top bar across the hinge (the top line of the panel: the labels the
    /// table half no longer draws). Measured for the height budgets; nothing at all when there is nothing to say.
    @ViewBuilder
    private var marksRow: some View {
        let parts = markParts
        if !parts.isEmpty {
            TableMarksLine(parts: parts)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { marksMeasured = $0 }
                .transition(.opacity)
        }
    }

    /// The marks line's room in a budget, its gap included: nothing while it is not shown; before the first
    /// measurement, one line of label text (24).
    private var marksRoom: CGFloat {
        markParts.isEmpty ? 0 : (marksMeasured > 0 ? marksMeasured : 24) + gap
    }

    /// The cards block, reporting its natural height (for the commentary's room and the fade at the bottom).
    private var measuredCards: some View {
        cards.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardsHeight = $0 }
    }

    /// The numbers strip shows in free play and matches with Your shot closed, and never while the opening runs: its
    /// surface card carries the friction figures, and the first minute is one instruction beside a racked table
    /// (0.7.5 layouts item 6, with NotebookStory's one line).
    private var showsNumbers: Bool {
        !modeActive && !showShotPanel && !typeSize.isAccessibilitySize && model.openingStage == .none
            // 0.7.10 wiring: only when the strip has something to draw (NotebookNumbers' own rule): a shot's tiles, or
            // with Explanations off the surface card. Before a shot with Explanations on it is empty, and its room
            // would be held blank. (While aiming the strike slot holds that place, and the line above already says no.)
            && (NotebookStory.hasShot(model) || !explanations)
    }

    /// One column, read like a book: top bar, cards, the commentary taking all the room left, the numbers, then the
    /// aiming and playback controls at the lower edge. The cards come first and keep all the height they need; the
    /// commentary gets what remains, and is left out (so the cards are not squeezed) when less than a few rows' worth
    /// remains, as while aiming a trick shot.
    private func oneColumn(_ size: CGSize) -> some View {
        // The fixed parts: padding (32), top bar (40), the Lens key's row, the lower edge, the numbers, and the gaps
        // between blocks (one more while the key row shows).
        let numbersHeight: CGFloat = showsNumbers ? (numbersMeasured > 0 ? numbersMeasured : 128) : 0
        let gaps = CGFloat((showsNumbers ? 4 : 3) + (model.lensOn ? 1 : 0)) * gap
        let free = size.height - 2 * Theme.Space.md - Theme.Size.minHit - keyHeight - bottomHeight - numbersHeight - gaps
            - marksRoom  // UI rethink package 8
        let storyMinimum: CGFloat = 140
        // 0.7.10 strike: the slot also holds the strike panel, which shows with Explanations off as well (StrikeSlot).
        let showsStory = (explanations || StrikeSlot.shows(model, aiming: showShotPanel)) && free - cardsHeight >= storyMinimum
        let cardsMax = max(120, showsStory ? free - storyMinimum : free)
        let overflows = cardsHeight > cardsMax
        return VStack(spacing: gap) {
            NotebookTopBar(model: model)
            marksRow
            keyRow
            FittingScroll(maxHeight: cardsMax) { measuredCards }
                .fadesAtBottom(overflows)
            if showsStory {
                StrikeSlot(model: model, leader: leader, aiming: showShotPanel, showSteps: $showSteps)
                    .frame(maxHeight: .infinity)  // 0.7.10 strike
            } else {
                Spacer(minLength: 0)
            }
            if showsNumbers {
                NotebookNumbers(model: model)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { numbersMeasured = $0 }
            }
            lowerEdge()
        }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.lensOn)
        .padding(.horizontal, margin)
        .padding(.vertical, Theme.Space.md)
    }

    /// The column while "Your strike" shows (UI rethink package 4): the top bar, the Lens key, the mode's cards (capped
    /// at a fifth of the height, scrolling past it), then one console card holding "Your strike" (heading, sentence and
    /// the live figures, at their own height, scrolling past what the controls leave them) and the controls, which take
    /// all the height left and grow the tip picture and dial into it; under the card, Continue when a Lens moment holds,
    /// then the reel or its "Last shot" button and the tabs. Nothing is stretched to fill but the controls.
    /// The height the cards take: their own, up to the cap, plus their gap; nothing without cards.
    private func cardsShown(_ cap: CGFloat) -> CGFloat { cardsHeight > 0 ? min(cardsHeight, cap) + gap : 0 }

    private func strikeColumn(_ size: CGSize) -> some View {
        let cardsMax = max(100, size.height * 0.2)
        let padding = Theme.Space.cardPadding(device)
        // UI rethink package 1: the measured parts (the status and hint lines, the reel and tabs, Continue, the key),
        // never guesses. The controls keep at least their smallest height; the strike's figures take the rest and scroll
        // past it, so Shoot is never pushed out of sight.
        let reelRoom: CGFloat = reelOnStage ? 0 : max(Theme.Size.minHit, playbackMeasured) + gap
        let lowerFixed = reelRoom + (showsContinue ? Theme.Size.minHit + gap : 0)
        let keyRoom = model.lensOn ? keyHeight + gap : 0
        let controlsMin = ShotPanel.consoleMinimumHeight(width: size.width - 2 * margin - 2 * padding)
            + max(Theme.Space.lg, shotChromeMeasured)
        // Split into named parts so the type checker has short sums to solve (one long CGFloat chain is slow to check).
        let topRoom: CGFloat = 2 * Theme.Space.md + Theme.Size.minHit + gap + keyRoom + marksRoom
        let cardRoom: CGFloat = cardsShown(cardsMax) + 2 * padding + Theme.Space.md
        let taken: CGFloat = topRoom + lowerFixed + cardRoom + controlsMin
        let strikeMax: CGFloat = max(120, size.height - taken)
        return VStack(spacing: gap) {
            NotebookTopBar(model: model)
            marksRow
            keyRow
            FittingScroll(maxHeight: cardsMax) { measuredCards }
                .fadesAtBottom(cardsHeight > cardsMax)
                // With no card to show, its gap goes too, so the console starts right under the top bar.
                .padding(.bottom, cardsHeight > 0 ? 0 : -gap)
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                StrikeSlot(model: model, leader: leader, aiming: showShotPanel, showSteps: $showSteps,
                           strikeMaxHeight: strikeMax)
                if showShotPanel {
                    // The controls at their own natural height, first claim on the room (layout priority), so Shoot is
                    // always in sight; "Your strike" above takes what is left and scrolls (UI rethink package 4
                    // follow-up: with the console filling, a 900-point Mac window pushed Shoot under the edge).
                    ShotPanel(model: model, isOpen: $showShotPanel, framed: false,
                              onChromeHeight: { h in if abs(h - shotChromeMeasured) > 0.5 { shotChromeMeasured = h } })
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                        .transition(.opacity)
                }
            }
            .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
            // One console card: the kit's panel round "Your strike" and the controls together.
            .kitPanel()
            continueRow
            if !reelOnStage { reelAndTabs }
        }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.lensOn)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: showsContinue)
        .padding(.horizontal, margin)
        .padding(.top, Theme.Space.md)
        .padding(.bottom, Theme.Space.xs)
    }

    /// Two columns: the top bar, cards and the controls on the leading side, the commentary and the numbers on the
    /// other. Used when the panel is short and wide (the folding phone propped like a laptop, the band under the table
    /// on an iPad held upright) or wide enough for two readable columns (a large Mac window, a 13-inch iPad sideways).
    /// With Explanations off the commentary is not drawn, which left the second column blank (or holding only the
    /// numbers at its foot): the cards move there instead, above the numbers when they show, and the first column
    /// keeps the top bar, the key and the controls (0.7.5 layouts item 9).
    private func twoColumns(_ size: CGSize) -> some View {
        // 0.7.10 strike: the second column keeps the slot (the strike panel) with Explanations off too, outside the opening.
        let cardsBesideStory = explanations || StrikeSlot.shows(model, aiming: showShotPanel)
        // Padding (28), top bar (40), the key row and its gap, the lower edge and the gaps (30) are fixed; the cards
        // take the rest.
        let cardsMax = max(120, size.height - 2 * Theme.Space.sm - Theme.Size.minHit - keyHeight - (model.lensOn ? gap : 0)
                                 - bottomHeight - 2 * gap - marksRoom)
        // In the second column the cards have the whole height but the padding and, when shown, the numbers and a gap.
        let numbersRoom: CGFloat = showsNumbers ? (numbersMeasured > 0 ? numbersMeasured : 128) + gap : 0
        let cardsMaxAlone = max(120, size.height - 2 * Theme.Space.sm - numbersRoom)
        return HStack(alignment: .top, spacing: Theme.Space.sm) {
            VStack(spacing: gap) {
                NotebookTopBar(model: model)
                marksRow
                keyRow
                if cardsBesideStory {
                    FittingScroll(maxHeight: cardsMax) { measuredCards }
                        .fadesAtBottom(cardsHeight > cardsMax)
                }
                Spacer(minLength: 0)
                lowerEdge()
            }
            // Half the panel on a big screen, where the controls column holds the aiming controls too; the folding
            // phone keeps the share it was laid out with.
            .frame(width: size.width * (onHinge ? 0.44 : 0.5))
            VStack(spacing: gap) {
                if cardsBesideStory {
                    StrikeSlot(model: model, leader: leader, aiming: showShotPanel, showSteps: $showSteps)  // 0.7.10 strike
                        .frame(maxHeight: .infinity)
                } else {
                    FittingScroll(maxHeight: cardsMaxAlone) { measuredCards }
                        .fadesAtBottom(cardsHeight > cardsMaxAlone)
                    Spacer(minLength: 0)
                }
                if showsNumbers {
                    NotebookNumbers(model: model)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { numbersMeasured = $0 }
                }
            }
        }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.lensOn)
        .padding(Theme.Space.sm)
    }
}

// MARK: Top bar

/// The title row that would sit over the table on a phone: back to the menu, what is being played, the surface picker.
private struct NotebookTopBar: View {
    let model: ShowpieceModel

    /// The opening's own status while it tells its story, else the game or mode on the table.
    private var title: String {
        // 0.7.7 bullet-time: a frozen hit names its moment on the words half for the length of the freeze.
        if let words = model.bulletTime.statusWords { return words }
        // UI rethink package 4: the first minute is titled by what it is, "Break", on every device.
        if model.openingStage == .handOver { return ShotPanel.actionWord(racked: true) }
        if model.stage != .explore && model.stage != .lead { return model.stageTitle }
        if let match = model.match { return NotebookWords.gameName(match.rules.kind) }
        if DailyMode.showing(model) { return DailyShot.title }  // 0.7.10 daily: played as a trick shot, named as itself.
        if model.trickMode.isActive { return String(localized: "Trick shots") }
        if model.lessonMode.isActive { return String(localized: "Lessons") }
        // UI rethink package 8: the menu's own sentence-case name (TitleScreen), so the game uses one name.
        if model.eightBallMode.isActive {
            return String(localized: "Menu: behind the 8-ball", defaultValue: "Behind the 8-ball",
                          comment: "Main menu entry: the eight-ball situations to escape. Sentence case.")
        }
        return String(localized: "Free play")
    }

    var body: some View {
        // The worded controls where they fit whole; in a narrow column (a small Mac window) the same controls as icons,
        // never words cut to "B..." and "Me..." (UI rethink package 4 follow-up).
        // UI rethink package 8: the title gives way first. On the open folding phone's narrow panel the worded row
        // without the title comes before the icons; the icon row keeps a title that truncates rather than squeezing
        // the buttons. The title is also the panel's heading for VoiceOver, so it is spoken when it is not shown.
        ViewThatFits(in: .horizontal) {
            row(showsTitle: true)
            row(showsTitle: false)
            row(showsTitle: true).kitDevice(.phone)
        }
    }

    /// The design's order (UI rethink package 8, from the package 4 note): Back, the title, then Zoom, Share and Menu.
    /// During Ride the Ride chip takes Zoom's and Menu's place, with Share before it.
    private func row(showsTitle: Bool) -> some View {
        HStack(spacing: Theme.Space.sm) {
            MenuBackButton(model: model)
            if showsTitle {
                Text(verbatim: title)
                    .font(Theme.heading)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(-1)
                    .accessibilityAddTraits(.isHeader)
            } else {
                // Dropped from sight for room, still the panel's heading for VoiceOver.
                Color.clear.frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: title))
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            if model.rideStatus != nil {
                ClipShareButton(model: model)  // 0.7.7 clips: shown only while a clip is offered
                RideTitleChip(model: model)
            } else {
                // 0.7.10 everyone: zoom without a pinch or a double tap (TableZoomMenu).
                TableZoomMenuButton(model: model)
                ClipShareButton(model: model)  // 0.7.7 clips: shown only while a clip is offered
                SurfaceMenuButton(model: model)
            }
        }
    }
}

// MARK: The table marks' line (UI rethink package 8)

/// What the marks on the open folding phone's table half mean, in words: the labels the table layers draw on the cloth
/// everywhere else and leave off across the hinge (tableMarksOnly, LayoutFlags.swift). Each part names the mark as it
/// looks ("Ringed", "Dashed line") and what it means, from the same answers the layers draw from, so the line and the
/// marks always agree.
enum TableMarksWords {
    struct Part: Identifiable, Equatable {
        let id: String
        /// The mark as it looks on the cloth, in the secondary face (left out when the line is short of room).
        let mark: String
        /// What the mark means.
        let words: String
        /// A measured value after the words, in the figure face (the fork's turn).
        var figure: NumberStyle.Reading? = nil
        /// Words after the figure ("left").
        var after: String = ""

        /// The whole part as one phrase for VoiceOver ("Solid line, ball goes here 1.2° left").
        var spoken: String {
            [mark, [words, figure?.text ?? "", after].filter { !$0.isEmpty }.joined(separator: " ")]
                .joined(separator: ", ")
        }
    }

    /// The parts for what is on the table now. `aiming`: "Your shot" is open, so AimOverlay is up; `aimGuide`: the
    /// Aim guide option (off, the badge and the fork are not drawn, so they are not named either).
    @MainActor
    static func parts(model: ShowpieceModel, aiming: Bool, aimGuide: Bool) -> [Part] {
        var parts: [Part] = []
        // When AimOverlay draws at all (its own guard in draw(_:size:)).
        let drawsAim = aiming && model.aimReady && !model.placingCueBall && model.layout.count == 16
            && NextShot.isOnTable(model.aimOrigin)
        if drawsAim {
            // The target-ball badge's words: the ball the guide's ring is round.
            if let target = TargetBallBadge.targetWords(for: model, aimGuide: aimGuide) {
                parts.append(Part(id: "target",
                                  mark: String(localized: "Table marks: ringed", defaultValue: "Ringed",
                                               comment: "Names the ring drawn round the ball the aim hits first."),
                                  words: target))
            }
            // The side-spin fork: the dashed prong is the cue's line, the bright one the ball's, turned by the figure
            // the table half still draws bare.
            if aimGuide, let fork = AimGeometry.fork(for: model) {
                parts.append(Part(id: "cue",
                                  mark: String(localized: "Table marks: dashed line", defaultValue: "Dashed line",
                                               comment: "Names the thin dashed line drawn along the cue's own aim."),
                                  words: AimFork.cueLabel))
                parts.append(Part(id: "ball",
                                  mark: String(localized: "Table marks: solid line", defaultValue: "Solid line",
                                               comment: "Names the bright aim line the ball really leaves along."),
                                  words: AimFork.ballLabel,
                                  figure: NumberStyle.angle(degrees: abs(fork.turnDegrees)),
                                  after: fork.turnDegrees > 0
                                      ? String(localized: "Table marks: left", defaultValue: "left",
                                               comment: "After a turn in degrees: the ball leaves to the shooter's left.")
                                      : String(localized: "Table marks: right", defaultValue: "right",
                                               comment: "After a turn in degrees: the ball leaves to the shooter's right.")))
            }
            // The mechanical bridge's "Bridge" pill.
            if model.restInUse {
                parts.append(Part(id: "bridge",
                                  mark: String(localized: "Bridge"),
                                  words: String(localized: "Table marks: the cue rests on it",
                                                defaultValue: "the cue rests on it",
                                                comment: "After the word Bridge: the cue lies on the mechanical bridge.")))
            }
        }
        // The last try's rest ring (GhostOverlay draws it while a ghost shows and no other future does).
        if let ghost = model.ghost, !model.otherFutureShowing, !ghost.cueBallScratched {
            parts.append(Part(id: "lastTry",
                              mark: String(localized: "Table marks: dashed ring", defaultValue: "Dashed ring",
                                           comment: "Names the small dashed ring where the last try's cue ball stopped."),
                              words: String(localized: "Last try")))
        }
        // A trick shot's answer path and its rest ring (TrickShotViews).
        if model.trickMode.answerPathOnCloth?.rest != nil {
            parts.append(Part(id: "answer",
                              mark: String(localized: "Table marks: long dashes", defaultValue: "Long dashes",
                                           comment: "Names the long-dashed path of a trick shot's answer."),
                              words: String(localized: "Answer")))
        }
        // The what-if's other future (WhatIfOverlay).
        if model.whatIf.isShowing {
            parts.append(Part(id: "whatIf",
                              mark: String(localized: "Table marks: violet", defaultValue: "Violet",
                                           comment: "Names the violet paths of the other future in a what-if."),
                              words: WhatIfWords.title))
        }
        // The every-surface fan (EveryWorldOverlay): its path titles leave the cloth too; the card names each surface.
        if model.everyWorld.isShowing {
            parts.append(Part(id: "everyWorld",
                              mark: String(localized: "Table marks: coloured paths", defaultValue: "Coloured paths",
                                           comment: "Names the coloured paths of the same shot on every other surface."),
                              words: EveryWorldWords.title))
        }
        return parts
    }
}

/// The panel's top line across the hinge: one line of what the table half's marks mean. When the marks' names do not
/// fit it drops them and keeps the meanings; when even that does not fit (a large text size) each part takes a line of
/// its own. One VoiceOver element.
private struct TableMarksLine: View {
    let parts: [TableMarksWords.Part]
    @Environment(\.palette) private var palette

    var body: some View {
        ViewThatFits(in: .horizontal) {
            line(marks: true)
            line(marks: false)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                ForEach(parts) { piece($0, marks: true).lineLimit(2) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: String(localized: "Table marks",
                                                  comment: "VoiceOver name of the panel line saying what the table's marks mean.")))
        .accessibilityValue(Text(verbatim: parts.map(\.spoken).joined(separator: ". ")))
    }

    private func line(marks: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
            ForEach(parts) { piece($0, marks: marks).lineLimit(1) }
        }
    }

    private func piece(_ part: TableMarksWords.Part, marks: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
            if marks {
                Text(verbatim: part.mark)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
            }
            Text(verbatim: part.words)
                .font(Theme.label)
                .foregroundStyle(palette.paper)
            if let figure = part.figure { KitFigure(figure, size: .inline) }
            if !part.after.isEmpty {
                Text(verbatim: part.after)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper)
            }
        }
    }
}

private extension View {
    /// When a block is taller than its room and scrolls, its last lines fade out to say there is more.
    func fadesAtBottom(_ overflows: Bool) -> some View {
        mask {
            LinearGradient(stops: [.init(color: .black, location: 0),  // design-lint: allow a mask's opaque stop, never drawn
                                   .init(color: .black, location: overflows ? 0.9 : 1),  // design-lint: allow a mask stop
                                   .init(color: overflows ? .clear : .black, location: 1)],  // design-lint: allow a mask stop
                           startPoint: .top, endPoint: .bottom)
        }
    }
}
