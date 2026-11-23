// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 every-world: the Playback menu's "Every Surface..."
//          (Shift-Command-U) right after What If..., enabled exactly while the every-surface fan can open and is not up.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md C1:
//          Playback gains Make It Again (Shift-Command-S) after Watch It in the Lens (MakeItAgainCommand).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: a new match from the menu bar asks only when
//          that game has a save).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts item 3 and half of L-A,
//          plans/22-Nov-2026-v075-whatif-and-gaps-plan.md: the Shot and Playback menus and the toolbar's play, replay,
//          speed and Your shot do nothing while the main menu is open; Learn, Trick Shots and Behind the 8-Ball open
//          their list at once and close the other lists and any page (model.showList); Continue Match, New Free Game,
//          the Straight Stroke Drill and Watch the Intro close any page, and a Continue Match whose save does not load
//          leaves the menu as it is; Game > Tables is a list of items, each re-racking its table every time, ticked
//          for the table actually on screen (none in a pool-only mode or a match); Next Explained Moment moves a
//          guided Lens replay on to its next held moment; Speed gains Auto (the paced replay); Playback gains What
//          If... (Shift-Command-T) after Try Again; the toolbar's Your shot is plain and disabled on the computer's
//          turn.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 menus-entries: New Game offers bumper pool and five-pin against
//          the computer at each level as well as eight-ball and nine-ball; bar billiards stays Play Alone. Playback
//          gains Watch It in the Lens (Shift-Command-R), enabled while a remarkable shot is on offer.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.3: the New Game menu offers only what one person plays: the computer, or bar billiards alone)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.2: the New Game submenus list the computer first and two
//          players last.)
// Edited: Claude Opus 5.5 High, 20-November-2026 (Playback menu: Try Again, Command-T).
// Edited: Claude Opus 5.5 High, 20-November-2026 (Ride camera: a Playback menu item, Command-E, and a toolbar toggle).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the toolbar's Lens toggle is labelled "Physics Lens", an existing
//          string, so the blueprint view is named clearly on the Mac too).
// Edited: Claude Opus 5.5 High, 21-November-2026 (Playback menu: a Surface submenu to pick the playing surface).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Surface submenu gains a Tables section: pool table, bumper pool,
//          five-pin billiards, bar billiards).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Mac as a Mac, and the iPad's hardware keyboard with it: a Game
//          menu (a new game of every kind, the trick-shot and Behind the 8-Ball lists, watch the break, the main menu,
//          tables and surfaces), a Shot menu (Your shot, Shoot, aim, power, the cue tip and calling a pocket, each with a
//          key), the View menu's Physics Lens, Ride camera and notebook switch, Playback (play, replay, speed, the next
//          and previous explained moment, try again), and Help opening How to play. File's New Window is gone: the Mac
//          has exactly one game window (a Window scene, set in BreakdownApp), which remembers its size and place
//          (WindowFrameMemory) and never turns into tabs. Options open in the Mac's own Settings window
//          (SettingsWindowContent). The toolbar gains a notebook switch.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 2, 13, 16, 18,
//          19 and 32: the Game menu mirrors the main menu's Play list: Continue Match, New Free Game (which now keeps a
//          saved match, as Practice does), a New Game submenu with each game for two players, eight-ball and nine-ball
//          against the computer at each level, and bar billiards alone, then Learn, the Straight Stroke Drill and Watch
//          the Intro. A new match that would replace the saved one is sent to the menu card, which asks first. Shoot
//          goes through the model's fireStroke and is disabled while a stroke would be refused; the aim, power and tip
//          keys do nothing on the computer's turn. The View menu gains Zoom In, Zoom Out and Actual Size (Command-plus,
//          Command-minus, Command-0) through the scene bridge, a new focused value. Play and Pause leaves the bare
//          space bar, which swallowed spaces typed into name fields; the space bar now plays and pauses only while the
//          table has keyboard focus (ShowpieceView).)
// PURPOSE: What makes the Mac build feel like a Mac app, and what an iPad gains with a hardware keyboard (the same menus
//          appear in the iPad's menu bar and keyboard shortcut list, so the two share this code):
//            - the menus and their shortcuts. Game: Continue Match, New Free Game (Command-N), New Game (eight-ball,
//              nine-ball, bumper pool and five-pin against the computer at each level, bar billiards alone), Learn,
//              Straight Stroke Drill, Trick Shots, Behind the 8-Ball, Watch the Intro, Main Menu, Tables, Surface.
//              Shot: Your Shot (Command-Y), Shoot or Break (Command-Return), aim a quarter degree either way (Command-Left and Right), power (Command-Up and
//              Down), the cue tip (Option and the arrows, Option-0 to centre it), Call Pocket (Option-1 to 6, Option-S for
//              a safety) when the game asks for a call. View: Physics Lens (Command-L), Ride Camera (Command-E), Show
//              Notebook (Option-Command-I), Zoom In, Zoom Out, Actual Size (Command-plus, -minus, -0). Playback: Play or
//              Pause (space while the table has focus), Replay with Lens (Command-R), Watch It in the Lens
//              (Shift-Command-R, while a remarkable shot is on offer), Make It Again (Shift-Command-S, while the
//              shot on screen can be saved as the player's own challenge; Play It Now once saved), the four
//              speeds (Command-1 to 4) and Auto, Next and Previous Explained Moment (Command-] and Command-[), Try
//              Again (Command-T), What If... (Shift-Command-T), Every Surface... (Shift-Command-U). Help: How to Play
//              (Command-?).
//            - behind the main menu the Shot and Playback menus and the toolbar's playback controls are disabled, so
//              nothing acts on the table the menu covers.
//            - the Mac window toolbar (play, speed, replay, Lens, Ride, Your shot, the notebook), reusing the play, replay
//              and speed controls from PlaybackControls and the system's own toggle buttons;
//            - the Mac window's single-window rule and its remembered frame, and the Settings window's content;
//            - the plumbing that lets menu items reach the front window's model, shot-panel switch, page switch and
//              notebook switch (focused values set by ShowpieceView).
//          Writes to the model only through its public methods and the contract's match methods.
//          Haptics check (plan package 2, item 6): everything a vibration says is also seen or heard. Ball, rail and
//          pocket taps play with their sounds from the same cues (FeelMapping feeds SoundBoard and Haptics alike); the
//          scrub bar's tick as it crosses an impact is the tick mark under the thumb; the power ticks while pulling are
//          the live percentage and the gauge; a trick shot's success buzz is the success glow and card. Nothing relies
//          on a vibration alone, so the Mac (no vibration) loses nothing.
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: Playback ends with
//          "Share Clip…" (Shift-Command-E) and the other shape (ClipCommandItems), enabled exactly when the share
//          button shows.)
// SRP/DRY check: Pass - menus, toolbar and window plumbing only. The actions are the model's; the shot words (Break,
//          Shoot, the pocket names, the game names in NotebookWords) are reused, not repeated.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: Plumbing: menu commands find the front window's model through focused values.

