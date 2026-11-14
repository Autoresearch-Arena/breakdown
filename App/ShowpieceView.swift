// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The showpiece screen's layout and nothing else: the 3D table (TableStage) with the title, the status
//          label, the controls, and the caption and shot panel arranged for the screen at hand. On a phone held upright
//          the caption sits under the title and the shot panel above the controls, all floating over the table. On
//          the Mac, on iPad and in landscape the screen splits: the table on the left with the controls under it, and
//          a side column on the right for the caption and the shot panel, so nothing covers the action. The camera is
//          told how much room the controls take (measured, so large text pushes the table up instead of hiding it).
//          Owns the model, the shot-panel switch and the leader state; every control lives in its own file.
//          Package 4 (0.4.0, Claude Sonnet 5.5 High): the screen now MEASURES where its title row, caption slot and control
//          strip really are and hands those edges and the safe areas to the 3D view (StageChrome), so the camera frames the
//          table in exactly the space left between them; and the opening title fades in with the system's smooth motion
//          instead of appearing and cutting away.
// SRP/DRY check: Pass - the old 330-line view is split into TableStage, PlaybackControls, ScrubBar, CaptionViews,
//          ShotPanel, Surfaces, MacChrome and Theme. This file only arranges them; flow stays in ShowpieceModel.
import BreakdownPhysics
import SwiftUI

struct ShowpieceView: View {
    @State private var model = ShowpieceModel()
    @State private var bridge = SceneBridge()
    @State private var leader = LeaderState()
    @State private var showShotPanel = false
    /// Height of the controls (and the shot panel on a phone), measured, for the camera and for safe spacing.
    @State private var bottomHeight: CGFloat = 0
    /// Real laid-out edges in StageSpace, measured from the views themselves, for the camera (see StageChrome).
    @State private var headerBottom: Double?
    @State private var captionBottom: Double?
    @State private var controlsTop: Double?
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                                 headerBottom: headerBottom, captionBottom: wide ? nil : captionBottom,
                                 controlsTop: controlsInColumn ? nil : controlsTop)
        return ZStack {
            TableStage(model: model, bridge: bridge, leader: leader, showAim: showShotPanel, chrome: chrome)
            VStack(spacing: 10) {
                ScreenHeader(model: model)
                    .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).maxY } action: { headerBottom = $0 }
                if !wide {
                    // The caption has its own slot, sized for the tallest caption, so the table is framed below it.
                    CaptionSlot(model: model, leader: leader, maxHeight: geo.size.height * 0.3)
                        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).maxY } action: { captionBottom = $0 }
                }
                Spacer(minLength: 0)
                if !controlsInColumn { bottomStack(geo: geo, wide: wide) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            if model.stage == .lead { TitleCard() }
        }
        // The title and anything else that comes or goes with the opening uses the system's smooth motion, not a cut.
        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.7), value: model.stage == .lead)
    }

    private func bottomStack(geo: GeometryProxy, wide: Bool) -> some View {
        FittingScroll(maxHeight: geo.size.height * 0.62) {
            VStack(spacing: 10) {
                if showShotPanel && !wide {
                    ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                        .transition(.opacity)
                }
                PlaybackControls(model: model, shotPanelOpen: $showShotPanel)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bottomHeight = $0 }
        .onGeometryChange(for: Double.self) { $0.frame(in: .named(StageSpace.name)).minY } action: { controlsTop = $0 }
    }

    // MARK: Side column (Mac, iPad, landscape)

    /// On a phone turned sideways there is no room under the table for the controls, so they join the column and the
    /// table gets the full height.
    private func sideColumn(geo: GeometryProxy, controlsInColumn: Bool) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    CaptionArea(model: model, leader: leader, showsPlaceholder: true, maxHeight: .greatestFiniteMagnitude)
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

/// The wordmark and the status label, along the top inside the safe area. The status wraps to two lines instead of
/// running off the edge, and sits on glass so it reads over the bright Lens grid as well as the dark table.
private struct ScreenHeader: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .footnote) private var tracking: CGFloat = 4

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            #if os(iOS)
            // On the Mac the window's title bar already says Breakdown. At the largest text sizes the wordmark would
            // fill the whole line and push the status off, so it gives way (the title card still names the app).
            if !typeSize.isAccessibilitySize {
                Text("BREAKDOWN")
                    .font(.footnote.weight(.semibold))
                    .tracking(tracking)
                    .foregroundStyle(palette.paper.opacity(0.85))
                    .fixedSize()
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)
            }
            #endif
            Spacer(minLength: 0)
            status
        }
    }

    private var status: some View {
        // While the title card is up the label is invisible but keeps its space, so the header never changes height.
        let lead = model.stage == .lead
        return Text(lead ? "Table" : model.stageTitle)
            .font(Theme.label)
            .multilineTextAlignment(.trailing)
            .lineLimit(2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
            .opacity(lead ? 0 : 1)
            .accessibilityHidden(lead)
            .accessibilityLabel("Status: \(model.stageTitle)")
    }
}

/// The opening title. It rises into place with the system's smooth animation (a gentle fade, scale and un-blur, the
/// tagline a beat later) and leaves the same way, instead of appearing and cutting away. With Reduce Motion on it only
/// fades, with no scale or blur.
private struct TitleCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = 10
    @State private var shown = false

    var body: some View {
        VStack(spacing: 8) {
            Text("BREAKDOWN")
                .font(Theme.display)
                .tracking(tracking)
                .foregroundStyle(palette.paper)
                .accessibilityAddTraits(.isHeader)
            Text("watch the physics think")
                .font(Theme.tagline)
                .foregroundStyle(palette.accent)
                .opacity(shown ? 1 : 0)
                .animation(reduceMotion ? nil : .smooth(duration: 0.8).delay(0.25), value: shown)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.6), radius: 12)
        .opacity(shown ? 1 : 0)
        .scaleEffect(reduceMotion || shown ? 1 : 0.94)
        .blur(radius: reduceMotion || shown ? 0 : 8)
        // Leaving: fade and swell a touch (the stage's animation drives this transition).
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 1.04)))
        .allowsHitTesting(false)
        .onAppear { withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) { shown = true } }
    }
}
