// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The shot's own settings, carried quietly inside a Lens clip's file (0.7.7, plans/23-Nov-2026-clips-plan.md,
//          Step 7), so a later version can open a shared clip back in the game and play the very same shot. Not used
//          to open anything yet: this version only writes it.
//          What it holds is everything the solver needs to make the recording again: where every ball started, the
//          strike (direction, speed, tip, cue angle, struck ball), the shot's seed, the version stamp of the solver's
//          numbers the shot was built with (the player's break uses 1, a shot the default 2), the table, the surface
//          and the physics generation. solve() rebuilds the input the way the model does (ShowpieceModel.solverCopy)
//          and runs the solver; ClipMaker only keeps the record when that re-solve moves exactly as the attempt did
//          (same motionHash), so a clip never carries settings that would play a different shot.
//          Written into the file as one QuickTime metadata item, key "breakdown.shot", the record as JSON text
//          (metadataItem()). Some apps strip a video's metadata when it is shared; the record is a bonus, never
//          relied on.
// SRP/DRY check: Pass - checked ShotAttempt (not Codable, holds a whole Timeline) and ShotInput (not Codable): this is
//          the smallest saved form of a shot. If the make-it-again feature adds its own saved-shot type, the coordinator
//          keeps one and points the other at it.
import AVFoundation
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

struct ClipShotRecord: Codable, Equatable, Sendable {
    /// The record's own format, so a later reader can tell old records from new.
    var format = 1
    /// Every ball's starting centre (index 0 the pool cue ball; (-1, -1) is off the table).
    var positions: [Vec2]
    /// The strike: unit direction on the table plan, launch speed (m/s), tip offsets (m), cue angle (sine), struck ball.
    var direction: Vec2
    var speed: Double
    var tipUp: Double
    var tipSide: Double
    var elevation: Double
    var ballIndex: Int
    /// The shot's seed (the solver's one source of variation).
    var seed: UInt64
    /// PoolParameters.version the input was built with (a label hashed into the recording).
    var parametersVersion: Int
    /// The table and surface, by their stored names, and the physics generation.
    var table: String
    var surface: String
    var generation: Int
    var isBreak: Bool

    /// The record of a kept attempt: its effective input (before the table's and surface's numbers were written in)
    /// and what it was solved on.
    init(attempt: ShotAttempt) {
        let input = attempt.input
        positions = input.positions
        direction = input.strike.direction
        speed = input.strike.speed
        tipUp = input.strike.tipUp
        tipSide = input.strike.tipSide
        elevation = input.strike.elevation
        ballIndex = input.strike.ballIndex
        seed = input.seed
        parametersVersion = input.parameters.version
        table = attempt.table.rawValue
        surface = attempt.surface.rawValue
        generation = attempt.generation
        isBreak = attempt.isBreak
    }

    /// The recording these settings make, solved the way the model solves a shot: default numbers stamped with the
    /// record's version, then the table, the surface and the generation (ShowpieceModel.solverCopy). Nil for a table
    /// or surface this version does not know. Pure and slow-ish (a whole solve): call it off the main actor.
    func solve() -> Timeline? {
        guard let kind = TableKind(rawValue: table), let bed = PlaySurface(rawValue: surface) else { return nil }
        var parameters = PoolParameters()
        parameters.version = parametersVersion
        let strike = CueStrike(direction: direction, speed: speed, tipUp: tipUp, tipSide: tipSide, elevation: elevation,
                               ballIndex: ballIndex)
        let input = ShotInput(parameters: parameters, positions: positions, strike: strike, seed: seed)
        let solvable = ShowpieceModel.solverCopy(input, table: kind, surface: bed, generation: generation)
        return PoolSolver.simulate(solvable)
    }

    /// The metadata key the record is written under.
    static let metadataKey = "breakdown.shot"

    /// The record as one QuickTime metadata item (JSON text). Nil only if encoding fails, which plain numbers cannot.
    func metadataItem() -> AVMetadataItem? {
        guard let data = try? JSONEncoder().encode(self), let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key = Self.metadataKey as NSString
        item.value = text as NSString
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }

    /// Reads a record back from metadata items (the tests use it; opening a clip is for a later version).
    static func read(from items: [AVMetadataItem]) async -> ClipShotRecord? {
        for item in items where item.keySpace == .quickTimeMetadata {
            guard (item.key as? String) == metadataKey else { continue }
            guard let text = try? await item.load(.stringValue), let data = text.data(using: .utf8) else { continue }
            if let record = try? JSONDecoder().decode(ClipShotRecord.self, from: data) { return record }
        }
        return nil
    }
}
