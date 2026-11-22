<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: What the regular iPhone screen is made of in 0.7.6 (every control, its size, background and icon, with file references), three adversarial design critiques of the Boss's screenshots, and the skeptic's corrections to the first design draft. Input to the phone UI plan.
SRP/DRY check: Pass - reference material for plans/22-Nov-2026-phone-ui-plan.md; not repeated there.
-->
# The phone screen today: inventory and three adversarial critiques

## Inventory of the phone's chrome (0.7.6 code)

Inventory of the upright-phone chrome. Code checked on branch claude/iphone-layout-overlap-7f3f27, in the worktree at /Users/macmini/GitHub/breakdown/.claude/worktrees/localization-setup-translations-1c1f5c. Nothing was edited, built or run.

DEPLOYMENT TARGET
- /Users/macmini/GitHub/breakdown/.claude/worktrees/localization-setup-translations-1c1f5c/Breakdown.xcodeproj/project.pbxproj:75, 86, 98 and 104 set both the iPhone and the Mac deployment targets to 26.0. The iOS 26 Liquid Glass APIs need no availability checks, and the code uses them without any.
- The only availability check on the chrome path is App/Surfaces.swift:90. It checks for iOS 27.1, for the folding phone's hinge region. It has nothing to do with glass.

GLASS: REAL API OR IMITATION
- It is Apple's real Liquid Glass throughout. The chrome uses the glass effect, the glass and prominent-glass button styles, and one glass container, at App/PlaybackControls.swift:259.
- No Material or thin-material background appears anywhere. Every Material hit in App/ is a 3D scene material, not a UI one.
- There is one shared helper, glassCard, at App/Surfaces.swift:27-30: regular glass on a rounded rectangle, default corner 24 and padding 16. App/Theme.swift holds only colours and fonts. It has no surface tokens.
- Three hand-made touches sit on top of the system glass:
  - a 3pt accent bar overlaid on the caption glass (App/CaptionViews.swift:221)
  - a 15% accent tint on the caption chip (App/CaptionViews.swift:1093)
  - the app is forced dark, and prominent buttons draw their text in the dark ground colour (App/PlaybackControls.swift:118, App/ShotPanel.swift:216)
- Glass features that are never used: the interactive glass variant, the clear glass variant, glass morphing IDs, glass unions, scroll-edge effects, safe-area bars and system toolbars. The only glass container wraps the Lens / Ride / Your shot row. The title row and the scrub row are not grouped.
- A few controls are not glass at all:
  - the hint's close button is plain bordered (App/ShotPanel.swift:348)
  - a bordered button in App/WhatIfViews.swift:328
  - a bordered button in App/GhostOverlay.swift:236
  - the play, replay, speed and What if buttons in the scrub row are plain buttons inside one glass capsule

LAYOUT FRAME (App/ShowpieceView.swift)
- The stage is a full-bleed 3D table with one vertical stack on top (379-401): spacing 6, side padding 16, top padding 4, bottom padding 6. The stack is the title row, a spacer, then the bottom stack.
- Bottom stack budget (444-519): spacing 10.
  - Its height budget is 62% of the screen height (453). On a 402 x 874 phone that is about 542pt.
  - The cards' cap (464) is that budget minus the measured pinned pieces, with a floor of 12% of the height (526).
  - Until the playback row is measured, it is allowed 124pt (523).
- The camera fits the table between the title row's bottom and the bottom stack's measured top (518). Every point the stack takes comes off the table.

TITLE ROW: ScreenHeader (App/ShowpieceView.swift:671-716)
- The row is a horizontal stack with spacing 12. Its contents in order:
  - Back button, MenuBackButton (720-743): symbol chevron.backward, icon only, label "Menu". Regular glass circle at regular control size, 22x22 glyph frame, about 44pt round (estimated).
  - LensLegendChip, shown only while the Lens is on (detailed below).
  - "Tap to skip", only during the opening (684-690): symbol forward.end.fill, glass, small control size, caption semibold.
  - The right-hand round button is not a menu. It is SurfaceMenuButton, the surface picker (749-784). Label "Surface", icon only, glass circle, same size as the back button. Its symbol changes with the surface (App/PlaySurface.swift:80-91): square.grid.3x3.fill (cloth), trophy.fill, mug.fill, snowflake, sparkles, aqi.medium, checkerboard.rectangle, circle.fill, circle.grid.3x3.fill, moon.fill.
  - Status title, shown when the stage is not explore or lead (697-705): regular glass, corner 16, padding 12 by 6, caption semibold, up to 2 lines.
- LensLegendChip (App/CaptionViews.swift:798-846):
  - Regular glass, corner 16, padding 12 by 8 (841).
  - "Physics Lens" in bold caption, accent colour. Then the entries "Sliding" (magenta) and "Rolling" (cyan), each with a 16x3 glowing line.
  - A size-fitting fallback stacks the pieces when one row does not fit.

