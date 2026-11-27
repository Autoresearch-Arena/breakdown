// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: The locale every number on screen is written in, and the short unit symbols the figure tiles print.
//          Apple writes numbers by the phone's REGION, not its language, so a phone set to the United States that runs
//          the game in French or German showed "6.7 m/s" inside French and German sentences. AppLocale.numbers keeps
//          the phone's own locale when the phone's region speaks the language the game is showing (so a Swiss German
//          player keeps their own style) or the game is in English, and otherwise takes the shown language's own style
//          (French and German "6,7", Russian "6,7", Japanese "6.7"). Every place that turns a number into text passes
//          it: String(format:locale:), the .number / .percent / .measurement / .list format styles.
//          UnitSymbol gives the figure tiles their unit in the shown language (Russian м/с, Arabic م/ث), matching the
//          sentences beside them; CaptionFigure.unit itself stays the fixed English key the code compares.
//          NumberStyle holds the one precision rule per unit (design language, "Units and precision"): the kit's figure
//          views and every screen write a measured value through it, getting the number and the shown unit apart.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign: UnitSymbol also gives the strike's units on
//          their own (N·s, N, J, turns/s, mm), so the panel can draw the unit smaller and grey beside the number; each
//          carries the translation the glued "%@ turns/s" lines already had, German "U/s" among them.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2, plans/26-Nov-2026-design-language.md "Units
//          and precision": NumberStyle, one precision rule per unit (speed, spin, angle, tip offset, ball size, table
//          distance, table size, time, force, impulse, energy, gravity, friction and resistance) written in
//          AppLocale.numbers, each giving the number and its shown unit apart (NumberStyle.Reading) so the figure face
//          can draw the unit smaller and grey; "s" for every time; UnitSymbol gains "m/s²" for gravity and "m" for a
//          table's size.)
// SRP/DRY check: Pass - checked App/ for an existing locale helper (none: every site used Locale.current directly) and
//          Captions.swift's CaptionFigure (it keeps the key; this only maps the key to the shown symbol).
import Foundation

enum AppLocale {
    /// The locale numbers are written in. Worked out once: the shown language cannot change while the app runs.
    static let numbers: Locale = {
        let current = Locale.current
        // The language the game is actually showing (the best match among its translations), e.g. "fr" or "pt-BR".
        guard let shown = Bundle.main.preferredLocalizations.first else { return current }
        guard let shownCode = Locale.Language(identifier: shown).languageCode else { return current }
        // Running the game in French on a phone set to the United States makes Locale.current "fr_US", whose numbers are
        // American ("6.7"), so the current locale's language alone proves nothing. What decides it is whether the
        // phone's REGION belongs to the shown language: its main language, worked out from the region alone ("und-CH"
        // gives German, "und-US" English).
        if let region = current.region {
            let regionLanguage = Locale.Language(identifier: "und-" + region.identifier).maximalIdentifier
            // The region speaks the shown language (France, Switzerland for German, Brazil): its own style, so a Swiss
            // German player keeps "6.7" and a French player "6,7".
            if Locale.Language(identifier: regionLanguage).languageCode == shownCode { return current }
        }
        // English follows the phone's region, as the rest of the phone does (English on a German phone writes "6,7").
        if shownCode == .english { return current }
        // Any other language on a region that speaks something else: the shown language's own number style, so the
        // numbers agree with the words around them.
        return Locale(identifier: shown)
    }()
}

