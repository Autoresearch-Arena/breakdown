// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The table in words, for a player who cannot see it (accessibility plan, packages 1 to 3). Every sentence
//          VoiceOver says about the balls, the aim and the shot is built here, from the same numbers the screen draws:
//          - ballLabel / place / ballValue: each ball's name ("3 ball, solid") and where it is in the terms a player
//            uses at a table (near which pocket, against which rail, how many diamonds from the head or foot rail and
//            from the nearer long rail), plus what is in the way between it and the cue ball.
//          - pocketLabel: a pocket by the name the eight-ball game gives it (EightBallPocket.title).
//          - aim: what the cue ball will hit first, how full ("half-ball hit, cutting it to the left") and where that
//            ball goes next ("It goes into the foot-left corner pocket" / "It misses ... by about 1 ball-width"),
//            from the aim guide's own ray cast (AimGeometry.firstContact) and the shared line tests (TableLines).
//          - summary: one to three short sentences when a shot finishes, from the shared reading of the shot
//            (ShotFacts): a miscue, what the cue ball hit first, what dropped and where, where the cue ball stopped.
//          - ruling: a match ruling spoken (fouls, group, ball in hand, the result and who shoots next), from the
//            Ruling codes the rules engine returns (BreakdownRules), with the players' names.
//          Read by TableStage (the table's accessibility children, the narration), AimOverlay (the aim element) and
//          TableAccessLayer. Words go through String(localized:) so the string catalog collects them; numbers are
//          formatted for the player's language. No drawing and no model writes.
// SRP/DRY check: Pass - checked CaptionEngine (Captions.swift: the per-event physics sentences, reused as they are
//          for "Step through the shot"; its ball-name strings are reused here), EightBallTypes (pocket, group and
//          foul titles, reused) and EightBallJudge (its line tests now live in TableLines, used here). The ruling
//          words are private to this file on purpose: the match screens own the visible ruling card and may give the
//          same codes their own titles; two extensions on one package type would clash.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

enum TableWords {
    // MARK: Names

    /// A ball as it appears inside a sentence: "the cue ball", "the 3 ball" (strings shared with the captions).
    static func ballName(_ ball: Int, cueBall: Int = 0) -> String {
        ball == cueBall ? String(localized: "the cue ball") : String(localized: "the \(ball) ball")
    }

    /// A ball as an element's label: "Cue ball", "3 ball, solid", "11 ball, stripe", "8 ball". Solids and stripes
    /// only on the pool table (`pool`); the other tables' balls are just numbered.
    static func ballLabel(_ ball: Int, cueBall: Int = 0, pool: Bool) -> String {
        if ball == cueBall { return String(localized: "Cue ball") }
        guard pool else { return String(localized: "\(ball) ball") }
        switch EightBallGroup.of(ball: ball) {
        case .solids?: return String(localized: "\(ball) ball, solid")
        case .stripes?: return String(localized: "\(ball) ball, stripe")
        case nil: return String(localized: "\(ball) ball")
        }
    }

    /// An edge pocket's element label, exactly as the eight-ball game names it ("Foot-left corner"). Pocket index is
    /// the solver's (0 to 5), which is EightBallPocket's raw value.
    static func pocketLabel(_ pocket: Int) -> String? {
        EightBallPocket(rawValue: pocket)?.title
    }

    /// An edge pocket inside a sentence: "the foot-left corner pocket".
    static func pocketPhrase(_ pocket: Int) -> String {
        switch EightBallPocket(rawValue: pocket) {
        case .headLeft?: return String(localized: "the head-left corner pocket")
        case .headRight?: return String(localized: "the head-right corner pocket")
        case .footLeft?: return String(localized: "the foot-left corner pocket")
        case .footRight?: return String(localized: "the foot-right corner pocket")
        case .leftSide?: return String(localized: "the left side pocket")
        case .rightSide?: return String(localized: "the right side pocket")
        case nil: return String(localized: "a hole in the bed")
        }
    }

    /// A rail inside a sentence. Index as TableLines.Heading.rail: 0 head (x = 0), 1 foot (x = L), 2 right (y = 0),
    /// 3 left (y = W); left and right as the player sees them standing at the head end (EightBallPocket's convention).
    static func railPhrase(_ rail: Int) -> String {
        switch rail {
        case 0: return String(localized: "the head rail")
        case 1: return String(localized: "the foot rail")
        case 2: return String(localized: "the right rail")
        default: return String(localized: "the left rail")
        }
    }

