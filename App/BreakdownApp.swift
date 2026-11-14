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
// SRP/DRY check: Pass - shell only. Note SwiftUI.Scene is qualified because RealityKit also defines Scene.
//          The colours come from Theme (palette.ground) and the timing from StartupAssets; nothing is repeated here.
import SwiftUI

@main
struct BreakdownApp: App {
    init() {
        StartupLog.mark("app init")
        // Draw every table picture in the background right now; the main thread carries on with the window.
        StartupAssets.shared.prewarm()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ShowpieceView()
                .modifier(LaunchCurtain())
                .modifier(PaletteProvider())
                .preferredColorScheme(.dark)
                #if os(macOS)
                // Wide enough for the table plus the caption column, tall enough for the table plus the scrub bar.
                .frame(minWidth: 760, minHeight: 560)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1120, height: 760)
        .windowResizability(.contentMinSize)
        #endif
        .commands { PlaybackCommands() }
    }
}

/// A cover in the room's dark colour over the whole window until the 3D scene has been built, then a short fade to
/// reveal it. Without it the first frames show the scene half-built (balls piled where they start, the camera not yet
/// framing the table), which looked like a pop. It also takes no touches, so it can never trap input.
private struct LaunchCurtain: ViewModifier {
    @State private var gate = StartupGate.shared
    /// True once the cover should be fading out, and true once it is gone for good.
    @State private var revealing = false
    @State private var removed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The room's colour at standard contrast, which the launch screen also uses.
    private let ground = Color(red: 0.02, green: 0.03, blue: 0.05)

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
