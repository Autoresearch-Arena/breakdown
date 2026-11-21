# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Generates the bumper pool props as App/Models/BumperPool.usdz for the Breakdown app: one bumper (a chrome
#          post with a foot flange, a white rubber ring at ball-centre height and a domed chrome cap) and one cup liner
#          (the hard plastic sleeve that lines each cup in the bed, with a thin lip on the cloth). Run headless:
#              /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python Tools/blender/make_bumper_pool.py
#          Deterministic: same code, same file.
#          Each reusable part is authored at its OWN origin (not in table coordinates); App/Tables/BumperPoolTable.swift
#          clones the bumper twelve times and the liner twice and places the copies from the solved TableSpec.
#          Frame: RealityKit, +Y up, metres, cloth at y = 0, origin on the post's (or cup's) centre line.
#            BumperPoolBase  - chrome foot flange and post core, y = 0 to the cap.
#            BumperPoolRing  - white rubber ring, outer radius RING_R (= the solver's post radius, 1 in), centred on the
#                              ball-centre height of a 2-1/8 in ball, so the drawn contact matches the solved one.
#            BumperPoolCap   - domed chrome cap; its top is POST_H, the solver's post height.
#            BumperPoolCupLiner - plastic sleeve, inner radius 2.188 in / 2, outer 2.488 in / 2 (replacement bumper pool
#                              hole liner sizes), 3/4 in deep, with a lip that
#                              stands LINER_LIP above the cloth. Its outer radius equals the solver's bed-hole radius.
#          Geometry only: no materials, cameras or lights; Swift assigns materials by part name. After export the file is
#          read back with pxr and every contract number is checked; the script exits non-zero if any check fails.
# SRP/DRY check: Pass - follows make_bridge.py (same identity frame, lathe, export and read-back pattern); kept as its
#          own script because each table owns its generator (App/Tables/README.md). The numbers shared with Swift are
#          RING_R, POST_H and LINER_OUTER_R; keep them equal to BumperPoolTable.swift.

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_PATH = os.path.join(REPO, "App", "Models", "BumperPool.usdz")

INCH = 0.0254
# ---------------------------------------------------------------- contract numbers (metres, RealityKit frame)
BALL_R = 2.125 * INCH / 2          # 2-1/8 in bumper pool ball; the ring is centred on its centre height
RING_R = 1.0 * INCH                # 2 in rubber bumper ring (manufacturer listings) = solver post radius
RING_INNER_R = 0.0135              # ring hugs the post core
RING_HALF_H = 0.0135               # ring spans ball centre +/- this, so any ball on the cloth meets the rubber
POST_CORE_R = 0.0110
FLANGE_R = 0.0170
FLANGE_H = 0.0035
POST_H = 0.048                     # cap top = solver post height
CAP_R = 0.0150

LINER_INNER_R = 2.188 * INCH / 2
LINER_OUTER_R = 2.488 * INCH / 2   # = solver bed-hole radius
LINER_DEPTH = 0.75 * INCH
LINER_LIP = 0.0012                 # lip stands this far above the cloth
LIP_R = LINER_OUTER_R + 0.0030     # lip overlaps the cloth around the cut

SEGMENTS = 48


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


def lathe(profile, segments=SEGMENTS):
    """Body of revolution about +Y. profile is [(y, r)] in order; r = 0 makes a pole (closed end).
    The profile runs so that the surface faces outward when walked bottom to top on the outside."""
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
    for ra, rb in zip(rings, rings[1:]):
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


def build_base():
    # Foot flange with a rounded edge, then the core rising into the cap (the cap part covers the top).
    prof = [(0.0, 0.0), (0.0, FLANGE_R - 0.001), (0.0008, FLANGE_R), (FLANGE_H - 0.0008, FLANGE_R),
            (FLANGE_H, FLANGE_R - 0.0012), (FLANGE_H + 0.0006, POST_CORE_R), (POST_H - 0.006, POST_CORE_R),
            (POST_H - 0.006, 0.0)]
    v, f = lathe(prof)
    obj = make_object("BumperPoolBase", v, f, math.radians(40.0))
    fix_normals(obj)
    return obj


def build_ring():
    # Rubber ring: square section with well rounded outer corners (a moulded rubber band), centred on BALL_R.
    y0, y1 = BALL_R - RING_HALF_H, BALL_R + RING_HALF_H
    rr = 0.0045                       # corner rounding of the outer face
    prof = [(y0, RING_INNER_R)]
    for i in range(7):                # bottom outer corner
        a = 0.5 * math.pi * (1 - i / 6)
        prof.append((y0 + rr - rr * math.sin(a), RING_R - rr + rr * math.cos(a)))
    for i in range(7):                # top outer corner
        a = 0.5 * math.pi * i / 6
        prof.append((y1 - rr + rr * math.sin(a), RING_R - rr + rr * math.cos(a)))
    prof.append((y1, RING_INNER_R))
    v, f = lathe(prof)
    # close the inner wall: join the last ring back to the first (a tube, open nowhere)
    n = SEGMENTS
    first, last = 0, (len(prof) - 1) * n
    for k in range(n):
        k1 = (k + 1) % n
        f.append((last + k, first + k, first + k1, last + k1))
    obj = make_object("BumperPoolRing", v, f, math.radians(50.0))
    fix_normals(obj)
    return obj


