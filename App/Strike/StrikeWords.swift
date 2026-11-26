// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Every word and number format the strike panel shows (plans/25-Nov-2026-strike-panel-and-controls-plan.md,
//          "Words"): each figure in its unit, in the game's own number style (AppLocale.numbers), the tile labels, the
//          error notes in plain units ("0.4° left", "2 mm left"), the panel's headings, and the one line the upright
//          phone's explanation gains when the stroke changed the strike (the largest error only). Every sentence goes
//          through String(localized:), with the number as a placeholder so a language can place its unit; the speed
//          reuses the game's existing "%@ m/s" line and the degrees its "%@°" line. "About" before the force is a word
//          of its own in every language, never dropped. The new English lines are listed with their translations in
//          localization/pending/v0710-strike.json.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 10: FigureText, a figure's number and unit apart, so the panel draws the unit smaller and grey on the
//          number's baseline; one function per figure returns it, the unit from UnitSymbol (carrying the glued lines'
//          translations). The glued functions stay for the notebook, the phone and the typed entry. New short labels,
//          the three band captions, the sub-lines ("goes 1.2° left", "from a 2.40 m/s swing", "up from level", "as
//          planned", "calm limit 3.5 m/s", "Rolling"), the delta chip ("+4.8 vs 11.9 planned"), and the plain sentence
//          above the figures, before a shot (spin, then the cut) and after one (the biggest difference, through
//          largestErrorLine). New English lines and their translations: localization/pending/v081-aiming.json.)
// SRP/DRY check: Pass - checked StrokeWords (swing readouts, the stroke's result line), AimFork.turnWords ("%@° left"
//          and "%@° right", reused for the aim's error), CueAngleMenu.shortWords ("%@°", reused) and NotebookInfo's
//          private formatters (millimetres and degrees for the trick-shot window; kept there, these differ in sign).
import Foundation

/// A figure's number and its unit, apart (aiming panel redesign): the panel draws the unit smaller and grey on the
/// number's baseline. `number` may carry a leading "≈" (the force), drawn with the number.
struct FigureText: Equatable, Sendable {
    var number: String
    var unit: String
}

enum StrikeWords {
    // MARK: Numbers

