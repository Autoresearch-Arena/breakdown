// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3 part A review: the name is the heading on
//          every device, as the design language's mode card says; the status line wraps from the leading edge through
//          its own small layout, since the shared WrappingRow lines its rows up on the trailing edge.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3's leftover notes: the status line wraps through
//          the one shared WrappingRow (Surfaces.swift), now with a leading alignment; the private StatusLineLayout copy
//          is gone. The line looks the same.)
// PURPOSE: The mode card (design language, "Mode card"), the one card every mode fills in: shot of the day, trick
//          shots, behind the 8-ball, lessons, drills, the table games. In order: (1) the name row, the item's name
//          (heading) with its five difficulty dots on the right; (2) one
//          plain sentence, the goal; (3) a status line of inline figures (try count, time left, best result, score),
//          each a caption word and its figure with the unit grey on the same baseline, wrapping when narrow; (4) an
//          optional "How forgiving" slot where the mode sets up a shot, taken as any view so this card does not depend
//          on the figure tile type (package 3 part B fills it with FigureTiles: aim in degrees, speed in m/s, tip in
//          mm); (5) the button row, primary right, secondary left of it, "More" for the rest. While a guided Lens
//          replay plays on the upright phone (lensReplayCompact) the card slims to its name row and primary only.
//          Also KitStatusItem and KitStatusLine, the status line's figures, shared with the result card.
// SRP/DRY check: Pass - checked the trick, lesson, situation, drill and daily cards (each builds its own glass card,
//          heading, status words and buttons); this is the one frame they move into in package 5. Surface, buttons,
//          dots, figures (KitFigure) and the section label (SectionLabel) come from the kit; numbers come in already
//          written by NumberStyle. The status line's wrapping is the shared WrappingRow (Surfaces.swift) laid out from
//          the leading edge, the same layout the button rows and the call's chips use.
import SwiftUI

/// One figure in a status line: a caption word ("Tries", "Best") and its figure, with an optional unit in grey on the
/// same baseline. Words and numbers are already localized and rounded by the caller (NumberStyle).
struct KitStatusItem: Identifiable, Equatable, Sendable {
    let label: String
    let figure: String
    let unit: String
    /// The unit sits straight on the figure (degrees, percent) instead of after a space (KitFigure draws that from
    /// the unit itself; this keeps the spoken value the same).
    let hugs: Bool

    var id: String { label }

    init(_ label: String, figure: String, unit: String = "") {
        self.label = label
        self.figure = figure
        self.unit = unit
        self.hugs = KitFigure.unitHugs(unit)
    }

    /// The figure and unit as spoken and as one piece of text ("2.61 m/s", "1.5°").
    var spoken: String { unit.isEmpty || hugs ? figure + unit : figure + " " + unit }

    /// From a NumberStyle reading: its number and its shown unit.
    init(_ label: String, reading: NumberStyle.Reading) {
        self.init(label, figure: reading.number, unit: reading.unit)
    }
}

/// A line of status figures that wraps onto more lines when narrow. Each item is one VoiceOver element ("Best, 2.61
/// m/s").
struct KitStatusLine: View {
    let items: [KitStatusItem]
    @Environment(\.palette) private var palette

    var body: some View {
        WrappingRow(alignment: .leading, spacing: Theme.Space.sm, lineSpacing: Theme.Space.xxs) {
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
                    Text(item.label)
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper2)
                    KitFigure(number: item.figure, unit: item.unit, size: .inline)
                }
                .lineLimit(1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.label)
                .accessibilityValue(item.spoken)
            }
        }
    }
}

/// The mode card. `Tiles` is the "How forgiving" slot (EmptyView when the mode does not set up a shot).
struct ModeCard<Tiles: View>: View {
    let name: String
    /// 0 to 5, or nil for an item with no difficulty (a free table).
    let difficulty: Int?
    let goal: String
    let status: [KitStatusItem]
    let tilesTitle: String
    let primary: KitAction?
    let secondary: KitAction?
    let more: [KitAction]
    let tiles: Tiles

