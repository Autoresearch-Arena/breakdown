# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# Edited: Claude Opus 5.5 High, 21-November-2026 (comment only: make_pocket.py became make_pockets.py).
# PURPOSE: Generates the room's models for the Breakdown app: the long lamp shade that hangs over the table, a
#          wall-mounted cue rack, a bar stool and a cube of chalk, as four files in App/Models (LampShade.usdz,
#          CueRack.usdz, Stool.usdz, Chalk.usdz). Run headless:
#              /opt/homebrew/bin/blender -b --factory-startup --python Tools/blender/make_room.py
#          Deterministic: same code, same files.
#          Why: from the low Ride camera the space above the far rail was bare black. The room (walls, waist rail,
#          floor) is built in code by TableBuilder (TableRoom.swift); these are the shaped things in it, so the light
#          has a visible source and the dark has something in it.
#          Output contract (TableRoom.swift places and dresses them by part name; +Y up, metres, RealityKit frame):
#            LampShade.usdz, origin at the centre of the shade's bottom opening, long side along X:
#              ShadeOuter - the enamelled sheet-metal shade, open at the bottom: a sloped trapezoid hood from the
#                           opening (SHADE_LEN x SHADE_WID at y = 0) to a narrower top (y = SHADE_H).
#              ShadeInner - the same hood 3 mm inside the outer one: the white reflector Swift lights from inside.
#              ShadeTrim  - a thin brass band round the bottom opening.
#              ShadeBulbs - three bulbs inside, centred on y = BULB_Y.
#              ShadeRods  - two hanging rods from the top of the shade up to y = ROD_TOP (into the ceiling).
#            CueRack.usdz, origin at the bottom centre of the back board on the wall (the wall is z = 0, the rack
#            stands out along +Z):
#              RackBoard  - the wooden back board.  RackRails - the cup rail at the bottom and the clip rail at the top.
#              RackCues   - five cues standing in the rack.
#            Stool.usdz, origin on the floor under the seat's centre:
#              StoolSeat  - the round padded seat.  StoolFrame - four splayed legs and the foot ring.
#            Chalk.usdz, origin at the bottom centre:
#              ChalkWrap  - the paper-wrapped cube.  ChalkFace - the worn chalk face on top.
#          Geometry only: no materials, cameras or lights are exported; Swift assigns materials by part name.
#          After export each file is read back with pxr and its contract numbers checked; exits non-zero on failure.
# SRP/DRY check: Pass - follows make_bumper_pool.py and the old make_pocket.py, now make_pockets.py (lathe, named-object, export and verify steps);
#          those helpers are private to each script by the established pattern in Tools/blender. One script makes all
#          four room models because they share every helper and are only ever rebuilt together.

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MODELS = os.path.join(REPO, "App", "Models")

# ---------------------------------------------------------------- contract numbers (metres)
# Lamp: a classic long billiard shade over a 9-foot table covers most of the bed; this one is 1.30 m long so the
# pool of light reaches the pockets, and TableRoom.swift scales it with the table's length for the other tables.
SHADE_LEN = 1.30
SHADE_WID = 0.36
SHADE_TOP_LEN = 1.16
SHADE_TOP_WID = 0.16
SHADE_H = 0.17
SHADE_SKIN = 0.003          # gap between the outer hood and the inner reflector
BULB_Y = 0.105
BULB_R = 0.032
BULB_X = (-0.40, 0.0, 0.40)
ROD_X = 0.45
ROD_R = 0.004
ROD_TOP = 1.70              # into the ceiling: the shade hangs 0.86 m above the cloth and the ceiling is 2.4 m up

# Cue rack.
BOARD_W = 0.56
BOARD_H = 1.30
BOARD_D = 0.025
CUP_Y = 0.10
CLIP_Y = 1.02
CUE_LEN = 1.47
CUE_COUNT = 5

# Stool.
SEAT_R = 0.19
SEAT_TOP = 0.76
SEAT_T = 0.065
LEG_R = 0.016
RING_Y = 0.27

# Chalk (a standard cube is about 22 mm).
CHALK = 0.022

SEGMENTS = 32


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


def fix_normals(obj):
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()


def merge(parts):
    """Joins several (verts, faces) pieces into one."""
    verts, faces = [], []
    for v, f in parts:
        base = len(verts)
        verts += v
        faces += [tuple(i + base for i in face) for face in f]
    return verts, faces


