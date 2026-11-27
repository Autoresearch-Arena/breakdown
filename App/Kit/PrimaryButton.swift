// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: The primary button (design language, "Buttons"): the one main action on a screen, bottom right of the
//          controls. A cyan capsule with ground-coloured words in the heading weight, 50 points high on the phone and
//          56 on big screens (taller with large text), an optional leading outline icon. `tall` makes it the action
//          column's Shoot or Break: at least 112 points high on big screens, still a capsule. Use it as a style
//          (`.buttonStyle(PrimaryButtonStyle())`, or `.buttonStyle(.kitPrimary)`) on any Button, or as the
//          PrimaryButton view that builds the worded label for you.
// SRP/DRY check: Pass - checked ShowpieceView, WhatIfViews and PhoneStrip: their main actions use the system glass
//          styles with their own sizes; none is a shared primary style. The label comes from KitButtonLabel and the
//          sizes from Theme.Size, so no value is repeated here.
import SwiftUI

/// The primary role: cyan fill, ground text, capsule. Disabled, it drops to the sunken surface with paper3 words so
/// it never looks pressable.
struct PrimaryButtonStyle: ButtonStyle {
    /// Fill the width it is offered (a button row's single action, the phone dock's right half).
    var fullWidth: Bool = false
    /// The action column's Shoot or Break: at least Theme.Size.actionColumnMin high on big screens.
    var tall: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        // A ButtonStyle struct is not handed the environment, so the look is drawn by a view that reads it.
        PrimaryButtonBody(configuration: configuration, fullWidth: fullWidth, tall: tall)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// The primary role at its normal size.
    static var kitPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
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

    var body: some View {
        configuration.label
            .font(Theme.heading)
            .foregroundStyle(isEnabled ? palette.ground : palette.paper3)
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.xs)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight)
            .background(isEnabled ? palette.accent : palette.panelSunken, in: Capsule())
            .contentShape(Capsule())
            // Pressed: a touch dimmer, not smaller, so the capsule never jumps under the finger.
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(Theme.Motion.standard, value: configuration.isPressed)
    }
}

/// A worded primary button. `title` is already localized (String(localized:)).
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let fullWidth: Bool
    let tall: Bool
    let isEnabled: Bool
    let action: @MainActor () -> Void

    init(_ title: String, systemImage: String? = nil, fullWidth: Bool = false, tall: Bool = false,
         isEnabled: Bool = true, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.fullWidth = fullWidth
        self.tall = tall
        self.isEnabled = isEnabled
        self.action = action
    }

    /// From a card's KitAction (its enabled state comes with it).
    init(_ item: KitAction, fullWidth: Bool = false, tall: Bool = false) {
        self.init(item.title, systemImage: item.systemImage, fullWidth: fullWidth, tall: tall,
                  isEnabled: item.isEnabled, action: item.action)
    }

    var body: some View {
        Button {
            action()
        } label: {
            KitButtonLabel(title, systemImage: systemImage)
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: fullWidth, tall: tall))
        .disabled(!isEnabled)
    }
}

#Preview("Primary, every state") {
    KitPreviewStage(device: .big) {
        PrimaryButton("Next") {}
        PrimaryButton("Share", systemImage: "square.and.arrow.up") {}
        PrimaryButton("Next") {}.disabled(true)
        PrimaryButton("Next", fullWidth: true) {}
        PrimaryButton("Shoot", tall: true) {}
    }
}

#Preview("Primary, phone") {
    KitPreviewStage(device: .phone) {
        PrimaryButton("Next") {}
        PrimaryButton("Next", fullWidth: true) {}
        PrimaryButton("Shoot", tall: true) {}
    }
}
