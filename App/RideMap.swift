// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, Stage 4: the table outline and its pockets are
//          drawn by TablePlan.draw, which hands back the table-to-map mapping, so the Lens's small plan (LensPlan.swift)
//          draws the very same table as this map. RideMap's own picture is unchanged.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 12, Ride: the title-row chip is one slim glass
//          capsule holding the map, the ride's words and ONE figure, the ridden ball's speed now in m/s through
//          NumberStyle (RideSpeedFigure; shown while the ride is riding, not while it rises or rewinds). The map is a
//          little larger, shows only while a ride shows its guides, and carries a word on it: "You" beside the ridden
//          ball's dot, so "the dot is you, the wedge is where you look" reads without a legend. The wedge is paper, not
//          cyan (cyan on this game means rolling or "act here"). On the phone's docked map the speed sits under the map
//          as a slim caption, since there the ride's words are the title. Design lint cleared: the chip is the glass
//          capsule, the pocket holes and the ball's edge are the ground colour, the plan's cloth and rail are plain
//          rectangles (no bare corner), and the two drawn table colours keep their values with the lint's allow note.)
// PURPOSE: The Ride hand-over's title-row pieces (plans/22-Nov-2026-ride-handover-plan.md, work packages 4 and 5, 0.7.6
//          stream ride; restyled by plans/26-Nov-2026-ui-rethink-plan.md package 12). RideMap is a small table map, the
//          answer to "from what point of view": the table's outline with its pockets, a dot for the ridden ball where
//          it is at the clock with the word "You" beside it, a narrow wedge for the way the camera faces while it rides,
//          and a ring on the pocket the first struck ball drops into. It is drawn the way the overhead view shows the
//          table (the long side up an upright phone, across a wide screen), so the map and the table the shot began on
//          agree. RideTitleChip puts the map, the ride's status words (rideStatus: "Riding with the cue ball", "Back to
//          the table", "Now the same shot, slowed down", the once-only tip) and the ridden ball's speed in one slim
//          glass capsule for a title row (big screens, the open folding phone's panel and the notebook's title row).
//          The upright phone docks RideMap alone in a blurb (ShowpieceView) with the speed as a slim caption under it,
//          because its title row already carries the ride's words (PhoneTitle).
//          Reads the model (rideAct, rideStatus, ridePlan, the clock, the recording) and RideLive (the camera's facing
//          and the view's shape, written by TableScene each frame). Never takes touches; the words and the figure are
//          read out as one status.
// SRP/DRY check: Pass - checked TrickPathThumb (the gallery's table drawing: its bed and rail colours are the look
//          reused here; its colours are private to it, so the two values are repeated below with a note), the kit's
//          kitGlassCapsule (a one-line pill that sets its own font; the chip holds a map and a figure as well, so it
//          uses the same capsule shape and material through glassEffect instead) and KitFigure (the one figure face,
//          reused for the speed).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// The ride's status words with the table map in front of them and the ridden ball's speed after them, as one slim
/// glass capsule for a title row. Shows only while a ride has something to say.
struct RideTitleChip: View {
    let model: ShowpieceModel

    var body: some View {
        if let status = model.rideStatus {
            HStack(spacing: Theme.Space.xs) {
                if model.rideShowsGuides { RideMap(model: model, longSide: RideMap.chipLongSide, showsSpeed: false) }
                Text(status)
                    .font(Theme.label)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                // The one figure: the ridden ball's speed, only while the ride is riding (not while it rises or rewinds).
                if model.rideShowsSpeed { RideSpeedFigure(model: model) }
            }
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, Theme.Space.xxs)
            .glassEffect(.regular, in: .capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Status: \(status)"))
            .transition(.opacity)
        }
    }
}

/// The ridden ball's speed at the clock, in the inline figure face (NumberStyle's speed rule). Redraws every frame
/// while shown, so it counts down as the ball slows; tabular digits, so it never jitters sideways.
struct RideSpeedFigure: View {
    let model: ShowpieceModel

    var body: some View {
        TimelineView(.animation) { _ in
            KitFigure(RideSpeedFigure.reading(model), size: .inline)
                .fixedSize()
        }
        .accessibilityHidden(true)
    }

    /// The ridden ball's speed now (zero once it has dropped), as NumberStyle writes it.
    @MainActor
    static func reading(_ model: ShowpieceModel) -> NumberStyle.Reading {
        let state = model.timeline.state(ball: model.ridePlan.cueBall, at: model.time)
        return NumberStyle.speed(metresPerSecond: state.pocketed ? 0 : state.velocity.length)
    }
}

extension ShowpieceModel {
    /// True while the ride's one figure is shown: from the mount to the last held beat, while the camera is down with
    /// the ball (not while it rises back, rewinds or has landed).
    var rideShowsSpeed: Bool {
        switch rideAct {
        case .mount, .roll, .hold: return true
        case .none, .dismount, .landed, .rewind: return false
        }
    }
}

