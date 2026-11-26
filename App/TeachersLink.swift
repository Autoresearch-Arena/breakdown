// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: How to play's link to the page for teachers (plans/25-Nov-2026-everyone-can-play-plan.md, Part E item 3).
//          The page's words are store/pages/teachers.md; the coordinator publishes it on the studio site beside the
//          privacy and support pages, at the address below. The row opens it in the system browser (the game itself
//          still sends nothing: opening a page is the browser's, as any link is). The row says only what the page is
//          for; the address is never shown, and no person, brand or source is named.
//          Read by HowToPlaySheet (App/TitleScreen.swift).
// SRP/DRY check: Pass - checked TitleScreen's rulesLink (a row that pushes a page inside How to play; this one leaves
//          the game, so it carries an arrow out instead of a chevron and is a Link, not a NavigationLink) and the app's
//          other addresses (none: the privacy and support addresses live only in App Store Connect).
import SwiftUI

enum TeachersPage {
    /// Where store/pages/teachers.md is published, beside /breakdown/privacy and /breakdown/support.
    static let url = URL(string: "https://markbarney.net/breakdown/teachers")!
}

/// One row in How to play: "For teachers", a line under it, and an arrow out of the game.
struct TeachersLinkRow: View {
    @Environment(\.palette) private var palette

    var body: some View {
        Link(destination: TeachersPage.url) {
            HStack(spacing: 12) {
                Image(systemName: "graduationcap")
                    .font(.title3)
                    .foregroundStyle(palette.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("For teachers").font(Theme.heading).foregroundStyle(.primary)
                    Text("What the game shows a physics class, and how to use it in a lesson.")
                        .font(Theme.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(palette.track.opacity(0.5)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
        .accessibilityHint(Text("Opens the page in your browser"))
    }
}
