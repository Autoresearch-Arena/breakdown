// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The strike panel's figures as VoiceOver says them (plans/25-Nov-2026-everyone-can-play-plan.md, Part D
//          item 3): each tile is one element that reads its label, then its figure with the unit in words ("Force over
//          1 ms of tip contact, about 1700 newtons"), never the symbols "N·s" or "m/s", which a screen reader spells
//          out letter by letter. After a shot a tile whose figure the stroke changed reads planned, then delivered
//          ("planned 2.60 metres per second, delivered 2.55 metres per second"); a tile that did not change reads its
//          one figure. The visible tile also names the two figures in one word each (plannedWord, deliveredWord), so
//          dim against bright is never the only way to tell them apart (Part A item 5).
//          Numbers come from StrikeWords.number (the game's own number style), so the spoken figure is the one on
//          screen. Every sentence goes through String(localized:) with the number as a placeholder; the new English
//          lines are in localization/pending/v0710-everyone.json with their translations.
//          Read by StrikePanel (the tiles) and NumberTile (the two one-word labels).
// SRP/DRY check: Pass - checked StrikeWords (the visible figures and their unit symbols; these are the same numbers
//          in spoken units, kept apart so the screen keeps its short symbols) and TableWords (spoken table and aim
//          words; none of these units is there).
import Foundation

enum StrikeSpoken {
    // MARK: Figures in spoken units

    static func speed(_ v: Double) -> String {
        String(localized: "\(StrikeWords.number(v, decimals: 2)) metres per second")
    }

    static func push(_ v: Double) -> String {
        String(localized: "\(StrikeWords.number(v, decimals: 2)) newton seconds")
    }

    /// The force is an estimate, so it always says "about", as the tile does.
    static func force(_ v: Double) -> String {
        String(localized: "about \(StrikeWords.number(v, decimals: 0)) newtons")
    }

    static func energy(_ v: Double) -> String {
        String(localized: "\(StrikeWords.number(v, decimals: 2)) joules")
    }

    /// Spin, without its sign: the tile's label already says top or back, left or right.
    static func spin(_ v: Double) -> String {
        String(localized: "\(StrikeWords.number(abs(v), decimals: 1)) turns per second")
    }

    /// The tip's distance from the centre, without its sign: the label already says above or below, left or right.
    static func millimetres(_ metres: Double) -> String {
        String(localized: "\(StrikeWords.number(abs(metres) * 1000, decimals: 1)) millimetres")
    }

    static func degrees(_ v: Double) -> String {
        String(localized: "\(StrikeWords.number(v, decimals: 1)) degrees")
    }

    static func centimetres(_ metres: Double) -> String {
        String(localized: "\(StrikeWords.number(metres * 100, decimals: 0)) centimetres")
    }

    /// The cut with no ball in line.
    static var noCut: String { String(localized: "no ball in line") }

    /// One figure of a strike in spoken units. The aim has no tile of its own (its error is the cut tile's note), so
    /// it reads as degrees too.
    static func value(_ f: StrikeComparison.Figure, of s: StrikeFigures) -> String {
        switch f {
        case .swing: return speed(s.swing)
        case .leaves: return speed(s.leaves)
        case .push: return push(s.push)
        case .force: return force(s.force)
        case .energy: return energy(s.energy)
        case .topSpin: return spin(s.topSpin)
        case .sideSpin: return spin(s.sideSpin)
        case .tipUp: return millimetres(s.tipUp)
        case .tipSide: return millimetres(s.tipSide)
        case .cueAngle: return degrees(s.cueAngle)
        case .cut: return s.cut.map(degrees) ?? noCut
        case .aim: return degrees(s.aimDegrees)
        }
    }

    /// What a tile says after its label: the live figure; after a shot, the delivered figure alone when the stroke did
    /// not change it, or planned then delivered when it did. `differs` is the tile's own test (the cut tile counts a
    /// changed aim as a change, as its note does).
    static func tile(_ f: StrikeComparison.Figure, _ reading: StrikeReading.Reading, differs: Bool) -> String {
        switch reading {
        case .live(let figures):
            return value(f, of: figures)
        case .played(let c):
            guard differs else { return value(f, of: c.delivered) }
            return plannedThenDelivered(planned: value(f, of: c.planned), delivered: value(f, of: c.delivered))
        }
    }

    /// "planned 2.60 metres per second, delivered 2.55 metres per second".
    static func plannedThenDelivered(planned: String, delivered: String) -> String {
        String(localized: "planned \(planned), delivered \(delivered)")
    }

    // MARK: The visible one-word labels

    /// Beside the dimmed figure in a tile after a shot.
    static var plannedWord: String { String(localized: "Planned") }
    /// Beside the bright figure in a tile whose figure the stroke changed.
    static var deliveredWord: String { String(localized: "Delivered") }
}
