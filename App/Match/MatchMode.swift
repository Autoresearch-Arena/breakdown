// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: one saved game per game, match-<kind>.json,
//          the old match.json adopted; a computer shot is offered as worth watching only when rare or it scored).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 match-ui, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md B2:
//          you (the seat the words call you, MatchWords.you) and personSeat for the views; targetBall for five-pin's
//          wrong-ball words. A game the computer wins plays the foul moment, not the win (moment(for:winnerIsComputer:)
//          reads the after-state at both call sites). The computer's answer to a choice stays as the settled line in
//          the banner. A sitting tally (wins per seat, in memory only, carried by rematch) for the result card. A
//          break's routine ruling with its Lens offer up does not settle by itself: it waits for a tap. A computer
//          seat's name cannot be changed. The saved summary says whether the computer shoots next, and a save that
//          cannot be continued (undecodable, another format, finished, or two people with no computer) is deleted.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F9:
//          confirmingEnd, so the menu back button can give up Escape while End this game is asking.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 watch-invite, plans/22-Nov-2026-v074-glow-up-plan.md G3: a
//          remarkable shot by either seat is offered for a Lens replay on its ruling. rule() reads the model's judged
//          highlight for the recording it rules (ShowpieceModel.matchShotHighlight) and keeps it as lensHighlight when it
//          is the break's own, or a rare kind, or a common kind not yet offered this match (offeredHighlightKinds, not
//          saved, cleared by rematch); a ball too fast for the pocket is never offered. A routine ruling that offers one
//          becomes a card, so the shot can be named and watched (highlightShow).)
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
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 13, 15, 16 and 18, contract docs/v07-contracts.md 3.3.
//          The call: the suggested call moved here from the call card (suggestedCall), so the model can play a stroke
//          made with no call on the suggestion (adoptSuggestedCall) and the ruling card can say it did
//          (lastCallWasSuggested, lastShotCall); refusal says why the match would refuse a stroke now. Routine
//          rulings ("keep shooting", turn changes against the computer) settle by themselves after settleBeat seconds
//          of the balls at rest and stay as a line in the turn banner (lastRulingShow, settledRuling); the card stays
//          for fouls, the pegs, choices, a hand-over between two people on one device and the end. The ruling's facts
//          (balls pocketed, the first ball hit) are kept here, so the card and the banner word the shot even after
//          the table on screen has moved on. The computer: update() now runs the opponent while a ruling card is up
//          too, and upcomingComputerDecision gives it the table that card will leave, so it thinks before the card
//          goes. The menu's Continue row can name the saved game (savedSummary, SavedMatchSummary).)
// PURPOSE: A match: the person against the computer, or bar billiards alone (since 0.7.3 nothing offers two people one
//          device, though the engine still runs any number of seats) (plans/21-Nov-2026-rules-games-plan.md package 3 steps 4, 7 and 8, package 4
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

/// The saved game named for the menu's Continue row (contract 3.3): which game, against whom, whose shot. The words
/// are MatchWords.savedLine's.
struct SavedMatchSummary: Equatable {
    let kind: MatchKind
    /// The computer's level when one of the seats is the computer; nil for a game between people.
    let opponent: ComputerLevel?
    let playerNames: [String]
    /// The name of whoever shoots next.
    let turnName: String
    /// The next shot is the computer's (the turn seat is a computer seat), so the line says "The computer's shot."
    /// rather than a seat's name.
    let computerToShoot: Bool
}

@MainActor
@Observable
final class MatchMode {
    enum Phase: Equatable { case aiming, shooting, ruling, handOver, over }

