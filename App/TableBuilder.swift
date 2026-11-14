// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: Builds the STATIC warm table and everything that sits on it: felt, wooden rails, cushions, corner blocks,
//          pocket discs, the sixteen balls (with their Lens spin markers), the key and fill lights, and the generated
//          lamp reflection that lights the glossy parts. It makes entities and hands them back; it never runs per
//          frame and never reads the playback clock. Anything about how the table LOOKS (materials, rail shape,
//          pocket shape, ball finish, lighting, reflections) belongs here and only here.
//          Does NOT belong here: Lens drawing (LensLayer.swift), camera (TableCamera.swift), per-frame placement of
//          balls (TableScene.apply).
//          Split out of TableScene.swift in package 0 of the glow-up plan with no behaviour change.
// SRP/DRY check: Pass - static scene construction only; coordinates come from TableFrame, colours from rgba/Theme.
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import Foundation
import RealityKit
import simd

/// One ball's entities: the group that is moved each frame, the glossy body, and the Lens spin pin.
struct BallParts {
    let ball: Entity
    let body: ModelEntity
    let marker: ModelEntity
}

@MainActor
enum TableBuilder {
    // MARK: Table

    /// Felt, rails, cushions, corner blocks and pocket discs, all under one group so the whole warm table can fade
    /// out as the Lens melts in.
    static func makeTable(frame: TableFrame, pockets: [Vec2]) -> Entity {
        let tableGroup = Entity()
        let L = frame.length, W = frame.width
        func pbr(_ c: PlatformColor, rough: Float, metal: Float = 0) -> PhysicallyBasedMaterial {
            var m = PhysicallyBasedMaterial()
            m.baseColor = .init(tint: c)
            m.roughness = .init(floatLiteral: rough)
            m.metallic = .init(floatLiteral: metal)
            return m
        }
        let feltMat = pbr(rgba(0.05, 0.40, 0.35), rough: 0.95)
        // Walnut: darker and glossier than before so it picks up the lamp reflection.
        let woodMat = pbr(rgba(0.34, 0.16, 0.08), rough: 0.28)
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
        for (k, p) in pockets.enumerated() {
            let radius: Float = k < 4 ? 0.088 : 0.07
            let disc = ModelEntity(mesh: .generateCylinder(height: 0.002, radius: radius), materials: [pocketMat])
            disc.position = frame.world(p, height: 0.001)
            tableGroup.addChild(disc)
        }
        return tableGroup
    }

    // MARK: Balls

    /// One glossy ball with its Lens spin pin, parented to `parent`. The caller keeps the parts and moves them.
    static func makeBall(number n: Int, radius R: Float, parent: Entity) -> BallParts {
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
        parent.addChild(ball)
        return BallParts(ball: ball, body: body, marker: marker)
    }

    // MARK: Lights

    /// A key with shadows and a cool fill, added to `parent`. Without image-based light the fill keeps shadows readable.
    static func addLights(to parent: Entity) {
        let key = Entity()
        // Warm key, like a lamp over the table.
        let keyLight = DirectionalLightComponent(color: PlatformColor(red: 1.0, green: 0.90, blue: 0.76, alpha: 1), intensity: 2900, isRealWorldProxy: false)
        key.components.set(keyLight)
        key.components.set(DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 1.0))
        key.look(at: .zero, from: SIMD3(-0.8, 3.0, 1.2), relativeTo: nil)
        parent.addChild(key)
        let fill = Entity()
        fill.components.set(DirectionalLightComponent(color: PlatformColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 1), intensity: 450, isRealWorldProxy: false))
        fill.look(at: .zero, from: SIMD3(1.5, 2.0, -1.5), relativeTo: nil)
        parent.addChild(fill)
    }

    // MARK: Reflections

    /// A small sideways-panorama picture of a dark room with one warm rectangular lamp overhead and a faint cool
    /// strip to one side. It is only ever seen as a reflection on the balls and rails, which is what makes them
    /// look glossy instead of like plastic. Drawn in code so no image file ships.
    private static func lampEnvironmentImage() -> CGImage? {
        let w = 1024, h = 512
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // Top of the image is straight up. Warm dark brown overhead fading to near black below the horizon.
        let colors = [CGColor(red: 0.10, green: 0.07, blue: 0.05, alpha: 1), CGColor(red: 0.06, green: 0.05, blue: 0.045, alpha: 1),
                      CGColor(red: 0.015, green: 0.015, blue: 0.02, alpha: 1)] as CFArray
        let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 0.5, 1])!
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: CGFloat(h)), end: CGPoint(x: 0, y: 0), options: [])
        // CoreGraphics counts y upward from the bottom, so large y is high elevation.
        func lamp(x: Double, y: Double, width: Double, height: Double, _ c: (Double, Double, Double), _ glow: Double) {
            let rect = CGRect(x: x, y: y, width: width, height: height)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: glow, color: CGColor(red: c.0, green: c.1, blue: c.2, alpha: 0.9))
            ctx.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1))
            ctx.fill(rect)
            ctx.restoreGState()
        }
        // The main lamp, high and slightly left of the camera, and a thin cool strip low on the other side.
        lamp(x: 300, y: 380, width: 280, height: 60, (1.0, 0.90, 0.70), 40)
        lamp(x: 760, y: 280, width: 34, height: 120, (0.55, 0.72, 1.0), 20)
        return ctx.makeImage()
    }

    /// Light the scene with the lamp picture and let every model under `root` reflect it. If the picture cannot be
    /// built the scene simply keeps its plain lights.
    static func installEnvironment(on root: Entity) async {
        guard let image = lampEnvironmentImage(),
              let environment = try? await EnvironmentResource(equirectangular: image) else { return }
        root.components.set(ImageBasedLightComponent(source: .single(environment), intensityExponent: 0.8))
        func attach(_ entity: Entity) {
            if entity.components.has(ModelComponent.self) {
                entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: root))
            }
            for child in entity.children { attach(child) }
        }
        attach(root)
    }
}
