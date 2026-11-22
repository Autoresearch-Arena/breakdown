# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Exports the other developer's six cues and the swan-neck rest from art/equipment/*.blend into the app as
#          RealityKit models (plan item 57, plans/21-Nov-2026-bugs-after-0-6-6-plan.md), then reads every file back and
#          checks it. Writes App/Models/CueHouse.usdz, CueBreak.usdz, CueJump.usdz, CueMasse.usdz, CueRosewood.usdz,
#          CueCobalt.usdz and SwanNeckRest.usdz, which App/CueRig.swift loads by name. Run headless:
#              /opt/homebrew/bin/blender -b --factory-startup --python Tools/blender/export_equipment.py -- \
#                  [--out-dir DIR] [--preview DIR]
#          The same .blend files give the same geometry every run (checked point for point; the order of the parts
#          inside the file, and so its bytes, can differ between runs). Nothing is redrawn: the geometry is the art's
#          own, only moved into the app's frame and grouped by finish.
#          How (the same export-and-verify route as make_cue.py and make_bridge.py):
#            1. Open one .blend and take the objects that belong to the piece (its own collection; for the rest also
#               the three rubber foot pads that sit under its brass feet, and NOT the demonstration cue lying in it).
#               Curves (the rest's neck, feet, cradle and handle) are turned into meshes as the file evaluates them.
#            2. Move every vertex into the app's frame (below), so each prim ends with an identity transform.
#            3. Join the parts that share a finish into one mesh named after it (OilFinishedMaple, SatinBrass, ...).
#               No materials are exported: CueRig.swift paints each part by that name, from the finish table this
#               script prints (the art's own Principled colours, turned from linear light into the screen's sRGB;
#               a grained finish gives the mean of its grain's two colours).
#            4. Export without Blender's axis conversion, re-label the stage Y-up with pxr, pack it as .usdz.
#            5. Read the .usdz back and check: up axis, metres, identity transforms, the expected part names, the
#               bounds (a cue's tip face at z = 0 and its butt at its length; the rest standing on y = 0 with its
#               cradle over the origin), and a triangle budget. Any failed check exits non-zero.
#          Frames (the contract with CueRig.swift): metres, +Y up.
#            Cue  - the centre of the tip's striking face at the origin, the axis along +Z to the butt.
#            Rest - the origin on the cloth straight under the bottom of the V cradle, the cradle across X, the
#                   handle running back along +Z (away from the cue ball), the brass neck reaching forward over
#                   any ball between the feet and the cradle.
#          It also prints the numbers CueRig needs (each cue's shaft radius 0.30 m from its tip, and how high the
#          cue's axis rides when that shaft lies in the cradle) so the Swift constants can quote a measurement.
# SRP/DRY check: Pass - make_cue.py and make_bridge.py build the old code-made cue and bridge from scratch; this one
#          only exports the other developer's art, so it shares their export/verify steps but not their geometry.
#          Kept beside them rather than editing them, as the batch rules ask.

import math
import os
import sys

import bpy

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ART = os.path.join(REPO, "art", "equipment")
DEFAULT_OUT = os.path.join(REPO, "App", "Models")

# Where a hand or rest bridge carries the cue, metres from the tip (CueRig.bridgeSetback): the shaft radius here sets
# how high the cue rides in the rest's cradle.
BRIDGE_Z = 0.30
# Triangle budget per model: the old code-made cue was held under 30,000; the art is far lighter than that.
MAX_TRIS = 30000


def masse_frame(p):
    """The massé cue was drawn lying along Blender's +X, tip at x = -0.63, axis 17 mm above the baize. Turn it so the
    tip face centre is the origin and the axis runs along +Z: (x, y, z) -> (y, z - 0.017, x + 0.63). A proper
    rotation (determinant +1), so nothing is mirrored."""
    return (p[1], p[2] - MASSE_AXIS_Z, p[0] + MASSE_TIP_X)


MASSE_TIP_X = 0.63
MASSE_AXIS_Z = 0.017


def studio_cue_frame(p):
    """The five studio cues were built along Blender's +Z from the tip face (z = 0) to the butt: already the app's
    frame, so the points are kept as they are (only the stage is re-labelled Y-up at export)."""
    return (p[0], p[1], p[2])


REST_CRADLE_Y = 0.062


