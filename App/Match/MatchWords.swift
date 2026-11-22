// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 match-ui review: a game ended by the clock says "Time ran
//          out." once, without "Time is up." on the same card.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 match-ui, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md B2:
//          the person is "you". personSeat finds the one seat the person holding the device plays (the seat that is
//          not the computer, or the only seat when playing alone); while that seat keeps its default name ("Player 1",
//          in any old save too) or none, every sentence that names it is said in the second person ("You have the
//          solids.", "You shoot again.", "You win!"); a typed name is kept. Nothing stores "You": it is only words.
//          A game-ending ruling says why it ended (the .gameOver reason gives endReason's sentence), so an eight-ball
//          loss card is never empty, and three fouls in a row says the game was lost. The computer's answer to a
//          choice is one sentence naming it. Fouls on the other tables name the balls by colour and say "the struck
//          ball", never "the cue ball"; the new head-line foul is worded; ball in hand behind the line says what may
//          not be hit first. The saved line ends "Your shot." or "The computer's shot.". Nine-ball's two-foul line.
//          Bar billiards' white peg loses "this break's" points, and "Time is up." can be left out of routine rulings
//          (the bar-down line and the one-time announcement already say it).)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens) - the ruling sentences take the game: on the three
//          other tables the balls are named as players there name them (the white, the yellow, the red, a white, a
//          marked ball; TableGameWords) and a ball put back goes to its own spot, not the pool foot spot. Every
//          RulingReason, MatchFoul and MatchEndReason case the table rules use already had its sentence here.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 13, 18 and 20: nine-ball's illegal break gets its own
//          foul words instead of "no ball reached a rail after the hit", which was wrong whenever some balls did, and
//          the separate break line is not repeated after it; a shot played on the suggested call says which call that
//          was; the menu's Continue row can name the saved game (savedLine).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the hand-over between two people on one device names whose
//          shot it is ("Sam to shoot.") instead of telling them to pass the device.)
// PURPOSE: Every word a match says, in one place. The rules (package module BreakdownRules) speak only in codes:
//          MatchFoul, RulingReason, MatchEndReason, MatchChoice, BallInHand. This file turns them into plain sentences
//          a player reads after each shot ("Foul: the cue ball hit the 11 first. Ball in hand for you."), the game
//          names, the call line and the hand-over line. Everything goes through String(localized:) so the string
//          catalog collects it; numbers and names are passed in as finished strings or whole numbers so every
//          language can order the sentence its own way. Each sentence that names a seat has a second-person form for
//          the seat the words call you (you(in:)); the caller passes that seat in, and nil names every seat.
//          Read by MatchViews (the banner and the cards), CallControl, TableGamePage and the menu (savedLine). It
//          reads nothing itself: the caller hands in the ruling, the state, the names and what the recording showed
//          (balls pocketed, the first ball hit).
// SRP/DRY check: Pass - checked EightBallTypes.swift (EightBallGroup.title, EightBallPocket.title are reused here, not
//          repeated) and EightBallFoul.title (short labels for the puzzle's scorecard; a match needs whole sentences
//          naming the ball, so these are separate words for a different job). TableWords.ruling is the spoken form
//          and keeps its own sentences; the other tables' ball names are TableGameWords.ball, reused.
import BreakdownRules
import Foundation

enum MatchWords {
    // MARK: Names

    static func title(_ kind: MatchKind) -> String {
        switch kind {
        case .eightBall: return String(localized: "Eight-ball")
        case .nineBall: return String(localized: "Nine-ball")
        case .bumperPool: return String(localized: "Bumper pool")
        case .fivePin: return String(localized: "Five-pin")
        case .barBilliards: return String(localized: "Bar billiards")
        }
    }

    /// The name a seat shows, falling back to "Player 2" for a seat the names list does not cover.
    static func name(_ player: PlayerID, in names: [String]) -> String {
        names.indices.contains(player.index) && !names[player.index].isEmpty
            ? names[player.index] : defaultName(player)
    }

    static func defaultName(_ player: PlayerID) -> String { String(localized: "Player \(player.index + 1)") }

    // MARK: You

