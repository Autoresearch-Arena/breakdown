// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: projects through AimProjector.forLayer, so a
//          click lands where the pointer is in a narrow Mac window.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, gauges-pointer stream, item 31 and the pointer half of item 2
//          of plans/21-Nov-2026-bugs-after-0-6-6-plan.md, following docs/v07-contracts.md section 4. Hover no longer
//          writes the aim: moving the pointer to the Shoot button, the tip picture or the cue ball dragged the line with
//          it. Hover now only draws a faint dashed preview of where a click would aim; a click or press-drag on the cloth
//          sets the aim, and a set aim never moves when the pointer leaves. The Pencil's hover follows the same rule. A
//          pointer release behind the cue ball plays through ShowpieceModel.fireStroke(); a release ahead of the ball,
//          short of the backswing or after hardly moving is a change of mind that puts the aim and power back as they
//          were at the press (aimSnapshot / restoreAim), with no card. No release plays while a ball was lifted at the
//          press. Scroll turns the line the way it looks on screen, like the arrow keys (AimProjector.turnSign). The
//          pointer marks itself as the input in use (model.inputInUse), and nothing here acts while the person's
//          controls are not live (the computer's turn, a solve in flight).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 gaps, item 2's pointer half: whether a press is on the cue
//          ball is now the touch arbiter's own grab circle (TableTouch.grabRadius), and the click slop and the shortest
//          pull are the touch layer's (TableTouch.slop, StrokeTracker.minimumBackswing). The old fixed 44-point circle
//          disagreed with the arbiter's, so a press just off the ball could aim the line as it dragged and then play
//          here on a release behind the ball. A pointer still plays only on a release behind the ball; a forward
//          release is a change of mind.)
// PURPOSE: Aiming with a pointer, a scroll wheel and an Apple Pencil held above the screen, shared by the Mac and the
//          iPad (trackpad, mouse, Pencil hover). It is added to the touch aiming layer (AimOverlay) from the outside, as
//          one modifier, so the touch gestures in that file are untouched and a finger plays exactly as before:
//            - Hover: while "Your shot" is open and the balls are at rest, a faint dashed line runs from the cue ball
//              toward the pointer (or the hovering Pencil tip), as far as the first ball or cushion it would meet, with
//              a faint ring there. It is a preview only: the aim itself does not move. Drawn thin and dashed, with no
//              glow, so it never reads as the set line (the overlay's bright line). Over the cue ball itself, where a
//              press is a pull-back, no preview is drawn. With the Aim guide option off the preview is the overlay's
//              short line with no ring, so a hover never shows the contact the option hides.
//            - Click or press-drag on the cloth: sets the aim. The overlay's own drag and tap do this for every input; a
//              plain click on bare cloth that the overlay left alone is aimed here, after the overlay has had its turn,
//              so a click on a ball or a pocket keeps the overlay's snap to it.
//            - Press on the cue ball, drag back, release: the overlay's own pull-back sets the power while dragging (as
//              for a finger); with a pointer, letting go behind the ball also takes the shot, the way a mouse player
//              expects. Letting go ahead of the ball, short of a real pull, or after hardly moving, is a change of mind:
//              aim and power go back to what they were at the press. A finger or the Pencil touching the glass keeps the
//              touch rule: letting go keeps the power for the Shoot button (or a push through the ball plays it).
//            - Scroll (a mouse wheel or a two-finger slide on a trackpad) turns the aim a quarter degree at a time for
//              fine tuning, the same step and the same on-screen sense as the arrow keys (ShowpieceModel.nudgeAim).
//          Also HoverHighlight, the small brightening every pointer-reachable control of the notebook and the title row
//          gets under the pointer, so the Mac and an iPad with a trackpad show what a click will hit.
//          Reads the camera through AimProjector and the guide's stop rule through AimGeometry.guideLine
//          (AimGeometry.swift), like the overlay does; writes the model only through aim(toward:), nudgeAim(_:),
//          fireStroke(), restoreAim(_:) and inputInUse.
//          Not verified on a device in this change (written without building, per the batch rules): the hover preview,
//          the click, the scroll and the release paths need a Mac, an iPad with a trackpad and a hover-capable Pencil.
// SRP/DRY check: Pass - checked AimOverlay (touch drag, tap, arrow keys, drawing; reused through the model, not copied),
//          AimGeometry (the projector, the guide's stop rule and the turn sign, reused) and StrokeGesture (the measured
//          stroke; this file only decides what a pointer's release means). The grab radius and pull slop match the
//          overlay's on purpose. The break's spot-to-offset rule in previewDirection mirrors ShowpieceModel.aim(toward:)
//          for drawing only, because asking the model would move the aim.
import BreakdownLensModel
import BreakdownPhysics
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension View {
    /// Pointer, scroll and Pencil-hover aiming for the aiming layer. `isOpen` is the shot panel's switch, closed by a
    /// break the same way the Break button closes it.
    func pointerAim(model: ShowpieceModel, bridge: SceneBridge, isOpen: Binding<Bool>) -> some View {
        modifier(PointerAim(model: model, bridge: bridge, isOpen: isOpen))
    }

    /// The pointer-hover brightening for a control (see HoverHighlight).
    func hoverHighlight(_ style: HoverHighlight.Style = .lift) -> some View {
        modifier(HoverHighlight(style: style))
    }
}

