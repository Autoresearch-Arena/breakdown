<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: The plan for redesigning Breakdown's regular-iPhone layout, for a new session to carry out. Part 1 is the
         Boss's own notes, in his words, with his screenshots. Part 2 is what the phone screen is made of today (read in
         the code). Part 3 is the design: principles, the one text component, and every screen state. Part 4 is the
         order of work, each step with what done looks like and how it is checked. Design first, then build; no hacking.
Edited: Claude Opus 5.5 High, 22-November-2026 (Parts 3 and 4 rewritten after the Boss asked for Liquid Glass and an
         adversarial look: research, an inventory, three critiques, a draft and a skeptic's corrections).
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

### On Liquid Glass and the controls

- "Look at the design notes for Liquid Glass, because ideally all this should look fabulous on Liquid Glass and should
  take advantage of the Liquid Glass transparent effects."
- "This needs serious planning, because so far your UI here is just an absolute disaster. Those buttons at the bottom do
  not need to be that gigantic, and the icons you're using for them are bad. They're meaningless, pretty much. Please
  take an adversarial look at this."

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

Reference material: plans/22-Nov-2026-liquid-glass-brief.md (Apple's Liquid Glass rules and the SwiftUI calls, with
sources) and plans/22-Nov-2026-phone-ui-critiques.md (every control on the phone today with its size and icon, three
adversarial critiques of the Boss's screenshots, and the skeptic's corrections to the first draft, all applied below).

Measurements are for the regular iPhone held upright, 402 x 874 points (top safe area to 62, bottom safe area from 840).

### Principles (from the Boss's notes)

1. The middle of the screen belongs to the action. Between the title row and a slim control strip there is only the
   table.
2. No cards for words. Words are blurbs sized to their text and placed where the action is not. No reserved room, no
   empty plate, no bar for a short line.
3. Keep the plain sentence and the physics, and make them look good: figures bold and monospaced, long text folded
   behind a tappable dot.
4. Never shortchange the graphics: the camera comes in on the moment, the Lens drawings stay large.
5. Calm first minute: a racked table, one instruction, a normal-speed break. Nothing appears before it can be used.
6. Small, clear controls: every control means something at a glance (Apple: "Make sure the meaning of each control is
   clear. Don't make people guess"). App-specific ideas (Lens, Ride, Your shot) get WORDS, not invented icons. Standard
   actions (back, play, pause, replay) keep their standard symbols. Hit areas stay at least 44 points; "not gigantic"
   comes from shape and style, not from tiny targets.

### Scope: the upright phone only, beside the shared views

The notebook side panel (iPad, Mac, the open folding phone) and the sideways phone's column reuse ShotPanel,
PlaybackControls and LensLegendChip (App/NotebookPanel.swift, ShowpieceView's sideColumn). Those stay as they are. The
upright phone gets NEW phone-only views next to them: Blurb, PhoneStrip (the control strip), PhoneAimPanel, PhoneTitleRow.
"Remove" in this plan means "stop using on the upright phone", never "delete the shared view".

### Liquid Glass: what is glass and what is not

- Content, never glass: the table, the Lens drawings, the event ring, every blurb, the title text.
- Glass: the two title-row circles (back, menu), the control strip, the aiming panel (or the what-if nudge panel in its
  place). Nothing else. No glass on glass.
- Variants: the whole bottom strip and panel use REGULAR glass (they carry words), interactive. The two title circles use
  CLEAR glass with a 35 per cent black dimming layer under it while the Lens is off (the warm table is bright and busy),
  and plain clear glass while the Lens is on (the Lens view is dark).
- Use glassEffect with the interactive variant on plain buttons everywhere (not a mix of glass button styles), so unions
  and identities work the same way. Glass is the last appearance modifier; no custom backgrounds, borders or tints on
  glass, except the one primary action below.
- Grouping: the bottom strip and the aiming panel live in one GlassEffectContainer (spacing 8) inside a bottom safe-area
  bar (safeAreaBar, edge bottom). The table view ignores the safe area and runs under it; the camera frames the table
  between the title row and the bar's top, read from the bar's safe-area inset, not from a measured preference.
- Unions: play/pause and replay join as one shape; Lens and Ride join as one shape. Text and symbols never share a union.
- Morph: the primary action button and the aiming panel share one glass identity, so "Your shot" grows into the panel and
  the panel shrinks back into it. The other strip pieces fade with the materialize transition. Animate with the smooth
  animation.
- Legibility: the table is not a scroll view, so the system's scroll edge effect does nothing for it. Draw a content-
  layer gradient, black to clear, behind the title row (top 120 points) and behind the strip (bottom 160 points), so
  white labels read over any cloth. With Reduce Transparency, glass becomes opaque and the gradients stay.
- Colour: magenta and cyan mean only sliding and rolling, everywhere. The accent today is cyan (App/Theme.swift), so the
  primary action must not be cyan: it is white glass with dark text (prominent style tinted white), the only tinted
  control on screen. "Hard", "The idea" and other labels use the secondary text colour.

### The Blurb (the one text component)

- Material: thin material at least (white over green cloth needs it); regular material for opened or long text. Corner 12
  (concentric when docked near a screen corner). No border, no accent bar, no tint.
- Size: padding 10; width follows the text up to 260 (85 per cent of the width at accessibility sizes); height follows the
  content, no minimum. Nothing smaller than 11 points.
- Slots, in order, each optional: a title in subheadline semibold with the lead figure after it in bold monospaced white
  ("Throw · 2.1°"); up to three figure chips in caption monospaced (Caption.figures, already built); the sentence in
  subheadline, three lines at most; the worked equation in italic caption, only with Show the maths on or on a headline
  beat; up to two small glass buttons, only for a choice that is not the primary action; a "more" dot when text is
  folded.
- Tap: opens in place (same side of its anchor) up to 370 wide and about half the screen high, then scrolls; a held
  replay stays held while open; tap again or play to close. Appears and goes with a fade and a slight scale.
- Placement on the upright phone: ANCHORED blurbs go above or below their anchor (never beside: with the moment framed in
  the middle there is only about 185 points either side), centred on the anchor's x, kept inside a 16-point margin,
  joined by a 2-point leader over a 4-point shadow (the Lens tips' line). While an anchored blurb shows, the moment
  framing puts its focus at about 35 per cent of the table area's height so the blurb has room below. DOCKED blurbs stack
  at the top of the table area, 6 apart, in this order top down: the Lens key, a ruling or notice, the first-minute
  instruction, a Lens tip. The table framing starts below the lowest docked blurb. A blurb never moves during a beat.
- The event ring stays; its title chip goes (it repeated the blurb's title and collided with it).
- The Lens key is a one-line docked blurb (about 170 by 26): "Sliding" and "Rolling" with their glowing lines, only while
  the Lens is on. It leaves the title row.
- Accessibility: VoiceOver reads the whole text whatever is folded; Dynamic Type grows the text and the width cap.

### The title row (y 62 to 106, 16 in from each side)

- Back: the standard back chevron in a 44 clear circle at the left. No text; spoken "Back".
- Title: plain headline, one line, at most about 258 wide, shrinking to 0.8 before truncating: the trick or lesson name,
  "Break", the match's turn and score, or Ride's status words. A difficulty follows in the secondary colour ("The Called
  Break · Hard"). The title is a button (VoiceOver: button trait, hint "Shows the idea") that opens the idea blurb.
- Menu: the system "more" mark (ellipsis) in a 44 clear circle at the right, spoken "More". It holds: Surface (a submenu),
  What if, Show the maths, All trick shots or All lessons, Watch again, Show the answer's path, and, at accessibility
  sizes, anything the strip moved into it (below).
- First minute only: a "Skip" text capsule left of the menu while the opening plays.
- Ride's small table map does not fit here: it is a docked content blurb at the bottom-left above the strip (as the Ride
  hand-over plan allows), while Ride's status words take the title.

### The control strip (PhoneStrip)

Everything in one row does not fit (about 392 points needed, 370 available, before a scrub bar), so two rows:

- Scrub row (centre about y 772): the rail from x 16 to about 334, 6 high, unplayed white at 25 per cent, played white, a
  2-point tick at each explained moment, no plate, a 44-high touch area, a 20-point knob. Then speed: a regular glass
  capsule drawn 32 high with a 44 tap area, showing "Auto" or the fixed speed in monospaced text ("1×", "½×", "¼×",
  "⅒×"); no symbol (none means speed). Its menu: Auto (the calm guided pace), 1×, ½×, ¼×, ⅒×. While Auto paces a
  replay the label stays "Auto"; it never shows a rate that changes every frame.
- Button row (y about 796 to 840), at most three groups:
  - Transport (left): play.fill or pause.fill, and arrow.counterclockwise (Replay), two 44 circles in one union. While a
    guided moment is held, the play button is the way on: the play symbol, spoken "Continue".
  - Views: "Lens" and "Ride" as 44-high text capsules in subheadline semibold, no symbols, in one union. Lens on is shown
    by a 3-point underline half magenta, half cyan (the key in miniature) and the selected state ("On" for VoiceOver);
    the font weight never changes (a weight change would make the joined glass jump). Ride the same way.
  - Primary action (right-aligned): one white prominent capsule, 44 high, text only, its word plus 16 a side. It shows
    the first of these that applies: "Watch it" (a trick or lesson not yet watched), "Continue" (a match ruling waiting
    for a tap), "Your turn" (during a trick or lesson replay; it stays "Your turn" for the whole replay, so its word
    never changes under the thumb), "Try again" (after a missed attempt), "Next shot" (after a make), "Your shot" (after
    the player's own shot). Hidden while a shot is live.
- When each shows: Lens from the end of the first shot on; Ride for any finished shot whose struck ball hits another
  ball, and during a trick's or lesson's replay as today; never in the first minute before the first shot ends.
- Too wide (German at the default size, any accessibility size): move items into the title-row menu in this order: Ride,
  then Lens, then speed, the last only once the rail would be under 160 points. The primary action never shortens its
  word; transport symbols grow with the text style and stay at least 44.
- Your shot stays a toggle on the model (the controller's Y button and the what-if open and close it,
  App/ControllerInput.swift and App/WhatIfFork.swift): on the phone, at rest on your turn the panel is open; Y, or the
  "Put away" chevron, puts it away into the "Your shot" button, which brings it back.

### The aiming panel (PhoneAimPanel)

x 16 to 386, ending at the bar's top, regular glass, concentric corners, padding 12, sized to its content.

- Row 1: the tip picker (52) and the power bar filling the rest, with the power figure ("8.3 m/s") above it in headline
  monospaced and "Swing speed" in caption. The "Calm zone ends" mark stays on the bar. Minus and plus leave the row
  (the drag sets power); for VoiceOver the bar is adjustable in fixed steps.
- Row 2: "Put away" (chevron.down, only when there is a shot to return to); the cue angle as a text capsule ("Level" or
  its degrees); "Shot options" (slider.horizontal.3: Try again, Fine controls, Aim at nearest ball, Move cue ball, Undo,
  Rack, Re-rack, Show the hint again; never the ellipsis, which the title row already uses); then "Break" or "Shoot",
  the white prominent capsule, about 96 by 44, text only.
- While calling a shot in a match, the call row (Safety, the chosen pocket, "Call it", from App/Match/CallControl.swift)
  replaces row 2, and Shoot appears once the call is made.
- What-if: its nudge controls take the panel's place, sized to their content; its result is an anchored blurb.

### Every phone state, upright

- First minute: title "Break"; the docked instruction blurb, full sentence over two lines ("Drag on the table to aim. Pull
  back from the white ball, then push through it."), fading once the break is struck (not on the first touch); the table
  from the docked blurb to the panel; the panel without "Put away". Nothing else.
- Aiming later: notices (ball in hand, a stance hint) as docked blurbs; the "1 Solid" label small and clear of the rack.
- A shot playing: the table from the title row to the strip; transport, rail, speed, and Lens after the first shot.
- Replay finished: the full strip, with the primary action.
- Guided Lens replay: the table from the title row to the strip (about 640 points tall, against about 330 in the red-box
  frame), framed on the moment; title "The Called Break · Hard"; the Lens key and the idea (folded to one line, with its
  "more" dot) docked at the top; one anchored blurb for the explanation above or below the moment; the lead figure also
  written beside its Lens drawing; primary action "Your turn".
- Match: the title shows whose turn and the score; a ruling is a docked blurb with "Continue" as the primary action; a
  ruling that is a choice keeps both its buttons in the blurb and hides the primary action.
- Lens tips: docked blurbs with small glass "Not now" and "Next" or "Got it"; the pointer line stays.
- Ride: as plans/22-Nov-2026-ride-handover-plan.md (built in 0.7.6), with its status words in the title and the map
  docked bottom-left.

### Where the critiques disagreed (decided)

- Lens and Ride in the strip, not the title row: thumb reach, and long titles keep their room.
- Lens on shown by a two-colour underline, not a fill: it is what the Lens draws.
- Continue as a word on the primary action only for rulings; during a guided replay the play button continues.
- Two-row aiming panel: the power figure and Break need room at large text.
- The cue angle stays visible: it is physics.
- New drawings (an angle arc, an energy bar) wait for their own plan; the lead figure beside the existing drawing is
  enough now.

### Stop using on the upright phone

- App/CaptionViews.swift: CaptionStrip (its fixed room, hidden measuring copies, page-dot slot, figure tile row), the
  accent bar, the ring's title chip; LensLegendChip in the title row.
- App/ShowpieceView.swift: the bottom stack and its height budgets; the mode-card column; the status title's plate; the
  surface picker circle; the lensReplayCompact slim forms (App/LayoutFlags.swift) once every card is a blurb.
- The glassCard wrapper on the what-if, opening, trick, lesson, Behind the 8-Ball, match, free-play and stroke cards and
  ContactArrivalLine: their content becomes blurb content.
- App/PlaybackControls.swift's big capsule row and its fitting ladder; the scrub plate.
- App/ShotPanel.swift's hint card and its bordered close, the power minus and plus, the glassCard wrapper, Try again in
  the main row.
- Symbols that mean nothing here: viewfinder (Lens), video (Ride), target (Your shot), forward.fill (Continue),
  scribble.variable, slider.horizontal.below.rectangle, arrow.uturn.backward.circle. Re-rack uses
  arrow.triangle.2.circlepath; the cue angle shows degrees.
- Bordered buttons in App/WhatIfViews.swift and App/GhostOverlay.swift become glass.

### Not changing

The open folding phone, iPad, Mac and the sideways phone keep their side panels and the shared views.

## Part 4. Order of work

Every step ends with screenshots on the iPhone 17 simulator (402 x 874, the regular iPhone size) of the states it
touches, checked against Part 3 before the next step starts. No step starts before the one before it is checked.

0. Look first. Capture every state above as it is now (launch flags -trickPlay called-break, -pauseAt, -yourShotDemo,
   -aimDemo; a match from the menu) as the "before" set in plans/images.
1. Mock. One picture per state at 402 x 874 (a simple HTML page drawn to Part 3 over the "before" tables). Show the Boss
   the whole set once, as pictures, before building anything.
2. Blurb. The view and its placement function, with unit tests: never over the keep-clear rectangle, never under the
   title row or the strip, docked stacking order, steady through a beat.
3. Glass frame. PhoneTitleRow and its menu (the surface picker inside it); PhoneStrip in one glass container in the bottom
   safe-area bar, with its unions and identities; the content gradients; the camera framing from the title row to the
   bar's top, read from the safe-area inset.
4. Explanation. The anchored blurb replaces CaptionStrip and the ring chip on the upright phone; the play button
   continues a held moment; the Lens key becomes a docked blurb.
5. Mode cards. Each becomes a docked or anchored blurb; the primary action takes the cards' main buttons in the order in
   Part 3; the slim forms and lensReplayCompact go once nothing reads them.
6. Aiming panel. PhoneAimPanel's two rows, the morph from and into "Your shot", Shot options, the call row; the power bar
   adjustable for VoiceOver; the instruction as the docked blurb.
7. Clean up. Everything in "Stop using on the upright phone" is unused on that path (the shared views still serve the
   notebook and the sideways column).
8. Check every state at the default and an accessibility text size, in German, with Reduce Transparency and with Increase
   Contrast, on the brightest and the darkest surface. Then the first minute on a fresh install, and the open folding
   phone, iPad and Mac once each, unchanged.

## Where the code is

Branch claude/iphone-layout-overlap-7f3f27 (0.7.6, not yet pushed to main): the bug fixes from
plans/22-Nov-2026-phone-bug-hunt.md, the moment framing, readable Lens marks, pages, figures (Caption.figures), the Ride
hand-over, and the sound fix (no rolling hiss, no reverb). Build and test commands are in README.md; derived data goes on
/Volumes/Team 4TB/breakdown-build/.
