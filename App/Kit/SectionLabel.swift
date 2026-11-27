// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-design-language.md, "Section label" and
//          the text scale's section role). SectionLabel is the one label above every group, list and band: caption,
//          bold, upper case, tracking 1.4, paper2 ("WHAT THE BALL GETS", a sheet's group header). A heading for
//          VoiceOver, read in its own case (the upper case is only drawn). The sectionLabelStyle() modifier gives any
//          Text the same look where a caller already builds its own (a sheet's Section header).
//          Read by SheetPage's groups (App/Kit/SheetPage.swift) and the later packages' cards and lists.
// SRP/DRY check: Pass - checked BandCaption (App/Strike/Instrument.swift: the same look in the aiming bands, through the
//          old groupCaption alias and .secondary; package 4 moves its callers here) and the menu's own headers
//          (TitleScreen, package 7 moves them here). No other shared section label exists.
import SwiftUI

/// The section label: caption bold, upper case, tracked, paper2, a heading.
struct SectionLabel: View {
    /// The words, already localised, in sentence case ("What the ball gets"); drawn upper case.
    let text: Text

    /// A label from words the caller already localised.
    init(_ text: String) { self.text = Text(verbatim: text) }
    /// A label from a ready Text (a localised key, or styled runs).
    init(_ text: Text) { self.text = text }

    var body: some View {
        text
            .sectionLabelStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SectionLabelStyle: ViewModifier {
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        content
            .font(Theme.section)
            .tracking(Theme.sectionTracking)
            .textCase(.uppercase)
            .foregroundStyle(palette.paper2)
            // One line at the ordinary sizes; it wraps rather than cuts at the accessibility sizes.
            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
    }
}

extension View {
    /// The section label's look (caption bold, upper case, tracking 1.4, paper2) on any view.
    func sectionLabelStyle() -> some View { modifier(SectionLabelStyle()) }
}

#Preview("Section labels") {
    VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
        SectionLabel("What the ball gets")
        Text(verbatim: "Content under the label").font(Theme.body).foregroundStyle(Palette(contrast: .standard).paper)
        SectionLabel("Ways to play").padding(.top, Theme.Space.lg)
    }
    .padding(Theme.Space.lg)
    .background(Palette(contrast: .standard).ground)
}
