// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (merge with the lessons: a locked power control is not moved by the
//          stroke's depth).
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 touch stream, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items
//          2, 5, 7, 9, 11, 12 and 13, docs/v07-contracts.md section 4. This file now decides who owns every touch on the
//          aiming layer (TableTouchArbiter, below): a touch waits, undecided, until it moves past the slop or rests for
//          the hold delay, so the first finger of a pinch, a pan or a double tap never moves the aim, never skips the
//          replay and never starts a stroke; a second finger turns it into a zoom (aim and power put back from the
//          touch-down snapshot) or, when one of the two is on the cue ball, into the stroke and its bridge in either
//          order. A committed touch strokes (on the cue ball), lifts and carries a ball (free play), or aims. The
//          cue-ball grab circle is sized from the ball on screen. The stroke refuses before it starts when the model
//          says it may not be played (no call and no suggestion, the computer's turn, ...), clicks only once the shot
//          is accepted, wants a real backswing, keeps the finger's power on a lift, follows the curved pull, leaves the
//          power alone in lesson steps not about power, honours "Shoot with the button only", and the Pencil's tilt
//          steers the cue angle only past a writing grip, through the model's lock. A mouse or trackpad never strokes:
//          its pull is the overlay's, its release PointerAim's.)
// PURPOSE: The stroke by hand (plans/21-Nov-2026-stroke-and-power-plan.md), the touch side, and the one place that
//          decides what a touch on the aiming layer is. Added to the aiming layer (AimOverlay) as one modifier, which
//          hands the aim drag, a pointer's pull, carrying a lifted ball, letting go and taps back to the overlay through
//          TableTouchRoutes, and drawn from its Canvas with one call:
//          - Who owns a touch (docs/v07-contracts.md section 4): undecided at touch-down (the model's aimSnapshot() is
//            taken then and nothing on the model changes); zoom when a second finger lands away from the cue ball, or a
//            double tap is recognised (TableZoom.onDoubleTap; the snapshot is put back); bridge and stroke when one of
//            two fingers is on the cue ball, whichever landed first; then, once the first finger moves past the slop or
//            rests for the hold delay, stroke (on the cue ball), placement (on a ball free play lets the player lift,
//            or while a ball is already lifted) or aim. A touch lifted while undecided is a tap: it waits out the
//            double-tap window, then skips a playing shot to its end or aims through the spot (snapping to a ball or a
//            pocket). A mouse or trackpad decides at once (a click sets the aim; no hold, no zoom pairing).
//          - The stroke: followed by its own id, so other fingers never disturb it. Each move is a StrokeTracker sample;
//            the power follows the tracker's powerDepth through the curved pull (StrokeTracker.powerFraction); the
//            model keeps the stroke so far as its pending stroke, so whichever route then fires plays this stroke. A
//            quick push forward through the cue ball after a real backswing plays the shot through the model's
//            fireStroke(), and only an accepted strike gets the firm click. Lifting without a push keeps the power
//            where the finger is.
//          - The groove: a faint band on the cloth along the cue line through where the finger first touched, as wide
//            as a steady stroke's wander (StrokeModel.steadyWander), and the finger's thin trace over it.
//          - Feel: a faint texture while the finger is on the groove, rougher as it strays (Haptics.strokeTexture).
//          - The bridge hand: the other finger resting on the cloth sets the bridge length, its distance to the cue
//            ball (clamped in StrokeModel), and may move while it rests; a stroke with no second finger uses the
//            automatic bridge.
//          - Apple Pencil on iPad: stood up past a writing grip while it strokes, its angle off the glass sets the cue's
//            angle through model.activeElevation (so a lesson's lock holds); at a writing grip it changes nothing.
//          While a stroke is on, or a finger rests as its bridge, the table's pinch and two-finger pan hold still
//          (TableZoom.strokeHold).
// SRP/DRY check: Pass - checked AimOverlay (the aim, pointer pull, carrying and tap handlers stay there and are called
//          from here; its pull handle ring is drawn at TableTouch.grabRadius, the same circle this file grabs with),
//          PointerAim (hover, the pointer's release-to-shoot and scroll stay there), TableZoom (pinch, pan and the
//          double tap's zoom stay there; this file only decides when they own the fingers) and CueAngleMenu (the Pencil
//          snaps to its offered angles, so the menu always reads what the Pencil set).
import BreakdownLensModel
import BreakdownPhysics
import SwiftUI

// MARK: Shared touch rules

