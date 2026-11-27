// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, foundation: phoneUpright, the upright phone's own
//          layout switch, and phoneGlassNamespace with PhoneGlassID, the one glass identity the primary action and the
//          aiming panel share so "Your shot" grows into the panel and back.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 8, the open folding phone: tableMarksOnly, the
//          table half of the open fold drawing marks only, its words moved to the top line of the notebook panel.
//          phoneGlassNamespace and PhoneGlassID are removed: the upright phone's thumb dock (package 6) dropped the
//          bottom bar's shared glass, so nothing reads them any more.)
// PURPOSE: Shared layout flags handed down the view tree through the environment, so a view that sets a layout state
//          (ShowpieceView) and the cards that react to it (free play, match, trick, lesson and situation cards) never
//          need to know about each other. Frozen after the 0.7.5 foundation commit except for the phone UI plan's
//          foundation entries below and UI rethink package 8's tableMarksOnly: streams read and set these flags but do
//          not add to this file.
// SRP/DRY check: Pass - checked NotebookPanel.swift (inlinePages, notebookRoomy) and MacChrome.swift (showpieceModel,
//          shotPanelOpen, notebookPage); none of those carries the guided-replay compact state, the upright phone
//          layout or the fold's marks-only flag.
import SwiftUI

extension EnvironmentValues {
    /// True on a phone held upright while a guided Lens replay plays (ShowpieceView sets it on the bottom stack).
    /// Mode cards then show their slim form, heading and main button only, so the table keeps its height.
    @Entry var lensReplayCompact: Bool = false
    /// True on the stage while the upright phone layout is on screen (title row, docked blurbs, the bottom bar with
    /// PhoneStrip), set by ShowpieceView. False in the notebook, the sideways column and the big-window table-only
    /// layout, which keep the shared views.
    @Entry var phoneUpright: Bool = false
    /// UI rethink package 8: true on the table half of the open folding phone (ShowpieceView sets it on the stage when
    /// a hinge splits the screen). The table layers then draw marks only: the aim line, the ghost ball, rings and the
    /// bare degree figure on the side-spin fork. Every word they would print on the cloth (the fork's "Cue aims here"
    /// and "Ball goes here", the target-ball badge, "Last try", the bridge and power pills, TablePathStroke's labels)
    /// is left off, and the notebook panel's top line (TableMarksLine in NotebookPanel.swift) says what the marks mean.
    /// Canvas layers read it from their GraphicsContext's environment, so a shared drawing helper needs no parameter.
    @Entry var tableMarksOnly: Bool = false
}
