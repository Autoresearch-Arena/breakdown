// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The Lens keeps its bearings (0.7.10, plans/25-Nov-2026-front-door-and-table-view-plan.md Stage 4). When the
//          Lens camera is zoomed in so far that no rail and no pocket is left in view (the review's iPad showed one ball
//          on an empty grid across the whole table half at the first moment of the break), a small plan of the whole
//          table sits in the bottom-left corner of the table's area: the same table drawing as the Ride map
//          (TablePlan.draw in RideMap.swift), a box in the Lens's cyan marking the part of the cloth the camera is
//          looking at, and every ball still on the table as a dot (the cue ball white, the rest fainter), where it is at
//          the clock. It takes no touches, is not read aloud (the Lens's own words say what is happening), and fades
//          in and out as the camera goes past that point and back.
//          How it knows what the camera sees: the four corners of the free space the table is framed in
//          (CameraFraming.framing of the bridge's measured request, the 3D view's own coordinates) are turned into
//          table points through the camera as it is now (AimProjector.table(at:), the same projection the aiming and
//          the Lens callouts use). All four inside the cloth means no rail or pocket can be in view. Which way the
//          table lies on the plan follows the camera's own rule (CameraFraming.tableYaw(for:)).
//          Mounted by ShowpieceView over the stage, beside the Lens callouts; shown only while the Lens is on, the menu
//          is closed and the Ride map is not up (Ride has its own map).
//          Reads the model (lensOn, menuOpen, rideShowsGuides, timeline, time) and the SceneBridge (the table scene's
//          camera, the 3D view's size and origin, the measured chrome). Writes nothing.
// SRP/DRY check: Pass - checked RideMap (its table drawing is now TablePlan, shared here rather than copied),
//          LensCallouts (the same AimProjector and StageSpace pattern) and MomentFrame/TableZoom (they move the camera;
//          this only reads where it ended up).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct LensPlanLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.phoneUpright) private var upright
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.palette) private var palette
    @State private var cameraBox = AimProjector.CameraBox()

    /// The plan's long side in points: room for the box and the dots on a big screen, smaller on an upright phone.
    private var longSide: CGFloat { upright ? 64 : 96 }

    /// Whether the plan may be up at all; the per-frame test (zoomed past every rail) decides whether it shows.
    private var eligible: Bool { model.lensOn && !model.menuOpen && !model.rideShowsGuides }

    var body: some View {
        ZStack {
            if eligible {
                TimelineView(.animation) { _ in
                    GeometryReader { geo in
                        let origin = geo.frame(in: .named(StageSpace.name)).origin
                        if let view = cameraView() {
                            plan(view, layerOrigin: origin)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // Positions below are worked out in the 3D view's own left-to-right coordinates.
        .environment(\.layoutDirection, .leftToRight)
    }

    /// What the camera is looking at this frame.
    private struct CameraView {
        /// The free space's corners on the cloth, in table coordinates (x along the length, y across), in order round.
        let corners: [Vec2]
        /// The free space in the 3D view's own coordinates (points, origin top left).
        let free: FramingRect
        /// The table lies upright on screen (and so on the plan).
        let portrait: Bool
        /// No rail or pocket is in view: every corner of the free space lands on the cloth.
        let zoomedPastRails: Bool
    }

    /// Projects the free space's corners onto the cloth through the camera as placed this frame; nil before the scene
    /// exists, or when a corner looks above the horizon (only the low Ride views do that, and they hide this plan).
    private func cameraView() -> CameraView? {
        let table = model.timeline.table
        guard let root = bridge.table?.root,
              let projector = AimProjector(camera: cameraBox.find(in: root), size: bridge.viewSize,
                                           frame: TableFrame(table)) else { return nil }
        let request = bridge.request()
        let free = CameraFraming.framing(request).inner
        let screen = [CGPoint(x: free.left, y: free.top), CGPoint(x: free.right, y: free.top),
                      CGPoint(x: free.right, y: free.bottom), CGPoint(x: free.left, y: free.bottom)]
        let corners = screen.compactMap { projector.table(at: $0) }
        guard corners.count == 4 else { return nil }
        let inside = corners.allSatisfy { $0.x > 0 && $0.x < table.length && $0.y > 0 && $0.y < table.width }
        let portrait = CameraFraming.tableYaw(for: request) != 0
        return CameraView(corners: corners, free: free, portrait: portrait, zoomedPastRails: inside)
    }

    /// The plan, placed in the bottom-left corner of the free space, faded in while the camera is past the rails.
    private func plan(_ view: CameraView, layerOrigin: CGPoint) -> some View {
        let table = model.timeline.table
        let short = longSide * CGFloat(table.width / max(0.01, table.length))
        let size = CGSize(width: (view.portrait ? short : longSide) + 6, height: (view.portrait ? longSide : short) + 6)
        // The free space's corner, from the 3D view's coordinates to this layer's (both measured in StageSpace).
        let dx = bridge.viewOrigin.x - layerOrigin.x, dy = bridge.viewOrigin.y - layerOrigin.y
        let margin: CGFloat = 10
        let centre = CGPoint(x: CGFloat(view.free.left) + dx + margin + size.width / 2,
                             y: CGFloat(view.free.bottom) + dy - margin - size.height / 2)
        return Canvas { ctx, canvasSize in draw(&ctx, size: canvasSize, view: view) }
            .frame(width: size.width, height: size.height)
            .background(palette.ground.opacity(0.55), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .position(centre)
            .opacity(view.zoomedPastRails ? 1 : 0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: view.zoomedPastRails)
    }

    /// The table, the box of what the camera sees and the balls where they are at the clock.
    private func draw(_ ctx: inout GraphicsContext, size: CGSize, view: CameraView) {
        let tl = model.timeline
        guard let map = TablePlan.draw(&ctx, size: size, portrait: view.portrait, table: tl.table,
                                       palette: palette) else { return }
        // Bar billiards' holes in the bed, so its plan is its own table.
        for hole in tl.table.bedHoles {
            let c = map.at(hole.center)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 1.4, y: c.y - 1.4, width: 2.8, height: 2.8)), with: .color(.black))
        }
        // The box: the cloth the camera is looking at, in the Lens's rolling cyan.
        var box = Path()
        box.addLines(view.corners.map(map.at))
        box.closeSubpath()
        ctx.fill(box, with: .color(palette.accent.opacity(0.18)))
        ctx.stroke(box, with: .color(palette.accent), lineWidth: 1.2)
        // The balls still on the table, the cue ball last so it sits on top.
        for b in (0..<tl.ballCount).reversed() {
            let state = tl.state(ball: b, at: model.time)
            let p = state.position
            guard !state.pocketed, p.x >= 0, p.x <= tl.table.length, p.y >= 0, p.y <= tl.table.width else { continue }
            let c = map.at(p)
            let r: CGFloat = b == 0 ? 2.2 : 1.6
            let dot = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
            ctx.fill(dot, with: .color(b == 0 ? palette.paper : palette.paper.opacity(0.55)))
        }
    }
}
