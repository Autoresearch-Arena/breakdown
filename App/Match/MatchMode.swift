// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (opponent stream: a match can seat the computer (Player.computer, a
//          ComputerLevel). MatchOpponent (App/Match/MatchOpponent.swift) is held here and run from update() while the
//          match is aiming; computerSeatToAct says whose decision is due, and the person's taps (readyToShoot, setCall,
//          answer, and the model's cue-ball placement) are refused on the computer's turn unless the computer itself
//          is acting (computerActing). Against the computer there is no hand-over: the device stays with the person.
//          Rematch keeps who is the computer. Every ruling plays its moment (SoundBoard.play: win, foul, turn change),
//          and a game the rules finish is counted in the on-device record (MatchRecord).)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens) - the three table games play from first shot to a
//          result: a match can start with one player where the rules allow it (bar billiards alone); after each shot
//          the next table comes from the table's own rules (BumperPoolRules, FivePinRules and BarBilliardsRules
//          nextLayout, on the recorded TableSpec, so balls go back to their own spots clear of bumpers, pins and
//          holes, pins stand again and the next white sits on the D) instead of the pool foot spot; the bar-billiards
//          clock is a real-time clock fed every frame by the model (tickClock) and paused by MatchClock's rule
//          (replays, the Lens, solving, cards, the menu) instead of charging each shot its recording's length; each
//          shot keeps the ball that was struck and the points explained (TablePoints) for the ruling card; a finished
//          one-player bar-billiards game records its best score on the device (BarBilliardsBest).
// PURPOSE: A match for two on one device (plans/21-Nov-2026-rules-games-plan.md package 3 steps 4, 7 and 8, package 4
//          step 3, model side). MatchMode owns the MatchState and one `any MatchRules` (EightBallRules, NineBallRules,
//          or a table's rules from the BreakdownRules module) and runs the turn loop:
//            aiming    - the shooter lines up (placing the cue ball first when they have ball in hand) and, in a
//                        game with calls, picks ball and pocket; ShowpieceModel.fire() asks readyToShoot.
//            shooting  - the model is solving and playing the shot. The ruling waits until the replay has played
//                        out or been skipped (the model's aimReady), so the Lens, replay and Ride work on every shot.
//            ruling    - the shot was read (ShotFacts, built with the striking player's cue ball) and ruled; the
//                        state and the layout for the next shot are saved to the app's support folder.
//            handOver  - the turn passed: the device goes to the other player.
//            over      - a result; rematch() starts the next game with the other player breaking.
//          The ruling's bookkeeping is the rules' own applying(_:facts:to:); this class only places balls (spots,
//          re-racks, the default spot of a scratched cue ball) and tells the model what to show. Saved as SavedMatch
//          (JSON, Application Support/Breakdown/match.json) after every ruling and every answered choice; the model
//          offers it again as "Continue match" (hasSavedMatch, continueSavedMatch) after the app is quit.
//          Contract: docs/award-batch-contracts.md section 2.2. The words for rulings and turns are the match views'
//          (App/Match/MatchViews.swift); this file holds no player text except the default player names.
// SRP/DRY check: Pass - checked EightBallMode (the shape: an observable mode that drives the model and reads the
//          recording, never re-solving), BreakdownRules (all rule decisions and the bookkeeping default live there),
//          NextShot (spotting and the head spot), ShowpieceModel (rack positions and putting a still table on screen
//          are its helpers, used here, not repeated). Nothing else in the app runs a match.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import Observation

/// What is on the table between shots of a match: the positions, whether they are a rack waiting for a break, and the
/// seed the rack was built from (the break strikes with it). Saved with the state.
struct MatchTableSetup: Codable, Equatable {
    var layout: [Vec2]
    var racked: Bool
    var rackSeed: UInt64
}

/// The saved match: everything needed to put the same table and the same turn back after the app is quit.
struct SavedMatch: Codable {
    /// Bumped if this shape ever changes incompatibly; a file with another number is not offered.
    static let currentFormat = 1
    var format: Int
    var state: MatchState
    var setup: MatchTableSetup
    /// Who broke the first game, so a rematch alternates the break.
    var firstBreaker: PlayerID
}

@MainActor
@Observable
final class MatchMode {
    enum Phase: Equatable { case aiming, shooting, ruling, handOver, over }

