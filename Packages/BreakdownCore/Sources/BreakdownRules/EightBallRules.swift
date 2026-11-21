// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The rules of eight-ball for two players on one device (plans/21-Nov-2026-rules-games-plan.md package 3),
//          in our own words:
//            - The break. The breaker places the cue ball behind the head line. A legal break pockets an object ball
//              or drives at least four object balls to a rail; otherwise the other player chooses to take the table
//              as it lies or have it racked again (and then breaks it). A scratch on the break is a foul: ball in
//              hand behind the head line for the other player. The 8 on the break neither wins nor loses: it is
//              spotted, or the table is racked again; the breaker chooses, unless the break also fouled, in which
//              case the other player chooses (and has ball in hand).
//            - The table is open after the break. Groups (solids 1 to 7, stripes 9 to 15) are settled by the first
//              called ball that is legally pocketed: the shooter takes its group, the other player the other.
//            - Every shot after the break is called: a ball and a pocket, or a safety.
//            - A legal shot hits one of the shooter's own group first (any ball but the 8 while the table is open;
//              the 8 once the group is gone), and then pockets a ball or sends some ball to a rail. A shot that
//              touches nothing, scratches, or sends an object ball off the table is a foul too.
//            - A foul gives the other player ball in hand anywhere. Balls pocketed on a foul stay down.
//            - The shooter keeps shooting while they legally pocket the ball they called in the pocket they called.
//              Any other ball that drops stays down, but does not keep the turn.
//            - The game is won by legally pocketing the 8 in the called pocket once the group is gone, and lost by
//              the 8 going off the table, dropping on a foul, dropping early, or dropping in a pocket that was not
//              called for it, checked in that order (lossOnTheEight, the same order as the Behind the 8-Ball judge).
//          Reads the shot through ShotFacts (BreakdownTimeline), never re-solves it, and returns a Ruling; the
//          bookkeeping that folds a ruling into the MatchState is MatchRules' shared applying(_:facts:to:). The app's
//          match flow (App/Match/MatchMode.swift) holds an EightBallRules and asks it after every shot and choice.
//          Also suggests the default call for the call control: the ball the cue is pointed at and the pocket
//          nearest its path, so one tap confirms an obvious shot (suggestedCall).
// SRP/DRY check: Pass - checked App/EightBall/EightBallJudge.swift (its loss order and foul reading are mirrored here
//          through the same ShotFacts and the same EightBall types; the judge's stroke-based fouls, cue or bridge
//          touching and double hit, need the drawn cue and are not part of a match), MatchRules.swift (the bookkeeping
//          stays there) and NineBallRules.swift (shares no rule; each game's legal-first ball differs).
import BreakdownLensModel
import BreakdownTimeline

public struct EightBallRules: MatchRules {
    public init() {}

    public var kind: MatchKind { .eightBall }
    public var rack: MatchRack { .fifteenBallTriangle }
    public var usesCalls: Bool { true }
    /// The breaker places the cue ball anywhere behind the head line (the rack puts it on the head spot, which is on
    /// the line, so taking it as it lies is always allowed too). Also used after every re-rack.
    public var startingBallInHand: BallInHand { .behindHeadLine }

    /// How many object balls must reach a rail for a break that pockets nothing to be legal.
    public static let breakRailCount = 4

    // MARK: Which balls are legal

    /// The balls the shooter must hit first, and may call: their group's balls still on the table; the 8 once those
    /// are gone; while the table is open, any ball on the table but the 8 (the 8 too, if nothing else is left).
    public func legalBalls(in state: MatchState) -> Set<Int> {
        if state.group(of: state.turn) != nil {
            let own = state.ballsRemaining(for: state.turn)
            return own.isEmpty ? [8] : Set(own)
        }
        let open = state.ballsLeft.filter { $0 != 8 }
        return open.isEmpty ? [8] : Set(open)
    }

    /// True when the shooter is playing the 8 (their group is gone).
    public func isOnTheEight(_ state: MatchState) -> Bool { legalBalls(in: state) == [8] }

    public func mayCall(_ ball: Int, in state: MatchState) -> Bool {
        !state.isOver && !state.isBreak && state.ballsLeft.contains(ball) && legalBalls(in: state).contains(ball)
    }

