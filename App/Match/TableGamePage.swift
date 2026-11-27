// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: each way to play is the
//          kit's list row (no tinted highlighted row), "Play the computer" carrying the chosen level as five difficulty
//          dots; the section titles are the kit's section labels; the replace question is a panel with the kit's
//          buttons (Keep my saved game the way on, Start a new game a destructive secondary); the rules' numbers are
//          plain sans in paper2, the details paper2, the spacing on the scale.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: asks to replace only this game's save; Keep
//          my saved game plays it).
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
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(verbatim: table.summary).font(Theme.body).foregroundStyle(palette.paper2)
                    Text(TableGameWords.gameLine(game)).font(Theme.body).foregroundStyle(palette.paper)
                }
                .fixedSize(horizontal: false, vertical: true)
                if let request = replacing, let saved = MatchMode.savedSummary(for: request.kind) {
                    replaceQuestion(saved, request: request)
                }
                // Bumper pool and five-pin are played against the computer; bar billiards alone against the clock;
                // every table can be practised. Two players on one device is never offered. UI rethink package 5: each
                // way to play is the kit's list row (no tinted "highlighted" row; the computer's level is its five
                // dots).
                VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                    if playsTheComputer {
                        SectionLabel(String(localized: "Against the computer"))
                            .accessibilityAddTraits(.isHeader)
                        ComputerLevelPicker(model: model, leading: true)
                        playRow(String(localized: "Play the computer"), line: recordLine,
                                level: ModeDifficulty.dots(model.computerLevel)) {
                            start(MatchStartRequest(kind: game, computer: model.computerLevel))
                        }
                    }
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        if game == .barBilliards {
                            playRow(String(localized: "Play alone"), line: TableGameWords.best(BarBilliardsBest.best())) {
                                start(MatchStartRequest(kind: game, players: 1))
                            }
                        }
                        playRow(String(localized: "Practice"),
                                line: String(localized: "Knock the balls around with no turns and no score.")) {
                            model.playTable(table)
                            onStarted()
                        }
                    }
                    .padding(.top, playsTheComputer ? Theme.Space.xs : 0)
                }
                VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                    SectionLabel(String(localized: "How to play"))
                        .accessibilityAddTraits(.isHeader)
                    TableRulesSteps(game: game)
                }
            }
            .padding(Theme.Space.lg)
        }
        .background(palette.ground)
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
    /// panel beside the table): which game is saved, and whether to replace it. Keeping it is the way on (it plays the
    /// saved game); starting anew is a destructive secondary in warning words.
    private func replaceQuestion(_ saved: SavedMatchSummary, request: MatchStartRequest) -> some View {
        // Keeping it plays it: this game's own save, picked up where it was left (0.7.5, one save per game).
        let keep = KitAction(String(localized: "Keep my saved game")) {
            replacing = nil
            if model.continueSavedMatch(kind: request.kind) { onStarted() }
        }
        return VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(String(localized: "A new game replaces your saved one: \(MatchWords.savedLine(saved))"))
                .font(Theme.body)
                .foregroundStyle(palette.paper)
                .fixedSize(horizontal: false, vertical: true)
            KitButtonRow(primary: keep,
                         secondary: KitAction(String(localized: "Start a new game"), role: .destructive) { begin(request) })
                .modeShortcut(keep, .cancelAction)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
    }

    /// One way to play as the kit's list row: its name and an optional line under it (nil draws no line, as "Play the
    /// computer" before its first finished game), with the computer's level as five dots where there is one.
    @ViewBuilder
    private func playRow(_ title: String, line: String?, level: Int? = nil,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if let level {
                ListRow(leading: .none, title: title, line: line, difficulty: { DifficultyDots(level: level) })
            } else {
                ListRow(leading: .none, title: title, line: line)
            }
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
            TableRulesSteps(game: game).padding(Theme.Space.lg)
        }
        .navigationTitle(Text(MatchWords.title(game)))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The rules as numbered steps, then the note that this is one version of a game played many ways. The numbers are
/// plain sans in paper2 (design language: list numbers are never italic serif), the step's title paper, its detail
/// paper2.
struct TableRulesSteps: View {
    let game: MatchKind
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .headline) private var numberWidth: CGFloat = Theme.Space.lg

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            ForEach(Array(TableGameWords.steps(game).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                    Text(verbatim: (index + 1).formatted(.number.locale(AppLocale.numbers)))
                        .font(Theme.heading.monospacedDigit())
                        .foregroundStyle(palette.paper2)
                        .frame(width: numberWidth, alignment: .leading)
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        Text(step.title).font(Theme.heading).foregroundStyle(palette.paper)
                        Text(step.detail)
                            .font(Theme.body)
                            .foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                // VoiceOver reads the step as one sentence: the number is decoration.
                .accessibilityElement(children: .combine)
            }
            Text(TableGameWords.oneVersion)
                .font(Theme.body)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
