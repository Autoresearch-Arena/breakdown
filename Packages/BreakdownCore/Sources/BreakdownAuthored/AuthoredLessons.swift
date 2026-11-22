// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The six lessons' numbers and the stop shot's second exercise, the one copy (bug plan after 0.6.6, item 38):
//          layout, reference stroke, goal, measured windows and, for a lesson that raises the cue, the offered cue
//          angles that work. The app's Lessons adds the words, the lesson's control and its Watch moment, and reads
//          these; BreakProbe's "verify" plays them and "lessons" re-authors them (LessonAuthoring.swift).
// SRP/DRY check: Pass - data only; the types are AuthoredTypes'. sine(forAngle:) is the same formula as the app's
//          CueAngleMenu.sine(forAngle:), so a lesson's reference elevation is exactly what the control sets.
import BreakdownLensModel
import Foundation

public enum AuthoredLessons {
    /// The path, in the order it is taught.
    public static let all: [AuthoredLesson] = [stop, follow, draw, cut, curve, jump]

    public static func lesson(id: String) -> AuthoredLesson? { all.first { $0.id == id } }

    /// The sine of an offered cue angle in degrees, as the app's cue-angle control computes it.
    public static func sine(forAngle a: Int) -> Double { a <= 0 ? 0 : sin(Double(a) * .pi / 180) }