OVER THE TABLE
- Caption chip and ring, CaptionLeader (App/CaptionViews.swift:943-1109, placed at App/ShowpieceView.swift:225):
  - Ring of radius 20, 2pt stroke.
  - The chip is a regular glass capsule with a 15% accent tint, padding 10 by 5, caption semibold, up to 2 lines.
  - It sits 8pt from the ring, as wide as its title up to the stage width minus 36. It prefers right, then left, then above, then below the ring.
  - On the upright phone the line to the card is off. The chip stays above the strip's top.
- Lens tips bubble, LensCalloutBubble (App/LensCallouts.swift:264-312):
  - glassCard with corner 20 and padding 12, at most 420 wide, inset 16 from each side (155-156).
  - Symbols (81-82): scribble.variable for tips 1 and 2, slider.horizontal.below.rectangle for tip 3, in title 3 size. Plus arrow.down or arrow.forward pointing at the bar.
  - Body text in subheadline, "1 of 3" in caption.
  - Buttons: "Not now" (glass, small) and "Next" / "Got it" (prominent glass, small).
  - The first two tips sit 12pt under the title row (144). The third sits 12pt above the playback row (152).
  - Pointer line: 2pt, over a 4pt dark shadow, ending in a ring of radius 9 (180-184).

BOTTOM STACK, TOP TO BOTTOM
1. CaptionStrip (App/CaptionViews.swift:560-767; inserted at App/ShowpieceView.swift:470):
   - The room's height is fixed, measured from a hidden copy: equation line, two title lines, four detail lines (581), plus padding.
   - The height is capped at 28% of the screen height, about 245pt. The cap is a ceiling only. At default text the measured room is estimated at about 150-175pt with the equation line and about 125-150pt without it.
   - The frame is pinned to that room's minimum and maximum (711). While a guided replay plays, the glass fills the whole room even when the words are short (705).
   - Surface (209-222): regular glass, corner 18, padding 10, plus 4pt extra on the leading side, plus the 3pt accent bar.
   - Fonts: equation in italic serif callout size, one line, shrinking to half (583). Title in headline. Detail in subheadline.
   - Page dots keep a 48pt-wide slot (481). Each dot is 6pt inside a 30pt-tall hit area.
   - Continue (233-251): symbol forward.fill, label "Continue", prominent glass in the accent colour. At the largest text sizes it shows the icon only.
2. Mode cards, in a scroll that appears only when they overflow (App/ShowpieceView.swift:474-491):
   - Every card is a full-width glassCard with corner 22 and padding 12. The exceptions are the stroke result card and the contact line, which use corner 20.
   - Locations:
     - WhatIfCard: App/WhatIfViews.swift:128 and 152
     - OpeningCard: App/OpeningHandover.swift:173 and 212
     - TrickShotCard: App/TrickShotViews.swift:193
     - LessonCard: App/Lessons/LessonViews.swift:141
     - EightBallCard: App/EightBall/EightBallViews.swift:242
     - MatchCard: App/Match/MatchViews.swift:133
     - Free-play cards: App/FreePlayViews.swift:162, 279, 319, 396, 482
     - Stroke cards: App/Stroke/StrokeViews.swift:87 and 168
     - Contact line: App/RetryWords.swift:221
   - Trick card buttons (button minimum height 30, App/TrickShotViews.swift:445):
     - "Watch it" (play.fill) or "Watch again" (arrow.counterclockwise), at 382
     - "Your turn" (target), at 390
     - "Show the answer's path" / "Hide the answer's path" (point.topleft.down.to.point.bottomright.curvepath.fill), at 410-411
     - "All trick shots" (list.bullet, icon only), at 425
     - "Show the maths" / "Hide the maths" (function, icon only), at 234
     - "The idea" in caption, magenta; the equation in italic serif title 3.
   - During a guided Lens replay the cards switch to a slim form (App/ShowpieceView.swift:532). That form is still a full-width glass card.
3. ShotPanel (App/ShotPanel.swift:66-363; wrapped at App/ShowpieceView.swift:495 in the default glassCard, corner 24, padding 16):
   - Main rows (150-194): spacing 6-12, chosen one row, two rows or stacked by what fits.
   - TipPicker is 52pt, scaling with text (App/AimGauges.swift:61).
   - PowerGauge is at least 84 wide with a 12pt bar (App/AimGauges.swift:218). Its minus and plus buttons are 30x30 (App/AimGauges.swift:435).
   - Cue angle menu: symbol angle, or scope when inside a lesson zone. Label "Level" or the degrees (App/CueAngleControl.swift:92-103, glass).
   - Try again: arrow.uturn.backward, glass, regular, headline.
   - Shoot / Break: text only, no symbol, prominent glass, headline, minimum height 30 (360). The code comment says this lands at 44pt or more.
   - More shot options: ellipsis, glass circle, at least 30 wide (326-332).
   - The more menu holds:
     - "Fine controls" (slider.horizontal.3)
     - "Aim at nearest ball" (scope)
     - "Move cue ball" (hand.raised)
     - "Undo last shot" (arrow.uturn.backward.circle)
     - "Rack" and "Re-rack for a break" (triangle, both)
     - "Show the hint again" (questionmark.circle)
   - Hint: hand.draw icon in title 3, xmark close button 30x30 in plain bordered style. It scrolls past 150pt.
   - Status line: cpu or exclamationmark.circle.
   - The inline fine controls are 260pt tall, scaling with text (84).
