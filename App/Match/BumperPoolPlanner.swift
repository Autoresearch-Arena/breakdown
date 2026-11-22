// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: How the computer chooses its stroke at bumper pool (plans/22-Nov-2026-v074-glow-up-plan.md, feature R,
//          table-opponent brief item 4). OpponentPlanner.plan hands a bumper-pool snapshot here; this file says what a
//          stroke is worth to the computer and how widely to search, runs TableOpponentSearch, and turns its choice
//          into an OpponentPlan for MatchOpponent to play and OpponentWords to explain.
//          The value of a solved stroke for the shooter's seat s against the other seat o:
//            - a win +1000, a loss -1000 (nothing else matters then);
//            - +10 for each of its own balls the stroke drops in its own cup (BumperPoolRules.targetHole), -10 for
//              each of the other side's balls it drops in theirs;
//            - -8 for a foul (a ball in the wrong cup or off the table: it comes back and the turn passes);
//            - position: 3 times the gain in its own balls' nearness to its cup less 3 times the other side's gain,
//              where nearness is the sum over a side's balls on the table of max(0, 1 - d / 0.6 m), d the distance to
//              that side's cup, measured from the snapshot's layout to where the balls came to rest.
//          The fan: every degree round the ball at 0.6, 0.9, 1.3, 1.8 and 2.4 m/s, the middle of the ball (hard adds
//          the reference touch of draw); the success mark is 10 (one ball in its cup). The speeds stay low because the
//          cups refuse fast balls: the newer physics lets a ball skip over a cup it crosses too fast, and these cups
//          catch only about 18 mm round their centre. Easy plays the raw best of a fan two degrees apart at 0.9, 1.4
//          and 2.0 m/s (540 solves). Nothing here builds on mirror-image geometry: the design probe found the mirror
//          banks sink nothing from the start, because the bumpers sit in their way.
//          The plan's kind: .cup when the chosen stroke, struck perfectly, drops one of its own balls in its own cup
//          (marked when that is the side's marked ball; the route from that ball's cushion and bumper touches before
//          it dropped), otherwise .advance with the ball it struck.
// SRP/DRY check: Pass - the rules (which cup, whose ball, what is a foul, who won) are BumperPoolRules'; the solving,
//          smoothing, refining and noise check are TableOpponentSearch's; the cups' positions come from the solve
//          parameters (PoolParameters.bedHoles, written there from BumperPoolTable); no other file values a
//          bumper-pool stroke.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

enum BumperPoolPlanner {
    // MARK: The value's numbers (the plan's, also the ones the design probe played whole games with)

    static let winValue = 1000.0
    static let cupValue = 10.0
    static let foulValue = -8.0
    static let positionWeight = 3.0
    /// A ball this far from its cup or further counts nothing towards its side's nearness, metres: about half the
    /// table's length, so only balls already in the cup's half pull the value.
    static let nearReach = 0.6

    // MARK: The fan

    static let speeds = [0.6, 0.9, 1.3, 1.8, 2.4]
    static let step = 1.0
    static let tipUp = 0.0
    /// One ball in its own cup, struck perfectly: what the aim window is measured against.
    static let successValue = cupValue
    static let easySpeeds = [0.9, 1.4, 2.0]
    static let easyStep = 2.0
    /// The fallback stroke when the search has nothing (the struck ball not on the table): a gentle roll at its cup.
    static let fallbackSpeed = 0.9

    // MARK: Planning

