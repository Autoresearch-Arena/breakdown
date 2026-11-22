# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Exports the pool table's pockets for the Breakdown app from the other developer's hero corner pocket
#          (art/equipment/hero-corner-pocket.blend) and makes the matching side pocket from the same profiles, as
#          App/Models/CornerPocket.usdz and App/Models/SidePocket.usdz. Run headless:
#              /opt/homebrew/bin/blender -b --factory-startup --python Tools/blender/make_pockets.py
#          Deterministic: same source file and code, same output. Replaces make_pocket.py and its generic leather cup
#          (plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 33).
#          The hero file is a whole corner of a table at full size (bed, cushions, rails, apron, sights) built round the
#          solver's own corner: its hole is the solver's capture circle (0.065 m round the point where the two cushion
#          nose lines meet), its knuckles sit 0.0853 m along each nose (the 0.1207 m corner mouth) and its jaw faces
#          lean back along the solver's corner jaw. Only three of its parts are the pocket; the rest of the corner is
#          built in code by TableBuilder and must not be shipped twice:
#            PocketLiner - "Flush pocket liner": the dark liner round the back of the pocket, from just above the cloth
#                          up to a flat lip flush with the rail top, spanning the back of the hole between the jaws.
#            PocketSlate - "Slate edge beneath the cloth": the cut edge of the slate below the cloth hole.
#            PocketFunnel - "Funnel and catch basket": the dark funnel below the slate that the ball drops into. The
#                          hero leaves its bottom open (a 30 mm hole that would show the floor through the table), so a
#                          flat cap is added at its bottom ring.
#          Output contract (TableRoom.swift, "pocket liners"), RealityKit frame: +Y up, metres, the hole's centre at the
#          origin with the cloth at y = 0, the back of the pocket (away from the table) along +Z. Swift turns each copy
#          about Y to its pocket's back direction and scales x and z by the drawn hole radius over the model's own:
#            CornerPocket.usdz - hole radius 0.065 (CORNER_HOLE_R), liner over +/-79 degrees of the back.
#            SidePocket.usdz   - hole radius SIDE_HOLE_R, liner over +/-SIDE_HALF_ARC of the back.
#          The hero was modelled with a 47 mm rail; the app's rail top is 60 mm (TableBuilder.railTop), so the liner is
#          stretched upward from its foot (y = 5 mm) so its lip lies flush with the app's rail.
#          The side pocket uses the hero's own sections (liner, slate, funnel) as offsets from the hole edge, swept round
#          the side hole the app draws: centred SIDE_SHIFT behind the nose line and just big enough to hold the throat
#          between the side jaws (the same rule TableBuilder.pocketCuts uses). Its liner ends where its foot meets the
#          back of the cushion, as the hero's does (the hero's liner ends just behind the cushion's back face), so no part
#          of the liner stands inside the cushion zone where it would poke through the cushion's top.
#          Geometry only: no materials, cameras or lights are exported; Swift assigns materials by part name.
#          After export each file is read back with pxr and every contract number is checked; exits non-zero on failure.
# SRP/DRY check: Pass - replaces make_pocket.py (deleted); follows its export-and-verify steps and make_bridge.py's
#          pattern. The solver numbers copied below (marked "keep in step") mirror BreakdownPhysics' PoolParameters and
#          TableBuilder, because a Blender script cannot read Swift.

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
HERO = os.path.join(REPO, "art", "equipment", "hero-corner-pocket.blend")
CORNER_OUT = os.path.join(REPO, "App", "Models", "CornerPocket.usdz")
SIDE_OUT = os.path.join(REPO, "App", "Models", "SidePocket.usdz")

HERO_PARTS = {
    "PocketLiner": "Flush pocket liner",
    "PocketSlate": "Slate edge beneath the cloth",
    "PocketFunnel": "Funnel and catch basket",
}