extension FocusedValues {
    @Entry var showpieceModel: ShowpieceModel?
    @Entry var shotPanelOpen: Binding<Bool>?
    /// How to play, Options or Tables (ShowpieceView's page switch), for the Help menu.
    @Entry var notebookPage: Binding<NotebookPage?>?
    /// The View menu's notebook switch.
    @Entry var notebookShown: Binding<Bool>?
    /// The front window's scene bridge, so the View menu can zoom its table (TableZoom lives on the scene).
    @Entry var sceneBridge: SceneBridge?
    /// A new match waiting for a yes because it would replace the saved one; the menu card asks (TitleScreen).
    @Entry var pendingMatchStart: Binding<MatchStartRequest?>?
}

// MARK: Shared shot keys

/// The keyboard's shot controls, shared by the Shot menu (Mac menu bar, iPad keyboard). Each first makes sure the aim is
/// open to change, the same way touching the table does: a shot still playing jumps to where the balls stopped, and the
/// shot panel opens so the player sees what the key changed.
@MainActor
private enum ShotKeys {
    /// A twentieth of the power range per key press: the gauge moves a visible notch, twenty presses cover it all.
    static let powerStep = 0.05
    /// A tenth of the tip's travel per key press, so ten presses go from the centre to the edge of the safe zone.
    static let tipSteps = 10.0

    static func prepare(_ model: ShowpieceModel, _ panel: Binding<Bool>?) {
        if !model.aimReady { model.skipToResult() }
        panel?.wrappedValue = true
    }

