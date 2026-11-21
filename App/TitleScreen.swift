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
// PURPOSE: The main menu the app opens on, laid over the live table, dimmed, so the room stays visible behind it. It
//          names the game, says in one line what it is, and offers: Trick shots (the list of shots to learn),
//          Continue (once something is under way), Free play (a fresh rack for your own break; New free game once a
//          game is under way), Watch the break (the showpiece opening
//          with the slow-motion Physics Lens), How to play (the three steps, in a sheet) and Options (a sheet).
//          It changes the model only through its menu methods (closeMenu, startGame, watchBreak) and the trick-shot
//          mode's list switch and end(). Launch switches that
//          open a specific screen for testing skip it, so the screenshots those switches take stay as before.
// SRP/DRY check: Pass - menu and instructions only. Options live in GameSettings; fonts come from Theme, colours from
//          Palette, and the controls named in the instructions are the real labels in PlaybackControls, ShotPanel and
//          AimOverlay.
import SwiftUI

struct TitleScreen: View {
    let model: ShowpieceModel
    /// Play opens the aiming controls on the fresh rack; the screen owns that switch, so it is handed in.
    let onPlay: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = 10
    /// Drives the gentle entrance; the same timing for the wordmark and the card, with the tagline a beat later.
    @State private var shown = false
    @State private var howToOpen = false
    @State private var optionsOpen = false

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
            // A dimmed veil over the table so the menu reads clearly and the room is still there behind it.
            palette.ground.opacity(0.62).ignoresSafeArea()
            ScrollView {
                card
                    .padding(.horizontal, 16)
                    .padding(.vertical, 40)
                    .frame(maxWidth: 460)
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.vertical, alignment: .center) { h, _ in h }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .opacity(shown ? 1 : 0)
        .transition(.opacity)
        .onAppear {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) { shown = true }
        }
        .sheet(isPresented: $howToOpen) { HowToPlaySheet(isOpen: $howToOpen) }
        .sheet(isPresented: $optionsOpen) { OptionsSheet(isOpen: $optionsOpen) }
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
                    .padding(.top, 2)
            }

            VStack(spacing: 12) {
                // The game's purpose first: the list of trick shots, in a sheet over the menu.
                if model.gameInProgress {
                    menuButton("Trick shots", symbol: "wand.and.sparkles", prominent: true) { model.trickMode.listOpen = true }
                    menuButton("Behind the 8-Ball", symbol: "8.circle.fill", prominent: false) { model.eightBallMode.listOpen = true }
                    menuButton("Continue", symbol: "play.fill", prominent: false) { model.closeMenu() }
                        // Return continues on the Mac and with a hardware keyboard.
                        .keyboardShortcut(.defaultAction)
                    menuButton("New free game", symbol: "triangle", prominent: false) {
                        model.trickMode.end(); model.eightBallMode.end(); model.startGame(); onPlay()
                    }
                } else {
                    menuButton("Trick shots", symbol: "wand.and.sparkles", prominent: true) { model.trickMode.listOpen = true }
                        .keyboardShortcut(.defaultAction)
                    menuButton("Behind the 8-Ball", symbol: "8.circle.fill", prominent: false) { model.eightBallMode.listOpen = true }
                    menuButton("Free play", symbol: "play.fill", prominent: false) {
                        model.trickMode.end(); model.eightBallMode.end(); model.startGame(); onPlay()
                    }
                }
                menuButton("Watch the break", symbol: "sparkles", prominent: false) { model.trickMode.end(); model.eightBallMode.end(); model.watchBreak() }
                HStack(spacing: 12) {
                    menuButton("How to play", symbol: "questionmark.circle", prominent: false) { howToOpen = true }
                    menuButton("Options", symbol: "gearshape", prominent: false) { optionsOpen = true }
                }
            }
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private func menuButton(_ title: LocalizedStringKey, symbol: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        let button = Button(action: action) {
            Label(title, systemImage: symbol)
                .font(Theme.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 30)
        }
        .controlSize(.large)
        if prominent {
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

/// The three steps of the game, in plain words, in a sheet from the menu.
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
                    ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
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
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
    }
}
