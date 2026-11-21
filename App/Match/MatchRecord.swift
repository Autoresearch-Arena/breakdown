// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: A small on-device record of finished matches (plans/21-Nov-2026-rules-games-plan.md package 6): games played
//          and won per game type, and games played and won against the computer per level. "Won" means won by the
//          first seat: you, against the computer (the person always sits first), and whoever sits as Player 1 in a game
//          for two on one device. A game ended from the menu (conceded) is not counted: only a game the rules finished.
//          Stored as JSON under one UserDefaults key ("matchRecord"), read whenever the menu draws, written once per
//          finished game by MatchMode (noteFinished). Shown on the menu's Play list (TitleScreen) as small marks.
// SRP/DRY check: Pass - checked GameSettings (options only, model stream's file; this record keeps its own key here
//          rather than adding to it) and TrickShotMode / EightBallMode progress (stored per shot and per situation,
//          not per game type). Nothing else counts matches.
import BreakdownRules
import Foundation

/// Games played and won.
struct MatchTally: Codable, Equatable, Sendable {
    var played = 0
    var won = 0
}

struct MatchRecord: Codable, Equatable, Sendable {
    static let storageKey = "matchRecord"

    /// By MatchKind raw value.
    var byKind: [String: MatchTally] = [:]
    /// Games against the computer, by ComputerLevel raw value.
    var byLevel: [String: MatchTally] = [:]

    func tally(_ kind: MatchKind) -> MatchTally { byKind[kind.rawValue] ?? MatchTally() }
    func tally(_ level: ComputerLevel) -> MatchTally { byLevel[level.rawValue] ?? MatchTally() }

    /// Count one finished game. Nothing is counted for a state without a result.
    mutating func note(_ state: MatchState) {
        guard let result = state.result else { return }
        let firstWon = result.winner == PlayerID.first
        byKind[state.kind.rawValue, default: MatchTally()].played += 1
        if firstWon { byKind[state.kind.rawValue, default: MatchTally()].won += 1 }
        // A game against the computer: the computer's level (the first computer seat; a match has at most one).
        if let level = state.players.compactMap(\.computer).first {
            byLevel[level.rawValue, default: MatchTally()].played += 1
            if firstWon { byLevel[level.rawValue, default: MatchTally()].won += 1 }
        }
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
}
