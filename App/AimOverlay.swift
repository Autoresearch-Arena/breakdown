// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (test script "retry", also started by -retryDemo: a shot, Try again,
//          a change of spin, the same shot again, ending on the comparison).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the Aim guide option: with it off only a short aim line is drawn,
//          with no ghost ball, no ringed target and no follow-on lines, so the player judges the angle).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the mechanical bridge: for a trick shot that needs it, the bridge's
//          head is drawn on the cloth under the cue a little behind the ball, its notch carrying the cue, with its long
//          handle running back beside the cue and a small "Bridge" label, so the player sees why the shot is reachable).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the cue stick and the bridge are real 3D models on the table now
//          (CueRig); this layer no longer strokes a flat cue or draws a flat bridge, and keeps only the small "Bridge"
//          label beside the bridge head).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the bridge label follows model.showsBridge, so Behind the 8-Ball
//          situations that need the bridge get it too).
// Edited: Claude Opus 5.5 High, 21-November-2026 (ball in hand, play-views stream: while the model has the cue ball
//          lifted (placingCueBall) a drag anywhere on the table carries it to the finger (moveCueBallCandidate) and
//          letting go puts it down (confirmCueBallPlacement; an illegal spot keeps it lifted, tinted red by
//          PlayTableLayer); the arrow keys move it a ball radius in the direction they point on screen and Return
//          puts it down; the aim drawing steps aside meanwhile. The retry test log reads the model's RetryComparison.
//          The spoken route for placement is the ball-in-hand card (FreePlayViews), not this layer's Aim element.)
// PURPOSE: Aim by touching the table. A transparent layer laid over the 3D table while "Your shot" is open. It does
//          two jobs. (1) Gestures: a drag that starts away from the cue ball swings the aim line to follow the finger
//          (the finger's spot on the table is found with AimProjector, so it works from any camera angle); a drag that
//          starts on the cue ball is a pull-back, and how far you pull behind the aim line sets the power, shown live
//          in the power gauge and as a percentage by the ball; letting go keeps the power. On a Mac the pointer does the
//          same, and the arrow keys fine-tune: left and right turn the aim a quarter degree (shift: a degree), up and
//          down change the power, Return takes the shot. (2) Drawing: a glowing aim line to the first ball it will hit, the "ghost ball" where the cue ball will be at that
//          moment, the ball it hits ringed, where that ball and the cue ball will head afterwards, or the line to the
//          cushion when it misses everything. All of it is drawn in screen space from the live camera, so it also
//          follows the camera's swing into the Physics Lens. The cue itself (drawn back as far as the power) and the
//          mechanical bridge are 3D models placed by CueRig; for a bridge shot this layer only labels the bridge.
//          TEST HOOK: launching with -aimScript <break|shots|scratch> makes the layer drive itself through the same
//          drag handlers a finger uses (aim drag, pull-back, release, Break or Shoot, second shot, or a shot straight at a
//          pocket) and log what it did with the prefix AIMSCRIPT, so the flow can be checked and photographed without
//          anyone at the screen. It does not go through UIKit touch delivery; real touches were checked separately.
//          Reads and writes the model only through its aim, power and fire methods; the layer is only in the view
//          tree while the panel is open, so it costs nothing otherwise. For VoiceOver the whole layer is one adjustable
//          "Aim" element; the sliders in the fine-controls sheet remain the complete accessible route.
// SRP/DRY check: Pass - checked CaptionViews (a Canvas overlay that projects model points; same pattern, but one-way
//          and for the caption ring) and ShotPanel (the sliders, kept as the fallback). Ray casting and camera maths
//          live in AimGeometry; the gauges in AimGauges; this file is only gesture, keys and drawing.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import RealityKit
import SwiftUI

