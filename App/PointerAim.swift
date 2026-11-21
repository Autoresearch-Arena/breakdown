// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Aiming with a pointer, a scroll wheel and an Apple Pencil held above the screen, shared by the Mac and the
//          iPad (trackpad, mouse, Pencil hover). It is added to the touch aiming layer (AimOverlay) from the outside, as
//          one modifier, so the touch gestures in that file are untouched and a finger plays exactly as before:
//            - Hover: while "Your shot" is open and the balls are at rest, the aim line follows the pointer (or the
//              hovering Pencil tip) across the table before anything is clicked. It sets the same aim a drag would
//              (ShowpieceModel.aim(toward:)), so the overlay's own drawing shows the line, ghost ball and guides. Close
//              to the cue ball the aim holds still: there a tiny movement would swing the line wildly, and it is the
//              path the pointer takes to grab the ball.
//            - Press on the cue ball, drag back, release: the overlay's own pull-back sets the power while dragging (as
//              for a finger); with a pointer, letting go also takes the shot, the way a mouse player expects. Letting
//              go after dragging forward of the ball, or after hardly moving, takes no shot (a change of mind). A finger
//              or the Pencil touching the glass keeps the touch rule: letting go keeps the power for the Shoot button.
//            - Scroll (a mouse wheel or a two-finger slide on a trackpad) turns the aim a quarter degree at a time for
//              fine tuning, the same step as the arrow keys (ShowpieceModel.nudgeAim).
//          Also HoverHighlight, the small brightening every pointer-reachable control of the notebook and the title row
//          gets under the pointer, so the Mac and an iPad with a trackpad show what a click will hit.
//          Reads the camera through AimProjector (AimGeometry.swift), like the overlay does; writes the model only
//          through aim(toward:), nudgeAim(_:) and fire().
//          Not verified on a device in this change (written without building, per the batch rules): the hover, scroll
//          and release paths need a Mac and an iPad with a trackpad and a hover-capable Pencil to try.
// SRP/DRY check: Pass - checked AimOverlay (touch drag, arrow keys, drawing; reused through the model, not copied) and
//          AimGeometry (the projector, reused). The grab radius and pull slop match the overlay's on purpose.
import BreakdownLensModel
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
    }

    let cameraBox = AimProjector.CameraBox()
    var size = CGSize(width: 1, height: 1)
    var hovering = false
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
    @State private var state = PointerAimState()

    /// Same as AimOverlay's: how close to the cue ball (points) a press must start to grab it.
    private static let grabRadius: CGFloat = 44
    /// Same as AimOverlay's: a drag shorter than this is a click, not a pull.
    private static let pullSlop: CGFloat = 10
    /// Inside this distance of the cue ball (points) hovering leaves the aim alone. The aim's angle changes by about
    /// (sideways move / distance) radians, so at 110 points a 2-point wobble is about one degree; much closer the line
    /// would jump about as the pointer is brought onto the ball to pull back.
    private static let holdRadius: CGFloat = 110
    /// A pull shorter than this behind the cue ball, in metres on the table, is a change of mind and takes no shot:
    /// four per cent of the full pull (ShowpieceModel.pullReach, half a metre), below the softest deliberate shot.
    private static let minimumPull = 0.02
    /// Scroll distance (points of a trackpad slide) for one quarter-degree aim step: a slow, deliberate slide of about a
    /// finger's width (some 40 points) turns the line a degree and a half. A mouse wheel's notch counts as one step.
    private static let scrollPointsPerStep = 6.0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { $0.size } action: { state.size = $0 }
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
                _ = Self.applyScroll(Double(delta), precise: true, state: state, model: model)
            })
            #else
            .onAppear(perform: installScrollMonitor)
            .onDisappear(perform: removeScrollMonitor)
            #endif
    }

    private func projector() -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: state.cameraBox.find(in: root), size: state.size, frame: TableFrame(model.timeline.table))
    }

    // MARK: Hover

    private func hover(_ phase: HoverPhase) {
        switch phase {
        case .active(let point):
            state.hovering = true
            // Never while a button is held (that drag belongs to the overlay), and only once the balls are at rest: the
            // guide is drawn from where they stopped.
            guard state.press == nil, model.aimReady, let proj = projector() else { return }
            if let ball = proj.screen(model.aimOrigin), hypot(ball.x - point.x, ball.y - point.y) < Self.holdRadius { return }
            guard let spot = proj.table(at: point) else { return }
            model.aim(toward: spot)
        case .ended:
            state.hovering = false
        }
    }

    // MARK: Press and release

    private func track(_ events: SpatialEventCollection, ended: Bool = false) {
        for event in events {
            if state.press == nil, event.phase == .active, !ended {
                let onBall: Bool
                if let proj = projector(), let ball = proj.screen(model.aimOrigin) {
                    onBall = hypot(ball.x - event.location.x, ball.y - event.location.y) <= Self.grabRadius
                } else {
                    onBall = false
                }
                state.press = PointerAimState.Press(id: event.id, start: event.location, onBall: onBall,
                                                    isPointer: Self.isPointer(event))
            } else if let press = state.press, press.id == event.id, event.phase != .active || ended {
                state.press = nil
                if event.phase != .cancelled { release(press, at: event.location) }
            }
        }
    }

    /// A mouse or trackpad. On the Mac every press is one; on the iPad a finger and the Pencil report themselves apart.
    private static func isPointer(_ event: SpatialEventCollection.Event) -> Bool {
        #if os(macOS)
        return true
        #else
        return event.kind == .pointer
        #endif
    }

    /// A pointer let go after pulling back from the cue ball: take the shot at the power the pull set.
    private func release(_ press: PointerAimState.Press, at location: CGPoint) {
        guard press.isPointer, press.onBall, model.aimReady,
              hypot(location.x - press.start.x, location.y - press.start.y) > Self.pullSlop,
              let proj = projector(), let spot = proj.table(at: location) else { return }
        // How far behind the cue ball the pointer ended, along the aim line: the same measure the overlay's pull uses.
        let behind = (model.aimOrigin - spot).dot(model.aimDirection)
        guard behind >= Self.minimumPull else { return }
        hintSeen = true
        // The break hands the screen to its slow-motion opening, so the panel closes, as with the Break button.
        if model.fire() { isOpen = false }
    }

    // MARK: Scroll

    /// Turns a scroll into whole aim steps and applies them. `precise` scrolls (trackpads) are in points; a mouse
    /// wheel's are in notches. Shared by the iPad's recogniser and the Mac's event monitor. Returns false when the aim
    /// is not open to change (the balls are still moving), so the Mac lets the scroll go on to the window.
    @discardableResult
    fileprivate static func applyScroll(_ delta: Double, precise: Bool, state: PointerAimState, model: ShowpieceModel) -> Bool {
        guard state.press == nil, model.aimReady else { return false }
        state.scrollCarry += precise ? delta / scrollPointsPerStep : delta
        let steps = state.scrollCarry.rounded(.towardZero)
        if steps != 0 {
            state.scrollCarry -= steps
            // Scrolling up (or sliding two fingers up) turns the line anticlockwise on the table plan.
            model.nudgeAim(steps)
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
        state.scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            // Read the plain numbers here; the model is touched on the main actor, where AppKit delivers these anyway.
            let dx = Double(event.scrollingDeltaX), dy = Double(event.scrollingDeltaY)
            let precise = event.hasPreciseScrollingDeltas
            // Whichever way the slide mostly went; a sideways slide to the right turns clockwise.
            let delta = abs(dy) >= abs(dx) ? dy : -dx
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard state.hovering else { return false }
                return PointerAim.applyScroll(delta, precise: precise, state: state, model: model)
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