    // MARK: 1. Stop shot
    // Item 10 of the bug plan after 0.6.6: re-laid straight across the table into the top side pocket from near the
    // bottom rail, where a player stands square (the old line ran from mid-table along the top-right corner's diagonal,
    // and the bridge hand sat past even the sitting reach). BreakProbe lessons stop (21-Nov-2026, 0.7.0 physics): the 3
    // 0.30 m from the pocket, the cue ball 0.25 m behind it; 2,835 candidates, 990 passed, 530 survived the screen. The
    // power was then set to 1.80 m/s, inside the lesson's window, because the second exercise needs that pace (below) and
    // the tip to -3.5 mm, the middle of its band ("tricks near lesson-stop" walked the windows from it): aim 88.50 to
    // 91.50 degrees, power 1.20 to 2.80 m/s, tip height -6.5 to -1.0 mm, side -9.0 to +9.0 mm.
    public static let stop = AuthoredLesson(
        id: "lesson-stop", number: 1,
        layout: authoredLayout([0: Vec2(1.2700, 0.7200), 3: Vec2(1.2700, 0.9700)]),
        reference: AuthoredStrike(aim: 90.00, power: 1.80, tipUp: -0.0035, tipSide: 0), cueAngle: nil,
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 5)], cueZone: AuthoredZone(Vec2(1.2700, 0.9128), 0.05), firstHit: 3),
        window: AuthoredWindow(aim: 1.50, power: 0.60, tipUp: 0.0025, tipSide: 0.0090), cueAngles: nil)

    // MARK: 2. Follow
    // Item 10: re-laid into the top-right corner on a 40-degree line from near the bottom rail, a square stance with room
    // for the cue ball to roll on after the pot. BreakProbe lessons follow (21-Nov-2026): the 3 1.0 m from the pocket,
    // the cue ball 0.25 m behind it, the zone 0.70 m past contact with a 0.15 m radius, kept only if a centre hit misses;
    // 4,224 candidates, 1,014 passed, 246 survived. Windows: aim 39.25 to 41.01 degrees, power 1.65 to 2.00 m/s, tip
    // height +5.5 to +14.0 mm (the top is the miscue limit), side -8.0 to +7.5 mm.
    public static let follow = AuthoredLesson(
        id: "lesson-follow", number: 2,
        layout: authoredLayout([0: Vec2(1.5824, 0.4665), 3: Vec2(1.7740, 0.6272)]),
        reference: AuthoredStrike(aim: 40.13, power: 1.85, tipUp: 0.010, tipSide: 0), cueAngle: nil,
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 3)], cueZone: AuthoredZone(Vec2(2.2664, 1.0404), 0.15), firstHit: 3),
        window: AuthoredWindow(aim: 0.88, power: 0.15, tipUp: 0.0040, tipSide: 0.0075), cueAngles: nil)

    // MARK: 3. Draw
    // Item 10: re-laid straight across the table into the top side pocket, a square stance; the cue ball comes back
    // toward the bottom rail. BreakProbe lessons draw (21-Nov-2026): the 3 0.40 m from the pocket, the cue ball 0.20 m
    // behind it, the zone 0.30 m behind contact with a 0.25 m radius, kept only if a centre hit misses; 1,672 candidates,
    // 756 passed, 494 survived. Windows: aim 86.08 to 93.92 degrees, power 1.40 to 2.40 m/s, tip height -14.0 to -5.5 mm,
    // side -10.0 to +10.0 mm.
    public static let draw = AuthoredLesson(
        id: "lesson-draw", number: 3,
        layout: authoredLayout([0: Vec2(1.2700, 0.6700), 3: Vec2(1.2700, 0.8700)]),
        reference: AuthoredStrike(aim: 90.00, power: 1.90, tipUp: -0.010, tipSide: 0), cueAngle: nil,
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 5)], cueZone: AuthoredZone(Vec2(1.2700, 0.5129), 0.25), firstHit: 3),
        window: AuthoredWindow(aim: 3.92, power: 0.50, tipUp: 0.0040, tipSide: 0.0100), cueAngles: nil)

    // MARK: 4. Cut and throw
    // BreakProbe lessons cut (21-Nov-2026 on generation one): a 30-degree cut, the reference 0.57 degrees thinner than the
    // geometric ghost ball, allowing for throw. Its stance was already square. Unchanged on the 0.7.0 physics (tricks
    // near, 21-Nov-2026); windows: aim 56.47 to 57.85 degrees, power 0.85 to 6.15 m/s, tip height -14.0 to +14.0 mm (the
    // miscue limit both ways), side -6.0 to +3.0 mm.
    public static let cut = AuthoredLesson(
        id: "lesson-cut", number: 4,
        layout: authoredLayout([0: Vec2(1.9279, 0.7124), 3: Vec2(2.2270, 1.1135)]),
        reference: AuthoredStrike(aim: 57.13, power: 2.15, tipUp: 0, tipSide: 0), cueAngle: nil,
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 3)], firstHit: 3),
        window: AuthoredWindow(aim: 0.66, power: 1.30, tipUp: 0.0140, tipSide: 0.0030), cueAngles: nil)

    // MARK: 5. Curve
    // BreakProbe lessons curve, re-authored near its old answer on the tuned generation two (the blocker 1.2 radii off
    // the line, so it half-blocks it: a raised cue bends the cue ball too little to pass a ball dead on the line and come
    // back to it within half a metre). Item 10: the whole layout moved 0.2 m toward the head rail, a square stance (it
    // was a stretch); the stroke is unchanged and still passes on the 0.7.0 physics (tricks near, 21-Nov-2026). Windows:
    // aim 7.81 to 11.41 degrees, power 1.55 to 2.40 m/s, tip height -11.5 to -6.5 mm, side +6.0 to +10.0 mm; cue angles
    // 25 to 30 degrees.
    public static let curve = AuthoredLesson(
        id: "lesson-curve", number: 5,
        layout: authoredLayout([0: Vec2(0.8000, 0.6350), 4: Vec2(1.0000, 0.6007), 9: Vec2(1.3500, 0.6350)]),
        reference: AuthoredStrike(aim: 9.47, power: 1.95, tipUp: -0.009, tipSide: 0.008, elevation: sine(forAngle: 25)),
        cueAngle: 25,
        goal: AuthoredGoal(drops: [], firstHit: 9),
        window: AuthoredWindow(aim: 1.66, power: 0.40, tipUp: 0.0025, tipSide: 0.0020), cueAngles: 25...30)

    // MARK: 6. Jump
    // BreakProbe lessons jump, kept only if a level cue misses and two neighbouring cue angles work. Item 10: the layout
    // moved 0.2 m toward the head rail, a square stance; there the old stroke let the cue ball run on into a pocket, so it
    // was re-authored near it (tricks near, 21-Nov-2026: 30,855 strokes, 12,619 passed, 5,965 survived), at 50 degrees.
    // Windows: aim -2.92 to +2.92 degrees, power 3.10 to 5.20 m/s, tip height -11.5 to +14.0 mm, side -1.5 to +1.5 mm;
    // cue angles 40 to 70.
    public static let jump = AuthoredLesson(
        id: "lesson-jump", number: 6,
        layout: authoredLayout([0: Vec2(0.8000, 0.6350), 6: Vec2(1.0500, 0.6350), 11: Vec2(1.8000, 0.6350)]),
        reference: AuthoredStrike(aim: 0.00, power: 4.30, tipUp: 0.0015, tipSide: 0, elevation: sine(forAngle: 50)),
        cueAngle: 50,
        goal: AuthoredGoal(drops: [], firstHit: 11),
        window: AuthoredWindow(aim: 2.92, power: 0.90, tipUp: 0.0125, tipSide: 0.0015), cueAngles: 40...70)

    // MARK: The stop shot's second exercise
    // The stop lesson's own line with the cue ball further back, where copying the lesson's settings misses and a lower
    // tip alone makes it (BreakProbe lessons stop-exercise 1.8, 21-Nov-2026). At the lesson's first 1.60 m/s no distance
    // left the exercise any room in power; at 1.80 m/s, 0.50 m back, copying the lesson misses (the cue ball rolls on)
    // and tip heights -13.5 to -5.5 mm stop it, with a twentieth of a metre a second either way still working. A square
    // stance too. Windows: aim 1.04 degrees, power 0.10 m/s, tip height 4.0 mm, side 4.5 mm.
    public static let stopExercise = AuthoredExercise(
        layout: authoredLayout([0: Vec2(1.2700, 0.4700), 3: Vec2(1.2700, 0.9700)]),
        reference: AuthoredStrike(aim: 90.00, power: 1.80, tipUp: -0.0095, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 5)], cueZone: AuthoredZone(Vec2(1.2700, 0.9128), 0.05), firstHit: 3),
        window: AuthoredWindow(aim: 1.04, power: 0.10, tipUp: 0.0040, tipSide: 0.0045))
}