    // MARK: The ruling on a shot

    public func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        state.isBreak ? breakRuling(facts, in: state) : shotRuling(facts, call: call, in: state)
    }

    /// The fouls an ordinary shot can make, in MatchFoul's order. A tie for the first contact counts the legal ball.
    func shotFouls(_ facts: ShotFacts, legal: Set<Int>) -> [MatchFoul] {
        var found = Set<MatchFoul>()
        if facts.cueBallScratched { found.insert(.scratch) }
        if let first = facts.firstContact(preferring: legal) {
            if !legal.contains(first.ball) { found.insert(.wrongBallFirst) }
            if !facts.railOrPocketAfterContact { found.insert(.noRailAfterContact) }
        } else {
            found.insert(.noBallHit)
        }
        if !facts.objectBallsOffTable.isEmpty { found.insert(.objectBallOffTable) }
        return MatchFoul.allCases.filter { found.contains($0) }
    }

    /// What the loss table reads about the 8 on one shot.
    struct EightShot: Sendable {
        var offTable: Bool
        /// The pocket the 8 dropped in, if it did.
        var pocket: Int?
        var fouled: Bool
        /// The shooter's group was already gone when the shot started.
        var onTheEight: Bool
        var call: EightBallCall?
    }

    /// Loss of game on the 8, one explicit table checked top to bottom; the first row that applies is the loss. Off
    /// the table comes first, then a foul (a scratch included), then too early, then the wrong pocket. A safety, or a
    /// call of any other ball, that drops the 8 is the wrong pocket: the 8 was not called there.
    struct LossRow: Sendable {
        let loss: EightBallLoss
        let applies: @Sendable (EightShot) -> Bool
    }

    static let lossOnTheEight: [LossRow] = [
        LossRow(loss: .eightOffTable, applies: { s in s.offTable }),
        LossRow(loss: .eightOnFoul, applies: { s in s.pocket != nil && s.fouled }),
        LossRow(loss: .eightEarly, applies: { s in s.pocket != nil && !s.onTheEight }),
        LossRow(loss: .eightWrongPocket, applies: { s in
            s.pocket != nil && !(s.call?.ball == 8 && s.call?.pocket?.rawValue == s.pocket)
        }),
    ]

    /// The loss on the 8 for one shot, if any (the first row of lossOnTheEight that applies).
    static func loss(_ shot: EightShot) -> EightBallLoss? { lossOnTheEight.first { $0.applies(shot) }?.loss }

    private func other(_ state: MatchState) -> PlayerID { state.turn.next(among: max(state.players.count, 1)) }

    /// Every shot after the break.
    private func shotRuling(_ facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        let shooter = state.turn, opponent = other(state)
        let legal = legalBalls(in: state)
        let fouls = shotFouls(facts, legal: legal)
        let open: [RulingReason] = state.tableOpen ? [.tableOpen] : []

        // The 8 first: a loss ends the game whatever else happened; otherwise an 8 that dropped is the win.
        let eight = EightShot(offTable: facts.objectBallsOffTable.contains(8), pocket: facts.pocket(of: 8),
                              fouled: !fouls.isEmpty, onTheEight: legal == [8], call: call)
        if let loss = Self.loss(eight) {
            var reasons: [RulingReason] = fouls.isEmpty ? [] : [.foul]
            reasons.append(.gameOver)
            return Ruling(shooter: shooter, nextShooter: opponent, fouls: fouls, reasons: reasons,
                          result: MatchResult(winner: opponent, reason: MatchEndReason(loss)))
        }
        if eight.pocket != nil {
            return Ruling(shooter: shooter, nextShooter: shooter, reasons: [.legalPot, .gameOver],
                          result: MatchResult(winner: shooter, reason: .eightBallPocketed))
        }

        if !fouls.isEmpty {
            return Ruling(shooter: shooter, nextShooter: opponent, fouls: fouls, reasons: [.foul] + open,
                          ballInHand: .anywhere)
        }

        // The called ball, legally callable, in the called pocket: the shooter stays at the table, and on an open
        // table takes that ball's group.
        if case .ball(let b, pocket: let pocket)? = call, legal.contains(b), facts.pocket(of: b) == pocket.rawValue {
            if state.tableOpen, let g = EightBallGroup.of(ball: b) {
                return Ruling(shooter: shooter, nextShooter: shooter, reasons: [.legalPot, .groupsAssigned],
                              assignedGroup: g)
            }
            return Ruling(shooter: shooter, nextShooter: shooter, reasons: [.legalPot])
        }
        // Something dropped, but not as called (or the shot was a safety): it stays down and the turn passes.
        if !facts.objectBallsPocketed.isEmpty {
            return Ruling(shooter: shooter, nextShooter: opponent, reasons: [.calledBallMissed] + open)
        }
        return Ruling(shooter: shooter, nextShooter: opponent, reasons: [.noLegalPot] + open)
    }

    /// The break. Precedence: the 8 dropping (or flying off) is decided first, because it raises the spot-or-re-rack
    /// choice whatever else happened; then a foul; then whether the break was legal.
    private func breakRuling(_ facts: ShotFacts, in state: MatchState) -> Ruling {
        let breaker = state.turn, opponent = other(state)
        var found = Set<MatchFoul>()
        if facts.cueBallScratched { found.insert(.scratch) }
        if facts.firstContact == nil { found.insert(.noBallHit) }
        if !facts.objectBallsOffTable.isEmpty { found.insert(.objectBallOffTable) }
        let fouls = MatchFoul.allCases.filter { found.contains($0) }
        let fouled = !fouls.isEmpty
        let scratched = facts.cueBallScratched
        // After a break foul the other player has ball in hand: behind the head line for a scratch (as on the break
        // itself), anywhere for any other foul.
        let foulHand: BallInHand = scratched ? .behindHeadLine : .anywhere
        var foulReasons: [RulingReason] = []
        if fouled { foulReasons.append(.foul) }
        if fouled && scratched { foulReasons.append(.scratchOnBreak) }

        if facts.pocket(of: 8) != nil || facts.objectBallsOffTable.contains(8) {
            // The 8 is spotted or the table re-racked: the breaker's choice after a clean break (and they keep
            // shooting once it is spotted), the other player's after a foul.
            let chooser = fouled ? opponent : breaker
            return Ruling(shooter: breaker, nextShooter: chooser, fouls: fouls,
                          reasons: [.eightOnBreak] + foulReasons + [.tableOpen],
                          ballInHand: fouled ? foulHand : BallInHand.none,
                          choice: PendingChoice(choice: .spotEightOrRerack, chooser: chooser))
        }

        let legal = !facts.objectBallsPocketed.isEmpty || facts.objectBallsReachingRail.count >= Self.breakRailCount
        if !legal {
            // A bad break: the other player takes the table as it lies or has it racked again.
            return Ruling(shooter: breaker, nextShooter: opponent, fouls: fouls,
                          reasons: [.breakIllegal] + foulReasons + [.tableOpen],
                          ballInHand: fouled ? foulHand : BallInHand.none,
                          choice: PendingChoice(choice: .acceptTableOrRerack, chooser: opponent))
        }
        if fouled {
            return Ruling(shooter: breaker, nextShooter: opponent, fouls: fouls,
                          reasons: [.breakLegal] + foulReasons + [.tableOpen], ballInHand: foulHand)
        }
        if !facts.objectBallsPocketed.isEmpty {
            return Ruling(shooter: breaker, nextShooter: breaker, reasons: [.breakLegal, .legalPot, .tableOpen])
        }
        return Ruling(shooter: breaker, nextShooter: opponent, reasons: [.breakLegal, .noLegalPot, .tableOpen])
    }

    // MARK: Answering a choice

    /// Accept the table: the chooser shoots from the layout as it lies (with any ball in hand the break gave them).
    /// Spot the 8: the 8 goes back on the foot spot and the player whose turn it is shoots. Re-rack: a fresh rack,
    /// broken by the chooser from behind the head line. An answer the pending choice does not offer changes nothing.
    public func ruling(answering answer: MatchChoiceAnswer, in state: MatchState) -> Ruling {
        guard let pending = state.pendingChoice, pending.choice.answers.contains(answer) else {
            return Ruling(shooter: state.turn, nextShooter: state.turn, reasons: [.choiceAnswered],
                          ballInHand: state.ballInHand, choice: state.pendingChoice)
        }
        let chooser = pending.chooser
        switch answer {
        case .acceptTable:
            return Ruling(shooter: chooser, nextShooter: chooser, reasons: [.choiceAnswered],
                          ballInHand: state.ballInHand)
        case .spotEight:
            return Ruling(shooter: chooser, nextShooter: state.turn, reasons: [.choiceAnswered, .ballSpotted],
                          ballInHand: state.ballInHand, ballsToSpot: [8])
        case .rerack:
            return Ruling(shooter: chooser, nextShooter: chooser, reasons: [.choiceAnswered, .rerack],
                          ballInHand: .behindHeadLine, rerack: true)
        }
    }

    // MARK: The suggested call

    /// The call the control pre-selects so one tap confirms an obvious shot: the ball the cue ball would hit first
    /// along `aim`, if the shooter may call it, sent to the pocket nearest the line it would travel. When the first
    /// ball on the line may not be called (or the line hits nothing), the callable ball nearest the aim's direction is
    /// suggested instead, with its path taken as the line from the cue ball through it (a straight-in guess).
    /// Nil when no ball may be called (the break, or the game is over).
    /// - positions: the layout, index = ball number, the off-table parking spot for balls that are gone.
    /// - aim: the cue's direction on the table plan (need not be unit length).
    /// - pockets: the six edge pocket centres in EightBallPocket order (PoolParameters.pocketCenters).
    /// - ballRadius: the ball radius in metres.
    public func suggestedCall(positions: [Vec2], cueBall: Int = 0, aim: Vec2, pockets: [Vec2], ballRadius: Double,
                              in state: MatchState) -> EightBallCall? {
        guard positions.indices.contains(cueBall), ShotFacts.isOnTable(positions[cueBall]) else { return nil }
        let cue = positions[cueBall]
        let d = aim.normalized
        let callable = state.ballsLeft.filter { b in
            positions.indices.contains(b) && ShotFacts.isOnTable(positions[b]) && mayCall(b, in: state)
        }
        guard !callable.isEmpty, d != .zero else { return nil }

        // The first ball on the cue ball's line: a ball whose centre passes within a diameter of the line is hit when
        // the cue ball has travelled along - sqrt((2R)^2 - off^2), with the cue ball's centre then at the ghost ball.
        let diameter = 2 * ballRadius
        var hit: (ball: Int, travel: Double)?
        for (b, q) in positions.enumerated() where b != cueBall && ShotFacts.isOnTable(q) {
            let rel = q - cue
            let along = rel.dot(d)
            guard along > 0 else { continue }
            let off2 = rel.lengthSquared - along * along
            guard off2 < diameter * diameter else { continue }
            let travel = along - (diameter * diameter - off2).squareRoot()
            if hit == nil || travel < hit!.travel { hit = (b, travel) }
        }

        let target: Int
        let path: Vec2
        if let h = hit, callable.contains(h.ball) {
            // An object ball leaves along the line from the ghost ball's centre through its own.
            target = h.ball
            path = (positions[h.ball] - (cue + d * h.travel)).normalized
        } else {
            target = callable.max { a, b in
                (positions[a] - cue).normalized.dot(d) < (positions[b] - cue).normalized.dot(d)
            } ?? callable[0]
            path = (positions[target] - cue).normalized
        }

        // The pocket nearest the path: the smallest sideways distance among pockets ahead of the ball; if none is
        // ahead, simply the nearest pocket.
        let from = positions[target]
        let count = min(pockets.count, EightBallPocket.allCases.count)
        guard count > 0 else { return nil }
        var best: (pocket: Int, miss: Double)?
        for k in 0..<count {
            let rel = pockets[k] - from
            let along = rel.dot(path)
            guard along > 0 else { continue }
            let miss = max(0, rel.lengthSquared - along * along).squareRoot()
            if best == nil || miss < best!.miss { best = (k, miss) }
        }
        let k = best?.pocket ?? (0..<count).min { (pockets[$0] - from).length < (pockets[$1] - from).length } ?? 0
        guard let pocket = EightBallPocket(rawValue: k) else { return nil }
        return .ball(target, pocket: pocket)
    }
}
