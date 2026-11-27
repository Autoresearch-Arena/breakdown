// Author: Claude Haiku 5.5 High
// Date: 18-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 7, "The front door and the sheets",
//          plans/26-Nov-2026-ui-rethink-plan.md and mockup-menu-ipad.png: the menu is Shot of the day, Continue when
//          something is in progress, Play (the cyan primary when nothing is), Trick shots, Behind the 8-ball and
//          Lessons, each with its sentence and, inside the row, the kit's progress chip (hidden until something is
//          earned), and Shot of the day its difficulty dots; then three tiles, Achievements, How to play and Options.
//          No "Today" heading. "Watch the intro" moved
//          into How to play (a row there, through the frontDoorWatchIntro environment value); Tables moved into the Play
//          list and onto the notebook page's "The table" card, which shows the table on screen with its real figures.
//          Everything sits on the panel surface (opaque, rule edge, medium corners), rows are sunken list rows, no
//          glass and no system grey or blue: the card over a dimmed table, the upright phone's sheet, and the notebook's
//          page, which now fills its column from the top and takes two columns on a wide page (the upright iPad's
//          bottom panel), so there is no empty band. The computer's level is three chips instead of the system's
//          segmented control; the replace question uses the kit's primary, secondary and quiet buttons. How to play is
//          the kit's SheetPage with panel groups and list rows; its pushed pages sit on the ground with Done top
//          right; list numbers are plain sans in paper2. Every action, keyboard shortcut and VoiceOver reading is kept.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md:
//          How to play names the Lens paths by shape as well as colour (dashed and solid, as every player now sees
//          them), the Controls page names the zoom button and menu, the keys and the controller buttons of the shot of
//          the day, and a last row links to the page for teachers (TeachersLinkRow).)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, plans/25-Nov-2026-front-door-and-table-view-plan.md
//          Stage 1 and the words plan's Part A row 6: one line per row (each row's sentence is now its VoiceOver hint
//          and a line on How to play's new "The menu" page, MenuGuidePage); the intro paragraph under the name moved to
//          that page too. Three short groups replace one list of ten: Today (Continue, and the spot marked for Shot of
//          the day), Ways to play (Play a game, Trick shots, Behind the 8-Ball, Tables) and More (Learn, Achievements,
//          How to play, Options, Watch the intro, as one row of tiles). On an upright phone the menu is the game's name
//          at the top and a sheet over the lower half, with no veil, and the table framed between them (the two edges
//          go to the camera through MenuScreenState.uprightBand). The highlighted row is the game's own accent colour,
//          not the system's blue. The rows' words come from MenuGuide, one place, so the menu, its hints and How to
//          play say the same thing.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: MenuGuide.daily, so How to play's menu page lists
//          Shot of the day; its row is drawn from that entry like the others, today's state as its mark.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: a "Shot of the day" row above Play, built from
//          App/Daily/DailyMenuRow.swift's pieces, one marked line.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 achievements hooks, plans/23-Nov-2026-achievements-plan.md:
//          an Achievements row after Tables, with a mark of how many are earned whose symbol changes while some are
//          new, opening the Achievements page; each marked "// 0.7.7 achievements:".)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream menu, plans/22-Nov-2026-v076-phone-plan.md, bugs 54,
//          55 and 57: turning the phone keeps the menu screen that was open. The menu's own screens (the Play list, the
//          entrance, the How to play, Options and Tables sheets) live in one shared MenuScreenState instead of each
//          TitleScreen's own state, and leaving the screen only forgets them when the menu has really closed, so the
//          upright copy and the sideways copy show the same screen and the replace question survives the turn. With a
//          page binding handed in, How to play, Options and Tables open as the screen's own page sheet, which never goes
//          away when the phone turns. Play is its own catalog key, "Play a game", with a comment that it means a game,
//          never playback, and the level picker's label is "Computer level", not the cue-angle word. Entry names wrap
//          to two lines (all at the accessibility sizes) instead of ending in an ellipsis.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: the replace question asks only when that game
//          has a save, and Keep plays that save).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow review: the saved line is read through a closure
//          rather than by passing MatchWords.savedLine itself, so no actor-isolation conversion is asked of map.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream model-flow items 3, 4, 5 and 11: Trick shots, Learn and Behind the 8-Ball open their list alone
//          (model.showList), so two lists never stack; Continue match closes the menu and goes to the table only when
//          the saved match really loaded, and otherwise the menu stays (and the row goes, the model clears it); the
//          saved game's line is the match words' own (MatchWords.savedLine), one sentence for the menu and the Tables
//          pages; the computer's level is remembered across launches (the model stores it); the unused next-step
//          highlight is gone, so Continue is highlighted whenever there is something to go back to; the eight-ball
//          rules say that from behind the head line a ball also behind it cannot be hit first unless the cue ball
//          crosses the line; How to play's Mac minimum size applies only in a sheet, not as a notebook page; the
//          PURPOSE now says what a first launch really does.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 menus-entries: the computer plays all four table games, so
//          the Play list gains Bumper pool and Five-pin billiards against it, and the Play row's line and the menu's
//          intro say "four games". Trick shots moves directly under Play with a line that says what the shots are for
//          (watch one, see why it works, make it). The level picker is the model's shared computerLevel, the same
//          choice the Tables pages show (ComputerLevelPicker, below). How to play no longer opens with the lessons: it
//          ends with "Watch the trick shots", and the lessons are named there as an option.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.3: two players on one device is gone from the Play list; the Boss: passing one phone between two people is not a game to offer)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: playing the computer is the game's offer. The menu's intro and
//          the Play row's line name the computer, not a friend; the Play list opens on the computer's level and its
//          Eight-ball and Nine-ball rows, then Practice and Straight stroke, and two players on one device is a plain
//          "Two players" row at the end that opens its own short list. How to play calls the sliding paths magenta,
//          the Lens's colour now, and eight-ball's rules speak of you and your opponent.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.1: the "Next: Lesson ..." row is gone and Play, or Continue, is
//          the highlighted entry and sits above Learn; the intro line no longer says to learn first; the lessons are
//          offered, never pushed.)
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (now the main menu: Play or New game, Continue, Watch the break, How to
//          play and Options, reachable again at any time from the back button on the table; the instructions moved
//          into their own sheet so the menu is short).
// Edited: Claude Opus 5.5 High, 20-November-2026 (-jumpDemo joins the launch switches that skip the menu).
// Edited: Claude Opus 5.5 High, 20-November-2026 (-rideDemo skips the menu).
// Edited: Claude Opus 5.5 High, 20-November-2026 (trick shots are now the game's purpose: "Trick shots" is the first
//          and primary choice and opens the list of shots (TrickShotList, hosted by the table layer so a launch flag can
//          open it too); Continue, Free play and Watch the break follow. Free play and Watch the break leave trick-shot
//          mode. The one-line description and the first How to play step now say what the game is for.)
// Edited: Claude Opus 5.5 High, 21-November-2026 ("Behind the 8-Ball" under Trick shots in both menus opens its list
//          (EightBallList, hosted by EightBallTableLayer); Free play, New free game and Watch the break end it too).
// Edited: Claude Opus 5.5 High, 21-November-2026 (-trickAim and -pauseAt also skip the menu, for store screenshots).
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (the one-line description always wraps in full instead of being cut
//          off with an ellipsis, the card is centred by the scroll view rather than forced to the screen's height, and
//          How to play and Options stack when there is no room for them side by side, as on a folding phone's outer
//          screen).
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo: onHowTo and onOptions let the Duo panel show the menu as
//          one of its own pages, with no dimming veil and no sheets over the table.)
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (a Tables button opens TableList: a table is a game of its own, no longer a
//          section of the Surface menu).
// Edited: Claude Opus 5.5 High, 21-November-2026 (a menu a stranger can read: ordered by what a new player should do
//          next (Continue when something is in progress, then Play, Trick shots, Behind the 8-Ball, Tables, Watch the
//          intro, How to play, Options), every entry with one short line saying what it is and, where there is
//          progress to show, a small mark (trick shots made, medals won). Play opens a short list in the card itself:
//          Continue match when a saved one exists, Practice (free play), Eight-ball and Nine-ball. "Watch the break" is
//          now "Watch the intro". How to play gains a Rules section with a page each for eight-ball and nine-ball, in
//          our own plain words.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (opponent stream: the Play list gains "Against the computer", which
//          opens a third list in the same card: a level choice (Easy, Medium, Hard) with that level's record, then
//          Eight-ball and Nine-ball against the computer. Eight-ball and Nine-ball carry a small mark of games won out
//          of games played on this device (MatchRecord). Inline in the card, so it works as the notebook panel's menu
//          page on the open Duo, iPad and Mac.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens: How to play's Rules section also links the rules
//          of bumper pool, five-pin and bar billiards, TableRulesPage.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons stream: Learn, the six lessons (LessonList), is the first entry
//          after Continue, with its progress mark (lessons passed); it is the highlighted entry for a player with nothing
//          in progress and no lesson passed yet. Practice and Watch the intro end a lesson through the model.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hook: "Straight stroke" in the Play list's practice
//          options, the drill that judges how straight the player strokes (StrokeDrill).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 1, 3, 18, 39
//          and 52: the menu's own line says what the game is now (the table that shows its physics, six lessons, games
//          against a friend or the computer); the next step from stored progress is named and highlighted ("Next:
//          Lesson 2, Follow", then that lesson's trick shot, then a game against the easy computer), and a player with
//          no lesson passed gets it highlighted even when Continue is offered; Continue names the game it continues
//          (which game, against whom, whose shot); a new match that would replace the saved one asks first on the card
//          (MatchStartRequest, the same route the Mac's Game menu uses); the win record is kept per level against the
//          computer and left off the two-player rows; the veil lightens while the opening's replay plays behind the
//          menu on a later launch. How to play starts from Learn and the stroke as the input in use plays it
//          (FirstInstruction) and gains a Controls page: the push, the bridge finger, practice strokes, the Pencil, tap
//          to aim, pinch, pan, double tap, the pointer and keys, and the controller. The store scenes' launch flags
//          skip the menu.)
// PURPOSE: (Since UI rethink package 7 the entries and their order are as the latest Edited line says; the rest of
//          this paragraph is the history of what each entry does.)
//          The main menu, laid over the live table, dimmed, so the room stays visible behind it. (A first launch
//          skips it: the game opens on a racked pool table with the cue in hand and one line saying how to shoot,
//          with no opening replay first. The menu is reached from the back button on the table, and later launches
//          open on it.)
//          It names the game and offers, in three groups since 0.7.10 (Today, Ways to play, More): Continue (whatever is on the
//          table, or the saved match after a relaunch), Play (Continue match, then the computer's level and the four
//          games against it: Eight-ball, Nine-ball, Bumper pool and Five-pin billiards; then Practice and Straight
//          stroke), Trick shots, Learn (the lessons, offered, never pushed), Behind the 8-Ball, Tables, Watch the
//          intro (the showpiece opening with the slow-motion Physics Lens), How to play (the steps, the controls and
//          the rules, in a sheet) and Options (a sheet). Nothing here offers two people sharing one device.
//          It changes the model only through its menu methods (closeMenu, startGame, watchBreak, playTable via
//          TableList), the match methods of the model contract (startMatch through MatchStartRequest,
//          continueSavedMatch), the shared computerLevel, and the modes' list switches and end(). Launch switches that
//          open a specific screen for testing skip it, so the screenshots those switches take stay as before.
// SRP/DRY check: Pass - menu and instructions only. Options live in GameSettings; fonts come from Theme, colours from
//          Palette, and the controls named in the instructions are the real labels in PlaybackControls, ShotPanel and
//          AimOverlay. Progress is read from the modes (TrickShotMode.isDone, EightBallMode.medals), never stored here.
//          The rules pages describe what the rules engine does (BreakdownRules) in words; they hold no rule logic.
import BreakdownAuthored
import BreakdownRules
import SwiftUI

// MARK: A new match that may replace the saved one

/// A new match the player asked for. When a match is saved on the device (one save slot), the menu card asks before
/// starting it (item 18); the Mac's Game menu sends its requests through the same card, so there is one place that
/// asks. Held by ShowpieceView, handed to the menu and published to the menu bar as a focused value.
struct MatchStartRequest: Equatable {
    let kind: MatchKind
    /// How many play (bar billiards also plays alone); nil is the game's usual two.
    var players: Int? = nil
    /// The computer's level for the second seat; nil for people only.
    var computer: ComputerLevel? = nil

    /// Starts it: any trick shot, situation or lesson ends, the model racks the match and closes the menu (closing it
    /// here as well is harmless and keeps the table in view whatever the model does first).
    @MainActor func start(on model: ShowpieceModel) {
        model.trickMode.end(); model.eightBallMode.end()
        model.startMatch(kind, players: players, computer: computer)
        model.closeMenu()
    }
}

// MARK: The menu's own screens, shared by every copy of the menu

/// Which of the menu's own screens is open, kept outside any one TitleScreen (bug 54). Upright the menu is drawn on the
/// stage; turned sideways it is a second TitleScreen over the whole window (ShowpieceView menuOnStage / menuOverWindow),
/// and on a folding phone it moves into the notebook panel. Those are different views, so state kept in any one of them
/// was thrown away when the phone turned: the Play list fell back to the main list, a sheet slid away and the card faded
/// in again from nothing. Every TitleScreen reads this one shared instance instead, and it is forgotten only when the
/// menu really closes (TitleScreen's onDisappear checks model.menuOpen), so the next opening starts on the main list.
/// The replace question itself (MatchStartRequest) stays with ShowpieceView, which the Mac's Game menu also sets.
@MainActor @Observable
final class MenuScreenState {
    static let shared = MenuScreenState()

    /// The gentle entrance has played. Kept, so a turned phone shows the card at once instead of fading it in again.
    var shown = false
    /// How to play, Options or Tables as the menu's own sheet (used only when no page binding is handed in). One switch,
    /// as ShowpieceView's own page is, since only one of them is ever open.
    var sheet: NotebookPage?
    /// The Play list (the computer's level and its four games, Practice, Straight stroke) replaces the main list
    /// inside the same card. The level itself lives on the model (computerLevel), shared with the Tables pages.
    var playListOpen = false
    /// 0.7.10 frontdoor: on an upright phone the open menu is the game's name at the top and a sheet over the lower
    /// half, with the table framed between them. The name's bottom edge and the sheet's top edge in StageSpace, written
    /// by that layout as it is laid out (nil until measured).
    var uprightNameBottom: Double?
    var uprightSheetTop: Double?

    private init() {}

    /// 0.7.10 frontdoor: the band the table is framed into on an upright phone while the menu is up (from under the
    /// name to the top of the sheet), or nil until both edges are measured. ShowpieceView hands it to the camera in
    /// place of the hidden title row and bottom bar.
    var uprightBand: (top: Double, bottom: Double)? {
        guard let top = uprightNameBottom, let bottom = uprightSheetTop, bottom > top else { return nil }
        return (top, bottom)
    }

    /// The menu closed: back to the main list, no sheet, and the entrance plays again next time.
    func menuClosed() {
        shown = false
        sheet = nil
        playListOpen = false
        uprightNameBottom = nil
        uprightSheetTop = nil
    }
}

struct TitleScreen: View {
    let model: ShowpieceModel
    /// Play opens the aiming controls on the fresh rack; the screen owns that switch, so it is handed in.
    let onPlay: () -> Void
    /// On a folding phone the menu is a page of the side panel, which has its own pages for How to play and Options; the
    /// panel hands these in, and the menu then neither dims the screen nor opens sheets over the table.
    var onHowTo: (() -> Void)? = nil
    var onOptions: (() -> Void)? = nil
    var onTables: (() -> Void)? = nil
    // 0.7.7 achievements: the notebook's handler for the Achievements page (nil: the screen's page or the menu's sheet).
    var onAchievements: (() -> Void)? = nil
    /// The screen's own page switch (ShowpieceView's NotebookPage, shown there as a sheet outside the notebook). When it
    /// is handed in, How to play, Options and Tables open through it instead of this view's own sheets: that sheet hangs
    /// from the screen, not from this menu copy, so turning the phone neither closes it nor loses the rules page or
    /// table page open inside it (bug 54). Nil keeps the menu's own sheets.
    var page: Binding<NotebookPage?>? = nil
    /// A new match waiting for a yes because it would replace the saved one (ShowpieceView owns it; the Mac's Game menu
    /// can set it too). While set, the card asks instead of listing.
    @Binding var pendingMatch: MatchStartRequest?
    private var inline: Bool { onHowTo != nil }
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The wordmark's tracking (the display role's +6, wordmark only), scaled with the text size.
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = Theme.displayTracking
    /// 0.7.10 frontdoor: the phone held upright (the stage says so), where the menu is a sheet over the lower half.
    @Environment(\.phoneUpright) private var phoneUpright
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The device the kit lays out for, when the host says (the notebook sets it); see `device`.
    @Environment(\.kitDevice) private var kitDevice
    /// The height the upright sheet's rows want, measured, so the sheet is only as tall as they are (and scrolls past
    /// its cap). Starts near the usual height so the first frame is close.
    @State private var sheetContentHeight: CGFloat = 440
    /// UI rethink package 7: the width the menu has as the notebook's page, measured; a wide page (the upright iPad's
    /// bottom panel) lays the menu out in two columns so no band of it stands empty.
    @State private var inlineWidth: CGFloat = 0
    /// The menu's open screens and its entrance (see MenuScreenState). A computed read of the shared instance, so the
    /// view's memberwise initializer is unchanged and Observation tracks every property the body reads.
    private var state: MenuScreenState { .shared }

    /// The device the menu lays out for: the host's word when it gives one (the notebook: a big screen's column or the
    /// open folding phone's panel), else the phone, since every other host of the menu is a phone-sized screen.
    private var device: Theme.Device { kitDevice ?? (inline ? .big : .phone) }

    /// The menu's own sheet. Inline (the notebook) the panel shows these as its own pages, so a sheet left open before
    /// the phone unfolded is remembered but never presented over the table.
    private var sheetItem: Binding<NotebookPage?> {
        Binding(get: { inline ? nil : state.sheet }, set: { state.sheet = $0 })
    }

    /// Opens How to play, Options or Tables: the panel's page inline, the screen's page sheet when one is handed in,
    /// otherwise the menu's own sheet.
    private func openPage(_ target: NotebookPage, inline handler: (() -> Void)?) {
        if let handler { handler() } else if let page { page.wrappedValue = target } else { state.sheet = target }
    }

    /// One of the menu's own sheets, as ShowpieceView.pageSheet shows the same three.
    @ViewBuilder private func menuSheet(_ shown: NotebookPage) -> some View {
        let isOpen = Binding(get: { state.sheet != nil }, set: { if !$0 { state.sheet = nil } })
        switch shown {
        case .howTo: HowToPlaySheet(isOpen: isOpen, input: model.inputInUse)
        case .options: OptionsSheet(isOpen: isOpen)
        case .tables: TableList(model: model, onChosen: onPlay, onClose: { state.sheet = nil })
        // 0.7.7 achievements: the Achievements page as the menu's own sheet.
        case .achievements: AchievementList(model: model, onClose: { state.sheet = nil })
        }
    }

    /// The main menu's Play, and the title of the list it opens (bug 55): MenuGuide.play's own key.
    private static var playTitle: String { MenuGuide.play.title }

    /// True when a launch switch asks for a specific screen, in which case the menu stays out of the way.
    /// -noTitle is there for anyone who wants the table straight away. The store scenes (StoreScene.flags) put their
    /// own scene up still.
    static var launchSkipsTitle: Bool {
        let args = ProcessInfo.processInfo.arguments
        // -trick and -trickPlay open a trick shot on the table; -trickList is not here: its list opens over the menu.
        let switches = ["-noTitle", "-yourBreakDemo", "-yourShotDemo", "-aimDemo", "-aimDemoRack", "-retryDemo", "-jumpDemo",
                        "-rideDemo", "-trick", "-trickPlay", "-trickAim", "-pauseAt"] + StoreScene.flags
        return switches.contains { args.contains($0) }
    }

    /// How strongly the table is dimmed behind the menu. Lighter while the opening's slow Lens replay plays behind it on
    /// a later launch (item 52), so the moving trails read through; the card itself is the opaque panel, so the words
    /// keep their contrast either way.
    private var veilOpacity: Double { model.menuBackdropPlaying ? 0.5 : 0.62 }

    /// 0.7.10 frontdoor: the upright phone's layout (the name at the top, a sheet over the lower half). Inline (the
    /// notebook, the open folding phone) the menu keeps its own panel.
    private var sheetLayout: Bool { phoneUpright && !inline }
    /// The tallest the upright sheet gets, as a share of the screen's height inside the safe area; past it the rows
    /// scroll inside the sheet, so the table above always keeps some of the screen.
    private static let sheetMaxShare: CGFloat = 0.66
    /// The widest the centred card gets over a dimmed table (a phone turned sideways, a small window).
    private static let cardMaxWidth: CGFloat = 460
    /// UI rethink package 7: the notebook page's width from which the menu takes two columns (the upright iPad's bottom
    /// panel); the sideways iPad's and the Mac's side column stay one column.
    private static let twoColumnWidth: CGFloat = 640

    var body: some View {
        ZStack {
            if !inline {
                if sheetLayout {
                    // 0.7.10 frontdoor: no veil on the upright phone; the table above the sheet stays bright. A
                    // near-clear layer still takes the touches, so nothing behind the menu can be aimed or zoomed, and a
                    // soft shade at the top keeps the name readable over the room.
                    palette.ground.opacity(0.001).ignoresSafeArea().accessibilityHidden(true)
                    LinearGradient(colors: [palette.ground.opacity(0.85), palette.ground.opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 200)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                } else {
                    // A dimmed veil over the table so the menu reads clearly and the room is still there behind it.
                    // Inline the menu has its own panel and the table beside it stays bright.
                    palette.ground.opacity(veilOpacity).ignoresSafeArea()
                }
            }
            if sheetLayout {
                uprightMenu
            } else if inline {
                inlineMenu
            } else {
                ScrollView {
                    card
                        .padding(.horizontal, Theme.Space.md)
                        .padding(.vertical, Theme.Space.lg)
                        .frame(maxWidth: Self.cardMaxWidth)
                        .frame(maxWidth: .infinity)
                }
                // Centred while it fits, scrolls when it does not. A card forced to the screen's height squeezed the
                // description down to one cut-off line.
                .defaultScrollAnchor(.center, for: .alignment)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .opacity(state.shown ? 1 : 0)
        .transition(.opacity)
        .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: model.menuBackdropPlaying)
        .onAppear {
            // Only a menu that has just opened fades in; a copy built because the phone turned shows at once (bug 54).
            guard !state.shown else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) { state.shown = true }
        }
        // Back to the main list whenever the menu is opened again, and a question left unanswered when the menu goes
        // is dropped, so it never greets the player later. Only when the menu has really closed: this copy also goes
        // when the phone turns (the other layout builds its own copy) or when the notebook shows a page or list in its
        // place, and then the open screen and the question must stay (bug 54). The removal follows the change that
        // caused it, so model.menuOpen already says which it was.
        .onDisappear {
            guard !model.menuOpen else { return }
            state.menuClosed()
            pendingMatch = nil
        }
        .sheet(item: sheetItem) { shown in menuSheet(shown) }
    }

    /// The game's name and its line, in the serif face; the line in paper2 (cyan means "you can act here", never a
    /// tagline). VoiceOver reads the wordmark as the screen's heading. Leading in the notebook's column, centred
    /// elsewhere.
    private var wordmark: some View {
        VStack(alignment: inline ? .leading : .center, spacing: sheetLayout ? Theme.Space.xxs : Theme.Space.xs) {
            Text("BREAKDOWN")
                .font(Theme.display)
                .tracking(tracking)
                .foregroundStyle(palette.paper)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            Text("watch the physics think")
                .font(Theme.body)
                .fontDesign(.serif)
                .foregroundStyle(palette.paper2)
                .opacity(state.shown ? 1 : 0)
                .animation(reduceMotion ? nil : .smooth(duration: 0.8).delay(0.25), value: state.shown)
        }
        .frame(maxWidth: .infinity, alignment: inline ? .leading : .center)
    }

    /// Whichever list is up: the replace question, the Play list or the main list, crossfading between them.
    private var menuContent: some View {
        Group {
            if let request = pendingMatch {
                replaceList(request)
            } else if state.playListOpen {
                playList
            } else {
                mainList
            }
        }
        .transition(.opacity)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: state.playListOpen)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: pendingMatch)
        .kitDevice(device)
    }

    /// A phone turned sideways or a small window: the name and the lists on one panel card, centred over a dimmed table.
    private var card: some View {
        VStack(spacing: Theme.Space.lg) {
            wordmark
            menuContent
        }
        .kitPanel()
        .kitDevice(device)
    }

    /// UI rethink package 7: the menu as the notebook's page (the side column on a sideways iPad and the Mac, the open
    /// folding phone's panel, the upright iPad's full-width bottom panel). It fills the page from the top: the name on
    /// the ground, the lists on one panel, and the table on screen with its real figures (the way into Tables). A wide
    /// page puts the name and the table on the left and the lists on the right, so no band of the page stands empty.
    private var inlineMenu: some View {
        let twoColumns = inlineWidth >= Self.twoColumnWidth && !typeSize.isAccessibilitySize
        return ScrollView {
            Group {
                if twoColumns {
                    HStack(alignment: .top, spacing: Theme.Space.lg) {
                        VStack(alignment: .leading, spacing: Theme.Space.cardGap(device)) {
                            wordmark
                            tableCard
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        menuContent
                            .kitPanel()
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Theme.Space.cardGap(device)) {
                        wordmark
                            .padding(.bottom, Theme.Space.xs)
                        menuContent
                            .kitPanel()
                        tableCard
                    }
                }
            }
            .padding(Theme.Space.pageMargin(device))
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            if abs(inlineWidth - width) > 0.5 { inlineWidth = width }
        }
        .kitDevice(device)
    }

    /// The table on screen and its real figures (bed, ball, pockets), with Tables as the card's one quiet action.
    private var tableCard: some View {
        let kind = model.solvedTable
        return PanelCard(title: String(localized: "Menu: the table", defaultValue: "The table",
                                       comment: "Main menu card heading over the table on screen and its figures."),
                         titleAction: KitAction(String(localized: "Tables")) { openPage(.tables, inline: onTables) }) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(verbatim: kind.title)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
                TableFiguresLine(kind: kind)
            }
        }
    }

    /// 0.7.10 frontdoor: the upright phone. The name sits at the top over the room, the lists are a panel sheet over the
    /// lower half that reaches under the home indicator, and the table is framed between the two: both edges are
    /// written to MenuScreenState for the camera. The sheet is as tall as its rows and never taller than
    /// sheetMaxShare of the screen; the Play list, which is longer, scrolls inside it. UI rethink package 7: the sheet is
    /// the panel surface (opaque, rule edge, medium corners), not glass.
    private var uprightMenu: some View {
        let sheetShape = UnevenRoundedRectangle(topLeadingRadius: Theme.Corner.medium,
                                                topTrailingRadius: Theme.Corner.medium, style: .continuous)
        return GeometryReader { geo in
            VStack(spacing: 0) {
                wordmark
                    .padding(.top, Theme.Space.xs)
                    .padding(.horizontal, Theme.Space.pageMargin(.phone))
                    .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).maxY } action: { bottom in
                        if state.uprightNameBottom != bottom { state.uprightNameBottom = bottom }
                    }
                Spacer(minLength: Theme.Space.sm)
                ScrollView {
                    menuContent
                        .padding(.horizontal, Theme.Space.pageMargin(.phone))
                        .padding(.top, Theme.Space.md)
                        .padding(.bottom, Theme.Space.sm)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            if abs(sheetContentHeight - height) > 0.5 { sheetContentHeight = height }
                        }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: min(max(sheetContentHeight, 1), geo.size.height * Self.sheetMaxShare))
                .frame(maxWidth: .infinity)
                .background(alignment: .top) {
                    sheetShape
                        .fill(palette.panel)
                        .overlay { sheetShape.stroke(palette.rule, lineWidth: Theme.Size.hairline) }
                        .ignoresSafeArea(edges: .bottom)
                }
                .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).minY } action: { top in
                    if state.uprightSheetTop != top { state.uprightSheetTop = top }
                }
            }
        }
        .kitDevice(.phone)
    }

    // MARK: The main list

    /// Something to go back to: the game on the table, or after a relaunch the saved match.
    private var resumable: Bool { model.gameInProgress || model.hasSavedMatch }

    /// The gap between the menu's rows.
    private var rowGap: CGFloat { Theme.Space.xs }

    /// UI rethink package 7 (mockup-menu-ipad.png): Shot of the day, Continue when something is in progress (the
    /// screen's primary then), Play (the primary when nothing is), Trick shots, Behind the 8-ball and Lessons, then three
    /// tiles: Achievements, How to play and Options. No heading over the first part. "Watch the intro" moved into How to
    /// play; Tables is in the Play list and on the table card. Progress chips sit inside their rows and show only once
    /// something is earned.
    private var mainList: some View {
        VStack(alignment: .leading, spacing: rowGap) {
            // 0.7.10 daily: Shot of the day, first; its words and state are DailyMenuRow's.
            MenuRow(title: MenuGuide.daily.title, line: DailyMenuRow.line(model), chip: dailyChip,
                    spoken: DailyMenuRow.mark(model)?.spoken, difficulty: dailyDifficulty) {
                DailyMenuRow.open(model); onPlay()
            }
            // Continue first whenever something is in progress, as the screen's one primary; Return presses it.
            if model.gameInProgress {
                continueBlock(String(localized: "Continue"), line: liveLine) { model.closeMenu() }
            } else if model.hasSavedMatch {
                continueBlock(String(localized: "Continue match"), line: savedLine) { continueMatch() }
            }
            SectionLabel(Self.waysToPlayTitle)
                .padding(.top, Theme.Space.xs)
            if resumable {
                MenuRow(entry: MenuGuide.play) { state.playListOpen = true }
            } else {
                // Nothing to go back to: Play is the primary, on Return.
                PrimaryButton(Self.playTitle, fullWidth: true) { state.playListOpen = true }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityHint(Text(verbatim: MenuGuide.play.line))
            }
            // 0.7.4: the trick shots sit directly under Play, where people look first.
            MenuRow(entry: MenuGuide.tricks, chip: .progress(trickProgress.done, trickProgress.total),
                    spoken: String(localized: "\(trickProgress.done) of \(trickProgress.total) made")) {
                model.showList(.tricks)
            }
            MenuRow(entry: MenuGuide.eightBall, chip: .progress(medalProgress.done, medalProgress.total),
                    spoken: String(localized: "\(medalProgress.done) of \(medalProgress.total) medals won")) {
                model.showList(.eightBall)
            }
            // The lessons: offered, never pushed (never the primary).
            MenuRow(entry: MenuGuide.learn, chip: .progress(lessonProgress.done, lessonProgress.total),
                    spoken: String(localized: "\(lessonProgress.done) of \(lessonProgress.total) passed")) {
                model.showList(.lessons)
            }
            SectionLabel(String(localized: "More", comment: "Main menu group heading: the lessons, achievements, help, options and the intro"))
                .padding(.top, Theme.Space.xs)
            moreEntries
        }
    }

    /// Continue as the screen's primary, with the line saying what it goes back to under it.
    private func continueBlock(_ title: String, line: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            PrimaryButton(title, fullWidth: true) { action() }
                .keyboardShortcut(.defaultAction)
                .accessibilityHint(Text(verbatim: line))
            Text(verbatim: line)
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
        }
    }

    /// The second group's heading. Its own key: the plain "Play" is the playback button's word (bug 55).
    private static var waysToPlayTitle: String {
        String(localized: "Ways to play",
               comment: "Main menu group heading over Play a game, Trick shots, Behind the 8-Ball and Tables")
    }

    /// Achievements, How to play and Options as three tiles side by side. From the second size above the default a
    /// tile is too small for its name, so they become ordinary rows.
    @ViewBuilder private var moreEntries: some View {
        // 0.7.7 achievements: the list of physics the player has pulled off.
        let achievements: () -> Void = { openPage(.achievements, inline: onAchievements) }
        let howTo: () -> Void = { openPage(.howTo, inline: onHowTo) }
        let options: () -> Void = { openPage(.options, inline: onOptions) }
        let b = model.achievements
        let achievementSpoken = AchievementWords.menuSpoken(earned: b.earnedCount, total: b.total, new: b.newCount)
        if typeSize >= .xxLarge {
            MenuRow(entry: MenuGuide.achievements, chip: .progress(b.earnedCount, b.total), spoken: achievementSpoken,
                    action: achievements)
            MenuRow(entry: MenuGuide.howTo, action: howTo)
            MenuRow(entry: MenuGuide.options, action: options)
        } else {
            HStack(alignment: .top, spacing: rowGap) {
                // Sparkles while some are new since the list was last opened (the old mark's symbol), the outline
                // rosette otherwise.
                MenuTile(entry: MenuGuide.achievements, symbol: b.newCount > 0 ? "sparkles" : nil,
                         chip: .progress(b.earnedCount, b.total), spoken: achievementSpoken, action: achievements)
                MenuTile(entry: MenuGuide.howTo, action: howTo)
                MenuTile(entry: MenuGuide.options, action: options)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The live game's line: a match names itself (which game, against whom, whose shot); anything else is the table as
    /// it was left.
    private var liveLine: String {
        if model.match != nil, let summary = model.savedMatchSummary { return MatchWords.savedLine(summary) }
        return String(localized: "Back to the table, just as you left it.")
    }

    /// The saved match's line, named when the save can be read. The match words' own sentence (0.7.5), the same one
    /// the Tables pages show, so the menu and those pages name a saved game alike (which game, against whom, whose
    /// shot).
    private var savedLine: String {
        // An explicit closure rather than the function itself, so no actor-isolation conversion is asked of map.
        model.savedMatchSummary.map { MatchWords.savedLine($0) }
            ?? String(localized: "Pick up your saved match where you left it.")
    }

    /// Today's shot's chip: its tries or the streak once there is something to show (DailyMenuRow.mark); nothing before
    /// the first try with no streak, as every progress chip hides until something is earned.
    private var dailyChip: MenuChip? {
        guard let mark = DailyMenuRow.mark(model), mark.symbol != "circle" else { return nil }
        return .value(mark.text)
    }

    /// Today's shot's difficulty on the five-dot scale (mockup-menu-ipad.png), read from the day's bank entry, the
    /// same mapping the shot's own card uses (ModeDifficulty); nil if the entry's rating is not one the game knows.
    private var dailyDifficulty: Int? {
        let entry = DailyBank.entry(forDay: model.dailyMode.today)
        return TrickDifficulty(rawValue: entry.difficulty).map { ModeDifficulty.dots($0) }
    }

    /// Lessons passed out of the six.
    private var lessonProgress: (done: Int, total: Int) {
        (model.lessonMode.passedCount, Lessons.all.count)
    }

    /// Trick shots made out of the ones that can be played.
    private var trickProgress: (done: Int, total: Int) {
        let mode = model.trickMode
        let playable = TrickShots.all.filter { !$0.pending }
        return (playable.filter { mode.isDone($0) }.count, playable.count)
    }

    /// Medals won out of the situations there are.
    private var medalProgress: (done: Int, total: Int) {
        (model.eightBallMode.medals.count, EightBallSituations.all.count)
    }

    // MARK: The Play list

    /// The list's back step and title: "Back" in the quiet style, then the serif title.
    private func listHeader(_ title: String, back: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            QuietButton(String(localized: "Back"), systemImage: "chevron.backward") { back() }
                // The quiet button keeps its 44 point hit area; it spills into the gap above the title.
                .padding(.leading, -Theme.Space.xs)
            Text(verbatim: title)
                .font(Theme.title)
                .foregroundStyle(palette.paper)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The computer first: its level and its four games lead the list, so one tap on Play and one on a game starts a
    /// match against it. Practice, the stroke drill and the Tables page follow. The level is the model's
    /// (computerLevel), so a level picked here is the one the Tables pages show, and the reverse.
    private var playList: some View {
        VStack(alignment: .leading, spacing: rowGap) {
            listHeader(Self.playTitle) { state.playListOpen = false }
            if model.hasSavedMatch {
                continueBlock(String(localized: "Continue match"), line: savedLine) { continueMatch() }
            }
            SectionLabel(String(localized: "Against the computer"))
                .padding(.top, Theme.Space.xs)
            ComputerLevelPicker(model: model, leading: true)
            // On Return when no saved match is waiting; with one, Continue match keeps Return.
            MenuRow(title: String(localized: "Eight-ball"),
                    line: String(localized: "You against the computer. Claim a group, clear it, sink the 8."),
                    chip: recordChip(.eightBall), spoken: recordSpoken(.eightBall)) {
                start(MatchStartRequest(kind: .eightBall, computer: model.computerLevel))
            }
            .keyboardShortcut(model.hasSavedMatch ? nil : KeyboardShortcut.defaultAction)
            MenuRow(title: String(localized: "Nine-ball"),
                    line: String(localized: "You against the computer. Lowest ball first; sink the 9 to win."),
                    chip: recordChip(.nineBall), spoken: recordSpoken(.nineBall)) {
                start(MatchStartRequest(kind: .nineBall, computer: model.computerLevel))
            }
            // The other tables' games (0.7.4: the computer plays them too), named as the notebook and the Tables list
            // name them. The match itself puts its own table on (MatchMode, from the request's kind).
            MenuRow(title: NotebookWords.gameName(.bumperPool),
                    line: String(localized: "You against the computer. Bank your balls past the bumpers into your cup."),
                    chip: recordChip(.bumperPool), spoken: recordSpoken(.bumperPool)) {
                start(MatchStartRequest(kind: .bumperPool, computer: model.computerLevel))
            }
            MenuRow(title: NotebookWords.gameName(.fivePin),
                    line: String(localized: "You against the computer. Drive its ball into the pins. First to \(FivePinRules.standardTarget)."),
                    chip: recordChip(.fivePin), spoken: recordSpoken(.fivePin)) {
                start(MatchStartRequest(kind: .fivePin, computer: model.computerLevel))
            }
            SectionLabel(String(localized: "Menu: on your own", defaultValue: "On your own",
                                comment: "Main menu's Play list heading over Practice, Straight stroke and Tables: things played alone."))
                .padding(.top, Theme.Space.xs)
            MenuRow(title: String(localized: "Practice"),
                    line: String(localized: "Your own break on a fresh rack. No turns, no fouls.")) {
                model.trickMode.end(); model.eightBallMode.end(); model.startGame(); onPlay()
            }
            MenuRow(title: String(localized: "Straight stroke"),
                    line: String(localized: "Send the cue ball up the table and back. Does it return to the cue?")) {
                model.strokeDrill.begin(); onPlay()
            }
            // UI rethink package 7: Tables left the main list; it is a way to play, so it lives here.
            MenuRow(entry: MenuGuide.tables) { openPage(.tables, inline: onTables) }
        }
    }

    /// Games won out of games finished against the computer at one level, for one game; no chip before the first.
    private func recordChip(_ kind: MatchKind) -> MenuChip? {
        let r = MatchRecord.record(kind: kind, level: model.computerLevel)
        let played = r.won + r.lost
        guard played > 0 else { return nil }
        return .value(String(localized: "\(r.won)/\(played)"))
    }

    /// The same record for VoiceOver ("2 won of 5 played"); nil before the first.
    private func recordSpoken(_ kind: MatchKind) -> String? {
        let r = MatchRecord.record(kind: kind, level: model.computerLevel)
        let played = r.won + r.lost
        guard played > 0 else { return nil }
        return String(localized: "\(r.won) won of \(played) played")
    }

    // MARK: Replacing the saved match

    /// The save a new game of this kind would replace (each game keeps its own, 0.7.5).
    private func replacedLine(_ request: MatchStartRequest) -> String {
        MatchMode.savedSummary(for: request.kind).map { MatchWords.savedLine($0) } ?? savedLine
    }

    /// The one save slot is taken: say which game it holds and ask before a new one replaces it (item 18). Keeping it is
    /// the primary, starting the new game the secondary, Cancel quiet.
    private func replaceList(_ request: MatchStartRequest) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(String(localized: "Replace your saved game?"))
                .font(Theme.title)
                .foregroundStyle(palette.paper)
                .accessibilityAddTraits(.isHeader)
            Text(([replacedLine(request), String(localized: "A new game ends it for good.")]).joined(separator: " "))
                .font(device == .phone ? Theme.bodyCompact : Theme.body)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(String(localized: "Keep my saved game"), fullWidth: true) {
                pendingMatch = nil
                continueMatch(kind: request.kind)
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityHint(Text(verbatim: replacedLine(request)))
            SecondaryButton(String(localized: "Start the new game"), fullWidth: true) {
                pendingMatch = nil
                request.start(on: model)
                onPlay()
            }
            .accessibilityHint(Text(verbatim: NotebookWords.gameName(request.kind)))
            QuietButton(String(localized: "Cancel")) { pendingMatch = nil }
                .keyboardShortcut(.cancelAction)
                .frame(maxWidth: .infinity)
        }
    }

    /// A new match: straight away when nothing is saved, otherwise after a yes on the card.
    private func start(_ request: MatchStartRequest) {
        if model.hasSavedMatch(request.kind) {
            pendingMatch = request
            return
        }
        request.start(on: model)
        onPlay()
    }

    /// Continue match: onto the table only when the saved match really loaded (0.7.5). A save that does not load
    /// leaves the menu up, and the model clears the row, so a Continue that does nothing is never left on offer. The
    /// model ends any trick shot or situation itself once the save loads, so a failed Continue ends nothing.
    private func continueMatch(kind: MatchKind? = nil) {
        guard model.continueSavedMatch(kind: kind) else { return }
        model.closeMenu()
        onPlay()
    }
}

// MARK: The computer's level

/// The computer's level (Easy, Medium, Hard) as three chips, the chosen one in the selected state (a cyan edge), and one
/// line on what that level plays like. Bound to the model's computerLevel, so the main menu's Play list and the Tables
/// pages of bumper pool and five-pin show and set one shared choice, remembered on the device across launches (0.7.5).
/// The model is @Observable, so reading computerLevel here redraws the chips and the line whichever screen changed it.
/// UI rethink package 7: chips in place of the system's segmented control, whose grey track the design has no place for.
struct ComputerLevelPicker: View {
    let model: ShowpieceModel
    /// Centred in a card; leading on a Tables page and in the Play list, where everything else is leading.
    var leading = false
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: leading ? .leading : .center, spacing: Theme.Space.xs) {
            HStack(spacing: Theme.Space.xs) {
                ForEach(ComputerLevel.allCases, id: \.self) { level in
                    let chosen = level == model.computerLevel
                    Button {
                        model.computerLevel = level
                    } label: {
                        Chip(word: level.title, selected: chosen)
                            .frame(minHeight: Theme.Size.minHit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: level.title))
                    .accessibilityAddTraits(chosen ? .isSelected : [])
                }
            }
            // Its own key (bug 55): the plain "Level" is the cue-angle word, translated as flat. Heard, not seen.
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(String(localized: "Computer level",
                                            comment: "Label of the picker for how well the computer plays: Easy, Medium or Hard. Read aloud by VoiceOver.")))
            Text(model.computerLevel.line)
                .font(Theme.body)
                .foregroundStyle(palette.paper2)
                .multilineTextAlignment(leading ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: leading ? .leading : .center)
    }
}

