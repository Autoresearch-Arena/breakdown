# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Generates the mechanical bridge (the chrome "spider" rest used for out-of-reach shots) as
#          App/Models/Bridge.usdz for the Breakdown app. Run headless:
#              /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python Tools/blender/make_bridge.py
#          Optional extra args after "--": "--preview <png path>" renders a quick look with throwaway materials
#          (never exported). The script is deterministic: same code, same file.
#          Output contract (shared with the Swift integrator, see the cue/bridge task): RealityKit frame, +Y up,
#          metres, cloth at y = 0, the cue passes over the head along Z with the ball at negative Z.
#            BridgeHead    - upright chrome plate, front face on z = 0, back face on z = +HEAD_THICK, feet on y = 0,
#                            centre notch is a rounded V whose bottom is exactly y = 0.0215 at x = 0.
#            BridgeFerrule - brass socket on the back of the plate, on the handle's axis (offset to +X so the cue,
#                            which runs along x = 0, never touches it).
#            BridgeHandle  - tapered wooden pole, about 1.1 m, rising gently and splaying 5 degrees to +X so it
#                            passes under and beside the cue, with a rounded end cap.
#          Geometry only: no materials, cameras or lights are exported; Swift assigns materials by part name.
#          After export the file is read back with pxr (OpenUSD, shipped inside Blender) and every contract number
#          is checked; the script exits non-zero if any check fails.
# SRP/DRY check: Pass - first Blender tool in the repo (Tools/blender was empty); one lathe helper serves both the
#          ferrule and the handle, one coordinate mapper serves every part.

import math
import os
import sys

import bmesh
import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_PATH = os.path.join(REPO, "App", "Models", "Bridge.usdz")

# ---------------------------------------------------------------- contract numbers (metres, RealityKit frame)
HEAD_HALF_W = 0.060        # plate is 0.12 m across X
HEAD_THICK = 0.005         # plate runs from z = 0 (front, facing the ball) to z = +0.005
CRADLE_Y = 0.0215          # lowest point of the centre notch, where the cue's underside rests
CRADLE_R = 0.010           # cradle radius; must exceed the cue radius so the cue touches the very bottom
CRADLE_WALL = math.radians(55.0)  # V walls, measured from horizontal
SIDE_X = 0.033             # decorative side notches
SIDE_Y = 0.040
SIDE_R = 0.006
FOOT_INNER = 0.044         # flat feet from |x| = 0.044 to 0.060; the bottom arches up between them
ARCH_H = 0.010
BEVEL_W = 0.0006

HANDLE_X0 = 0.020          # handle/ferrule axis at the plate's back face
HANDLE_Y0 = 0.0115
YAW = math.radians(5.0)    # splays out to +X
HANDLE_START = 0.020       # distance along the axis where the pole begins (hidden inside the ferrule)
HANDLE_LEN = 1.100
HANDLE_R0 = 0.008          # 16 mm at the head end
HANDLE_R1 = 0.011          # 22 mm at the far end
HANDLE_TOP_MAX = 0.061     # top of the far end above the cloth
FERRULE_LEN = 0.045

SEGMENTS = 40              # around each lathe


# ---------------------------------------------------------------- helpers
def rk_to_blender(p):
    """Identity on purpose. Geometry is authored directly in the RealityKit frame and written without
    Blender's axis conversion (which would leave a rotation on /root and store the points Z-up); the stage is
    then stamped Y-up in export(). Every prim therefore has an identity transform and points in final metres.
    The preview camera uses this too, so in the Blender scene "up" is +Y."""
    return tuple(p)


