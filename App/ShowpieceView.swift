// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 coordinator: wires the Ride hand-over in).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream ride, plans/22-Nov-2026-ride-handover-plan.md: the title
//          row's status slot shows the ride's acts with the small table map (RideTitleChip), in place of the surface
//          button while a ride speaks.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 coordinator: writes the playback row top for the third Lens tip, a waiting match ruling keeps Your shot closed, the menu sends its pages to the page sheet).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream card, plans/22-Nov-2026-v076-phone-plan.md, bugs #10,
//          #11, #36, #45, #50: the phone's bottom stack is the explanation's fixed room, the scrolling cards, Your shot
//          and the playback row, with the room, Your shot and the playback row pinned and measured, so the cards get
//          the share less their real heights and Shoot is never below the fold; Your shot waits closed while a newly
//          struck shot rolls and comes back when the balls stop. Sideways, the playback row is always pinned under the
//          column, the explanation leads the column during a guided Lens replay, the column scrolls to Your shot when
//          it opens, and the caption card tells the leader only the part of it the column shows.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: the playback row is pinned under the phone's
//          scrolling cards, and the match card goes slim whenever the Lens is on in a match).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts review: lensReplayCompact is false while the opening
//          runs, so its guided slow replay neither slims the cards nor holds back Your shot in the first minute.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md B5 and
//          stream layouts items 1, 2, 11, 13 and L-B: behind the menu the title row and the phone's bottom stack are
//          disabled, so their Escape and Return go quiet, and the back button gives up Escape while the menu is open or
//          End-this-game is asking; in the side-column layout the menu is laid over the whole window and the column
//          goes blank and quiet behind it (its width kept, so the table does not move); with the notebook put away on a
//          wide window the controls take a smaller share of the height and the title row reaches the corners; on a
//          phone held upright a guided Lens replay slims the mode cards (lensReplayCompact) and Your shot waits closed
//          while it plays, and in a match it also waits closed while a card with its own button is up, opening again
//          when the reason goes; opening Your shot closes a what-if; the stage reports its frame for the caption chip.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F11:
//          the what-if mounts. While a what-if shows, the last-try ghost and the stroke trace step aside and
//          WhatIfOverlay draws the other future; WhatIfCard leads the bottom stack's and the side column's cards.)
// Edited: Claude Haiku 5.5 Medium, 18-November-2026 (the opening title is now the TitleScreen file, shown until Start is tapped; the old title card was removed).
// Edited: Claude Opus 5.5 High, 20-November-2026 (Try again and compare: the "last try" ghost is laid over the table
//          under the aiming layer, the comparison card sits above the controls or at the top of the side column, and
//          -retryDemo opens the aiming panel like -aimDemo and runs the scripted retry).
// Edited: Claude Opus 5.5 High, 20-November-2026 (main menu over the table whenever the model says so, with a back
//          button in the header; the wordmark and the in-play status label are gone from the table, and the caption
//          slot only takes room while the Lens is up with explanations on).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the table fills the screen: no caption slot on a phone held upright;
//          the explanation card floats over the table's top edge just under the title row and never moves the table;
//          the Lens colour key is a glass chip in the title row beside the back button; gaps and paddings are tighter.
//          The camera now keeps only the playing area clear of the title row and controls and lets the rails run under
//          that glass, see CameraFraming).
// Edited: Claude Opus 5.5 High, 20-November-2026 (trick shots: the trick-shot layer (rings on the shot's balls and
//          pockets, the success glow, the list sheet and the -trick launch flags) sits over the table under the aiming
//          layer, and the trick-shot card sits above the controls on a phone held upright or at the top of the side
//          column; marked "Trick shots" where they sit).
// Edited: Claude Opus 5.5 High, 20-November-2026 (nothing covers the table: on a phone held upright the explanation
//          moved from over the table's top edge into a fixed-height CaptionStrip directly above the controls, inside the
//          measured bottom stack, so the camera frames the table above it and the table moves only when the Lens comes
//          up or goes; the leader line to the card is drawn only in the wide layout, the ring and title chip everywhere).
// Edited: Claude Opus 5.5 High, 21-November-2026 (a round glass Surface button in the title row, right side before the
//          status label, opens a menu of playing surfaces; picking one re-solves and replays the shot on it).
// Edited: Claude Opus 5.5 High, 21-November-2026 (each surface in that menu shows a one-line note under its name
//          saying what its friction and gravity do to the balls, so picking one also explains it).
// Edited: Claude Opus 5.5 High, 21-November-2026 (starts the opening music, TitleMusic, while the main menu is up and fades it when play starts or Sound is switched off).
// Edited: Claude Opus 5.5 High, 21-November-2026 (Behind the 8-Ball: EightBallTableLayer sits beside the trick-shot
//          layer and EightBallCard beside the trick-shot card, in both layouts).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the -rackShoot test flag, for the store video.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (play-views hooks: PlayTableLayer (lifted cue ball, nine-ball
//          hit-first ring) beside the 8-ball layer, and PlayCards (ball in hand, table cleared, the match card) beside
//          the 8-ball card in both layouts; the bottom stack animates on the model's retryComparison.)
// PURPOSE: The showpiece screen's layout and nothing else: the 3D table (TableStage) with the title row (back button,
//          Physics Lens key, surface picker, status label), the controls, and the caption and shot panel arranged for the screen at
//          hand. On a phone held upright the caption strip (fixed height, while the Lens is up with explanations on)
//          and the shot panel sit above the controls, measured so the camera frames the table above them. A phone
//          turned sideways (or a window too small for the notebook but wider than tall) splits: the table on the left
//          and a side column on the right for the caption and the shot panel, so nothing covers the action. iPad, Mac
//          and the open folding phone get the notebook (NotebookPanel) instead: see the 21-November edits. The camera is
//          told how much room the controls take (measured, so large text pushes the table up instead of hiding it).
//          Owns the model, the shot-panel switch and the leader state; every control lives in its own file.
//          Package 4 (0.4.0, Claude Sonnet 5.5 High): the screen now MEASURES where its title row, caption slot and control
//          strip really are and hands those edges and the safe areas to the 3D view (StageChrome), so the camera frames the
//          table in exactly the space left between them; and the opening title fades in with the system's smooth motion
//          instead of appearing and cutting away.
//          Package 4 (13-Nov-2026): while "Your shot" is open the screen lays the aiming layer (AimOverlay) over the
//          table, between the 3D view and the floating controls, and tells the scene not to draw its own fixed-length
//          aim line (the overlay draws a better one that stops at the first ball). Launch flags -aimDemo (skip the cold
//          open and open the aiming panel on the break's resting balls) and -aimDemoRack (same, on a fresh rack ready for
//          a break) put the screen in the aiming state for screenshots without tapping through.
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Surface menu gains a Tables section listing the four tables).
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (folding phone: when the system reports a hinge across the window
//          (ScreenLayout.fold), the screen splits exactly along it. The table fills the panel before the fold, and the
//          other panel holds everything else: the cards, captions, shot panel, the playback controls and the main
//          menu. A hinge running across (the phone propped like a laptop) puts the table on the top panel and the rest
//          on the bottom one. Nothing sits on the fold itself.)
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo: on a hinge the table panel carries nothing but the
//          table (no title row), and the other panel is DuoPanel, a full-height notebook with the mode's cards, the live
//          commentary, the numbers and the controls; the main menu, the lists and the option pages are pages of that
//          panel instead of sheets or overlays, so nothing ever covers the table. The environment value inlinePages
//          tells the sheet-hosting views so. MenuBackButton and SurfaceMenuButton are shared with the panel's top bar.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (first minute: OpeningLayer (tap anywhere skips the opening, the glow
//          on the cue ball at the hand-over) and LensCalloutLayer (the three Lens callouts, once) over the table;
//          OpeningCard (the hand-over line) with the other cards. Hook lines only; the views are in OpeningHandover.swift
//          and LensCallouts.swift.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the notebook on every big screen: any window big enough for the table
//          plus a readable column (an iPad either way up, an iPad in a large split or Stage Manager window, a Mac
//          window) splits the same way the folding phone does, chosen from the window's size alone
//          (ScreenLayout.notebook): beside the table when the window is wider than tall, under it when taller. The hinge,
//          where there is one, still wins. Smaller windows (phones, a third of an iPad, a small Mac window) keep the
//          phone layouts exactly as before. The View menu can put the panel away, which gives the table the whole window
//          with the phone-style controls under it. How to play, Options and Tables are one page switch owned here
//          (NotebookPage), so the Help menu reaches How to play in any layout: a page of the panel in the notebook, a
//          sheet otherwise. The aiming layer gains pointer, scroll and Pencil-hover aiming (PointerAim), and the title
//          row's round buttons brighten under the pointer.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons stream, hook lines: LessonTableLayer beside the trick-shot
//          layer, LessonCard beside the trick-shot card in both layouts, and the aiming layer is handed the lesson's
//          open controls and target bands.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hooks: the stroke's faint trace over the table during
//          the replay (StrokeTraceOverlay), and the stroke's cards (the result line, the straight-stroke drill) beside
//          the other cards in the phone's bottom stack and the side column.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 3, 6, 8, 18,
//          32: the opening's tap-to-skip layer now lies under the title row and the controls, so Continue, Pause, the
//          scrub bar and Menu do their own jobs, and the phone's title row says "Tap to skip" while the opening plays;
//          the model's requests to open, close or toggle Your shot (after a break once the balls stop, Keep playing,
//          the controller) are acted on here, the one owner of that switch; a new match that would replace a saved one
//          waits for a yes on the menu card (MatchStartRequest, shared with the Mac's Game menu through a focused
//          value); the scene bridge is a focused value so the View menu can zoom the table; the space bar plays and
//          pauses only while the table has keyboard focus, so it never swallows a space typed into a name field.)
// SRP/DRY check: Pass - the old 330-line view is split into TableStage, PlaybackControls, ScrubBar, CaptionViews,
//          ShotPanel, Surfaces, MacChrome and Theme. This file only arranges them; flow stays in ShowpieceModel.
import BreakdownPhysics
import SwiftUI

struct ShowpieceView: View {
    @State private var model = ShowpieceModel()
    @State private var bridge = SceneBridge()
    @AppStorage(GameSettings.soundKey) private var soundOption = true
    @State private var leader = LeaderState()
    @State private var showShotPanel = false
    /// Real laid-out edges in StageSpace, measured from the views themselves, for the camera (see StageChrome).
    @State private var headerBottom: Double?
    @State private var controlsTop: Double?
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @ScaledMetric(relativeTo: .body) private var columnWidth: CGFloat = 320
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The page shown in place of play: How to play, Options or Tables. In the notebook it is a page of the panel; in
    /// the phone layouts a sheet. Owned here so the Help menu can open How to play whichever layout is on screen.
    @State private var page: NotebookPage?
    /// The View menu's "Show Notebook": off gives the table the whole window on a screen that would have the notebook.
    @AppStorage(NotebookPanel.shownKey) private var panelShown = true
    /// A new match waiting for a yes because it would replace the saved one (item 18). Set by the menu card or the Mac's
    /// Game menu; the menu card asks.
    @State private var pendingMatch: MatchStartRequest?
    /// The table has keyboard focus: the space bar plays and pauses only then (item 32).
    @FocusState private var tableFocused: Bool
    /// Your shot was open when something on a phone held upright made it wait closed (a guided Lens replay, or a match
    /// card with its own button); it opens again when that reason goes (0.7.5 layouts items 13 and L-B). One flag for
    /// both reasons, so a replay and a card that overlap cannot reopen or forget the panel twice.
    @State private var panelWaiting = false
    /// A shot struck after the opening is rolling (0.7.6, #45): set when a new recording starts playing on the ordinary
    /// table, cleared when the balls stop. Your shot waits closed meanwhile (its controls cannot be used until then),
    /// so the rolling balls get the room. Set from the new recording only, so a scrub or a replay never shuts the panel.
    @State private var shotRolling = false
    /// Measured on a phone held upright (0.7.6, #10, #36): the playback row's frame (StageSpace), the explanation room's
    /// height and Your shot's height, all pinned outside the scrolling cards, so the cards get what is really left.
    @State private var playbackFrame: CGRect = .zero
    @State private var stripHeight: CGFloat = 0
    @State private var shotPanelHeight: CGFloat = 0
    /// The side column's visible scroll area (StageSpace), so the caption card there reports only what is on screen.
    @State private var columnViewport: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            let wide = ScreenLayout.isWide(geo.size)
            let short = ScreenLayout.isShort(geo.size)
            let fold = ScreenLayout.fold(in: geo)
            // The notebook for a window big enough for it (nil on phones and small windows: their layouts are untouched).
            let notebookFits = ScreenLayout.notebook(for: geo.size, largeText: typeSize.isAccessibilitySize)
            let notebook = fold == nil && panelShown ? notebookFits : nil
            // The panel put away on a big screen: the table takes the whole window, controls under it, no side column.
            let tableOnly = fold == nil && !panelShown && notebookFits != nil
            // Where the table ends and the panel begins: the folding phone's hinge, or the notebook's split line (a
            // rectangle of no thickness, so the two sides simply meet on it).
            let division = fold ?? notebook?.division(in: geo.size)
            // A division running down the screen (opened like a book, or the panel beside the table) or across it
            // (propped like a laptop, or the panel under the table).
            let bookFold = division.flatMap { $0.height > $0.width ? $0 : nil }
            let laptopFold = division.flatMap { $0.height > $0.width ? nil : $0 }
            let split = (wide && !tableOnly) || division != nil
            let controlsInColumn = division != nil || short
            // The side column beside the table with no notebook (a phone turned sideways, a small window): the menu is
            // laid over the whole window there, not only over the table (0.7.5 layouts item 2).
            let menuOverWindow = split && division == nil
            // Your shot waits closed on a phone held upright while a guided Lens replay plays (item 13), a match
            // card with its own button is up (L-B), or a newly struck shot rolls (0.7.6, #45); see panelWaiting.
            let panelWaits = !wide && division == nil
                && (Self.lensReplayCompact(model, size: geo.size) || matchCardWaits || shotRolling)
            ZStack {
                palette.ground.ignoresSafeArea()
                // One container for every layout, so the table keeps its identity (and its built 3D scene) when the
                // phone turns, folds or unfolds; only its frame and its neighbours change. The hinge itself stays empty.
                (laptopFold != nil ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))) {
                    stage(geo: geo, wide: split, controlsInColumn: controlsInColumn,
                          columnEdge: laptopFold != nil ? .bottom : (split ? .trailing : nil),
                          menuOnStage: division == nil && !menuOverWindow, header: division == nil)
                        // Folding phone or notebook: the table owns the whole side before the division.
                        .frame(width: bookFold.map { max(0, $0.minX) }, height: laptopFold.map { max(0, $0.minY) })
                    if let division {
                        Color.clear.frame(width: bookFold == nil ? nil : division.width,
                                          height: laptopFold == nil ? nil : division.height)
                    }
                    if division != nil {
                        // The other side: the whole notebook, menus and lists included.
                        NotebookPanel(model: model, leader: leader, showShotPanel: $showShotPanel, page: $page,
                                      pendingMatch: $pendingMatch, onHinge: fold != nil)
                            .frame(width: bookFold.map { max(0, geo.size.width - $0.maxX) },
                                   height: laptopFold.map { max(0, geo.size.height - $0.maxY) })
                            .overlay(alignment: laptopFold != nil ? .top : .leading) { panelHairline(top: laptopFold != nil) }
                    } else if split {
                        // The side column beside the table (Mac, iPad, a phone turned sideways).
                        sideColumn(geo: geo, controlsInColumn: controlsInColumn,
                                   width: min(columnWidth, geo.size.width * 0.45), divider: .leading)
                            // Behind the menu the column is blank and quiet: no cards or Shoot showing through the
                            // veil, no Return or Escape from its buttons, nothing read aloud. Its width stays, so the
                            // table does not move when the menu comes or goes (item 2).
                            .opacity(model.menuOpen ? 0 : 1)
                            .allowsHitTesting(!model.menuOpen)
                            .disabled(model.menuOpen)
                            .accessibilityHidden(model.menuOpen)
                            .animation(menuMotion, value: model.menuOpen)
                    }
                }
                // Lists, menus and option sheets stay out of sheets in the notebook: they are pages of its panel.
                .environment(\.inlinePages, division != nil)
                // The line to the card only where the card is beside the table; upright, the card is a strip far below.
                CaptionLeader(leader: leader, showLine: split)
                // The main menu over the whole window in the side-column layout, so its veil and card span the window
                // and not just the table beside a busy column (item 2). Above the leader line. It comes and goes with
                // the system's smooth motion, as it does over the table (stage()); the animation is on this container
                // only, so the notebook's own page cross-fade and the stage keep theirs.
                ZStack {
                    if model.menuOpen && menuOverWindow {
                        TitleScreen(model: model, onPlay: { showShotPanel = true }, page: $page, pendingMatch: $pendingMatch)
                            .transition(.opacity)
                    }
                }
                .animation(menuMotion, value: model.menuOpen)
            }
            .coordinateSpace(name: StageSpace.name)
            // Items 13 and L-B: Your shot steps aside while the reason holds and comes back when it goes, if it was
            // open. While the reason holds, any opening (a tap, the controller, the model, the Mac) is remembered
            // instead of shown (see the showShotPanel change below), so the panel never ends up under the card.
            .onChange(of: panelWaits) { _, waits in
                if waits {
                    if showShotPanel { showShotPanel = false; panelWaiting = true }
                } else if panelWaiting {
                    panelWaiting = false
                    showShotPanel = true
                }
            }
            // #45: a new recording that starts rolling on the ordinary table after the opening (the player's shot, the
            // computer's, a re-solve on another surface) makes Your shot wait; the balls stopping lets it back. The first
            // minute and anything behind the menu are left exactly as they were.
            .onChange(of: model.timelineVersion) { _, _ in
                shotRolling = model.openingStage == .none && !model.menuOpen && model.stage == .explore && !model.aimReady
            }
            .onChange(of: model.aimReady) { _, ready in if ready { shotRolling = false } }
            .onChange(of: showShotPanel) { _, open in
                guard open else { return }
                if panelWaits {
                    // Deferred, not refused: it opens when the replay ends or the card goes.
                    showShotPanel = false
                    panelWaiting = true
                    return
                }
                // Opened by the player, the model or the waiting above: nothing is waiting any more.
                panelWaiting = false
                // The what-if card and Your shot share the card slot; aiming the next shot ends the what-if (item 13).
                // Only an open one: "Keep this one" closes the what-if itself and then asks for this panel, and the kept
                // future's faint target it leaves on the table must survive that.
                if model.whatIf.isOpen { model.whatIf.close() }
            }
            // How to play, Options and Tables outside the notebook (the Help menu, or a page left open when the window
            // shrank below the notebook): a sheet, as the main menu opens them on a phone.
            .sheet(item: Binding(get: { division == nil ? page : nil }, set: { page = $0 })) { shown in
                pageSheet(shown)
            }
            .onAppear {
                model.viewSize = geo.size
                // Test hook: launch with -yourBreakDemo to run the player's own break without tapping.
                if ProcessInfo.processInfo.arguments.contains("-yourBreakDemo") { model.aimOffset = 0.012; model.breakNow() }
                // Test hook: -yourShotDemo opens the shot panel and plays a follow-up shot from the break's layout.
                if ProcessInfo.processInfo.arguments.contains("-yourShotDemo") { showShotPanel = true; model.shootNow() }
                // Test hooks for the aiming layer: skip the cold open, open "Your shot", optionally on a fresh rack.
                let args = ProcessInfo.processInfo.arguments
                if args.contains("-aimDemo") || args.contains("-aimDemoRack") || args.contains("-retryDemo") {
                    model.skipToResult(); model.setLens(false); showShotPanel = true
                    if ProcessInfo.processInfo.arguments.contains("-aimDemoRack") { model.rerack() }
                    // -rackShoot (with -aimDemoRack): play the table's own opening shot a moment later, for the store video.
                    if args.contains("-rackShoot") {
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1.2))
                            model.shootNow()
                        }
                    }
                }
            }
            .onChange(of: geo.size) { _, new in model.viewSize = new }
            // The opening music plays under the main menu once per launch and fades when play starts.
            .onChange(of: model.menuOpen, initial: true) { _, open in
                if open { TitleMusic.shared.start() } else { TitleMusic.shared.stop() }
            }
            .onChange(of: soundOption) { _, on in if !on { TitleMusic.shared.stop() } }
            // The model asks for Your shot to open, close or toggle (after a break once the balls stop on the person's
            // turn, the first-break card's Keep playing, the controller); this view owns the switch, so it acts here.
            .onChange(of: model.shotPanelRequest) { _, request in
                guard let request else { return }
                switch request.action {
                case .open: showShotPanel = true
                // The model closing the panel outranks a panel waiting to come back (0.7.5 layouts).
                case .close: showShotPanel = false; panelWaiting = false
                case .toggle: showShotPanel.toggle()
                }
            }
        }
        .focusedSceneValue(\.showpieceModel, model)
        .focusedSceneValue(\.sceneBridge, bridge)
        .focusedSceneValue(\.pendingMatchStart, $pendingMatch)
        .focusedSceneValue(\.shotPanelOpen, $showShotPanel)
        .focusedSceneValue(\.notebookPage, $page)
        .focusedSceneValue(\.notebookShown, $panelShown)
        #if os(macOS)
        .toolbar { ShowpieceToolbar(model: model, shotPanelOpen: $showShotPanel, notebookShown: $panelShown) }
        #endif
    }

    // MARK: The table and what floats over it

    /// `columnEdge` is the side where the column (or the other panel of a folding phone) meets the table, if any.
    /// `menuOnStage` is false when the main menu is shown on the other panel of a folding phone instead; `header` is false
    /// there too, since the panel's top bar carries the buttons and the table has nothing over it.
    private func stage(geo: GeometryProxy, wide: Bool, controlsInColumn: Bool, columnEdge: Edge?, menuOnStage: Bool,
                       header: Bool = true) -> some View {
        // The 3D view is full-bleed; the camera is told the safe areas and the measured edges of what floats over it.
        // Where the table's view stops at the column or the fold it has no safe inset on that side.
        let i = geo.safeAreaInsets
        // SwiftUI's insets are leading and trailing, the camera's are left and right: turned round for right-to-left
        // languages, where the status badge and the home indicator stay where the hardware put them.
        let leadingInset = i.leading
        let trailingInset = columnEdge == .trailing ? 0 : i.trailing
        let rtl = layoutDirection == .rightToLeft
        let chrome = StageChrome(safe: FramingInsets(top: i.top, left: rtl ? trailingInset : leadingInset,
                                                     bottom: columnEdge == .bottom ? 0 : i.bottom,
                                                     right: rtl ? leadingInset : trailingInset),
                                 headerBottom: header ? headerBottom : nil, controlsTop: controlsInColumn ? nil : controlsTop,
                                 // No title row on the Duo's table half and beside the notebook: the camera must not
                                 // keep room for one while the real edge is unmeasured (0.7.5 layouts item 10).
                                 hasHeader: header)
        return ZStack {
            // The aiming overlay draws the aim line, so the scene's own fixed-length line stays off.
            TableStage(model: model, bridge: bridge, leader: leader, showAim: false, showCue: showShotPanel, chrome: chrome)
            // Drag to aim, pull back to set power. Under the controls so they keep their touches.
            // The previous attempt, faint, while a shot is being retried. Never takes touches.
            // Both step aside while a what-if shows: the violet other future is then the only extra drawing (0.7.5).
            if model.ghost != nil && !model.whatIf.isShowing { GhostOverlay(model: model, bridge: bridge) }
            // The Ride hand-over's rings on the ridden and first-struck balls and the dotted path between them.
            RideOverlay(model: model, bridge: bridge)
            // The stroke that played the shot, faint on the cloth while it replays. Never takes touches.
            if model.currentAttempt?.stroke?.trace.isEmpty == false && !model.whatIf.isShowing {
                StrokeTraceOverlay(model: model, bridge: bridge)
            }
            // The what-if's other future: violet paths, ghost balls and the parting marker. Never takes touches.
            if model.whatIf.isShowing { WhatIfOverlay(model: model, bridge: bridge) }
            // Trick shots: rings on the shot's balls and pockets, the success glow, the list sheet, launch flags.
            TrickTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            // Lessons: rings, the finish circle, the pass glow, the list sheet, and the Watch beat's stop (LessonViews).
            LessonTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            // Behind the 8-Ball: the called ball and pocket, the list sheet, launch flags (EightBallViews).
            EightBallTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            // Free play and matches: the lifted cue ball's tint, the head line, nine-ball's ball to hit first.
            PlayTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            if showShotPanel {
                AimOverlay(model: model, bridge: bridge, isOpen: $showShotPanel, open: model.openControls,
                           zones: model.lessonZones)
                    // Mac and iPad: the aim follows a hovering pointer or Pencil, scrolling fine-tunes it, and letting go
                    // of a pointer pull-back takes the shot (PointerAim). A finger plays exactly as before.
                    .pointerAim(model: model, bridge: bridge, isOpen: $showShotPanel)
            }
            // First minute: tap the table to skip the opening, the cue ball's glow and groove at the hand-over. Under the
            // title row and the controls, so their buttons keep their own jobs while the opening plays (item 6).
            OpeningLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            VStack(spacing: 6) {
                if header {
                    ScreenHeader(model: model)
                        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).maxY } action: { headerBottom = $0 }
                }
                Spacer(minLength: 0)
                // Hidden (but still measured, so the table does not jump) while the menu is up. Disabled too, so the
                // cards' Return and Escape shortcuts do not fire behind the menu (0.7.5 layouts item 1).
                if !controlsInColumn {
                    bottomStack(geo: geo, wide: wide)
                        .opacity(model.menuOpen ? 0 : 1)
                        .allowsHitTesting(!model.menuOpen)
                        .disabled(model.menuOpen)
                        .accessibilityHidden(model.menuOpen)
                        // The controls keep a readable width on a big window; the title row above is not capped, so
                        // its buttons reach the corners (item 11).
                        .frame(maxWidth: 760)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            // The Lens callouts.
            LensCalloutLayer(model: model, bridge: bridge)
            // The main menu, over everything, until the player picks something (and again from the back button).
            if model.menuOpen && menuOnStage {
                TitleScreen(model: model, onPlay: { showShotPanel = true }, page: $page, pendingMatch: $pendingMatch)
            }
        }
        // The space bar plays and pauses the replay while the table has keyboard focus (a click on it gives it focus,
        // and it has it from the start). A name field elsewhere keeps its spaces: a focused text field handles the key
        // itself, so it never reaches here. The aiming layer inside keeps its own arrow keys and Return.
        .focusable()
        .focusEffectDisabled()
        .focused($tableFocused)
        .onAppear { tableFocused = true }
        // The aiming layer takes focus while Your shot is open (its arrows and Return); a space pressed there passes up
        // to this handler. When the panel closes the layer goes, so focus comes back to the table.
        .onChange(of: showShotPanel) { _, open in if !open { tableFocused = true } }
        .onKeyPress(.space) {
            guard !model.menuOpen else { return .ignored }
            model.togglePlay()
            return .handled
        }
        // The stage's frame in StageSpace (the table's half on the open Duo and beside the notebook, the whole window
        // on a phone) bounds the caption chip, so the chip never crosses onto the words half (0.7.5 layouts item 12).
        // Written on change only.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
            if leader.stageRect != frame { leader.stageRect = frame }
        }
        // With the menu elsewhere (the other panel of a folding phone, the notebook, or laid over the whole window
        // beside the side column) the table stops taking touches itself: no aiming, and no tapping the hidden
        // title-row buttons, behind an open menu.
        .allowsHitTesting(menuOnStage || !model.menuOpen)
        // The menu comes and goes with the system's smooth motion, not a cut.
        .animation(menuMotion, value: model.menuOpen)
    }

    /// How the menu comes and goes: the system's smooth motion, a short plain fade with Reduce Motion. Shared by the
    /// menu over the table, the menu over the whole window and the side column stepping aside for it.
    private var menuMotion: Animation {
        reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.7)
    }

    private func bottomStack(geo: GeometryProxy, wide: Bool) -> some View {
        // `wide` is the split layout, which is false with the notebook put away on a big window, so the window's own
        // shape is read here for the height caps (0.7.5 layouts item 11).
        let wideWindow = ScreenLayout.isWide(geo.size)
        // A phone this wide for its height (the closed Duo: nearly two thirds as wide as tall) has no height to spare for the
        // table anyway, and a taller stack keeps a scorecard and its controls from being cut at the bottom. Only on phone
        // widths: a big window with the notebook put away has height to spare for the table, so the controls get under
        // half of a landscape window and the phone's share of a portrait one.
        let squarish = geo.size.width / max(1, geo.size.height) > 0.65
        let share: CGFloat = wideWindow ? (geo.size.width > geo.size.height ? 0.45 : 0.62) : (squarish ? 0.74 : 0.62)
        // Phone held upright: the explanation's room, right under the table. Not gated on the menu: the whole stack is
        // already hidden while the menu is up, and keeping it measured stops the table jumping behind the menu.
        let showStrip = !wide && model.lensOn && explanations
        let showPanel = showShotPanel && !wide
        // Pinned outside the scrolling cards, each measured (0.7.6, #10, #36): the explanation's room, Your shot and the
        // playback row (play, scrub, speed; Lens, Ride, Your shot), which in long languages or at large text sizes is two
        // rows or a stack, not the one row the old fixed allowance assumed. The cards get the share less what these
        // really take, with a floor so a card is never squeezed to nothing (it scrolls in that floor instead).
        let playback = playbackFrame.height > 0 ? playbackFrame.height + 10 : Self.playbackRowAllowance
        let pinned = playback + (showStrip ? stripHeight + 10 : 0) + (showPanel ? shotPanelHeight + 10 : 0)
        let cardsCap = max(geo.size.height * Self.cardsFloorShare, geo.size.height * share - pinned)
        return VStack(spacing: 10) {
        if showStrip {
            // Its room is fixed (see CaptionStrip): the table moves once when the Lens comes up and never between
            // captions, and nothing in it grows over the table. A lower cap on a big window, where the room's lines are
            // short anyway; at large text sizes the words page and scroll inside the cap.
            CaptionStrip(model: model, leader: leader, maxHeight: geo.size.height * (wideWindow ? 0.2 : 0.28))
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { stripHeight = $0 }
                .transition(.opacity)
        }
        FittingScroll(maxHeight: cardsCap) {
            VStack(spacing: 10) {
                // The what-if card first: while it shows, the result cards below step aside (0.7.5).
                if !wide { WhatIfCard(model: model) }
                if !wide { ComparisonCard(model: model) }
                if !wide { OpeningCard(model: model) }
                // Trick shots: the shot's card, above the controls so the camera frames the table above it.
                if !wide { TrickShotCard(model: model) }
                if !wide { LessonCard(model: model) }
                if !wide { EightBallCard(model: model) }
                // Free play and matches: ball in hand, table cleared, the match card (FreePlayViews, MatchViews).
                if !wide { PlayCards(model: model) }
                // The stroke: the hard shot's result line and the straight-stroke drill.
                if !wide { StrokeCards(model: model) }
                // What See the contact stopped on (RetryWords).
                if !wide { ContactArrivalLine(model: model) }
            }
        }
        // Your shot between the cards and the playback row, never inside the scroll, so Shoot is always on screen
        // however tall the match or trick card above it is (#36).
        if showPanel {
            ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shotPanelHeight = $0 }
                .transition(.opacity)
        }
        PlaybackControls(model: model, shotPanelOpen: $showShotPanel)
            // Its real frame: the height for the cards' cap above. Its top (StageSpace) is where the third Lens tip's
            // bubble should sit (stream pacing reads it once the model carries it; see the 0.7.6 hand-off).
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
                if playbackFrame != frame { playbackFrame = frame }
                // The third Lens tip anchors on this top (0.7.6 coordinator, stream pacing hand-off).
                if model.playbackRowTop != Double(frame.minY) { model.playbackRowTop = Double(frame.minY) }
            }
            .onDisappear { model.playbackRowTop = nil }
        }
        // Phone held upright, guided Lens replay: the mode cards show their slim form (heading and main button) so the
        // table keeps its height while the replay plays (B3, item 13).
        .environment(\.lensReplayCompact, Self.lensCardsSlim(model, size: geo.size))
        .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
        .animation(reduceMotion ? nil : .snappy, value: model.retryComparison)
        .animation(reduceMotion ? nil : .snappy, value: model.trickMode.isActive)
        .animation(reduceMotion ? nil : .snappy, value: model.lessonMode.isActive)
        .animation(reduceMotion ? nil : .snappy, value: model.eightBallMode.isActive)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: model.lensOn)
        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).minY } action: { controlsTop = $0 }
    }

    /// The height the pinned playback row takes on a phone (two rows of buttons and the gap above them), used only until
    /// the row's real height is measured (0.7.6).
    static let playbackRowAllowance: CGFloat = 124
    /// The least share of the screen's height the scrolling cards keep on a phone held upright, however much the pinned
    /// pieces take at the largest text sizes, so a card is never squeezed to nothing (0.7.6).
    static let cardsFloorShare: CGFloat = 0.12

    /// The cards' slim form on a phone held upright: during a guided Lens replay (lensReplayCompact), and whenever the
    /// Lens is on in a match, where the match card's instruction, score and ruling otherwise shrink the Lens table to a
    /// small diagram (0.7.5 coordinator, seen on the iPhone 17 Pro Max). The score and the ruling come back the moment
    /// the Lens goes off. Your shot is not held closed for this: aiming in the Lens is a real use.
    static func lensCardsSlim(_ model: ShowpieceModel, size: CGSize) -> Bool {
        lensReplayCompact(model, size: size)
            || (!ScreenLayout.isWide(size) && model.openingStage == .none && model.lensOn && model.match != nil)
    }

    /// True on a phone held upright (not ScreenLayout.isWide) while a guided Lens replay plays: the Lens is up, guided
    /// pacing drives the clock, and the balls have not stopped. The bottom stack hands it to the cards as
    /// lensReplayCompact, and Your shot waits closed while it holds (0.7.5 layouts item 13). Never while the opening
    /// runs: its slow replay is guided too, but the first minute keeps its cards and Your shot exactly as they were
    /// (an opening request for Your shot must open it, not wait), so only a replay after the opening counts.
    static func lensReplayCompact(_ model: ShowpieceModel, size: CGSize) -> Bool {
        !ScreenLayout.isWide(size) && model.openingStage == .none && model.lensOn && model.guided && !model.aimReady
    }

    /// True while a match or table-game card with its own main button is up (L-B): the full ruling card (Continue, or a
    /// person's choice), the hand-over (Ready) and the result (Rematch). The routine ruling's banner has no button and
    /// settles by itself, so it does not count; aiming and a shot playing never count. On a phone held upright Your
    /// shot waits closed meanwhile, so the card and the Shoot row do not crowd the table to its top third.
    private var matchCardWaits: Bool {
        guard let match = model.match else { return false }
        switch match.phase {
        case .ruling: return match.lastRuling == nil || match.lastRulingShow == .card || match.rulingWaitsForTap
        case .handOver, .over: return true
        case .aiming, .shooting: return false
        }
    }

    /// How to play, Options or Tables as a sheet, for the layouts without the notebook panel.
    @ViewBuilder private func pageSheet(_ shown: NotebookPage) -> some View {
        let isOpen = Binding(get: { page != nil }, set: { if !$0 { page = nil } })
        switch shown {
        case .howTo: HowToPlaySheet(isOpen: isOpen, input: model.inputInUse)
        case .options: OptionsSheet(isOpen: isOpen)
        case .tables: TableList(model: model, onChosen: { showShotPanel = true }, onClose: { page = nil })
        }
    }

    // MARK: Side column (a phone turned sideways, and windows too small for the notebook)

    /// On a phone turned sideways there is no room under the table for the controls, so they join the column and the
    /// table gets the full height.
    /// The thin line where a panel meets the table (the top edge when the phone is propped like a laptop).
    @ViewBuilder private func panelHairline(top: Bool) -> some View {
        if top {
            Rectangle().fill(palette.track).frame(height: 1)
        } else {
            Rectangle().fill(palette.track).frame(width: 1).ignoresSafeArea()
        }
    }

    /// `width` is nil when the column spans the screen (under the table on a folding phone propped like a laptop);
    /// `divider` is the edge that meets the table and gets the hairline.
    /// The two movable parts of the side column, in a ForEach so swapping their order moves them rather than rebuilding
    /// them (the caption card keeps its identity, so the leader's card frame is never cleared by a stale disappear);
    /// and the id the column scrolls to when Your shot opens.
    private enum ColumnPart: Hashable { case cards, caption, shotPanel }

    private func sideColumn(geo: GeometryProxy, controlsInColumn: Bool, width: CGFloat?, divider: Edge) -> some View {
        // While a guided Lens replay plays (after the opening, which keeps its column as it was) the explanation and its
        // Continue lead the column: below a tall trick or what-if card they were out of sight while the replay held and
        // moved on (#11).
        let captionFirst = model.openingStage == .none && model.lensOn && model.guided
        let order: [ColumnPart] = captionFirst ? [.caption, .cards] : [.cards, .caption]
        return VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(order, id: \.self) { part in
                            switch part {
                            case .caption:
                                CaptionArea(model: model, leader: leader, maxHeight: .greatestFiniteMagnitude,
                                            viewport: columnViewport)
                            default:
                                // The cards in their own stack with the column's spacing.
                                VStack(spacing: 12) {
                                    WhatIfCard(model: model)
                                    ComparisonCard(model: model)
                                    OpeningCard(model: model)
                                    // Trick shots: the shot's card at the top of the column.
                                    TrickShotCard(model: model)
                                    LessonCard(model: model)
                                    EightBallCard(model: model)
                                    PlayCards(model: model)
                                    StrokeCards(model: model)
                                    ContactArrivalLine(model: model)
                                }
                            }
                        }
                        if showShotPanel {
                            ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                                .id(ColumnPart.shotPanel)
                                .transition(.opacity)
                                // Opened below the cards, out of sight in a short column: the column brings it into
                                // view (#50).
                                .onAppear {
                                    withAnimation(reduceMotion ? nil : .snappy) {
                                        proxy.scrollTo(ColumnPart.shotPanel, anchor: .bottom)
                                    }
                                }
                        }
                    }
                    .padding(16)
                    .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
                    .animation(reduceMotion ? nil : .snappy, value: captionFirst)
                }
                .scrollBounceBehavior(.basedOnSize)
                // The column's visible area, so the caption card reports only what of it is on screen (#11).
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
                    if columnViewport != frame { columnViewport = frame }
                }
            }
            // The playback row is always pinned under the column, Your shot open or not: inside the scroll it slid
            // below the bottom of a short column, with Lens, Ride and the scrub bar out of reach (#50).
            if controlsInColumn {
                PlaybackControls(model: model, shotPanelOpen: $showShotPanel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(palette.ground)
        .overlay(alignment: divider == .top ? .top : .leading) {
            if divider == .top {
                Rectangle().fill(palette.track).frame(height: 1)
            } else {
                Rectangle().fill(palette.track).frame(width: 1).ignoresSafeArea()
            }
        }
    }
}

