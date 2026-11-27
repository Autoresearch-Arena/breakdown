// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-design-language.md, "Progress chip").
//          ProgressChip is the one progress mark on every menu row and tile: a capsule chip on the row's right side
//          holding only the inline figure "3/13" (earned over total, in the app's number locale). It draws nothing at
//          all until the first item is earned (no "0/13" on a fresh install: calm first), and a tick replaces the
//          figure once the whole collection is complete. VoiceOver reads "3 of 13 done" or "All 13 done".
//          Read by the later packages' menu rows and tiles (TitleScreen, package 7) and by ListRow's callers.
// SRP/DRY check: Pass - checked the menu's own count labels (TitleScreen and the mode lists drew their own, package 7
//          moves them here) and Chip (App/Kit/Chip.swift: same capsule, built on it rather than drawn twice).
import SwiftUI

/// "3/13" in a chip, hidden until something is earned, a tick when the collection is complete.
struct ProgressChip: View {
    /// How many are earned.
    let earned: Int
    /// How many there are.
    let total: Int

    @Environment(\.palette) private var palette
    // The tick's size follows the reader's text, like the inline figure it replaces.
    @ScaledMetric(relativeTo: .subheadline) private var tickPoints: CGFloat = Theme.FigureSize.inline.baseSize

    /// The state the chip shows; a pure rule so the tests can check it.
    enum Stage: Equatable, Sendable {
        /// Nothing earned yet (or nothing to earn): the chip draws nothing.
        case hidden
        /// Some earned: the figure.
        case counting
        /// All earned: the tick.
        case complete
    }

    nonisolated static func stage(earned: Int, total: Int) -> Stage {
        if total <= 0 || earned <= 0 { return .hidden }
        return earned >= total ? .complete : .counting
    }

    /// The figure as drawn ("3/13"), in the app's number locale.
    nonisolated static func figure(earned: Int, total: Int) -> String {
        let n = earned.formatted(.number.locale(AppLocale.numbers))
        let t = total.formatted(.number.locale(AppLocale.numbers))
        return n + "/" + t
    }

    var body: some View {
        switch Self.stage(earned: earned, total: total) {
        case .hidden:
            EmptyView()
        case .counting:
            Chip(value: Self.figure(earned: earned, total: total), word: nil)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: String(localized: "Progress chip: earned of total",
                                                          defaultValue: "\(earned) of \(total) done",
                                                          comment: "VoiceOver for a menu row's progress chip, e.g. 3 of 13 done. First number earned, second the total.")))
        case .complete:
            Image(systemName: "checkmark")
                .font(.system(size: tickPoints * 0.8, weight: .semibold))
                .foregroundStyle(palette.accent)
                .padding(.vertical, Theme.Space.chipVertical)
                .padding(.horizontal, Theme.Space.chipHorizontal)
                .background(palette.panelSunken, in: Capsule())
                .fixedSize()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: String(localized: "Progress chip: all done",
                                                          defaultValue: "All \(total) done",
                                                          comment: "VoiceOver for a menu row's progress chip once every item is earned, e.g. All 13 done.")))
        }
    }
}

#Preview("Progress chips") {
    let palette = Palette(contrast: .standard)
    VStack(alignment: .trailing, spacing: Theme.Space.sm) {
        HStack { Text(verbatim: "Nothing earned (draws nothing):").foregroundStyle(palette.paper2); ProgressChip(earned: 0, total: 13) }
        HStack { Text(verbatim: "Some earned:").foregroundStyle(palette.paper2); ProgressChip(earned: 3, total: 13) }
        HStack { Text(verbatim: "Complete:").foregroundStyle(palette.paper2); ProgressChip(earned: 6, total: 6) }
    }
    .font(Theme.caption)
    .padding(Theme.Space.lg)
    .background(palette.panel)
    .background(palette.ground)
}
