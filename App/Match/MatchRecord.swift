// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 18: the record now counts only games against the
//          computer, per game and per level, from the person's side (the seat that is not the computer, not "Player
//          1"). Two-player games on one device are no longer counted per seat: who sat as Player 1 says nothing about
//          the person holding the device. record(kind:level:) is what the menu shows; tally(_:) for a game and for a
//          level now read the same games-against-the-computer counts. A record stored by 0.6.6 still loads: its
//          per-level counts carry over, its per-game counts (which mixed in two-player games) are dropped.)
// PURPOSE: A small on-device record of finished games against the computer (plans/21-Nov-2026-rules-games-plan.md
//          package 6): played and won per game and level, per level across games, and per game across levels. "Won"
//          means the person beat the computer. A game ended from the match card (End match) is not counted: only a
//          game the rules finished, so ending a game you are losing never shows as a loss or a win.
//          Stored as JSON under one UserDefaults key ("matchRecord"), read whenever the menu draws, written once per
//          finished game by MatchMode (noteFinished). Shown by the menu (TitleScreen) beside the computer's levels.
// SRP/DRY check: Pass - checked GameSettings (options only; this record keeps its own key here rather than adding to
//          it) and TrickShotMode / EightBallMode progress (stored per shot and per situation, not per game type).
//          Nothing else counts matches.
import BreakdownRules
import Foundation

/// Games played and won.
struct MatchTally: Codable, Equatable, Sendable {
    var played = 0
    var won = 0
    /// Games against the computer always end with a winner (eight-ball and nine-ball, the only games it plays, have
    /// no draw), so every game not won was lost.
    var lost: Int { played - won }
}

struct MatchRecord: Codable, Equatable, Sendable {
    static let storageKey = "matchRecord"

    /// Games against the computer, by MatchKind raw value, every level together.
    var byKind: [String: MatchTally] = [:]
    /// Games against the computer, by ComputerLevel raw value, every game together.
    var byLevel: [String: MatchTally] = [:]
    /// Games against the computer, by game and level ("eightBall.easy").
    var byKindAndLevel: [String: MatchTally] = [:]

    /// Bumped when the meaning of the stored counts changes. Format 1 (0.6.6) counted two-player games by seat in
    /// byKind; format 2 counts only games against the computer.
    static let currentFormat = 2
    var format = MatchRecord.currentFormat

    init() {}

    private enum CodingKeys: String, CodingKey { case byKind, byLevel, byKindAndLevel, format }

    /// Every field is optional on reading, so a record written by an older build loads instead of failing (a
    /// synthesized decoder would reject the missing keys and lose the whole record).
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let stored = try c.decodeIfPresent(Int.self, forKey: .format) ?? 1
        byLevel = try c.decodeIfPresent([String: MatchTally].self, forKey: .byLevel) ?? [:]
        byKindAndLevel = try c.decodeIfPresent([String: MatchTally].self, forKey: .byKindAndLevel) ?? [:]
        // Format 1's per-game counts mixed two-player games with games against the computer and cannot be split, so
        // they are dropped rather than shown as something they are not. Its per-level counts were computer-only.
        byKind = stored >= 2 ? (try c.decodeIfPresent([String: MatchTally].self, forKey: .byKind) ?? [:]) : [:]
        format = MatchRecord.currentFormat
    }

    private static func key(_ kind: MatchKind, _ level: ComputerLevel) -> String { "\(kind.rawValue).\(level.rawValue)" }

    /// Games against the computer of one game, every level together.
    func tally(_ kind: MatchKind) -> MatchTally { byKind[kind.rawValue] ?? MatchTally() }
    /// Games against the computer at one level, every game together.
    func tally(_ level: ComputerLevel) -> MatchTally { byLevel[level.rawValue] ?? MatchTally() }
    /// Games against the computer of one game at one level.
    func tally(_ kind: MatchKind, _ level: ComputerLevel) -> MatchTally {
        byKindAndLevel[Self.key(kind, level)] ?? MatchTally()
    }

    /// Count one finished game against the computer. A game without a result, or one between people, is not
    /// counted.
    mutating func note(_ state: MatchState) {
        guard let result = state.result,
              let level = state.players.compactMap(\.computer).first,
              let person = state.players.first(where: { !$0.isComputer })?.id else { return }
        let won = result.winner == person
        func count(_ t: inout MatchTally) {
            t.played += 1
            if won { t.won += 1 }
        }
        count(&byKind[state.kind.rawValue, default: MatchTally()])
        count(&byLevel[level.rawValue, default: MatchTally()])
        count(&byKindAndLevel[Self.key(state.kind, level), default: MatchTally()])
    }

    /// The record on this device; an empty one when none is stored or it cannot be read (logged, never fatal).
    static func load(from defaults: UserDefaults = .standard) -> MatchRecord {
        guard let data = defaults.data(forKey: storageKey) else { return MatchRecord() }
        do {
            return try JSONDecoder().decode(MatchRecord.self, from: data)
        } catch {
            NSLog("MatchRecord: the stored record could not be read: %@", error.localizedDescription)
            return MatchRecord()
        }
    }

    func save(to defaults: UserDefaults = .standard) {
        do {
            defaults.set(try JSONEncoder().encode(self), forKey: Self.storageKey)
        } catch {
            NSLog("MatchRecord: the record could not be saved: %@", error.localizedDescription)
        }
    }

    /// Read, count one finished game, write back.
    static func noteFinished(_ state: MatchState, in defaults: UserDefaults = .standard) {
        var r = load(from: defaults)
        r.note(state)
        r.save(to: defaults)
    }

    /// Games against the computer only, per game and level (two-player games are not counted per seat), for the
    /// menu: the person's wins and losses against that level at that game on this device.
    static func record(kind: MatchKind, level: ComputerLevel, in defaults: UserDefaults = .standard)
        -> (won: Int, lost: Int) {
        let t = load(from: defaults).tally(kind, level)
        return (t.won, t.lost)
    }
}