    /// The seat the person holding the device plays: the one seat that is not the computer when the computer plays
    /// the other, or the only seat in a game played alone (bar billiards). Nil when no single seat is the person's
    /// (a game between people, kept only in old saves).
    static func personSeat(in players: [Player]) -> PlayerID? {
        let people = players.filter { !$0.isComputer }
        guard people.count == 1, players.count == 1 || players.contains(where: \.isComputer) else { return nil }
        return people[0].id
    }

    /// The seat the words call "you": the person's seat while it carries no name of its own. A seat's name is its
    /// default ("Player 1") from the start, in this language or, for a save written before a language change, in
    /// English; empty counts too. A name the player typed is theirs and the sentences use it.
    static func you(in players: [Player]) -> PlayerID? {
        guard let seat = personSeat(in: players), let p = players.first(where: { $0.id == seat }) else { return nil }
        return isDefaultName(p.name, seat: seat) ? seat : nil
    }

    /// True for a name the player never chose: empty, or the seat's default in this language or in English.
    static func isDefaultName(_ name: String, seat: PlayerID) -> Bool {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // The English default is built without the catalog on purpose: saves made in English keep that name.
        return n.isEmpty || n == defaultName(seat) || n == "Player \(seat.index + 1)"
    }

    /// A seat's name as a label on its own (score rows, the eight-ball and bumper-pool rows): "You" for the seat the
    /// words call you, otherwise its name.
    static func displayName(_ player: PlayerID, in names: [String], you: PlayerID?) -> String {
        player == you ? String(localized: "You") : name(player, in: names)
    }

    /// "the 3", "the 3 and the 11", in the player's language.
    static func balls(_ numbers: [Int]) -> String {
        numbers.map { String(localized: "the \($0)") }.formatted(.list(type: .and))
    }

    // MARK: The call

    static func callLine(_ call: EightBallCall) -> String {
        switch call {
        case .ball(let b, let p): return String(localized: "Called: the \(b), \(p.title).")
        case .safety: return String(localized: "Called: Safety.")
        }
    }

    /// The ruling card's line when the stroke went through with no call made and the game played the suggested call
    /// (MatchMode.lastCallWasSuggested), so the player sees what they were held to.
    static func suggestedCallUsed(_ call: EightBallCall) -> String {
        switch call {
        case .ball(let b, let p): return String(localized: "No call was made, so the suggested call was used: the \(b), \(p.title).")
        case .safety: return String(localized: "No call was made, so the suggested call was used: Safety.")
        }
    }

    // MARK: The banner

    /// The banner's heading. `isBreak` is only passed true for a pool rack's break (the other tables have no break,
    /// so their first shot is a plain "to shoot"); `isYou` says it to the person ("Your break", "Your shot").
    static func toShoot(_ name: String, isBreak: Bool, isYou: Bool = false) -> String {
        if isYou { return isBreak ? String(localized: "Your break") : String(localized: "Your shot") }
        return isBreak ? String(localized: "\(name) to break") : String(localized: "\(name) to shoot")
    }

    /// Nine-ball: the lowest ball on the table is the one to hit first.
    static func hitFirst(_ ball: Int) -> String { String(localized: "Hit the \(ball) first") }

    /// Nine-ball: a seat one foul from losing (NineBallRules.foulsToLose), a quiet line under "Hit the N first".
    static func onTwoFouls(_ name: String, isYou: Bool) -> String {
        isYou ? String(localized: "You are on two fouls. A third loses the game.")
              : String(localized: "\(name) is on two fouls.")
    }

    static func groupLine(_ group: EightBallGroup?, left: Int, tableOpen: Bool) -> String {
        guard let group else { return tableOpen ? String(localized: "Table open") : "" }
        return left == 0 ? String(localized: "\(group.title): on the 8")
                         : String(localized: "\(group.title): \(left) left")
    }

    // MARK: Fouls

    /// Who fouled and on which table, so a foul on the other tables is worded the way those tables are played.
    struct FoulContext {
        /// The game (pool numbers on the pool table; the other tables' balls by colour).
        var kind: MatchKind = .eightBall
        /// The shooter's name, for the foul that is theirs alone (five-pin's own ball knocking the pins).
        var shooter: String?
        /// The shooter is the seat the words call you.
        var shooterIsYou = false
        /// The ball the shooter had to hit first where the table fixes one (five-pin: the other player's ball).
        var target: Int?
    }

