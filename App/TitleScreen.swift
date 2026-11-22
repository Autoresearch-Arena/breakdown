// Author: Claude Haiku 5.5 High
// Date: 18-November-2026
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
// PURPOSE: The main menu, laid over the live table, dimmed, so the room stays visible behind it. (A first launch
//          skips it: the game opens on a racked pool table with the cue in hand and one line saying how to shoot,
//          with no opening replay first. The menu is reached from the back button on the table, and later launches
//          open on it.)
//          It names the game, says in one line what it is, and offers, top to bottom: Continue (whatever is on the
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

struct TitleScreen: View {
    let model: ShowpieceModel
    /// Play opens the aiming controls on the fresh rack; the screen owns that switch, so it is handed in.
    let onPlay: () -> Void
    /// On a folding phone the menu is a page of the side panel, which has its own pages for How to play and Options; the
    /// panel hands these in, and the menu then neither dims the screen nor opens sheets over the table.
    var onHowTo: (() -> Void)? = nil
    var onOptions: (() -> Void)? = nil
    var onTables: (() -> Void)? = nil
    /// A new match waiting for a yes because it would replace the saved one (ShowpieceView owns it; the Mac's Game menu
    /// can set it too). While set, the card asks instead of listing.
    @Binding var pendingMatch: MatchStartRequest?
    private var inline: Bool { onHowTo != nil }
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = 10
    /// Drives the gentle entrance; the same timing for the wordmark and the card, with the tagline a beat later.
    @State private var shown = false
    @State private var howToOpen = false
    @State private var optionsOpen = false
    @State private var tablesOpen = false
    /// The Play list (the computer's level and its four games, Practice, Straight stroke) replaces the main list
    /// inside the same card. The level itself lives on the model (computerLevel), shared with the Tables pages.
    @State private var playListOpen = false

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

    /// The menu's own one line about the game: the same idea the store page leads with (item 39).
    private static var intro: String {
        String(localized: "A pool table that shows its own physics. Play four games against the computer, and see why every shot went where it did.")
    }

    /// How strongly the table is dimmed behind the menu. Lighter while the opening's slow Lens replay plays behind it on
    /// a later launch (item 52), so the moving trails read through the glass; the card itself stays on its own glass,
    /// so the words keep their contrast either way.
    private var veilOpacity: Double { model.menuBackdropPlaying ? 0.5 : 0.62 }

