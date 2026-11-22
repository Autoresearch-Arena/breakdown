// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 table-opponent review: the aim window is now measured with
//          the planner's own success test on each refined trial (Spec.succeeds) instead of a bar on the value. The
//          value also carries position terms, so a cup shot of a ball that started near its cup scored below the cup's
//          10 once the ball's lost nearness was taken off, and every such shot reported no window at all; hard
//          five-pin's leave term did the same to its scoring strokes.)
// PURPOSE: The stroke search the computer uses on the tables without pockets to aim at: bumper pool and five-pin
//          (plans/22-Nov-2026-v074-glow-up-plan.md, feature R, table-opponent brief item 3). Pool's planner can list
//          its candidate shots by geometry (a ball, a pocket, a ghost ball); here the scoring shots are banks off
//          bumpers and caroms into pins, which geometry cannot list, so the computer tries strokes all round the
//          ball on the real solver and keeps what scores, the way a player learns a table by feel.
//          The search, in phases (TableOpponentSearch.search):
//            1. Fan: every aim round the ball at the planner's step, at each of its speeds and tips (TableFan), plus
//               any extra aims the planner adds (five-pin's fine aims across the other ball). Each stroke is solved
//               exactly like OpponentPlanner.trial (NextShot.shot from the struck ball, PoolSolver.simulate within
//               EightBallJudge.sweepEventBudget, ShotFacts, the rules' ruling) and given the planner's value.
//            2. Smooth: each row (one speed and tip) is averaged with a Gaussian as wide as the level's own aim noise,
//               so a stroke that only scores on a knife edge ranks below one whose neighbours score too.
//            3. Seeds: the best smoothed strokes, at least a degree apart, so the next phases look at several ideas.
//            4. Refine: round each seed, eleven aims a tenth of a degree apart at 0.85, 1 and 1.15 times its speed.
//            5. Noise check: the best few refined strokes are each struck several times with the level's own hand
//               (OpponentNoise), drawn from seeds mixed out of the snapshot's noiseSeed and never that seed itself
//               (that is the noise the real stroke will be dealt); the highest mean value wins.
//          Easy stops after the fan and plays its raw best (no smoothing, refining or noise check). Every phase is
//          capped by a count of solves, never by clock time, so a plan is the same on every device, and each phase
//          checks Task.isCancelled so an abandoned think stops early (MatchOpponent.cancel cancels the task).
//          Read by BumperPoolPlanner and FivePinPlanner, which supply the fan, the value and the success test, and
//          turn the result into an OpponentPlan. Nothing here runs on the main actor.
// SRP/DRY check: Pass - the solve-and-rule step repeats OpponentPlanner.trial's recipe on purpose but returns this
//          search's own reading (a value and the route counts), which that pool-shaped trial (keeps, safety, next
//          pot) cannot carry; the parallel runner, the stroke, the noise and its seed helpers are reused from
//          MatchOpponent.swift; the rails before the first contact are counted from the timeline because ShotFacts
//          only reads rails after it; post touches come from ShotFacts.postsTouched.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

/// One solved try of a stroke on bumper pool or five-pin, as the planner's value and the rules read it.
struct TableTrial: Equatable, Sendable {
    var stroke: OpponentStroke
    /// The planner's value of the result for the shooter (higher is better); TableOpponentSearch.jamValue for a jam.
    var value: Double
    /// The shooter's points less the other player's on this shot (five-pin); 0 on a game without points.
    var points: Double = 0
    /// The ruling and the reading; nil when the solve jammed.
    var ruling: Ruling?
    var facts: ShotFacts?
    /// Straight-rail touches by the struck ball before it first touched another ball (0 when it touched none).
    var railsBeforeFirstContact = 0
    /// The first of the shooter's own balls to drop in its own cup (TableOpponentSearch.OwnCup); nil when none did.
    var ownDrop: Int?
    /// Bumper and straight-rail touches by `ownDrop` before it dropped.
    var postsBeforeDrop = 0
    var railsBeforeDrop = 0
    /// The solve used up its event budget: scored as jamValue and never chosen over a real result.
    var jammed = false
}