/// What the pointer is doing right now. A class, so the Mac's scroll-wheel monitor (an AppKit callback outside the view
/// tree) reaches the same values the gestures write.
@MainActor
private final class PointerAimState {
    struct Press {
        var id: SpatialEventCollection.Event.ID
        var start: CGPoint
        /// The press began on the cue ball: a pull-back, not an aim drag.
        var onBall: Bool
        /// A mouse or trackpad click (not a finger or the Pencil on the glass).
        var isPointer: Bool
        /// A ball was lifted when the press began: this press carries that ball or puts it down (the overlay's job),
        /// and its release is never a shot or an aim.
        var placing: Bool
        /// The balls were at rest and the person's controls live when the press began.
        var ready: Bool
        /// Puts the aim and power back exactly as they were at the press (the model's snapshot), and tells whether
        /// they still are. Closures, so this file needs no name for the snapshot's type.
        var restore: @MainActor () -> Void
        var unchanged: @MainActor () -> Bool
    }

    let cameraBox = AimProjector.CameraBox()
    var size = CGSize(width: 1, height: 1)
    /// The layer's frame in StageSpace, for AimProjector.forLayer (UI rethink package 1).
    var layerFrame: CGRect?
    var hovering = false
    /// Where the pointer or the Pencil hovers over the cloth, in the layer's own points, while a preview may be drawn;
    /// nil otherwise.
    var previewPoint: CGPoint?
    var press: Press?
    /// Scroll distance not yet turned into whole aim steps, so slow trackpad slides still add up.
    var scrollCarry = 0.0
    #if os(macOS)
    var scrollMonitor: Any?
    #endif
}

struct PointerAim: ViewModifier {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var isOpen: Bool
    @AppStorage("aimHintSeen") private var hintSeen = false
    @Environment(\.palette) private var palette
    @State private var state = PointerAimState()
    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    /// True while a hover preview may be drawn (the point itself is on the state object: the preview's Canvas redraws
    /// every frame anyway, so a hover move need not re-render this layer, only switching the preview on or off does).
    @State private var previewing = false

    /// The touch layer's own slop: a drag shorter than this is a click, not a pull (TableTouch.slop).
    private static var pullSlop: CGFloat { TableTouch.slop }
    /// A pull shorter than this behind the cue ball, in metres on the table, is a change of mind and takes no shot:
    /// four per cent of the full pull, below the softest deliberate shot. The touch stroke's backswing floor
    /// (StrokeTracker.minimumBackswing), so a pointer and a finger need the same real pull.
    private static let minimumPull = StrokeTracker.minimumBackswing