    var body: some View {
        ZStack {
            // A dimmed veil over the table so the menu reads clearly and the room is still there behind it. Inline the
            // menu has its own panel and the table beside it stays bright.
            if !inline { palette.ground.opacity(veilOpacity).ignoresSafeArea() }
            ScrollView {
                card
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 460)
                    .frame(maxWidth: .infinity)
            }
            // Centred while it fits, scrolls when it does not. A card forced to the screen's height squeezed the
            // description down to one cut-off line.
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
        }
        .opacity(shown ? 1 : 0)
        .transition(.opacity)
        .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: model.menuBackdropPlaying)
        .onAppear {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) { shown = true }
        }
        // Back to the main list whenever the menu is opened again.
        // A question left unanswered when the menu goes is dropped, so it never greets the player later.
        .onDisappear { playListOpen = false; pendingMatch = nil }
        .sheet(isPresented: $howToOpen) { HowToPlaySheet(isOpen: $howToOpen, input: model.inputInUse) }
        .sheet(isPresented: $optionsOpen) { OptionsSheet(isOpen: $optionsOpen) }
        .sheet(isPresented: $tablesOpen) { TableList(model: model, onChosen: onPlay, onClose: { tablesOpen = false }) }
    }

    private var card: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                // The wordmark and tagline are the title; VoiceOver reads the wordmark as the screen's heading.
                Text("BREAKDOWN")
                    .font(Theme.display)
                    .tracking(tracking)
                    .foregroundStyle(palette.paper)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Text("watch the physics think")
                    .font(Theme.tagline)
                    .foregroundStyle(palette.accent)
                    .opacity(shown ? 1 : 0)
                    .animation(reduceMotion ? nil : .smooth(duration: 0.8).delay(0.25), value: shown)
                Text(Self.intro)
                    .font(Theme.copy)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            Group {
                if let request = pendingMatch {
                    replaceList(request)
                } else if playListOpen {
                    playList
                } else {
                    mainList
                }
            }
            .transition(.opacity)
            .animation(reduceMotion ? nil : .snappy, value: playListOpen)
            .animation(reduceMotion ? nil : .snappy, value: pendingMatch)
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
    }

    // MARK: The main list

    /// Something to go back to: the game on the table, or after a relaunch the saved match.
    private var resumable: Bool { model.gameInProgress || model.hasSavedMatch }

    /// Continue is highlighted whenever there is something to go back to. (Since 0.7.1 nothing steers the player into
    /// the lessons: Learn is an ordinary entry and Play, or Continue, leads.)
    private var continueHighlighted: Bool { resumable }

    private var mainList: some View {
        VStack(spacing: 10) {
            // Continue first whenever something is in progress. Return presses whichever entry is highlighted.
            if model.gameInProgress {
                MenuRow(title: "Continue", verbatimLine: liveLine, symbol: "play.fill", prominent: continueHighlighted) {
                    model.closeMenu()
                }
                .keyboardShortcut(continueHighlighted ? KeyboardShortcut.defaultAction : nil)
            } else if model.hasSavedMatch {
                MenuRow(title: "Continue match", verbatimLine: savedLine, symbol: "play.fill", prominent: continueHighlighted) {
                    continueMatch()
                }
                .keyboardShortcut(continueHighlighted ? KeyboardShortcut.defaultAction : nil)
            }
            MenuRow(title: "Play", line: "Four games against the computer, or practise on your own.",
                    symbol: "circle.grid.cross", prominent: playHighlighted) { playListOpen = true }
                .keyboardShortcut(playHighlighted ? KeyboardShortcut.defaultAction : nil)
            // 0.7.4: the trick shots sit directly under Play, where people look first: they are the coolest thing the
            // table shows. The lessons follow as an ordinary entry.
            MenuRow(title: "Trick shots", line: "Watch a shot that looks impossible, see why it works, then make it.",
                    symbol: "wand.and.sparkles", mark: trickMark) { model.showList(.tricks) }
            MenuRow(title: "Learn", line: "Six short lessons: stop, follow, draw, cut, curve and jump.",
                    symbol: "graduationcap", mark: lessonMark) { model.showList(.lessons) }
            MenuRow(title: "Behind the 8-Ball", line: "Escape the nastiest spots in eight-ball and score each way out.",
                    symbol: "8.circle.fill", mark: medalMark) { model.showList(.eightBall) }
            MenuRow(title: "Tables", line: "Other tables, each a game of its own.", symbol: "square.grid.2x2") {
                if let onTables { onTables() } else { tablesOpen = true }
            }
            MenuRow(title: "Watch the intro", line: "The opening break again, slowed down under the Physics Lens.",
                    symbol: "sparkles") {
                model.trickMode.end(); model.eightBallMode.end(); model.watchBreak()
            }
            MenuRow(title: "How to play", line: "The controls, the Lens and the rules of each game.",
                    symbol: "questionmark.circle") {
                if let onHowTo { onHowTo() } else { howToOpen = true }
            }
            MenuRow(title: "Options", line: "Sound, vibration, the aim guide and the tips.", symbol: "gearshape") {
                if let onOptions { onOptions() } else { optionsOpen = true }
            }
        }
    }

    /// Play is highlighted only when there is nothing to go back to and no next step left (the whole path is done).
    private var playHighlighted: Bool { !resumable }

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
        model.savedMatchSummary.map(MatchWords.savedLine) ?? String(localized: "Pick up your saved match where you left it.")
    }

    /// Lessons passed out of the six.
    private var lessonMark: MenuRow.Mark {
        let passed = model.lessonMode.passedCount
        let total = Lessons.all.count
        return MenuRow.Mark(symbol: "checkmark.circle.fill",
                            text: String(localized: "\(passed)/\(total)"),
                            spoken: String(localized: "\(passed) of \(total) passed"))
    }

    /// Trick shots made out of the ones that can be played.
    private var trickMark: MenuRow.Mark {
        let mode = model.trickMode
        let playable = TrickShots.all.filter { !$0.pending }
        let made = playable.filter { mode.isDone($0) }.count
        return MenuRow.Mark(symbol: "checkmark.circle.fill",
                            text: String(localized: "\(made)/\(playable.count)"),
                            spoken: String(localized: "\(made) of \(playable.count) made"))
    }

    /// Medals won out of the situations there are.
    private var medalMark: MenuRow.Mark {
        let won = model.eightBallMode.medals.count
        let total = EightBallSituations.all.count
        return MenuRow.Mark(symbol: "medal.fill",
                            text: String(localized: "\(won)/\(total)"),
                            spoken: String(localized: "\(won) of \(total) medals won"))
    }

    // MARK: The Play list

    private func listHeader(_ title: LocalizedStringKey, back: @escaping () -> Void) -> some View {
        HStack {
            Button(action: back) {
                Label("Back", systemImage: "chevron.backward")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.glass)
            .controlSize(.regular)
            Spacer(minLength: 0)
            Text(title)
                .font(Theme.sectionTitle)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            // Balances the Back button so the title sits in the middle.
            Color.clear.frame(width: 44, height: 1).accessibilityHidden(true)
        }
    }

    /// The computer first: its level and its four games lead the list, so one tap on Play and one on a game starts a
    /// match against it. Practice and the stroke drill follow. The level is the model's (computerLevel), so a level
    /// picked here is the one the Tables pages show, and the reverse.
    private var playList: some View {
        VStack(spacing: 10) {
            listHeader("Play") { playListOpen = false }
            if model.hasSavedMatch {
                MenuRow(title: "Continue match", verbatimLine: savedLine, symbol: "play.fill", prominent: true) { continueMatch() }
                    .keyboardShortcut(.defaultAction)
            }
            Text("Against the computer")
                .font(Theme.heading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            ComputerLevelPicker(model: model)
            // Highlighted (and on Return) when no saved match is waiting; with one, Continue match keeps both.
            MenuRow(title: "Eight-ball", line: "You against the computer. Claim a group, clear it, sink the 8.",
                    symbol: "8.circle", prominent: !model.hasSavedMatch,
                    mark: recordMark(.eightBall, level: model.computerLevel)) {
                start(MatchStartRequest(kind: .eightBall, computer: model.computerLevel))
            }
            .keyboardShortcut(model.hasSavedMatch ? nil : KeyboardShortcut.defaultAction)
            MenuRow(title: "Nine-ball", line: "You against the computer. Lowest ball first; sink the 9 to win.",
                    symbol: "9.circle", mark: recordMark(.nineBall, level: model.computerLevel)) {
                start(MatchStartRequest(kind: .nineBall, computer: model.computerLevel))
            }
            // The other tables' games (0.7.4: the computer plays them too), named as the notebook and the Tables list
            // name them. The match itself puts its own table on (MatchMode, from the request's kind).
            MenuRow(verbatimTitle: NotebookWords.gameName(.bumperPool),
                    verbatimLine: String(localized: "You against the computer. Bank your balls past the bumpers into your cup."),
                    symbol: TableKind.bumperPool.symbol, mark: recordMark(.bumperPool, level: model.computerLevel)) {
                start(MatchStartRequest(kind: .bumperPool, computer: model.computerLevel))
            }
            MenuRow(verbatimTitle: NotebookWords.gameName(.fivePin),
                    verbatimLine: String(localized: "You against the computer. Drive its ball into the pins. First to \(FivePinRules.standardTarget)."),
                    symbol: TableKind.fivePin.symbol, mark: recordMark(.fivePin, level: model.computerLevel)) {
                start(MatchStartRequest(kind: .fivePin, computer: model.computerLevel))
            }
            MenuRow(title: "Practice", line: "Your own break on a fresh rack. No turns, no fouls.", symbol: "triangle") {
                model.trickMode.end(); model.eightBallMode.end(); model.startGame(); onPlay()
            }
            MenuRow(title: "Straight stroke", line: "Send the cue ball up the table and back. Does it return to the cue?",
                    symbol: "arrow.up.and.down") {
                model.strokeDrill.begin(); onPlay()
            }
        }
    }

    /// Games won out of games finished against the computer at one level, for one game; no mark before the first.
    private func recordMark(_ kind: MatchKind, level: ComputerLevel) -> MenuRow.Mark? {
        let r = MatchRecord.record(kind: kind, level: level)
        let played = r.won + r.lost
        guard played > 0 else { return nil }
        return MenuRow.Mark(symbol: "trophy.fill", text: String(localized: "\(r.won)/\(played)"),
                            spoken: String(localized: "\(r.won) won of \(played) played"))
    }

    // MARK: Replacing the saved match

    /// The one save slot is taken: say which game it holds and ask before a new one replaces it (item 18).
    private func replaceList(_ request: MatchStartRequest) -> some View {
        VStack(spacing: 10) {
            Text(String(localized: "Replace your saved game?"))
                .font(Theme.sectionTitle)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(([savedLine, String(localized: "A new game ends it for good.")]).joined(separator: " "))
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            MenuRow(verbatimTitle: String(localized: "Keep my saved game"), verbatimLine: savedLine, symbol: "play.fill",
                    prominent: true) {
                pendingMatch = nil
                continueMatch()
            }
            .keyboardShortcut(.defaultAction)
            MenuRow(verbatimTitle: String(localized: "Start the new game"),
                    verbatimLine: NotebookWords.gameName(request.kind), symbol: "arrow.triangle.2.circlepath") {
                pendingMatch = nil
                request.start(on: model)
                onPlay()
            }
            Button(String(localized: "Cancel")) { pendingMatch = nil }
                .buttonStyle(.glass)
                .keyboardShortcut(.cancelAction)
        }
    }

    /// A new match: straight away when nothing is saved, otherwise after a yes on the card.
    private func start(_ request: MatchStartRequest) {
        if model.hasSavedMatch {
            pendingMatch = request
            return
        }
        request.start(on: model)
        onPlay()
    }

    /// Continue match: onto the table only when the saved match really loaded (0.7.5). A save that does not load
    /// leaves the menu up, and the model clears the row, so a Continue that does nothing is never left on offer. The
    /// model ends any trick shot or situation itself once the save loads, so a failed Continue ends nothing.
    private func continueMatch() {
        guard model.continueSavedMatch() else { return }
        model.closeMenu()
        onPlay()
    }
}

