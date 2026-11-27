// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// PURPOSE: The scrub bar: a custom control (the impact ticks are the point of it) that behaves like a standard one.
//          It has a 44 point tall hit area, a thumb that grows under the pointer, a light haptic tick each time the
//          playhead crosses a recorded impact while you drag, and full VoiceOver support (a name, a spoken value,
//          swipe up and down to step, and "next impact" and "previous impact" actions). Reads the model's clock and
//          the recorded events; the only thing it writes is ShowpieceModel.scrub(to:).
// Edited: Claude Opus 5.5 High, 21-November-2026 (a pin knocked down on another table ticks like an impact).
// Edited: Claude Opus 5.5 High, 21-November-2026 (generation-two kinds: a jam brought to rest ticks like an impact, a
//          ball skipping over a hole gets a short tick in the pocket colour).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream: while a what-if shows, a violet diamond marks
//          where the two futures part, with a VoiceOver action "Where they part"; the impact tick's haptic respects
//          Vibration off; the Mac's time readout writes its decimals the way the player's language does.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif-review: Next impact, Previous impact and Where they part
//          are one list of named actions instead of two mechanisms side by side; same names, same jumps.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream what-if, bug 30 of plans/22-Nov-2026-phone-bug-hunt.md:
//          the parting diamond draws over the playhead, so it stays visible when Where they part lands on it.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, foundation: phoneStyle for the upright phone's
//          strip (PhoneStrip): unplayed rail white at 25 per cent, played rail white, no accent glow on the knob, and a
//          2-point white tick at each explained moment (the captions) instead of the coloured impact ticks, because on
//          the phone cyan and magenta mean only rolling and sliding. Touch area, haptics and VoiceOver are unchanged.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md:
//          the impact marks differ in shape as well as tint (the strike a tall line, a ball hit a dot,
//          a cushion a short line, a pocket a triangle into the hole, a rim skip a ring), plan Part A4.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit, part C: the scrub bar is
//          folded into the shot reel (App/Kit/ShotReel.swift). ScrubBar is now a thin wrapper over ShotReelTrack with the
//          same initialisers: ScrubBar(model:) draws the reel's track (the paced beats and pots as tall ticks in their
//          meaning colour, the minor events as a faint density band), ScrubBar(model:phoneStyle: true) keeps the phone
//          strip's white look. Touch area, haptics, the what-if diamond and VoiceOver are the track's, unchanged.
//          TimeReadout now writes its time with NumberStyle's scrub-bar precision, in the inline figure and grey unit.)
// SRP/DRY check: Pass - the drawing, the drag and the VoiceOver element live once, in ShotReelTrack; this file only
//          keeps the old names working for their callers (PhoneStrip, the scrub row in PlaybackControls).
import SwiftUI

/// The old scrub bar's name, kept for its callers: the shot reel's track (ShotReelTrack, App/Kit/ShotReel.swift).
struct ScrubBar: View {
    let model: ShowpieceModel
    /// The upright phone strip's look (PhoneStrip): white rail, white knob, a tick at each explained moment. Off
    /// everywhere else, which draws the reel's beat and pot ticks on a cyan played stretch.
    var phoneStyle = false

    var body: some View {
        // The old bar's sizes (a 6 point rail, a 20 point thumb) in both looks, so the phone strip is unchanged.
        ShotReelTrack(model: model, device: .big, look: phoneStyle ? .phoneStrip : .standard)
    }
}

/// The elapsed and total time next to the scrub bar, in digits that do not jitter ("1.2 / 4.8 s"); the reel's time.
struct TimeReadout: View {
    let model: ShowpieceModel

    var body: some View {
        ShotReelTime(model: model, showsTotal: true)
    }
}
