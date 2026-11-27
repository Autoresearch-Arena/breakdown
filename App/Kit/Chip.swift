// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-design-language.md, "Chip"). Chip is the
//          kit's one small capsule: panelSunken, 6 by 10 points of padding, an inline figure (KitFigure, inline size)
//          and a caption word in paper2 ("2.61 m/s leaves", "3 rails"). An event chip carries a leading dot in its
//          meaning colour (contact, cushion, pocket, slide...); the chip itself stays neutral. A selected chip (the
//          chosen pocket in the call row, package 5) gets the 1.5 point cyan edge and its word in paper, cyan being
//          "you can act here, and this is chosen". Either part may be left out: a figure alone, or a word alone (a ball
//          chip in the call row).
//          The chip is not a button: a caller that makes it tappable wraps it in a Button (and keeps the 44 point hit
//          area with contentShape or padding). VoiceOver reads it as one element, figure then word, with the selected
//          trait when chosen.
//          Read by the later packages: the Lens chip on the cloth, the call row's ball and pocket chips, status lines.
// SRP/DRY check: Pass - checked DeltaChip (App/Strike/Instrument.swift: the worded planned-against-delivered pill, kept
//          for its callers; the language moves that difference into a "Last shot" card), the speed pill (PlaybackControls,
//          package 3 part A folds it into ShotReel) and CaptionViews' chips (packages 6 and 9). No neutral chip with a
//          figure, a word and a meaning dot existed.
import SwiftUI

/// A small neutral capsule: an inline figure and a caption word, with an optional dot in a meaning colour.
struct Chip: View {
    /// The figure, inline size; nil for a word-only chip.
    let figure: KitFigure?
    /// The word after the figure (already localised); nil for a figure-only chip.
    let word: Text?
    /// A leading dot in a meaning colour (an event chip); nil for none.
    var dot: Color? = nil
    /// Chosen: the cyan edge, the word in paper.
    var selected = false

    @Environment(\.palette) private var palette

    /// The general form.
    init(figure: KitFigure?, word: Text?, dot: Color? = nil, selected: Bool = false) {
        self.figure = figure
        self.word = word
        self.dot = dot
        self.selected = selected
    }

    /// A figure from NumberStyle and an optional word.
    init(_ reading: NumberStyle.Reading, word: String? = nil, dot: Color? = nil, selected: Bool = false) {
        self.init(figure: KitFigure(reading, size: .inline), word: word.map { Text(verbatim: $0) }, dot: dot,
                  selected: selected)
    }

    /// A figure already written out ("3/13", "2.6 m/s") and an optional word.
    init(value: String, word: String? = nil, dot: Color? = nil, selected: Bool = false) {
        self.init(figure: KitFigure(text: value, size: .inline), word: word.map { Text(verbatim: $0) }, dot: dot,
                  selected: selected)
    }

    /// A word-only chip (a ball in the call row, a pocket's name).
    init(word: String, dot: Color? = nil, selected: Bool = false) {
        self.init(figure: nil, word: Text(verbatim: word), dot: dot, selected: selected)
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.xxs) {
            if let dot {
                // The 3 point dot in the event's meaning colour (Theme.Space.chipDot); the chip itself stays neutral.
                Circle()
                    .fill(dot)
                    .frame(width: Theme.Space.chipDot, height: Theme.Space.chipDot)
                    .accessibilityHidden(true)
            }
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
                if let figure { figure }
                if let word {
                    word
                        .font(selected && figure == nil ? Theme.caption.weight(.semibold) : Theme.caption)
                        .foregroundStyle(selected ? palette.paper : palette.paper2)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, Theme.Space.chipVertical)
        .padding(.horizontal, Theme.Space.chipHorizontal)
        .background(palette.panelSunken, in: Capsule())
        // A sunken surface has no edge; only a chosen chip gets the cyan one.
        .overlay {
            if selected { Capsule().strokeBorder(palette.accent, lineWidth: Theme.Size.editableUnderline) }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview("Chips") {
    let palette = Palette(contrast: .standard)
    VStack(alignment: .leading, spacing: Theme.Space.sm) {
        Chip(NumberStyle.speed(metresPerSecond: 2.61), word: "leaves")
        Chip(NumberStyle.distance(metres: 0.42), word: "travelled", dot: palette.contact)
        Chip(value: "3", word: "rails", dot: palette.cushion)
        Chip(value: "1", word: "pocketed", dot: palette.pocket)
        HStack(spacing: Theme.Space.xs) {
            Chip(word: "Corner")
            Chip(word: "Side", selected: true)
            Chip(value: "3/13")
        }
    }
    .padding(Theme.Space.lg)
    .background(palette.panel)
    .background(palette.ground)
}
