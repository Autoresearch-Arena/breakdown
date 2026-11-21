# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Builds the Breakdown pool cue as a 3D model in Blender and writes App/Models/Cue.usdz, which the
#          RealityKit scene loads by name from the app bundle. The cue is a body of revolution: every part is a
#          side profile (radius against distance along the cue) spun once around the cue's axis. Nine parts are
#          separate named meshes, tip to butt: CueTip, CueFerrule, CueShaft, CueJoint, CueForearm, CueRings, CueWrap,
#          CueSleeve, CueBumper. No materials are exported; the Swift side paints each part by its name.
#          Frame (the shared contract with the Swift integrator): metres, +Y up, the cue laid along +Z with the
#          centre of the tip's striking face at the origin and the butt end at z = 1.47. The geometry is built
#          directly in that frame (Blender's Z axis is the cue axis), exported without Blender's axis conversion so
#          the points carry no hidden root rotation, and the stage is then re-labelled Y-up with pxr before it is
#          packed into the .usdz. Every part's local transform is identity.
#          Usage (headless, deterministic; nothing random):
#            Blender -b --factory-startup --python Tools/blender/make_cue.py -- [--out PATH] [--preview DIR]
#          The export is always read back with pxr and checked (up axis, units, part names, bounds, triangle count,
#          radius where a bridge carries the cue); the script exits non-zero if any check fails. --preview renders
#          throwaway close-up PNGs (materials and camera exist only after the export, so they never ship).
# SRP/DRY check: Pass - the only generator for the cue model; the bridge has its own generator. The lathe and
#          corner-rounding helpers live here because no other Python in the project builds meshes.

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------------------------------------------
# Dimensions (metres). Diameters from the contract are halved to radii here.
# ---------------------------------------------------------------------------------------------------------------
REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DEFAULT_OUT = os.path.join(REPO, "App", "Models", "Cue.usdz")

SEGMENTS = 64            # vertices around the cue for every part
CUE_LENGTH = 1.47        # 58 inch cue
JOINT_Z = 0.735          # where shaft meets the joint collar
BRIDGE_Z = 0.30          # where a mechanical bridge carries the cue; a ring is placed exactly here

TIP_R = 0.0065           # 13 mm tip and ferrule
TIP_LEN = 0.007
TIP_DOME_SPHERE = 0.025  # radius of the sphere the tip face is cut from (shallow dome, about 0.85 mm high)
FERRULE_END = TIP_LEN + 0.018
FERRULE_END_R = 0.00655
SHAFT_JOINT_R = 0.0105   # 21 mm at the joint
SHAFT_TAPER_POWER = 2.2  # pro taper: radius grows with (distance fraction) ** power, so it stays slim near the tip
JOINT_END = JOINT_Z + 0.012
JOINT_R = 0.0111
FOREARM_START_R = 0.0109
WRAP_START = 1.112       # forearm ends here; the trim rings sit on the forearm just before it
WRAP_END = WRAP_START + 0.27
WRAP_START_R = 0.0130
WRAP_END_R = 0.0145
SLEEVE_END = 1.455
SLEEVE_END_R = 0.0155    # the fattest point of the cue (31 mm)
BUMPER_R = 0.0152


# ---------------------------------------------------------------------------------------------------------------
# Profile helpers. A profile is a list of (radius, z) points walked from the tip side to the butt side. Walking
# that way keeps the outside of the surface on the same side everywhere, so faces point outward without fixing up.
# ---------------------------------------------------------------------------------------------------------------
def round_corners(points, radii, steps=4):
    """Replace each corner i that has radii[i] > 0 with a circular arc of that radius (a fillet / bevel).
    The tangent length is clamped to just under half of each neighbouring edge so two fillets never overlap."""
    out = [points[0]]
    for i in range(1, len(points) - 1):
        rad = radii.get(i, 0.0)
        p = points[i]
        if rad <= 0:
            out.append(p)
            continue
        a, b = points[i - 1], points[i + 1]
        d1 = (a[0] - p[0], a[1] - p[1])
        d2 = (b[0] - p[0], b[1] - p[1])
        l1, l2 = math.hypot(*d1), math.hypot(*d2)
        d1 = (d1[0] / l1, d1[1] / l1)
        d2 = (d2[0] / l2, d2[1] / l2)
        cos_full = max(-1.0, min(1.0, d1[0] * d2[0] + d1[1] * d2[1]))
        half = math.acos(cos_full) / 2.0
        if half < 1e-6 or abs(half - math.pi / 2) < 1e-6:
            out.append(p)  # straight line, nothing to round
            continue
        t = rad / math.tan(half)
        t = min(t, 0.45 * l1, 0.45 * l2)
        rad = t * math.tan(half)
        t1 = (p[0] + d1[0] * t, p[1] + d1[1] * t)
        t2 = (p[0] + d2[0] * t, p[1] + d2[1] * t)
        bis = (d1[0] + d2[0], d1[1] + d2[1])
        lb = math.hypot(*bis)
        bis = (bis[0] / lb, bis[1] / lb)
        dc = rad / math.sin(half)
        c = (p[0] + bis[0] * dc, p[1] + bis[1] * dc)
        a1 = math.atan2(t1[1] - c[1], t1[0] - c[0])
        a2 = math.atan2(t2[1] - c[1], t2[0] - c[0])
        sweep = a2 - a1  # take the short way round the centre
        while sweep > math.pi:
            sweep -= 2 * math.pi
        while sweep < -math.pi:
            sweep += 2 * math.pi
        for k in range(steps + 1):
            ang = a1 + sweep * k / steps
            out.append((c[0] + rad * math.cos(ang), c[1] + rad * math.sin(ang)))
    out.append(points[-1])
    return out