    let rules: any MatchRules
    /// The table this game is played on (the pool table for eight-ball and nine-ball).
    let table: TableKind
    private(set) var state: MatchState
    private(set) var phase: Phase = .aiming
    /// The shooter's call for the next shot (games with calls only).
    private(set) var currentCall: EightBallCall?
    /// The ruling on the last shot (or the last answered choice), for the ruling card.
    private(set) var lastRuling: Ruling?
    /// The ball struck on the last shot (the cue ball of the player who shot, read before the ruling moved the turn
    /// on), so the ruling card names the right ball on tables where each player has their own.
    private(set) var lastShotBall: Int?
    /// Five-pin and bar billiards: how the last shot's points came, line by line (empty for the other games).
    private(set) var lastPoints: [TablePoints.Line] = []
    /// A finished one-player bar-billiards game: what it did to the best score on this device.
    private(set) var bestOutcome: BarBilliardsBest.Outcome?

    @ObservationIgnored unowned let model: ShowpieceModel
    /// What is on the table now between shots (saved), and what goes on it once the ruling card is dismissed.
    @ObservationIgnored private(set) var setup: MatchTableSetup
    @ObservationIgnored private var nextSetup: MatchTableSetup?
    /// The shot being played: where it started, the call it was played with, and the model's timelineVersion of its
    /// recording (nil until the background solve has delivered it).
    @ObservationIgnored private var shotStart: [Vec2] = []
    @ObservationIgnored private var shotCall: EightBallCall?
    @ObservationIgnored private var shotVersion: Int?
    @ObservationIgnored private var firstBreaker: PlayerID
    /// The game clock to the fraction of a second. The observed state's clockRemaining is only updated when the whole
    /// second shown changes (and before every ruling and save), so the banner redraws once a second, not every frame.
    /// Nil until the clock first runs, and after anything replaces the state; it then starts from the state.
    @ObservationIgnored private var clockExact: Double?
    /// The furthest point of the shot's recording shown so far: the clock runs only while the replay moves past it
    /// (the shot's first showing), never while the player rewinds and watches again.
    @ObservationIgnored private var shotSeenUpTo = 0.0

    /// The computer player, when one sits at this match; nil for a match between people.
    private(set) var opponent: MatchOpponent?
    /// True only while the computer itself is taking its turn (MatchOpponent.perform): the one time the guards below
    /// let a stroke, call, answer or cue-ball placement through on the computer's turn.
    @ObservationIgnored var computerActing = false

    /// A new match of `kind`, not yet on the table (start() puts it there). `players` is how many play, kept within
    /// what the rules allow; nil means two wherever the game takes two. With `computer` set, the second seat is the
    /// computer at that level; the person sits first and breaks the first game.
    init(model: ShowpieceModel, kind: MatchKind, players: Int? = nil, computer: ComputerLevel? = nil) {
        self.model = model
        let r = Self.rules(for: kind)
        rules = r
        table = Self.table(for: kind)
        let seats = players.map { min(max($0, r.playerCount.lowerBound), r.playerCount.upperBound) } ?? Self.seats(for: r)
        var fresh = r.initialState(playerNames: Self.defaultNames(count: seats))
        if let level = computer, fresh.players.count > 1 {
            fresh.players[1].computer = level
            fresh.players[1].name = OpponentWords.name(level)
        }
        state = fresh
        firstBreaker = fresh.turn
        setup = MatchTableSetup(layout: [], racked: false, rackSeed: 0)
        if fresh.players.contains(where: \.isComputer) { opponent = MatchOpponent() }
    }

    /// A saved match, not yet on the table (resume() puts it there).
    init(model: ShowpieceModel, restoring saved: SavedMatch) {
        self.model = model
        rules = Self.rules(for: saved.state.kind)
        table = Self.table(for: saved.state.kind)
        state = saved.state
        firstBreaker = saved.firstBreaker
        setup = saved.setup
        if saved.state.players.contains(where: \.isComputer) { opponent = MatchOpponent() }
    }

    // MARK: What the views read