def box(cx, cy, cz, sx, sy, sz):
    """An axis-aligned box centred on (cx, cy, cz) with full sizes (sx, sy, sz)."""
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    v = [(cx + x, cy + y, cz + z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return v, f


def tube(p0, p1, r0, r1, segments=SEGMENTS):
    """A closed tapered cylinder from p0 (radius r0) to p1 (radius r1)."""
    ax = [p1[i] - p0[i] for i in range(3)]
    length = math.sqrt(sum(a * a for a in ax))
    ax = [a / length for a in ax]
    ref = (1.0, 0.0, 0.0) if abs(ax[0]) < 0.9 else (0.0, 0.0, 1.0)
    u = [ax[1] * ref[2] - ax[2] * ref[1], ax[2] * ref[0] - ax[0] * ref[2], ax[0] * ref[1] - ax[1] * ref[0]]
    lu = math.sqrt(sum(a * a for a in u))
    u = [a / lu for a in u]
    w = [ax[1] * u[2] - ax[2] * u[1], ax[2] * u[0] - ax[0] * u[2], ax[0] * u[1] - ax[1] * u[0]]
    verts, faces = [], []
    for p, r in ((p0, r0), (p1, r1)):
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            verts.append(tuple(p[i] + r * (math.cos(a) * u[i] + math.sin(a) * w[i]) for i in range(3)))
    for k in range(segments):
        k1 = (k + 1) % segments
        faces.append((k, k1, segments + k1, segments + k))
    verts.append(tuple(p0)); verts.append(tuple(p1))
    c0, c1 = len(verts) - 2, len(verts) - 1
    for k in range(segments):
        k1 = (k + 1) % segments
        faces.append((c0, k1, k))
        faces.append((c1, segments + k, segments + k1))
    return verts, faces


def sphere(c, r, rings=10, segments=SEGMENTS):
    verts, faces = [], []
    verts.append((c[0], c[1] + r, c[2]))
    for i in range(1, rings):
        t = math.pi * i / rings
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            verts.append((c[0] + r * math.sin(t) * math.cos(a), c[1] + r * math.cos(t), c[2] + r * math.sin(t) * math.sin(a)))
    verts.append((c[0], c[1] - r, c[2]))
    bottom = len(verts) - 1
    for k in range(segments):
        faces.append((0, 1 + (k + 1) % segments, 1 + k))
    for i in range(rings - 2):
        a0, a1 = 1 + i * segments, 1 + (i + 1) * segments
        for k in range(segments):
            k1 = (k + 1) % segments
            faces.append((a0 + k, a0 + k1, a1 + k1, a1 + k))
    last = 1 + (rings - 2) * segments
    for k in range(segments):
        faces.append((last + k, last + (k + 1) % segments, bottom))
    return verts, faces


def torus(cy, major, minor, segments=SEGMENTS, sides=10):
    verts, faces = [], []
    for k in range(segments):
        a = 2.0 * math.pi * k / segments
        for j in range(sides):
            b = 2.0 * math.pi * j / sides
            r = major + minor * math.cos(b)
            verts.append((r * math.cos(a), cy + minor * math.sin(b), r * math.sin(a)))
    for k in range(segments):
        k1 = (k + 1) % segments
        for j in range(sides):
            j1 = (j + 1) % sides
            faces.append((k * sides + j, k1 * sides + j, k1 * sides + j1, k * sides + j1))
    return verts, faces


def hood(inset):
    """The shade's sloped hood: four sides and a flat top, open at the bottom, moved `inset` inward everywhere."""
    hl0, hw0 = SHADE_LEN / 2 - inset, SHADE_WID / 2 - inset
    hl1, hw1 = SHADE_TOP_LEN / 2 - inset, SHADE_TOP_WID / 2 - inset
    top = SHADE_H - inset
    v = [(-hl0, 0.0, -hw0), (hl0, 0.0, -hw0), (hl0, 0.0, hw0), (-hl0, 0.0, hw0),
         (-hl1, top, -hw1), (hl1, top, -hw1), (hl1, top, hw1), (-hl1, top, hw1)]
    f = [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)]
    return v, f


# ---------------------------------------------------------------- the four models
def build_lamp():
    v, f = hood(0.0)
    make_object("ShadeOuter", v, f, math.radians(30.0))
    v, f = hood(SHADE_SKIN)
    make_object("ShadeInner", v, f, math.radians(30.0))
    # Brass band round the opening: four thin boxes just outside the hood's bottom edge.
    hl, hw, t, h = SHADE_LEN / 2, SHADE_WID / 2, 0.006, 0.018
    trim = merge([box(0, h / 2, -hw - t / 2 + 0.001, SHADE_LEN + 2 * t, h, t), box(0, h / 2, hw + t / 2 - 0.001, SHADE_LEN + 2 * t, h, t),
                  box(-hl - t / 2 + 0.001, h / 2, 0, t, h, SHADE_WID), box(hl + t / 2 - 0.001, h / 2, 0, t, h, SHADE_WID)])
    obj = make_object("ShadeTrim", trim[0], trim[1], math.radians(30.0))
    fix_normals(obj)
    bulbs = merge([sphere((x, BULB_Y, 0.0), BULB_R) for x in BULB_X])
    obj = make_object("ShadeBulbs", bulbs[0], bulbs[1], math.radians(80.0))
    fix_normals(obj)
    rods = merge([tube((x, SHADE_H - SHADE_SKIN, 0.0), (x, ROD_TOP, 0.0), ROD_R, ROD_R, 12) for x in (-ROD_X, ROD_X)])
    obj = make_object("ShadeRods", rods[0], rods[1], math.radians(40.0))
    fix_normals(obj)


def build_rack():
    v, f = box(0, BOARD_H / 2, BOARD_D / 2, BOARD_W, BOARD_H, BOARD_D)
    obj = make_object("RackBoard", v, f, math.radians(30.0))
    fix_normals(obj)
    rails = merge([box(0, CUP_Y, BOARD_D + 0.045, BOARD_W, 0.035, 0.09),
                   box(0, CLIP_Y, BOARD_D + 0.03, BOARD_W, 0.03, 0.06)])
    obj = make_object("RackRails", rails[0], rails[1], math.radians(30.0))
    fix_normals(obj)
    cues = []
    for k in range(CUE_COUNT):
        x = (k - (CUE_COUNT - 1) / 2) * (BOARD_W - 0.12) / (CUE_COUNT - 1)
        z = BOARD_D + 0.045
        # Butt in the cup rail, leaning back a hair against the clip rail.
        cues.append(tube((x, CUP_Y - 0.01, z), (x, CUP_Y - 0.01 + CUE_LEN, z - 0.02), 0.0145, 0.0065, 16))
    cues = merge(cues)
    obj = make_object("RackCues", cues[0], cues[1], math.radians(40.0))
    fix_normals(obj)


def build_stool():
    seat = merge([tube((0, SEAT_TOP - SEAT_T, 0), (0, SEAT_TOP - 0.012, 0), SEAT_R - 0.004, SEAT_R),
                  tube((0, SEAT_TOP - 0.012, 0), (0, SEAT_TOP, 0), SEAT_R, SEAT_R - 0.014)])
    obj = make_object("StoolSeat", seat[0], seat[1], math.radians(35.0))
    fix_normals(obj)
    parts = []
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        top = (0.11 * math.cos(a), SEAT_TOP - SEAT_T, 0.11 * math.sin(a))
        foot = (0.20 * math.cos(a), 0.0, 0.20 * math.sin(a))
        parts.append(tube(foot, top, LEG_R, LEG_R * 0.85, 12))
    # The foot ring sits where the splayed legs pass: the legs run from 0.20 m out at the floor to 0.11 m at the seat.
    ring_r = 0.20 - (0.20 - 0.11) * RING_Y / (SEAT_TOP - SEAT_T)
    parts.append(torus(RING_Y, ring_r, 0.008))
    frame = merge(parts)
    obj = make_object("StoolFrame", frame[0], frame[1], math.radians(40.0))
    fix_normals(obj)


def build_chalk():
    v, f = box(0, CHALK * 0.47, 0, CHALK, CHALK * 0.94, CHALK)
    obj = make_object("ChalkWrap", v, f, math.radians(30.0))
    fix_normals(obj)
    v, f = box(0, CHALK * 0.94 + 0.0005, 0, CHALK * 0.86, 0.001, CHALK * 0.86)
    obj = make_object("ChalkFace", v, f, math.radians(30.0))
    fix_normals(obj)


# ---------------------------------------------------------------- export and verification
def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(coll):
            coll.remove(item)


def export(path):
    """Plain .usdc to a temp folder, stamped Y-up / metres with pxr, then packed as .usdz (as make_bridge.py)."""
    import shutil
    import tempfile
    from pxr import Usd, UsdGeom, UsdUtils
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp_dir = tempfile.mkdtemp(prefix="room_usd_")
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


def read_parts(path, errs):
    from pxr import Gf, Usd, UsdGeom
    stage = Usd.Stage.Open(path)
    if UsdGeom.GetStageUpAxis(stage) != "Y":
        errs.append("%s: up axis %s" % (path, UsdGeom.GetStageUpAxis(stage)))
    if abs(UsdGeom.GetStageMetersPerUnit(stage) - 1.0) > 1e-9:
        errs.append("%s: metersPerUnit" % path)
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
    return parts, tris


def bounds(pts):
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]