    let rules: any MatchRules
    /// The End-this-game confirmation is up; the menu back button gives up Escape while it is.
    var confirmingEnd = false
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
    /// The object balls that dropped on the last ruled shot (only balls that started it on the table), read from its
    /// recording when it was ruled, so the card and the banner can word it after the table has moved on.
    private(set) var lastPocketed: [Int] = []
    /// The first ball the striking ball touched on the last ruled shot, nil when it touched none.
    private(set) var lastFirstBall: Int?
    /// The call the last ruled shot was played with (games with calls; nil otherwise).
    private(set) var lastShotCall: EightBallCall?
    /// The last ruled shot was played on the suggested call because the stroke went through with no call made.
    private(set) var lastCallWasSuggested = false
    /// How the last ruling is shown: .card waits for the player; .banner settles by itself (settleBeat).
    private(set) var lastRulingShow: RulingShow = .card
    /// A routine ruling that has settled into the turn banner: shown there as a line until the next shot.
    private(set) var settledRuling: Ruling?
    /// The remarkable shot the last ruling offers for a Lens replay (0.7.4): the break's own moment, or a shot by
    /// either seat that highlightOffered let through; nil when the ruling offers none. lensHighlightVersion is the
    /// model's timelineVersion of the recording it belongs to (ShowpieceModel.offerLensReplay compares them).
    private(set) var lensHighlight: ShotHighlight?
    private(set) var lensHighlightVersion: Int?
    /// The common kinds already offered in this game (rare kinds are offered every time). Not saved: a resumed match
    /// starts afresh, which at worst offers one more card. Cleared by rematch().
    @ObservationIgnored private var offeredHighlightKinds: Set<HighlightKind> = []

    /// How a ruling is shown (bug plan item 15).
    enum RulingShow: Equatable { case banner, card }
    /// How long a routine ruling shows before it settles, seconds of the balls at rest at the table. The line stays
    /// in the turn banner afterwards, so the beat only has to register the moment (a glance at a short header), not
    /// to give time to read every word; any longer and a player who has read it waits on the game.
    static let settleBeat: Double = 1.5

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
    /// The current call was adopted from the suggestion (adoptSuggestedCall), not made by the player; carried to the
    /// shot's ruling as lastCallWasSuggested.
    @ObservationIgnored private var callIsSuggested = false
    @ObservationIgnored private var shotCallSuggested = false
    /// Seconds a .banner ruling has been up with the balls at rest (counted by tickClock, which only runs while the
    /// table is live, so the menu and a replay hold it; reset by every new ruling).
    @ObservationIgnored private var settleElapsed = 0.0

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

    /// The seat the person holding the device plays (MatchWords.personSeat): the seat that is not the computer, or
    /// the only seat when playing alone. Wins and losses on the cards are told from this seat.
    var personSeat: PlayerID? { MatchWords.personSeat(in: state.players) }

    /// The seat the words call "you": the person's seat while its name is still the default. Read fresh from the
    /// state every time, so a name typed in the names editor takes over at once and emptying it brings "you" back.
    var you: PlayerID? { MatchWords.you(in: state.players) }

    /// The ball a seat must hit first where the table fixes one (five-pin: the other player's ball), for the
    /// wrong-ball foul's words; nil on every other table.
    func targetBall(for seat: PlayerID) -> Int? { (rules as? FivePinRules)?.targetBall(for: seat) }

    /// Games won in this sitting, per seat: counted when the rules finish a game, carried by rematch(), never saved
    /// (a new match, or ending this one, starts from nothing). The result card shows it from the second game on.
    private(set) var sittingWins: [Int] = []
    /// Games finished in this sitting (a game with no winner counts here and in nobody's wins).
    private(set) var sittingGames = 0

    // MARK: The call (item 13)