/// The numbers and small rules every part of the touch layer shares, so the circle drawn round the cue ball is the
/// circle that grabs it and the pull reads power the same way everywhere.
@MainActor
enum TableTouch {
    /// Points a touch must move before it is a drag, not a tap: about a third of a fingertip, the slop the overlay's
    /// pull has always used.
    static let slop: CGFloat = 10
    /// The smallest cue-ball grab circle, points (a radius): half of the 44-point minimum hit target, so a fingertip
    /// can always land in it even on an upright phone where the ball is a few points across.
    static let grabFloor: CGFloat = 22
    /// Seconds a finger may rest, undecided, before it commits: long enough for the second finger of a pinch (which
    /// lands within about a tenth of a second of the first) or of a two-finger placement, short enough that a finger
    /// resting on the cue ball to start a slow stroke is not kept waiting noticeably.
    static let holdDelay = 0.3
    /// Seconds after touch-down within which a second finger pairs with the first (zoom, or bridge and stroke). Equal
    /// to the hold delay: a touch can only pair while it is still undecided, and the hold is what ends that.
    static let pairingWindow = holdDelay
    /// Seconds a tap waits before it acts, in case it is the first half of a double tap: about the system's own
    /// double-tap interval (some 0.35 s), so the first tap of a zoom never aims or skips the replay.
    static let doubleTapWindow = 0.35

    /// The cue-ball grab circle's radius on screen: twice the ball's own radius as drawn there (the pull handle ring
    /// the overlay draws round it), with the floor above.
    static func grabRadius(_ proj: AimProjector, centre: Vec2, ballRadius: Double) -> CGFloat {
        guard let a = proj.screen(centre), let b = proj.screen(centre + Vec2(0, ballRadius)),
              let c = proj.screen(centre + Vec2(ballRadius, 0)) else { return grabFloor }
        let onScreen = max(hypot(a.x - b.x, a.y - b.y), hypot(a.x - c.x, a.y - c.y))
        return max(grabFloor, onScreen * 2)
    }

    /// True when a pull on the cue ball should move the power bar: the power control is open, and in a lesson only
    /// when the lesson is about power. In the other lessons' steps (try 3 and the pass shot open every control) the
    /// pull plays the shot at the power already set, so a pull drawn only to play never drags the lesson's power off.
    static func pullSetsPower(_ model: ShowpieceModel) -> Bool {
        guard model.openControls.contains(.power) else { return false }
        let lessons = model.lessonMode
        if lessons.isActive, let lesson = lessons.current { return lesson.control == .power }
        return true
    }
}

/// What the aiming layer does once the arbiter has handed it a gesture (AimOverlay supplies these).
struct TableTouchRoutes {
    /// Aim through the table point under this screen point (a drag to aim, or a click).
    var aim: @MainActor (CGPoint) -> Void
    /// A mouse or trackpad pulling back from the cue ball, from `start` to `now`: the power follows it.
    var pull: @MainActor (_ start: CGPoint, _ now: CGPoint) -> Void
    /// Carry the lifted ball to this screen point.
    var carry: @MainActor (CGPoint) -> Void
    /// The finger or pointer let go of an aim, a pull or a carried ball (a carried ball is put down).
    var release: @MainActor () -> Void
    /// A tap or click that did not move, with the balls at rest: aim through it, snapping to a ball or a pocket.
    var tap: @MainActor (CGPoint) -> Void
}

/// Who owns the touch sequence on the aiming layer now (docs/v07-contracts.md section 4).
enum TouchOwner: Equatable {
    /// From touch-down until the finger moves past the slop, rests for the hold delay, or a second finger lands.
    case undecided
    /// Pinch, two-finger pan or double tap: TableZoom's gestures own every finger until all lift.
    case zoom
    /// The measured stroke on the cue ball (with any other finger as its bridge).
    case stroke
    /// A lifted ball follows the finger or pointer; letting go puts it down.
    case placement
    /// Drag to aim.
    case aim
    /// A mouse or trackpad pulling back from the cue ball.
    case pull
    /// A mouse or trackpad pressed on a ball it could lift: a drag lifts and carries it, a click aims at it.
    case liftOnMove
    /// Nothing more for this sequence: a refused stroke, a stroke already played, controls not live.
    case done
}

/// The stroke in progress and the arbitration state, shared by the gesture and the overlay's drawing. A class so the
/// gesture (a value) and the Canvas see the same state; not observed, because the Canvas redraws every frame anyway.
@MainActor
final class StrokeSession {
    typealias EventID = SpatialEventCollection.Event.ID

    // The stroke.
    var tracker: StrokeTracker?
    var strokeID: EventID?
    var bridgeID: EventID?
    /// Where the stroke finger first touched, on screen, and the groove's unit directions there: back (away from the
    /// ball) and to the shooter's right.
    var origin = CGPoint.zero
    var back = CGVector(dx: 0, dy: 1)
    var right = CGVector(dx: 1, dy: 0)
    /// Screen points the finger has passed through, for the thin live trace.
    var screenTrace: [CGPoint] = []
    /// Screen length of a full pull (StrokeTracker.fullPull) from the touch point, for the groove's length.
    var grooveLength: CGFloat = 200
    /// The bridge finger's table spot while it rests on the cloth.
    var bridgeSpot: Vec2?
    /// Groove travel since the last texture tick, points.
    var sinceTick: CGFloat = 0
    /// True once the stroke finger has moved past the slop: the pull is on (the overlay lights its handle).
    var pulled = false
    /// True once the Pencil, during this stroke, has been stood up past the writing grip: from then on it steers the
    /// cue angle (down to level, too) until the stroke ends. Before that, the menu's angle stands.
    var pencilSteering = false

