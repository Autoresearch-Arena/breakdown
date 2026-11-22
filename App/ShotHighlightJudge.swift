// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Reads a recorded shot and says which remarkable moments it had (plans/22-Nov-2026-v074-glow-up-plan.md,
//          F3 and stream lens-pacing): a jump, a curve, a thrown pot, a combination, a kick, a bank, two at once, a
//          big draw, a dead stop, a ball too fast for the pocket, a bumper into the cup, the red pin alone, or a break.
//          Pure: a recording in, a list out. FOUNDATION stub: the lens-pacing stream fills the body and keeps these
//          signatures; the model and the match call them.
// SRP/DRY check: Pass - checked Captions (the moments' captions and the bend lookup), ShotFacts (first contact, pots)
//          and TrickShotJudge (judges a trick shot's goal, not what kind of shot it was). Detection lives only here.
import BreakdownLensModel
import BreakdownTimeline

enum ShotHighlightJudge {
    /// Every remarkable moment of a recorded shot, strongest (HighlightKind.rank) first; empty for an ordinary shot. Pure.
    static func detect(timeline: Timeline, facts: ShotFacts, captions: [Caption], table: TableKind, isBreak: Bool) -> [ShotHighlight] { [] }

    /// The strongest one, or nil.
    static func judge(timeline: Timeline, facts: ShotFacts, captions: [Caption], table: TableKind, isBreak: Bool) -> ShotHighlight? {
        detect(timeline: timeline, facts: facts, captions: captions, table: table, isBreak: isBreak).first
    }
}
