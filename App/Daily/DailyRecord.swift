// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: What the player has done with the shot of the day (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1 item
//          6), saved on the device as one small value under one UserDefaults key, "dailyRecord", the way
//          AchievementRecord does it (JSON, every field optional on reading, a record that cannot be read logged and
//          replaced by an empty one, never fatal). For each day played: the shot's id, the tries used, the try that made
//          it (none for a miss), the white ball's distance from the mark on that try, the score, and whether the score
//          has been sent to the board (stage 3 sets it). Kept for every day, a few dozen bytes each.
//          The streak is worked out from the days, never counted by hand: days in a row with a make, ending today if
//          today is made, otherwise ending yesterday while today is still open (no try yet, or tries left). A missed day
//          (not played, or five misses) ends it. The best streak is kept as well, so it survives any later trimming.
//          Read and written by DailyMode; read by DailyMenuRow (the menu's mark), DailyViews, DailyShare, AchievementBook
//          (the streak and first-try achievements, through AchievementProgress) and the tests (DailyRecordTests).
// SRP/DRY check: Pass - storage and the streak only; the score is DailyScore's, the day number DailyBank's, judging
//          TrickShotJudge's. Follows AchievementRecord's save pattern rather than inventing another.
import Foundation

struct DailyRecord: Codable, Equatable {
    static let storageKey = "dailyRecord"
    /// Tries a player has at each day's shot.
    static let maxTries = 5

    /// One day's play.
    struct Day: Codable, Equatable {
        /// DailyBank's day number.
        var day: Int
        /// The bank entry played (AuthoredDailyShot.id), so a later bank change cannot rewrite what was played.
        var shotID: String
        /// Tries used, 0 to 5.
        var tries: Int
        /// The try that made it (1 to 5); nil while not made.
        var madeOnTry: Int?
        /// Metres from the mark to where the white ball stopped on the try that made it; nil without a make, or when no
        /// mark could be measured.
        var distance: Double?
        /// The day's score (DailyScore); 0 without a make.
        var score: Int
        /// The score has been posted to the board (stage 3, Game Center). False until then.
        var sent: Bool

        init(day: Int, shotID: String, tries: Int = 0, madeOnTry: Int? = nil, distance: Double? = nil, score: Int = 0,
             sent: Bool = false) {
            self.day = day; self.shotID = shotID; self.tries = tries; self.madeOnTry = madeOnTry
            self.distance = distance; self.score = score; self.sent = sent
        }

        var made: Bool { madeOnTry != nil }
        /// Made, or all five tries used: nothing more to play that day.
        var finished: Bool { made || tries >= DailyRecord.maxTries }
        var triesLeft: Int { finished ? 0 : max(0, DailyRecord.maxTries - tries) }

        private enum CodingKeys: String, CodingKey { case day, shotID, tries, madeOnTry, distance, score, sent }

        /// Lenient, as AchievementRecord's: a field another build did not write reads as its plain default.
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            day = try c.decode(Int.self, forKey: .day)
            shotID = (try? c.decodeIfPresent(String.self, forKey: .shotID)) ?? ""
            tries = (try? c.decodeIfPresent(Int.self, forKey: .tries)) ?? 0
            madeOnTry = try? c.decodeIfPresent(Int.self, forKey: .madeOnTry)
            distance = try? c.decodeIfPresent(Double.self, forKey: .distance)
            score = (try? c.decodeIfPresent(Int.self, forKey: .score)) ?? 0
            sent = (try? c.decodeIfPresent(Bool.self, forKey: .sent)) ?? false
        }
    }

    /// Every day played, oldest first, one entry per day number.
    var days: [Day] = []
    /// The longest streak ever reached.
    var bestStreak = 0

    init() {}

    private enum CodingKeys: String, CodingKey { case days, bestStreak }

    /// Every field optional on reading, so a record written by another build loads instead of failing.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        days = (try? c.decodeIfPresent([Day].self, forKey: .days)) ?? []
        bestStreak = (try? c.decodeIfPresent(Int.self, forKey: .bestStreak)) ?? 0
    }

    // MARK: Reading

    /// One day's play, or nil when that day was never played.
    func day(_ number: Int) -> Day? { days.first { $0.day == number } }

    /// Days in a row with a make, as of day `today`: counted back from today when today is made, from yesterday while
    /// today is still open, and 0 once today is lost (five misses). A day missing from the record breaks the run.
    func streak(asOf today: Int) -> Int {
        var d: Int
        if let t = day(today), t.made {
            d = today
        } else if let t = day(today), t.finished {
            return 0
        } else {
            d = today - 1
        }
        let made = Set(days.filter(\.made).map(\.day))
        var run = 0
        while made.contains(d) { run += 1; d -= 1 }
        return run
    }

    /// The longest run of made days anywhere in the record.
    var longestRun: Int {
        let made = days.filter(\.made).map(\.day).sorted()
        var best = 0, run = 0
        var last: Int?
        for d in made {
            run = (last.map { $0 + 1 == d } ?? false) ? run + 1 : 1
            best = max(best, run)
            last = d
        }
        return best
    }

    /// True once any day was made on its first try (the first-try achievement).
    var hasFirstTryMake: Bool { days.contains { $0.madeOnTry == 1 } }

    // MARK: Writing

    /// Count one try at day `number`'s shot. `made` is TrickShotJudge's verdict; `distance` the white ball's distance
    /// from the mark (metres; nil when it could not be measured). Returns the day as it now stands, or nil when the day
    /// was already finished (no more tries: nothing changes).
    @discardableResult
    mutating func noteTry(day number: Int, shotID: String, made: Bool, distance: Double?) -> Day? {
        var entry = day(number) ?? Day(day: number, shotID: shotID)
        guard !entry.finished else { return nil }
        entry.tries += 1
        if made {
            entry.madeOnTry = entry.tries
            entry.distance = distance
            entry.score = DailyScore.score(madeOnTry: entry.tries, distance: distance ?? .infinity)
        }
        if let i = days.firstIndex(where: { $0.day == number }) {
            days[i] = entry
        } else {
            days.append(entry)
            days.sort { $0.day < $1.day }
        }
        bestStreak = max(bestStreak, longestRun)
        return entry
    }

    /// Stage 3's queue: the day's score has been posted. False when there is no such day.
    @discardableResult
    mutating func markSent(day number: Int) -> Bool {
        guard let i = days.firstIndex(where: { $0.day == number }) else { return false }
        days[i].sent = true
        return true
    }

    // MARK: Saving

    /// The record on this device; an empty one when none is stored or it cannot be read (logged, never fatal).
    static func load(from defaults: UserDefaults = .standard) -> DailyRecord {
        guard let data = defaults.data(forKey: storageKey) else { return DailyRecord() }
        do {
            return try JSONDecoder().decode(DailyRecord.self, from: data)
        } catch {
            NSLog("DailyRecord: the stored record could not be read: %@", error.localizedDescription)
            return DailyRecord()
        }
    }

    func save(to defaults: UserDefaults = .standard) {
        do {
            defaults.set(try JSONEncoder().encode(self), forKey: Self.storageKey)
        } catch {
            NSLog("DailyRecord: the record could not be saved: %@", error.localizedDescription)
        }
    }
}
