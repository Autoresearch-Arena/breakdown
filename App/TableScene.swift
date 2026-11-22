// Author: Claude Sonnet 5.5 High
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 foundation: hooks for signature beats, the held Lens beat, the shared computer level and the highlight offer; plans/22-Nov-2026-v074-glow-up-plan.md)
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (the Lens colour legend is a glass chip in the title row now, so it
//          no longer hangs off the camera).
// PURPOSE: The thin coordinator of the 3D scene. Owns the root entity and the shared state (current timeline and
//          table frame, the ball entities), wires the three jobs together, and runs the per-frame apply(): fade the
//          warm table out and the Lens in with the melt value, place every ball for the playback clock, then hand the
//          Lens layer and the camera what they need. RealityKit physics is not used: every transform comes from the
//          recorded timeline, so scrubbing in either direction is exact.
//          Layout (package 0 of the glow-up plan, 13-Nov-2026; behaviour unchanged from 0.2.2):
//            TableScene.swift   this file: root, shared state, load(), apply(), ball placement. Keep it short.
//            TableBuilder.swift the static warm table, rails, cushions, pockets, balls, lights, reflections.
//            LensLayer.swift    grid, trails, rings, arrows, aim line and their per-frame reveal.
//            TableCamera.swift  camera rig, framing and the melt swing.
//          Package 2 (13-Nov-2026) added: the Lens legend hangs off the camera's HUD anchor; test launch flags
//          -lensDebugTime <seconds> and -lensDebugMelt <0..1> pin the clock and melt for screenshots, and
//          -lensSelfTest runs the scrub-exactness check and prints the result.
//          Package 4 (13-Nov-2026): the camera now takes the measured free space (a FramingRequest) and the clock, so it can
//          frame between the title, caption slot and controls and push in on the break; nothing else here changed.
//          Edited: Claude Opus 5.5 High, 20-November-2026 (Ride the shot: owns the ShotCamera, loads it with each new
//          timeline and hands it to the camera with the clock and whether Ride is on; -rideSelfTest logs its check).
//          Edit the file for the job you are doing; do not add Lens or table detail back into this one.
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump shots: a ball is drawn at its recorded height above the cloth,
//          so a jumping cue ball leaves the table surface on screen; on the cloth the height is zero and nothing moves.
//          A ball that flew off the table keeps flying its last arc past the rail and then vanishes, instead of the
//          pocket's sink, which would pull it down through the rail.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (playing surfaces: the table is built in the chosen surface, and
//          setSurface swaps only the bed's material on the existing table when it changes, picture drawn in the background).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the 3D cue and bridge: owns a CueRig inside the table group, so it
//          fades with the table in the Lens, and hands it the aim, the CueStroke of the shot on screen, the clock and
//          whether Ride is on in apply()).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the cushions wear the bed's cloth on tournament cloth and dive-bar
//          felt, as a real table's do; every other surface keeps the standard cushion cloth).
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: load() takes the TableKind the shot was solved on and
//          rebuilds the warm table whenever the recorded table (size, pockets, posts, pins, bed holes) or the kind
//          changes, adding that kind's props (TableKind.makeProps) under the table group so they fade with it; the
//          Lens grid is redrawn for the new table and the balls are scaled to the new ball size. Each frame, a prop named
//          "pin-<k>" topples flat over 0.15 s from the moment the timeline says pin k went down, along the direction it
//          was pushed: a pure function of the clock, so scrubbing either way is exact.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan, wiring only: owns the hand zoom (TableZoom, sprung back
//          on every new shot and handed to the camera) and a TableDetail (ball contact shadows, the lamp shade's fade,
//          the small-ball pictures), fed each frame; a pocketed ball now slides into the middle of its own drawn hole
//          as it drops into the moulded cup, so it goes behind the lip instead of through the pocket's edge; balls are
//          drawn 8% larger in the Lens; the bed is redressed once the cloth's close-up normal map has been drawn; the
//          table is built with the scene root as its light source, for the models that load later.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (release stream: the -lensSelfTest check moved, unchanged, into
//          LensScrubCheck.run so the unit tests run the same check; this file now only logs its result.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 21, 23, 34 and 56, wiring only: the balls are dressed
//          in the table's own ball set (TableDetail.dress, from TableBallSet) when the scene is made and again whenever
//          the table kind changes; apply takes the bridge mark and hands it to TableDetail's ring; each ball's drawn
//          radius is passed on so its picture follows its own size on screen; and the opening's lamp shot is cued and
//          its hold read through cueIntro and introHolding (TableCamera).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream camera, wiring only: owns the moment framing's gate
//          (MomentFrame) and hands its answer to the camera each frame from the request TableStage sets (moment); the
//          Ride camera is loaded with the struck ball (bug #21); the hand zoom is told while Ride flies (rideHold, bug
//          #24); and the Lens is now drawn after the camera has moved, in updateCamera, so its drawings can read this
//          frame's on-screen scale (TableCamera.pointsPerMetre, through tableCamera).)
// SRP/DRY check: Pass - coordination only; it reads the model and timeline and never changes them.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import Foundation
import RealityKit
import simd

@MainActor
final class TableScene {
    let root = Entity()
    /// Holds the warm table group, so the table can be rebuilt for another table kind without changing child order.
    private let tableHolder = Entity()
    private var tableGroup: Entity
    private let lens = LensLayer()
    /// The event of the guided Lens beat being held this frame (TableStage sets it from model.heldCaption), handed
    /// to the Lens for the contact drawing (0.7.4 foundation).
    var lensHeldEvent: Int?
    private let camera = TableCamera()
    /// The Ride camera (see ShotCamera): follows the cue ball and the ball it hits during a replay when Ride is on.
    private let shotCamera = ShotCamera()
    /// The 3D cue and mechanical bridge (see CueRig), a child of the table group.
    private let cueRig: CueRig
    private var balls: [Entity] = []
    private var bodies: [ModelEntity] = []
    private var markers: [ModelEntity] = []
    private var frame: TableFrame
    private var timeline: Timeline
    private var loadedVersion = -1
    /// Per ball: true when it left the table by flying over a cushion (worked out once per recorded shot).
    private var flewOff: [Bool] = []
    private var tourFrame = 0
    /// The clock the last apply() used (after any test pinning), so the camera pushes in on exactly the frame drawn.
    private var lastClock = 0.0
    /// The playing bed (the entity TableBuilder names "felt") and the surface it was last asked to wear.
    private var bed: ModelEntity?
    /// The cushions (TableBuilder names them "cushions") and the cloth they were built in. On the two other real cloths
    /// (tournament and dive bar) the cushions are covered in the same cloth as the bed, as on a real table.
    private var cushions: ModelEntity?
    private var standardCushionMaterials: [any Material] = []
    private var surface: PlaySurface
    /// The table the warm table was last built for (the recorded TableSpec and the kind), and the ball radius the ball
    /// entities were made with (another table's balls are drawn by scaling them).
    private var builtTable: TableSpec
    private var builtKind: TableKind
    private let builtBallRadius: Float
    /// The kind's props (nil on the pool table), and per pin the prop named "pin-<k>" with its resting transform, found
    /// once it exists (a props model may load after the table is built).
    private var props: Entity?
    private var pins: [(entity: Entity, position: SIMD3<Float>, orientation: simd_quatf)?] = []
    var subscriptions: [EventSubscription] = []
    /// The hand zoom (pinch, two-finger pan, double tap on a ball), read by TableZoomGestures and the camera.
    let zoom = TableZoom()
    /// Contact shadows, the lamp shade's fade and the small-ball pictures (see TableDetail); made once the balls are.
    private var detail: TableDetail?
    /// Per ball: the plan point (world x, z) of the hole it drops into in this shot, nil if it stays up.
    private var dropHole: [SIMD2<Float>?] = []
    /// The moment framing of a guided Lens replay (see MomentFrame): its gate lives here, its request comes from
    /// TableStage every frame (nil: no moment framing).
    private let momentFrame = MomentFrame()
    var moment: MomentRequest?
    /// The camera, for the Lens drawings' on-screen scale (TableCamera.pointsPerMetre(at:)), read after it has moved.
    var tableCamera: TableCamera { camera }
    /// The Lens inputs of this frame, set by apply() and drawn by updateCamera() once the camera has moved, so the
    /// drawings can size themselves for this frame's view (0.7.6). Nil when nothing is waiting.
    private var pendingLens: (time: Double, melt: Double, aim: AimPreview?, visibility: [Bool])?

    init(timeline: Timeline, surface: PlaySurface, table kind: TableKind = .standard) {
        self.timeline = timeline
        self.surface = surface
        frame = TableFrame(timeline.table)
        builtTable = timeline.table
        builtKind = kind
        builtBallRadius = Float(timeline.table.ballRadius)
        flewOff = (0..<timeline.ballCount).map { timeline.flewOffTable($0) }
        tableGroup = Entity()
        cueRig = CueRig(lightSource: root)
        buildTable()
        // Child order matches the old single-file scene: table, Lens, camera, then balls and lights.
        root.addChild(tableHolder)
        root.addChild(lens.root)
        root.addChild(camera.rig)
        lens.buildStatic(ballCount: timeline.ballCount, frame: frame, table: timeline.table)
        shotCamera.load(timeline, frame: frame)
        for n in 0..<timeline.ballCount {
            let parts = TableBuilder.makeBall(number: n, radius: frame.ballRadius, parent: root)
            balls.append(parts.ball); bodies.append(parts.body); markers.append(parts.marker)
        }
        detail = TableDetail(bodies: bodies)
        detail?.attach(to: tableGroup)
        detail?.dress(TableBallSet.for(table: kind))
        dropHole = Self.dropHoles(timeline, frame: frame, table: builtTable)
        TableBuilder.addLights(to: root)
        if surface.coversCushions { dress(surface) }
        // The cloth's close-up normal map is drawn after launch; when it arrives, the bed and cushions put it on.
        if StartupAssets.shared.clothDetailNormalIfReady() == nil {
            Task { [weak self] in
                _ = await StartupAssets.shared.clothDetailNormal()
                self?.clothDetailArrived()
            }
        }
    }

    /// Rebuild the cushions' standard cloth and the bed's material now that the close-up detail exists
    /// (TableBuilder.bedMaterial adds it to the real cloths).
    private func clothDetailArrived() {
        let cloth = TableBuilder.bedMaterial(for: .cloth, image: StartupAssets.shared.clothImage())
        standardCushionMaterials = [cloth]
        if !surface.coversCushions { cushions?.model?.materials = standardCushionMaterials }
        dress(surface)
    }

    /// For each ball that drops in this shot, the middle of the hole it drops into, in world plan (x, z): an edge
    /// pocket's drawn circle (TableBuilder.pocketCuts) or a bed hole's centre. Read from the shot's pocket events.
    private static func dropHoles(_ timeline: Timeline, frame: TableFrame, table: TableSpec) -> [SIMD2<Float>?] {
        let cuts = TableBuilder.pocketCuts(frame: frame, table: table)
        var holes = [SIMD2<Float>?](repeating: nil, count: timeline.ballCount)
        for event in timeline.events where event.kind == .pocket {
            for hit in event.balls where hit.ball < holes.count && holes[hit.ball] == nil {
                let k = event.pocket
                if k >= 0, k < cuts.count {
                    holes[hit.ball] = cuts[k].center
                } else if k >= TableSpec.edgePocketCount, k - TableSpec.edgePocketCount < table.bedHoles.count {
                    let w = frame.world(table.bedHoles[k - TableSpec.edgePocketCount].center)
                    holes[hit.ball] = SIMD2(w.x, w.z)
                }
            }
        }
        return holes
    }

    /// Build the warm table for the current timeline's table and kind (replacing any earlier one), with the kind's
    /// props and the cue rig inside it. Not per frame: only when the table changes.
    private func buildTable() {
        tableGroup.removeFromParent()
        tableGroup = TableBuilder.makeTable(frame: frame, table: builtTable, surface: surface, lightSource: root)
        bed = tableGroup.findEntity(named: "felt") as? ModelEntity
        cushions = tableGroup.findEntity(named: "cushions") as? ModelEntity
        standardCushionMaterials = cushions?.model?.materials ?? []
        props = builtKind.makeProps(TablePropsContext(frame: frame, table: builtTable, lightSource: root))
        if let props { tableGroup.addChild(props) }
        pins = [(entity: Entity, position: SIMD3<Float>, orientation: simd_quatf)?](repeating: nil, count: builtTable.pins.count)
        tableGroup.addChild(cueRig.root)
        detail?.attach(to: tableGroup)
        tableHolder.addChild(tableGroup)
        // A rebuilt table misses the one-time reflection hookup (installEnvironment), so it is done here once lit.
        if root.components.has(ImageBasedLightComponent.self) { TableProps.receiveLight(tableGroup, from: root) }
    }

    /// Rebuild the table, the Lens grid and the ball size when the recorded table or the kind changed.
    private func syncTable(_ kind: TableKind) {
        guard timeline.table != builtTable || kind != builtKind else { return }
        builtTable = timeline.table
        builtKind = kind
        buildTable()
        lens.buildGrid(frame: frame, table: builtTable)
        if surface.coversCushions { dress(surface) }
        // Each table is played with its own balls (bar billiards' whites and red, and so on): re-dress them.
        detail?.dress(TableBallSet.for(table: kind))
    }

    /// Light the scene with the generated lamp picture so the glossy parts have something to reflect.
    func installEnvironment() async {
        await TableBuilder.installEnvironment(on: root)
    }

    /// Rebuild the Lens trails and rings for a new recorded shot.
    /// - kind: the table the timeline was solved on (ShowpieceModel.solvedTable); a change rebuilds the warm table.
    /// - cueBall: the ball the player struck (the model's RidePlan.cueBall), which the Ride camera follows.
    func load(_ timeline: Timeline, version: Int, kind: TableKind = .standard, cueBall: Int = 0) {
        guard version != loadedVersion else { return }
        loadedVersion = version
        self.timeline = timeline
        frame = TableFrame(timeline.table)
        syncTable(kind)
        flewOff = (0..<timeline.ballCount).map { timeline.flewOffTable($0) }
        lens.rebuild(timeline: timeline, frame: frame)
        shotCamera.load(timeline, frame: frame, cueBall: cueBall)
        momentFrame.reset()
        dropHole = Self.dropHoles(timeline, frame: frame, table: builtTable)
        // Every new shot is watched from the normal view: a hand zoom springs back.
        zoom.springBack()
        for b in 0..<balls.count {
            balls[b].isEnabled = true
        }
        if Self.launchFlag("-lensSelfTest") { runSelfTest() }
        if Self.launchFlag("-rideSelfTest") { shotCamera.selfTest(size: CGSize(width: 402, height: 874)) }
    }

    /// Dress the playing bed in another surface, without rebuilding the table: only the bed's material changes (the
    /// cushions keep their cloth). A picture not made yet is drawn in the background and put on when it is ready; if
    /// the surface changes again meanwhile, the late picture is dropped. Cheap to call every update (same surface:
    /// nothing happens).
    func setSurface(_ s: PlaySurface) {
        guard s != surface else { return }
        surface = s
        dress(s)
    }

    /// Put the surface's picture on the bed (and on the cushions for the real cloths) once it is drawn.
    private func dress(_ s: PlaySurface) {
        Task { [weak self] in
            let image = await StartupAssets.shared.bedImage(for: s)
            guard let self, self.surface == s else { return }
            let material = TableBuilder.bedMaterial(for: s, image: image)
            self.bed?.model?.materials = [material]
            self.cushions?.model?.materials = s.coversCushions ? [material] : self.standardCushionMaterials
        }
    }

    // MARK: Per frame

    /// - stroke: how the shot on screen was struck, for the cue's follow-through at the start of the clock.
    /// - ride: true while the Ride camera may fly (ShowpieceModel.rideActive); the follow-through hides then.
    /// - bridgeMark: where the bridge hand rests while aiming (BridgeRing); nil hides the ring.
    func apply(time rawT: Double, melt rawMelt: Double, rate: Double, aim: AimPreview?, cueAim: AimPreview? = nil,
               stroke: CueStroke? = nil, ride: Bool = false, bridgeMark: BridgeMark? = nil) {
        // Test hooks (launch flags): pin the clock and/or the melt so a screenshot shows one exact frame.
        var t = Self.launchValue("-lensDebugTime") ?? rawT
        // -lensDebugTour a,b,c: before settling on the pinned time, visit these clock times, one per frame, forward
        // then back, so a screenshot afterwards can be compared with one taken with no tour (scrub exactness).
        if let tour = Self.launchList("-lensDebugTour"), tourFrame < tour.count { t = tour[tourFrame]; tourFrame += 1 }
        lastClock = t
        let melt = Self.launchValue("-lensDebugMelt") ?? rawMelt
        let R = frame.ballRadius
        let m = Float(melt)
        let tableOpacity = max(0, 1 - Float(melt) * 1.15)
        tableGroup.components.set(OpacityComponent(opacity: tableOpacity))
        tableGroup.isEnabled = tableOpacity > 0.01

        // Another table's balls are another size: the entities were made once, so they are scaled to it.
        let ballScale = builtBallRadius > 0 ? R / builtBallRadius : 1
        // In the Lens the balls are drawn 8% larger (look plan package 5): seen straight down at the Lens's distance a
        // racked ball is small beside the glowing trails; 8% keeps touching balls from visibly overlapping.
        let lensScale = 1 + 0.08 * m
        let tableHalf = SIMD2(frame.length * 0.5, frame.width * 0.5)
        var visibility: [Bool] = []
        for b in 0..<balls.count {
            let s = timeline.state(ball: b, at: t)
            // The centre sits one radius above the ball's lowest point, which is s.height above the cloth (a jump).
            var pos = frame.world(s.position, height: R + Float(s.height))
            var lift = Float(s.height)
            var scale: Float = 1
            var visible = true
            if s.pocketed, let tp = timeline.pocketTime[b], b < flewOff.count, flewOff[b],
               timeline.segments[b].count >= 2 {
                // Flew over the rail: carry on along the last flight's closed-form arc (the segment before the parked
                // one, evaluated past its end), then vanish once it is well clear of the table.
                let flight = timeline.segments[b][timeline.segments[b].count - 2]
                let k = flight.kinematics(at: t)
                pos = frame.world(k.position, height: R + Float(k.height))
                lift = Float(k.height)
                visible = (t - tp) < 0.6
            } else if s.pocketed, let tp = timeline.pocketTime[b] {
                // Into the hole, not through its edge: over 0.22 s the ball slides to the middle of its drawn hole as it
                // drops 10 cm into the moulded cup, so the lip and the cup hide it; then it shrinks away in the cup's
                // bottom by 0.35 s (from straight above the cup's floor would otherwise show it sitting there).
                let k = Float(min(1, (t - tp) / 0.22))
                if b < dropHole.count, let hole = dropHole[b] {
                    let ease = k * k * (3 - 2 * k)
                    pos.x += (hole.x - pos.x) * ease
                    pos.z += (hole.y - pos.z) * ease
                }
                pos.y -= 0.10 * k
                let gone = Float(min(1, max(0, (t - tp - 0.22) / 0.13)))
                scale = (1 - 0.15 * k) * (1 - gone)
                visible = (t - tp) < 0.35
            }
            // A ball parked off the table (pocketed in an earlier shot) never shows.
            if !NextShot.isOnTable(timeline.segments[b][0].position0) { visible = false }
            balls[b].isEnabled = visible
            balls[b].position = pos
            balls[b].orientation = frame.orientation(s.orientation)
            balls[b].scale = SIMD3(repeating: scale * ballScale * lensScale)
            detail?.ball(b, centre: pos, lift: lift, radius: R, drawn: R * ballScale * lensScale,
                         onCloth: visible && !s.pocketed, tableHalf: tableHalf)
            bodies[b].components.set(OpacityComponent(opacity: 1 - 0.55 * m))
            markers[b].components.set(OpacityComponent(opacity: m))
            visibility.append(visible)
        }

        detail?.bridge(bridgeMark, frame: frame)
        applyPins(t)
        // The Lens itself is drawn in updateCamera, right after the camera moves (see pendingLens).
        pendingLens = (t, melt, aim, visibility)
        cueRig.update(aim: cueAim, stroke: stroke, clock: t, timeline: timeline, frame: frame, ride: ride)
    }

    /// Topple every pin prop the timeline says is down by clock time t: a quarter turn about its base over 0.15 s, along
    /// the direction the ball pushed it, lifted by its radius as it lies down so it rests on the cloth rather than in it.
    /// A pure function of the clock; a pin not down yet stands at its resting transform.
    private func applyPins(_ t: Double) {
        guard !pins.isEmpty, let props else { return }
        for k in pins.indices {
            if pins[k] == nil, let e = props.findEntity(named: "pin-\(k)") {
                pins[k] = (e, e.position, e.orientation)
            }
            guard let pin = pins[k] else { continue }
            guard k < timeline.pinDownTime.count, let down = timeline.pinDownTime[k], t >= down,
                  let fall = timeline.pinFalls.first(where: { $0.pin == k }) else {
                pin.entity.position = pin.position
                pin.entity.orientation = pin.orientation
                continue
            }
            let x = Float(min(1, (t - down) / 0.15))
            let angle = x * .pi / 2
            var d = frame.direction(fall.direction)
            d = simd_length(d) > 1e-6 ? simd_normalize(d) : SIMD3(1, 0, 0)
            // Turning about up x d by +angle takes the pin's +Y axis over toward d.
            let axis = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), d))
            pin.entity.orientation = simd_quatf(angle: angle, axis: axis) * pin.orientation
            let lift = k < builtTable.pins.count ? Float(builtTable.pins[k].radius) : 0
            pin.entity.position = pin.position + SIMD3(0, lift * sin(angle), 0)
        }
    }

    /// Frames the whole table in the measured free space, swings from a low three-quarter view to straight down as the
    /// Lens melts in, and pushes in on the break (see TableCamera).
    /// - ride: true while Ride is on and a replay is playing (ShowpieceModel.rideActive); the ride follows the same
    ///   clock as the balls, including any test pinning.
    func updateCamera(melt: Double, request: FramingRequest, ride: Bool = false) {
        shotCamera.clock = lastClock
        shotCamera.active = ride
        // The moment framing for this clock (a pure function of it once its gate is open; see MomentFrame).
        let focus = momentFrame.focus(clock: lastClock, request: moment, handAtFit: zoom.atFittedView, frame: frame,
                                      reduceMotion: TableCamera.reduceMotion)
        camera.update(melt: Self.launchValue("-lensDebugMelt") ?? melt, clock: lastClock, duration: timeline.duration,
                      request: request, frame: frame, ride: shotCamera, zoom: zoom, moment: focus)
        // The hand zoom ignores pinches, pans and double taps while the ride has the view (bug #24); not merely while
        // Ride is on, which it stays while the player aims the next shot from the ordinary table view.
        zoom.rideHold = shotCamera.flying
        // With the camera placed: the lamp shade's fade and each ball's picture for the size it now is on screen.
        detail?.view(eye: camera.eye, forward: camera.forward, focal: camera.focal)
        // And the Lens, for this frame's clock and this frame's view.
        if let p = pendingLens {
            pendingLens = nil
            lens.heldEvent = lensHeldEvent
            lens.apply(time: p.time, melt: p.melt, aim: p.aim, timeline: timeline, frame: frame, ballVisible: p.visibility)
        }
    }

    /// Whether the showpiece opening is at its start (TableStage, every frame, before the clock moves): its rise from
    /// under the lamp starts when this turns true (see TableCamera.cueIntro).
    func cueIntro(_ on: Bool) { camera.cueIntro(on) }

    /// True while the opening's lamp shot has not yet risen to the table; TableStage holds the clock meanwhile.
    var introHolding: Bool { camera.introHolding }

    // MARK: Test hooks

    private static func launchFlag(_ name: String) -> Bool { ProcessInfo.processInfo.arguments.contains(name) }

    private static func launchList(_ name: String) -> [Double]? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: name), i + 1 < a.count else { return nil }
        return a[i + 1].split(separator: ",").compactMap { Double($0) }
    }

    private static func launchValue(_ name: String) -> Double? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: name), i + 1 < a.count else { return nil }
        return Double(a[i + 1])
    }

    /// Scrub-exactness check. Drives the Lens to a list of clock times, records its fingerprint at each, then
    /// visits the same times again going backwards, then in a shuffled order, and compares. Also checks that the
    /// trail fade only ever dims with age. Results go to the console (visible with simctl launch --console).
    /// The check itself is LensScrubCheck.run (shared with the unit tests); this only logs its result.
    private func runSelfTest() {
        let r = LensScrubCheck.run(lens: lens, timeline: timeline, frame: frame)
        NSLog("LENS-SELFTEST scrub mismatches=%d distinctStates=%d/%d fadeMonotone=%@ floor=%.2f bloom=%@ -> %@",
              r.mismatches, r.distinctStates, r.timesVisited, r.fadeMonotone ? "yes" : "NO", r.fadeFloor,
              r.bloomActive ? "on" : "off", r.passed ? "PASS" : "FAIL")
    }
}
