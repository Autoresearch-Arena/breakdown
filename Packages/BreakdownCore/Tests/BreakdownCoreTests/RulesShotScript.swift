// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Hand-built shots for the match rules tests (EightBallRulesTests, NineBallRulesTests). A ShotScript says
//          in a few words what happened in a shot (the first ball the cue ball touched, a ball touched at the same
//          instant, balls driven to a rail, balls pocketed and where, balls off the table) and writes the small
//          recording that says exactly that, then reads it with the real ShotFacts, so the rules are tested on the
//          same reading the app gives them and no solver is involved. Recording rules that matter:
//            - a pocketed or off-table ball has its pocketTime set, or ShotFacts.resting would keep it on the table
//              and MatchRules.applying would leave it in ballsLeft;
//            - a ball driven to a rail moves before its cushion event (ShotFacts ignores a ball pushed into a rail
//              it was frozen against);
//            - events come after the first contact, which is at 0.2 s.
// SRP/DRY check: Pass - ShotFactsTests and MatchContractTests keep their own builders private to their classes and
//          test the reading itself; this one is shared by the two rules test files only.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline

struct ShotScript {
    static let radius = 0.028575

    /// Every ball of `onTable` (the cue ball always) at its own spread-out spot; the rest parked off the table.
    static func layout(onTable: [Int] = Array(1...15)) -> [Vec2] {
        (0..<16).map { b in
            b == 0 || onTable.contains(b) ? Vec2(0.2 + 0.13 * Double(b), 0.6) : ShotFacts.offTable
        }
    }

    var start: [Vec2] = ShotScript.layout()
    var cueBall = 0
    /// The first ball the cue ball touched (nil: it touched nothing).
    var firstHit: Int?
    /// A second ball touched 5 microseconds later, inside ShotFacts.sameInstant (a tie).
    var tieWith: Int?
    /// Balls that moved and then reached a straight rail after the first contact.
    var toRail: [Int] = []
    /// Balls pocketed, in order, with the pocket index (EightBallPocket raw values).
    var pocketed: [(ball: Int, pocket: Int)] = []
    /// Balls that flew off the table.
    var offTable: [Int] = []

    init(start: [Vec2] = ShotScript.layout(), firstHit: Int? = nil, tieWith: Int? = nil, toRail: [Int] = [],
         pocketed: [(ball: Int, pocket: Int)] = [], offTable: [Int] = []) {
        self.start = start; self.firstHit = firstHit; self.tieWith = tieWith; self.toRail = toRail
        self.pocketed = pocketed; self.offTable = offTable
    }

    private func still(_ p: Vec2, from t0: Double = 0, to t1: Double = .infinity) -> BallSegment {
        BallSegment(t0: t0, t1: t1, phase: .stationary, position0: p, velocity0: .zero, acceleration: .zero,
                    omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: ShotScript.radius, orientation0: .identity)
    }

    private func ball(_ b: Int) -> ImpactBall {
        ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: Vec2(0.5, 0), omegaBefore: .zero,
                   omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0.02,
                   rotationalAfter: 0)
    }

    /// The recording, read with ShotFacts.
    func facts() -> ShotFacts {
        var segments = start.map { [still($0)] }
        var events: [LensEvent] = []
        var pocketTime = [Double?](repeating: nil, count: start.count)
        if let b = firstHit {
            events.append(LensEvent(time: 0.2, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                                    balls: [ball(cueBall), ball(b)]))
        }
        if let b = tieWith {
            events.append(LensEvent(time: 0.2 + 5e-6, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                                    balls: [ball(cueBall), ball(b)]))
        }
        for b in toRail {
            // Moves a tenth of a metre at 0.3 s, then meets the rail at 0.35 s.
            let moved = start[b] + Vec2(0, 0.1)
            segments[b] = [still(start[b], to: 0.3), still(moved, from: 0.3)]
            events.append(LensEvent(time: 0.35, kind: .cushion, point: moved, normal: Vec2(0, -1), balls: [ball(b)],
                                    edge: .rail))
        }
        for (k, d) in pocketed.enumerated() {
            let t = 0.5 + 0.1 * Double(k)
            events.append(LensEvent(time: t, kind: .pocket, point: start[d.ball], normal: Vec2(1, 0),
                                    balls: [ball(d.ball)], pocket: d.pocket))
            pocketTime[d.ball] = t
        }
        for (k, b) in offTable.enumerated() {
            let t = 1.5 + 0.1 * Double(k)
            events.append(LensEvent(time: t, kind: .phaseTransition, point: .zero, normal: Vec2(0, -1),
                                    balls: [ball(b)], phaseFrom: .airborne, phaseTo: .stationary, flight: .offTable))
            pocketTime[b] = t
        }
        events.sort { $0.time < $1.time }
        let spec = TableSpec(length: 2.54, width: 1.27, ballRadius: ShotScript.radius, pockets: [],
                             pocketCaptureRadius: [])
        let tl = Timeline(table: spec, seed: 1, parameterHash: 1, segments: segments, events: events,
                          pocketTime: pocketTime, duration: (events.last?.time ?? 0) + 0.5)
        return ShotFacts(timeline: tl, start: start, cueBall: cueBall)
    }
}

/// Plays a ruling into a state the way the app does: the ruling, then MatchRules' shared bookkeeping.
func playShot(_ rules: some MatchRules, _ shot: ShotScript, call: EightBallCall? = nil,
          in state: MatchState) -> (ruling: Ruling, state: MatchState) {
    let f = shot.facts()
    let r = rules.ruling(for: f, call: call, in: state)
    return (r, rules.applying(r, facts: f, to: state))
}

/// The start layout with only the given object balls still standing (for scripting a game's later shots).
func onlyStanding(_ balls: [Int]) -> [Vec2] { ShotScript.layout(onTable: balls) }