    /// Moves the cue tip by one step up (+1) or down (-1), right (+1) or left (-1), and keeps it inside the circle the
    /// model allows (tipLimit), scaling the point back along its own direction when a step would leave it.
    static func moveTip(_ model: ShowpieceModel, up: Double, side: Double) {
        let limit = model.tipLimit
        let step = limit / tipSteps
        var u = model.activeTipUp + up * step
        var s = model.activeTipSide + side * step
        let r = (u * u + s * s).squareRoot()
        if r > limit { u *= limit / r; s *= limit / r }
        model.activeTipUp = u
        model.activeTipSide = s
    }

    /// The ball a call would name: the first ball on the aim line, when the game wants a call and allows that ball.
    static func callableBall(_ model: ShowpieceModel) -> Int? {
        guard let match = model.match, match.mustCall, model.aimReady, model.layout.count > 1 else { return nil }
        let radius = model.timeline.table.ballRadius
        guard let hit = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: model.aimDirection,
                                                 radius: radius),
              match.rules.mayCall(hit.ball, in: match.state) else { return nil }
        return hit.ball
    }
}

// MARK: Game menu

struct GameCommands: Commands {
    @FocusedValue(\.showpieceModel) private var model
    @FocusedValue(\.shotPanelOpen) private var shotPanelOpen
    @FocusedValue(\.pendingMatchStart) private var pendingMatch
    @FocusedValue(\.notebookPage) private var page

    var body: some Commands {
        // No second window: the game window is the only one (see BreakdownApp), so File's New Window goes.
        CommandGroup(replacing: .newItem) {}
        CommandMenu("Game") {
            // The Play list's order: what is in progress, then a fresh table, then a new game of each kind.
            Button("Continue Match") {
                guard let model else { return }
                page?.wrappedValue = nil
                model.trickMode.end(); model.eightBallMode.end()
                // A save that does not load is dropped by the model and the menu stays as it is (0.7.5).
                guard model.continueSavedMatch() else { return }
                model.closeMenu()
                shotPanelOpen?.wrappedValue = true
            }
            .disabled(!(model?.hasSavedMatch ?? false))
            // Practice: a fresh rack. A saved match stays saved, as the main menu's Practice leaves it (item 18).
            Button("New Free Game") {
                guard let model else { return }
                // Any page (How to play, Tables) gives way to the table, as start(_:) does for a new match.
                page?.wrappedValue = nil
                model.trickMode.end(); model.eightBallMode.end(); model.startGame()
                shotPanelOpen?.wrappedValue = true
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(model == nil)
            Menu("New Game") {
                // The games one person can play: four against the computer (0.7.4 adds bumper pool and five-pin),
                // bar billiards alone. Two players on one device is not offered (0.7.3).
                ForEach([MatchKind.eightBall, .nineBall, .bumperPool, .fivePin, .barBilliards], id: \.self) { kind in
                    Menu(NotebookWords.gameName(kind)) {
                        // The computer plays every game but bar billiards, which stays a game played alone.
                        if kind != .barBilliards {
                            ForEach(ComputerLevel.allCases, id: \.self) { level in
                                Button(String(localized: "Against the Computer: \(level.title)")) {
                                    start(MatchStartRequest(kind: kind, computer: level))
                                }
                            }
                        }
                        // Bar billiards is also played alone, against the clock (TableGamePage offers the same).
                        if kind == .barBilliards {
                            Button("Play Alone") { start(MatchStartRequest(kind: kind, players: 1)) }
                        }
                    }
                }
            }
            .disabled(model == nil)
            Divider()
            // The three lists open at once and close each other (model.showList) and any page, so the list asked for is
            // the one on screen, never one hidden behind another (0.7.5).
            Button("Learn…") { open(.lessons) }
                .disabled(model == nil)
            Button("Straight Stroke Drill") {
                guard let model else { return }
                page?.wrappedValue = nil
                model.strokeDrill.begin()
                shotPanelOpen?.wrappedValue = true
            }
            .disabled(model == nil)
            Button("Trick Shots…") { open(.tricks) }
                .disabled(model == nil)
            Button("Behind the 8-Ball…") { open(.eightBall) }
                .disabled(model == nil)
            Button("Watch the Intro") {
                guard let model else { return }
                page?.wrappedValue = nil
                model.trickMode.end(); model.eightBallMode.end(); model.watchBreak()
            }
            .disabled(model == nil)
            // The back button's Escape opens the main menu too; this is the same thing, findable in the menu bar.
            Button("Main Menu") { model?.openMenu() }
                .disabled(model == nil || (model?.menuOpen ?? false))
            Divider()
            // A table is a different game; a surface changes what the bed is made of. The same choices as the main
            // menu's Tables page and the round Surface button.
            // Tables: one item per table rather than a Picker, because a Picker ignores a pick of the ticked row, and
            // every pick must re-rack (0.7.5). Each item is a Toggle only for the menu's own tick: whatever the click
            // asks, it plays that table. The tick is the table actually on screen (model.tableOnScreen), so none is
            // ticked while a trick shot, lesson, situation, drill or match is up.
            Menu(String(localized: "Tables")) {
                ForEach(TableKind.allCases) { kind in
                    Toggle(isOn: Binding(get: { model?.tableOnScreen == kind }, set: { _ in model?.playTable(kind) })) {
                        Label(kind.title, systemImage: kind.symbol)
                    }
                }
            }
            .disabled(model == nil)
            Picker("Surface", selection: Binding(get: { model?.surface ?? .cloth }, set: { model?.setSurface($0) })) {
                ForEach(PlaySurface.allCases) { surface in
                    Label(surface.title, systemImage: surface.symbol).tag(surface)
                }
            }
            .disabled(model == nil)
        }
    }

    /// Opens one of the three mode lists from the menu bar: any page gives way and the other lists close.
    private func open(_ list: ModeList) {
        page?.wrappedValue = nil
        model?.showList(list)
    }

    /// A new match from the menu bar. With a match saved (one slot), the main menu opens on the card that asks before
    /// replacing it, the same question the in-window menu asks; otherwise the match starts at once.
    private func start(_ request: MatchStartRequest) {
        guard let model else { return }
        if model.hasSavedMatch(request.kind), let pendingMatch {
            pendingMatch.wrappedValue = request
            // The card is the menu's main page: close any list or page that would sit over it.
            page?.wrappedValue = nil
            model.trickMode.listOpen = false
            model.lessonMode.listOpen = false
            model.eightBallMode.listOpen = false
            model.openMenu()
            return
        }
        request.start(on: model)
        shotPanelOpen?.wrappedValue = true
    }
}

// MARK: Shot menu

struct ShotCommands: Commands {
    @FocusedValue(\.showpieceModel) private var model
    @FocusedValue(\.shotPanelOpen) private var shotPanelOpen

