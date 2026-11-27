// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3 part A review: the surface is the system thin
//          material, and the regular material under Increase Contrast, as the design language's surfaces table says,
//          instead of the glass effect. The identity and namespace parameters are kept so callers compile, but draw nothing
//          now: a morph between two places needs the glass effect, which this style no longer uses.)
// PURPOSE: The glass floating-control style (design language, "Surfaces": glass is for small controls over the 3D
//          table only: Back, Menu, Zoom, Share, the mode pills, playback on the phone). A capsule of the system's thin
//          material (the regular material under Increase Contrast; the system makes either near opaque under Reduce
//          Transparency) with paper words in the label style, at least 44 points high, an optional leading outline
//          icon. The glassID and namespace parameters are accepted and ignored (a glass morph, such as the phone bar's
//          PhoneGlassID, needs the system glass effect, which that bar keeps drawing itself). Glass never
//          holds a paragraph: the kitGlassCapsule modifier is for a one-line pill (a status word, the speed pill) and
//          nothing longer.
// SRP/DRY check: Pass - checked ShowpieceView (glass status label and round glass buttons, each styled in place),
//          WhatIfViews (system glass buttons) and Surfaces.glassCard (a glass card with a corner radius, not a capsule
//          control); this is the shared capsule control those places can move to.
import SwiftUI

/// A small control over the 3D table: glass capsule, paper words, at least 44 by 44 points.
struct GlassControlStyle: ButtonStyle {
    /// Accepted for callers written against the glass-effect version; ignored by the material surface.
    var glassID: String? = nil
    var namespace: Namespace.ID? = nil

    func makeBody(configuration: Configuration) -> some View {
        GlassControlBody(configuration: configuration, glassID: glassID, namespace: namespace)
    }
}

extension ButtonStyle where Self == GlassControlStyle {
    /// The glass floating-control style.
    static var kitGlass: GlassControlStyle { GlassControlStyle() }
}

private struct GlassControlBody: View {
    let configuration: ButtonStyleConfiguration
    let glassID: String?
    let namespace: Namespace.ID?
    @Environment(\.palette) private var palette
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(Theme.label)
            .foregroundStyle(isEnabled ? palette.paper : palette.paper3)
            .padding(.horizontal, Theme.Space.md)
            .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .kitGlassSurface(glassID: glassID, namespace: namespace)
    }
}

extension View {
    /// A one-line pill on glass over the table (a status word, the speed pill): the glass capsule with paper words and
    /// the chip padding. Not for paragraphs; words live in the panel.
    func kitGlassCapsule(glassID: String? = nil, namespace: Namespace.ID? = nil) -> some View {
        modifier(GlassCapsuleText(glassID: glassID, namespace: namespace))
    }

    /// The material capsule itself. Kit-internal; screens use the style or kitGlassCapsule. The identity is not
    /// applied: a material has no morph, and a matched-geometry move would clash when both ends are on screen.
    fileprivate func kitGlassSurface(glassID: String?, namespace: Namespace.ID?) -> some View {
        modifier(GlassSurface(glassID: glassID, namespace: namespace))
    }
}

/// The thin material capsule, the regular material under Increase Contrast (design language, "Ground and surfaces").
private struct GlassSurface: ViewModifier {
    let glassID: String?
    let namespace: Namespace.ID?
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.background(contrast == .increased ? Material.regularMaterial : Material.thinMaterial, in: Capsule())
    }
}

private struct GlassCapsuleText: ViewModifier {
    let glassID: String?
    let namespace: Namespace.ID?
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .font(Theme.label)
            .foregroundStyle(palette.paper)
            .lineLimit(1)
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, Theme.Space.xs)
            .kitGlassSurface(glassID: glassID, namespace: namespace)
    }
}

/// A worded glass control ("Back", "Menu", "Zoom", "Share"): every glass control carries its word, an outline icon may
/// lead it. `title` is already localized (String(localized:)).
struct GlassControl: View {
    let title: String
    let systemImage: String?
    let isEnabled: Bool
    let glassID: String?
    let namespace: Namespace.ID?
    let action: @MainActor () -> Void

    init(_ title: String, systemImage: String? = nil, isEnabled: Bool = true, glassID: String? = nil,
         namespace: Namespace.ID? = nil, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.glassID = glassID
        self.namespace = namespace
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            KitButtonLabel(title, systemImage: systemImage)
        }
        .buttonStyle(GlassControlStyle(glassID: glassID, namespace: namespace))
        .disabled(!isEnabled)
    }
}

#Preview("Glass, every state") {
    ZStack {
        // A cloth-like backdrop so the glass has something to bend; the real one is the 3D table.
        LinearGradient(colors: [Color(red: 0.05, green: 0.30, blue: 0.24), Color(red: 0.02, green: 0.12, blue: 0.10)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(spacing: Theme.Space.xs) {
                GlassControl("Back", systemImage: "chevron.backward") {}
                GlassControl("Menu") {}
                GlassControl("Zoom", systemImage: "plus.magnifyingglass") {}
                GlassControl("Share", systemImage: "square.and.arrow.up") {}
            }
            GlassControl("Zoom", isEnabled: false) {}
            Text(verbatim: "2.61 m/s").kitGlassCapsule()
        }
        .padding(Theme.Space.lg)
    }
    .modifier(PaletteProvider())
    .preferredColorScheme(.dark)
}
