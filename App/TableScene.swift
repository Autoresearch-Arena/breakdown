// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The renderer. Builds the warm table (felt, wooden rails, cushions, pockets, lit balls) and the cold
//          Physics Lens layer (grid, glowing trails coloured by motion phase, velocity arrows, impact rings)
//          from a recorded timeline, then each frame places everything for the playback clock and blends warm to
//          cold with the melt value. RealityKit physics is not used: every transform comes from the timeline.
//          Lens meshes are built once per timeline and revealed by time, so scrubbing in either direction is exact.
// SRP/DRY check: Pass - rendering only; it reads the model and timeline and never changes them.
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import RealityKit
import simd

@MainActor
final class TableScene {
    let root = Entity()
    private let cameraRig = Entity()
    private let tableGroup = Entity()
    private let lensRoot = Entity()
    private let trailRoot = Entity()
    private let ringRoot = Entity()
    private let arrowRoot = Entity()
    private let gridEntity = ModelEntity()
    private let aimLine = ModelEntity()
    private var balls: [Entity] = []
    private var bodies: [ModelEntity] = []
    private var markers: [ModelEntity] = []
    private var arrows: [(root: Entity, shaft: Entity, head: Entity)] = []
    private var trails: [[(entity: ModelEntity, tEnd: Double)]] = []
    private var trailShown: [Int] = []
    private var rings: [(entity: ModelEntity, event: LensEvent, radius: Float)] = []
    private let ringMesh = TableScene.annulus(segments: 64, inner: 0.82)
    private var frame: TableFrame
    private var timeline: Timeline
    private var loadedVersion = -1
    var subscriptions: [EventSubscription] = []

    private let trailMaterials: [MotionPhase: UnlitMaterial]
    private let ringMaterials: [LensEventKind: UnlitMaterial]
    private let arrowMaterial: UnlitMaterial

    init(timeline: Timeline) {
        self.timeline = timeline
        frame = TableFrame(timeline.table)
        func unlit(_ c: PlatformColor) -> UnlitMaterial {
            var m = UnlitMaterial(color: c)
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            m.faceCulling = .none
            return m
        }
        trailMaterials = [.sliding: unlit(rgba(1.0, 0.58, 0.16, 0.95)), .rolling: unlit(rgba(0.25, 0.92, 1.0, 0.95)),
                          .spinning: unlit(rgba(1.0, 0.35, 0.85, 0.95)), .stationary: unlit(rgba(1, 1, 1, 0.5))]
        ringMaterials = [.ballBall: unlit(rgba(1.0, 0.97, 0.80, 0.95)), .cushion: unlit(rgba(0.45, 0.65, 1.0, 0.95)),
                         .pocket: unlit(rgba(1.0, 0.82, 0.25, 0.95)), .cueStrike: unlit(rgba(1.0, 0.97, 0.80, 0.95)),
                         .phaseTransition: unlit(rgba(1, 1, 1, 0.5))]
        arrowMaterial = unlit(rgba(1.0, 0.93, 0.55, 1.0))
        buildStatic()
    }

    // MARK: Static scene

