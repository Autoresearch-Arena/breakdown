// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: App entry point for Breakdown on iPhone, iPad and Mac. Shows the showpiece screen, resolves the colour
//          palette for the reader's appearance and contrast settings, adds the Playback menu, and on the Mac sets a
//          sensible default and minimum window size. The scene is dark in every appearance because the table is a dark room.
//          Start-up (package 0.4.1): at launch it starts StartupAssets, which draws every table picture on background
//          threads while the window and the 3D view are still being set up, and it lays a cover of the room's own
//          dark colour over the window that fades away once the scene reports it is built. The launch screen is the
//          same dark colour (see the project's launch background setting), so there is no white flash and no pop: the
//          dark room simply lights up. With Reduce Motion the cover is removed with no fade.
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Mac as a Mac: one game window (a Window scene) that remembers its
//          size and place and can be made as small as the phone layout, a Settings window for Options, and the Game,
//          Shot, View, Playback and Help menus from MacChrome on both the Mac and the iPad's keyboard menu bar.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 18: one game window on iPad, as on the Mac. iPadOS has
//          no single-window scene (SwiftUI's Window is Mac-only) and the project's scene manifest is generated, so the
//          rule is kept here: the first window to appear holds the game (GameWindowClaim); any further window the
//          system opens shows a short card instead of a second game, with "Play here" (the game moves to this window)
//          and "Close this window". Two windows can never run two games that overwrite one saved match.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts item 14, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md:
//          "Play here" says what it does: the game starts here and the one in the other window ends, a saved match
//          kept to continue. The game is not carried across windows; the hint no longer says it moves.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 gamecenter: at launch GameCenter.launch signs in quietly,
//          only if a sign-in has worked before and the board is not hidden. A first launch shows no sign-in.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 2's leftover note: the two hand-written ground
//          colours are Palette.ground (the launch curtain's at standard contrast, as the launch screen); the extra iPad
//          window's notice is drawn with the kit (the title role, paper and paper2, the kit's primary Play here and
//          secondary Close this window, Theme spacing) instead of system fonts, grey and glass buttons.)
// SRP/DRY check: Pass - shell only. Note SwiftUI.Scene is qualified because RealityKit also defines Scene.
//          The colours come from Theme (palette.ground) and the timing from StartupAssets; nothing is repeated here.
import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct BreakdownApp: App {
    init() {
        StartupLog.mark("app init")
        // Draw every table picture in the background right now; the main thread carries on with the window.
        StartupAssets.shared.prewarm()
        // 0.7.10 gamecenter: a quiet sign-in for a returning player; nothing at all on a first launch.
        GameCenter.shared.launch()
    }

    var body: some SwiftUI.Scene {
        #if os(macOS)
        // The Mac has exactly one game window: a Window scene cannot be opened twice, File's New Window is removed
        // (GameCommands), and the window never turns into tabs (WindowFrameMemory). Closing it quits the game.
        Window(Text(verbatim: "Breakdown"), id: "game") {
            root
                // Small enough to reach the phone layout (a phone-width column with the controls under the table), so
                // dragging the window from its smallest to full screen passes through phone, notebook and two-column
                // notebook (NotebookGeometry); tall enough for the table above the controls.
                .frame(minWidth: 480, minHeight: 520)
                // Remembers the window's size and place between launches.
                .background(WindowFrameMemory())
        }
        .defaultSize(width: 1120, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            GameCommands()
            ShotCommands()
            ViewCommands()
            PlaybackCommands()
            HelpCommands()
        }
        // Options as the Mac's own Settings window, from the app menu with Command-comma.
        Settings {
            SettingsWindowContent()
                .modifier(PaletteProvider())
                .preferredColorScheme(.dark)
        }
        #else
        // iPhone and iPad. On iPad the system can open more than one window of the app; only one of them holds the
        // game (OneGameWindow). The menus below also fill the iPad's menu bar and hardware keyboard shortcut list.
        WindowGroup {
            OneGameWindow { root }
        }
        .commands {
            GameCommands()
            ShotCommands()
            ViewCommands()
            PlaybackCommands()
            HelpCommands()
        }
        #endif
    }

    /// The game screen with its launch cover, colours and dark room, the same in every window.
    private var root: some View {
        ShowpieceView()
            .modifier(LaunchCurtain())
            .modifier(PaletteProvider())
            .preferredColorScheme(.dark)
    }
}

#if os(iOS)
/// Which window holds the game on iPad. Shared by every window of the app process; the main actor owns it, as it
/// owns the windows.
@MainActor
@Observable
final class GameWindowClaim {
    static let shared = GameWindowClaim()
    /// The window that holds the game; nil before the first window appears and after the holder goes away.
    private(set) var holder: UUID?
    /// False until some window has held the game. Until then a window shows the game straight away (the first
    /// launch frame must be the game under its launch cover, never the notice), and claims it as it appears.
    private(set) var everHeld = false

    /// Hold the game in window `id` if no window does.
    func claimIfFree(_ id: UUID) { if holder == nil { holder = id; everHeld = true } }
    /// Move the game to window `id` ("Play here"): the window that held it shows the notice instead.
    func take(_ id: UUID) { holder = id; everHeld = true }

