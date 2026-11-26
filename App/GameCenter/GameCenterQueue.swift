// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The small saved list of scores waiting to be sent to the Game Center boards (0.7.10, Shot of the day plan
//          stage 3 item 6, plans/25-Nov-2026-shot-of-the-day-plan.md). A score the player earns while offline, or
//          before the sign-in has finished, waits here and is sent at the next chance, exactly once. A daily score
//          belongs to one day's board: once that day (Coordinated Universal Time) has passed the board it was for has
//          closed, so the score is dropped unsent rather than landing on the wrong day's board. A streak has no day and
//          waits until it is sent; only the best unsent streak is kept.
//          Also the permanent ids the game shares with App Store Connect: the two boards, and "breakdown." plus an
//          achievement's own id (scripts/gamecenter-setup.py builds the same ids; change both together, never one).
//          Pure: no GameKit, no views. The day is a plain whole number of days since 1 January 1970 in Coordinated
//          Universal Time (utcDay), passed in, so tests can use any day. Saved as JSON under one UserDefaults key in
//          the AchievementRecord pattern (lenient load, never fatal). Read and written only by GameCenter
//          (App/GameCenter/GameCenter.swift); checked by BreakdownTests/GameCenterQueueTests.swift.
// SRP/DRY check: Pass - checked AchievementRecord and MatchRecord (the load and save shape is followed, not shared, as
//          each record logs its own name) and App/Daily (written in parallel; nothing here reads it, so the queue keeps
//          its own day number). No other store of unsent scores exists.
import Foundation

/// The two Game Center boards. The raw values are the permanent leaderboard ids in App Store Connect.
enum GameCenterBoard: String, Codable, CaseIterable, Sendable {
    /// Today's shot: a recurring board that starts again every day at midnight Coordinated Universal Time.
    case daily = "breakdown.daily"
    /// The longest run of days with a make: an all-time board.
    case streak = "breakdown.streak"
}

/// The ids the game and App Store Connect share.
enum GameCenterIDs {
    /// Every Game Center id of this game starts with this.
    static let prefix = "breakdown."

    /// The Game Center id of one of the game's achievements: "breakdown." plus the game's own permanent id
    /// (Achievement.id, which the catalogue says must never change).
    static func achievement(_ gameID: String) -> String { prefix + gameID }
}

struct GameCenterQueue: Codable, Equatable {
    static let storageKey = "gameCenterQueue"
    static let currentFormat = 1
    var format = GameCenterQueue.currentFormat

    /// One score waiting to be sent.
    struct Entry: Codable, Equatable, Identifiable, Sendable {
        let id: UUID
        let board: GameCenterBoard
        let value: Int
        /// The day the score was earned (utcDay), for the daily board; nil for the streak, which never expires.
        let day: Int?

        init(id: UUID = UUID(), board: GameCenterBoard, value: Int, day: Int?) {
            self.id = id
            self.board = board
            self.value = value
            self.day = day
        }
    }

    /// Waiting scores, oldest first.
    private(set) var entries: [Entry] = []
    /// Entries handed out by begin and not yet finished: never saved, so a send cut short by the app closing is tried
    /// again at the next launch, and never handed out twice in one run.
    private var inFlight: Set<UUID> = []

    init() {}

    private enum CodingKeys: String, CodingKey { case format, entries }

    /// Lenient: a missing or unreadable list reads as empty rather than failing the whole value.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        format = GameCenterQueue.currentFormat
        entries = (try? c.decodeIfPresent([Entry].self, forKey: .entries)) ?? []
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(format, forKey: .format)
        try c.encode(entries, forKey: .entries)
    }

    /// Equal when the saved parts are equal (what is in flight is one run's bookkeeping).
    static func == (a: GameCenterQueue, b: GameCenterQueue) -> Bool { a.entries == b.entries }

    // MARK: The day

    /// Whole days since 1 January 1970 in Coordinated Universal Time, so the day turns at the same moment everywhere,
    /// as the daily board does. Rounded down, so a moment before 1970 still lands on the right day.
    static func utcDay(of date: Date) -> Int {
        Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    // MARK: Changing the list

    /// Keep a score to send. A second daily score for the same day keeps only the higher one (the board keeps the best
    /// anyway). A streak keeps only the best unsent streak. A value of zero or less is never kept: an empty board line
    /// says nothing. Returns true when the list changed.
    @discardableResult
    mutating func add(board: GameCenterBoard, value: Int, day: Int?) -> Bool {
        guard value > 0 else { return false }
        let entryDay = board == .daily ? day : nil
        // Only a waiting entry is merged with; one already being sent is left alone, and the new score waits beside it
        // (the board keeps the better of the two).
        if let i = entries.firstIndex(where: { $0.board == board && $0.day == entryDay && !inFlight.contains($0.id) }) {
            guard value > entries[i].value else { return false }
            entries[i] = Entry(board: board, value: value, day: entryDay)
            return true
        }
        entries.append(Entry(board: board, value: value, day: entryDay))
        return true
    }

    /// Drop every daily score whose day has passed. Returns true when the list changed.
    @discardableResult
    mutating func dropExpired(today: Int) -> Bool {
        let before = entries.count
        entries.removeAll { entry in
            guard let day = entry.day else { return false }
            return day < today
        }
        return entries.count != before
    }

    /// The scores to send now: the expired ones dropped first, then every waiting entry not already being sent, each
    /// marked as being sent so a second call before it finishes does not hand it out again.
    mutating func begin(today: Int) -> [Entry] {
        dropExpired(today: today)
        let due = entries.filter { !inFlight.contains($0.id) }
        for entry in due { inFlight.insert(entry.id) }
        return due
    }

    /// A send has finished. Sent: the entry is gone for good, so it is never sent twice. Not sent (offline, refused):
    /// it waits for the next chance, unless its day has passed by then.
    mutating func finish(_ id: UUID, sent: Bool) {
        inFlight.remove(id)
        if sent { entries.removeAll { $0.id == id } }
    }

    // MARK: Saving

    /// The list on this device; an empty one when none is stored or it cannot be read (logged, never fatal).
    static func load(from defaults: UserDefaults = .standard) -> GameCenterQueue {
        guard let data = defaults.data(forKey: storageKey) else { return GameCenterQueue() }
        do {
            return try JSONDecoder().decode(GameCenterQueue.self, from: data)
        } catch {
            NSLog("GameCenterQueue: the stored list could not be read: %@", error.localizedDescription)
            return GameCenterQueue()
        }
    }

    func save(to defaults: UserDefaults = .standard) {
        do {
            defaults.set(try JSONEncoder().encode(self), forKey: Self.storageKey)
        } catch {
            NSLog("GameCenterQueue: the list could not be saved: %@", error.localizedDescription)
        }
    }
}
