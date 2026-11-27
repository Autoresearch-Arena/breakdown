// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-design-language.md, "Sheet" and
//          "Surfaces"). SheetPage is the one page every sheet uses (Tables, Options, Achievements, How to play, the
//          lessons list): the ground colour behind everything (no system grouped grey), a serif title top left (the
//          title role), "Done" in cyan top right (quiet: text only, label style, 44 point hit area; the one way to
//          dismiss, always the same place), then the caller's content scrolling under it, and an optional footer in
//          caption (the version line on Options). Side margins are 24 points on big screens, 20 on the open folding
//          phone's panel and 16 on the upright phone (Theme.Space.pageMargin).
//          SheetGroup is a panel group inside it: an optional SectionLabel above (8 points to the content), then the
//          content on the panel surface (panel colour, 1 point rule edge, medium corners, card padding), the groups
//          a card gap apart.
//          Which device the kit is laid out for (KitDeviceReader): a caller that knows (the folding phone's panel,
//          a preview) sets it with .kitDevice(_:) on any ancestor; otherwise a compact width on iOS is the phone and
//          anything else (a regular width, a Mac window) is a big screen. Nothing reads the screen or the idiom, so
//          a resizable Mac window and the folding phone's postures follow their real width.
//          Read by the later packages' sheets (package 7: TableList, GameSettings, AchievementViews, How to play) and
//          by ListRow (App/Kit/ListRow.swift) for its body size.
// SRP/DRY check: Pass - checked the sheets' own NavigationStack toolbars and grouped Forms (TableList, GameSettings,
//          AchievementViews: each drew its own title and Done; package 7 moves them onto this), bandSurface
//          (App/Strike/Instrument.swift: the aiming band, padded for the band, not a sheet group) and LayoutFlags
//          (phoneUpright: set only inside the phone's play screen, so the kit cannot rely on it). No shared sheet page
//          or device reading existed.
import SwiftUI

// MARK: Which device the kit lays out for

extension EnvironmentValues {
    /// The device the kit lays out for, when a caller knows it (the folding phone's panel sets .foldPanel); nil lets
    /// the kit work it out from the width.
    @Entry var kitDevice: Theme.Device? = nil
}

extension View {
    /// Tells the kit below which device it lays out for (margins, paddings, gaps, the body size).
    func kitDevice(_ device: Theme.Device) -> some View { environment(\.kitDevice, device) }
}

/// Reads the kit's device inside a view: the one set with .kitDevice(_:), else the width's class.
struct KitDeviceReader: DynamicProperty {
    @Environment(\.kitDevice) private var chosen
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    /// The device to lay out for.
    @MainActor var current: Theme.Device {
        if let chosen { return chosen }
        #if os(iOS)
        return sizeClass == .compact ? .phone : .big
        #else
        return .big
        #endif
    }
}

// MARK: The page

/// A sheet's page: ground, serif title top left, Done top right, the content scrolling under them.
struct SheetPage<Content: View, Footer: View>: View {
    /// The page's title, already localised, in sentence case ("Options").
    let title: String
    /// Dismisses the sheet; nil uses the environment's dismiss action.
    var onDone: (() -> Void)? = nil
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    private var device = KitDeviceReader()

    init(title: String, onDone: (() -> Void)? = nil, @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.title = title
        self.onDone = onDone
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        let margin = Theme.Space.pageMargin(device.current)
        VStack(spacing: 0) {
            titleRow
                .padding(.horizontal, margin)
                .padding(.top, device.current == .phone ? Theme.Space.md : Theme.Space.lg)
                .padding(.bottom, Theme.Space.xs)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.cardGap(device.current)) {
                    content
                    // A page with no footer adds no gap under its last group.
                    if Footer.self != EmptyView.self {
                        footer
                            .font(Theme.caption)
                            .foregroundStyle(palette.paper2)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Theme.Space.xs)
                    }
                }
                .padding(.horizontal, margin)
                .padding(.top, Theme.Space.xs)
                .padding(.bottom, Theme.Space.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(palette.ground.ignoresSafeArea())
        .foregroundStyle(palette.paper)
        .tint(palette.accent)
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.md) {
            Text(verbatim: title)
                .font(device.current == .phone ? Theme.title : Theme.display)
                .foregroundStyle(palette.paper)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Theme.Space.xs)
            Button {
                if let onDone { onDone() } else { dismiss() }
            } label: {
                Text(verbatim: String(localized: "Sheet: Done", defaultValue: "Done",
                                      comment: "The button at the top right of every sheet that closes it."))
                    .font(Theme.label.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
    }
}

extension SheetPage where Footer == EmptyView {
    /// A page with no footer.
    init(title: String, onDone: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, onDone: onDone, content: content, footer: { EmptyView() })
    }
}

// MARK: A group

/// A panel group on a sheet: an optional section label, then the content on the panel surface.
struct SheetGroup<Content: View>: View {
    /// The group's label, already localised, in sentence case; drawn upper case. Nil for none.
    var label: String? = nil
    @ViewBuilder var content: Content

    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()

    init(_ label: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
            if let label { SectionLabel(label) }
            VStack(alignment: .leading, spacing: Theme.Space.sm) { content }
                .padding(Theme.Space.cardPadding(device.current))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.panel, in: Theme.Corner.cardShape)
                .overlay { Theme.Corner.cardShape.strokeBorder(palette.rule, lineWidth: Theme.Size.hairline) }
        }
    }
}

#Preview("Sheet page, big screen") {
    let palette = Palette(contrast: .standard)
    SheetPage(title: "Options", onDone: {}) {
        SheetGroup("Feel") {
            Text(verbatim: "Sound").font(Theme.body)
            Text(verbatim: "Haptics").font(Theme.body)
        }
        SheetGroup("Physics Lens") {
            Text(verbatim: "Show the notebook").font(Theme.body)
        }
        SheetGroup {
            Text(verbatim: "A group with no label.").font(Theme.body).foregroundStyle(palette.paper2)
        }
    } footer: {
        Text(verbatim: "Version 0.8.2")
    }
    .kitDevice(.big)
}

#Preview("Sheet page, phone") {
    SheetPage(title: "Tables", onDone: {}) {
        SheetGroup("Pool") {
            Text(verbatim: "Nine-foot table").font(Theme.bodyCompact)
        }
    }
    .kitDevice(.phone)
}