// MARK: Header and title

/// Along the top inside the safe area: the back button to the main menu on the left, the Lens colour key beside it
/// while the Lens is up, and on the right a status label only while the opening tells its story ("The break",
/// "Hold on", "Slow motion"). In play the status label is gone: the Lens button already says which view is up, and
/// every word off the table is room for the table. The key lives here because this row exists anyway for the back
/// button, so the key costs the table nothing.
private struct ScreenHeader: View {
    let model: ShowpieceModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MenuBackButton(model: model)
            if model.lensOn {
                LensLegendChip().transition(.opacity)
            }
            Spacer(minLength: 0)
            // While the opening plays, a tap on the table skips it; on the phone nothing else says so (item 6). The words
            // are also a button, for anyone who taps them rather than the table.
            if model.openingStage == .playing {
                Button { model.skipOpening() } label: {
                    Label(String(localized: "Tap to skip"), systemImage: "forward.end.fill")
                        .font(Theme.label)
                        .lineLimit(1)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .accessibilityHint("Goes straight to your own break")
                .transition(.opacity)
                Spacer(minLength: 0)
            }
            // A ride names its acts here, with the small table map (0.7.6 stream ride, RideMap.swift). The surface
            // button steps aside meanwhile, so the chip fits beside the back button and the Lens key on a regular
            // iPhone held upright; picking a surface mid-ride would re-solve the shot anyway.
            if model.rideStatus != nil {
                RideTitleChip(model: model)
            } else {
                SurfaceMenuButton(model: model)
            }
            if model.stage != .explore && model.stage != .lead {
                Text(model.stageTitle)
                    .font(Theme.label)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                    .transition(.opacity)
                    .accessibilityLabel("Status: \(model.stageTitle)")
            }
        }
        .opacity(model.menuOpen ? 0 : 1)
        // Disabled behind the menu, so the hidden back button's Escape and the skip button do nothing there (0.7.5).
        .disabled(model.menuOpen)
        .accessibilityHidden(model.menuOpen)
        .animation(.easeOut(duration: 0.25), value: model.stage)
        .animation(.easeOut(duration: 0.25), value: model.lensOn)
        .animation(.easeOut(duration: 0.25), value: model.openingStage)
        .animation(.easeOut(duration: 0.25), value: model.rideAct)
    }
}

