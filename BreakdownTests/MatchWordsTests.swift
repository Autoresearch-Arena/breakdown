// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The match's words since 0.7.5 (plans/22-Nov-2026-v075-whatif-and-gaps-plan.md, stream match-ui): the person
//          is "you" (MatchWords.personSeat and you: the seat that is not the computer, while its name is the default)
//          in every sentence that names a seat, while the computer's sentences keep its name and a typed name is kept;
//          the saved game's line says "Your shot." or "The computer's shot."; a game-ending ruling always says why
//          (an eight-ball loss card is never empty, three fouls says the game was lost); the computer's answer to a
//          choice is one sentence for each answer; a game the computer wins does not play the win moment; ball in hand
//          behind the head line states its rule and the new head-line foul is worded; nine-ball's two-foul line; the
//          repeated "Time is up." can be left out. Words are compared with String(localized:) of the same sentence, so
//          the tests hold in every language the catalog carries; names are built from MatchWords.defaultName and
//          OpponentWords.name, never typed in English, except where a test is about an English name in an old save.
// SRP/DRY check: Pass - checks only. The table games' own words (points, banners, five-pin fouls) are checked in
//          TableGameWordsTests; the rulings themselves in the package's rules tests.
@testable import Breakdown
import BreakdownRules
import XCTest

final class MatchWordsTests: XCTestCase {
    // MARK: Seats

    /// The person in the first seat on the default name, the computer at Hard in the second (as MatchMode seats them).
    private var players: [Player] {
        [Player(id: .first, name: MatchWords.defaultName(.first)),
         Player(id: .second, name: OpponentWords.name(.hard), computer: .hard)]
    }

    private var names: [String] { players.map(\.name) }
    private var computer: String { OpponentWords.name(.hard) }

    func testThePersonsSeatIsYouAndTheComputerKeepsItsName() {
        let you = MatchWords.you(in: players)
        XCTAssertEqual(you, .first)
        XCTAssertEqual(MatchWords.personSeat(in: players), .first)

        let mine = Ruling(shooter: .first, nextShooter: .first, reasons: [.legalPot, .groupsAssigned],
                          assignedGroup: .solids)
        let said = MatchWords.sentences(for: mine, names: names, pocketed: [3], firstBall: 3, you: you)
        XCTAssertTrue(said.contains(String(localized: "You pocketed \(MatchWords.balls([3])).")), "\(said)")
        XCTAssertTrue(said.contains(String(localized: "You have the solids.")), "\(said)")
        XCTAssertTrue(said.contains(String(localized: "You shoot again.")), "\(said)")

        let theirs = Ruling(shooter: .second, nextShooter: .second, reasons: [.groupsAssigned], assignedGroup: .stripes)
        let told = MatchWords.sentences(for: theirs, names: names, pocketed: [], firstBall: nil, you: you)
        XCTAssertTrue(told.contains(String(localized: "\(computer) has the stripes.")), "\(told)")
        XCTAssertTrue(told.contains(String(localized: "\(computer) shoots again.")), "\(told)")

        // The turn passing to the person, and the person's ball in hand.
        let passes = Ruling(shooter: .second, nextShooter: .first, reasons: [.noLegalPot])
        XCTAssertTrue(MatchWords.sentences(for: passes, names: names, pocketed: [], firstBall: nil, you: you)
            .contains(String(localized: "Your shot.")))
        let foul = Ruling(shooter: .second, nextShooter: .first, fouls: [.scratch], reasons: [.foul], ballInHand: .anywhere)
        XCTAssertTrue(MatchWords.sentences(for: foul, names: names, pocketed: [], firstBall: nil, you: you)
            .contains(String(localized: "Ball in hand for you.")))

        XCTAssertEqual(MatchWords.resultTitle(MatchResult(winner: .first, reason: .eightBallPocketed), names: names, you: you),
                       String(localized: "You win!"))
        XCTAssertEqual(MatchWords.resultTitle(MatchResult(winner: .second, reason: .eightBallPocketed), names: names, you: you),
                       String(localized: "\(computer) wins!"))
        XCTAssertEqual(MatchWords.toShoot(names[0], isBreak: false, isYou: true), String(localized: "Your shot"))
        XCTAssertEqual(MatchWords.toShoot(names[0], isBreak: true, isYou: true), String(localized: "Your break"))
        XCTAssertEqual(MatchWords.toShoot(computer, isBreak: false), String(localized: "\(computer) to shoot"))
        XCTAssertEqual(MatchWords.displayName(.first, in: names, you: you), String(localized: "You"))
        XCTAssertEqual(MatchWords.displayName(.second, in: names, you: you), computer)
        XCTAssertEqual(MatchWords.choicePrompt(PendingChoice(choice: .acceptTableOrRerack, chooser: .first), names: names,
                                               you: you),
                       String(localized: "Take the table as it lies, or have it racked again?"))
    }

