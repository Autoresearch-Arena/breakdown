// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The score words of the three table games: TablePoints (what a five-pin or bar-billiards shot scored, line
//          by line, from the rules' own constants) and TableGameWords (those lines, the scores, the balls and the clock
//          in plain words), plus the spoken ruling's new parts in TableWords.ruling (points to either player, points
//          lost, the pegs, the scores). Words are compared with String(localized:) of the same sentence, so the tests
//          hold in every language the catalog carries; every point value comes from FivePinRules and BarBilliardsRules.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 21: bumper pool's balls are named by their side's colour
//          and counted, never by a pool number, and the strike line points at the ball the cue is on.)
// SRP/DRY check: Pass - checks only; no rule is re-decided here (the rulings are built by hand, the way the rules
//          would return them, and the package's own tests cover the rules).
@testable import Breakdown
import BreakdownRules
import XCTest

final class TableGameWordsTests: XCTestCase {
    private let names = ["Sam", "Alex"]

    // MARK: Five-pin points

    func testWhitePinsScoreTheirValueEach() {
        let r = Ruling(shooter: .first, nextShooter: .second, reasons: [.pointsScored, .pinsReset],
                       points: [2 * FivePinRules.whitePinPoints, 0])
        XCTAssertEqual(TablePoints.fivePin(pinsDown: [1, 2], targetHitRed: false, ruling: r),
                       [.whitePins(count: 2, points: 2 * FivePinRules.whitePinPoints)])
    }

    func testTheRedPinAlonePaysMore() {
        let r = Ruling(shooter: .first, nextShooter: .second, points: [FivePinRules.redPinAlonePoints, 0])
        XCTAssertEqual(TablePoints.fivePin(pinsDown: [FivePinRules.redPin], targetHitRed: false, ruling: r),
                       [.redPinAlone(points: FivePinRules.redPinAlonePoints)])
        let withOthers = TablePoints.fivePin(pinsDown: [FivePinRules.redPin, 3], targetHitRed: true, ruling: r)
        XCTAssertEqual(withOthers, [.whitePins(count: 1, points: FivePinRules.whitePinPoints),
                                    .redPin(points: FivePinRules.redPinPoints),
                                    .redBallHit(points: FivePinRules.redBallPoints)])
    }

    func testAFoulGivesThePointsToTheOtherPlayerAtLeastTheMinimum() {
        // A clean miss makes nothing; the ruling pays the other player the minimum.
        let miss = Ruling(shooter: .first, nextShooter: .second, fouls: [.noBallHit], reasons: [.foul, .pointsScored],
                          points: [0, FivePinRules.foulMinimum])
        XCTAssertEqual(TablePoints.fivePin(pinsDown: [], targetHitRed: false, ruling: miss),
                       [.foulPoints(to: .second, points: FivePinRules.foulMinimum, raisedToMinimum: true)])
        // Own ball knocked three white pins: those points, more than the minimum, go across unchanged.
        let made = 3 * FivePinRules.whitePinPoints
        let own = Ruling(shooter: .second, nextShooter: .first, fouls: [.ownBallKnockedPins], reasons: [.foul],
                         points: [made, 0])
        XCTAssertEqual(TablePoints.fivePin(pinsDown: [1, 2, 3], targetHitRed: false, ruling: own),
                       [.whitePins(count: 3, points: made), .foulPoints(to: .first, points: made, raisedToMinimum: false)])
    }

    func testAShotThatMakesNothingSaysSo() {
        let r = Ruling(shooter: .first, nextShooter: .second, points: [0, 0])
        XCTAssertEqual(TablePoints.fivePin(pinsDown: [], targetHitRed: false, ruling: r), [.nothingScored])
    }

    // MARK: Bar-billiards points

    func testDropsScoreTheirHoleAndTheRedDouble() {
        let values = BarBilliardsRules.holeValues
        let worth = values[0] + values[2] * BarBilliardsRules.redMultiplier
        let r = Ruling(shooter: .first, nextShooter: .first, reasons: [.pointsScored, .legalPot], points: [worth])
        let lines = TablePoints.barBilliards(drops: [(ball: 0, hole: 0), (ball: BarBilliardsRules.redBall, hole: 2)],
                                             hit: true, ruling: r, breakBefore: 100, breakAfter: 100 + worth)
        XCTAssertEqual(lines, [
            .drop(ball: 0, holeValue: values[0], points: values[0], isRed: false),
            .drop(ball: BarBilliardsRules.redBall, holeValue: values[2],
                  points: values[2] * BarBilliardsRules.redMultiplier, isRed: true),
            .breakSoFar(points: 100 + worth),
        ])
    }

    func testAMissScoresNothingAndEndsTheBreak() {
        let r = Ruling(shooter: .first, nextShooter: .second, fouls: [.noBallHit], reasons: [.foul], points: [0, 0])
        XCTAssertEqual(TablePoints.barBilliards(drops: [], hit: false, ruling: r, breakBefore: 250, breakAfter: 0),
                       [.missedEverything, .breakEnded(points: 250)])
    }