    @Environment(\.palette) private var palette
    @Environment(\.lensReplayCompact) private var slim
    private var deviceReader = KitDeviceReader()
    private var device: Theme.Device { deviceReader.current }

    init(name: String, difficulty: Int? = nil, goal: String, status: [KitStatusItem] = [],
         tilesTitle: String = String(localized: "How forgiving"),
         primary: KitAction?, secondary: KitAction? = nil, more: [KitAction] = [],
         @ViewBuilder tiles: () -> Tiles) {
        self.name = name
        self.difficulty = difficulty
        self.goal = goal
        self.status = status
        self.tilesTitle = tilesTitle
        self.primary = primary
        self.secondary = secondary
        self.more = more
        self.tiles = tiles()
    }

    private var hasTiles: Bool { Tiles.self != EmptyView.self }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            nameRow
            if !slim {
                Text(goal)
                    .font(device == .phone ? Theme.bodyCompact : Theme.body)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                if !status.isEmpty {
                    KitStatusLine(items: status)
                }
                if hasTiles {
                    VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                        SectionLabel(tilesTitle)
                        tiles
                    }
                    .padding(.top, Theme.Space.xxs)
                }
            }
            if primary != nil || secondary != nil || !more.isEmpty {
                KitButtonRow(primary: primary, secondary: slim ? nil : secondary, more: slim ? [] : more)
                    .padding(.top, Theme.Space.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .animation(Theme.Motion.standard, value: slim)
        .accessibilityElement(children: .contain)
    }

    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
            KitCardTitle(name, style: .heading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Space.xs)
            if let difficulty {
                DifficultyDots(level: difficulty)
                    // The dots rest on the name's first baseline, like a full stop, however tall the name grows.
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
            }
        }
    }
}

extension ModeCard where Tiles == EmptyView {
    /// A mode card with no "How forgiving" slot.
    init(name: String, difficulty: Int? = nil, goal: String, status: [KitStatusItem] = [],
         primary: KitAction?, secondary: KitAction? = nil, more: [KitAction] = []) {
        self.init(name: name, difficulty: difficulty, goal: goal, status: status, primary: primary,
                  secondary: secondary, more: more, tiles: { EmptyView() })
    }
}

#Preview("Mode card, every state") {
    KitPreviewStage(device: .big) {
        ModeCard(name: "Draw back", difficulty: 3,
                 goal: "Hit the 1 ball full and bring the cue ball back to the cushion.",
                 status: [KitStatusItem("Tries", figure: "4"),
                          KitStatusItem("Best", reading: NumberStyle.distance(metres: 0.124)),
                          KitStatusItem("Score", figure: "820")],
                 primary: KitAction("Try it") {}, secondary: KitAction("Watch it", systemImage: "play") {},
                 more: [KitAction("Share") {}, KitAction("Reset", role: .destructive) {}])
        ModeCard(name: "Cut to the corner", difficulty: 5,
                 goal: "Cut the 3 ball into the far corner.",
                 status: [KitStatusItem("Time left", reading: NumberStyle.time(seconds: 42, place: .notebook))],
                 primary: KitAction("Shoot") {}) {
            // A stand-in for the figure tiles package 3 part B provides.
            HStack(spacing: Theme.Space.xs) {
                Text(verbatim: "1.5°").font(Theme.controlFigure)
                Text(verbatim: "0.20 m/s").font(Theme.controlFigure)
                Text(verbatim: "3.0 mm").font(Theme.controlFigure)
            }
        }
        ModeCard(name: "Free table", goal: "Play any shot you like.", primary: KitAction("Next") {})
    }
}

#Preview("Mode card, phone and slim") {
    KitPreviewStage(device: .phone) {
        ModeCard(name: "Draw back", difficulty: 2, goal: "Bring the cue ball back to the cushion.",
                 status: [KitStatusItem("Tries", figure: "1")],
                 primary: KitAction("Try it") {}, secondary: KitAction("Watch it") {})
        ModeCard(name: "Draw back", difficulty: 2, goal: "Bring the cue ball back to the cushion.",
                 primary: KitAction("Try it") {}, secondary: KitAction("Watch it") {})
            .environment(\.lensReplayCompact, true)
    }
}