4. PlaybackControls (App/PlaybackControls.swift:178-316; inserted at App/ShowpieceView.swift:499):
   - Vertical stack, spacing 8.
   - Scrub row (200-227): a regular glass capsule with 8pt side padding.
     - Play / Pause: play.fill / pause.fill, icon only, at least 44x44.
     - ScrubBar: 44pt hit area, 6pt rail, 20pt thumb (App/ScrubBar.swift:33-35).
     - Speed: text only, "Auto" or for example "0.5×", no symbol, at least 44 tall.
     - Replay: arrow.counterclockwise, icon only, at least 44.
     - What if: arrow.triangle.branch, icon only, at least 44 (App/WhatIfViews.swift:58-62). Its slot is kept even while the button is invisible, leaving an empty 44pt gap until your own shot has stopped.
     - With Your shot open, the scrub row drops to small size (192).
   - Button row (258-276):
     - All three are glass, inside the glass container with spacing 8, at LARGE control size (274). The "compact" setting defaults to off, and the phone does not pass it (App/ShowpieceView.swift:499).
     - Each is title plus icon, one line, never squeezed:
       - "Physics Lens", falling back to "Lens": viewfinder (236)
       - "Ride": video (245)
       - "Your shot": target (254)
     - When switched on, each becomes prominent accent glass with dark text (117-121).
     - A size-fitting ladder (265-270) tries the full Lens name on one row, then the short name on one row, then two rows of each.
     - With 370pt of usable width, I estimate the short "Lens" fits on one row. The plan says two rows. Only a measurement settles it.
     - Large glass buttons are estimated at about 48-52pt tall. That puts the whole playback block at about 100pt for one row, or about 160pt for two.

ICON PROBLEMS (evidence for "meaningless")
- target means both "Your shot" (PlaybackControls:254) and "Your turn" (TrickShotViews:390).
- play.fill means both Play (PlaybackControls:60) and "Watch it" (TrickShotViews:382).
- arrow.counterclockwise means both Replay (PlaybackControls:82) and "Watch again".
- arrow.uturn.backward means Try again (ShotPanel:283). The undo entry uses its circled version.
- scope is both "Aim at nearest ball" and the cue angle's in-zone icon.
- triangle is used twice in the same menu.
- viewfinder (Lens) and video (Ride) read as camera and record-video. Neither says physics or riding the ball.
- The surface button's icon changes with every surface, so the button has no fixed meaning.

ESTIMATED VERTICAL BUDGET (874pt screen, default text, guided Lens replay with a trick on)
- Top safe area about 62pt.
- Title row about 44pt.
- Caption strip about 150-175pt.
- Slim trick card about 60-90pt.
- Playback block about 100-160pt.
- Gaps about 40pt.
- Bottom safe area about 34pt.
- That leaves roughly 300-370pt for the table. All of these are estimates except the caps and constants given above.

## Critique: Apple platform design (Liquid Glass and the guidelines)

**Liquid Glass and layout review of Breakdown's upright phone screens**

**1. Worst problems, ranked**

1. **The table loses the middle of the screen.** In the 0.7.6 red-boxes shot, the bottom stack takes about 60% of the height. It holds:
   - the explanation card
   - the trick card with "The idea"
   - the scrub capsule
   - two rows of capsules

   In the 0.7.5 shots, the table ends at about 47% of the height and the moment sits right on the card's top edge. The Throw ring is half under the glass. The table is the content and the reason the app exists; here it has been demoted to a header.

2. **Words are glass cards sitting in the content layer.**
   - The 0.7.5 explanation card is a nine-line paragraph in regular glass with a hand-drawn accent bar.
   - Its words run in a column about 60% wide because Continue holds the right side open. The right third of the card is empty glass.
   - This breaks "don't use Liquid Glass in the content layer", "use it sparingly" and "reduce custom backgrounds".

3. **Glass is layered on glass, over the words.**
   - In the 0.7.5 path-bends shot, the "The path bends" chip (tinted glass) and its ring are drawn across the card's own sentence, hiding "not" and "motion". The ring cuts through "bottom".
   - In the Throw shot, the chip and ring straddle the card's top edge.
   - On the aiming screen, the hint card is stacked on the aiming panel, which is stacked on two rows of buttons.
   - This breaks "avoid layering Liquid Glass elements on top of each other" and basic legibility.

4. **Reserved empty room.**
   - In 0.7.6, the "ΔKE → 0" line gets its own full-width row.
   - A ghosted Continue floats beside it.
   - The fixed four-line detail room holds a single sentence. The owner's red boxes are exactly that dead glass.
   - In 0.7.5, the trick card is about 200pt wide of empty plate around a title, "Hard" and one button.
   - This breaks "sized to content", and violates his "not cards" note.

5. **Too many prominent buttons.**
   - The 0.7.5 frames show three accent-filled controls at once: Continue, Your turn and Lens.
   - The aiming screen shows two: Break and Your shot.
   - They are also huge (large control size, about 50pt) and Your shot sits orphaned on a second centred row.
   - This breaks "only one primary action", "use style, not size", and "no more than two text buttons side by side".

