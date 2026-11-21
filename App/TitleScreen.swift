// Author: Claude Haiku 5.5 High
// Date: 18-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (now the main menu: Play or New game, Continue, Watch the break, How to
//          play and Options, reachable again at any time from the back button on the table; the instructions moved
//          into their own sheet so the menu is short).
// Edited: Claude Opus 5.5 High, 20-November-2026 (-jumpDemo joins the launch switches that skip the menu).
// Edited: Claude Opus 5.5 High, 20-November-2026 (-rideDemo skips the menu).
// Edited: Claude Opus 5.5 High, 20-November-2026 (trick shots are now the game's purpose: "Trick shots" is the first
//          and primary choice and opens the list of shots (TrickShotList, hosted by the table layer so a launch flag can
//          open it too); Continue, Free play and Watch the break follow. Free play and Watch the break leave trick-shot
//          mode. The one-line description and the first How to play step now say what the game is for.)
// Edited: Claude Opus 5.5 High, 21-November-2026 ("Behind the 8-Ball" under Trick shots in both menus opens its list
//          (EightBallList, hosted by EightBallTableLayer); Free play, New free game and Watch the break end it too).
// Edited: Claude Opus 5.5 High, 21-November-2026 (-trickAim and -pauseAt also skip the menu, for store screenshots).
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (the one-line description always wraps in full instead of being cut
//          off with an ellipsis, the card is centred by the scroll view rather than forced to the screen's height, and
//          How to play and Options stack when there is no room for them side by side, as on a folding phone's outer
//          screen).
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo: onHowTo and onOptions let the Duo panel show the menu as
//          one of its own pages, with no dimming veil and no sheets over the table.)
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (a Tables button opens TableList: a table is a game of its own, no longer a
//          section of the Surface menu).
// Edited: Claude Opus 5.5 High, 21-November-2026 (a menu a stranger can read: ordered by what a new player should do
//          next (Continue when something is in progress, then Play, Trick shots, Behind the 8-Ball, Tables, Watch the
//          intro, How to play, Options), every entry with one short line saying what it is and, where there is
//          progress to show, a small mark (trick shots made, medals won). Play opens a short list in the card itself:
//          Continue match when a saved one exists, Practice (free play), Eight-ball and Nine-ball. "Watch the break" is
//          now "Watch the intro". How to play gains a Rules section with a page each for eight-ball and nine-ball, in
//          our own plain words.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (opponent stream: the Play list gains "Against the computer", which
//          opens a third list in the same card: a level choice (Easy, Medium, Hard) with that level's record, then
//          Eight-ball and Nine-ball against the computer. Eight-ball and Nine-ball carry a small mark of games won out
//          of games played on this device (MatchRecord). Inline in the card, so it works as the notebook panel's menu
//          page on the open Duo, iPad and Mac.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens: How to play's Rules section also links the rules
//          of bumper pool, five-pin and bar billiards, TableRulesPage.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons stream: Learn, the six lessons (LessonList), is the first entry
//          after Continue, with its progress mark (lessons passed); it is the highlighted entry for a player with nothing
//          in progress and no lesson passed yet. Practice and Watch the intro end a lesson through the model.)
// PURPOSE: The main menu the app opens on, laid over the live table, dimmed, so the room stays visible behind it. It
//          names the game, says in one line what it is, and offers, top to bottom: Continue (whatever is on the table,
//          or the saved match after a relaunch), Play (Practice, Eight-ball, Nine-ball, Continue match), Trick shots,
//          Behind the 8-Ball, Tables, Watch the intro (the showpiece opening with the slow-motion Physics Lens), How to
//          play (the three steps and the rules, in a sheet) and Options (a sheet). Learn (the lessons) comes first after
//          Continue.
//          It changes the model only through its menu methods (closeMenu, startGame, watchBreak, playTable via
//          TableList) and the match methods of the model contract (startMatch, continueSavedMatch), and the modes'
//          list switches and end(). Launch switches that open a specific screen for testing skip it, so the
//          screenshots those switches take stay as before.
// SRP/DRY check: Pass - menu and instructions only. Options live in GameSettings; fonts come from Theme, colours from
//          Palette, and the controls named in the instructions are the real labels in PlaybackControls, ShotPanel and
//          AimOverlay. Progress is read from the modes (TrickShotMode.isDone, EightBallMode.medals), never stored here.
//          The rules pages describe what the rules engine does (BreakdownRules) in words; they hold no rule logic.
import BreakdownRules
import SwiftUI

struct TitleScreen: View {
    let model: ShowpieceModel
    /// Play opens the aiming controls on the fresh rack; the screen owns that switch, so it is handed in.
    let onPlay: () -> Void
    /// On a folding phone the menu is a page of the side panel, which has its own pages for How to play and Options; the
    /// panel hands these in, and the menu then neither dims the screen nor opens sheets over the table.
    var onHowTo: (() -> Void)? = nil
    var onOptions: (() -> Void)? = nil
    var onTables: (() -> Void)? = nil
    private var inline: Bool { onHowTo != nil }
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = 10
    /// Drives the gentle entrance; the same timing for the wordmark and the card, with the tagline a beat later.
    @State private var shown = false
    @State private var howToOpen = false
    @State private var optionsOpen = false
    @State private var tablesOpen = false
    /// The Play list (Practice, Eight-ball, Nine-ball) replaces the main list inside the same card.
    @State private var playListOpen = false
    /// The against-the-computer list replaces the Play list inside the same card.
    @State private var computerListOpen = false
    /// The level picked for a game against the computer (kept while the app runs).
    @State private var computerLevel: ComputerLevel = .medium

    /// True when a launch switch asks for a specific screen, in which case the menu stays out of the way.
    /// -noTitle is there for anyone who wants the table straight away.
    static var launchSkipsTitle: Bool {
        let args = ProcessInfo.processInfo.arguments
        // -trick and -trickPlay open a trick shot on the table; -trickList is not here: its list opens over the menu.
        let switches = ["-noTitle", "-yourBreakDemo", "-yourShotDemo", "-aimDemo", "-aimDemoRack", "-retryDemo", "-jumpDemo",
                        "-rideDemo", "-trick", "-trickPlay", "-trickAim", "-pauseAt"]
        return switches.contains { args.contains($0) }
    }

    private static var intro: String { String(localized: "Learn trick shots that make people stop and stare, and see the physics that makes each one work.") }

    var body: some View {
        ZStack {
            // A dimmed veil over the table so the menu reads clearly and the room is still there behind it. Inline the
            // menu has its own panel and the table beside it stays bright.
            if !inline { palette.ground.opacity(0.62).ignoresSafeArea() }
            ScrollView {
                card
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 460)
                    .frame(maxWidth: .infinity)
            }
            // Centred while it fits, scrolls when it does not. A card forced to the screen's height squeezed the
            // description down to one cut-off line.
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
        }
        .opacity(shown ? 1 : 0)
        .transition(.opacity)
        .onAppear {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) { shown = true }
        }
        // Back to the main list whenever the menu is opened again.
        .onDisappear { playListOpen = false; computerListOpen = false }
        .sheet(isPresented: $howToOpen) { HowToPlaySheet(isOpen: $howToOpen) }
        .sheet(isPresented: $optionsOpen) { OptionsSheet(isOpen: $optionsOpen) }
        .sheet(isPresented: $tablesOpen) { TableList(model: model, onChosen: onPlay, onClose: { tablesOpen = false }) }
    }

    private var card: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                // The wordmark and tagline are the title; VoiceOver reads the wordmark as the screen's heading.
                Text("BREAKDOWN")
                    .font(Theme.display)
                    .tracking(tracking)
                    .foregroundStyle(palette.paper)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Text("watch the physics think")
                    .font(Theme.tagline)
                    .foregroundStyle(palette.accent)
                    .opacity(shown ? 1 : 0)
                    .animation(reduceMotion ? nil : .smooth(duration: 0.8).delay(0.25), value: shown)
                Text(Self.intro)
                    .font(Theme.copy)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            Group {
                if computerListOpen { computerList } else if playListOpen { playList } else { mainList }
            }
            .transition(.opacity)
            .animation(reduceMotion ? nil : .snappy, value: playListOpen)
            .animation(reduceMotion ? nil : .snappy, value: computerListOpen)
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
    }

    // MARK: The main list

    /// Something to go back to: the game on the table, or after a relaunch the saved match.
    private var resumable: Bool { model.gameInProgress || model.hasSavedMatch }

    private var mainList: some View {
        VStack(spacing: 10) {
            // Continue first whenever something is in progress. Return continues on the Mac and with a keyboard.
            if model.gameInProgress {
                MenuRow(title: "Continue", line: "Back to the table, just as you left it.", symbol: "play.fill",
                        prominent: true) { model.closeMenu() }
                    .keyboardShortcut(.defaultAction)
            } else if model.hasSavedMatch {
                MenuRow(title: "Continue match", line: "Pick up your saved match where you left it.",
                        symbol: "play.fill", prominent: true) { continueMatch() }
                    .keyboardShortcut(.defaultAction)
            }
            // Learn: first after Continue (first-minute plan, package 3). For a newcomer with nothing to continue and no
            // lesson passed it is the highlighted entry; once a lesson is passed, Play takes that place again.
            MenuRow(title: "Learn", line: "Six short lessons: stop, follow, draw, cut, curve and jump.",
                    symbol: "graduationcap", prominent: learnFirst, mark: lessonMark) { model.lessonMode.listOpen = true }
                .keyboardShortcut(learnFirst ? KeyboardShortcut.defaultAction : nil)
            MenuRow(title: "Play", line: "Practise on your own, or play eight-ball or nine-ball with a friend or the computer.",
                    symbol: "circle.grid.cross", prominent: !resumable && !learnFirst) { playListOpen = true }
                .keyboardShortcut(resumable || learnFirst ? nil : KeyboardShortcut.defaultAction)
            MenuRow(title: "Trick shots", line: "Shots that make people stare, easiest first.", symbol: "wand.and.sparkles",
                    mark: trickMark) { model.trickMode.listOpen = true }
            MenuRow(title: "Behind the 8-Ball", line: "Escape the nastiest spots in eight-ball and score each way out.",
                    symbol: "8.circle.fill", mark: medalMark) { model.eightBallMode.listOpen = true }
            MenuRow(title: "Tables", line: "Other tables, each a game of its own.", symbol: "square.grid.2x2") {
                if let onTables { onTables() } else { tablesOpen = true }
            }
            MenuRow(title: "Watch the intro", line: "The opening break again, slowed down under the Physics Lens.",
                    symbol: "sparkles") {
                model.trickMode.end(); model.eightBallMode.end(); model.watchBreak()
            }
            MenuRow(title: "How to play", line: "The controls, the Lens and the rules of each game.",
                    symbol: "questionmark.circle") {
                if let onHowTo { onHowTo() } else { howToOpen = true }
            }
            MenuRow(title: "Options", line: "Sound, vibration, the aim guide and the tips.", symbol: "gearshape") {
                if let onOptions { onOptions() } else { optionsOpen = true }
            }
        }
    }

    /// Learn is the highlighted entry for a newcomer: nothing to continue and no lesson passed yet.
    private var learnFirst: Bool { !resumable && model.lessonMode.passedCount == 0 }

    /// Lessons passed out of the six.
    private var lessonMark: MenuRow.Mark {
        let passed = model.lessonMode.passedCount
        let total = Lessons.all.count
        return MenuRow.Mark(symbol: "checkmark.circle.fill",
                            text: String(localized: "\(passed)/\(total)"),
                            spoken: String(localized: "\(passed) of \(total) passed"))
    }

    /// Trick shots made out of the ones that can be played.
    private var trickMark: MenuRow.Mark {
        let mode = model.trickMode
        let playable = TrickShots.all.filter { !$0.pending }
        let made = playable.filter { mode.isDone($0) }.count
        return MenuRow.Mark(symbol: "checkmark.circle.fill",
                            text: String(localized: "\(made)/\(playable.count)"),
                            spoken: String(localized: "\(made) of \(playable.count) made"))
    }

    /// Medals won out of the situations there are.
    private var medalMark: MenuRow.Mark {
        let won = model.eightBallMode.medals.count
        let total = EightBallSituations.all.count
        return MenuRow.Mark(symbol: "medal.fill",
                            text: String(localized: "\(won)/\(total)"),
                            spoken: String(localized: "\(won) of \(total) medals won"))
    }

    // MARK: The Play list

    private var playList: some View {
        VStack(spacing: 10) {
            HStack {
                Button { playListOpen = false } label: {
                    Label("Back", systemImage: "chevron.backward")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.glass)
                .controlSize(.regular)
                Spacer(minLength: 0)
                Text("Play")
                    .font(Theme.sectionTitle)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                // Balances the Back button so the title sits in the middle.
                Color.clear.frame(width: 44, height: 1).accessibilityHidden(true)
            }
            if model.hasSavedMatch {
                MenuRow(title: "Continue match", line: "Pick up your saved match where you left it.",
                        symbol: "play.fill", prominent: true) { continueMatch() }
                    .keyboardShortcut(.defaultAction)
            }
            MenuRow(title: "Practice", line: "Your own break on a fresh rack. No turns, no fouls.", symbol: "triangle",
                    prominent: !model.hasSavedMatch) {
                model.trickMode.end(); model.eightBallMode.end(); model.startGame(); onPlay()
            }
            MenuRow(title: "Eight-ball", line: "Two players. Claim solids or stripes, clear them, then sink the 8.",
                    symbol: "8.circle", mark: recordMark(.eightBall)) { start(.eightBall) }
            MenuRow(title: "Nine-ball", line: "Two players. Always hit the lowest ball first; sink the 9 to win.",
                    symbol: "9.circle", mark: recordMark(.nineBall)) { start(.nineBall) }
            MenuRow(title: "Against the computer", line: "Eight-ball or nine-ball against a computer player of your level.",
                    symbol: "cpu") { computerListOpen = true }
        }
    }

    /// Games won out of games played of one kind on this device; no mark before the first finished game.
    private func recordMark(_ kind: MatchKind) -> MenuRow.Mark? {
        let t = MatchRecord.load().tally(kind)
        guard t.played > 0 else { return nil }
        return MenuRow.Mark(symbol: "trophy.fill", text: String(localized: "\(t.won)/\(t.played)"),
                            spoken: OpponentWords.recordSpoken(t))
    }

    // MARK: Against the computer

    private var computerList: some View {
        VStack(spacing: 10) {
            HStack {
                Button { computerListOpen = false } label: {
                    Label("Back", systemImage: "chevron.backward")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.glass)
                .controlSize(.regular)
                Spacer(minLength: 0)
                Text("Against the computer")
                    .font(Theme.sectionTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                // Balances the Back button so the title sits in the middle.
                Color.clear.frame(width: 44, height: 1).accessibilityHidden(true)
            }
            Picker(String(localized: "Level"), selection: $computerLevel) {
                ForEach(ComputerLevel.allCases, id: \.self) { level in Text(level.title).tag(level) }
            }
            .pickerStyle(.segmented)
            Text(computerLevel.line)
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(OpponentWords.levelRecord(MatchRecord.load().tally(computerLevel), level: computerLevel))
                .font(Theme.label)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            MenuRow(title: "Eight-ball", line: "You against the computer. Claim a group, clear it, sink the 8.",
                    symbol: "8.circle", prominent: true) { start(.eightBall, computer: computerLevel) }
            MenuRow(title: "Nine-ball", line: "You against the computer. Lowest ball first; sink the 9 to win.",
                    symbol: "9.circle") { start(.nineBall, computer: computerLevel) }
        }
    }

    /// A new match of the given kind. The model racks it and closes the menu; closing it here as well is harmless and
    /// keeps the table in view whatever the model does first.
    private func start(_ kind: MatchKind, computer: ComputerLevel? = nil) {
        model.trickMode.end(); model.eightBallMode.end()
        model.startMatch(kind, computer: computer)
        model.closeMenu()
        onPlay()
    }

    private func continueMatch() {
        model.trickMode.end(); model.eightBallMode.end()
        model.continueSavedMatch()
        model.closeMenu()
        onPlay()
    }
}