    private func buildStatic() {
        root.addChild(tableGroup)
        root.addChild(lensRoot)
        lensRoot.addChild(gridEntity)
        lensRoot.addChild(trailRoot)
        lensRoot.addChild(ringRoot)
        lensRoot.addChild(arrowRoot)
        lensRoot.addChild(aimLine)
        root.addChild(cameraRig)

        let L = frame.length, W = frame.width, R = frame.ballRadius
        func pbr(_ c: PlatformColor, rough: Float, metal: Float = 0) -> PhysicallyBasedMaterial {
            var m = PhysicallyBasedMaterial()
            m.baseColor = .init(tint: c)
            m.roughness = .init(floatLiteral: rough)
            m.metallic = .init(floatLiteral: metal)
            return m
        }
        let feltMat = pbr(rgba(0.04, 0.36, 0.33), rough: 0.96)
        let woodMat = pbr(rgba(0.30, 0.15, 0.08), rough: 0.45)
        let cushionMat = pbr(rgba(0.03, 0.30, 0.27), rough: 0.9)
        let pocketMat = UnlitMaterial(color: rgba(0.01, 0.01, 0.015))

        // Felt bed under everything, a little larger than the playing surface.
        let felt = ModelEntity(mesh: .generatePlane(width: L + 0.5, depth: W + 0.5), materials: [feltMat])
        felt.position = SIMD3(0, -0.002, 0)
        tableGroup.addChild(felt)

        // Rails and cushions are built in segments that match the cushion ranges the solver uses, leaving the
        // pocket gaps open. Segments are listed along each side as (start, end) in table coordinates.
        let cg: Float = 0.09, sg: Float = 0.075
        let longSegs: [(Float, Float)] = [(cg, L * 0.5 - sg), (L * 0.5 + sg, L - cg)]
        let shortSegs: [(Float, Float)] = [(cg, W - cg)]
        let railDepth: Float = 0.16, railHeight: Float = 0.07, cushionDepth: Float = 0.04, cushionHeight: Float = 0.032
        func addSide(segs: [(Float, Float)], alongX: Bool, atFar: Bool) {
            for (a, b) in segs {
                let len = b - a
                let mid = (a + b) * 0.5
                // Cushion strip: its face lies on the playing-surface edge, body outside.
                let cs = ModelEntity(mesh: .generateBox(size: alongX ? SIMD3(len, cushionHeight, cushionDepth) : SIMD3(cushionDepth, cushionHeight, len)), materials: [cushionMat])
                let rs = ModelEntity(mesh: .generateBox(size: alongX ? SIMD3(len, railHeight, railDepth) : SIMD3(railDepth, railHeight, len)), materials: [woodMat])
                let cOff = cushionDepth * 0.5, rOff = cushionDepth + railDepth * 0.5
                if alongX {
                    // Long sides run along x; far side is table y = W (world z = -W/2).
                    let z = atFar ? -(W * 0.5) : (W * 0.5)
                    let sign: Float = atFar ? -1 : 1
                    cs.position = SIMD3(mid - L * 0.5, cushionHeight * 0.5, z + sign * cOff)
                    rs.position = SIMD3(mid - L * 0.5, railHeight * 0.5, z + sign * rOff)
                } else {
                    let x = atFar ? (L * 0.5) : -(L * 0.5)
                    let sign: Float = atFar ? 1 : -1
                    // table y runs to world -z
                    cs.position = SIMD3(x + sign * cOff, cushionHeight * 0.5, -(mid - W * 0.5))
                    rs.position = SIMD3(x + sign * rOff, railHeight * 0.5, -(mid - W * 0.5))
                }
                tableGroup.addChild(cs); tableGroup.addChild(rs)
            }
        }
        addSide(segs: longSegs, alongX: true, atFar: false)
        addSide(segs: longSegs, alongX: true, atFar: true)
        addSide(segs: shortSegs, alongX: false, atFar: false)
        addSide(segs: shortSegs, alongX: false, atFar: true)

        // Wooden corner blocks outside each corner pocket, and dark pocket discs at the pocket points.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let side: Float = cushionDepth + railDepth
                let block = ModelEntity(mesh: .generateBox(size: SIMD3(side, railHeight, side)), materials: [woodMat])
                block.position = SIMD3(sx * (L * 0.5 + side * 0.5), railHeight * 0.5, sz * (W * 0.5 + side * 0.5))
                tableGroup.addChild(block)
            }
        }
        for (k, p) in timeline.table.pockets.enumerated() {
            let radius: Float = k < 4 ? 0.088 : 0.07
            let disc = ModelEntity(mesh: .generateCylinder(height: 0.002, radius: radius), materials: [pocketMat])
            disc.position = frame.world(p, height: 0.001)
            tableGroup.addChild(disc)
        }

        // Balls.
        for n in 0..<timeline.ballCount {
            let ball = Entity()
            var m = PhysicallyBasedMaterial()
            if let tex = BallTextures.ballTexture(number: n) { m.baseColor = .init(texture: .init(tex)) }
            m.roughness = .init(floatLiteral: 0.14)
            m.clearcoat = .init(floatLiteral: 1.0)
            m.clearcoatRoughness = .init(floatLiteral: 0.05)
            let body = ModelEntity(mesh: .generateSphere(radius: R), materials: [m])
            body.components.set(OpacityComponent(opacity: 1))
            ball.addChild(body)
            // A bright pin at one pole so spin reads clearly in the Lens.
            let marker = ModelEntity(mesh: .generateSphere(radius: R * 0.14), materials: [UnlitMaterial(color: rgba(1, 1, 1))])
            marker.position = SIMD3(R * 0.97, 0, 0)
            marker.components.set(OpacityComponent(opacity: 0))
            ball.addChild(marker)
            root.addChild(ball)
            balls.append(ball); bodies.append(body); markers.append(marker)

            let arrow = Entity()
            let shaft = ModelEntity(mesh: .generateBox(width: 1, height: 0.003, depth: 0.007), materials: [arrowMaterial])
            let shaftHolder = Entity()
            shaft.position = SIMD3(0.5, 0, 0)
            shaftHolder.addChild(shaft)
            let head = ModelEntity(mesh: .generateCone(height: 0.045, radius: 0.016), materials: [arrowMaterial])
            head.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3(0, 0, 1))
            let headHolder = Entity()
            headHolder.addChild(head)
            arrow.addChild(shaftHolder); arrow.addChild(headHolder)
            arrowRoot.addChild(arrow)
            arrows.append((arrow, shaftHolder, headHolder))
        }

        // Grid under the Lens.
        if let tex = BallTextures.gridTexture(length: Double(L), width: Double(W)) {
            var m = UnlitMaterial()
            m.color = .init(tint: .white, texture: .init(tex))
            // Opaque so it draws before the transparent trails and rings; fading comes from the opacity component.
            gridEntity.model = ModelComponent(mesh: .generatePlane(width: L + 0.4, depth: W + 0.4), materials: [m])
            gridEntity.position = SIMD3(0, 0.0004, 0)
        }

        // Aim line for the player's own break.
        aimLine.model = ModelComponent(mesh: .generateBox(width: 1, height: 0.002, depth: 0.004),
                                       materials: [UnlitMaterial(color: rgba(1, 1, 1, 0.8))])
        aimLine.isEnabled = false

        // Lights: a key with shadows and a cool fill. Without image-based light the fill keeps shadows readable.
        let key = Entity()
        let keyLight = DirectionalLightComponent(color: .white, intensity: 2600, isRealWorldProxy: false)
        key.components.set(keyLight)
        key.components.set(DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 1.0))
        key.look(at: .zero, from: SIMD3(-0.8, 3.0, 1.2), relativeTo: nil)
        root.addChild(key)
        let fill = Entity()
        fill.components.set(DirectionalLightComponent(color: PlatformColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 1), intensity: 900, isRealWorldProxy: false))
        fill.look(at: .zero, from: SIMD3(1.5, 2.0, -1.5), relativeTo: nil)
        root.addChild(fill)

        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 45
        camera.camera.near = 0.05
        camera.camera.far = 40
        cameraRig.addChild(camera)
        cameraEntity = camera
    }

    private(set) var cameraEntity: PerspectiveCamera?

    // MARK: Timeline-dependent layer

    /// Rebuild the trails, rings and arrows for a new recorded shot.
    func load(_ timeline: Timeline, version: Int) {
        guard version != loadedVersion else { return }
        loadedVersion = version
        self.timeline = timeline
        frame = TableFrame(timeline.table)
        for child in Array(trailRoot.children) { child.removeFromParent() }
        for child in Array(ringRoot.children) { child.removeFromParent() }
        trails = []; trailShown = []; rings = []

        for b in 0..<timeline.ballCount { buildTrails(for: b) }
        for e in timeline.events where e.kind == .ballBall || e.kind == .cushion || e.kind == .pocket {
            let strength = Float(min(1.5, max(0.1, e.normalImpulse)))
            let radius = 0.03 + 0.05 * strength
            guard let mat = ringMaterials[e.kind] else { continue }
            let ring = ModelEntity(mesh: ringMesh, materials: [mat])
            ring.scale = SIMD3(radius, 1, radius)
            ring.position = frame.world(e.point, height: 0.003)
            ring.isEnabled = false
            ring.components.set(OpacityComponent(opacity: 0))
            ringRoot.addChild(ring)
            rings.append((ring, e, radius))
        }
        for b in 0..<balls.count {
            balls[b].isEnabled = true
        }
    }

    private func buildTrails(for ball: Int) {
        var chunks: [(ModelEntity, Double)] = []
        let segs = timeline.segments[ball]
        let tLimit = min(timeline.duration, timeline.pocketTime[ball] ?? .infinity)
        let half: Float = 0.0035
        for seg in segs where seg.phase == .sliding || seg.phase == .rolling {
            let tEnd = min(seg.t1, tLimit)
            guard tEnd > seg.t0 else { continue }
            var t = seg.t0
            var pts: [SIMD3<Float>] = [frame.world(seg.kinematics(at: t).position, height: 0.0016)]
            while t < tEnd {
                let speed = seg.kinematics(at: t).velocity.length
                let dt = min(0.05, max(0.002, 0.015 / max(speed, 0.01)))
                t = min(tEnd, t + dt)
                pts.append(frame.world(seg.kinematics(at: t).position, height: 0.0016))
                if pts.count >= 5 || t >= tEnd {
                    if let mesh = ribbon(pts, half: half), let mat = trailMaterials[seg.phase] {
                        let e = ModelEntity(mesh: mesh, materials: [mat])
                        e.isEnabled = false
                        trailRoot.addChild(e)
                        chunks.append((e, t))
                    }
                    pts = [pts[pts.count - 1]]
                }
            }
        }
        trails.append(chunks)
        trailShown.append(0)
    }

    /// A flat ribbon along a short polyline, lying on the table.
    private func ribbon(_ pts: [SIMD3<Float>], half: Float) -> MeshResource? {
        guard pts.count >= 2 else { return nil }
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for (i, p) in pts.enumerated() {
            let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
            var d = b - a
            d.y = 0
            let len = simd_length(d)
            let dir = len > 1e-9 ? d / len : SIMD3<Float>(1, 0, 0)
            let side = SIMD3<Float>(-dir.z, 0, dir.x) * half
            positions.append(p + side); positions.append(p - side)
        }
        for i in 0..<(pts.count - 1) {
            let a = UInt32(i * 2)
            indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
        }
        var d = MeshDescriptor(name: "trail")
        d.positions = MeshBuffers.Positions(positions)
        d.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [d])
    }

    /// A flat unit-radius ring (annulus) lying on the table; scaled per impact.
    private static func annulus(segments: Int, inner: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for i in 0...segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            positions.append(SIMD3(cos(a), 0, sin(a)))
            positions.append(SIMD3(cos(a) * inner, 0, sin(a) * inner))
        }
        for i in 0..<segments {
            let k = UInt32(i * 2)
            indices += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
        }
        var d = MeshDescriptor(name: "ring")
        d.positions = MeshBuffers.Positions(positions)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    // MARK: Per frame

    func apply(time t: Double, melt: Double, rate: Double, aim: AimPreview?) {
        let R = frame.ballRadius
        let m = Float(melt)
        lensRoot.isEnabled = m > 0.002
        lensRoot.components.set(OpacityComponent(opacity: m))
        let tableOpacity = max(0, 1 - Float(melt) * 1.15)
        tableGroup.components.set(OpacityComponent(opacity: tableOpacity))
        tableGroup.isEnabled = tableOpacity > 0.01

        for b in 0..<balls.count {
            let s = timeline.state(ball: b, at: t)
            var pos = frame.world(s.position, height: R)
            var scale: Float = 1
            var visible = true
            if s.pocketed, let tp = timeline.pocketTime[b] {
                let k = Float(min(1, (t - tp) / 0.22))
                pos.y -= 0.09 * k
                scale = 1 - 0.7 * k
                visible = (t - tp) < 0.35
            }
            balls[b].isEnabled = visible
            balls[b].position = pos
            balls[b].orientation = frame.orientation(s.orientation)
            balls[b].scale = SIMD3(repeating: scale)
            bodies[b].components.set(OpacityComponent(opacity: 1 - 0.55 * m))
            markers[b].components.set(OpacityComponent(opacity: m))

            // Velocity arrow
            let arrow = arrows[b]
            let speed = s.velocity.length
            let showArrow = visible && !s.pocketed && speed > 0.04 && m > 0.02
            arrow.root.isEnabled = showArrow
            if showArrow {
                let len = Float(min(0.8, 0.02 + 0.05 * speed))
                let dir = frame.direction(s.velocity.normalized)
                let yaw = -atan2(dir.z, dir.x)
                arrow.root.position = frame.world(s.position, height: R + 0.012)
                arrow.root.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
                arrow.shaft.scale = SIMD3(len, 1, 1)
                arrow.head.position = SIMD3(len + 0.02, 0, 0)
            }
        }

        // Trails: reveal chunks whose end time the clock has passed.
        if m > 0.002 {
            for b in 0..<trails.count {
                let chunks = trails[b]
                var target = trailShown[b]
                while target < chunks.count, chunks[target].tEnd <= t { target += 1 }
                while target > 0, chunks[target - 1].tEnd > t { target -= 1 }
                let old = trailShown[b]
                if target != old {
                    if target > old { for i in old..<target { chunks[i].entity.isEnabled = true } }
                    else { for i in target..<old { chunks[i].entity.isEnabled = false } }
                    trailShown[b] = target
                }
            }
        }

        // Rings: expand and fade for a moment after each impact. The span stretches with slow motion so a ring
        // is visible for about the same real time at any speed.
        let span = 0.55 * min(1.0, max(0.1, rate))
        for r in rings {
            let tau = t - r.event.time
            if m > 0.002, tau >= 0, tau <= span {
                let k = Float(tau / span)
                r.entity.isEnabled = true
                let grow = r.radius * (1 + 4.0 * k)
                r.entity.scale = SIMD3(grow, 1, grow)
                r.entity.components.set(OpacityComponent(opacity: (1 - k) * (1 - k)))
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

    // MARK: Camera

    /// Frames the whole table and swings from a low three-quarter view to straight down as the Lens melts in.
    func updateCamera(melt: Double, viewSize: CGSize, bottomInset: Double) {
        guard let cam = cameraEntity else { return }
        let aspect = Float(max(0.3, viewSize.width / max(1, viewSize.height)))
        let portrait = aspect < 1
        let L = frame.length, W = frame.width
        // Portrait puts the long side up the screen: the camera moves round to the short edge.
        let phi: Float = portrait ? .pi / 2 : 0
        let halfH = tan(Float(45) * .pi / 360)
        let usable = Float(max(0.5, 1 - bottomInset))
        let horizHalf = (portrait ? W : L) * 0.5 + 0.26
        let vertHalf = (portrait ? L : W) * 0.5 + 0.22
        let dTop = max(horizHalf / (aspect * halfH), vertHalf / (usable * halfH))
        let m = Float(melt)
        let ease = m * m * (3 - 2 * m)
        let elevDeg: Float = 48 + 41 * ease
        let elev = elevDeg * .pi / 180
        let dist = dTop * (1.08 - 0.06 * ease)
        let horizontal = SIMD3<Float>(sin(phi), 0, cos(phi))
        // Push the table up the screen so it clears the control bar: a fraction of the view height, converted
        // to ground distance (foreshortened by the viewing angle).
        let shift = Float(bottomInset) * 0.5 * 2 * halfH * dist / max(0.3, sin(elev))
        let target = horizontal * shift
        let pos = target + (horizontal * cos(elev) + SIMD3(0, sin(elev), 0)) * dist
        cam.look(at: target, from: pos, upVector: SIMD3(0, 1, 0), relativeTo: nil)
    }
}

struct AimPreview {
    var from: Vec2
    var direction: Vec2
    var length: Double
    var always: Bool
}
