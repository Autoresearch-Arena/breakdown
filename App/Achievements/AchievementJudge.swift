// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: AchievementProgress carries the shot of the day's best
//          streak and whether a day was made on its first try, and earns the three daily achievements from them.)
// PURPOSE: Which achievements a recorded shot earns, and which collections the stored progress completes
//          (plans/23-Nov-2026-achievements-plan.md, new file 4). Pure: no model, no UserDefaults, safe in tests.
//          - AchievementJudge.shotAchievements reads one shot: ShotHighlightJudge.detect once (its moments map onto the
//            shot achievements, so a shot is never remarkable in one place and not the other), then the new checks read
//            the recording's own events: the cue ball over another ball in the air ("Over the top"), a carom, a ball in
//            off a pocket's jaw, a ball rattled out of one pocket's jaws, and a big break. A break is read only for the
//            big break: the rack's scatter would otherwise read as caroms and jaw touches on every break.
//          - RunTracker follows free play's pool rack from a clean break to an empty table (run-rack).
//          - AchievementProgress is the progress the game already keeps (lessons passed, trick shots made, medals,
//            levels beaten, tables and surfaces played), and says which collection achievements it completes and how far
//            along each is.
//          Earning never depends on a signature: an empty one only means the replay holds the ordinary beats.
//          Read by AchievementBook (every shot, every sweep) and the tests (AchievementJudgeTests).
// SRP/DRY check: Pass - checked ShotHighlightJudge and ShotMoments (detect and the event finders are reused; ShotMoments'
//          private readers are not reachable, so the jaw and drop scans read timeline.events directly rather than adding
//          helpers to that file, which this feature does not touch), ShotFacts (the scratch and resting places) and
//          MatchRecord (the levels beaten are read from its tally by the book). Nothing here is stored.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

/// Everything one shot's reading needs.
struct AchievementShotContext {
    let timeline: Timeline
    let facts: ShotFacts
    let captions: [Caption]
    /// The table the shot was solved on.
    let table: TableKind
    let isBreak: Bool
    /// Free play: no match, no authored mode (trick shot, lesson, Behind the 8-Ball), no drill. Run the rack is a free
    /// play achievement.
    let freePlay: Bool
    /// The attempt as recorded (its start, its striking ball, what it was solved on).
    let attempt: ShotAttempt
}

enum AchievementJudge {
    /// Samples across the cue ball's flight when looking for a ball under it: at least sixty, and about one every two
    /// milliseconds of a longer flight (a jump on the Moon flies several times longer), so a ball the cue ball passes
    /// straight over is never stepped across. A cue ball at jump speed moves well under one ball radius in that time.
    static let flightSamplesMinimum = 60
    static let flightSamplesPerSecond = 500.0
    static let flightSamplesMaximum = 4000

    // MARK: One shot

    /// The shot achievements this shot earns, in catalogue order, each once, with the events its replay holds on.
    static func shotAchievements(_ c: AchievementShotContext) -> [(id: String, signature: [Int])] {
        let tl = c.timeline
        let m = ShotMoments(timeline: tl, captions: c.captions)
        let cue = c.facts.cueBall
        var found: [String: [Int]] = [:]

        if c.isBreak {
            // A break is a break and nothing else (ShotHighlightJudge reads it the same way).
            if let s = bigBreak(m, tl, cue: cue, table: c.table) { found["big-break"] = s }
        } else {
            for h in ShotHighlightJudge.detect(timeline: tl, facts: c.facts, captions: c.captions, table: c.table,
                                               isBreak: false) {
                if h.kind == .jump {
                    // A jump counts only when the cue ball really went over a ball, not for any hop.
                    if found["jump-clear"] == nil, clearsBall(m, tl, cue: cue, start: c.attempt.start) {
                        found["jump-clear"] = h.signatureEvents
                    }
                    continue
                }
                guard let id = Achievements.shotID(for: h.kind), found[id] == nil else { continue }
                found[id] = h.signatureEvents
            }
            if let s = carom(m, cue: cue) { found["carom"] = s }
            if let s = jawIn(m, tl) { found["jaw-in"] = s }
            if let s = rattleOut(m, tl) { found["rattle-out"] = s }
        }
        return Achievements.shotIDs.compactMap { id in found[id].map { (id: id, signature: $0) } }
    }

