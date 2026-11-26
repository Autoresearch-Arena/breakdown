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
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign: UnitSymbol also gives the strike's units on
//          their own (N·s, N, J, turns/s, mm), so the panel can draw the unit smaller and grey beside the number; each
//          carries the translation the glued "%@ turns/s" lines already had, German "U/s" among them.)
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
        default: return key
        }
    }
}
