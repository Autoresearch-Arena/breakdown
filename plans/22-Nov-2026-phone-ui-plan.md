<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: The plan for redesigning Breakdown's regular-iPhone layout, for a new session to carry out. Part 1 is the
         Boss's own notes, in his words, with his screenshots. Part 2 is what the phone screen is made of today (read in
         the code). Part 3 is the design: principles, the one text component, and every screen state. Part 4 is the
         order of work, each step with what done looks like and how it is checked. Design first, then build; no hacking.
SRP/DRY check: Pass - checked plans/ (the 0.7.6 phone plan fixed bugs inside the existing cards; its "fixed room"
         explanation card is what the Boss rejected, and this replaces it on the phone) and the 0.7.6 code on branch
         claude/iphone-layout-overlap-7f3f27.
-->
# The phone UI: a plan

## Part 1. The Boss's notes

All from 22 November 2026, in his words (lightly trimmed of swearing only where it carries no meaning). His screenshots
are in plans/images/.

### On 0.7.5, his iPhone (plans/images/22-Nov-2026-075-throw-card.png, ...-path-bends-card.png)

- "I'm still noticing a few issues in the most recent build with overlapping stuff on a regular iPhone."
- "The new player experience is not good. Things happen way too fast and we're not zooming in enough on the action on
  the screen. We're showing the whole table, but we're not coming in to show the action when we need to."
- What the shots show: the explanation card climbs over the near end of the table; its words squeezed into a narrow
  column beside Continue; the event's ring and its "Throw" / "The path bends" label drawn half over the card and right
  across its words; under it a trick card ("The Called Break / Hard / Your turn") that is mostly empty glass; then the
  playback row and three big buttons. The table is a third of the screen and the moment is a few points wide.

### On what the explanations are for

- "We don't want to necessarily say less. We do want the plain language sentence, but we want it to look good. We want
  to highlight some of the physics, or at least show the player that this game is physics, or this app is physics
  central. That's what I really want to be showing: what's going on."
- "On the phone, sometimes they're going to have to cull some of the text or show that it's a dot that you can tap and
  see it. We really don't want to shortchange the graphics here on the phone, either, like the balls rolling and vectors
  and stuff."

### On the roll-along (Ride) camera

- "When we go to do that roll-along camera, it's not good right now. We don't know what we're seeing exactly or from
  what point of view we're seeing it from. If we're going to show off the roll-along camera, we want it to be very clear
  to the player what's happening: we're switching from the view of you making the shot overhead on the table to how the
  balls are actually rolling and what happens when the balls hit each other." (Plan: plans/22-Nov-2026-ride-handover-plan.md.)

### On the 0.7.6 attempt (plans/images/22-Nov-2026-076-red-boxes.png, his red boxes)

The frame is The Called Break's Lens replay stopped on "Pocketed" on the iPhone 17 simulator: the table cut to a strip at
the top, then an explanation card with a bar for "ΔKE → 0", a title line, one sentence and empty space, then the trick
card's "The idea" paragraph, then the playback row and the buttons. His red boxes are on every empty area inside the
cards and on the space the table lost.

- "This bar with the physics says 'delta KE goes to zero.' That doesn't need all of the screen space that you're
  assigning to it. It has a whole black bar blacking out the middle of the screen to give me five characters. Same thing
  with pocketed. Same thing with the three ball drops in at blah blah blah, and then you've got all that dead space."
- "This is the center of the screen where we should be seeing the action. This entire iPhone layout is wrong."
- "These cards that you've got need to be dynamic. Rather, they need to not be cards. This yellow card needs to not be a
  card. It needs to be tiny bits of modular text that we can slot in anywhere, that can appear as a tiny little blurb
  that doesn't need a card that takes up... this looks like a fifth of the screen space at the center of the screen."
- "You need to write an actual plan before you go hacking at the UI. Not random hacking."

### On working with him (applies to whoever does this)

