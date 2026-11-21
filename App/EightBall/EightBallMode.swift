// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the screens builder's pass: only your own group's balls, or the 8 once
//          they are gone, can be called, with a short note when another ball is tapped; the rings on the table are one
//          Equatable value (marks) that also shows faintly what can be tapped next; Back out of calling; Shoot with the
//          same call; the hint returns to aiming when a call is already made; the Physics Lens replay of your shot; the
//          "On a real table" switch and the escape it describes; the cue angle for jumps and masses (the shot panel has
//          no elevation control); Reset after a shot taken with no call).
// PURPOSE: Behind the 8-Ball flow, modelled on TrickShotMode. Holds which situation is on the table and walks the
//          player through it: Looking (the table set up, the story card) > Calling (tap a ball, then a pocket, or tap
//          Safety) > Aiming (the shot panel open, the player's own settings, never the answer) > Playing (the shot is
//          rolling) > Scored (the verdict from EightBallJudge: made as called, difficulty, named style points, total,
//          medal, then the "On a real table" card). Watching is the optional hint: the authored escape plays, and that
//          situation's style is then capped at 2 (design decision 6).
//          Tries: the first three scored tries of a visit count (each retry costs a point, applied by the verdict);
//          after that the shot is practice and is not stored.
//          It drives the table only through ShowpieceModel's own methods (enterEightBallTable, loadTrickLayout,
//          setSurface, shootNow, tryAgain, replay, setLens, setRide, shotElevation), and learns that a shot has finished
//          from the model's aimReady and timelineVersion, which EightBallTableLayer forwards to update(). An attempt is
//          judged only when it started from the situation's own setup and a call was made.
//          Best totals and medals are stored in UserDefaults under "eightBallBest" and "eightBallMedals" (dictionaries
//          of situation id to Int; a medal is its raw value).
//          Entering puts the situation's surface on through model.setSurface (menu, 3D cloth and solver agree);
//          end() puts the player's own surface back.
//          Launch flags (handled by EightBallTableLayer): -eightList opens the list, -eight <id> sets a situation up,
//          and -eightPlay <escape id> then plays that escape as a judged try (for testing the scorecard); -eightAim
//          <escape id> only lines it up with the call made, and -eightWatch <escape id> plays it as the hint.
// SRP/DRY check: Pass - flow only. Data is EightBallSituations, judging EightBallJudge, views EightBallViews; the table
//          is driven through ShowpieceModel's existing trick-shot methods, not copies of them.
import BreakdownLensModel
import BreakdownPhysics
import Foundation
import Observation

/// What to ring on the table: strong rings on the called (or picked) ball and pocket, faint rings on what can be
/// tapped next while calling. Ball numbers and solver pocket indices.
struct EightBallMarks: Equatable {
    var balls: [Int] = []
    var pockets: [Int] = []
    var faintBalls: [Int] = []
    var faintPockets: [Int] = []
}

@MainActor
@Observable
final class EightBallMode {
    enum Phase: Equatable {
        /// No situation on the table.
        case off
        /// Set up, the story on the card; waiting for Make your call (or a hint).
        case looking
        /// Tapping a ball, then a pocket, or Safety.
        case calling
        /// The authored escape is playing as a hint.
        case watching
        /// The call is made; the player lines up.
        case aiming
        /// The player's shot is rolling.
        case playing
        /// The attempt is over and scored.
        case scored(EightBallVerdict)
    }

    /// The model this mode drives. The model owns the mode, so this does not keep the model alive.
    @ObservationIgnored unowned let model: ShowpieceModel

    private(set) var current: EightBallSituation?
    private(set) var phase: Phase = .off
    /// The list sheet; opened from the menu.
    var listOpen = false
    /// The call for the next shot, once made.
    private(set) var call: EightBallCall?
    /// While calling: the ball tapped, waiting for its pocket.
    private(set) var pendingBall: Int?
    /// While calling: one short line when a tap could not be used (not your ball, not the 8 yet).
    private(set) var callNote: String?
    /// Scored tries in this visit to the current situation (the next try is tries + 1).
    private(set) var tries = 0
    /// The last verdict of this visit, kept for the real-table card after the scored card is dismissed.
    private(set) var lastVerdict: EightBallVerdict?
    /// Situations whose authored escape was watched in this visit (style capped at 2).
    private(set) var hintWatched: Set<String> = []
    /// Bumped on every make, so the views can fire one haptic and one glow per success.
    private(set) var celebrations = 0
    /// The scored card shows the "On a real table" card instead of the score while this is on.
    var showingRealTable = false
    /// What the shot panel should be; applied by the table layer when aimingRequests changes.
    private(set) var wantsAiming = false
    private(set) var aimingRequests = 0
    /// Stored best totals and medals per situation id.
    private(set) var bestScores: [String: Int]
    private(set) var medals: [String: EightBallMedal]