    /// True when a screen point is inside the cue ball's grab circle: the very circle the touch arbiter grabs with and
    /// the overlay draws (TableTouch.grabRadius, from the ball's size on screen with a 22-point floor). A fixed
    /// 44-point circle here used to disagree with it: a press just outside the arbiter's circle but inside this one
    /// aimed the line as it dragged, then fired here on a release behind the ball (item 2's pointer half).
    private func onCueBall(_ point: CGPoint, _ proj: AimProjector) -> Bool {
        guard let ball = proj.screen(model.aimOrigin) else { return false }
        let radius = TableTouch.grabRadius(proj, centre: model.aimOrigin, ballRadius: model.timeline.table.ballRadius)
        return hypot(ball.x - point.x, ball.y - point.y) <= radius
    }
    /// Scroll distance (points of a trackpad slide) for one quarter-degree aim step: a slow, deliberate slide of about a
    /// finger's width (some 40 points) turns the line a degree and a half. A mouse wheel's notch counts as one step.
    private static let scrollPointsPerStep = 6.0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { $0.size } action: { state.size = $0 }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { state.layerFrame = $0 }
            // The hover preview, over the aiming layer's own drawing; it never takes a touch or a click. Redrawn every
            // frame while it shows, so it follows the camera if the table is zoomed under a still pointer.
            .overlay {
                if previewing {
                    TimelineView(.animation) { _ in
                        Canvas { ctx, size in drawPreview(&ctx, size: size) }
                    }
                    // The aiming layer fills the screen past the safe area; so must this, or its points would be
                    // offset from the layer's by the safe-area inset.
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .onContinuousHover(coordinateSpace: .local) { phase in hover(phase) }
            // Alongside the overlay's own drag, never instead of it: this only watches which device pressed and where,
            // and acts when a pointer lets go.
            .simultaneousGesture(
                SpatialEventGesture()
                    .onChanged { events in track(events) }
                    .onEnded { events in track(events, ended: true) }
            )
            #if os(iOS)
            .gesture(ScrollWheelAim { delta in
                Self.noteInput(model)
                let sign = Self.turnSign(state: state, bridge: bridge, model: model)
                _ = Self.applyScroll(Double(delta), precise: true, sign: sign, state: state, model: model)
            })
            #else
            .onAppear(perform: installScrollMonitor)
            .onDisappear(perform: removeScrollMonitor)
            #endif
    }

    /// The camera maths for this layer, from the live camera entity; nil before the scene exists.
    private static func projector(state: PointerAimState, bridge: SceneBridge, model: ShowpieceModel) -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector.forLayer(camera: state.cameraBox.find(in: root), bridge: bridge, layerFrame: state.layerFrame,
                                     layerSize: state.size, frame: TableFrame(model.timeline.table))
    }

    private func projector() -> AimProjector? { Self.projector(state: state, bridge: bridge, model: model) }

    /// The sign that makes a scroll turn the line the way it looks on screen, from the camera now (see
    /// AimProjector.turnSign). +1 before the scene exists.
    private static func turnSign(state: PointerAimState, bridge: SceneBridge, model: ShowpieceModel) -> Double {
        projector(state: state, bridge: bridge, model: model)?
            .turnSign(origin: model.aimOrigin, direction: model.aimDirection) ?? 1
    }

    /// The pointer (mouse, trackpad) is the input in use: the first-minute line and the hints follow it (item 1). Only
    /// written when it changes, so a stream of hover moves does not keep invalidating the views that read it.
    private static func noteInput(_ model: ShowpieceModel) {
        if model.inputInUse != .pointer { model.inputInUse = .pointer }
    }

    // MARK: Hover

    private func hover(_ phase: HoverPhase) {
        switch phase {
        case .active(let point):
            state.hovering = true
            // On the Mac every hover is a pointer. On the iPad a trackpad's pointer and a hovering Pencil both arrive
            // here and cannot be told apart, so only a pointer's click or scroll marks the input there.
            #if os(macOS)
            Self.noteInput(model)
            #endif
            state.previewPoint = previewAllowed(at: point) ? point : nil
            let on = state.previewPoint != nil
            if on != previewing { previewing = on }
        case .ended:
            state.hovering = false
            state.previewPoint = nil
            previewing = false
        }
    }

    /// The shot can be aimed now, by this person, and nothing is lifted or held: the conditions for a preview (and, at
    /// release, for a click to aim).
    private var aimOpenNow: Bool {
        model.aimReady && !model.placingCueBall && model.personControlsLive && model.openControls.contains(.aim)
            && model.layout.count == 16 && NextShot.isOnTable(model.aimOrigin)
    }

