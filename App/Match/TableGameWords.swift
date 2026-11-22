// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The words of the three table games (bumper pool, five-pin, bar billiards) that the pool games do not need:
//          the balls by the names players use at these tables (the white, the yellow, the red, a white, a marked
//          ball), each turn-banner line, the points-explained card after a five-pin or bar-billiards shot, the
//          spoken scores, the clock and the bar, the single-player best score, and each table's "How to play" steps
//          and game line. Every sentence goes through String(localized:) so the string catalog collects it; numbers
//          are passed in whole, so each language formats and orders them its own way. Every point value in the rules
//          steps is read from the rules' constants (FivePinRules, BarBilliardsRules), never retyped.
//          Read by MatchViews (banner, points card, result), MatchWords (ball lists on these tables), TableWords
//          (spoken scores), TableList and TableGamePage (game lines and rules), and the tests.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 20 and 21: the time-up line and the rules page's
//          "Time up" step say what the game does - after the bar drops only the whites left in the tray are played and
//          whites resting on the bed stay there - matching the banner's count (BarBilliardsRules.whitesLeftToPlay);
//          bumper pool's balls are named by their side's colour as TableBallSet draws them (white for the first
//          player, red for the second, a spot on each marked ball) instead of by pool numbers nobody can see, in
//          sentences, lists, the turn banner and the rules page.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: bar billiards' line in the Tables list says what the game is,
//          a score against the clock, without offering it as a game against a friend.)
// SRP/DRY check: Pass - checked MatchWords (the shared ruling sentences, game names and player names are reused from
//          there, not repeated) and TableKind (table names and summaries reused). Nothing else words these games.
import BreakdownRules
import Foundation

enum TableGameWords {
    // MARK: Balls

    /// One ball of a table game inside a sentence: five-pin's white, yellow and red; bar billiards' red and its
    /// whites (all alike); bumper pool's marked white and marked red, and its other balls by their side's colour
    /// (TableBallSet.bumperPool draws them plain, so a number would name something nobody can see).
    static func ball(_ ball: Int, kind: MatchKind) -> String {
        switch kind {
        case .fivePin:
            if ball == FivePinRules.redBall { return String(localized: "the red") }
            return ball == FivePinRules.playerBalls[0] ? String(localized: "the white") : String(localized: "the yellow")
        case .barBilliards:
            return ball == BarBilliardsRules.redBall ? String(localized: "the red") : String(localized: "a white")
        case .bumperPool:
            guard let colour = bumperColour(of: ball) else { return String(localized: "the \(ball)") }
            let marked = BumperPoolRules.sides.contains(where: { $0.first == ball })
            switch colour {
            case .red: return marked ? String(localized: "the marked red") : String(localized: "a red")
            // White, and yellow should a side ever be given it, read as a white ball.
            case .white, .yellow: return marked ? String(localized: "the marked white") : String(localized: "a white")
            }
        case .eightBall, .nineBall:
            return String(localized: "the \(ball)")
        }
    }

    /// Bumper pool: the colour of the side a ball belongs to (TableBallSet's seat colours); nil for a ball that is
    /// on neither side.
    static func bumperColour(of ball: Int) -> BallColour? {
        guard let seat = BumperPoolRules.seat(of: ball), TableBallSet.bumperPoolSideColours.indices.contains(seat)
        else { return nil }
        return TableBallSet.bumperPoolSideColours[seat]
    }

