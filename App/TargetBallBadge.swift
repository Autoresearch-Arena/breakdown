// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The target-ball badge (look plan package 3). On a phone held upright the camera fits the whole table, so a
//          ball is a few millimetres across and its number and stripe cannot be read. While aiming, the ball the cue
//          ball will hit first gets a small floating badge above it (on glass everywhere but the upright phone, where
//          it is smaller, on thin material, and kept clear of the rack and the target's neighbours): a little picture of the ball (its colour,
//          a band for a stripe) with its number, and the words "Solid", "Stripe" or "Eight ball". The badge is anchored
//          to the ball the way CaptionLeader anchors its chip to a caption's ball: the ball is projected to the screen
//          every frame with the live camera (AimProjector) and the badge is placed beside it, kept fully on screen.
//          Which ball: AimGeometry.firstContact, the same answer the aim guide draws its ghost ball from. With the Aim
//          guide option off the badge is not shown either, because naming the ball would tell the player what the
//          guide is switched off to hide.
//          Shown inside AimOverlay (so only while "Your shot" is open); decoration only: no touches, and hidden from
//          VoiceOver, which reads the aim through the overlay's own adjustable element.
//          Strings: the ball words are TableBallSet.label's (localization/pending/look.json and v07-base.json).
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 21 and 50: the badge draws the ball as the table it is
//          on draws it (TableBallSet: a numbered pool ball, a plain white, red or yellow ball, or bumper pool's marked
//          ball with its spot) and names it in that table's words ("Stripe", "White", "Marked red"; TableBallSet.label),
//          instead of calling every ball on every table Solid or Stripe; and the ball is the one the guide itself shows
//          the cue ball hitting first, side-spin push included (AimGeometry.guideContact), so the badge, the guide and
//          the spoken aim always agree.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan Part 3: on the upright phone the badge is small, on
//          thin material rather than glass, and placed clear of the rack and the target's neighbours; every other
//          layout keeps the glass chip placed just above the target ball.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md Part
//          A6: a numbered pool ball's badge names it by number in words ("3 ball, solid", TableWords.ballLabel), not by
//          its colour and a tiny printed number alone.)
// SRP/DRY check: Pass - checked CaptionViews (CaptionLeader projects a caption's ball and places a glass chip; this
//          places a different chip for a different moment, reusing the same projection maths from AimGeometry rather
//          than copying it), AimOverlay (draws the guide; the badge sits in its layer with one line) and BallTextures
//          (the ball colours come from it, so the badge always matches the balls).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

struct TargetBallBadge: View {
    /// The target ball on screen; `clear` is the upright phone's keep-clear rectangle (nil on every other layout).
    typealias Target = (ball: Int, centre: CGPoint, radius: CGFloat, clear: CGRect?)

    let model: ShowpieceModel
    let bridge: SceneBridge

    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    /// Set by ShowpieceView on the stage that holds AimOverlay; only the upright phone changes look and placement.
    @Environment(\.phoneUpright) private var upright
    @State private var cameraBox = AimProjector.CameraBox()
    /// The badge's measured size, for keeping it on screen.
    @State private var badgeSize = CGSize(width: 90, height: 30)

    /// Gap between the ball's top edge and the badge, and the least distance the badge keeps from the screen's edges.
    private let gap: CGFloat = 10

    var body: some View {
        TimelineView(.animation) { _ in
            GeometryReader { geo in
                if let target = target(in: geo.size) {
                    // The table drawn on screen (the one the shot was solved on) says how the ball looks and is named.
                    let set = TableBallSet.for(table: model.solvedTable)
                    // 0.7.10 everyone: a numbered pool ball is named by its number in words too ("3 ball, solid"), so
                    // the badge never leans on the ball's colour or its tiny printed number alone.
                    let look = set.look(of: target.ball)
                    BallBadgeChip(look: look, label: Self.label(look, ball: target.ball, set: set), upright: upright)
                        .onGeometryChange(for: CGSize.self) { $0.size } action: { badgeSize = $0 }
                        .position(place(target, in: geo.size))
                        .id(target.ball)
                        .transition(.opacity)
                }
            }
        }
        // Placed in screen points from the 3D projection, which does not mirror for right-to-left languages.
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 0.7.10 everyone: the badge's words. A numbered pool ball says its number with its group, as VoiceOver names it
    /// (TableWords.ballLabel: "3 ball, solid", "8 ball"); the small tables' balls keep their set's own word.
    private static func label(_ look: BallLook, ball: Int, set: TableBallSet) -> String {
        if case .pool(let number) = look, number > 0 { return TableWords.ballLabel(number, pool: true) }
        return set.label(of: ball)
    }

    /// The ball the aim will hit first and where it is on screen: its centre and its on-screen radius. The same answer
    /// the guide draws its ghost ball from (AimGeometry.guideContact: the launch direction, side-spin push included).
    /// On the upright phone also the keep-clear rectangle (nil elsewhere): see keepClear.
    private func target(in size: CGSize) -> Target? {
        guard aimGuide, model.aimReady, model.layout.count == 16, NextShot.isOnTable(model.aimOrigin),
              let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return nil }
        let r = model.timeline.table.ballRadius
        guard let hit = AimGeometry.guideContact(for: model),
              let centre = proj.screen(hit.target) else { return nil }
        let side = proj.screen(hit.target + Vec2(r, 0)).map { hypot($0.x - centre.x, $0.y - centre.y) } ?? 8
        let clear = upright ? keepClear(around: hit.target, ballRadius: r, projector: proj) : nil
        return (hit.ball, centre, max(4, side), clear)
    }

