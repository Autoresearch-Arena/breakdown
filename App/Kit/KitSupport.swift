// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3 part A review: the preview stage sets the
//          device through the kit's own kitDevice modifier.)
// PURPOSE: The few shared pieces the buttons and cards in App/Kit (part A) lean on, kept in one place so they never
//          repeat them. Which device a kit view lays out for is not here: it is the kitDevice environment value and
//          KitDeviceReader in SheetPage.swift (part B), which every kit view reads. (1) KitAction, one worded button's
//          title, optional outline icon, role and closure, the way cards take their buttons. (2) KitButtonLabel, the
//          one label every button wears: an optional outline icon leading a word. (3) KitPreviewStage, the dark
//          ground every kit preview sits on (the window forces dark at its root; previews do not inherit that).
// SRP/DRY check: Pass - checked LayoutFlags.swift, Surfaces.swift and the part B kit files (SheetPage owns the
//          device reading, so the part A views use KitDeviceReader rather than a second copy); no shared action,
//          button label or preview backdrop existed.
import SwiftUI

/// One worded button a card shows: every button carries a word (design language, "Buttons"), an outline icon may lead
/// it. `title` is already localized by the caller (String(localized:)). A destructive role turns a secondary button's
/// word warning and is passed to the system so menus and VoiceOver treat it as destructive too.
struct KitAction: Identifiable {
    let id: String
    let title: String
    let systemImage: String?
    let role: ButtonRole?
    let isEnabled: Bool
    let action: @MainActor () -> Void

    init(_ title: String, systemImage: String? = nil, role: ButtonRole? = nil, isEnabled: Bool = true,
         id: String? = nil, action: @escaping @MainActor () -> Void) {
        self.id = id ?? title
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.isEnabled = isEnabled
        self.action = action
    }

    var isDestructive: Bool { role == .destructive }
}

/// The one label every kit button wears: an optional leading outline icon (medium weight, the design language's icon
/// rule) and the word. The icon is decorative for VoiceOver; the word is the button's name.
struct KitButtonLabel: View {
    let title: String
    let systemImage: String?

    init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .fontWeight(.medium)
                    .symbolVariant(.none)
                    .accessibilityHidden(true)
            }
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The backdrop every kit preview sits on: the ground colour, the dark scheme, the palette and the cyan tint, as the
/// window gives them at its root. Previews only; nothing in the game uses it.
struct KitPreviewStage<Content: View>: View {
    let device: Theme.Device
    @ViewBuilder var content: Content

    init(device: Theme.Device = .big, @ViewBuilder content: () -> Content) {
        self.device = device
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.cardGap(device)) {
                content
            }
            .padding(Theme.Space.pageMargin(device))
            .frame(maxWidth: device == .phone ? 390 : Theme.Size.sideColumn, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette(contrast: .standard).ground)
        .kitDevice(device)
        .modifier(PaletteProvider())
        .preferredColorScheme(.dark)
    }
}
