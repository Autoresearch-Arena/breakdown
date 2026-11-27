// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: The secondary button (design language, "Buttons"): at most one beside the primary ("Try again", "Watch a
//          way out", "Share"). The panel colour inside a 1 point rule edge, paper words in the label style, a capsule
//          as high as the primary (50 phone, 56 big), an optional leading outline icon. Destructive actions are this
//          button with warning words (`destructive: true`, or a Button with the destructive role): never a red fill.
//          `tall` matches a tall primary in the action column ("Try again" the same size as Shoot). Use it as a style
//          (`.buttonStyle(SecondaryButtonStyle())`, `.kitSecondary`, `.kitDestructive`) or as the SecondaryButton view.
// SRP/DRY check: Pass - checked ShowpieceView and WhatIfViews (system glass buttons, no shared secondary style). The
//          label is KitButtonLabel, the sizes Theme.Size, the colours Palette; the height rule mirrors the primary's
//          on purpose so the two always sit level in a row.
import SwiftUI

/// The secondary role: panel fill, rule edge, paper words (warning words when destructive), capsule.
struct SecondaryButtonStyle: ButtonStyle {
    /// Warning words, for an action that throws something away. A Button given the destructive role gets them too.
    var destructive: Bool = false
    /// Fill the width it is offered.
    var fullWidth: Bool = false
    /// Match a tall primary in the action column.
    var tall: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        SecondaryButtonBody(configuration: configuration,
                            destructive: destructive || configuration.role == .destructive,
                            fullWidth: fullWidth, tall: tall)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The secondary role at its normal size.
    static var kitSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    /// The secondary role with warning words, for a destructive action.
    static var kitDestructive: SecondaryButtonStyle { SecondaryButtonStyle(destructive: true) }
}

private struct SecondaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let destructive: Bool
    let fullWidth: Bool
    let tall: Bool
    @Environment(\.palette) private var palette
    @Environment(\.isEnabled) private var isEnabled
    private var deviceReader = KitDeviceReader()
    private var device: Theme.Device { deviceReader.current }

    private var minHeight: CGFloat {
        let normal = Theme.Size.button(device)
        return tall && device != .phone ? max(normal, Theme.Size.actionColumnMin) : normal
    }

    private var wordColour: Color {
        guard isEnabled else { return palette.paper3 }
        return destructive ? palette.warning : palette.paper
    }

    var body: some View {
        configuration.label
            .font(Theme.label)
            .foregroundStyle(wordColour)
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.xs)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight)
            // Pressed, the fill sinks to the strip colour: the edge stays, so the capsule keeps its outline.
            .background(configuration.isPressed ? palette.panelSunken : palette.panel, in: Capsule())
            .overlay(Capsule().strokeBorder(palette.rule, lineWidth: Theme.Size.hairline))
            .contentShape(Capsule())
            .animation(Theme.Motion.standard, value: configuration.isPressed)
    }
}

/// A worded secondary button. `title` is already localized (String(localized:)).
struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let destructive: Bool
    let fullWidth: Bool
    let tall: Bool
    let isEnabled: Bool
    let action: @MainActor () -> Void

    init(_ title: String, systemImage: String? = nil, destructive: Bool = false, fullWidth: Bool = false,
         tall: Bool = false, isEnabled: Bool = true, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.destructive = destructive
        self.fullWidth = fullWidth
        self.tall = tall
        self.isEnabled = isEnabled
        self.action = action
    }

    /// From a card's KitAction (a destructive role gives warning words).
    init(_ item: KitAction, fullWidth: Bool = false, tall: Bool = false) {
        self.init(item.title, systemImage: item.systemImage, destructive: item.isDestructive, fullWidth: fullWidth,
                  tall: tall, isEnabled: item.isEnabled, action: item.action)
    }

    var body: some View {
        Button(role: destructive ? .destructive : nil) {
            action()
        } label: {
            KitButtonLabel(title, systemImage: systemImage)
        }
        .buttonStyle(SecondaryButtonStyle(destructive: destructive, fullWidth: fullWidth, tall: tall))
        .disabled(!isEnabled)
    }
}

#Preview("Secondary, every state") {
    KitPreviewStage(device: .big) {
        SecondaryButton("Try again") {}
        SecondaryButton("Watch a way out", systemImage: "play") {}
        SecondaryButton("Try again") {}.disabled(true)
        SecondaryButton("Delete", systemImage: "trash", destructive: true) {}
        SecondaryButton("Delete", destructive: true, isEnabled: false) {}
        SecondaryButton("Try again", fullWidth: true) {}
        HStack(spacing: Theme.Space.sm) {
            SecondaryButton("Try again", tall: true) {}
            PrimaryButton("Shoot", tall: true) {}
        }
    }
}

#Preview("Secondary, phone") {
    KitPreviewStage(device: .phone) {
        HStack(spacing: Theme.Space.sm) {
            SecondaryButton("Try again", fullWidth: true) {}
            PrimaryButton("Next", fullWidth: true) {}
        }
        SecondaryButton("Delete", destructive: true) {}
    }
}