    /// A count of ball-widths or diamonds, rounded to the nearest half (finer than a player can judge by eye or
    /// hand), in the player's number style: "2", "1.5", "0.5".
    static func amount(_ x: Double) -> String {
        ((x * 2).rounded() / 2).formatted(.number.precision(.fractionLength(0...1)))
    }

    /// A sentence that begins with a ball's name ("the 3 ball ...") starts with a capital, as a sentence should.
    /// Upper-cases only the first character, in the player's language; scripts without case are unchanged.
    static func capitalized(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased(with: Locale.current) + s.dropFirst()
    }

    // MARK: Where a ball is

    /// Within this many ball-widths of a pocket's centre a ball is described by the pocket, not by diamonds.
    /// Four widths is about a diamond and a quarter on a pool table: the area a player would call "by the pocket".
    static let nearPocketWidths = 4.0
    /// A ball whose edge is within half a ball-width of a cushion is "against" it.
    static let againstRailWidths = 0.5

    /// Where a point on the table is, as a phrase that can follow "came to rest" or stand as an element's value:
    /// "about 2 ball-widths from the foot-left corner pocket", "against the left rail, 3 diamonds from the head rail",
    /// "2.5 diamonds from the head rail and 1 diamond from the right rail". A diamond is an eighth of the length
    /// (a quarter of the width), as the sights on the rails are spaced.
    static func place(_ p: Vec2, table: TableSpec) -> String {
        let r = table.ballRadius
        let width = 2 * r
        // 1. Near a pocket: the most useful landmark there is.
        if table.pocketsEnabled {
            var nearest: (k: Int, d: Double)?
            for (k, hole) in table.pockets.enumerated() where k < TableSpec.edgePocketCount {
                let d = (hole - p).length
                if nearest == nil || d < nearest!.d { nearest = (k, d) }
            }
            if let n = nearest, n.d <= nearPocketWidths * width {
                let pocket = pocketPhrase(n.k)
                // Measured from the hole's edge (the capture radius), so a ball hanging in the jaws reads "in the jaws".
                let capture = n.k < table.pocketCaptureRadius.count ? table.pocketCaptureRadius[n.k] : r
                let gap = max(0, n.d - capture) / width
                if gap < 0.5 { return String(localized: "in the jaws of \(pocket)") }
                return String(localized: "about \(amount(gap)) ball-widths from \(pocket)")
            }
        }
        // 2. Diamonds from the nearer end rail and the nearer long rail.
        let alongDiamond = table.length / 8, acrossDiamond = table.width / 4
        let fromHead = p.x <= table.length / 2
        let endRail = fromHead ? 0 : 1
        let along = (fromHead ? p.x : table.length - p.x) / alongDiamond
        let fromRight = p.y <= table.width / 2
        let sideRail = fromRight ? 2 : 3
        let across = (fromRight ? p.y : table.width - p.y) / acrossDiamond
        // Distance from the ball's edge to each cushion, for "against".
        let edgeToSide = (fromRight ? p.y : table.width - p.y) - r
        let edgeToEnd = (fromHead ? p.x : table.length - p.x) - r
        if edgeToSide <= againstRailWidths * width {
            return String(localized: "against \(railPhrase(sideRail)), \(amount(along)) diamonds from \(railPhrase(endRail))")
        }
        if edgeToEnd <= againstRailWidths * width {
            return String(localized: "against \(railPhrase(endRail)), \(amount(across)) diamonds from \(railPhrase(sideRail))")
        }
        // The middle of the table has no nearer rail to speak of.
        if abs(along - 4) < 0.25, abs(across - 2) < 0.25 { return String(localized: "in the middle of the table") }
        return String(localized: "\(amount(along)) diamonds from \(railPhrase(endRail)) and \(amount(across)) diamonds from \(railPhrase(sideRail))")
    }

