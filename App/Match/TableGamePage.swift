// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: A table's game page, pushed from its entry in the Tables list (plans/21-Nov-2026-other-tables-games-plan.md
//          package 5): the game the table plays, ways to play it (bar billiards alone, for a best score kept on the
//          device; practice on the table with no rules; or a match for two players), and the rules as numbered
//          steps ("How to play"), with the plain note that these games vary from place to place and this is one common
//          version. TableRulesPage is the rules alone, for the How to play sheet's Rules links.
//          Both are ordinary pages in the Tables list's NavigationStack, so on the open folding phone, iPad and Mac
//          they are pages of the notebook side panel beside the table (the Tables list is a page there), and a sheet's
//          page on a phone. Nothing here is drawn over the table.
//          Starting a match calls ShowpieceModel.startMatch(kind, players:), which ends any trick shot or situation,
//          closes the menu and puts the table's start layout on; practice is the list's existing playTable.
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the ways to play lead with the ones a person plays by
//          themselves (bar billiards alone, then Practice, highlighted); Two players comes last, plain, with a line
//          that says what the game is rather than offering to pass the device around.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 18: starting a game here while a match is saved asks
//          first, inside the page, naming the saved game (MatchMode.savedSummary, MatchWords.savedLine), instead of
//          silently throwing it away.)
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
    /// A new game was asked for while a match is saved: how many players it was for, until the player says whether
    /// to replace the saved one.
    @State private var replacingFor: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: table.summary).font(Theme.body).foregroundStyle(.secondary)
                    Text(TableGameWords.gameLine(game)).font(Theme.body)
                }
                .fixedSize(horizontal: false, vertical: true)
                if let players = replacingFor, let saved = MatchMode.savedSummary() {
                    replaceQuestion(saved, players: players)
                }
                // These tables have no computer player, so what one person can play comes first: bar billiards alone
                // (highlighted), else Practice (highlighted). Two players stays as the last, plain choice.
                VStack(spacing: 10) {
                    if game == .barBilliards {
                        playButton(String(localized: "Play alone"), line: TableGameWords.best(BarBilliardsBest.best()),
                                   symbol: "person.fill", prominent: true) { start(players: 1) }
                    }
                    playButton(String(localized: "Practice"), line: String(localized: "Knock the balls around with no turns and no score."),
                               symbol: "scope", prominent: game != .barBilliards) {
                        model.playTable(table)
                        onStarted()
                    }
                    playButton(String(localized: "Two players"), line: String(localized: "A full game with turns and a score."),
                               symbol: "person.2", prominent: false) { start(players: 2) }
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

    /// A new match of this table's game with `players` players, then hand over to the table. With a match saved (or
    /// one in play, which is saved too) the page asks first: the device keeps one saved match, and a new one would
    /// replace it.
    private func start(players: Int) {
        if model.hasSavedMatch, MatchMode.savedSummary() != nil {
            replacingFor = players
            return
        }
        begin(players: players)
    }

    private func begin(players: Int) {
        replacingFor = nil
        model.startMatch(game, players: players)
        onStarted()
    }

    /// The question, in the page itself (no alert, so on the open folding phone and big screens it stays in the side
    /// panel beside the table): which game is saved, and whether to replace it.
    private func replaceQuestion(_ saved: SavedMatchSummary, players: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "A new game replaces your saved one: \(MatchWords.savedLine(saved))"))
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            CardButtonRow {
                Button { replacingFor = nil } label: {
                    Text(String(localized: "Keep my saved game")).font(.headline).lineLimit(1)
                }
                .buttonStyle(.glass)
                .keyboardShortcut(.cancelAction)
                Button(role: .destructive) { begin(players: players) } label: {
                    Text(String(localized: "Start a new game")).font(.headline).lineLimit(1)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(palette.track.opacity(0.5)))
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
