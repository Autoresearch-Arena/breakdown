// Author: Claude Sonnet 5.5 High
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: SceneBridge.viewMeasured, so drawing layers
//          use the 3D view's frame only once it has been measured.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door: StageChrome.tableAcross, passed into the
//          request as liesAcross, lays the table across the band above the upright phone's menu sheet.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: each
//          frame hands the scene the freeze's cue, model.bulletTime.cue, beside the held Lens event.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream camera: each frame hands the scene the moment framing's
//          request (MomentFrame.allowed and the pace plan) in place of the retired signature close-up's step, and the
//          scene is loaded with the struck ball so the Ride camera follows it (bug #21).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts item 10, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md:
//          StageChrome.hasHeader. Where the table has no title row (the open Duo's table half, beside the notebook) the
//          camera keeps only the safe area at the top, not a phantom 40-point row, so the table is a little larger.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 foundation: hooks for signature beats, the held Lens beat, the shared computer level and the highlight offer; plans/22-Nov-2026-v074-glow-up-plan.md)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.1: the opening's lamp shot is switched off; it looked broken.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (review fix: the aim preview and 3D cue start from the striker).
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 coordinator: wires the Ride hand-over in).
// Edited: Claude Opus 5.5 High, 20-November-2026 (no caption slot any more: captions float over the table's top edge
//          and cost it nothing, so StageChrome and the camera request no longer carry a caption edge).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the bridge on the 3D cue now follows model.showsBridge and
//          model.strokeUsesBridge, which cover trick shots and Behind the 8-Ball alike).
// PURPOSE: Hosts the 3D table inside SwiftUI. Builds the TableScene once, runs the per-frame step (advance the
//          model's clock, place everything for that time, aim the camera, and project the caption's ball to the
//          screen for the leader ring), and reloads the Lens when a new shot is recorded. Anything that changes
//          while the scene runs (the free space the screen measured, whether the aim line shows, the view's size) is
//          passed through SceneBridge, a plain reference object, because the per-frame closure is created once and
//          would otherwise keep reading stale copies. Does not draw the table: TableScene and its files do that.
//          Package 4 (0.4.0): the screen now hands over StageChrome, the real laid-out edges of the title row, the caption
//          slot and the control strip plus the safe areas, all in StageSpace; this file turns them into the 3D view's
//          own coordinates (a FramingRequest) every frame, so the camera frames the table in exactly the space that is
//          left, in portrait, landscape, on iPad and on the Mac. Before, a guessed fraction of the height was passed.
//          Edited: Claude Opus 5.5 High, 20-November-2026 (one line: the camera update also passes whether Ride is on).
// Edited: Claude Opus 5.5 High, 21-November-2026 (playing surfaces: the scene is built on the surface the shot is
//          solved on, and each update hands it over so the bed changes with it).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the 3D cue: the aim preview also carries power, elevation, tip
//          offsets, the bridge and whether the cue may show (the old flat cue's rule: the shot has played out and the cue
//          ball is on the table); each frame also hands the scene the CueStroke of the shot on screen and whether Ride
//          is on, for the follow-through).
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: the scene is built and reloaded with the table kind the
//          shot was solved on, so it redraws the table when that changes).
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan, two hooks: the table takes the pinch, two-finger pan and
//          double tap of TableZoomGestures; each frame the caption leader is told where the title row ends, so its
//          on-table label keeps clear of the top controls in the Lens.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, packages 1, 3 and 5: the 3D picture is no longer
//          one silent "Pool table" element. TableAccessLayer lays an element over every ball and pocket where it really
//          is, plus a table element with "Step through the shot"; it steps aside while the shot panel is open, when
//          the aiming layer carries the same elements. Each frame the update also reads a game controller
//          (GameControllerInput) and lets ShotNarration speak a finished shot (and a match ruling) once; the bridge
//          carries whether a screen reader is on and what has been said, so nothing here reads the clock in a body.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 23 and 34: the 3D cue is drawn at the angle the strike
//          will really use (model.strikeElevation, which clears any ball under the cue) and on the mechanical rest
//          whenever it is in use (model.restInUse, in every mode); the follow-through uses the recorded shot's angle and
//          whether it was struck off the rest; the bridge mark is handed to the scene as a ring on the cloth (BridgeMark),
//          left out while the rest stands there; and the showpiece opening's lamp shot is cued every frame before the
//          clock moves, with the clock held until the camera has risen to the table.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment hook, plan items 10, 23 and 57: the aim preview
//          carries the cue the game picked, model.cueChoice.kind, so CueRig draws that cue, and the bridge's length, so
//          the drawn pull-back stops in front of the bridge hand; its elevation is model.strikeElevation and its rest
//          flag model.restInUse, as docs/v07-contracts.md 2.5 says.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: stroke(of:modeUsesBridge:)
//          is split out of stroke(for:), so a clip draws the same cue follow-through from a kept attempt. Unchanged.)
// SRP/DRY check: Pass - split out of ShowpieceView; the scene hand-off code is unchanged from before the glow-up,
//          only the inputs now come from the bridge instead of the view's own state.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import RealityKit
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// What the screen measured of itself, in StageSpace (points, origin at the stage's top-left inside the safe area).
/// ShowpieceView fills this from the real laid-out views; the camera never sees a guessed margin.
struct StageChrome: Equatable {
    /// Safe-area insets of the region the 3D view fills (the side column's side has none).
    var safe = FramingInsets()
    /// Bottom edge of the title row.
    var headerBottom: Double?
    /// Top edge of the control strip; nil where the controls live in the side column.
    var controlsTop: Double?
    /// False where the stage has no title row at all (the open Duo's table half, the table beside the notebook): an
    /// unmeasured headerBottom then means "nothing there", not "a row not measured yet" (0.7.5 layouts item 10).
    var hasHeader = true
    /// 0.7.10 frontdoor: lay the table across even in a tall view (the upright phone's main menu; see
    /// FramingRequest.liesAcross).
    var tableAcross = false
}

