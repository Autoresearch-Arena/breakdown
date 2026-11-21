// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (passes the shot's cue elevation to the table, so the massé and the jump are struck with a raised cue).
// Edited: Claude Opus 5.5 High, 20-November-2026 (Watch it now turns the Ride camera on through model.setRide).
// Edited: Claude Opus 5.5 High, 21-November-2026 (lineUpAnswer, for the -trickAim store-screenshot flag.)
// PURPOSE: Trick-shot mode: the game's main purpose. Holds which trick shot is on the table and walks the player through
//          it: Ready (the table set up at the shot's start, a card with the hook) > Watching (the authored solution plays
//          at full speed) > Explaining (it replays slowly in the Physics Lens while the card gives the one idea behind
//          it, with the maths behind a button) > Your turn (the table back at the start, aiming open, with the player's
//          own settings, never the answer) > Judged (made it, or one sentence on what to change; Try again puts the
//          balls back with the same settings; a make marks the shot done on this device, with a haptic and a short glow,
//          and offers the next shot).
//          It drives the table only through ShowpieceModel's own methods (the trick-shot section there loads a layout or
//          a seeded rack with given settings; shootNow, breakNow, replay, tryAgain and setLens do the rest), and it learns
//          that a shot has finished from the model's aimReady and timelineVersion, which the table layer forwards to
//          update(). Attempts are judged by TrickShotJudge, and only when they started from the trick's own start, so a
//          follow-up shot from wherever the balls stopped is never marked as a miss.
//          The shot panel's open state belongs to the screen; this mode asks for it through `wantsAiming`, which the
//          table layer applies.
//          Done shots are stored in UserDefaults under "trickShotsDone" as a comma-separated list of ids.
//          Launch flags (handled by the table layer at start-up): -trickList opens the list over the menu, -trick <id>
//          opens a shot ready to watch, -trickPlay <id> opens it and plays the solution.
// SRP/DRY check: Pass - flow only. The shot data is TrickShots, the judging is TrickShotJudge, the views are
//          TrickShotViews; the table is driven through ShowpieceModel's existing methods, not copies of them.
import BreakdownLensModel
import BreakdownPhysics
import Foundation
import Observation

@MainActor
@Observable
final class TrickShotMode {
    enum Phase: Equatable {
        /// No trick shot on the table: free play.
        case off
        /// Set up at the start, waiting for Watch it or Your turn.
        case ready
        /// The authored solution is playing.
        case watching
        /// The solution replays in the Lens and the card explains the idea.
        case explaining
        /// The player is lining up or their attempt is playing.
        case aiming
        /// The attempt is over: made or missed, with a line on what to change.
        case judged(TrickVerdict)
        /// The player shot again from where the balls stopped; Try again puts them back.
        case offScript
    }

    /// The model this mode drives. The model owns the mode, so this does not keep the model alive.
    @ObservationIgnored unowned let model: ShowpieceModel

    private(set) var current: TrickShot?
    private(set) var phase: Phase = .off
    /// The list sheet; opened from the menu.
    var listOpen = false
    /// Whether the explanation card shows the equation; starts from the Options setting.
    var showMaths = UserDefaults.standard.bool(forKey: GameSettings.mathsKey)
    /// Bumped on every make, so the views can fire one haptic and one glow per success.
    private(set) var celebrations = 0
    /// What the shot panel should be: open while it is the player's turn, closed while the solution plays.
    private(set) var wantsAiming = false
    /// Bumped whenever wantsAiming is set, so the screen applies it even when the value does not change.
    private(set) var aimingRequests = 0
    private(set) var doneIDs: Set<String>

    /// The player's own settings per shot, kept across watching the answer, so Your turn never hands them the answer.
    @ObservationIgnored private var playerSettings: [String: TrickSettings] = [:]
    /// The recording already judged, so each attempt is judged once.
    @ObservationIgnored private var judgedVersion = -1
    /// The recording the solution produced while watching, so it is never judged as the player's.
    @ObservationIgnored private var solutionVersion = -1

    private static let doneKey = "trickShotsDone"