def make_object(name, verts_rk, faces, smooth_angle):
    """Builds a named mesh object (object and mesh data share the name, so the USD prim carries it)."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([rk_to_blender(v) for v in verts_rk], [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    # Sharp edges only where the surface really breaks (plate faces, ferrule shoulders); everything else smooth.
    mesh.set_sharp_from_angle(angle=smooth_angle)
    return obj


def lathe(profile, frame, segments=SEGMENTS):
    """Body of revolution. profile is [(s, r)] along the axis, first and last r should be 0 to close the ends.
    frame = (origin, axis, u, v) as RealityKit vectors. Returns (verts, faces)."""
    origin, axis, u, v = frame
    verts, faces, rings = [], [], []
    for s, r in profile:
        c = [origin[i] + axis[i] * s for i in range(3)]
        if r <= 0.0:
            rings.append([len(verts)])
            verts.append(tuple(c))
            continue
        ring = []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ca, sa = math.cos(a), math.sin(a)
            ring.append(len(verts))
            verts.append(tuple(c[i] + r * (ca * u[i] + sa * v[i]) for i in range(3)))
        rings.append(ring)
    for ra, rb in zip(rings, rings[1:]):
        if len(ra) == 1 and len(rb) == 1:
            continue
        if len(ra) == 1:      # fan from a pole
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


def smin(a, b, k):
    """Polynomial smooth minimum: rounds the peaks where two edge curves meet (k = blend width)."""
    h = max(k - abs(a - b), 0.0) / k
    return min(a, b) - h * h * k * 0.25


def notch(dx, y_bottom, r, wall):
    """Rounded V: a circular cradle of radius r sitting on y_bottom, flaring into straight walls."""
    dx = abs(dx)
    xt = r * math.sin(wall)
    if dx <= xt:
        return y_bottom + r - math.sqrt(r * r - dx * dx)
    yt = y_bottom + r * (1.0 - math.cos(wall))
    return yt + (dx - xt) * math.tan(wall)


def head_top(x):
    crown = 0.058 - 6.0 * x * x          # gently domed shoulders, 0.058 m at the middle
    y = crown
    y = smin(y, notch(x - SIDE_X, SIDE_Y, SIDE_R, CRADLE_WALL), 0.005)
    y = smin(y, notch(x + SIDE_X, SIDE_Y, SIDE_R, CRADLE_WALL), 0.005)
    # Centre notch last and with a small blend; at x = 0 every other curve is far above it, so the bottom
    # stays exactly CRADLE_Y (checked again on the exported file).
    y = smin(y, notch(x, CRADLE_Y, CRADLE_R, CRADLE_WALL), 0.005)
    return y


def head_bottom(x):
    ax = abs(x)
    if ax >= FOOT_INNER:
        return 0.0
    c = math.cos(0.5 * math.pi * ax / FOOT_INNER)
    return ARCH_H * c * c                # cos^2 arch: zero slope where it meets the feet


def head_outline():
    """Counter-clockwise outline in the XY plane (seen from the front, -Z)."""
    pts = []
    # bottom edge, left to right; x = 0 is sampled exactly
    n_bot = 64
    for i in range(n_bot + 1):
        x = -HEAD_HALF_W + 2.0 * HEAD_HALF_W * i / n_bot
        pts.append((x, head_bottom(x)))
    # top edge, right to left; dense sampling so the cradle is smooth, x = 0 sampled exactly
    n_top = 240
    for i in range(n_top + 1):
        x = HEAD_HALF_W - 2.0 * HEAD_HALF_W * i / n_top
        pts.append((x, head_top(x)))
    return pts


def build_head():
    outline = head_outline()
    n = len(outline)
    verts = [(x, y, 0.0) for x, y in outline] + [(x, y, HEAD_THICK) for x, y in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    obj = make_object("BridgeHead", verts, faces, math.radians(35.0))
    # Merge the duplicated corner points (top and bottom edges share x = +/-0.06 at different y; only true
    # duplicates collapse) and fix winding so normals point out.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-7)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.set_sharp_from_angle(angle=math.radians(35.0))
    # Small bevel on every hard edge so it reads as a polished casting; harden normals keeps faces flat.
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = BEVEL_W
    bev.segments = 3
    bev.limit_method = "ANGLE"
    bev.angle_limit = math.radians(35.0)
    bev.harden_normals = True
    tri = obj.modifiers.new("Tri", "TRIANGULATE")
    tri.keep_custom_normals = True
    return obj


def handle_frame():
    """Axis rising so the far end's top sits at HANDLE_TOP_MAX, yawed 5 degrees to +X."""
    end_s = HANDLE_START + HANDLE_LEN
    pitch = math.asin((HANDLE_TOP_MAX - HANDLE_R1 - HANDLE_Y0) / end_s)
    axis = (math.cos(pitch) * math.sin(YAW), math.sin(pitch), math.cos(pitch) * math.cos(YAW))
    # u: horizontal perpendicular, v = axis x u (points roughly up)
    u = (math.cos(YAW), 0.0, -math.sin(YAW))
    v = (axis[1] * u[2] - axis[2] * u[1], axis[2] * u[0] - axis[0] * u[2], axis[0] * u[1] - axis[1] * u[0])
    origin = (HANDLE_X0, HANDLE_Y0, HEAD_THICK)
    return origin, axis, u, v


