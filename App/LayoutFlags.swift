// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Shared layout flags handed down the view tree through the environment, so a view that sets a layout state
//          (ShowpieceView) and the cards that react to it (free play, match, trick, lesson and situation cards) never
//          need to know about each other. Frozen after the 0.7.5 foundation commit: streams read and set these flags
//          but do not add to this file.
// SRP/DRY check: Pass - checked NotebookPanel.swift (inlinePages, notebookRoomy) and MacChrome.swift (showpieceModel,
//          shotPanelOpen, notebookPage); none of those carries the guided-replay compact state.
import SwiftUI

extension EnvironmentValues {
    /// True on a phone held upright while a guided Lens replay plays (ShowpieceView sets it on the bottom stack).
    /// Mode cards then show their slim form, heading and main button only, so the table keeps its height.
    @Entry var lensReplayCompact: Bool = false
}