    init(model: ShowpieceModel) {
        self.model = model
        let stored = UserDefaults.standard.string(forKey: Self.doneKey) ?? ""
        doneIDs = Set(stored.split(separator: ",").map(String.init))
    }

    var isActive: Bool { current != nil && phase != .off }
    func isDone(_ shot: TrickShot) -> Bool { doneIDs.contains(shot.id) }

    /// The mechanical bridge is drawn under the cue while the player lines up a shot that needs it.
    var showsBridge: Bool { current?.usesBridge == true && phase == .aiming }

    /// Balls and pockets to mark on the table: the balls the goal names and the pockets they must drop in. Shown while
    /// the shot is set up and while the player lines up, not while anything is moving.
    var markers: (balls: [Int], pockets: [Int])? {
        guard let shot = current else { return nil }
        switch phase {
        case .ready, .aiming, .judged, .offScript:
            break
        default:
            return nil
        }
        return (shot.goal.drops.map(\.ball), shot.goal.drops.compactMap(\.pocket))
    }

    // MARK: Flow

    /// Put a trick shot on the table, ready to watch or try. Closes the menu and the list.
    func begin(_ shot: TrickShot) {
        guard !shot.pending else { return }
        current = shot
        listOpen = false
        model.enterTrickTable()
        // The player's own settings (or a plain start), never the answer: the aim line must not give it away.
        loadStart(with: playerSettings[shot.id] ?? defaultSettings(for: shot))
        if playerSettings[shot.id] == nil, !shot.isBreak { model.aimAtNearestBall() }
        model.setLens(false)
        phase = .ready
        requestAiming(false)
        ride(false)
    }

    func begin(id: String) {
        if let shot = TrickShots.shot(id: id) { begin(shot) }
    }

    /// Watch it: the answer, at full speed. For the break, the model's own opening plays it with the slow Lens replay.
    func watch() {
        guard let shot = current else { return }
        rememberPlayerSettings()
        loadStart(with: shot.solution)
        model.setLens(false)
        requestAiming(false)
        phase = .watching
        ride(true)
        if shot.isBreak { model.breakNow() } else { model.shootNow() }
        solutionVersion = model.timelineVersion
    }

    /// Your turn: the table back at the start with the player's own settings, aiming open.
    func yourTurn() {
        guard let shot = current else { return }
        ride(false)
        loadStart(with: playerSettings[shot.id] ?? defaultSettings(for: shot))
        if playerSettings[shot.id] == nil, !shot.isBreak { model.aimAtNearestBall() }
        model.setLens(false)
        phase = .aiming
        requestAiming(true)
    }

    /// Test route (-trickAim <id>): the answer's own stroke lined up with aiming open and nothing played, so a store
    /// screenshot shows the real cue, and the bridge on a bridge shot, exactly where the answer puts them.
    func lineUpAnswer() {
        guard let shot = current else { return }
        ride(false)
        loadStart(with: shot.solution)
        model.setLens(false)
        phase = .aiming
        requestAiming(true)
    }

    /// Try again after an attempt: same start, same settings, the last try kept as a ghost (the model's own retry).
    func tryAgain() {
        guard current != nil else { return }
        if model.canTryAgain, let attempt = model.currentAttempt, startsAtTrick(attempt) {
            model.tryAgain()
            model.dismissComparison()
            phase = .aiming
            requestAiming(true)
        } else {
            yourTurn()
        }
    }

    /// The next shot in the list that is ready to play, or the list itself after the last one.
    func next() {
        guard let shot = current else { listOpen = true; return }
        let playable = TrickShots.all.filter { !$0.pending }
        if let i = playable.firstIndex(where: { $0.id == shot.id }), i + 1 < playable.count {
            begin(playable[i + 1])
        } else {
            listOpen = true
        }
    }

    /// Leave trick-shot mode (free play from the menu).
    func end() {
        ride(false)
        current = nil
        phase = .off
        wantsAiming = false
    }