    func testATypedNameIsKept() {
        var named = players
        named[0].name = "Sam"
        XCTAssertNil(MatchWords.you(in: named), "a typed name is the person's own")
        XCTAssertEqual(MatchWords.personSeat(in: named), .first, "still the person's seat for wins and losses")
        let r = Ruling(shooter: .first, nextShooter: .first, reasons: [.legalPot])
        let said = MatchWords.sentences(for: r, names: named.map(\.name), pocketed: [], firstBall: nil,
                                        you: MatchWords.you(in: named))
        XCTAssertEqual(said, [String(localized: "\("Sam") shoots again.")])

        // An emptied name, and the English default of a save written before a language change, are still "you".
        var empty = players
        empty[0].name = ""
        XCTAssertEqual(MatchWords.you(in: empty), .first)
        var english = players
        english[0].name = "Player 1"
        XCTAssertEqual(MatchWords.you(in: english), .first)
    }

    func testNobodyIsYouBetweenTwoPeopleAndPlayingAloneIsYou() {
        let people = [Player(id: .first, name: MatchWords.defaultName(.first)),
                      Player(id: .second, name: MatchWords.defaultName(.second))]
        XCTAssertNil(MatchWords.personSeat(in: people))
        XCTAssertNil(MatchWords.you(in: people))
        let alone = [Player(id: .first, name: MatchWords.defaultName(.first))]
        XCTAssertEqual(MatchWords.you(in: alone), .first)
        let r = Ruling(shooter: .first, nextShooter: .first, reasons: [.pointsScored], points: [40])
        XCTAssertTrue(MatchWords.sentences(for: r, names: alone.map(\.name), pocketed: [], firstBall: nil,
                                           kind: .barBilliards, you: .first)
            .contains(String(localized: "You score \(40).")))
    }

    // MARK: The saved game

    func testTheSavedLineSaysWhoseShot() {
        let game = MatchWords.title(.eightBall)
        let level = ComputerLevel.hard.title
        let yours = SavedMatchSummary(kind: .eightBall, opponent: .hard, playerNames: names,
                                      turnName: names[0], computerToShoot: false)
        XCTAssertEqual(MatchWords.savedLine(yours),
                       String(localized: "\(game) against the computer (\(level)). Your shot."))
        let theirs = SavedMatchSummary(kind: .eightBall, opponent: .hard, playerNames: names,
                                       turnName: computer, computerToShoot: true)
        XCTAssertEqual(MatchWords.savedLine(theirs),
                       String(localized: "\(game) against the computer (\(level)). The computer's shot."))
    }

    // MARK: The end of a game