# ---------------------------------------------------------------- numbers (metres), keep in step with the app
APP_RAIL_TOP = 0.060          # TableBuilder.railTop
LINER_FOOT = 0.005            # the hero liner's lowest ring stays where it is; everything above it is stretched
CUSHION_DEPTH = 0.045         # TableBuilder.cushionDepth
SIDE_MOUTH = 0.1334           # PoolParameters.sideMouth
SIDE_JAW = (-0.241922, -0.970296)   # PoolParameters.sideJaw: (along the rail, out of the table) for the right knuckle
SIDE_CAPTURE = 0.052          # PoolParameters.sideCaptureRadius
SIDE_SHIFT = 0.011            # TableBuilder.pocketCuts: the side hole is drawn this far behind the nose line
HOLE_MARGIN = 0.003           # TableBuilder.pocketCuts: the throat's back corners stay this far inside the hole

# The corner hole the hero is built round, read from the hero (its slate radius) and checked against the solver.
SOLVER_CORNER_CAPTURE = 0.065  # PoolParameters.cornerCaptureRadius

# The side hole the app draws, by TableBuilder.pocketCuts' rule: the capture circle (moved back by the shift) and the
# back ends of both jaw faces (where each jaw line meets the back of the cushion) must lie inside it.
_KNUCKLE_X = SIDE_MOUTH * 0.5
_JAW_T = CUSHION_DEPTH / -SIDE_JAW[1]
_JAW_BACK = (_KNUCKLE_X + SIDE_JAW[0] * _JAW_T, -CUSHION_DEPTH)   # plan (along the rail, out of the table is -y)
_JAW_BACK_FROM_CENTRE = (_JAW_BACK[0], _JAW_BACK[1] + SIDE_SHIFT)
SIDE_HOLE_R = max(SIDE_CAPTURE + SIDE_SHIFT, math.hypot(*_JAW_BACK_FROM_CENTRE) + HOLE_MARGIN)


def side_half_arc(liner_foot_r):
    """Half the side liner's arc, radians from the back: as far round as its foot (the innermost ring) stays behind the
    back of the cushion (plan y <= -CUSHION_DEPTH, measured from the nose line)."""
    c = (CUSHION_DEPTH - SIDE_SHIFT) / liner_foot_r
    return math.acos(min(1.0, c))


# ---------------------------------------------------------------- reading the hero
def load_hero():
    """Append the three pocket parts from the hero file and return {name: (verts, faces)} in the hero's own Z-up frame
    (world positions), faces as vertex index tuples."""
    with bpy.data.libraries.load(HERO, link=False) as (src, dst):
        missing = [n for n in HERO_PARTS.values() if n not in src.objects]
        if missing:
            raise RuntimeError("hero file lacks %s" % missing)
        dst.objects = list(HERO_PARTS.values())
    out = {}
    for key, name in HERO_PARTS.items():
        obj = bpy.data.objects[name]
        mw = obj.matrix_world
        verts = [tuple(mw @ v.co) for v in obj.data.vertices]
        faces = [tuple(p.vertices) for p in obj.data.polygons]
        out[key] = (verts, faces)
    # The appended objects are only data sources; remove them before building the export scene.
    for name in HERO_PARTS.values():
        bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)
    return out


def hero_back_dir():
    """The hero's corner sits at the origin with the table toward +x and +y (its cushion noses run along both axes), so
    the back of the pocket is the diagonal (-1, -1)."""
    return (-1.0 / math.sqrt(2.0), -1.0 / math.sqrt(2.0))


def to_app_frame(p, back):
    """Hero Z-up (x, y, z) to the app's Y-up frame with the pocket's back along +Z: Y is the hero's z, Z is the plan
    component along `back`, X = Y x Z (so the turn is a proper rotation and face winding is kept)."""
    bx, by = back
    x, y, z = p
    return (x * -by + y * bx, z, x * bx + y * by)