// MARK: The menu's entries, in words

/// One main-menu entry as words: its symbol, its name and the one sentence saying what it opens.
struct MenuEntry {
    let symbol: String
    let title: String
    let line: String
}

/// 0.7.10 frontdoor: the main menu's entries in one place. The menu shows each name with its sentence under it (UI
/// rethink package 7); How to play's "The menu" page (MenuGuidePage) lists every name with its sentence. The keys are
/// the ones the menu has always used, so the translations carry over, except the two names package 7 put in sentence
/// case and the menu's own words ("Lessons", "Behind the 8-ball").
enum MenuGuide {
    /// The menu's one line about the game (item 39), the lead of the menu page in How to play since 0.7.10.
    static var intro: String {
        String(localized: "A pool table that shows its own physics. Play four games against the computer, and see why every shot went where it did.")
    }

    /// Play a game: its own key (bug 55), since the plain "Play" is the playback button's word.
    static var play: MenuEntry {
        MenuEntry(symbol: "circle.grid.cross",
                  title: String(localized: "Play a game",
                                comment: "Main menu entry and the title of the list it opens: play a game against the computer, or practise. A game, never media playback."),
                  line: String(localized: "Four games against the computer, or practise on your own."))
    }
    static var tricks: MenuEntry {
        MenuEntry(symbol: "wand.and.sparkles", title: String(localized: "Trick shots"),
                  line: String(localized: "Watch a shot that looks impossible, see why it works, then make it."))
    }
    /// UI rethink package 7: sentence case, as every title is ("Behind the 8-ball").
    static var eightBall: MenuEntry {
        MenuEntry(symbol: "8.circle",
                  title: String(localized: "Menu: behind the 8-ball", defaultValue: "Behind the 8-ball",
                                comment: "Main menu entry: the eight-ball situations to escape. Sentence case."),
                  line: String(localized: "Escape the nastiest spots in eight-ball and score each way out."))
    }
    static var tables: MenuEntry {
        MenuEntry(symbol: "rectangle", title: String(localized: "Tables"),
                  line: String(localized: "Other tables, each a game of its own."))
    }
    /// The six lessons, named "Lessons" on the menu (UI rethink package 7), the notebook's word for them.
    static var learn: MenuEntry {
        MenuEntry(symbol: "graduationcap", title: String(localized: "Lessons"),
                  line: String(localized: "Six short lessons: stop, follow, draw, cut, curve and jump."))
    }
    static var achievements: MenuEntry {
        MenuEntry(symbol: "rosette", title: String(localized: "Achievements"),
                  line: String(localized: "Physics you have pulled off, with the shot that did it."))
    }
    static var howTo: MenuEntry {
        MenuEntry(symbol: "questionmark.circle", title: String(localized: "How to play"),
                  line: String(localized: "The controls, the Lens and the rules of each game."))
    }
    static var options: MenuEntry {
        MenuEntry(symbol: "slider.horizontal.3", title: String(localized: "Options"),
                  line: String(localized: "Sound, vibration, the aim guide and the tips."))
    }
    /// In How to play since UI rethink package 7, no longer on the main menu.
    static var watchIntro: MenuEntry {
        MenuEntry(symbol: "sparkles", title: String(localized: "Watch the intro"),
                  line: String(localized: "The opening break again, slowed down under the Physics Lens."))
    }

