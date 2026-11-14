// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: The cold Physics Lens layer. Owns the grid under the Lens, the glowing speed-wide trail ribbons coloured by
//          motion phase, the impact rings, the velocity arrows, and the player's aim line, plus their materials and
//          their per-frame reveal logic (trail pieces appear as the clock passes them, rings expand and fade, arrows
//          follow the balls, the whole layer fades with the melt value). Trail, ring and arrow meshes are built once
//          per recorded timeline and revealed by time, so scrubbing in either direction is exact.
//          Anything about how the Lens LOOKS or when its parts appear belongs here and only here.
//          Does NOT belong here: the warm table and balls (TableBuilder.swift), the camera (TableCamera.swift), or
//          moving the balls themselves (TableScene.apply). The coordinator hands this layer the clock, the melt, the
//          timeline, the frame and which balls are visible; the layer never reads or changes the model.
//          Split out of TableScene.swift in package 0 of the glow-up plan with no behaviour change.
// SRP/DRY check: Pass - Lens drawing only; coordinates come from TableFrame, colours from Theme and rgba.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
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
    /// Parent of every Lens entity; fades as a whole with the melt value.
    let root = Entity()
    private let trailRoot = Entity()
    private let ringRoot = Entity()
    private let arrowRoot = Entity()
    private let gridEntity = ModelEntity()
    private let aimLine = ModelEntity()
    private var arrows: [(root: Entity, shaft: Entity, head: Entity)] = []
    private var trails: [[(entity: ModelEntity, tEnd: Double)]] = []
    private var trailShown: [Int] = []
    private var rings: [(entity: ModelEntity, event: LensEvent, radius: Float)] = []
    private let ringMesh = LensLayer.annulus(segments: 64, inner: 0.82)

    private let trailMaterials: [MotionPhase: UnlitMaterial]
    private let haloMaterials: [MotionPhase: UnlitMaterial]
    private let ringMaterials: [LensEventKind: UnlitMaterial]
    private let arrowMaterial: UnlitMaterial

    init() {
        func unlit(_ c: PlatformColor) -> UnlitMaterial {
            var m = UnlitMaterial(color: c)
            m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
            m.faceCulling = .none
            return m
        }
        let amber = Theme.amberRGB, cyan = Theme.cyanRGB
        trailMaterials = [.sliding: unlit(rgba(amber.0, amber.1, amber.2, 0.95)), .rolling: unlit(rgba(cyan.0, cyan.1, cyan.2, 0.95)),
                          .spinning: unlit(rgba(1.0, 0.35, 0.85, 0.95)), .stationary: unlit(rgba(1, 1, 1, 0.5))]
        // Faint, wide strips under each trail piece. Decoration only: the width of the bright core is the data.
        haloMaterials = [.sliding: unlit(rgba(amber.0, amber.1, amber.2, 0.20)), .rolling: unlit(rgba(cyan.0, cyan.1, cyan.2, 0.20)),
                         .spinning: unlit(rgba(1.0, 0.35, 0.85, 0.20)), .stationary: unlit(rgba(1, 1, 1, 0.08))]
        ringMaterials = [.ballBall: unlit(rgba(1.0, 0.97, 0.80, 0.95)), .cushion: unlit(rgba(0.45, 0.65, 1.0, 0.95)),
                         .pocket: unlit(rgba(1.0, 0.82, 0.25, 0.95)), .cueStrike: unlit(rgba(1.0, 0.97, 0.80, 0.95)),
                         .phaseTransition: unlit(rgba(1, 1, 1, 0.5))]
        arrowMaterial = unlit(rgba(1.0, 0.93, 0.55, 1.0))
        root.addChild(gridEntity)
        root.addChild(trailRoot)
        root.addChild(ringRoot)
        root.addChild(arrowRoot)
        root.addChild(aimLine)
    }

    // MARK: Static parts

    /// The shapes that do not depend on the recorded shot: one velocity arrow per ball, the grid, the aim line.
    func buildStatic(ballCount: Int, frame: TableFrame) {
        for _ in 0..<ballCount {
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
        let L = frame.length, W = frame.width
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
    }

    // MARK: Timeline-dependent parts

    /// Rebuild the trails and rings for a new recorded shot.
    func rebuild(timeline: Timeline, frame: TableFrame) {
        for child in Array(trailRoot.children) { child.removeFromParent() }
        for child in Array(ringRoot.children) { child.removeFromParent() }
        trails = []; trailShown = []; rings = []

        for b in 0..<timeline.ballCount { buildTrails(for: b, timeline: timeline, frame: frame) }
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
    }

    private func buildTrails(for ball: Int, timeline: Timeline, frame: TableFrame) {
        var chunks: [(ModelEntity, Double)] = []
        let segs = timeline.segments[ball]
        let tLimit = min(timeline.duration, timeline.pocketTime[ball] ?? .infinity)
        // The bright core is the data: it is wider where the ball is faster, so a still frame shows the speed.
        func coreHalf(_ speed: Double) -> Float { 0.0022 + 0.0007 * Float(min(speed, 8)) }
        for seg in segs where seg.phase == .sliding || seg.phase == .rolling {
            let tEnd = min(seg.t1, tLimit)
            guard tEnd > seg.t0 else { continue }
            var t = seg.t0
            var pts: [SIMD3<Float>] = [frame.world(seg.kinematics(at: t).position, height: 0.0016)]
            var halves: [Float] = [coreHalf(seg.kinematics(at: t).velocity.length)]
            while t < tEnd {
                let speed = seg.kinematics(at: t).velocity.length
                let dt = min(0.05, max(0.002, 0.015 / max(speed, 0.01)))
                t = min(tEnd, t + dt)
                pts.append(frame.world(seg.kinematics(at: t).position, height: 0.0016))
                halves.append(coreHalf(seg.kinematics(at: t).velocity.length))
                if pts.count >= 5 || t >= tEnd {
                    if let mesh = ribbon(pts, halves: halves), let mat = trailMaterials[seg.phase] {
                        let e = ModelEntity(mesh: mesh, materials: [mat])
                        e.isEnabled = false
                        // The glow strip is a child, so it appears and disappears with its trail piece. It sits a hair
                        // lower so the bright core draws over it.
                        if let haloMesh = ribbon(pts, halves: halves.map { $0 * 2.8 }), let haloMat = haloMaterials[seg.phase] {
                            let halo = ModelEntity(mesh: haloMesh, materials: [haloMat])
                            halo.position = SIMD3(0, -0.0003, 0)
                            e.addChild(halo)
                        }
                        trailRoot.addChild(e)
                        chunks.append((e, t))
                    }
                    pts = [pts[pts.count - 1]]
                    halves = [halves[halves.count - 1]]
                }
            }
        }
        trails.append(chunks)
        trailShown.append(0)
    }

    /// A flat ribbon along a short polyline, lying on the table, with its own half-width at each point.
    private func ribbon(_ pts: [SIMD3<Float>], halves: [Float]) -> MeshResource? {
        guard pts.count >= 2, halves.count == pts.count else { return nil }
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for (i, p) in pts.enumerated() {
            let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
            var d = b - a
            d.y = 0
            let len = simd_length(d)
            let dir = len > 1e-9 ? d / len : SIMD3<Float>(1, 0, 0)
            let side = SIMD3<Float>(-dir.z, 0, dir.x) * halves[i]
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

    /// Fade the layer with the melt, reveal trails and rings for the clock, steer the arrows and the aim line.
    /// `ballVisible` says which balls are currently shown (the coordinator decides that), so their arrows hide too.
    func apply(time t: Double, melt: Double, rate: Double, aim: AimPreview?,
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
}