/// The strokes the first phase tries: every aim from 0 up to 360 degrees at `step`, at each speed and tip, plus
/// `extraAims` (degrees, any range; spaced `extraStep` apart so they can be smoothed as their own row).
struct TableFan: Equatable, Sendable {
    var step: Double
    var speeds: [Double]
    var tips: [Double]
    var extraAims: [Double] = []
    var extraStep: Double = 0.1
}

/// How far a level takes the search beyond the fan (TableOpponentSearch's phases 2 to 5).
struct TableSearchDepth: Equatable, Sendable {
    /// False for easy: the fan's raw best is played.
    var smooths: Bool
    /// How many seeds are refined.
    var seedKeep: Int
    /// How many refined strokes get the noise check, and how many noisy strokes each.
    var noiseKeep: Int
    var noiseSamples: Int

    /// Easy plays the raw fan; medium refines six seeds and checks four with six noisy strokes each; hard refines
    /// eight and checks six with twelve each (the plan's budgets: about 2,000 solves for bumper pool at medium and
    /// 3,900 at hard, 3,300 and 6,500 for five-pin).
    static func of(_ level: ComputerLevel) -> TableSearchDepth {
        switch level {
        case .easy: return TableSearchDepth(smooths: false, seedKeep: 0, noiseKeep: 0, noiseSamples: 0)
        case .medium: return TableSearchDepth(smooths: true, seedKeep: 6, noiseKeep: 4, noiseSamples: 6)
        case .hard: return TableSearchDepth(smooths: true, seedKeep: 8, noiseKeep: 6, noiseSamples: 12)
        }
    }

    /// The tips a level's fan tries, given the table's own (`base`): hard tries the middle of the ball and the
    /// reference touch of draw (EightBallJudge.referenceTipUp, 7 mm below centre), the table's own first; easy and
    /// medium only the table's own.
    static func tips(_ level: ComputerLevel, base: Double) -> [Double] {
        guard level == .hard else { return [base] }
        let other = base == 0 ? EightBallJudge.referenceTipUp : 0
        return [base, other]
    }
}

enum TableOpponentSearch {
    /// The value of a solve that jammed (used up its event budget): worse than any foul, so it is never chosen, and
    /// it drags down the smoothed value of the strokes beside it.
    static let jamValue = -50.0
    /// Refining: eleven aims a tenth of a degree apart round a seed, at these multiples of its speed.
    static let refineStep = 0.1
    static let refineOffsets: [Double] = (-5...5).map { Double($0) * refineStep }
    static let refineSpeedFactors = [0.85, 1.0, 1.15]
    /// Seeds are kept at least this far apart in aim, degrees, so the refine looks at different ideas.
    static let seedSpacing = 1.0

    /// The shooter's balls and the bed hole they score in (bumper pool), for TableTrial's route counts.
    struct OwnCup: Equatable, Sendable {
        var balls: Set<Int>
        var hole: Int
    }

    /// The planner's value of one solved stroke for the shooter: higher is better.
    typealias Value = @Sendable (Ruling, ShotFacts) -> Double

    /// Whether one noise-free trial did what the stroke is for (a ball in its cup, a scoring stroke): the aim window
    /// counts the refined aims that pass. A test on the trial, not a bar on the value, because the value also carries
    /// position terms that can pull a real success below any fixed mark.
    typealias Success = @Sendable (TableTrial) -> Bool

    /// What a planner hands the search.
    struct Spec: Sendable {
        var fan: TableFan
        /// Bumper pool's own cup; nil on five-pin.
        var ownCup: OwnCup?
        var value: Value
        var succeeds: Success
    }

