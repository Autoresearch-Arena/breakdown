// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: App entry point for Breakdown on iPhone, iPad and Mac. Shows the showpiece screen, resolves the colour
//          palette for the reader's appearance and contrast settings, adds the Playback menu, and on the Mac sets a
//          sensible default and minimum window size. The scene is dark in every appearance because the table is a dark room.
// SRP/DRY check: Pass - shell only. Note SwiftUI.Scene is qualified because RealityKit also defines Scene.
import SwiftUI

@main
struct BreakdownApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ShowpieceView()
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