    /// The computer's stroke for the snapshot's turn.
    static func plan(_ s: OpponentSnapshot) -> OpponentPlan {
        let seat = s.state.turn.index
        let other = s.state.turn.next(among: max(s.state.players.count, 1)).index
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        guard BumperPoolRules.sides.indices.contains(seat), BumperPoolRules.targetHole.indices.contains(seat) else {
            return fallback(s, cueBall: cueBall)
        }
        let fan = s.level == .easy
            ? TableFan(step: easyStep, speeds: easySpeeds, tips: [tipUp])
            : TableFan(step: step, speeds: speeds, tips: TableSearchDepth.tips(s.level, base: tipUp))
        // Plain values for the @Sendable value closure (the search runs it on many threads at once).
        let start = s.layout, inPlay = Set(s.state.ballsLeft), p = s.parameters
        let spec = TableOpponentSearch.Spec(
            fan: fan, successValue: successValue,
            ownCup: TableOpponentSearch.OwnCup(balls: Set(BumperPoolRules.sides[seat]),
                                               hole: BumperPoolRules.targetHole[seat]),
            value: { ruling, facts in
                BumperPoolPlanner.value(ruling: ruling, facts: facts, seat: seat, other: other, start: start,
                                        inPlay: inPlay, parameters: p)
            })
        guard let found = TableOpponentSearch.search(s, spec: spec, depth: TableSearchDepth.of(s.level)) else {
            return fallback(s, cueBall: cueBall)
        }
        let t = found.trial
        if let ball = t.ownDrop {
            let route = OpponentPlan.CupRoute(rails: t.railsBeforeDrop, posts: t.postsBeforeDrop)
            return OpponentPlan(kind: .cup(ball: ball, marked: ball == BumperPoolRules.sides[seat][0], route: route),
                                stroke: t.stroke, placement: nil, call: nil, window: found.window)
        }
        return OpponentPlan(kind: .advance(ball: cueBall), stroke: t.stroke, placement: nil, call: nil, window: nil)
    }

    /// No search was possible: roll the struck ball gently straight at its own cup.
    private static func fallback(_ s: OpponentSnapshot, cueBall: Int) -> OpponentPlan {
        let seat = s.state.turn.index
        let holes = s.parameters.bedHoles
        var aim = 0.0
        if BumperPoolRules.targetHole.indices.contains(seat), holes.indices.contains(BumperPoolRules.targetHole[seat]),
           s.layout.indices.contains(cueBall), NextShot.isOnTable(s.layout[cueBall]) {
            let d = holes[BumperPoolRules.targetHole[seat]].center - s.layout[cueBall]
            aim = atan2(d.y, d.x) * 180 / Double.pi
        }
        return OpponentPlan(kind: .advance(ball: cueBall),
                            stroke: OpponentStroke(aimDegrees: aim, speed: fallbackSpeed, tipUp: tipUp),
                            placement: nil, call: nil, window: nil)
    }

    // MARK: The value

    /// The value of one solved stroke for seat `seat` against seat `other` (see the header). `start` is the layout
    /// the stroke was played from, `inPlay` the balls still in the game before it (MatchState.ballsLeft).
    static func value(ruling: Ruling, facts: ShotFacts, seat: Int, other: Int, start: [Vec2], inPlay: Set<Int>,
                      parameters p: PoolParameters) -> Double {
        if let r = ruling.result {
            return r.winner?.index == seat ? winValue : -winValue
        }
        var v = 0.0
        for d in facts.holeDrops where inPlay.contains(d.ball) {
            guard let side = BumperPoolRules.seat(of: d.ball), BumperPoolRules.targetHole.indices.contains(side),
                  d.hole == BumperPoolRules.targetHole[side] else { continue }
            if side == seat { v += cupValue } else if side == other { v -= cupValue }
        }
        if ruling.fouled { v += foulValue }
        let mine = nearness(facts.resting, side: seat, inPlay: inPlay, parameters: p)
            - nearness(start, side: seat, inPlay: inPlay, parameters: p)
        let theirs = nearness(facts.resting, side: other, inPlay: inPlay, parameters: p)
            - nearness(start, side: other, inPlay: inPlay, parameters: p)
        return v + positionWeight * (mine - theirs)
    }

    /// A side's nearness to its own cup in `layout`: the sum over its balls still in play and on the table of
    /// max(0, 1 - d / nearReach). A ball that dropped (or left the table) counts nothing: its cup points are counted
    /// above, and a ball that comes back is put on its start spot, far from its cup.
    static func nearness(_ layout: [Vec2], side: Int, inPlay: Set<Int>, parameters p: PoolParameters) -> Double {
        guard BumperPoolRules.sides.indices.contains(side), BumperPoolRules.targetHole.indices.contains(side),
              p.bedHoles.indices.contains(BumperPoolRules.targetHole[side]) else { return 0 }
        let cup = p.bedHoles[BumperPoolRules.targetHole[side]].center
        return BumperPoolRules.sides[side].reduce(0.0) { acc, b in
            guard inPlay.contains(b), layout.indices.contains(b), NextShot.isOnTable(layout[b]) else { return acc }
            return acc + max(0, 1 - (layout[b] - cup).length / nearReach)
        }
    }
}
