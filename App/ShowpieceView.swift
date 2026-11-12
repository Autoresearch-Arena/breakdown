// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// PURPOSE: The showpiece screen: the 3D table full-bleed, with a quiet title, the caption and equation card that
//          appear once the table melts into the Lens, and the controls (play, speed, scrub with event ticks,
//          Lens toggle, replay, and the player's own break and follow-up shots). Same code on iPhone and Mac.
// SRP/DRY check: Pass - presentation only; flow lives in ShowpieceModel, drawing in TableScene.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import RealityKit
import SwiftUI

@MainActor
final class SceneHolder {
    var table: TableScene?
}

struct ShowpieceView: View {
    @State private var model = ShowpieceModel()
    @State private var holder = SceneHolder()
    @State private var showBreakPanel = false

    private let ink = Color(red: 0.92, green: 0.96, blue: 1.0)
    private let cyan = Color(red: 0.30, green: 0.88, blue: 1.0)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.02, green: 0.03, blue: 0.05).ignoresSafeArea()
                RealityView { content in
                    #if os(iOS)
                    content.camera = .virtual
                    #endif
                    let table = TableScene(timeline: model.timeline)
                    content.add(table.root)
                    holder.table = table
                    table.load(model.timeline, version: model.timelineVersion)
                    table.subscriptions.append(content.subscribe(to: SceneEvents.Update.self) { event in
                        MainActor.assumeIsolated {
                            model.advance(event.deltaTime)
                            let aim: AimPreview? = showBreakPanel ? Self.aim(for: model) : nil
                            table.apply(time: model.time, melt: model.melt, rate: model.displayRate, aim: aim)
                            let inset = min(0.38, 190 / max(300, geo.size.height))
                            table.updateCamera(melt: model.melt, viewSize: geo.size, bottomInset: inset)
                        }
                    })
                } update: { _ in
                    if let table = holder.table, model.timelineVersion >= 0 {
                        table.load(model.timeline, version: model.timelineVersion)
                    }
                }
                .ignoresSafeArea()

                overlay(size: geo.size)
            }
            .onAppear {
                model.viewSize = geo.size
                // Test hook: launch with -yourBreakDemo to run the player's own break without tapping.
                if ProcessInfo.processInfo.arguments.contains("-yourBreakDemo") { model.aimOffset = 0.012; model.breakNow() }
                // Test hook: -yourShotDemo opens the shot panel and plays a follow-up shot from the break's layout.
                if ProcessInfo.processInfo.arguments.contains("-yourShotDemo") { showBreakPanel = true; model.shootNow() }
            }
            .onChange(of: geo.size) { _, new in model.viewSize = new }
        }
    }

    private static func aim(for model: ShowpieceModel) -> AimPreview {
        // After the first shot the guide line follows the aim slider from the cue ball's resting spot.
        if !model.racked, model.layout.count == 16 {
            return AimPreview(from: model.layout[0], direction: model.shotAimDirection, length: 1.4, always: true)
        }
        let positions = Rack.positions(parameters: PoolParameters(), seed: UInt64(10 + model.breakSerial + 1))
        let target = positions[1] + Vec2(0, model.aimOffset)
        let dir = (target - positions[0]).normalized
        return AimPreview(from: positions[0], direction: dir, length: 1.2, always: true)
    }

    // MARK: Overlay

    @ViewBuilder
    private func overlay(size: CGSize) -> some View {
        VStack(spacing: 10) {
            header
            Spacer(minLength: 0)
            if model.melt > 0.4, let caption = model.activeCaption() {
                CaptionCard(caption: caption)
                    .transition(.opacity)
            }
            if showBreakPanel { breakPanel }
            controls
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.2), value: model.activeCaption()?.id)
        .overlay {
            if model.stage == .lead { titleCard }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("BREAKDOWN")
                .font(.system(.footnote, design: .rounded, weight: .heavy))
                .tracking(3)
                .foregroundStyle(ink.opacity(0.85))
            Spacer()
            Text(model.stageTitle)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(cyan)
                .opacity(model.stage == .lead ? 0 : 1)
        }
        .padding(.top, 8)
    }

    private var titleCard: some View {
        VStack(spacing: 8) {
            Text("BREAKDOWN")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .tracking(8)
                .foregroundStyle(ink)
            Text("watch the physics think")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(cyan)
        }
        .shadow(color: .black.opacity(0.6), radius: 12)
        .transition(.opacity)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 10) {
            ScrubBar(model: model, accent: cyan)
                .frame(height: 34)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { playButton; speedChips; Spacer(minLength: 4); lensButtons }
                VStack(spacing: 8) {
                    HStack(spacing: 8) { playButton; speedChips; Spacer(minLength: 0) }
                    HStack(spacing: 8) { lensButtons; Spacer(minLength: 0) }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(cyan.opacity(0.25), lineWidth: 1))
    }

    private var playButton: some View {
        roundButton(system: model.playing && model.time < model.duration ? "pause.fill" : "play.fill") { model.togglePlay() }
    }

    private var speedChips: some View {
        HStack(spacing: 6) {
            ForEach([0.1, 0.25, 0.5, 1.0], id: \.self) { r in
                chip(rateLabel(r), active: abs(model.displayRate - r) < 0.001 && model.chosenRate != nil) { model.setRate(r) }
            }
        }
    }

    private var lensButtons: some View {
        HStack(spacing: 6) {
            chip(model.lensOn ? "Lens on" : "Lens off", active: model.lensOn) { model.setLens(!model.lensOn) }
            roundButton(system: "arrow.counterclockwise") { model.replay(withLens: true) }
            chip(showBreakPanel ? "Close" : "Your shot", active: showBreakPanel) { showBreakPanel.toggle() }
        }
    }

    private func rateLabel(_ r: Double) -> String { r < 1 ? String(format: "%g×", r) : "1×" }

    private func chip(_ text: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .foregroundStyle(active ? Color.black : ink)
                .background(active ? cyan : Color.white.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func roundButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 34, height: 30)
                .foregroundStyle(ink)
                .background(Color.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    /// The player's panel: a break while the rack is full, then shot after shot from the resting layout.
    private var breakPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.racked {
                sliderRow("Aim", value: $model.aimOffset, range: -0.03...0.03, text: String(format: "%+.0f mm", model.aimOffset * 1000))
                sliderRow("Power", value: $model.power, range: 7...13, text: String(format: "%.1f m/s", model.power))
                sliderRow("Cue tip", value: $model.tipHeight, range: -0.02...0.02, text: tipWord(model.tipHeight))
                actionButton("Break") { showBreakPanel = false; model.breakNow() }
            } else {
                HStack(spacing: 6) {
                    Text("Aim").font(.system(.caption, design: .rounded, weight: .semibold)).frame(width: 56, alignment: .leading)
                        .foregroundStyle(ink.opacity(0.8))
                    roundButton(system: "minus") { model.aimDegrees -= 0.25 }
                    Slider(value: $model.aimDegrees, in: -180...180).tint(cyan)
                    roundButton(system: "plus") { model.aimDegrees += 0.25 }
                    Text(String(format: "%+.1f°", model.aimDegrees)).font(.system(.caption, design: .monospaced))
                        .frame(width: 62, alignment: .trailing).foregroundStyle(ink)
                }
                sliderRow("Power", value: $model.shotPower, range: 0.5...8, text: String(format: "%.1f m/s", model.shotPower))
                sliderRow("Cue tip", value: $model.shotTipUp, range: -0.02...0.02, text: tipWord(model.shotTipUp))
                sliderRow("Side", value: $model.shotTipSide, range: -0.02...0.02,
                          text: model.shotTipSide < -0.002 ? "left" : (model.shotTipSide > 0.002 ? "right" : "centre"))
                HStack(spacing: 8) {
                    chip("Aim at nearest", active: false) { model.aimAtNearestBall() }
                    chip("Re-rack", active: false) { model.rerack() }
                    Spacer(minLength: 0)
                }
                actionButton("Shoot") { model.shootNow() }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func tipWord(_ v: Double) -> String { v < -0.002 ? "draw" : (v > 0.002 ? "follow" : "centre") }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .foregroundStyle(.black)
                .background(cyan, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, text: String) -> some View {
        HStack {
            Text(label).font(.system(.caption, design: .rounded, weight: .semibold)).frame(width: 56, alignment: .leading)
                .foregroundStyle(ink.opacity(0.8))
            Slider(value: value, in: range).tint(cyan)
            Text(text).font(.system(.caption, design: .monospaced)).frame(width: 66, alignment: .trailing)
                .foregroundStyle(ink)
        }
    }
}

// MARK: Caption card

private struct CaptionCard: View {
    let caption: Caption

    private var accent: Color {
        switch caption.accent {
        case .strike: return Color(red: 1.0, green: 0.93, blue: 0.55)
        case .impact: return Color(red: 1.0, green: 0.85, blue: 0.55)
        case .cushion: return Color(red: 0.55, green: 0.72, blue: 1.0)
        case .friction: return Color(red: 1.0, green: 0.62, blue: 0.25)
        case .pocket: return Color(red: 1.0, green: 0.82, blue: 0.25)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption.equation)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(accent)
            Text(caption.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(caption.detail)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3).padding(.vertical, 12)
        }
    }
}

// MARK: Scrub bar

private struct ScrubBar: View {
    let model: ShowpieceModel
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let d = max(model.duration, 0.001)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: 6)
                Canvas { ctx, size in
                    for e in model.timeline.events {
                        let x = size.width * (e.time / d)
                        var c: Color
                        var h: CGFloat = 8
                        switch e.kind {
                        case .ballBall: c = Color(red: 1, green: 0.9, blue: 0.6)
                        case .cushion: c = Color(red: 0.5, green: 0.7, blue: 1)
                        case .pocket: c = Color(red: 1, green: 0.8, blue: 0.2); h = 14
                        case .cueStrike: c = .white; h = 14
                        case .phaseTransition: continue
                        }
                        let rect = CGRect(x: x - 0.5, y: (size.height - h) / 2, width: 1.2, height: h)
                        ctx.fill(Path(rect), with: .color(c.opacity(0.7)))
                    }
                }
                .allowsHitTesting(false)
                Capsule().fill(accent).frame(width: max(6, w * (model.time / d)), height: 6)
                Circle().fill(.white).frame(width: 16, height: 16)
                    .offset(x: min(max(0, w * (model.time / d) - 8), w - 16))
                    .shadow(color: accent.opacity(0.8), radius: 4)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                model.scrub(to: Double(g.location.x / max(1, w)) * d)
            })
            .frame(maxHeight: .infinity)
        }
    }
}
