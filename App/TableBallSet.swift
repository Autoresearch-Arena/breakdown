// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Which balls each table is played with (plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 21; contract
//          docs/v07-contracts.md section 1.2). Until 0.7.0 every table drew the sixteen numbered pool balls, so bar
//          billiards' "whites" were numbered pool balls, bumper pool's sides were solids against stripes with no mark on
//          the "marked ball", and the aiming badge said Solid or Stripe on every table. A table's ball set says, for each
//          ball slot (0 to 15, the solver's indices):
//            - look(of:): what the ball looks like, as codes the look stream draws (BallTextures) and the match views
//              colour their ball icons from: the numbered pool picture, one plain colour, or a colour with a spot;
//            - label(of:): the short word the target badge and the ball icons use ("Stripe", "White", "Marked red").
//          The words for a ball inside a sentence stay where they are (TableGameWords.ball for the three tables,
//          MatchWords and TableWords for pool); this file only adds the badge's short labels.
//          Which slot is which ball is read from the rules' own constants (BarBilliardsRules, FivePinRules,
//          BumperPoolRules), never retyped, so the drawing, the words and the game always agree. A slot a table does
//          not use keeps the pool look: it is off the table and never drawn there.
//          Pure value types, nonisolated and Sendable. Strings: localization/pending/v07-base.json.
// SRP/DRY check: Pass - checked BallTextures (draws the pool pictures; the look stream adds the plain and spotted ones
//          from these codes), TargetBallBadge (its Solid/Stripe/Eight ball words are reused here as the pool labels),
//          TableGameWords (in-sentence ball names, unchanged and not repeated) and TableKind (the table choice).
import BreakdownRules
import Foundation

/// The colours the non-pool balls come in. The look stream maps each to its drawn colour (BallTextures); white is the
/// pool cue ball's ivory, so a table's white ball and the pool cue ball look the same.
enum BallColour: String, CaseIterable, Sendable {
    case white, red, yellow
}

/// What one ball looks like, as a code for the drawing (not the drawing itself).
enum BallLook: Equatable, Sendable {
    /// The numbered pool picture BallTextures draws today: 0 is the cue ball, 1 to 7 solids, 8 the eight, 9 to 15
    /// stripes.
    case pool(number: Int)
    /// One colour all over, no number, no mark.
    case plain(BallColour)
    /// One colour with a round spot of another: bumper pool's marked ball of each side.
    case spotted(BallColour, spot: BallColour)
}

enum TableBallSet: String, CaseIterable, Sendable {
    /// The sixteen numbered pool balls.
    case pool
    /// Seven plain whites and one red (BarBilliardsRules.whiteBalls and redBall).
    case barBilliards
    /// A white and a yellow, one for each player, and a red object ball (FivePinRules.playerBalls and redBall).
    case fivePin
    /// Five balls a side, white against red; the first ball of each side (its marked ball) carries a spot of the
    /// other side's colour (BumperPoolRules.sides).
    case bumperPool

    /// The ball set a table is played with. Exhaustive on purpose: a new table fails to compile until it is given one.
    static func `for`(table: TableKind) -> TableBallSet {
        switch table {
        case .standard: return .pool
        case .barBilliards: return .barBilliards
        case .fivePin: return .fivePin
        case .bumperPool: return .bumperPool
        }
    }

    /// Bumper pool's side colours by seat: the first player's side is white and the second's red. Neither the rules
    /// nor the table file names a colour (they say only "five red and five white"); white goes to the first seat
    /// because its marked ball is ball 0, which is the white cue ball on every other table, so the first player keeps
    /// the white as at the pool table.
    static let bumperPoolSideColours: [BallColour] = [.white, .red]

    /// What the ball in slot `ball` looks like on this table.
    func look(of ball: Int) -> BallLook {
        switch self {
        case .pool:
            return .pool(number: ball)
        case .barBilliards:
            if ball == BarBilliardsRules.redBall { return .plain(.red) }
            if BarBilliardsRules.whiteBalls.contains(ball) { return .plain(.white) }
            return .pool(number: ball)
        case .fivePin:
            if ball == FivePinRules.redBall { return .plain(.red) }
            // playerBalls is [white's ball, yellow's ball], in seat order.
            switch FivePinRules.playerBalls.firstIndex(of: ball) {
            case 0?: return .plain(.white)
            case 1?: return .plain(.yellow)
            default: return .pool(number: ball)
            }
        case .bumperPool:
            guard let seat = BumperPoolRules.seat(of: ball), Self.bumperPoolSideColours.indices.contains(seat)
            else { return .pool(number: ball) }
            let colour = Self.bumperPoolSideColours[seat]
            // The marked ball is the first of its side's list (BumperPoolTable puts it in front of the side's cup).
            guard BumperPoolRules.sides[seat].first == ball else { return .plain(colour) }
            // The spot is the other side's colour, so it shows on either ball.
            return .spotted(colour, spot: colour == .red ? .white : .red)
        }
    }

    /// The short word for the ball in slot `ball`, for the target badge and the ball icons. Pool keeps the badge's
    /// existing words; the other tables name the colour, and a marked ball says so.
    func label(of ball: Int) -> String {
        switch look(of: ball) {
        case .pool(let number):
            if number == 0 { return String(localized: "Cue ball") }
            if number == 8 { return String(localized: "Eight ball") }
            return number > 8 ? String(localized: "Stripe") : String(localized: "Solid")
        case .plain(let colour):
            return Self.word(colour)
        case .spotted(let colour, _):
            switch colour {
            case .white: return String(localized: "Marked white")
            case .red: return String(localized: "Marked red")
            // No table marks a yellow ball; should one ever appear it is named by its colour alone.
            case .yellow: return Self.word(colour)
            }
        }
    }

    private static func word(_ colour: BallColour) -> String {
        switch colour {
        case .white: return String(localized: "White")
        case .red: return String(localized: "Red")
        case .yellow: return String(localized: "Yellow")
        }
    }
}