6. **Icons that say nothing.**
   - A viewfinder for Lens reads as scan or crop.
   - A video camera for Ride reads as record.
   - The circled target means both Your shot and Your turn, and it is a bordered symbol.
   - The dot grid for the surface picker reads as a keypad or an app launcher, and its glyph changes per surface.
   - Fast-forward for Continue reads as skip ahead or double speed.
   - This breaks "make sure the meaning of each control is clear", "prefer symbols without borders" and "use text when it is clearer".

7. **The title row is crowded with mixed heights.**
   - The Lens key is a glass capsule in the navigation row, but it is a legend, which is content.
   - In 0.7.6 it wraps to two lines, a ball thumbnail collides with the back chevron, and the table's dashed outline runs through the row.

8. **The aiming panel has dead space and debug-looking type.**
   - The ellipsis floats alone at bottom-left, with an empty band between the rows.
   - The power caption is set in lowercase monospace.
   - The plus and minus buttons are 30pt glass circles.
   - The "1 Solid" glass chip sits over the rack.

9. **Global styling fights the system.**
   - The app is forced dark, and dark text sits on cyan.
   - The accent bar and the 15% tint are added on top of the glass.
   - No glass container groups the strip, there are no morph IDs, no safe-area bar, and no clear variant is used anywhere.

**2. The bottom buttons**

- **Physics Lens.** Keep it, but move it to the title row as a text-only capsule reading "Lens". Use regular glass, about 34pt visible inside a 44pt hit area, with subheadline semibold text.
  - On state: a solid white glass selection with a dark label, the way a segmented control shows selection. No accent fill.
  - The key becomes a separate small material blurb, shown only while the Lens is on.
- **Ride.** Keep it as a text capsule "Ride", grouped with Lens. Two text buttons in one glass group is within the limit.
  - Show it only when a replay contains a collision worth riding. Hide it otherwise.
- **Your shot.** This is not a toggle. It is the one prominent action: a tinted prominent-glass capsule, text only, 44pt tall, about 100pt wide, at the right end of the bottom strip.
  - Its label follows context: "Your shot", "Your turn" in a trick or lesson replay, and "Continue" while a moment is held.
  - When tapped, it morphs into the aiming panel and is not shown while that panel is open.
- **What if, the surface picker, Show the maths and All trick shots** move into the ellipsis menu.

**3. The ideal screens on a 402 x 874 phone**

**Replay screen (guided Lens replay, trick on)**

- **Top safe area:** 0 to 62.
- **Title row:** 62 to 106, side inset 16, spacing 8.
  - Back: a 44pt glass circle with a plain chevron.
  - Status title, no plate: "The Called Break" in subheadline semibold, with "Hard" in caption in its colour. Tapping the title opens the idea as a blurb.
  - On the right, the Lens and Ride text group, then an ellipsis glass circle (44). A fixed spacer separates the text group from the circle.
- **Lens key:** a thin-material blurb docked at the top-left of the table area, about 22pt tall, caption-two text, "Sliding" and "Rolling" with their line swatches. It appears only while the Lens is on.
- **Table:** about 110 to 784, roughly 670pt against about 330 today. The moment framing zooms the moment into this space.
- **Explanation:**
  - An anchored blurb beside the moment and away from its focus, in thin material with label colours and no accent edge.
  - Corner 12, padding 10, width sized to the text with a maximum of about 260.
  - Title in subheadline semibold, with the lead figure in accent and monospaced digits ("Throw · 2.1°").
  - One sentence in footnote, at most three lines, then a small "more" dot.
  - About 70 to 90pt tall, joined to the ring by a 1pt leader line.
  - No chip on the ring itself.
- **Strip:** a bottom safe-area bar in one glass container, 790 to 834, with the table running underneath and the home area below.
  - Play, pause or replay: 44, clear glass with dimming.
  - Scrub bar in the remaining width, about 150. The knob turns interactive glass while dragged.
  - Speed: a text capsule ("1×"), about 48 wide.
  - Prominent context action: about 100 wide.
  - About 8pt gaps.

**Aiming screen (break)**

- **Title row:** as above, with the status "Break".
- **Instruction:** a one-line material blurb docked at the top of the table area, "Drag on the table to aim", in footnote. It fades on the first drag and has no close button.
- **"1 Solid" label:** a small material label, offset clear of the rack.
- **Table:** about 110 to 690.
- **Aiming panel:**
  - It is the strip morphing out of the same container, in regular glass, with concentric corners inset 8 from the screen corners. It runs from about 700 to 834, roughly 120pt, with padding 12.
  - **First row:** the tip picker as a 44pt cue-ball face, then the power bar filling the rest.
    - The power bar has "Power" in a caption above it, the speed figure in monospaced caption on the right, and a tick for the calm zone with no words.
    - The plus and minus buttons move into fine controls.
  - **Second row:** a back chevron (44, glass) that closes the panel and morphs back into the strip, the cue angle as a small text capsule ("Level"), the ellipsis menu, and Break as the only prominent button (44 tall, about 96 wide) at the right.
  - No Your shot button is shown while the panel is open.

