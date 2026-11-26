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
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 6: a larger arc at the size the layout hands it (about a 100-point radius on the upright iPad) running
//          from level to upright, ticks with figures at 0, 20, 45 and 90 degrees, the cue as a cyan needle ending in the
//          instrument kit's handle, a flat grey pivot ball, the degrees as a typeable figure beside the dial (under it
//          in a narrow column) with "up from level", and a faint ghost needle at the planned angle after a shot. The
//          small "5° up" caption is gone (the figure is printed once). The drag still stops at the top angle offered.
//          The dial and the figure are two VoiceOver elements: the adjustable dial, and the figure's typing button.)
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

    /// Aiming panel redesign: the dial's side, points, from the layout (about twice the 100-point arc radius on the
    /// upright iPad), and the degrees figure's size. Nil keeps the old 88 to 140 points.
    var size: CGFloat? = nil
    var figureSize: CGFloat = 26
    /// The degrees figure under the dial instead of beside it (a narrow column).
    var figureBelow = false

    var body: some View {
        let reading = StrikeReading.current(model)
        let planned = reading?.comparison?.planned.cueAngle
        let layout = figureBelow ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                                 : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        layout {
            accessible(dial(size: size ?? min(max(side, 88), 140), ghost: planned))
            readout(reading).fixedSize()
        }
    }

    /// The degrees, typeable, with "up from level" under them; after a shot "as planned" (the stroke never changes
    /// the angle the cue is raised to, StrikeReading.comparison).
    private func readout(_ reading: StrikeReading.Reading?) -> some View {
        let moved = reading?.comparison?.differs(.cueAngle) == true
        return VStack(alignment: .leading, spacing: 4) {
            TypeableFigure(model: model, kind: .cueAngle, spokenLabel: StrikeWords.cueAngleLabel,
                           spokenValue: reading.map { StrikeSpoken.tile(.cueAngle, $0, differs: moved) }
                               ?? StrikeSpoken.degrees(degrees)) {
                FigureLine(figure: StrikeWords.degreesFigure(degrees), size: figureSize, role: .set,
                           editable: StrikeEntry.Kind.cueAngle.isOpen(model))
                    .padding(.bottom, 4)
            }
            Text(verbatim: StrikeWords.upFromLevel)
                .font(.system(size: max(12, figureSize * 0.55)))
                .foregroundStyle(.secondary)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
            if reading?.comparison != nil {
                Text(verbatim: StrikeWords.asPlanned)
                    .font(.system(size: max(12, figureSize * 0.55)))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// The dial as one adjustable VoiceOver element, stepping through the offered angles.
    private func accessible<Content: View>(_ content: Content) -> some View {
        content
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

    /// The quarter circle: the ball at the lower leading corner, the arc, the lesson's band, ticks at 0, 20, 45 and 90
    /// degrees with their figures, and the cue as the needle, ending in the instrument kit's handle; after a shot a
    /// faint ghost needle at the planned angle. Drawn in screen terms (left to right) whatever the reading direction:
    /// the cue is a picture of a cue, not text.
    private func dial(size: CGFloat, ghost: Double?) -> some View {
        let ball = size * 0.07
        let labelSize = max(10, size * 0.065)
        // Room past the arc for the ticks and their figures (the 90 sits above the arc's top).
        let labelRoom = 18 + labelSize * 1.9
        let pivot = CGPoint(x: ball + 2, y: size - ball - 2)
        let radius = size - ball - labelRoom
        let degreesNow = degrees
        let accent = palette.accent, track = palette.track, paper = palette.paper
        let handle = max(22, size * 0.12)
        // A point on the dial at an angle and a distance from the ball (a plain closure, so the canvas may call it).
        let point: @Sendable (Double, CGFloat) -> CGPoint = { deg, r in
            let a = deg * .pi / 180
            return CGPoint(x: pivot.x + r * CGFloat(cos(a)), y: pivot.y - r * CGFloat(sin(a)))
        }
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
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
                // The arc from level to upright; the drag stops at the top angle offered (Self.top).
                ctx.stroke(arc(from: 0, to: 90), with: .color(track), style: StrokeStyle(lineWidth: max(6, size * 0.045), lineCap: .round))
                if let zone {
                    ctx.stroke(arc(from: Double(zone.lowerBound), to: Double(zone.upperBound)),
                               with: .color(accent.opacity(0.8 * zoneStrength)),
                               style: StrokeStyle(lineWidth: max(10, size * 0.07), lineCap: .round))
                }
                // Ticks with their figures at 0, 20, 45 and 90 degrees.
                for a in [0.0, 20.0, 45.0, 90.0] {
                    var tick = Path()
                    tick.move(to: point(a, radius + 6)); tick.addLine(to: point(a, radius + 14))
                    ctx.stroke(tick, with: .color(.secondary), lineWidth: 1)
                    let text = Text(verbatim: a == 0 ? StrikeWords.number(a, decimals: 0) + "°" : StrikeWords.number(a, decimals: 0))
                        .font(.system(size: labelSize, design: .monospaced))
                        .foregroundStyle(.secondary)
                    ctx.draw(text, at: point(a, radius + 14 + labelSize * 0.9), anchor: .center)
                }
                // The planned angle's ghost needle after a shot.
                if let ghost {
                    var g = Path()
                    g.move(to: point(ghost, ball * 1.2)); g.addLine(to: point(ghost, radius))
                    ctx.stroke(g, with: .color(paper.opacity(0.25)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                // The cue: from just off the ball out to the arc.
                var cue = Path()
                cue.move(to: point(degreesNow, ball * 1.2)); cue.addLine(to: point(degreesNow, radius))
                ctx.stroke(cue, with: .color(accent), style: StrokeStyle(lineWidth: max(3, size * 0.02), lineCap: .round))
                // The ball: flat grey, as the tip picture.
                ctx.fill(Path(ellipseIn: CGRect(x: pivot.x - ball, y: pivot.y - ball, width: ball * 2, height: ball * 2)),
                         with: .color(Color(white: 0.80)))
            }
            .frame(width: size, height: size)
            InstrumentHandle(diameter: handle)
                .position(point(degreesNow, radius))
        }
        .frame(width: size, height: size)
        .environment(\.layoutDirection, .leftToRight)
        .contentShape(Rectangle())
        .gesture(angleDrag(pivot: pivot))
    }

    /// The drag on the dial: the angle from the ball to the finger, on whole degrees, settling on an offered angle.
    private func angleDrag(pivot: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0).onChanged { value in
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
        }
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
