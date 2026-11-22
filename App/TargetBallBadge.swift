// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The target-ball badge (look plan package 3). On a phone held upright the camera fits the whole table, so a
//          ball is a few millimetres across and its number and stripe cannot be read. While aiming, the ball the cue
//          ball will hit first gets a small floating glass badge above it: a little picture of the ball (its colour,
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
// SRP/DRY check: Pass - checked CaptionViews (CaptionLeader projects a caption's ball and places a glass chip; this
//          places a different chip for a different moment, reusing the same projection maths from AimGeometry rather
//          than copying it), AimOverlay (draws the guide; the badge sits in its layer with one line) and BallTextures
//          (the ball colours come from it, so the badge always matches the balls).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

struct TargetBallBadge: View {
    let model: ShowpieceModel
    let bridge: SceneBridge

    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
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
                    BallBadgeChip(look: set.look(of: target.ball), label: set.label(of: target.ball))
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

    /// The ball the aim will hit first and where it is on screen: its centre and its on-screen radius. The same answer
    /// the guide draws its ghost ball from (AimGeometry.guideContact: the launch direction, side-spin push included).
    private func target(in size: CGSize) -> (ball: Int, centre: CGPoint, radius: CGFloat)? {
        guard aimGuide, model.aimReady, model.layout.count == 16, NextShot.isOnTable(model.aimOrigin),
              let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return nil }
        let r = model.timeline.table.ballRadius
        guard let hit = AimGeometry.guideContact(for: model),
              let centre = proj.screen(hit.target) else { return nil }
        let side = proj.screen(hit.target + Vec2(r, 0)).map { hypot($0.x - centre.x, $0.y - centre.y) } ?? 8
        return (hit.ball, centre, max(4, side))
    }

    /// Above the ball, clear of the guide's ring round it (1.3 ball radii, see AimOverlay); flipped below when there
    /// is no room above; always fully on screen.
    private func place(_ t: (ball: Int, centre: CGPoint, radius: CGFloat), in size: CGSize) -> CGPoint {
        let w = badgeSize.width, h = badgeSize.height
        let ring = t.radius * 1.3
        var y = t.centre.y - ring - gap - h / 2
        if y - h / 2 < gap { y = t.centre.y + ring + gap + h / 2 }
        let x = min(max(t.centre.x, gap + w / 2), max(gap + w / 2, size.width - gap - w / 2))
        y = min(max(y, gap + h / 2), max(gap + h / 2, size.height - gap - h / 2))
        return CGPoint(x: x, y: y)
    }
}

/// The badge itself: a small drawn ball as its table draws it, and that table's word for it, on system glass.
private struct BallBadgeChip: View {
    let look: BallLook
    let label: String
    @ScaledMetric(relativeTo: .caption) private var ball: CGFloat = 22

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
                .font(Theme.label)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .padding(.vertical, 4)
        .glassEffect(.regular, in: .capsule)
    }
}
