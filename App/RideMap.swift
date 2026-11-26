// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, Stage 4: the table outline and its pockets are
//          drawn by TablePlan.draw, which hands back the table-to-map mapping, so the Lens's small plan (LensPlan.swift)
//          draws the very same table as this map. RideMap's own picture is unchanged.)
// PURPOSE: The Ride hand-over's title-row pieces (plans/22-Nov-2026-ride-handover-plan.md, work packages 4 and 5, 0.7.6
//          stream ride). RideMap is a small table map, the answer to "from what point of view": the table's outline
//          with its pockets, a dot for the ridden ball where it is at the clock, a narrow wedge for the way the camera
//          faces while it rides, and a ring on the pocket the first struck ball drops into. It is drawn the way the
//          overhead view shows the table (the long side up an upright phone, across a wide screen), so the map and
//          the table the shot began on agree. RideTitleChip puts the map beside the ride's status words (rideStatus:
//          "Riding with the cue ball", "Back to the table", "Now the same shot, slowed down", the once-only tip) in
//          one glass chip, sized for the title row of a regular iPhone (402 points wide) beside the back button.
//          Reads the model (rideAct, rideStatus, ridePlan, the clock, the recording) and RideLive (the camera's facing
//          and the view's shape, written by TableScene each frame). Used by ShowpieceView's ScreenHeader; the open
//          folding phone and the notebook put the same chip in their own title row (NotebookPanel, the coordinator's
//          line). Never takes touches; the words are read out as a status.
// SRP/DRY check: Pass - checked TrickPathThumb (the gallery's table drawing: its bed and rail colours and its
//          pocket dots are the look reused here; its colours are private to it, so the two values are repeated below
//          with a note) and ScreenHeader's status label (the same glass and font, reused by matching Theme.label).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// The ride's status words with the table map in front of them, as one glass chip for a title row. Shows only while a
/// ride has something to say.
struct RideTitleChip: View {
    let model: ShowpieceModel

    var body: some View {
        if let status = model.rideStatus {
            HStack(spacing: 8) {
                if model.rideShowsGuides { RideMap(model: model) }
                Text(status)
                    .font(Theme.label)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Status: \(status)"))
            .transition(.opacity)
        }
    }
}

/// 0.7.10 frontdoor: the small table plan both maps draw (RideMap here, LensPlan for the Lens), so they show one table.
/// It lays the table out the way the overhead view shows it and hands back how to put a table point on the map.
enum TablePlan {
    /// TrickPathThumb's bed and rail (private there): the cloth's green at a little over half its brightness, and the
    /// dark wood-brown edge.
    static let bed = Color(red: 0.03, green: 0.22, blue: 0.17)
    static let rail = Color(red: 0.10, green: 0.07, blue: 0.05)

    /// Where table points land on the map: `at` for a position, `direction` for a heading, `scale` in points per metre.
    struct Mapping {
        let at: (Vec2) -> CGPoint
        let direction: (Vec2) -> CGVector
        let scale: CGFloat
    }

