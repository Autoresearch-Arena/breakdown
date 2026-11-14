// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: Small geometry toolkit for building the table out of custom meshes with Apple's MeshDescriptor: a mesh
//          accumulator (positions, normals, texture coordinates, triangles), an ear-clipping triangulator for flat
//          outlines (including outlines with a hole joined by a bridge), a sweep that pushes a 2D cross-section
//          along a straight run (cushion strips with angled ends), a sweep along a closed loop (the rounded rail
//          edge), vertical walls, and a helper that walks a rectangle with circular pocket cut-outs. It makes
//          MeshResources and never touches the scene. TableBuilder.swift is the only caller.
//          Why custom meshes: boxes cannot give a sloped cushion nose, rounded rail edges, or a round pocket hole
//          cut cleanly through felt and wood.
//          Conventions: plan view uses SIMD2(x, z) in world metres (x along the long side, z across it); a
//          cross-section uses (distance outward from the playing surface, height).
//          Package 0.4.1 (13-Nov-2026): cushion strips now end on the pocket's own circle (addSweep takes the pocket
//          centre and radius for each end) with smooth jaw-facing normals, replacing the flat slanted end block.
//          Triangle winding is fixed automatically by comparing the geometric normal with the supplied vertex
//          normals, so callers only have to supply correct normals, never think about winding.
// SRP/DRY check: Pass - geometry only; no materials, no textures, no scene state. Checked TableScene and
//          LensLayer: the Lens builds its own ribbons and shares nothing with this file.
import Foundation
import RealityKit
import simd

/// Accumulates one mesh. Call `vertex` for each point, `tri` for each triangle, then `resource()`.
struct MeshBuilder {
    private(set) var positions: [SIMD3<Float>] = []
    private(set) var normals: [SIMD3<Float>] = []
    private(set) var uvs: [SIMD2<Float>] = []
    private(set) var indices: [UInt32] = []

    var isEmpty: Bool { indices.isEmpty }

    @discardableResult
    mutating func vertex(_ p: SIMD3<Float>, _ n: SIMD3<Float>, _ uv: SIMD2<Float>) -> UInt32 {
        positions.append(p); normals.append(simd_normalize(n)); uvs.append(uv)
        return UInt32(positions.count - 1)
    }

    /// Adds a triangle, flipping its winding if needed so it faces the way the vertex normals say.
    mutating func tri(_ a: UInt32, _ b: UInt32, _ c: UInt32) {
        let pa = positions[Int(a)], pb = positions[Int(b)], pc = positions[Int(c)]
        let g = simd_cross(pb - pa, pc - pa)
        // A zero-area triangle only wastes a draw; skip it.
        if simd_length_squared(g) < 1e-14 { return }
        let n = normals[Int(a)] + normals[Int(b)] + normals[Int(c)]
        if simd_dot(g, n) >= 0 { indices += [a, b, c] } else { indices += [a, c, b] }
    }

    mutating func quad(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) {
        tri(a, b, c); tri(a, c, d)
    }

    func resource() -> MeshResource? {
        guard !indices.isEmpty else { return nil }
        var d = MeshDescriptor(name: "table-part")
        d.positions = MeshBuffers.Positions(positions)
        d.normals = MeshBuffers.Normals(normals)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [d])
    }
}

// MARK: - Planar outlines

enum Outline {
    /// Signed area in the plan (positive when counter-clockwise in x-right, z-up maths).
    static func signedArea(_ p: [SIMD2<Float>]) -> Float {
        var s: Float = 0
        for i in 0..<p.count {
            let a = p[i], b = p[(i + 1) % p.count]
            s += a.x * b.y - b.x * a.y
        }
        return s * 0.5
    }

    private static func cross(_ o: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }

    /// Ear-clipping triangulation. Handles concave outlines and the repeated points left by a bridge cut that joins
    /// an outer outline to a hole. Returns index triples into `pts`. If the outline is degenerate it still returns
    /// every ear it can find rather than looping forever.
    static func triangulate(_ pts: [SIMD2<Float>]) -> [(Int, Int, Int)] {
        guard pts.count >= 3 else { return [] }
        var idx = Array(0..<pts.count)
        if signedArea(pts) < 0 { idx.reverse() }
        var out: [(Int, Int, Int)] = []
        var guardCount = 0
        while idx.count > 3 && guardCount < pts.count * pts.count {
            guardCount += 1
            var clipped = false
            for i in 0..<idx.count {
                let ip = idx[(i + idx.count - 1) % idx.count], ic = idx[i], inx = idx[(i + 1) % idx.count]
                let a = pts[ip], b = pts[ic], c = pts[inx]
                if cross(a, b, c) <= 1e-9 { continue }   // reflex or flat: not an ear
                var blocked = false
                for j in idx where j != ip && j != ic && j != inx {
                    let p = pts[j]
                    // Bridge duplicates sit exactly on a corner of the candidate; they do not block it.
                    if p == a || p == b || p == c { continue }
                    if cross(a, b, p) >= -1e-9 && cross(b, c, p) >= -1e-9 && cross(c, a, p) >= -1e-9 { blocked = true; break }
                }
                if blocked { continue }
                out.append((ip, ic, inx))
                idx.remove(at: i)
                clipped = true
                break
            }
            if !clipped {
                // No ear found (numerical trouble): drop a vertex so the loop always ends.
                idx.remove(at: 0)
            }
        }
        if idx.count == 3 { out.append((idx[0], idx[1], idx[2])) }
        return out
    }

    /// Joins an outer outline and a hole outline into one outline with a two-way bridge between the given points.
    static func bridge(outer: [SIMD2<Float>], outerIndex: Int, hole: [SIMD2<Float>], holeIndex: Int) -> [SIMD2<Float>] {
        var o = outer
        if signedArea(o) < 0 { o.reverse() }
        var h = hole
        if signedArea(h) > 0 { h.reverse() }   // the hole must run the other way round
        // Re-find the bridge points after any reversal by position.
        let op = outer[outerIndex], hp = hole[holeIndex]
        let oi = o.firstIndex(of: op) ?? 0
        let hi = h.firstIndex(of: hp) ?? 0
        var result: [SIMD2<Float>] = []
        for k in 0...o.count { result.append(o[(oi + k) % o.count]) }   // back to the start
        for k in 0...h.count { result.append(h[(hi + k) % h.count]) }   // round the hole and back to its start
        return result
    }

    /// Points on a circular arc from angle `a0` to `a1` (radians), inclusive, going the short way implied by sign.
    static func arc(center: SIMD2<Float>, radius: Float, from a0: Float, to a1: Float, stepDegrees: Float = 6) -> [SIMD2<Float>] {
        let steps = max(2, Int(abs(a1 - a0) * 180 / .pi / stepDegrees))
        return (0...steps).map { i in
            let t = a0 + (a1 - a0) * Float(i) / Float(steps)
            return center + radius * SIMD2(cos(t), sin(t))
        }
    }

    /// A circle that cuts a rectangle outline: centre and radius in plan.
    struct Cut { let center: SIMD2<Float>; let radius: Float }