    var body: some Commands {
        CommandMenu("Shot") {
            // Behind the main menu every item here is disabled (the outer disabled wins over each item's own), so no
            // key aims, shoots or opens Your shot on a table the menu covers (0.7.5).
            Group { shotItems }
                .disabled(model?.menuOpen ?? false)
        }
    }

    @ViewBuilder private var shotItems: some View {
        // Not on the computer's turn: Your shot is the person's (L-A), as the toolbar's toggle shows.
        Button("Your Shot") { shotPanelOpen?.wrappedValue.toggle() }
            .keyboardShortcut("y", modifiers: .command)
            .disabled(shotPanelOpen == nil || (model.map { $0.computerTurnStage != .none } ?? false))
        Button((model?.racked ?? false) ? "Break" : "Shoot") {
            guard let model else { return }
            // The break hands the screen to its slow-motion opening, so the panel closes, as with the Break button.
            // A refusal is recorded by the model and its reason shows on the shot panel.
            if model.fireStroke() == .breakStruck { shotPanelOpen?.wrappedValue = false }
        }
        .keyboardShortcut(.return, modifiers: .command)
        // Disabled while a stroke would be refused: a replay still playing, a card or choice waiting, no call and
        // no suggestion, the computer's turn, a solve in flight (items 2, 13 and 16).
        .disabled(model == nil || model?.strokeRefusal != nil)
        Divider()
        // On the computer's turn the person's shot keys do nothing (item 16), as the greyed shot panel shows.
        Group {
            Button("Aim Anticlockwise") { act { $0.nudgeAim(1) } }
                .keyboardShortcut(.leftArrow, modifiers: .command)
            Button("Aim Clockwise") { act { $0.nudgeAim(-1) } }
                .keyboardShortcut(.rightArrow, modifiers: .command)
            Button("More Power") { act { $0.powerFraction += ShotKeys.powerStep } }
                .keyboardShortcut(.upArrow, modifiers: .command)
            Button("Less Power") { act { $0.powerFraction -= ShotKeys.powerStep } }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Divider()
            Button("Tip Higher (Follow)") { act { ShotKeys.moveTip($0, up: 1, side: 0) } }
                .keyboardShortcut(.upArrow, modifiers: .option)
            Button("Tip Lower (Draw)") { act { ShotKeys.moveTip($0, up: -1, side: 0) } }
                .keyboardShortcut(.downArrow, modifiers: .option)
            Button("Tip Left") { act { ShotKeys.moveTip($0, up: 0, side: -1) } }
                .keyboardShortcut(.leftArrow, modifiers: .option)
            Button("Tip Right") { act { ShotKeys.moveTip($0, up: 0, side: 1) } }
                .keyboardShortcut(.rightArrow, modifiers: .option)
            Button("Centre the Tip") { act { $0.activeTipUp = 0; $0.activeTipSide = 0 } }
                .keyboardShortcut("0", modifiers: .option)
        }
        .disabled(!(model?.personControlsLive ?? false))
        Divider()
        callMenu
    }

