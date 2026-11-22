// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The twelve Behind the 8-Ball situations' numbers, the one copy (bug plan after 0.6.6, item 38): each table
//          in diamonds, your group, the surface it is set on, and every authored escape's stroke, call, rails, bridge,
//          rating and the technique test it is checked with. The app's EightBallSituations adds the titles, stories and
//          "On a real table" words and reads these; BreakProbe's "verify" plays every escape and "eightball near"
//          re-authors them (EightBallAuthoring.swift, Reauthor.swift). Item 30: every escape's aim window holds at least
//          one of the aim control's quarter-degree steps, or the content check fails it; the authoring aims for two
//          (half a degree), and each comment says where a window falls short of that.
// SRP/DRY check: Pass - data only; the types are AuthoredTypes', the call and group BreakdownRules'.
import BreakdownRules

public enum AuthoredEscapes {
    public static let all: [AuthoredSituation] = [
        tucked, frozen, jumpDiamond, bendAround, kickForTheGame, zShot, pointBlank, masseForTheWin, jumpOffTheBridge,
        kickBankCrossSide, fullTableSwerve, noWayToMakeIt,
    ]

    public static func situation(id: String) -> AuthoredSituation? { all.first { $0.id == id } }

    /// A kick: the cue ball takes exactly `rails` cushions before its first ball.
    private static func kick(_ id: String, rails: Int, _ s: AuthoredStrike, _ call: EightBallCall, rating: Int,
                             bridge: Bool = false, railCheck: ClosedRange<Int>? = nil) -> AuthoredEscape {
        AuthoredEscape(id: id, kind: .kick, alsoUses: [], rails: rails, strike: s, call: call, usesBridge: bridge,
                       rating: rating, check: .kick, railCheck: railCheck ?? rails...rails, touchBall: nil)
    }

    /// A jump: the cue ball leaves the cloth before its first ball, and a level cue on the same stroke fails.
    private static func jump(_ id: String, _ s: AuthoredStrike, _ call: EightBallCall, rating: Int, bridge: Bool = false)
        -> AuthoredEscape {
        AuthoredEscape(id: id, kind: .jump, alsoUses: bridge ? [.bridge] : [], rails: 0, strike: s, call: call,
                       usesBridge: bridge, rating: rating, check: .jump, railCheck: 0...0, touchBall: nil)
    }

    /// A massé or a swerve: the curve does it, and a level cue on the same stroke fails.
    private static func curve(_ id: String, _ kind: AuthoredEscapeKind, _ s: AuthoredStrike, _ call: EightBallCall,
                              rating: Int) -> AuthoredEscape {
        AuthoredEscape(id: id, kind: kind, alsoUses: [], rails: 0, strike: s, call: call, usesBridge: false,
                       rating: rating, check: .curve, railCheck: 0...0, touchBall: nil)
    }

    // MARK: 1. Tucked Behind the 8
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: no one-rail stroke near the old one, nor at any of 49 places for the 3 within half a diamond, kept an aim window
    //   of one aim step (the widest 0.18), so the kick was searched round the full circle with up to three rails
    //   ("eightball wide", 306,000 strokes, 283 passed): a two-rail kick off the head rail at the first diamond from the
    //   left rail and the left rail at along 2.20; aim 154.13 to 154.43, power 3.20 to 3.50 m/s, tip -4.0 mm.
    // B: unchanged; aim 26.99 to 27.55, power 2.80 to 4.80 m/s, tip -7.5 to +10.5 mm, elevation sine 0.65 to 0.93.
    public static let tucked = AuthoredSituation(
        id: "tucked-behind-the-8", number: 1, cue: Diamond(2.2, 2.6), eight: Diamond(2.0, 3.0),
        balls: [3: Diamond(0.8, 5.4), 6: Diamond(3.6, 7.5), 9: Diamond(3.5, 6.8), 11: Diamond(0.5, 2.0),
                12: Diamond(3.2, 1.4), 14: Diamond(1.6, 7.2), 15: Diamond(3.0, 5.4)],
        group: .solids, surface: .cloth,
        escapes: [
            kick("A", rails: 2, AuthoredStrike(aim: 154.27, power: 3.35, tipUp: -0.0040, tipSide: 0),
                 .ball(3, pocket: .footLeft), rating: 3),
            jump("B", AuthoredStrike(aim: 27.25, power: 3.80, tipUp: -0.002, tipSide: 0, elevation: 0.80),
                 .ball(3, pocket: .footLeft), rating: 4),
        ])