    /// An object ball's element value: where it is, then what blocks the straight line from the cue ball to it
    /// ("The 8 ball is in the way from the cue ball."). The cue ball's own value is just its place.
    static func ballValue(_ ball: Int, cueBall: Int = 0, layout: [Vec2], table: TableSpec) -> String {
        guard layout.indices.contains(ball) else { return "" }
        let spot = place(layout[ball], table: table)
        guard ball != cueBall, layout.indices.contains(cueBall), NextShot.isOnTable(layout[cueBall]) else { return spot }
        let others = layout.indices.filter { $0 != ball && $0 != cueBall && NextShot.isOnTable(layout[$0]) }
        // A line from the cue ball's centre to this ball's centre, blocked by any ball within a ball's width of it.
        let blocking = TableLines.blockers(from: layout[cueBall], to: layout[ball], past: others, in: layout,
                                           radius: table.ballRadius)
        guard let first = blocking.first else { return spot }
        let blocker = ballName(first, cueBall: cueBall)
        return spot + ". " + capitalized(String(localized: "\(blocker) is in the way from the cue ball."))
    }

    /// One line for the whole table: how many balls are on it.
    static func tableValue(layout: [Vec2], cueBall: Int = 0) -> String {
        let count = layout.indices.filter { $0 != cueBall && NextShot.isOnTable(layout[$0]) }.count
        return String(localized: "\(count) balls on the table besides the cue ball")
    }

    // MARK: Aim

    /// The aim spoken as a target, not a number of degrees: what the cue ball hits first, how full, and where that
    /// ball goes. `layout` index 0 is the cue ball (AimGeometry's convention).
    static func aim(layout: [Vec2], from origin: Vec2, direction: Vec2, table: TableSpec) -> String {
        let r = table.ballRadius
        guard let hit = AimGeometry.firstContact(layout: layout, from: origin, direction: direction, radius: r) else {
            let rail = TableLines.heading(from: origin, direction: direction, table: table, window: 0)
            if case .rail(let k) = rail { return String(localized: "The cue ball hits no ball and runs to \(railPhrase(k)).") }
            return String(localized: "The cue ball hits no ball.")
        }
        let target = ballName(hit.ball)
        // How full the hit is, by ball fraction (the share of the object ball the cue ball covers at contact, as
        // the player sees it down the line): 1 - sine of the cut angle. AimContact.cut is that sine. The names are
        // the usual quarter steps; each covers the band halfway to its neighbours.
        let sine = hit.cut
        let first: String
        if sine < 0.125 {
            first = String(localized: "Hits \(target) full.")
        } else {
            let fullness: String
            switch sine {
            case ..<0.375: fullness = String(localized: "three-quarter-ball hit")
            case ..<0.625: fullness = String(localized: "half-ball hit")
            case ..<0.875: fullness = String(localized: "quarter-ball hit")
            default: fullness = String(localized: "thin hit")
            }
            // Counter-clockwise on the solver's plan is the shooter's left (EightBallPocket's convention), so a
            // positive cross product of the aim and the object ball's path is a cut to the left.
            let cross = direction.x * hit.objectDirection.y - direction.y * hit.objectDirection.x
            first = cross > 0 ? String(localized: "Hits \(target) with a \(fullness), cutting it to the left.")
                              : String(localized: "Hits \(target) with a \(fullness), cutting it to the right.")
        }
        return first + " " + whereItGoes(ball: hit.ball, from: hit.target, direction: hit.objectDirection, layout: layout,
                                         ghost: hit.ghost, table: table)
    }

    /// Where an object ball struck along `direction` from `from` is heading: into a pocket, blocked, just missing,
    /// missing by some ball-widths, or to a rail.
    private static func whereItGoes(ball: Int, from: Vec2, direction: Vec2, layout: [Vec2], ghost: Vec2,
                                    table: TableSpec) -> String {
        let r = table.ballRadius
        switch TableLines.heading(from: from, direction: direction, table: table) {
        case .rail(let k):
            return String(localized: "It heads for \(railPhrase(k)).")
        case .pocket(let k, let miss, let capture):
            let pocket = pocketPhrase(k)
            // Anything else on the line to the pocket (the cue ball is at the ghost spot by then).
            var rest = layout
            if rest.indices.contains(0) { rest[0] = ghost }
            let others = rest.indices.filter { $0 != ball && $0 != 0 && NextShot.isOnTable(rest[$0]) }
            if let blocker = TableLines.blockers(from: from, to: table.pockets[k], past: others, in: rest, radius: r).first {
                return String(localized: "It heads for \(pocket), but \(ballName(blocker)) is in the way.")
            }
            if miss <= capture { return String(localized: "It goes into \(pocket).") }
            let widths = (miss - capture) / (2 * r)
            if widths < 0.5 { return String(localized: "It just misses \(pocket).") }
            return String(localized: "It misses \(pocket) by about \(amount(widths)) ball-widths.")
        }
    }

