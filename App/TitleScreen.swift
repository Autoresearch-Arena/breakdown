// Author: Claude Haiku 5.5 Medium
// Date: 18-November-2026
// PURPOSE: The title screen the app opens on. It names the app, says in plain words what Breakdown is, lists the three
//          things to do (watch the break, read the Lens, take the cue) and starts the game with one Start button. It sits
//          over the live table, dimmed, so the room stays visible behind it. It reads and writes ShowpieceModel only to
//          start the cold open (beginFromTitle). Launch switches that open a specific screen for testing skip it, so
//          the screenshots those switches take stay the same as before.
// SRP/DRY check: Pass - title and instructions only. Fonts come from Theme, colours from Palette, and the controls named
//          in the instructions are the real labels in PlaybackControls, ShotPanel and AimOverlay.
import SwiftUI

struct TitleScreen: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = 10
    /// Drives the gentle entrance; the same timing for the wordmark and the card, with the tagline a beat later.
    @State private var shown = false

    /// True when a launch switch asks for a specific screen, in which case the title stays out of the way.
    /// -noTitle is there for anyone who wants the cold open straight away.
    static var launchSkipsTitle: Bool {
        let args = ProcessInfo.processInfo.arguments
        let switches = ["-noTitle", "-yourBreakDemo", "-yourShotDemo", "-aimDemo", "-aimDemoRack", "-retryDemo"]
        return switches.contains { args.contains($0) }
    }

    private static let intro = "Breakdown is a pool game that shows its working. Every ball, bounce and spin is worked out by our own physics engine, and the Physics Lens shows what happened behind each shot."

    private static let steps: [(title: String, detail: String)] = [
        ("Watch the break",
         "The first shot plays itself at full speed. Then the table melts into the physics: the paths, the speeds, and the energy passed from ball to ball."),
        ("Read the Lens",
         "Amber paths are balls sliding and cyan paths are balls rolling. Thicker means faster, and older path fades. Drag the bar to scrub through the shot in either direction."),
        ("Take the cue",
         "Tap Your shot, then drag on the table to aim. Pull back to set the power, touch the small cue-ball picture to add spin, and tap Shoot, or Break on a fresh rack."),
    ]

    var body: some View {
        ZStack {
            // A dimmed veil over the table so the card reads clearly and the room is still there behind it.
            palette.ground.opacity(0.6).ignoresSafeArea()
            ScrollView {
                card
                    .padding(.horizontal, 16)
                    .padding(.vertical, 40)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .opacity(shown ? 1 : 0)
        .transition(.opacity)
        .onAppear {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) { shown = true }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 10) {
                // The wordmark and tagline are the title; VoiceOver reads the wordmark as the screen's heading.
                Text("BREAKDOWN")
                    .font(Theme.display)
                    .tracking(tracking)
                    .foregroundStyle(palette.paper)
                    .accessibilityAddTraits(.isHeader)
                Text("watch the physics think")
                    .font(Theme.tagline)
                    .foregroundStyle(palette.accent)
                    .opacity(shown ? 1 : 0)
                    .animation(reduceMotion ? nil : .smooth(duration: 0.8).delay(0.25), value: shown)
                Text(Self.intro)
                    .font(Theme.copy)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 18) {
                Text("How it works")
                    .font(Theme.sectionTitle)
                    .foregroundStyle(palette.paper)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                    StepRow(number: index + 1, title: step.title, detail: step.detail)
                }
            }

            Button {
                model.beginFromTitle()
            } label: {
                Text("Start")
                    .font(Theme.heading)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .foregroundStyle(palette.ground)
            .controlSize(.large)
            // Return starts the game on the Mac and with a hardware keyboard.
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
    }
}

/// One numbered instruction: a serif numeral, a heading and a sentence or two of plain words.
private struct StepRow: View {
    let number: Int
    let title: String
    let detail: String
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("\(number)")
                .font(Theme.equation)
                .foregroundStyle(palette.accent)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
                Text(detail)
                    .font(Theme.copy)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // VoiceOver reads the step as one sentence: the number is decoration, the title and detail are the content.
        .accessibilityElement(children: .combine)
    }
}
