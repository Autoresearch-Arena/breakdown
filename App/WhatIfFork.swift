// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The what-if replay's state (spec 4.3): one nudged copy of the player's own shot, solved beside the real one
//          on the same seed and stroke. This is the 0.7.5 foundation stub: the API below is fixed so the layouts,
//          model-flow and learn-modes streams can call it before the whatif stream fills it in. The model owns one
//          instance (ShowpieceModel.whatIf, created on first use) and closes it whenever a new recording loads.
//          It never loads its recording onto the table, never touches isSolving, and never judges or marks anything.
// SRP/DRY check: Pass - checked GhostOverlay/ShotAttempt (the last try) and TrickShotMode (the trick answer); neither
//          solves an alternate future, so this is new.
import Foundation
import Observation

/// The what-if replay (spec 4.3): one nudged copy of the player's shot, solved beside the real one. Owned by the model
/// (model.whatIf); never loads its recording onto the table, never touches isSolving, never judges or marks anything.
@MainActor @Observable final class WhatIfFork {
    /// Unowned because the model owns this fork and outlives it; a strong reference would be a retain cycle.
    @ObservationIgnored unowned let model: ShowpieceModel
    init(model: ShowpieceModel) { self.model = model }
    /// The card, the nudge controls and the other future are up.
    private(set) var isOpen = false
    /// The entry may be offered now (the button and the Mac menu item read it).
    var canOpen: Bool { false }
    /// Open and still about the recording it was opened on. Every result card steps aside while this is true.
    var isShowing: Bool { false }
    /// "Keep this one" may be offered.
    var canKeep: Bool { false }
    func open() {}
    func close() { isOpen = false }
    func keep() {}
}