// MARK: The computer's level

/// The computer's level (Easy, Medium, Hard) as a segmented choice, and one line on what that level plays like. Bound
/// to the model's computerLevel, so the main menu's Play list and the Tables pages of bumper pool and five-pin show and
/// set one shared choice, remembered on the device across launches (0.7.5). The model is @Observable, so reading computerLevel here redraws
/// the picker and the line whichever screen changed it.
struct ComputerLevelPicker: View {
    let model: ShowpieceModel
    /// Centred in the menu's card; leading on a Tables page, where everything else is leading.
    var leading = false

    var body: some View {
        VStack(alignment: leading ? .leading : .center, spacing: 10) {
            // An explicit binding, as the Mac's Tables and Surface pickers do: the view holds the model as a plain
            // constant (it is a class), so there is no projected $ binding to hand the picker.
            Picker(String(localized: "Level"),
                   selection: Binding(get: { model.computerLevel }, set: { model.computerLevel = $0 })) {
                ForEach(ComputerLevel.allCases, id: \.self) { level in Text(level.title).tag(level) }
            }
            .pickerStyle(.segmented)
            Text(model.computerLevel.line)
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(leading ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: leading ? .leading : .center)
    }
}

// MARK: One menu entry

/// A menu entry: symbol, name, one short line saying what it is, and an optional small progress mark at the end. The
/// whole row is one button; VoiceOver reads the name, then the progress, and offers the line as the hint.
private struct MenuRow: View {
    struct Mark {
        let symbol: String
        /// Short, for the eye ("3/10").
        let text: String
        /// Whole, for VoiceOver ("3 of 10 made").
        let spoken: String
    }

