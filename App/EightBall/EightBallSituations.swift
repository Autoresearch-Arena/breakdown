// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the twelve situations authored and checked in the solver with the
//          new "BreakProbe eightball" search; every escape below passes there with its call and no foul).
// Edited: Claude Opus 5.5 High, 21-November-2026 (imports BreakdownRules, where the eight-ball group, pocket and call
//          types now live; nothing else changed.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6: item 38, every number (the tables, groups,
//          surfaces, strokes, calls, rails, bridge and ratings) moved to the package's authored library
//          (BreakdownAuthored, AuthoredEscapes), which the dev tool's content check plays too, so no copy can drift;
//          items 27 and 30, every escape re-authored on the 0.7.0 physics and cloths with an aim window of at least one
//          of the aim control's quarter-degree steps (two where the table allows), re-laying a situation or finding a new
//          route where its escapes needed it, and the cards' words changed to match a new route. The runs are recorded
//          beside the numbers in AuthoredEscapes.)
// PURPOSE: The Behind the 8-Ball library as the app shows it: the twelve situations of the design (section 3), each a
//          full eight-ball table in progress (both groups and the 8, the rest pocketed), with the authored escapes
//          (stroke, call, bridge, rating, "On a real table" card), the lesson and the trick shots that teach it.
//          The numbers are the package library's (Packages/BreakdownCore/Sources/BreakdownAuthored/AuthoredEscapes.swift:
//          each table in diamonds, its group and surface, each escape's stroke, call, rails, bridge and rating, and the
//          technique test the dev tool checks it with); the words are here, where the string catalog collects them.
//          How they were checked (the package's dev tool, EightBallAuthoring.swift and Reauthor.swift): each layout is
//          proved hooked first (level straight strokes all the way round, two speeds, make no legal ball in any pocket
//          without a rail first); each escape's stroke passes in the real solver on the situation's own cloth: cue ball
//          neither pocketed nor off the table, first ball one of yours (or the 8 when you are on it), the called ball in
//          the called pocket, the 8 not pocketed unless called, no ball off the table, a rail or pocket after contact,
//          the cue stick clear of every other ball at the strike, and the technique really used (rails before contact
//          for a kick, a take-off for a jump, a curve a level cue cannot copy for a massé or swerve, a cushion for the
//          banked ball), with an aim window of at least one aim step. "BreakProbe verify" plays them all before every
//          upload.
//          Pockets: headRight 0, footRight 1, headLeft 2, footLeft 3, rightSide 4, leftSide 5 (solver indices).
//          Read by EightBallMode (flow), EightBallJudge (escapes, ratings) and EightBallViews (words).
// SRP/DRY check: Pass - the app's words and the building of the app's types from the library; the types are
//          EightBallTypes, the numbers the library's. Each card's numbers are built from the escape's own stroke and the
//          situation's surface (RealTableNumbers), never typed twice.
import BreakdownAuthored
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

    /// The words of one escape, matched to the package library's escape by its id ("A", "B", ...): its title and the
    /// "On a real table" card's lines. The card's numbers come from the library's stroke and the situation's surface,
    /// filled in by `make`, so they can never disagree with what the solver was given.
    private struct Words {
        let id: String
        let title: String
        let aim: String
        let cue: String
        let speed: String
        let commonMiss: String
    }

    /// One situation: the package library's table, group, surface and escapes (strokes, calls, rails, bridge, ratings)
    /// with this file's words. Every library escape must have its words and every set of words an escape, and every
    /// technique must be one the app names: a mismatch is an authoring mistake, stopped here.
    private static func make(_ a: AuthoredSituation, title: String, story: String, escapes words: [Words], lesson: String,
                             taughtBy: [String]) -> EightBallSituation {
        precondition(words.count == a.escapes.count && words.allSatisfy { w in a.escapes.contains { $0.id == w.id } },
                     "situation \(a.id): its words and the library's escapes do not match")
        let surface = PlaySurface(a.surface)
        let built = a.escapes.map { e -> EightBallEscape in
            guard let w = words.first(where: { $0.id == e.id }),
                  let kind = EightBallEscapeKind(rawValue: e.kind.rawValue) else {
                preconditionFailure("situation \(a.id), escape \(e.id): no words, or a technique the app does not name")
            }
            let settings = TrickSettings(e.strike)
            return EightBallEscape(id: e.id, title: w.title, kind: kind,
                                   alsoUses: e.alsoUses.compactMap { EightBallEscapeKind(rawValue: $0.rawValue) },
                                   rails: e.rails, settings: settings, call: e.call, usesBridge: e.usesBridge,
                                   rating: e.rating,
                                   card: RealTableCard(aim: w.aim, cue: w.cue, speed: w.speed, commonMiss: w.commonMiss,
                                                       numbers: RealTableNumbers(settings: settings, surface: surface)))
        }
        return EightBallSituation(id: a.id, number: a.number, title: title, story: story, setup: a.layout, group: a.group,
                                  surface: surface, escapes: built, lesson: lesson, taughtBy: taughtBy)
    }

    // MARK: 1. Tucked Behind the 8
    static let tucked = make(
        AuthoredEscapes.tucked, title: String(localized: "Tucked Behind the 8"),
        story: String(localized: "You're on solids with two left. Your opponent rolled the cue ball dead behind the 8."),
        escapes: [
            Words(id: "A", title: String(localized: "Two-rail kick"),
                  aim: String(localized: "Send the cue ball into the head rail at the first diamond from the left rail, then off the left rail just past the second diamond, and up the table to cut the 3 into the foot-left corner."),
                  cue: String(localized: "Level, a little draw, no side."),
                  speed: String(localized: "Medium: an easy stroke, enough to travel the table and a bit more."),
                  commonMiss: String(localized: "Hitting the head rail a little too far right: the cue ball comes back too near the middle and clips the 8.")),
            Words(id: "B", title: String(localized: "Jump the 8"),
                  aim: String(localized: "Aim at the 3 as if the 8 weren't there, cutting it into the foot-left corner."),
                  cue: String(localized: "Raised steeply, about 53 degrees. Hit down through the centre with a short punch."),
                  speed: String(localized: "Firm: a crisp punch, not a long follow-through."),
                  commonMiss: String(localized: "Too little height, so the cue ball clips the 8. Scooping under the ball is a foul.")),
        ],
        lesson: String(localized: "The usual order is kick first, then curve, then jump. Hitting the 8 first is a foul: that's where the name comes from."),
        taughtBy: ["two-rail-kick", "jump-over"])

    // MARK: 2. Frozen on the Rail (Dive-bar felt)
    static let frozen = make(
        AuthoredEscapes.frozen, title: String(localized: "Frozen on the Rail"),
        story: String(localized: "You're on stripes. Your 10 is frozen to the rail and two solids hide it."),
        escapes: [
            Words(id: "A", title: String(localized: "One-rail kick off the head rail"),
                  aim: String(localized: "Kick into the head rail about three quarters of a diamond right of the middle diamond. The cue ball runs back down and pins the 10 along the rail into the foot-right corner."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Firm. Dead bar rails eat speed, so hit harder than it looks."),
                  commonMiss: String(localized: "A trace of side spin: the rebound shifts and the 10 comes off the rail short of the corner.")),
            Words(id: "B", title: String(localized: "Two-rail kick"),
                  aim: String(localized: "Head rail just under a diamond right of the middle, then the right rail about three quarters of a diamond short of the 10, so the cue ball runs down the rail into it."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Firm to hard: a solid hit that still has pace after two dead rails."),
                  commonMiss: String(localized: "Too soft on this felt: the cue ball dies on the second rail and never reaches the 10.")),
        ],
        lesson: String(localized: "To kick a ball on the rail, aim along the rail, not at the ball. Too much speed and it won't hold the rail, and even a little side changes the rebound."),
        taughtBy: ["two-rail-kick", "stop-dead"])

    // MARK: 3. Jump a Diamond Out
    static let jumpDiamond = make(
        AuthoredEscapes.jumpDiamond, title: String(localized: "Jump a Diamond Out"),
        story: String(localized: "You're on solids. An opponent ball sits a diamond in front of you."),
        escapes: [
            Words(id: "A", title: String(localized: "One-rail kick"),
                  aim: String(localized: "Kick off the left rail a little past the second diamond. The cue ball crosses the table and cuts the 5 into the right side pocket."),
                  cue: String(localized: "Level, well below centre for draw."),
                  speed: String(localized: "Firm: a solid hit across the table and back."),
                  commonMiss: String(localized: "Hitting the rail too far up the table, so the 5 is struck too full and rattles in the jaws.")),
            Words(id: "B", title: String(localized: "Jump the 11"),
                  aim: String(localized: "Aim the cut on the 5 into the side as if the 11 weren't there."),
                  cue: String(localized: "Raised to about 44 degrees. Short, crisp stroke, hitting a little below the cue's line through the centre."),
                  speed: String(localized: "Firm: a sharp punch."),
                  commonMiss: String(localized: "Too steep for the distance: the cue ball lands short and runs into the 11.")),
        ],
        lesson: String(localized: "Jump when the blocker is far enough away to clear. More speed gives a longer jump, more elevation a shorter, higher one. Near a rail, a jump can leave the table."),
        taughtBy: ["jump-over"])

    // MARK: 4. Bend Around
    static let bendAround = make(
        AuthoredEscapes.bendAround, title: String(localized: "Bend Around"),
        story: String(localized: "You're on stripes. A solid half covers the line to your 15, and the kicks are long."),
        escapes: [
            Words(id: "A", title: String(localized: "Swerve past the 6"),
                  aim: String(localized: "Start the cue ball just past the left edge of the 6. Right side bends it back onto the 15."),
                  cue: String(localized: "Raised a little, about 24 degrees, with lots of right side."),
                  speed: String(localized: "Medium: the curve needs some pace to bend in time."),
                  commonMiss: String(localized: "Too little side or too much speed: it doesn't bend back and misses the 15 on the left.")),
            Words(id: "B", title: String(localized: "Jump the 6"),
                  aim: String(localized: "Aim at the 15 for the foot-right corner as if the 6 weren't there."),
                  cue: String(localized: "Raised to about 44 degrees. Short punch through the centre."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Not enough height: the cue ball clips the 6, which is a foul.")),
            Words(id: "C", title: String(localized: "Three-rail kick"),
                  aim: String(localized: "Right rail at the first diamond, then the head rail, then the left rail just short of the second diamond, and down onto the 15."),
                  cue: String(localized: "Level, a little draw, no side."),
                  speed: String(localized: "Medium to firm: enough for three rails and the length of the table."),
                  commonMiss: String(localized: "Hitting the first rail a little long, so the path drifts and catches a solid.")),
        ],
        lesson: String(localized: "A swerve is a gentle bend from a slightly raised cue. It's the easiest curve, and the usual fallback when the kick lanes are bad."),
        taughtBy: ["masse-curve"])

    // MARK: 5. Kick for the Game (Dive-bar felt)
    static let kickForTheGame = make(
        AuthoredEscapes.kickForTheGame, title: String(localized: "Kick for the Game"),
        story: String(localized: "You've cleared your stripes. The 8 sits off the left rail near the corner, and a solid blocks it."),
        escapes: [
            Words(id: "A", title: String(localized: "One-rail kick"),
                  aim: String(localized: "Kick off the left rail just short of the sixth diamond, catching the 8 thin so it runs down the rail into the foot-left corner."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Gentle: a soft roll, even on slow felt."),
                  commonMiss: String(localized: "Too much speed: the 8 is hit too hard off the rail and jumps out of the corner.")),
            Words(id: "B", title: String(localized: "Three-rail kick"),
                  aim: String(localized: "Left rail at the second diamond, the head rail just right of the middle, the right rail at the first diamond, then the length of the table onto the 8."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Hard: on dead bar rails the cue ball loses a lot at each one."),
                  commonMiss: String(localized: "Coming up short: the dead rails take more than you expect.")),
        ],
        lesson: String(localized: "Kicking just to hit a ball is far easier than kicking to pocket it. The 8 anywhere but the called pocket loses the game."),
        taughtBy: ["two-rail-kick"])

    // MARK: 6. The Z Shot (bridge)
    static let zShot = make(
        AuthoredEscapes.zShot, title: String(localized: "The Z Shot"),
        story: String(localized: "Hill-hill, you're on stripes and hooked mid-table. Your 13 sits just off the foot rail."),
        escapes: [
            Words(id: "A", title: String(localized: "Two-rail Z kick"),
                  aim: String(localized: "Right rail at the first diamond past the side pocket, then the foot rail, and along it into the 13 and on into the foot-left corner."),
                  cue: String(localized: "On the bridge: head flat a hand's width back, cue in the notch, light fingers on the butt. Level, a little draw and a touch of left side."),
                  speed: String(localized: "Firm: it has to carry two rails and still push the 13 in."),
                  commonMiss: String(localized: "Too much side: the cue ball comes off the foot rail before it reaches the 13.")),
            Words(id: "B", title: String(localized: "Three-rail kick"),
                  aim: String(localized: "Left rail just past the first diamond beyond the side pocket, across to the right rail near the foot corner, then the foot rail into the 13."),
                  cue: String(localized: "On the bridge, level, a little draw, no side."),
                  speed: String(localized: "Hard: three rails and a ball to push."),
                  commonMiss: String(localized: "Hitting the first rail a little early: the path runs wide of the 13 at the foot rail.")),
        ],
        lesson: String(localized: "A little side on a two-rail kick holds the cue ball on the foot rail. A shot like this goes maybe one time in ten; shape on your next ball after it is what makes it great."),
        taughtBy: ["two-rail-kick", "bridge-draw"])

    // MARK: 7. Point-Blank
    static let pointBlank = make(
        AuthoredEscapes.pointBlank, title: String(localized: "Point-Blank"),
        story: String(localized: "You're on your last stripe. The 8 is almost touching the cue ball."),
        escapes: [
            Words(id: "A", title: String(localized: "One-rail kick"),
                  aim: String(localized: "Kick off the left rail a quarter diamond past the sixth diamond, back across onto the 14 for the foot-right corner."),
                  cue: String(localized: "Level, a little draw, no side."),
                  speed: String(localized: "Medium."),
                  commonMiss: String(localized: "Hitting the rail too close to you: the cue ball comes back into the 8.")),
            Words(id: "B", title: String(localized: "Steep jump over the 8"),
                  aim: String(localized: "Aim at the 14 for the foot-right corner straight over the 8."),
                  cue: String(localized: "Very steep, about 58 degrees. A short, quick jab, and get the tip out of the way."),
                  speed: String(localized: "Firm, but short: the stroke is a jab, not a push."),
                  commonMiss: String(localized: "A lazy stroke: the tip stays on the ball too long and it's a double hit.")),
        ],
        lesson: String(localized: "The closer the blocker, the steeper the jump has to be. Close jumps sit right on the edge of the double-hit rule."),
        taughtBy: ["jump-over"])

    // MARK: 8. Massé for the Win (Tournament cloth)
    static let masseForTheWin = make(
        AuthoredEscapes.masseForTheWin, title: String(localized: "Massé for the Win"),
        story: String(localized: "You're on the 8. It hangs in the jaws of the foot-right corner, and a stripe sits dead in the way."),
        escapes: [
            Words(id: "A", title: String(localized: "Length-of-the-table kick"),
                  aim: String(localized: "Send the cue ball back to the head rail a quarter diamond right of the right-hand diamond. It comes all the way back and taps the 8 in."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Soft: this slick cloth and lively rail do the work. About a lag to the head rail and back."),
                  commonMiss: String(localized: "Too much speed on fast cloth: the cue ball runs through and scratches behind the 8.")),
            Words(id: "B", title: String(localized: "Full massé"),
                  aim: String(localized: "Point the cue down the table, left of the 12, and let the curve bring the cue ball right onto the 8."),
                  cue: String(localized: "Steep, about 53 degrees, tip well right of centre."),
                  speed: String(localized: "Medium: a curve on fast cloth needs pace to finish."),
                  commonMiss: String(localized: "On slick cloth the curve takes late. Aim too fine and it bends too late to reach the 8.")),
        ],
        lesson: String(localized: "The full massé is the last resort and the most spectacular. The kick is the honest answer; the massé scores more because it's harder, not because it's wiser."),
        taughtBy: ["masse-curve"])

    // MARK: 9. Jump Off the Bridge (bridge for the jump)
    static let jumpOffTheBridge = make(
        AuthoredEscapes.jumpOffTheBridge, title: String(localized: "Jump Off the Bridge"),
        story: String(localized: "You're on solids with two left. The cue ball is far out on the table, and a stripe sits half a diamond in front of it."),
        escapes: [
            Words(id: "A", title: String(localized: "One-rail kick"),
                  aim: String(localized: "Kick off the right rail just past the sixth diamond, back across onto the 4 for the foot-left corner."),
                  cue: String(localized: "Level, a little draw, no side."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Hitting the rail a little short: the cue ball catches the 9 on the way back.")),
            Words(id: "B", title: String(localized: "Jump the 9 off the bridge"),
                  aim: String(localized: "Aim at the 4 for the foot-left corner straight over the 9."),
                  cue: String(localized: "On the bridge, cue raised to about 49 degrees, butt held high. Jab down through the centre."),
                  speed: String(localized: "Firm: a short, sharp jab."),
                  commonMiss: String(localized: "The bridge head drifting into a ball while you set up. That's a foul before you shoot.")),
        ],
        lesson: String(localized: "A raised bridge gives the steep cue a jump needs when the cue ball is out of reach. Touching any ball with the bridge is a foul."),
        taughtBy: ["jump-over", "bridge-draw", "combo-chain"])

    // MARK: 10. Kick-Bank Cross-Side
    static let kickBankCrossSide = make(
        AuthoredEscapes.kickBankCrossSide, title: String(localized: "Kick-Bank Cross-Side"),
        story: String(localized: "You're on stripes. Your 13 sits a ball off the right rail, just past the side pocket."),
        escapes: [
            Words(id: "A", title: String(localized: "One-rail kick"),
                  aim: String(localized: "Kick off the foot rail just under half a diamond right of the middle. The cue ball comes back up and cuts the 13 into the right side pocket."),
                  cue: String(localized: "Level, below centre for draw."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Too full on the 13: it hits the near point of the side pocket and stays out.")),
            Words(id: "B", title: String(localized: "Bank cross-side"),
                  aim: String(localized: "Cut the 13 into the right rail just past the side pocket, so it banks straight back across the table into the left side pocket."),
                  cue: String(localized: "Level, a little follow, no side."),
                  speed: String(localized: "Firm."),
                  commonMiss: String(localized: "Throw from the cut: hit the 13 a little thin and the bank comes off short of the side pocket.")),
        ],
        lesson: String(localized: "A bank is never obvious and must be called. Throw from the cut shortens or lengthens a bank, and a kick then a bank stacks two sources of error."),
        taughtBy: ["two-rail-kick", "cross-bank"])

    // MARK: 11. Full-Table Swerve (Tournament cloth)
    static let fullTableSwerve = make(
        AuthoredEscapes.fullTableSwerve, title: String(localized: "Full-Table Swerve"),
        story: String(localized: "You're on stripes. Your 9 sits by the head-left corner, and a cluster of solids fills the middle."),
        escapes: [
            Words(id: "A", title: String(localized: "Three-rail kick"),
                  aim: String(localized: "Foot rail just right of the first diamond, the left rail near the corner, the right rail past the side pocket, then up the table to the 9."),
                  cue: String(localized: "Level, above centre for follow."),
                  speed: String(localized: "Medium: lively rails and fast cloth carry it."),
                  commonMiss: String(localized: "Too firm on fast cloth: the cue ball runs past the 9 and the angles open up.")),
            Words(id: "B", title: String(localized: "Full-table swerve"),
                  aim: String(localized: "Start the cue ball toward the left rail between the second and third diamonds. Left side bends it off that line, round the solids and onto the 9."),
                  cue: String(localized: "Raised to about 30 degrees, with full left side."),
                  speed: String(localized: "Medium to firm: the curve has the whole table to build."),
                  commonMiss: String(localized: "The curve takes late on slick cloth. Start too straight and it hooks into the cluster.")),
        ],
        lesson: String(localized: "A swerve that runs the length of the table can pocket a ball you can't see. The longer the path, the more the curve depends on the cloth and the speed."),
        taughtBy: ["masse-curve", "two-rail-kick"])

    // MARK: 12. No Way to Make It
    static let noWayToMakeIt = make(
        AuthoredEscapes.noWayToMakeIt, title: String(localized: "No Way to Make It"),
        story: String(localized: "You're on solids. The 1 is frozen on the foot rail behind stripes, the 6 is tied up, and you're behind the 8."),
        escapes: [
            Words(id: "A", title: String(localized: "Kick safety"),
                  aim: String(localized: "Two rails: the left rail just short of the second diamond, the right rail at the first diamond past the side pocket, then a soft touch on the 1. The cue ball dies by the foot rail."),
                  cue: String(localized: "Level, a touch above centre, no side."),
                  speed: String(localized: "Medium: enough for two rails and the far end, and no more."),
                  commonMiss: String(localized: "Too firm: the cue ball comes back out into the open and leaves your opponent a shot.")),
        ],
        lesson: String(localized: "When you can't make a ball, choose the safety that leaves you the favourite. A kick safety often hands your opponent a foul and the game back to you."),
        taughtBy: ["two-rail-kick", "stop-dead"])
}