    // Who owns the touch.
    var owner: TouchOwner?
    /// Every finger or pointer down in this sequence.
    var down: Set<EventID> = []
    /// The first touch as it landed, and as it is now.
    var first: SpatialEventCollection.Event?
    var firstNow: SpatialEventCollection.Event?
    /// True for a mouse or trackpad sequence.
    var isPointer = false
    /// Puts back the aim and power from touch-down (or from the first press of a possible double tap): a closure over
    /// model.aimSnapshot() and model.restoreAim(_:), so a zoom can undo whatever the first finger did.
    var restoreAim: (@MainActor () -> Void)?
    /// The hold-delay timer of an undecided touch, and a tap waiting out the double-tap window.
    var holdTask: Task<Void, Never>?
    var pendingTap: Task<Void, Never>?
    /// The last tap or click: when it lifted (on the events' clock, and on the system clock for the double-tap hook,
    /// which has no event) and the restore from before it, so a double tap puts back the aim from before its first half.
    var recentTap: (time: Double, uptime: Double, restoreAim: (@MainActor () -> Void)?)?
    /// Double taps recognised so far (TableZoom.onDoubleTap), and the count when this sequence began: a waiting tap
    /// from a sequence that turned out to be half of a double tap does nothing.
    var doubleTaps = 0
    var doubleTapsAtStart = 0

    var isTracking: Bool { tracker != nil }
    /// True while a stroke's pull is on: the overlay lights the handle and ticks the power.
    var pullOn: Bool { tracker != nil && pulled }
}

extension View {
    /// The touch layer of the aiming layer: who owns each touch, and the measured stroke (see StrokeGestures).
    func strokeGestures(model: ShowpieceModel, bridge: SceneBridge, session: StrokeSession,
                        isOpen: Binding<Bool>, routes: TableTouchRoutes) -> some View {
        modifier(StrokeGestures(model: model, bridge: bridge, session: session, isOpen: isOpen, routes: routes))
    }
}

struct StrokeGestures: ViewModifier {
    typealias Event = SpatialEventCollection.Event

    let model: ShowpieceModel
    let bridge: SceneBridge
    let session: StrokeSession
    @Binding var isOpen: Bool
    let routes: TableTouchRoutes
    @AppStorage("aimHintSeen") private var hintSeen = false
    /// The Options switch "Shoot with the button only" (stroke-model stream): the push sets power but never plays.
    @AppStorage(GameSettings.buttonOnlyKey) private var buttonOnly = false
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var size = CGSize(width: 1, height: 1)