    /// Draws the rail, the cloth and the edge pockets into a map of `size`, the table's long side along the map's long
    /// side, and returns the mapping (nil when the map is too small to hold the table). `portrait`: the overhead view
    /// shows the table upright (TableCamera: the camera looks from the head end, so the table's x runs down the map and
    /// its y to the right); otherwise x runs right and y up.
    static func draw(_ ctx: inout GraphicsContext, size: CGSize, portrait: Bool, table: TableSpec,
                     palette: Palette) -> Mapping? {
        let length = CGFloat(table.length), width = CGFloat(table.width)
        let inset: CGFloat = 3
        // Points per metre: the table's long side along the map's long side.
        let along = portrait ? size.height : size.width, across = portrait ? size.width : size.height
        let scale = min((along - 2 * inset) / length, (across - 2 * inset) / width)
        guard scale > 0 else { return nil }
        let ox = (size.width - (portrait ? width : length) * scale) / 2
        let oy = (size.height - (portrait ? length : width) * scale) / 2
        let at: (Vec2) -> CGPoint = { p in
            portrait ? CGPoint(x: ox + CGFloat(p.y) * scale, y: oy + CGFloat(p.x) * scale)
                     : CGPoint(x: ox + CGFloat(p.x) * scale, y: oy + (width - CGFloat(p.y)) * scale)
        }
        let direction: (Vec2) -> CGVector = { v in
            portrait ? CGVector(dx: v.y, dy: v.x) : CGVector(dx: v.x, dy: -v.y)
        }
        let cloth = CGRect(x: ox, y: oy, width: (portrait ? width : length) * scale,
                           height: (portrait ? length : width) * scale)
        ctx.fill(Path(roundedRect: cloth.insetBy(dx: -2, dy: -2), cornerRadius: 3), with: .color(rail))
        ctx.fill(Path(roundedRect: cloth, cornerRadius: 1.5), with: .color(bed))
        ctx.stroke(Path(roundedRect: cloth, cornerRadius: 1.5), with: .color(palette.paper.opacity(0.2)), lineWidth: 0.5)
        for k in 0..<TableSpec.edgePocketCount {
            guard let p = table.holeCenter(pocket: k) else { continue }
            let c = at(p)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 1.6, y: c.y - 1.6, width: 3.2, height: 3.2)), with: .color(.black))
        }
        return Mapping(at: at, direction: direction, scale: scale)
    }
}

/// The small table map (see the file header). Redraws every frame while it is shown: the ball moves with the clock and
/// the wedge with the camera.
struct RideMap: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    /// The map's long side, points: small enough for the title row of a regular iPhone held upright beside the back
    /// button and the words, big enough that the dot and the wedge read.
    static let longSide: CGFloat = 40

    var body: some View {
        TimelineView(.animation) { _ in
            let portrait = RideLive.shared.portrait
            let table = model.timeline.table
            let short = Self.longSide * CGFloat(table.width / max(0.01, table.length))
            Canvas { ctx, size in draw(&ctx, size: size, portrait: portrait) }
                .frame(width: (portrait ? short : Self.longSide) + 6, height: (portrait ? Self.longSide : short) + 6)
        }
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, portrait: Bool) {
        let tl = model.timeline
        let plan = model.ridePlan
        guard let map = TablePlan.draw(&ctx, size: size, portrait: portrait, table: tl.table, palette: palette) else { return }
        let at = map.at, direction = map.direction
        // The pocket the first struck ball drops into, ringed.
        if let hole = RideBeats.targetHole(plan: plan, timeline: tl) {
            let c = at(hole)
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 3.5, y: c.y - 3.5, width: 7, height: 7)),
                       with: .color(palette.pocket), lineWidth: 1.2)
        }
        let ball = at(tl.state(ball: plan.cueBall, at: model.time).position)
        // The wedge: which way the camera looks, from the ball, narrow (about thirty degrees) so it reads as a heading.
        if let facing = RideLive.shared.facing {
            let d = direction(facing)
            let heading = atan2(d.dy, d.dx), spread = CGFloat.pi / 12, reach: CGFloat = 11
            var wedge = Path()
            wedge.move(to: ball)
            wedge.addLine(to: CGPoint(x: ball.x + cos(heading - spread) * reach, y: ball.y + sin(heading - spread) * reach))
            wedge.addLine(to: CGPoint(x: ball.x + cos(heading + spread) * reach, y: ball.y + sin(heading + spread) * reach))
            wedge.closeSubpath()
            ctx.fill(wedge, with: .color(palette.accent.opacity(0.55)))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: ball.x - 2.4, y: ball.y - 2.4, width: 4.8, height: 4.8)),
                 with: .color(palette.paper))
        ctx.stroke(Path(ellipseIn: CGRect(x: ball.x - 2.4, y: ball.y - 2.4, width: 4.8, height: 4.8)),
                   with: .color(.black.opacity(0.6)), lineWidth: 0.6)
    }
}