def build_ferrule(frame):
    # Short brass socket with a bead at the back and chamfered shoulders.
    prof = [(0.0, 0.0), (0.0, 0.0090), (0.002, 0.0100), (0.030, 0.0100), (0.032, 0.0108), (0.038, 0.0108),
            (0.040, 0.0100), (0.043, 0.0095), (FERRULE_LEN, 0.0085), (FERRULE_LEN, 0.0)]
    v, f = lathe(prof, frame)
    return make_object("BridgeFerrule", v, f, math.radians(40.0))


def build_handle(frame):
    prof = [(HANDLE_START, 0.0), (HANDLE_START, HANDLE_R0)]
    steps = 24
    for i in range(1, steps + 1):
        t = i / steps
        prof.append((HANDLE_START + t * (HANDLE_LEN - HANDLE_R1), HANDLE_R0 + (HANDLE_R1 - HANDLE_R0) * t))
    # rounded end cap: quarter circle of radius HANDLE_R1 ending on the axis at HANDLE_START + HANDLE_LEN
    base = HANDLE_START + HANDLE_LEN - HANDLE_R1
    for i in range(1, 9):
        a = 0.5 * math.pi * i / 8
        r = HANDLE_R1 * math.cos(a)
        prof.append((base + HANDLE_R1 * math.sin(a), 0.0 if i == 8 else r))
    v, f = lathe(prof, frame)
    return make_object("BridgeHandle", v, f, math.radians(50.0))


# ---------------------------------------------------------------- export and verification
def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(coll):
            coll.remove(item)


def export(path):
    """Writes a plain .usdc to a temp folder, stamps it Y-up / metres with pxr, then packs the .usdz."""
    import tempfile
    from pxr import Usd, UsdGeom, UsdUtils
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp_dir = tempfile.mkdtemp(prefix="bridge_usd_")
    tmp = os.path.join(tmp_dir, "Bridge.usdc")
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
    import shutil
    shutil.rmtree(tmp_dir, ignore_errors=True)


def verify(path):
    """Reads the exported file back with pxr and checks every contract number. Returns a report dict."""
    from pxr import Usd, UsdGeom, Gf
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
        if not prim.IsA(UsdGeom.Mesh):
            continue
        if prim.GetTypeName() in ("Camera",) or "Light" in prim.GetTypeName():
            errs.append("junk prim %s" % prim.GetPath())
        mesh = UsdGeom.Mesh(prim)
        xf = cache.GetLocalToWorldTransform(prim)
        pts = [xf.Transform(Gf.Vec3d(p)) for p in mesh.GetPointsAttr().Get()]
        counts = mesh.GetFaceVertexCountsAttr().Get()
        tris += sum(c - 2 for c in counts)
        parts[prim.GetName()] = pts
    rep["prims"] = prims
    rep["triangles"] = tris
    for name in ("BridgeHead", "BridgeFerrule", "BridgeHandle"):
        if name not in parts:
            errs.append("missing part %s" % name)
    bounds = {}
    for name, pts in parts.items():
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        bounds[name] = (lo, hi)
    rep["bounds"] = bounds
    if "BridgeHead" in parts:
        lo, hi = bounds["BridgeHead"]
        if abs(lo[1]) > 1e-6:
            errs.append("head lowest y %.6f" % lo[1])
        if abs(lo[2]) > 1e-6 or abs(hi[2] - HEAD_THICK) > 1e-6:
            errs.append("head z range %.6f..%.6f" % (lo[2], hi[2]))
        # Cradle bottom at x = 0: for each depth z, the lowest top-edge point (y above the arch); the bevel
        # rolls the front and back edges down a fraction of a millimetre, so the cue's resting height is the
        # highest of those, i.e. the flat between the bevels.
        by_z = {}
        for p in parts["BridgeHead"]:
            if abs(p[0]) < 1e-6 and p[1] > ARCH_H + 0.001:
                key = round(p[2], 6)
                by_z[key] = min(by_z.get(key, 1.0), p[1])
        cy = max(by_z.values()) if by_z else None
        rep["cradle_bottom_y"] = cy
        rep["cradle_flat_z"] = sorted(z for z, y in by_z.items() if cy and abs(y - cy) < 1e-6)
        if cy is None or abs(cy - CRADLE_Y) > 2e-6:
            errs.append("cradle bottom %s" % cy)
    if "BridgeHandle" in parts:
        lo, hi = bounds["BridgeHandle"]
        if hi[1] > 0.065:
            errs.append("handle top %.4f" % hi[1])
        if not (1.05 < hi[2] < 1.16):
            errs.append("handle far z %.4f" % hi[2])
        if lo[0] < 0.009:
            errs.append("handle reaches x %.4f (cue corridor)" % lo[0])
    if "BridgeFerrule" in parts and bounds["BridgeFerrule"][0][0] < 0.009:
        errs.append("ferrule reaches x %.4f (cue corridor)" % bounds["BridgeFerrule"][0][0])
    rep["errors"] = errs
    return rep


