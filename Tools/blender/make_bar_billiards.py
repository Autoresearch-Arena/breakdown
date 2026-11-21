# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Generates the bar-billiards skittle (the turned wooden "mushroom" peg that guards the scoring holes) as
#          App/Models/BarBilliards.usdz for the Breakdown app. Run headless:
#              /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python Tools/blender/make_bar_billiards.py
#          The script is deterministic: same code, same file.
#          Output contract (shared with App/Tables/BarBilliardsTable.swift and App/Tables/README.md):
#          RealityKit frame, +Y up, metres. ONE reusable part, authored at its own origin and placed in Swift:
#            BarBilliardsSkittle - a body of revolution about +Y with its base centre at the origin, base on y = 0.
#                                  Foot radius 12 mm, a straight stalk of radius SKITTLE_STALK_R (9 mm) from 16 mm to
#                                  48 mm up (so a 47.6 mm ball, centre 23.8 mm up, always touches the stalk: the
#                                  solver's Pin.radius), flaring into a domed cap of radius 19.5 mm whose underside
#                                  (55 mm) is above the top of a ball (47.6 mm); top at SKITTLE_H (76 mm).
#          Swift clones this part three times (two white, one black) into the "pin-<k>" holders and paints each one;
#          the file carries no materials, cameras or lights.
#          Sizes: the hobby table page (michaelcross.me.uk/billiards) gives 3 inch (76 mm) wooden mushrooms; the
#          3-D-printed league-scale table (github.com/AidanJones/pocket_bar_billiards) uses an 80 mm skittle whose cap
#          rim sits at 74 percent of its height, so a ball passes under the cap. Real turned mushrooms vary by maker.
#          After export the file is read back with pxr (OpenUSD, shipped inside Blender) and every contract number is
#          checked; the script exits non-zero if any check fails.
# SRP/DRY check: Pass - follows Tools/blender/make_bridge.py (same lathe idea, export and pxr check); the lathe here
#          is a vertical-axis version only, as the bridge's lathe takes an arbitrary frame and is not importable (each
#          generator is a standalone Blender script).

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_PATH = os.path.join(REPO, "App", "Models", "BarBilliards.usdz")

# ---------------------------------------------------------------- contract numbers (metres, RealityKit frame)
PART = "BarBilliardsSkittle"
SKITTLE_H = 0.076          # 3 inch mushroom
SKITTLE_STALK_R = 0.009    # contact radius at ball-centre height; BarBilliardsTable.skittleRadius must match
STALK_Y0, STALK_Y1 = 0.016, 0.048
FOOT_R = 0.012
CAP_R = 0.0195
CAP_UNDER_Y = 0.055        # must stay above the ball's top (2 x 0.0238125 = 0.047625)
BALL_R = 0.0238125         # 1 7/8 inch ball, for the clearance check only
SEGMENTS = 32


def profile():
    """(r, y) from the base centre up the outside to the top pole; the dome is a quarter ellipse."""
    pts = [(0.0, 0.0), (FOOT_R, 0.0), (FOOT_R + 0.0003, 0.002), (0.0115, 0.006), (0.0098, 0.011),
           (SKITTLE_STALK_R, STALK_Y0), (SKITTLE_STALK_R, 0.024), (SKITTLE_STALK_R, STALK_Y1),
           (0.0100, 0.0515), (0.0135, 0.0540), (0.0175, CAP_UNDER_Y), (CAP_R, 0.0575), (CAP_R, 0.0600)]
    dome_h = SKITTLE_H - 0.0600
    steps = 8
    for i in range(1, steps + 1):
        a = 0.5 * math.pi * i / steps
        r = 0.0 if i == steps else CAP_R * math.cos(a)
        pts.append((r, 0.0600 + dome_h * math.sin(a)))
    return pts


def lathe(prof, segments=SEGMENTS):
    """Vertical body of revolution about +Y; r = 0 entries become single poles."""
    verts, faces, rings = [], [], []
    for r, y in prof:
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
    for ra, rb in zip(rings, rings[1:]):
        if len(ra) == 1:
            for k in range(segments):
                faces.append((ra[0], rb[(k + 1) % segments], rb[k]))
        elif len(rb) == 1:
            for k in range(segments):
                faces.append((ra[k], ra[(k + 1) % segments], rb[0]))
        else:
            for k in range(segments):
                k1 = (k + 1) % segments
                faces.append((ra[k], ra[k1], rb[k1], rb[k]))
    return verts, faces


