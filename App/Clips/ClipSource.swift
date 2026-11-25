// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9: a clip of a shot with no highlight takes the moments the
//          game's own replay holds (model.paceSignature, a trick's or a lesson's signature), so the jump's take-off and
//          its side view stay in the App Store's short clip.)
// PURPOSE: What one Lens clip is made from, and when the game offers one (0.7.7, plans/23-Nov-2026-clips-plan.md,
//          Step 3).
//          ClipSource holds plain values only (the recording, its surface and table, the struck ball, the cue's
//          follow-through, the shot's name, its signature moments, its captions and the settings record), so the game
//          can move on while the clip renders: nothing here points back at the live model.
//          It is also the entry point for other features: anything that holds a ShotAttempt (an achievement's replay,
//          a list row) calls ClipMaker.shared.start(ClipSource(attempt:title:signature:modeUsesBridge: false),
//          shape: .standard). Nothing here reads another feature's types.
//          ClipOffer answers, from the model's stored state, whether a clip is offered now. Views, menus, the Mac's
//          menu items and the phone's primary action call its cheap checks (available, isWhatIf, bestShotAvailable,
//          afterWatch) every time they draw; a ClipSource (which may build every caption of the recording) is only built
//          inside start, on a tap. Nothing is offered during the first minute (the opening), behind the menu, while a
//          shot is solving or while a clip is being made, and nothing is ever started without a tap.
// SRP/DRY check: Pass - reuses CaptionEngine.make (the same call ShowpieceModel.load makes), TableStage.stroke(of:) for
//          the follow-through, HighlightWords and WhatIfWords for the names, and the model's own state for every rule;
//          the clip itself is made by ClipMaker.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

struct ClipSource {
    let timeline: Timeline
    let surface: PlaySurface
    let table: TableKind
    /// The struck ball (the Ride camera and the captions' ball names follow it).
    let striker: Int
    /// The strike that was solved, when known (the captions read a raised cue's angle from it).
    let strike: CueStrike?
    /// The cue's follow-through at the start of the clock.
    let stroke: CueStroke
    /// The shot's name for the end card ("Bank shot", "What if"), already translated; nil for an ordinary shot.
    let title: String?
    /// Event indices the shot is about (its highlight's signature), held as headline beats.
    let signature: [Int]
    /// One caption per explained event, in the game's language.
    let captions: [Caption]
    /// The settings record, a candidate until ClipMaker has re-solved it and found the same motion.
    let record: ClipShotRecord?
    /// The attempt's motion fingerprint, for that check; nil when there is no attempt.
    let motionHash: UInt64?
    /// The attempt itself, when there is one (the record check fingerprints the re-solved recording with it).
    let attempt: ShotAttempt?

    /// A clip of a kept attempt. `captions`: pass the model's own when the attempt is the recording on screen (they
    /// were built for exactly it); nil builds them here with the same call the model's load makes.
    /// Built only when the player taps a start, never while a view is drawn: building captions walks every event.
    init(attempt: ShotAttempt, title: String?, signature: [Int], modeUsesBridge: Bool, captions: [Caption]? = nil) {
        timeline = attempt.timeline
        surface = attempt.surface
        table = attempt.table
        striker = attempt.input.strike.ballIndex
        strike = attempt.input.strike
        stroke = TableStage.stroke(of: attempt, modeUsesBridge: modeUsesBridge)
        self.title = title
        self.signature = signature
        self.captions = captions ?? CaptionEngine.make(from: attempt.timeline, surface: attempt.surface,
                                                       strike: attempt.input.strike, table: attempt.table,
                                                       striker: attempt.input.strike.ballIndex)
        record = ClipShotRecord(attempt: attempt)
        motionHash = attempt.motionHash
        self.attempt = attempt
    }

    /// A clip of a recording with no attempt behind it (the opening's showpiece break, for the self-test): a level cue
    /// through the centre, the struck ball read from the recording's own cue strike, and no settings record.
    /// `signature`: the moments to hold as headlines (the self-test passes the game's own, so a trick filmed for the
    /// App Store keeps the trick's moments, 0.7.9).
    init(timeline: Timeline, surface: PlaySurface, table: TableKind, title: String?, signature: [Int] = []) {
        self.timeline = timeline
        self.surface = surface
        self.table = table
        let struck = timeline.events.first { $0.kind == .cueStrike }?.balls.first?.ball ?? 0
        striker = struck
        strike = nil
        stroke = CueStroke()
        self.title = title
        self.signature = signature
        captions = CaptionEngine.make(from: timeline, surface: surface, table: table, striker: struck)
        record = nil
        motionHash = nil
        attempt = nil
    }
}