def verify(path, names, checks):
    errs, rep = [], {}
    parts, tris = read_parts(path, errs)
    rep["triangles"] = tris
    if tris > 12000:
        errs.append("too many triangles %d" % tris)
    for name in names:
        if name not in parts:
            errs.append("missing part %s" % name)
    if not errs:
        checks(parts, errs, rep)
    rep["errors"] = errs
    return rep


def near(a, b, tol=2e-4):
    return abs(a - b) <= tol


def check_lamp(parts, errs, rep):
    lo, hi = bounds(parts["ShadeOuter"])
    rep["shade"] = (lo, hi)
    if not near(lo[1], 0.0) or not near(hi[1], SHADE_H):
        errs.append("shade height %.4f..%.4f" % (lo[1], hi[1]))
    if not near(hi[0] - lo[0], SHADE_LEN) or not near(hi[2] - lo[2], SHADE_WID):
        errs.append("shade footprint %.4f x %.4f" % (hi[0] - lo[0], hi[2] - lo[2]))
    blo, bhi = bounds(parts["ShadeBulbs"])
    if blo[1] < 0.0 or bhi[1] > SHADE_H - SHADE_SKIN:
        errs.append("bulbs outside the hood")
    rlo, rhi = bounds(parts["ShadeRods"])
    if not near(rhi[1], ROD_TOP):
        errs.append("rods top %.4f" % rhi[1])