/// Values the per-frame closure needs that change after the scene is built.
@MainActor
final class SceneBridge {
    var table: TableScene?
    /// Show the guide line from the cue ball while the shot panel is open.
    var showAim = false
    /// Show the 3D cue (and bridge) at the aim while the shot panel is open, even though the Lens aim line is off.
    var showCue = false
    /// The measured title and control edges, for the camera.
    var chrome = StageChrome()
    /// The size of the 3D view itself, which the camera frames the table to.
    var viewSize = CGSize(width: 800, height: 600)
    /// True once the 3D view's frame has been measured (viewSize and viewOrigin are real, not the defaults).
    var viewMeasured = false
    /// Where the 3D view's top-left corner sits in StageSpace (negative when it extends under the safe areas).
    var viewOrigin = CGPoint.zero
    /// VoiceOver is running, so a finished shot is spoken (ShotNarration.frame). Set from the view's environment.
    var speaks = false
    /// The recording (model.timelineVersion) whose summary has been spoken, so each shot is said once.
    var narratedVersion = -1
    /// "Ana to break" has been said for the match on the table.
    var matchStartSpoken = false
    /// The system's Differentiate Without Colour setting, for the bridge ring (an awkward stance gets an inner ring).
    var differentiateWithoutColour = false

    /// The free-space request for the camera, in the 3D view's own coordinates. A title row not measured yet (the first
    /// frame) falls back to the safe area plus a typical row, which is replaced as soon as the real one arrives; with no
    /// title row at all the top edge is the safe area alone (chrome.hasHeader false).
    func request() -> FramingRequest {
        let oy = Double(viewOrigin.y)
        let header = chrome.headerBottom.map { $0 - oy } ?? (chrome.safe.top + (chrome.hasHeader ? 40 : 0))
        let q = FramingRequest(size: viewSize, safe: chrome.safe, headerBottom: header,
                               controlsTop: chrome.controlsTop.map { $0 - oy },
                               liesAcross: chrome.tableAcross)  // 0.7.10 frontdoor
        // Test hook: launch with -frameDebug to print the measured request whenever it changes.
        if Self.frameDebug, q != lastLogged { lastLogged = q; NSLog("FRAMING %@ origin=%@", String(describing: q), String(describing: viewOrigin)) }
        return q
    }
    private static let frameDebug = ProcessInfo.processInfo.arguments.contains("-frameDebug")
    private var lastLogged: FramingRequest?
}

