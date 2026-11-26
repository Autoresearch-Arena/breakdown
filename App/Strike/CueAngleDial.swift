// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The cue angle as a quarter-circle dial with the cue as its needle (plans/25-Nov-2026-strike-panel-and-
//          controls-plan.md, stage 3 item 3), for the shot panel on iPad, Mac and the open folding phone, where it takes
//          the place of the cue-angle menu (CueAngleMenu stays on the upright phone and in small layouts). The ball sits
//          in the lower corner, the arc runs from level (along the cloth) to 80 degrees; drag the needle and read the
//          degrees. It reads and writes the same value the menu does, the sine in model.activeElevation, through the
//          model's setter (a lesson's lock, the computer's turn and a mode that sets its own angle all refuse there).
//          The drag lands on whole degrees and settles on an offered angle (CueAngleMenu.angles) within a degree and a
//          half of it, so every authored angle (lessons, trick shots) is easy to set exactly.
//          Kept from the menu: a lesson's marked angles (LessonZones.cueAngles) drawn as a band on the arc, and its
//          lock (lockedForStep). Where a trick shot or a Behind the 8-Ball situation sets its own angle
//          (model.cueAngleLockedByMode) the dial still shows that angle, dimmed with a lock, and says why. For VoiceOver
//          it is one adjustable element stepping through the offered angles, with the menu's spoken value.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md:
//          at the accessibility text sizes the angle's words wrap instead of shrinking to fit.)
// SRP/DRY check: Pass - checked CueAngleMenu (the angles, the sine conversion, the words and the spoken value are all
//          reused from it; nothing is listed twice) and FineControls' cue-angle slider (the same setter).
import SwiftUI

struct CueAngleDial: View {
    let model: ShowpieceModel
    /// The lesson's marked angles, if any, and how strongly they are marked.
    var zone: ClosedRange<Int>? = nil
    var zoneStrength: Double = 1
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 96
    // 0.7.10 everyone: at the accessibility sizes the angle's words wrap instead of shrinking to fit.
    @Environment(\.dynamicTypeSize) private var typeSize

    /// The steepest angle on the dial: the last one the menu offers.
    private static let top = Double(CueAngleMenu.angles.last ?? 80)
    /// How close (degrees) a drag must come to an offered angle to settle on it.
    private static let settle = 1.5

    /// A lesson step that holds the angle.
    private var lessonLocked: Bool { !model.openControls.contains(.elevation) }
    /// Anything that stops the player changing it here.
    private var locked: Bool { lessonLocked || model.cueAngleLockedByMode || !model.personControlsLive }

    /// The player's angle, degrees.
    private var degrees: Double { asin(min(max(model.activeElevation, 0), 0.995)) * 180 / .pi }

    var body: some View {
        let size = min(max(side, 88), 140)
        VStack(spacing: 4) {
            dial(size: size)
            Text(verbatim: CueAngleMenu.words(degrees: degrees))
                .font(Theme.number)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.7)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Cue angle"))
        .accessibilityValue(TableWords.cueAngleValue(words: CueAngleMenu.words(degrees: degrees),
                                                     degrees: CueAngleMenu.nearestAngle(toSine: model.activeElevation),
                                                     band: zone))
        .accessibilityHint(model.cueAngleLockedByMode ? StrikeWords.lockedByMode
                           : String(localized: "Raise the cue to jump or curve the cue ball"))
        .accessibilityAdjustableAction { direction in
            guard !locked else { return }
            let angles = CueAngleMenu.angles
            let now = CueAngleMenu.nearestAngle(toSine: model.activeElevation)
            guard let i = angles.firstIndex(of: now) else { return }
            switch direction {
            case .increment: if i + 1 < angles.count { model.activeElevation = CueAngleMenu.sine(forAngle: angles[i + 1]) }
            case .decrement: if i > 0 { model.activeElevation = CueAngleMenu.sine(forAngle: angles[i - 1]) }
            @unknown default: break
            }
        }
        .modifier(DialLock(lesson: lessonLocked, mode: model.cueAngleLockedByMode))
        .help(model.cueAngleLockedByMode ? StrikeWords.lockedByMode : String(localized: "Cue angle"))
    }

