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
// PURPOSE: The showpiece screen's layout and nothing else: the 3D table (TableStage) with the title row (back button,
//          Lens colour key, status label), the controls, and the caption and shot panel arranged for the screen at
//          hand. On a phone held upright the caption floats over the table's top edge under the title row and the shot
//          panel sits above the controls, all floating over the table. On
//          the Mac, on iPad and in landscape the screen splits: the table on the left with the controls under it, and
//          a side column on the right for the caption and the shot panel, so nothing covers the action. The camera is
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
// SRP/DRY check: Pass - the old 330-line view is split into TableStage, PlaybackControls, ScrubBar, CaptionViews,
//          ShotPanel, Surfaces, MacChrome and Theme. This file only arranges them; flow stays in ShowpieceModel.
import BreakdownPhysics
import SwiftUI

struct ShowpieceView: View {
    @State private var model = ShowpieceModel()
    @State private var bridge = SceneBridge()
    @State private var leader = LeaderState()
    @State private var showShotPanel = false
    /// Real laid-out edges in StageSpace, measured from the views themselves, for the camera (see StageChrome).
    @State private var headerBottom: Double?
    @State private var controlsTop: Double?
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var columnWidth: CGFloat = 320

    var body: some View {
        GeometryReader { geo in
            let wide = ScreenLayout.isWide(geo.size)
            let short = ScreenLayout.isShort(geo.size)
            ZStack {
                palette.ground.ignoresSafeArea()
                if wide {
                    HStack(spacing: 0) {
                        stage(geo: geo, wide: true, controlsInColumn: short)
                        sideColumn(geo: geo, controlsInColumn: short)
                    }
                } else {
                    stage(geo: geo, wide: false, controlsInColumn: false)
                }
                CaptionLeader(leader: leader)
            }
            .coordinateSpace(name: StageSpace.name)
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
                }
            }
            .onChange(of: geo.size) { _, new in model.viewSize = new }
        }
        .focusedSceneValue(\.showpieceModel, model)
        .focusedSceneValue(\.shotPanelOpen, $showShotPanel)
        #if os(macOS)
        .toolbar { ShowpieceToolbar(model: model, shotPanelOpen: $showShotPanel) }
        #endif
    }

    // MARK: The table and what floats over it

    private func stage(geo: GeometryProxy, wide: Bool, controlsInColumn: Bool) -> some View {
        // The 3D view is full-bleed; the camera is told the safe areas and the measured edges of what floats over it.
        // In the wide layout the table's view stops at the side column, so it has no safe inset on that side.
        let i = geo.safeAreaInsets
        let chrome = StageChrome(safe: FramingInsets(top: i.top, left: i.leading, bottom: i.bottom, right: wide ? 0 : i.trailing),
                                 headerBottom: headerBottom, controlsTop: controlsInColumn ? nil : controlsTop)
        return ZStack {
            // The aiming overlay draws the aim line, so the scene's own fixed-length line stays off.
            TableStage(model: model, bridge: bridge, leader: leader, showAim: false, chrome: chrome)
            // Drag to aim, pull back to set power. Under the controls so they keep their touches.
            // The previous attempt, faint, while a shot is being retried. Never takes touches.
            if model.ghost != nil { GhostOverlay(model: model, bridge: bridge) }
            if showShotPanel { AimOverlay(model: model, bridge: bridge, isOpen: $showShotPanel) }
            VStack(spacing: 6) {
                ScreenHeader(model: model)
                    .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).maxY } action: { headerBottom = $0 }
                if !wide {
                    // The explanation floats over the table's top edge. It is deliberately NOT measured for the camera:
                    // the Spacer below absorbs its height, so it comes and goes without moving the table or the controls.
                    // It takes no touches (aiming drags start anywhere on the table) except at the accessibility text
                    // sizes, where a long card may need to scroll.
                    CaptionArea(model: model, leader: leader, maxHeight: geo.size.height * 0.28)
                        .frame(maxWidth: 560)
                        .allowsHitTesting(typeSize.isAccessibilitySize)
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
            // The main menu, over everything, until the player picks something (and again from the back button).
            if model.menuOpen { TitleScreen(model: model, onPlay: { showShotPanel = true }) }
        }
        // The menu comes and goes with the system's smooth motion, not a cut.
        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.7), value: model.menuOpen)
    }

    private func bottomStack(geo: GeometryProxy, wide: Bool) -> some View {
        FittingScroll(maxHeight: geo.size.height * 0.62) {
            VStack(spacing: 10) {
                if !wide { ComparisonCard(model: model) }
                if showShotPanel && !wide {
                    ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                        .transition(.opacity)
                }
                PlaybackControls(model: model, shotPanelOpen: $showShotPanel)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
        .animation(reduceMotion ? nil : .snappy, value: model.comparisonReady)
        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).minY } action: { controlsTop = $0 }
    }

    // MARK: Side column (Mac, iPad, landscape)

    /// On a phone turned sideways there is no room under the table for the controls, so they join the column and the
    /// table gets the full height.
    private func sideColumn(geo: GeometryProxy, controlsInColumn: Bool) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ComparisonCard(model: model)
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
        .frame(width: min(columnWidth, geo.size.width * 0.45))
        .background(palette.ground)
        .overlay(alignment: .leading) { Rectangle().fill(palette.track).frame(width: 1).ignoresSafeArea() }
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
            .accessibilityLabel("Menu")
            .accessibilityHint("Pauses the game and opens the main menu")
            if model.lensOn {
                LensLegendChip().transition(.opacity)
            }
            Spacer(minLength: 0)
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