    var mustCall: Bool { rules.usesCalls && !state.isBreak }
    var playerNames: [String] { state.players.map(\.name) }
    /// The ball the current shooter strikes.
    var cueBallIndex: Int { rules.cueBall(for: state.turn, in: state) }
    /// True when this game is played from one of the two pool racks (the model keeps the pool table for it).
    var isPoolGame: Bool {
        switch rules.rack {
        case .fifteenBallTriangle, .nineBallDiamond: return true
        case .tableLayout: return false
        }
    }
    /// True when the next shot may be struck: aiming, no choice waiting, and a call made where one is needed. On the
    /// computer's turn only the computer may strike.
    var readyToShoot: Bool {
        phase == .aiming && state.pendingChoice == nil && !state.isOver && (!mustCall || currentCall != nil)
            && personMayAct
    }

    /// True when the computer plays this seat.
    func isComputer(_ player: PlayerID) -> Bool {
        state.players.indices.contains(player.index) && state.players[player.index].isComputer
    }

    /// The computer seat whose decision is due now: the chooser of a pending choice, otherwise the shooter. Nil when
    /// the decision is a person's (or nothing is due).
    var computerSeatToAct: PlayerID? {
        guard phase == .aiming, !state.isOver else { return nil }
        if let pending = state.pendingChoice { return isComputer(pending.chooser) ? pending.chooser : nil }
        return isComputer(state.turn) ? state.turn : nil
    }

    /// False while it is the computer's decision and the computer is not the one acting: the person's taps on the
    /// table, the call control and the choice buttons are then ignored.
    var personMayAct: Bool { computerSeatToAct == nil || computerActing }

    /// True when the computer plays one of the seats (no hand-over between turns: the device stays with the person).
    var hasComputer: Bool { state.players.contains(where: \.isComputer) }

    // MARK: Turn loop

    /// Put a new match on the table: the rack, the first breaker to aim.
    func start() {
        setup = model.matchSetup(for: rules.rack, seed: Self.freshSeed())
        model.showMatchTable(setup)
        beginTurn()
        save()
    }

    /// Put a restored match on the table where it was saved.
    func resume() {
        model.showMatchTable(setup)
        if state.isOver { phase = .over } else { beginTurn() }
    }

    func setCall(_ call: EightBallCall?) {
        guard phase == .aiming, personMayAct else { return }
        if let ball = call?.ball, !rules.mayCall(ball, in: state) { return }
        currentCall = call
    }

    /// The model has started a shot (called from ShowpieceModel's strike, before the solve).
    func shotFired() {
        shotCall = mustCall ? currentCall : nil
        shotVersion = nil
        phase = .shooting
    }

    /// The shot's recording is on screen (called when the solve lands), with the positions it started from.
    func shotLoaded(version: Int, start: [Vec2]) {
        guard phase == .shooting else { return }
        shotVersion = version
        shotStart = start
        shotSeenUpTo = 0
    }

    /// The model dropped the shot before it was solved (the surface changed while solving): back to aiming.
    func shotCancelled() {
        if phase == .shooting, shotVersion == nil { phase = .aiming }
    }

    /// Called every frame by the model. Rules on the shot once its replay has played out (or been skipped).
    func update() {
        // The computer thinks and plays while the match is aiming; it does nothing on a person's turn.
        if phase == .aiming { opponent?.update(self); return }
        guard phase == .shooting, let v = shotVersion, model.timelineVersion == v, model.aimReady else { return }
        rule()
    }

    /// Read the recording, ask the rules, apply the ruling, work out the next table and save.
    private func rule() {
        let struck = cueBallIndex
        let facts = ShotFacts(timeline: model.timeline, start: shotStart, cueBall: struck)
        var before = state
        // The game clock as it stands now: it ran in real time while the shot was aimed and first played
        // (tickClock), so a shot is judged by the clock at the moment it is ruled, as BarBilliardsRules expects.
        if let exact = clockExact, before.clockRemaining != nil { before.clockRemaining = exact }
        let ruling = rules.ruling(for: facts, call: before.isBreak ? nil : shotCall, in: before)
        let after = rules.applying(ruling, facts: facts, to: before)
        // setupAfter and the points read `before`: BarBilliardsRules' helpers take the state as it stood before the
        // shot (its bar, its balls in the game, its break).
        nextSetup = setupAfter(ruling, facts: facts, before: before, after: after)
        lastPoints = TablePoints.lines(for: facts, ruling: ruling, before: before, after: after, rules: rules)
        lastShotBall = struck
        state = after
        clockExact = after.clockRemaining
        lastRuling = ruling
        currentCall = nil
        phase = .ruling
        Self.playMoment(for: ruling)
        if state.isOver { MatchRecord.noteFinished(state) }
        if after.isOver, after.kind == .barBilliards, after.players.count == 1, let score = after.scores.first {
            bestOutcome = BarBilliardsBest.record(score)
        }
        save()
    }