def rest_frame(p):
    """The rest was drawn standing on the baize (Blender z up) with its cradle at y = 0.062 facing +Y toward the cue
    ball and its handle running back along -Y. The app wants +Y up and the handle along +Z:
    (x, y, z) -> (x, z, 0.062 - y). A proper rotation (determinant +1)."""
    return (p[0], p[2], REST_CRADLE_Y - p[1])


# One entry per exported model: the .blend, the collection holding the piece, extra objects that belong to it but
# sit in the scene collection, objects in the collection that do not belong to it, the frame mapping and the
# expected length (cues) for the check.
PIECES = [
    dict(out="CueHouse", blend="house-maple.blend", collection="House maple", frame=studio_cue_frame, length=1.47),
    dict(out="CueBreak", blend="oxblood-break.blend", collection="Oxblood break", frame=studio_cue_frame, length=1.47),
    dict(out="CueJump", blend="amber-jump.blend", collection="Amber jump", frame=studio_cue_frame, length=1.05),
    dict(out="CueMasse", blend="masse-cue.blend", collection="Massé cue", frame=masse_frame, length=1.26,
         skip=("Baize",)),
    dict(out="CueRosewood", blend="rosewood-four-point.blend", collection="Rosewood four-point",
         frame=studio_cue_frame, length=1.47),
    dict(out="CueCobalt", blend="cobalt.blend", collection="Cobalt", frame=studio_cue_frame, length=1.47),
    dict(out="SwanNeckRest", blend="swan-neck-rest.blend", collection="Swan-neck span rest", frame=rest_frame,
         extra_prefix="Rubber foot",
         # The demonstration cue lying in the cradle and the baize are part of the art's scene, not of the rest.
         skip=("Baize", "Leather tip", "Cream ferrule", "Maple shaft", "Dark butt")),
]


def part_name(material_name):
    """A finish's part name: the material's words run together ("Oil finished maple" -> "OilFinishedMaple")."""
    ascii_name = material_name.replace("é", "e")
    return "".join(w[:1].upper() + w[1:] for w in ascii_name.replace("-", " ").split())


def to_srgb(c):
    """Linear light (Blender's colour values) to the sRGB components a UIColor / NSColor takes."""
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def finish_of(material):
    """The finish CueRig paints: sRGB base colour (a grained finish gives the mean of its ramp's two colours, in
    linear light, before the conversion), roughness and metalness, all read from the art's Principled BSDF."""
    nodes = material.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    base = list(bsdf.inputs["Base Color"].default_value)[:3]
    ramp = next((n for n in nodes if n.type == "VALTORGB"), None)
    if ramp is not None:
        els = ramp.color_ramp.elements
        base = [(els[0].color[i] + els[-1].color[i]) / 2 for i in range(3)]
    return dict(rgb=tuple(round(to_srgb(c), 3) for c in base),
                rough=round(bsdf.inputs["Roughness"].default_value, 3),
                metal=round(bsdf.inputs["Metallic"].default_value, 3))


def collect(piece):
    """Open the piece's .blend and return {part name: (verts, faces)} in the app's frame, plus the finish table."""
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ART, piece["blend"]))
    coll = bpy.data.collections[piece["collection"]]
    skip = set(piece.get("skip", ()))
    objects = [o for o in coll.objects if o.name not in skip]
    if piece.get("extra_prefix"):
        objects += [o for o in bpy.data.objects if o.name.startswith(piece["extra_prefix"]) and o not in objects]
    depsgraph = bpy.context.evaluated_depsgraph_get()
    parts, finishes = {}, {}
    for ob in sorted(objects, key=lambda o: o.name):
        if ob.type not in ("MESH", "CURVE"):
            continue
        evaluated = ob.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()            # curves come back as their bevelled tube mesh
        material = ob.data.materials[0]
        name = part_name(material.name)
        finishes[name] = finish_of(material)
        verts, faces = parts.setdefault(name, ([], []))
        base = len(verts)
        for v in mesh.vertices:
            verts.append(piece["frame"](tuple(ob.matrix_world @ v.co)))
        for poly in mesh.polygons:
            faces.append(tuple(base + i for i in poly.vertices))
        evaluated.to_mesh_clear()
    return parts, finishes