enum UnitSymbol {
    /// The symbol a figure tile prints for a unit key ("m/s", "cm", "s"), in the shown language. Degrees and percent
    /// are the same everywhere; an unknown key prints as it is.
    static func shown(_ key: String) -> String {
        switch key {
        case "m/s": return String(localized: "Unit: m/s", defaultValue: "m/s",
                                  comment: "Short symbol for metres per second, printed after a speed figure. Use the symbol a school physics book in this language uses.")
        case "cm": return String(localized: "Unit: cm", defaultValue: "cm",
                                 comment: "Short symbol for centimetres, printed after a distance figure.")
        case "s": return String(localized: "Unit: s", defaultValue: "s",
                                comment: "Short symbol for seconds, printed after a time figure.")
        // The strike panel's units, apart from their numbers (aiming panel redesign).
        case "N·s": return String(localized: "Unit: N·s", defaultValue: "N·s",
                                  comment: "Short symbol for newton seconds (the push a cue gives the ball).")
        case "N": return String(localized: "Unit: N", defaultValue: "N",
                                comment: "Short symbol for newtons (a force).")
        case "J": return String(localized: "Unit: J", defaultValue: "J",
                                comment: "Short symbol for joules (an energy).")
        case "turns/s": return String(localized: "Unit: turns/s", defaultValue: "turns/s",
                                      comment: "Short unit for spin: whole turns of the ball per second.")
        case "mm": return String(localized: "Unit: mm", defaultValue: "mm",
                                 comment: "Short symbol for millimetres.")
        // UI rethink package 2: gravity and a table's size.
        case "m/s²": return String(localized: "Unit: m/s²", defaultValue: "m/s²",
                                   comment: "Short symbol for metres per second squared, printed after a gravity figure (9.81 on Earth). Use the symbol a school physics book in this language uses.")
        case "m": return String(localized: "Unit: m", defaultValue: "m",
                                comment: "Short symbol for metres, printed after a table's length or width.")
        default: return key
        }
    }
}

/// One precision rule per unit (design language, "Units and precision"). Every figure on screen is written through
/// one of these, in AppLocale.numbers, so the same quantity never shows two ways on two screens. Inputs are in SI
/// (metres, seconds, newtons), the units the physics package works in; each function converts and rounds.
/// The rules that depend on size (speed, table distance) decide on the ROUNDED value, so 9.996 m/s reads "10.0", not
/// "10.00". A result that rounds to zero is written as a plain zero, never "-0.0".
/// Pure and nonisolated, so tests and background work can call them.
enum NumberStyle {
    /// A figure as the screen draws it: the number and its unit apart (the figure face draws the unit smaller and
    /// grey), plus both joined for a sentence or a VoiceOver label.
    struct Reading: Equatable, Sendable {
        /// The number, already rounded and written in AppLocale.numbers ("2.61", "2,61").
        let number: String
        /// The unit's fixed English key ("m/s", "°", "turns/s"), the one CaptionFigure.unit and UnitSymbol use.
        let unitKey: String
        /// The unit in the shown language (UnitSymbol.shown), empty for a quantity named in words.
        var unit: String { unitKey.isEmpty ? "" : UnitSymbol.shown(unitKey) }
        /// Number and unit as one unbreakable piece ("2.61 m/s", "2.1°"): a symbol that hugs its number (degrees,
        /// percent) is written straight on, any other unit after a no-break space, so a line never breaks inside it.
        var text: String {
            if unitKey.isEmpty { return number }
            return NumberStyle.hugs(unitKey) ? number + unit : number + "\u{00A0}" + unit
        }
    }

    /// Where a time is shown, which sets its precision.
    enum TimePlace: Sendable {
        /// The notebook and every other reading: two decimals.
        case notebook
        /// The scrub bar, which moves under the finger: one decimal.
        case scrubBar
    }

    // MARK: The rules, one per unit