/// When the game offers a clip, read by every start: the round share button, the More menu rows, the cards' buttons,
/// the phone's primary action and the Mac's Playback menu.
@MainActor
enum ClipOffer {
    /// The shot a clip would be made of now, and whether it is a what-if's other future. Nil while a clip is being
    /// made, behind the menu, during the opening (the calm first minute offers nothing) and while a shot is solving.
    /// Reads stored state only.
    private static func attempt(_ m: ShowpieceModel) -> (attempt: ShotAttempt, whatIf: Bool)? {
        guard !ClipMaker.shared.isMaking, !m.menuOpen, m.openingStage == .none, !m.isSolving else { return nil }
        // A what-if showing its result: the other future is the shot to share.
        if m.whatIf.isShowing, let other = m.whatIf.result?.alternate { return (other, true) }
        // Otherwise the player's own shot on screen, once its balls are at rest.
        if m.aimReady, m.playerShotOnScreen, let shot = m.currentAttempt { return (shot, false) }
        return nil
    }

    /// True when a clip of the shot on screen (or the other future) is offered now. A still table (a re-rack, a laid
    /// out position) has nothing to explain: the same test PacePlan makes before it holds any moment.
    static func available(_ m: ShowpieceModel) -> Bool {
        guard let a = attempt(m) else { return false }
        return a.attempt.timeline.duration > 0.3
    }

    /// True when the offered clip is a what-if's other future (the menu rows say so).
    static func isWhatIf(_ m: ShowpieceModel) -> Bool { attempt(m)?.whatIf == true }

    /// The clip's source, built on a tap. The other future: named "What if", no signature, captions built here. The
    /// shot on screen: named after its highlight when it had one, with its signature, and the model's own captions
    /// (already built for exactly this recording, so nothing is worked out twice).
    static func source(_ m: ShowpieceModel) -> ClipSource? {
        guard available(m), let a = attempt(m) else { return nil }
        if a.whatIf {
            return ClipSource(attempt: a.attempt, title: WhatIfWords.title, signature: [], modeUsesBridge: false)
        }
        let highlight = m.highlightOnScreen
        // No highlight (a trick shot or a lesson): the moments the game's own replay holds (0.7.9). Without them a
        // short clip, the App Store's above all, let the jump over a blocker's take-off go to fit its time.
        return ClipSource(attempt: a.attempt, title: highlight.map { HighlightWords.title($0.kind) },
                          signature: highlight?.signatureEvents ?? m.paceSignature, modeUsesBridge: m.strokeUsesBridge,
                          captions: m.captions)
    }

    /// True when the cleared table offers "Share your best shot".
    static func bestShotAvailable(_ m: ShowpieceModel) -> Bool {
        m.bestShotForClip != nil && !ClipMaker.shared.isMaking && m.tableCleared
    }

    /// The rack's best shot as a clip source (its captions built here: it is not the recording on screen).
    static func bestShot(_ m: ShowpieceModel) -> ClipSource? {
        guard bestShotAvailable(m), let best = m.bestShotForClip else { return nil }
        return ClipSource(attempt: best.attempt, title: HighlightWords.title(best.highlight.kind),
                          signature: best.highlight.signatureEvents, modeUsesBridge: false)
    }

    /// The upright phone's primary action after a remarkable shot: free play, its "Watch it" used or its card closed,
    /// the controls still as the shot left them, no what-if showing, and a clip available.
    static func afterWatch(_ m: ShowpieceModel) -> Bool {
        m.match == nil && m.highlightOnScreen != nil && m.highlightOnOffer == nil && m.highlightControlsUntouched
            && !m.whatIf.isShowing && available(m)
    }

    /// Make a clip of the shot on offer (a tap on any start).
    static func start(_ m: ShowpieceModel, shape: ClipShape = .standard) {
        guard let source = source(m) else { return }
        ClipMaker.shared.start(source, shape: shape)
    }

    /// Make a clip of the rack's best shot (the cleared table's button).
    static func startBestShot(_ m: ShowpieceModel, shape: ClipShape = .standard) {
        guard let source = bestShot(m) else { return }
        ClipMaker.shared.start(source, shape: shape)
    }
}