    /// The match moment a ruling sounds and is felt (SoundBoard.play plays its voice and its haptic together): a win
    /// for the end of the game, a foul, a turn change; nothing when the shooter simply carries on.
    static func moment(for r: Ruling) -> GameMoment? {
        if r.result != nil { return .win }
        if r.fouled { return .foul }
        if r.turnPasses { return .turnChange }
        return nil
    }

    private static func playMoment(for r: Ruling) {
        if let m = moment(for: r) { SoundBoard.play(m) }
    }

    /// Called every frame the table is live (ShowpieceModel.advance; it stops before this while the menu is open)
    /// with the real seconds since the last frame. Runs the game clock by MatchClock's rule; games without a clock
    /// ignore it.
    func tickClock(realSeconds: Double) {
        guard let shown = state.clockRemaining else { return }
        // The shot's first showing is the replay moving past anything already seen of this shot.
        let newGround = phase == .shooting && model.time > shotSeenUpTo
        if phase == .shooting { shotSeenUpTo = max(shotSeenUpTo, model.time) }
        let moment = MatchClock.Moment(hasClock: true, isOver: state.isOver, stage: MatchClock.Stage(phase),
                                       lensOn: model.lensOn, isSolving: model.isSolving, tableAtRest: model.aimReady,
                                       playingNewGround: newGround)
        guard MatchClock.runs(moment) else { return }
        let exact = MatchClock.ticked(clockExact ?? shown, by: MatchClock.seconds(forFrame: realSeconds))
        clockExact = exact
        guard MatchClock.shownSeconds(exact) != MatchClock.shownSeconds(shown) else { return }
        state.clockRemaining = exact
        // Saved once a minute while aiming, so quitting the app costs at most a minute of clock. Not mid-shot: the
        // saved table is then still the one before the shot.
        if phase == .aiming, MatchClock.shownSeconds(exact) % 60 == 0 { save() }
    }

    /// True once the bar-billiards clock has run out (the bar is down).
    var timeIsUp: Bool { state.clockRemaining.map { $0 <= 0 } ?? false }

    /// The ruling card was dismissed (from .ruling), or the next player has the device (from .handOver).
    func acknowledgeRuling() {
        switch phase {
        case .ruling:
            if let s = nextSetup { show(s) }
            nextSetup = nil
            if state.isOver { phase = .over; return }
            let shooter = lastRuling?.shooter ?? state.turn
            let chooserIsOther = state.pendingChoice.map { $0.chooser != shooter } ?? false
            // Against the computer the device never changes hands, so there is no hand-over.
            if (lastRuling?.turnPasses == true || chooserIsOther) && !hasComputer { phase = .handOver } else { beginTurn() }
        case .handOver:
            beginTurn()
        default:
            break
        }
    }

    /// Answer a pending choice (accept the table, spot the 8, or re-rack).
    func answer(_ answer: MatchChoiceAnswer) {
        guard phase == .aiming || phase == .ruling, personMayAct, let pending = state.pendingChoice,
              pending.choice.answers.contains(answer) else { return }
        // The ruling card offers the choice itself (MatchViews), so an answer can arrive before the card is dismissed:
        // the table the ruling left goes on screen first, so spotting reads the right layout.
        if phase == .ruling {
            if let s = nextSetup { show(s) }
            nextSetup = nil
        }
        let before = state
        let ruling = rules.ruling(answering: answer, in: before)
        let after = rules.applying(ruling, facts: nil, to: before)
        let s: MatchTableSetup
        if ruling.rerack {
            s = model.matchSetup(for: rules.rack, seed: Self.freshSeed())
        } else {
            var l = model.layout
            spot(ruling.ballsToSpot, in: &l)
            s = MatchTableSetup(layout: l, racked: setup.racked, rackSeed: setup.rackSeed)
        }
        state = after
        lastRuling = ruling
        show(s)
        Self.playMoment(for: ruling)
        if state.isOver { MatchRecord.noteFinished(state) }
        save()
        if state.isOver {
            phase = .over
        } else if ruling.nextShooter != pending.chooser && !hasComputer {
            phase = .handOver
        } else {
            beginTurn()
        }
    }