    /// One foul as the end of "Foul: ...". `firstBall` is the ball the struck ball touched first, when the recording
    /// has one, so a wrong-ball foul can name it. `illegalBreak` is true when the ruling also carries the reason
    /// breakIllegal: nine-ball files an illegal break under the "no rail" foul (the nearest code the rules have), so
    /// that foul is worded as the break's own failure, which is true even when some balls did reach a rail.
    /// On the pool table the words are as before. The other tables have no cue ball (each player strikes their own
    /// white, yellow or marked ball), so there the fouls that would name it say "the struck ball" and name balls by
    /// colour (TableGameWords.ball), never by a number.
    static func foul(_ f: MatchFoul, firstBall: Int?, illegalBreak: Bool = false,
                     context c: FoulContext = FoulContext()) -> String {
        if illegalBreak, f == .noRailAfterContact {
            return String(localized: "an illegal break: nothing went down and fewer than \(NineBallRules.breakRailCount) balls reached a rail")
        }
        if c.kind.isTableGame, let words = tableFoul(f, firstBall: firstBall, context: c) { return words }
        switch f {
        case .scratch: return String(localized: "the cue ball went in a pocket or off the table")
        case .wrongBallFirst:
            if let b = firstBall { return String(localized: "the cue ball hit the \(b) first") }
            return String(localized: "the cue ball hit the wrong ball first")
        case .noBallHit: return String(localized: "the cue ball touched no ball")
        case .noRailAfterContact: return String(localized: "no ball reached a rail after the hit")
        case .objectBallOffTable: return String(localized: "a ball left the table")
        case .cueOrBridgeTouchedBall: return String(localized: "the cue or the bridge touched a ball")
        case .doubleHit: return String(localized: "the cue struck the cue ball twice")
        case .illegalJump: return String(localized: "the cue ball was scooped over a ball")
        case .wrongCup: return String(localized: "a ball dropped in the other player's cup")
        case .ownBallKnockedPins: return ownBallKnockedPins(c)
        case .cueBallBehindHeadLine:
            return String(localized: "from behind the head line, the cue ball hit a ball behind the line without crossing it first")
        // The table rules may append fouls; until this file names one, the card still says a foul happened.
        @unknown default: return String(localized: "a foul")
        }
    }

    /// The other tables' own words for the fouls that would otherwise say "cue ball"; nil keeps the shared words
    /// (a ball off the table, the wrong cup, the pins: none of them names the struck ball).
    private static func tableFoul(_ f: MatchFoul, firstBall: Int?, context c: FoulContext) -> String? {
        switch f {
        case .wrongBallFirst:
            guard let b = firstBall else { return String(localized: "the wrong ball was hit first") }
            let first = TableGameWords.ball(b, kind: c.kind)
            if let t = c.target, t != b {
                // "the red was hit before the yellow"
                return String(localized: "\(first) was hit before \(TableGameWords.ball(t, kind: c.kind))")
            }
            return String(localized: "\(first) was hit first")
        case .noBallHit: return String(localized: "the struck ball touched no ball")
        case .scratch: return String(localized: "the struck ball left the table")
        default: return nil
        }
    }

    /// Five-pin's foul of knocking pins with your own ball, naming whose ball it was. With no name given the old
    /// words stand ("your own ball"), which is also what the person reads.
    private static func ownBallKnockedPins(_ c: FoulContext) -> String {
        guard let shooter = c.shooter, !c.shooterIsYou else { return String(localized: "your own ball knocked pins down") }
        return String(localized: "\(shooter)'s own ball knocked pins down")
    }

    // MARK: The ruling

    /// What the next shooter may do with the cue ball, with their name (or to the person, "for you"). Behind the head
    /// line it adds the rule that comes with it: a ball that is also behind the line can't be hit first.
    static func ballInHand(_ kind: BallInHand, for name: String, isYou: Bool = false) -> String? {
        switch kind {
        case .none: return nil
        case .anywhere:
            return isYou ? String(localized: "Ball in hand for you.") : String(localized: "Ball in hand for \(name).")
        case .behindHeadLine:
            return isYou
                ? String(localized: "Ball in hand behind the head line for you. From behind the line, a ball also behind it can't be hit first.")
                : String(localized: "Ball in hand behind the head line for \(name). From behind the line, a ball also behind it can't be hit first.")
        }
    }