def build(parts):
    """Empty the scene and make one mesh object per finish, named after it (object and mesh share the name, so the
    USD prim carries it). Smooth across gentle angles, sharp at a turned part's flat ends."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    for name, (verts, faces) in sorted(parts.items()):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        mesh.validate()
        mesh.update()
        ob = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(ob)
        for poly in mesh.polygons:
            poly.use_smooth = True
        # 40 degrees: the cue's slow taper and the rest's round tubes stay smooth, an end cap's square edge stays
        # crisp (the art turned every face smooth, which would shade a flat cap like a dome).
        mesh.set_sharp_from_angle(angle=math.radians(40))


def export(out_path):
    """Write the scene as a Y-up, metre .usdz with /root as the default prim (make_cue.py's steps)."""
    from pxr import Usd, UsdGeom, UsdUtils
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    tmp_usdc = os.path.splitext(out_path)[0] + "_tmp.usdc"
    bpy.ops.wm.usd_export(filepath=tmp_usdc, export_materials=False, export_lights=False, export_cameras=False,
                          export_animation=False, convert_orientation=False, merge_parent_xform=True,
                          export_custom_properties=False, author_blender_name=False, export_normals=True,
                          export_uvmaps=False, root_prim_path="/root", meters_per_unit=1.0)
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
        raise SystemExit("usdz packaging failed: %s" % out_path)


def verify(path, piece, expected_parts):
    """Read the shipped file back and check it against the frame contract. Returns (problems, points by part)."""
    from pxr import Usd, UsdGeom, Gf
    problems = []
    stage = Usd.Stage.Open(path)
    if UsdGeom.GetStageUpAxis(stage) != "Y":
        problems.append("up axis is not Y")
    if abs(UsdGeom.GetStageMetersPerUnit(stage) - 1.0) > 1e-9:
        problems.append("not in metres")
    cache = UsdGeom.BBoxCache(Usd.TimeCode.Default(), [UsdGeom.Tokens.default_])
    tris, points = 0, {}
    for prim in stage.Traverse():
        if prim.IsA(UsdGeom.Xformable):
            m = UsdGeom.Xformable(prim).ComputeLocalToWorldTransform(Usd.TimeCode.Default())
            if not Gf.IsClose(m, Gf.Matrix4d(1.0), 1e-9):
                problems.append("%s has a non-identity transform" % prim.GetPath())
        if prim.IsA(UsdGeom.Mesh):
            mesh = UsdGeom.Mesh(prim)
            tris += sum(c - 2 for c in mesh.GetFaceVertexCountsAttr().Get())
            points[prim.GetName()] = [tuple(p) for p in mesh.GetPointsAttr().Get()]
        elif prim.GetTypeName() not in ("Xform", "Scope"):
            problems.append("unexpected prim %s of type %s" % (prim.GetPath(), prim.GetTypeName()))
    if set(points) != set(expected_parts):
        problems.append("parts %s, expected %s" % (sorted(points), sorted(expected_parts)))
    whole = cache.ComputeWorldBound(stage.GetPrimAtPath("/root")).ComputeAlignedRange()
    lo, hi = whole.GetMin(), whole.GetMax()
    print("VERIFY %s bounds (%.4f, %.4f, %.4f) to (%.4f, %.4f, %.4f), %d triangles"
          % (os.path.basename(path), lo[0], lo[1], lo[2], hi[0], hi[1], hi[2], tris))
    if tris > MAX_TRIS:
        problems.append("%d triangles is over the budget" % tris)
    if "length" in piece:
        # A cue: the tip face at z = 0, the butt at the cue's length, the axis on z, no wider than a 32 mm butt.
        if abs(lo[2]) > 1e-4 or abs(hi[2] - piece["length"]) > 1e-4:
            problems.append("length runs %.5f to %.5f, expected 0 to %.3f" % (lo[2], hi[2], piece["length"]))
        for axis in (0, 1):
            if hi[axis] > 0.0165 or lo[axis] < -0.0165 or abs(hi[axis] + lo[axis]) > 1e-4:
                problems.append("radial bound on axis %d is off: %.5f to %.5f" % (axis, lo[axis], hi[axis]))
    else:
        # The rest: standing on the cloth (nothing below y = 0), the cradle over the origin, the handle behind.
        if lo[1] < -1e-4:
            problems.append("the rest reaches below the cloth: %.5f" % lo[1])
        if hi[2] < 1.0:
            problems.append("the handle does not run back along +Z")
    return problems, points


def shaft_radius_at(points, z):
    """The cue's outer radius at distance z from the tip: the largest radius of the turned (non-inlay) parts at that
    station, interpolated between the rings either side, because the art's lathes have rings only at part ends."""
    best = 0.0
    for name, pts in points.items():
        rings = {}
        for x, y, pz in pts:
            rings.setdefault(round(pz, 5), []).append(math.hypot(x, y))
        stations = sorted(rings)
        for a, b in zip(stations, stations[1:]):
            if a <= z <= b and b - a > 1e-6:
                ra, rb = max(rings[a]), max(rings[b])
                best = max(best, ra + (rb - ra) * (z - a) / (b - a))
    return best


def seat_height(rest_points, radius):
    """How high the axis of a shaft of this radius rides when it lies in the cradle, metres above the cloth: the
    lowest centre height at which a circle of that radius, in the cradle's cross-section (|z| under 6 mm), touches no
    point of the rest. For each point within the circle's reach across, the centre must be at least
    y + sqrt(r^2 - x^2) high; the seat is the largest such value."""
    h = 0.0
    for pts in rest_points.values():
        for x, y, z in pts:
            if abs(z) < 0.006 and abs(x) < radius:
                h = max(h, y + math.sqrt(radius * radius - x * x))
    return h


def preview(out_dir, tag, finishes, views):
    """Throwaway renders of the scene just exported (only after the export is written, so none of this can ship),
    each part in its finish's colour, for a look by eye. The scene holds the app's raw coordinates (Y up, the long
    axis along Z), so a camera turned 90 degrees about Y looks along -X: the piece's side, Z across, Y up.
    `views` is a list of (name, centre z, centre y, width in metres)."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "OBJECT"
    scene.display.shading.show_specular_highlight = True
    for ob in scene.objects:
        if ob.type == "MESH" and ob.name in finishes:
            ob.color = finishes[ob.name]["rgb"] + (1.0,)
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.rotation_euler = (0.0, math.radians(90), 0.0)
    for name, z, y, width in views:
        cam_data.ortho_scale = width
        cam.location = (2.0, y, z)
        scene.render.resolution_x, scene.render.resolution_y = 1600, 400 if width > 0.5 else 1000
        scene.render.filepath = os.path.join(out_dir, "%s-%s.png" % (tag, name))
        bpy.ops.render.render(write_still=True)
        print("PREVIEW", scene.render.filepath)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = DEFAULT_OUT
    preview_dir = None
    if "--out-dir" in argv:
        out_dir = os.path.abspath(argv[argv.index("--out-dir") + 1])
    if "--preview" in argv:
        preview_dir = os.path.abspath(argv[argv.index("--preview") + 1])
        os.makedirs(preview_dir, exist_ok=True)
    failures, all_finishes, cue_points, rest_points = [], {}, {}, None
    for piece in PIECES:
        parts, finishes = collect(piece)
        all_finishes.update(finishes)
        build(parts)
        path = os.path.join(out_dir, piece["out"] + ".usdz")
        export(path)
        problems, points = verify(path, piece, list(parts))
        failures += ["%s: %s" % (piece["out"], p) for p in problems]
        if "length" in piece:
            cue_points[piece["out"]] = points
        else:
            rest_points = points
        if preview_dir:
            if "length" in piece:
                # The whole cue, then its butt end, where the finishes differ.
                views = [("side", piece["length"] / 2, 0.0, piece["length"] * 1.05),
                         ("butt", piece["length"] * 0.72, 0.0, piece["length"] * 0.5)]
            else:
                # The whole rest, then its head (the neck, the feet and the cradle).
                views = [("side", 0.64, 0.05, 1.36), ("head", 0.12, 0.05, 0.30)]
            preview(preview_dir, piece["out"], finishes, views)
    # The finish table CueRig.swift paints from (sRGB, roughness, metalness).
    for name, f in sorted(all_finishes.items()):
        print("FINISH %-18s rgb=(%.3f, %.3f, %.3f) rough=%.3f metal=%.3f" % (name, *f["rgb"], f["rough"], f["metal"]))
    # The numbers CueRig quotes: each cue's shaft radius at the bridge's distance and its seat in the rest's cradle.
    for name, pts in cue_points.items():
        r = shaft_radius_at(pts, BRIDGE_Z)
        seat = seat_height(rest_points, r) if rest_points else float("nan")
        print("MEASURE %-12s shaft radius at %.2f m: %.5f m, axis height in the cradle: %.5f m" % (name, BRIDGE_Z, r, seat))
    if failures:
        print("VERIFY FAILED:")
        for p in failures:
            print("  -", p)
        sys.exit(1)
    print("VERIFY OK")


main()
