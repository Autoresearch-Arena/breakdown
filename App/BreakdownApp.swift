// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: App entry point for Breakdown on iPhone and Mac. Shows the showpiece screen full-bleed.
// SRP/DRY check: Pass - shell only. Note SwiftUI.Scene is qualified because RealityKit also defines Scene.
import SwiftUI

@main
struct BreakdownApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ShowpieceView()
                .preferredColorScheme(.dark)
        }
    }
}