    /// The ruling card's sentences, in order: what happened, then what follows.
    /// - Parameters:
    ///   - pocketed: object balls that dropped on this shot (from the recording).
    ///   - firstBall: the ball the shooter's struck ball touched first, or nil.
    ///   - kind: the game, so the other tables' balls are named as players there name them (default: pool numbers).
    ///   - you: the seat the words call you (MatchWords.you, MatchMode.you), or nil to name every seat.
    ///   - target: the ball the shooter had to hit first where the table fixes one (MatchMode.targetBall).
    ///   - mentionTimeUp: false for a routine ruling: in bar billiards every shot after the bar drops carries the
    ///     time-up reason, and the banner's bar-down line and the one-time announcement already say it.
    static func sentences(for r: Ruling, names: [String], pocketed: [Int], firstBall: Int?,
                          kind: MatchKind = .eightBall, you: PlayerID? = nil, target: Int? = nil,
                          mentionTimeUp: Bool = true) -> [String] {
        let shooter = name(r.shooter, in: names)
        let next = name(r.nextShooter, in: names)
        let shooterIsYou = r.shooter == you
        let nextIsYou = r.nextShooter == you
        // An answered choice is one sentence naming who chose and what (the computer's answers settle into the
        // banner), in place of the re-rack, spotted-ball and "shoots again" lines. What still follows is said after
        // it: ball in hand (taking the table after a scratch keeps it), or the turn passing (spotting the 8 hands the
        // table to whoever's turn it was). A re-rack says who breaks, and a break is always from behind the line, so
        // nothing follows it.
        if r.reasons.contains(.choiceAnswered) {
            var out = [choiceAnswered(r, names: names, you: you)]
            if !r.rerack {
                if let hand = ballInHand(r.ballInHand, for: next, isYou: nextIsYou) {
                    out.append(hand)
                } else if r.turnPasses {
                    out.append(nextIsYou ? String(localized: "Your shot.") : String(localized: "\(next) to shoot."))
                }
            }
            return out
        }
        // Pool balls by number; the other tables' balls by their names there.
        func balls(_ numbers: [Int]) -> String {
            kind.isTableGame ? TableGameWords.balls(numbers, kind: kind) : MatchWords.balls(numbers)
        }
        var out: [String] = []
        // An illegal break that the rules count as a foul (nine-ball) is said once, in the foul line.
        let illegalBreakFoul = r.fouled && r.reasons.contains(.breakIllegal) && r.fouls.contains(.noRailAfterContact)
        if r.fouled {
            let context = FoulContext(kind: kind, shooter: shooter, shooterIsYou: shooterIsYou, target: target)
            let what = r.fouls.map { foul($0, firstBall: firstBall, illegalBreak: illegalBreakFoul, context: context) }
                .formatted(.list(type: .and))
            out.append(String(localized: "Foul: \(what)."))
        }
        // The ball that won the game is said by the end line ("You pocketed the 9."), so the pot line lists only
        // what else dropped with it.
        let endCode = r.result?.reason
        let decidingBall: Int? = endCode == .eightBallPocketed ? 8 : (endCode == .nineBallPocketed ? 9 : nil)
        for reason in r.reasons {
            switch reason {
            case .legalPot:
                let others = pocketed.filter { $0 != decidingBall }
                if !others.isEmpty {
                    out.append(shooterIsYou ? String(localized: "You pocketed \(balls(others)).")
                                            : String(localized: "\(shooter) pocketed \(balls(others))."))
                }
            case .noLegalPot:
                out.append(pocketed.isEmpty ? String(localized: "Nothing went down.")
                                            : String(localized: "Went down without keeping the turn: \(balls(pocketed))."))
            case .calledBallMissed: out.append(String(localized: "The called ball did not go in the called pocket."))
            case .foul: break   // said above, with the fouls named
            case .tableOpen: out.append(String(localized: "The table is still open."))
            case .groupsAssigned:
                if let g = r.assignedGroup { out.append(groupTaken(g, by: shooter, isYou: shooterIsYou)) }
            case .breakLegal: out.append(String(localized: "A legal break."))
            case .breakIllegal:
                if !illegalBreakFoul {
                    out.append(String(localized: "The break pocketed nothing and drove too few balls to a rail."))
                }
            case .scratchOnBreak: out.append(String(localized: "Scratch on the break."))
            case .eightOnBreak: out.append(String(localized: "The 8 went down on the break."))
            case .ballSpotted:
                if !r.ballsToSpot.isEmpty { out.append(TableGameWords.spotted(r.ballsToSpot, kind: kind)) }
            case .foulWarning:
                out.append(shooterIsYou
                    ? String(localized: "You have fouled twice in a row. A third foul loses the game.")
                    : String(localized: "\(shooter) has fouled twice in a row. A third foul loses the game."))
            case .pointsScored:
                for (seat, p) in r.points.enumerated() where p != 0 {
                    let id = PlayerID(seat)
                    out.append(id == you ? String(localized: "You score \(p).")
                                         : String(localized: "\(name(id, in: names)) scores \(p)."))
                }
            case .pinsReset: out.append(String(localized: "The pins are stood up again."))
            case .ballsReturned: out.append(String(localized: "Balls come back to be played again."))
            // Bar billiards: the white peg costs the break in progress, not every point of the turn so far.
            case .whitePegDown: out.append(String(localized: "The white peg went down: this break's points are lost."))
            case .blackPegDown: out.append(String(localized: "The black peg went down: the whole score is lost."))
            // The shot that ends a game on the clock says "Time ran out." in its end line; "Time is up." as well would
            // say the same thing twice on one card.
            case .timeUp:
                if mentionTimeUp, r.result?.reason != .timeExpired { out.append(String(localized: "Time is up.")) }
            case .gameOver:
                // Why the game ended, so a game-ending card is never empty (an eight-ball loss has no other line).
                if let result = r.result {
                    let why = MatchWords.endReason(result, shooter: r.shooter, names: names, you: you)
                    if !why.isEmpty { out.append(why) }
                }
            case .choiceAnswered: break   // answered above
            case .rerack: out.append(String(localized: "The balls are racked again."))
            // Reasons appended later by the table rules say nothing here until they are given words.
            @unknown default: break
            }
        }
        // What follows, unless the game is over (the result card says that).
        if r.result == nil {
            if let hand = ballInHand(r.ballInHand, for: next, isYou: nextIsYou) {
                out.append(hand)
            } else if r.turnPasses {
                out.append(nextIsYou ? String(localized: "Your shot.") : String(localized: "\(next) to shoot."))
            } else if r.choice == nil {
                out.append(shooterIsYou ? String(localized: "You shoot again.")
                                        : String(localized: "\(shooter) shoots again."))
            }
        }
        return out
    }