## Critique: Game UX

For the Boss, use plain words only. The sizes in points below are for whoever builds this.

**(1) Worst problems, ranked**

1. **The table loses the screen.** Seen in the red-box shot and the throw shot. A stack of cards sits under the table: the explanation, the trick card, the scrub plate and the button rows. In the red-box frame the table is a strip covering about a quarter of the height. In the throw shot the explained moment is a few points wide, at the bottom edge of a whole-table view. This breaks two rules: content first with glass floating over it, and full-bleed content running under the bars. The cause is structural, not padding.

2. **The label is drawn across its own sentence.** In the path-bends shot, the ring and the "The path bends" chip sit on top of three lines of the explanation that has the same title. In the throw shot, the ring and the "Throw" chip straddle the card's top edge. The same words appear twice, and they collide. That is a hard defect, and it shows that nothing placed in a stack under the table can be placed safely.

3. **Cards hold words, and much of the glass is empty.** In the red-box shot, the change in kinetic energy line gets a full-width bar and the rest of that card is empty. In the throw shot, the text squeezes into the left half while the right half holds only Continue, and the trick card is mostly empty glass around one button. The accent stripe down the plate carries no information. This breaks "no glass in the content layer", "use it sparingly" and "no glass on glass": a card sits on a card, which sits on the strip. This backs the brief over the plan. Blurbs should be thin material with no accent edge.

4. **Three or four filled accent buttons on one screen.** The throw shot has Continue, Your turn and the active Lens, all filled cyan. The first screen has Break and Your shot, both filled cyan. This breaks "only one primary action" and "use style, not size."

5. **The bottom buttons are oversized and wrap.** In the red-box shot they break onto two rows (Physics Lens and Ride, then Your shot alone, centred), which settles the inventory's estimate. They run at large control size, about fifty points tall, under a separate glass scrub plate. That makes two glass rows where one compact strip belongs.

6. **The icons are meaningless.** In the throw shot, the same target icon means "Your turn" on the card and "Your shot" just below it, as two different actions. The viewfinder icon on Lens reads as camera focus, and the video-camera icon on Ride reads as record. The grid at top right reads as an app launcher but actually picks the table surface, and its icon changes with each surface. The speed label "Auto" tells a newcomer nothing. This breaks "don't make people guess."

7. **Controls shown when they can do nothing.** On the first screen, Lens and Ride are offered before any shot exists to look at. The Your shot toggle sits under an aim panel that is already open. The minus and plus power buttons duplicate the pull-back drag that the instruction teaches. This breaks "show and hide controls to reflect gameplay." In the throw shot, Continue on the card also competes with play and pause in the scrub row, giving two ways to advance the same beat.

**(2) The three bottom buttons**

- **Your shot: remove it as a toggle.** When the table is at rest and it is your turn, the aim panel simply is there. During a replay the one prominent slot says, in text only, "Your turn" for a trick or lesson, or "Your shot" otherwise. It has no icon. It uses prominent glass in the accent colour, is 44 tall and sized to its text (about 100–112 wide). It must be the only filled button on the screen.
- **Physics Lens: keep it as the one persistent toggle.** It should be a text capsule reading "Lens", in regular glass, 44 tall and about 64 wide, with no icon. When on, the word goes bold with a small accent dot in front. The background is never tinted, because the tint belongs to the primary action. The blueprint table already shows that the Lens is on.
- **Ride: show it only while a replay of a shot that has already run is on screen.** It should be a text capsule reading "Ride", about 60 wide, joined with Lens in one glass union. It has no icon, and no camera or record symbol. It is hidden while aiming and before the first shot.
- **Elsewhere on the screen:**
  - Swap the grid button for the standard ellipsis menu. It holds Surface, What if, Show the maths, Fine controls and Watch again.
  - Replace "Auto" with a speed readout such as "1×" or "½×".

**(3) Ideal screens, 402 × 874**

**Replay (guided Lens).** Top safe area 62, title row 44, table 654, scrub row 28, gap 8, button row 44, bottom safe area 34. Total 874.

- **Title row:**
  - Back chevron at the left, a 44 clear-glass circle.
  - "The Called Break" in the centre, 17pt semibold plain text on one line, with no plate.
  - The ellipsis menu at the right, a 44 circle.
  - "Hard" and the trick's idea move behind a tap on the title, which opens a blurb.
- **Lens key:** a thin-material blurb reading "Sliding / Rolling" at 12pt, about 170 × 26, docked under the title at the top left of the table area. It shows only while the Lens is on.
- **Table:** runs full-bleed from the top edge to the bottom edge. The camera frames from y 106 to y 760 and zooms so the moment sits about 40% down.
- **Explanation:** a thin-material blurb anchored beside the moment, on the side with room, never over the balls involved.
  - At most 260 wide and about 96 tall.
  - A 15pt semibold title plus one figure chip in a monospaced face, such as "2.1°".
  - One sentence at 15pt, at most three lines, with a "more" dot for the rest.
  - A ring of radius 20 on the ball, joined to the blurb by a 1pt leader.
