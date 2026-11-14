// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Builds the STATIC warm table and everything that sits on it, as one group that fades out when the Lens
//          melts in: cloth that stops exactly at the cushion noses, cushions with a sloped rounded nose and jaw-cut
//          ends, a walnut rail frame with a rounded edge and an apron, real pocket wells (a wall that drops below the
//          cloth, a black floor and a satin-metal rim), pearl diamond sights, head and foot spots, legs, and the room
//          floor painted with its own pool of light. Also builds the sixteen balls (with their Lens spin markers), the
//          overhead spot lamp (the key light, with shadows) plus a cool fill, and the generated lamp-and-room picture
//          that lights and reflects off the glossy parts. It makes entities and hands them back; it never runs per
//          frame and never reads the playback clock. Anything about how the table LOOKS (materials, rail shape,
//          pocket shape, ball finish, lighting, reflections) belongs here and only here.
//          Geometry helpers are in TableMeshes.swift; cloth, wood and floor pictures in SurfaceTextures.swift; ball
//          pictures in BallTextures.swift.
//          Does NOT belong here: Lens drawing (LensLayer.swift), camera (TableCamera.swift), per-frame placement of
//          balls (TableScene.apply).
//          Rule for anyone adding to this file: every VISIBLE entity of the warm table goes under the group that
//          makeTable returns, or it will stay on screen in the Lens view. Lights are the exception (they have no
//          opacity and stay on the scene root so the balls keep their lighting).
//          History: split out of TableScene.swift in package 0 (13-Nov-2026); rebuilt in glow-up package 1.
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
    // MARK: Dimensions (metres). The solver's playing surface is the rectangle between the cushion noses.

    /// Width of the cushion zone (cloth-covered rubber) between the playing edge and the wooden rail.
    static let cushionDepth: Float = 0.045
    /// Wooden rail from the cushion's back to the outer edge, and its top height above the cloth.
    static let railWidth: Float = 0.155
    static let railTop: Float = 0.060
    /// Rounded top edge of the rail, and the apron that hangs below it.
    static let railFillet: Float = 0.016
    static let apronBottom: Float = -0.17
    /// Pocket mouth radii, equal to the solver's cushion gaps so the jaws end exactly where the physics opens up.
    static let cornerPocketRadius: Float = 0.09
    static let sidePocketRadius: Float = 0.075
    static let pocketDepth: Float = 0.12
    static let floorHeight: Float = -0.80

    private static func pbr(_ c: PlatformColor, rough: Float, metal: Float = 0) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: c)
        m.roughness = .init(floatLiteral: rough)
        m.metallic = .init(floatLiteral: metal)
        return m
    }

    private static func part(_ b: MeshBuilder, _ m: some Material, _ name: String) -> ModelEntity? {
        guard let mesh = b.resource() else { return nil }
        let e = ModelEntity(mesh: mesh, materials: [m])
        e.name = name
        return e
    }

    // MARK: Table

    /// Felt, cushions, rails, pocket wells, diamond sights, spots, legs and the room floor, all under one group so the
    /// whole warm table (and the floor it stands on) fades out as the Lens melts in. Nothing here may be added outside
    /// the group, or it would stay visible in the Lens.
    static func makeTable(frame: TableFrame, pockets: [Vec2]) -> Entity {
        let tableGroup = Entity()
        let L = frame.length, W = frame.width
        let a = L * 0.5, b = W * 0.5
        let c = cushionDepth
        let cuts: [Outline.Cut] = pockets.enumerated().map { k, p in
            let w = frame.world(p)
            return Outline.Cut(center: SIMD2(w.x, w.z), radius: k < 4 ? cornerPocketRadius : sidePocketRadius)
        }

        // Materials. The cloth carries its weave in the colour picture and a soft sheen at grazing angles.
        var feltMat = pbr(rgba(1, 1, 1), rough: 0.93)
        if let t = SurfaceTextures.cloth() { feltMat.baseColor = .init(tint: .white, texture: .init(t)) }
        feltMat.sheen = .init(tint: rgba(0.35, 0.75, 0.62))
        var woodMat = pbr(rgba(1, 1, 1), rough: 0.50)
        if let t = SurfaceTextures.wood() { woodMat.baseColor = .init(tint: .white, texture: .init(t)) }
        woodMat.clearcoat = .init(floatLiteral: 0.5)
        woodMat.clearcoatRoughness = .init(floatLiteral: 0.32)
        var wellMat = pbr(rgba(1, 1, 1), rough: 0.8)
        if let t = SurfaceTextures.pocketWall() { wellMat.baseColor = .init(tint: .white, texture: .init(t)) }
        wellMat.faceCulling = .none
        var pearlMat = pbr(rgba(0.93, 0.90, 0.82), rough: 0.22)
        pearlMat.clearcoat = .init(floatLiteral: 1.0)
        let plateMat = pbr(rgba(0.55, 0.52, 0.48), rough: 0.32, metal: 1.0)
        let spotMat = pbr(rgba(0.55, 0.68, 0.60), rough: 0.9)
        let clothUV: (SIMD3<Float>) -> SIMD2<Float> = { p in SIMD2(p.x / L + 0.5, p.z / W + 0.5) }

        // 1. Cloth: exactly the playing surface (plus the strip that tucks under the cushion nose), with a round
        //    hole bitten out at each pocket. Nothing overhangs the rails.
        let tuck: Float = 0.014
        var felt = MeshBuilder()
        let feltOutline = Outline.rectWithCuts(hx: a + tuck, hz: b + tuck, cuts: cuts, arcsOutside: false).points
        felt.addFlat(feltOutline, y: 0, normal: SIMD3(0, 1, 0)) { p, _ in SIMD2(p.x / L + 0.5, p.y / W + 0.5) }
        if let e = part(felt, feltMat, "felt") { tableGroup.addChild(e) }

        // 2. Cushions: a sloped, rounded nose swept along each run between pockets, with the end cut toward the pocket.
        let section: [(d: Float, y: Float)] = [(0.014, 0), (0.0020, 0.0265), (0.0, 0.0325), (0.0030, 0.0375), (0.020, 0.0395), (c, 0.040), (c, 0)]
        let sectionSmooth = [false, true, true, true, true, false, false]
        func shear(_ r: Float) -> Float { (r - (r * r - c * c).squareRoot()) / c }
        var cushions = MeshBuilder()
        // Long sides run along x (z = +/-b); short sides along z (x = +/-a). Segment ends match the solver's gaps.
        let cg: Float = 0.09, sg: Float = 0.075
        let longRuns: [(Float, Float)] = [(-a + cg, -sg), (sg, a - cg)]
        let shortRuns: [(Float, Float)] = [(-b + cg, b - cg)]
        for sign: Float in [1, -1] {
            for (s0, s1) in longRuns {
                // Near the corner the jaw leans by the corner pocket's angle, near the side pocket by the side's.
                let k0 = s0 < 0 ? shear(cornerPocketRadius) : shear(sidePocketRadius)
                let k1 = s1 > 0 ? shear(cornerPocketRadius) : shear(sidePocketRadius)
                cushions.addSweep(section: section, smooth: sectionSmooth, origin: SIMD2(0, sign * b), along: SIMD2(1, 0),
                                  outward: SIMD2(0, sign), s0: s0, s1: s1, shear0: -k0, shear1: k1, uv: clothUV)
            }
            for (s0, s1) in shortRuns {
                cushions.addSweep(section: section, smooth: sectionSmooth, origin: SIMD2(sign * a, 0), along: SIMD2(0, 1),
                                  outward: SIMD2(sign, 0), s0: s0, s1: s1, shear0: -shear(cornerPocketRadius),
                                  shear1: shear(cornerPocketRadius), uv: clothUV)
            }
        }
        if let e = part(cushions, feltMat, "cushions") { tableGroup.addChild(e) }

        // 3. Rail frame: a flat top with the pocket openings cut through it, a rounded outer edge, and the apron.
        let A = a + c + railWidth, B = b + c + railWidth
        let f = railFillet
        let outerR: Float = 0.07
        func roundedRect(hx: Float, hz: Float, radius r: Float) -> [SIMD2<Float>] {
            var pts: [SIMD2<Float>] = [SIMD2(hx, 0)]
            let corners: [(SIMD2<Float>, Float)] = [(SIMD2(hx - r, hz - r), 0), (SIMD2(-hx + r, hz - r), .pi / 2),
                                                      (SIMD2(-hx + r, -hz + r), .pi), (SIMD2(hx - r, -hz + r), .pi * 1.5)]
            for (centre, start) in corners {
                pts += Outline.arc(center: centre, radius: r, from: start, to: start + .pi / 2, stepDegrees: 7.5)
            }
            pts.removeLast()   // the last arc point is the start of the list again
            return pts
        }
        let topOuter = roundedRect(hx: A - f, hz: B - f, radius: outerR - f)
        // The inner opening: the cushion zone's rectangle with each pocket circle bulging out of it.
        let opening = Outline.rectWithCuts(hx: a + c, hz: b + c, cuts: cuts, arcsOutside: true)
        let lipPts = opening.points, lipArc = opening.arcEdge
        // Bridge for the ring: add the point (a + c, 0) on the short end of the opening, and join it to (A - f, 0).
        var holePts = opening.points
        if let i = (0..<holePts.count).first(where: { k in
            let p = holePts[k], q = holePts[(k + 1) % holePts.count]
            return abs(p.x - (a + c)) < 1e-5 && abs(q.x - (a + c)) < 1e-5 && min(p.y, q.y) < 0 && max(p.y, q.y) > 0
        }) {
            holePts.insert(SIMD2(a + c, 0), at: i + 1)
        }
        let bridgeAt = holePts.firstIndex(of: SIMD2(a + c, 0)) ?? 0
        let ring = Outline.bridge(outer: topOuter, outerIndex: 0, hole: holePts, holeIndex: bridgeAt)
        var frameTop = MeshBuilder()
        frameTop.addFlat(ring, y: railTop, normal: SIMD3(0, 1, 0)) { p, centre in
            // Grain follows each rail: along x on the long sides, along z on the short sides.
            let ex = abs(centre.x) - a, ez = abs(centre.y) - b
            return ez >= ex ? SIMD2(p.x * 0.9, p.y * 3.6) : SIMD2(p.y * 0.9, p.x * 3.6)
        }
        // Rounded outer edge and the apron below it, swept along the top outline.
        var profile: [(off: Float, y: Float)] = []
        var profSmooth: [Bool] = []
        for k in 0...5 {
            let t = Float(k) / 5 * .pi / 2
            profile.append((f * sin(t), railTop - f + f * cos(t))); profSmooth.append(true)
        }
        profile.append((f, apronBottom)); profSmooth.append(false)
        frameTop.addLoopProfile(topOuter, profile: profile, smooth: profSmooth, sign: 1, uvAlong: 0.9, uvAcross: 3.6)
        // The short lip where the rail steps up from the cushion top, along the straight stretches only.
        let lipNormals = MeshBuilder.loopNormals(lipPts, flip: true)
        frameTop.addWall(lipPts, outward: lipNormals, top: lipPts.map { _ in railTop }, bottom: 0.040, closed: true,
                         uvScale: 0.9, skip: lipArc)
        if let e = part(frameTop, woodMat, "rails") { tableGroup.addChild(e) }

        // 4. Pocket wells: a wall that drops below the cloth, its top following whatever surrounds it, and a black floor.
        var wells = MeshBuilder()
        var plates = MeshBuilder()
        for cut in cuts {
            let n = 60
            var pts: [SIMD2<Float>] = [], inward: [SIMD2<Float>] = [], tops: [Float] = []
            for i in 0..<n {
                let t = Float(i) / Float(n) * 2 * .pi
                let dir = SIMD2(cos(t), sin(t))
                let p = cut.center + dir * cut.radius
                pts.append(p); inward.append(-dir)
                // Height of whatever the wall meets: open cloth level inside the playing area, cushion height beside
                // it, rail height under the frame.
                let ex = abs(p.x) - a, ez = abs(p.y) - b
                let h: Float
                if ex < 0 && ez < 0 { h = 0.0 }
                else if (ex < c && ez < 0) || (ez < c && ex < 0) { h = 0.036 }
                else { h = railTop }
                tops.append(h)
            }
            wells.addWall(pts, outward: inward, top: tops, bottom: -pocketDepth, closed: true, uvScale: 1)
            // A thin satin-metal plate round the part of the opening that cuts the wooden rail top: the pocket's rim.
            for i in 0..<n where tops[i] == railTop && tops[(i + 1) % n] == railTop {
                let j = (i + 1) % n
                let ri = -inward[i], rj = -inward[j]
                let p0 = pts[i], p1 = pts[j], p2 = pts[j] + rj * 0.014, p3 = pts[i] + ri * 0.014
                let ids = [p0, p1, p2, p3].map { plates.vertex(SIMD3($0.x, railTop + 0.0008, $0.y), SIMD3(0, 1, 0), .zero) }
                plates.quad(ids[0], ids[1], ids[2], ids[3])
            }
            // Black floor of the well, a little smaller so it never pokes through the wall.
            let disc = Outline.arc(center: cut.center, radius: cut.radius * 0.98, from: 0, to: 2 * .pi, stepDegrees: 10).dropLast()
            wells.addFlat(Array(disc), y: -pocketDepth, normal: SIMD3(0, 1, 0)) { _, _ in SIMD2(0, 1) }
        }
        if let e = part(wells, wellMat, "wells") { tableGroup.addChild(e) }
        if let e = part(plates, plateMat, "pocket-plates") { tableGroup.addChild(e) }

        // 5. Diamond sights on the rail tops: three between each corner pocket and side pocket, three on each end.
        var diamonds = MeshBuilder()
        let railMid = c + railWidth * 0.5
        func diamond(at p: SIMD2<Float>, alongX: Bool) {
            let hl: Float = 0.016, hw: Float = 0.010
            let along = alongX ? SIMD2<Float>(1, 0) : SIMD2<Float>(0, 1), across = alongX ? SIMD2<Float>(0, 1) : SIMD2<Float>(1, 0)
            let pts = [p + along * hl, p + across * hw, p - along * hl, p - across * hw]
            diamonds.addFlat(pts, y: railTop + 0.0007, normal: SIMD3(0, 1, 0)) { _, _ in .zero }
        }
        for k in [1, 2, 3, 5, 6, 7] {
            let x = Float(k) * L / 8 - a
            diamond(at: SIMD2(x, b + railMid), alongX: true)
            diamond(at: SIMD2(x, -(b + railMid)), alongX: true)
        }
        for k in 1...3 {
            let z = Float(k) * W / 4 - b
            diamond(at: SIMD2(a + railMid, z), alongX: false)
            diamond(at: SIMD2(-(a + railMid), z), alongX: false)
        }
        if let e = part(diamonds, pearlMat, "diamonds") { tableGroup.addChild(e) }

        // 6. Head spot and foot spot on the cloth (a quarter and three quarters of the way down the table).
        var spots = MeshBuilder()
        for x in [-a * 0.5, a * 0.5] {
            let disc = Outline.arc(center: SIMD2(x, 0), radius: 0.0065, from: 0, to: 2 * .pi, stepDegrees: 20).dropLast()
            spots.addFlat(Array(disc), y: 0.0008, normal: SIMD3(0, 1, 0)) { _, _ in .zero }
        }
        if let e = part(spots, spotMat, "spots") { tableGroup.addChild(e) }

        // 7. Four legs under the apron, and the room floor with the table's pool of light on it.
        let legSize: Float = 0.13
        let legH = apronBottom - floorHeight
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let leg = ModelEntity(mesh: .generateBox(size: SIMD3(legSize, legH, legSize), cornerRadius: 0.012), materials: [woodMat])
                leg.position = SIMD3(sx * (A - 0.22), apronBottom - legH * 0.5, sz * (B - 0.22))
                tableGroup.addChild(leg)
            }
        }
        // The floor paints its own pool of lamplight and table shadow, so it uses an unlit material (see SurfaceTextures).
        var floorMat = UnlitMaterial(color: .white)
        if let t = SurfaceTextures.roomFloor(tableHalf: SIMD2(A, B)) { floorMat.color = .init(tint: .white, texture: .init(t)) }
        floorMat.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        let floor = ModelEntity(mesh: .generatePlane(width: 16, depth: 16), materials: [floorMat])
        floor.position = SIMD3(0, floorHeight, 0)
        floor.name = "floor"
        tableGroup.addChild(floor)
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

    /// The lamp over the table: a warm spot light hung above the middle that throws soft-edged shadows and falls off
    /// toward the edges, so the table and the floor around it sit in a pool of light. A faint cool directional fill from
    /// the opposite side keeps the shadowed faces of the rails readable. Lights have no opacity, so they stay in `parent`
    /// (the scene root) and keep lighting the balls while the table fades out in the Lens.
    static func addLights(to parent: Entity) {
        let lamp = Entity()
        let spot = SpotLightComponent(color: PlatformColor(red: 1.0, green: 0.88, blue: 0.72, alpha: 1), intensity: 90_000,
                                      innerAngleInDegrees: 34, outerAngleInDegrees: 70, attenuationRadius: 9)
        lamp.components.set(spot)
        var shadow = SpotLightComponent.Shadow()
        shadow.depthBias = 2.0
        lamp.components.set(shadow)
        // High over the middle of the table and a little toward the camera side, so shadows fall away from the viewer.
        lamp.look(at: .zero, from: SIMD3(-0.25, 2.3, 0.45), relativeTo: nil)
        parent.addChild(lamp)
        let fill = Entity()
        fill.components.set(DirectionalLightComponent(color: PlatformColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 1), intensity: 650, isRealWorldProxy: false))
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
        lamp(x: 280, y: 372, width: 340, height: 84, (1.0, 0.91, 0.74), 56)
        lamp(x: 760, y: 270, width: 40, height: 150, (0.55, 0.72, 1.0), 26)
        // A dim warm bounce from the floor and a faint wall strip, so the lower half of a ball is not dead black.
        lamp(x: 0, y: 150, width: 1024, height: 22, (0.20, 0.13, 0.08), 30)
        return ctx.makeImage()
    }

    /// Light the scene with the lamp picture and let every model under `root` reflect it. If the picture cannot be
    /// built the scene simply keeps its plain lights.
    static func installEnvironment(on root: Entity) async {
        guard let image = lampEnvironmentImage(),
              let environment = try? await EnvironmentResource(equirectangular: image) else { return }
        root.components.set(ImageBasedLightComponent(source: .single(environment), intensityExponent: 1.1))
        func attach(_ entity: Entity) {
            // The floor is left out on purpose: reflected room light would flatten it into a uniform grey, and the
            // pool of light under the lamp is what makes the table sit in the room.
            if entity.components.has(ModelComponent.self) {
                entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: root))
            }
            for child in entity.children { attach(child) }
        }
        attach(root)
    }
}
