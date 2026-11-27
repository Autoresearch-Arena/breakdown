// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: The panel, the house surface (design language, "Surfaces" and "Panel card"), in three pieces.
//          (1) kitPanel(): the surface alone: opaque panel colour, a 1 point rule edge, medium corners, the card
//          padding for the device (16 phone, 20 otherwise); no shadow, no blur, no glass. Every reading surface
//          uses it.
//          (2) PanelCard: the card built on it: a title row (a section label, a heading or a serif title on the left,
//          at most one quiet action on the right), the content, then an optional button row at the bottom.
//          (3) KitButtonRow: the one button row every card ends with: "More" and a quiet action on the left, then the
//          secondary, then the primary at the bottom right (principle 6). When the words do not fit on one line (a
//          narrow column or a large text size) the row stacks full width, primary on top.
// SRP/DRY check: Pass - checked Surfaces.glassCard (glass, for floating cards; the panel is opaque on purpose), the
//          aiming panel's band (ShotPanel, flat but drawn in place) and the mode cards (glassCard each). This is the
//          one panel surface; the buttons come from the kit's three roles.
import SwiftUI

extension View {
    /// The panel surface: opaque panel fill, 1 point rule edge, medium corners, the device's card padding.
    /// `padded: false` draws the surface only, for content that sets its own insets (a list inside a sheet group).
    func kitPanel(padded: Bool = true) -> some View {
        modifier(PanelSurface(padded: padded))
    }
}

private struct PanelSurface: ViewModifier {
    let padded: Bool
    @Environment(\.palette) private var palette
    private var deviceReader = KitDeviceReader()
    private var device: Theme.Device { deviceReader.current }

    func body(content: Content) -> some View {
        content
            .padding(padded ? Theme.Space.cardPadding(device) : 0)
            .background(palette.panel, in: Theme.Corner.cardShape)
            .overlay(Theme.Corner.cardShape.strokeBorder(palette.rule, lineWidth: Theme.Size.hairline))
    }
}

/// How a panel card's title reads: the section label (caption, bold, upper case, tracked, paper2), a heading (card
/// titles), or the serif title (a page's or sheet's main card on a big screen).
enum PanelCardTitleStyle: Sendable {
    case section, heading, title
}

/// A panel card: title row, content, optional button row. Titles and words are already localized by the caller.
struct PanelCard<Content: View, Buttons: View>: View {
    let title: String?
    let titleStyle: PanelCardTitleStyle
    /// The one quiet action the title row may carry ("How scoring works", "Done").
    let titleAction: KitAction?
    let content: Content
    let buttons: Buttons

    init(title: String? = nil, titleStyle: PanelCardTitleStyle = .section, titleAction: KitAction? = nil,
         @ViewBuilder content: () -> Content, @ViewBuilder buttons: () -> Buttons) {
        self.title = title
        self.titleStyle = titleStyle
        self.titleAction = titleAction
        self.content = content()
        self.buttons = buttons()
    }

    private var hasButtons: Bool { Buttons.self != EmptyView.self }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            if title != nil || titleAction != nil {
                titleRow
            }
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            if hasButtons {
                buttons
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, Theme.Space.xxs)
            }
        }
        .kitPanel()
        .accessibilityElement(children: .contain)
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
            if let title {
                KitCardTitle(title, style: titleStyle)
            }
            Spacer(minLength: 0)
            if let titleAction {
                QuietButton(titleAction)
                    // The quiet button keeps its 44 point hit area, but it must not push the content down by the
                    // whole of it: the hit area spills into the card's padding instead.
                    .padding(.vertical, -Theme.Space.sm)
            }
        }
    }
}

extension PanelCard where Buttons == EmptyView {
    /// A panel card with no button row.
    init(title: String? = nil, titleStyle: PanelCardTitleStyle = .section, titleAction: KitAction? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, titleStyle: titleStyle, titleAction: titleAction, content: content,
                  buttons: { EmptyView() })
    }
}

/// A card's title in one of the three title styles, marked as a header for VoiceOver.
struct KitCardTitle: View {
    let text: String
    let style: PanelCardTitleStyle
    @Environment(\.palette) private var palette

    init(_ text: String, style: PanelCardTitleStyle) {
        self.text = text
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .section:
                Text(verbatim: text)
                    .sectionLabelStyle()
            case .heading:
                Text(text)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
            case .title:
                Text(text)
                    .font(Theme.title)
                    .foregroundStyle(palette.paper)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// The button row every card ends with. Left: "More" (a menu of `more`) and one quiet action. Right: the secondary,
/// then the primary, bottom right. Any of them may be absent. Falls back to a full-width stack (primary first) when the
/// row cannot fit its words on one line.
struct KitButtonRow: View {
    let primary: KitAction?
    let secondary: KitAction?
    let quiet: KitAction?
    let more: [KitAction]

    init(primary: KitAction? = nil, secondary: KitAction? = nil, quiet: KitAction? = nil, more: [KitAction] = []) {
        self.primary = primary
        self.secondary = secondary
        self.quiet = quiet
        self.more = more
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            oneLine
            stacked
        }
    }

    private var oneLine: some View {
        HStack(spacing: Theme.Space.sm) {
            MoreMenuButton(more)
            if let quiet { QuietButton(quiet) }
            Spacer(minLength: 0)
            if let secondary { SecondaryButton(secondary).fixedSize() }
            if let primary { PrimaryButton(primary).fixedSize() }
        }
    }

    /// The narrow form: primary on top, full width, so it is still the first main action the thumb finds; the quiet
    /// actions share the last line.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            if let primary { PrimaryButton(primary, fullWidth: true) }
            if let secondary { SecondaryButton(secondary, fullWidth: true) }
            if quiet != nil || !more.isEmpty {
                HStack(spacing: Theme.Space.sm) {
                    MoreMenuButton(more)
                    if let quiet { QuietButton(quiet) }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview("Panel card, every state") {
    KitPreviewStage(device: .big) {
        PanelCard(title: "What the ball gets") {
            Text(verbatim: "Content only, section label title.")
                .font(Theme.body)
        }
        PanelCard(title: "Last shot", titleStyle: .heading,
                  titleAction: KitAction("How scoring works") {}) {
            Text(verbatim: "A heading with one quiet action on the right.")
                .font(Theme.body)
        }
        PanelCard(title: "Shot of the day", titleStyle: .title) {
            Text(verbatim: "A serif title and a button row, the primary bottom right.")
                .font(Theme.body)
        } buttons: {
            KitButtonRow(primary: KitAction("Next") {}, secondary: KitAction("Try again") {},
                         more: [KitAction("Share") {}])
        }
        PanelCard {
            Text(verbatim: "No title row at all.")
                .font(Theme.body)
        }
        Text(verbatim: "The bare surface")
            .frame(maxWidth: .infinity, alignment: .leading)
            .kitPanel()
    }
}

#Preview("Panel card, phone and a narrow row") {
    KitPreviewStage(device: .phone) {
        PanelCard(title: "Last shot") {
            Text(verbatim: "On the phone: 16 padding, 50 high buttons.")
                .font(Theme.bodyCompact)
        } buttons: {
            KitButtonRow(primary: KitAction("Watch a way out") {}, secondary: KitAction("Try again") {},
                         quiet: KitAction("Share") {}, more: [KitAction("Reset", role: .destructive) {}])
        }
    }
}