    /// What the cue is pointed at now, as a call: the first ball on the aim line, if the rules let the shooter call
    /// it, into the pocket nearest the line that ball would leave along (the same right-angle guide the aim line
    /// draws, AimGeometry.firstContact). Nil when no call is due, or the first ball on the line may not be called, or
    /// the line hits nothing. Shared by the call card (it pre-selects this) and the model (a stroke made with no call
    /// is played on this one). EightBallRules.suggestedCall is not used: it falls back to some other callable ball
    /// when the line misses, which would hold a player to a call they never pointed at.
    var suggestedCall: EightBallCall? {
        guard mustCall, phase == .aiming, model.layout.count == 16, NextShot.isOnTable(model.aimOrigin) else { return nil }
        let table = model.timeline.table
        guard let hit = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin,
                                                 direction: model.aimDirection, radius: table.ballRadius),
              rules.mayCall(hit.ball, in: state),
              let k = Self.nearestPocket(from: hit.target, along: hit.objectDirection, pockets: table.pockets),
              let named = EightBallPocket(rawValue: k) else { return nil }
        return .ball(hit.ball, pocket: named)
    }

    /// The pocket whose centre lies closest to the line a ball leaves along, counting only edge pockets ahead of it.
    /// Nil when no pocket is ahead (the ball is heading straight for a cushion with no pocket on that side).
    static func nearestPocket(from start: Vec2, along direction: Vec2, pockets: [Vec2]) -> Int? {
        var best: (k: Int, miss: Double)?
        for (k, p) in pockets.prefix(EightBallPocket.allCases.count).enumerated() {
            let d = p - start
            let ahead = d.dot(direction)
            guard ahead > 0 else { continue }
            // Sideways distance from the line to the pocket's centre.
            let miss = max(0, d.lengthSquared - ahead * ahead).squareRoot()
            if best == nil || miss < best!.miss { best = (k, miss) }
        }
        return best?.k
    }

    /// No call made: take the suggestion as the call and remember it was suggested, so the ruling card can say which
    /// call the shot was held to. False when no call is due, one is already made, or there is no suggestion.
    func adoptSuggestedCall() -> Bool {
        guard mustCall, currentCall == nil, let s = suggestedCall else { return false }
        setCall(s)
        guard currentCall == s else { return false }
        callIsSuggested = true
        return true
    }

    /// Why the match would refuse a stroke now, or nil when one may be struck. .noCall only when no call is made and
    /// there is no suggestion to play instead. The model's strokeRefusal adds its own (solving, a replay playing, a
    /// ball lifted); this is the match's part, in the order the player would have to deal with them.
    var refusal: ShotRefusal? {
        if state.isOver || phase == .over { return .gameOver }
        if phase != .aiming { return .rulingPending }
        if !personMayAct { return .notYourTurn }
        if state.pendingChoice != nil { return .choicePending }
        if mustCall && currentCall == nil && suggestedCall == nil { return .noCall }
        return nil
    }

    // MARK: The computer's next decision (item 16)

    /// A decision the computer seat has to make next, and the table it will be made on.
    struct ComputerDecision {
        let seat: PlayerID
        let level: ComputerLevel
        /// The table the decision is played from: the table on screen while aiming; while a ruling card is up, the
        /// table the card's dismissal will put on (the next setup), so thinking can start before the card goes.
        let layout: [Vec2]
        let racked: Bool
        /// True while aiming: the decision is due now and may be played once the balls are at rest.
        let dueNow: Bool
    }

    /// The computer's next decision as soon as it is known: the chooser of a pending choice, otherwise the shooter,
    /// when that seat is the computer. Nil while a shot plays, on a hand-over, after the game, or when the decision
    /// is a person's.
    var upcomingComputerDecision: ComputerDecision? {
        guard !state.isOver else { return nil }
        let seat = state.pendingChoice?.chooser ?? state.turn
        guard state.players.indices.contains(seat.index), let level = state.players[seat.index].computer else {
            return nil
        }
        switch phase {
        case .aiming:
            return ComputerDecision(seat: seat, level: level, layout: model.layout, racked: model.racked, dueNow: true)
        case .ruling:
            let next = nextSetup ?? setup
            return ComputerDecision(seat: seat, level: level, layout: next.layout, racked: next.racked, dueNow: false)
        case .shooting, .handOver, .over:
            return nil
        }
    }

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
        // A call set here is the player's (or the computer's) own; adoptSuggestedCall marks its own afterwards.
        callIsSuggested = false
    }

    /// The model has started a shot (called from ShowpieceModel's strike, before the solve).
    func shotFired() {
        shotCall = mustCall ? currentCall : nil
        shotCallSuggested = shotCall != nil && callIsSuggested
        callIsSuggested = false
        shotVersion = nil
        // The settled line in the banner was about the shot before this one.
        settledRuling = nil
        // So is any Lens offer.
        lensHighlight = nil
        lensHighlightVersion = nil
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

    /// Called every frame by the model. Rules on the shot once its replay has played out (or been skipped), and
    /// settles a routine ruling once it has shown for settleBeat.
    func update() {
        switch phase {
        case .aiming, .ruling:
            // The computer thinks as soon as its decision is known (during the ruling card before its turn too) and
            // plays once the match is aiming; it does nothing on a person's turn.
            opponent?.update(self)
            if phase == .ruling, lastRulingShow == .banner, settleElapsed >= Self.settleBeat { acknowledgeRuling() }
        case .shooting:
            guard let v = shotVersion, model.timelineVersion == v, model.aimReady else { return }
            rule()
        case .handOver, .over:
            break
        }
    }

    /// A routine ruling showing in the banner: move on now instead of waiting out the beat (a tap on its line, or
    /// the model when the player reaches for the next stroke). Does nothing for a ruling that wants the card.
    func settleNow() {
        guard phase == .ruling, lastRulingShow == .banner else { return }
        acknowledgeRuling()
    }

    /// How a ruling is shown. The card, which waits for a tap: any foul; a peg down in bar billiards (a lost break or a
    /// lost score is a penalty like a foul, even though the rules do not file it as one); a choice to make; the end
    /// of the game; and a turn passing between two people on one device (the device changes hands). Everything else
    /// is routine and settles into the banner: keep shooting, and every ordinary turn change against the computer.
    static func rulingShow(for r: Ruling, after: MatchState, hasComputer: Bool) -> RulingShow {
        if r.fouled || r.result != nil || after.isOver || after.pendingChoice != nil { return .card }
        if r.reasons.contains(.whitePegDown) || r.reasons.contains(.blackPegDown) { return .card }
        if r.turnPasses && !hasComputer && after.players.count > 1 { return .card }
        return .banner
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
        // What the recording showed, kept with the ruling: the object balls that dropped (only balls that started
        // this shot on the table; one pocketed earlier sits at the parking spot from the start and is not named
        // again) and the first ball the striking ball touched (so a wrong-ball foul names it).
        let tl = model.timeline
        lastPocketed = (0..<tl.ballCount).filter {
            $0 != struck && tl.pocketTime[$0] != nil && NextShot.isOnTable(tl.state(ball: $0, at: 0).position)
        }
        lastFirstBall = Self.firstBall(hitBy: struck, in: tl)
        lastShotCall = shotCall
        lastCallWasSuggested = shotCallSuggested
        lastRulingShow = Self.rulingShow(for: ruling, after: after, hasComputer: hasComputer)
        // A shot by the computer is offered only when its kind is rare or it scored (0.7.5 polish P1): an ordinary
        // draw that sent nothing down is not worth stopping the game for.
        var offered = model.matchShotHighlight
        if let h = offered, isComputer(before.turn),
           !HighlightOffer.offersComputerShot(h.kind, scored: ShotHighlightJudge.sentBallDown(facts, table: model.solvedTable)) {
            offered = nil
        }
        offerHighlight(offered, version: shotVersion)
        settleElapsed = 0
        settledRuling = nil
        state = after
        clockExact = after.clockRemaining
        lastRuling = ruling
        currentCall = nil
        phase = .ruling
        Self.playMoment(for: ruling, after: after)
        if state.isOver { noteFinished() }
        if after.isOver, after.kind == .barBilliards, after.players.count == 1, let score = after.scores.first {
            bestOutcome = BarBilliardsBest.record(score)
        }
        save()
    }

    /// Which highlight the ruling just made offers for a Lens replay (0.7.4), and how it is shown. The break's own
    /// moment rides on the break's existing offer and leaves the ruling as it is. Any other kind except a ball too fast
    /// for the pocket is offered when it is rare, or common and not yet offered this game; then a routine ruling
    /// becomes the card, so the shot is named and can be watched before play moves on.
    private func offerHighlight(_ h: ShotHighlight?, version: Int?) {
        lensHighlight = nil
        lensHighlightVersion = nil
        guard let h, let version else { return }
        guard let show = Self.highlightShow(h.kind, offered: offeredHighlightKinds, current: lastRulingShow) else {
            return
        }
        if h.kind != .breakShot, !h.kind.isRare { offeredHighlightKinds.insert(h.kind) }
        lensHighlight = h
        lensHighlightVersion = version
        lastRulingShow = show
    }

    /// How a ruling is shown when its shot had a highlight of `kind`, or nil when the highlight is not offered: the
    /// break keeps the ruling's own way (its Lens offer is the break's, as before 0.7.4); a ball too fast for the
    /// pocket and a common kind already offered this game are not offered; anything else turns a banner into the card.
    static func highlightShow(_ kind: HighlightKind, offered: Set<HighlightKind>, current: RulingShow) -> RulingShow? {
        if kind == .breakShot { return current }
        if kind == .rimSkip { return nil }
        guard kind.isRare || !offered.contains(kind) else { return nil }
        return .card
    }

    /// The match moment a ruling sounds and is felt (SoundBoard.play plays its voice and its haptic together): a win
    /// for the end of the game, a foul, a turn change; nothing when the shooter simply carries on. A game the
    /// computer wins sounds the foul moment, not the win: the win sound is only ever the person's (a game with no
    /// named winner, such as bar billiards alone, keeps the win).
    static func moment(for r: Ruling, winnerIsComputer: Bool = false) -> GameMoment? {
        if r.result != nil { return winnerIsComputer ? .foul : .win }
        if r.fouled { return .foul }
        if r.turnPasses { return .turnChange }
        return nil
    }

    /// Plays a ruling's moment, reading who won from the state the ruling left (`after`; the seats never change).
    private static func playMoment(for r: Ruling, after: MatchState) {
        let winnerIsComputer = r.result?.winner.map { w in after.players.contains { $0.id == w && $0.isComputer } }
            ?? false
        if let m = moment(for: r, winnerIsComputer: winnerIsComputer) { SoundBoard.play(m) }
    }

    /// A game the rules finished: counted in the on-device record (MatchRecord) and in this sitting's tally.
    private func noteFinished() {
        MatchRecord.noteFinished(state)
        if sittingWins.count != state.players.count { sittingWins = Array(repeating: 0, count: state.players.count) }
        sittingGames += 1
        if let w = state.result?.winner, sittingWins.indices.contains(w.index) { sittingWins[w.index] += 1 }
    }

    /// The first ball a given striking ball touched in a recording, or nil when it touched none.
    static func firstBall(hitBy cueBall: Int, in tl: Timeline) -> Int? {
        for e in tl.events where e.kind == .ballBall {
            let ids = e.balls.map(\.ball)
            if ids.contains(cueBall) { return ids.first { $0 != cueBall } }
        }
        return nil
    }

    /// Called every frame the table is live (ShowpieceModel.advance; it stops before this while the menu is open)
    /// with the real seconds since the last frame. Runs the game clock by MatchClock's rule; games without a clock
    /// ignore it.
    func tickClock(realSeconds: Double) {
        // A routine ruling's beat counts here, in live table seconds, for every game (the clock below is bar
        // billiards' only). It only runs while the balls are at rest: a replay started from the card (the Lens on a
        // break) holds it, and it starts over once the replay has played out.
        if phase == .ruling, lastRulingShow == .banner {
            // A break's ruling with "Watch it in the Lens" up waits for a tap (on the banner or the offer) instead of
            // settling and taking the offer away before the player has read it.
            let lensOfferWaits = model.currentAttempt?.isBreak == true && model.offerLensReplay
            settleElapsed = model.aimReady && !lensOfferWaits
                ? settleElapsed + MatchClock.seconds(forFrame: realSeconds) : 0
        }
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
            // A routine ruling stays as a line in the turn banner until the next shot; a card's ruling does not.
            settledRuling = lastRulingShow == .banner ? lastRuling : nil
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
        // The answer is the latest word on the table; the banner no longer carries the shot's settled line. The
        // computer's answer becomes that line itself ("Computer (Hard) takes the table as it lies."), so the person
        // sees what it chose; a person's own answer needs no telling.
        settledRuling = isComputer(pending.chooser) ? ruling : nil
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
        Self.playMoment(for: ruling, after: after)
        if state.isOver { noteFinished() }
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
        lastPocketed = []
        lastFirstBall = nil
        lastShotCall = nil
        lastCallWasSuggested = false
        lastRulingShow = .card
        settledRuling = nil
        settleElapsed = 0
        lensHighlight = nil
        lensHighlightVersion = nil
        offeredHighlightKinds = []
        callIsSuggested = false
        bestOutcome = nil
        clockExact = nil
        currentCall = nil
        nextSetup = nil
        start()
    }

    /// A person's seat takes a typed name; an emptied field puts the default back (so the words say "you" again). The
    /// computer's seat is never renamed: its name says its level.
    func setPlayerName(_ name: String, for player: PlayerID) {
        guard state.players.indices.contains(player.index), !state.players[player.index].isComputer else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        state.players[player.index].name = trimmed.isEmpty ? Self.defaultName(seat: player.index) : trimmed
        save()
    }

    // MARK: Pieces

    /// Aiming for the player whose turn it is; with ball in hand the cue ball is lifted for them to place.
    private func beginTurn() {
        phase = .aiming
        currentCall = nil
        callIsSuggested = false
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
            Self.deleteSave(kind: state.kind)
            model.noteMatchSave(exists: false)
            return
        }
        guard let url = Self.saveURL(for: state.kind) else { return }
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

    /// The app's support folder, Application Support/Breakdown (created on first save).
    private static var saveFolder: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Breakdown", isDirectory: true)
    }

    /// One saved game per game (0.7.5): match-<kind>.json, so starting bumper pool no longer ends a five-pin game
    /// that is still in progress.
    static func saveURL(for kind: MatchKind) -> URL? {
        saveFolder?.appendingPathComponent("match-\(kind.rawValue).json")
    }

    /// Before 0.7.5 the device kept one save, match.json. It is moved to its own game's file the first time the saves
    /// are looked at (or removed, when that game already has a newer file or it cannot be read).
    private static func adoptOldSave() {
        guard let old = saveFolder?.appendingPathComponent("match.json"),
              FileManager.default.fileExists(atPath: old.path) else { return }
        if let data = try? Data(contentsOf: old), let saved = try? JSONDecoder().decode(SavedMatch.self, from: data),
           let target = saveURL(for: saved.state.kind), !FileManager.default.fileExists(atPath: target.path) {
            do { try FileManager.default.moveItem(at: old, to: target); return } catch {
                NSLog("MatchMode: could not move the old saved match to %@: %@", target.path, error.localizedDescription)
            }
        }
        try? FileManager.default.removeItem(at: old)
    }

    /// The games with a save file, the most recently saved first.
    static func savedKinds() -> [MatchKind] {
        adoptOldSave()
        func written(_ kind: MatchKind) -> Date? {
            guard let url = saveURL(for: kind),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
            return attributes[.modificationDate] as? Date ?? .distantPast
        }
        return MatchKind.allCases.compactMap { kind in written(kind).map { (kind, $0) } }
            .sorted { $0.1 > $1.1 }.map(\.0)
    }

    static var saveExists: Bool { !savedKinds().isEmpty }

    /// The saved game named for a Continue row: which game, the computer's level when it plays, the players' names
    /// and whose shot it is. With no kind, the most recently saved game that can be continued; nil when none can.
    static func savedSummary(for kind: MatchKind? = nil) -> SavedMatchSummary? {
        guard let saved = loadSaved(kind: kind) else { return nil }
        let s = saved.state
        let names = s.players.map(\.name)
        let computerToShoot = s.players.first { $0.id == s.turn }?.isComputer ?? false
        return SavedMatchSummary(kind: s.kind, opponent: s.players.compactMap(\.computer).first, playerNames: names,
                                 turnName: MatchWords.name(s.turn, in: names), computerToShoot: computerToShoot)
    }

    /// The saved match of one game, or with no kind the most recently saved one that loads; nil when there is none or
    /// it cannot be continued. A file that decodes but can never be played on (another format, a finished game, or
    /// more than one seat with no computer: a game between two people on one device, which nothing offers since
    /// 0.7.3), and a file that does not decode, is deleted, so the menu never offers a Continue that cannot load. A
    /// file that cannot be read at all (the disk, not its contents) is left alone: it may read next time.
    static func loadSaved(kind: MatchKind? = nil) -> SavedMatch? {
        guard let kind else {
            for k in savedKinds() { if let saved = loadSaved(kind: k) { return saved } }
            return nil
        }
        adoptOldSave()
        guard let url = saveURL(for: kind), FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            NSLog("MatchMode: the saved match at %@ could not be read: %@", url.path, error.localizedDescription)
            return nil
        }
        do {
            let saved = try JSONDecoder().decode(SavedMatch.self, from: data)
            let s = saved.state
            let twoPeople = s.players.count > 1 && !s.players.contains(where: \.isComputer)
            guard saved.format == SavedMatch.currentFormat, !s.isOver, !twoPeople, s.kind == kind else {
                NSLog("MatchMode: the saved match at %@ cannot be continued and was removed", url.path)
                deleteSave(kind: kind)
                return nil
            }
            return saved
        } catch {
            NSLog("MatchMode: the saved match at %@ could not be decoded and was removed: %@", url.path,
                  error.localizedDescription)
            deleteSave(kind: kind)
            return nil
        }
    }

    /// Remove one game's save; the other games' saves stay.
    static func deleteSave(kind: MatchKind) {
        guard let url = saveURL(for: kind), FileManager.default.fileExists(atPath: url.path) else { return }
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