    let title: Text
    let line: Text
    let symbol: String
    var prominent = false
    var mark: Mark? = nil
    let action: () -> Void
    @Environment(\.palette) private var palette

    /// Fixed words, looked up in the string catalog. (Distinct labels for run-time words below, so a string literal
    /// never picks an unlocalized overload.)
    init(title: LocalizedStringKey, line: LocalizedStringKey, symbol: String, prominent: Bool = false, mark: Mark? = nil,
         action: @escaping () -> Void) {
        self.init(titleText: Text(title), lineText: Text(line), symbol: symbol, prominent: prominent, mark: mark,
                  action: action)
    }

    /// A fixed name with a line built at run time (already translated), such as the saved match's summary.
    init(title: LocalizedStringKey, verbatimLine: String, symbol: String, prominent: Bool = false, mark: Mark? = nil,
         action: @escaping () -> Void) {
        self.init(titleText: Text(title), lineText: Text(verbatim: verbatimLine), symbol: symbol, prominent: prominent,
                  mark: mark, action: action)
    }

    /// A name and line built at run time (already translated), such as the next step ("Next: Lesson 2, Follow").
    init(verbatimTitle: String, verbatimLine: String, symbol: String, prominent: Bool = false, mark: Mark? = nil,
         action: @escaping () -> Void) {
        self.init(titleText: Text(verbatim: verbatimTitle), lineText: Text(verbatim: verbatimLine), symbol: symbol,
                  prominent: prominent, mark: mark, action: action)
    }

