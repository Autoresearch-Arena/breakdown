// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: For each authored trick shot, the moments its guided Lens replay must stop on (plans/22-Nov-2026-v074-
//          glow-up-plan.md, F4 and stream lens-pacing): the jump's take-off and landing, the end of the masse's bend,
//          the throw contact and so on, found in whichever recording of that shot is on screen (the answer or the
//          player's own try). FOUNDATION stub: the lens-pacing stream fills the body; TrickShotMode calls it. The ids
//          "squirt" and "side-off-rail" are reserved for the two new shots of 0.7.4.
// SRP/DRY check: Pass - checked TrickShots (ids), Captions (Caption.id is the event index) and ShotHighlightJudge
//          (shares its event finders with this file; neither copies the other's).
import BreakdownLensModel
import BreakdownTimeline

enum TrickSignature {
    /// The events a trick shot's guided replay must hold on (at most two, clock order, each captioned), for the
    /// recording of that shot on screen (the answer or the player's own try). Empty when none is found.
    static func events(forTrick id: String, in timeline: Timeline, captions: [Caption]) -> [Int] { [] }
}