    /// A list of balls of a table game: "the white and the red". Balls that look alike are counted instead of listed
    /// one by one: bar billiards' whites ("2 whites and the red") and bumper pool's plain balls of each side ("the
    /// marked red, 2 whites and a red").
    static func balls(_ numbers: [Int], kind: MatchKind) -> String {
        switch kind {
        case .barBilliards:
            let whites = numbers.filter { $0 != BarBilliardsRules.redBall }.count
            var parts = counted(whites: whites, reds: 0)
            if numbers.contains(BarBilliardsRules.redBall) { parts.append(String(localized: "the red")) }
            return parts.formatted(.list(type: .and))
        case .bumperPool:
            // The marked balls are named one by one (each side has one); the rest are counted by colour.
            let marked = numbers.filter { b in BumperPoolRules.sides.contains(where: { $0.first == b }) }
            let plain = numbers.filter { !marked.contains($0) }
            let reds = plain.filter { bumperColour(of: $0) == .red }.count
            var parts = marked.map { ball($0, kind: kind) }
            parts += counted(whites: plain.count - reds, reds: reds)
            return parts.formatted(.list(type: .and))
        case .fivePin, .eightBall, .nineBall:
            return numbers.map { ball($0, kind: kind) }.formatted(.list(type: .and))
        }
    }

    /// "a white", "3 whites", "a red", "2 reds": the counted part of a list of balls that look alike.
    private static func counted(whites: Int, reds: Int) -> [String] {
        var parts: [String] = []
        if whites == 1 { parts.append(String(localized: "a white")) }
        if whites > 1 { parts.append(String(localized: "\(whites) whites")) }
        if reds == 1 { parts.append(String(localized: "a red")) }
        if reds > 1 { parts.append(String(localized: "\(reds) reds")) }
        return parts
    }

    /// Where a ball that the ruling puts back goes, as a sentence.
    static func spotted(_ numbers: [Int], kind: MatchKind) -> String {
        switch kind {
        case .bumperPool: return String(localized: "Back to where they started: \(balls(numbers, kind: kind)).")
        case .fivePin: return String(localized: "Back on its own spot: \(balls(numbers, kind: kind)).")
        case .barBilliards: return String(localized: "The red goes back on its spot.")
        case .eightBall, .nineBall: return String(localized: "Back on the foot spot: \(MatchWords.balls(numbers)).")
        }
    }

    // MARK: The turn banner

    /// Bumper pool: which ball the shooter strikes. The plain balls of a side look alike and the order is fixed, so
    /// the line points at the ball the cue is already set on rather than naming it.
    static func bumperStrike(_ ball: Int, marked: Bool) -> String {
        if marked { return String(localized: "Strike your marked ball.") }
        return bumperColour(of: ball) == .red ? String(localized: "Strike the red the cue is set on.")
                                              : String(localized: "Strike the white the cue is set on.")
    }

    /// Bumper pool: one side's balls still to sink.
    static func ballsToSink(_ count: Int) -> String {
        count == 1 ? String(localized: "1 ball left") : String(localized: "\(count) balls left")
    }

    /// Five-pin: which ball the shooter plays and which they must hit first.
    static func fivePinStrike(seat: Int) -> String {
        seat == 0 ? String(localized: "Strike the white; hit the yellow first.")
                  : String(localized: "Strike the yellow; hit the white first.")
    }

    /// Five-pin: the winning total.
    static func target(_ points: Int) -> String { String(localized: "First to \(points)") }

    /// Bar billiards: the break in progress.
    static func breakSoFar(_ points: Int) -> String { String(localized: "This break: \(points)") }

    /// Bar billiards: the time left as minutes and seconds, from whole seconds.
    static func timeLeft(seconds: Int) -> String {
        let clock = Duration.seconds(max(0, seconds)).formatted(.time(pattern: .minuteSecond))
        return String(localized: "Time left: \(clock)")
    }

    /// Bar billiards once time is up: the bar is down; whites still to play (the one on the D and the tray's, from
    /// BarBilliardsRules.whitesLeftToPlay; never the ones resting on the bed).
    static func barDown(whitesLeft: Int) -> String {
        whitesLeft == 1 ? String(localized: "The bar is down: 1 white left to play.")
                        : String(localized: "The bar is down: \(whitesLeft) whites left to play.")
    }

    /// Spoken (and shown once) the moment the clock reaches zero.
    static var timeUpNow: String {
        String(localized: "Time is up. The bar is down: balls that drop now stay down. You play on with the whites left in the tray, and the game ends once the last one has been played.")
    }

