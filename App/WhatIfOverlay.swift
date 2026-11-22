// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Draws the other future of a what-if over the table: the alternate paths in violet, the ghost balls, the
//          rest rings and the marker where the two futures part. Same stored properties as GhostOverlay (the model
//          for the recordings, the bridge for the live camera). 0.7.5 foundation stub: draws nothing until the whatif
//          stream fills it; ShowpieceView mounts it only while model.whatIf.isShowing.
// SRP/DRY check: Pass - checked GhostOverlay.swift (the last try's paths) and StrokeTraceOverlay; this draws a
//          different recording and steps those two aside while it shows.
import SwiftUI

/// The other future's paths, ghosts and parting marker over the table (stub: draws nothing yet).
struct WhatIfOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    var body: some View { EmptyView() }
}