    /// "You have the solids.", "Computer (Hard) has the stripes."
    private static func groupTaken(_ g: EightBallGroup, by shooter: String, isYou: Bool) -> String {
        if isYou {
            return g == .solids ? String(localized: "You have the solids.") : String(localized: "You have the stripes.")
        }
        return g == .solids ? String(localized: "\(shooter) has the solids.") : String(localized: "\(shooter) has the stripes.")
    }

    // MARK: Choices

    /// The question a pending choice asks. Put to the person it has no name in front ("Take the table as it lies,
    /// or have it racked again?").
    static func choicePrompt(_ c: PendingChoice, names: [String], you: PlayerID? = nil) -> String {
        if c.chooser == you {
            switch c.choice {
            case .acceptTableOrRerack: return String(localized: "Take the table as it lies, or have it racked again?")
            case .spotEightOrRerack: return String(localized: "Put the 8 back on its spot, or rack again?")
            }
        }
        let who = name(c.chooser, in: names)
        switch c.choice {
        case .acceptTableOrRerack: return String(localized: "\(who): take the table as it lies, or have it racked again?")
        case .spotEightOrRerack: return String(localized: "\(who): put the 8 back on its spot, or rack again?")
        }
    }

    static func answer(_ a: MatchChoiceAnswer) -> String {
        switch a {
        case .acceptTable: return String(localized: "Take the table")
        case .spotEight: return String(localized: "Spot the 8")
        case .rerack: return String(localized: "Rack again")
        }
    }