    /// 0.7.10 wiring: Shot of the day, first on the menu. The same name the shot's own screens use (DailyWords.title)
    /// and the menu's general sentence about it (DailyWords.menuNew); today's state is the row's line and chip.
    static var daily: MenuEntry {
        MenuEntry(symbol: "calendar", title: DailyWords.title, line: DailyWords.menuNew)
    }

    /// Every entry, in the menu's order, for the menu page in How to play (UI rethink package 7: Tables is inside Play,
    /// the intro inside How to play, so both are listed after the menu's own entries).
    static var all: [MenuEntry] {
        [daily, play, tricks, eightBall, learn, achievements, howTo, options, tables, watchIntro]
    }
}

// MARK: One menu entry

/// A row's chip: a progress count (the kit's ProgressChip: hidden until one is earned, a tick when all are), or a plain
/// figure (today's tries, a won-of-played record).
private enum MenuChip {
    case progress(Int, Int)
    case value(String)
}

private struct MenuChipView: View {
    let chip: MenuChip

    var body: some View {
        switch chip {
        case .progress(let earned, let total): ProgressChip(earned: earned, total: total)
        case .value(let text): Chip(value: text)
        }
    }
}

/// UI rethink package 7: a menu entry as the design's list row: the name in heading paper, its one sentence in paper2
/// under it, the chip on the right inside the row, a paper3 chevron; a sunken strip with small corners. The whole row
/// is one button; VoiceOver reads the name, then the progress, then the sentence as the hint.
private struct MenuRow: View {
    let title: String
    let line: String?
    var chip: MenuChip? = nil
    var spoken: String? = nil
    /// Difficulty on the five-dot scale, as a meta line under the sentence (the kit's list row's place for it).
    var difficulty: Int? = nil
    let action: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.kitDevice) private var kitDevice

    init(title: String, line: String?, chip: MenuChip? = nil, spoken: String? = nil, difficulty: Int? = nil,
         action: @escaping () -> Void) {
        self.title = title
        self.line = line
        self.chip = chip
        self.spoken = spoken
        self.difficulty = difficulty
        self.action = action
    }

    /// One of the main menu's entries, its words from MenuGuide.
    init(entry: MenuEntry, chip: MenuChip? = nil, spoken: String? = nil, action: @escaping () -> Void) {
        self.init(title: entry.title, line: entry.line, chip: chip, spoken: spoken, action: action)
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Theme.Space.sm) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    // One line at the default sizes: a long name shrinks a little rather than wrapping. At the
                    // accessibility sizes it wraps onto every line it needs, never ending in an ellipsis (bug 57).
                    Text(verbatim: title)
                        .font(Theme.heading)
                        .foregroundStyle(palette.paper)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    if let line {
                        Text(verbatim: line)
                            .font(kitDevice == .phone ? Theme.bodyCompact : Theme.body)
                            .foregroundStyle(palette.paper2)
                            .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let difficulty {
                        DifficultyDots(level: difficulty)
                            .padding(.top, Theme.Space.xxs)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let chip { MenuChipView(chip: chip).fixedSize() }
                Image(systemName: "chevron.right")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(palette.paper3)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Space.sm)
            .padding(.horizontal, Theme.Space.md)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minHit, alignment: .leading)
            .background(palette.panelSunken, in: Theme.Corner.tileShape)
            .contentShape(Theme.Corner.tileShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(Text(verbatim: spokenValue))
        .accessibilityHint(Text(verbatim: line ?? ""))
    }

    /// The progress (or today's state), then the difficulty, as the row's one VoiceOver value.
    private var spokenValue: String {
        var parts: [String] = []
        if let spoken, !spoken.isEmpty { parts.append(spoken) }
        if let difficulty {
            parts.append(String(localized: "Menu: difficulty spoken", defaultValue: "Difficulty \(difficulty) of 5",
                                comment: "VoiceOver for the difficulty dots on a main menu row, e.g. Difficulty 3 of 5."))
        }
        return parts.joined(separator: ", ")
    }
}

