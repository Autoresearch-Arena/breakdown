// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (the colour legend left the 3D scene: it is a SwiftUI glass chip in
//          the title row now (LensLegendChip in CaptionViews), which follows Dynamic Type and VoiceOver and costs the
//          table no room).
// Edited: Claude Opus 5.5 High, 21-November-2026 (spin markers: every moving or spinning ball in the Lens now carries
//          an amber belt showing the part of its spin that is NOT natural rolling (draw, follow, the slip that makes a
//          ball slide), with an arrowhead on top showing which way the top of the ball turns, and a flat blue ring on
//          the cloth with an arrow for side spin (english). Both fade with the amount and are read from the recorded
//          timeline at the clock, so scrubbing shows the same markers either way.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (AimPreview also carries what the 3D cue needs: whether it may show,
//          power, elevation, tip offsets and the bridge; the Lens does not read them).
// PURPOSE: The cold Physics Lens layer. Owns the grid under the Lens, the glowing trails coloured by motion phase,
//          the impact rings, the velocity arrows and the player's aim line, plus their materials
//          and their per-frame logic. Anything about how the Lens LOOKS or when its parts appear belongs here.
//          Does NOT belong here: the warm table and balls (TableBuilder.swift), the camera (TableCamera.swift), the
//          pictures themselves (LensTextures.swift, BallTextures.gridTexture), or moving the balls (TableScene.apply).
//          The coordinator hands this layer the clock, the melt, the timeline, the frame and which balls are visible;
//          the layer never reads or changes the model.
//
//          HOW THE TRAILS WORK (package 2 of the glow-up plan, 13-Nov-2026). Every path is built ONCE per recorded shot
//          into two meshes (one for sliding, one for rolling) as thin ribbons. Each vertex carries the TIME the ball
//          was there as a texture coordinate. The material's picture is a strip along age: bright and white-hot at the
//          head, easing over a couple of seconds to a faint trace, and transparent for any time still in the future.
//          Each frame the only thing that changes is a texture offset equal to a function of the playback clock, so
//          the head of every trail sits exactly at the ball, the fade with age is exact, and scrubbing backwards or
//          forwards shows the identical picture for the identical time. No trail piece is ever switched on or off.
//          Rings use a fixed span of clock time (not of wall time), so they too depend on the clock alone.
//
//          GLOW. RealityKit in Xcode 27 has a bloom component (BloomComponent, BloomOptionsComponent), but it is
//          iOS 27 / macOS 27 only and this app deploys to 26. So the glow is built in the pictures first (a thin bright
//          core inside a wider soft halo, on every device), and the system bloom is added on top only where it exists,
//          with the halo turned down so the two do not stack into mush. Launch with -noBloom to see the fallback.
//          FADE (package 4, 0.4.0): the newest second of a path is full strength, then brightness drops steeply (a power
//          curve under a smoothstep) to a faint floor by four seconds of age, and the line also narrows with age (the picture
//          is thinner for older time), so a late-break frame shows bold fresh lines over dim hairlines instead of a scribble.
//          Both curves are functions of age alone, baked into the one picture, so the clock-only exactness is untouched.
//          Draw order is fixed with sort groups: grid, then trails, then rings, then spin markers, then arrows.
//
//          SPIN MARKERS (21-Nov-2026). Rolling spin is not interesting on its own: it just follows the velocity. What
//          makes draw, follow and swerve happen is the DIFFERENCE between the ball's spin and natural roll, so that is
//          what the amber belt shows (amber because that difference is exactly what makes a ball slide). The vertical
//          part of the spin, english, gets its own flat ring on the cloth in the cushion blue, since cushions are where
//          side spin shows itself. Each ball owns one belt and one ring built once; per frame only their pose and
//          opacity change.
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Lens grid is built by buildGrid, which TableScene calls again
//          when the table changes; it also marks the holes in another table's bed).
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, package 4: with Differentiate Without Colour on,
//          a sliding path is built as dashes and a rolling path stays solid, so the two phases differ in shape, not
//          only in amber against cyan; the trails are rebuilt when the setting changes. The dashes are cut from the
//          geometry at build time, so the clock-only exactness of the picture is untouched. Package 5: the
//          generation-two events now leave a visible mark like the others: a red double ring where the cue MISCUED (the
//          one place a sound alone would carry it), a pocket-coloured ring where a ball skipped over a hole, and an
//          impact ring where a jam was brought to rest.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 22,
//          24 and 28: a ball in the air leaves its own trail, white and dashed, drawn at the ball's own height, with a
//          soft dot on the cloth under it while it flies and a white ring where it lands; its velocity arrow rides at
//          its height instead of on the cloth. A skip over a hole is a BROKEN ring (dashed arcs) so its shape, not
//          only its colour, says "did not drop"; a jam brought to rest gets a cross on each wedged ball that holds
//          still and fades instead of expanding like an impact. Throw: at a ball-to-ball contact where friction sent
//          the struck ball half a degree or more off the line of centres (CaptionEngine.throwFacts, the same rule the
//          caption uses), the line of centres is drawn dashed beside the real departure, from the struck ball, for a
//          short span of clock. Every new mark is a function of the clock alone and is in the fingerprint.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment hook, plan items 57 and 23: AimPreview carries the
//          picked cue and the bridge's length for CueRig; two appended fields with defaults.)
// SRP/DRY check: Pass - Lens drawing only; coordinates come from TableFrame, colours from Theme, pictures from LensTextures.
//          The throw rule is CaptionEngine's (one rule for the words and the drawing).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Metal
import RealityKit
import simd

/// Where the player's break is aimed, drawn as a guide line on the felt.
struct AimPreview {
    var from: Vec2
    var direction: Vec2
    var length: Double
    var always: Bool
    // For the 3D cue (CueRig); the Lens itself ignores these. Appended with defaults so existing callers still compile.
    /// True when the cue may be drawn: the shot on screen has played out and the cue ball is on the table. The aim
    /// line above keeps showing without it.
    var showsCue = false
    /// Power 0 to 1: how far the cue is drawn back.
    var powerFraction = 0.0
    /// Sine of the cue's raise above the table (only the massé and the jump use it).
    var elevation = 0.0
    /// Tip contact offsets on the cue ball, metres: up is follow, right (as the player sees it) is side spin.
    var tipUp = 0.0
    var tipSide = 0.0
    /// The cue rests on the mechanical bridge.
    var usesBridge = false
    /// Which cue CueRig draws: the one the game picked for the shot (model.cueChoice.kind; plan item 57, the
    /// equipment stream's hook, appended with a default like the rest).
    var cue: CueKind = .house
    /// Metres from the cue ball's centre back to the bridge hand (model.strokeBridgeLength): CueRig stops the drawn
    /// pull-back in front of it (plan item 23). Nil: the automatic bridge.
    var bridgeLength: Double? = nil
}