- **Scrub row:** at 760–788, a bare 6pt rail with moment ticks and a glass knob, 44 hit area, with no plate. It is 322 wide, then a 40-wide speed text button.
- **Button row:**
  - At 796–840 on the left, play/pause and replay joined in clear glass with a dark dimming layer, 88 wide.
  - Next, the Lens and Ride union, about 124 wide.
  - Then a flexible spacer and "Your turn" in prominent glass, about 112 wide.
  - While a moment is held, play becomes a tinted forward icon and takes the one prominent slot. "Your turn" drops to regular glass. A tap on the table also continues.

**Aiming (first break).** Top safe area 62, title row 44, table 662, aim panel 72, bottom safe area 34. Total 874.

- **Title row:** back chevron, the plain title "Break", the ellipsis menu.
- **Instruction:** a one-line thin-material blurb docked at the top of the table area, about 300 × 38, over the far rail: "Drag to aim. Pull back, push through." It fades after the first aim.
- **Table:** frames from y 106 to y 768. That is about half again the table height on today's first screen.
- **Aim panel:** sits at 768–840 in regular glass, 370 wide. It morphs out of the strip's container, so it never stacks on top of it. It is one row with 10 of padding:
  - the cue-ball spin disc, 52;
  - the power bar, flexible at about 130, with its readout in small monospaced type above it and no minus or plus buttons;
  - the ellipsis, 44, holding the cue angle, fine controls and aim at nearest ball;
  - "Break" in prominent glass, 96 × 44, the only filled button.
  - The cue angle appears as a small chip in the panel only when it is not level.
- **Hidden while aiming:** Lens, Ride and the Your shot toggle.

## Critique: Physics showcase

(1) The worst problems, ranked

1. **The labels collide with the words (both 0.7.5 shots).** The event chip repeats the card title word for word: "Throw" appears twice, and so does "The path bends". On the path-bends shot the chip and its ring sit right on top of the body text, so the paragraph can't be read. On the throw shot the ring sits on the card's top edge, half covered, so it points at nothing. An anchor should point at the table, never at the text it labels.
2. **The physics is written out as prose.** The throw card has six figures in one sentence: speed, the energy split, heat, the throw angle and two ball names. The path-bends card has five: the bend angle, friction, gravity, the time and the final speed. They all sit at the same body weight in a ten-line column, and the right half of the card is empty. Meanwhile the drawing on the table is a bare coloured line, and its key is stuck far away in the title row. The angle, the energy split and the moment where sliding turns to rolling should be drawn. Writing them out breaks hierarchy and wastes the Lens.
3. **The words sit on top of the action.** The card climbs over the near end of the table. On the path-bends shot the velocity arrows are cut off by the card's edge. Body text over the bright, lit patch of table loses contrast. The table gets about a third of the screen. The explanation is content, so it should never cover the thing it explains.
4. **The red-box shot (0.7.6) is a fixed room with empty plates.** A five-character equation takes the full width. "Pocketed" plus one sentence leaves a blank block, and a half-faded Continue ghost sits beside the equation. The equation is also the wrong one: the ball is still moving, so "energy goes to zero" is misleading. A grudging equation is worse than none.
5. **There are too many tinted actions.** The 0.7.5 shots tint three backgrounds at once: Continue, Your turn and the Lens toggle when it is on. The trick card is almost all empty glass with a second big tinted button in it. Apple's rule is one prominent action at a time.
6. **The colour code is muddled.** Magenta means sliding in the Lens. It is also used for "Hard" and for "The idea". Magenta and cyan should belong only to sliding and rolling.
7. **The bottom capsules are huge and their icons say nothing.**
   - They are about 50 points tall. In 0.7.6 they wrap onto two rows, with Your shot alone and centred on the second (first-screen and red-box shots).
   - The viewfinder reads as "camera" and the video camera as "record".
   - The target means both Your shot and Your turn.
   - The top-right grid looks like an app launcher or a keypad. It is really the surface picker, and its symbol changes with every surface.
8. **On the first screen the controls stack up.** Under the table there are four stacked plates: the hint, the aiming panel and two rows of buttons, which is about half the screen. Lens and Ride appear before there is anything to replay. Your shot stays tinted while its own panel is open. The one physics figure there, the swing speed, is a tiny lowercase monospaced header. The minus and plus buttons are 30 points, under the 44-point minimum for a control used this often.

(2) The three bottom buttons

- **Physics Lens:** keep it. It is the app's whole point.
  - A text capsule reading "Lens", with no icon, in regular glass. It looks 36 points tall, with a 44-point touch area, and is about 60 points wide.
  - When it is on, the label gets a short magenta-and-cyan underline, which is the Lens key in miniature. The background is never tinted.
- **Ride:** keep it, but only once a replay exists. Hide it while aiming and during the first minute.
  - A text capsule reading "Ride", in regular glass, about 56 points wide. No icon.
- **Your shot:** remove it as a toggle.
  - That slot becomes the single context action, the one tinted button, about 96 by 44 points. It reads "Your shot", "Your turn" (in a trick or lesson) or "Continue" (while a moment is held or a ruling waits).
  - Tapping it morphs the strip into the aiming panel. Once the panel is open, the button is gone, so it can't sit there tinted next to its own panel.
  - No icon, because the word is clearer.