    /// Called by the table layer whenever the model's playback state changes: moves Watching on to Explaining when the
    /// answer has played, and judges the player's attempt once it has come to rest.
    func update() {
        guard let shot = current, model.aimReady else { return }
        switch phase {
        case .watching:
            guard model.timelineVersion == solutionVersion else { return }
            phase = .explaining
            ride(false)
            // The break already replayed itself slowly in the Lens during its opening; a shot replays now.
            if !shot.isBreak { model.replay(withLens: true) }
        case .ready, .aiming, .judged, .offScript:
            // While explaining, a shot of the player's is never judged: it may be a retry of the answer itself.
            guard let attempt = model.currentAttempt, model.timelineVersion != judgedVersion,
                  model.timelineVersion != solutionVersion else { return }
            judgedVersion = model.timelineVersion
            guard startsAtTrick(attempt) else { phase = .offScript; return }
            playerSettings[shot.id] = TrickSettings(aim: attempt.aim, power: attempt.power, tipUp: attempt.tipUp,
                                                    tipSide: attempt.tipSide)
            let verdict = TrickShotJudge.verdict(for: shot, attempt: attempt)
            // The trick card already says what to change; the retry comparison card would repeat it over the table.
            model.dismissComparison()
            phase = .judged(verdict)
            // The card offers Try again; the panel closes so the table has the room while the verdict is read.
            requestAiming(false)
            if verdict.made { markDone(shot) }
        default:
            break
        }
    }

    // MARK: Pieces

    /// Lay out the trick's start with the given settings: the authored layout, or the authored rack with its own seed.
    private func loadStart(with s: TrickSettings) {
        guard let shot = current else { return }
        switch shot.setup {
        case .layout(let positions):
            model.loadTrickLayout(positions, aim: s.aim, power: s.power, tipUp: s.tipUp, tipSide: s.tipSide,
                                  elevation: s.elevation ?? 0)
        case .rack(let seed):
            model.loadTrickRack(seed: seed, aimOffset: s.aim, power: s.power, tipUp: s.tipUp, tipSide: s.tipSide)
        }
    }

    /// Where a player starts before trying anything: straight at the head ball for the break, otherwise a medium
    /// stroke through the middle of the cue ball (the aim is then pointed at the nearest ball).
    private func defaultSettings(for shot: TrickShot) -> TrickSettings {
        shot.isBreak ? TrickSettings(aim: 0, power: 10, tipUp: 0, tipSide: 0)
                     : TrickSettings(aim: 0, power: 3, tipUp: 0, tipSide: 0)
    }

    /// Keep what the player had dialled in before the answer replaces it on the table.
    private func rememberPlayerSettings() {
        guard let shot = current, phase == .ready || phase == .aiming || phase == .offScript || isJudged else { return }
        playerSettings[shot.id] = shot.isBreak
            ? TrickSettings(aim: model.aimOffset, power: model.power, tipUp: model.tipHeight, tipSide: model.breakTipSide)
            : TrickSettings(aim: model.aimDegrees, power: model.shotPower, tipUp: model.shotTipUp, tipSide: model.shotTipSide)
    }

    private var isJudged: Bool { if case .judged = phase { return true } else { return false } }

    /// True when an attempt started from this trick's own start (not from wherever the last shot left the balls).
    private func startsAtTrick(_ attempt: ShotAttempt) -> Bool {
        guard let shot = current else { return false }
        switch shot.setup {
        case .layout(let positions): return !attempt.isBreak && attempt.start == positions
        case .rack(let seed): return attempt.isBreak && attempt.breakSeed == seed
        }
    }

    private func markDone(_ shot: TrickShot) {
        celebrations += 1
        guard !doneIDs.contains(shot.id) else { return }
        doneIDs.insert(shot.id)
        UserDefaults.standard.set(doneIDs.sorted().joined(separator: ","), forKey: Self.doneKey)
    }

    private func requestAiming(_ open: Bool) {
        wantsAiming = open
        aimingRequests += 1
    }

    /// The ride camera: the view from behind the cue ball as it travels, for watching the answer.
    private func ride(_ on: Bool) {
        // Watching the answer rides behind the cue ball; the player's own turn goes back to the table camera.
        model.setRide(on)
    }
}