/// UI rethink package 7: one of the three tiles (Achievements, How to play, Options): the outline icon in paper2 over
/// the name, the progress chip under it once something is earned; a sunken strip with small corners. VoiceOver hears
/// the same name, progress and hint as a row.
private struct MenuTile: View {
    let entry: MenuEntry
    /// A symbol in place of the entry's own (Achievements while some are new).
    var symbol: String? = nil
    var chip: MenuChip? = nil
    var spoken: String? = nil
    let action: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Space.xxs) {
                Image(systemName: symbol ?? entry.symbol)
                    .font(Theme.heading)
                    .fontWeight(.medium)
                    .foregroundStyle(palette.paper2)
                    .accessibilityHidden(true)
                // A short name; the longest ("Achievements") shrinks a little or takes two lines.
                Text(verbatim: entry.title)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                if let chip { MenuChipView(chip: chip).fixedSize() }
            }
            .padding(.vertical, Theme.Space.sm)
            .padding(.horizontal, Theme.Space.xxs)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minHit, maxHeight: .infinity)
            .background(palette.panelSunken, in: Theme.Corner.tileShape)
            .contentShape(Theme.Corner.tileShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: entry.title))
        .accessibilityValue(Text(verbatim: spoken ?? ""))
        .accessibilityHint(Text(verbatim: entry.line))
    }
}