/// The round glass back button that pauses the game and opens the main menu; shared by the title row over the table
/// and the notebook panel's top bar.
struct MenuBackButton: View {
    let model: ShowpieceModel

    /// The back button claims Escape only when nothing else on screen is using it.
    private var escapeIsMine: Bool { !model.menuOpen && model.match?.confirmingEnd != true }

    var body: some View {
        Button { model.openMenu() } label: {
            Label("Menu", systemImage: "chevron.backward")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        // Escape opens the menu on the Mac and with a hardware keyboard, except while the menu is already open or the
        // match card's End-this-game is asking: Escape is then theirs (it cancels), claimed once (0.7.5 layouts item 1).
        .keyboardShortcut(escapeIsMine ? KeyboardShortcut.cancelAction : nil)
        .hoverHighlight()
        .accessibilityLabel("Menu")
        .accessibilityHint("Pauses the game and opens the main menu")
    }
}

/// The playing-surface picker: a round glass button the size of the back button, showing the current surface's symbol,
/// that opens a menu of every surface with a check beside the chosen one. Tables are not here: a table is a different game, chosen from the main menu (TableList). Picking one re-solves the shot on screen on
/// that surface and replays it (ShowpieceModel.setSurface). It lives in the title row because that row is there anyway
/// and its right side is empty in play, so the picker costs the table nothing.
struct SurfaceMenuButton: View {
    let model: ShowpieceModel

    var body: some View {
        Menu {
            // One button per surface rather than an inline Picker: a menu row draws a second Text in its label as a
            // smaller subtitle under the title, and that is where each surface explains itself (PlaySurface.summary,
            // e.g. how far balls skid on ice). A Picker row would drop the subtitle. The chosen surface shows a check
            // in place of its symbol. Title and summary are already translated, so they are passed as plain text.
            ForEach(PlaySurface.allCases) { surface in
                Button {
                    model.setSurface(surface)
                } label: {
                    Label {
                        Text(verbatim: surface.title)
                        Text(verbatim: surface.summary)
                    } icon: {
                        Image(systemName: surface == model.surface ? "checkmark" : surface.symbol)
                    }
                }
                .accessibilityAddTraits(surface == model.surface ? .isSelected : [])
            }
        } label: {
            Label("Surface", systemImage: model.surface.symbol)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 22, height: 22)
        }
        .menuIndicator(.hidden)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        .hoverHighlight()
        .accessibilityLabel("Surface")
        .accessibilityValue(model.surface.title)
    }
}
