// Author: Claude Opus 5.5 High
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream pacing, plans/22-Nov-2026-v076-phone-plan.md, bug-hunt
//          entry 22: The Called Break's answer gets its slow guided Lens replay like every other trick (the break guard
//          is gone from update and recordingReplaced; breaks have played at real speed with the Lens off since 0.7.1).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 1, 9 and 10: the player's cue angle is kept with their settings, so Your turn after Watch it keeps a
//          raised cue; markers carries the cue ball's finish circle (Stop Dead); recordingReplaced follows a surface
//          change mid-answer (the shared part is RecordingFollow, at the end of this file, also used by LessonMode).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F10:
//          startsAtTrick is internal for the what-if's Keep; recordingReplaced is a stub learn-modes fills.)
// Edited: GPT 6.2 Sol, 21-November-2026 (draw-massé carom lesson).
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (passes the shot's cue elevation to the table, so the massé and the jump are struck with a raised cue).
// Edited: Claude Opus 5.5 High, 20-November-2026 (Watch it now turns the Ride camera on through model.setRide).
// Edited: Claude Opus 5.5 High, 21-November-2026 (lineUpAnswer, for the -trickAim store-screenshot flag.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (no longer dismisses the model's retry comparison: the trick card
//          shows its sentence itself and the general card hides while a trick shot is up.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 trick-shots stream: the answer's replay holds the shot's own
//          moments (TrickSignature through model.setPaceSignature); the answer's cue-ball path is kept for Show the
//          answer's path (answerPath, showAnswerPath); Watch yours replays a made try the same way (watchYours).)
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
//          TrickShotViews; the table is driven through ShowpieceModel's existing methods, not copies of them. The small
//          RecordingFollow helper at the end is the one copy of what this mode and LessonMode both do when the model
//          re-solves the recording on screen.
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

    /// The answer's cue-ball path, kept from its recording when the answer is watched (0.7.4), so after a try the card
    /// can lay it faintly beside the player's own. Kept for the shot it belongs to; another shot's is never shown.
    struct AnswerPath: Equatable {
        let shotID: String
        /// The cue ball's path in table metres, from its start to where it stopped or dropped (ShotAttempt.ghostPaths).
        let cue: [Vec2]
        /// Where it came to rest; nil when it dropped.
        let rest: Vec2?
    }
    private(set) var answerPath: AnswerPath?
    /// Whether the answer's path is drawn on the cloth: the card's Show / Hide the answer's path. Cleared by begin,
    /// next, end and watch, so it is always the player's own choice for the try in front of them.
    var showAnswerPath = false

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

    /// Balls and pockets to mark on the table: the balls the goal names and the pockets they must drop in, and the
    /// circle the cue ball must finish in (Stop Dead's, 0.7.5; the same shape as LessonMode.markers, drawn by the same
    /// GoalMarks). Shown while the shot is set up and while the player lines up, not while anything is moving.
    var markers: (balls: [Int], pockets: [Int], zone: TrickZone?)? {
        guard let shot = current else { return nil }
        switch phase {
        case .ready, .aiming, .judged, .offScript:
            break
        default:
            return nil
        }
        if let first = shot.goal.firstHit, let second = shot.goal.secondHit {
            return ([first, second], [], nil)
        }
        return (shot.goal.drops.map(\.ball), shot.goal.drops.compactMap(\.pocket), shot.goal.cueZone)
    }

    /// True once this shot's answer has been watched, so its path can be offered beside a try.
    var hasAnswerPath: Bool {
        guard let shot = current, let path = answerPath else { return false }
        return path.shotID == shot.id && !path.cue.isEmpty
    }

    /// Whether the card offers Show / Hide the answer's path: while the player lines up or reads the verdict.
    var offersAnswerPath: Bool {
        guard hasAnswerPath else { return false }
        return phase == .aiming || isJudged
    }

    /// The answer's path to draw on the cloth now, or nil.
    var answerPathOnCloth: AnswerPath? {
        offersAnswerPath && showAnswerPath ? answerPath : nil
    }

    // MARK: Flow

    /// Put a trick shot on the table, ready to watch or try. Closes the menu and the list.
    func begin(_ shot: TrickShot) {
        guard !shot.pending else { return }
        current = shot
        listOpen = false
        showAnswerPath = false
        // Another shot's answer path is of no use here; this shot's is kept (it was watched).
        if answerPath?.shotID != shot.id { answerPath = nil }
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

    /// Watch it: the answer, at full speed, riding behind the cue ball. When it has played, update() replays it slowly
    /// in the Lens, the break too (0.7.6).
    func watch() {
        guard let shot = current else { return }
        rememberPlayerSettings()
        showAnswerPath = false
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
        showAnswerPath = false
    }

    /// Watch yours (0.7.4): after a make, the player's own stroke replays slowly in the Lens, holding the same moments
    /// the answer's replay held (TrickSignature, found in this recording). The recording and its version do not change,
    /// so nothing is judged again and the phase stays judged; replay(withLens:) counts it as the player's replay (the
    /// phase is not watching or explaining), so the Lens tips may join it as they do on any replay the player starts.
    func watchYours() {
        guard let shot = current, isJudged, model.currentAttempt != nil else { return }
        ride(false)
        model.setPaceSignature(TrickSignature.events(forTrick: shot.id, in: model.timeline, captions: model.captions))
        model.replay(withLens: true)
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
            // Keep the answer's own cue-ball path for Show the answer's path after the player's tries (0.7.4).
            if let a = model.currentAttempt {
                answerPath = AnswerPath(shotID: shot.id, cue: a.ghostPaths().cue, rest: a.cueBallScratched ? nil : a.cueRest)
            }
            // The answer replays now, holding the moments the shot is about (TrickSignature: the jump's take-off and
            // landing, the massé's bend, the break's push into the rack and the called ball dropping, ...). The
            // signature is set before the replay, so the pace plan the replay reads already holds it. The break too
            // (0.7.6, entry 22): it used to be skipped on the belief that a break replays itself slowly in its opening,
            // but since 0.7.1 a struck break plays once at real speed with the Lens off, so The Called Break was the one
            // trick whose Watch it never explained anything.
            model.setPaceSignature(TrickSignature.events(forTrick: shot.id, in: model.timeline, captions: model.captions))
            model.replay(withLens: true)
        case .ready, .aiming, .judged, .offScript:
            // While explaining, a shot of the player's is never judged: it may be a retry of the answer itself.
            guard let attempt = model.currentAttempt, model.timelineVersion != judgedVersion,
                  model.timelineVersion != solutionVersion else { return }
            judgedVersion = model.timelineVersion
            guard startsAtTrick(attempt) else { phase = .offScript; return }
            // The cue angle too (0.7.5): without it, Your turn after Watch it put a raised cue back to level.
            playerSettings[shot.id] = TrickSettings(aim: attempt.aim, power: attempt.power, tipUp: attempt.tipUp,
                                                    tipSide: attempt.tipSide,
                                                    elevation: attempt.elevation > 0 ? attempt.elevation : nil)
            let verdict = TrickShotJudge.verdict(for: shot, attempt: attempt)
            // The trick card is the one result card: it carries the retry's one-sentence difference itself, and the
            // general comparison card hides while this mode is active (ComparisonCard), so the facts are kept, not
            // dismissed, for the card to read.
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

    /// Keep what the player had dialled in before the answer replaces it on the table, the cue angle included (0.7.5;
    /// the break is always struck level).
    private func rememberPlayerSettings() {
        guard let shot = current, phase == .ready || phase == .aiming || phase == .offScript || isJudged else { return }
        playerSettings[shot.id] = shot.isBreak
            ? TrickSettings(aim: model.aimOffset, power: model.power, tipUp: model.tipHeight, tipSide: model.breakTipSide)
            : TrickSettings(aim: model.aimDegrees, power: model.shotPower, tipUp: model.shotTipUp, tipSide: model.shotTipSide,
                            elevation: model.shotElevation > 0 ? model.shotElevation : nil)
    }

    private var isJudged: Bool { if case .judged = phase { return true } else { return false } }

    /// The model re-solved the recording on screen (a surface change, ShowpieceModel.setSurface): the one with version
    /// `old` is now `new`. Before 0.7.5 the answer's version no longer matched, so a surface picked while the answer
    /// played left update() waiting for ever and the explanation never came. Now the versions this mode keeps follow
    /// the recording (RecordingFollow), and an answer being explained is explained again on the new cloth: its kept
    /// path rebuilt from the new recording, its moments found again, and the slow Lens replay started over.
    func recordingReplaced(old: Int, new: Int) {
        guard let shot = current else { return }
        RecordingFollow.move(&solutionVersion, old: old, new: new)
        RecordingFollow.move(&judgedVersion, old: old, new: new)
        // The break is explained again like any other answer (0.7.6, entry 22).
        guard phase == .explaining, solutionVersion == new else { return }
        // setSurface calls this before it swaps in the re-solved attempt, so the attempt is resolved here from the new
        // recording (the one on screen now) rather than read from model.currentAttempt, which still holds the old one.
        if let a = RecordingFollow.attemptOnScreen(model) {
            answerPath = AnswerPath(shotID: shot.id, cue: a.ghostPaths().cue, rest: a.cueBallScratched ? nil : a.cueRest)
        }
        model.setPaceSignature(TrickSignature.events(forTrick: shot.id, in: model.timeline, captions: model.captions))
        model.replay(withLens: true)
    }

    /// True when an attempt started from this trick's own start (not from wherever the last shot left the balls).
    func startsAtTrick(_ attempt: ShotAttempt) -> Bool {
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

/// The part of following a re-solved recording (0.7.5, a surface change mid-answer) that TrickShotMode and LessonMode
/// share, written once: a recording version a mode keeps moves from the old number to the new one, and the attempt on
/// screen is read from the new recording. ShowpieceModel.setSurface calls each mode's recordingReplaced(old:new:)
/// right after loading the re-solved recording and before it swaps in the re-solved attempt, so model.currentAttempt
/// still holds the old timeline at that moment; attemptOnScreen resolves it onto the new one, as setSurface itself
/// does a moment later (ShotAttempt.resolved, on the model's surface, which setSurface has already changed).
@MainActor
enum RecordingFollow {
    /// A kept version that named the old recording now names the new one; any other version is left alone.
    static func move(_ version: inout Int, old: Int, new: Int) {
        if version == old { version = new }
    }

    /// The attempt on screen, on the recording the model has just loaded.
    static func attemptOnScreen(_ model: ShowpieceModel) -> ShotAttempt? {
        model.currentAttempt?.resolved(on: model.timeline, surface: model.surface)
    }
}