def profile(verts):
    """Distinct (radius, height) rings of a lathed part in the app frame, bottom first."""
    rings = sorted({(round(math.hypot(v[0], v[2]), 4), round(v[1], 4)) for v in verts}, key=lambda q: (q[1], q[0]))
    return rings


# ---------------------------------------------------------------- building
def make_object(name, verts, faces, smooth_angle):
    """Named mesh object; object and mesh data share the name so the USD prim carries it."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(v) for v in verts], [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    mesh.set_sharp_from_angle(angle=smooth_angle)
    return obj


def stretch_liner(v, hero_top):
    """Lift the liner so its lip meets the app's taller rail: heights above the foot scale by (60 - 5) / (47 - 5)."""
    x, y, z = v
    k = (APP_RAIL_TOP - LINER_FOOT) / (hero_top - LINER_FOOT)
    return (x, LINER_FOOT + (y - LINER_FOOT) * k, z)


def cap_bottom(verts, faces):
    """Close a lathed shell's lowest ring with a fan to a centre point (the hero funnel's open bottom)."""
    ymin = min(v[1] for v in verts)
    ring = [i for i, v in enumerate(verts) if abs(v[1] - ymin) < 1e-6]
    ring.sort(key=lambda i: math.atan2(verts[i][2], verts[i][0]))
    centre = len(verts)
    verts = verts + [(0.0, ymin, 0.0)]
    faces = faces + [(centre, ring[k], ring[(k + 1) % len(ring)]) for k in range(len(ring))]
    return verts, faces


def lathe_arc(prof, radius_of, half_arc, steps):
    """Sweep a (r, y) profile (bottom first) about +Y over +/-half_arc round +Z (a full circle when half_arc is None).
    radius_of(r) maps the hero radius to this pocket's."""
    full = half_arc is None
    n = steps if full else steps + 1
    verts, faces = [], []
    for (r, y) in prof:
        rr = radius_of(r)
        for k in range(n):
            a = (2.0 * math.pi * k / steps) if full else (-half_arc + 2.0 * half_arc * k / steps)
            verts.append((rr * math.sin(a), y, rr * math.cos(a)))
    for j in range(len(prof) - 1):
        for k in range(steps if full else n - 1):
            k1 = (k + 1) % n
            a, b = j * n + k, j * n + k1
            faces.append((a, b, b + n, a + n))
    return verts, faces


def liner_section(verts):
    """The hero liner's section in the app frame: one ring per height, except the flat lip at the top, which has an
    inner and an outer edge. Returned bottom first as (r, y)."""
    rings = profile(verts)
    by_y = {}
    for r, y in rings:
        by_y.setdefault(y, []).append(r)
    out = []
    for y in sorted(by_y):
        rs = sorted(set(by_y[y]))
        if len(rs) == 1:
            out.append((rs[0], y))
        else:
            out.append((rs[0], y))
            out.append((rs[-1], y))
    return out


def build_corner(hero):
    back = hero_back_dir()
    parts = {}
    for key, (verts, faces) in hero.items():
        parts[key] = ([to_app_frame(v, back) for v in verts], list(faces))
    lv, lf = parts["PocketLiner"]
    hero_top = max(v[1] for v in lv)
    parts["PocketLiner"] = ([stretch_liner(v, hero_top) for v in lv], lf)
    parts["PocketFunnel"] = cap_bottom(*parts["PocketFunnel"])
    for key, (v, f) in parts.items():
        make_object(key, v, f, math.radians(50.0))
    hole_r = max(math.hypot(v[0], v[2]) for v in parts["PocketSlate"][0])
    return parts, hole_r, hero_top


