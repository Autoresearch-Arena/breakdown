// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (pockets drawn from the solver's own geometry: cushion runs stop at its knuckles with ends cut along its jaw lines, and each hole is the capture circle grown just enough to fill the throat; the hard-coded pocket radii are gone).
// Edited: Claude Opus 5.5 High, 21-November-2026 (playing surfaces: the bed is built in the chosen surface's look by
//          bedMaterial, which TableScene also uses to swap the bed alone when the surface changes; the cushions stay cloth).
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: the table is drawn at whatever size the TableSpec gives;
//          with no edge pockets (no jaws) each cushion runs its whole side with mitred corners and no wells or cuts are
//          made; holes in the bed (TableSpec.bedHoles) are bitten out of the cloth and get a well wall and a black floor
//          like a pocket's. Posts, pins and every other prop are the table kind's own (App/Tables), added by TableScene.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan packages 1, 2 and 5: the room round the table, the lamp
//          shade and the props (TableRoom.swift, called from makeTable, which replaces the old fading floor); moulded
//          pocket liners from Blender in every pocket (TableRoom.addPocketLiners, placed on the same cut circles, now
//          worked out by pocketCuts so TableScene can drop a pocketed ball into the right hole); a rounder cushion nose
//          whose top profile is read from the one section; a soft contact shadow where each cushion meets the bed in
//          place of the dark seam, and a soft fold shadow along the cushion top against the rail; the cloth's close-up
//          normal map on the bed and cushions (bedMaterial, when the picture is ready); a crisper ball coat and the ball
//          material shared with the small-on-screen pictures (ballMaterial); the reflection picture redrawn from the
//          room as it now is. makeTable takes the scene's light source so models that load later still reflect it.)
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
//          History: split out of TableScene.swift in package 0 (13-Nov-2026); rebuilt in glow-up package 1; package 0.4.1
//          (13-Nov-2026): pictures now come from StartupAssets (made on background threads at launch), and the pocket
//          mouths follow the physics capture radius so a ball dropping near the edge is never clipped by the cloth.
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
    nonisolated static let cushionDepth: Float = 0.045
    /// Wooden rail from the cushion's back to the outer edge, and its top height above the cloth.
    nonisolated static let railWidth: Float = 0.155
    nonisolated static let railTop: Float = 0.060
    /// Rounded top edge of the rail, and the apron that hangs below it.
    nonisolated static let railFillet: Float = 0.016
    nonisolated static let apronBottom: Float = -0.17
    nonisolated static let pocketDepth: Float = 0.12
    nonisolated static let floorHeight: Float = -0.80

    /// Half the table's outer length and width, in metres (the floor picture is shaped by it). Pure arithmetic, so the
    /// background picture jobs can call it before the table exists.
    nonisolated static func floorHalfExtent(length: Float, width: Float) -> SIMD2<Float> {
        SIMD2(length * 0.5 + cushionDepth + railWidth, width * 0.5 + cushionDepth + railWidth)
    }

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

    /// The circle each edge pocket's hole is drawn with, in plan (world x, world z), one per TableSpec pocket.
    /// Everything about the pockets comes from the solver's table description (pocket model version 2): the hole
    /// centres, the capture radii and the jaws. Each hole is drawn at least as big as the capture radius (so a ball
    /// that drops is never cut by cloth) and big enough to fill the throat between the two jaws right back to the
    /// rail, so there is no gap between a jaw face and the well. Used for the cloth, the rail opening, the wells, the
    /// moulded liners, and by TableScene to drop a pocketed ball into the middle of its hole.
    static func pocketCuts(frame: TableFrame, table: TableSpec) -> [Outline.Cut] {
        let b = frame.width * 0.5
        let c = cushionDepth
        func plan(_ v: Vec2) -> SIMD2<Float> { let w = frame.world(v); return SIMD2(w.x, w.z) }
        func planDir(_ v: Vec2) -> SIMD2<Float> { let d = frame.direction(v); return simd_normalize(SIMD2(d.x, d.z)) }
        return table.pockets.enumerated().map { k, hole in
            // The drawn hole sits a little behind the solver's hole centre, out toward the rail, so it bites less into
            // the playing surface; it stays inside the cloth outline (whose tuck is 14 mm), which the outline code needs,
            // and it is grown below to still contain the whole capture circle.
            let solverCentre = plan(hole)
            let shift: Float = 0.011
            let out = SIMD2<Float>(k < 4 ? (solverCentre.x < 0 ? -1 : 1) : 0, solverCentre.y < 0 ? -1 : 1)
            let centre = solverCentre + out * shift
            var reach = Float(table.pocketCaptureRadius[k]) + simd_length(out * shift)
            var backs: [SIMD2<Float>] = []
            for j in table.jaws where j.pocket == k {
                let start = plan(j.start), dir = planDir(j.end - j.start)
                // Where the jaw line meets the back of the cushion strip, cushionDepth out from its own nose line.
                let onLong = abs(abs(start.y) - b) < 1e-4
                let outward = onLong ? SIMD2<Float>(0, start.y < 0 ? -1 : 1) : SIMD2<Float>(start.x < 0 ? -1 : 1, 0)
                backs.append(start + dir * (c / max(0.1, simd_dot(dir, outward))))
            }
            // For a corner, the corner of the cushion zone between the two jaw backs must be inside the hole too.
            if k < 4, backs.count == 2 { backs.append(SIMD2(centre.x + (centre.x < 0 ? -c : c), centre.y + (centre.y < 0 ? -c : c))) }
            for p in backs { reach = max(reach, simd_length(p - centre) + 0.003) }
            return Outline.Cut(center: centre, radius: reach)
        }
    }

    /// The cushion's cross-section, (distance outward from the playing edge, height), closed round from the cloth under
    /// the nose, up the nose, across the top to the rail and down. The nose is a near-round bull-nose (look plan package
    /// 2: the old three-point nose read as a sharp ridge up close): points on a curve of about 6 mm radius either side
    /// of the playing edge at (0, 32.5 mm), where the solver's cushion contact is. The top then runs nearly flat to the
    /// rail at 40 mm.
    private static let cushionSection: [(d: Float, y: Float)] = [
        (0.014, 0), (0.0042, 0.0222), (0.0013, 0.0276), (0.0, 0.0325), (0.0012, 0.0362), (0.0045, 0.0386),
        (0.010, 0.0397), (0.020, 0.0400), (cushionDepth, 0.0400), (cushionDepth, 0),
    ]
    /// Which section points get smooth (shared) normals: all of the nose and top, not the corners at the back.
    private static let cushionSmooth = [false, true, true, true, true, true, true, true, false, false]
    /// The rising part of the section, from the nose (d = 0) back to the rail: what a well wall must meet.
    private static var cushionTopProfile: [(d: Float, y: Float)] {
        cushionSection.filter { $0.y >= 0.0325 }.sorted { $0.d < $1.d }
    }

    /// Felt, cushions, rails, pocket wells, diamond sights, spots, legs and the room (floor, walls, lamp, props), all
    /// under one group so the whole warm table and the room it stands in fade out as the Lens melts in. Nothing here
    /// may be added outside the group, or it would stay visible in the Lens.
    /// - surface: the playing surface the bed is drawn in (see PlaySurfaceLook). The bed is the entity named
    ///   "felt", which TableScene looks up to swap its material when the surface changes.
    /// - lightSource: the scene root carrying the lamp reflection, so the models that load after the table is built
    ///   (pocket liners, lamp shade, props) still reflect it; nil when there is none yet.
    static func makeTable(frame: TableFrame, table: TableSpec, surface: PlaySurface = .cloth, lightSource: Entity? = nil) -> Entity {
        StartupLog.mark("makeTable begin")
        defer { StartupLog.mark("makeTable end") }
        let tableGroup = Entity()
        let L = frame.length, W = frame.width
        let a = L * 0.5, b = W * 0.5
        let c = cushionDepth
        func plan(_ v: Vec2) -> SIMD2<Float> { let w = frame.world(v); return SIMD2(w.x, w.z) }
        func planDir(_ v: Vec2) -> SIMD2<Float> { let d = frame.direction(v); return simd_normalize(SIMD2(d.x, d.z)) }
        let cuts = pocketCuts(frame: frame, table: table)

        // Materials. The cloth carries its weave in the colour picture and a soft sheen at grazing angles. The cushions
        // always wear the cloth: a cushion is the rail's rubber wrapped in cloth, whatever the bed is made of. Only the
        // playing bed takes the chosen surface's look.
        let feltMat = bedMaterial(for: .cloth, image: StartupAssets.shared.clothImage())
        let bedMat = surface == .cloth ? feltMat : bedMaterial(for: surface, image: StartupAssets.shared.bedImageNow(for: surface))
        var woodMat = pbr(rgba(1, 1, 1), rough: 0.50)
        if let t = StartupAssets.texture(StartupAssets.shared.woodImage()) { woodMat.baseColor = .init(tint: .white, texture: .init(t)) }
        woodMat.clearcoat = .init(floatLiteral: 0.5)
        woodMat.clearcoatRoughness = .init(floatLiteral: 0.32)
        var wellMat = pbr(rgba(1, 1, 1), rough: 0.8)
        if let t = StartupAssets.texture(StartupAssets.shared.pocketWallImage()) { wellMat.baseColor = .init(tint: .white, texture: .init(t)) }
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
        var feltOutline = Outline.rectWithCuts(hx: a + tuck, hz: b + tuck, cuts: cuts, arcsOutside: false).points
        // Holes in the bed (another table's scoring holes or cups): round holes cut right through the cloth, each joined
        // to the outline by a bridge so one outline still describes the whole cloth. The same circles shape the wells.
        let bedHoleRims: [(center: SIMD2<Float>, points: [SIMD2<Float>])] = table.bedHoles.map { hole in
            let centre = plan(hole.center)
            // Started a little off angle zero, so a hole's rightmost point never lines up exactly with another's.
            let pts = Array(Outline.arc(center: centre, radius: Float(hole.radius), from: 0.0137, to: 0.0137 + 2 * .pi,
                                        stepDegrees: 15).dropLast())
            return (centre, pts)
        }
        if !bedHoleRims.isEmpty { feltOutline = Outline.withHoles(outer: feltOutline, holes: bedHoleRims.map(\.points)) }
        felt.addFlat(feltOutline, y: 0, normal: SIMD3(0, 1, 0)) { p, _ in SIMD2(p.x / L + 0.5, p.y / W + 0.5) }
        if let e = part(felt, bedMat, "felt") { tableGroup.addChild(e) }

        // 2. Cushions: a rounded bull-nose swept along each run between pockets, with the end cut toward the pocket.
        //    Each run also lays two soft shadows (look plan package 2): one on the bed along the cushion's foot, where
        //    the nose overhangs the cloth (it used to show as a hard dark seam), and one along the back of the cushion
        //    top, where the cloth folds down against the wooden rail, so the cushion top reads as its own cloth with an
        //    edge. Both are see-through black (the soft spot picture), so they work over any bed or cushion cloth.
        var cushions = MeshBuilder()
        var shades = MeshBuilder()
        /// One cushion run: the swept cushion, then its two shadow strips. A strip's ends follow the jaw lines (the
        /// same lean as the cushion's cut ends), so they never reach over a pocket hole.
        func cushionRun(origin: SIMD2<Float>, along: SIMD2<Float>, outward: SIMD2<Float>,
                        _ j0: (knuckle: SIMD2<Float>, direction: SIMD2<Float>), _ j1: (knuckle: SIMD2<Float>, direction: SIMD2<Float>)) {
            cushions.addSweep(section: cushionSection, smooth: cushionSmooth, origin: origin, along: along, outward: outward,
                              jaw0: j0, jaw1: j1, uv: clothUV)
            /// Distance along the run where the jaw line of `j` is `d` out from the nose line.
            func endAlong(_ j: (knuckle: SIMD2<Float>, direction: SIMD2<Float>), _ d: Float) -> Float {
                simd_dot(j.knuckle - origin, along) + simd_dot(j.direction, along) * d / max(1e-4, simd_dot(j.direction, outward))
            }
            /// A flat strip at height y, darkest along outward distance d0 and clear along d1; along the run it spans
            /// s0 to s1 on the d0 edge and t0 to t1 on the d1 edge.
            func strip(_ d0: Float, _ d1: Float, y: Float, s0: Float, s1: Float, t0: Float, t1: Float) {
                let n = SIMD3<Float>(0, 1, 0)
                func p(_ s: Float, _ d: Float) -> SIMD3<Float> { let q = origin + along * s + outward * d; return SIMD3(q.x, y, q.y) }
                // The soft spot picture is sampled from its centre (darkest) out to its edge (clear) down the middle
                // column. A round picture is used on purpose: whichever way the system orients texture rows, the centre
                // stays the centre and the edge stays the edge, so the shadow can never come out reversed.
                let dark = SIMD2<Float>(0.5, 0.5), clear = SIMD2<Float>(0.5, 1.0)
                let v0 = shades.vertex(p(s0, d0), n, dark), v1 = shades.vertex(p(s1, d0), n, dark)
                let v2 = shades.vertex(p(t1, d1), n, clear), v3 = shades.vertex(p(t0, d1), n, clear)
                shades.quad(v0, v1, v2, v3)
            }
            // Contact shadow on the bed: darkest 12 mm under the nose (where the cushion's foot meets the cloth), clear
            // 30 mm out into the bed. Stopped 2 cm short of each knuckle, where the bed is cut away for the pocket.
            let s0 = simd_dot(j0.knuckle - origin, along) + 0.02, s1 = simd_dot(j1.knuckle - origin, along) - 0.02
            if s1 > s0 { strip(0.012, -0.030, y: 0.0006, s0: s0, s1: s1, t0: s0, t1: s1) }
            // Fold shadow on the cushion top: darkest at the rail (d = cushionDepth), clear 15 mm in, just above the top.
            let foldIn: Float = c - 0.015
            strip(c, foldIn, y: 0.0403, s0: endAlong(j0, c), s1: endAlong(j1, c), t0: endAlong(j0, foldIn), t1: endAlong(j1, foldIn))
        }
        // Long sides run along x (z = +/-b); short sides along z (x = +/-a). Each run stops at the solver's knuckles and
        // its ends are cut along the solver's jaw lines, so what you see is exactly what the balls bounce off.
        let jawPlan = table.jaws.map { (knuckle: plan($0.start), direction: planDir($0.end - $0.start)) }
        /// The jaw whose knuckle is on this nose line (outward distance zero) nearest to `near`.
        func jaw(onLine origin: SIMD2<Float>, outward: SIMD2<Float>, near: SIMD2<Float>) -> (knuckle: SIMD2<Float>, direction: SIMD2<Float>) {
            jawPlan.filter { abs(simd_dot($0.knuckle - origin, outward)) < 1e-4 }
                .min { simd_length($0.knuckle - near) < simd_length($1.knuckle - near) }!
        }
        // No pockets (no jaws): each side is one run from corner to corner, its ends mitred at 45 degrees so the four
        // cushions meet in the corners.
        if table.jaws.isEmpty {
            for sign: Float in [1, -1] {
                let origin = SIMD2<Float>(0, sign * b), outward = SIMD2<Float>(0, sign)
                let m = Float(0.5).squareRoot()
                cushionRun(origin: origin, along: SIMD2(1, 0), outward: outward,
                           (SIMD2(-a, sign * b), SIMD2(-m, sign * m)), (SIMD2(a, sign * b), SIMD2(m, sign * m)))
                let shortOrigin = SIMD2<Float>(sign * a, 0), shortOut = SIMD2<Float>(sign, 0)
                cushionRun(origin: shortOrigin, along: SIMD2(0, 1), outward: shortOut,
                           (SIMD2(sign * a, -b), SIMD2(sign * m, -m)), (SIMD2(sign * a, b), SIMD2(sign * m, m)))
            }
        }
        for sign: Float in [1, -1] where !table.jaws.isEmpty {
            let origin = SIMD2<Float>(0, sign * b), outward = SIMD2<Float>(0, sign)
            let cornerL = SIMD2(-a, sign * b), cornerR = SIMD2(a, sign * b)
            // Each long rail is two runs: corner to side pocket and side pocket to corner. The side pocket's two
            // knuckles sit either side of the middle, so "nearest to a point just left / right of the middle" picks them.
            let runs = [(jaw(onLine: origin, outward: outward, near: cornerL), jaw(onLine: origin, outward: outward, near: SIMD2(-0.03, sign * b))),
                        (jaw(onLine: origin, outward: outward, near: SIMD2(0.03, sign * b)), jaw(onLine: origin, outward: outward, near: cornerR))]
            for (j0, j1) in runs {
                cushionRun(origin: origin, along: SIMD2(1, 0), outward: outward, j0, j1)
            }
            let shortOrigin = SIMD2<Float>(sign * a, 0), shortOut = SIMD2<Float>(sign, 0)
            cushionRun(origin: shortOrigin, along: SIMD2(0, 1), outward: shortOut,
                       jaw(onLine: shortOrigin, outward: shortOut, near: SIMD2(sign * a, -b)),
                       jaw(onLine: shortOrigin, outward: shortOut, near: SIMD2(sign * a, b)))
        }
        if let e = part(cushions, feltMat, "cushions") { tableGroup.addChild(e) }
        if let e = part(shades, shadowMaterial(opacity: 0.55), "cushion-shadows") { tableGroup.addChild(e) }

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

        // 4. Pocket wells: a wall that drops below the cloth, its top following whatever surrounds it, a black floor,
        //    and a full metal rim all the way round the mouth.
        /// Height of the table's top surface at a plan point: cloth level inside the playing area, the cushion's own
        /// profile beside it (so a well wall meets the cushion exactly), rail height under the frame.
        let topProfile = cushionTopProfile
        func surfaceHeight(_ p: SIMD2<Float>) -> Float {
            let ex = abs(p.x) - a, ez = abs(p.y) - b
            func cushionTop(_ d: Float) -> Float {
                // Rising part of the section from the nose (d = 0) back to the rail, read from the one section.
                let pts = topProfile
                for k in 0..<(pts.count - 1) where d <= pts[k + 1].d {
                    let t = (d - pts[k].d) / (pts[k + 1].d - pts[k].d)
                    return pts[k].y + (pts[k + 1].y - pts[k].y) * max(0, t)
                }
                return 0.040
            }
            if ex < 0 && ez < 0 { return 0 }
            if ez < c && ex < 0 { return cushionTop(ez) }
            if ex < c && ez < 0 { return cushionTop(ex) }
            return railTop
        }
        var wells = MeshBuilder()
        var plates = MeshBuilder()
        for cut in cuts {
            let n = 72
            var pts: [SIMD2<Float>] = [], inward: [SIMD2<Float>] = [], tops: [Float] = []
            for i in 0..<n {
                let t = Float(i) / Float(n) * 2 * .pi
                let dir = SIMD2(cos(t), sin(t))
                let p = cut.center + dir * cut.radius
                pts.append(p); inward.append(-dir)
                tops.append(surfaceHeight(p))
            }
            wells.addWall(pts, outward: inward, top: tops, bottom: -pocketDepth, closed: true, uvScale: 1)
            // Satin-metal rim: a thin band right round the mouth, lying on whatever surface is there (cloth, cushion or
            // rail) a hair above it. It is complete (the old rim existed only where the mouth cut the wood).
            let rimWidth: Float = 0.013
            for i in 0..<n {
                let j = (i + 1) % n
                let ri = -inward[i], rj = -inward[j]
                let o0 = pts[i] + ri * rimWidth, o1 = pts[j] + rj * rimWidth
                let lift: Float = 0.0012
                let v0 = plates.vertex(SIMD3(pts[i].x, tops[i] + lift, pts[i].y), SIMD3(0, 1, 0), .zero)
                let v1 = plates.vertex(SIMD3(pts[j].x, tops[j] + lift, pts[j].y), SIMD3(0, 1, 0), .zero)
                let v2 = plates.vertex(SIMD3(o1.x, surfaceHeight(o1) + lift, o1.y), SIMD3(0, 1, 0), .zero)
                let v3 = plates.vertex(SIMD3(o0.x, surfaceHeight(o0) + lift, o0.y), SIMD3(0, 1, 0), .zero)
                plates.quad(v0, v1, v2, v3)
            }
            // Black floor of the well, a little smaller so it never pokes through the wall.
            let disc = Outline.arc(center: cut.center, radius: cut.radius * 0.98, from: 0, to: 2 * .pi, stepDegrees: 10).dropLast()
            wells.addFlat(Array(disc), y: -pocketDepth, normal: SIMD3(0, 1, 0)) { _, _ in SIMD2(0, 1) }
        }
        // Bed holes: a wall straight down from the cloth round the hole's own outline, and a black floor.
        for rim in bedHoleRims {
            let inward = rim.points.map { simd_normalize(rim.center - $0) }
            wells.addWall(rim.points, outward: inward, top: rim.points.map { _ in 0 }, bottom: -pocketDepth, closed: true, uvScale: 1)
            wells.addFlat(rim.points.map { rim.center + ($0 - rim.center) * 0.98 }, y: -pocketDepth, normal: SIMD3(0, 1, 0)) { _, _ in SIMD2(0, 1) }
        }
        if let e = part(wells, wellMat, "wells") { tableGroup.addChild(e) }
        if let e = part(plates, plateMat, "pocket-plates") { tableGroup.addChild(e) }
        // The moulded cup and rolled lip in each pocket (TableRoom): the wall and floor above stay as the fallback while
        // the model loads, and the cup sits just inside them, so a dropping ball goes behind the lip into the cup.
        addPocketLiners(cuts: cuts, to: tableGroup, lightSource: lightSource)

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

        // 7. Four legs under the apron, and the room: the floor with the table's pool of light on it, the walls, the
        //    lamp shade and the props (TableRoom).
        let legSize: Float = 0.13
        let legH = apronBottom - floorHeight
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let leg = ModelEntity(mesh: .generateBox(size: SIMD3(legSize, legH, legSize), cornerRadius: 0.012), materials: [woodMat])
                leg.position = SIMD3(sx * (A - 0.22), apronBottom - legH * 0.5, sz * (B - 0.22))
                tableGroup.addChild(leg)
            }
        }
        tableGroup.addChild(makeRoom(frame: frame, tableHalf: SIMD2(A, B), wood: woodMat, lightSource: lightSource))
        return tableGroup
    }

    // MARK: Soft shadows

    /// The soft round shadow picture as a texture, made once (it is tiny) and shared by every shadow.
    private static var softSpot: TextureResource?

    /// A see-through black material wearing the soft round shadow picture (SurfaceTextures.softSpotImage), at most
    /// `opacity` dark in the middle. Unlit, so the shadow is the same darkness whatever the lights do. Used for the
    /// cushion strips here, and by TableDetail (each ball's contact shadow) and CueRig (the cue's shadow).
    static func shadowMaterial(opacity: Float) -> UnlitMaterial {
        if softSpot == nil { softSpot = StartupAssets.texture(SurfaceTextures.softSpotImage()) }
        var m = UnlitMaterial(color: .black)
        if let t = softSpot { m.color = .init(tint: .black, texture: .init(t)) }
        m.blending = .transparent(opacity: .init(floatLiteral: opacity))
        return m
    }

    // MARK: Playing bed

    /// The playing bed's material for a surface: its picture plus its finish (PlaySurfaceLook). Used for the bed when
    /// the table is built and again by TableScene when the surface changes, and for the cushions' cloth.
    static func bedMaterial(for surface: PlaySurface, image: CGImage?) -> PhysicallyBasedMaterial {
        let finish = surface.bedFinish
        var m = pbr(rgba(1, 1, 1), rough: finish.roughness)
        if let t = StartupAssets.texture(image) { m.baseColor = .init(tint: .white, texture: .init(t)) }
        if let specular = finish.specular { m.specular = .init(floatLiteral: specular) }
        if finish.clearcoat > 0 {
            m.clearcoat = .init(floatLiteral: finish.clearcoat)
            m.clearcoatRoughness = .init(floatLiteral: finish.clearcoatRoughness)
        }
        if let sheen = finish.sheen { m.sheen = .init(tint: rgba(Double(sheen.x), Double(sheen.y), Double(sheen.z))) }
        // The three real cloths gain the close-up fibre detail (look plan package 2) once its picture has been drawn
        // (StartupAssets' second pass); TableScene rebuilds the bed's material when it arrives. Ice, glass, sand and the
        // rest are not woven, so they never wear it.
        if [PlaySurface.cloth, .tournament, .diveBar].contains(surface), let n = clothDetailTexture() {
            m.normal = .init(texture: .init(n))
        }
        return m
    }

    /// The cloth's close-up normal map as a texture, made once when the picture is ready; nil until then.
    private static var clothDetail: TextureResource?
    private static func clothDetailTexture() -> TextureResource? {
        if clothDetail == nil, let image = StartupAssets.shared.clothDetailNormalIfReady() {
            clothDetail = StartupAssets.texture(image, semantic: .normal)
        }
        return clothDetail
    }

    // MARK: Balls

    /// One glossy ball with its Lens spin pin, parented to `parent`. The caller keeps the parts and moves them.
    static func makeBall(number n: Int, radius R: Float, parent: Entity) -> BallParts {
        defer { if n == 0 || n == 15 { StartupLog.mark("ball \(n) done") } }
        let ball = Entity()
        let m = ballMaterial(image: StartupAssets.shared.ballImage(number: n))
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

    /// A ball's finish around one of its pictures: phenolic resin under a clear, polished coat. The coat's roughness
    /// is 0.03 (it was 0.05), which keeps the lamp's three bulbs (in the reflection picture) as small, sharp
    /// highlights on every ball, as on a freshly polished set. Shared by the normal pictures (makeBall) and the
    /// high-contrast small-on-screen pictures (TableDetail swaps between them).
    static func ballMaterial(image: CGImage?) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        if let tex = StartupAssets.texture(image) { m.baseColor = .init(texture: .init(tex)) }
        m.roughness = .init(floatLiteral: 0.14)
        m.clearcoat = .init(floatLiteral: 1.0)
        m.clearcoatRoughness = .init(floatLiteral: 0.03)
        return m
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

    /// A sideways-panorama picture of the room as a ball in the middle of the table sees it (look plan package 1: the
    /// balls reflect what is actually there). It lights the glossy parts and is what makes the balls and rails look
    /// glossy instead of like plastic. Drawn in code so no image file ships. Layout: x runs once round the horizon,
    /// y from straight up (top row) to straight down (bottom row); elevations below are in degrees.
    ///   - Overhead, the open bottom of the lamp shade: a long glowing window (the shade's opening is 1.30 by 0.36 m,
    ///     0.86 m above the cloth, see TableRoom), with three small white-hot bulb cores along its length, which give
    ///     each ball a sharp highlight, and a dark green rim where the enamel shade is seen edge-on.
    ///   - The ceiling, nearly black, above about 35 degrees.
    ///   - The walls: dark green-grey plaster, a little warmer low down where the lamp's spill reaches, the wooden
    ///     waist rail as a thin brown line just above the horizon (it is 0.2 m above the cloth and about three metres
    ///     away), and the dark wainscot below it; on one side the cue rack's board and the pale line of its cues.
    ///   - Just below the horizon the table's own wooden rails, and below them the dim green of the cloth, which
    ///     tints the underside of every ball as real cloth does.
    /// The shade's long side is drawn along the picture's x = 0 and x = half (taken to be the world's x axis, the
    /// table's length); if the system maps them elsewhere, the window simply turns on the balls.
    nonisolated static func lampEnvironmentImage() -> CGImage? {
        let w = 1024, h = 512
        var px = [UInt8](repeating: 255, count: w * h * 4)
        func smooth(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
            let t = max(0, min(1, (x - e0) / (e1 - e0))); return t * t * (3 - 2 * t)
        }
        func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> (Double, Double, Double) {
            (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
        }
        let cloth = (0.020, 0.070, 0.052), rail = (0.090, 0.050, 0.030), wainscot = (0.050, 0.035, 0.025)
        let waist = (0.110, 0.065, 0.035), plaster = (0.060, 0.066, 0.060), ceiling = (0.030, 0.028, 0.026)
        let glow = (1.0, 0.90, 0.72), enamel = (0.03, 0.09, 0.06), bulb = (1.0, 1.0, 0.97)
        // The shade's opening (half length, half width) and its height above a ball's centre, metres.
        let shadeHalfLength = 0.65, shadeHalfWidth = 0.18
        let shadeUp = Double(shadeBottom) - 0.028
        let bulbUp = shadeUp + 0.105
        for row in 0..<h {
            // Row 0 is the top of the picture: straight up.
            let elev = 90 - (Double(row) + 0.5) / Double(h) * 180
            let elevRad = elev * Double.pi / 180
            for col in 0..<w {
                let lon = (Double(col) + 0.5) / Double(w) * 2 * Double.pi
                var c: (Double, Double, Double)
                // Below the horizon: cloth, then the table's rails right at the horizon, then the walls.
                if elev < -3 { c = cloth }
                else if elev < 1 { c = mix(cloth, rail, smooth(-3, -1.5, elev)) }
                else if elev < 3.2 { c = mix(rail, wainscot, smooth(1, 1.8, elev)) }
                else if elev < 4.6 { c = waist }
                else if elev < 35 {
                    // Plaster, a little brighter low down where the lamp's spill lands on the walls.
                    let spill = 1 + 0.5 * (1 - smooth(5, 30, elev))
                    c = (plaster.0 * spill, plaster.1 * spill, plaster.2 * spill)
                } else { c = mix(plaster, ceiling, smooth(35, 42, elev)) }
                // The cue rack on one wall: a dark board with pale cues standing in it.
                let rackLon = 1.5 * Double.pi
                let dl = atan2(sin(lon - rackLon), cos(lon - rackLon))
                if abs(dl) < 0.09, elev > -1, elev < 22 {
                    c = mix(c, (0.035, 0.020, 0.012), 0.8)
                    if elev > 2, elev < 20, Int((dl + 0.09) / 0.036) % 2 == 0 { c = mix(c, (0.30, 0.22, 0.14), 0.5) }
                }
                // Overhead: the shade's opening as seen from below. Along direction `lon` the opening's edge is
                // `reach` metres out, so the window starts at elevation atan(shadeUp / reach).
                let reach = min(shadeHalfLength / max(1e-6, abs(cos(lon))), shadeHalfWidth / max(1e-6, abs(sin(lon))))
                let edge = atan(shadeUp / reach) * 180 / Double.pi
                if elev > edge - 4 {
                    // A dark enamel rim, then the warm glowing reflector inside it.
                    c = mix(c, enamel, smooth(edge - 4, edge - 2.5, elev))
                    c = mix(c, glow, smooth(edge - 1, edge + 1.5, elev))
                    // The three bulbs: 0.40 m either side of the middle and in the middle, 0.105 m up inside the shade.
                    let x = cos(elevRad) * cos(lon), y = sin(elevRad), z = cos(elevRad) * sin(lon)
                    for bx in [-0.40, 0.0, 0.40] {
                        let len = (bx * bx + bulbUp * bulbUp).squareRoot()
                        let cosAngle = (x * bx + y * bulbUp + z * 0) / len
                        let angle = acos(max(-1, min(1, cosAngle))) * 180 / Double.pi
                        // About four degrees across with a soft edge: small enough for a crisp highlight on a ball.
                        c = mix(c, bulb, 1 - smooth(1.4, 2.4, angle))
                    }
                }
                let i = (row * w + col) * 4
                px[i] = UInt8(max(0, min(255, c.0 * 255 + 0.5)))
                px[i + 1] = UInt8(max(0, min(255, c.1 * 255 + 0.5)))
                px[i + 2] = UInt8(max(0, min(255, c.2 * 255 + 0.5)))
            }
        }
        guard let provider = CGDataProvider(data: Data(px) as CFData) else { return nil }
        return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    /// Light the scene with the lamp picture and let every model under `root` reflect it. If the picture cannot be
    /// built the scene simply keeps its plain lights.
    static func installEnvironment(on root: Entity) async {
        StartupLog.mark("environment begin")
        // However this ends, the scene has been built: the window may now fade its dark cover away.
        defer { StartupLog.mark("environment end"); StartupGate.shared.sceneIsBuilt() }
        // The picture and its environment are made on a background task started at launch (StartupAssets), so this
        // is normally an instant hand-over rather than a wait.
        guard let environment = await StartupAssets.shared.environment() else { return }
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