    /// True when the struck ball, in the air between its first real take-off (ShotHighlightJudge.jumpSpeed) and its
    /// landing (or the recording's end), passed over another ball: at some sampled moment it was off the cloth while a
    /// ball that started on the table, and was not yet pocketed, sat within one ball radius of it across the cloth.
    /// One radius is a first guess the jump-over trick's test proves on the real answer; if that test ever fails,
    /// widen it to 1.5 radii here and say so.
    static func clearsBall(_ m: ShotMoments, _ tl: Timeline, cue: Int, start: [Vec2]) -> Bool {
        guard let up = m.takeOff(of: cue, minimumUp: ShotHighlightJudge.jumpSpeed) else { return false }
        let t0 = tl.events[up].time
        let t1 = m.landing(of: cue, after: up).map { tl.events[$0].time } ?? tl.duration
        guard t1 > t0 else { return false }
        let r = tl.table.ballRadius
        let others = (0..<min(start.count, tl.ballCount)).filter { $0 != cue && NextShot.isOnTable(start[$0]) }
        guard !others.isEmpty else { return false }
        let n = min(flightSamplesMaximum, max(flightSamplesMinimum, Int(((t1 - t0) * flightSamplesPerSecond).rounded(.up))))
        for k in 0...n {
            let t = t0 + (t1 - t0) * Double(k) / Double(n)
            let me = tl.state(ball: cue, at: t)
            guard me.height > 0 else { continue }
            for b in others {
                let other = tl.state(ball: b, at: t)
                if !other.pocketed, (other.position - me.position).length <= r { return true }
            }
        }
        return false
    }

    /// A carom: the struck ball met one ball, then a different one, and that second ball dropped at or after the
    /// second contact. Holds the two contacts.
    static func carom(_ m: ShotMoments, cue: Int) -> [Int]? {
        guard let first = m.firstContact(of: cue), let second = m.secondContact(of: cue),
              let a = m.other(in: first, than: cue), let b = m.other(in: second, than: cue), a != b,
              let drop = m.pocket(of: b), m.time(drop) >= m.time(second) - ShotMoments.instant else { return nil }
        return m.signature([first, second])
    }

    /// True for a touch of a pocket's jaw or knuckle (the sides and points of its mouth).
    private static func isJawTouch(_ e: LensEvent) -> Bool {
        e.kind == .cushion && (e.edge == .jaw || e.edge == .knuckle)
    }

    /// In off the jaw: a ball touched the jaw or point of the pocket it dropped into, after its last ball contact
    /// (or from the start) and before the drop. Holds the touch and the drop. The first ball that qualifies.
    static func jawIn(_ m: ShotMoments, _ tl: Timeline) -> [Int]? {
        let events = tl.events
        for drop in m.pockets() {
            guard let ball = events[drop].balls.first?.ball else { continue }
            let pocket = events[drop].pocket
            let after = m.lastContact(of: ball, atOrBefore: events[drop].time) ?? -1
            for i in events.indices where i > after && i < drop {
                let e = events[i]
                if isJawTouch(e), e.balls.first?.ball == ball, e.pocket == pocket {
                    return m.signature([i, drop])
                }
            }
        }
        return nil
    }

    /// Rattled out: a ball touched one pocket's jaws or points twice or more after its last ball contact and never
    /// dropped. Holds the first two touches. The first ball that qualifies, in the order of its first such touch.
    static func rattleOut(_ m: ShotMoments, _ tl: Timeline) -> [Int]? {
        let events = tl.events
        var checked = Set<Int>()
        for i in events.indices where isJawTouch(events[i]) {
            guard let ball = events[i].balls.first?.ball, !checked.contains(ball) else { continue }
            checked.insert(ball)
            guard m.pocket(of: ball) == nil else { continue }
            let after = m.lastContact(of: ball, atOrBefore: .infinity) ?? -1
            // Touches after the last contact, grouped by pocket, in clock order.
            var byPocket: [Int: [Int]] = [:]
            for j in events.indices where j > after && isJawTouch(events[j]) && events[j].balls.first?.ball == ball {
                byPocket[events[j].pocket, default: []].append(j)
            }
            // The pocket whose second touch came first.
            let rattles = byPocket.values.filter { $0.count >= 2 }.sorted { $0[1] < $1[1] }
            if let touches = rattles.first { return m.signature([touches[0], touches[1]]) }
        }
        return nil
    }

    /// A big break: a break on the pool table that sent three or more object balls down. Holds the first two drops.
    static func bigBreak(_ m: ShotMoments, _ tl: Timeline, cue: Int, table: TableKind) -> [Int]? {
        guard table == .standard else { return nil }
        let drops = m.pockets().filter { tl.events[$0].balls.first?.ball != cue }
        let balls = Set(drops.compactMap { tl.events[$0].balls.first?.ball })
        guard balls.count >= 3 else { return nil }
        return m.signature([drops.first, drops.dropFirst().first])
    }
}

// MARK: Running the rack

/// Follows free play's pool rack shot by shot: a break that drops a ball without a scratch starts a run, every later
/// shot that drops one without a scratch keeps it, anything else ends it, and a run that leaves no object ball on the
/// table earns run-rack. Not stored: a run is one sitting's.
struct RunTracker: Equatable {
    private(set) var running = false

    /// Note one shot; true when this shot finished a run. `poolRack` is free play on the pool table.
    mutating func note(isBreak: Bool, poolRack: Bool, dropped: Int, scratched: Bool, objectBallsLeft: Int) -> Bool {
        let clean = poolRack && dropped > 0 && !scratched
        if isBreak {
            running = clean
        } else if running {
            running = clean
        }
        guard running, objectBallsLeft == 0 else { return false }
        running = false
        return true
    }
}