    /// Walks the outline of the rectangle |x| <= hx, |z| <= hz in counter-clockwise order, replacing every stretch
    /// that falls inside one of `cuts` by the circle's arc. `arcsOutside` picks which way the arc bulges: false keeps
    /// the arc inside the rectangle (a hole bitten out of the felt), true sends it outside (the opening in the rail
    /// frame grows around the pocket). Returns the points and, for each point, whether the edge to the NEXT point is
    /// an arc.
    static func rectWithCuts(hx: Float, hz: Float, cuts: [Cut], arcsOutside: Bool) -> (points: [SIMD2<Float>], arcEdge: [Bool]) {
        // Start part-way along the bottom edge, a spot no pocket reaches, so the walk never begins inside a circle.
        let start = SIMD2<Float>(-hx * 0.5, -hz)
        let corners: [SIMD2<Float>] = [SIMD2(hx, -hz), SIMD2(hx, hz), SIMD2(-hx, hz), SIMD2(-hx, -hz)]
        var segs: [(SIMD2<Float>, SIMD2<Float>)] = []
        var cur = start
        for c in corners { segs.append((cur, c)); cur = c }
        segs.append((cur, start))

        func inside(_ p: SIMD2<Float>, _ c: Cut) -> Bool { simd_length(p - c.center) < c.radius - 1e-6 }
        var pts: [SIMD2<Float>] = []
        var arcFlag: [Bool] = []
        func emit(_ p: SIMD2<Float>, arc: Bool) { pts.append(p); arcFlag.append(arc) }

        var pending: (cut: Cut, entry: SIMD2<Float>)?
        emit(start, arc: false)
        for (p0, p1) in segs {
            let d = p1 - p0
            let len = simd_length(d)
            let dir = d / len
            // Circle crossings of this edge as intervals along it, in order.
            var hits: [(t0: Float, t1: Float, cut: Cut)] = []
            for c in cuts {
                let f = p0 - c.center
                let b = simd_dot(f, dir)
                let disc = b * b - (simd_dot(f, f) - c.radius * c.radius)
                if disc <= 0 { continue }
                let s = disc.squareRoot()
                let t0 = -b - s, t1 = -b + s
                if t1 <= 0 || t0 >= len { continue }
                hits.append((t0, t1, c))
            }
            hits.sort { $0.t0 < $1.t0 }
            // A circle that already holds the start of this edge continues a pending arc from the previous edge.
            for h in hits {
                let entersHere = h.t0 > 0
                let exitsHere = h.t1 < len
                if entersHere { pending = (h.cut, p0 + dir * h.t0) }
                if exitsHere, let pend = pending {
                    let exit = p0 + dir * h.t1
                    let c = pend.cut
                    let a0 = atan2(pend.entry.y - c.center.y, pend.entry.x - c.center.x)
                    var a1 = atan2(exit.y - c.center.y, exit.x - c.center.x)
                    // Two ways round: pick the one whose middle falls on the wanted side of the rectangle.
                    func wrap(_ x: Float) -> Float { var v = x; while v > .pi { v -= 2 * .pi }; while v < -.pi { v += 2 * .pi }; return v }
                    let shortWay = wrap(a1 - a0)
                    var sweep = shortWay
                    let midShort = c.center + c.radius * SIMD2(cos(a0 + shortWay * 0.5), sin(a0 + shortWay * 0.5))
                    let insideRect = abs(midShort.x) < hx && abs(midShort.y) < hz
                    if insideRect == arcsOutside { sweep = shortWay > 0 ? shortWay - 2 * .pi : shortWay + 2 * .pi }
                    a1 = a0 + sweep
                    let arcPts = arc(center: c.center, radius: c.radius, from: a0, to: a1)
                    // The entry point may already be emitted (it ends the straight run); then it starts the arc.
                    if let l = pts.last, simd_length(l - arcPts[0]) < 1e-4 { arcFlag[arcFlag.count - 1] = true } else { emit(arcPts.first!, arc: true) }
                    for (qi, q) in arcPts.enumerated().dropFirst() { emit(q, arc: qi < arcPts.count - 1) }
                    pending = nil
                } else if entersHere {
                    // Entered on this edge, leaves on a later one: emit the entry point as the end of the straight run.
                    emit(p0 + dir * h.t0, arc: false)
                }
            }
            // The end of this edge is a corner of the rectangle, unless a circle swallows it.
            let swallowed = cuts.contains { inside(p1, $0) }
            if !swallowed && p1 != start { emit(p1, arc: false) }
        }
        // Drop a duplicated closing point.
        if pts.count > 1, simd_length(pts[0] - pts[pts.count - 1]) < 1e-5 { pts.removeLast(); arcFlag.removeLast() }
        return (pts, arcFlag)
    }
}

// MARK: - Mesh pieces

extension MeshBuilder {
    /// A flat face at height `y` filling an outline (already triangulated by ear clipping). `uv` maps a plan point to
    /// texture space, and may depend on the triangle's centre so each region can run its grain its own way.
    mutating func addFlat(_ pts: [SIMD2<Float>], y: Float, normal: SIMD3<Float>, uv: (SIMD2<Float>, SIMD2<Float>) -> SIMD2<Float>) {
        for (i, j, k) in Outline.triangulate(pts) {
            let centre = (pts[i] + pts[j] + pts[k]) / 3
            let ids = [i, j, k].map { n in vertex(SIMD3(pts[n].x, y, pts[n].y), normal, uv(pts[n], centre)) }
            tri(ids[0], ids[1], ids[2])
        }
    }

