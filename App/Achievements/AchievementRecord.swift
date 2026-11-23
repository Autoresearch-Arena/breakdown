// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The achievements save (plans/23-Nov-2026-achievements-plan.md, new file 5), in the MatchRecord pattern: one
//          Codable value stored as JSON under one UserDefaults key ("achievements"), on this device only. It holds, per
//          earned achievement id, the date it was earned, the shot that earned it (AchievementShot, when there was one)
//          and whether the player has seen it in the list yet (the menu's "new" state); the tables and surfaces a shot
//          has been struck on (nothing else stores those); and whether the first-launch quiet pass over older progress
//          has run (seeded).
//          The decoder is lenient: every field may be missing (an older or newer save still loads), and an earned entry
//          whose shot cannot be read keeps its date with no shot. Read and written only by AchievementBook (once at
//          launch, and again only when something changed).
// SRP/DRY check: Pass - checked GameSettings (options only; this keeps its own key here, as TrickShotMode, LessonMode
//          and MatchRecord keep theirs) and MatchRecord (the load and save shape is copied from it, not shared, as each
//          record logs its own name). No other store of achievements exists.
import Foundation

struct AchievementRecord: Codable, Equatable {
    static let storageKey = "achievements"
    /// Bumped when the meaning of a stored field changes.
    static let currentFormat = 1
    var format = AchievementRecord.currentFormat

    /// One earned achievement.
    struct Earned: Codable, Equatable {
        var date: Date
        /// The player's own shot that earned it; nil for a collection finished without a shot of the player's on screen.
        var shot: AchievementShot?
        /// False while it is new (the menu's mark and the list's dot); true once the list has been opened.
        var seen: Bool

        init(date: Date, shot: AchievementShot?, seen: Bool) {
            self.date = date
            self.shot = shot
            self.seen = seen
        }

        private enum CodingKeys: String, CodingKey { case date, shot, seen }

        /// Lenient: a shot that cannot be read (a newer or broken recipe) is dropped, the date kept; a missing date
        /// reads as the start of the reference calendar rather than losing the achievement.
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            date = (try? c.decode(Date.self, forKey: .date)) ?? Date(timeIntervalSinceReferenceDate: 0)
            shot = try? c.decodeIfPresent(AchievementShot.self, forKey: .shot)
            seen = (try? c.decodeIfPresent(Bool.self, forKey: .seen)) ?? true
        }
    }

    /// Earned achievements by id.
    var earned: [String: Earned] = [:]
    /// TableKind raw values a shot has been struck on, in the order first played.
    var tablesPlayed: [String] = []
    /// PlaySurface raw values a shot has been struck on, in the order first played.
    var surfacesPlayed: [String] = []
    /// The first-launch quiet pass over the progress the game already kept has run.
    var seeded = false

    init() {}

    private enum CodingKeys: String, CodingKey { case format, earned, tablesPlayed, surfacesPlayed, seeded }

    /// Every field is optional on reading, so a record written by another build loads instead of failing (a synthesized
    /// decoder would reject a missing key and lose the whole record).
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        format = AchievementRecord.currentFormat
        earned = (try? c.decodeIfPresent([String: Earned].self, forKey: .earned)) ?? [:]
        tablesPlayed = (try? c.decodeIfPresent([String].self, forKey: .tablesPlayed)) ?? []
        surfacesPlayed = (try? c.decodeIfPresent([String].self, forKey: .surfacesPlayed)) ?? []
        seeded = (try? c.decodeIfPresent(Bool.self, forKey: .seeded)) ?? false
    }

    /// The record on this device; an empty one when none is stored or it cannot be read (logged, never fatal).
    static func load(from defaults: UserDefaults = .standard) -> AchievementRecord {
        guard let data = defaults.data(forKey: storageKey) else { return AchievementRecord() }
        do {
            return try JSONDecoder().decode(AchievementRecord.self, from: data)
        } catch {
            NSLog("AchievementRecord: the stored record could not be read: %@", error.localizedDescription)
            return AchievementRecord()
        }
    }

    func save(to defaults: UserDefaults = .standard) {
        do {
            defaults.set(try JSONEncoder().encode(self), forKey: Self.storageKey)
        } catch {
            NSLog("AchievementRecord: the record could not be saved: %@", error.localizedDescription)
        }
    }

    /// Earn one achievement. False, and nothing changes, when it is already earned: the first date and shot stay.
    @discardableResult
    mutating func earn(_ id: String, on date: Date, shot: AchievementShot?, seen: Bool) -> Bool {
        guard earned[id] == nil else { return false }
        earned[id] = Earned(date: date, shot: shot, seen: seen)
        return true
    }

    /// Everything earned counts as seen (the list was opened). True when anything changed.
    @discardableResult
    mutating func markAllSeen() -> Bool {
        var changed = false
        for (id, e) in earned where !e.seen {
            earned[id]?.seen = true
            changed = true
        }
        return changed
    }

    /// Remember a table or surface a shot was struck on. True when it is new.
    @discardableResult
    mutating func notePlayed(table: String, surface: String) -> Bool {
        var changed = false
        if !tablesPlayed.contains(table) { tablesPlayed.append(table); changed = true }
        if !surfacesPlayed.contains(surface) { surfacesPlayed.append(surface); changed = true }
        return changed
    }
}