    /// The chosen stroke.
    struct Result: Equatable, Sendable {
        /// The chosen stroke's noise-free trial.
        var trial: TableTrial
        /// Its mean value over the noise check (its noise-free value when no noise check ran: easy, or cancelled).
        var expected: Double
        /// Its mean points (TableTrial.points) over the noise check, the same way.
        var expectedPoints: Double
        /// The width of the unbroken run of refined aims at the chosen speed and tip, round the chosen aim, whose
        /// noise-free trial passes the spec's success test; degrees. Nil when the chosen stroke itself does not pass or
        /// there was no refine.
        var window: Double?
        /// How many strokes were solved.
        var solves: Int
    }

    // MARK: One trial

    /// Solve one stroke from the snapshot's layout and read it, as OpponentPlanner.trial does for pool.
    static func trial(_ s: OpponentSnapshot, stroke: OpponentStroke, spec: Spec) -> TableTrial {
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        let input = NextShot.shot(from: s.layout, direction: stroke.direction, speed: stroke.speed, tipUp: stroke.tipUp,
                                  tipSide: stroke.tipSide, seed: 1, parameters: s.parameters, ballIndex: cueBall)
        guard let tl = PoolSolver.simulate(input, eventBudget: EightBallJudge.sweepEventBudget) else {
            return TableTrial(stroke: stroke, value: jamValue, jammed: true)
        }
        let facts = ShotFacts(timeline: tl, start: s.layout, cueBall: cueBall)
        let ruling = s.rules.ruling(for: facts, call: nil, in: s.state)
        var t = TableTrial(stroke: stroke, value: spec.value(ruling, facts), ruling: ruling, facts: facts)
        t.points = netPoints(ruling, state: s.state)
        if let t0 = facts.firstContactTime {
            t.railsBeforeFirstContact = railTouches(tl, ball: cueBall, before: t0)
        }
        if let cup = spec.ownCup,
           let drop = facts.holeDrops.first(where: { cup.balls.contains($0.ball) && $0.hole == cup.hole }) {
            t.ownDrop = drop.ball
            t.postsBeforeDrop = facts.postsTouched.filter { $0.ball == drop.ball && $0.time < drop.time }.count
            t.railsBeforeDrop = railTouches(tl, ball: drop.ball, before: drop.time)
        }
        return t
    }

    /// The shooter's points less the other seat's in a ruling; 0 when the game gives no points. Ruling.points is
    /// sized per game, so both seats are read by index.
    static func netPoints(_ r: Ruling, state: MatchState) -> Double {
        let mine = state.turn.index
        let theirs = state.turn.next(among: max(state.players.count, 1)).index
        let a = r.points.indices.contains(mine) ? r.points[mine] : 0
        let b = theirs != mine && r.points.indices.contains(theirs) ? r.points[theirs] : 0
        return Double(a - b)
    }

    /// Straight-rail cushion touches by `ball` before time `t` (posts, jaws and knuckles are not rails).
    static func railTouches(_ tl: Timeline, ball: Int, before t: Double) -> Int {
        tl.events.filter { e in
            e.kind == .cushion && e.edge == .rail && e.time < t && e.balls.first?.ball == ball
        }.count
    }

    // MARK: Noise samples

    /// Mix sample number `k` (1 and up) out of `seed`: one SplitMix step from the seed crossed with an odd constant
    /// times k, so neighbouring samples are unrelated and none is the seed itself.
    static func mix(_ seed: UInt64, _ k: Int) -> UInt64 {
        var r = OpponentRandom(seed: seed ^ (UInt64(truncatingIfNeeded: k) &* 0x9E6C_63D0_676A_9A99))
        return r.next()
    }

    /// The seeds of the noise check's `count` samples: mix(noiseSeed, k + 1) for k from 0. Never the noiseSeed
    /// itself (k + 1 is at least 1), which is the seed the real stroke's noise is drawn from.
    static func sampleSeeds(noiseSeed: UInt64, count: Int) -> [UInt64] {
        (0..<max(count, 0)).map { mix(noiseSeed, $0 + 1) }
    }