    @ObservationIgnored private var playerSettings: [String: TrickSettings] = [:]
    @ObservationIgnored private var judgedVersion = -1
    @ObservationIgnored private var hintVersion = -1
    /// The player's own surface from before the mode, put back by end(): setSurface stores the choice, and a situation
    /// set on dive-bar felt must not leave the player on it after they leave.
    @ObservationIgnored private var surfaceBefore: PlaySurface?

    private static let bestKey = "eightBallBest"
    private static let medalsKey = "eightBallMedals"

    init(model: ShowpieceModel) {
        self.model = model
        let d = UserDefaults.standard
        bestScores = (d.dictionary(forKey: Self.bestKey) as? [String: Int]) ?? [:]
        let raw = (d.dictionary(forKey: Self.medalsKey) as? [String: Int]) ?? [:]
        medals = raw.compactMapValues(EightBallMedal.init(rawValue:))
    }

    var isActive: Bool { current != nil && phase != .off }
    func best(_ s: EightBallSituation) -> Int? { bestScores[s.id] }
    func medal(_ s: EightBallSituation) -> EightBallMedal? { medals[s.id] }
    /// The running total over every situation's best.
    var runningTotal: Int { bestScores.values.reduce(0, +) }
    /// The try the next shot will be (above EightBallVerdict.maxTries it is practice).
    var nextTry: Int { tries + 1 }
    /// True once an escape was watched in this visit: style is capped at 2 here.
    var hintTaken: Bool { current.map { hintWatched.contains($0.id) } ?? false }

    /// The bridge is drawn under the cue while the player lines up in a situation whose escapes need it.
    var showsBridge: Bool { current?.usesBridge == true && phase == .aiming }

    /// True while the balls sit where the situation put them (false after a shot taken with no call).
    var isAtStart: Bool {
        guard let s = current else { return false }
        return model.layout == s.setup
    }

    /// The balls that may be called: your group's balls still up, or the 8 once they are gone.
    var callableBalls: [Int] {
        guard let s = current, model.layout.count == 16 else { return [] }
        return s.legalBalls.filter { NextShot.isOnTable(model.layout[$0]) }
    }

    /// The rings on the table. While calling, before a ball is picked, the callable balls show faintly; after, the six
    /// pockets do. Once called, the ball and pocket stay ringed while aiming and on the scored card.
    var marks: EightBallMarks? {
        guard current != nil else { return nil }
        switch phase {
        case .calling:
            if let b = pendingBall {
                return EightBallMarks(balls: [b], faintPockets: EightBallPocket.allCases.map(\.rawValue))
            }
            return EightBallMarks(faintBalls: callableBalls)
        case .aiming, .scored:
            if let call, case .ball(let b, let p) = call { return EightBallMarks(balls: [b], pockets: [p.rawValue]) }
            return nil
        default:
            return nil
        }
    }

    /// The legacy pair form of the rings (called ball and pocket only), kept for anything that reads it.
    var markers: (balls: [Int], pockets: [Int])? {
        guard let m = marks, !m.balls.isEmpty || !m.pockets.isEmpty else { return nil }
        return (m.balls, m.pockets)
    }

    /// The escape the "On a real table" card describes after a verdict: the one the shot matched, else the one whose
    /// call is the same, else the top-rated one. Nil when the situation has no escapes.
    func escapeForCard(_ v: EightBallVerdict?) -> EightBallEscape? {
        guard let s = current else { return nil }
        if let id = v?.matchedEscape, let e = s.escapes.first(where: { $0.id == id }) { return e }
        if let c = v?.call, let e = s.escapes.first(where: { $0.call == c }) { return e }
        return s.escapes.max { $0.rating < $1.rating }
    }

    // MARK: Flow

    /// Put a situation on the table: the menu and the list close, trick shots end, the situation's cloth is chosen.
    func begin(_ s: EightBallSituation) {
        // Only on a fresh entry: going from one situation to the next must not record the last one's cloth as theirs.
        if current == nil { surfaceBefore = model.surface }
        if phase == .watching { model.setRide(false) }
        current = s
        listOpen = false
        tries = 0
        lastVerdict = nil
        showingRealTable = false
        hintWatched.remove(s.id)
        call = nil
        pendingBall = nil
        callNote = nil
        model.enterEightBallTable()
        // Through the model's own surface change, so the Surface menu, the 3D cloth and the solver agree.
        model.setSurface(s.surface)
        loadStart(with: playerSettings[s.id] ?? Self.defaultSettings)
        if playerSettings[s.id] == nil { model.aimAtNearestBall() }
        model.setLens(false)
        model.setRide(false)
        phase = .looking
        requestAiming(false)
    }

