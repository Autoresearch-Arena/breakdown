// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: How to play's link to the page for teachers (plans/25-Nov-2026-everyone-can-play-plan.md, Part E item 3).
//          The page's words are store/pages/teachers.md; the coordinator publishes it on the studio site beside the
//          privacy and support pages, at the address below. The row opens it in the system browser (the game itself
//          still sends nothing: opening a page is the browser's, as any link is). The row says only what the page is
//          for; the address is never shown, and no person, brand or source is named.
//          Read by HowToPlaySheet (App/TitleScreen.swift).
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 7's leftover note: the row is drawn in the kit's
//          list row shape with the palette's roles (paper, paper2, paper3 on the sunken strip, small corners, Theme
//          spacing) instead of the system's primary, secondary and tertiary on a bare 14 point card; the graduation cap
//          is gone, as the rules rows above it carry no icon, and the arrow out of the game is the trailing mark.)
// SRP/DRY check: Pass - checked TitleScreen's rulesLink (a row that pushes a page inside How to play; this one leaves
//          the game, so it carries an arrow out instead of a chevron and is a Link, not a NavigationLink) and the app's
//          other addresses (none: the privacy and support addresses live only in App Store Connect).
import SwiftUI

enum TeachersPage {
    /// Where store/pages/teachers.md is published, beside /breakdown/privacy and /breakdown/support.
    static let url = URL(string: "https://markbarney.net/breakdown/teachers")!
}

/// One row in How to play: "For teachers", a line under it, and an arrow out of the game. Drawn in the kit's list row
/// shape (App/Kit/ListRow.swift: a sunken strip with small corners, the title in the heading role and paper, the line
/// in paper2, the trailing mark in paper3), so it sits with the rules rows above it; the arrow out of the game takes
/// the chevron's place, and the line wraps instead of being cut to one line, since it is the row's whole point.
struct TeachersLinkRow: View {
    @Environment(\.palette) private var palette
    private var device = KitDeviceReader()

    init() {}

    var body: some View {
        Link(destination: TeachersPage.url) {
            HStack(alignment: .center, spacing: Theme.Space.sm) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text("For teachers")
                        .font(Theme.heading)
                        .foregroundStyle(palette.paper)
                    Text("What the game shows a physics class, and how to use it in a lesson.")
                        .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.forward")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(palette.paper3)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Space.sm)
            .padding(.horizontal, Theme.Space.md)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minHit, alignment: .leading)
            .background(palette.panelSunken, in: Theme.Corner.tileShape)
            .contentShape(Theme.Corner.tileShape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
        .accessibilityHint(Text("Opens the page in your browser"))
    }
}