    // MARK: Smoothing

    /// The smoothing weights for a row whose aims are `step` apart, for an aim noise of `sigma` degrees: when the
    /// noise is finer than the step, a quarter, a half and a quarter over the neighbours (the row cannot resolve it
    /// any better); otherwise a Gaussian out to three sigma.
    static func kernel(sigma: Double, step: Double) -> [Double] {
        guard step > 0, sigma > 0 else { return [1] }
        if sigma < step { return [0.25, 0.5, 0.25] }
        let reach = Int((3 * sigma / step).rounded(.up))
        return (-reach...reach).map { k in
            let x = Double(k) * step / sigma
            return exp(-0.5 * x * x)
        }
    }

    /// `values` averaged with the centred weights `w`. A circular row (the fan's full turn) wraps at the seam, so
    /// 359 and 0 degrees are neighbours like any other two; a straight row (fine aims, a refine) renormalises the
    /// weights that fall inside it at its ends.
    static func smooth(_ values: [Double], kernel w: [Double], circular: Bool) -> [Double] {
        let n = values.count
        guard n > 0, w.count > 1 else { return values }
        let reach = w.count / 2
        return (0..<n).map { i in
            var sum = 0.0, weight = 0.0
            for (k, wk) in w.enumerated() {
                var j = i + k - reach
                if circular {
                    j = ((j % n) + n) % n
                } else if j < 0 || j >= n {
                    continue
                }
                sum += wk * values[j]
                weight += wk
            }
            return weight > 0 ? sum / weight : values[i]
        }
    }

    // MARK: Ordering

    /// An aim in 0 up to 360 degrees.
    static func normalized(_ a: Double) -> Double {
        let m = a.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }

    /// The angle between two aims, 0 to 180 degrees.
    static func gap(_ a: Double, _ b: Double) -> Double {
        let d = abs(normalized(a) - normalized(b))
        return min(d, 360 - d)
    }

    /// The search's one ordering, so every choice is the same on every run: the higher value first, then the lower
    /// aim (0 to 360), the lower speed, the tip nearer the middle of the ball, and last the lower index (two strokes
    /// can only tie on all of these when an extra aim lands exactly on a fan aim).
    static func ranksBefore(_ va: Double, _ a: OpponentStroke, _ ia: Int,
                            _ vb: Double, _ b: OpponentStroke, _ ib: Int) -> Bool {
        if va != vb { return va > vb }
        let aa = normalized(a.aimDegrees), ab = normalized(b.aimDegrees)
        if aa != ab { return aa < ab }
        if a.speed != b.speed { return a.speed < b.speed }
        if a.tipUp != b.tipUp { return abs(a.tipUp) < abs(b.tipUp) }
        return ia < ib
    }

    /// The index of the best of `values` by ranksBefore; nil when empty.
    private static func best(_ values: [Double], _ strokes: [OpponentStroke]) -> Int? {
        var b: Int?
        for i in values.indices {
            guard let cur = b else { b = i; continue }
            if ranksBefore(values[i], strokes[i], i, values[cur], strokes[cur], cur) { b = i }
        }
        return b
    }

    /// A result with no noise check: the trial's own value and points stand for the means.
    private static func plain(_ t: TableTrial, window: Double?, solves: Int) -> Result {
        Result(trial: t, expected: t.value, expectedPoints: t.points, window: window, solves: solves)
    }

    // MARK: The search