    /// Bar billiards alone: the best score kept on this device.
    static func best(_ points: Int?) -> String {
        guard let points else { return String(localized: "No best score yet") }
        return String(localized: "Best: \(points)")
    }

    // MARK: Scores

    /// Everyone's score in one sentence, for VoiceOver: "Scores: Sam: 120 and Alex: 80."
    static func scores(_ scores: [Int], names: [String]) -> String {
        let each = scores.enumerated().map { seat, score in
            String(localized: "\(MatchWords.name(PlayerID(seat), in: names)): \(score)")
        }
        return String(localized: "Scores: \(each.formatted(.list(type: .and))).")
    }

    // MARK: The points-explained card

    /// One line of the card in plain words. `kind` names the balls; `names` the players.
    static func line(_ l: TablePoints.Line, kind: MatchKind, names: [String]) -> String {
        switch l {
        case .whitePins(let count, let points):
            return count == 1 ? String(localized: "One white pin down: \(points) points.")
                              : String(localized: "\(count) white pins down: \(points) points.")
        case .redPin(let points): return String(localized: "The red pin down with others: \(points) points.")
        case .redPinAlone(let points): return String(localized: "The red pin down on its own: \(points) points.")
        case .redBallHit(let points): return String(localized: "The other player's ball hit the red: \(points) points.")
        case .foulPoints(let to, let points, let raised):
            let who = MatchWords.name(to, in: names)
            return raised ? String(localized: "It was a foul, so \(who) gets the points, raised to the least a foul gives: \(points).")
                          : String(localized: "It was a foul, so the \(points) points go to \(who).")
        case .drop(let ball, let value, let points, let isRed):
            return isRed ? String(localized: "The red dropped in the \(value) hole and scores double: \(points) points.")
                         : String(localized: "\(capitalised(TableGameWords.ball(ball, kind: kind))) dropped in the \(value) hole: \(points) points.")
        case .missedEverything: return String(localized: "The white touched no ball, so nothing scores.")
        case .breakLost(let points):
            return points == 0 ? String(localized: "The white peg went down; the break had no points to lose.")
                               : String(localized: "The white peg went down: this break's \(points) points are lost.")
        case .scoreLost(let points):
            return points == 0 ? String(localized: "The black peg went down; there was no score to lose.")
                               : String(localized: "The black peg went down: all \(points) points are lost.")
        case .breakSoFar(let points): return String(localized: "The break goes on with \(points) points so far.")
        case .breakEnded(let points): return String(localized: "The break is over with \(points) points.")
        case .nothingScored: return String(localized: "No points this shot.")
        }
    }

    /// The whole card, in order.
    static func lines(_ ls: [TablePoints.Line], kind: MatchKind, names: [String]) -> [String] {
        ls.map { line($0, kind: kind, names: names) }
    }

    /// The first letter in upper case, for a ball phrase that starts a sentence ("A white dropped ...").
    private static func capitalised(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased(with: .current) + s.dropFirst()
    }

    // MARK: The result

    /// Bar billiards alone: what the finished game did to the best score.
    static func bestOutcome(_ o: BarBilliardsBest.Outcome) -> String {
        switch o {
        case .first(let score): return String(localized: "Your first finished game: \(score) is the score to beat.")
        case .newBest(let score, let previous): return String(localized: "New best score: \(score), beating \(previous).")
        case .notBest(let score, let best): return String(localized: "You scored \(score). Your best is still \(best).")
        }
    }

    // MARK: The Tables list and How to play

    /// The game a table plays, in one line for the Tables list.
    static func gameLine(_ kind: MatchKind) -> String {
        switch kind {
        case .bumperPool: return String(localized: "Two players race to sink five balls each in the far cup.")
        case .fivePin: return String(localized: "Two players score with the pins and the red, first to \(FivePinRules.standardTarget).")
        case .barBilliards: return String(localized: "Score as much as you can before the clock runs out.")
        case .eightBall, .nineBall: return ""
        }
    }