- **The rest:** What-if moves into the menu. The surface picker leaves the title row for the menu, and the title row's right button becomes the standard three-dot menu.

(3) The ideal layouts on a 402 x 874 point screen, with 16-point side margins

**The replay screen**
- **Title row** (y 62 to 106):
  - A back chevron in a 44-point clear-glass circle on the left, and the three-dot menu in a 44-point circle on the right.
  - Between them, plain text with no plate, about 15 points semibold: "The Called Break · Hard". Tapping it opens the trick's idea as a blurb.
- **Table** (y about 110 to 770, about 660 points): full-bleed, with the camera framed on the moment.
- **Drawn on the table for the throw:**
  - a dashed line of centres;
  - an arc between that line and the object ball's path, labelled "2.1°" in a monospaced figure on the arc;
  - a stacked bar about 60 by 6 points next to the balls showing the energy split (91 / 3 / heat);
  - speed labels at the arrow tips.
- **Drawn on the table for the path bend:** the curve itself, with "14°" on its arc, magenta turning cyan at the point where sliding becomes rolling, and a tick there reading "rolls · 1.0 m/s".
- **Lens key:** a blurb about 100 by 36 points docked at the top left of the table area, in thin material at 11 points. It appears only while the Lens is on.
- **Explanation blurb:** anchored beside the moment on the side away from it, with a 1-point leader line to the ring. Thin material, 12-point corners, 10-point padding, at most about 260 points wide, about 110 to 130 points tall. From top to bottom:
  - the title in headline weight, with the lead figure in the accent colour and monospaced ("Throw  2.1°");
  - up to three figure chips in 12-point monospace;
  - one sentence of at most three lines in 15 points;
  - an optional italic equation line in 13 points, shown only when the maths is turned on;
  - a "more" dot when text is folded.
- **Scrub rail:** a full-width rail at about y 772, 6 points tall with a 44-point touch area. Its thumb turns into glass only while it is being dragged.
- **Button row** (y about 790 to 834):
  - a clear-glass group of three symbols, about 132 points wide: play/pause, replay, and the speed;
  - then Lens and Ride;
  - then the tinted context action.
  - That is three groups in about 356 points, which fits the 370-point width at default text size. At larger text sizes Ride moves into the menu.
- **Bottom safe area:** 34 points.

**The aiming screen**
- **Title row:** the same as the replay screen, with the status reading "Break".
- **Table** (y about 110 to 700).
- **Instruction:** drawn on the table as a faint drag arrow pulling back from the cue ball. The words are one line in a top-docked blurb, "Drag back, push through", with "more" behind a tap.
- **Aiming panel:** morphs out of the strip and fills the strip's place. Regular glass, 370 by about 130 points, 24-point corners.
  - Row one: the tip picker (52 points); then the power gauge, with the swing speed as the hero figure, "8.3 m/s" in 17-point monospace above the bar and "swing speed" in 11-point caption under it; then 44-point minus and plus buttons.
  - Row two: the three-dot menu (44 points), the cue-angle menu, a gap, then Break as the one tinted button, about 100 by 44 points.
- **Hidden before the first shot:** the transport controls, Lens and Ride. The chrome under the table drops from about 480 points today to about 170.

## The skeptic's corrections to the first draft (all applied in the plan)

1. **Keep the shared views and add phone versions next to them.** The notebook panel uses ShotPanel, PlaybackControls (compact) and LensLegendChip at App/NotebookPanel.swift:225-248, and the sideways phone uses them at App/ShowpieceView.swift:627-652. As written, "What to delete" and step 7 ("search finds nothing") would break the iPad, Mac, folding phone and sideways phone, which the draft says won't change. Change "delete" to "stop using on the upright phone". Add phone-only views (PhoneStrip, PhoneAimPanel, Blurb) and leave the shared ones as they are.

2. **Keep the toggle for controllers.** App/ControllerInput.swift:209 maps the Y button to toggling the shot panel, and App/WhatIfFork.swift:262 and 305 open and close it. "Your shot is no longer a toggle" breaks both. Keep the toggle request on the model, and say what Y does in each state: on the phone it opens or puts away the panel.

3. **Don't change the main button's word under the thumb.** During a guided replay the draft's main button flips between "Your turn" and "Continue" at every held moment. One mis-tap then ends the replay. While a moment is held, the play button is the way on: the play symbol, with the spoken label "Continue". The main button stays "Your turn" for the whole replay. A ruling's Continue stays in the main slot only because "Your turn" never shows during a ruling.

4. **Add the missing actions to the main button's list.** The trick card today offers "Watch it", "Watch again", "Try again", "Next shot", "Watch yours in the Lens" and "Show the answer's path" (App/TrickShotViews.swift:20-34, 382). The draft's list only covers Continue, Your turn and Your shot. Order it as:
   - "Watch it", before the first watch
   - "Continue", for a ruling
   - "Your turn"
   - "Try again", after a missed attempt
   - "Next shot", after a make
   - "Your shot"

   "Show the answer's path" and "Watch again" go in the top-right menu. Today Try again is a full button, and burying it in the panel's menu hides the most-used retry.