    /// The next game with the same players; the other player breaks.
    func rematch() {
        let names = playerNames
        let computers = state.players.map(\.computer)
        firstBreaker = firstBreaker.next(among: names.count)
        var fresh = rules.initialState(playerNames: names)
        // The same seats: whoever was the computer stays the computer, at the same level.
        for i in fresh.players.indices where computers.indices.contains(i) { fresh.players[i].computer = computers[i] }
        opponent?.cancel()
        fresh.turn = firstBreaker
        state = fresh
        lastRuling = nil
        lastShotBall = nil
        lastPoints = []
        bestOutcome = nil
        clockExact = nil
        currentCall = nil
        nextSetup = nil
        start()
    }

    func setPlayerName(_ name: String, for player: PlayerID) {
        guard state.players.indices.contains(player.index) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        state.players[player.index].name = trimmed.isEmpty ? Self.defaultName(seat: player.index) : trimmed
        save()
    }

    // MARK: Pieces

    /// Aiming for the player whose turn it is; with ball in hand the cue ball is lifted for them to place.
    private func beginTurn() {
        phase = .aiming
        currentCall = nil
        model.beginMatchTurn()
    }

    /// Put a table setup on screen, unless the table already shows it (so the replay of the last shot survives a
    /// ruling that moved nothing). Pins that fell are always stood up again: the still table is a fresh solve, which
    /// starts with every pin standing, while the last shot's replay ends with them down.
    private func show(_ s: MatchTableSetup) {
        let unchanged = !s.racked && s.layout == model.layout && !model.racked && model.timeline.pinFalls.isEmpty
        setup = s
        if !unchanged { model.showMatchTable(s) }
    }

    /// The table the next shot starts from: a fresh rack, or where the balls stopped with spotted and returned balls put
    /// back and any player's missing cue ball on its default spot (ball in hand lets them move it from there).
    private func setupAfter(_ ruling: Ruling, facts: ShotFacts, before: MatchState, after: MatchState) -> MatchTableSetup {
        if ruling.rerack { return model.matchSetup(for: rules.rack, seed: Self.freshSeed()) }
        // The other tables put balls back by their own rules; the pool spotting below would use the pool table's foot
        // spot and ignore bumpers, pins and holes.
        if let l = tableLayoutAfter(ruling, facts: facts, before: before) {
            return MatchTableSetup(layout: l, racked: false, rackSeed: setup.rackSeed)
        }
        var l = facts.resting
        spot(ruling.ballsToSpot + rules.ballsReturningToHand(after: facts, in: before), in: &l)
        let p = model.physicsTable.parameters
        for seat in after.players.map(\.id) {
            let c = rules.cueBall(for: seat, in: after)
            guard l.indices.contains(c), !NextShot.isOnTable(l[c]) else { continue }
            // Ball 0 goes to the head spot (respotCueBall already ignores itself); a table's own player ball goes to
            // the nearest free place the spotting rule finds.
            l[c] = c == 0 ? NextShot.respotCueBall(among: l, parameters: p) : NextShot.spot(c, among: l, parameters: p)
        }
        return MatchTableSetup(layout: l, racked: false, rackSeed: setup.rackSeed)
    }

    /// The next layout on one of the other tables, from that table's own rules; nil for the pool games. Each helper
    /// works on the TableSpec the shot was recorded on (the bumpers, pins and holes exactly as the solver had them)
    /// and the table's start layout for the spots balls go back to (bumper pool's starting places; five-pin's white,
    /// yellow and red spots; bar billiards' D, where the first white starts, and the red spot).
    private func tableLayoutAfter(_ ruling: Ruling, facts: ShotFacts, before: MatchState) -> [Vec2]? {
        let spec = model.timeline.table
        let start = table.startLayout ?? []
        switch rules {
        case is BumperPoolRules:
            return BumperPoolRules.nextLayout(after: facts, ruling: ruling, start: start, table: spec)
        case let five as FivePinRules:
            var spots: [Int: Vec2] = [:]
            for b in five.rack.objectBalls where start.indices.contains(b) && NextShot.isOnTable(start[b]) {
                spots[b] = start[b]
            }
            return FivePinRules.nextLayout(after: facts.resting, table: spec, spots: spots)
        case let bar as BarBilliardsRules:
            // BarBilliardsTable.startLayout puts the first white (ball 0) on the D spot and the red on its spot.
            let red = BarBilliardsRules.redBall
            guard start.indices.contains(0), start.indices.contains(red) else { return facts.resting }
            return bar.nextLayout(after: facts, in: before, table: spec, dSpot: start[0], redSpot: start[red])
        default:
            return nil
        }
    }