def make_object(name, verts, faces):
    """Named mesh object (object and mesh data share the name, so the USD prim carries it)."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    # Hard edges only at the flat base and the cap rim; the turned body stays smooth.
    mesh.set_sharp_from_angle(angle=math.radians(40.0))
    # Make the normals point outward whatever the winding above came out as.
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.set_sharp_from_angle(angle=math.radians(40.0))
    return obj


# ---------------------------------------------------------------- export and verification
def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(coll):
            coll.remove(item)


def export(path):
    """Writes a plain .usdc to a temp folder, stamps it Y-up / metres with pxr, then packs the .usdz."""
    import shutil
    import tempfile
    from pxr import Usd, UsdGeom, UsdUtils
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp_dir = tempfile.mkdtemp(prefix="barbilliards_usd_")
    tmp = os.path.join(tmp_dir, "BarBilliards.usdc")
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
    """Reads the exported file back with pxr and checks every contract number. Returns a report dict."""
    from pxr import Gf, Usd, UsdGeom
    stage = Usd.Stage.Open(path)
    errs, rep = [], {}
    rep["upAxis"] = UsdGeom.GetStageUpAxis(stage)
    rep["metersPerUnit"] = UsdGeom.GetStageMetersPerUnit(stage)
    if rep["upAxis"] != "Y":
        errs.append("up axis is %s" % rep["upAxis"])
    if abs(rep["metersPerUnit"] - 1.0) > 1e-9:
        errs.append("metersPerUnit %s" % rep["metersPerUnit"])
    cache = UsdGeom.XformCache()
    parts, tris, prims = {}, 0, []
    for prim in stage.Traverse():
        prims.append("%s (%s)" % (prim.GetPath(), prim.GetTypeName()))
        t = prim.GetTypeName()
        if t == "Camera" or "Light" in t or t == "Material":
            errs.append("junk prim %s" % prim.GetPath())
        if not prim.IsA(UsdGeom.Mesh):
            continue
        mesh = UsdGeom.Mesh(prim)
        xf = cache.GetLocalToWorldTransform(prim)
        pts = [xf.Transform(Gf.Vec3d(p)) for p in mesh.GetPointsAttr().Get()]
        tris += sum(c - 2 for c in mesh.GetFaceVertexCountsAttr().Get())
        parts[prim.GetName()] = pts
    rep["prims"] = prims
    rep["triangles"] = tris
    if PART not in parts:
        errs.append("missing part %s" % PART)
    else:
        pts = parts[PART]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        rep["bounds"] = (lo, hi)
        if abs(lo[1]) > 1e-6:
            errs.append("base y %.6f (must be 0)" % lo[1])
        if abs(hi[1] - SKITTLE_H) > 1e-6:
            errs.append("top y %.6f (must be %.3f)" % (hi[1], SKITTLE_H))
        for i in (0, 2):
            if abs(lo[i] + hi[i]) > 1e-6:
                errs.append("not centred on the axis (axis %d: %.6f..%.6f)" % (i, lo[i], hi[i]))
        rmax = max(math.hypot(p[0], p[2]) for p in pts)
        rep["max_radius"] = rmax
        if abs(rmax - CAP_R) > 1e-6:
            errs.append("cap radius %.6f" % rmax)
        # Contact radius: every ring between the stalk ends is exactly the pin's contact radius, and the ball's
        # centre height lies on the stalk.
        stalk = [math.hypot(p[0], p[2]) for p in pts if STALK_Y0 - 1e-9 <= p[1] <= STALK_Y1 + 1e-9]
        rep["stalk_radius"] = (min(stalk), max(stalk)) if stalk else None
        if not stalk or abs(min(stalk) - SKITTLE_STALK_R) > 1e-6 or abs(max(stalk) - SKITTLE_STALK_R) > 1e-6:
            errs.append("stalk radius %s" % (rep["stalk_radius"],))
        if not (STALK_Y0 < BALL_R < STALK_Y1):
            errs.append("ball centre height is off the stalk")
        # Nothing wider than the stalk below the cap's underside reaches the ball: anything from the stalk top to
        # the ball's top must stay inside the stalk-ball contact circle.
        for p in pts:
            r = math.hypot(p[0], p[2])
            if STALK_Y1 < p[1] < 2 * BALL_R and r > SKITTLE_STALK_R + 0.0015:
                errs.append("flare at y %.4f r %.4f would meet the ball first" % (p[1], r))
                break
        if tris > 3000:
            errs.append("too heavy: %d triangles" % tris)
    rep["errors"] = errs
    return rep


def main():
    clear_scene()
    v, f = lathe(profile())
    make_object(PART, v, f)
    export(OUT_PATH)
    rep = verify(OUT_PATH)
    print("BAR BILLIARDS REPORT")
    for k, val in rep.items():
        print("  %s: %s" % (k, val))
    if rep["errors"]:
        print("BAR BILLIARDS CHECK FAILED:", rep["errors"])
        sys.exit(1)
    print("BAR BILLIARDS CHECK PASSED")


main()