    /// A vertical wall standing on a plan polyline. `top` gives the height at each point, `bottom` is constant.
    /// `outward` holds the plan-view direction each point's face looks toward (smooth normals come from it).
    mutating func addWall(_ pts: [SIMD2<Float>], outward: [SIMD2<Float>], top: [Float], bottom: Float, closed: Bool,
                          uvScale: Float = 1, skip: [Bool]? = nil) {
        var run: Float = 0
        let n = pts.count
        let last = closed ? n : n - 1
        for i in 0..<last {
            let j = (i + 1) % n
            let seg = simd_length(pts[j] - pts[i])
            defer { run += seg }
            if let s = skip, s[i] { continue }
            let u0 = run * uvScale, u1 = (run + seg) * uvScale
            let n0 = SIMD3(outward[i].x, 0, outward[i].y), n1 = SIMD3(outward[j].x, 0, outward[j].y)
            let a = vertex(SIMD3(pts[i].x, top[i], pts[i].y), n0, SIMD2(u0, 0))
            let b = vertex(SIMD3(pts[j].x, top[j], pts[j].y), n1, SIMD2(u1, 0))
            let c = vertex(SIMD3(pts[j].x, bottom, pts[j].y), n1, SIMD2(u1, 1))
            let d = vertex(SIMD3(pts[i].x, bottom, pts[i].y), n0, SIMD2(u0, 1))
            quad(a, b, c, d)
        }
    }

