# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Generates the five-pin billiards (Italian "cinque birilli") skittles as App/Models/FivePin.usdz for the
#          Breakdown app. Run headless:
#              /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python Tools/blender/make_five_pin.py
#          Optional extra args after "--": "--preview <png path>" renders a quick look with throwaway materials
#          (never exported). Deterministic: same code, same file.
#          Shape: the regulation pin of CEB Rules of the Game B/7 (5 Pins), Article 1001 (edition 01-09-2026): round,
#          25 mm high, 7 mm across at the base and at the head, 10 mm at the widest part (the belly); the drawing there
#          (and scheme H of B/8) also shows a 5 mm neck. Heights of the belly, neck and head are read off that drawing.
#          Output contract (App/Tables/README.md and App/Tables/FivePinTable.swift):
#            FivePinPinWhite - one white pin, base centre at the origin on y = 0, standing along +Y, 0.025 m tall.
#            FivePinPinRed   - the same pin for the red centre pin (same geometry, its own name so Swift paints it red).
#          Each reusable part is authored at its own origin; Swift clones it into an entity named "pin-<k>" placed at
#          each pin's spot (that holder is what TableScene topples). RealityKit frame, +Y up, metres.
#          Geometry only: no materials, cameras or lights are exported; Swift assigns materials by part name.
#          After export the file is read back with pxr and every contract number is checked (part names, height, base
#          on y = 0, base / belly / neck / head diameters, centred on the axis, triangle budget); the script also
#          prints the pin's effective contact radius against a 61.5 mm ball (see contact_radius) and checks it matches
#          the number FivePinTable.swift gives the solver. Exits non-zero if any check fails.
# SRP/DRY check: Pass - follows make_bridge.py / make_cue.py (lathe, named-object, export and verify steps); those
#          helpers are private to each script by the established pattern, so the lathe is repeated here in its simple
#          single-axis form rather than shared.

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_PATH = os.path.join(REPO, "App", "Models", "FivePin.usdz")

# ---------------------------------------------------------------- contract numbers (metres)
PIN_HEIGHT = 0.025          # CEB B/7 Art. 1001
BASE_R = 0.0035             # 7 mm base
BELLY_R = 0.005             # 10 mm at the largest part
NECK_R = 0.0025             # 5 mm neck (drawing in Art. 1001)
HEAD_R = 0.0035             # 7 mm head
BELLY_Y = 0.0058            # heights read off the Art. 1001 drawing (25 mm = full height)
NECK_Y = 0.0168
HEAD_Y = 0.0223
BALL_R = 0.03075            # 61.5 mm carom ball (FIBiS / UMB), for the contact-radius check
SWIFT_CONTACT_R = 0.0024    # the number FivePinTable.swift gives Pin.radius; must match contact_radius()
SEGMENTS = 28
PARTS = ("FivePinPinWhite", "FivePinPinRed")


# ---------------------------------------------------------------- profile
def smoothstep(t):
    return t * t * (3.0 - 2.0 * t)


def radius_at(y):
    """Pin radius at height y: smooth (zero-slope) blends between the keyed diameters, then an elliptical dome on the
    head so the top closes at exactly PIN_HEIGHT. The keys are where the drawing puts the base, belly, neck and head."""
    keys = [(0.0, BASE_R), (BELLY_Y, BELLY_R), (NECK_Y, NECK_R), (HEAD_Y, HEAD_R)]
    if y >= HEAD_Y:
        t = (y - HEAD_Y) / (PIN_HEIGHT - HEAD_Y)
        return HEAD_R * math.sqrt(max(0.0, 1.0 - t * t))
    for (y0, r0), (y1, r1) in zip(keys, keys[1:]):
        if y0 <= y <= y1:
            return r0 + (r1 - r0) * smoothstep((y - y0) / (y1 - y0))
    return BASE_R


def profile():
    """[(y, r)] from the base up; first and last r are 0 so the lathe closes both ends (flat base, domed head)."""
    ys = [0.0, 0.0004]
    n = 26
    for i in range(1, n + 1):
        ys.append(0.0004 + (HEAD_Y - 0.0004) * i / n)
    for i in range(1, 9):
        a = 0.5 * math.pi * i / 8
        ys.append(HEAD_Y + (PIN_HEIGHT - HEAD_Y) * math.sin(a))
    # Make sure the exact key heights are sampled so the verify step reads the true diameters.
    for k in (BELLY_Y, NECK_Y):
        if all(abs(k - y) > 1e-6 for y in ys):
            ys.append(k)
    ys = sorted(set(round(y, 9) for y in ys))
    prof = [(0.0, 0.0)]
    for y in ys:
        r = radius_at(y)
        if y >= PIN_HEIGHT - 1e-9:
            r = 0.0
        prof.append((y, r))
    # Tiny chamfer at the foot so the base edge catches light instead of reading as a cut cylinder.
    prof[1] = (0.0, BASE_R - 0.0002)
    prof[2] = (0.0004, BASE_R)
    return prof


def contact_radius(ball_r=BALL_R):
    """The solver treats a pin as a vertical cylinder: a ball touches it when centre-to-axis distance is R + radius.
    A 61.5 mm ball's centre is above the 25 mm pin, so the real first touch is where the ball's surface meets the pin
    highest up: the distance is the largest over pin height y of radius_at(y) + the ball's horizontal half-chord at y.
    This returns that distance minus R, the radius the solver needs for the touch to happen at the true distance."""
    best = 0.0
    steps = 2500
    for i in range(steps + 1):
        y = PIN_HEIGHT * i / steps
        chord = math.sqrt(max(0.0, ball_r * ball_r - (ball_r - y) ** 2))
        best = max(best, radius_at(y) + chord)
    return best - ball_r