def build_side(hero_app, hero_hole_r):
    """The side pocket from the corner's sections (hero_app: the corner parts in the app frame), each ring moved out by (side hole - hero hole), swept round the side
    hole: the liner over the back only, the slate and funnel all the way round."""
    shift = SIDE_HOLE_R - hero_hole_r
    # hero_app holds the corner as built for the app, so its liner is already stretched to the app's rail.
    liner = liner_section(hero_app["PocketLiner"][0])
    foot_r = liner[0][0] + shift
    half_arc = side_half_arc(foot_r)
    # The hero's liner runs 64 segments over its arc; keep the same angular step so both pockets look alike.
    hero_arc = 2.0 * math.radians(79.0)
    steps = max(8, int(round(64 * (2.0 * half_arc) / hero_arc)))
    v, f = lathe_arc(liner, lambda r: r + shift, half_arc, steps)
    make_object("PocketLiner", v, f, math.radians(50.0))
    slate = profile(hero_app["PocketSlate"][0])
    v, f = lathe_arc(slate, lambda r: r + shift, None, 160)
    make_object("PocketSlate", v, f, math.radians(50.0))
    funnel = profile(hero_app["PocketFunnel"][0])
    funnel = [q for q in funnel if q[0] > 0]           # drop the cap's centre point; the cap is rebuilt below
    v, f = lathe_arc(funnel, lambda r: r + shift, None, 160)
    v, f = cap_bottom(v, f)
    make_object("PocketFunnel", v, f, math.radians(50.0))
    return half_arc


# ---------------------------------------------------------------- export and verification
def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(coll):
            coll.remove(item)


def export(path):
    """Plain .usdc to a temp folder, stamped Y-up / metres with pxr, then packed as .usdz (as make_bridge.py). The
    geometry is already in the app's Y-up frame, so Blender's own axis conversion stays off."""
    import shutil
    import tempfile
    from pxr import Usd, UsdGeom, UsdUtils
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp_dir = tempfile.mkdtemp(prefix="pockets_usd_")
    tmp = os.path.join(tmp_dir, os.path.splitext(os.path.basename(path))[0] + ".usdc")
    bpy.ops.wm.usd_export(
        filepath=tmp, selected_objects_only=False, export_animation=False, export_materials=False,
        export_uvmaps=False, export_mesh_colors=False, export_normals=True, export_lights=False,
        export_cameras=False, export_curves=False, export_points=False, export_volumes=False, export_hair=False,
        export_armatures=False, export_shapekeys=False, export_custom_properties=False,
        convert_world_material=False, generate_preview_surface=False,
        convert_orientation=False, convert_scene_units="METERS", triangulate_meshes=True,
        merge_parent_xform=True, evaluation_mode="RENDER")
    stage = Usd.Stage.Open(tmp)
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    UsdGeom.SetStageMetersPerUnit(stage, 1.0)
    stage.GetRootLayer().Save()
    if os.path.exists(path):
        os.remove(path)
    if not UsdUtils.CreateNewUsdzPackage(tmp, path):
        raise RuntimeError("usdz packaging failed")
    shutil.rmtree(tmp_dir, ignore_errors=True)