@MainActor
final class LensLayer {
    // MARK: Tunables

    /// Seconds of clock the newest part of a path stays at full brightness.
    static let trailHold = 1.0
    /// Age at which a path has faded to its faint trace, and how bright that trace is (0 to 1). Package 4 (0.4.0) made
    /// the hold shorter and the floor lower: by the end of a break the old 0.20 floor on thick lines was still a dense
    /// scribble; now only the last second or so is bright and everything older is a faint hairline (see `trailWidth`).
    static let trailFadeEnd = 4.0
    static let trailFloor = 0.11
    /// How thin the oldest path gets, as a share of its fresh width (the picture narrows the line as it ages).
    static let trailOldWidth = 0.42
    /// Clock seconds an impact ring takes to expand and fade. Fixed in clock time so it depends on the clock alone.
    static let ringSpan = 0.4
    /// Spin marker fades, as speeds in m/s at the ball's surface (spin times radius), so they read the same on any
    /// table size. Below `lo` a marker is hidden; it reaches its base strength by `mid` and full brightness by `full`.
    static let slipFade = (lo: 0.04, mid: 0.25, full: 1.2)
    static let sideFade = (lo: 0.02, mid: 0.12, full: 0.6)
    /// Clock seconds over which a pocketed ball's markers fade out (the ball itself sinks away in about 0.22 s).
    static let spinPocketFade = 0.2
    /// Dashed sliding trails (Differentiate Without Colour): length of each dash and of each gap, metres along the
    /// path. A fresh line is up to about 5 cm wide (two half-widths of `half(speed)` at break speed), so a 6 cm dash
    /// is longer than the line is wide and reads as a dash, and a 4 cm gap is wide enough to see at a slow roll.
    static let dashLength = 0.06
    static let dashGap = 0.04
    /// Ring strength (the impulse scale used for impact rings) for events that record no impulse of their own: a
    /// miscue and a rim skip get a full-size ring because each is a single, decisive moment worth seeing.
    static let markerStrength: Float = 1.0
    /// Miscue ring colour: the warm red that ends the power bar (AimGauges), the app's one "too far" colour.
    static let miscueRGB: (Double, Double, Double) = (1.0, 0.30, 0.25)
    /// An airborne trail rides this far above the ball's lowest point: between the sliding (1.6 mm) and rolling
    /// (4.6 mm) lifts, so where a flight starts and ends on the cloth it joins the cloth trails without fighting them
    /// for depth, and in the air it climbs with the ball.
    static let airborneLift: Float = 0.0031
    /// Airborne dashes: shorter than the sliding ones (6 cm on, 4 cm off) because a jump's whole flight is often only
    /// a few tens of centimetres; 3 cm on and 2 cm off still gives several dashes over the shortest hop.
    static let airDash = 0.03
    static let airGap = 0.02
    /// The dot on the cloth under a flying ball: shown once the ball is a millimetre up (the solver's own minimumHop),
    /// as wide as the ball, fading as it climbs so a high jump's dot reads as far below the ball.
    static let dotMinHeight = 0.001
    /// Clock seconds a jam's cross stays up: it marks balls brought to REST, so it holds still for longer than an
    /// impact ring's flash (two and a half ring spans, an even second) and then fades.
    static let jamMarkSpan = 1.0
    /// Throw marks: how long they stay (clock seconds; a guided hold stops the clock on the hit, so they stay for the
    /// whole hold) and how long they are drawn. Half a metre opens a one-degree throw to about 9 mm at the far end, a
    /// third of a ball's width, which reads at the normal camera distance.
    static let throwMarkSpan = 1.5
    static let throwLineLength: Float = 0.5

