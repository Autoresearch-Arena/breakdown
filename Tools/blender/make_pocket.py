# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Generates the moulded pool pocket (the leather cup a ball drops into, and the rolled lip round its mouth) as
#          App/Models/Pocket.usdz for the Breakdown app. Run headless:
#              /opt/homebrew/bin/blender -b --factory-startup --python Tools/blender/make_pocket.py
#          Deterministic: same code, same file.
#          Why a model: the old pocket was a straight wall dropping from the cloth to a flat black floor, which read as
#          a square black box from the low Ride camera. A real pocket is a rounded cup with a rolled lip at the mouth,
#          and a ball that drops goes behind that lip and out of sight.
#          Output contract (TableBuilder.swift, "pocket liners"):
#            PocketLiner - the cup: a body of revolution about +Y, open at the top. Its rim is at y = -0.002, radius
#                          REF_R - 0.0005 (a hair inside the mouth so it never fights the code-built wall above it), it
#                          drops straight for 4 cm, then rounds in to a closed bottom at y = -LINER_DEPTH (above the
#                          code-built black floor at -0.12, which stays as the fallback while this loads).
#            PocketLip   - a rolled ring round the mouth: a tube of radius LIP_TUBE whose top just touches the cloth
#                          (y = 0) and whose inner edge reaches LIP_INSET inside the mouth.
#          Both are authored for a mouth of radius REF_R = 0.075 m centred on the origin at cloth level. Swift scales
#          each copy across (x and z only) by its pocket's drawn radius / REF_R, so the mouth follows the solver's jaws
#          and capture circle exactly as the code-built hole does (pocket radii run about 0.065 to 0.09 m, so the lip's
#          tube is squashed or stretched by at most a fifth across, which does not show). +Y up, metres, RealityKit frame.
#          Geometry only: no materials, cameras or lights are exported; Swift assigns materials by part name.
#          After export the file is read back with pxr and every contract number is checked; exits non-zero on failure.
# SRP/DRY check: Pass - follows make_bumper_pool.py (lathe, named-object, export and verify steps); those helpers are
#          private to each script by the established pattern in Tools/blender.

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_PATH = os.path.join(REPO, "App", "Models", "Pocket.usdz")

# ---------------------------------------------------------------- contract numbers (metres)
REF_R = 0.075              # the mouth radius the model is authored for (Swift scales x and z from it)
LINER_TOP = -0.002         # just below the cloth, so the cloth's own edge stays crisp
LINER_STRAIGHT = 0.040     # straight drop before the cup rounds in
LINER_DEPTH = 0.115        # bottom of the cup; the code-built floor is at -0.12 (TableBuilder.pocketDepth)
LIP_TUBE = 0.0035          # radius of the rolled lip's tube
LIP_INSET = 0.0055         # how far the lip's inner edge reaches inside the mouth
SEGMENTS = 64


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


def lathe(profile, segments=SEGMENTS, closed=False):
    """Body of revolution about +Y. profile is [(y, r)]; r = 0 makes a pole. closed=True joins the last ring back
    to the first (a tube)."""
    verts, faces, rings = [], [], []
    for y, r in profile:
        if r <= 0.0:
            rings.append([len(verts)])
            verts.append((0.0, y, 0.0))
            continue
        ring = []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ring.append(len(verts))
            verts.append((r * math.cos(a), y, -r * math.sin(a)))
        rings.append(ring)
    pairs = list(zip(rings, rings[1:]))
    if closed:
        pairs.append((rings[-1], rings[0]))
    for ra, rb in pairs:
        if len(ra) == 1 and len(rb) == 1:
            continue
        if len(ra) == 1:
            for k in range(segments):
                faces.append((ra[0], rb[k], rb[(k + 1) % segments]))
        elif len(rb) == 1:
            for k in range(segments):
                faces.append((ra[k], rb[0], ra[(k + 1) % segments]))
        else:
            for k in range(segments):
                k1 = (k + 1) % segments
                faces.append((ra[k], rb[k], rb[k1], ra[k1]))
    return verts, faces


def fix_normals(obj):
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()


def liner_profile():
    """The cup, top to bottom: a straight wall, then a quarter-ellipse into a closed bottom (a leather cup sags
    round, it is never a flat floor)."""
    top_r = REF_R - 0.0005
    prof = [(LINER_TOP, top_r), (LINER_TOP - LINER_STRAIGHT, top_r)]
    y0 = LINER_TOP - LINER_STRAIGHT
    depth = LINER_DEPTH + y0          # remaining drop (y0 is negative)
    steps = 12
    for i in range(1, steps + 1):
        a = 0.5 * math.pi * i / steps
        r = top_r * math.cos(a)
        y = y0 - depth * math.sin(a)
        prof.append((y, 0.0 if i == steps else r))
    return prof


def lip_profile():
    """A circle of radius LIP_TUBE in the (r, y) plane, its top touching y = 0 and its inner edge LIP_INSET inside
    the mouth."""
    rc = REF_R - LIP_INSET + LIP_TUBE
    yc = -LIP_TUBE
    prof = []
    steps = 16
    for i in range(steps):
        a = 2.0 * math.pi * i / steps
        prof.append((yc + LIP_TUBE * math.sin(a), rc + LIP_TUBE * math.cos(a)))
    return prof


def build():
    v, f = lathe(liner_profile())
    liner = make_object("PocketLiner", v, f, math.radians(50.0))
    fix_normals(liner)
    v, f = lathe(lip_profile(), closed=True)
    lip = make_object("PocketLip", v, f, math.radians(60.0))
    fix_normals(lip)


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
    tmp_dir = tempfile.mkdtemp(prefix="pocket_usd_")
    tmp = os.path.join(tmp_dir, "Pocket.usdc")
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


def verify(path):
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
    if tris > 8000:
        errs.append("too many triangles %d" % tris)

    def near(a, b, tol=2e-5):
        return abs(a - b) <= tol
    for name in ("PocketLiner", "PocketLip"):
        if name not in parts:
            errs.append("missing part %s" % name)
    if "PocketLiner" in parts:
        pts = parts["PocketLiner"]
        top = max(p[1] for p in pts)
        bottom = min(p[1] for p in pts)
        rmax = max(math.hypot(p[0], p[2]) for p in pts)
        rep["liner"] = (top, bottom, rmax)
        if not near(top, LINER_TOP):
            errs.append("liner top %.5f" % top)
        if not near(bottom, -LINER_DEPTH):
            errs.append("liner bottom %.5f" % bottom)
        if bottom <= -0.12:
            errs.append("liner reaches the code-built floor")
        if rmax >= REF_R:
            errs.append("liner wider than the mouth %.5f" % rmax)
    if "PocketLip" in parts:
        pts = parts["PocketLip"]
        top = max(p[1] for p in pts)
        rmin = min(math.hypot(p[0], p[2]) for p in pts)
        rmax = max(math.hypot(p[0], p[2]) for p in pts)
        rep["lip"] = (top, rmin, rmax)
        if not near(top, 0.0, 1e-4):
            errs.append("lip top %.5f is not at the cloth" % top)
        if not near(rmin, REF_R - LIP_INSET, 2e-4):
            errs.append("lip inner edge %.5f" % rmin)
    rep["errors"] = errs
    return rep


def main():
    clear_scene()
    build()
    export(OUT_PATH)
    rep = verify(OUT_PATH)
    print("POCKET REPORT")
    for k, v in rep.items():
        print("  %s: %s" % (k, v))
    if rep["errors"]:
        print("POCKET CHECK FAILED:", rep["errors"])
        sys.exit(1)
    print("POCKET CHECK PASSED")


main()