    /// A number in the game's number style with a fixed count of decimals; a value that rounds to zero is written
    /// without a minus sign ("0.0", never "-0.0").
    static func number(_ v: Double, decimals: Int) -> String {
        let scale = pow(10, Double(decimals))
        var rounded = (v * scale).rounded() / scale
        if rounded == 0 { rounded = 0 }
        return rounded.formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(decimals)))
    }

    /// The same with a sign always shown ("+0.02", "−0.40"), for differences.
    static func signed(_ v: Double, decimals: Int) -> String {
        let scale = pow(10, Double(decimals))
        var rounded = (v * scale).rounded() / scale
        if rounded == 0 { rounded = 0 }
        return rounded.formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(decimals))
            .sign(strategy: .always(includingZero: false)))
    }

    // MARK: Units

    static func speed(_ v: Double) -> String { String(localized: "\(number(v, decimals: 2)) m/s") }
    static func push(_ v: Double) -> String { String(localized: "\(number(v, decimals: 2)) N·s") }
    /// The force is an estimate, so it always reads "about": the word is translated, never left out.
    static func force(_ v: Double) -> String { String(localized: "about \(number(v, decimals: 0)) N") }
    static func energy(_ v: Double) -> String { String(localized: "\(number(v, decimals: 2)) J") }
    static func spin(_ v: Double) -> String { String(localized: "\(number(abs(v), decimals: 1)) turns/s") }
    static func millimetres(_ metres: Double) -> String {
        String(localized: "\(number(abs(metres) * 1000, decimals: 1)) mm")
    }
    static func degrees(_ v: Double) -> String { String(localized: "\(number(v, decimals: 1))°") }
    static func centimetres(_ metres: Double) -> String {
        Measurement(value: (metres * 100).rounded(), unit: UnitLength.centimeters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided).locale(AppLocale.numbers))
    }

    // MARK: Figures, number and unit apart (aiming panel redesign)

    static func speedFigure(_ v: Double) -> FigureText { FigureText(number: number(v, decimals: 2), unit: UnitSymbol.shown("m/s")) }
    static func pushFigure(_ v: Double) -> FigureText { FigureText(number: number(v, decimals: 2), unit: UnitSymbol.shown("N·s")) }
    /// The force is an estimate: the "≈" sign rides with the number on screen (VoiceOver keeps saying "about", the
    /// translated word, through StrikeSpoken.force).
    static func forceFigure(_ v: Double) -> FigureText {
        FigureText(number: "≈" + number(v, decimals: 0), unit: UnitSymbol.shown("N"))
    }
    static func energyFigure(_ v: Double) -> FigureText { FigureText(number: number(v, decimals: 2), unit: UnitSymbol.shown("J")) }
    /// Spin without its sign: the label says top or back, left or right.
    static func spinFigure(_ v: Double) -> FigureText {
        FigureText(number: number(abs(v), decimals: 1), unit: UnitSymbol.shown("turns/s"))
    }
    /// The tip's distance from the centre without its sign: the word beside it says which way.
    static func millimetresFigure(_ metres: Double) -> FigureText {
        FigureText(number: number(abs(metres) * 1000, decimals: 1), unit: UnitSymbol.shown("mm"))
    }
    static func degreesFigure(_ v: Double) -> FigureText { FigureText(number: number(v, decimals: 1), unit: "°") }
    /// The bridge, whole centimetres.
    static func centimetresFigure(_ metres: Double) -> FigureText {
        FigureText(number: number((metres * 100).rounded(), decimals: 0), unit: UnitSymbol.shown("cm"))
    }

    // MARK: Labels

    static var swingLabel: String { String(localized: "Swing") }
    static var leavesLabel: String { String(localized: "Ball leaves at") }
    static var pushLabel: String { String(localized: "Push") }
    /// Names the contact time the force is worked out over, as the plan asks.
    static var forceLabel: String {
        String(localized: "Force over \(number(StrikeFigures.tipContactTime * 1000, decimals: 0)) ms of tip contact")
    }
    static var energyLabel: String { String(localized: "Energy") }
    static var cutLabel: String { String(localized: "Cut") }
    static var bridgeLabel: String { String(localized: "Bridge") }
    static var cueAngleLabel: String { String(localized: "Cue angle") }

    static func topSpinLabel(_ v: Double) -> String {
        if abs(v) < 0.05 { return String(localized: "No top or back spin") }
        return v > 0 ? String(localized: "Top spin") : String(localized: "Back spin")
    }

    static func sideSpinLabel(_ v: Double) -> String {
        if abs(v) < 0.05 { return String(localized: "No side spin") }
        return v > 0 ? String(localized: "Right spin") : String(localized: "Left spin")
    }

    static func tipUpLabel(_ metres: Double) -> String {
        if abs(metres) < 0.00005 { return String(localized: "Tip at centre height") }
        return metres > 0 ? String(localized: "Tip above centre") : String(localized: "Tip below centre")
    }

    static func tipSideLabel(_ metres: Double) -> String {
        if abs(metres) < 0.00005 { return String(localized: "Tip on the centre line") }
        return metres > 0 ? String(localized: "Tip right of centre") : String(localized: "Tip left of centre")
    }

    /// The cut tile's label: which ball the line meets first, or that it meets none.
    static func cutOnLabel(ball: Int?) -> String {
        guard let ball else { return String(localized: "No ball in line") }
        return String(localized: "Cut on the \(ball)")
    }

    // MARK: The aiming panel's short labels and sub-lines (aiming panel redesign)

    static var leavesShortLabel: String { String(localized: "Leaves at") }
    static var forceShortLabel: String { String(localized: "Force") }
    /// Beside the force figure: the contact time it is worked out over.
    static var forceOver: String {
        String(localized: "over \(number(StrikeFigures.tipContactTime * 1000, decimals: 0)) ms")
    }
    static var ballGetsCaption: String { String(localized: "What the ball gets") }
    static var physicsCaption: String { String(localized: "The physics") }
    static var youSetCaption: String { String(localized: "What you set") }
    static var playedStrokeHeading: String { String(localized: "Your stroke") }
    /// Under the cut: where the white goes off the cue's line ("goes 1.2° left"), or that it goes along it.
    static func turnLine(_ degrees: Double) -> String {
        if abs(degrees) < 0.05 { return String(localized: "goes along the cue") }
        return String(localized: "goes \(aimError(degrees))")
    }
    /// Under the speed the ball leaves at: the swing that gave it ("from a 2.40 m/s swing").
    static func fromSwing(_ swing: Double) -> String { String(localized: "from a \(speed(swing)) swing") }
    static var upFromLevel: String { String(localized: "up from level") }
    static var asPlanned: String { String(localized: "as planned") }
    /// The calm mark's label on the big power bar ("calm limit 3.5 m/s").
    static func calmLimit(_ swing: Double) -> String {
        String(localized: "calm limit \(number(swing, decimals: 1)) \(UnitSymbol.shown("m/s"))")
    }
    /// Disabled Shoot while the balls are still moving.
    /// Its own key: "Rolling" already names the rolling motion in the Lens, which other languages word differently.
    static var rollingWord: String {
        String(localized: "Shoot: rolling", defaultValue: "Rolling",
               comment: "On the disabled Shoot button while the balls are still moving after a shot.")
    }
    /// The delta chip under a figure the stroke changed: the signed difference and the planned figure, both in the
    /// figure's number style ("+4.8 vs 11.9 planned"). Worded, so the difference is never told by its colour alone.
    static func deltaChip(_ delta: String, planned: String) -> String {
        String(localized: "\(delta) vs \(planned) planned")
    }
    /// The tip's direction words beside its millimetres.
    static func tipUpWord(_ metres: Double) -> String {
        if abs(metres) < 0.00005 { return String(localized: "centre height") }
        return metres > 0 ? String(localized: "above") : String(localized: "below")
    }
    static func tipSideWord(_ metres: Double) -> String {
        if abs(metres) < 0.00005 { return String(localized: "centre line") }
        // The same "right" and "left" lines the fine controls show (ShotPanel.shownWord), read here directly.
        return metres > 0 ? String(localized: "right") : String(localized: "left")
    }
    static var shorterBridge: String { String(localized: "Shorter bridge") }
    static var longerBridge: String { String(localized: "Longer bridge") }
    /// The accessibility hint on a figure a tap types into.
    static var typeFigureHint: String { String(localized: "Opens a field to type an exact value.") }

    // MARK: The plain sentence above the figures

    /// Before a shot: the spin in words, then the cut on the ball in line and where the white goes off the cue.
    /// "Back spin with some right side. The 11 is cut 3.4°; the white goes 1.2° left."
    static func plainSentence(_ f: StrikeFigures) -> String {
        var parts = [spinSentence(top: f.topSpin, side: f.sideSpin)]
        if let cut = f.cut, let ball = f.cutBall {
            let degrees = StrikeWords.degrees(cut)
            if abs(f.turnDegrees) < 0.05 {
                parts.append(String(localized: "The \(ball) is cut \(degrees)."))
            } else {
                parts.append(String(localized: "The \(ball) is cut \(degrees); the white goes \(aimError(f.turnDegrees))."))
            }
        }
        return parts.joined(separator: " ")
    }

    /// The spin in a few words: top or back first, then any side.
    static func spinSentence(top: Double, side: Double) -> String {
        let vertical = abs(top) < 0.05 ? 0 : (top > 0 ? 1 : -1)
        let across = abs(side) < 0.05 ? 0 : (side > 0 ? 1 : -1)
        switch (vertical, across) {
        case (-1, 1): return String(localized: "Back spin with some right side.")
        case (-1, -1): return String(localized: "Back spin with some left side.")
        case (-1, _): return String(localized: "Back spin, no side.")
        case (1, 1): return String(localized: "Top spin with some right side.")
        case (1, -1): return String(localized: "Top spin with some left side.")
        case (1, _): return String(localized: "Top spin, no side.")
        case (_, 1): return String(localized: "Right side, no top or back spin.")
        case (_, -1): return String(localized: "Left side, no top or back spin.")
        default: return String(localized: "No spin: a centre-ball hit.")
        }
    }

    /// After a shot: the single biggest difference (largestErrorLine), or that the stroke gave what was set.
    static func playedSentence(_ c: StrikeComparison) -> String {
        largestErrorLine(c) ?? String(localized: "Your stroke gave what you set.")
    }

    // MARK: Headings

    static var liveHeading: String { String(localized: "Your strike") }
    static var playedHeading: String { String(localized: "Planned and delivered") }
    /// Under the played heading: how to read the two figures in a tile.
    static var playedKey: String { String(localized: "Dim: what you set. Bright: what your stroke gave.") }
    static var miscueLine: String { String(localized: "Past the tip's grip: this hit slips off the ball.") }
    static var stepsLabel: String { String(localized: "Step by step") }

    // MARK: Errors in plain units

    /// The aim's error, as the shooter sees it ("0.4° left"), through the side-spin fork's own lines.
    static func aimError(_ degrees: Double) -> String {
        let d = number(abs(degrees), decimals: 1)
        return degrees > 0 ? String(localized: "\(d)° left") : String(localized: "\(d)° right")
    }

    /// The tip's sideways error ("2.0 mm left").
    static func tipError(_ metres: Double) -> String {
        let mm = number(abs(metres) * 1000, decimals: 1)
        return metres > 0 ? String(localized: "\(mm) mm right") : String(localized: "\(mm) mm left")
    }

    /// The error note for a figure that differs, in its unit with a sign; nil when it does not differ.
    static func note(_ f: StrikeComparison.Figure, _ c: StrikeComparison) -> String? {
        guard c.differs(f) else { return nil }
        let a = StrikeComparison.value(f, of: c.planned), b = StrikeComparison.value(f, of: c.delivered)
        switch f {
        case .aim: return aimError(c.aimError)
        case .tipSide: return tipError(c.tipSideError)
        case .tipUp:
            guard let a, let b else { return nil }
            return String(localized: "\(signed((b - a) * 1000, decimals: 1)) mm")
        default:
            guard let a, let b else { return nil }
            let d = b - a
            switch f {
            case .swing, .leaves: return String(localized: "\(signed(d, decimals: 2)) m/s")
            case .push: return String(localized: "\(signed(d, decimals: 2)) N·s")
            case .force: return String(localized: "\(signed(d, decimals: 0)) N")
            case .energy: return String(localized: "\(signed(d, decimals: 2)) J")
            case .topSpin, .sideSpin: return String(localized: "\(signed(d, decimals: 1)) turns/s")
            case .cueAngle, .cut: return String(localized: "\(signed(d, decimals: 1))°")
            default: return nil
            }
        }
    }

    /// The upright phone's one line under the strike's explanation when the stroke changed the strike: the largest
    /// error only. Nil when nothing differs.
    static func largestErrorLine(_ c: StrikeComparison) -> String? {
        switch c.largestError {
        case .aim(let degrees)?:
            return String(localized: "Planned against delivered: your stroke turned the cue \(aimError(degrees)).")
        case .tip(let metres)?:
            return String(localized: "Planned against delivered: the tip landed \(tipError(metres)) of where you set it.")
        case .miscue?:
            return String(localized: "Planned against delivered: your stroke pushed the tip past its grip.")
        case nil:
            return nil
        }
    }

    // MARK: Entry

    static var typeHint: String { String(localized: "Tap a tile with a pencil mark to type an exact value.") }
    static var doneWord: String { String(localized: "Done") }
    static var heightWord: String { String(localized: "Height") }
    static var sideWord: String { String(localized: "Side") }
    static var lockedByMode: String { String(localized: "This shot sets its own cue angle.") }
}