    /// The stroke to play from the snapshot, by the phases in the header. Nil when the struck ball is not on the
    /// table or the fan is empty (the planner then falls back to a plain stroke).
    static func search(_ s: OpponentSnapshot, spec: Spec, depth: TableSearchDepth) -> Result? {
        let cueBall = s.rules.cueBall(for: s.state.turn, in: s.state)
        guard s.layout.indices.contains(cueBall), NextShot.isOnTable(s.layout[cueBall]) else { return nil }
        let fan = spec.fan
        guard fan.step > 0, !fan.speeds.isEmpty, !fan.tips.isEmpty else { return nil }

        // 1. The fan. Rows are every tip and speed (tips outer); within a row, the full-turn aims, then the extras.
        let gridCount = max(1, Int((360 / fan.step).rounded()))
        let extra = fan.extraAims.map(normalized)
        let aims = (0..<gridCount).map { Double($0) * fan.step } + extra
        var rowList: [(tip: Double, speed: Double)] = []
        for tip in fan.tips { for v in fan.speeds { rowList.append((tip, v)) } }
        var fanList: [OpponentStroke] = []
        for row in rowList {
            for a in aims { fanList.append(OpponentStroke(aimDegrees: a, speed: row.speed, tipUp: row.tip)) }
        }
        let fanStrokes = fanList
        let fanTrials = OpponentPlanner.parallel(fanStrokes.count) { trial(s, stroke: fanStrokes[$0], spec: spec) }
        var solves = fanStrokes.count
        let fanValues = fanTrials.map(\.value)

        // Easy plays the raw best; a cancelled think returns the same so the caller always has a stroke.
        if !depth.smooths || depth.seedKeep <= 0 || Task.isCancelled {
            guard let b = best(fanValues, fanStrokes) else { return nil }
            return plain(fanTrials[b], window: nil, solves: solves)
        }

        // 2. Smooth each row with the level's own aim noise (scaled for this game like the hand itself).
        let sigma = s.level.aimNoiseDegrees * OpponentNoise.tableScale(s.rules.kind)
        let gridKernel = kernel(sigma: sigma, step: fan.step)
        let extraKernel = kernel(sigma: sigma, step: fan.extraStep)
        var smoothed = fanValues
        for r in rowList.indices {
            let base = r * aims.count
            let g = smooth(Array(fanValues[base..<(base + gridCount)]), kernel: gridKernel, circular: true)
            for j in g.indices { smoothed[base + j] = g[j] }
            if !extra.isEmpty {
                let lo = base + gridCount
                let e = smooth(Array(fanValues[lo..<(lo + extra.count)]), kernel: extraKernel, circular: false)
                for j in e.indices { smoothed[lo + j] = e[j] }
            }
        }

        // 3. Seeds: the best smoothed strokes, each at least seedSpacing from every seed already taken.
        let order = fanStrokes.indices.sorted {
            ranksBefore(smoothed[$0], fanStrokes[$0], $0, smoothed[$1], fanStrokes[$1], $1)
        }
        var seeds: [Int] = []
        for i in order where seeds.count < depth.seedKeep {
            let aim = fanStrokes[i].aimDegrees
            if seeds.allSatisfy({ gap(fanStrokes[$0].aimDegrees, aim) >= seedSpacing }) { seeds.append(i) }
        }
        guard !seeds.isEmpty, !Task.isCancelled else {
            guard let b = best(smoothed, fanStrokes) else { return nil }
            return plain(fanTrials[b], window: nil, solves: solves)
        }

        // 4. Refine round each seed: refineSpeedFactors rows of refineOffsets aims, at the seed's tip.
        let speedRange = PlayerShotSpeed.ordinary
        let cols = refineOffsets.count, rowsPerSeed = refineSpeedFactors.count, block = cols * rowsPerSeed
        var refineList: [OpponentStroke] = []
        for i in seeds {
            let c = fanStrokes[i]
            for f in refineSpeedFactors {
                let v = min(max(c.speed * f, speedRange.lowerBound), speedRange.upperBound)
                for off in refineOffsets {
                    refineList.append(OpponentStroke(aimDegrees: normalized(c.aimDegrees + off), speed: v,
                                                     tipUp: c.tipUp))
                }
            }
        }
        let refineStrokes = refineList
        let refineTrials = OpponentPlanner.parallel(refineStrokes.count) {
            trial(s, stroke: refineStrokes[$0], spec: spec)
        }
        solves += refineStrokes.count
        let refineValues = refineTrials.map(\.value)

        // Each seed's best refined stroke by its smoothed row (one candidate per seed keeps the ideas apart).
        let fineKernel = kernel(sigma: sigma, step: refineStep)
        var refinedSmooth = refineValues
        for start in stride(from: 0, to: refineValues.count, by: cols) {
            let row = smooth(Array(refineValues[start..<(start + cols)]), kernel: fineKernel, circular: false)
            for j in row.indices { refinedSmooth[start + j] = row[j] }
        }
        var candidates: [Int] = []
        for k in seeds.indices {
            let lo = k * block
            let idx = Array(lo..<(lo + block))
            if let b = best(idx.map { refinedSmooth[$0] }, idx.map { refineStrokes[$0] }) { candidates.append(lo + b) }
        }
        candidates.sort {
            ranksBefore(refinedSmooth[$0], refineStrokes[$0], $0, refinedSmooth[$1], refineStrokes[$1], $1)
        }
        let picked = Array(candidates.prefix(max(depth.noiseKeep, 1)))
        guard let top = picked.first else { return nil }
        if depth.noiseKeep <= 0 || depth.noiseSamples <= 0 || Task.isCancelled {
            return plain(refineTrials[top], window: window(top, refineTrials, spec.succeeds, cols: cols),
                         solves: solves)
        }

        // 5. The noise check: each picked stroke struck noiseSamples times by the level's hand, from seeds mixed out
        // of the snapshot's noiseSeed (never the seed the real stroke will use).
        let noises = sampleSeeds(noiseSeed: s.noiseSeed, count: depth.noiseSamples).map {
            OpponentNoise.draw(level: s.level, seed: $0, kind: s.rules.kind)
        }
        let tipLimit = s.parameters.miscueOffsetLimit
        var noisyList: [OpponentStroke] = []
        for c in picked {
            for n in noises { noisyList.append(refineStrokes[c].with(n, speeds: speedRange, tipLimit: tipLimit)) }
        }
        let noisyStrokes = noisyList
        let noisyTrials = OpponentPlanner.parallel(noisyStrokes.count) {
            trial(s, stroke: noisyStrokes[$0], spec: spec)
        }
        solves += noisyStrokes.count
        let m = Double(noises.count)
        var meanValues: [Double] = [], meanPoints: [Double] = []
        for k in picked.indices {
            let slice = noisyTrials[(k * noises.count)..<((k + 1) * noises.count)]
            meanValues.append(slice.reduce(0.0) { $0 + $1.value } / m)
            meanPoints.append(slice.reduce(0.0) { $0 + $1.points } / m)
        }
        // The highest mean wins; ties go to the lower aim, then the lower speed (ranksBefore on the means).
        guard let w = best(meanValues, picked.map { refineStrokes[$0] }) else { return nil }
        let chosen = picked[w]
        return Result(trial: refineTrials[chosen], expected: meanValues[w], expectedPoints: meanPoints[w],
                      window: window(chosen, refineTrials, spec.succeeds, cols: cols), solves: solves)
    }

    /// The aim window of refined stroke `i`: the unbroken run of its row (same seed, speed and tip) round it whose
    /// noise-free trial passes `succeeds`, each aim standing for one refineStep slice. Nil when `i` itself does not
    /// pass.
    private static func window(_ i: Int, _ trials: [TableTrial], _ succeeds: Success, cols: Int) -> Double? {
        guard trials.indices.contains(i), cols > 0, succeeds(trials[i]) else { return nil }
        let rowStart = (i / cols) * cols, rowEnd = rowStart + cols - 1
        var lo = i, hi = i
        while lo > rowStart && succeeds(trials[lo - 1]) { lo -= 1 }
        while hi < rowEnd && succeeds(trials[hi + 1]) { hi += 1 }
        return Double(hi - lo + 1) * refineStep
    }
}