5. **Keep Auto and all four speeds.** The code's speeds are a tenth, a quarter, half and full (App/PlaybackControls.swift:41), plus Auto, which hands the pace back to the paced replay. The draft drops the tenth speed and "Auto". The owner's complaint is "things happen way too fast", and Auto is the calm pacing. A label that "shows the rate actually playing" would change every frame while Auto paces. Show "Auto" or the fixed speed. Draw the speed capsule 32 high, but give it a 44-point tap area.

6. **Don't reuse the "more" symbol.** The draft shows the ellipsis on the top-right menu and on the aiming panel's menu at the same time, with different contents. That is the same one-symbol, two-meanings failure the inventory lists. Give the panel's menu the sliders symbol (slider.horizontal.3), labelled "Shot options". Fine controls then becomes a text item inside it.

7. **Keep Lens and the main button off the Lens colours.** The accent is cyan, which is also the Rolling colour (App/Theme.swift:127, 139). A cyan main button breaks "magenta and cyan mean only sliding and rolling". It also breaks the guidance against giving button labels a colour similar to what's behind them, because the Lens draws cyan under it. Tint the main button with a colour that isn't on the Lens: plain white glass with dark text, or a warm accent.
   - For Lens on, don't use a bold weight change: it changes the width and makes the joined glass jump. Keep the weight fixed.
   - Mark it on with the two-colour underline at three points, give it the selected state for VoiceOver, and say "On" as its value.

8. **Use one glass kind across the bottom strip.** Clear circles beside regular capsules in one row look patchy. The draft's "black circle at 35 per cent, always" also contradicts its own "no custom backgrounds". Use regular glass for the whole strip, because it carries words. Use clear glass with the dimming layer only for the two title circles, and only while the Lens is off, since the Lens view is already dark.

9. **The safe-area bar gives no edge fade over the table.** The scroll edge effect only works on scroll views, and the table isn't one, so nothing improves legibility at the top or bottom. Add a content-layer gradient, dark to clear, behind the title row and the strip, and fold it into the Reduce Transparency check. The camera should read the bottom safe-area inset after the bar is in place, not a measured preference. Say this in step 3.

10. **Say exactly how the panel morphs.** Shapes only morph where an identity is shared. Give the main button and the aiming panel the same glass identity, so "Your shot" grows into the panel. The other strip pieces fade out with the materialize transition. Use the glass effect with the interactive variant on plain buttons everywhere, instead of mixing glass button styles, so unions and identities apply the same way.

11. **An anchored blurb won't fit beside a centred moment.** The moment framing centres the focus at about x 201, which leaves roughly 185 points on each side, so a 260-wide blurb can't sit beside it. On the upright phone:
    - Anchored blurbs go above or below the anchor, centred on its x and kept inside a 16-point margin.
    - While a blurb shows, the framing puts the focus at about 35 per cent of the table area's height, with the blurb below it.
    - The leader is the Lens tips' 2-point line over a 4-point shadow, not 1 point, which is lost on the grid.

12. **Make ultra-thin material the minimum, not the default.** White text over saturated green cloth needs at least thin material. Use regular material for opened text.

13. **Give the top dock a stacking rule.** The Lens key, the first-minute instruction, notices, rulings and the first two Lens tips all claim y 114. Stack them in this order, top down, 6 apart: Lens key, ruling or notice, instruction, tip. The table framing starts below the lowest one.

14. **Don't fade the first instruction on the first drag.** An accidental touch would remove it for good. Keep the full sentence, "Drag on the table to aim. Pull back from the white ball, then push through it.", over two lines. "Drag back, push through" loses the word "aim". Fade it once the break is struck. Keep the "Calm zone ends" mark on the power bar (App/AimGauges.swift:310), which the draft drops silently.

15. **Removing minus and plus needs a VoiceOver path.** Make the power bar adjustable for VoiceOver in fixed steps, and say this in step 6.

16. **The match calling controls are wider than one Safety capsule.** App/Match/CallControl.swift uses Safety, the chosen pocket and "Call it" in one row that becomes a column at large text. That doesn't fit panel row 2 next to the cue angle and Shoot. While calling, the call row replaces panel row 2, and Shoot shows only after the call is made.

17. **Add a rule for what moves into the menu when the strip gets too wide.** At default size in German, and at accessibility sizes, the button row overflows. Move items out in this order: Ride, then Lens, then speed, but only once the rail is under 160 points. The main button never shortens its word. Its full title and transport symbols stay; the symbols grow with the text style but are never under 44 points.

18. **The title tap is an invisible way into "The idea", which is the core content.** Show the idea folded to one line as the docked blurb when the replay starts, with the "more" dot. A tap on the title can also open it, but give the title the button trait and a VoiceOver hint.

19. **Ride's table map can't share the title row.** At 258 points wide there's no room for both. Put Ride's status words in the title, and dock the map at the bottom-left above the strip as a content blurb, following the Ride hand-over plan.

20. **Ride's rule needs exact wording.** "Ride only for a finished shot with a collision" should say whether Ride is also offered during the trick replay, as today. Write it as a rule a junior can follow.