def build_cap():
    # Domed chrome cap sitting over the core top, a short skirt then a dome to POST_H.
    base = POST_H - 0.0085
    prof = [(base, 0.0), (base, CAP_R - 0.0008), (base + 0.0008, CAP_R), (base + 0.0030, CAP_R)]
    dome_h = POST_H - (base + 0.0030)
    for i in range(1, 11):
        a = 0.5 * math.pi * i / 10
        prof.append((base + 0.0030 + dome_h * math.sin(a), 0.0 if i == 10 else CAP_R * math.cos(a)))
    v, f = lathe(prof)
    obj = make_object("BumperPoolCap", v, f, math.radians(40.0))
    fix_normals(obj)
    return obj


def build_liner():
    # Sleeve: outer wall from the lip down to LINER_DEPTH, a closed floor ring, inner wall back up, and a lip on top.
    prof = [(LINER_LIP, LINER_INNER_R), (LINER_LIP, LIP_R - 0.0006), (LINER_LIP - 0.0006, LIP_R), (0.0, LIP_R),
            (0.0, LINER_OUTER_R), (-LINER_DEPTH, LINER_OUTER_R), (-LINER_DEPTH, LINER_INNER_R)]
    v, f = lathe(prof)
    n = SEGMENTS
    first, last = 0, (len(prof) - 1) * n
    for k in range(n):
        k1 = (k + 1) % n
        f.append((last + k, first + k, first + k1, last + k1))
    obj = make_object("BumperPoolCupLiner", v, f, math.radians(40.0))
    fix_normals(obj)
    return obj


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
    tmp_dir = tempfile.mkdtemp(prefix="bumper_usd_")
    tmp = os.path.join(tmp_dir, "BumperPool.usdc")
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
    if tris > 6000:
        errs.append("too many triangles %d" % tris)
    bounds = {}
    for name in ("BumperPoolBase", "BumperPoolRing", "BumperPoolCap", "BumperPoolCupLiner"):
        if name not in parts:
            errs.append("missing part %s" % name)
            continue
        pts = parts[name]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        rmax = max(math.hypot(p[0], p[2]) for p in pts)
        bounds[name] = (lo, hi, rmax)
    rep["bounds"] = bounds

    def near(a, b, tol=2e-5):
        return abs(a - b) <= tol
    if "BumperPoolBase" in bounds and not near(bounds["BumperPoolBase"][0][1], 0.0, 1e-6):
        errs.append("base lowest y %.6f" % bounds["BumperPoolBase"][0][1])
    if "BumperPoolRing" in bounds:
        lo, hi, rmax = bounds["BumperPoolRing"]
        if not near(rmax, RING_R):
            errs.append("ring radius %.5f != %.5f" % (rmax, RING_R))
        if not (lo[1] < BALL_R < hi[1]):
            errs.append("ring does not span ball centre height")
    if "BumperPoolCap" in bounds:
        lo, hi, rmax = bounds["BumperPoolCap"]
        if not near(hi[1], POST_H):
            errs.append("cap top %.5f != %.5f" % (hi[1], POST_H))
        if rmax > RING_R:
            errs.append("cap wider than ring")
    if "BumperPoolCupLiner" in bounds:
        lo, hi, rmax = bounds["BumperPoolCupLiner"]
        if lo[1] < -0.12 or not near(lo[1], -LINER_DEPTH):
            errs.append("liner bottom %.5f" % lo[1])
        if not near(hi[1], LINER_LIP):
            errs.append("liner top %.5f" % hi[1])
        rin = min(math.hypot(p[0], p[2]) for p in parts["BumperPoolCupLiner"])
        if not near(rin, LINER_INNER_R) or rin <= BALL_R:
            errs.append("liner inner radius %.5f (ball %.5f)" % (rin, BALL_R))
    for name, (lo, hi, rmax) in bounds.items():
        if name != "BumperPoolCupLiner" and lo[1] < -1e-6:
            errs.append("%s below the cloth" % name)
    rep["errors"] = errs
    return rep


def main():
    clear_scene()
    build_base()
    build_ring()
    build_cap()
    build_liner()
    export(OUT_PATH)
    rep = verify(OUT_PATH)
    print("BUMPER POOL REPORT")
    for k, v in rep.items():
        print("  %s: %s" % (k, v))
    if rep["errors"]:
        print("BUMPER POOL CHECK FAILED:", rep["errors"])
        sys.exit(1)
    print("BUMPER POOL CHECK PASSED")


main()
