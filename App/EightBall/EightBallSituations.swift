// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the twelve situations authored and checked in the solver with the
//          new "BreakProbe eightball" search; every escape below passes there with its call and no foul).
// Edited: Claude Opus 5.5 High, 21-November-2026 (imports BreakdownRules, where the eight-ball group, pocket and call
//          types now live; nothing else changed.)
// PURPOSE: The Behind the 8-Ball library: data only. The twelve situations of the design (section 3), each a full
//          eight-ball table in progress (both groups and the 8, the rest pocketed), written in diamonds through
//          EightBallTable.layout and stored in metres, with the authored escapes (stroke, call, bridge, rating,
//          "On a real table" card), the lesson and the trick shots that teach it.
//          How they were checked (Packages/BreakdownCore/Sources/BreakProbe/EightBallAuthoring.swift, run as
//          "BreakProbe eightball" for the search and "BreakProbe eightball verify" for the strokes below, three threads,
//          21-Nov-2026): each layout is proved hooked first (level straight strokes all the way round, two speeds, make
//          no legal ball in any pocket without a rail first); each escape's stroke was found by a grid sweep, re-centred
//          in its windows, and passes in the real solver on the situation's own cloth: cue ball neither pocketed nor off
//          the table, first ball one of yours (or the 8 when you are on it), the called ball in the called pocket, the 8
//          not pocketed unless called, no ball off the table, a rail or pocket after contact, the cue stick clear of every
//          other ball at the strike, and the technique really used (rails before contact for a kick, a take-off for a
//          jump, a curve a level cue cannot copy for a massé or swerve, a cushion for the banked ball). The seed does not
//          change any outcome. Each escape's comment gives the windows walked outward from its exact stroke: aim
//          degrees, speed m/s, side and tip-height metres, and the cue's elevation as a sine.
//          Positions follow the design's diamonds, nudged where the solver needed it (each nudge is noted).
//          Pockets: headRight 0, footRight 1, headLeft 2, footLeft 3, rightSide 4, leftSide 5 (solver indices).
//          Read by EightBallMode (flow), EightBallJudge (escapes, ratings) and EightBallViews (words).
// SRP/DRY check: Pass - data only; the types are EightBallTypes. Each card's numbers are built from the escape's own
//          stroke and the situation's surface (RealTableNumbers), never typed twice. The search lives in the package's
//          dev tool and copies nothing from here; it holds the same diamonds and strokes as its evidence.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules

enum EightBallSituations {
    static func situation(id: String) -> EightBallSituation? { all.first { $0.id == id } }

    static let all: [EightBallSituation] = [
        tucked, frozen, jumpDiamond, bendAround, kickForTheGame, zShot, pointBlank, masseForTheWin, jumpOffTheBridge,
        kickBankCrossSide, fullTableSwerve, noWayToMakeIt,
    ]

    // MARK: Building blocks

    /// One escape before it knows its cloth: the card's numbers come from the stroke and the situation's surface,
    /// filled in by `make`, so they can never disagree with what the solver was given.
    private struct Draft {
        let id: String
        let title: String
        let kind: EightBallEscapeKind
        var alsoUses: [EightBallEscapeKind] = []
        let rails: Int
        let settings: TrickSettings
        let call: EightBallCall
        var usesBridge = false
        let rating: Int
        let aim: String
        let cue: String
        let speed: String
        let commonMiss: String
    }

    private static func make(id: String, number: Int, title: String, story: String, setup: [Vec2],
                             group: EightBallGroup, surface: PlaySurface, escapes: [Draft], lesson: String,
                             taughtBy: [String]) -> EightBallSituation {
        let built = escapes.map { d in
            EightBallEscape(id: d.id, title: d.title, kind: d.kind, alsoUses: d.alsoUses, rails: d.rails,
                            settings: d.settings, call: d.call, usesBridge: d.usesBridge, rating: d.rating,
                            card: RealTableCard(aim: d.aim, cue: d.cue, speed: d.speed, commonMiss: d.commonMiss,
                                                numbers: RealTableNumbers(settings: d.settings, surface: surface)))
        }
        return EightBallSituation(id: id, number: number, title: title, story: story, setup: setup, group: group,
                                  surface: surface, escapes: built, lesson: lesson, taughtBy: taughtBy)
    }