// MARK: Collections

/// One item of a collection's progress picture: a lesson, a trick shot, a situation, a level, a table or a surface.
struct AchievementProgressItem: Identifiable, Equatable {
    let id: String
    /// Already translated.
    let name: String
    /// SF Symbol for tables and surfaces (their own); nil for the rest.
    let symbol: String?
    let done: Bool
}

/// The progress the game already keeps, gathered in one value.
struct AchievementProgress: Equatable {
    var lessonsDone: Set<String> = []
    var tricksDone: Set<String> = []
    /// Behind the 8-Ball situation ids with a medal.
    var escapesWon: Set<String> = []
    /// ComputerLevel raw values with at least one game won against the computer.
    var levelsBeaten: Set<String> = []
    /// TableKind and PlaySurface raw values a shot was struck on.
    var tablesPlayed: Set<String> = []
    var surfacesPlayed: Set<String> = []
    // 0.7.10 daily: the shot of the day's longest streak and whether any day was made on its first try (DailyRecord).
    var dailyBestStreak = 0
    var dailyFirstTry = false

    /// Every collection achievement this progress has earned. Counts come from the content lists, never written in.
    static func earned(_ p: AchievementProgress) -> Set<String> {
        var out = Set<String>()
        for lesson in Lessons.all where p.lessonsDone.contains(lesson.id) {
            out.insert(Achievements.lessonAchievementID(lesson.id))
        }
        if !Lessons.all.isEmpty, Lessons.all.allSatisfy({ p.lessonsDone.contains($0.id) }) {
            out.insert(Achievements.everyLesson)
        }
        let playable = Achievements.playableTricks
        for trick in playable where p.tricksDone.contains(trick.id) {
            out.insert(Achievements.trickAchievementID(trick.id))
        }
        if !playable.isEmpty, playable.allSatisfy({ p.tricksDone.contains($0.id) }) {
            out.insert(Achievements.everyTrick)
        }
        if !EightBallSituations.all.isEmpty, EightBallSituations.all.allSatisfy({ p.escapesWon.contains($0.id) }) {
            out.insert(Achievements.everyEscape)
        }
        for level in ComputerLevel.allCases where p.levelsBeaten.contains(level.rawValue) {
            out.insert(Achievements.levelAchievementID(level))
        }
        if TableKind.allCases.allSatisfy({ p.tablesPlayed.contains($0.rawValue) }) {
            out.insert(Achievements.everyTable)
        }
        if PlaySurface.allCases.allSatisfy({ p.surfacesPlayed.contains($0.rawValue) }) {
            out.insert(Achievements.everySurface)
        }
        // 0.7.10 daily: the shot of the day's streaks and first-try make.
        if p.dailyBestStreak >= Achievements.dailyWeekDays { out.insert(Achievements.dailyStreakWeek) }
        if p.dailyBestStreak >= Achievements.dailyMonthDays { out.insert(Achievements.dailyStreakMonth) }
        if p.dailyFirstTry { out.insert(Achievements.dailyFirstTry) }
        return out
    }

    /// The items of a collection's picture, in the content's own order.
    func items(_ kind: AchievementProgressKind) -> [AchievementProgressItem] {
        switch kind {
        case .none:
            return []
        case .lessons:
            return Lessons.all.map {
                AchievementProgressItem(id: $0.id, name: $0.title, symbol: nil, done: lessonsDone.contains($0.id))
            }
        case .tricks:
            return Achievements.playableTricks.map {
                AchievementProgressItem(id: $0.id, name: $0.title, symbol: nil, done: tricksDone.contains($0.id))
            }
        case .escapes:
            return EightBallSituations.all.map {
                AchievementProgressItem(id: $0.id, name: $0.title, symbol: nil, done: escapesWon.contains($0.id))
            }
        case .levels:
            return ComputerLevel.allCases.map {
                AchievementProgressItem(id: $0.rawValue, name: $0.title, symbol: nil,
                                        done: levelsBeaten.contains($0.rawValue))
            }
        case .tables:
            return TableKind.allCases.map {
                AchievementProgressItem(id: $0.rawValue, name: $0.title, symbol: $0.symbol,
                                        done: tablesPlayed.contains($0.rawValue))
            }
        case .surfaces:
            return PlaySurface.allCases.map {
                AchievementProgressItem(id: $0.rawValue, name: $0.title, symbol: $0.symbol,
                                        done: surfacesPlayed.contains($0.rawValue))
            }
        }
    }

    /// How far along a collection is, for "4 of 6" and the pictures.
    func count(_ kind: AchievementProgressKind) -> (done: Int, total: Int) {
        let all = items(kind)
        return (all.filter(\.done).count, all.count)
    }
}