    /// Smooth 0-to-1 ramp between `a` and `b`.
    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let s = min(1, max(0, (x - a) / (b - a)))
        return s * s * (3 - 2 * s)
    }

    /// Opacity of a spin marker for a surface speed `x`: zero below `lo`, eased in to a base of 0.5 by `mid`, then
    /// growing to full by `full`, so a stronger spin glows brighter and nothing ever pops in or out.
    static func spinOpacity(_ x: Double, _ f: (lo: Double, mid: Double, full: Double)) -> Double {
        smoothstep(f.lo, f.mid, x) * (0.5 + 0.5 * smoothstep(f.mid, f.full, x))
    }

    /// Fraction 0 (fresh) to 1 (fully faded) of the way through the fade at `age` seconds behind the ball, eased at
    /// both ends so there is no visible kink where the hold ends or the trace begins.
    static func trailFade(age: Double) -> Double {
        if age <= trailHold { return 0 }
        if age >= trailFadeEnd { return 1 }
        let s = (age - trailHold) / (trailFadeEnd - trailHold)
        return s * s * (3 - 2 * s)
    }

    /// Brightness of a trail at `age` seconds behind the ball: 1 while fresh, dropping steeply (the power makes the
    /// first part of the fade quick, so path older than about two seconds is already dim), never below `trailFloor`.
    /// The trail picture is baked from this one function, so this is the single definition of the fade.
    static func trailBrightness(age: Double) -> Double {
        let f = trailFade(age: age)
        return trailFloor + (1 - trailFloor) * pow(1 - f, 1.6)
    }

    /// Width of a trail at `age`: 1 while fresh, narrowing to `trailOldWidth`. Baked into the picture's cross-section.
    static func trailWidth(age: Double) -> Double {
        1 - (1 - trailOldWidth) * trailFade(age: age)
    }

    // MARK: Parts

    /// Parent of every Lens entity; fades as a whole with the melt value.
    let root = Entity()
    private let trailRoot = Entity()
    private let ringRoot = Entity()
    private let arrowRoot = Entity()
    private let gridEntity = ModelEntity()
    private let aimLine = ModelEntity()
    private var arrows: [(root: Entity, shaft: Entity, head: Entity, glow: Entity)] = []
    /// One timed mark on the table: an impact ring (grows and fades) or a held mark (a jam's cross, a throw line:
    /// stays its size, holds, then fades). All are driven by the clock alone.
    private struct Flash {
        let entity: ModelEntity
        let time: Double
        let span: Double
        let radius: Float
        let grows: Bool
        /// Peak opacity of a held mark.
        let peak: Float
    }
    private var rings: [Flash] = []
    private let ringMesh = LensLayer.annulus(segments: 72, inner: 0.62)
    /// A skip over a hole: the same ring cut into twelve arcs with gaps, so its shape says "did not drop".
    private let brokenRingMesh = LensLayer.annulus(segments: 72, inner: 0.62, arcs: 12)
    /// A jam brought to rest: a flat cross on each wedged ball.
    private let crossMesh = LensLayer.cross(halfWidth: 0.16)
    /// Throw lines: one solid, one dashed, both a unit long along +x from the origin (scaled to length).
    private let solidLineMesh = LensLayer.strip(dashes: 0, halfWidth: 0.0035)
    private let dashedLineMesh = LensLayer.strip(dashes: 9, halfWidth: 0.0035)
    private var markMaterial = UnlitMaterial()
    /// The soft dot on the cloth under each ball, shown while it flies.
    private let dotRoot = Entity()
    private var dots: [ModelEntity] = []
    private var dotMaterial = UnlitMaterial()

    /// One entity per trail colour, each holding every ball's path of that colour.
    private var trailEntities: [MotionPhase: ModelEntity] = [:]
    private var trailMaterials: [MotionPhase: UnlitMaterial] = [:]
    private var trailOffsets: [MotionPhase: Float] = [:]
    private var ringMaterials: [LensEventKind: UnlitMaterial] = [:]
    /// The ring for a miscue (a cue strike whose tip slid off), separate from the ordinary strike ring.
    private var miscueMaterial: UnlitMaterial?
    /// The last recording and frame the trails were built from, so a change of the colour setting can rebuild them.
    private var lastBuild: (timeline: Timeline, frame: TableFrame)?
    /// Whether the current trails were built dashed.
    private var builtDashed = false
    private var settingObserver: NSObjectProtocol?
    private var arrowMaterial = UnlitMaterial()
    private var arrowGlowMaterial = UnlitMaterial()
    /// Spin markers: per ball, the slip belt around the ball and the side-spin ring on the cloth.
    private let spinRoot = Entity()
    private var spinMarkers: [(slip: ModelEntity, side: ModelEntity)] = []
    private var slipMaterial = UnlitMaterial()
    private var sideMaterial = UnlitMaterial()

    /// True when the system bloom pass is on for the Lens (iOS 27 / macOS 27 and not turned off by -noBloom).
    private(set) var bloomActive = false
    private let sortGroup = ModelSortGroup(depthPass: nil)


    private static func clampSampler() -> MaterialParameters.Texture.Sampler {
        let d = MTLSamplerDescriptor()
        d.sAddressMode = .clampToEdge
        d.tAddressMode = .clampToEdge
        d.minFilter = .linear
        d.magFilter = .linear
        return MaterialParameters.Texture.Sampler(d)
    }

    /// A transparent, unlit, double-sided material whose colour AND opacity come from one picture (its alpha).
    private static func glow(_ tex: TextureResource, tint: PlatformColor = .white) -> UnlitMaterial {
        var m = UnlitMaterial()
        let t = MaterialParameters.Texture(tex, sampler: clampSampler())
        m.color = .init(tint: tint, texture: t)
        // Opacity 1 times the picture's own alpha. (Feeding the picture in as a separate opacity texture was tried
        // first and dimmed colours unevenly on the iOS 27 simulator, so the alpha rides on the colour picture.)
        m.blending = .transparent(opacity: 1.0)
        m.faceCulling = .none
        return m
    }

    init() {
        bloomActive = Self.enableBloom(on: root)
        // With a real bloom pass the halo in the pictures is dialled back; without one it carries the whole glow.
        let haloGain = bloomActive ? 0.55 : 1.0

        let amber = Theme.amberRGB, cyan = Theme.cyanRGB
        // A flight is white (the spec's airborne trail): neither sliding nor rolling, because nothing touches the cloth.
        let phaseColours: [MotionPhase: (Double, Double, Double)] = [.sliding: amber, .rolling: cyan,
                                                                     .airborne: Theme.paperRGB]
        for (phase, c) in phaseColours {
            if let tex = LensTextures.trail(color: c, haloGain: haloGain, brightness: { Self.trailBrightness(age: $0) }, width: { Self.trailWidth(age: $0) }) {
                trailMaterials[phase] = Self.glow(tex)
            }
        }
        // Rings and arrows share one soft line picture, tinted per use.
        if let ringTex = LensTextures.softLine(peak: 0.85, haloGain: haloGain) {
            func ring(_ r: Double, _ g: Double, _ b: Double) -> UnlitMaterial { Self.glow(ringTex, tint: rgba(r, g, b)) }
            ringMaterials = [.ballBall: ring(1.0, 0.97, 0.80), .cushion: ring(0.45, 0.70, 1.0),
                             // White: a landing (the only phase change that leaves a ring), the airborne trail's colour.
                             .pocket: ring(1.0, 0.82, 0.25), .cueStrike: ring(1.0, 0.97, 0.80), .phaseTransition: ring(1, 1, 1),
                             // A skip over a hole wears the pocket colour (on a broken ring); a jam brought to rest the
                             // impact colour (on a cross). Their shapes, not these colours, set them apart.
                             .rimSkip: ring(1.0, 0.82, 0.25), .settledInContact: ring(1.0, 0.97, 0.80)]
            let red = Self.miscueRGB
            miscueMaterial = ring(red.0, red.1, red.2)
        }
        // The dot under a flying ball: the soft line picture with its peak at the centre of a disc (v runs centre to
        // rim on the annulus), so it is brightest under the ball and soft at its edge.
        if let dotTex = LensTextures.softLine(peak: 0.0, haloGain: haloGain) {
            let p = Theme.paperRGB
            dotMaterial = Self.glow(dotTex, tint: rgba(p.0, p.1, p.2))
        }
        if let lineTex = LensTextures.softLine(peak: 0.5, haloGain: haloGain) {
            // Throw lines in the Lens's light paper colour; the departure is solid, the line of centres dashed.
            let p = Theme.paperRGB
            markMaterial = Self.glow(lineTex, tint: rgba(p.0, p.1, p.2))
            arrowGlowMaterial = Self.glow(lineTex, tint: rgba(1.0, 0.93, 0.55))
            // Slip is sliding, so it wears the sliding amber; side spin wears the cushion-ring blue used above.
            slipMaterial = Self.glow(lineTex, tint: rgba(amber.0, amber.1, amber.2))
            sideMaterial = Self.glow(lineTex, tint: rgba(0.45, 0.70, 1.0))
        }
        var core = UnlitMaterial(color: rgba(1.0, 0.96, 0.78))
        core.faceCulling = .none
        arrowMaterial = core

        root.addChild(gridEntity)
        root.addChild(dotRoot)
        root.addChild(trailRoot)
        root.addChild(ringRoot)
        root.addChild(spinRoot)
        root.addChild(arrowRoot)
        root.addChild(aimLine)

        // Differentiate Without Colour switched while the app runs: rebuild the trails dashed or solid at once.
        let change = LensTextures.differentiateWithoutColorChanged
        settingObserver = change.center.addObserver(forName: change.name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuildIfSettingChanged() }
        }
    }

    /// Rebuild the current trails when the dashed setting no longer matches how they were built.
    private func rebuildIfSettingChanged() {
        guard LensTextures.differentiateWithoutColor != builtDashed, let last = lastBuild else { return }
        rebuild(timeline: last.timeline, frame: last.frame)
    }

    /// Switches on the system bloom for everything under `root`, where the system has it. Returns whether it is on.
    private static func enableBloom(on root: Entity) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("-noBloom") { return false }
        if #available(iOS 27.0, macOS 27.0, *) {
            // Hierarchical: only the Lens glows. The warm table and the controls behind are left alone.
            root.components.set(BloomComponent(scope: .hierarchical))
            var options = BloomOptionsComponent()
            options.strength = 1.4
            options.threshold = 0.35
            options.blurRadius = 12
            root.components.set(options)
            return true
        }
        return false
    }

    // MARK: Static parts

    /// The shapes that do not depend on the recorded shot: one velocity arrow per ball, the grid, the aim line.
    func buildStatic(ballCount: Int, frame: TableFrame, table: TableSpec) {
        // Velocity arrow = a glowing ribbon shaft, a bright triangular head and a larger faint head behind it.
        let shaftMesh = MeshResource.generatePlane(width: 1, depth: 0.042)
        let headMesh = LensLayer.triangle(length: 0.034, halfWidth: 0.015)
        for _ in 0..<ballCount {
            let arrow = Entity()
            let shaft = ModelEntity(mesh: shaftMesh, materials: [arrowGlowMaterial])
            shaft.components.set(ModelSortGroupComponent(group: sortGroup, order: 30))
            let shaftHolder = Entity()
            shaft.position = SIMD3(0.5, 0, 0)
            shaftHolder.addChild(shaft)
            let head = ModelEntity(mesh: headMesh, materials: [arrowMaterial])
            head.position = SIMD3(0, 0.0004, 0)
            head.components.set(ModelSortGroupComponent(group: sortGroup, order: 32))
            let glow = ModelEntity(mesh: headMesh, materials: [arrowGlowMaterial])
            glow.scale = SIMD3(2.0, 1, 2.0)
            glow.position = SIMD3(-0.015, 0, 0)
            glow.components.set(ModelSortGroupComponent(group: sortGroup, order: 31))
            let headHolder = Entity()
            headHolder.addChild(glow); headHolder.addChild(head)
            arrow.addChild(shaftHolder); arrow.addChild(headHolder)
            arrowRoot.addChild(arrow)
            arrows.append((arrow, shaftHolder, headHolder, glow))
        }

        // Spin markers, one pair per ball, sharing two meshes. Both are unit-radius arcs scaled per frame.
        let beltMesh = LensLayer.spinArc(flat: false, halfWidth: 0.13, headLength: 0.46, headHalfWidth: 0.24)
        let flatMesh = LensLayer.spinArc(flat: true, halfWidth: 0.09, headLength: 0.40, headHalfWidth: 0.20)
        for _ in 0..<ballCount {
            let slip = ModelEntity(mesh: beltMesh, materials: [slipMaterial])
            slip.components.set(ModelSortGroupComponent(group: sortGroup, order: 25))
            slip.components.set(OpacityComponent(opacity: 0))
            slip.isEnabled = false
            let side = ModelEntity(mesh: flatMesh, materials: [sideMaterial])
            side.components.set(ModelSortGroupComponent(group: sortGroup, order: 24))
            side.components.set(OpacityComponent(opacity: 0))
            side.isEnabled = false
            spinRoot.addChild(slip); spinRoot.addChild(side)
            spinMarkers.append((slip, side))
        }

        // The dot under each ball while it flies: a soft disc a ball wide, lying just above the grid.
        let dotMesh = LensLayer.annulus(segments: 32, inner: 0)
        for _ in 0..<ballCount {
            let dot = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
            dot.scale = SIMD3(frame.ballRadius, 1, frame.ballRadius)
            dot.components.set(ModelSortGroupComponent(group: sortGroup, order: 5))
            dot.components.set(OpacityComponent(opacity: 0))
            dot.isEnabled = false
            dotRoot.addChild(dot)
            dots.append(dot)
        }

        buildGrid(frame: frame, table: table)

        // Aim line for the player's own break.
        aimLine.model = ModelComponent(mesh: .generateBox(width: 1, height: 0.002, depth: 0.004),
                                       materials: [UnlitMaterial(color: rgba(1, 1, 1, 0.8))])
        aimLine.isEnabled = false
    }

    /// Grid under the Lens, with the cushion line, the rail outline and the pockets drawn into it (the edge pockets the
    /// table has, and any holes in its bed). Called again by TableScene when the table changes.
    func buildGrid(frame: TableFrame, table: TableSpec) {
        let L = frame.length, W = frame.width
        let pockets = zip(table.pockets, table.pocketCaptureRadius).map { (x: $0.0.x, y: $0.0.y, radius: $0.1) }
            + table.bedHoles.map { (x: $0.center.x, y: $0.center.y, radius: $0.captureRadius) }
        if let tex = BallTextures.gridTexture(length: Double(L), width: Double(W), pockets: pockets) {
            let m = Float(BallTextures.gridMargin)
            gridEntity.model = ModelComponent(mesh: .generatePlane(width: L + 2 * m, depth: W + 2 * m), materials: [Self.glow(tex)])
            gridEntity.position = SIMD3(0, 0.0004, 0)
            gridEntity.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
        }
    }

    // MARK: Timeline-dependent parts

    /// Rebuild the trails and rings for a new recorded shot.
    func rebuild(timeline: Timeline, frame: TableFrame) {
        for child in Array(trailRoot.children) { child.removeFromParent() }
        for child in Array(ringRoot.children) { child.removeFromParent() }
        trailEntities = [:]; trailOffsets = [:]; rings = []
        lastBuild = (timeline, frame)
        builtDashed = LensTextures.differentiateWithoutColor

        // Gather every ball's ribbons into one mesh per colour.
        var builders: [MotionPhase: RibbonBuilder] = [.sliding: RibbonBuilder(), .rolling: RibbonBuilder(),
                                                      .airborne: RibbonBuilder()]
        for b in 0..<timeline.ballCount {
            addTrails(for: b, timeline: timeline, frame: frame, dashSliding: builtDashed, into: &builders)
        }
        for (phase, builder) in builders {
            guard let mesh = builder.mesh(), let mat = trailMaterials[phase] else { continue }
            let e = ModelEntity(mesh: mesh, materials: [mat])
            let order: Int32 = phase == .sliding ? 10 : (phase == .rolling ? 11 : 12)
            e.components.set(ModelSortGroupComponent(group: sortGroup, order: order))
            trailRoot.addChild(e)
            trailEntities[phase] = e
        }

        /// One mark lying on the table at `point`, hidden until the clock reaches it.
        func place(_ mesh: MeshResource, _ mat: UnlitMaterial, at point: Vec2, scale: Float, yaw: Float = 0,
                   height: Float = 0.008) -> ModelEntity {
            let mark = ModelEntity(mesh: mesh, materials: [mat])
            mark.scale = SIMD3(scale, 1, scale)
            mark.position = frame.world(point, height: height)
            if yaw != 0 { mark.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0)) }
            mark.isEnabled = false
            mark.components.set(OpacityComponent(opacity: 0))
            mark.components.set(ModelSortGroupComponent(group: sortGroup, order: 20))
            ringRoot.addChild(mark)
            return mark
        }

        for e in timeline.events {
            // Which events leave a ring: every impact and drop as before, plus the generation-two moments (a jam
            // brought to rest, a skip over a hole), a miscue, which a player could otherwise only hear, and a landing
            // from a jump (only that phase change: skid-to-roll and take-off leave no ring).
            let isMiscue = e.kind == .cueStrike && e.miscue == true
            let isLanding = e.kind == .phaseTransition && e.flight == .landing
            let ringed: Set<LensEventKind> = [.ballBall, .cushion, .pocket, .rimSkip, .settledInContact]
            guard ringed.contains(e.kind) || isMiscue || isLanding else { continue }
            let recorded = Float(min(1.5, max(0.1, e.normalImpulse)))
            let strength = (isMiscue || e.kind == .rimSkip) ? Self.markerStrength : recorded
            let radius = 0.022 + 0.034 * strength
            guard let mat = isMiscue ? miscueMaterial : ringMaterials[e.kind] else { continue }
            if e.kind == .settledInContact {
                // A jam brought to rest: a cross on each wedged ball where it came to rest, held still, not an
                // expanding flash, because the event is balls stopping, not a hit.
                for b in e.balls where b.ball < timeline.ballCount {
                    let at = timeline.state(ball: b.ball, at: e.time).position
                    let mark = place(crossMesh, mat, at: at, scale: frame.ballRadius * 1.3, yaw: .pi / 4)
                    rings.append(Flash(entity: mark, time: e.time, span: Self.jamMarkSpan, radius: frame.ballRadius * 1.3,
                                       grows: false, peak: 0.85))
                }
                continue
            }
            // A miscue is drawn as two rings, one inside the other, so its shape (not only its red) sets it apart
            // from every impact ring; the inner one is 0.6 of the outer, a gap wider than the ring's own band. A skip
            // over a hole is one broken ring, again a shape no impact has.
            let sizes: [Float] = isMiscue ? [radius, radius * 0.6] : [radius]
            let mesh = e.kind == .rimSkip ? brokenRingMesh : ringMesh
            for size in sizes {
                let ring = place(mesh, mat, at: e.point, scale: size)
                rings.append(Flash(entity: ring, time: e.time, span: Self.ringSpan, radius: size, grows: true, peak: 0.85))
            }
            // Throw: the line of centres (dashed) beside where the struck ball really went (solid), from that ball.
            if let t = CaptionEngine.throwFacts(e), t.object < timeline.ballCount {
                let from = timeline.state(ball: t.object, at: e.time).position
                for (line, mesh, peak) in [(t.lineOfCentres, dashedLineMesh, Float(0.7)), (t.departure, solidLineMesh, Float(0.9))] {
                    let dir = frame.direction(line)
                    let yaw = -atan2(dir.z, dir.x)
                    let mark = place(mesh, markMaterial, at: from, scale: 1, yaw: yaw, height: 0.009)
                    // Long along the line, a unit wide across (the strip's own half-width is in metres already).
                    mark.scale = SIMD3(Self.throwLineLength, 1, 1)
                    rings.append(Flash(entity: mark, time: e.time, span: Self.throwMarkSpan, radius: 1, grows: false,
                                       peak: peak))
                }
            }
        }
    }

    /// Ribbon geometry for one colour: positions, the (time, across) picture coordinates and triangles.
    @MainActor private struct RibbonBuilder {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        /// Adds one strip along `pts`; `times[i]` is when the ball was at `pts[i]`, `halves[i]` the half-width there.
        mutating func addStrip(_ pts: [SIMD3<Float>], times: [Double], halves: [Float]) {
            guard pts.count >= 2, times.count == pts.count, halves.count == pts.count else { return }
            let base = UInt32(positions.count)
            for (i, p) in pts.enumerated() {
                let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
                var d = b - a
                d.y = 0
                let len = simd_length(d)
                let dir = len > 1e-9 ? d / len : SIMD3<Float>(1, 0, 0)
                let side = SIMD3<Float>(-dir.z, 0, dir.x) * halves[i]
                // u carries the time as a fraction of the picture's age window; v runs across the ribbon.
                let u = Float(times[i] / LensTextures.ageWindow)
                positions.append(p + side); uvs.append(SIMD2(u, 0))
                positions.append(p - side); uvs.append(SIMD2(u, 1))
            }
            for i in 0..<(pts.count - 1) {
                let a = base + UInt32(i * 2)
                indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
            }
        }

        func mesh() -> MeshResource? {
            guard !positions.isEmpty else { return nil }
            var d = MeshDescriptor(name: "trails")
            d.positions = MeshBuffers.Positions(positions)
            d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
            d.primitives = .triangles(indices)
            return try? MeshResource.generate(from: [d])
        }
    }

    /// Cuts one strip into dashes `on` metres long separated by `off`-metre gaps, measured along the path, so the
    /// pattern is even whatever the point spacing. Each cut point is placed by straight interpolation between its two
    /// neighbours, with its time and half-width interpolated the same way, so every dash still carries the exact
    /// times the trail picture fades by. The pattern restarts at the start of each strip.
    static func dashes(_ pts: [SIMD3<Float>], times: [Double], halves: [Float], on: Double, off: Double)
        -> [(pts: [SIMD3<Float>], times: [Double], halves: [Float])] {
        guard pts.count >= 2, on > 0, off > 0 else { return [] }
        var out: [(pts: [SIMD3<Float>], times: [Double], halves: [Float])] = []
        var current: (pts: [SIMD3<Float>], times: [Double], halves: [Float]) = ([pts[0]], [times[0]], [halves[0]])
        var drawing = true
        var phase = 0.0                     // distance into the current dash or gap
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let length = Double(simd_distance(a, b))
            var used = 0.0                  // distance already walked along this piece
            while length - used > 1e-9 {
                let room = (drawing ? on : off) - phase
                let step = min(room, length - used)
                used += step
                phase += step
                let k = Float(used / length)
                let p = a + (b - a) * k
                let t = times[i - 1] + (times[i] - times[i - 1]) * Double(k)
                let h = halves[i - 1] + (halves[i] - halves[i - 1]) * k
                if drawing { current.pts.append(p); current.times.append(t); current.halves.append(h) }
                if phase >= (drawing ? on : off) - 1e-9 {
                    // End of a dash: keep it; end of a gap: start the next dash at this point.
                    if drawing { if current.pts.count >= 2 { out.append(current) } } else { current = ([p], [t], [h]) }
                    drawing.toggle()
                    phase = 0
                }
            }
        }
        if drawing, current.pts.count >= 2 { out.append(current) }
        return out
    }

    private func addTrails(for ball: Int, timeline: Timeline, frame: TableFrame, dashSliding: Bool,
                           into builders: inout [MotionPhase: RibbonBuilder]) {
        let segs = timeline.segments[ball]
        let tLimit = min(timeline.duration, timeline.pocketTime[ball] ?? .infinity)
        // The line is wider where the ball is faster, so a still frame shows speed. Half-width of the whole
        // ribbon (core and halo together) in metres: about 3 points on a phone at the slowest, 6 at a break.
        func half(_ speed: Double) -> Float { 0.013 + 0.0016 * Float(min(speed, 8)) }
        for seg in segs where seg.phase == .sliding || seg.phase == .rolling || seg.phase == .airborne {
            let tEnd = min(seg.t1, tLimit)
            guard tEnd > seg.t0 else { continue }
            var t = seg.t0
            var pts: [SIMD3<Float>] = [], times: [Double] = [], halves: [Float] = []
            // Each colour rides at its own height (rolling 3 mm above sliding) so overlapping paths never fight over depth.
            // A flight climbs with the ball: its lift is added to the ball's own height above the cloth at each point.
            let airborne = seg.phase == .airborne
            let lift: Float = airborne ? Self.airborneLift : (seg.phase == .rolling ? 0.0046 : 0.0016)
            func add(_ time: Double) {
                let k = seg.kinematics(at: time)
                let p = frame.world(k.position, height: lift + (airborne ? Float(k.height) : 0))
                // Points closer than 2 mm add nothing but a noisy ribbon direction; skip them (the last point always stays).
                if let last = pts.last, simd_distance(last, p) < 0.002, time < tEnd { return }
                pts.append(p); times.append(time); halves.append(half(k.velocity.length))
            }
            add(t)
            while t < tEnd {
                let speed = seg.kinematics(at: t).velocity.length
                // About a centimetre and a half between points, whatever the speed, capped at 50 ms for slow rolls.
                let dt = min(0.05, max(0.002, 0.015 / max(speed, 0.01)))
                t = min(tEnd, t + dt)
                add(t)
            }
            if airborne {
                // A flight is always dashed and white (the spec's airborne trail), so it never reads as either
                // phase on the cloth, with or without colour. The dash is measured along the path in three
                // dimensions, so a steep hop still gets even dashes.
                for dash in Self.dashes(pts, times: times, halves: halves, on: Self.airDash, off: Self.airGap) {
                    builders[seg.phase]?.addStrip(dash.pts, times: dash.times, halves: dash.halves)
                }
            } else if dashSliding && seg.phase == .sliding {
                // Differentiate Without Colour: sliding is dashed, rolling solid (the legend chip matches).
                for dash in Self.dashes(pts, times: times, halves: halves, on: Self.dashLength, off: Self.dashGap) {
                    builders[seg.phase]?.addStrip(dash.pts, times: dash.times, halves: dash.halves)
                }
            } else {
                builders[seg.phase]?.addStrip(pts, times: times, halves: halves)
            }
        }
    }

    /// A flat unit-radius ring (annulus) lying on the table; scaled per impact. UV v runs inner (0) to outer (1) edge.
    /// `arcs` above zero cuts it into that many arcs with equal gaps between them (the rim skip's broken ring): the
    /// circle is split into 2 * arcs equal parts and only every other part is filled. `segments` should be a multiple
    /// of 2 * arcs so every arc has the same number of pieces (72 and 12 give three each).
    private static func annulus(segments: Int, inner: Float, arcs: Int = 0) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for i in 0...segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            positions.append(SIMD3(cos(a), 0, sin(a))); uvs.append(SIMD2(0.5, 1))
            positions.append(SIMD3(cos(a) * inner, 0, sin(a) * inner)); uvs.append(SIMD2(0.5, 0))
        }
        for i in 0..<segments {
            // Which of the 2 * arcs parts this piece falls in; odd parts are the gaps.
            if arcs > 0, (i * 2 * arcs / segments) % 2 == 1 { continue }
            let k = UInt32(i * 2)
            indices += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
        }
        var d = MeshDescriptor(name: "ring")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    /// A flat cross lying on the table: two bars from -1 to 1 through the origin, along x and along z, each
    /// `halfWidth` wide either side (unit scale). UV v runs across each bar so the soft line picture puts its bright
    /// core down the middle.
    private static func cross(halfWidth w: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for along in [SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 0, 1)] {
            let across = SIMD3<Float>(-along.z, 0, along.x) * w
            let base = UInt32(positions.count)
            positions += [-along + across, -along - across, along + across, along - across]
            uvs += [SIMD2(0.5, 0), SIMD2(0.5, 1), SIMD2(0.5, 0), SIMD2(0.5, 1)]
            indices += [base, base + 1, base + 2, base + 1, base + 3, base + 2]
        }
        var d = MeshDescriptor(name: "cross")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    /// A flat line one unit long along +x from the origin, `halfWidth` metres either side, lying on the table.
    /// `dashes` above zero cuts it into that many dashes with equal gaps (2 * dashes - 1 equal parts, every other one
    /// drawn, so it starts and ends with a dash). UV v runs across.
    private static func strip(dashes: Int, halfWidth w: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        let parts = dashes > 0 ? 2 * dashes - 1 : 1
        for p in stride(from: 0, to: parts, by: dashes > 0 ? 2 : 1) {
            let x0 = Float(p) / Float(parts), x1 = Float(p + 1) / Float(parts)
            let base = UInt32(positions.count)
            positions += [SIMD3(x0, 0, w), SIMD3(x0, 0, -w), SIMD3(x1, 0, w), SIMD3(x1, 0, -w)]
            uvs += [SIMD2(0.5, 0), SIMD2(0.5, 1), SIMD2(0.5, 0), SIMD2(0.5, 1)]
            indices += [base, base + 1, base + 2, base + 1, base + 3, base + 2]
        }
        var d = MeshDescriptor(name: dashes > 0 ? "dashedLine" : "line")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    /// A flat arrow head lying on the table, tip along +x, base at the origin.
    private static func triangle(length: Float, halfWidth: Float) -> MeshResource {
        var d = MeshDescriptor(name: "head")
        d.positions = MeshBuffers.Positions([SIMD3(length, 0, 0), SIMD3(0, 0, halfWidth), SIMD3(0, 0, -halfWidth)])
        d.textureCoordinates = MeshBuffers.TextureCoordinates([SIMD2(0.5, 0.5), SIMD2(0.5, 0.5), SIMD2(0.5, 0.5)])
        d.primitives = .triangles([0, 1, 2])
        return try! MeshResource.generate(from: [d])
    }

    /// A unit-radius arc with an arrowhead, for the spin markers. The arc runs round the local +y axis through 288
    /// degrees, as p(a) = (cos a, 0, -sin a) for a from -sweep up to 0, so travelling along it (towards the head) is a
    /// right-handed turn about +y: lay local +y along a spin vector and the arrow turns the way the ball turns.
    /// The head sits at local (1, 0, 0) pointing along -z, the arc's direction of travel there.
    /// - flat: true makes a washer-like strip lying in the arc's own plane (the side-spin ring on the cloth); false
    ///   makes a belt whose width runs along the axis (the slip belt round the ball), with the head lying flat on
    ///   the belt, so with local +x pointing up the head lies level on top of the ball where the camera sees it.
    /// UV v runs across the strip (0 to 1) so the soft line picture puts its bright core down the middle.
    private static func spinArc(flat: Bool, halfWidth: Float, headLength: Float, headHalfWidth: Float) -> MeshResource {
        let segments = 56
        let sweep = Float.pi * 1.6
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for i in 0...segments {
            let a = -sweep + sweep * Float(i) / Float(segments)
            let c = SIMD3<Float>(cos(a), 0, -sin(a))
            let across = flat ? c : SIMD3<Float>(0, 1, 0)
            positions.append(c + across * halfWidth); uvs.append(SIMD2(0.5, 0))
            positions.append(c - across * halfWidth); uvs.append(SIMD2(0.5, 1))
        }
        for i in 0..<segments {
            let k = UInt32(i * 2)
            indices += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
        }
        // Arrowhead: base across the strip at the arc's end, tip ahead along the direction of travel. Its picture
        // coordinates sit on the line's bright core, so the head reads as solid.
        let base = UInt32(positions.count)
        let end = SIMD3<Float>(1, 0, 0)
        let across = flat ? end : SIMD3<Float>(0, 1, 0)
        positions += [end + across * headHalfWidth, end - across * headHalfWidth, SIMD3(1, 0, -headLength)]
        uvs += [SIMD2(0.5, 0.5), SIMD2(0.5, 0.5), SIMD2(0.5, 0.5)]
        indices += [base, base + 1, base + 2]
        var d = MeshDescriptor(name: flat ? "sideSpin" : "slipSpin")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    // MARK: Per frame

    /// Fade the layer with the melt, slide the trail pictures to the clock, expand the rings, steer the arrows and
    /// the aim line. `ballVisible` says which balls are currently shown (the coordinator decides that).
    /// Everything here is a function of (t, melt, timeline) only.
    func apply(time t: Double, melt: Double, aim: AimPreview?,
               timeline: Timeline, frame: TableFrame, ballVisible: [Bool]) {
        let R = frame.ballRadius
        let m = Float(melt)
        root.isEnabled = m > 0.002
        root.components.set(OpacityComponent(opacity: m))

        // Velocity arrows
        for b in 0..<arrows.count {
            let s = timeline.state(ball: b, at: t)
            let arrow = arrows[b]
            let speed = s.velocity.length
            let showArrow = ballVisible[b] && !s.pocketed && speed > 0.04 && m > 0.02
            arrow.root.isEnabled = showArrow
            if showArrow {
                let len = Float(min(0.8, 0.02 + 0.05 * speed))
                let dir = frame.direction(s.velocity.normalized)
                let yaw = -atan2(dir.z, dir.x)
                // Above the ball wherever it is: a flying ball's arrow flies with it (height is zero on the cloth).
                arrow.root.position = frame.world(s.position, height: R + 0.012 + Float(s.height))
                arrow.root.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
                arrow.shaft.scale = SIMD3(len, 1, 1)
                arrow.head.position = SIMD3(len + 0.012, 0, 0)
            }
            // Spin markers reuse the state just read, so the Lens still asks the timeline once per ball per frame.
            if b < spinMarkers.count {
                applySpin(ball: b, state: s, time: t, melt: m, timeline: timeline, frame: frame, visible: ballVisible[b])
            }
            // The dot on the cloth under a flying ball: full under a low hop, fading to a third as the ball climbs a
            // ball's diameter, so the gap between dot and ball reads as height.
            if b < dots.count {
                let dot = dots[b]
                let flying = ballVisible[b] && !s.pocketed && s.height >= Self.dotMinHeight && m > 0.02
                if flying {
                    let up = Float(min(1, s.height / (2 * Double(R))))
                    dot.isEnabled = true
                    dot.position = frame.world(s.position, height: 0.0012)
                    dot.components.set(OpacityComponent(opacity: 0.8 * (1 - 0.66 * up)))
                } else if dot.isEnabled {
                    dot.isEnabled = false
                }
            }
        }

        // Trails: slide each colour's picture so its "now" lines up with the clock. Vertex time u = tv / window;
        // the picture's head sits at headX, so sampling at u + (headX - t / window) puts a vertex recorded at time t
        // exactly on the head, older ones further down the fade, and later ones off the transparent end.
        let shift = Float(LensTextures.headX - t / LensTextures.ageWindow)
        for (phase, e) in trailEntities {
            guard var mat = trailMaterials[phase] else { continue }
            mat.textureCoordinateTransform = .init(offset: SIMD2(shift, 0), scale: SIMD2(1, 1), rotation: 0)
            e.model?.materials = [mat]
            trailOffsets[phase] = shift
        }

        // Rings: expand and fade for a fixed span of clock time after each impact. Held marks (a jam's cross, the throw
        // lines) keep their size, stay at their peak for the first three fifths of their span, then fade.
        for r in rings {
            let tau = t - r.time
            if m > 0.002, tau >= 0, tau <= r.span {
                let k = Float(tau / r.span)
                r.entity.isEnabled = true
                if r.grows {
                    let grow = r.radius * (1 + 1.8 * k)
                    r.entity.scale = SIMD3(grow, 1, grow)
                    r.entity.components.set(OpacityComponent(opacity: r.peak * (1 - k) * (1 - k)))
                } else {
                    let fade: Float = k < 0.6 ? 1 : 1 - (k - 0.6) / 0.4
                    r.entity.components.set(OpacityComponent(opacity: r.peak * fade))
                }
            } else if r.entity.isEnabled {
                r.entity.isEnabled = false
            }
        }

        // Aim line for the player's break.
        if let aim, m < 0.5 || aim.always {
            aimLine.isEnabled = true
            let dir = frame.direction(aim.direction)
            let yaw = -atan2(dir.z, dir.x)
            aimLine.position = frame.world(aim.from, height: R) + dir * Float(aim.length) * 0.5
            aimLine.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            aimLine.scale = SIMD3(Float(aim.length), 1, 1)
        } else {
            aimLine.isEnabled = false
        }
    }

    /// Poses and fades one ball's spin markers for clock `t`. A function of the clock and the recorded timeline only.
    private func applySpin(ball b: Int, state: BallState, time t: Double, melt m: Float,
                           timeline: Timeline, frame: TableFrame, visible: Bool) {
        let marker = spinMarkers[b]
        func hide() {
            if marker.slip.isEnabled { marker.slip.isEnabled = false }
            if marker.side.isEnabled { marker.side.isEnabled = false }
        }
        guard visible, m > 0.02 else { hide(); return }

        // A pocketed ball's recorded state freezes with zero velocity at the capture, which would read as pure slip.
        // Instead show the spin it carried into the pocket and fade it out over a short span of clock time, so the
        // marker leaves with the ball rather than popping.
        var s = state
        var fade = 1.0
        if s.pocketed, let tp = timeline.pocketTime[b] {
            fade = max(0, 1 - (t - tp) / Self.spinPocketFade)
            guard fade > 0 else { hide(); return }
            s = timeline.state(ball: b, at: max(0, tp - 1e-6))
        }

        let R = Double(frame.ballRadius)
        let Rf = frame.ballRadius
        let w = s.omega, v = s.velocity
        // Natural roll in the solver's convention (BallSegment, rolling phase): omega = (-vy / R, vx / R). The slip is
        // what is left of the horizontal spin after taking that away; zero for a cleanly rolling ball.
        let slipX = w.x + v.y / R, slipY = w.y - v.x / R
        let slipMag = (slipX * slipX + slipY * slipY).squareRoot()
        let slipOpacity = Self.spinOpacity(R * slipMag, Self.slipFade) * fade
        let lift = Float(s.height)

        if slipOpacity > 0.004 {
            let strength = Float(Self.smoothstep(Self.slipFade.mid, Self.slipFade.full, R * slipMag))
            // Table (x, y, up) maps to scene (x, up, -y) by a proper rotation, so a spin vector maps the same way.
            let axis = simd_normalize(SIMD3<Float>(Float(slipX), 0, -Float(slipY)))
            // Local frame of the belt: +y along the slip axis, +x straight up (so the arrowhead lies on top of the
            // ball, facing the camera), +z completing a right-handed set.
            let up = SIMD3<Float>(0, 1, 0)
            let basis = simd_float3x3(columns: (up, axis, simd_cross(up, axis)))
            let r = Rf * (1.30 + 0.10 * strength)
            marker.slip.isEnabled = true
            marker.slip.position = frame.world(s.position, height: Rf + lift)
            marker.slip.orientation = simd_quatf(basis)
            // The belt also grows wider (local y) with the amount, so a hard draw shot looks heavier than a trace.
            marker.slip.scale = SIMD3(r, r * (0.75 + 0.6 * strength), r)
            marker.slip.components.set(OpacityComponent(opacity: Float(slipOpacity)))
        } else if marker.slip.isEnabled {
            marker.slip.isEnabled = false
        }

        // Side spin (english): the vertical spin component. Positive is anticlockwise seen from above.
        let wz = w.z
        let sideAmount = R * abs(wz)
        let sideOpacity = Self.spinOpacity(sideAmount, Self.sideFade) * fade
        if sideOpacity > 0.004 {
            let strength = Float(Self.smoothstep(Self.sideFade.mid, Self.sideFade.full, sideAmount))
            let r = Rf * (1.55 + 0.15 * strength)
            marker.side.isEnabled = true
            marker.side.position = frame.world(s.position, height: 0.006 + lift)
            // The ring's arrow turns about local +y; for clockwise spin flip it upside down (half turn about x).
            marker.side.orientation = wz >= 0 ? simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
                                               : simd_quatf(angle: Float.pi, axis: SIMD3<Float>(1, 0, 0))
            marker.side.scale = SIMD3(repeating: r)
            marker.side.components.set(OpacityComponent(opacity: Float(sideOpacity)))
        } else if marker.side.isEnabled {
            marker.side.isEnabled = false
        }
    }

    // MARK: Self-check (launch with -lensSelfTest)

    /// A fingerprint of everything the Lens shows that depends on the clock: the trail picture offsets, every ring,
    /// every arrow and the layer's own opacity. Two calls with the same clock must give the same fingerprint.
    func fingerprint() -> UInt64 {
        var h = StableHasher()
        for phase in [MotionPhase.sliding, .rolling, .airborne] { h.combine(Double(trailOffsets[phase] ?? 0)) }
        // The dots under flying balls (the rings loop below covers the throw lines and the jam crosses too).
        for dot in dots {
            h.combine(dot.isEnabled ? 1 : 0)
            guard dot.isEnabled else { continue }
            h.combine(Double(dot.position.x)); h.combine(Double(dot.position.z))
            h.combine(Double(dot.components[OpacityComponent.self]?.opacity ?? -1))
        }
        for r in rings {
            // A hidden ring keeps its last size and opacity; they are not visible, so they are not part of the picture.
            h.combine(r.entity.isEnabled ? 1 : 0)
            guard r.entity.isEnabled else { continue }
            h.combine(Double(r.entity.scale.x))
            h.combine(Double(r.entity.components[OpacityComponent.self]?.opacity ?? -1))
        }
        for a in arrows {
            h.combine(a.root.isEnabled ? 1 : 0)
            guard a.root.isEnabled else { continue }
            h.combine(Double(a.root.position.x)); h.combine(Double(a.root.position.z))
            h.combine(Double(a.root.orientation.angle)); h.combine(Double(a.shaft.scale.x))
        }
        for marker in spinMarkers {
            for e in [marker.slip, marker.side] {
                h.combine(e.isEnabled ? 1 : 0)
                guard e.isEnabled else { continue }
                h.combine(Double(e.position.x)); h.combine(Double(e.position.z)); h.combine(Double(e.scale.x))
                h.combine(Double(e.orientation.vector.x)); h.combine(Double(e.orientation.vector.y))
                h.combine(Double(e.components[OpacityComponent.self]?.opacity ?? -1))
            }
        }
        h.combine(Double(root.components[OpacityComponent.self]?.opacity ?? -1))
        return h.value
    }
}