    /// Calling a pocket for the ball the aim line meets first, in games that ask for a call. Disabled otherwise.
    private var callMenu: some View {
        let ball = model.flatMap { ShotKeys.callableBall($0) }
        let mustCall = model?.match?.mustCall ?? false
        return Menu("Call Pocket") {
            ForEach(Array(EightBallPocket.allCases.enumerated()), id: \.element) { index, pocket in
                Button(pocket.title) {
                    guard let ball else { return }
                    model?.match?.setCall(.ball(ball, pocket: pocket))
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .option)
                .disabled(ball == nil)
            }
            Divider()
            Button("Safety") { model?.match?.setCall(.safety) }
                .keyboardShortcut("s", modifiers: .option)
        }
        .disabled(!mustCall)
    }

    /// Runs a shot key on the model after opening the aim to change (ShotKeys.prepare). Nothing on the computer's turn,
    /// and nothing behind the main menu (a backstop to the disabled menu, 0.7.5).
    private func act(_ change: (ShowpieceModel) -> Void) {
        guard let model, model.personControlsLive, !model.menuOpen else { return }
        ShotKeys.prepare(model, shotPanelOpen)
        change(model)
    }
}

// MARK: View menu

struct ViewCommands: Commands {
    @FocusedValue(\.showpieceModel) private var model
    @FocusedValue(\.notebookShown) private var notebookShown
    @FocusedValue(\.sceneBridge) private var bridge

    var body: some Commands {
        CommandGroup(before: .toolbar) {
            Toggle("Physics Lens", isOn: Binding(get: { model?.lensOn ?? false }, set: { model?.setLens($0) }))
                .keyboardShortcut("l", modifiers: .command)
                .disabled(model == nil)
            // Ride: the replay camera follows the cue ball and the ball it hits at table height.
            Toggle("Ride Camera", isOn: Binding(get: { model?.rideOn ?? false }, set: { model?.setRide($0) }))
                .keyboardShortcut("e", modifiers: .command)
                .disabled(model == nil)
            // The notebook beside or under the table on a big window; off gives the table the whole window.
            Toggle("Show Notebook", isOn: Binding(get: { notebookShown?.wrappedValue ?? true },
                                                  set: { notebookShown?.wrappedValue = $0 }))
                .keyboardShortcut("i", modifiers: [.command, .option])
                .disabled(notebookShown == nil)
            Divider()
            // Zoom by keyboard and menu (item 32), the same zoom a pinch drives (TableZoom). One step in or out per
            // press; Actual Size is the fitted view of the whole table.
            Button("Zoom In") { bridge?.table?.zoom.zoomStep(1) }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(bridge?.table == nil)
            Button("Zoom Out") { bridge?.table?.zoom.zoomStep(-1) }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(bridge?.table == nil)
            Button("Actual Size") { bridge?.table?.zoom.actualSize() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(bridge?.table == nil)
            Divider()
        }
    }
}

// MARK: Playback menu

struct PlaybackCommands: Commands {
    @FocusedValue(\.showpieceModel) private var model
    @FocusedValue(\.shotPanelOpen) private var shotPanelOpen