def verify(path, hole_r, half_arc_deg):
    """Read the file back and check the contract: Y up, metres, the three parts, the slate on the hole edge from the
    cloth down, the liner's lip flush with the app's rail and its foot just above the cloth, the liner only over the
    back (within half_arc_deg of +Z), and the funnel below the cloth and closed."""
    from pxr import Gf, Usd, UsdGeom
    stage = Usd.Stage.Open(path)
    errs, rep = [], {}
    if UsdGeom.GetStageUpAxis(stage) != "Y":
        errs.append("up axis %s" % UsdGeom.GetStageUpAxis(stage))
    if abs(UsdGeom.GetStageMetersPerUnit(stage) - 1.0) > 1e-9:
        errs.append("metersPerUnit")
    cache = UsdGeom.XformCache()
    parts, tris = {}, 0
    for prim in stage.Traverse():
        t = prim.GetTypeName()
        if t == "Camera" or "Light" in t or t == "Material":
            errs.append("junk prim %s" % prim.GetPath())
        if not prim.IsA(UsdGeom.Mesh):
            continue
        mesh = UsdGeom.Mesh(prim)
        xf = cache.GetLocalToWorldTransform(prim)
        parts[prim.GetName()] = [xf.Transform(Gf.Vec3d(p)) for p in mesh.GetPointsAttr().Get()]
        tris += sum(c - 2 for c in mesh.GetFaceVertexCountsAttr().Get())
    rep["triangles"] = tris
    if tris > 12000:
        errs.append("too many triangles %d" % tris)
    for name in ("PocketLiner", "PocketSlate", "PocketFunnel"):
        if name not in parts:
            errs.append("missing part %s" % name)
    if errs:
        rep["errors"] = errs
        return rep

    def r_of(p):
        return math.hypot(p[0], p[2])

    slate = parts["PocketSlate"]
    rep["slate"] = (min(p[1] for p in slate), max(p[1] for p in slate), min(map(r_of, slate)), max(map(r_of, slate)))
    if abs(max(p[1] for p in slate)) > 1e-4:
        errs.append("slate top %.5f is not at the cloth" % max(p[1] for p in slate))
    if abs(max(map(r_of, slate)) - hole_r) > 2e-4 or abs(min(map(r_of, slate)) - hole_r) > 2e-4:
        errs.append("slate is not on the hole edge %.5f" % hole_r)
    liner = parts["PocketLiner"]
    top = max(p[1] for p in liner)
    foot = min(p[1] for p in liner)
    arc = max(abs(math.degrees(math.atan2(p[0], p[2]))) for p in liner)
    rep["liner"] = (foot, top, min(map(r_of, liner)), max(map(r_of, liner)), arc)
    if abs(top - APP_RAIL_TOP) > 1e-4:
        errs.append("liner lip %.5f is not flush with the rail" % top)
    if not (0.0 < foot < 0.01):
        errs.append("liner foot %.5f is not just above the cloth" % foot)
    if arc > half_arc_deg + 0.5:
        errs.append("liner reaches %.2f deg from the back (limit %.2f)" % (arc, half_arc_deg))
    funnel = parts["PocketFunnel"]
    rep["funnel"] = (min(p[1] for p in funnel), max(p[1] for p in funnel), min(map(r_of, funnel)))
    if max(p[1] for p in funnel) > -0.005:
        errs.append("funnel rises to %.5f, above the slate's foot of the cloth" % max(p[1] for p in funnel))
    if min(map(r_of, funnel)) > 1e-6:
        errs.append("funnel bottom is open")
    rep["errors"] = errs
    return rep


def report(label, rep):
    print("%s REPORT" % label)
    for k, v in rep.items():
        print("  %s: %s" % (k, v))
    return bool(rep["errors"])


def main():
    clear_scene()
    hero = load_hero()
    parts, hole_r, hero_top = build_corner(hero)
    if abs(hole_r - SOLVER_CORNER_CAPTURE) > 2e-4:
        print("POCKET CHECK FAILED: the hero's hole %.5f is not the solver's corner capture circle" % hole_r)
        sys.exit(1)
    # The hero's liner arc, measured, is the corner's contract (TableRoom.cornerLinerHalfArc).
    corner_arc = max(abs(math.degrees(math.atan2(v[0], v[2]))) for v in parts["PocketLiner"][0])
    export(CORNER_OUT)
    failed = report("CORNER POCKET", verify(CORNER_OUT, hole_r, corner_arc))
    print("  corner hole radius %.5f, liner half arc %.2f deg" % (hole_r, corner_arc))

    clear_scene()
    half_arc = build_side(parts, hole_r)
    export(SIDE_OUT)
    failed = report("SIDE POCKET", verify(SIDE_OUT, SIDE_HOLE_R, math.degrees(half_arc))) or failed
    print("  side hole radius %.5f, liner half arc %.2f deg" % (SIDE_HOLE_R, math.degrees(half_arc)))
    if failed:
        print("POCKET CHECK FAILED")
        sys.exit(1)
    print("POCKET CHECK PASSED")


main()