- Decide and do the work; no choice buttons or "this or that?" menus at the end of a turn.
- He tests on a regular iPhone 17 Pro; check on the same size yourself (the iPhone 17 simulator is the same 402 x 874
  points). Do not go overboard on a small part of what he says; do exactly what he asked.

## Part 2. What the phone screen is made of today (0.7.6 branch)

Everything below is in App/ShowpieceView.swift unless named. A phone held upright is the `stage` with a full-bleed 3D
table (TableStage) and SwiftUI floating over it:

- Title row (ScreenHeader): back button, the status title slot (stageTitle), the Lens key chip (LensLegendChip, "Physics
  Lens / Sliding / Rolling"), the menu button.
- Bottom stack (bottomStack), top to bottom:
  - CaptionStrip (App/CaptionViews.swift): the explanation card. In 0.7.6 a FIXED ROOM (equation line, two title lines,
    four detail lines) with Continue on the title line and page dots. This is the card in the red-box frame.
  - A scrolling column of mode cards, each a full-width glass card: WhatIfCard (App/WhatIfViews.swift), ComparisonCard,
    OpeningCard (the first minute's instruction), TrickShotCard (App/TrickShotViews.swift, with "The idea"), LessonCard
    (App/Lessons/LessonViews.swift), EightBallCard (App/EightBall/EightBallViews.swift), PlayCards (App/FreePlayViews.swift
    and App/Match/MatchViews.swift: ball in hand, table cleared, the match card), StrokeCards (App/Stroke/StrokeViews.swift),
    ContactArrivalLine (App/RetryWords.swift).
  - ShotPanel (App/ShotPanel.swift), Your shot's aiming controls, pinned under the cards.
  - PlaybackControls (App/PlaybackControls.swift): play/pause, scrub bar, speed, replay, What if; then Physics Lens, Ride
    and Your shot as large capsules (two rows on a phone).
- Over the table: CaptionLeader (App/CaptionViews.swift: the event ring and its title chip), the Lens callout tips
  (App/LensCallouts.swift), the trick/lesson/8-ball/play table layers, the aim overlay.
- The camera (App/TableCamera.swift, App/CameraFraming.swift) fits the whole table between the title row's bottom and the
  bottom stack's MEASURED top, so every point of height the stack takes is taken from the table. The 0.7.6 moment framing
  (App/MomentFrame.swift) zooms on the explained moment inside that same space.
- A layout flag (App/LayoutFlags.swift, lensReplayCompact) makes the mode cards show a "slim" form during a guided Lens
  replay; slim still means a full-width glass card.

What is wrong with this structure, in one line: every piece of text is a full-width card in one vertical stack under the
table, and the table gets whatever height is left. The fix is structural, not a padding change.

## Part 3. The design

### Principles (each from his notes)

1. The middle of the screen is the action's. Between the title row and a slim control strip at the bottom there is only
   the table. Nothing is stacked under the table on a phone held upright.
2. No cards for words. Words are blurbs: small, sized to their own text, placed where the action is not. No reserved
   room, no empty plate, no full-width bar for a short line.
3. Keep the plain sentence and the physics; make them look good. The figures are highlighted (colour, a monospaced
   number); long text folds behind a tap ("a dot you can tap").
4. Never shortchange the graphics: the camera comes in on the moment, and the Lens drawings stay large and clear.
5. Calm and slow enough for a newcomer: the first minute stays as it is (racked table, one instruction, a normal break).

### The one text component: Blurb

A single SwiftUI view, used for every piece of text over the table on a phone (explanations, the trick's idea, a ruling,
ball in hand, the first instruction, what-if results):

- A small rounded plate, dark and translucent with a light blur, a thin accent edge in the moment's colour; padding about
  8 points; width = its text's natural width, capped at about 70 per cent of the screen; height = its content. No
  minimum size.
- Content slots, each optional, in this order: a small bold title with an optional lead figure after it ("Throw ·
  2.1°"); up to three tiny figure chips; the sentence(s) in a small text style, at most three lines shown; the worked
  equation as one tiny italic line (Show the maths on, or a headline beat); a row of at most two small buttons (a
  ruling's Continue, "Watch it in the Lens"); a tiny "more" dot when text is folded.
- Tap: opens to the full text in place (still a blurb, taller, scrolls past about half the screen); tapping again or
  playing on closes it. While open, a held replay stays held.
- Placement is given by the caller: anchored to a table point with a short leader line; or docked to the top or bottom
  edge of the table area. A placement engine (one small function) chooses, for an anchored blurb, the side of the anchor
  with room, never over a given "keep clear" rectangle (the moment's focus, the balls it names), never under the title
  row or the control strip, and keeps it there for the whole beat (no jumping frame to frame).
- Accessibility: VoiceOver reads the full text whatever is folded; Dynamic Type grows the text, and the cap grows with it.

### The control strip

At the bottom, one compact strip: play/pause (which becomes Continue while a moment is held), the scrub bar, speed,
replay; then one row of small capsules: Lens, Ride, and the context action (Your shot, or Your turn during a trick or
lesson replay, or Continue for a waiting ruling). Your shot's aiming panel (ShotPanel) opens from it as today but is
tightened to its content. The strip's measured top is the bottom of the table's space.

### Every phone state, upright

- First minute: racked table filling the space; the instruction as a blurb docked at the top of the table area; the
  strip at the bottom. Nothing else.
- Aiming (Your shot open): the aiming panel above the strip, sized to its content; any notice (ball in hand, a stance
  hint) is a blurb at the top of the table area.
- A shot playing: only the table and the strip.
- Guided Lens replay: the moment framing centres the action; the explanation is one anchored blurb beside the moment,
  away from its focus; the trick's, lesson's or situation's name is a one-line blurb docked at the top, its idea behind a
  tap; "Your turn" is in the strip.
- Match: whose turn and the score in a one-line blurb docked at the top; a ruling as a blurb with its buttons; the call
  control (pocket, safety) as a compact blurb above the strip while calling.
- What-if: its nudge controls take the aiming panel's place above the strip; its result is a blurb.
- Ride: as plans/22-Nov-2026-ride-handover-plan.md, with its status words and table map in the title row.

### Not changing

- The open folding phone, iPad and Mac keep the notebook side panel (words beside the table, never over it).
- A phone turned sideways keeps its side column; blurbs there only where it is simple.

## Part 4. Order of work

Each step ends with screenshots on the iPhone 17 simulator (regular size) of the states it touches, compared against the
principles above, before the next step starts.

0. Look first. Capture every state above on the iPhone 17 simulator as it is now (launch flags: -trickPlay called-break,
   -pauseAt, -yourShotDemo, -aimDemo; a match from the menu). Keep them as the "before" set in plans/images.
1. Design. One mock per state (drawn over the "before" screenshots or as a simple HTML page at 402 x 874), showing exactly
   where each blurb sits and how big. Show the Boss the set once, as a picture, before building.
2. Build the Blurb component and its placement function, with unit tests for placement (never over the keep-clear
   rectangle, never under the title row or the strip, stable through a beat).
3. The explanation: replace CaptionStrip and the title chip on the upright phone with the anchored blurb; Continue moves to
   the play button; the camera's free space becomes title row to strip.
4. The mode cards (trick, lesson, Behind the 8-Ball, match, free play, opening, stroke, what-if result, contact line):
   each becomes a blurb docked or anchored as Part 3 says; delete the slim-card forms the blurbs replace.
5. The control strip and the aiming panel tightened to their content.
6. Check every state again on the iPhone 17 simulator, at the default and a large text size and in German; then the
   first minute on a fresh install. Then the open folding phone, iPad and Mac once each, to confirm they are unchanged.

## Where the code is

Branch claude/iphone-layout-overlap-7f3f27 (0.7.6, not yet pushed to main): the bug fixes from
plans/22-Nov-2026-phone-bug-hunt.md, the moment framing, readable Lens marks, pages, figures (Caption.figures), the Ride
hand-over, and the sound fix (no rolling hiss, no reverb). Build and test commands are in README.md; derived data goes on
/Volumes/Team 4TB/breakdown-build/.