    /// A preview is drawn for a hover over the cloth while the aim may be set by a click, and not over the cue ball,
    /// where a press is a pull-back rather than an aim.
    private func previewAllowed(at point: CGPoint) -> Bool {
        guard state.press == nil, aimOpenNow, let proj = projector(), proj.table(at: point) != nil else { return false }
        return !onCueBall(point, proj)
    }

    /// The direction a click at `spot` would aim, without moving the aim. For a shot, straight through the spot. For
    /// the break the click only chooses how far off the apex ball to hit (ShowpieceModel.aim(toward:)): where the line
    /// through the spot crosses the apex ball's column, held inside the break's aim limit.
    private func previewDirection(toward spot: Vec2) -> Vec2? {
        let from = model.aimOrigin
        let d = (spot - from).normalized
        guard d.lengthSquared > 0.5 else { return nil }
        guard model.racked, model.layout.count > 1 else { return d }
        let apex = model.layout[1]
        let limit = ShowpieceModel.breakAimLimit
        let offset: Double
        if d.x > 0.05 {
            let y = from.y + d.y * ((apex.x - from.x) / d.x)
            offset = min(max(y - apex.y, -limit), limit)
        } else {
            offset = d.y >= 0 ? limit : -limit
        }
        return (apex + Vec2(0, offset) - from).normalized
    }

    /// The overlay's short line with the Aim guide off (AimOverlay's draw: 0.35 m), so the preview tells no more than
    /// the set line would: with the guide off the player judges the angle, and a hover must not show the contact.
    private static let unguidedReach = 0.35