    // MARK: 2. Frozen on the Rail (Dive-bar felt)
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // The 10 moved along its rail from along 7.0 to 7.45, still frozen and screened ("eightball relay": the nearest
    //   place where both kicks hold an aim step; the hook was checked again there, no direct makes). On the re-tuned
    //   dive-bar felt. A: head rail at across 2.77; aim -175.46 to -175.20, power 3.55 to 5.30 m/s, tip +1.0 to +14.0 mm.
    //   B: head rail at across 2.80, right rail at along 6.74; aim -175.29 to -174.71, power 3.45 to 6.90 m/s, tip +3.5
    //   to +14.0 mm.
    public static let frozen = AuthoredSituation(
        id: "frozen-on-the-rail", number: 2, cue: Diamond(2.4, 4.6), eight: Diamond(2.0, 3.6),
        balls: [10: Diamond(3.905, 7.45), 12: Diamond(0.5, 7.4), 1: Diamond(0.8, 2.5), 3: Diamond(2.95, 5.65),
                5: Diamond(3.4, 6.3), 6: Diamond(1.3, 6.3)],
        group: .stripes, surface: .diveBar,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: -175.32, power: 4.40, tipUp: 0.0075, tipSide: 0),
                 .ball(10, pocket: .footRight), rating: 3),
            kick("B", rails: 2, AuthoredStrike(aim: -174.99, power: 5.15, tipUp: 0.0090, tipSide: 0),
                 .ball(10, pocket: .footRight), rating: 4),
        ])

    // MARK: 3. Jump a Diamond Out
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: re-searched near its old stroke; left rail at along 2.32; aim 63.88 to 64.76, power 2.55 to 3.20 m/s, tip -9.0
    //   to -7.0 mm. B: unchanged; aim -32.22 to -30.60, power 4.15 to 6.15 m/s, elevation sine 0.53 to 0.86.
    public static let jumpDiamond = AuthoredSituation(
        id: "jump-a-diamond-out", number: 3, cue: Diamond(2.0, 1.4), eight: Diamond(2.4, 6.4),
        balls: [5: Diamond(3.5, 3.7), 2: Diamond(0.6, 6.9), 9: Diamond(0.9, 5.8), 11: Diamond(2.5, 2.15),
                13: Diamond(3.3, 7.4), 14: Diamond(0.4, 4.8)],
        group: .solids, surface: .cloth,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: 64.26, power: 2.90, tipUp: -0.0080, tipSide: 0),
                 .ball(5, pocket: .rightSide), rating: 3),
            jump("B", AuthoredStrike(aim: -31.30, power: 5.20, tipUp: -0.010, tipSide: 0, elevation: 0.70),
                 .ball(5, pocket: .rightSide), rating: 3),
        ])

    // MARK: 4. Bend Around
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: unchanged; aim -14.65 to -14.21, power 3.05 to 3.25 m/s, side 13.5 mm, elevation sine 0.40 (one aim step; no
    //   wider swerve was found near it). B: unchanged; aim -22.13 to -21.63, elevation sine 0.49 to 0.84. C: no stroke
    //   near the old one kept an aim step, so searched round the full circle ("eightball wide", 306,000 strokes, 162
    //   passed): right rail at along 0.92, head rail at across 2.90, left rail at along 1.89; aim -132.10 to -131.82,
    //   power 4.80 to 5.15 m/s, tip -5.5 to 0 mm.
    public static let bendAround = AuthoredSituation(
        id: "bend-around", number: 4, cue: Diamond(1.6, 3.0), eight: Diamond(2.9, 2.4),
        balls: [15: Diamond(3.0, 6.4), 11: Diamond(3.55, 2.1), 2: Diamond(0.4, 5.2), 4: Diamond(3.5, 5.4),
                6: Diamond(2.1, 3.98), 7: Diamond(0.9, 7.6)],
        group: .stripes, surface: .cloth,
        escapes: [
            curve("A", .swerve, AuthoredStrike(aim: -14.43, power: 3.15, tipUp: -0.0025, tipSide: 0.0135, elevation: 0.40),
                  .ball(15, pocket: .footRight), rating: 3),
            jump("B", AuthoredStrike(aim: -21.95, power: 4.35, tipUp: -0.0055, tipSide: 0, elevation: 0.70),
                 .ball(15, pocket: .footRight), rating: 3),
            kick("C", rails: 3, AuthoredStrike(aim: -131.96, power: 4.95, tipUp: -0.0030, tipSide: 0),
                 .ball(15, pocket: .footRight), rating: 4, railCheck: 2...4),
        ])

    // MARK: 5. Kick for the Game (Dive-bar felt)
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: re-searched near its old stroke on the re-tuned felt; left rail at along 6.00; aim 26.61 to 26.93, power 1.45 to
    //   2.10 m/s, tip -3.0 to +14.0 mm. B: re-searched; left rail at along 2.14, head rail at across 2.45, right rail at
    //   along 0.87; aim 119.16 to 120.10, power 6.95 to 7.50 m/s, tip +9.5 to +13.5 mm.
    public static let kickForTheGame = AuthoredSituation(
        id: "kick-for-the-game", number: 5, cue: Diamond(1.6, 3.0), eight: Diamond(0.2, 6.8),
        balls: [1: Diamond(1.0, 4.6), 4: Diamond(2.8, 6.4), 6: Diamond(3.5, 2.0), 7: Diamond(2.2, 7.6)],
        group: .stripes, surface: .diveBar,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: 26.77, power: 1.75, tipUp: 0.0055, tipSide: 0),
                 .ball(8, pocket: .footLeft), rating: 3),
            kick("B", rails: 3, AuthoredStrike(aim: 119.72, power: 7.15, tipUp: 0.0115, tipSide: 0),
                 .ball(8, pocket: .footLeft), rating: 5),
        ])

    // MARK: 6. The Z Shot (bridge)
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: re-searched near its old stroke; right rail at along 4.92, foot rail at across 1.75; aim -36.91 to -36.59, power
    //   4.00 to 5.05 m/s, tip -5.5 to -0.5 mm, side -3.0 mm. B: re-searched; left rail at along 5.13, right rail at along
    //   7.35, foot rail at across 2.06; aim 52.30 to 52.82, power 4.90 to 5.90 m/s, tip -10.0 mm.
    public static let zShot = AuthoredSituation(
        id: "the-z-shot", number: 6, cue: Diamond(2.6, 3.2), eight: Diamond(1.2, 3.0),
        balls: [13: Diamond(1.5, 7.85), 15: Diamond(3.0, 1.2), 2: Diamond(0.6, 6.4), 4: Diamond(2.27, 4.6),
                6: Diamond(1.9, 5.8), 7: Diamond(2.8, 2.3)],
        group: .stripes, surface: .cloth,
        escapes: [
            kick("A", rails: 2, AuthoredStrike(aim: -36.77, power: 4.55, tipUp: -0.0030, tipSide: -0.0030),
                 .ball(13, pocket: .footLeft), rating: 4, bridge: true),
            kick("B", rails: 3, AuthoredStrike(aim: 52.54, power: 5.40, tipUp: -0.0100, tipSide: 0),
                 .ball(13, pocket: .footLeft), rating: 5, bridge: true),
        ])

    // MARK: 7. Point-Blank
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: re-searched near its old stroke; left rail at along 6.26; aim 73.84 to 74.40, power 2.45 to 4.75 m/s, tip -6.5
    //   to -5.5 mm. B: unchanged; aim -62.23 to -61.09, elevation sine 0.73 to 0.91.
    public static let pointBlank = AuthoredSituation(
        id: "point-blank", number: 7, cue: Diamond(1.0, 6.0), eight: Diamond(1.3, 6.17),
        balls: [14: Diamond(2.6, 6.9), 1: Diamond(3.4, 3.1), 3: Diamond(0.6, 2.2), 6: Diamond(2.2, 4.9),
                7: Diamond(3.7, 5.8)],
        group: .stripes, surface: .cloth,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: 74.12, power: 3.60, tipUp: -0.0060, tipSide: 0),
                 .ball(14, pocket: .footRight), rating: 3),
            jump("B", AuthoredStrike(aim: -61.55, power: 3.50, tipUp: -0.0045, tipSide: 0, elevation: 0.85),
                 .ball(14, pocket: .footRight), rating: 5),
        ])

    // MARK: 8. Massé for the Win (Tournament cloth)
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // Both unchanged on the re-tuned tournament cloth. A: head rail at across 3.22; aim -177.46 to -176.96, power 1.40 to
    //   4.15 m/s. B: aim -14.00 to -8.52, power 4.10 to 4.50 m/s, side 8.0 to 11.0 mm, elevation sine 0.78 to 0.82.
    public static let masseForTheWin = AuthoredSituation(
        id: "masse-for-the-win", number: 8, cue: Diamond(2.9, 6.5), eight: Diamond(3.85, 7.85),
        balls: [9: Diamond(0.8, 2.6), 10: Diamond(1.6, 5.2), 12: Diamond(3.4, 7.2), 13: Diamond(0.5, 7.0)],
        group: .solids, surface: .tournament,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: -177.14, power: 1.75, tipUp: 0.006, tipSide: 0),
                 .ball(8, pocket: .footRight), rating: 3),
            curve("B", .masse, AuthoredStrike(aim: -11.28, power: 4.30, tipUp: 0.0005, tipSide: 0.0095, elevation: 0.80),
                  .ball(8, pocket: .footRight), rating: 5),
        ])

    // MARK: 9. Jump Off the Bridge
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A: re-searched near its old stroke; right rail at along 5.96; aim -63.57 to -63.03, power 2.95 to 4.85 m/s, tip
    //   -6.0 to -4.0 mm. B: unchanged; aim 23.01 to 23.97, elevation sine 0.59 to 0.88.
    public static let jumpOffTheBridge = AuthoredSituation(
        id: "jump-off-the-bridge", number: 9, cue: Diamond(2.0, 5.0), eight: Diamond(3.0, 5.2),
        balls: [4: Diamond(0.9, 7.3), 7: Diamond(3.2, 3.0), 9: Diamond(1.75, 5.6), 11: Diamond(3.6, 1.0),
                12: Diamond(2.3, 7.4), 15: Diamond(0.4, 3.0)],
        group: .solids, surface: .cloth,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: -63.33, power: 3.90, tipUp: -0.0050, tipSide: 0),
                 .ball(4, pocket: .footLeft), rating: 3),
            jump("B", AuthoredStrike(aim: 23.49, power: 3.85, tipUp: -0.0045, tipSide: 0, elevation: 0.75),
                 .ball(4, pocket: .footLeft), rating: 4, bridge: true),
        ])

    // MARK: 10. Kick-Bank Cross-Side
    // On the 0.7.0 physics (21-Nov-2026): the kick-then-bank was a sliver before (0.04 degrees) and stayed one: nothing
    // near it, no place for the 13 within half a diamond, and nothing round the full circle with up to two rails before
    // the 13 ("eightball wide", 378,000 strokes, the widest 0.08) held one aim step. So the situation is re-laid
    // ("eightball relay ... cue", item 30): the cue ball moved from across 2.2, along 6.6 to across 1.75, along 6.30,
    // and, because from there the 13 would be a straight pot, the 3 moved onto that line at across 2.94, along 5.37 to
    // block it (the hook checked again: no direct makes). There the second way out is a cross-side bank struck straight
    // at the 13, rated 4.
    // A: foot rail at across 2.42; aim -22.72 to -22.08 (two aim steps), power 2.80 to 4.60 m/s, tip -6.0 to -4.0 mm.
    // B: the 13 off the right rail into the left side; aim -135.25 to -134.99, power 5.25 to 6.15 m/s, tip +5.0 to
    //   +14.0 mm.
    public static let kickBankCrossSide = AuthoredSituation(
        id: "kick-bank-cross-side", number: 10, cue: Diamond(1.75, 6.30), eight: Diamond(2.2, 2.0),
        balls: [13: Diamond(3.6, 4.6), 10: Diamond(0.7, 1.5), 2: Diamond(2.83, 5.7), 3: Diamond(2.94, 5.37),
                5: Diamond(3.5, 6.9), 6: Diamond(1.15, 3.0)],
        group: .stripes, surface: .cloth,
        escapes: [
            kick("A", rails: 1, AuthoredStrike(aim: -22.40, power: 3.70, tipUp: -0.0050, tipSide: 0),
                 .ball(13, pocket: .rightSide), rating: 3),
            AuthoredEscape(id: "B", kind: .bank, alsoUses: [], rails: 0,
                           strike: AuthoredStrike(aim: -135.11, power: 5.70, tipUp: 0.0095, tipSide: 0),
                           call: .ball(13, pocket: .leftSide), usesBridge: false, rating: 4, check: .bank,
                           railCheck: 0...2, touchBall: nil),
        ])

    // MARK: 11. Full-Table Swerve (Tournament cloth)
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // On the re-tuned tournament cloth both were searched again near their old strokes, aim in twenty-fifths of a degree.
    //   A: foot rail at across 1.17, left rail at along 7.33, right rail at along 4.55; aim 57.28 to 57.70, power 2.75 to
    //   3.60 m/s, tip +8.5 to +14.0 mm. B: aim 152.12 to 152.82, power 4.30 to 4.60 m/s, side -11.5 mm, tip -7.0 to
    //   -2.0 mm, elevation sine 0.50.
    public static let fullTableSwerve = AuthoredSituation(
        id: "full-table-swerve", number: 11, cue: Diamond(2.6, 7.0), eight: Diamond(2.6, 2.2),
        balls: [9: Diamond(0.4, 0.5), 14: Diamond(2.65, 1.0), 1: Diamond(1.6, 3.8), 3: Diamond(2.1, 4.3),
                4: Diamond(1.8, 4.6), 5: Diamond(0.3, 3.2), 7: Diamond(0.5, 5.5)],
        group: .stripes, surface: .tournament,
        escapes: [
            kick("A", rails: 3, AuthoredStrike(aim: 57.48, power: 3.20, tipUp: 0.0115, tipSide: 0),
                 .ball(9, pocket: .headLeft), rating: 4),
            curve("B", .swerve, AuthoredStrike(aim: 152.50, power: 4.45, tipUp: -0.0045, tipSide: -0.0115, elevation: 0.50),
                  .ball(9, pocket: .headLeft), rating: 5),
        ])

    // MARK: 12. No Way to Make It
    // On the 0.7.0 physics (21-Nov-2026: the coupled rail, the push rule and the re-tuned cloths), checked with
    // "BreakProbe eightball near", "relay" and "wide" and walked again with "eightball verify"; aim windows in degrees.
    // A, the kick safety: re-searched near its old stroke; left rail at along 1.93, right rail at along 4.99; aim 59.88
    //   to 60.58, power 2.85 to 3.45 m/s, tip +5.5 to +14.0 mm; nothing drops and the 1 is touched first.
    // The hero kick on the 1 that this situation used to carry as a second escape is gone: it was a sliver before (0.06
    //   degrees), and on the 0.7.0 physics no stroke near it, none at seven places for the 1 along the foot rail, and none
    //   round the full circle with up to four rails (306,000 strokes, 8 passed, the widest 0.08 degrees) holds one aim
    //   step, so no player could find it on purpose (item 30). The situation's own story is that there is no way to make
    //   it; the safety is its answer.
    public static let noWayToMakeIt = AuthoredSituation(
        id: "no-way-to-make-it", number: 12, cue: Diamond(2.4, 0.6), eight: Diamond(2.5, 1.0),
        balls: [1: Diamond(2.0, 7.9), 6: Diamond(1.1, 5.9), 9: Diamond(1.8, 7.5), 10: Diamond(1.25, 5.75),
                11: Diamond(0.95, 6.1), 13: Diamond(2.4, 7.55), 14: Diamond(3.4, 4.2)],
        group: .solids, surface: .cloth,
        escapes: [
            AuthoredEscape(id: "A", kind: .safety, alsoUses: [.kick], rails: 2,
                           strike: AuthoredStrike(aim: 60.16, power: 3.15, tipUp: 0.0100, tipSide: 0),
                           call: .safety, usesBridge: false, rating: 2, check: .touch, railCheck: 1...3, touchBall: 1),
        ])
}