def volume():
    """Solid-of-revolution volume, for the mass estimate printed in the report."""
    v, steps = 0.0, 2500
    for i in range(steps):
        y0, y1 = PIN_HEIGHT * i / steps, PIN_HEIGHT * (i + 1) / steps
        r = radius_at(0.5 * (y0 + y1))
        v += math.pi * r * r * (y1 - y0)
    return v


# ---------------------------------------------------------------- mesh building
def lathe_y(prof, segments=SEGMENTS):
    """Body of revolution about +Y. prof is [(y, r)]; r = 0 entries become single pole vertices."""
    verts, faces, rings = [], [], []
    for y, r in prof:
        if r <= 0.0:
            rings.append([len(verts)])
            verts.append((0.0, y, 0.0))
            continue
        ring = []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ring.append(len(verts))
            # Counter-clockwise seen from above (+Y) so outward normals come out of the winding below.
            verts.append((r * math.cos(a), y, -r * math.sin(a)))
        rings.append(ring)
    for ra, rb in zip(rings, rings[1:]):
        if len(ra) == 1 and len(rb) == 1:
            continue
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
    """Named mesh object (object and mesh share the name, so the USD prim carries it). Geometry is authored directly
    in the RealityKit frame (Y up) and exported without axis conversion, as make_bridge.py does."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    mesh.set_sharp_from_angle(angle=math.radians(50.0))   # only the flat base edge stays sharp
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
    tmp_dir = tempfile.mkdtemp(prefix="fivepin_usd_")
    tmp = os.path.join(tmp_dir, "FivePin.usdc")
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


def ring_radius_near(pts, y, tol=2e-5):
    """Largest distance from the Y axis among points within tol of height y (the sampled ring there)."""
    rs = [math.hypot(p[0], p[2]) for p in pts if abs(p[1] - y) < tol]
    return max(rs) if rs else None


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
        if prim.GetTypeName() == "Camera" or "Light" in prim.GetTypeName() or "Material" in prim.GetTypeName():
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
    if tris > 6000:
        errs.append("too many triangles: %d" % tris)
    for name in PARTS:
        if name not in parts:
            errs.append("missing part %s" % name)
            continue
        pts = parts[name]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        rep[name + " bounds"] = (tuple(round(v, 6) for v in lo), tuple(round(v, 6) for v in hi))
        if abs(lo[1]) > 1e-7:
            errs.append("%s base at y %.7f" % (name, lo[1]))
        if abs(hi[1] - PIN_HEIGHT) > 1e-6:
            errs.append("%s height %.6f" % (name, hi[1]))
        if abs(lo[0] + hi[0]) > 1e-6 or abs(lo[2] + hi[2]) > 1e-6:
            errs.append("%s not centred on the Y axis" % name)
        if abs(hi[0] - BELLY_R) > 1e-4:
            errs.append("%s widest radius %.5f" % (name, hi[0]))
        for label, y, want in (("base", 0.0004, BASE_R), ("belly", BELLY_Y, BELLY_R), ("neck", NECK_Y, NECK_R),
                               ("head", HEAD_Y, HEAD_R)):
            got = ring_radius_near(pts, y)
            rep["%s %s radius" % (name, label)] = got
            if got is None or abs(got - want) > 5e-5:
                errs.append("%s %s radius %s, want %.4f" % (name, label, got, want))
    c = contact_radius()
    rep["contact radius vs 61.5 mm ball"] = round(c, 6)
    if abs(c - SWIFT_CONTACT_R) > 1.5e-4:
        errs.append("contact radius %.5f no longer matches the Swift value %.4f" % (c, SWIFT_CONTACT_R))
    v = volume()
    rep["volume cm3"] = round(v * 1e6, 3)
    rep["mass g at 0.75 g/cm3 (turned hardwood)"] = round(v * 1e6 * 0.75, 2)
    rep["errors"] = errs
    return rep


def render_preview(png):
    """Throwaway look-see render of the two pins side by side; runs after export so none of this reaches the file."""
    from mathutils import Vector
    white = bpy.data.materials.new("white"); white.diffuse_color = (0.93, 0.91, 0.86, 1)
    red = bpy.data.materials.new("red"); red.diffuse_color = (0.75, 0.08, 0.07, 1)
    bpy.data.objects["FivePinPinWhite"].data.materials.append(white)
    bpy.data.objects["FivePinPinRed"].data.materials.append(red)
    bpy.data.objects["FivePinPinRed"].location = (0.02, 0, 0)
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_WORKBENCH"
    scn.display.shading.color_type = "MATERIAL"
    scn.display.shading.light = "STUDIO"
    scn.render.resolution_x, scn.render.resolution_y = 900, 700
    cam_d = bpy.data.cameras.new("cam"); cam_d.lens = 80
    cam = bpy.data.objects.new("cam", cam_d); scn.collection.objects.link(cam)
    cam.location = (0.01, 0.03, -0.12)
    d = Vector((0.01, 0.012, 0.0)) - Vector(cam.location)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    scn.world = bpy.data.worlds.new("w"); scn.world.color = (0.1, 0.3, 0.15)
    scn.render.filepath = png
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else None
    clear_scene()
    verts, faces = lathe_y(profile())
    for name in PARTS:
        make_object(name, verts, faces)
    export(OUT_PATH)
    rep = verify(OUT_PATH)
    print("FIVE PIN REPORT")
    for k, v in rep.items():
        print("  %s: %s" % (k, v))
    if preview:
        render_preview(preview)
    if rep["errors"]:
        print("FIVE PIN CHECK FAILED:", rep["errors"])
        sys.exit(1)
    print("FIVE PIN CHECK PASSED")


main()