    /// The faint preview: a thin dashed line from the cue ball's edge to the first ball, cushion, bumper, pin or hole it
    /// would meet (the guide's own stop rule, AimGeometry.guideLine), and a faint dashed ring where the cue ball would
    /// be at that moment. Along the cue's line: it shows where a click points the cue; the overlay's guide then bends
    /// with side spin as usual. With the Aim guide option off it follows the overlay's rule instead: a short line that
    /// still stops at anything in its way, and no ring.
    private func drawPreview(_ ctx: inout GraphicsContext, size: CGSize) {
        guard let point = state.previewPoint, state.press == nil, aimOpenNow,
              let proj = AimProjector.forLayer(camera: bridge.table.flatMap { state.cameraBox.find(in: $0.root) },
                                               bridge: bridge, layerFrame: state.layerFrame, layerSize: size,
                                               frame: TableFrame(model.timeline.table)),
              let spot = proj.table(at: point), let direction = previewDirection(toward: spot) else { return }
        let table = model.timeline.table
        let r = table.ballRadius
        let guide = AimGeometry.guideLine(layout: model.layout, origin: model.aimOrigin, direction: direction, table: table)
        let reach = aimGuide ? guide.reach : min(Self.unguidedReach, guide.reach)
        guard reach > r, let a = proj.screen(model.aimOrigin + direction * r),
              let b = proj.screen(model.aimOrigin + direction * reach) else { return }
        var line = Path(); line.move(to: a); line.addLine(to: b)
        let ink = palette.paper
        ctx.stroke(line, with: .color(ink.opacity(0.45)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 5]))
        guard aimGuide else { return }
        // Where the cue ball would be when the line ends: at the ghost ball if a ball is met, at the stop otherwise.
        let end = model.aimOrigin + direction * reach
        var ring = Path()
        let steps = 32
        for i in 0..<steps {
            let t = Double(i) / Double(steps) * 2 * Double.pi
            guard let p = proj.screen(end + Vec2(cos(t), sin(t)) * r) else { return }
            if i == 0 { ring.move(to: p) } else { ring.addLine(to: p) }
        }
        ring.closeSubpath()
        ctx.stroke(ring, with: .color(ink.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
    }

    // MARK: Press and release

    private func track(_ events: SpatialEventCollection, ended: Bool = false) {
        for event in events {
            if state.press == nil, event.phase == .active, !ended {
                begin(event)
            } else if let press = state.press, press.id == event.id, event.phase != .active || ended {
                state.press = nil
                if event.phase != .cancelled { release(press, at: event.location) }
            }
        }
    }

    /// The first device down: remember where, what kind, whether it grabbed the cue ball, whether a ball was lifted,
    /// and the aim and power as they were (contract section 4's snapshot, so a change of mind can put them back).
    private func begin(_ event: SpatialEventCollection.Event) {
        let isPointer = Self.isPointer(event)
        if isPointer { Self.noteInput(model) }
        state.previewPoint = nil
        previewing = false
        // Inside the arbiter's grab circle, and only with a full layout (StrokeGestures.onCueBall asks the same), so a
        // press this layer treats as a pull is exactly the one the arbiter made a pull.
        let onBall: Bool
        if let proj = projector(), model.layout.count == 16, NextShot.isOnTable(model.aimOrigin) {
            onBall = onCueBall(event.location, proj)
        } else {
            onBall = false
        }
        let model = self.model
        let snapshot = model.aimSnapshot()
        state.press = PointerAimState.Press(
            id: event.id, start: event.location, onBall: onBall, isPointer: isPointer,
            placing: model.placingCueBall, ready: model.aimReady && model.personControlsLive,
            restore: { model.restoreAim(snapshot) },
            unchanged: { model.aimSnapshot() == snapshot })
    }

    /// A mouse or trackpad. On the Mac every press is one; on the iPad a finger and the Pencil report themselves apart
    /// (the Pencil on the glass is .pencil, so it keeps the touch rules).
    private static func isPointer(_ event: SpatialEventCollection.Event) -> Bool {
        #if os(macOS)
        return true
        #else
        return event.kind == .pointer
        #endif
    }

    /// What a pointer's release means. A finger or the Pencil is the overlay's and the stroke's business, and a press
    /// that began with a ball lifted only carried or put down that ball (the overlay puts it down on release; firing
    /// here as well would also take the shot, depending on which handler ran first).
    private func release(_ press: PointerAimState.Press, at location: CGPoint) {
        guard press.isPointer, !press.placing else { return }
        let moved = hypot(location.x - press.start.x, location.y - press.start.y) > Self.pullSlop
        if press.onBall {
            releasePull(press, at: location, moved: moved)
        } else if !moved {
            click(press, at: location)
        }
    }

    /// A pointer let go after pressing on the cue ball. Behind the ball, past a real pull: take the shot at the power the
    /// pull set. Anything else (ahead of the ball, too short a pull, hardly moved) is a change of mind: the aim and power
    /// go back to the press, and no card is shown.
    private func releasePull(_ press: PointerAimState.Press, at location: CGPoint, moved: Bool) {
        // Only while nothing has been struck since the press (a push through the ball may already have played it) and
        // nothing has been lifted; otherwise this release means nothing.
        guard press.ready, model.aimReady, !model.placingCueBall, model.personControlsLive else { return }
        guard moved, let spot = projector()?.table(at: location) else { press.restore(); return }
        // How far behind the cue ball the pointer ended, along the aim line: the same measure the overlay's pull uses.
        let behind = (model.aimOrigin - spot).dot(model.aimDirection)
        guard behind >= Self.minimumPull else { press.restore(); return }
        hintSeen = true
        // The break hands the screen to its slow-motion opening, so the panel closes, as with the Break button. A refused
        // stroke records its reason on the model, and the shot card says it.
        if model.fireStroke() == .breakStruck { isOpen = false }
    }

    /// A pointer click on the cloth (it hardly moved): aim through the spot. Usually inert: the overlay's own drag aims
    /// at the press for every input today, so by now the aim has changed and this does nothing. It is the fallback for
    /// an overlay that waits before aiming (contract section 4's undecided touch, whose tap on bare cloth may do
    /// nothing), so a click always sets the aim. The overlay's tap runs on the same release and snaps the aim to a ball
    /// or a pocket under the click; that snap must win, so this waits one turn of the main actor and aims only if the
    /// aim is still what it was at the press (the overlay did nothing with this click).
    private func click(_ press: PointerAimState.Press, at location: CGPoint) {
        guard press.ready, aimOpenNow, let spot = projector()?.table(at: location) else { return }
        let model = self.model
        let unchanged = press.unchanged
        Task { @MainActor in
            guard unchanged(), model.aimReady, !model.placingCueBall, model.personControlsLive else { return }
            model.aim(toward: spot)
        }
    }

    // MARK: Scroll

    /// Turns a scroll into whole aim steps and applies them. `precise` scrolls (trackpads) are in points; a mouse
    /// wheel's are in notches. `sign` makes the turn follow the screen (AimProjector.turnSign): scrolling up turns the
    /// line anticlockwise as the player sees it, as the left arrow does. Shared by the iPad's recogniser and the Mac's
    /// event monitor. Returns false when the aim is not open to change (the balls are still moving, a ball is lifted,
    /// it is not the person's turn), so the Mac lets the scroll go on to the window.
    @discardableResult
    fileprivate static func applyScroll(_ delta: Double, precise: Bool, sign: Double, state: PointerAimState,
                                        model: ShowpieceModel) -> Bool {
        guard state.press == nil, model.aimReady, !model.placingCueBall, model.personControlsLive else { return false }
        state.scrollCarry += precise ? delta / scrollPointsPerStep : delta
        let steps = state.scrollCarry.rounded(.towardZero)
        if steps != 0 {
            state.scrollCarry -= steps
            model.nudgeAim(steps * sign)
        }
        return true
    }

    #if os(macOS)
    /// SwiftUI has no scroll-wheel event for a plain view, so the Mac listens to the window's scroll events while the
    /// aiming layer is on screen and takes only those that arrive while the pointer is over the table.
    private func installScrollMonitor() {
        guard state.scrollMonitor == nil else { return }
        let state = self.state
        let model = self.model
        let bridge = self.bridge
        state.scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            // Read the plain numbers here; the model is touched on the main actor, where AppKit delivers these anyway.
            let dx = Double(event.scrollingDeltaX), dy = Double(event.scrollingDeltaY)
            let precise = event.hasPreciseScrollingDeltas
            // Whichever way the slide mostly went; a sideways slide to the right turns clockwise.
            let delta = abs(dy) >= abs(dx) ? dy : -dx
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard state.hovering else { return false }
                PointerAim.noteInput(model)
                let sign = PointerAim.turnSign(state: state, bridge: bridge, model: model)
                return PointerAim.applyScroll(delta, precise: precise, sign: sign, state: state, model: model)
            }
            return handled ? nil : event
        }
    }

    private func removeScrollMonitor() {
        if let monitor = state.scrollMonitor { NSEvent.removeMonitor(monitor) }
        state.scrollMonitor = nil
        state.scrollCarry = 0
    }
    #endif
}