    /// Per-point outward directions of a closed loop, averaged over the two neighbouring edges so lighting is smooth.
    /// "Outward" is the right-hand side when walking the loop counter-clockwise; pass `flip` to get the other side.
    static func loopNormals(_ pts: [SIMD2<Float>], flip: Bool = false) -> [SIMD2<Float>] {
        var ccw = pts
        let reversed = Outline.signedArea(pts) < 0
        if reversed { ccw.reverse() }
        let n = ccw.count
        var res = [SIMD2<Float>](repeating: .zero, count: n)
        for i in 0..<n {
            let p = ccw[(i + n - 1) % n], q = ccw[i], r = ccw[(i + 1) % n]
            func edgeNormal(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> SIMD2<Float> {
                let d = b - a
                let l = simd_length(d)
                return l > 1e-9 ? SIMD2(d.y, -d.x) / l : .zero   // right-hand side of a counter-clockwise walk
            }
            var v = edgeNormal(p, q) + edgeNormal(q, r)
            if simd_length(v) < 1e-9 { v = edgeNormal(q, r) }
            res[i] = simd_normalize(v) * (flip ? -1 : 1)
        }
        if reversed { res.reverse() }
        return res
    }

    /// A cross-section pushed along a closed loop. `profile` lists (offset outward from the loop, height) from the
    /// top down; `sign` is +1 when the face looks away from the loop's inside.
    mutating func addLoopProfile(_ loop: [SIMD2<Float>], profile: [(off: Float, y: Float)], smooth: [Bool],
                                 sign: Float = 1, uvAlong: Float = 1, uvAcross: Float = 1) {
        let outward = MeshBuilder.loopNormals(loop)
        let n = loop.count
        // Cumulative distance along the loop for texture coordinates.
        var run = [Float](repeating: 0, count: n + 1)
        for i in 0..<n { run[i + 1] = run[i] + simd_length(loop[(i + 1) % n] - loop[i]) }
        // Profile edge normals in (offset, height) space, pointing out of the solid.
        var edgeN: [SIMD2<Float>] = []
        for k in 0..<(profile.count - 1) {
            let d = SIMD2(profile[k + 1].off - profile[k].off, profile[k + 1].y - profile[k].y)
            let l = max(1e-9, simd_length(d))
            edgeN.append(SIMD2(-d.y, d.x) / l * SIMD2(sign, 1) * SIMD2(1, 1))
        }
        var across: [Float] = [0]
        for k in 1..<profile.count {
            across.append(across[k - 1] + simd_length(SIMD2(profile[k].off - profile[k - 1].off, profile[k].y - profile[k - 1].y)))
        }
        for k in 0..<(profile.count - 1) {
            for i in 0..<n {
                let j = (i + 1) % n
                func v(_ pi: Int, _ loopI: Int, _ edge: Int, _ u: Float) -> UInt32 {
                    var en = edgeN[edge]
                    if smooth[pi] {
                        let other = pi == edge ? edge - 1 : edge + 1
                        if other >= 0 && other < edgeN.count { en = simd_normalize(en + edgeN[other]) }
                    }
                    let o = outward[loopI]
                    let pt = profile[pi]
                    let pos = SIMD3(loop[loopI].x + o.x * pt.off, pt.y, loop[loopI].y + o.y * pt.off)
                    let nrm = SIMD3(o.x * en.x, en.y, o.y * en.x)
                    return vertex(pos, nrm, SIMD2(u * uvAlong, across[pi] * uvAcross))
                }
                let a = v(k, i, k, run[i]), b = v(k, j, k, run[i + 1])
                let c = v(k + 1, j, k, run[i + 1]), d = v(k + 1, i, k, run[i])
                quad(a, b, c, d)
            }
        }
    }

    /// A cross-section swept along a straight run whose two ends are cut to follow a pocket's round mouth (a cushion
    /// strip). The section is a closed polygon of (distance outward from the playing edge, height). `origin` is the
    /// edge point at along-distance 0, `along` and `outward` are unit plan vectors. Each end is given as the pocket's
    /// plan centre and mouth radius (`jaw0` for the start, `jaw1` for the end): a section point at outward distance d
    /// stops exactly where the circle crosses that line, so the cushion's end hugs the pocket wall with no gap and no
    /// step. The end faces get smooth normals that look toward the pocket centre, so they shade as a rounded jaw
    /// instead of a flat block. `uv` maps a world point to texture space.
    mutating func addSweep(section: [(d: Float, y: Float)], smooth: [Bool], origin: SIMD2<Float>, along: SIMD2<Float>,
                           outward: SIMD2<Float>, jaw0: (centre: SIMD2<Float>, radius: Float),
                           jaw1: (centre: SIMD2<Float>, radius: Float), uv: (SIMD3<Float>) -> SIMD2<Float>) {
        // Along-distance of each pocket centre, and which side of it the cushion lies on.
        let c0 = simd_dot(jaw0.centre - origin, along), c1 = simd_dot(jaw1.centre - origin, along)
        func plan(_ p: (d: Float, y: Float), end: Int) -> SIMD2<Float> {
            let j = end == 0 ? jaw0 : jaw1
            // Distance from the pocket centre along the run where the mouth circle crosses this outward distance.
            let reach = (max(0, j.radius * j.radius - p.d * p.d)).squareRoot()
            let s = end == 0 ? c0 + reach : c1 - reach
            return origin + along * s + outward * p.d
        }
        func pos(_ p: (d: Float, y: Float), end: Int) -> SIMD3<Float> {
            let q = plan(p, end: end)
            return SIMD3(q.x, p.y, q.y)
        }
        let n = section.count
        // Which way is "out of the solid" for each section edge: away from the section's centroid.
        let cd = section.map { $0.d }.reduce(0, +) / Float(n), cy = section.map { $0.y }.reduce(0, +) / Float(n)
        var edgeN: [SIMD2<Float>] = []
        for i in 0..<n {
            let a = section[i], b = section[(i + 1) % n]
            var nrm = SIMD2(b.y - a.y, -(b.d - a.d))
            let l = max(1e-9, simd_length(nrm)); nrm /= l
            let mid = SIMD2((a.d + b.d) * 0.5 - cd, (a.y + b.y) * 0.5 - cy)
            if simd_dot(nrm, mid) < 0 { nrm = -nrm }
            edgeN.append(nrm)
        }
        for i in 0..<n {
            let j = (i + 1) % n
            func vert(_ pi: Int, end: Int) -> UInt32 {
                var en = edgeN[i]
                if smooth[pi] {
                    let other = pi == i ? (i + n - 1) % n : (i + 1) % n
                    en = simd_normalize(en + edgeN[other])
                }
                let p = pos(section[pi], end: end)
                let nrm3 = SIMD3(outward.x * en.x, en.y, outward.y * en.x)
                return vertex(p, nrm3, uv(p))
            }
            let a0 = vert(i, end: 0), b0 = vert(j, end: 0), a1 = vert(i, end: 1), b1 = vert(j, end: 1)
            quad(a0, b0, b1, a1)
        }
        // End caps: flat polygons, normal along the run direction.
        for end in 0..<2 {
            let pts2 = section.map { SIMD2($0.d, $0.y) }
            let centre = end == 0 ? jaw0.centre : jaw1.centre
            for (i, j, k) in Outline.triangulate(pts2) {
                let ids = [i, j, k].map { m -> UInt32 in
                    let p = pos(section[m], end: end)
                    // Looks toward the pocket centre.
                    let flat = SIMD3(centre.x - p.x, 0, centre.y - p.z)
                    // Tilted up a little so the overhead lamp catches the jaw and it reads as a rounded, felt-covered face.
                    let toPocket = simd_length(flat) > 1e-6 ? simd_normalize(flat) + SIMD3(0, 0.7, 0) : flat
                    return vertex(p, simd_length(toPocket) > 1e-6 ? toPocket : SIMD3(along.x, 0, along.y), uv(p))
                }
                tri(ids[0], ids[1], ids[2])
            }
        }
    }
}