/// 0.7.10 frontdoor: the small table plan both maps draw (RideMap here, LensPlan for the Lens), so they show one table.
/// It lays the table out the way the overhead view shows it and hands back how to put a table point on the map.
enum TablePlan {
    /// TrickPathThumb's bed and rail (private there): the cloth's green at a little over half its brightness, and the
    /// dark wood-brown edge. A picture of the table's own cloth and wood, not an interface colour, so no Palette role.
    static let bed = Color(red: 0.03, green: 0.22, blue: 0.17)  // design-lint: allow the drawn table's cloth, as in TrickPathThumb
    static let rail = Color(red: 0.10, green: 0.07, blue: 0.05)  // design-lint: allow the drawn table's wood, as in TrickPathThumb

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
        // Square corners: at this size a rounded rail reads the same, and a plain rectangle needs no corner value.
        ctx.fill(Path(cloth.insetBy(dx: -2, dy: -2)), with: .color(rail))
        ctx.fill(Path(cloth), with: .color(bed))
        ctx.stroke(Path(cloth), with: .color(palette.paper.opacity(0.2)), lineWidth: 0.5)
        for k in 0..<TableSpec.edgePocketCount {
            guard let p = table.holeCenter(pocket: k) else { continue }
            let c = at(p)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 1.6, y: c.y - 1.6, width: 3.2, height: 3.2)),
                     with: .color(palette.ground))
        }
        return Mapping(at: at, direction: direction, scale: scale)
    }
}

/// The small table map (see the file header), with "You" on it beside the ridden ball. Redraws every frame while it is
/// shown: the ball moves with the clock and the wedge with the camera. Shown only while a ride shows its guides (the
/// callers check model.rideShowsGuides; drawn outside a ride it shows nothing).
struct RideMap: View {
    let model: ShowpieceModel
    /// The map's long side, points.
    var longSide: CGFloat = RideMap.dockLongSide
    /// The slim speed caption under the map (the phone's dock, where the title row holds the words). The title-row
    /// chip turns it off and shows the speed after its words instead.
    var showsSpeed = true
    @Environment(\.palette) private var palette

    /// Long side for the phone's docked map: large enough for the dot, the wedge and the word "You" to read at a
    /// glance (the phone never skimps on the pictures), small enough to stay a corner blurb.
    static let dockLongSide: CGFloat = 64
    /// Long side inside the title-row chip: a title row is 44 points tall, so a sideways map fits in it whole.
    static let chipLongSide: CGFloat = 52

    var body: some View {
        if model.rideShowsGuides {
            VStack(spacing: Theme.Space.xxs) {
                TimelineView(.animation) { _ in
                    let portrait = RideLive.shared.portrait
                    let table = model.timeline.table
                    let short = longSide * CGFloat(table.width / max(0.01, table.length))
                    Canvas { ctx, size in draw(&ctx, size: size, portrait: portrait) }
                        .frame(width: (portrait ? short : longSide) + 6, height: (portrait ? longSide : short) + 6)
                }
                if showsSpeed, model.rideShowsSpeed { RideSpeedFigure(model: model) }
            }
            .accessibilityHidden(true)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, portrait: Bool) {
        let tl = model.timeline
        let plan = model.ridePlan
        guard let map = TablePlan.draw(&ctx, size: size, portrait: portrait, table: tl.table, palette: palette) else { return }
        let at = map.at, direction = map.direction
        // The pocket the first struck ball drops into, ringed in the pocket gold (its meaning on the cloth too).
        if let hole = RideBeats.targetHole(plan: plan, timeline: tl) {
            let c = at(hole)
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 3.5, y: c.y - 3.5, width: 7, height: 7)),
                       with: .color(palette.pocket), lineWidth: 1.2)
        }
        let ball = at(tl.state(ball: plan.cueBall, at: model.time).position)
        // The wedge: which way the camera looks, from the ball, narrow (about thirty degrees) so it reads as a heading.
        // Paper, not cyan: it is where you look, not a rolling ball.
        var heading: CGFloat?
        if let facing = RideLive.shared.facing {
            let d = direction(facing)
            let h = atan2(d.dy, d.dx), spread = CGFloat.pi / 12, reach = longSide * 0.3
            heading = h
            var wedge = Path()
            wedge.move(to: ball)
            wedge.addLine(to: CGPoint(x: ball.x + cos(h - spread) * reach, y: ball.y + sin(h - spread) * reach))
            wedge.addLine(to: CGPoint(x: ball.x + cos(h + spread) * reach, y: ball.y + sin(h + spread) * reach))
            wedge.closeSubpath()
            ctx.fill(wedge, with: .color(palette.paper.opacity(0.6)))
        }
        let dot = CGRect(x: ball.x - 2.8, y: ball.y - 2.8, width: 5.6, height: 5.6)
        ctx.fill(Path(ellipseIn: dot), with: .color(palette.paper))
        ctx.stroke(Path(ellipseIn: dot), with: .color(palette.ground.opacity(0.7)), lineWidth: 0.6)
        drawYou(&ctx, size: size, ball: ball, heading: heading)
    }

    /// The word on the map: "You" beside the ridden ball's dot, on the side away from the wedge (behind the ball, where
    /// the camera is), kept inside the map. A ground-coloured shadow keeps it legible over the cloth and the rail.
    private func drawYou(_ ctx: inout GraphicsContext, size: CGSize, ball: CGPoint, heading: CGFloat?) {
        let text = ctx.resolve(Text(RideWords.you).font(Theme.caption.weight(.semibold)).foregroundStyle(palette.paper))
        let measured = text.measure(in: size)
        // Behind the ball (the camera's side) when the wedge shows; otherwise just above it.
        let away = heading.map { $0 + .pi } ?? -.pi / 2
        let gap = 5 + max(measured.width, measured.height) / 2
        var centre = CGPoint(x: ball.x + cos(away) * gap, y: ball.y + sin(away) * gap)
        centre.x = min(max(centre.x, measured.width / 2 + 1), size.width - measured.width / 2 - 1)
        centre.y = min(max(centre.y, measured.height / 2), size.height - measured.height / 2)
        var label = ctx
        label.addFilter(.shadow(color: palette.ground.opacity(0.9), radius: 1.5))
        label.draw(text, at: centre, anchor: .center)
    }
}
