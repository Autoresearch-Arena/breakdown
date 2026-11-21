// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
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
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hooks: the stroke's faint trace over the table during
//          the replay (StrokeTraceOverlay), and the stroke's cards (the result line, the straight-stroke drill) beside
//          the other cards in the phone's bottom stack and the side column.)
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
            ZStack {
                palette.ground.ignoresSafeArea()
                // One container for every layout, so the table keeps its identity (and its built 3D scene) when the
                // phone turns, folds or unfolds; only its frame and its neighbours change. The hinge itself stays empty.
                (laptopFold != nil ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))) {
                    stage(geo: geo, wide: split, controlsInColumn: controlsInColumn,
                          columnEdge: laptopFold != nil ? .bottom : (split ? .trailing : nil), menuOnStage: division == nil,
                          header: division == nil)
                        // Folding phone or notebook: the table owns the whole side before the division.
                        .frame(width: bookFold.map { max(0, $0.minX) }, height: laptopFold.map { max(0, $0.minY) })
                    if let division {
                        Color.clear.frame(width: bookFold == nil ? nil : division.width,
                                          height: laptopFold == nil ? nil : division.height)
                    }
                    if division != nil {
                        // The other side: the whole notebook, menus and lists included.
                        NotebookPanel(model: model, leader: leader, showShotPanel: $showShotPanel, page: $page,
                                      onHinge: fold != nil)
                            .frame(width: bookFold.map { max(0, geo.size.width - $0.maxX) },
                                   height: laptopFold.map { max(0, geo.size.height - $0.maxY) })
                            .overlay(alignment: laptopFold != nil ? .top : .leading) { panelHairline(top: laptopFold != nil) }
                    } else if split {
                        // The side column beside the table (Mac, iPad, a phone turned sideways).
                        sideColumn(geo: geo, controlsInColumn: controlsInColumn,
                                   width: min(columnWidth, geo.size.width * 0.45), divider: .leading)
                    }
                }
                // Lists, menus and option sheets stay out of sheets in the notebook: they are pages of its panel.
                .environment(\.inlinePages, division != nil)
                // The line to the card only where the card is beside the table; upright, the card is a strip far below.
                CaptionLeader(leader: leader, showLine: split)
            }
            .coordinateSpace(name: StageSpace.name)
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
        }
        .focusedSceneValue(\.showpieceModel, model)
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
                                 headerBottom: header ? headerBottom : nil, controlsTop: controlsInColumn ? nil : controlsTop)
        return ZStack {
            // The aiming overlay draws the aim line, so the scene's own fixed-length line stays off.
            TableStage(model: model, bridge: bridge, leader: leader, showAim: false, showCue: showShotPanel, chrome: chrome)
            // Drag to aim, pull back to set power. Under the controls so they keep their touches.
            // The previous attempt, faint, while a shot is being retried. Never takes touches.
            if model.ghost != nil { GhostOverlay(model: model, bridge: bridge) }
            // The stroke that played the shot, faint on the cloth while it replays. Never takes touches.
            if model.currentAttempt?.stroke?.trace.isEmpty == false { StrokeTraceOverlay(model: model, bridge: bridge) }
            // Trick shots: rings on the shot's balls and pockets, the success glow, the list sheet, launch flags.
            TrickTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            // Behind the 8-Ball: the called ball and pocket, the list sheet, launch flags (EightBallViews).
            EightBallTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            // Free play and matches: the lifted cue ball's tint, the head line, nine-ball's ball to hit first.
            PlayTableLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            if showShotPanel {
                AimOverlay(model: model, bridge: bridge, isOpen: $showShotPanel)
                    // Mac and iPad: the aim follows a hovering pointer or Pencil, scrolling fine-tunes it, and letting go
                    // of a pointer pull-back takes the shot (PointerAim). A finger plays exactly as before.
                    .pointerAim(model: model, bridge: bridge, isOpen: $showShotPanel)
            }
            VStack(spacing: 6) {
                if header {
                    ScreenHeader(model: model)
                        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).maxY } action: { headerBottom = $0 }
                }
                Spacer(minLength: 0)
                // Hidden (but still measured, so the table does not jump) while the menu is up.
                if !controlsInColumn {
                    bottomStack(geo: geo, wide: wide)
                        .opacity(model.menuOpen ? 0 : 1)
                        .allowsHitTesting(!model.menuOpen)
                        .accessibilityHidden(model.menuOpen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 6)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            // First minute: tap anywhere skips the opening, the cue ball glows at the hand-over, the Lens callouts.
            OpeningLayer(model: model, bridge: bridge, shotPanelOpen: $showShotPanel)
            LensCalloutLayer(model: model, bridge: bridge)
            // The main menu, over everything, until the player picks something (and again from the back button).
            if model.menuOpen && menuOnStage { TitleScreen(model: model, onPlay: { showShotPanel = true }) }
        }
        // With the menu on the other panel of a folding phone nothing covers the table, so the table panel stops
        // taking touches itself: no aiming, and no tapping the hidden title-row buttons, behind an open menu.
        .allowsHitTesting(menuOnStage || !model.menuOpen)
        // The menu comes and goes with the system's smooth motion, not a cut.
        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.7), value: model.menuOpen)
    }

    private func bottomStack(geo: GeometryProxy, wide: Bool) -> some View {
        // A phone this wide for its height (the closed Duo: nearly two thirds as wide as tall) has no height to spare for the
        // table anyway, and a taller stack keeps a scorecard and its controls from being cut at the bottom.
        let squarish = geo.size.width / max(1, geo.size.height) > 0.65
        return FittingScroll(maxHeight: geo.size.height * (squarish ? 0.74 : 0.62)) {
            VStack(spacing: 10) {
                if !wide { ComparisonCard(model: model) }
                if !wide { OpeningCard(model: model) }
                // Trick shots: the shot's card, above the controls so the camera frames the table above it.
                if !wide { TrickShotCard(model: model) }
                if !wide { EightBallCard(model: model) }
                // Free play and matches: ball in hand, table cleared, the match card (FreePlayViews, MatchViews).
                if !wide { PlayCards(model: model) }
                // The stroke: the hard shot's result line and the straight-stroke drill.
                if !wide { StrokeCards(model: model) }
                if showShotPanel && !wide {
                    ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                        .transition(.opacity)
                }
                // Phone held upright: the explanation, directly above the controls and measured with them, so nothing
                // covers the table. Its height is reserved (see CaptionStrip), so the table moves once when the Lens
                // comes up and never between captions. Not gated on the menu: the whole stack is already hidden while
                // the menu is up, and keeping it measured stops the table jumping behind the menu.
                if !wide && model.lensOn && explanations {
                    CaptionStrip(model: model, maxHeight: geo.size.height * 0.28)
                        .transition(.opacity)
                }
                PlaybackControls(model: model, shotPanelOpen: $showShotPanel)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
        .animation(reduceMotion ? nil : .snappy, value: model.retryComparison)
        .animation(reduceMotion ? nil : .snappy, value: model.trickMode.isActive)
        .animation(reduceMotion ? nil : .snappy, value: model.eightBallMode.isActive)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: model.lensOn)
        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).minY } action: { controlsTop = $0 }
    }

    /// How to play, Options or Tables as a sheet, for the layouts without the notebook panel.
    @ViewBuilder private func pageSheet(_ shown: NotebookPage) -> some View {
        let isOpen = Binding(get: { page != nil }, set: { if !$0 { page = nil } })
        switch shown {
        case .howTo: HowToPlaySheet(isOpen: isOpen)
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
    private func sideColumn(geo: GeometryProxy, controlsInColumn: Bool, width: CGFloat?, divider: Edge) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ComparisonCard(model: model)
                    OpeningCard(model: model)
                    // Trick shots: the shot's card at the top of the column.
                    TrickShotCard(model: model)
                    EightBallCard(model: model)
                    PlayCards(model: model)
                    StrokeCards(model: model)
                    CaptionArea(model: model, leader: leader, maxHeight: .greatestFiniteMagnitude)
                    if showShotPanel {
                        ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                            .transition(.opacity)
                        // With the panel open there is no room to pin the controls too, so they scroll with it.
                        if controlsInColumn { PlaybackControls(model: model, shotPanelOpen: $showShotPanel) }
                    }
                }
                .padding(16)
                .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
            }
            .scrollBounceBehavior(.basedOnSize)
            if controlsInColumn && !showShotPanel {
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
            SurfaceMenuButton(model: model)
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
        .accessibilityHidden(model.menuOpen)
        .animation(.easeOut(duration: 0.25), value: model.stage)
        .animation(.easeOut(duration: 0.25), value: model.lensOn)
    }
}

/// The round glass back button that pauses the game and opens the main menu; shared by the title row over the table
/// and the notebook panel's top bar.
struct MenuBackButton: View {
    let model: ShowpieceModel

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
        // Escape opens the menu on the Mac and with a hardware keyboard.
        .keyboardShortcut(.cancelAction)
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