    func testTheBlackPegLosesTheWholeScoreAndTheWhiteTheBreak() {
        let black = Ruling(shooter: .first, nextShooter: .second, reasons: [.blackPegDown], points: [-1_200, 0])
        XCTAssertEqual(TablePoints.barBilliards(drops: [(ball: 0, hole: 1)], hit: true, ruling: black, breakBefore: 300,
                                                breakAfter: 0),
                       [.scoreLost(points: 1_200)], "a peg down scores nothing for the shot, whatever dropped")
        let white = Ruling(shooter: .first, nextShooter: .second, reasons: [.whitePegDown], points: [-300, 0])
        XCTAssertEqual(TablePoints.barBilliards(drops: [], hit: true, ruling: white, breakBefore: 300, breakAfter: 0),
                       [.breakLost(points: 300)])
    }

    // MARK: The words

    func testPointsLinesInWords() {
        let w = FivePinRules.whitePinPoints
        XCTAssertEqual(TableGameWords.line(.whitePins(count: 1, points: w), kind: .fivePin, names: names),
                       String(localized: "One white pin down: \(w) points."))
        XCTAssertEqual(TableGameWords.line(.whitePins(count: 3, points: 3 * w), kind: .fivePin, names: names),
                       String(localized: "\(3) white pins down: \(3 * w) points."))
        XCTAssertEqual(TableGameWords.line(.foulPoints(to: .second, points: 6, raisedToMinimum: false), kind: .fivePin,
                                           names: names),
                       String(localized: "It was a foul, so the \(6) points go to \("Alex")."))
        XCTAssertEqual(TableGameWords.line(.breakLost(points: 0), kind: .barBilliards, names: names),
                       String(localized: "The white peg went down; the break had no points to lose."))
        let red = BarBilliardsRules.redBall
        XCTAssertEqual(TableGameWords.line(.drop(ball: red, holeValue: 50, points: 100, isRed: true), kind: .barBilliards,
                                           names: names),
                       String(localized: "The red dropped in the \(50) hole and scores double: \(100) points."))
    }

    func testScoresAreSpokenForEveryPlayer() {
        let each = [String(localized: "\("Sam"): \(120)"), String(localized: "\("Alex"): \(80)")]
        XCTAssertEqual(TableGameWords.scores([120, 80], names: names),
                       String(localized: "Scores: \(each.formatted(.list(type: .and)))."))
    }

    func testBarBilliardsWhitesAreCountedNotListed() {
        let red = BarBilliardsRules.redBall
        XCTAssertEqual(TableGameWords.balls([0, 1, red], kind: .barBilliards),
                       [String(localized: "\(2) whites"), String(localized: "the red")].formatted(.list(type: .and)))
        XCTAssertEqual(TableGameWords.ball(FivePinRules.playerBalls[1], kind: .fivePin), String(localized: "the yellow"))
    }

    func testBumperPoolBallsAreNamedByTheirSidesColour() {
        // Seat 0 plays white, seat 1 red (TableBallSet.bumperPoolSideColours); each side's first ball is its marked one.
        let whiteMarked = BumperPoolRules.sides[0][0], whitePlain = BumperPoolRules.sides[0][1]
        let redMarked = BumperPoolRules.sides[1][0], redPlain = BumperPoolRules.sides[1][1]
        XCTAssertEqual(TableGameWords.ball(whiteMarked, kind: .bumperPool), String(localized: "the marked white"))
        XCTAssertEqual(TableGameWords.ball(whitePlain, kind: .bumperPool), String(localized: "a white"))
        XCTAssertEqual(TableGameWords.ball(redMarked, kind: .bumperPool), String(localized: "the marked red"))
        XCTAssertEqual(TableGameWords.ball(redPlain, kind: .bumperPool), String(localized: "a red"))
        // Plain balls are counted, never named by a number nobody can see.
        XCTAssertEqual(TableGameWords.balls([redMarked, BumperPoolRules.sides[0][1], BumperPoolRules.sides[0][2], redPlain],
                                            kind: .bumperPool),
                       [String(localized: "the marked red"), String(localized: "\(2) whites"), String(localized: "a red")]
                           .formatted(.list(type: .and)))
        XCTAssertEqual(TableGameWords.bumperStrike(redPlain, marked: false),
                       String(localized: "Strike the red the cue is set on."))
        XCTAssertEqual(TableGameWords.bumperStrike(whiteMarked, marked: true), String(localized: "Strike your marked ball."))
    }

    func testTheClockAndTheBar() {
        XCTAssertEqual(TableGameWords.timeLeft(seconds: 65),
                       String(localized: "Time left: \(Duration.seconds(65).formatted(.time(pattern: .minuteSecond)))"))
        XCTAssertEqual(TableGameWords.barDown(whitesLeft: 1), String(localized: "The bar is down: 1 white left to play."))
    }

    func testTheSpokenRulingCarriesPointsLossesAndScores() {
        let r = Ruling(shooter: .first, nextShooter: .second, reasons: [.blackPegDown], points: [-500, 0])
        let spoken = TableWords.ruling(r, names: names, scores: [0, 900])
        XCTAssertTrue(spoken.contains(String(localized: "The black peg went down: the whole score is lost.")))
        XCTAssertTrue(spoken.contains(String(localized: "\("Sam") loses \(500) points.")))
        XCTAssertTrue(spoken.contains(TableGameWords.scores([0, 900], names: names)))
        // A five-pin foul pays the other player, and that is said too.
        let foul = Ruling(shooter: .first, nextShooter: .second, fouls: [.noBallHit], reasons: [.foul],
                          points: [0, FivePinRules.foulMinimum])
        XCTAssertTrue(TableWords.ruling(foul, names: names)
            .contains(String(localized: "\("Alex") scores \(FivePinRules.foulMinimum).")))
    }
}