    /// An answered choice in one sentence naming who chose (the ruling's shooter is the chooser, as
    /// EightBallRules.ruling(answering:) builds it): a re-rack, the 8 spotted, or the table taken as it lies.
    static func choiceAnswered(_ r: Ruling, names: [String], you: PlayerID? = nil) -> String {
        let isYou = r.shooter == you
        let who = name(r.shooter, in: names)
        if r.rerack {
            return isYou ? String(localized: "You have it racked again and break.")
                         : String(localized: "\(who) has it racked again and breaks.")
        }
        if r.ballsToSpot.contains(8) {
            return isYou ? String(localized: "You have the 8 put back on its spot.")
                         : String(localized: "\(who) has the 8 put back on its spot.")
        }
        return isYou ? String(localized: "You take the table as it lies.")
                     : String(localized: "\(who) takes the table as it lies.")
    }

    // MARK: The end

    /// The result card's title (and a game-ending ruling's heading): who won, or plain "Game over" when the game
    /// names no winner.
    static func resultTitle(_ r: MatchResult, names: [String], you: PlayerID? = nil) -> String {
        guard let w = r.winner else { return String(localized: "Game over") }
        return w == you ? String(localized: "You win!") : String(localized: "\(name(w, in: names)) wins!")
    }

    /// Why the game ended. `shooter` is whoever took the last shot: for a loss on the 8 it is the player who lost.
    static func endReason(_ r: MatchResult, shooter: PlayerID?, names: [String], you: PlayerID? = nil) -> String {
        let who = shooter.map { name($0, in: names) } ?? ""
        let winner = r.winner.map { name($0, in: names) } ?? ""
        let whoIsYou = shooter != nil && shooter == you
        let winnerIsYou = r.winner != nil && r.winner == you
        switch r.reason {
        case .eightBallPocketed:
            return winnerIsYou ? String(localized: "You pocketed the 8 in the called pocket.")
                               : String(localized: "\(winner) pocketed the 8 in the called pocket.")
        case .eightOnFoul:
            return whoIsYou ? String(localized: "You pocketed the 8 on a foul.")
                            : String(localized: "\(who) pocketed the 8 on a foul.")
        case .eightEarly:
            return whoIsYou ? String(localized: "You pocketed the 8 before clearing your group.")
                            : String(localized: "\(who) pocketed the 8 before clearing their group.")
        case .eightWrongPocket:
            return whoIsYou ? String(localized: "You sank the 8 in a pocket that was not called.")
                            : String(localized: "\(who) sank the 8 in a pocket that was not called.")
        case .eightOffTable:
            return whoIsYou ? String(localized: "You knocked the 8 off the table.")
                            : String(localized: "\(who) knocked the 8 off the table.")
        case .nineBallPocketed:
            return winnerIsYou ? String(localized: "You pocketed the 9.") : String(localized: "\(winner) pocketed the 9.")
        case .threeConsecutiveFouls:
            // Said on the ruling card that ends the game, so it says the game was lost, not only the third foul.
            return whoIsYou ? String(localized: "You fouled three times in a row, which loses the game.")
                            : String(localized: "\(who) fouled three times in a row, which loses the game.")
        case .allBallsSunk:
            return winnerIsYou ? String(localized: "You sank every ball of your side.")
                               : String(localized: "\(winner) sank every ball of their side.")
        case .targetScoreReached:
            return winnerIsYou ? String(localized: "You reached the target score.")
                               : String(localized: "\(winner) reached the target score.")
        case .timeExpired: return String(localized: "Time ran out.")
        case .conceded: return String(localized: "The game was ended early.")
        @unknown default: return ""
        }
    }

    // MARK: Between turns

    /// The hand-over card's heading (and what VoiceOver says) in a game between two people: whose shot comes next.
    /// The same words as a ruling's "Sam to shoot." line, so the catalog already has them in every language.
    static func handOver(to name: String) -> String { String(localized: "\(name) to shoot.") }

    // MARK: The saved game

    /// The menu's Continue row (and the Tables page's question) for a saved match: which game, against whom, and
    /// whose shot it is. Against the computer it ends "Your shot." or "The computer's shot.", never a seat's name.
    static func savedLine(_ s: SavedMatchSummary) -> String {
        let game = title(s.kind)
        if let level = s.opponent {
            return s.computerToShoot
                ? String(localized: "\(game) against the computer (\(level.title)). The computer's shot.")
                : String(localized: "\(game) against the computer (\(level.title)). Your shot.")
        }
        if s.playerNames.count == 1 {
            return String(localized: "\(game), playing alone.")
        }
        let who = s.playerNames.formatted(.list(type: .and))
        return String(localized: "\(game): \(who). \(s.turnName) to shoot.")
    }
}
