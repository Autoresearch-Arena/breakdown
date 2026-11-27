// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: The quiet button and the two kinds of "More" (design language, "Buttons", principle 4).
//          (1) QuietButtonStyle and QuietButton: cyan words in the label style, no fill and no edge, with a hit area
//          of at least 44 by 44 points; for links, "More", "Done", "How scoring works", Share on a result card.
//          (2) MoreMenuButton: the worded "More" button that opens a menu of the actions beyond one primary and one
//          secondary (a destructive one keeps its role, so the menu draws it in the system's destructive style).
//          (3) MoreDisclosure: "More" in front of text rather than actions (a score's breakdown, a ruling's reason):
//          a quiet "More" / "Less" toggle that grows the card to show it, with the standard ease (a cross-fade under
//          Reduce Motion). A menu never holds a paragraph or a table, so the two are kept apart.
// SRP/DRY check: Pass - checked ShowpieceView, PhoneStrip, NotebookPanel and the mode cards: their "More" toggles and
//          menus are each drawn in place; this is the one shared version. Colours from Palette, sizes from Theme.
import SwiftUI

/// The quiet role: cyan words, label style, at least a 44 by 44 point hit area. Disabled, the words drop to paper3.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        QuietButtonBody(configuration: configuration)
    }
}

extension ButtonStyle where Self == QuietButtonStyle {
    /// The quiet role.
    static var kitQuiet: QuietButtonStyle { QuietButtonStyle() }
}

private struct QuietButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.palette) private var palette
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(Theme.label)
            .foregroundStyle(isEnabled ? palette.accent : palette.paper3)
            .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
            // The hit area is the whole 44 point frame, not only the glyphs.
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(Theme.Motion.standard, value: configuration.isPressed)
    }
}

/// A worded quiet button. `title` is already localized (String(localized:)).
struct QuietButton: View {
    let title: String
    let systemImage: String?
    let isEnabled: Bool
    let action: @MainActor () -> Void

    init(_ title: String, systemImage: String? = nil, isEnabled: Bool = true,
         action: @escaping @MainActor () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }

    /// From a card's KitAction.
    init(_ item: KitAction) {
        self.init(item.title, systemImage: item.systemImage, isEnabled: item.isEnabled, action: item.action)
    }

    var body: some View {
        Button {
            action()
        } label: {
            KitButtonLabel(title, systemImage: systemImage)
        }
        .buttonStyle(QuietButtonStyle())
        .disabled(!isEnabled)
    }
}

/// The worded "More" button that opens a menu of the remaining actions. Draws nothing when `items` is empty, so a card
/// can always pass its list. The word is "More" (never a bare dots icon); the menu items are the KitActions' words.
struct MoreMenuButton: View {
    let items: [KitAction]
    let title: String

    init(_ items: [KitAction], title: String = String(localized: "More")) {
        self.items = items
        self.title = title
    }

    var body: some View {
        if !items.isEmpty {
            Menu {
                ForEach(items) { item in
                    Button(role: item.role) {
                        item.action()
                    } label: {
                        if let systemImage = item.systemImage {
                            Label(item.title, systemImage: systemImage)
                        } else {
                            Text(item.title)
                        }
                    }
                    .disabled(!item.isEnabled)
                }
            } label: {
                KitButtonLabel(title, systemImage: "ellipsis")
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
            .buttonStyle(QuietButtonStyle())
            .fixedSize()
        }
    }
}

/// Text behind a worded "More" (principle 4: one plain sentence, more behind a tap). The quiet toggle reads "More"
/// closed and "Less" open; the content grows in under it with the standard ease, and the card's height animates.
/// VoiceOver hears the toggle's state as its value.
struct MoreDisclosure<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Starting open (previews, or a screen that restores the reader's choice).
    init(startsOpen: Bool, @ViewBuilder content: () -> Content) {
        self.content = content()
        _isOpen = State(initialValue: startsOpen)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Button {
                withAnimation(Theme.Motion.standard) { isOpen.toggle() }
            } label: {
                KitButtonLabel(isOpen ? String(localized: "Less") : String(localized: "More"),
                               systemImage: isOpen ? "chevron.up" : "chevron.down")
            }
            .buttonStyle(QuietButtonStyle())
            .accessibilityValue(isOpen ? String(localized: "Shown") : String(localized: "Hidden"))
            if isOpen {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview("Quiet, every state") {
    KitPreviewStage(device: .big) {
        QuietButton("Done") {}
        QuietButton("How scoring works", systemImage: "questionmark.circle") {}
        QuietButton("Share", systemImage: "square.and.arrow.up") {}
        QuietButton("Done", isEnabled: false) {}
        MoreMenuButton([
            KitAction("Watch it", systemImage: "play") {},
            KitAction("Share", systemImage: "square.and.arrow.up") {},
            KitAction("Reset", systemImage: "arrow.counterclockwise", role: .destructive) {},
            KitAction("Last shot", isEnabled: false) {},
        ])
        MoreDisclosure {
            Text(verbatim: "A longer paragraph that sits behind the worded More.")
                .font(Theme.body)
        }
        MoreDisclosure(startsOpen: true) {
            Text(verbatim: "Shown open: the card has grown to hold it.")
                .font(Theme.body)
        }
    }
}