// MARK: One menu entry

/// A menu entry: symbol, name, one short line saying what it is, and an optional small progress mark at the end. The
/// whole row is one button; VoiceOver reads the name, then the progress, and offers the line as the hint.
private struct MenuRow: View {
    struct Mark {
        let symbol: String
        /// Short, for the eye ("3/10").
        let text: String
        /// Whole, for VoiceOver ("3 of 10 made").
        let spoken: String
    }

    let title: LocalizedStringKey
    let line: LocalizedStringKey
    let symbol: String
    var prominent = false
    var mark: Mark? = nil
    let action: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        let button = Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.heading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(line)
                        .font(Theme.body)
                        .opacity(0.75)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if let mark {
                    HStack(spacing: 4) {
                        Image(systemName: mark.symbol)
                        Text(verbatim: mark.text).monospacedDigit()
                    }
                    .font(Theme.label)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(palette.track))
                    .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .controlSize(.large)
        .accessibilityLabel(Text(title))
        .accessibilityValue(mark.map { Text(verbatim: $0.spoken) } ?? Text(verbatim: ""))
        .accessibilityHint(Text(line))
        if prominent {
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

// MARK: How to play

/// The three steps of the game, in plain words, and the rules of the two pool games, in a sheet from the menu (a page
/// of the side panel on a folding phone, which shows this same view).
struct HowToPlaySheet: View {
    @Binding var isOpen: Bool
    @Environment(\.palette) private var palette

    private static var steps: [(title: String, detail: String)] {
        [
            (String(localized: "Pick a trick shot"),
             String(localized: "Tap Trick shots and choose one. Watch it, then tap Your turn: drag on the table to aim, pull back from the white ball to set the power, touch the small cue-ball picture to add spin, and tap Shoot.")),
            (String(localized: "Read the Lens"),
             String(localized: "Tap Lens to see the physics: amber paths are balls sliding, cyan paths are balls rolling, thicker is faster. Drag the bar to scrub through the shot either way.")),
            (String(localized: "Try again"),
             String(localized: "Missed? Tap Try again. The balls go back where they were, with the same aim and power. Change one thing, shoot, and your last try stays on the table to compare.")),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    NumberedSteps(steps: Self.steps)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rules")
                            .font(Theme.sectionTitle)
                            .accessibilityAddTraits(.isHeader)
                        NavigationLink {
                            RulesPage(title: "Eight-ball", rules: RulesPage.eightBall)
                        } label: {
                            rulesLink("Eight-ball", line: "Solids, stripes and the 8.", symbol: "8.circle")
                        }
                        NavigationLink {
                            RulesPage(title: "Nine-ball", rules: RulesPage.nineBall)
                        } label: {
                            rulesLink("Nine-ball", line: "Lowest ball first, and the 9 wins.", symbol: "9.circle")
                        }
                        // The other tables' games (tables-screens): the same rules their Tables pages show.
                        NavigationLink {
                            TableRulesPage(game: .bumperPool)
                        } label: {
                            rulesLink("Bumper pool", line: "Five balls each, sunk in the far cup.", symbol: TableKind.bumperPool.symbol)
                        }
                        NavigationLink {
                            TableRulesPage(game: .fivePin)
                        } label: {
                            rulesLink("Five-pin billiards", line: "Pins, a red ball and points.", symbol: TableKind.fivePin.symbol)
                        }
                        NavigationLink {
                            TableRulesPage(game: .barBilliards)
                        } label: {
                            rulesLink("Bar billiards", line: "Holes, pegs and a clock.", symbol: TableKind.barBilliards.symbol)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("How to play")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { isOpen = false } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
    }

    private func rulesLink(_ title: LocalizedStringKey, line: LocalizedStringKey, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(palette.accent).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.heading).foregroundStyle(.primary)
                Text(line).font(Theme.body).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(palette.track.opacity(0.5)))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A numbered list of short titled paragraphs: the How to play steps and each rules page.
private struct NumberedSteps: View {
    let steps: [(title: String, detail: String)]
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
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
        }
    }
}

/// The rules of one game, in our own plain words. They describe what the match rules in BreakdownRules decide; the
/// rulings themselves come from there, never from this text.
private struct RulesPage: View {
    let title: LocalizedStringKey
    let rules: [(title: String, detail: String)]

    var body: some View {
        ScrollView {
            NumberedSteps(steps: rules).padding(24)
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    static var eightBall: [(title: String, detail: String)] {
        [
            (String(localized: "The idea"),
             String(localized: "Two players share one table. One takes the solids, 1 to 7, the other the stripes, 9 to 15. Clear your group, then sink the 8 to win.")),
            (String(localized: "The break"),
             String(localized: "A good break sinks a ball or drives at least four balls to a cushion. If it does neither, your opponent may play the table as it lies or have it racked again. Sink the cue ball on the break and your opponent places it anywhere behind the head line.")),
            (String(localized: "The 8 on the break"),
             String(localized: "Sinking the 8 on the break neither wins nor loses. The breaker chooses: put the 8 back on its spot, or rack again.")),
            (String(localized: "An open table"),
             String(localized: "After the break nobody owns a group. The first ball you call and sink on a fair shot makes its group yours.")),
            (String(localized: "Call every shot"),
             String(localized: "Before each shot, name the ball and the pocket. The game suggests the ball you are aiming at and the nearest pocket, so one tap confirms it.")),
            (String(localized: "A fair shot"),
             String(localized: "Hit one of your own balls first, or the 8 once your group is gone. Then a ball must drop or any ball must reach a cushion.")),
            (String(localized: "Fouls"),
             String(localized: "Sinking the cue ball, hitting the wrong ball first, hitting nothing, or knocking a ball off the table is a foul. Your opponent then has ball in hand: they place the cue ball anywhere.")),
            (String(localized: "Keep your turn"),
             String(localized: "Sink the ball you called and you shoot again. Miss it, or foul, and the turn passes.")),
            (String(localized: "Winning and losing"),
             String(localized: "Sink the 8 in the pocket you called once your group is gone and you win. Sink it early, in the wrong pocket, off the table, or on a foul, and you lose.")),
        ]
    }

    static var nineBall: [(title: String, detail: String)] {
        [
            (String(localized: "The idea"),
             String(localized: "Only the balls 1 to 9 are used, racked in a diamond with the 1 at the front and the 9 in the middle. Whoever sinks the 9 on a fair shot wins, whenever it happens.")),
            (String(localized: "Lowest ball first"),
             String(localized: "Every shot must hit the lowest-numbered ball on the table first. Then a ball must drop or any ball must reach a cushion.")),
            (String(localized: "No calling"),
             String(localized: "You do not name your shots: any ball that drops on a fair shot counts. The game marks the ball you must hit first.")),
            (String(localized: "Keep your turn"),
             String(localized: "Sink any ball on a fair shot and you shoot again.")),
            (String(localized: "Fouls"),
             String(localized: "A foul gives your opponent ball in hand anywhere on the table. A 9 sunk on a foul comes back to its spot.")),
            (String(localized: "Three fouls"),
             String(localized: "Three fouls in a row by the same player lose the game. The game warns you after the second.")),
        ]
    }
}