    var body: some Commands {
        CommandMenu("Playback") {
            // Behind the main menu every item here is disabled, as in the Shot menu (0.7.5).
            Group { playbackItems }
                .disabled(model?.menuOpen ?? false)
        }
    }

    @ViewBuilder private var playbackItems: some View {
        let isPlaying = (model?.playing ?? false) && (model?.time ?? 0) < (model?.duration ?? 0)
        // No key here: a bare space in the menu bar swallowed spaces typed into name fields (item 32). The space
        // bar plays and pauses while the table has keyboard focus instead (ShowpieceView).
        Button(isPlaying ? "Pause" : "Play") { model?.togglePlay() }
        Button("Replay with Lens") { model?.replay(withLens: true) }
            .keyboardShortcut("r", modifiers: .command)
        // The remarkable shot just played, replayed slowly in the Lens holding its key moment: the same as the
        // "Watch it in the Lens" button on the highlight card (the model decides when one is on offer, and the
        // item is greyed whenever the card is not showing). Shift-Command-R, beside Replay with Lens, is free.
        Button("Watch It in the Lens") { model?.watchHighlight() }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(model?.highlightOnOffer == nil)
        // 0.7.7 make-it-again: Make It Again (Shift-Command-S) saves the shot on screen as the player's own challenge;
        // once saved it reads Play It Now. Enabled exactly when the card's button would act (OwnShotShelf).
        MakeItAgainCommand(model: model)
        Menu("Speed") {
            // Auto: back to the paced replay that slows for each explained moment (0.7.5). No key: Command-0 is
            // the View menu's Actual Size.
            Button("Auto") { model?.setAutoRate() }
            ForEach(Array(PlaybackSpeed.rates.enumerated()), id: \.offset) { index, rate in
                Button(PlaybackSpeed.label(rate)) { model?.setRate(rate) }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
        }
        Divider()
        // The explained moments are the Lens captions; stepping to one pauses the replay there and lights it in
        // the notebook's story, as clicking its row does. While a guided Lens replay drives the clock, Next is its
        // Continue instead (model.nextBeat): it ends a held moment or goes on to the next one and holds there, so
        // the Mac can move a guided replay on as the Continue button does (0.7.5).
        Button("Next Explained Moment") {
            guard let model else { return }
            if model.guided { model.nextBeat() } else { step(forward: true) }
        }
        .keyboardShortcut("]", modifiers: .command)
        .disabled(!(model?.guided ?? false) && moment(forward: true) == nil)
        Button("Previous Explained Moment") { step(forward: false) }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(moment(forward: false) == nil)
        Divider()
        // Same as the Try again button in the shot panel; opens the panel so the restored aim can be changed.
        Button("Try Again") { model?.tryAgain(); shotPanelOpen?.wrappedValue = true }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(!(model?.canTryAgain ?? false))
        // The what-if (spec 4.3): the same as the What if button in the playback row. Enabled exactly when the
        // button shows (WhatIfFork.canOpen); the card opens in the notebook or the card slot, never on the table.
        Button("What If…") { model?.whatIf.open() }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(!(model?.whatIf.canOpen ?? false))
        ClipCommandItems(model: model)  // 0.7.7 clips: Share Clip… and the other shape
        // 0.7.7 every-world: Same shot, every surface, as the More menu's and the Surface menu's "Every surface".
        // Enabled exactly while that item shows (EveryWorldFan.canOpen and not already up); its card opens in the
        // notebook, never on the table. Shift-Command-U: Shift-Command-E is Share Clip and Shift-Command-S Make It Again.
        Button("Every Surface…") { model?.everyWorld.open() }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .disabled(!((model?.everyWorld.canOpen ?? false) && !(model?.everyWorld.isShowing ?? false)))
    }

    /// The clock time of the next (or previous) caption from the playback clock, or nil when there is none that way.
    /// A small margin keeps a moment just stepped to from being found again.
    private func moment(forward: Bool) -> Double? {
        guard let model else { return nil }
        let now = model.time, margin = 1e-3
        let times = model.captions.map(\.time)
        return forward ? times.filter { $0 > now + margin }.min() : times.filter { $0 < now - margin }.max()
    }

    private func step(forward: Bool) {
        guard let model, let t = moment(forward: forward) else { return }
        model.scrub(to: t)
    }
}

// MARK: Help menu

struct HelpCommands: Commands {
    @FocusedValue(\.notebookPage) private var page