#if os(iOS)
/// The iPad's scroll input (a mouse wheel, or two fingers sliding on a trackpad) as a pan recogniser that accepts no
/// touches at all, so a finger on the glass still reaches the overlay's drag untouched.
private struct ScrollWheelAim: UIGestureRecognizerRepresentable {
    let onScroll: @MainActor (CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.allowedScrollTypesMask = .all
        pan.allowedTouchTypes = []
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard let view = recognizer.view else { return }
        // Report only the movement since the last call: reset the running total each time.
        let t = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)
        let delta = abs(t.y) >= abs(t.x) ? t.y : -t.x
        if delta != 0 { onScroll(delta) }
    }
}
#endif

// MARK: Hover highlight

/// A control brightens a little while the pointer is over it, so on the Mac and on an iPad with a trackpad the player
/// sees what a click will hit. Touch never hovers, so phones are unchanged.
struct HoverHighlight: ViewModifier {
    enum Style {
        /// Brighten the control itself: for buttons that already draw their own glass shape.
        case lift
        /// Lay a faint rounded fill behind it: for plain rows that have no shape of their own.
        case fill(cornerRadius: CGFloat)
    }

    var style: Style = .lift
    @State private var hovering = false

    func body(content: Content) -> some View {
        Group {
            switch style {
            case .lift:
                content.brightness(hovering ? 0.08 : 0)
            case .fill(let radius):
                content.background(RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.07 : 0)))
            }
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