    /// Put balls back on the table one by one (each is lifted first, so its old place never blocks its new one).
    private func spot(_ balls: [Int], in l: inout [Vec2]) {
        let p = model.physicsTable.parameters
        for b in balls where l.indices.contains(b) {
            l[b] = NextShot.offTable
            l[b] = NextShot.spot(b, among: l, parameters: p)
        }
    }

    // MARK: Saving

    /// Write the state and the table the next shot starts from. A finished game leaves nothing to continue, so its
    /// file is removed instead.
    private func save() {
        if state.isOver {
            Self.deleteSave()
            model.noteMatchSave(exists: false)
            return
        }
        guard let url = Self.saveURL else { return }
        // While aiming, the clock to the moment it really stands at, not the last whole second shown.
        if let exact = clockExact, state.clockRemaining != nil, phase == .aiming { state.clockRemaining = exact }
        let saved = SavedMatch(format: SavedMatch.currentFormat, state: state, setup: nextSetup ?? setup,
                               firstBreaker: firstBreaker)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(saved).write(to: url, options: .atomic)
            model.noteMatchSave(exists: true)
        } catch {
            // Not fatal: the match plays on; only resuming after a quit is lost. Logged so it is never silent.
            NSLog("MatchMode: could not save the match to %@: %@", url.path, error.localizedDescription)
        }
    }

    /// Application Support/Breakdown/match.json (the app's support folder; created on first save).
    static var saveURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Breakdown", isDirectory: true)
            .appendingPathComponent("match.json")
    }

    static var saveExists: Bool { saveURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false }

    /// The saved match, or nil when there is none, it cannot be read, or it was written in another format.
    static func loadSaved() -> SavedMatch? {
        guard let url = saveURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let saved = try JSONDecoder().decode(SavedMatch.self, from: Data(contentsOf: url))
            guard saved.format == SavedMatch.currentFormat, !saved.state.isOver else { return nil }
            return saved
        } catch {
            NSLog("MatchMode: the saved match at %@ could not be read: %@", url.path, error.localizedDescription)
            return nil
        }
    }

    static func deleteSave() {
        guard let url = saveURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do { try FileManager.default.removeItem(at: url) } catch {
            NSLog("MatchMode: could not remove the saved match at %@: %@", url.path, error.localizedDescription)
        }
    }

    // MARK: Which game

    /// The rules for each game (the names fixed in docs/award-batch-contracts.md 1.5).
    static func rules(for kind: MatchKind) -> any MatchRules {
        switch kind {
        case .eightBall: return EightBallRules()
        case .nineBall: return NineBallRules()
        case .bumperPool: return BumperPoolRules()
        case .fivePin: return FivePinRules()
        case .barBilliards: return BarBilliardsRules()
        }
    }

    static func table(for kind: MatchKind) -> TableKind {
        switch kind {
        case .eightBall, .nineBall: return .standard
        case .bumperPool: return .bumperPool
        case .fivePin: return .fivePin
        case .barBilliards: return .barBilliards
        }
    }

    /// Two players where the game allows it (every game takes two; bar billiards also plays alone).
    private static func seats(for r: any MatchRules) -> Int {
        min(max(2, r.playerCount.lowerBound), r.playerCount.upperBound)
    }

    private static func defaultName(seat: Int) -> String { String(localized: "Player \(seat + 1)") }
    private static func defaultNames(count: Int) -> [String] { (0..<count).map { defaultName(seat: $0) } }

    /// A seed for a new rack. The rack's seed only sets its sub-micrometre jitter (Rack.swift), which is enough to make
    /// every break spread differently, so any number will do; it is saved, so a resumed match breaks the same rack.
    private static func freshSeed() -> UInt64 { UInt64.random(in: 1...UInt64(UInt32.max)) }
}
