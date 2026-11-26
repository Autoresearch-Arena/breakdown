// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: the spoken ruling's scores say "You" for the
//          person's seat).
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
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens: the spoken ruling covers the other tables too -
//          points scored by either player and points lost, the white and black pegs, time running out, balls coming
//          back, pins stood up again - and ends with everyone's score in games that keep one.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, access stream:
//          - item 49: the three small tables speak their own balls (the white, the yellow, the red, a white, the marked
//            red, from TableBallSet, the same set the pictures and the badge use), their own features (each scoring
//            hole by its value, the cups, the pegs, the pins and the bumpers, `features`), places relative to those
//            features and in ball-widths from named cushions instead of pool diamonds, and an aim that stops at, and
//            names, the first bumper, pin or hole on the path, as the drawn guide does;
//          - item 50: spokenAim(for:) is the whole spoken aim, along the launch direction the guide draws (side spin's
//            push included) with the contact the guide shows (AimGeometry.guideContact), so the words, the badge and
//            the line agree;
//          - item 46: the lesson words for a player who cannot see the bands: the tip as an amount ("a little below
//            centre, 3 millimetres"), whether tip, power, aim and cue angle are inside the lesson's marked band and
//            how far off they are, the voice versions of the step lines (with the band's range and where the finish
//            circle is), and the card's verdict and idea as spoken lines;
//          - item 47: the stance is folded into the aim's words (stanceLine) instead of being announced on each
//            change.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 4: the spoken bar-billiards ruling says a fallen white peg loses "this break's points", not this
//          turn's; the tip's spoken value already names its millimetres (tipAmount), as the fine controls now show them.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone: markLabel and markValue, the shot of the day's
//          mark placed in the words a ball is placed in, for its element in TableAccessLayer.)
// SRP/DRY check: Pass - checked CaptionEngine (Captions.swift: the per-event physics sentences, reused as they are
//          for "Step through the shot"; its ball-name strings are reused here), EightBallTypes (pocket, group and
//          foul titles, reused) and EightBallJudge (its line tests now live in TableLines, used here). The ruling
//          words are private to this file on purpose: the match screens own the visible ruling card and may give the
//          same codes their own titles; two extensions on one package type would clash. The small tables' ball
//          looks come from TableBallSet and their constants from the rules (BarBilliardsRules, BumperPoolRules,
//          FivePinRules), never retyped; the lesson card's own visible words (LessonViews) are reused where the same
//          sentence is spoken (the step names, "Made it!", "The idea"), so a translation is shared, not repeated.
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

    /// A ball inside a sentence on any table: the pool names on the pool table; on the small tables the ball's own
    /// colour from the table's ball set ("the white", "the yellow", "the red", "a white" where several look alike,
    /// "the marked red").
    static func ballName(_ ball: Int, cueBall: Int, table: TableKind) -> String {
        guard table != .standard else { return ballName(ball, cueBall: cueBall) }
        switch TableBallSet.for(table: table).look(of: ball) {
        case .pool:
            // A slot the table does not use (never on the table); named as on the pool table.
            return ballName(ball, cueBall: cueBall)
        case .plain(let colour):
            return colourName(colour, table: table)
        case .spotted(let colour, _):
            return colour == .red ? String(localized: "the marked red") : String(localized: "the marked white")
        }
    }

    /// A plain ball by colour. Bar billiards has seven whites and bumper pool five of each side's colour, so one of
    /// them is "a white" or "a red"; five-pin has one ball of each colour, and bar billiards one red.
    private static func colourName(_ colour: BallColour, table: TableKind) -> String {
        let several = (table == .barBilliards && colour == .white) || (table == .bumperPool && colour != .yellow)
        switch colour {
        case .white: return several ? String(localized: "a white") : String(localized: "the white")
        case .red: return several ? String(localized: "a red") : String(localized: "the red")
        case .yellow: return String(localized: "the yellow")
        }
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

    /// A ball's element label on any table: the pool labels on the pool table; on the small tables the ball set's
    /// own word ("White", "Yellow", "Marked red"), with the ball the player strikes saying so.
    static func ballLabel(_ ball: Int, cueBall: Int, table: TableKind) -> String {
        guard table != .standard else { return ballLabel(ball, cueBall: cueBall, pool: true) }
        let word = TableBallSet.for(table: table).label(of: ball)
        return ball == cueBall ? String(localized: "\(word), the ball you strike") : word
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

    /// Any hole a ball can drop into, by the pocket index the solver records (edge pockets 0 to 5, bed hole j as
    /// 6 + j): an edge pocket by its name, a bed hole by what it is on that table ("the 200 hole", "the far cup").
    static func holePhrase(_ pocket: Int, table: TableSpec, kind: TableKind) -> String {
        let j = pocket - TableSpec.edgePocketCount
        guard j >= 0 else { return pocketPhrase(pocket) }
        return features(of: table, kind: kind).first { $0.kind == .hole(j) }?.phrase ?? pocketPhrase(pocket)
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

    /// A rail on any table. The small tables have no head and foot in the pool sense, so their end cushions are the
    /// near one (where play starts, plan x = 0) and the far one.
    static func railPhrase(_ rail: Int, kind: TableKind) -> String {
        guard kind != .standard else { return railPhrase(rail) }
        switch rail {
        case 0: return String(localized: "the near cushion")
        case 1: return String(localized: "the far cushion")
        case 2: return String(localized: "the right cushion")
        default: return String(localized: "the left cushion")
        }
    }

    /// A count of ball-widths or diamonds, rounded to the nearest half (finer than a player can judge by eye or
    /// hand), in the player's number style: "2", "1.5", "0.5".
    static func amount(_ x: Double) -> String {
        ((x * 2).rounded() / 2).formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(0...1)))
    }

    /// A sentence that begins with a ball's name ("the 3 ball ...") starts with a capital, as a sentence should.
    /// Upper-cases only the first character, in the player's language; scripts without case are unchanged.
    static func capitalized(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased(with: Locale.current) + s.dropFirst()
    }

    /// Two spoken lines as one value: the second, when there is one, after a full stop.
    static func joined(_ first: String, _ second: String?) -> String {
        guard let second, !second.isEmpty else { return first }
        guard !first.isEmpty else { return second }
        return first + ". " + second
    }

    // MARK: The small tables' fixed things

    /// One fixed thing on a small table that a player finds, aims at or is stopped by.
    struct Feature: Equatable {
        enum Kind: Equatable {
            /// Bed hole j (pocket 6 + j): a bar-billiards scoring hole or a bumper-pool cup.
            case hole(Int)
            /// Standing pin k (TableSpec.pins): a bar-billiards peg or a five-pin skittle.
            case pin(Int)
            /// Fixed post k (TableSpec.posts): a bumper.
            case post(Int)
        }
        let kind: Kind
        let centre: Vec2
        /// The element's label ("200 hole", "Black peg", "Far cup").
        let label: String
        /// Inside a sentence ("the 200 hole", "the black peg", "the far cup").
        let phrase: String
    }

    /// Every hole, pin and post of a small table, named the way players of that table name them. Values and roles
    /// come from the rules' constants: bar billiards' hole values and its black peg (BarBilliardsRules), five-pin's
    /// red pin (FivePinRules); bumper pool's two cups are bed holes 0 (near) and 1 (far) (BumperPoolRules). Left and
    /// right are as seen from the near end, the solver's convention (y = W is the left cushion). Empty on the pool
    /// table, which has none of these.
    static func features(of table: TableSpec, kind: TableKind) -> [Feature] {
        guard kind != .standard else { return [] }
        var out: [Feature] = []
        let midY = table.width / 2
        for (j, hole) in table.bedHoles.enumerated() {
            switch kind {
            case .barBilliards where BarBilliardsRules.holeValues.indices.contains(j):
                let value = BarBilliardsRules.holeValues[j]
                out.append(Feature(kind: .hole(j), centre: hole.center, label: String(localized: "\(value) hole"),
                                   phrase: String(localized: "the \(value) hole")))
            case .bumperPool:
                let near = hole.center.x < table.length / 2
                out.append(Feature(kind: .hole(j), centre: hole.center,
                                   label: near ? String(localized: "Near cup") : String(localized: "Far cup"),
                                   phrase: near ? String(localized: "the near cup") : String(localized: "the far cup")))
            default:
                out.append(Feature(kind: .hole(j), centre: hole.center, label: String(localized: "Hole"),
                                   phrase: String(localized: "a hole in the bed")))
            }
        }
        for (k, pin) in table.pins.enumerated() {
            switch kind {
            case .barBilliards:
                if k == BarBilliardsRules.blackPeg {
                    out.append(Feature(kind: .pin(k), centre: pin.center, label: String(localized: "Black peg"),
                                       phrase: String(localized: "the black peg")))
                } else {
                    let left = pin.center.y > midY
                    out.append(Feature(kind: .pin(k), centre: pin.center,
                                       label: left ? String(localized: "White peg, left") : String(localized: "White peg, right"),
                                       phrase: left ? String(localized: "the left white peg") : String(localized: "the right white peg")))
                }
            case .fivePin:
                if k == FivePinRules.redPin {
                    out.append(Feature(kind: .pin(k), centre: pin.center, label: String(localized: "Red pin"),
                                       phrase: String(localized: "the red pin")))
                    continue
                }
                // The white pins stand round the red one: named by which side of it they stand.
                let red = table.pins.indices.contains(FivePinRules.redPin) ? table.pins[FivePinRules.redPin].center
                                                                           : Vec2(table.length / 2, midY)
                let d = pin.center - red
                let label: String, phrase: String
                if abs(d.x) >= abs(d.y) {
                    label = d.x < 0 ? String(localized: "White pin, near") : String(localized: "White pin, far")
                    phrase = d.x < 0 ? String(localized: "the near white pin") : String(localized: "the far white pin")
                } else {
                    label = d.y > 0 ? String(localized: "White pin, left") : String(localized: "White pin, right")
                    phrase = d.y > 0 ? String(localized: "the left white pin") : String(localized: "the right white pin")
                }
                out.append(Feature(kind: .pin(k), centre: pin.center, label: label, phrase: phrase))
            default:
                // No other table stands pins today; one that does is named plainly until it gets its own words.
                out.append(Feature(kind: .pin(k), centre: pin.center, label: String(localized: "Pin"),
                                   phrase: String(localized: "a pin")))
            }
        }
        for (k, post) in table.posts.enumerated() {
            out.append(Feature(kind: .post(k), centre: post.center, label: String(localized: "Bumper"),
                               phrase: String(localized: "a bumper")))
        }
        return out
    }

    /// The first fixed thing a ball leaving `from` along unit `direction` meets, and how far its centre travels
    /// first: a post or a standing pin when the centre comes within the contact distance (ball radius plus the
    /// thing's radius), a hole when the centre crosses its capture radius, the solver's own rules, as
    /// AimGeometry.obstacleDistance finds them for the drawn guide. `pinsDown` are skipped (already knocked over).
    static func firstFeature(from: Vec2, direction: Vec2, table: TableSpec, kind: TableKind,
                             pinsDown: Set<Int> = []) -> (feature: Feature, distance: Double)? {
        let r = table.ballRadius
        var best: (feature: Feature, distance: Double)?
        for f in features(of: table, kind: kind) {
            let reach: Double
            switch f.kind {
            case .hole(let j): reach = table.bedHoles[j].captureRadius
            case .pin(let k):
                if pinsDown.contains(k) { continue }
                reach = r + table.pins[k].radius
            case .post(let k): reach = r + table.posts[k].radius
            }
            let d = f.centre - from
            let along = d.dot(direction)
            guard along > 0 else { continue }
            let perpSquared = d.lengthSquared - along * along
            guard perpSquared < reach * reach else { continue }
            let t = along - (reach * reach - perpSquared).squareRoot()
            guard t >= 0 else { continue }
            if best == nil || t < best!.distance { best = (f, t) }
        }
        return best
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

    /// Where a point is on a small table, as a whole sentence (the pool table's place is a phrase; use the pool
    /// `place` there). A small table has no diamonds, so a point is placed by the nearest hole, cup, peg, pin or
    /// bumper when one is within `nearPocketWidths` ball-widths ("The 200 hole is about 2 ball-widths away."), and
    /// otherwise in ball-widths from the nearer end and side cushions (a ball-width is the unit a player can measure by
    /// eye on any table). The fixed thing is the sentence's subject on purpose: its name then never has to bend after
    /// a preposition, which in many of the game's languages would change with each thing's gender and case.
    /// `excluding` leaves one fixed thing out, so a hole's own element is placed by its neighbours and the cushions,
    /// never as "right beside" itself.
    static func placeSentence(_ p: Vec2, table: TableSpec, kind: TableKind, excluding: Feature.Kind? = nil) -> String {
        let r = table.ballRadius
        let width = 2 * r
        // 1. Beside a fixed thing: measured from its edge, so a ball touching a peg reads "right beside" it.
        var nearest: (feature: Feature, gap: Double)?
        for f in features(of: table, kind: kind) where f.kind != excluding {
            let edge: Double
            switch f.kind {
            case .hole(let j): edge = table.bedHoles[j].radius
            case .pin(let k): edge = table.pins[k].radius
            case .post(let k): edge = table.posts[k].radius
            }
            let gap = max(0, (f.centre - p).length - edge - r) / width
            if nearest == nil || gap < nearest!.gap { nearest = (f, gap) }
        }
        if let n = nearest, n.gap <= nearPocketWidths {
            if n.gap < 0.5 { return capitalized(String(localized: "\(n.feature.phrase) is right beside it.")) }
            return capitalized(String(localized: "\(n.feature.phrase) is about \(amount(n.gap)) ball-widths away."))
        }
        // 2. Ball-widths from the nearer end cushion and the nearer side cushion, edge to cushion.
        let fromNear = p.x <= table.length / 2
        let endRail = fromNear ? 0 : 1
        let fromRight = p.y <= table.width / 2
        let sideRail = fromRight ? 2 : 3
        let toEnd = max(0, (fromNear ? p.x : table.length - p.x) - r) / width
        let toSide = max(0, (fromRight ? p.y : table.width - p.y) - r) / width
        if toSide <= againstRailWidths {
            return String(localized: "It is against \(railPhrase(sideRail, kind: kind)), \(amount(toEnd)) ball-widths from \(railPhrase(endRail, kind: kind)).")
        }
        if toEnd <= againstRailWidths {
            return String(localized: "It is against \(railPhrase(endRail, kind: kind)), \(amount(toSide)) ball-widths from \(railPhrase(sideRail, kind: kind)).")
        }
        return String(localized: "It is \(amount(toEnd)) ball-widths from \(railPhrase(endRail, kind: kind)) and \(amount(toSide)) from \(railPhrase(sideRail, kind: kind)).")
    }

    // 0.7.10 everyone (plans/25-Nov-2026-everyone-can-play-plan.md Part D1): the shot of the day's mark.
    /// The mark's element name.
    static var markLabel: String { String(localized: "The mark") }

    /// The mark's element value: where it is, in the words a ball is placed in (the pool table's diamonds and pockets,
    /// or a small table's cushions and fixed things), then what it is for.
    static func markValue(_ p: Vec2, table: TableSpec, kind: TableKind) -> String {
        if kind == .standard {
            return capitalized(place(p, table: table)) + ". " + String(localized: "Where the white ball should stop.")
        }
        return placeSentence(p, table: table, kind: kind) + " " + String(localized: "Where the white ball should stop.")
    }

    /// An object ball's element value: where it is, then what blocks the straight line from the cue ball to it
    /// ("The 8 ball is in the way from the cue ball."). The cue ball's own value is just its place.
    static func ballValue(_ ball: Int, cueBall: Int = 0, layout: [Vec2], table: TableSpec,
                          kind: TableKind = .standard) -> String {
        guard layout.indices.contains(ball) else { return "" }
        let pool = kind == .standard
        let spot = pool ? place(layout[ball], table: table) : placeSentence(layout[ball], table: table, kind: kind)
        guard ball != cueBall, layout.indices.contains(cueBall), NextShot.isOnTable(layout[cueBall]) else { return spot }
        let others = layout.indices.filter { $0 != ball && $0 != cueBall && NextShot.isOnTable(layout[$0]) }
        // A line from the cue ball's centre to this ball's centre, blocked by any ball within a ball's width of it.
        let blocking = TableLines.blockers(from: layout[cueBall], to: layout[ball], past: others, in: layout,
                                           radius: table.ballRadius)
        guard let first = blocking.first else { return spot }
        if pool {
            let blocker = ballName(first, cueBall: cueBall)
            return spot + ". " + capitalized(String(localized: "\(blocker) is in the way from the cue ball."))
        }
        // The small tables' place is already a sentence.
        let blocker = ballName(first, cueBall: cueBall, table: kind)
        let striker = ballName(cueBall, cueBall: cueBall, table: kind)
        return spot + " " + String(localized: "In the way from \(striker): \(blocker).")
    }

    /// One line for the whole table: how many balls are on it.
    static func tableValue(layout: [Vec2], cueBall: Int = 0) -> String {
        let count = layout.indices.filter { $0 != cueBall && NextShot.isOnTable(layout[$0]) }.count
        return String(localized: "\(count) balls on the table besides the cue ball")
    }

    // MARK: Aim

    /// The aim spoken as a target, not a number of degrees: what the cue ball hits first, how full, and where that
    /// ball goes. `layout` index 0 is the cue ball (AimGeometry's convention). The pool table, along `direction`.
    static func aim(layout: [Vec2], from origin: Vec2, direction: Vec2, table: TableSpec) -> String {
        aim(layout: layout, from: origin, direction: direction, table: table, kind: .standard, striker: 0, contact: nil)
    }

    /// The aim on any table along `direction` (the launch direction the guide draws). `contact` is the ball contact
    /// the guide shows, when the caller has it (AimGeometry.guideContact); otherwise the ray cast finds it. On a
    /// small table a hole, pin or bumper met before any ball stops the sentence there and is named, as the guide
    /// stops there.
    static func aim(layout: [Vec2], from origin: Vec2, direction: Vec2, table: TableSpec, kind: TableKind,
                    striker: Int, contact: AimContact?, pinsDown: Set<Int> = []) -> String {
        let r = table.ballRadius
        let hit = contact ?? AimGeometry.firstContact(layout: layout, from: origin, direction: direction, radius: r)
        let toHit = hit.map { ($0.ghost - origin).length } ?? .greatestFiniteMagnitude
        let toWall = AimGeometry.cushionDistance(from: origin, direction: direction, table: table)
        let mover = kind == .standard ? String(localized: "the cue ball") : ballName(striker, cueBall: striker, table: kind)
        if let met = firstFeature(from: origin, direction: direction, table: table, kind: kind, pinsDown: pinsDown),
           met.distance < toHit, met.distance < toWall {
            // The thing is named after a colon, never after a preposition (see placeSentence).
            if case .hole = met.feature.kind {
                return String(localized: "First in its path: \(met.feature.phrase), and it drops in.")
            }
            return String(localized: "First in its path: \(met.feature.phrase).")
        }
        guard let hit, toHit <= toWall + 1e-9 else {
            let rail = TableLines.heading(from: origin, direction: direction, table: table, window: 0)
            if kind == .standard {
                if case .rail(let k) = rail { return String(localized: "The cue ball hits no ball and runs to \(railPhrase(k)).") }
                return String(localized: "The cue ball hits no ball.")
            }
            if case .rail(let k) = rail {
                return capitalized(String(localized: "\(mover) hits no ball and runs to \(railPhrase(k, kind: kind))."))
            }
            return capitalized(String(localized: "\(mover) hits no ball."))
        }
        let target = ballName(hit.ball, cueBall: striker, table: kind)
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
                                         ghost: hit.ghost, striker: striker, table: table, kind: kind, pinsDown: pinsDown)
    }

    /// Where an object ball struck along `direction` from `from` is heading: into a pocket, blocked, just missing,
    /// missing by some ball-widths, or to a rail; on a small table, the first hole, pin or bumper on its path.
    private static func whereItGoes(ball: Int, from: Vec2, direction: Vec2, layout: [Vec2], ghost: Vec2, striker: Int,
                                    table: TableSpec, kind: TableKind, pinsDown: Set<Int>) -> String {
        let r = table.ballRadius
        if kind != .standard {
            let toWall = AimGeometry.cushionDistance(from: from, direction: direction, table: table)
            if let met = firstFeature(from: from, direction: direction, table: table, kind: kind, pinsDown: pinsDown),
               met.distance < toWall {
                return String(localized: "Next in its path: \(met.feature.phrase).")
            }
            if case .rail(let k) = TableLines.heading(from: from, direction: direction, table: table) {
                return String(localized: "Next in its path: \(railPhrase(k, kind: kind)).")
            }
            return ""
        }
        switch TableLines.heading(from: from, direction: direction, table: table) {
        case .rail(let k):
            return String(localized: "It heads for \(railPhrase(k)).")
        case .pocket(let k, let miss, let capture):
            let pocket = pocketPhrase(k)
            // Anything else on the line to the pocket (the cue ball is at the ghost spot by then).
            var rest = layout
            if rest.indices.contains(striker) { rest[striker] = ghost }
            let others = rest.indices.filter { $0 != ball && $0 != striker && NextShot.isOnTable(rest[$0]) }
            if let blocker = TableLines.blockers(from: from, to: table.pockets[k], past: others, in: rest, radius: r).first {
                return String(localized: "It heads for \(pocket), but \(ballName(blocker)) is in the way.")
            }
            if miss <= capture { return String(localized: "It goes into \(pocket).") }
            let widths = (miss - capture) / (2 * r)
            if widths < 0.5 { return String(localized: "It just misses \(pocket).") }
            return String(localized: "It misses \(pocket) by about \(amount(widths)) ball-widths.")
        }
    }

    /// The whole spoken aim for the next shot, as the Aim element says it: the break keeps its offset from the lead
    /// ball (the rack is the target); a shot says what the ball will hit and where that ball goes, along the launch
    /// direction the guide draws (side spin's push included) and with the contact the guide shows, then the angle
    /// for anyone who wants it, a lesson's aim band when one is marked, and the stance when it is not a square one.
    /// The target sentence is spoken even with the Aim guide option off: that option hides drawing for sighted
    /// players who want to judge the angle, and for a player who cannot see the table these words are the only view.
    @MainActor
    static func spokenAim(for model: ShowpieceModel) -> String {
        if model.racked {
            return String(localized: "\(String(format: "%+.0f", locale: AppLocale.numbers, model.aimOffset * 1000)) millimetres from the lead ball")
        }
        guard NextShot.isOnTable(model.aimOrigin), model.layout.count > 1 else {
            return String(localized: "The cue ball is off the table.")
        }
        let table = model.timeline.table
        let pinsDown = Set(table.pins.indices.filter { model.timeline.pinIsDown($0, at: model.time) })
        let target = aim(layout: model.layout, from: model.aimOrigin, direction: AimGeometry.launchDirection(for: model),
                         table: table, kind: model.solvedTable, striker: model.strikeBall,
                         contact: AimGeometry.guideContact(for: model), pinsDown: pinsDown)
        let degrees = String(localized: "\(String(format: "%.1f", locale: AppLocale.numbers, model.aimDegrees)) degrees")
        var out = target + " " + degrees
        if let band = aimBandLine(degrees: model.aimDegrees, band: model.lessonZones?.aim) { out = joined(out, band) }
        if let stance = stanceLine(model) { out = joined(out, stance) }
        return out
    }

    /// The stance and the raised cue for the strike being lined up, as the equipment card shows them; nil for a
    /// square stance with a clear path. Spoken inside the aim and after a finished shot instead of being announced
    /// on every change (the card itself stays silent, so the stance never talks over the aim).
    @MainActor
    static func stanceLine(_ model: ShowpieceModel) -> String? {
        let lines = EquipmentRows.current(model).map(\.line)
        return lines.isEmpty ? nil : lines.joined(separator: ". ")
    }

    // MARK: The shot, when it finishes

    /// One to three short sentences about a finished shot: a miscue, what the cue ball hit first, what dropped and
    /// where, and where the cue ball stopped (or that it went in or off the table).
    static func summary(timeline: Timeline, start: [Vec2], cueBall: Int = 0) -> String {
        summary(timeline: timeline, start: start, cueBall: cueBall, kind: .standard)
    }

    /// The finished shot on any table. On a small table the striking ball is named by its colour, a drop names the
    /// hole or cup, and knocked bar-billiards pegs are counted as pegs.
    static func summary(timeline: Timeline, start: [Vec2], cueBall: Int, kind: TableKind) -> String {
        guard kind != .standard else { return poolSummary(timeline: timeline, start: start, cueBall: cueBall) }
        let facts = ShotFacts(timeline: timeline, start: start, cueBall: cueBall)
        let table = timeline.table
        let striker = ballName(cueBall, cueBall: cueBall, table: kind)
        func name(_ b: Int) -> String { ballName(b, cueBall: cueBall, table: kind) }
        var out: [String] = []
        if timeline.events.contains(where: { $0.kind == .cueStrike && $0.miscue == true }) {
            out.append(String(localized: "Miscue: the tip slid off the cue ball."))
        }
        if let first = facts.firstContact {
            out.append(capitalized(String(localized: "\(striker) hit \(name(first.ball)) first.")))
        } else {
            out.append(capitalized(String(localized: "\(striker) hit no ball.")))
        }
        let drops = facts.objectBallsPocketed
        if drops.count > 3 {
            let names = drops.map { name($0.ball) }.formatted(.list(type: .and).locale(AppLocale.numbers))
            out.append(String(localized: "\(drops.count) balls dropped: \(names)."))
        } else {
            // The hole after a colon, never after a preposition (see placeSentence).
            for d in drops {
                out.append(capitalized(String(localized: "\(name(d.ball)) dropped: \(holePhrase(d.pocket, table: table, kind: kind)).")))
            }
        }
        if !facts.pinsDown.isEmpty {
            out.append(kind == .barBilliards ? String(localized: "\(facts.pinsDown.count) pegs down.")
                                             : String(localized: "\(facts.pinsDown.count) pins down."))
        }
        if let k = facts.pocket(of: cueBall) {
            out.append(capitalized(String(localized: "\(striker) dropped: \(holePhrase(k, table: table, kind: kind)).")))
        } else if facts.cueBallOffTable {
            out.append(capitalized(String(localized: "\(striker) left the table.")))
        } else if facts.resting.indices.contains(cueBall), ShotFacts.isOnTable(facts.resting[cueBall]) {
            out.append(capitalized(String(localized: "\(striker) came to rest.")))
            out.append(placeSentence(facts.resting[cueBall], table: table, kind: kind))
        }
        return out.joined(separator: " ")
    }

    private static func poolSummary(timeline: Timeline, start: [Vec2], cueBall: Int) -> String {
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
            let numbers = drops.map { String($0.ball) }.formatted(.list(type: .and).locale(AppLocale.numbers))
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

    /// A ruling spoken: the fouls, a group taken, points, the other tables' events (pegs, time, balls back, pins up),
    /// ball in hand, a choice to make, and either the result or who shoots next, then everyone's score when `scores`
    /// is given (games that keep a running score). `names` are the players' names by seat.
    static func ruling(_ r: Ruling, names: [String], scores: [Int]? = nil, you: PlayerID? = nil) -> String {
        func name(_ p: PlayerID) -> String { names.indices.contains(p.index) ? names[p.index] : String(p.index + 1) }
        var out: [String] = []
        if !r.fouls.isEmpty {
            let list = r.fouls.map(foulWords).formatted(.list(type: .and).locale(AppLocale.numbers))
            out.append(String(localized: "Foul: \(list)."))
        }
        if let group = r.assignedGroup {
            out.append(group == .solids ? String(localized: "\(name(r.shooter)) takes the solids.")
                                        : String(localized: "\(name(r.shooter)) takes the stripes."))
        }
        // The pegs and the clock come before the points, as on the ruling card.
        for reason in r.reasons {
            switch reason {
            // "This break's points" (0.7.5): in bar billiards the points at stake are the break's, as the ruling card
            // and the bar-down line say; "turn" read as if the whole game's score went.
            case .whitePegDown: out.append(String(localized: "The white peg went down: this break's points are lost."))
            case .blackPegDown: out.append(String(localized: "The black peg went down: the whole score is lost."))
            case .timeUp: out.append(String(localized: "Time is up."))
            default: break
            }
        }
        // Points for whoever got them (a five-pin foul pays the other player), and points lost to a peg.
        for (seat, p) in r.points.enumerated() where p != 0 {
            out.append(p > 0 ? String(localized: "\(name(PlayerID(seat))) scores \(p).")
                             : String(localized: "\(name(PlayerID(seat))) loses \(-p) points."))
        }
        if r.reasons.contains(.ballsReturned) { out.append(String(localized: "Balls come back to be played again.")) }
        if r.reasons.contains(.pinsReset) { out.append(String(localized: "The pins are stood up again.")) }
        if let scores { out.append(TableGameWords.scores(scores, names: names, you: you)) }
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

    // MARK: Lessons, without sight

    /// Tip offsets smaller than this (metres) count as on the centre line: a quarter of a millimetre, well under the
    /// half-millimetre the spoken amounts are rounded to.
    static let centreTolerance = 0.00025

    /// A length in millimetres from metres, rounded to the nearest half millimetre (finer than a player can set by
    /// touch, coarse enough to say quickly).
    static func millimetres(_ metres: Double) -> String { amount(abs(metres) * 1000) }

    /// One point on the cue ball along one axis: "centre", "4 millimetres below centre", "3 millimetres left of
    /// centre". `vertical` picks above and below (tip height) or left and right (side).
    static func tipPoint(_ metres: Double, vertical: Bool) -> String {
        if abs(metres) < centreTolerance { return String(localized: "centre") }
        let mm = millimetres(metres)
        if vertical {
            return metres > 0 ? String(localized: "\(mm) millimetres above centre")
                              : String(localized: "\(mm) millimetres below centre")
        }
        return metres > 0 ? String(localized: "\(mm) millimetres right of centre")
                          : String(localized: "\(mm) millimetres left of centre")
    }

    /// The tip as an amount: how far from the centre in words a player can picture (a little, halfway, well toward
    /// the edge of the tip's reach, the thirds of `limit`), with the millimetres after it: "a little below centre,
    /// 3 millimetres; halfway to the right, 8 millimetres". "Centre of the cue ball" when both are on the centre.
    static func tipAmount(up: Double, side: Double, limit: Double) -> String {
        func extent(_ v: Double) -> Int { limit > 0 ? min(2, Int(abs(v) / limit * 3)) : 0 }
        var parts: [String] = []
        if abs(up) >= centreTolerance {
            let words: [String] = up > 0
                ? [String(localized: "a little above centre"), String(localized: "halfway up"), String(localized: "well above centre")]
                : [String(localized: "a little below centre"), String(localized: "halfway down"), String(localized: "well below centre")]
            parts.append(String(localized: "\(words[extent(up)]), \(millimetres(up)) millimetres"))
        }
        if abs(side) >= centreTolerance {
            let words: [String] = side > 0
                ? [String(localized: "a little right of centre"), String(localized: "halfway to the right"), String(localized: "well to the right")]
                : [String(localized: "a little left of centre"), String(localized: "halfway to the left"), String(localized: "well to the left")]
            parts.append(String(localized: "\(words[extent(side)]), \(millimetres(side)) millimetres"))
        }
        return parts.isEmpty ? String(localized: "Centre of the cue ball") : parts.joined(separator: "; ")
    }

    /// Where the tip stands against a lesson's marked tip bands: inside, or how far and which way to move it. Nil
    /// when no tip band is marked.
    static func tipBandLine(up: Double, side: Double, zones: LessonZones?) -> String? {
        var parts: [String] = []
        if let band = zones?.tipUp {
            if band.contains(up) {
                parts.append(String(localized: "Height inside the marked band."))
            } else if up < band.lowerBound {
                parts.append(String(localized: "Raise the tip \(millimetres(band.lowerBound - up)) millimetres to reach the marked band."))
            } else {
                parts.append(String(localized: "Lower the tip \(millimetres(up - band.upperBound)) millimetres to reach the marked band."))
            }
        }
        if let band = zones?.tipSide {
            if band.contains(side) {
                parts.append(String(localized: "Side inside the marked band."))
            } else if side < band.lowerBound {
                parts.append(String(localized: "Move the tip \(millimetres(band.lowerBound - side)) millimetres right to reach the marked band."))
            } else {
                parts.append(String(localized: "Move the tip \(millimetres(side - band.upperBound)) millimetres left to reach the marked band."))
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// The tip picture's spoken value: the amount, then the band when a lesson marks one.
    @MainActor
    static func tipValue(_ model: ShowpieceModel, zones: LessonZones?) -> String {
        let amount = tipAmount(up: model.activeTipUp, side: model.activeTipSide, limit: model.tipLimit)
        return joined(amount, tipBandLine(up: model.activeTipUp, side: model.activeTipSide, zones: zones))
    }

    /// The power against a lesson's marked band, in the bar's own percent (the gauge speaks its value in percent of
    /// the bar, so the distance is in the same unit): inside, or how much to add or take off. Nil without a band.
    @MainActor
    static func powerBandLine(_ model: ShowpieceModel, zones: LessonZones?) -> String? {
        guard let band = zones?.power else { return nil }
        let range = model.powerRange
        let span = max(1e-9, range.upperBound - range.lowerBound)
        let power = model.activePower
        if band.contains(power) { return String(localized: "Inside the marked band.") }
        // At least one percent, so a value just outside the band never reads "add 0 percent".
        func percent(_ speed: Double) -> String { max(1, (speed / span * 100).rounded()).formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(0))) }
        if power < band.lowerBound {
            return String(localized: "Add \(percent(band.lowerBound - power)) percent to reach the marked band.")
        }
        return String(localized: "Take off \(percent(power - band.upperBound)) percent to reach the marked band.")
    }

    /// The aim against a lesson's marked fan (degrees on the table plan; counter-clockwise, the larger angle, is the
    /// shooter's left): inside, or how many degrees to turn which way. Nil without a fan.
    static func aimBandLine(degrees: Double, band: ClosedRange<Double>?) -> String? {
        guard let band else { return nil }
        // Signed turns to each edge, taken the short way round the circle.
        func turn(to target: Double) -> Double {
            var d = target - degrees
            while d > 180 { d -= 360 }
            while d < -180 { d += 360 }
            return d
        }
        let toLow = turn(to: band.lowerBound), toHigh = turn(to: band.upperBound)
        if toLow <= 0, toHigh >= 0 { return String(localized: "Inside the marked fan.") }
        let needed = abs(toLow) < abs(toHigh) ? toLow : toHigh
        let size = abs(needed).formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(0...1)))
        return needed > 0 ? String(localized: "Turn the aim \(size) degrees left to reach the marked fan.")
                          : String(localized: "Turn the aim \(size) degrees right to reach the marked fan.")
    }

    /// The cue-angle control's spoken value: its own words ("Level", "30° up"), then the lesson's marked angles when
    /// some are marked.
    static func cueAngleValue(words: String, degrees: Int, band: ClosedRange<Int>?) -> String {
        guard let band else { return words }
        if band.contains(degrees) { return joined(words, String(localized: "Inside the marked angles.")) }
        return joined(words, String(localized: "The marked angles are \(band.lowerBound) to \(band.upperBound) degrees up."))
    }

    /// An angle in the cue-angle menu that a lesson marks: its words and "marked", so the mark is heard, not only seen.
    static func markedAngle(words: String) -> String { String(localized: "\(words), marked") }

    /// "Try 1 of 3" and so on: the same words as the lesson card's corner (LessonViews), so they share a translation.
    @MainActor
    static func lessonStepName(_ step: LessonMode.Step) -> String {
        switch step {
        case .try1: return String(localized: "Try 1 of 3")
        case .try2: return String(localized: "Try 2 of 3")
        case .try3: return String(localized: "Try 3 of 3")
        case .pass: return String(localized: "Pass shot")
        case .exercise: return String(localized: "A new distance")
        }
    }

    /// The voice version of a lesson step: what is set and open, said in terms of the controls VoiceOver reaches
    /// (each one says whether it is inside its band), the marked band's range in words for try 2, the goal, and
    /// where the finish circle is. The card's own line talks about marks to look at; this one never relies on them.
    @MainActor
    static func lessonStepVoice(_ lesson: Lesson, step: LessonMode.Step, model: ShowpieceModel) -> String {
        var parts = [lessonStepName(step)]
        switch step {
        case .try1:
            parts.append(String(localized: "Everything is set for you and locked. Double-tap Shoot and listen to what happens."))
        case .try2:
            let zones = model.lessonZones
            switch lesson.control {
            case .tipUp:
                parts.append(String(localized: "Only the tip height is open. On Cue tip position, use the actions Up a little and Down a little until it says the height is inside the marked band. Then shoot."))
                if let band = zones?.tipUp {
                    parts.append(String(localized: "The band runs from \(tipPoint(band.lowerBound, vertical: true)) to \(tipPoint(band.upperBound, vertical: true))."))
                }
            case .tipSide:
                parts.append(String(localized: "Only the side spin is open. On Cue tip position, use the actions Left a little and Right a little until it says the side is inside the marked band. Then shoot."))
                if let band = zones?.tipSide {
                    parts.append(String(localized: "The band runs from \(tipPoint(band.lowerBound, vertical: false)) to \(tipPoint(band.upperBound, vertical: false))."))
                }
            case .aim:
                parts.append(String(localized: "Only the aim is open. Swipe up or down on Aim until it says inside the marked fan. Then shoot."))
            case .power:
                parts.append(String(localized: "Only the power is open. Swipe up or down on Power until it says inside the marked band. Then shoot."))
            case .elevation:
                parts.append(String(localized: "Only the cue angle is open. Open Cue angle and pick an angle that says marked. Then shoot."))
                if let band = zones?.cueAngles {
                    parts.append(String(localized: "The marked angles are \(band.lowerBound) to \(band.upperBound) degrees up."))
                }
            }
        case .try3:
            parts.append(String(localized: "Every control is open now. Each one still says whether it is inside its band."))
        case .pass:
            parts.append(String(localized: "No marks and nothing locked. Make it on your own to pass."))
        case .exercise:
            parts.append(String(localized: "Same line, the cue ball further back, your lesson stroke set up. Before you shoot, say where the cue ball will go. Then change only the tip height to stop it dead."))
        }
        let goal = step == .exercise ? Lessons.stopExercise.trick.goalLine : lesson.goalLine
        parts.append(goal)
        if let zone = model.lessonMode.markers?.zone {
            parts.append(String(localized: "The marked circle for the cue ball is \(place(zone.centre, table: model.timeline.table))."))
        }
        return parts.joined(separator: " ")
    }

    /// The judged card as one spoken line: Made it, Missed or Lesson passed, the judge's one thing to change, the
    /// retry's one difference, and the trick shot a passed lesson leads to. The same words the card shows.
    @MainActor
    static func lessonVerdict(_ lesson: Lesson, step: LessonMode.Step, verdict: TrickVerdict,
                              model: ShowpieceModel) -> String {
        let passed = verdict.made && step == .pass
        var parts = [passed ? String(localized: "Lesson passed")
                            : (verdict.made ? String(localized: "Made it!") : String(localized: "Missed")),
                     verdict.line]
        if let c = model.retryComparison { parts.append(RetryWords.sentence(c)) }
        if passed, let trick = model.lessonMode.suggestedTrick {
            parts.append(String(localized: "The trick shot \(trick.title) is built on this idea."))
        }
        return parts.joined(separator: " ")
    }
}