    /// True when window `id` should show the game: it holds it, or no window has held it yet.
    func shows(_ id: UUID) -> Bool { holder == id || (!everHeld && holder == nil) }
    /// Window `id` is going away; if it held the game, the game is free for the next window to claim.
    func release(_ id: UUID) { if holder == id { holder = nil } }
}

/// One window's content on iPad: the game when this window holds it, otherwise a short card explaining that the game
/// is in another window. Only the holding window builds a ShowpieceView, so there is only ever one model, one table
/// and one writer of the saved match. On the iPhone there is only ever one window, so it always holds the game.
private struct OneGameWindow<Game: View>: View {
    @ViewBuilder let game: Game
    /// This window's identity for the claim (one per window, kept for the window's life).
    @State private var id = UUID()
    /// The shared claim, read in body so the window redraws when it changes (it is @Observable).
    private var claim: GameWindowClaim { GameWindowClaim.shared }

    var body: some View {
        // A ZStack, not a Group: the appear and disappear hooks then belong to the window's content as a whole, not to
        // whichever child is showing (a Group would release the claim when the notice gives way to the game).
        ZStack {
            if claim.shows(id) {
                game
            } else {
                OtherWindowNotice { claim.take(id) }
            }
        }
        .onAppear { claim.claimIfFree(id) }
        // The holder went away (its window was closed): the first window still open takes the game over.
        .onChange(of: claim.holder) { _, holder in if holder == nil { claim.claimIfFree(id) } }
        .onDisappear { claim.release(id) }
    }
}

/// Shown in an extra iPad window: the game is open in another window; play here instead, or close this one.
private struct OtherWindowNotice: View {
    let playHere: () -> Void
    /// This window's scene session, found from the view's own window so "Close this window" closes this one.
    @State private var session: UISceneSession?
    /// The ground and words from the palette (the environment's default is the standard-contrast palette, so this reads
    /// right even where no PaletteProvider sits above it).
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: Theme.Space.md) {
            Text(String(localized: "One game at a time"))
                .font(Theme.title)
                .foregroundStyle(palette.paper)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "The game is open in another window. Play here instead, or close this window."))
                .font(Theme.body)
                .foregroundStyle(palette.paper2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            // The kit's buttons: Play here the one primary, Close this window the secondary under it.
            VStack(spacing: Theme.Space.sm) {
                PrimaryButton(String(localized: "Play here"), fullWidth: true, action: playHere)
                    // Says what really happens: this window builds a fresh game and the other window's ends (the game
                    // itself does not move across windows; a saved match is kept and can be continued here).
                    .accessibilityHint(String(localized: "Plays here. The game in the other window ends; a saved match can be continued."))
                if let session {
                    SecondaryButton(String(localized: "Close this window"), fullWidth: true) {
                        UIApplication.shared.requestSceneSessionDestruction(session, options: nil) { error in
                            NSLog("BreakdownApp: the extra window could not be closed: %@", error.localizedDescription)
                        }
                    }
                }
            }
            .frame(maxWidth: Theme.Size.sideColumn)
        }
        .padding(Theme.Space.xl)
        .frame(maxWidth: Theme.Size.sideColumn + 2 * Theme.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.ground.ignoresSafeArea())
        .tint(palette.accent)
        .background(SceneSessionReader { session = $0 })
    }
}

/// Reports the scene session of the window this view is in, once it is in one.
private struct SceneSessionReader: UIViewRepresentable {
    let found: @MainActor (UISceneSession?) -> Void

    func makeUIView(context: Context) -> Probe { Probe(found: found) }
    func updateUIView(_ uiView: Probe, context: Context) {}

    final class Probe: UIView {
        let found: @MainActor (UISceneSession?) -> Void
        init(found: @escaping @MainActor (UISceneSession?) -> Void) {
            self.found = found
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError("not used from a storyboard") }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            // Reported on the next turn of the main actor, not in the middle of the layout pass that moved the view,
            // so the SwiftUI state it sets is never changed while a view update is under way.
            let session = window?.windowScene?.session
            let report = found
            Task { @MainActor in report(session) }
        }
    }
}
#endif

/// A cover in the room's dark colour over the whole window until the 3D scene has been built, then a short fade to
/// reveal it. Without it the first frames show the scene half-built (balls piled where they start, the camera not yet
/// framing the table), which looked like a pop. It also takes no touches, so it can never trap input.
private struct LaunchCurtain: ViewModifier {
    @State private var gate = StartupGate.shared
    /// True once the cover should be fading out, and true once it is gone for good.
    @State private var revealing = false
    @State private var removed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The room's colour at standard contrast (Palette.ground), which the launch screen also uses. Fixed at standard
    /// rather than read from the environment, so the cover matches the launch screen's colour exactly.
    private let ground = Palette(contrast: .standard).ground

    func body(content: Content) -> some View {
        content
            .overlay {
                if !removed {
                    ground
                        .ignoresSafeArea()
                        .opacity(revealing ? 0 : 1)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: revealing)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .task(id: gate.sceneBuilt) {
                guard gate.sceneBuilt else {
                    // Safety net: if the scene never reports (it always should), do not leave the window dark for good.
                    try? await Task.sleep(for: .seconds(8))
                    gate.sceneIsBuilt()
                    return
                }
                // Let the scene draw its first few frames behind the cover, fade the cover, then drop it from the tree.
                try? await Task.sleep(for: .milliseconds(250))
                revealing = true
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 50 : 600))
                removed = true
            }
    }
}
