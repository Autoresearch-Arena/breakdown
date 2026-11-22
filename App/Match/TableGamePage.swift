// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: A table's game page, pushed from its entry in the Tables list (plans/21-Nov-2026-other-tables-games-plan.md
//          package 5): the game the table plays, ways to play it (bumper pool and five-pin against the computer at a
//          chosen level, with the person's record at that level; bar billiards alone, for a best score kept on the
//          device; practice on the table with no rules), and the rules as numbered steps ("How to play"), with the
//          plain note that these games vary from place to place and this is one common version. TableRulesPage is the
//          rules alone, for the How to play sheet's Rules links.
//          Both are ordinary pages in the Tables list's NavigationStack, so on the open folding phone, iPad and Mac
//          they are pages of the notebook side panel beside the table (the Tables list is a page there), and a sheet's
//          page on a phone. Nothing here is drawn over the table.
//          Starting a match goes through MatchStartRequest.start(on:) (the route the main menu and the Mac's Game menu
//          use), which ends any trick shot or situation, calls ShowpieceModel.startMatch and closes the menu; the
//          match puts the table's start layout on. Practice is the list's existing playTable. The level is the
//          model's shared computerLevel (ComputerLevelPicker in TitleScreen.swift).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 menus-entries: bumper pool and five-pin get "Against the
//          computer": the level picker shared with the main menu, that level's line, and "Play the computer" with the
//          won-of-played record at that level when there is one; Practice follows, plain. A saved match is asked about
//          with the whole request (MatchStartRequest) instead of a player count.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.3: no two-player game on one device)
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
    /// A new game was asked for while a match is saved: the request, held until the player says whether to replace
    /// the saved one.
    @State private var replacing: MatchStartRequest?

    /// The games the computer plays on these tables (0.7.4). Bar billiards stays a game played alone.
    private var playsTheComputer: Bool { game == .bumperPool || game == .fivePin }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: table.summary).font(Theme.body).foregroundStyle(.secondary)
                    Text(TableGameWords.gameLine(game)).font(Theme.body)
                }
                .fixedSize(horizontal: false, vertical: true)
                if let request = replacing, let saved = MatchMode.savedSummary(for: request.kind) {
                    replaceQuestion(saved, request: request)
                }
                // Bumper pool and five-pin are played against the computer (highlighted); bar billiards alone against
                // the clock (highlighted); every table can be practised, plain. Two players on one device is never
                // offered.
                VStack(alignment: .leading, spacing: 10) {
                    if playsTheComputer {
                        Text("Against the computer")
                            .font(Theme.heading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.isHeader)
                        ComputerLevelPicker(model: model, leading: true)
                        playButton(String(localized: "Play the computer"), line: recordLine,
                                   symbol: "person.and.background.dotted", prominent: true) {
                            start(MatchStartRequest(kind: game, computer: model.computerLevel))
                        }
                    }
                    if game == .barBilliards {
                        playButton(String(localized: "Play alone"), line: TableGameWords.best(BarBilliardsBest.best()),
                                   symbol: "person.fill", prominent: true) {
                            start(MatchStartRequest(kind: game, players: 1))
                        }
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

    /// The person's record against the computer at the chosen level in this game ("2 won of 5 played"), or nil before
    /// the first finished game (MatchRecord counts only games the rules finished).
    private var recordLine: String? {
        let r = MatchRecord.record(kind: game, level: model.computerLevel)
        let played = r.won + r.lost
        guard played > 0 else { return nil }
        return String(localized: "\(r.won) won of \(played) played")
    }

    /// A new match of this table's game, then hand over to the table. With a match saved (or one in play, which is
    /// saved too) the page asks first: the device keeps one saved match, and a new one would replace it.
    private func start(_ request: MatchStartRequest) {
        if model.hasSavedMatch(request.kind) {
            replacing = request
            return
        }
        begin(request)
    }

    /// Starts it through the same route as the main menu and the Mac's Game menu (MatchStartRequest.start: any trick
    /// shot or situation ends, the match racks, the menu closes, which is harmless here), then hands over.
    private func begin(_ request: MatchStartRequest) {
        replacing = nil
        request.start(on: model)
        onStarted()
    }

    /// The question, in the page itself (no alert, so on the open folding phone and big screens it stays in the side
    /// panel beside the table): which game is saved, and whether to replace it.
    private func replaceQuestion(_ saved: SavedMatchSummary, request: MatchStartRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "A new game replaces your saved one: \(MatchWords.savedLine(saved))"))
                .font(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            CardButtonRow {
                // Keeping it plays it: this game's own save, picked up where it was left (0.7.5, one save per game).
                Button {
                    replacing = nil
                    if model.continueSavedMatch(kind: request.kind) { onStarted() }
                } label: {
                    Text(String(localized: "Keep my saved game")).font(.headline).lineLimit(1)
                }
                .buttonStyle(.glass)
                .keyboardShortcut(.cancelAction)
                Button(role: .destructive) { begin(request) } label: {
                    Text(String(localized: "Start a new game")).font(.headline).lineLimit(1)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(palette.track.opacity(0.5)))
    }

    /// One way to play as a full-width button: symbol, name and an optional line under it (nil draws no line, as
    /// "Play the computer" before its first finished game).
    private func playButton(_ title: String, line: String?, symbol: String, prominent: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.title3).frame(width: 28).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.heading)
                    if let line {
                        Text(line).font(Theme.body).opacity(0.8).fixedSize(horizontal: false, vertical: true)
                    }
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