def cradle_half_width(y):
    """Analytic half-width of the centre notch at height y (same curve the mesh samples)."""
    lo, hi = 0.0, HEAD_HALF_W
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if head_top(mid) < y:
            lo = mid
        else:
            hi = mid
    return lo


CAM_POS = (-0.22, 0.16, -0.30)
CAM_TARGET = (0.02, 0.02, 0.12)


def render_preview(png):
    """Throwaway look-see render; runs after export so none of this reaches the file."""
    chrome = bpy.data.materials.new("chrome"); chrome.diffuse_color = (0.85, 0.86, 0.9, 1); chrome.roughness = 0.15
    brass = bpy.data.materials.new("brass"); brass.diffuse_color = (0.8, 0.6, 0.25, 1); brass.metallic = 1; brass.roughness = 0.3
    wood = bpy.data.materials.new("wood"); wood.diffuse_color = (0.45, 0.25, 0.1, 1); wood.roughness = 0.5
    for name, mat in (("BridgeHead", chrome), ("BridgeFerrule", brass), ("BridgeHandle", wood)):
        bpy.data.objects[name].data.materials.append(mat)
    bpy.ops.mesh.primitive_plane_add(size=3, location=(0, 0, 0.5), rotation=(-math.pi / 2, 0, 0))
    cloth = bpy.data.materials.new("cloth"); cloth.diffuse_color = (0.05, 0.3, 0.12, 1)
    bpy.context.active_object.data.materials.append(cloth)
    # a stand-in cue (radius 7.5 mm) resting in the cradle, for the eye only
    bpy.ops.mesh.primitive_cylinder_add(radius=0.0075, depth=1.2, location=rk_to_blender((0, CRADLE_Y + 0.0075, 0.3)))
    cue = bpy.data.materials.new("cue"); cue.diffuse_color = (0.9, 0.8, 0.6, 1)
    bpy.context.active_object.data.materials.append(cue)
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_WORKBENCH"
    scn.display.shading.color_type = "MATERIAL"
    scn.display.shading.light = "STUDIO"
    scn.display.shading.show_shadows = True
    scn.display.shading.show_cavity = True
    scn.render.resolution_x, scn.render.resolution_y = 1400, 900
    cam_d = bpy.data.cameras.new("cam"); cam_d.lens = 50
    cam = bpy.data.objects.new("cam", cam_d); scn.collection.objects.link(cam)
    cam.location = rk_to_blender(CAM_POS)
    target = rk_to_blender(CAM_TARGET)
    d = [target[i] - cam.location[i] for i in range(3)]
    from mathutils import Vector
    cam.rotation_euler = Vector(d).to_track_quat("-Z", "Y").to_euler()  # scene is Y-up
    scn.camera = cam
    sun_d = bpy.data.lights.new("sun", "SUN"); sun_d.energy = 4
    sun = bpy.data.objects.new("sun", sun_d); scn.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(-60), math.radians(20), 0)
    scn.world = bpy.data.worlds.new("w"); scn.world.color = (0.5, 0.5, 0.55)
    scn.render.filepath = png
    bpy.ops.render.render(write_still=True)
    # second look: straight at the front face, orthographic, to judge the notch profile
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = 0.14
    cam.location = rk_to_blender((0.0, 0.03, -0.5))
    cam.rotation_euler = (0.0, math.pi, 0.0)   # camera looks down its -Z; half a turn about Y looks along +Z
    scn.render.filepath = png.replace(".png", "-front.png")
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else None
    clear_scene()
    build_head()
    frame = handle_frame()
    build_ferrule(frame)
    build_handle(frame)
    export(OUT_PATH)
    rep = verify(OUT_PATH)
    print("BRIDGE REPORT")
    for k, v in rep.items():
        print("  %s: %s" % (k, v))
    for r in (0.0065, 0.0075, 0.0090):
        print("  cradle half-width at cue centre height (cue r=%.4f, y=%.4f): %.5f" %
              (r, CRADLE_Y + r, cradle_half_width(CRADLE_Y + r)))
    if preview:
        render_preview(preview)
    if rep["errors"]:
        print("BRIDGE CHECK FAILED:", rep["errors"])
        sys.exit(1)
    print("BRIDGE CHECK PASSED")


main()