// MARK: How to play

/// The steps of the game, in plain words, the controls for every input, and the rules of each game, in a sheet from
/// the menu (a page of the side panel in the notebook, which shows this same view). UI rethink package 7: the kit's
/// SheetPage (ground, serif title, cyan Done top right) with panel groups, the pushed pages on the ground with Done in
/// the same place, and "Watch the intro", which left the main menu, as a row here.
struct HowToPlaySheet: View {
    @Binding var isOpen: Bool
    /// The input in use, so "Take your shot" teaches the stroke for the way this player plays (FirstInstruction).
    var input: PlayInput = FirstInstruction.platformDefault
    @Environment(\.palette) private var palette
    /// True when shown as a page of the notebook rather than a sheet (NotebookPanel sets it).
    @Environment(\.inlinePages) private var inlinePages
    /// "Watch the intro", handed down by ShowpieceView; nil where there is no table to play it on.
    @Environment(\.frontDoorWatchIntro) private var watchIntro

    private var steps: [(title: String, detail: String)] {
        [
            // 0.7.4: the steps no longer open with the lessons. They start with the shot itself and end with the trick
            // shots, where the Lens shows its best; the lessons are named in that last step as an option only.
            // The same instruction as the hand-over card and the shot panel's hint, so every place teaches one stroke.
            (String(localized: "Take your shot"),
             FirstInstruction.line(for: input) + " "
                + String(localized: "The small picture of the white ball sets where the cue strikes it, for spin.")),
            (String(localized: "Read the Lens"),
             // 0.7.10 everyone: the paths named by shape as well as colour.
             String(localized: "Tap Lens to see the physics: dashed magenta paths are balls sliding, solid cyan paths are balls rolling, thicker is faster. Drag the bar to scrub through the shot either way.")),
            (String(localized: "Try again"),
             String(localized: "Missed? Tap Try again. The balls go back where they were, with the same aim and power. Change one thing, shoot, and your last try stays on the table to compare.")),
            (String(localized: "Watch the trick shots"),
             String(localized: "Tap Trick shots to watch a shot that looks impossible, see why it works in the Lens, then make it yourself. Six short lessons wait under Lessons whenever you want them.")),
        ]
    }