    func testAGameEndingEightBallLossIsNeverAnEmptyCard() {
        // Pocketing the 8 early: the rules give no foul and no pot line, only the end.
        let early = Ruling(shooter: .first, nextShooter: .second, reasons: [.gameOver],
                           result: MatchResult(winner: .second, reason: .eightEarly))
        let said = MatchWords.sentences(for: early, names: names, pocketed: [8], firstBall: 2, you: .first)
        XCTAssertFalse(said.isEmpty)
        XCTAssertEqual(said, [String(localized: "You pocketed the 8 before clearing your group.")])
        // The computer losing on the 8 names it.
        let theirs = Ruling(shooter: .second, nextShooter: .first, reasons: [.gameOver],
                            result: MatchResult(winner: .first, reason: .eightOffTable))
        XCTAssertEqual(MatchWords.sentences(for: theirs, names: names, pocketed: [], firstBall: nil, you: .first),
                       [String(localized: "\(computer) knocked the 8 off the table.")])
        for s in said { XCTAssertFalse(s.isEmpty) }
    }

    func testThreeFoulsInARowSaysTheGameWasLost() {
        let r = Ruling(shooter: .first, nextShooter: .second, fouls: [.noBallHit], reasons: [.foul, .gameOver],
                       result: MatchResult(winner: .second, reason: .threeConsecutiveFouls))
        let said = MatchWords.sentences(for: r, names: names, pocketed: [], firstBall: nil, kind: .nineBall, you: .first)
        XCTAssertTrue(said.contains(String(localized: "You fouled three times in a row, which loses the game.")), "\(said)")
        XCTAssertFalse(said.contains(String(localized: "Your shot.")), "nothing follows the end of a game")
    }

    func testTheWinningPotIsSaidOnce() {
        let r = Ruling(shooter: .first, nextShooter: .first, reasons: [.legalPot, .gameOver],
                       result: MatchResult(winner: .first, reason: .nineBallPocketed))
        XCTAssertEqual(MatchWords.sentences(for: r, names: names, pocketed: [9], firstBall: 4, kind: .nineBall, you: .first),
                       [String(localized: "You pocketed the 9.")])
    }

    @MainActor
    func testAGameTheComputerWinsDoesNotPlayTheWin() {
        let r = Ruling(shooter: .second, nextShooter: .second, reasons: [.legalPot, .gameOver],
                       result: MatchResult(winner: .second, reason: .eightBallPocketed))
        XCTAssertNotEqual(MatchMode.moment(for: r, winnerIsComputer: true), .win)
        XCTAssertEqual(MatchMode.moment(for: r, winnerIsComputer: true), .foul)
        XCTAssertEqual(MatchMode.moment(for: r, winnerIsComputer: false), .win)
        // A game with no named winner (bar billiards alone) keeps the win.
        let alone = Ruling(shooter: .first, nextShooter: .first, reasons: [.gameOver],
                           result: MatchResult(winner: nil, reason: .timeExpired))
        XCTAssertEqual(MatchMode.moment(for: alone), .win)
    }

    // MARK: The computer's answer

    func testTheComputersAnswerIsOneSentenceForEachAnswer() {
        let rules = EightBallRules()
        var state = rules.initialState(playerNames: names)
        state.players[1].computer = .hard
        state.ballInHand = .none
        state.turn = .second
        state.pendingChoice = PendingChoice(choice: .acceptTableOrRerack, chooser: .second)
        let take = rules.ruling(answering: .acceptTable, in: state)
        XCTAssertEqual(MatchWords.sentences(for: take, names: names, pocketed: [], firstBall: nil, you: .first),
                       [String(localized: "\(computer) takes the table as it lies.")])
        let rack = rules.ruling(answering: .rerack, in: state)
        XCTAssertEqual(MatchWords.sentences(for: rack, names: names, pocketed: [], firstBall: nil, you: .first),
                       [String(localized: "\(computer) has it racked again and breaks.")],
                       "the re-rack line already says who breaks; no ball-in-hand or shoots-again line follows")
        state.pendingChoice = PendingChoice(choice: .spotEightOrRerack, chooser: .second)
        let spot = rules.ruling(answering: .spotEight, in: state)
        XCTAssertEqual(MatchWords.sentences(for: spot, names: names, pocketed: [], firstBall: nil, you: .first),
                       [String(localized: "\(computer) has the 8 put back on its spot.")])

        // Taking the table with ball in hand still says so after the choice.
        state.pendingChoice = PendingChoice(choice: .acceptTableOrRerack, chooser: .second)
        state.ballInHand = .anywhere
        let withHand = rules.ruling(answering: .acceptTable, in: state)
        XCTAssertEqual(MatchWords.sentences(for: withHand, names: names, pocketed: [], firstBall: nil, you: .first),
                       [String(localized: "\(computer) takes the table as it lies."),
                        String(localized: "Ball in hand for \(computer).")])
        // Spotting the 8 hands the table to whoever's turn it was: that is said too.
        state.ballInHand = .none
        state.turn = .first
        state.pendingChoice = PendingChoice(choice: .spotEightOrRerack, chooser: .second)
        let handed = rules.ruling(answering: .spotEight, in: state)
        XCTAssertEqual(MatchWords.sentences(for: handed, names: names, pocketed: [], firstBall: nil, you: .first),
                       [String(localized: "\(computer) has the 8 put back on its spot."), String(localized: "Your shot.")])
    }