    /// The upright phone's keep-clear rectangle, in the same screen points as place(): the union of the guide-ring-sized
    /// circles (1.3 on-screen radii) of every ball on the cloth within six ball diameters of the target, the target
    /// included. On a break that is the whole rack; later it is the target's neighbours. The plan (Part 3) asks for the
    /// label to stay clear of the rack: a label sitting on the balls it names hides them, and on the upright phone the
    /// balls are only a few points across, so even a small label covers several.
    private func keepClear(around target: Vec2, ballRadius r: Double, projector proj: AimProjector) -> CGRect? {
        let reach = 6 * 2 * r
        var rect: CGRect?
        for p in model.layout where NextShot.isOnTable(p) && (p - target).length <= reach {
            guard let c = proj.screen(p) else { continue }
            // The on-screen radius by the same side-point method target() uses (perspective shrinks far balls).
            let side = proj.screen(p + Vec2(r, 0)).map { hypot($0.x - c.x, $0.y - c.y) } ?? 8
            let ring = max(4, side) * 1.3
            let circle = CGRect(x: c.x - ring, y: c.y - ring, width: ring * 2, height: ring * 2)
            rect = rect.map { $0.union(circle) } ?? circle
        }
        return rect
    }

    /// Above the ball, clear of the guide's ring round it (1.3 ball radii, see AimOverlay); flipped below when there
    /// is no room above; always fully on screen. On the upright phone, above (or below) the whole keep-clear rectangle
    /// instead, still centred on the target's x, so the label never sits on the rack or the target's neighbours.
    private func place(_ t: Target, in size: CGSize) -> CGPoint {
        let w = badgeSize.width, h = badgeSize.height
        let top: CGFloat, bottom: CGFloat
        if let clear = t.clear {
            top = clear.minY
            bottom = clear.maxY
        } else {
            let ring = t.radius * 1.3
            top = t.centre.y - ring
            bottom = t.centre.y + ring
        }
        var y = top - gap - h / 2
        if y - h / 2 < gap { y = bottom + gap + h / 2 }
        let x = min(max(t.centre.x, gap + w / 2), max(gap + w / 2, size.width - gap - w / 2))
        y = min(max(y, gap + h / 2), max(gap + h / 2, size.height - gap - h / 2))
        return CGPoint(x: x, y: y)
    }
}

/// The badge itself: a small drawn ball as its table draws it, and that table's word for it, on system glass; on the
/// upright phone smaller and on thin material, because the plan keeps glass for the controls only (it is content).
private struct BallBadgeChip: View {
    let look: BallLook
    let label: String
    let upright: Bool
    @ScaledMetric(relativeTo: .caption) private var fullBall: CGFloat = 22
    @ScaledMetric(relativeTo: .caption) private var smallBall: CGFloat = 16
    private var ball: CGFloat { upright ? smallBall : fullBall }

    private static func color(_ c: (Double, Double, Double)) -> Color { Color(red: c.0, green: c.1, blue: c.2) }

    var body: some View {
        let colour = Self.color(BallTextures.swatch(look))
        let ivory = Self.color(BallTextures.colour(.white))
        HStack(spacing: 6) {
            ZStack {
                switch look {
                case .pool(let number):
                    // A stripe: ivory with a coloured band across the middle; a solid: all colour; then the number disc.
                    Circle().fill(number > 8 ? ivory : colour)
                    if number > 8 { Rectangle().fill(colour).frame(height: ball * 0.56) }
                    if number > 0 {
                        Circle().fill(ivory).frame(width: ball * 0.62, height: ball * 0.62)
                        Text(verbatim: "\(number)")
                            .font(.system(size: ball * 0.40, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.black)
                            .minimumScaleFactor(0.6)
                    }
                case .plain:
                    Circle().fill(colour)
                case .spotted(_, let spot):
                    // The marked ball: its side's colour with the other side's spot, as the 3D ball wears it.
                    Circle().fill(colour)
                    Circle().fill(Self.color(BallTextures.colour(spot))).frame(width: ball * 0.42, height: ball * 0.42)
                }
            }
            .frame(width: ball, height: ball)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.75))
            Text(label)
                // The upright phone uses the plan's floor size (caption2) so the label stays small over the table.
                .font(upright ? Theme.blurbChipLabel : Theme.label)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.leading, upright ? 4 : 5)
        .padding(.trailing, upright ? 8 : 10)
        .padding(.vertical, upright ? 3 : 4)
        .modifier(BadgeBackground(upright: upright))
    }
}

/// Glass for the chip everywhere but the upright phone, where it is content and sits on thin material (plan Part 3:
/// glass only for the title-row circles, the control strip and the aiming panel).
private struct BadgeBackground: ViewModifier {
    let upright: Bool
    func body(content: Content) -> some View {
        if upright {
            content.background(.thinMaterial, in: .capsule)
        } else {
            content.glassEffect(.regular, in: .capsule)
        }
    }
}