    /// Points of groove travel between texture ticks: about a fingertip's width, so a slow stroke ticks gently and a
    /// quick one buzzes.
    private static let tickSpacing: CGFloat = 12
    /// The Pencil's angle off the glass at the upper edge of a writing grip, degrees. A writing grip holds it about 45
    /// to 60 degrees up; only stood up past this does it steer the cue, so writing-style strokes never touch the angle.
    private static let writingGrip = 60.0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .simultaneousGesture(
                SpatialEventGesture()
                    .onChanged { events in track(events, ended: false) }
                    .onEnded { events in track(events, ended: true) }
            )
            .onAppear { installDoubleTapHook() }
            .onDisappear {
                bridge.table?.zoom.onDoubleTap = nil
                session.holdTask?.cancel(); session.holdTask = nil
                session.pendingTap?.cancel(); session.pendingTap = nil
            }
    }

    private func projector() -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
    }

    /// TableZoom tells this layer when its double tap is recognised, so the aim from before the first tap comes back
    /// and a tap still waiting does nothing. Set again at every touch-down, in case the table was rebuilt.
    private func installDoubleTapHook() {
        bridge.table?.zoom.onDoubleTap = { doubleTapRecognised() }
    }

    // MARK: Events

    private func track(_ events: SpatialEventCollection, ended: Bool) {
        for event in events {
            let active = event.phase == .active && !ended
            if active {
                if session.down.contains(event.id) {
                    moved(event)
                } else {
                    session.down.insert(event.id)
                    pressed(event)
                }
            } else if session.down.contains(event.id) {
                session.down.remove(event.id)
                lifted(event, cancelled: event.phase == .cancelled)
            }
        }
        // Every touch lifted (or the system cancelled them, which arrives as cancelled events): the sequence is over.
        if ended || session.down.isEmpty { sequenceEnded() }
    }

    /// A finger or the Pencil on the glass. A mouse or trackpad (and every press on the Mac) is a pointer.
    private static func isTouch(_ event: Event) -> Bool {
        #if os(iOS)
        return event.kind == .touch || event.kind == .pencil
        #else
        return false
        #endif
    }

    private func pressed(_ event: Event) {
        if session.owner == nil { startSequence(event) } else { anotherFinger(event) }
    }

    /// The first finger or the pointer is down: take the snapshot and wait (touch) or decide at once (pointer).
    private func startSequence(_ event: Event) {
        installDoubleTapHook()
        let touch = Self.isTouch(event)
        let input: PlayInput = touch ? .touch : .pointer
        if model.inputInUse != input { model.inputInUse = input }
        session.first = event
        session.firstNow = event
        session.isPointer = !touch
        session.strokeID = nil
        session.bridgeID = nil
        session.bridgeSpot = nil
        session.doubleTapsAtStart = session.doubleTaps
        // A press soon after a tap may be the second half of a double tap: keep the snapshot from before the first,
        // and drop the tap still waiting (it was the first half, or a tap the player has already moved on from).
        if let recent = session.recentTap, event.timestamp - recent.time <= TableTouch.doubleTapWindow,
           let earlier = recent.restoreAim {
            session.restoreAim = earlier
        } else {
            session.restoreAim = Self.restorer(for: model)
        }
        session.pendingTap?.cancel()
        session.pendingTap = nil
        if touch {
            session.owner = .undecided
            let id = event.id
            session.holdTask?.cancel()
            session.holdTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(TableTouch.holdDelay))
                guard !Task.isCancelled else { return }
                holdElapsed(id)
            }
        } else {
            commitPointer(event)
        }
    }

    /// A further finger while a sequence is on (touch only; a pointer has one press).
    private func anotherFinger(_ event: Event) {
        guard !session.isPointer, Self.isTouch(event), let firstNow = session.firstNow else { return }
        let proj = projector()
        let onBall = onCueBall(event.location, proj)
        switch session.owner {
        case .undecided?:
            session.holdTask?.cancel()
            let firstOnBall = onCueBall(session.first?.location ?? firstNow.location, proj)
            if onBall != firstOnBall, model.personControlsLive {
                // One of the two is on the cue ball: that one strokes, the other is the bridge, whichever came first.
                restore()
                if onBall {
                    commitStroke(event)
                    if session.owner == .stroke { setBridge(firstNow) }
                } else {
                    commitStroke(firstNow)
                    if session.owner == .stroke { setBridge(event) }
                }
            } else {
                // Two fingers off the ball (or both on it): a pinch or a pan. Nothing the first finger did stays.
                restore()
                session.owner = .zoom
            }
        case .aim?:
            if onBall, model.personControlsLive {
                // The aiming finger now rests as the bridge while this one strokes; the aim it set is kept.
                commitStroke(event)
                if session.owner == .stroke { setBridge(firstNow) }
            } else {
                // A second finger while aiming is a zoom: the first finger's aim is undone.
                restore()
                session.owner = .zoom
            }
        case .stroke?:
            // Any other finger on the cloth while stroking is the bridge hand.
            setBridge(event)
        case .zoom?, .placement?, .pull?, .liftOnMove?, .done?, nil:
            break
        }
    }

    private func moved(_ event: Event) {
        if event.id == session.strokeID { strokeMove(event); return }
        if event.id == session.bridgeID {
            // The bridge finger may settle while it rests: the bridge follows it.
            if let spot = projector()?.table(at: event.location) { session.bridgeSpot = spot; noteBridge() }
            return
        }
        guard event.id == session.first?.id, let start = session.first?.location else { return }
        session.firstNow = event
        let pastSlop = hypot(event.location.x - start.x, event.location.y - start.y) > TableTouch.slop
        switch session.owner {
        case .undecided?:
            if pastSlop { commitTouch(event, moved: true) }
        case .aim?:
            routes.aim(event.location)
        case .placement?:
            routes.carry(event.location)
        case .pull?:
            routes.pull(start, event.location)
        case .liftOnMove?:
            guard pastSlop else { return }
            liftOrAim(event)
        default:
            break
        }
    }

    private func lifted(_ event: Event, cancelled: Bool) {
        if event.id == session.strokeID { finish(cancelled: cancelled); return }
        if event.id == session.bridgeID {
            // Lifted: the stroke keeps the bridge it was set on (its spot stays until the sequence ends).
            session.bridgeID = nil
            return
        }
        guard event.id == session.first?.id, let start = session.first?.location else { return }
        session.holdTask?.cancel()
        let still = hypot(event.location.x - start.x, event.location.y - start.y) <= TableTouch.slop
        switch session.owner {
        case .undecided?:
            // Lifted before anything decided it, with no second finger: a tap, once the double-tap window passes.
            session.owner = .done
            if !cancelled { scheduleTap(at: event.location, time: event.timestamp) }
        case .aim?:
            // A click that did not move, or a finger that rested and lifted without moving: a tap on that spot.
            if still, !cancelled {
                if session.isPointer { tapNow(at: event.location, time: event.timestamp) }
                else { scheduleTap(at: event.location, time: event.timestamp) }
            }
            routes.release()
            session.owner = .done
        case .liftOnMove?:
            // A click on a ball that did not move: aim at the ball, as a tap does.
            if !cancelled { tapNow(at: event.location, time: event.timestamp) }
            session.owner = .done
        case .placement?:
            // Letting go puts the ball down; on an illegal spot the model keeps it lifted (and tinted).
            if !cancelled { routes.release() }
            session.owner = .done
        case .pull?:
            routes.release()
            session.owner = .done
        case .zoom?, .stroke?, .done?, nil:
            break
        }
    }

    /// Every touch lifted: ready for the next sequence.
    private func sequenceEnded() {
        session.holdTask?.cancel()
        session.holdTask = nil
        if session.isTracking { finish(cancelled: false) }
        session.owner = nil
        session.first = nil
        session.firstNow = nil
        session.down.removeAll()
        session.strokeID = nil
        session.bridgeID = nil
        session.bridgeSpot = nil
        bridge.table?.zoom.strokeHold = false
    }

    /// The undecided finger rested, alone, for the hold delay: commit it where it is.
    private func holdElapsed(_ id: StrokeSession.EventID) {
        guard session.owner == .undecided, session.first?.id == id, let now = session.firstNow else { return }
        commitTouch(now, moved: false)
    }

    // MARK: Deciding

    /// The first finger commits (it moved past the slop, or rested): by where it started.
    private func commitTouch(_ event: Event, moved: Bool) {
        session.holdTask?.cancel()
        guard let start = session.first?.location else { return }
        // On the computer's turn or while a stroke is solving, the cloth does nothing (zoom still works).
        guard model.personControlsLive else { session.owner = .done; return }
        // A pinch or pan already under way owns the fingers.
        if bridge.table?.zoom.isGesturing == true { restore(); session.owner = .zoom; return }
        // A ball already lifted: any drag carries it (the aim is not drawn while a ball is lifted).
        if model.placingCueBall {
            session.owner = .placement
            if moved { routes.carry(event.location) }
            return
        }
        let proj = projector()
        if onCueBall(start, proj) { commitStroke(event); return }
        if let ball = liftable(at: start, proj) {
            model.beginPlacingBall(ball)
            if model.placingCueBall {
                session.owner = .placement
                if moved { routes.carry(event.location) }
                return
            }
        }
        // Aim. A one-finger drag while the last shot still plays takes over: jump to where the balls came to rest
        // (only a committed drag; a pinch was decided before it got here, so it never skips the replay).
        if !model.aimReady { model.skipToResult() }
        session.owner = .aim
        if moved { routes.aim(event.location) }
    }

    /// A mouse or trackpad press decides at once: a click sets the aim where it lands (the pointer rule).
    private func commitPointer(_ event: Event) {
        guard model.personControlsLive else { session.owner = .done; return }
        if model.placingCueBall {
            session.owner = .placement
            routes.carry(event.location)
            return
        }
        // A click while the last shot still plays: to where the balls came to rest, then as usual.
        if !model.aimReady { model.skipToResult() }
        let proj = projector()
        if onCueBall(event.location, proj) {
            // The pull: the overlay sets the power as it is dragged, PointerAim plays it on release behind the ball.
            if let reason = model.strokeRefusal { model.refuse(reason); session.owner = .done }
            else { session.owner = .pull }
            return
        }
        if liftable(at: event.location, proj) != nil { session.owner = .liftOnMove; return }
        session.owner = .aim
        routes.aim(event.location)
    }

    /// A pointer pressed on a liftable ball has moved: lift it and carry it, or aim if it could not be lifted.
    private func liftOrAim(_ event: Event) {
        guard let start = session.first?.location else { return }
        if let ball = liftable(at: start, projector()) { model.beginPlacingBall(ball) }
        if model.placingCueBall {
            session.owner = .placement
            routes.carry(event.location)
        } else {
            session.owner = .aim
            routes.aim(event.location)
        }
    }

    /// The stroke may start on this finger unless the model refuses one now; a refusal is recorded (the card says
    /// why) and the touch does nothing else.
    private func commitStroke(_ event: Event) {
        if let reason = model.strokeRefusal {
            model.refuse(reason)
            session.owner = .done
            return
        }
        session.owner = beginStroke(event) ? .stroke : .done
    }

    /// True when a screen point is inside the cue ball's grab circle.
    private func onCueBall(_ point: CGPoint, _ proj: AimProjector?) -> Bool {
        guard let proj, model.layout.count == 16, NextShot.isOnTable(model.aimOrigin),
              let ball = proj.screen(model.aimOrigin) else { return false }
        let radius = TableTouch.grabRadius(proj, centre: model.aimOrigin, ballRadius: model.timeline.table.ballRadius)
        return hypot(ball.x - point.x, ball.y - point.y) <= radius
    }

    /// The ball a touch at this point may lift (model.liftableBall: any ball in free play, the striking ball with ball
    /// in hand in a match), within the ball's radius plus a fingertip's slack (the grab floor, in table metres here).
    /// Not the striking ball (it is grabbed for the stroke) and not on a racked table (a drag over the rack aims the
    /// break; the balls there are not arranged).
    private func liftable(at point: CGPoint, _ proj: AimProjector?) -> Int? {
        guard let proj, !model.racked, let spot = proj.table(at: point) else { return nil }
        let r = model.timeline.table.ballRadius
        var slack = r
        if let a = proj.screen(spot), let b = proj.screen(spot + Vec2(r, 0)) {
            let pointsPerRadius = hypot(a.x - b.x, a.y - b.y)
            if pointsPerRadius > 0.1 { slack = Double(TableTouch.grabFloor / pointsPerRadius) * r }
        }
        guard let ball = model.liftableBall(near: spot, within: r + slack), ball != model.strikeBall else { return nil }
        return ball
    }

    // MARK: Taps and the double tap

    /// A tap waits out the double-tap window, then acts unless a double tap was recognised meanwhile.
    private func scheduleTap(at point: CGPoint, time: Double) {
        let doubleTapsAtStart = session.doubleTapsAtStart
        session.recentTap = (time, ProcessInfo.processInfo.systemUptime, session.restoreAim)
        session.pendingTap?.cancel()
        session.pendingTap = Task { @MainActor in
            try? await Task.sleep(for: .seconds(TableTouch.doubleTapWindow))
            guard !Task.isCancelled, session.doubleTaps == doubleTapsAtStart else { return }
            session.pendingTap = nil
            performTap(at: point)
        }
    }

    /// A pointer's click acts at once (a click is the pointer's commitment); a double click puts the aim back.
    private func tapNow(at point: CGPoint, time: Double) {
        session.recentTap = (time, ProcessInfo.processInfo.systemUptime, session.restoreAim)
        performTap(at: point)
    }

    /// A tap: while the shot on screen still plays, skip to where the balls came to rest; with the balls at rest, aim
    /// through the spot (the overlay snaps to a ball or a pocket under it).
    private func performTap(at point: CGPoint) {
        guard model.personControlsLive else { return }
        if !model.aimReady { model.skipToResult(); return }
        routes.tap(point)
    }

    /// TableZoom recognised a double tap: it zooms; here the aim and power from before its first tap come back and any
    /// tap still waiting is dropped.
    private func doubleTapRecognised() {
        session.doubleTaps += 1
        session.pendingTap?.cancel()
        session.pendingTap = nil
        // The first half of this double tap was a tap moments ago; an older tap is not part of it (allow the window
        // twice over, for the second tap's own press and lift).
        if let recent = session.recentTap,
           ProcessInfo.processInfo.systemUptime - recent.uptime <= 2 * TableTouch.doubleTapWindow,
           let earlier = recent.restoreAim {
            earlier()
        } else {
            session.restoreAim?()
        }
    }

    /// Put the aim and power back as they were at touch-down.
    private func restore() {
        session.restoreAim?()
    }

    /// The model's aim and power now, as a closure that puts them back (model.aimSnapshot() and restoreAim(_:)). The
    /// snapshot's type is the model's; holding it inside a closure keeps this file to the two calls the contract names.
    private static func restorer(for model: ShowpieceModel) -> @MainActor () -> Void {
        let snapshot = model.aimSnapshot()
        return { model.restoreAim(snapshot) }
    }

    // MARK: The stroke

    /// A touch on the cue ball starts a stroke. False when the groove cannot be laid (no camera yet, a pinch under way).
    private func beginStroke(_ event: Event) -> Bool {
        guard model.layout.count == 16, bridge.table?.zoom.isGesturing != true,
              let proj = projector(), let ball = proj.screen(model.aimOrigin) else { return false }
        // The groove's directions on screen: back along the cue (away from the ball) and the shooter's right.
        let dir = model.aimDirection
        guard let behind = proj.screen(model.aimOrigin - dir * 0.3),
              let rightward = proj.screen(model.aimOrigin + Vec2(dir.y, -dir.x) * 0.3) else { return false }
        let b = CGVector(dx: behind.x - ball.x, dy: behind.y - ball.y)
        let bl = hypot(b.dx, b.dy)
        guard bl > 1 else { return false }
        let back = CGVector(dx: b.dx / bl, dy: b.dy / bl)
        // Right, made square to the groove on screen (the camera's perspective can skew the table's own right angle).
        var r = CGVector(dx: rightward.x - ball.x, dy: rightward.y - ball.y)
        let along = r.dx * back.dx + r.dy * back.dy
        r = CGVector(dx: r.dx - along * back.dx, dy: r.dy - along * back.dy)
        let rl = hypot(r.dx, r.dy)
        guard rl > 1e-3 else { return false }
        session.strokeID = event.id
        session.tracker = StrokeTracker()
        // A new stroke starts on the automatic bridge until a finger rests on the cloth.
        session.bridgeID = nil
        session.bridgeSpot = nil
        model.strokeBridge = nil
        session.origin = event.location
        session.back = back
        session.right = CGVector(dx: r.dx / rl, dy: r.dy / rl)
        session.screenTrace = [event.location]
        session.grooveLength = bl / 0.3 * CGFloat(StrokeTracker.fullPull)
        session.sinceTick = 0
        session.pulled = false
        session.pencilSteering = false
        bridge.table?.zoom.strokeHold = true
        strokeMove(event)
        return true
    }

    private func strokeMove(_ event: Event) {
        guard var tracker = session.tracker, let proj = projector() else { return }
        let p = event.location
        let dx = p.x - session.origin.x, dy = p.y - session.origin.y
        let along = Double(dx * session.back.dx + dy * session.back.dy)
        let across = Double(dx * session.right.dx + dy * session.right.dy)
        let spot = proj.table(at: p)
        // How far behind the cue ball the finger is, along the aim line, on the table: the pull-back's own measure.
        let depth = spot.map { (model.aimOrigin - $0).dot(model.aimDirection) } ?? (tracker.samples.last?.depth ?? 0)
        let before = tracker.samples.last
        tracker.add(.init(time: event.timestamp, depth: depth, along: along, across: across, spot: spot))
        session.tracker = tracker
        session.screenTrace.append(p)
        pencil(event)
        // A push through the ball with no backswing drawn first plays nothing; the card says why.
        if tracker.tooShortPush {
            model.refuse(.backswingTooShort)
            endStroke()
            session.owner = .done
            return
        }
        // Below the slop it is a tap on the ball and leaves the power as it was, as the overlay's pull always has.
        guard session.pulled || hypot(dx, dy) > TableTouch.slop else { return }
        session.pulled = true
        // A lesson step with the power locked, or not about power, keeps its set power: the stroke is still measured
        // (for its drift), but the depth does not move the bar.
        if TableTouch.pullSetsPower(model) {
            model.powerFraction = StrokeTracker.powerFraction(forDepth: tracker.powerDepth)
        }
        model.pendingStroke = tracker.record(power: model.activePower, bridge: bridgeLength())
        feel(previous: before, tracker: tracker)
        if tracker.delivered { deliver() }
    }

    /// The stroke has gone through the cue ball after a real backswing: play it, unless the player shoots with the
    /// button only (then the push has set the power and Shoot plays). The click comes only once the model has
    /// accepted the strike; a refusal is recorded by the model (fireStroke) and the card says why.
    private func deliver() {
        endStroke()
        session.owner = .done
        guard !buttonOnly else { return }
        switch model.fireStroke() {
        case .refused:
            break
        case .breakStruck:
            Haptics.shared.strokeContact()
            hintSeen = true
            // The break hands the screen to its slow-motion opening, so the panel closes, as with the Break button.
            isOpen = false
        case .shotStruck:
            Haptics.shared.strokeContact()
            hintSeen = true
        }
    }

    /// The stroke finger lifted (or the system took the touch) without a push: the power is set from where the finger
    /// is now, not from the furthest point of the backswing, and the stroke so far stays the pending one.
    private func finish(cancelled: Bool) {
        if cancelled {
            model.pendingStroke = nil
        } else if let tracker = session.tracker, session.pulled, !tracker.delivered, let depth = tracker.fingerDepth {
            if TableTouch.pullSetsPower(model) { model.powerFraction = StrokeTracker.powerFraction(forDepth: depth) }
            model.pendingStroke = tracker.record(power: model.activePower, bridge: bridgeLength())
        }
        endStroke()
        session.owner = .done
    }

    private func endStroke() {
        session.tracker = nil
        session.strokeID = nil
        session.screenTrace = []
        session.pulled = false
        // The pinch stays held while a bridge finger still rests: lifting the stroke finger must not turn it into a pan.
        bridge.table?.zoom.strokeHold = session.bridgeID != nil
    }

    // MARK: Bridge hand

    private func setBridge(_ event: Event) {
        session.bridgeID = event.id
        session.bridgeSpot = projector()?.table(at: event.location)
        noteBridge()
    }

    /// The bridge finger's distance to the cue ball, metres, clamped; nil with no bridge finger.
    private func bridgeLength() -> Double? {
        guard let spot = session.bridgeSpot else { return nil }
        return StrokeModel.bridgeLength(finger: (spot - model.aimOrigin).length, mechanical: false)
    }

    /// Tell the model the bridge now, so the power bar's calm zone moves while the finger rests.
    private func noteBridge() {
        model.strokeBridge = bridgeLength()
        if let tracker = session.tracker {
            model.pendingStroke = tracker.record(power: model.activePower, bridge: bridgeLength())
        }
    }

    // MARK: Feel

    /// A faint tick each fingertip's width of travel along the groove: soft and dull on the groove, crisper and
    /// stronger as the finger strays off it (roughness 1 at three groove half-widths off).
    private func feel(previous: StrokeTracker.Sample?, tracker: StrokeTracker) {
        guard let last = tracker.samples.last, let prev = previous else { return }
        session.sinceTick += CGFloat(abs(last.along - prev.along))
        guard session.sinceTick >= Self.tickSpacing else { return }
        session.sinceTick = 0
        let halfWidth = max(3, StrokeModel.steadyWander * max(tracker.strokeLength, StrokeTracker.shortestStroke))
        let roughness = min(1, max(0, (abs(last.across) - halfWidth) / (2 * halfWidth)))
        Haptics.shared.strokeTexture(roughness: roughness)
    }

    // MARK: Pencil

    /// The Pencil's altitude while stroking sets the cue's angle, through model.activeElevation (which refuses while a
    /// lesson has locked the angle). At a writing grip (up to 60 degrees off the glass) it changes nothing, so the
    /// menu's angle stands. Stood up past the grip it takes over for the rest of the stroke: the 30 degrees from the
    /// grip to upright span the cue-angle menu's whole range, level to 80 degrees (about 2.7 degrees of cue per degree
    /// of Pencil), snapped to the menu's angles so its menu reads what the Pencil set. It takes over only once its
    /// angle reaches the menu's first raised step, so a grip that wobbles just past the line never flattens the cue.
    private func pencil(_ event: Event) {
        #if os(iOS)
        guard event.kind == .pencil, let pose = event.inputDevicePose, raisedCueOpen else { return }
        let altitude = pose.altitude.degrees
        let top = Double(CueAngleMenu.angles.last ?? 80)
        let raise = min(top, max(0, (altitude - Self.writingGrip) * top / (90 - Self.writingGrip)))
        let snapped = CueAngleMenu.angles.min { abs(Double($0) - raise) < abs(Double($1) - raise) } ?? 0
        if !session.pencilSteering {
            guard altitude > Self.writingGrip, snapped > 0 else { return }
            session.pencilSteering = true
        }
        let sine = CueAngleMenu.sine(forAngle: snapped)
        if model.activeElevation != sine { model.activeElevation = sine }
        #endif
    }

    /// Trick shots and Behind the 8-Ball situations set their own cue angle; a break is always struck level. Everything
    /// else (free play, matches, a lesson step that opens the angle) is the model's lock to decide.
    private var raisedCueOpen: Bool {
        !model.racked && !model.trickMode.isActive && !model.eightBallMode.isActive
    }
}