struct TableStage: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    let leader: LeaderState
    let showAim: Bool
    /// True while "Your shot" is open: the 3D cue lies at the aim.
    var showCue = false
    let chrome: StageChrome

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        RealityView { content in
            #if os(iOS)
            content.camera = .virtual
            #endif
            let table = TableScene(timeline: model.timeline, surface: model.physicsSurface, table: model.solvedTable)
            content.add(table.root)
            bridge.table = table
            table.load(model.timeline, version: model.timelineVersion, kind: model.solvedTable,
                       cueBall: model.ridePlan.cueBall)
            // Reflections: lights the glossy parts from a generated lamp picture.
            await table.installEnvironment()
            // A copy of the content that the per-frame closure may keep: it is only used to project points to the screen.
            let projector = content
            table.subscriptions.append(content.subscribe(to: SceneEvents.Update.self) { event in
                MainActor.assumeIsolated {
                    // A game controller's sticks and triggers move the aim, power and tip before the frame is drawn.
                    GameControllerInput.shared.step(event.deltaTime, model: model)
                    // The showpiece opening starts with the camera low under the lamp (TableCamera's lamp shot); the
                    // clock waits until it has risen to the table, so the break is watched from the table view.
                    table.cueIntro(Self.showpieceStarting(model))
                    model.advance(table.introHolding ? 0 : event.deltaTime)
                    // Speak a shot that has just played out (only with VoiceOver on; once per recording).
                    ShotNarration.frame(model: model, bridge: bridge)
                    let preview: AimPreview? = (bridge.showAim || bridge.showCue) ? Self.aim(for: model) : nil
                    let aim = bridge.showAim ? preview : nil
                    let cueAim = bridge.showCue ? preview : nil
                    table.lensHeldEvent = model.heldCaption?.id
                    // 0.7.7 bullet-time: before apply, which reads it for the glassy balls.
                    table.bulletCue = model.bulletTime.cue
                    table.apply(time: model.time, melt: model.melt, rate: model.displayRate, aim: aim, cueAim: cueAim,
                                stroke: Self.stroke(for: model), ride: model.rideActive,
                                bridgeMark: cueAim.flatMap { Self.bridgeMark(for: model, cue: $0, bridge: bridge) })
                    // The moment framing of a guided Lens replay (MomentFrame): the camera glides in on each beat.
                    table.moment = MomentRequest(allowed: MomentFrame.allowed(for: model), plan: model.pacePlan)
                    table.rideCue = model.rideCue
                    table.updateCamera(melt: model.melt, request: bridge.request(), ride: model.rideActive)
                    // The camera has just moved, so project after it: the ring must sit on this frame's ball.
                    // Project into the 3D view's own space, then shift by where that view sits on the stage.
                    // (Projecting straight into the named space came back offset by twice the top safe-area inset in
                    // the iOS 27.2 simulator, so the shift is done here, where it can be checked.)
                    // The caption chip keeps below the title row (look plan package 5: Lens labels clear of the top controls).
                    let top = CGFloat(bridge.chrome.headerBottom ?? 0)
                    if leader.topClear != top { leader.topClear = top }
                    leader.refresh(model: model) { world in
                        guard let local = projector.project(point: world, to: .local) else { return nil }
                        return CGPoint(x: local.x + bridge.viewOrigin.x, y: local.y + bridge.viewOrigin.y)
                    }
                }
            })
        } update: { _ in
            if let table = bridge.table, model.timelineVersion >= 0 {
                table.load(model.timeline, version: model.timelineVersion, kind: model.solvedTable,
                           cueBall: model.ridePlan.cueBall)
            }
            // The bed shows the surface the shot is actually solved on: the chosen one, or cloth while a trick shot is
            // up (trick shots are always played on cloth). Reading it here makes the view update when it changes.
            bridge.table?.setSurface(model.physicsSurface)
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: {
            bridge.viewSize = $0.size
            bridge.viewOrigin = $0.origin
            bridge.viewMeasured = true
        }
        // Pinch to zoom, two fingers to pan, double tap a ball to centre on it (see TableZoom).
        .modifier(TableZoomGestures(model: model, bridge: bridge))
        #if os(iOS)
        // Test hook: -forceLandscape turns the app sideways at launch so landscape can be checked on a simulator that
        // has no rotate command here. No effect without the flag.
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-forceLandscape"),
                  let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
        #endif
        .onChange(of: showAim, initial: true) { _, new in bridge.showAim = new }
        .onChange(of: showCue, initial: true) { _, new in bridge.showCue = new }
        .onChange(of: chrome, initial: true) { _, new in bridge.chrome = new }
        // Also here, so a surface change reaches the scene even if the update closure above is not re-run for it.
        .onChange(of: model.physicsSurface) { _, new in bridge.table?.setSurface(new) }
        .ignoresSafeArea()
        // The rendered picture itself says nothing; the layer laid over it (same frame, so its projection lines up)
        // names every ball and pocket where it is on screen and carries the table's own element. While the shot panel
        // is open the aiming layer carries those elements instead (with double-tap to aim), so this copy is hidden.
        .accessibilityHidden(true)
        .overlay {
            TableAccessLayer(model: model, bridge: bridge)
                .accessibilityHidden(showCue)
        }
        .onChange(of: voiceOver, initial: true) { _, on in bridge.speaks = on }
        .onChange(of: differentiateWithoutColor, initial: true) { _, on in bridge.differentiateWithoutColour = on }
        .onAppear { GameControllerInput.shared.start(model: model) }
    }

    static func aim(for model: ShowpieceModel) -> AimPreview {
        var preview: AimPreview
        // After the first shot the guide line follows the aim slider from the cue ball's resting spot.
        if !model.racked, model.layout.count == 16 {
            // From the ball this player strikes (model.aimOrigin): ball 0 in pool, a player's own ball in five-pin and
            // bumper pool.
            preview = AimPreview(from: model.aimOrigin, direction: model.shotAimDirection, length: 1.4, always: true)
        } else {
            let positions = Rack.positions(parameters: PoolParameters(), seed: UInt64(10 + model.breakSerial + 1))
            let target = positions[1] + Vec2(0, model.aimOffset)
            let dir = (target - positions[0]).normalized
            preview = AimPreview(from: positions[0], direction: dir, length: 1.2, always: true)
        }
        // The 3D cue: shown on the same rule the old flat cue used (the balls on screen are the ones the next shot
        // starts from, and the cue ball is on the table); the aim line itself keeps showing either way.
        preview.showsCue = model.aimReady && model.layout.count == 16 && NextShot.isOnTable(model.aimOrigin)
        // The cue the game picked for this shot is the one drawn, its pull-back stopped short of the bridge hand
        // (plan items 57 and 23; equipment's hook).
        preview.cue = model.cueChoice.kind
        preview.bridgeLength = model.strokeBridgeLength
        preview.powerFraction = model.powerFraction
        // The angle the strike will use: the player's, raised to clear any ball under the whole cue (0 for a break).
        preview.elevation = model.strikeElevation
        preview.tipUp = model.activeTipUp
        preview.tipSide = model.activeTipSide
        // The mechanical rest whenever the shot needs it or the stance is Rest, in every mode.
        preview.usesBridge = model.restInUse
        return preview
    }

    /// True while the showpiece opening is at its start: the first launch's opening or Watch the intro (no shot of the
    /// player's on screen), in its lead-in or its break, with the menu closed. A player's own break goes through the
    /// same stages but carries its attempt, so it never gets the lamp shot.
    /// 0.7.1: the lamp shot is off. On screen it was a flat shade filling the view over a dark void, so the intro opens
    /// on the table again.
    static func showpieceStarting(_ model: ShowpieceModel) -> Bool { false }

    /// The bridge mark for the cue now shown at the aim: the bridge hand's spot, model.strokeBridgeLength behind the
    /// cue ball along the cue, while the cue may show and the mechanical rest is not standing there itself.
    static func bridgeMark(for model: ShowpieceModel, cue: AimPreview, bridge: SceneBridge) -> BridgeMark? {
        guard cue.showsCue, !cue.usesBridge, cue.direction.lengthSquared > 0.5 else { return nil }
        let back = cue.direction.normalized
        let r = model.timeline.table.ballRadius
        return BridgeMark(spot: cue.from - back * model.strokeBridgeLength, ballBack: cue.from - back * r,
                          awkward: model.stance.map { !$0.isNormal } ?? false,
                          innerRing: bridge.differentiateWithoutColour)
    }

    /// How the shot on screen was struck, for the cue's follow-through. The player's shots and breaks are recorded as
    /// attempts with their exact tip offsets and the cue angle the strike used; the cue rested on the mechanical bridge
    /// when the shot needs it (trick shots, situations) or the stance recorded with the stroke was the rest.
    /// The opening showpiece break has no attempt: a level cue through the centre.
    static func stroke(for model: ShowpieceModel) -> CueStroke {
        stroke(of: model.currentAttempt, modeUsesBridge: model.strokeUsesBridge)
    }

    // 0.7.7 clips: the same follow-through from any attempt (the body stroke(for:) used to hold), so a clip of a kept
    // shot (the rack's best, a what-if's other future) draws the cue exactly as the game did. `modeUsesBridge` is the
    // model's strokeUsesBridge when the shot is the one on screen, false for a shot kept from free play.
    nonisolated static func stroke(of shot: ShotAttempt?, modeUsesBridge: Bool) -> CueStroke {
        guard let shot else { return CueStroke() }
        if shot.isBreak { return CueStroke(tipUp: shot.tipUp, tipSide: shot.tipSide) }
        let onRest = modeUsesBridge || shot.stroke?.stance?.rung == .rest
        return CueStroke(tipUp: shot.tipUp, tipSide: shot.tipSide, elevation: shot.elevation, usesBridge: onRest)
    }
}