    func begin(id: String) {
        if let s = EightBallSituations.situation(id: id) { begin(s) }
    }

    /// Make your call: tap a ball, then a pocket. Puts the balls back first if an uncalled shot moved them.
    func startCalling() {
        guard current != nil else { return }
        if !isAtStart { resetTable() }
        pendingBall = nil
        callNote = nil
        showingRealTable = false
        phase = .calling
        requestAiming(false)
    }

    /// Leave calling without a new call: back to aiming with the old call if there is one, else to the story.
    func cancelCalling() {
        guard phase == .calling else { return }
        pendingBall = nil
        callNote = nil
        if call != nil { openAiming() } else { phase = .looking }
    }

    /// While calling: a tap on a ball. Only a callable ball is taken; any other ball gets a short note instead.
    func pick(ball: Int) {
        guard phase == .calling, let s = current, ball > 0, ball < 16, model.layout.count == 16,
              NextShot.isOnTable(model.layout[ball]) else { return }
        if callableBalls.contains(ball) {
            pendingBall = ball
            callNote = nil
        } else if ball == 8 {
            callNote = String(localized: "Not the 8 yet. Clear your own balls first.")
        } else if EightBallGroup.of(ball: ball) == s.group.other {
            callNote = String(localized: "That's your opponent's ball. You're on \(s.group.title).")
        }
    }

    /// While calling: a tap on a pocket after a ball. The call is made and aiming opens.
    func pick(pocket: EightBallPocket) {
        guard phase == .calling, let b = pendingBall else { return }
        call = .ball(b, pocket: pocket)
        pendingBall = nil
        callNote = nil
        openAiming()
    }

    func callSafety() {
        guard phase == .calling else { return }
        call = .safety
        pendingBall = nil
        callNote = nil
        openAiming()
    }

    /// Test route (-eightPlay <escape id>): make the escape's own call, line up its stroke and shoot it as a normal,
    /// judged try. Not a hint, so nothing is capped. Lets a made shot and its scorecard be checked without a hand on
    /// the sliders.
    func playAsTry(_ escape: EightBallEscape, shoot: Bool = true) {
        guard current != nil else { return }
        call = escape.call
        pendingBall = nil
        callNote = nil
        loadStart(with: escape.settings)
        openAiming()
        if shoot { model.shootNow() }
    }

    /// Line up again with the call already made (from the story card after a hint, for example).
    func aimWithCall() {
        guard current != nil, call != nil else { startCalling(); return }
        if !isAtStart { resetTable() }
        openAiming()
    }

    /// The hint: the authored escape plays at full speed with the ride camera. Caps this visit's style at 2.
    func watch(_ escape: EightBallEscape) {
        guard let s = current else { return }
        rememberPlayerSettings()
        hintWatched.insert(s.id)
        showingRealTable = false
        pendingBall = nil
        callNote = nil
        loadStart(with: escape.settings)
        model.setLens(false)
        requestAiming(false)
        phase = .watching
        model.setRide(true)
        model.shootNow()
        hintVersion = model.timelineVersion
    }

    /// Stop the hint early: the table jumps to where the escape left the balls, and update() moves on.
    func skipHint() {
        guard phase == .watching else { return }
        model.skipToResult()
        update()
    }

    /// Back to the start with the same call and settings (the model's own retry, keeping the last try as a ghost).
    func tryAgain() {
        guard let s = current else { return }
        showingRealTable = false
        model.setLens(false)
        model.setRide(false)
        if model.canTryAgain, let a = model.currentAttempt, !a.isBreak, a.start == s.setup,
           model.timelineVersion != hintVersion {
            model.tryAgain()
            model.dismissComparison()
        } else {
            loadStart(with: playerSettings[s.id] ?? Self.defaultSettings)
        }
        if call == nil { startCalling() } else { openAiming() }
    }

    /// Replay the shot on screen slowly in the Physics Lens, which explains it beat by beat.
    func lensReplay() {
        guard current != nil else { return }
        showingRealTable = false
        model.setRide(false)
        model.replay(withLens: true)
    }

    /// Put the situation back on the table with the player's settings (after a shot taken with no call).
    func resetTable() {
        guard let s = current else { return }
        model.setLens(false)
        loadStart(with: playerSettings[s.id] ?? Self.defaultSettings)
    }

    /// The next situation in the list, or the list itself after the last one.
    func next() {
        guard let s = current, let i = EightBallSituations.all.firstIndex(where: { $0.id == s.id }),
              i + 1 < EightBallSituations.all.count else { listOpen = true; return }
        begin(EightBallSituations.all[i + 1])
    }