    // MARK: 1. Tucked Behind the 8
    // Design layout, with the 3 nudged from (1.0, 5.0) to (0.8, 5.4): still dead behind the 8 on the same line, a
    // little nearer its corner, which widens the kick's aim window from 0.08 to 0.10 degrees either side.
    // A (search 306,000 strokes, 246 pass): windows aim 172.10 to 172.30, speed 1.95 to 2.50, side -0.5 to +0.5 mm,
    //   tip -0.5 to +8.0 mm. Off the head rail at across 1.86; the cue ball rests at across 0.87, along 6.38.
    // B (11,016 strokes, 456 pass; elevation and speed then set mid-band): aim 26.97 to 27.55, speed 2.80 to 4.75,
    //   tip -10.5 to +14.5 mm, elevation sine 0.65 to 0.94; take-off at 1.52 m/s upward.
    // The design's third escape (a kick safety) was searched but no stroke left every stripe screened, so it is left
    // out; Safety can still be called and is judged on what it leaves.
    static let tucked = make(
        id: "tucked-behind-the-8", number: 1, title: String(localized: "Tucked Behind the 8"),
        story: String(localized: "You're on solids with two left. Your opponent rolled the cue ball dead behind the 8."),
        setup: EightBallTable.layout(cue: (2.2, 2.6), eight: (2.0, 3.0), balls: [
            3: (0.8, 5.4), 6: (3.6, 7.5),
            9: (3.5, 6.8), 11: (0.5, 2.0), 12: (3.2, 1.4), 14: (1.6, 7.2), 15: (3.0, 5.4),
        ]),
        group: .solids, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: 172.20, power: 2.25, tipUp: 0.004, tipSide: 0),
                  call: .ball(3, pocket: .footLeft), rating: 3,
                  aim: String(localized: "Send the cue ball back into the head rail just left of the middle diamond. It comes back up the table and cuts the 3 into the foot-left corner."),
                  cue: String(localized: "Level, a touch above centre, no side."),
                  speed: String(localized: "Medium: an easy stroke, enough to travel the table and a bit more."),
                  commonMiss: String(localized: "Hitting the rail a hair too far right, so the cue ball clips the 8 on its way back.")),
            Draft(id: "B", title: String(localized: "Jump the 8"), kind: .jump, rails: 0,
                  settings: TrickSettings(aim: 27.25, power: 3.80, tipUp: -0.002, tipSide: 0, elevation: 0.80),
                  call: .ball(3, pocket: .footLeft), rating: 4,
                  aim: String(localized: "Aim at the 3 as if the 8 weren't there, cutting it into the foot-left corner."),
                  cue: String(localized: "Raised steeply, about 53 degrees. Hit down through the centre with a short punch."),
                  speed: String(localized: "Firm: a crisp punch, not a long follow-through."),
                  commonMiss: String(localized: "Too little height, so the cue ball clips the 8. Scooping under the ball is a foul.")),
        ],
        lesson: String(localized: "The usual order is kick first, then curve, then jump. Hitting the 8 first is a foul: that's where the name comes from."),
        taughtBy: ["two-rail-kick", "jump-over"])

    // MARK: 2. Frozen on the Rail (Dive-bar felt)
    // Design layout, with the 6 moved from (1.5, 6.8) to (1.3, 6.3) so it hides your 12 (otherwise the 12 was a
    // straight shot into the foot-left corner), and the 10 at across 3.905 (1.6 mm off the cushion: frozen to the eye).
    // Set on Dive-bar felt: dead rails and grabby cloth make the rail-hugging kick a speed shot.
    // A (306,000 strokes, 109 pass): aim -175.33 to -175.19, speed 2.55 to 3.50, side -0.5 to +0.5 mm, tip +1.5 to
    //   +13.5 mm. Off the head rail at across 2.77, back down the table onto the 10.
    // B (277 pass, then centred): aim -175.03 to -174.45, speed 2.60 to 5.40, side -0.5 to +0.5 mm, tip -4.0 to
    //   +19.5 mm. Head rail at across 2.82, then the right rail at along 6.29, and down the rail into the 10.
    static let frozen = make(
        id: "frozen-on-the-rail", number: 2, title: String(localized: "Frozen on the Rail"),
        story: String(localized: "You're on stripes. Your 10 is frozen to the rail and two solids hide it."),
        setup: EightBallTable.layout(cue: (2.4, 4.6), eight: (2.0, 3.6), balls: [
            10: (3.905, 7.0), 12: (0.5, 7.4),
            1: (0.8, 2.5), 3: (2.95, 5.65), 5: (3.4, 6.3), 6: (1.3, 6.3),
        ]),
        group: .stripes, surface: .diveBar,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick off the head rail"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: -175.25, power: 3.00, tipUp: 0.0075, tipSide: 0),
                  call: .ball(10, pocket: .footRight), rating: 3,
                  aim: String(localized: "Kick into the head rail about three quarters of a diamond right of the middle diamond. The cue ball runs back down and pins the 10 along the rail into the foot-right corner."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Firm. Dead bar rails eat speed, so hit harder than it looks."),
                  commonMiss: String(localized: "A trace of side spin: the rebound shifts and the 10 comes off the rail short of the corner.")),
            Draft(id: "B", title: String(localized: "Two-rail kick"), kind: .kick, rails: 2,
                  settings: TrickSettings(aim: -174.71, power: 3.85, tipUp: 0.008, tipSide: 0),
                  call: .ball(10, pocket: .footRight), rating: 4,
                  aim: String(localized: "Head rail just under a diamond right of the middle, then the right rail about three quarters of a diamond short of the 10, so the cue ball runs down the rail into it."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Firm to hard: a solid hit that still has pace after two dead rails."),
                  commonMiss: String(localized: "Too soft on this felt: the cue ball dies on the second rail and never reaches the 10.")),
        ],
        lesson: String(localized: "To kick a ball on the rail, aim along the rail, not at the ball. Too much speed and it won't hold the rail, and even a little side changes the rebound."),
        taughtBy: ["two-rail-kick", "stop-dead"])

    // MARK: 3. Jump a Diamond Out
    // Design layout, with the 9 moved from (1.2, 6.0) to (0.9, 5.8) so it screens your 2 (otherwise the 2 was a straight
    // shot into the foot-left corner).
    // A (306,000 strokes, 1,100 pass): aim 62.22 to 63.28, speed 4.40 to 5.50, side -0.5 to +1.0 mm, tip -15.5 to
    //   -8.5 mm. Off the left rail at along 2.38.
    // B (13,770 strokes, 706 pass): aim -32.38 to -30.58, speed 3.40 to 5.00, tip -15.0 to -4.0 mm, elevation sine
    //   0.57 to 0.87; take-off at 1.47 m/s upward.
    static let jumpDiamond = make(
        id: "jump-a-diamond-out", number: 3, title: String(localized: "Jump a Diamond Out"),
        story: String(localized: "You're on solids. An opponent ball sits a diamond in front of you."),
        setup: EightBallTable.layout(cue: (2.0, 1.4), eight: (2.4, 6.4), balls: [
            5: (3.5, 3.7), 2: (0.6, 6.9),
            9: (0.9, 5.8), 11: (2.5, 2.15), 13: (3.3, 7.4), 14: (0.4, 4.8),
        ]),
        group: .solids, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: 62.76, power: 4.80, tipUp: -0.012, tipSide: 0),
                  call: .ball(5, pocket: .rightSide), rating: 3,
                  aim: String(localized: "Kick off the left rail a little past the second diamond. The cue ball crosses the table and cuts the 5 into the right side pocket."),
                  cue: String(localized: "Level, well below centre for draw."),
                  speed: String(localized: "Firm: a solid hit across the table and back."),
                  commonMiss: String(localized: "Hitting the rail too far up the table, so the 5 is struck too full and rattles in the jaws.")),
            Draft(id: "B", title: String(localized: "Jump the 11"), kind: .jump, rails: 0,
                  settings: TrickSettings(aim: -31.36, power: 4.20, tipUp: -0.0105, tipSide: 0, elevation: 0.70),
                  call: .ball(5, pocket: .rightSide), rating: 3,
                  aim: String(localized: "Aim the cut on the 5 into the side as if the 11 weren't there."),
                  cue: String(localized: "Raised to about 44 degrees. Short, crisp stroke, hitting a little below the cue's line through the centre."),
                  speed: String(localized: "Firm: a sharp punch."),
                  commonMiss: String(localized: "Too steep for the distance: the cue ball lands short and runs into the 11.")),
        ],
        lesson: String(localized: "Jump when the blocker is far enough away to clear. More speed gives a longer jump, more elevation a shorter, higher one. Near a rail, a jump can leave the table."),
        taughtBy: ["jump-over"])

    // MARK: 4. Bend Around
    // Re-laid: the design's layout left the 15 about 1.25 m from its corner, and no swerve or two-rail kick passed
    // there (the only passing jump was a single aim). Now the cue ball is at (1.6, 3.0), the 6 at (2.1, 3.98) half covers
    // the line to the 15 at (3.0, 6.4), nearly straight into the foot-right corner; the 4 moved to (3.5, 5.4) and the 11
    // to (3.55, 2.1), screened by the 8.
    // A swerve (32,670 + 35,035 strokes in two grids): aim -13.05 to -12.65, speed 2.45 to 2.55, side +19.5 to +20.5 mm,
    //   tip -5.0 to +2.0 mm, elevation sine 0.30 only (a swerve in this solver is very touchy in cue angle and speed).
    // B (13,770 strokes, 343 pass, then centred): aim -22.15 to -21.75, speed 3.55 to 5.10, tip -19.5 to +10.0 mm,
    //   elevation sine 0.45 to 0.86.
    // C (306,000 strokes, 90 pass; no two-rail route exists here, this one takes three): aim -129.49 to -129.25, speed
    //   2.70 to 3.30, side -1.0 to +1.0 mm, tip +3.5 to +11.0 mm. Right rail at along 1.10, head rail at across 2.74,
    //   left rail at along 2.13.
    static let bendAround = make(
        id: "bend-around", number: 4, title: String(localized: "Bend Around"),
        story: String(localized: "You're on stripes. A solid half covers the line to your 15, and the kicks are long."),
        setup: EightBallTable.layout(cue: (1.6, 3.0), eight: (2.9, 2.4), balls: [
            15: (3.0, 6.4), 11: (3.55, 2.1),
            2: (0.4, 5.2), 4: (3.5, 5.4), 6: (2.1, 3.98), 7: (0.9, 7.6),
        ]),
        group: .stripes, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "Swerve past the 6"), kind: .swerve, rails: 0,
                  settings: TrickSettings(aim: -12.85, power: 2.50, tipUp: -0.0015, tipSide: 0.020, elevation: 0.30),
                  call: .ball(15, pocket: .footRight), rating: 3,
                  aim: String(localized: "Start the cue ball just past the left edge of the 6. Right side bends it back onto the 15."),
                  cue: String(localized: "Raised a little, about 17 degrees, with lots of right side."),
                  speed: String(localized: "Medium: the curve needs some pace to bend in time."),
                  commonMiss: String(localized: "Too little side or too much speed: it doesn't bend back and misses the 15 on the left.")),
            Draft(id: "B", title: String(localized: "Jump the 6"), kind: .jump, rails: 0,
                  settings: TrickSettings(aim: -21.95, power: 4.35, tipUp: -0.0055, tipSide: 0, elevation: 0.70),
                  call: .ball(15, pocket: .footRight), rating: 3,
                  aim: String(localized: "Aim at the 15 for the foot-right corner as if the 6 weren't there."),
                  cue: String(localized: "Raised to about 44 degrees. Short punch through the centre."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Not enough height: the cue ball clips the 6, which is a foul.")),
            Draft(id: "C", title: String(localized: "Three-rail kick"), kind: .kick, rails: 3,
                  settings: TrickSettings(aim: -129.39, power: 3.00, tipUp: 0.0075, tipSide: 0),
                  call: .ball(15, pocket: .footRight), rating: 4,
                  aim: String(localized: "Right rail at the first diamond, then the head rail, then the left rail past the second diamond, and down onto the 15."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Medium to firm: enough for three rails and the length of the table."),
                  commonMiss: String(localized: "Hitting the first rail a little long, so the path drifts and catches a solid.")),
        ],
        lesson: String(localized: "A swerve is a gentle bend from a slightly raised cue. It's the easiest curve, and the usual fallback when the kick lanes are bad."),
        taughtBy: ["masse-curve"])

    // MARK: 5. Kick for the Game (Dive-bar felt)
    // Design layout, set on Dive-bar felt: the slow, grabby felt makes the thin kick on the 8 far more forgiving (aim
    // window 2.2 degrees wide against 0.5 on cloth) while the three-rail route loses pace on dead rails.
    // A (306,000 strokes, 676 pass): aim 26.61 to 28.81, speed 1.00 to 2.05, side -19.5 to +19.5 mm, tip -6.5 to
    //   +19.5 mm. Off the left rail at along 5.87.
    // B (21 pass): aim 122.69 to 123.45, speed 4.60 to 5.90, side 0 only, tip +8.0 mm only. Left rail at along 2.02,
    //   head rail at across 2.26, right rail at along 1.03, then up the table onto the 8.
    static let kickForTheGame = make(
        id: "kick-for-the-game", number: 5, title: String(localized: "Kick for the Game"),
        story: String(localized: "You've cleared your stripes. The 8 sits off the left rail near the corner, and a solid blocks it."),
        setup: EightBallTable.layout(cue: (1.6, 3.0), eight: (0.2, 6.8), balls: [
            1: (1.0, 4.6), 4: (2.8, 6.4), 6: (3.5, 2.0), 7: (2.2, 7.6),
        ]),
        group: .stripes, surface: .diveBar,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: 27.71, power: 1.50, tipUp: 0.0065, tipSide: 0),
                  call: .ball(8, pocket: .footLeft), rating: 3,
                  aim: String(localized: "Kick off the left rail just short of the sixth diamond, catching the 8 thin so it runs down the rail into the foot-left corner."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Gentle: a soft roll, even on slow felt."),
                  commonMiss: String(localized: "Too much speed: the 8 is hit too hard off the rail and jumps out of the corner.")),
            Draft(id: "B", title: String(localized: "Three-rail kick"), kind: .kick, rails: 3,
                  settings: TrickSettings(aim: 123.07, power: 5.25, tipUp: 0.008, tipSide: 0),
                  call: .ball(8, pocket: .footLeft), rating: 5,
                  aim: String(localized: "Left rail at the second diamond, the head rail just right of the middle, the right rail at the first diamond, then the length of the table onto the 8."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Hard: on dead bar rails the cue ball loses a lot at each one."),
                  commonMiss: String(localized: "Coming up short: the dead rails take more than you expect.")),
        ],
        lesson: String(localized: "Kicking just to hit a ball is far easier than kicking to pocket it. The 8 anywhere but the called pocket loses the game."),
        taughtBy: ["two-rail-kick"])

    // MARK: 6. The Z Shot (bridge)
    // Design layout, with the 7 moved from (3.5, 2.2) to (2.8, 2.3) so it screens your 15 (otherwise the 15 was a
    // straight shot into the head-right corner).
    // A (561,600 strokes, 482 pass): aim -36.06 to -35.76, speed 3.35 to 4.35, side -5.0 mm only, tip -6.5 to
    //   -5.5 mm. Right rail at along 5.01, foot rail at across 1.75, then along the foot rail into the 13.
    // B (306,000 strokes, 86 pass): aim 52.44 to 52.74, speed 4.60 to 5.35, side 0 only, tip -8.0 mm only. Left rail at
    //   along 5.12, right rail at along 7.33, foot rail at across 1.93.
    static let zShot = make(
        id: "the-z-shot", number: 6, title: String(localized: "The Z Shot"),
        story: String(localized: "Hill-hill, you're on stripes and hooked mid-table. Your 13 sits just off the foot rail."),
        setup: EightBallTable.layout(cue: (2.6, 3.2), eight: (1.2, 3.0), balls: [
            13: (1.5, 7.85), 15: (3.0, 1.2),
            2: (0.6, 6.4), 4: (2.27, 4.6), 6: (1.9, 5.8), 7: (2.8, 2.3),
        ]),
        group: .stripes, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "Two-rail Z kick"), kind: .kick, rails: 2,
                  settings: TrickSettings(aim: -35.92, power: 3.85, tipUp: -0.006, tipSide: -0.005),
                  call: .ball(13, pocket: .footLeft), usesBridge: true, rating: 4,
                  aim: String(localized: "Right rail at the first diamond past the side pocket, then the foot rail, and along it into the 13 and on into the foot-left corner."),
                  cue: String(localized: "On the bridge: head flat a hand's width back, cue in the notch, light fingers on the butt. Level, a little draw and a touch of left side."),
                  speed: String(localized: "Firm: it has to carry two rails and still push the 13 in."),
                  commonMiss: String(localized: "Too much side: the cue ball comes off the foot rail before it reaches the 13.")),
            Draft(id: "B", title: String(localized: "Three-rail kick"), kind: .kick, rails: 3,
                  settings: TrickSettings(aim: 52.60, power: 4.95, tipUp: -0.008, tipSide: 0),
                  call: .ball(13, pocket: .footLeft), usesBridge: true, rating: 5,
                  aim: String(localized: "Left rail just past the first diamond beyond the side pocket, across to the right rail near the foot corner, then the foot rail into the 13."),
                  cue: String(localized: "On the bridge, level, a little draw, no side."),
                  speed: String(localized: "Hard: three rails and a ball to push."),
                  commonMiss: String(localized: "Hitting the first rail a little early: the path runs wide of the 13 at the foot rail.")),
        ],
        lesson: String(localized: "A little side on a two-rail kick holds the cue ball on the foot rail. A shot like this goes maybe one time in ten; shape on your next ball after it is what makes it great."),
        taughtBy: ["two-rail-kick", "bridge-draw"])

    // MARK: 7. Point-Blank
    // Design layout as written; the 8 sits about two inches in front of the cue ball.
    // A (306,000 strokes): aim 73.00 to 73.60, speed 2.20 to 3.20, side 0 only, tip -6.5 to -5.5 mm. Off the left rail
    //   at along 6.27.
    // B (5,184 strokes, 228 pass, then centred): aim -62.07 to -61.03, speed 2.80 to 4.15, tip -9.5 to +7.5 mm,
    //   elevation sine 0.73 to 0.93 (about 47 to 68 degrees); take-off at 1.49 m/s upward.
    static let pointBlank = make(
        id: "point-blank", number: 7, title: String(localized: "Point-Blank"),
        story: String(localized: "You're on your last stripe. The 8 is almost touching the cue ball."),
        setup: EightBallTable.layout(cue: (1.0, 6.0), eight: (1.3, 6.17), balls: [
            14: (2.6, 6.9),
            1: (3.4, 3.1), 3: (0.6, 2.2), 6: (2.2, 4.9), 7: (3.7, 5.8),
        ]),
        group: .stripes, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: 73.30, power: 2.70, tipUp: -0.006, tipSide: 0),
                  call: .ball(14, pocket: .footRight), rating: 3,
                  aim: String(localized: "Kick off the left rail a quarter diamond past the sixth diamond, back across onto the 14 for the foot-right corner."),
                  cue: String(localized: "Level, a little draw, no side."),
                  speed: String(localized: "Medium."),
                  commonMiss: String(localized: "Hitting the rail too close to you: the cue ball comes back into the 8.")),
            Draft(id: "B", title: String(localized: "Steep jump over the 8"), kind: .jump, rails: 0,
                  settings: TrickSettings(aim: -61.55, power: 3.50, tipUp: -0.0045, tipSide: 0, elevation: 0.85),
                  call: .ball(14, pocket: .footRight), rating: 5,
                  aim: String(localized: "Aim at the 14 for the foot-right corner straight over the 8."),
                  cue: String(localized: "Very steep, about 58 degrees. A short, quick jab, and get the tip out of the way."),
                  speed: String(localized: "Firm, but short: the stroke is a jab, not a push."),
                  commonMiss: String(localized: "A lazy stroke: the tip stays on the ball too long and it's a double hit.")),
        ],
        lesson: String(localized: "The closer the blocker, the steeper the jump has to be. Close jumps sit right on the edge of the double-hit rule."),
        taughtBy: ["jump-over"])

    // MARK: 8. Massé for the Win (Tournament cloth)
    // Design layout as written, set on Tournament cloth: slick and fast, so the massé takes late and the kick runs long.
    // A (306,000 strokes, 129 pass): aim -177.40 to -176.88, speed 1.15 to 2.35, side -1.5 to +1.5 mm, tip -7.5 to
    //   +19.5 mm. Off the head rail at across 3.22, the whole length of the table back onto the 8.
    // B (33,824 strokes, 40 pass): aim 0.20 to 4.10, speed 2.35 to 2.65, side +13.5 to +21.5 mm, tip -8.0 to -2.0 mm,
    //   elevation sine 0.79 to 0.81. Kept only because a level cue on the same stroke fails.
    static let masseForTheWin = make(
        id: "masse-for-the-win", number: 8, title: String(localized: "Massé for the Win"),
        story: String(localized: "You're on the 8. It hangs in the jaws of the foot-right corner, and a stripe sits dead in the way."),
        setup: EightBallTable.layout(cue: (2.9, 6.5), eight: (3.85, 7.85), balls: [
            9: (0.8, 2.6), 10: (1.6, 5.2), 12: (3.4, 7.2), 13: (0.5, 7.0),
        ]),
        group: .solids, surface: .tournament,
        escapes: [
            Draft(id: "A", title: String(localized: "Length-of-the-table kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: -177.14, power: 1.75, tipUp: 0.006, tipSide: 0),
                  call: .ball(8, pocket: .footRight), rating: 3,
                  aim: String(localized: "Send the cue ball back to the head rail a quarter diamond right of the right-hand diamond. It comes all the way back and taps the 8 in."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Soft: this slick cloth and lively rail do the work. About a lag to the head rail and back."),
                  commonMiss: String(localized: "Too much speed on fast cloth: the cue ball runs through and scratches behind the 8.")),
            Draft(id: "B", title: String(localized: "Full massé"), kind: .masse, rails: 0,
                  settings: TrickSettings(aim: 2.00, power: 2.50, tipUp: -0.005, tipSide: 0.017, elevation: 0.80),
                  call: .ball(8, pocket: .footRight), rating: 5,
                  aim: String(localized: "Point the cue down the table, left of the 12, and let the curve bring the cue ball right onto the 8."),
                  cue: String(localized: "Steep, about 53 degrees, tip well right of centre and a little low."),
                  speed: String(localized: "Medium: a curve on fast cloth needs pace to finish."),
                  commonMiss: String(localized: "On slick cloth the curve takes late. Aim too fine and it bends too late to reach the 8.")),
        ],
        lesson: String(localized: "The full massé is the last resort and the most spectacular. The kick is the honest answer; the massé scores more because it's harder, not because it's wiser."),
        taughtBy: ["masse-curve"])

    // MARK: 9. Jump Off the Bridge (bridge for the jump)
    // Design layout as written.
    // A (306,000 strokes, 68 pass): aim -62.03 to -61.47, speed 3.05 to 4.15, side 0 only, tip -6.5 to -5.5 mm. Off the
    //   right rail at along 6.03.
    // B (5,184 strokes, 164 pass): aim 23.01 to 23.97, speed 3.10 to 4.90, tip -19.5 to +4.0 mm, elevation sine 0.58 to
    //   0.90; take-off at 1.44 m/s upward. The carom-for-shape extra in the design is not authored.
    static let jumpOffTheBridge = make(
        id: "jump-off-the-bridge", number: 9, title: String(localized: "Jump Off the Bridge"),
        story: String(localized: "You're on solids with two left. The cue ball is far out on the table, and a stripe sits half a diamond in front of it."),
        setup: EightBallTable.layout(cue: (2.0, 5.0), eight: (3.0, 5.2), balls: [
            4: (0.9, 7.3), 7: (3.2, 3.0),
            9: (1.75, 5.6), 11: (3.6, 1.0), 12: (2.3, 7.4), 15: (0.4, 3.0),
        ]),
        group: .solids, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: -61.75, power: 3.60, tipUp: -0.006, tipSide: 0),
                  call: .ball(4, pocket: .footLeft), rating: 3,
                  aim: String(localized: "Kick off the right rail just past the sixth diamond, back across onto the 4 for the foot-left corner."),
                  cue: String(localized: "Level, a little draw, no side."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Hitting the rail a little short: the cue ball catches the 9 on the way back.")),
            Draft(id: "B", title: String(localized: "Jump the 9 off the bridge"), kind: .jump, alsoUses: [.bridge], rails: 0,
                  settings: TrickSettings(aim: 23.49, power: 3.85, tipUp: -0.0045, tipSide: 0, elevation: 0.75),
                  call: .ball(4, pocket: .footLeft), usesBridge: true, rating: 4,
                  aim: String(localized: "Aim at the 4 for the foot-left corner straight over the 9."),
                  cue: String(localized: "On the bridge, cue raised to about 49 degrees, butt held high. Jab down through the centre."),
                  speed: String(localized: "Firm: a short, sharp jab."),
                  commonMiss: String(localized: "The bridge head drifting into a ball while you set up. That's a foul before you shoot.")),
        ],
        lesson: String(localized: "A raised bridge gives the steep cue a jump needs when the cue ball is out of reach. Touching any ball with the bridge is a foul."),
        taughtBy: ["jump-over", "bridge-draw", "combo-chain"])

    // MARK: 10. Kick-Bank Cross-Side
    // Re-laid: with the 13 level with the side pockets (design (3.7, 4.0)) a bank to the far side has no rail to use
    // (the right rail there is the pocket's mouth), and the search found only single points. Now the 13 is at
    // (3.6, 4.6), half a diamond up from the side; the 2 moved to (2.83, 5.7) to block the direct line and the 6 to
    // (1.15, 3.0) to screen your 10.
    // A (306,000 strokes, 599 pass): aim -20.30 to -19.46, speed 4.25 to 5.40, side 0 only, tip -11.5 to -7.0 mm. Off
    //   the foot rail at across 2.67, back onto the 13 into the right side pocket.
    // B (378,000 strokes, 246 pass): aim -133.25 to -133.19, speed 2.35 to 2.95, side -4.0 to +1.5 mm, tip +3.5 to
    //   +12.5 mm. Off the right rail at along 4.99 into the 13, which banks off the right rail across to the left side.
    static let kickBankCrossSide = make(
        id: "kick-bank-cross-side", number: 10, title: String(localized: "Kick-Bank Cross-Side"),
        story: String(localized: "You're on stripes. Your 13 sits a ball off the right rail, just past the side pocket."),
        setup: EightBallTable.layout(cue: (2.2, 6.6), eight: (2.2, 2.0), balls: [
            13: (3.6, 4.6), 10: (0.7, 1.5),
            2: (2.83, 5.7), 3: (1.4, 7.0), 5: (3.5, 6.9), 6: (1.15, 3.0),
        ]),
        group: .stripes, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "One-rail kick"), kind: .kick, rails: 1,
                  settings: TrickSettings(aim: -19.80, power: 4.60, tipUp: -0.0095, tipSide: 0),
                  call: .ball(13, pocket: .rightSide), rating: 3,
                  aim: String(localized: "Kick off the foot rail two thirds of a diamond right of the middle. The cue ball comes back up and cuts the 13 into the right side pocket."),
                  cue: String(localized: "Level, below centre for draw."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Too full on the 13: it hits the near point of the side pocket and stays out.")),
            Draft(id: "B", title: String(localized: "Kick, then bank cross-side"), kind: .kick, alsoUses: [.bank], rails: 1,
                  settings: TrickSettings(aim: -133.21, power: 2.65, tipUp: 0.008, tipSide: 0),
                  call: .ball(13, pocket: .leftSide), rating: 5,
                  aim: String(localized: "Kick into the right rail at the first diamond past the side pocket. The cue ball comes off it into the 13, which banks off the right rail and straight across into the left side pocket."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Medium."),
                  commonMiss: String(localized: "Throw from the cut: hit the 13 a little thin and the bank comes off short of the side pocket.")),
        ],
        lesson: String(localized: "A bank is never obvious and must be called. Throw from the cut shortens or lengthens a bank, and a kick then a bank stacks two sources of error."),
        taughtBy: ["two-rail-kick", "cross-bank"])

    // MARK: 11. Full-Table Swerve (Tournament cloth)
    // Design layout, with the 14 moved from (3.4, 6.0) to (2.65, 1.0), screened by the 8 (at (3.4, 6.0) it was an easy
    // shot right beside the cue ball). Set on Tournament cloth: the long curve depends on the slick cloth.
    // A (306,000 strokes, 202 pass): aim 54.31 to 54.73, speed 1.65 to 2.55, side 0 only, tip +4.0 to +17.5 mm. Foot rail
    //   at across 1.32, left rail at along 7.15, right rail at along 4.43, then up the table to the 9.
    // B (67,680 strokes, 37 pass): aim 148.90 to 149.40, speed 3.40 to 3.60, side -20.5 to -19.5 mm, tip -3.5 to
    //   +3.0 mm, elevation sine 0.40 only. Takes 34 seconds to finish rolling on this cloth.
    static let fullTableSwerve = make(
        id: "full-table-swerve", number: 11, title: String(localized: "Full-Table Swerve"),
        story: String(localized: "You're on stripes. Your 9 sits by the head-left corner, and a cluster of solids fills the middle."),
        setup: EightBallTable.layout(cue: (2.6, 7.0), eight: (2.6, 2.2), balls: [
            9: (0.4, 0.5), 14: (2.65, 1.0),
            1: (1.6, 3.8), 3: (2.1, 4.3), 4: (1.8, 4.6), 5: (0.3, 3.2), 7: (0.5, 5.5),
        ]),
        group: .stripes, surface: .tournament,
        escapes: [
            Draft(id: "A", title: String(localized: "Three-rail kick"), kind: .kick, rails: 3,
                  settings: TrickSettings(aim: 54.53, power: 2.05, tipUp: 0.0105, tipSide: 0),
                  call: .ball(9, pocket: .headLeft), rating: 4,
                  aim: String(localized: "Foot rail a third of a diamond right of the first diamond, the left rail near the corner, the right rail past the side pocket, then up the table to the 9."),
                  cue: String(localized: "Level, above centre for follow."),
                  speed: String(localized: "Medium: lively rails and fast cloth carry it."),
                  commonMiss: String(localized: "Too firm on fast cloth: the cue ball runs past the 9 and the angles open up.")),
            Draft(id: "B", title: String(localized: "Full-table swerve"), kind: .swerve, rails: 0,
                  settings: TrickSettings(aim: 149.20, power: 3.50, tipUp: -0.0005, tipSide: -0.020, elevation: 0.40),
                  call: .ball(9, pocket: .headLeft), rating: 5,
                  aim: String(localized: "Start the cue ball toward the left rail between the second and third diamonds. Left side bends it off that line, round the solids and onto the 9."),
                  cue: String(localized: "Raised to about 24 degrees, with full left side."),
                  speed: String(localized: "Medium to firm: the curve has the whole table to build."),
                  commonMiss: String(localized: "The curve takes late on slick cloth. Start too straight and it hooks into the cluster.")),
        ],
        lesson: String(localized: "A swerve that runs the length of the table can pocket a ball you can't see. The longer the path, the more the curve depends on the cloth and the speed."),
        taughtBy: ["masse-curve", "two-rail-kick"])

    // MARK: 12. No Way to Make It
    // Design layout as written. Confirmed hooked, and every route to pocket a ball found by the search is a sliver:
    // a three- or four-rail kick on the 1 into the foot-left corner passed at one aim only, the 6 into the foot-left
    // corner off one rail at 0.04 degrees, and the hero shot below at 0.06.
    // A kick safety on the 1 (43,200 strokes, 125 pass): aim 60.57 to 61.21, speed 1.95 to 2.65, side -1.0 to +1.0 mm,
    //   tip -3.0 to +6.5 mm. Left rail at along 1.88, right rail at along 4.96, then a legal touch on the 1 with
    //   nothing dropping; the cue ball rests at across 0.67, along 7.68, by the foot rail. It does NOT leave every stripe
    //   screened (the design says it scores 3 only if the opponent ends up hooked): a fully hooking safety was found
    //   only at single strokes (one in 16,200, one in 145,800), so the repeatable kick safety is authored instead.
    // B (306,000 strokes, 26 pass, then centred): aim 27.82 to 28.04, speed 3.90 to 4.35, side -3.0 to +2.0 mm, tip
    //   -8.5 to -8.0 mm. Left rail at along 4.96, foot rail at across 1.80, along the rail into the 1, which runs into
    //   the foot-right corner.
    static let noWayToMakeIt = make(
        id: "no-way-to-make-it", number: 12, title: String(localized: "No Way to Make It"),
        story: String(localized: "You're on solids. The 1 is frozen on the foot rail behind stripes, the 6 is tied up, and you're behind the 8."),
        setup: EightBallTable.layout(cue: (2.4, 0.6), eight: (2.5, 1.0), balls: [
            1: (2.0, 7.9), 6: (1.1, 5.9),
            9: (1.8, 7.5), 10: (1.25, 5.75), 11: (0.95, 6.1), 13: (2.4, 7.55), 14: (3.4, 4.2),
        ]),
        group: .solids, surface: .cloth,
        escapes: [
            Draft(id: "A", title: String(localized: "Kick safety"), kind: .safety, alsoUses: [.kick], rails: 2,
                  settings: TrickSettings(aim: 60.97, power: 2.35, tipUp: 0.002, tipSide: 0),
                  call: .safety, rating: 2,
                  aim: String(localized: "Two rails: the left rail just short of the second diamond, the right rail at the first diamond past the side pocket, then a soft touch on the 1. The cue ball dies by the foot rail."),
                  cue: String(localized: "Level, a touch above centre, no side."),
                  speed: String(localized: "Medium: enough for two rails and the far end, and no more."),
                  commonMiss: String(localized: "Too firm: the cue ball comes back out into the open and leaves your opponent a shot.")),
            Draft(id: "B", title: String(localized: "Hero kick on the 1"), kind: .kick, rails: 2,
                  settings: TrickSettings(aim: 27.90, power: 4.10, tipUp: -0.008, tipSide: 0),
                  call: .ball(1, pocket: .footRight), rating: 5,
                  aim: String(localized: "Off the left rail at the first diamond past the side pocket, then the foot rail just left of the middle, and along it into the 1, which runs into the foot-right corner."),
                  cue: String(localized: "Level, below centre for draw."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Anything but perfect: the 1 leaves the rail and stays out, and your opponent is in.")),
        ],
        lesson: String(localized: "When you can't make a ball, choose the safety that leaves you the favourite. A kick safety often hands your opponent a foul and the game back to you."),
        taughtBy: ["two-rail-kick", "stop-dead"])
}