    /// Speed in m/s: two decimals below 10, one at 10 and over (a break shot's 11.4 does not need its hundredths).
    static func speed(metresPerSecond v: Double) -> Reading {
        Reading(number: decimal(v, places: places(v, small: 2, large: 1, limit: 10)), unitKey: "m/s")
    }
    /// Spin in turns/s: one decimal. Input in radians per second, the physics package's unit.
    static func spin(radiansPerSecond w: Double) -> Reading {
        spin(turnsPerSecond: w / (2 * .pi))
    }
    /// Spin in turns/s: one decimal.
    static func spin(turnsPerSecond t: Double) -> Reading {
        Reading(number: decimal(t, places: 1), unitKey: "turns/s")
    }
    /// An angle in degrees, "°" with no space: one decimal.
    static func angle(degrees d: Double) -> Reading {
        Reading(number: decimal(d, places: 1), unitKey: "°")
    }
    /// A tip offset (or any small offset on the ball) in mm: one decimal. Input in metres.
    static func tipOffset(metres m: Double) -> Reading {
        Reading(number: decimal(m * 1000, places: 1), unitKey: "mm")
    }
    /// A ball's size (its diameter) in mm: whole. Input in metres.
    static func ballSize(metres m: Double) -> Reading {
        Reading(number: decimal(m * 1000, places: 0), unitKey: "mm")
    }
    /// A distance on the table in cm: whole, one decimal below 10 cm (a near miss of 4.5 cm keeps its half). Input in
    /// metres.
    static func distance(metres m: Double) -> Reading {
        let cm = m * 100
        return Reading(number: decimal(cm, places: places(cm, small: 1, large: 0, limit: 10)), unitKey: "cm")
    }
    /// A table's length or width in m: two decimals.
    static func tableSize(metres m: Double) -> Reading {
        Reading(number: decimal(m, places: 2), unitKey: "m")
    }
    /// A time in s (never "sec"): two decimals in the notebook, one on the scrub bar.
    static func time(seconds t: Double, place: TimePlace = .notebook) -> Reading {
        Reading(number: decimal(t, places: place == .scrubBar ? 1 : 2), unitKey: "s")
    }
    /// A force in N: whole.
    static func force(newtons f: Double) -> Reading {
        Reading(number: decimal(f, places: 0), unitKey: "N")
    }
    /// An impulse (the push the cue gives) in N·s: two decimals.
    static func impulse(newtonSeconds j: Double) -> Reading {
        Reading(number: decimal(j, places: 2), unitKey: "N·s")
    }
    /// An energy in J: two decimals.
    static func energy(joules e: Double) -> Reading {
        Reading(number: decimal(e, places: 2), unitKey: "J")
    }
    /// Gravity in m/s²: two decimals (9.81 on Earth, 1.62 on the Moon).
    static func gravity(metresPerSecondSquared g: Double) -> Reading {
        Reading(number: decimal(g, places: 2), unitKey: "m/s²")
    }
    /// A friction or resistance coefficient: no unit (the sentence names it in words), two or three significant
    /// figures (0.20, 0.012, 0.0095).
    static func coefficient(_ x: Double) -> Reading {
        let value = abs(x) < 1e-12 ? 0 : x
        return Reading(number: value.formatted(.number.locale(AppLocale.numbers).precision(.significantDigits(2...3))),
                       unitKey: "")
    }

    // MARK: Shared helpers

    /// `x` with exactly `places` decimals in AppLocale.numbers, a rounded zero written without a minus sign.
    static func decimal(_ x: Double, places: Int) -> String {
        let scale = pow(10, Double(places))
        let rounded = (x * scale).rounded() / scale
        // A value that rounds to zero is written as zero: no "-0.0" after a tiny negative drift.
        let value = rounded == 0 ? 0 : rounded
        return value.formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(places)).grouping(.never))
    }

    /// How many decimals a size-dependent rule takes: `small` while the value, rounded to `small` decimals, stays
    /// under `limit`; `large` from there up. Deciding on the rounded value keeps 9.996 from printing as "10.00".
    static func places(_ x: Double, small: Int, large: Int, limit: Double) -> Int {
        let scale = pow(10, Double(small))
        return abs((x * scale).rounded() / scale) < limit ? small : large
    }

    /// The unit keys written straight onto their number with no space.
    static func hugs(_ unitKey: String) -> Bool { unitKey == "°" || unitKey == "%" }
}