    // MARK: The shot, when it finishes

    /// One to three short sentences about a finished shot: a miscue, what the cue ball hit first, what dropped and
    /// where, and where the cue ball stopped (or that it went in or off the table).
    static func summary(timeline: Timeline, start: [Vec2], cueBall: Int = 0) -> String {
        let facts = ShotFacts(timeline: timeline, start: start, cueBall: cueBall)
        let table = timeline.table
        var out: [String] = []
        if timeline.events.contains(where: { $0.kind == .cueStrike && $0.miscue == true }) {
            out.append(String(localized: "Miscue: the tip slid off the cue ball."))
        }
        if let first = facts.firstContact {
            out.append(String(localized: "The cue ball hit \(ballName(first.ball, cueBall: cueBall)) first."))
        } else {
            out.append(String(localized: "The cue ball hit no ball."))
        }
        let drops = facts.objectBallsPocketed
        if drops.count > 3 {
            // A break that drops many: the numbers as a list, not a sentence each.
            let numbers = drops.map { String($0.ball) }.formatted(.list(type: .and))
            out.append(String(localized: "\(drops.count) balls dropped: \(numbers)."))
        } else {
            for d in drops {
                out.append(capitalized(String(localized: "\(ballName(d.ball, cueBall: cueBall)) dropped in \(pocketPhrase(d.pocket)).")))
            }
        }
        if !facts.pinsDown.isEmpty {
            out.append(String(localized: "\(facts.pinsDown.count) pins down."))
        }
        if let k = facts.pocket(of: cueBall) {
            out.append(String(localized: "The cue ball went in \(pocketPhrase(k))."))
        } else if facts.cueBallOffTable {
            out.append(String(localized: "The cue ball left the table."))
        } else if facts.resting.indices.contains(cueBall), ShotFacts.isOnTable(facts.resting[cueBall]) {
            out.append(String(localized: "The cue ball came to rest \(place(facts.resting[cueBall], table: table))."))
        }
        return out.joined(separator: " ")
    }

    // MARK: Match rulings

    /// A ruling spoken: the fouls, a group taken, points, ball in hand, a choice to make, and either the result or
    /// who shoots next. `names` are the players' names by seat.
    static func ruling(_ r: Ruling, names: [String]) -> String {
        func name(_ p: PlayerID) -> String { names.indices.contains(p.index) ? names[p.index] : String(p.index + 1) }
        var out: [String] = []
        if !r.fouls.isEmpty {
            let list = r.fouls.map(foulWords).formatted(.list(type: .and))
            out.append(String(localized: "Foul: \(list)."))
        }
        if let group = r.assignedGroup {
            out.append(group == .solids ? String(localized: "\(name(r.shooter)) takes the solids.")
                                        : String(localized: "\(name(r.shooter)) takes the stripes."))
        }
        if r.points.indices.contains(r.shooter.index), r.points[r.shooter.index] > 0 {
            out.append(String(localized: "\(name(r.shooter)) scores \(r.points[r.shooter.index])."))
        }
        if let result = r.result {
            if let winner = result.winner {
                out.append(String(localized: "\(name(winner)) wins the game."))
            } else {
                out.append(String(localized: "The game is over."))
            }
            return out.joined(separator: " ")
        }
        if let choice = r.choice {
            switch choice.choice {
            case .acceptTableOrRerack:
                out.append(String(localized: "\(name(choice.chooser)) may play the table as it lies or have it re-racked."))
            case .spotEightOrRerack:
                out.append(String(localized: "\(name(choice.chooser)) may spot the 8 or re-rack."))
            }
        }
        switch r.ballInHand {
        case .anywhere: out.append(String(localized: "Ball in hand anywhere on the table."))
        case .behindHeadLine: out.append(String(localized: "Ball in hand behind the head line."))
        case .none: break
        }
        out.append(String(localized: "\(name(r.nextShooter)) to shoot."))
        return out.joined(separator: " ")
    }

    /// Words for a foul code. The eight that eight-ball shares reuse the judge's titles (same raw values).
    private static func foulWords(_ f: MatchFoul) -> String {
        if let shared = EightBallFoul(rawValue: f.rawValue) { return shared.title }
        switch f {
        case .wrongCup: return String(localized: "Into the wrong cup")
        case .ownBallKnockedPins: return String(localized: "Own ball knocked the pins")
        default: return f.rawValue
        }
    }
}