    private func close() { isOpen = false }

    var body: some View {
        NavigationStack {
            SheetPage(title: String(localized: "How to play"), onDone: close) {
                SheetGroup {
                    NumberedSteps(steps: steps)
                }
                SheetGroup {
                    // UI rethink package 7: the intro, moved here from the main menu. It closes the page and plays
                    // the opening break again under the Lens.
                    if let watchIntro {
                        Button {
                            close()
                            watchIntro()
                        } label: {
                            ListRow(leading: .none, title: MenuGuide.watchIntro.title, line: MenuGuide.watchIntro.line,
                                    showsChevron: false)
                        }
                        .buttonStyle(.plain)
                    }
                    NavigationLink {
                        ControlsPage()
                            .frontDoorPushedPage(title: String(localized: "Controls"), onDone: close)
                    } label: {
                        ListRow(leading: .none, title: String(localized: "Controls"),
                                line: String(localized: "Every gesture, key and button."))
                    }
                    .buttonStyle(.plain)
                    // 0.7.10 frontdoor: the main menu's entries with the sentence each one carries.
                    NavigationLink {
                        MenuGuidePage()
                            .frontDoorPushedPage(title: String(localized: "The menu"), onDone: close)
                    } label: {
                        ListRow(leading: .none, title: String(localized: "The menu"),
                                line: String(localized: "What each entry on the main menu opens."))
                    }
                    .buttonStyle(.plain)
                }
                SheetGroup(String(localized: "Rules")) {
                    rulesLink(String(localized: "Eight-ball"), line: String(localized: "Solids, stripes and the 8.")) {
                        RulesPage(rules: RulesPage.eightBall)
                    }
                    rulesLink(String(localized: "Nine-ball"), line: String(localized: "Lowest ball first, and the 9 wins.")) {
                        RulesPage(rules: RulesPage.nineBall)
                    }
                    // The other tables' games (tables-screens): the same rules their Tables pages show.
                    rulesLink(String(localized: "Bumper pool"), line: String(localized: "Five balls each, sunk in the far cup.")) {
                        TableRulesPage(game: .bumperPool)
                    }
                    rulesLink(String(localized: "Five-pin billiards"), line: String(localized: "Pins, a red ball and points.")) {
                        TableRulesPage(game: .fivePin)
                    }
                    rulesLink(String(localized: "Bar billiards"), line: String(localized: "Holes, pegs and a clock.")) {
                        TableRulesPage(game: .barBilliards)
                    }
                }
                // 0.7.10 everyone: the page for teachers, on the studio site (TeachersLink.swift).
                TeachersLinkRow()
            }
            .frontDoorSheetRoot()
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's minimum size only: as a page of the notebook (inlinePages) it takes the panel's width, and a fixed
        // minimum there pushed it past the panel's edge (0.7.5).
        .frame(minWidth: inlinePages ? nil : 420, minHeight: inlinePages ? nil : 420)
        #endif
    }

    /// One rules page's row: the kit's list row, pushing the page on the ground with Done top right.
    private func rulesLink<Page: View>(_ title: String, line: String, @ViewBuilder page: @escaping () -> Page) -> some View {
        NavigationLink {
            page().frontDoorPushedPage(title: title, onDone: close)
        } label: {
            ListRow(leading: .none, title: title, line: line)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Controls

/// Every way to play, written from what the code does (item 1): the touch stroke and its push (StrokeGesture,
/// StrokeTracker), the bridge finger and practice strokes, the Pencil's tilt, tap to aim (AimOverlay), pinch, pan and
/// double tap (TableZoom); the pointer's hover, click and release (PointerAim), the keys (AimOverlay.handleKey, the
/// View menu's zoom, the space bar on the table); and the controller as plan item 42 maps it (ControllerInput).
/// UI rethink package 7: one panel group per input under its section label.
private struct ControlsPage: View {
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()

    init() {}

    private struct InputSection {
        let title: String
        let symbol: String
        let rows: [(title: String, detail: String)]
    }

    private var sections: [InputSection] {
        [
            InputSection(title: String(localized: "Touch and stylus"), symbol: "hand.point.up.left", rows: [
                (String(localized: "Aim"),
                 String(localized: "Drag on the cloth to swing the aim line. Tap a ball to aim straight at it, or a pocket to aim the pot.")),
                (String(localized: "The stroke"),
                 String(localized: "Put a finger on the white ball, pull back to set the power, then push forward through the ball to play. Lifting the finger without pushing keeps the power and plays nothing; Break or Shoot plays it then.")),
                (String(localized: "Practice strokes"),
                 String(localized: "Before the last push, stroke back and forth short of the ball a few times. Keep the same rhythm and the shot comes out steadier.")),
                (String(localized: "Bridge finger"),
                 String(localized: "Rest a second finger on the cloth behind the white ball while you stroke. It is your bridge hand: how far it sits from the ball is your bridge.")),
                (String(localized: "Stylus"),
                 String(localized: "A stylus strokes like a finger. Where a raised cue is allowed, tilt it up past a writing grip to raise the cue.")),
                (String(localized: "Zoom"),
                 String(localized: "Pinch to zoom and drag with two fingers to move around. Double-tap a ball to zoom in on it, and again to come back out.")),
                // 0.7.10 everyone: the same zoom without a gesture (TableZoomMenu).
                (String(localized: "Zoom without a gesture"),
                 String(localized: "The zoom button above the table, or Zoom in the More menu on a phone held upright, zooms in on the white ball, in, out, or back to the whole table.")),
            ]),
            InputSection(title: String(localized: "Pointer and keyboard"), symbol: "cursorarrow", rows: [
                (String(localized: "Aim"),
                 String(localized: "Move the pointer to see the line, then click or drag on the cloth to set it. Scroll to fine-tune.")),
                (String(localized: "The stroke"),
                 String(localized: "Press on the white ball, drag back to set the power and let go to play. Let go in front of the ball to change your mind.")),
                (String(localized: "Keys"),
                 String(localized: "Arrow keys turn the aim and set the power, with Shift for bigger steps. Return plays the shot. Space plays or pauses the replay while the table is selected.")),
                // 0.7.10 everyone: the shot of the day from the keyboard alone (DailyCard).
                (String(localized: "Shot of the day"),
                 String(localized: "Return takes your shot, tries again, or watches the answer once the day is done. Command-S shares your result and Command-B opens the board.")),
                (String(localized: "Zoom"),
                 String(localized: "The View menu zooms in and out, and Actual Size shows the whole table again.")),
            ]),
            InputSection(title: String(localized: "Controller"), symbol: "gamecontroller", rows: [
                (String(localized: "Aim and power"),
                 String(localized: "The left stick turns the aim. The right trigger adds power and the left trigger takes it away. The right stick moves the tip on the white ball.")),
                (String(localized: "Buttons"),
                 String(localized: "A plays the shot, or presses the main button of the card on screen. B jumps to where the balls stopped. X turns the Physics Lens on or off. The shoulder buttons step through the explained moments.")),
                (String(localized: "Your shot and the menu"),
                 String(localized: "Y opens and closes Your shot. The Menu button opens the main menu. The direction pad moves a ball in hand and steps through the call.")),
                // 0.7.10 everyone: the shot of the day with a controller alone (DailyController), the mapping's line.
                (String(localized: "Shot of the day"),
                 String(localized: "Once today's shot is finished, the Options button shares your result and a left stick click opens the board.")),
            ]),
        ]
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.cardGap(device.current)) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    SheetGroup(section.title) {
                        ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                                Text(verbatim: row.title)
                                    .font(Theme.heading)
                                    .foregroundStyle(palette.paper)
                                Text(verbatim: row.detail)
                                    .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                                    .foregroundStyle(palette.paper2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .padding(Theme.Space.pageMargin(device.current))
        }
    }
}

// MARK: The menu, explained

/// 0.7.10 frontdoor: How to play's page about the main menu: each entry's name with what it opens, and the menu's own
/// line about the game. Words from MenuGuide, so the menu and this page never disagree.
private struct MenuGuidePage: View {
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()

    init() {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.cardGap(device.current)) {
                Text(verbatim: MenuGuide.intro)
                    .font(bodyFont)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
                SheetGroup {
                    ForEach(Array(MenuGuide.all.enumerated()), id: \.offset) { _, entry in
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                            Image(systemName: entry.symbol)
                                .font(Theme.heading)
                                .fontWeight(.medium)
                                .foregroundStyle(palette.paper2)
                                .frame(minWidth: Theme.Space.lg)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                                Text(verbatim: entry.title)
                                    .font(Theme.heading)
                                    .foregroundStyle(palette.paper)
                                Text(verbatim: entry.line)
                                    .font(bodyFont)
                                    .foregroundStyle(palette.paper2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(Theme.Space.pageMargin(device.current))
        }
    }

    private var bodyFont: Font { device.current == .phone ? Theme.bodyCompact : Theme.body }
}

/// A numbered list of short titled paragraphs: the How to play steps and each rules page. The numbers are plain sans
/// in paper2 (the design's list numbers), the titles heading paper, the paragraphs paper2.
private struct NumberedSteps: View {
    let steps: [(title: String, detail: String)]
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()
    @ScaledMetric(relativeTo: .headline) private var numberWidth: CGFloat = 24

    init(steps: [(title: String, detail: String)]) {
        self.steps = steps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                    Text(verbatim: (index + 1).formatted(.number.locale(AppLocale.numbers)))
                        .font(Theme.heading.monospacedDigit())
                        .foregroundStyle(palette.paper2)
                        .frame(width: numberWidth, alignment: .leading)
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        Text(verbatim: step.title)
                            .font(Theme.heading)
                            .foregroundStyle(palette.paper)
                        Text(verbatim: step.detail)
                            .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                            .foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                // VoiceOver reads the step as one sentence: the number is decoration.
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// The rules of one game, in our own plain words. They describe what the match rules in BreakdownRules decide; the
/// rulings themselves come from there, never from this text. The title is set by its pusher (frontDoorPushedPage).
private struct RulesPage: View {
    let rules: [(title: String, detail: String)]
    private var device = KitDeviceReader()

    init(rules: [(title: String, detail: String)]) {
        self.rules = rules
    }

    var body: some View {
        ScrollView {
            NumberedSteps(steps: rules)
                .padding(Theme.Space.pageMargin(device.current))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    static var eightBall: [(title: String, detail: String)] {
        [
            (String(localized: "The idea"),
             String(localized: "You and your opponent share one table. One of you takes the solids, 1 to 7, the other the stripes, 9 to 15. Clear your group, then sink the 8 to win.")),
            (String(localized: "The break"),
             // 0.7.5: one added sentence on ball in hand behind the head line, as the rules now judge it. Its own
             // string, so the paragraph before it keeps its translations; two whole sentences joined, never words.
             [String(localized: "A good break sinks a ball or drives at least four balls to a cushion. If it does neither, your opponent may play the table as it lies or have it racked again. Sink the cue ball on the break and your opponent places it anywhere behind the head line."),
              String(localized: "From behind the head line, a ball that is also behind the line can't be hit first unless the cue ball crosses the line before hitting it.")]
                .joined(separator: " ")),
            (String(localized: "The 8 on the break"),
             // Match stream hub edit (bug plan item 20): the fouled break, as EightBallRules.breakRuling rules it.
             String(localized: "Sinking the 8 on the break neither wins nor loses. After a clean break the breaker chooses: put the 8 back on its spot, or rack again. If the break was also a foul, your opponent chooses instead, with the cue ball in hand.")),
            (String(localized: "An open table"),
             String(localized: "After the break nobody owns a group. The first ball you call and sink on a fair shot makes its group yours.")),
            (String(localized: "Call every shot"),
             String(localized: "Before each shot, name the ball and the pocket. The game suggests the ball you are aiming at and the nearest pocket, so one tap confirms it.")),
            (String(localized: "A fair shot"),
             String(localized: "Hit one of your own balls first, or the 8 once your group is gone. Then a ball must drop or any ball must reach a cushion.")),
            (String(localized: "Fouls"),
             String(localized: "Sinking the cue ball, hitting the wrong ball first, hitting nothing, or knocking a ball off the table is a foul. Your opponent then has ball in hand: they place the cue ball anywhere.")),
            (String(localized: "Keep your turn"),
             String(localized: "Sink the ball you called and you shoot again. Miss it, or foul, and the turn passes.")),
            (String(localized: "Winning and losing"),
             String(localized: "Sink the 8 in the pocket you called once your group is gone and you win. Sink it early, in the wrong pocket, off the table, or on a foul, and you lose.")),
        ]
    }

    static var nineBall: [(title: String, detail: String)] {
        [
            (String(localized: "The idea"),
             String(localized: "Only the balls 1 to 9 are used, racked in a diamond with the 1 at the front and the 9 in the middle. Whoever sinks the 9 on a fair shot wins, whenever it happens.")),
            (String(localized: "Lowest ball first"),
             String(localized: "Every shot must hit the lowest-numbered ball on the table first. Then a ball must drop or any ball must reach a cushion.")),
            (String(localized: "No calling"),
             String(localized: "You do not name your shots: any ball that drops on a fair shot counts. The game marks the ball you must hit first.")),
            (String(localized: "Keep your turn"),
             String(localized: "Sink any ball on a fair shot and you shoot again.")),
            (String(localized: "Fouls"),
             String(localized: "A foul gives your opponent ball in hand anywhere on the table. A 9 sunk on a foul comes back to its spot.")),
            (String(localized: "Three fouls"),
             String(localized: "Three fouls in a row by the same player lose the game. The game warns you after the second.")),
        ]
    }
}
