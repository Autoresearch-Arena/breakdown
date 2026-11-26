// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-pacing: the body filled in, every shot mapped, the two
//          new shots' ids included, read through the shared finders in ShotHighlightJudge.swift.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream pacing, plans/22-Nov-2026-v076-phone-plan.md, bug-hunt
//          entry 5: The Called Break also holds the called ball dropping (the ball its goal names), so the moment the
//          shot is about is a stop; before, only the push into the rack was, and the called ball went in unheld.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md T5: an
//          unknown id that is a saved shot of the player's own gets its moments from OwnShotSignature.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: a shot of the day built from a trick shot holds that
//          trick's own moments; its id is mapped back first, DailyShot.sourceTrickID.)
// PURPOSE: For each authored trick shot, the moments its guided Lens replay must stop on (plans/22-Nov-2026-v074-
//          glow-up-plan.md, F4 and stream lens-pacing): the jump's take-off and landing, the end of the masse's bend,
//          the throw contact and so on, found in whichever recording of that shot is on screen (the answer or the
//          player's own try). TrickShotMode passes the result to ShowpieceModel.setPaceSignature before the answer's
//          replay and before "Watch yours"; PacePlan then holds each event as a headline beat. The ids "squirt" and
//          "side-off-rail" are the two new shots of 0.7.4 (trick-shots stream), mapped here before they exist.
// SRP/DRY check: Pass - checked TrickShots (ids), Captions (Caption.id is the event index) and ShotHighlightJudge
//          (its ShotMoments finders are reused here; neither file copies the other's).
import BreakdownLensModel
import BreakdownTimeline

enum TrickSignature {
    /// The ball every trick shot strikes: trick shots are pool-only and always played with the cue ball, ball 0.
    static let cueBall = 0

    /// The events a trick shot's guided replay must hold on (at most two, clock order, each captioned), for the
    /// recording of that shot on screen (the answer or the player's own try). For a known shot whose own moments are
    /// not in this recording (a try that missed, or a beat too slow to caption), the cue ball's first hit stands in, so
    /// the replay still has its headline; empty only for an unknown id or a recording in which nothing was captioned.
    static func events(forTrick id: String, in timeline: Timeline, captions: [Caption]) -> [Int] {
        // 0.7.10 daily: "daily-stop-dead" holds Stop Dead's moments; any other id is unchanged.
        let id = DailyShot.sourceTrickID(id)
        let m = ShotMoments(timeline: timeline, captions: captions)
        let cue = cueBall
        let first = m.firstContact(of: cue)
        let firstTime = first.map { m.time($0) } ?? .infinity

        // Each shot's moments, in order of preference (ShotMoments.signature keeps the captioned ones, at most two).
        let candidates: [Int?]
        switch id {
        case "called-break":
            // The break's push into the rack, then the called ball dropping (the ball the shot's goal names; nil when it
            // did not drop in this recording, a missed try, and the push stands alone).
            let called = TrickShots.shot(id: id)?.goal.drops.first?.ball
            candidates = [first, called.flatMap { m.pocket(of: $0) }]
        case "stop-dead", "squirt":
            // The dead stop; squirt's hit, where the off-line launch shows.
            candidates = [first]
        case "bridge-draw":
            // The hit, then the moment the backspin takes hold and the cue ball rolls back.
            candidates = [first, first.flatMap { m.firstRoll(of: cue, after: $0) }]
        case "follow-train":
            // The hit, then the second ball down (the follow carried the cue ball through to it).
            let drops = m.pockets()
            candidates = [first, drops.dropFirst().first]
        case "two-rail-kick":
            // The second rail (the one that sends the cue ball to its ball), then the hit.
            let rails = m.railsBeforeFirstContact(of: cue)
            candidates = [rails.count >= 2 ? rails[1] : rails.last, first]
        case "side-off-rail":
            // The one rail the side widened the angle off, then the hit.
            candidates = [m.railsBeforeFirstContact(of: cue).first, first]
        case "cross-bank":
            // The object ball's cushion on its way to the pocket.
            let object = first.flatMap { m.other(in: $0, than: cue) }
            candidates = [object.flatMap { m.railAfterLastContact(of: $0) }]
        case "combo-chain":
            // The contact between object balls: the last one the pocketed ball took, else the first such contact.
            candidates = [objectToObjectContact(m, timeline: timeline, cue: cue)]
        case "throw-it":
            candidates = [m.throwContact()]
        case "masse-curve":
            // Where the bend ends: the curve before the hit, else the biggest bend of the shot.
            candidates = [(m.largestBend(of: cue, atOrBefore: firstTime) ?? m.largestBend(of: cue))?.event]
        case "jump-over":
            let up = m.takeOff(of: cue)
            candidates = [up, up.flatMap { m.landing(of: cue, after: $0) }]
        case "draw-masse-carom":
            // The first ball, then the second the draw-masse curve brings the cue ball back to. That second contact is
            // often too soft to caption (the cue ball arrives under the caption's 0.4 m/s gate), so the end of the
            // curve after the first hit stands in for it: the bend is what the shot is about.
            candidates = [first, m.secondContact(of: cue),
                          m.largestBend(of: cue, after: first.map { m.time($0) } ?? .infinity)?.event]
        default:
            // 0.7.7 make-it-again: a saved shot of the player's own: its first contact, then the last ball down (its
            // bank, else its drop). Read from the recording alone, so this stays a plain nonisolated call. Any other
            // unknown id still gets an empty list, as before.
            return OwnShotSignature.events(forOwn: id, in: timeline, captions: captions)
        }
        let found = m.signature(candidates)
        return found.isEmpty ? m.signature([first]) : found
    }

    /// The contact in which one object ball drove another: the last contact of a pocketed object ball that the cue ball
    /// was not part of; failing that (a try that potted nothing), the first contact between two object balls.
    private static func objectToObjectContact(_ m: ShotMoments, timeline: Timeline, cue: Int) -> Int? {
        for p in m.pockets() {
            guard let ball = timeline.events[p].balls.first?.ball, ball != cue,
                  let c = m.lastContact(of: ball, atOrBefore: m.time(p)),
                  m.other(in: c, than: ball) != cue else { continue }
            return c
        }
        return timeline.events.indices.first { i in
            let e = timeline.events[i]
            return e.kind == .ballBall && e.balls.count >= 2 && !e.balls.contains { $0.ball == cue }
        }
    }
}