    // MARK: Fouls and ball in hand

    func testBallInHandBehindTheLineStatesItsRule() {
        XCTAssertEqual(MatchWords.ballInHand(.behindHeadLine, for: names[0], isYou: true),
                       String(localized: "Ball in hand behind the head line for you. From behind the line, a ball also behind it can't be hit first."))
        XCTAssertEqual(MatchWords.ballInHand(.behindHeadLine, for: computer),
                       String(localized: "Ball in hand behind the head line for \(computer). From behind the line, a ball also behind it can't be hit first."))
        XCTAssertEqual(MatchWords.foul(.cueBallBehindHeadLine, firstBall: 2),
                       String(localized: "from behind the head line, the cue ball hit a ball behind the line without crossing it first"))
        XCTAssertNotEqual(MatchWords.foul(.cueBallBehindHeadLine, firstBall: 2), String(localized: "a foul"))
    }

    func testThePoolFoulsKeepTheirWords() {
        XCTAssertEqual(MatchWords.foul(.wrongBallFirst, firstBall: 11), String(localized: "the cue ball hit the \(11) first"))
        XCTAssertEqual(MatchWords.foul(.scratch, firstBall: nil),
                       String(localized: "the cue ball went in a pocket or off the table"))
    }

    func testOneFoulFromLosing() {
        XCTAssertEqual(MatchWords.onTwoFouls(names[0], isYou: true),
                       String(localized: "You are on two fouls. A third loses the game."))
        XCTAssertEqual(MatchWords.onTwoFouls(computer, isYou: false), String(localized: "\(computer) is on two fouls."))
        let r = Ruling(shooter: .first, nextShooter: .second, fouls: [.scratch], reasons: [.foul, .foulWarning],
                       ballInHand: .anywhere)
        XCTAssertTrue(MatchWords.sentences(for: r, names: names, pocketed: [], firstBall: nil, kind: .nineBall, you: .first)
            .contains(String(localized: "You have fouled twice in a row. A third foul loses the game.")))
    }

    // MARK: Bar billiards

    func testTimeUpCanBeLeftOutAndTheWhitePegLosesTheBreak() {
        let r = Ruling(shooter: .first, nextShooter: .first, reasons: [.timeUp, .whitePegDown], points: [-120])
        let card = MatchWords.sentences(for: r, names: [names[0]], pocketed: [], firstBall: nil, kind: .barBilliards,
                                        you: .first)
        XCTAssertTrue(card.contains(String(localized: "Time is up.")))
        XCTAssertTrue(card.contains(String(localized: "The white peg went down: this break's points are lost.")))
        let routine = MatchWords.sentences(for: r, names: [names[0]], pocketed: [], firstBall: nil, kind: .barBilliards,
                                           you: .first, mentionTimeUp: false)
        XCTAssertFalse(routine.contains(String(localized: "Time is up.")))
    }
}