def lathe(name, profile, segments=SEGMENTS):
    """Spin a (radius, z) profile around the Z axis into a named mesh object (object and mesh data share the
    name so the exported prim carries it). A point with radius 0 becomes a single pole vertex closing the end."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    rings = []
    for r, z in profile:
        if r <= 1e-9:
            rings.append([bm.verts.new((0.0, 0.0, z))])
        else:
            rings.append([bm.verts.new((r * math.cos(2 * math.pi * j / segments),
                                        r * math.sin(2 * math.pi * j / segments), z))
                          for j in range(segments)])
    zs = [z for _, z in profile]
    z0, z1 = min(zs), max(zs)

    def v_of(z):
        return (z - z0) / max(z1 - z0, 1e-9)

    for i in range(len(rings) - 1):
        ra, rb = rings[i], rings[i + 1]
        za, zb = profile[i][1], profile[i + 1][1]
        for j in range(segments):
            jn = (j + 1) % segments
            # u runs 0..1 around the cue (the seam face uses 1.0, not 0.0); v runs 0..1 along the part.
            ua, ub = j / segments, (j + 1) / segments
            if len(ra) == 1:
                verts, uvs = [ra[0], rb[jn], rb[j]], [((ua + ub) / 2, v_of(za)), (ub, v_of(zb)), (ua, v_of(zb))]
            elif len(rb) == 1:
                verts, uvs = [ra[j], ra[jn], rb[0]], [(ua, v_of(za)), (ub, v_of(za)), ((ua + ub) / 2, v_of(zb))]
            else:
                verts = [ra[j], ra[jn], rb[jn], rb[j]]
                uvs = [(ua, v_of(za)), (ub, v_of(za)), (ub, v_of(zb)), (ua, v_of(zb))]
            f = bm.faces.new(verts)
            for loop, coord in zip(f.loops, uvs):
                loop[uv].uv = coord
    bm.to_mesh(me)
    bm.free()
    me.shade_smooth()
    # Creases sharper than this stay crisp (bevel ends, step faces); gentle curves and fillets stay smooth.
    me.set_sharp_from_angle(angle=math.radians(40))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


# ---------------------------------------------------------------------------------------------------------------
# The nine parts, tip to butt. Each profile starts at the radius where the previous part ended (or a little
# inside it) so any step between parts is closed by a small ring face instead of leaving a gap.
# ---------------------------------------------------------------------------------------------------------------
def shaft_radius(z):
    """Pro taper: slim and nearly parallel for the first third, then swelling smoothly to the joint.
    Continuous in radius and slope everywhere (slope is zero at the ferrule)."""
    s = (z - FERRULE_END) / (JOINT_Z - FERRULE_END)
    return FERRULE_END_R + (SHAFT_JOINT_R - FERRULE_END_R) * (s ** SHAFT_TAPER_POWER)


def build_parts():
    # Tip: a shallow dome whose apex is the origin, rounded into the leather side wall.
    def dome_z(r):
        return TIP_DOME_SPHERE - math.sqrt(TIP_DOME_SPHERE ** 2 - r * r)
    tip = [(0.0, 0.0)] + [(TIP_R * k / 6, dome_z(TIP_R * k / 6)) for k in range(1, 6)]
    corner = len(tip)
    tip += [(TIP_R, dome_z(TIP_R)), (TIP_R, TIP_LEN)]
    lathe("CueTip", round_corners(tip, {corner: 0.0009}, steps=5))

    lathe("CueFerrule", [(TIP_R, TIP_LEN), (FERRULE_END_R, FERRULE_END)])

    # Shaft rings: spaced more tightly where the taper bends most, plus one ring exactly at the bridge height.
    zs = {FERRULE_END, JOINT_Z, BRIDGE_Z}
    n = 40
    for k in range(1, n):
        s = k / n
        zs.add(FERRULE_END + (JOINT_Z - FERRULE_END) * s)
    lathe("CueShaft", [(shaft_radius(z), z) for z in sorted(zs)])

    # Joint collar: a metal ring a touch proud of the shaft, bevelled both ends, with a fine centre line.
    mid = (JOINT_Z + JOINT_END) / 2
    joint = [(SHAFT_JOINT_R, JOINT_Z), (JOINT_R, JOINT_Z),
             (JOINT_R, mid - 0.0006), (JOINT_R - 0.00018, mid), (JOINT_R, mid + 0.0006),
             (JOINT_R, JOINT_END), (FOREARM_START_R, JOINT_END)]
    lathe("CueJoint", round_corners(joint, {1: 0.0004, 5: 0.0004}, steps=3))

    # Forearm: dark wood widening straight to the wrap. It runs under the trim rings to the wrap start.
    lathe("CueForearm", [(FOREARM_START_R + (WRAP_START_R - FOREARM_START_R) * k / 4,
                          JOINT_END + (WRAP_START - JOINT_END) * k / 4) for k in range(5)])

    # Trim rings: three thin bands inlaid into the forearm just before the wrap, each standing 0.2 mm proud
    # with rounded edges; the forearm wood shows between them. Their inner edge sits just inside the forearm
    # surface so no gap can open. One object, three separate shells.
    bands = []
    for z0 in (WRAP_START - 0.0105, WRAP_START - 0.0070, WRAP_START - 0.0035):
        base = FOREARM_START_R + (WRAP_START_R - FOREARM_START_R) * (z0 - JOINT_END) / (WRAP_START - JOINT_END)
        prof = [(base - 0.00003, z0), (base + 0.0002, z0), (base + 0.0002, z0 + 0.002), (base - 0.00003, z0 + 0.002)]
        bands.append(round_corners(prof, {1: 0.00012, 2: 0.00012}, steps=3))
    rings_ob = None
    for k, prof in enumerate(bands):
        ob = lathe("CueRings" if k == 0 else "CueRingsPart%d" % k, prof)
        rings_ob = rings_ob or ob
    join_into(rings_ob, [o for o in bpy.data.objects if o.name.startswith("CueRingsPart")])

    # Wrap: smooth (a linen texture is better left to the material), with a small rolled bead at each end
    # where the wrap is finished off, as on a real cue.
    def wrap_r(z):
        return WRAP_START_R + (WRAP_END_R - WRAP_START_R) * (z - WRAP_START) / (WRAP_END - WRAP_START)
    bead = 0.0016
    wrap = [(WRAP_START_R, WRAP_START), (wrap_r(WRAP_START) + 0.00025, WRAP_START + bead * 0.5),
            (wrap_r(WRAP_START + bead), WRAP_START + bead)]
    for k in range(1, 8):
        z = WRAP_START + bead + (WRAP_END - WRAP_START - 2 * bead) * k / 8
        wrap.append((wrap_r(z), z))
    wrap += [(wrap_r(WRAP_END - bead), WRAP_END - bead), (wrap_r(WRAP_END) + 0.00025, WRAP_END - bead * 0.5),
             (WRAP_END_R, WRAP_END)]
    lathe("CueWrap", round_corners(wrap, {1: 0.0006, len(wrap) - 2: 0.0006}, steps=3))

    # Butt sleeve: starts with a small shoulder just proud of the wrap, swells to the widest point, then
    # rounds in to meet the bumper.
    sleeve = [(WRAP_END_R - 0.00005, WRAP_END), (WRAP_END_R + 0.0003, WRAP_END),
              (SLEEVE_END_R - 0.0002, WRAP_END + 0.030), (SLEEVE_END_R, SLEEVE_END - 0.001),
              (SLEEVE_END_R, SLEEVE_END), (BUMPER_R - 0.0001, SLEEVE_END)]
    lathe("CueSleeve", round_corners(sleeve, {1: 0.0003, 4: 0.0005}, steps=3))

    # Bumper: black rubber cap, rounded over at the end and closed with a pole at z = 1.47.
    bumper = [(BUMPER_R - 0.0001, SLEEVE_END), (BUMPER_R, SLEEVE_END), (BUMPER_R, CUE_LENGTH), (0.0, CUE_LENGTH)]
    lathe("CueBumper", round_corners(bumper, {1: 0.0002, 2: 0.005}, steps=8))


def join_into(target, others):
    """Merge several objects into one (the trim rings are one part made of three bands)."""
    if not others:
        return
    bm = bmesh.new()
    bm.from_mesh(target.data)
    for o in others:
        bm.from_mesh(o.data)
    bm.to_mesh(target.data)
    bm.free()
    for o in others:
        me = o.data
        bpy.data.objects.remove(o)
        bpy.data.meshes.remove(me)


# ---------------------------------------------------------------------------------------------------------------
# Export, then repackage as a Y-up stage. Blender writes upAxis Z; the points are already in the target frame,
# so only the stage label changes (no rotation is added anywhere).
# ---------------------------------------------------------------------------------------------------------------
PART_NAMES = ["CueTip", "CueFerrule", "CueShaft", "CueJoint", "CueForearm", "CueRings", "CueWrap", "CueSleeve",
              "CueBumper"]


def export(out_path):
    from pxr import Usd, UsdGeom, UsdUtils
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    tmp_usdc = os.path.splitext(out_path)[0] + "_tmp.usdc"
    bpy.ops.wm.usd_export(filepath=tmp_usdc, export_materials=False, export_lights=False, export_cameras=False,
                          export_animation=False, convert_orientation=False, merge_parent_xform=True,
                          export_custom_properties=False, author_blender_name=False, export_normals=True,
                          export_uvmaps=True, root_prim_path="/root", meters_per_unit=1.0)
    stage = Usd.Stage.Open(tmp_usdc)
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    UsdGeom.SetStageMetersPerUnit(stage, 1.0)
    stage.SetDefaultPrim(stage.GetPrimAtPath("/root"))
    stage.GetRootLayer().Save()
    if os.path.exists(out_path):
        os.remove(out_path)
    ok = UsdUtils.CreateNewUsdzPackage(tmp_usdc, out_path)
    os.remove(tmp_usdc)
    if not ok:
        raise SystemExit("usdz packaging failed")


def verify(path):
    """Read the shipped file back and check it against the contract. Returns a list of problems (empty = good)."""
    from pxr import Usd, UsdGeom, Gf
    problems = []
    stage = Usd.Stage.Open(path)
    up, mpu = UsdGeom.GetStageUpAxis(stage), UsdGeom.GetStageMetersPerUnit(stage)
    print("VERIFY file:", path)
    print("VERIFY upAxis:", up, " metersPerUnit:", mpu, " defaultPrim:", stage.GetDefaultPrim().GetPath())
    if up != "Y":
        problems.append("up axis is %s" % up)
    if abs(mpu - 1.0) > 1e-9:
        problems.append("metersPerUnit is %s" % mpu)
    cache = UsdGeom.BBoxCache(Usd.TimeCode.Default(), [UsdGeom.Tokens.default_])
    total_tris, found = 0, {}
    for prim in stage.Traverse():
        line = "VERIFY prim: %s (%s)" % (prim.GetPath(), prim.GetTypeName())
        if prim.IsA(UsdGeom.Xformable):
            m = UsdGeom.Xformable(prim).ComputeLocalToWorldTransform(Usd.TimeCode.Default())
            if not Gf.IsClose(m, Gf.Matrix4d(1.0), 1e-9):
                problems.append("%s has a non-identity transform" % prim.GetPath())
        if prim.IsA(UsdGeom.Mesh):
            mesh = UsdGeom.Mesh(prim)
            tris = sum(c - 2 for c in mesh.GetFaceVertexCountsAttr().Get())
            total_tris += tris
            b = cache.ComputeWorldBound(prim).ComputeAlignedRange()
            found[prim.GetName()] = prim
            line += " tris=%d z=[%.5f, %.5f] maxXY=%.5f" % (tris, b.GetMin()[2], b.GetMax()[2],
                                                           max(abs(b.GetMin()[0]), b.GetMax()[0]))
        elif prim.GetTypeName() not in ("Xform", "Scope"):
            problems.append("unexpected prim %s of type %s" % (prim.GetPath(), prim.GetTypeName()))
        print(line)
    for name in PART_NAMES:
        if name not in found:
            problems.append("missing part %s" % name)
    extra = sorted(set(found) - set(PART_NAMES))
    if extra:
        problems.append("unexpected meshes %s" % extra)
    whole = cache.ComputeWorldBound(stage.GetPrimAtPath("/root")).ComputeAlignedRange()
    lo, hi = whole.GetMin(), whole.GetMax()
    print("VERIFY bounds min: (%.5f, %.5f, %.5f) max: (%.5f, %.5f, %.5f)" % (lo[0], lo[1], lo[2], hi[0], hi[1], hi[2]))
    print("VERIFY total triangles:", total_tris)
    for axis in (0, 1):
        if abs(hi[axis] - 0.0155) > 0.0003 or abs(lo[axis] + 0.0155) > 0.0003:
            problems.append("radial bound on axis %d is off" % axis)
    if abs(lo[2]) > 1e-6 or abs(hi[2] - CUE_LENGTH) > 1e-6:
        problems.append("length bounds off: %f..%f" % (lo[2], hi[2]))
    if total_tris >= 30000:
        problems.append("too many triangles")
    # Radius where the bridge carries the cue, measured from the shipped shaft vertices on the z = 0.30 ring.
    if "CueShaft" in found:
        pts = UsdGeom.Mesh(found["CueShaft"]).GetPointsAttr().Get()
        ring = [math.hypot(p[0], p[1]) for p in pts if abs(p[2] - BRIDGE_Z) < 1e-6]
        if not ring:
            problems.append("no shaft ring at z = 0.30")
        else:
            r = max(ring)
            print("VERIFY shaft radius at z=0.30: vertex %.6f m, facet-flat minimum %.6f m (%d vertices)"
                  % (r, r * math.cos(math.pi / SEGMENTS), len(ring)))
    # Tip face: the vertex at the origin must be the striking-face centre.
    if "CueTip" in found:
        pts = UsdGeom.Mesh(found["CueTip"]).GetPointsAttr().Get()
        if not any(abs(p[0]) < 1e-9 and abs(p[1]) < 1e-9 and abs(p[2]) < 1e-9 for p in pts):
            problems.append("tip face centre is not at the origin")
    return problems


# ---------------------------------------------------------------------------------------------------------------
# Throwaway preview renders (only after the export has been written, so none of this can ship).
# ---------------------------------------------------------------------------------------------------------------
PREVIEW_COLOURS = {
    "CueTip": (0.10, 0.22, 0.45), "CueFerrule": (0.93, 0.92, 0.88), "CueShaft": (0.86, 0.74, 0.55),
    "CueJoint": (0.75, 0.75, 0.78), "CueForearm": (0.20, 0.09, 0.05), "CueRings": (0.92, 0.90, 0.82),
    "CueWrap": (0.08, 0.08, 0.09), "CueSleeve": (0.25, 0.10, 0.06), "CueBumper": (0.02, 0.02, 0.02),
}


def preview(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    scene = bpy.context.scene
    pivot = bpy.data.objects.new("PreviewPivot", None)
    scene.collection.objects.link(pivot)
    for name, col in PREVIEW_COLOURS.items():
        ob = bpy.data.objects[name]
        mat = bpy.data.materials.new(name + "Preview")
        mat.diffuse_color = col + (1.0,)
        mat.metallic = 0.8 if name in ("CueJoint",) else 0.0
        mat.roughness = 0.35
        ob.data.materials.append(mat)
        ob.parent = pivot
    pivot.rotation_euler = (0.0, math.radians(90), 0.0)  # lay the cue along +X for a side view
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_specular_highlight = True
    scene.display.shading.show_cavity = False
    scene.world = scene.world or bpy.data.worlds.new("World")
    scene.render.film_transparent = False
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    # Looking down -Y at a slight tilt so the round shading reads.
    cam.rotation_euler = (math.radians(80), 0.0, 0.0)
    shots = [("full", 0.735, 1.52, 2400, 220), ("tip", 0.030, 0.07, 1200, 600), ("joint", 0.735, 0.07, 1200, 600),
             ("rings", 1.105, 0.07, 1200, 600), ("butt", 1.43, 0.09, 1200, 600)]
    for tag, x, scale, w, h in shots:
        cam_data.ortho_scale = scale
        cam.location = (x, -0.5, 0.088)
        scene.render.resolution_x, scene.render.resolution_y = w, h
        scene.render.filepath = os.path.join(out_dir, "cue-preview-%s.png" % tag)
        bpy.ops.render.render(write_still=True)
        print("PREVIEW", scene.render.filepath)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = DEFAULT_OUT
    preview_dir = None
    if "--out" in argv:
        out = os.path.abspath(argv[argv.index("--out") + 1])
    if "--preview" in argv:
        preview_dir = os.path.abspath(argv[argv.index("--preview") + 1])
    # Start from an empty scene so the export holds only the cue.
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    build_parts()
    export(out)
    problems = verify(out)
    if preview_dir:
        preview(preview_dir)
    if problems:
        print("VERIFY FAILED:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print("VERIFY OK")


main()