def check_rack(parts, errs, rep):
    lo, hi = bounds(parts["RackBoard"])
    if not near(lo[2], 0.0) or not near(lo[1], 0.0):
        errs.append("board not on the wall at the origin")
    clo, chi = bounds(parts["RackCues"])
    rep["cues"] = (clo, chi)
    if clo[2] < 0.0:
        errs.append("cues pass through the wall")


def check_stool(parts, errs, rep):
    lo, hi = bounds(parts["StoolSeat"])
    if not near(hi[1], SEAT_TOP):
        errs.append("seat top %.4f" % hi[1])
    flo, fhi = bounds(parts["StoolFrame"])
    if flo[1] < -LEG_R * 1.01:
        errs.append("legs below the floor %.4f" % flo[1])


def check_chalk(parts, errs, rep):
    lo, hi = bounds(parts["ChalkWrap"])
    if not near(lo[1], 0.0, 1e-5):
        errs.append("chalk not on its base")
    if not near(hi[0] - lo[0], CHALK, 1e-5):
        errs.append("chalk size %.4f" % (hi[0] - lo[0]))


def main():
    jobs = [
        ("LampShade", build_lamp, ("ShadeOuter", "ShadeInner", "ShadeTrim", "ShadeBulbs", "ShadeRods"), check_lamp),
        ("CueRack", build_rack, ("RackBoard", "RackRails", "RackCues"), check_rack),
        ("Stool", build_stool, ("StoolSeat", "StoolFrame"), check_stool),
        ("Chalk", build_chalk, ("ChalkWrap", "ChalkFace"), check_chalk),
    ]
    failed = []
    for name, build, names, checks in jobs:
        clear_scene()
        build()
        path = os.path.join(MODELS, name + ".usdz")
        export(path)
        rep = verify(path, names, checks)
        print("ROOM REPORT %s" % name)
        for k, v in rep.items():
            print("  %s: %s" % (k, v))
        if rep["errors"]:
            failed.append((name, rep["errors"]))
    if failed:
        print("ROOM CHECK FAILED:", failed)
        sys.exit(1)
    print("ROOM CHECK PASSED")


main()