// MARK: Drawing

@MainActor
enum StrokeDrawing {
    /// The groove and the finger's trace, while a stroke is on. Called from the aiming layer's Canvas.
    static func draw(_ ctx: inout GraphicsContext, session: StrokeSession, paper: Color, accent: Color) {
        guard let tracker = session.tracker else { return }
        let o = session.origin, b = session.back, r = session.right
        // From a little ahead of the touch (toward the ball, the forward stroke's path) to a full pull behind it: the
        // pull's depth sets the power over the whole half metre, so the groove shows all of it. The bridge mark is
        // drawn beside the groove (AimOverlay), so nothing here runs over the bridge hand.
        let ahead: CGFloat = 40
        let length = session.grooveLength
        let half = max(3, CGFloat(StrokeModel.steadyWander * max(tracker.strokeLength, StrokeTracker.shortestStroke)))
        func at(_ s: CGFloat, _ t: CGFloat) -> CGPoint {
            CGPoint(x: o.x + b.dx * s + r.dx * t, y: o.y + b.dy * s + r.dy * t)
        }
        var band = Path()
        band.move(to: at(-ahead, -half))
        band.addLine(to: at(length, -half))
        band.addLine(to: at(length, half))
        band.addLine(to: at(-ahead, half))
        band.closeSubpath()
        ctx.fill(band, with: .color(paper.opacity(0.10)))
        var centre = Path()
        centre.move(to: at(-ahead, 0)); centre.addLine(to: at(length, 0))
        ctx.stroke(centre, with: .color(paper.opacity(0.22)), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
        guard session.screenTrace.count > 1 else { return }
        var trace = Path()
        trace.addLines(session.screenTrace)
        ctx.stroke(trace, with: .color(accent.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}