    /// Said on every rules page: these games vary from place to place.
    static var oneVersion: String {
        String(localized: "These rules vary from place to place. This is one common, simple version.")
    }

    /// Each game's rules as numbered steps, in the words of the rule sheet the package builds.
    static func steps(_ kind: MatchKind) -> [(title: String, detail: String)] {
        switch kind {
        case .bumperPool:
            return [
                (String(localized: "The idea"),
                 String(localized: "Two players, five balls each: white for the first player, red for the second. Sink all five of yours in the cup at the far end from where they started, before the other player does.")),
                (String(localized: "Your ball"),
                 String(localized: "You always strike one of your own balls: your marked ball, the one with a spot, while it is on the table, then your others one at a time in a fixed order. The cue is always set on the right one.")),
                (String(localized: "Keep your turn"),
                 String(localized: "Sink one of your own balls in your cup and you shoot again. Otherwise the turn passes.")),
                (String(localized: "Fouls"),
                 String(localized: "A ball in the wrong cup, or any ball knocked off the table, is a foul. That ball goes back to where it started and the turn passes.")),
                (String(localized: "Winning"),
                 String(localized: "The first side with all five balls in its cup wins, whoever sank the last one. An opponent's ball you knock into their own cup counts for them.")),
            ]
        case .fivePin:
            return [
                (String(localized: "The idea"),
                 String(localized: "Two players: one plays the white, the other the yellow. The red ball and the five pins in the middle are shared.")),
                (String(localized: "A fair shot"),
                 String(localized: "Strike your own ball so it hits the other player's ball first. Points come from what that ball and the red do next.")),
                (String(localized: "Points"),
                 String(localized: "Each white pin down scores \(FivePinRules.whitePinPoints). The red pin scores \(FivePinRules.redPinPoints), or \(FivePinRules.redPinAlonePoints) if it is the only pin to fall. The other player's ball hitting the red scores \(FivePinRules.redBallPoints).")),
                (String(localized: "Fouls"),
                 String(localized: "Missing the other ball, hitting the red first, knocking a pin with your own ball, or sending a ball off the table is a foul. The shot's points go to the other player, and never fewer than \(FivePinRules.foulMinimum).")),
                (String(localized: "Every shot"),
                 String(localized: "Turns alternate after every shot. The pins are stood up again, and a ball resting on a pin's spot goes back to its own spot.")),
                (String(localized: "Winning"),
                 String(localized: "The first to \(FivePinRules.standardTarget) points wins.")),
            ]
        case .barBilliards:
            let minutes = Int(BarBilliardsRules.standardClock / 60)
            return [
                (String(localized: "The idea"),
                 String(localized: "One or two players against a \(minutes)-minute clock. Two players take breaks in turn and the higher score wins; alone, you play for your best score.")),
                (String(localized: "Each shot"),
                 String(localized: "Every shot is a white from the tray, placed on the spot in the D. The red starts on its own spot.")),
                (String(localized: "Scoring"),
                 String(localized: "Your ball must hit another ball first. Each ball that then drops scores the number by its hole, and the red scores double.")),
                (String(localized: "Your break"),
                 String(localized: "Your break goes on while every shot drops a ball. A shot that drops nothing ends it; a shot that hits no ball scores nothing and ends it.")),
                (String(localized: "The pegs"),
                 String(localized: "Knock down a white peg and the break ends with its points lost. Knock down the black peg and your whole score is lost.")),
                (String(localized: "Balls come back"),
                 String(localized: "Dropped balls come back to the tray and the red goes back on its spot, until time is up.")),
                (String(localized: "Time up"),
                 String(localized: "When the clock runs out a bar drops: balls that drop stay down. You play on with the whites left in the tray; whites resting on the table stay where they are. When the last white from the tray has been played, the game ends. The clock stops while you watch a replay or the Lens.")),
            ]
        case .eightBall, .nineBall:
            return []
        }
    }
}