struct AimOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    /// Closed by the break: the cold open takes over the screen.
    @Binding var isOpen: Bool

    @AppStorage("aimHintSeen") private var hintSeen = false
    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    @Environment(\.palette) private var palette
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var mode: DragMode?
    @State private var pulling = false
    /// True while a finger (or pointer) is carrying the lifted cue ball; letting go puts it down.
    @State private var placingDrag = false
    @State private var viewSize = CGSize(width: 400, height: 800)
    @FocusState private var focused: Bool

    private enum DragMode { case aim, pull }

    /// How close to the cue ball (in points) a touch must start to count as grabbing the ball to pull back.
    private let grabRadius: CGFloat = 44
    /// A pull shorter than this on screen is a tap on the ball, not a pull: it leaves the power as it was.
    private let pullSlop: CGFloat = 10
    /// Honour the silent-testing flag for touch feedback too.
    private static let muted = ProcessInfo.processInfo.arguments.contains("-muteSound")

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(dragGesture)
            TimelineView(.animation) { _ in
                Canvas { ctx, size in draw(&ctx, size: size) }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewSize = $0 }
        // Keyboard: Mac, and iPad with a keyboard. The layer takes focus when it appears so the arrows work at once.
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .task { await TestScript.run(on: self) }
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow, .return], phases: [.down, .repeat], action: handleKey)
        .sensoryFeedback(.selection, trigger: pullBucket)
        // VoiceOver: one adjustable element; the sliders in the sheet do the rest.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aim")
        .accessibilityValue(spokenAim)
        .accessibilityHint("Swipe up or down to turn the aim. Use the more menu for the sliders.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.nudgeAim(4)
            case .decrement: model.nudgeAim(-4)
            @unknown default: break
            }
        }
    }

    // MARK: Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in drag(from: v.startLocation, to: v.location) }
            .onEnded { _ in endDrag() }
    }

    fileprivate func projectorForScript() -> AimProjector? { projector(size: viewSize) }

    fileprivate func endDrag() {
        // Ball in hand: letting go puts the ball down. On an illegal spot the model keeps it lifted (and the table
        // layer tints it red), so the player simply drags again.
        if placingDrag {
            placingDrag = false
            model.confirmCueBallPlacement()
            return
        }
        if mode == .pull { hintSeen = true }
        mode = nil; pulling = false
    }

    private func projector(size: CGSize) -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
    }

    fileprivate func drag(from start: CGPoint, to location: CGPoint) {
        // Ball in hand: the lifted cue ball follows the finger wherever the drag started; nothing is aimed.
        if model.placingCueBall {
            guard let proj = projector(size: viewSize), let spot = proj.table(at: location) else { return }
            model.moveCueBallCandidate(to: spot)
            placingDrag = true
            return
        }
        // Touching the table while the last shot is still playing takes over: jump to where the balls came to rest.
        if !model.aimReady { model.skipToResult() }
        guard model.layout.count == 16, let proj = projector(size: viewSize) else { return }
        if mode == nil {
            // Decided once, at the first touch: on the cue ball is a pull, anywhere else is aiming.
            let ball = proj.screen(model.aimOrigin)
            let near = ball.map { hypot($0.x - start.x, $0.y - start.y) <= grabRadius } ?? false
            mode = near ? .pull : .aim
        }
        guard let spot = proj.table(at: location) else { return }
        switch mode {
        case .aim:
            model.aim(toward: spot)
        case .pull:
            guard hypot(location.x - start.x, location.y - start.y) > pullSlop else { return }
            // How far the finger is behind the cue ball, measured along the aim line, on the table itself.
            let behind = (model.aimOrigin - spot).dot(model.aimDirection)
            model.powerFraction = behind / ShowpieceModel.pullReach
            pulling = true
        case nil:
            break
        }
    }

    /// Changes each tenth of pull so the phone can tick as the power climbs; -1 when not pulling.
    private var pullBucket: Int { pulling && !Self.muted ? Int(model.powerFraction * 10) : -1 }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        if model.placingCueBall { return placementKey(press) }
        guard model.aimReady else { return .ignored }
        let big = press.modifiers.contains(.shift)
        switch press.key {
        case .leftArrow: model.nudgeAim(screenSign() * (big ? 4 : 1)); return .handled
        case .rightArrow: model.nudgeAim(-screenSign() * (big ? 4 : 1)); return .handled
        case .upArrow: model.powerFraction += big ? 0.1 : 0.02; return .handled
        case .downArrow: model.powerFraction -= big ? 0.1 : 0.02; return .handled
        case .return:
            hintSeen = true
            if model.fire() { isOpen = false }
            return .handled
        default: return .ignored
        }
    }

    /// Ball in hand from the keyboard: each arrow moves the lifted ball one ball radius the way the arrow points on
    /// the screen (found by projecting a short screen step back onto the table, so it holds from any camera angle);
    /// Return puts it down.
    private func placementKey(_ press: KeyPress) -> KeyPress.Result {
        let step: CGPoint
        switch press.key {
        case .leftArrow: step = CGPoint(x: -20, y: 0)
        case .rightArrow: step = CGPoint(x: 20, y: 0)
        case .upArrow: step = CGPoint(x: 0, y: -20)
        case .downArrow: step = CGPoint(x: 0, y: 20)
        case .return:
            model.confirmCueBallPlacement()
            return .handled
        default: return .ignored
        }
        let at = CueBallPlacement.spot(model)
        guard let proj = projector(size: viewSize), let s = proj.screen(at),
              let there = proj.table(at: CGPoint(x: s.x + step.x, y: s.y + step.y)) else { return .ignored }
        let d = there - at
        guard d.lengthSquared > 1e-12 else { return .ignored }
        model.moveCueBallCandidate(to: at + d.normalized * model.timeline.table.ballRadius)
        return .handled
    }

    /// +1 when turning the aim counter-clockwise on the table plan also turns the line counter-clockwise on the
    /// screen, -1 when the camera views the table the other way round (portrait swings it a quarter turn). Left arrow
    /// always means "turn the line anticlockwise as the player sees it".
    private func screenSign() -> Double {
        guard let proj = projector(size: viewSize) else { return 1 }
        let o = model.aimOrigin, d = model.aimDirection
        let a = 2.0 * Double.pi / 180
        let turned = Vec2(cos(a) * d.x - sin(a) * d.y, sin(a) * d.x + cos(a) * d.y)
        guard let s0 = proj.screen(o), let s1 = proj.screen(o + d * 0.5), let s2 = proj.screen(o + turned * 0.5) else { return 1 }
        // Screen y points down, so a negative cross product is a counter-clockwise turn as seen.
        let cross = (s1.x - s0.x) * (s2.y - s0.y) - (s1.y - s0.y) * (s2.x - s0.x)
        return cross < 0 ? 1 : -1
    }

    private var spokenAim: String {
        model.racked
            ? String(localized: "\(String(format: "%+.0f", locale: Locale.current, model.aimOffset * 1000)) millimetres from the lead ball")
            : String(localized: "\(String(format: "%.1f", locale: Locale.current, model.aimDegrees)) degrees")
    }

    // MARK: Drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        guard model.aimReady, !model.placingCueBall, model.layout.count == 16, NextShot.isOnTable(model.aimOrigin), let proj = projector(size: size) else { return }
        let table = model.timeline.table
        let radius = table.ballRadius
        let origin = model.aimOrigin
        let dir = model.aimDirection
        guard dir.lengthSquared > 0.5, let cueScreen = proj.screen(origin) else { return }

        // Without the guide: no contact prediction, and the line stops a short way out instead of at the first ball.
        let contact = aimGuide ? AimGeometry.firstContact(layout: model.layout, from: origin, direction: dir, radius: radius) : nil
        let cushion = AimGeometry.cushionDistance(from: origin, direction: dir, table: table)
        let reach = contact.map { ($0.ghost - origin).length } ?? (aimGuide ? cushion : min(0.35, cushion))
        let accent = palette.accent, amber = palette.slide, paper = palette.paper

        // The cue and the mechanical bridge are 3D models (CueRig); for the trick shots that need the bridge, a small
        // label names it beside its head.
        if model.showsBridge { drawBridgeLabel(&ctx, proj, origin: origin, dir: dir, size: size) }

        // The aim line: a soft wide halo under a thin bright core, from the ball's edge to where the cue ball stops.
        if let a = proj.screen(origin + dir * radius), let b = proj.screen(origin + dir * reach) {
            var line = Path(); line.move(to: a); line.addLine(to: b)
            ctx.stroke(line, with: .color(accent.opacity(0.28)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            ctx.stroke(line, with: .color(paper.opacity(0.95)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        if let hit = contact {
            // The ghost ball: the cue ball where it will touch.
            if let ghost = circle(proj, hit.ghost, radius) {
                ctx.fill(ghost, with: .color(paper.opacity(0.14)))
                ctx.stroke(ghost, with: .color(paper.opacity(0.95)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            // The ball it will hit, ringed, and the spot where they touch.
            if let ring = circle(proj, hit.target, radius * 1.3) { ctx.stroke(ring, with: .color(amber), lineWidth: 2.5) }
            if let touch = proj.screen((hit.ghost + hit.target) * 0.5) {
                ctx.fill(Path(ellipseIn: CGRect(x: touch.x - 3, y: touch.y - 3, width: 6, height: 6)), with: .color(paper))
            }
            // Where the two balls go next: the object ball along the line of centres (longer for a fuller hit), the cue
            // ball at a right angle (longer for a thinner cut). Short guides, cut off at the cushion.
            let fullness = max(0, 1 - hit.cut * hit.cut).squareRoot()
            let objectLength = min(0.15 + 0.6 * fullness, AimGeometry.cushionDistance(from: hit.target, direction: hit.objectDirection, table: table))
            if let a = proj.screen(hit.target + hit.objectDirection * radius * 1.3), let b = proj.screen(hit.target + hit.objectDirection * (radius + objectLength)) {
                var path = Path(); path.move(to: a); path.addLine(to: b)
                ctx.stroke(path, with: .linearGradient(Gradient(colors: [amber, amber.opacity(0.05)]), startPoint: a, endPoint: b),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            if let side = hit.cueDirection {
                let cueLength = min(0.12 + 0.4 * hit.cut, AimGeometry.cushionDistance(from: hit.ghost, direction: side, table: table))
                if let a = proj.screen(hit.ghost + side * radius), let b = proj.screen(hit.ghost + side * (radius + cueLength)) {
                    var path = Path(); path.move(to: a); path.addLine(to: b)
                    ctx.stroke(path, with: .linearGradient(Gradient(colors: [paper.opacity(0.7), paper.opacity(0.05)]), startPoint: a, endPoint: b),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))
                }
            }
        } else if aimGuide, let end = circle(proj, origin + dir * reach, radius) {
            // Nothing in the way: the cue ball finishes at the cushion.
            ctx.stroke(end, with: .color(paper.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }

        // The pull handle around the cue ball, and the live power read-out while pulling.
        let ringRadius = max(24, handleRadius(proj, origin, radius))
        let handle = Path(ellipseIn: CGRect(x: cueScreen.x - ringRadius, y: cueScreen.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
        ctx.stroke(handle, with: .color(accent.opacity(pulling ? 1 : 0.8)), style: StrokeStyle(lineWidth: pulling ? 2.5 : 1.5, dash: pulling ? [] : [5, 4]))
        if pulling {
            let text = ctx.resolve(Text(String(format: "%.0f%%", model.powerFraction * 100)).font(.headline.monospacedDigit()).foregroundStyle(Color.white))
            let measured = text.measure(in: size)
            let badge = CGRect(x: cueScreen.x - measured.width / 2 - 10, y: cueScreen.y - ringRadius - measured.height - 14,
                               width: measured.width + 20, height: measured.height + 8)
            ctx.fill(Path(roundedRect: badge, cornerRadius: badge.height / 2), with: .color(.black.opacity(0.65)))
            ctx.draw(text, at: CGPoint(x: badge.midX, y: badge.midY))
        }
    }

    /// A small label so a first-time player knows what the new shape on the cloth is: the mechanical bridge (the
    /// "rest" or "spider"), whose 3D head CueRig stands 0.30 m behind the cue ball. The label sits on the cloth just
    /// past the right-hand end of the head (it is 0.12 m wide), where the old flat bridge put it.
    private func drawBridgeLabel(_ ctx: inout GraphicsContext, _ proj: AimProjector, origin: Vec2, dir: Vec2, size: CGSize) {
        let side = dir.perp
        let head = origin - dir * 0.30
        let halfWidth = 0.06
        guard let at = proj.screen(head + side * (halfWidth + 0.10), height: 0.002) else { return }
        let label = ctx.resolve(Text("Bridge").font(.caption2.weight(.semibold)).foregroundStyle(Color.white))
        let m = label.measure(in: size)
        let box = CGRect(x: at.x - m.width / 2 - 6, y: at.y - m.height / 2 - 2, width: m.width + 12, height: m.height + 4)
        ctx.fill(Path(roundedRect: box, cornerRadius: box.height / 2), with: .color(.black.opacity(0.55)))
        ctx.draw(label, at: CGPoint(x: box.midX, y: box.midY))
    }

    /// A circle lying on the cloth at the ball's height, as a closed screen path (a squashed oval from a low camera).
    private func circle(_ proj: AimProjector, _ centre: Vec2, _ radius: Double) -> Path? {
        var path = Path()
        let steps = 40
        for i in 0..<steps {
            let a = Double(i) / Double(steps) * 2 * Double.pi
            guard let p = proj.screen(centre + Vec2(cos(a), sin(a)) * radius) else { return nil }
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    /// On-screen size of the pull handle: about twice the ball's own radius, so it is easy to land a finger on.
    private func handleRadius(_ proj: AimProjector, _ centre: Vec2, _ radius: Double) -> CGFloat {
        guard let a = proj.screen(centre), let b = proj.screen(centre + Vec2(0, radius)), let c = proj.screen(centre + Vec2(radius, 0)) else { return 24 }
        return max(hypot(a.x - b.x, a.y - b.y), hypot(a.x - c.x, a.y - c.y)) * 2.0
    }
}

// MARK: Test hook

/// Scripted drags for -aimScript. Every drag is a list of screen points fed to AimOverlay.drag, one every 30 ms,
/// followed by the same end-of-drag clean-up a lifted finger causes.
@MainActor
private enum TestScript {
    static func run(on o: AimOverlay) async {
        let args = ProcessInfo.processInfo.arguments
        let scenario: String
        if args.contains("-retryDemo") { scenario = "retry" }
        else if let i = args.firstIndex(of: "-aimScript"), i + 1 < args.count { scenario = args[i + 1] }
        else { return }
        try? await Task.sleep(for: .seconds(3.5))
        let model = o.model
        switch scenario {
        case "break":
            // Aim a little off the apex ball, pull to about three quarters, break.
            await aim(o, toward: model.layout[1] + Vec2(0.01, 0.035))
            await hold(2)
            await pull(o, fraction: 0.75, hold: 2)
            await hold(1.5)
            _ = model.fire(); o.isOpen = false
        case "scratch":
            // A clear line to a pocket at full power: the cue ball should drop and be put back on the head spot.
            let t = model.timeline.table
            let corners = [Vec2(0, 0), Vec2(t.length, 0), Vec2(0, t.width), Vec2(t.length, t.width)] + t.pockets
            for pocket in corners {
                let d = (pocket - model.aimOrigin).normalized
                if AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: d, radius: t.ballRadius) == nil {
                    await aim(o, toward: pocket); break
                }
            }
            await pull(o, fraction: 1, hold: 1)
            _ = model.fire()
            await settle(model)
            NSLog("AIMSCRIPT scratch: cue ball now at (%.3f, %.3f), on table = %@", model.aimOrigin.x, model.aimOrigin.y,
                  NextShot.isOnTable(model.aimOrigin) ? "yes" : "NO")
        case "retry":
            // One shot at the farthest visible ball with draw, then Try again, switch to follow, and shoot again.
            let t = model.timeline.table
            var best: (Double, Vec2)?
            for b in 1..<16 where NextShot.isOnTable(model.layout[b]) {
                let delta = model.layout[b] - model.aimOrigin
                let seen = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: delta.normalized, radius: t.ballRadius)
                if seen?.ball == b, best == nil || delta.length > best!.0 { best = (delta.length, model.layout[b]) }
            }
            guard let ball = best?.1 else { return }
            await aim(o, toward: ball + (ball - model.aimOrigin).normalized.perp * t.ballRadius * 0.4)
            await pull(o, fraction: 0.6, hold: 1)
            model.activeTipUp = -0.012
            _ = model.fire()
            await settle(model)
            await hold(1)
            // Same settings first: the recordings must match exactly (the model logs both hashes).
            model.tryAgain()
            await hold(1)
            _ = model.fire()
            await settle(model)
            model.tryAgain()
            await hold(1)
            model.activeTipUp = 0.012
            NSLog("AIMSCRIPT retry: ghost on screen, spin changed to follow")
            await hold(4)
            _ = model.fire()
            await settle(model)
            NSLog("AIMSCRIPT retry: compared -> %@", model.retryComparison.map { RetryWords.sentence($0) } ?? "none")
        default: // shots
            for shot in 1...2 {
                let t = model.timeline.table
                // The farthest ball the cue ball can see in a straight line, so the guide has some length to show.
                var best: (Double, Vec2)?
                for b in 1..<16 where NextShot.isOnTable(model.layout[b]) {
                    let delta = model.layout[b] - model.aimOrigin
                    let seen = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: delta.normalized, radius: t.ballRadius)
                    if seen?.ball != b { continue }
                    if best == nil || delta.length > best!.0 { best = (delta.length, model.layout[b]) }
                }
                guard let ball = best?.1 else { return }
                // A slightly thin cut so the ghost ball and both outgoing lines show.
                let spot = ball + (ball - model.aimOrigin).normalized.perp * t.ballRadius * 0.8
                await aim(o, toward: spot)
                NSLog("AIMSCRIPT shot %d: aim %.2f deg, hits ball %d", shot, model.aimDegrees,
                      AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: model.aimDirection, radius: t.ballRadius)?.ball ?? -1)
                await hold(2.5)
                await pull(o, fraction: shot == 1 ? 0.55 : 0.8, hold: 2.5)
                NSLog("AIMSCRIPT shot %d: power %.2f m/s (%.0f%%)", shot, model.activePower, model.powerFraction * 100)
                await hold(1.5)
                _ = model.fire()
                await settle(model)
                await hold(1.5)
            }
        }
    }

    static func hold(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }

    /// Wait until the shot on screen has played out and the aiming layer is ready again (bounded, so a stuck run ends).
    static func settle(_ model: ShowpieceModel) async {
        for _ in 0..<400 { try? await Task.sleep(for: .milliseconds(100)); if model.aimReady, model.playing == false, model.time >= model.duration { break } }
    }

    /// A drag that starts well off the cue ball and ends on the screen point of the wanted table spot.
    static func aim(_ o: AimOverlay, toward spot: Vec2) async {
        guard let proj = o.projectorForScript(), let to = proj.screen(spot, height: nil), let from = proj.screen(o.model.aimOrigin + (spot - o.model.aimOrigin).perp.normalized * 0.4) else { return }
        await move(o, from, to)
    }

    /// A drag that starts on the cue ball and ends behind it, along the aim line, far enough for `fraction` power.
    static func pull(_ o: AimOverlay, fraction: Double, hold seconds: Double) async {
        let m = o.model
        guard let proj = o.projectorForScript(), let from = proj.screen(m.aimOrigin),
              let to = proj.screen(m.aimOrigin - m.aimDirection * (fraction * ShowpieceModel.pullReach)) else { return }
        await move(o, from, to, finish: false)
        await hold(seconds)
        o.endDrag()
    }

    private static func move(_ o: AimOverlay, _ from: CGPoint, _ to: CGPoint, finish: Bool = true) async {
        for step in 0...12 {
            let k = CGFloat(step) / 12
            o.drag(from: from, to: CGPoint(x: from.x + (to.x - from.x) * k, y: from.y + (to.y - from.y) * k))
            try? await Task.sleep(for: .milliseconds(30))
        }
        if finish { o.endDrag() }
    }
}