    /// Leave the mode (free play, trick shots or the break from the menu).
    func end() {
        if phase == .watching { model.setRide(false) }
        if let before = surfaceBefore { model.setSurface(before) }
        surfaceBefore = nil
        current = nil
        phase = .off
        call = nil
        pendingBall = nil
        callNote = nil
        showingRealTable = false
        wantsAiming = false
    }

    // MARK: The cue angle

    /// The cue angles offered while aiming, in degrees above level (0 is a level cue). The shot panel has no
    /// elevation control, so the card offers these for jumps and masses.
    static let cueAngles = [0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80]

    /// The cue angle now, in whole degrees, snapped to the nearest offered angle. Setting it writes the sine, the
    /// solver's unit, into the model's next shot.
    var cueAngle: Int {
        get {
            let degrees = asin(min(max(model.shotElevation, 0), 0.995)) * 180 / .pi
            return Self.cueAngles.min { abs(Double($0) - degrees) < abs(Double($1) - degrees) } ?? 0
        }
        set {
            model.shotElevation = newValue <= 0 ? 0 : sin(Double(newValue) * .pi / 180)
        }
    }

    // MARK: Following the table

    /// Called by the table layer whenever the model's playback state changes.
    func update() {
        guard let s = current else { return }
        // A shot started while aiming: it is now rolling.
        if phase == .aiming, !model.aimReady, model.timelineVersion != judgedVersion { phase = .playing; return }
        guard model.aimReady else { return }
        switch phase {
        case .watching:
            guard model.timelineVersion == hintVersion else { return }
            model.setRide(false)
            loadStart(with: playerSettings[s.id] ?? Self.defaultSettings)
            // With a call already made, the player goes straight back to lining up; otherwise to the story card.
            if call != nil { openAiming() } else { phase = .looking }
        case .playing, .aiming, .scored:
            guard let attempt = model.currentAttempt, let call, model.timelineVersion != judgedVersion,
                  model.timelineVersion != hintVersion else { return }
            judgedVersion = model.timelineVersion
            guard !attempt.isBreak, attempt.start == s.setup else { return }
            let settings = TrickSettings(aim: attempt.aim, power: attempt.power, tipUp: attempt.tipUp,
                                         tipSide: attempt.tipSide,
                                         elevation: model.shotElevation > 0 ? model.shotElevation : nil)
            playerSettings[s.id] = settings
            tries += 1
            var verdict = EightBallJudge.judge(timeline: attempt.timeline, call: call, situation: s,
                                               settings: settings, surface: model.physicsSurface, attempt: tries)
            if hintWatched.contains(s.id) { verdict = verdict.cappingStyle(at: EightBallVerdict.hintStyleCap) }
            model.dismissComparison()
            lastVerdict = verdict
            showingRealTable = false
            phase = .scored(verdict)
            requestAiming(false)
            record(verdict, for: s)
        default:
            break
        }
    }

    // MARK: Pieces

    /// A medium level stroke through the middle; the aim is then pointed at the nearest ball.
    private static let defaultSettings = TrickSettings(aim: 0, power: 3, tipUp: 0, tipSide: 0)

    private func loadStart(with st: TrickSettings) {
        guard let s = current else { return }
        model.loadTrickLayout(s.setup, aim: st.aim, power: st.power, tipUp: st.tipUp, tipSide: st.tipSide,
                              elevation: st.elevation ?? 0)
    }

    private func rememberPlayerSettings() {
        guard let s = current else { return }
        playerSettings[s.id] = TrickSettings(aim: model.aimDegrees, power: model.shotPower, tipUp: model.shotTipUp,
                                             tipSide: model.shotTipSide,
                                             elevation: model.shotElevation > 0 ? model.shotElevation : nil)
    }

    private func openAiming() {
        phase = .aiming
        requestAiming(true)
    }

    /// Keep the best total and the best medal; practice tries are never stored.
    private func record(_ v: EightBallVerdict, for s: EightBallSituation) {
        guard !v.isPractice else { return }
        if v.medal != nil { celebrations += 1 }
        let d = UserDefaults.standard
        if v.total > (bestScores[s.id] ?? -1) {
            bestScores[s.id] = v.total
            d.set(bestScores, forKey: Self.bestKey)
        }
        if let m = v.medal, medals[s.id].map({ m > $0 }) ?? true {
            medals[s.id] = m
            d.set(medals.mapValues(\.rawValue), forKey: Self.medalsKey)
        }
    }

    private func requestAiming(_ open: Bool) {
        wantsAiming = open
        aimingRequests += 1
    }
}
