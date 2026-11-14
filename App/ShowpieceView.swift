// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The showpiece screen's layout and nothing else: the 3D table (TableStage) with the title, the status
//          label, the controls, and the caption and shot panel arranged for the screen at hand. On a phone held upright
//          the caption sits under the title and the shot panel above the controls, all floating over the table. On
//          the Mac, on iPad and in landscape the screen splits: the table on the left with the controls under it, and
//          a side column on the right for the caption and the shot panel, so nothing covers the action. The camera is
//          told how much room the controls take (measured, so large text pushes the table up instead of hiding it).
//          Owns the model, the shot-panel switch and the leader state; every control lives in its own file.
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
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var columnWidth: CGFloat = 320

    var body: some View {
        GeometryReader { geo in
            let wide = ScreenLayout.isWide(geo.size)
            ZStack {
                palette.ground.ignoresSafeArea()
                if wide {
                    HStack(spacing: 0) {
                        stage(geo: geo, wide: true)
                        sideColumn(geo: geo)
                    }
                } else {
                    stage(geo: geo, wide: false)
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

    private func stage(geo: GeometryProxy, wide: Bool) -> some View {
        // The 3D view is full-bleed, so its height includes the safe areas. The controls sit inside them.
        let fullHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
        let covered = bottomHeight + geo.safeAreaInsets.bottom + 12 + 8
        return ZStack {
            TableStage(model: model, bridge: bridge, leader: leader,
                       showAim: showShotPanel, bottomInset: min(0.6, Double(covered / max(1, fullHeight))))
            VStack(spacing: 10) {
                ScreenHeader(model: model)
                if !wide {
                    CaptionArea(model: model, leader: leader, showsPlaceholder: false, maxHeight: geo.size.height * 0.3)
                }
                Spacer(minLength: 0)
                bottomStack(geo: geo, wide: wide)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            if model.stage == .lead { TitleCard() }
        }
    }

    private func bottomStack(geo: GeometryProxy, wide: Bool) -> some View {
        FittingScroll(maxHeight: geo.size.height * 0.55) {
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
    }

    // MARK: Side column (Mac, iPad, landscape)

    private func sideColumn(geo: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                CaptionArea(model: model, leader: leader, showsPlaceholder: true, maxHeight: .greatestFiniteMagnitude)
                if showShotPanel {
                    ShotPanel(model: model, isOpen: $showShotPanel).glassCard()
                        .transition(.opacity)
                }
            }
            .padding(16)
            .animation(reduceMotion ? nil : .snappy, value: showShotPanel)
        }
        .scrollBounceBehavior(.basedOnSize)
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

private struct TitleCard: View {
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = 10

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
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.6), radius: 12)
        .transition(.opacity)
        .allowsHitTesting(false)
    }
}
