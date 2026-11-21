// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: "Straight stroke", the drill in the Play list's practice options (plans/21-Nov-2026-stroke-and-power-plan.md).
//          The cue ball alone on the head spot, aimed straight up the table over the spot: stroke it up to the far rail
//          and back, and the drill judges how close it returns to the cue line (the line the cue was aimed along
//          through the start). A crooked stroke turns the cue off line and puts side on the ball, and both show up
//          twice over the length of the table and back. The card shows the verdict, the stroke's own trace, and the
//          progress the device remembers: the best return and how many dead-straight strokes there have been.
//          Free play underneath: Try again, the ghost, the comparison ("your stroke was straighter this time"), undo
//          and the power bar's zones all work as in Practice. Played on the pool table whatever table is chosen; any
//          other choice from the menu ends it.
// SRP/DRY check: Pass - checked TrickShotMode (same "made on first use by the model, ended by the menu" shape, but no
//          authored answer and no windows: this is free play judged by one measure) and ShotFacts (no cushion-reach
//          helper there fits a return path, so the cue ball's own recorded path is sampled here). The words are
//          StrokeWords'; the stored keys live in GameSettings.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Observation

@MainActor
@Observable
final class StrokeDrill {
    enum Grade: Equatable { case deadStraight, straight, offLine }

    enum Result: Equatable {
        /// Came back past the start; metres off the cue line there.
        case back(Double, Grade)
        /// Off the far rail but stopped before getting back to the start; metres off the line where it stopped.
        case short(Double)
        /// Never reached a cushion.
        case noRail
        /// The cue ball went in a pocket.
        case dropped
    }

    /// Within half a ball's radius of the line: the ball would still touch a cue tip held on the line.
    static var deadStraight: Double { PoolParameters().ballRadius / 2 }
    /// Within one ball's width (two radii): close enough that the ball comes back to the cue's own ball position.
    static var straight: Double { PoolParameters().ballRadius * 2 }
    /// The drill's starting power, house-cue-equivalent launch speed: free play's own default, which carries a
    /// centre-hit cue ball up to the far rail and back past the head spot on cloth with room to spare (alone it rolls
    /// about 2.6 v^2 metres, PowerWords; the trip is about 3.8 m plus the rail's loss).
    static let startPower = 3.0

    @ObservationIgnored private unowned let model: ShowpieceModel
    /// True from begin() until the menu starts something else (end()).
    private(set) var active = false
    /// The drill's layout: only the cue ball, on the head spot.
    private(set) var start: [Vec2] = []
    /// The latest drill stroke's verdict, its stroke and whether it was the best yet.
    private(set) var last: Result?
    private(set) var lastStroke: StrokeDelivery?
    private(set) var lastWasBest = false
    /// What the device remembers (GameSettings keys).
    private(set) var best: Double? = UserDefaults.standard.object(forKey: GameSettings.strokeDrillBestKey) as? Double
    private(set) var straightCount = UserDefaults.standard.integer(forKey: GameSettings.strokeDrillStraightKey)

    init(model: ShowpieceModel) { self.model = model }

    /// True while the drill is the thing on the table. Every other choice from the menu (Practice, a match, a trick
    /// shot, a situation, a table, the intro) ends it through the model, so the flag is the whole answer; the match
    /// check is a guard for a match continued some other way. It reads nothing that could create a mode, because the
    /// model asks it while choosing the table to solve on.
    var isActive: Bool { active && model.match == nil }

    /// From the Play list: the menu closes, other modes end, the cue ball goes on the head spot aimed up the table.
    func begin() {
        model.enterStrokeDrill()
        active = true
        last = nil; lastStroke = nil; lastWasBest = false
        let p = PoolParameters()
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[0] = Vec2(NextShot.headLineX(parameters: p), p.tableWidth / 2)
        start = layout
        model.loadTrickLayout(layout, aim: 0, power: Self.startPower, tipUp: 0, tipSide: 0)
        model.setLens(false)
    }

    /// Back to the start for another go: a retry of the last stroke when there is one (same settings, its ghost and the
    /// comparison), otherwise the start with the settings as they are.
    func again() {
        guard isActive else { return }
        if model.canTryAgain, let a = model.currentAttempt, a.start == start {
            model.tryAgain()
        } else {
            model.loadTrickLayout(start, aim: model.aimDegrees, power: model.shotPower, tipUp: model.shotTipUp,
                                  tipSide: model.shotTipSide)
        }
    }

    func end() { active = false }

    /// The model reports every attempt it records; a drill stroke (from the drill's start) is judged and remembered.
    func attemptRecorded(_ attempt: ShotAttempt) {
        guard isActive, !attempt.isBreak, attempt.start == start else { return }
        let result = Self.judge(attempt)
        last = result
        lastStroke = attempt.stroke
        lastWasBest = false
        guard case .back(let off, let grade) = result else { return }
        if best == nil || off < best! {
            best = off
            lastWasBest = true
            UserDefaults.standard.set(off, forKey: GameSettings.strokeDrillBestKey)
        }
        if grade == .deadStraight {
            straightCount += 1
            UserDefaults.standard.set(straightCount, forKey: GameSettings.strokeDrillStraightKey)
        }
    }

    /// Judge one stroke from its recording. The cue line runs through the start along the aim the player chose (not
    /// the drifted one: the drift is what is being judged). After the cue ball first touches a cushion, its path is
    /// sampled until it comes back to the start's place along that line; how far to the side it is there is the
    /// measure. One sample every millisecond of recorded time: at the drill's speeds the ball moves a few millimetres
    /// between samples, and the crossing point is interpolated between the two samples either side.
    static func judge(_ attempt: ShotAttempt) -> Result {
        let tl = attempt.timeline, ball = attempt.cueBall
        if tl.pocketTime[ball] != nil { return .dropped }
        guard let rail = tl.events.first(where: { $0.kind == .cushion && $0.balls.contains { $0.ball == ball } })
        else { return .noRail }
        let s = attempt.start[ball]
        let a = attempt.aim * Double.pi / 180
        let d = Vec2(cos(a), sin(a)), side = d.perp
        let step = 0.001
        var t = rail.time
        var previous = tl.state(ball: ball, at: t).position
        while t < tl.duration {
            t = min(tl.duration, t + step)
            let p = tl.state(ball: ball, at: t).position
            let along0 = (previous - s).dot(d), along1 = (p - s).dot(d)
            if along1 <= 0 {
                // Crossed back over the start between the two samples: interpolate where.
                let k = along0 > along1 ? along0 / (along0 - along1) : 1
                let at = previous + (p - previous) * k
                let off = abs((at - s).dot(side))
                return .back(off, grade(off))
            }
            previous = p
        }
        let rest = tl.state(ball: ball, at: tl.duration).position
        return .short(abs((rest - s).dot(side)))
    }

    static func grade(_ off: Double) -> Grade {
        if off <= deadStraight { return .deadStraight }
        if off <= straight { return .straight }
        return .offLine
    }
}