    private init(titleText: Text, lineText: Text, symbol: String, prominent: Bool, mark: Mark?,
                 action: @escaping () -> Void) {
        self.title = titleText
        self.line = lineText
        self.symbol = symbol
        self.prominent = prominent
        self.mark = mark
        self.action = action
    }

    var body: some View {
        let button = Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(Theme.heading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    line
                        .font(Theme.body)
                        .opacity(0.75)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if let mark {
                    HStack(spacing: 4) {
                        Image(systemName: mark.symbol)
                        Text(verbatim: mark.text).monospacedDigit()
                    }
                    .font(Theme.label)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(palette.track))
                    .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .controlSize(.large)
        .accessibilityLabel(title)
        .accessibilityValue(mark.map { Text(verbatim: $0.spoken) } ?? Text(verbatim: ""))
        .accessibilityHint(line)
        if prominent {
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

// MARK: How to play

/// The steps of the game, in plain words, the controls for every input, and the rules of each game, in a sheet from
/// the menu (a page of the side panel in the notebook, which shows this same view).
struct HowToPlaySheet: View {
    @Binding var isOpen: Bool
    /// The input in use, so "Take your shot" teaches the stroke for the way this player plays (FirstInstruction).
    var input: PlayInput = FirstInstruction.platformDefault
    @Environment(\.palette) private var palette
    /// True when shown as a page of the notebook rather than a sheet (NotebookPanel sets it).
    @Environment(\.inlinePages) private var inlinePages

    private var steps: [(title: String, detail: String)] {
        [
            // 0.7.4: the steps no longer open with the lessons. They start with the shot itself and end with the trick
            // shots, where the Lens shows its best; the lessons are named in that last step as an option only.
            // The same instruction as the hand-over card and the shot panel's hint, so every place teaches one stroke.
            (String(localized: "Take your shot"),
             FirstInstruction.line(for: input) + " "
                + String(localized: "The small picture of the white ball sets where the cue strikes it, for spin.")),
            (String(localized: "Read the Lens"),
             String(localized: "Tap Lens to see the physics: magenta paths are balls sliding, cyan paths are balls rolling, thicker is faster. Drag the bar to scrub through the shot either way.")),
            (String(localized: "Try again"),
             String(localized: "Missed? Tap Try again. The balls go back where they were, with the same aim and power. Change one thing, shoot, and your last try stays on the table to compare.")),
            (String(localized: "Watch the trick shots"),
             String(localized: "Tap Trick shots to watch a shot that looks impossible, see why it works in the Lens, then make it yourself. Learn has six short lessons whenever you want them.")),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    NumberedSteps(steps: steps)
                    NavigationLink {
                        ControlsPage()
                    } label: {
                        rulesLink("Controls", line: "Every gesture, key and button.", symbol: "hand.tap")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rules")
                            .font(Theme.sectionTitle)
                            .accessibilityAddTraits(.isHeader)
                        NavigationLink {
                            RulesPage(title: "Eight-ball", rules: RulesPage.eightBall)
                        } label: {
                            rulesLink("Eight-ball", line: "Solids, stripes and the 8.", symbol: "8.circle")
                        }
                        NavigationLink {
                            RulesPage(title: "Nine-ball", rules: RulesPage.nineBall)
                        } label: {
                            rulesLink("Nine-ball", line: "Lowest ball first, and the 9 wins.", symbol: "9.circle")
                        }
                        // The other tables' games (tables-screens): the same rules their Tables pages show.
                        NavigationLink {
                            TableRulesPage(game: .bumperPool)
                        } label: {
                            rulesLink("Bumper pool", line: "Five balls each, sunk in the far cup.", symbol: TableKind.bumperPool.symbol)
                        }
                        NavigationLink {
                            TableRulesPage(game: .fivePin)
                        } label: {
                            rulesLink("Five-pin billiards", line: "Pins, a red ball and points.", symbol: TableKind.fivePin.symbol)
                        }
                        NavigationLink {
                            TableRulesPage(game: .barBilliards)
                        } label: {
                            rulesLink("Bar billiards", line: "Holes, pegs and a clock.", symbol: TableKind.barBilliards.symbol)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("How to play")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { isOpen = false } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's minimum size only: as a page of the notebook (inlinePages) it takes the panel's width, and a fixed
        // minimum there pushed it past the panel's edge (0.7.5).
        .frame(minWidth: inlinePages ? nil : 420, minHeight: inlinePages ? nil : 420)
        #endif
    }

    private func rulesLink(_ title: LocalizedStringKey, line: LocalizedStringKey, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(palette.accent).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.heading).foregroundStyle(.primary)
                Text(line).font(Theme.body).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(palette.track.opacity(0.5)))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: Controls

/// Every way to play, written from what the code does (item 1): the touch stroke and its push (StrokeGesture,
/// StrokeTracker), the bridge finger and practice strokes, the Pencil's tilt, tap to aim (AimOverlay), pinch, pan and
/// double tap (TableZoom); the pointer's hover, click and release (PointerAim), the keys (AimOverlay.handleKey, the
/// View menu's zoom, the space bar on the table); and the controller as plan item 42 maps it (ControllerInput).
private struct ControlsPage: View {
    @Environment(\.palette) private var palette

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
            ]),
            InputSection(title: String(localized: "Pointer and keyboard"), symbol: "cursorarrow", rows: [
                (String(localized: "Aim"),
                 String(localized: "Move the pointer to see the line, then click or drag on the cloth to set it. Scroll to fine-tune.")),
                (String(localized: "The stroke"),
                 String(localized: "Press on the white ball, drag back to set the power and let go to play. Let go in front of the ball to change your mind.")),
                (String(localized: "Keys"),
                 String(localized: "Arrow keys turn the aim and set the power, with Shift for bigger steps. Return plays the shot. Space plays or pauses the replay while the table is selected.")),
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
            ]),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 14) {
                        Label(section.title, systemImage: section.symbol)
                            .font(Theme.sectionTitle)
                            .foregroundStyle(palette.accent)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title).font(Theme.heading)
                                Text(row.detail)
                                    .font(Theme.copy)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Controls")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// A numbered list of short titled paragraphs: the How to play steps and each rules page.
private struct NumberedSteps: View {
    let steps: [(title: String, detail: String)]
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(index + 1)")
                        .font(Theme.equation)
                        .foregroundStyle(palette.accent)
                        .frame(width: 24, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title).font(Theme.heading)
                        Text(step.detail)
                            .font(Theme.copy)
                            .foregroundStyle(.secondary)
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
/// rulings themselves come from there, never from this text.
private struct RulesPage: View {
    let title: LocalizedStringKey
    let rules: [(title: String, detail: String)]

    var body: some View {
        ScrollView {
            NumberedSteps(steps: rules).padding(24)
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
