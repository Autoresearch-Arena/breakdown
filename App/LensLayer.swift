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
// SRP/DRY check: Pass - Lens drawing only; coordinates come from TableFrame, colours from Theme, pictures from LensTextures.
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
    private var rings: [(entity: ModelEntity, event: LensEvent, radius: Float)] = []
    private let ringMesh = LensLayer.annulus(segments: 72, inner: 0.62)

    /// One entity per trail colour, each holding every ball's path of that colour.
    private var trailEntities: [MotionPhase: ModelEntity] = [:]
    private var trailMaterials: [MotionPhase: UnlitMaterial] = [:]
    private var trailOffsets: [MotionPhase: Float] = [:]
    private var ringMaterials: [LensEventKind: UnlitMaterial] = [:]
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
        let phaseColours: [MotionPhase: (Double, Double, Double)] = [.sliding: amber, .rolling: cyan]
        for (phase, c) in phaseColours {
            if let tex = LensTextures.trail(color: c, haloGain: haloGain, brightness: { Self.trailBrightness(age: $0) }, width: { Self.trailWidth(age: $0) }) {
                trailMaterials[phase] = Self.glow(tex)
            }
        }
        // Rings and arrows share one soft line picture, tinted per use.
        if let ringTex = LensTextures.softLine(peak: 0.85, haloGain: haloGain) {
            func ring(_ r: Double, _ g: Double, _ b: Double) -> UnlitMaterial { Self.glow(ringTex, tint: rgba(r, g, b)) }
            ringMaterials = [.ballBall: ring(1.0, 0.97, 0.80), .cushion: ring(0.45, 0.70, 1.0),
                             .pocket: ring(1.0, 0.82, 0.25), .cueStrike: ring(1.0, 0.97, 0.80), .phaseTransition: ring(1, 1, 1)]
        }
        if let lineTex = LensTextures.softLine(peak: 0.5, haloGain: haloGain) {
            arrowGlowMaterial = Self.glow(lineTex, tint: rgba(1.0, 0.93, 0.55))
            // Slip is sliding, so it wears the sliding amber; side spin wears the cushion-ring blue used above.
            slipMaterial = Self.glow(lineTex, tint: rgba(amber.0, amber.1, amber.2))
            sideMaterial = Self.glow(lineTex, tint: rgba(0.45, 0.70, 1.0))
        }
        var core = UnlitMaterial(color: rgba(1.0, 0.96, 0.78))
        core.faceCulling = .none
        arrowMaterial = core

        root.addChild(gridEntity)
        root.addChild(trailRoot)
        root.addChild(ringRoot)
        root.addChild(spinRoot)
        root.addChild(arrowRoot)
        root.addChild(aimLine)
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

        // Grid under the Lens, with the cushion line, the rail outline and the pockets drawn into it.
        let L = frame.length, W = frame.width
        let pockets = zip(table.pockets, table.pocketCaptureRadius).map { (x: $0.0.x, y: $0.0.y, radius: $0.1) }
        if let tex = BallTextures.gridTexture(length: Double(L), width: Double(W), pockets: pockets) {
            let m = Float(BallTextures.gridMargin)
            gridEntity.model = ModelComponent(mesh: .generatePlane(width: L + 2 * m, depth: W + 2 * m), materials: [Self.glow(tex)])
            gridEntity.position = SIMD3(0, 0.0004, 0)
            gridEntity.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
        }

        // Aim line for the player's own break.
        aimLine.model = ModelComponent(mesh: .generateBox(width: 1, height: 0.002, depth: 0.004),
                                       materials: [UnlitMaterial(color: rgba(1, 1, 1, 0.8))])
        aimLine.isEnabled = false
    }

    // MARK: Timeline-dependent parts

    /// Rebuild the trails and rings for a new recorded shot.
    func rebuild(timeline: Timeline, frame: TableFrame) {
        for child in Array(trailRoot.children) { child.removeFromParent() }
        for child in Array(ringRoot.children) { child.removeFromParent() }
        trailEntities = [:]; trailOffsets = [:]; rings = []

        // Gather every ball's ribbons into one mesh per colour.
        var builders: [MotionPhase: RibbonBuilder] = [.sliding: RibbonBuilder(), .rolling: RibbonBuilder()]
        for b in 0..<timeline.ballCount { addTrails(for: b, timeline: timeline, frame: frame, into: &builders) }
        for (phase, builder) in builders {
            guard let mesh = builder.mesh(), let mat = trailMaterials[phase] else { continue }
            let e = ModelEntity(mesh: mesh, materials: [mat])
            e.components.set(ModelSortGroupComponent(group: sortGroup, order: phase == .sliding ? 10 : 11))
            trailRoot.addChild(e)
            trailEntities[phase] = e
        }

        for e in timeline.events where e.kind == .ballBall || e.kind == .cushion || e.kind == .pocket {
            let strength = Float(min(1.5, max(0.1, e.normalImpulse)))
            let radius = 0.022 + 0.034 * strength
            guard let mat = ringMaterials[e.kind] else { continue }
            let ring = ModelEntity(mesh: ringMesh, materials: [mat])
            ring.scale = SIMD3(radius, 1, radius)
            ring.position = frame.world(e.point, height: 0.008)
            ring.isEnabled = false
            ring.components.set(OpacityComponent(opacity: 0))
            ring.components.set(ModelSortGroupComponent(group: sortGroup, order: 20))
            ringRoot.addChild(ring)
            rings.append((ring, e, radius))
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

    private func addTrails(for ball: Int, timeline: Timeline, frame: TableFrame, into builders: inout [MotionPhase: RibbonBuilder]) {
        let segs = timeline.segments[ball]
        let tLimit = min(timeline.duration, timeline.pocketTime[ball] ?? .infinity)
        // The line is wider where the ball is faster, so a still frame shows speed. Half-width of the whole
        // ribbon (core and halo together) in metres: about 3 points on a phone at the slowest, 6 at a break.
        func half(_ speed: Double) -> Float { 0.013 + 0.0016 * Float(min(speed, 8)) }
        for seg in segs where seg.phase == .sliding || seg.phase == .rolling {
            let tEnd = min(seg.t1, tLimit)
            guard tEnd > seg.t0 else { continue }
            var t = seg.t0
            var pts: [SIMD3<Float>] = [], times: [Double] = [], halves: [Float] = []
            // Each colour rides at its own height (rolling 3 mm above sliding) so overlapping paths never fight over depth.
            let lift: Float = seg.phase == .rolling ? 0.0046 : 0.0016
            func add(_ time: Double) {
                let k = seg.kinematics(at: time)
                let p = frame.world(k.position, height: lift)
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
            builders[seg.phase]?.addStrip(pts, times: times, halves: halves)
        }
    }

    /// A flat unit-radius ring (annulus) lying on the table; scaled per impact. UV v runs inner (0) to outer (1) edge.
    private static func annulus(segments: Int, inner: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for i in 0...segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            positions.append(SIMD3(cos(a), 0, sin(a))); uvs.append(SIMD2(0.5, 1))
            positions.append(SIMD3(cos(a) * inner, 0, sin(a) * inner)); uvs.append(SIMD2(0.5, 0))
        }
        for i in 0..<segments {
            let k = UInt32(i * 2)
            indices += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
        }
        var d = MeshDescriptor(name: "ring")
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
                arrow.root.position = frame.world(s.position, height: R + 0.012)
                arrow.root.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
                arrow.shaft.scale = SIMD3(len, 1, 1)
                arrow.head.position = SIMD3(len + 0.012, 0, 0)
            }
            // Spin markers reuse the state just read, so the Lens still asks the timeline once per ball per frame.
            if b < spinMarkers.count {
                applySpin(ball: b, state: s, time: t, melt: m, timeline: timeline, frame: frame, visible: ballVisible[b])
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

        // Rings: expand and fade for a fixed span of clock time after each impact.
        let span = Self.ringSpan
        for r in rings {
            let tau = t - r.event.time
            if m > 0.002, tau >= 0, tau <= span {
                let k = Float(tau / span)
                r.entity.isEnabled = true
                let grow = r.radius * (1 + 1.8 * k)
                r.entity.scale = SIMD3(grow, 1, grow)
                r.entity.components.set(OpacityComponent(opacity: 0.85 * (1 - k) * (1 - k)))
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
        for phase in [MotionPhase.sliding, .rolling] { h.combine(Double(trailOffsets[phase] ?? 0)) }
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
