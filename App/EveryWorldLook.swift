// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3, the closing sweep: the surface line colour is
//         marked for the design lint as the surfaces' own identity colours.)
// PURPOSE: The colour each playing surface's line takes in "Same shot, every surface" (0.7.7,
//          plans/23-Nov-2026-every-world-plan.md Build step 5): one normal value and one brighter value (for Increase
//          Contrast) per surface, each in the surface's own bed family (cloth green, tournament blue, dive-bar olive, ice
//          white-blue, glass silver, rubber red, cork amber-brown, carpet wine, sand yellow, Moon grey), so a line
//          reminds the player of the bed it was played on. Read by EveryWorldOverlay (the fanned paths, ghost balls and
//          symbol tags), EveryWorldViews (the chips' and rows' colour dots, the picked chip's underline) and the
//          upright phone's anchored blurb (its leader).
//          Ten hues cannot all be told apart on green cloth, and some players see colour poorly, so identity never rests
//          on hue alone: every path ends in a tag with the surface's own symbol, only one path is drawn strongly at a
//          time, and with Differentiate Without Colour the faint paths are dashed long and the strong one solid. The
//          Physics Lens's sliding magenta and rolling cyan and the what-if violet are kept clear of, so a fan line is
//          never read as a Lens mark or as the what-if's other future.
// SRP/DRY check: Pass - checked Theme (the Lens and what-if colours, kept clear of here), PlaySurfaceLook (the bed's
//          picture and finish for the 3D table; no line colours) and PlaySurface (names, summaries, symbols). No other
//          per-surface colour exists.
import SwiftUI

extension PlaySurface {
    /// The surface's line colour; `contrast` .increased gives the brighter value.
    func fanColour(_ contrast: ColorSchemeContrast) -> Color {
        let v = contrast == .increased ? fanRGB.bright : fanRGB.normal
        return Color(red: v.r, green: v.g, blue: v.b)  // design-lint: allow each surface's own line colour, defined with its normal and Increase Contrast values in fanRGB
    }

    /// Red, green and blue, 0 to 1. The brighter value is each normal one moved about 15 per cent of the way to white.
    private var fanRGB: (normal: (r: Double, g: Double, b: Double), bright: (r: Double, g: Double, b: Double)) {
        let n: (r: Double, g: Double, b: Double)
        switch self {
        case .cloth: n = (0.36, 0.80, 0.42)        // cloth green
        case .tournament: n = (0.38, 0.52, 1.0)    // tournament blue
        case .diveBar: n = (0.70, 0.72, 0.32)      // dive-bar olive
        case .ice: n = (0.86, 0.94, 1.0)           // ice white-blue
        case .glass: n = (0.66, 0.70, 0.76)        // glass silver
        case .rubber: n = (0.95, 0.32, 0.26)       // rubber red
        case .cork: n = (0.86, 0.58, 0.32)         // cork amber-brown
        case .carpet: n = (0.78, 0.30, 0.42)       // carpet wine
        case .sand: n = (0.96, 0.84, 0.50)         // sand yellow
        case .moon: n = (0.80, 0.80, 0.84)         // Moon grey
        }
        func lift(_ x: Double) -> Double { x + (1 - x) * 0.15 }
        return (n, (lift(n.r), lift(n.g), lift(n.b)))
    }
}
