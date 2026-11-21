// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: A table's game page, pushed from its entry in the Tables list (plans/21-Nov-2026-other-tables-games-plan.md
//          package 5): the game the table plays, ways to play it (a match for two players; bar billiards also alone,
//          for a best score kept on the device; or practice on the table with no rules), and the rules as numbered
//          steps ("How to play"), with the plain note that these games vary from place to place and this is one common
//          version. TableRulesPage is the rules alone, for the How to play sheet's Rules links.
//          Both are ordinary pages in the Tables list's NavigationStack, so on the open folding phone, iPad and Mac
//          they are pages of the notebook side panel beside the table (the Tables list is a page there), and a sheet's
//          page on a phone. Nothing here is drawn over the table.
//          Starting a match calls ShowpieceModel.startMatch(kind, players:), which ends any trick shot or situation,
//          closes the menu and puts the table's start layout on; practice is the list's existing playTable.
// SRP/DRY check: Pass - checked TitleScreen's HowToPlaySheet and RulesPage (the pool games' rules; their step list is
//          private to that file, so this page draws its own numbered list in the same style) and TableList (the rows;
//          it pushes this page). The words are TableGameWords; the best score is BarBilliardsBest.
import BreakdownRules
import SwiftUI

struct TableGamePage: View {
    let model: ShowpieceModel
    let table: TableKind
    let game: MatchKind
    /// Called once play has started (the Tables list opens the aiming controls and closes itself).
    let onStarted: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: table.summary).font(Theme.body).foregroundStyle(.secondary)
                    Text(TableGameWords.gameLine(game)).font(Theme.body)
                }
                .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 10) {
                    playButton(String(localized: "Two players"), line: String(localized: "Take turns on one device."),
                               symbol: "person.2.fill", prominent: true) { start(players: 2) }
                    if game == .barBilliards {
                        playButton(String(localized: "Play alone"), line: TableGameWords.best(BarBilliardsBest.best()),
                                   symbol: "person.fill", prominent: false) { start(players: 1) }
                    }
                    playButton(String(localized: "Practice"), line: String(localized: "Knock the balls around with no turns and no score."),
                               symbol: "scope", prominent: false) {
                        model.playTable(table)
                        onStarted()
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to play")
                        .font(Theme.sectionTitle)
                        .accessibilityAddTraits(.isHeader)
                    TableRulesSteps(game: game)
                }
            }
            .padding(24)
        }
        .navigationTitle(Text(verbatim: table.title))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// A new match of this table's game with `players` players, then hand over to the table.
    private func start(players: Int) {
        model.startMatch(game, players: players)
        onStarted()
    }

    private func playButton(_ title: String, line: String, symbol: String, prominent: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.title3).frame(width: 28).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.heading)
                    Text(line).font(Theme.body).opacity(0.8).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(prominent ? palette.accent.opacity(0.25) : palette.track.opacity(0.5)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// The rules of one table game on their own page (the How to play sheet links here).
struct TableRulesPage: View {
    let game: MatchKind

    var body: some View {
        ScrollView {
            TableRulesSteps(game: game).padding(24)
        }
        .navigationTitle(Text(MatchWords.title(game)))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The rules as numbered steps, then the note that this is one version of a game played many ways.
struct TableRulesSteps: View {
    let game: MatchKind
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(TableGameWords.steps(game).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(index + 1)")
                        .font(Theme.equation)
                        .foregroundStyle(palette.accent)
                        .frame(width: 24, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title).font(Theme.heading)
                        Text(step.detail)
                            .font(Theme.copy)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                // VoiceOver reads the step as one sentence: the number is decoration.
                .accessibilityElement(children: .combine)
            }
            Text(TableGameWords.oneVersion)
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