    var body: some Commands {
        CommandGroup(replacing: .help) {
            // A page of the notebook on a big screen, a sheet on a small one (ShowpieceView decides).
            Button("How to Play") { page?.wrappedValue = .howTo }
                .keyboardShortcut("?", modifiers: .command)
                .disabled(page == nil)
        }
    }
}

// MARK: Toolbar (Mac window)

#if os(macOS)
struct ShowpieceToolbar: ToolbarContent {
    let model: ShowpieceModel
    @Binding var shotPanelOpen: Bool
    /// The notebook switch, the same one the View menu's Show Notebook flips.
    @Binding var notebookShown: Bool

    var body: some ToolbarContent {
        // Behind the main menu the playback controls and Your shot are disabled, so a click in the toolbar does
        // nothing to the table the menu covers (0.7.5). The Lens, Ride and the notebook switch stay: they change
        // the view, not the game.
        ToolbarItemGroup(placement: .navigation) {
            PlayPauseButton(model: model).labelStyle(.iconOnly).help("Play or pause (space)")
                .disabled(model.menuOpen)
            ReplayButton(model: model).labelStyle(.iconOnly).help("Replay with the Lens (Command-R)")
                .disabled(model.menuOpen)
        }
        ToolbarItem(placement: .principal) {
            SpeedPicker(model: model).frame(minWidth: 220)
                .help("Playback speed: Auto slows for each explained moment, or pick a fixed speed (Command-1 to 4)")
                .disabled(model.menuOpen)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            // Real toggles: the system draws the pressed state, so on and off are visible in the toolbar.
            Toggle(isOn: Binding(get: { model.lensOn }, set: { model.setLens($0) })) {
                Label("Physics Lens", systemImage: "viewfinder")
            }
            .toggleStyle(.button)
            .help("Show the Physics Lens (Command-L)")
            Toggle(isOn: Binding(get: { model.rideOn }, set: { model.setRide($0) })) {
                Label("Ride", systemImage: "video")
            }
            .toggleStyle(.button)
            .help("Ride camera: the replay follows the balls at table height (Command-E)")
            // On the computer's turn Your shot is not the person's: drawn off (not lit) and disabled, though the panel
            // itself may still be open, greyed (L-A).
            Toggle(isOn: Binding(get: { shotPanelOpen && !computersTurn }, set: { shotPanelOpen = $0 })) {
                Label("Your shot", systemImage: "target")
            }
            .toggleStyle(.button)
            .help("Take your own shot (Command-Y)")
            .disabled(model.menuOpen || computersTurn)
            Toggle(isOn: $notebookShown) { Label("Notebook", systemImage: "sidebar.trailing") }
                .toggleStyle(.button)
                .help("Show or hide the notebook beside the table (Option-Command-I)")
        }
    }

    /// The computer's turn as the table shows it (thinking, lining up or striking, or its ruling due next).
    private var computersTurn: Bool { model.computerTurnStage != .none }
}

// MARK: The one game window (Mac)

/// Keeps the game window where and how big the player left it, across launches, and stops it from turning into tabs
/// (which would be a second game window by another route). AppKit stores the frame under a fixed name in the app's
/// defaults: the saved frame is applied when the window first appears, then every move and resize is saved. The
/// system's own window restoration is not relied on because it is off whenever "Close windows when quitting an
/// application" is on, which is the Mac's default.
struct WindowFrameMemory: NSViewRepresentable {
    static let frameName = "BreakdownGameWindow"

    func makeNSView(context: Context) -> NSView { FrameMemoryView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class FrameMemoryView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            NSWindow.allowsAutomaticWindowTabbing = false
            window.tabbingMode = .disallowed
            // Apply the saved frame first (false when there is none yet: the scene's default size stands), then start
            // saving under the same name.
            _ = window.setFrameUsingName(WindowFrameMemory.frameName)
            _ = window.setFrameAutosaveName(WindowFrameMemory.frameName)
        }
    }
}

/// The Mac's Settings window (the app menu's Settings, Command-comma): the same Options form the main menu shows on a
/// phone. Its Done button closes the Settings window, so it does what it says here too.
struct SettingsWindowContent: View {
    var body: some View {
        OptionsSheet(isOpen: Binding(get: { true }, set: { open in
            if !open { NSApplication.shared.keyWindow?.performClose(nil) }
        }))
    }
}
#endif