    /// The quarter circle: the ball at the lower leading corner, the arc, the lesson's band, the ticks at the offered
    /// angles and the cue as the needle. Drawn in screen terms (left to right) whatever the reading direction: the cue
    /// is a picture of a cue, not text.
    private func dial(size: CGFloat) -> some View {
        let ball = size * 0.14
        let pivot = CGPoint(x: ball, y: size - ball)
        let radius = size - ball * 1.6
        return Canvas { ctx, _ in
            func point(_ deg: Double, _ r: CGFloat) -> CGPoint {
                let a = deg * .pi / 180
                return CGPoint(x: pivot.x + r * CGFloat(cos(a)), y: pivot.y - r * CGFloat(sin(a)))
            }
            // An arc of the dial between two angles, as a fine polyline (a degree a step), so it bends the same way
            // whatever a framework means by "clockwise" on a flipped canvas.
            func arc(from a: Double, to b: Double) -> Path {
                var path = Path()
                let lo = min(a, b), hi = max(a, b)
                path.move(to: point(lo, radius))
                var d = lo
                while d < hi { d = min(hi, d + 1); path.addLine(to: point(d, radius)) }
                return path
            }
            // The arc from level to the top.
            ctx.stroke(arc(from: 0, to: Self.top), with: .color(palette.track),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round))
            // A lesson's marked angles, a brighter stretch of the arc.
            if let zone {
                ctx.stroke(arc(from: Double(zone.lowerBound), to: Double(zone.upperBound)),
                           with: .color(palette.accent.opacity(0.8 * zoneStrength)),
                           style: StrokeStyle(lineWidth: 10, lineCap: .round))
            }
            // A tick at every offered angle.
            for a in CueAngleMenu.angles {
                var tick = Path()
                tick.move(to: point(Double(a), radius - 7)); tick.addLine(to: point(Double(a), radius + 5))
                ctx.stroke(tick, with: .color(.secondary), lineWidth: 1)
            }
            // The cue: from just off the ball out past the arc, tip at the ball.
            var cue = Path()
            cue.move(to: point(degrees, ball * 1.2)); cue.addLine(to: point(degrees, radius + 6))
            ctx.stroke(cue, with: .color(palette.paper), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(origin: point(degrees, radius + 6), size: .zero).insetBy(dx: -6, dy: -6)),
                     with: .color(palette.accent))
            // The ball.
            ctx.fill(Path(ellipseIn: CGRect(x: pivot.x - ball, y: pivot.y - ball, width: ball * 2, height: ball * 2)),
                     with: .color(.white))
        }
        .frame(width: size, height: size)
        .environment(\.layoutDirection, .leftToRight)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            guard !locked else { return }
            let dx = Double(value.location.x - pivot.x), dy = Double(pivot.y - value.location.y)
            // Behind the ball or below the cloth reads as level; past the top, the top.
            var a = atan2(max(dy, 0), max(dx, 0.0001)) * 180 / .pi
            a = min(max(a, 0), Self.top)
            var whole = a.rounded()
            if let near = CueAngleMenu.angles.min(by: { abs(Double($0) - a) < abs(Double($1) - a) }),
               abs(Double(near) - a) <= Self.settle {
                whole = Double(near)
            }
            let sine = CueAngleMenu.sine(forAngle: Int(whole))
            if model.activeElevation != sine { model.activeElevation = sine }
        })
    }
}

/// The dial's lock: a lesson step's own mark and words (lockedForStep), or, where the mode sets the angle, the same
/// dimming and lock with no "Locked for this step" (the hint says why instead).
private struct DialLock: ViewModifier {
    let lesson: Bool
    let mode: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if lesson {
            content.lockedForStep(true)
        } else if mode {
            content.opacity(0.55)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
                }
        } else {
            content
        }
    }
}
