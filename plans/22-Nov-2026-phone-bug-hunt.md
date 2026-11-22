<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: Every bug a player can hit on a regular iPhone in 0.7.5 that survived an adversarial pass (nine finders, then two
         skeptics per finding, one asking whether a player can reach it and one re-reading the code). Written so a builder
         can fix each one from its entry. Found by reading the code; none was reproduced on a device.
SRP/DRY check: Pass - checked plans/ for an existing phone bug list; none. Design ideas for the Lens replay are not here.
-->
# Phone bugs found in 0.7.5

The Boss saw the ring and label drawn over the explanation card and the explained ball hidden under it on a regular
iPhone. This hunt looked at every phone screen. Each entry below was confirmed by both skeptics unless it sits under
"Judgment calls". Severity: Certain (follows from the code), Likely (depends on a size or length worked out from the code),
Cosmetic (visible but harmless).


## The root causes, in plain words

Most entries are a few causes showing up in different places. Fix the cause and its entries go together.

- A. The explanation card never measures or reports its real size. The camera frames the table above a short slot, the
  card grows up over the table anyway, the ring and label do not know where it is, Continue squeezes the words, and the
  worked equation comes and goes. Entries 1, 2, 3, 8, 9, 59, 60.
- B. The guided replay goes by too fast and stops in the wrong places. Every card lets go after the same short wait, two
  cards stop on one frozen frame, the Lens at normal speed flickers, the Lens tips point at nothing, and The Called Break
  never gets its slow replay at all. Entries 4, 5, 6, 7, 22.
- C. The physics drawings are sized for the whole table, so on a phone they come out smaller than the ring around them,
  and the zoom that should fix it aims at the wrong spot. Contact drawing, throw lines, spin marks, jump mark, ghost ball,
  target ring, last try's contact mark. Entries 14, 15, 16, 17, 40, 52, 65. This is the "don't shortchange the graphics"
  list.
- D. The slim-card setting hides what matters during a Lens replay: the trick's idea, the lesson's idea, a match ruling's
  button and its reasons, End match, and the right try number. Entries 32, 34, 35, 38, 41, 64. (Entry 32 freezes a match.)
- E. The bottom of the screen guesses heights instead of measuring them, so a taller row, card or panel pushes things below
  the fold or shrinks the table as it changes. Entries 10, 11, 13, 25, 28, 36, 44, 45, 48, 50.
- F. The roll-along camera: the spin through straight down, hard cuts, a view half as wide as intended, a lit button that
  does nothing on some tables, zoom gestures that land later, violet paths vanishing. Entries 18, 19, 20, 21, 24, 26.
- G. Words in other languages: the main menu's Play reading as media playback in French, Spanish, Japanese, Korean and
  Arabic; no plural forms anywhere (the catalog has none, checked); Russian mixing Latin and Cyrillic units (checked, two
  dozen strings); labels cut off at larger text; pocket directions that are wrong on an upright phone; one number that
  ignores the player's number style. Entries 12, 23, 27, 37, 39, 47, 49, 53, 55, 57, 58, 61, 62, 63.
- H. Single bugs with their own cause. Entries 29, 30, 31, 33, 42, 43, 46, 51, 54, 56.

The card-and-camera piece proposed for the Lens replay covers A, most of B and C, and part of E.

How sure: nine finders read the code area by area, then two skeptics per finding tried to knock it down, one asking
whether a player can actually get there and one re-reading the code. Nothing was reproduced on a device; "Likely" entries
rest on sizes and lengths worked out from the code.

## The explanation card and the guided replay

### 1. Event ring and its title pill draw over the explanation strip

- Severity: Certain  (earlier lead S1)
- Where: Guided Physics Lens replay, phone held upright, ball near the table's near (bottom) end, e.g. the Throw beat of The Called Break
- What the player sees: The coloured ring and the glass pill with the caption title sit half on the explanation card, or right across its words
- How to get there: Trick shots > The Called Break > Watch it, then Replay with the Lens (or Watch yours in the Lens after a make); wait for a beat whose ball is in the near half of the rack
- Cause: CaptionStrip deliberately never writes leader.card (CaptionViews.swift:288), so visibleRing (515-519) never hides a ring under the strip and chipCenter's fits() (531-535) never avoids it. The pill is clamped only to leader.stageRect, which on a phone is the whole stage including the bottom stack (ShowpieceView.swift:400-402, CaptionViews.swift:528, 539-540); there is a top clamp (topClear) but no bottom one. CaptionLeader is drawn above the whole stage and its bottom stack (ShowpieceView.swift:205).
- Fix: In CaptionStrip, report the glass card's frame in stage space to leader.card, and set it back to zero when no caption shows or the strip goes away. Then also cap the pill's centre so its bottom stays above the top of leader.card.

### 2. Long captions grow up over the table's near end, unseen by the camera

- Severity: Certain  (earlier lead S2)
- Where: Guided Lens replay, phone upright, any caption longer than a title plus three lines (Throw, Energy handed off with a bend, a headline beat with its equation)
- What the player sees: The glass card climbs well above its reserved slot and covers the near rail, pockets and balls at the table's near end; on the Throw card about 140 points of table are hidden
- How to get there: Any guided Lens replay of a break or trick shot; Throw is about sixty words in English and longer in German or French
- Cause: The strip's frame is fixed at the sizer height and bottom-aligned (CaptionViews.swift:312-330), but its content sits in FittingScroll(maxHeight) whose cap is 28% of the screen, about 245 pt (ShowpieceView.swift:441; CaptionViews.swift:316), so anything between roughly 105 pt and 245 pt overflows upward. The sizer reserves only a title and three lines and leaves out the headline equation line (CaptionViews.swift:333-339 passes no headline). controlsTop is measured from the bottom stack's frame (ShowpieceView.swift:475), so the camera never sees the overflow.
- Fix: Hold the strip's content to its reserved height: pass min(reservedHeight, maxHeight), not maxHeight, to the strip's FittingScroll (CaptionViews.swift:316), and reserve the equation line whenever a headline beat is held, so a long caption scrolls inside its slot instead of drawing over the table.

### 3. Continue squeezes the words into a narrow column, then the card jumps when it goes

- Severity: Certain  (earlier lead S3)
- Where: Guided Lens replay, phone upright, while a beat is held
- What the player sees: The caption text is wrapped into a narrow left column beside the Continue button; when the hold ends the button fades, the text re-wraps wider and the card's top edge drops mid-sentence
- How to get there: Any guided Lens replay; watch a held beat until it times out
- Cause: Continue sits in the same HStack as the words (CaptionViews.swift:314-324) and is fixedSize (203-205), taking about a third of the card's width (more for Continuer, Continuar, Продолжить). It appears only while model.holding, so when the hold ends the HStack loses it, FittingScroll re-measures, and the card height animates (342).
- Fix: In CaptionStrip, reserve the button's room for the whole guided replay: replace "if model.holding { ContinueButton(...) }" with "if model.guided { ContinueButton(model: model).opacity(model.holding ? 1 : 0).allowsHitTesting(model.holding) }", so the width of the words never changes during the replay.

### 4. Every held explanation lets go after six seconds, whatever its length

- Severity: Certain  (earlier lead S13)
- Where: Guided Lens replay, any layout
- What the player sees: A sixty-word Throw card is held for six seconds, then the replay moves on and the next beat replaces it before it can be read
- How to get there: Any guided Lens replay with a long caption (Throw, Energy handed off with a bend sentence, the stroke sentence added to a strike)
- Cause: readingTime clamps to maxDwell = 6 s (PacePlan.swift:81-82, 259-263); sixty words would need about 21 s at the plan's own reading rate. The hold ends when holdElapsed reaches that dwell (ShowpieceModel.swift:3654, 3686-3687).
- Fix: Keep the six-second cap only for the first-launch style and the menu backdrop; for every other guided replay with explanations on, set the dwell from the uncapped reading time (words divided by three, plus one).

### 5. Two long cards held back to back on one frozen rack; the called ball's drop is never a stop

- Severity: Likely  (earlier lead S14)
- Where: Guided Lens replay of a break (The Called Break, the showpiece, the player's own break)
- What the player sees: The replay stops on the first hit, then a millisecond of clock later stops again on Throw: two six-second holds on the same picture of the rack. The moment the called ball drops is not held
- How to get there: Trick shots > The Called Break, make it, then Watch yours in the Lens (or Replay)
- Cause: PacePlan always takes the first hit and then the first contact thrown a degree or more (PacePlan.swift:164-165, 179-180); in a rack the second-row contact comes about a millisecond later, and the clock crawls at the slow rate between them. The Called Break's signature is only the first contact (TrickSignature.swift, called-break case), so the signature cap of four beats (PacePlan.swift:151-152) fills with strike, first hit, throw, then a bend or jaw, which are taken before first(.pocket) (181-185); nothing names the called ball.
- Fix: In PacePlan, skip any candidate caption within a few hundredths of a second of a beat already chosen, and add the called ball's pocket event to TrickSignature's called-break candidates.

### 6. Lens on after a shot plays at real speed with captions flickering

- Severity: Certain  (earlier lead S15)
- Where: Free play or a match, phone upright, Lens on
- What the player sees: After a shot, turning the Lens on and pressing Play (or shooting with the Lens already on) runs the replay at full speed; the explanation strip swaps its words many times a second through a break, the card changes height with each swap, the ring hops from ball to ball, and no Continue ever appears. The speed menu reads 1x, not Auto
- How to get there: Free play: take a shot, tap Physics Lens, tap Play
- Cause: Every struck shot stores chosenRate = 1 (ShowpieceModel.swift:984-985), and guided pacing needs chosenRate == nil (3602-3603), so only the Replay button (2539) brings back pacing. Unguided captions show the latest event for 3.4 s of clock (3727-3737), so at 1x during a break each new event replaces the last; the strip animates every id change (CaptionViews.swift:327, 341, 344-346).
- Fix: In the unguided branch of activeCaption, while the Lens is on, show only the latest pace-plan beat caption (pacePlan.beats), not every event caption, so 1x Lens playback (a player's own shot with the Lens already on, or Lens then Play) gets readable, stable captions without bringing back the slow replay the 0.7.1 decision removed.

### 7. Lens tips point at trails that do not exist yet

- Severity: Certain
- Where: First Lens replay the player starts themselves, with the Lens tips not yet seen
- What the player sees: The callout says Magenta path: the ball is sliding, then Cyan path: rolling, but no trail is on the table and no pointer is drawn; the replay is frozen on the strike until the tips are dismissed
- How to get there: Fresh install or Options > Show the Lens tips again; take any shot, then tap Replay (Lens on)
- Cause: The tips start on the first guided hold (LensCallouts.swift:53-55), and the first beat is always the cue strike (PacePlan.swift:164), which is recorded at time 0 (BreakdownPhysics Simulation.swift:536). Trails are transparent for any time still in the future (LensLayer.swift:46), and target(phase:) only looks at stretches with t0 < now (LensCallouts.swift:185), so it returns nil and drawPointer draws nothing; holdForTips keeps the clock there (ShowpieceModel.swift:3685).
- Fix: In LensCallouts.due, also require that the held beat is past the strike (for example model.time > 0), so the tips start on the first-hit beat, after the sliding trail has been drawn.

### 8. Throw label and ring sit on the cue ball, not the ball that was thrown

- Severity: Certain  (earlier lead S21)
- Where: Guided Lens replay, a Throw beat
- What the player sees: The ring and the Throw pill circle the striking ball while the words describe the struck ball being dragged off the line of centres
- How to get there: Trick shots > Throw it (or any cut with throw), Watch it; or The Called Break's Throw beat
- Cause: The anchor follows the ball with the larger speed before the contact (CaptionViews.swift:486-487), which is the mover; the Throw sentence is about ThrowFacts.object, the ball that was at rest (Captions.swift:749-754). For a plain Energy handed off caption, following the mover is fine; only Throw is wrong.
- Fix: In CaptionViews.anchor, when Captions.throwFacts(event) is not nil, use its object ball instead of the faster ball (only for a Throw caption, not for every ball-to-ball event that happens to have throw).

### 9. Overflowing caption is clipped off when the bottom cards scroll

- Severity: Likely  (earlier lead S4)
- Where: Phone upright, Lens on, at the end of a guided replay or while aiming with the Lens on, at larger text sizes
- What the player sees: The top of the explanation card, title and first lines included, is cut off at the top of the scrolling card area and cannot be scrolled into view
- How to get there: Free play or a trick with Your shot open, Replay with the Lens; when the replay ends, Your shot comes back, cards go full again and the strip keeps its last caption
- Cause: The strip sits inside the bottom stack's FittingScroll (ShowpieceView.swift:431, 438-443). When the cards exceed the cap the content becomes a ScrollView (Surfaces.swift:47-49), which clips, and the strip's upward overflow lies outside its laid-out frame, so it is neither shown nor scrollable. At the replay's end the slim cards turn full and Your shot reopens (ShowpieceView.swift:222-228, 495-497) while the strip keeps its last caption (CaptionViews.swift:303, 344-346).
- Fix: In CaptionStrip, cap the inner FittingScroll at the strip's laid-out height (maxHeight: height) instead of maxHeight, so a long caption scrolls inside its own frame and never overflows outside the outer ScrollView.

### 10. Playback row's fixed 124-point allowance: buttons fall to two rows in most languages, stack (with a fourth What if row) at larger text, and the bottom stack eats the table

- Severity: Likely  (earlier lead S5)
- Where: Phone upright, bottom of the screen, any mode (free play, a match, a trick, a guided Lens replay), default text size in long languages and any of the larger and accessibility text sizes
- What the player sees: In German, French, Portuguese, Japanese and Russian at the default text size, Lens, Ride and Your shot do not fit one row, so Your shot sits alone on a second row; at the largest standard size the buttons also fall to two rows and overshoot. At the accessibility sizes the playback block (scrub row plus full-width Physics Lens, Ride, Your shot rows, and after any eligible shot at rest a fourth worded What if row) is two to three times the room set aside for it. The cards still take their full share above it, so the bottom stack takes most of the screen and the table shrinks to a thin band or the minimum sliver.
- How to get there: Settings > Language > Deutsch (or French, Portuguese, Japanese, Russian), open the app; or Settings > Display & Text Size > Larger Text, pick any accessibility size, open a match or free play with a card showing; for the What if row, in free play shoot a shot and wait for the balls to stop.
- Cause: playbackRowAllowance is a plain constant of 124 points with no text scaling (ShowpieceView.swift:484), sized for one button row and subtracted from the cards' cap (431). ViewThatFits falls to twoRows (PlaybackControls.swift:252-257, 276-286) for labels like Mitfahren and Dein Stoß, about 170 pt, and at the largest standard size. At accessibility sizes PlaybackControls uses the stacked layout (PlaybackControls.swift:248-249, 289-302), around 300 pt: three full-width large buttons plus the scrub row, and stacked appends WhatIfButton(fill: true) as a fourth full-width row (289-301). The outer VStack (ShowpieceView.swift:430-465) has no cap, so the extra height is taken from the table, whose inner bottom is clamped only to at least top + 40 (CameraFraming.swift:120-122).
- Fix: Measure PlaybackControls' real height with onGeometryChange into a state value, and subtract that plus the 10-point gap from the cards' cap (ShowpieceView.swift:431) instead of the fixed 124.

### 11. Sideways phone: the Lens explanation card and Continue sit below the fold of the side column, and the leader line runs off-screen across the cards

- Severity: Likely
- Where: Phone turned sideways (side column), Lens on: a guided Lens replay of a trick shot's answer (explaining phase), or the what-if open with a Replay or guided Play both
- What the player sees: The column shows the trick card with The idea (or the what-if card first); the explanation card and its Continue button are scrolled out of sight below it, several hundred points further down, and the replay holds and moves on with nothing visible to read. The leader line from the event ring still aims at that hidden card: it runs from the ball across the table and across the what-if card's words to the bottom edge.
- How to get there: Turn the phone sideways, Trick shots > Stop dead (or any non-break shot) > Watch it. Or in free play, shoot a shot, open the what-if, nudge once, then tap Replay.
- Cause: In the side column CaptionArea comes after every mode card (WhatIfCard first) inside the ScrollView, with the playback controls pinned below (ShowpieceView.swift:537-567, 539-551, 563-567). On a sideways phone the controls take two rows plus the scrub row, leaving roughly 210 pt of scroll area; the full trick card in explaining (no slim form outside the upright bottom stack, 468) is taller than that, so the CaptionArea card (CaptionViews.swift:259-266) starts below the visible area and nothing scrolls it in. CaptionArea reports its laid-out frame even when scrolled off-screen (CaptionViews.swift:264). CaptionLeader, drawn above the column, draws its line to the nearest point of that rect when showLine (= split) is set (ShowpieceView.swift:205; CaptionViews.swift:583-589).
- Fix: In sideColumn, show CaptionArea above WhatIfCard and the mode cards while the Lens is on with guided pacing, and clear leader.card whenever the card's frame falls outside the column's visible scroll area.

### 12. Speed menu reads "Automatisch" and squeezes the scrub bar in German, Italian and Portuguese

- Severity: Likely
- Where: Upright phone, the playback row (pause, scrub bar, speed, replay, What if)
- What the player sees: The speed button's label is "Automatisch", "Automatico" or "Automático" instead of a short "Auto", so the scrub bar between pause and the speed button is roughly a third shorter than in English. After the player's own shot, when What if also sits in the row, the bar shrinks to about 90 points, which makes scrubbing to a moment noticeably coarser. At the larger text sizes it shrinks to a stub that is hard to drag.
- How to get there: Set the phone to German, Italian or Portuguese. Normal launch, Trick shots, any shot, Watch it (any guided Lens replay). Compare the scrub bar's length with English.
- Cause: PlaybackControls.swift 147-153 (150) shows String(localized: "Auto") at fixed size (197: .fixedSize()) in the scrub row, and the scrub bar takes whatever width is left (194). The catalog translates "Auto" as "Automatisch" (de), "Automatico" (it) and "Automático" (pt, pt-BR), three times the English length; Spanish, French and Russian kept a short word. Everything else in the row has a fixed width (44-point buttons, 10-point gaps), so the scrub bar loses the difference.
- Fix: Give the speed button in the scrub row its own short catalog entry (for example a "Speed menu: Auto" key translated as "Auto" in German, Italian and Portuguese), and keep the full word for the list row and VoiceOver.

### 13. Third Lens tip floats over the table, its arrow pointing at blank space above the bar

- Severity: Cosmetic
- Where: Lens tips, step 3 of 3 (the scrub bar), phone upright
- What the player sees: The bubble with the down arrow sits well above the bar, over the table's near end, with an empty gap the height of the explanation slot between it and the bar it points at
- How to get there: First player-started Lens replay with tips enabled; tap Next twice
- Cause: The bubble is placed just above controlsTop (LensCallouts.swift:136-148), but controlsTop is the top of the whole bottom stack (ShowpieceView.swift:475), which includes the caption strip's reserved room (438-443); while tips show the strip is blank but keeps its room (CaptionViews.swift:301-303).
- Fix: Measure the playback row's own top in stage space and give it to the third tip's bubble as its bottom anchor, instead of the whole bottom stack's top.


## The Lens drawings and the zoom

### 14. Close-up and double-tap zoom aim at the screen centre, so the held moment or tapped ball lands high, near or under the title row

- Severity: Certain  (earlier lead S7)
- Where: Any table view on an upright phone with the bottom cards up (guided Physics Lens replay of a trick shot, ordinary play, a match). Worst in the Lens replay, where the strip, slim trick card and playback row fill the bottom.
- What the player sees: When a guided replay holds a signature moment, the 1.8x close-up does not centre that moment in the free space above the cards. It always puts it at the same spot, about 1.8 times the gap between the screen centre and the free-area centre above the screen centre. At default text size that is around y≈210 instead of y≈310, near the top, with neighbouring balls under the title row. Double-tapping a ball to zoom on it (2.5x) puts the ball at about y≈120, on the bottom edge of the title-row glass. With bigger cards (large text, a tall caption) it goes under the title row or off the top. Pinching also lets the table creep upward away from the fingers. The two-finger pan can move the view past the end of the table even though the zoom says the table can never leave the screen.
- How to get there: Launch, then Trick shots and any trick, e.g. The Called Break. Play it or watch the answer with Lens on (guided pacing) and wait for a held signature beat: the view zooms but the moment sits well above the middle of the table area. Or, in the Lens or the warm view with the bottom cards up, double-tap any ball: it jumps up to the title row instead of the middle of the table area.
- Cause: CameraFraming.pose slides the camera sideways and up (CameraFraming.swift:226,231-232) so the table is centred in the space between the title row and the bottom stack (ShowpieceView.swift:475 sets controlsTop to the top of the bottom stack). Its target is just position + forward, so the screen centre looks at a cloth point well toward the near end, not the table middle. TableZoom.apply zooms about that screen-centre point (TableZoom.swift:227-231) and adds the offset to it. focus, closeUp and pinch all set the offset as if the fitted look point were the table middle (comment and formula at TableZoom.swift:116-118; 147-149; 160-161; SignatureCloseUp.swift:73). So the event ends up at screen centre + magnification x (free-area centre - screen centre), not at the free-area centre. The look-point clamp (TableZoom.swift:103-104, 212) bounds the offset, not the real look point, so the 'never leaves the table' promise fails by the same amount.
- Fix: In TableZoom.apply, scale and move the camera about the cloth point that sits under the inner framing rectangle's centre (TableCamera passes it in; it is about the table middle), keeping the look direction: newPosition = Q + offset3 + (position - Q) * scale, newTarget = newPosition + dir. Clamp Q + offset to the table.

### 15. Held-hit contact drawing is smaller than the caption ring drawn over it, with lines under a point wide

- Severity: Certain  (earlier lead S8)
- Where: Physics Lens on an upright phone, guided replay held on a ball-to-ball hit (e.g. the Called Break's first hit or Throw beat), whole-table framing.
- What the player sees: The table is about 150 points per metre on screen (2.7 m of playing area between the title row and the cards). The line of centres and the tangent each reach two ball widths either side of the contact, about 34 points end to end. Their bright cores are well under a point wide (strips 6 mm and 5 mm wide, bright core about a third of that). Both sit almost entirely inside the 40-point, 2-point-thick caption ring centred a ball radius away, so the ring reads as the drawing and the lines are lost inside it. The right-angle mark is about 3 points on a side with a half-point bar. The momentum-triangle shafts are about a point wide with heads about 3 points long. The title pill beside the ring sits over the rightward arrows. The impact ring for the held hit is frozen at its smallest size because the clock stands still on the event, and much of it lies under the two touching balls.
- How to get there: Launch, Trick shots, The Called Break (or any trick with a ball-to-ball signature hit), Lens on with explanations, guided replay. Wait for the hold on the first hit or Throw and look at the contact.
- Cause: Every part is sized in table metres with no regard for the on-screen scale. Line reach is 2 ball diameters (LensLayer.swift:195, used at 1201). Strip half-widths are 0.003, 0.0025, 0.003 m and the corner-mark bar is 0.09 of 0.7 R (LensLayer.swift:1112-1115, 1249). Arrow shafts are 0.004 m and heads 0.022 by 0.011 m (LensLayer.swift:1117-1118, 209). The soft-line picture's bright core is only the central third (LensTextures.swift:81). The caption ring is a fixed 20-point radius with a 2-point stroke (CaptionViews.swift:510, 595), centred on the faster ball (CaptionViews.swift:487). Framing gives about 150 pt per metre upright (TableCamera.swift:183-186, CameraFraming.swift:110-126). The ring's impact flash at tau 0 has radius 0.022 + 0.034 x impulse (LensLayer.swift:645, 999).
- Fix: Make the contact strips, the corner mark and the arrows at least about two screen points wide, using the camera's points per metre, and hide the caption ring while the contact drawing is up.

### 16. Throw lines cannot be told apart on a phone: a one-degree throw separates them by about a point

- Severity: Certain
- Where: Physics Lens on an upright phone, guided replay held on the 'Throw' beat (the card in the owner's photos), or any hit with throw of half a degree or more.
- What the player sees: The two throw lines from the struck ball (dashed line of centres and solid real departure) are each about 75 points long and about a point wide. For a one-degree throw their far ends are about 1.3 points apart, three degrees about 4 points. With the glow halo they read as one line. The 'Throw' card explains a split the picture does not show. The first few points of both lines are under the struck ball.
- How to get there: Launch, Trick shots, The Called Break (or Throw It In), Lens on, guided replay. Wait for the 'Throw' hold and look at the struck ball.
- Cause: Line length is fixed at 0.5 m and width at 0.0035 m half-width (LensLayer.swift:191-192, 275-276), laid from the struck ball's centre (LensLayer.swift:668-678). The comment at LensLayer.swift:188-190 assumes 9 mm 'reads at the normal camera distance', true for a large window but about 1.3 points at the upright phone's ~150 points per metre. Throw is drawn from half a degree (Captions.swift:492).
- Fix: In LensLayer.swift around line 676, replace the fixed throw-line scale with a screen-based one, scaling both length and width by the current metres-per-point (with a minimum on-screen gap) instead of SIMD3(throwLineLength, 1, 1).

### 17. Jump height mark sits hidden under the flying ball in the overhead Lens

- Severity: Likely
- Where: Physics Lens (straight-down view) on a phone during a jump shot.
- What the player sees: The dot meant to show height under a flying ball is exactly the ball's radius and sits straight below it, while the Lens draws the ball 8% larger from almost directly above. There is no visible gap between dot and ball, only a faint lightening through the half-transparent ball. Only the white dashed trail marks the jump, and how high the ball went cannot be read.
- How to get there: Launch, Trick shots, Jump the Blocker, Lens on, watch or scrub through the jump.
- Cause: Dot radius is set to frame.ballRadius (LensLayer.swift:499). It is placed directly under the ball and faded as it climbs (LensLayer.swift:964-976). The design note says 'the gap between dot and ball reads as height' (LensLayer.swift:964-965), but that gap only exists in an angled view. The Lens looks down at 89 degrees (TableCamera.swift:186) and balls are 1.08x in the Lens (TableScene.swift:278), so the ball covers the dot except for tiny parallax.
- Fix: Replace the ball-wide dot with a ring on the ball's ground spot that is always a few points wider than the drawn ball and grows with height, so its edge stays visible from straight above.


## The roll-along (Ride) camera

### 18. Ride blend spins the whole picture on an upright phone (and snaps a quarter turn over the Lens)

- Severity: Certain  (earlier lead S9)
- Where: Any replay with Ride on, phone held upright: the half-second switch into the ride at the strike, and the rise back to the table at the end of the ride
- What the player sees: Upright, the table view looks from the rack end (rack at the bottom of the screen, cue ball at the top), so a break or any shot sent down the screen rides the opposite way to the table camera. As the blend runs, the picture rolls through a half turn in a few frames when it switches in, and rolls back the same way as the ride rises at the end. Over the Lens (looking almost straight down) the roll happens in the first two or three frames, so it reads as a sudden flip; sideways it is a quick quarter-turn snap instead. The sound panning flips left and right at the same moment.
- How to get there: Trick shots > The Called Break > Watch it with the phone upright (Watch it turns Ride on and the break heads down the screen). Or: turn Ride on, then menu > Watch the intro: the slow Lens replay rides and flips as it starts and again when the ride ends. Or in free play: Ride on, break.
- Cause: ShotCamera.swift 237-246 (mix) blends the two look directions component by component and then normalizes. Upright the table camera sits at +x looking toward -x (TableCamera.swift 181-182; CameraFraming.swift 185-186, so its sideways component is exactly zero), and the rack end is at high x (TableFrame.swift 33-35; NextShot.swift 104 foot spot at three quarters of the length), so a break's ride direction is +x. Partway through the blend the x parts cancel and the blended direction points straight down, parallel to the fixed world-up passed to camera.look at TableCamera.swift 247, so the roll is undefined and flips. The length guard at ShotCamera.swift 241 does not catch it (the vector is about 0.8 long there). The weight comes from engage at ShotCamera.swift 226-229 and from the rise at 251-257, so it happens at both ends. Over the Lens the table view's flat component is only about 0.02, so any heading takes over almost at once.
- Fix: In ShotCamera.mix, turn each shot's look into a rotation (simd_quatf from its forward and its own screen-up) and blend those with simd_slerp, then have TableCamera set the camera's orientation from the blend instead of using camera.look with a fixed world-up.

### 19. With Ride already on, every next shot and every Replay cuts straight into the chase view

- Severity: Certain  (earlier lead S9)
- Where: Free play (or any mode that shoots from where the balls stopped) and Replay, Ride left on
- What the player sees: Only the first shot after switching Ride on eases into the ride. On every later shot, the moment the stroke lands the table view is replaced in one frame by the low view behind the cue ball. Pressing Replay at the end of a ridden shot does the same: a hard cut from the overhead to the chase view at time zero.
- How to get there: Free play: tap Ride, take a shot (this one eases in), let it finish, aim and take another shot: a hard cut at the strike. Or after any ridden shot ends, press Replay in the scrub row.
- Cause: The only easing is engage, which follows the active flag in wall time (ShotCamera.swift 222-229). Active is ShowpieceModel.rideActive (ShowpieceModel.swift 1026), which stays true while aiming because aiming happens in the explore stage, so engage sits at 1 between shots. The ride pose itself is a pure function of the clock (riseWeight, ShotCamera.swift 251-257: 1 at the end of a shot, 0 at its start). When a new recording is loaded (TableScene.swift 129/222 into ShotCamera.load at 210-215) and the clock is set to 0 (ShowpieceModel.swift 984 in finishStrike; replay at 2531-2537), the weight jumps from 0 to 1 in one frame.
- Fix: In ShotCamera, set engage to 0 inside load(_:frame:), and also in override when the clock jumps back to the start (clock below 0.05 while the previous clock was later), so every new shot and every Replay eases in over half a second, as the first ride does.

### 20. Upright, the Ride lens is about half as wide as intended, and the cue ball sits at the edge of the cards

- Severity: Certain  (earlier lead S12)
- Where: Any Ride replay with the phone held upright
- What the player sees: The ride is a narrow, zoomed-in view. Only about 31 degrees across the screen (about 0.4 m of cloth at the cue ball), so on a cut the object ball runs out of the side of the frame within a few tenths of a second, and most of the rack is cropped on a break until the crane. The cue ball is drawn about 11 degrees below the centre of the free area. With a tall stack of cards under the table (the Lens explanation strip plus a full card plus the playback row), that puts it at or under the top of the cards.
- How to get there: Free play upright: Ride on, play a cut shot or a break. For the cue ball under the cards: Ride on, Physics Lens on, press Replay, so the explanation strip and cards are up while it rides.
- Cause: ShotCamera.swift 299-303 (rideFov) asks for 64 degrees across the narrow side, which needs about 107 degrees vertical on 402 by 874, then clamps to 62 vertical. That leaves 2·atan(tan 31° × 402/874) ≈ 31° horizontal. Sideways the same clamp pushes up to 46 vertical and about 85 across, so the clamp, not the intent, decides. Eye 0.62 m back and 0.42 m up with the aim point 0.38 m ahead (ShotCamera.swift 201-204) puts the cue ball about 11 degrees below the aim point. frameInFreeSpace (308-319) centres the aim point, not the ball, in the free rect (TableCamera.swift 196, 231), so a short free area leaves the ball at or under its bottom edge.
- Fix: In App/ShotCamera.swift, on a tall screen set the ride field of view so it is about 64 degrees across (up to about 100 tall), and in frameInFreeSpace place the cue ball, not the point ahead of it, in the lower third of the free area.

### 21. Ride lit but nothing rides when the striking ball is not ball zero (five-pin seat two, bumper pool, bar billiards)

- Severity: Certain  (earlier lead S10)
- Where: Table games from the Tables list, any layout: a match on five-pin billiards (second player, or the computer's shots), bumper pool (second player/side, or the first once their marked ball is down), bar billiards after the first white is down
- What the player sees: The Ride button is lit and the shot plays in the ordinary table view. No ride, no slow motion at the contact. The cue's follow-through after the strike is also missing, and the automatic close-up of the contact never comes, because both step aside for a Ride that never flies. Switching Ride on after such a shot does not replay it either.
- How to get there: Tables > five-pin billiards > start a two-player match, turn Ride on, play the first player's shot (it rides), then the second player's shot (it does not). Or Tables > five-pin (or bumper pool) against the computer, tap Ride, then watch the computer's shot.
- Cause: RidePlan only ever reads ball 0: its start speed, cueStart and cueStop (ShotCamera.swift 72-76, which returns not rideable when ball 0 is still), its first contact (80-82) and its heading track (438). The striking ball is match.cueBallIndex (ShowpieceModel.swift 1229; strikeBall itself is fine), coming from rules.cueBall (MatchMode.swift:229): five-pin seat two strikes ball 1 (FivePinRules.swift 22, 57-59; playerBalls is [0, 1]), bumper pool seat two strikes balls 9 to 13 (BumperPoolRules.swift 21, 46-49), and bar billiards' striker moves on once ball 0 is down (BarBilliardsRules.swift 50, 72-74). For any other striking ball the plan stays empty, so setRide's replay check fails (ShowpieceModel.swift:1036). Meanwhile rideActive (ShowpieceModel.swift 1026) is true, so CueRig hides the follow-through (CueRig.swift 208) and SignatureCloseUp is blocked (SignatureCloseUp.swift 57). The button reads only rideOn and has no disable (PlaybackControls.swift 231-234). The seed's second half (the button staying lit after a ride ends) is how any toggle works and is not claimed.
- Fix: Build RidePlan and RideTracks on the struck ball (lastInput?.strike.ballIndex, defaulting to 0) instead of the fixed ball 0, and make rideActive also require ridePlan.rideable.

### 22. The Called Break never gets its slow Physics Lens explanation; Watch it only rides the break at speed

- Severity: Certain  (earlier lead S6)
- Where: Trick shots, The Called Break, after Watch it (Explaining phase)
- What the player sees: Watch it plays the break once at real speed, riding behind the cue ball (with the upright-phone roll flip described in the Ride blend finding). The card then switches to 'The idea' over a still table with the Lens off. No slow Lens replay follows, although the Watch it button says the answer will be explained in the Physics Lens. Every other trick shot gets its slow guided Lens replay here. The break's own moment (the push into the rack, which the trick's pacing list includes) is never held. The only way to get a Lens replay is to press Replay on the playback row. On an upright phone that then switches the trick card to its slim form (see the slim trick card finding), which is how the owner's photos were taken.
- How to get there: Launch, open the menu, Trick shots, The Called Break, Watch it. Wait for the balls to stop.
- Cause: TrickShotMode.swift:266-272 skips the Lens replay for breaks ('if !shot.isBreak'), on the stale belief that 'the break already replayed itself slowly in the Lens during its opening'. Since 0.7.1 every struck break plays at real speed in the ordinary view with the Lens left off: ShowpieceModel.swift:977-985 (stage = .explore, chosenRate = 1). TrickShotMode.watch() (TrickShotMode.swift 175-186) turns Ride on, turns the Lens off and calls breakNow (180, 184). The button's promise is at TrickShotViews.swift:353-357. TrickSignature.swift:33 maps 'called-break' to its first hit, but that list is never applied to the answer.
- Fix: In TrickShotMode.update() at line 269, and in recordingReplaced at line 338, drop the !shot.isBreak guard so the break also sets its pacing list and calls model.replay(withLens: true) when it reaches the explaining phase.

### 23. Pocket directions in trick-shot and lesson text are wrong on an upright phone (The Called Break says top-right; the pocket is bottom-right)

- Severity: Certain  (earlier lead S22)
- Where: Trick card (hook in Ready, goal line while aiming) and the lesson card, phone held upright
- What the player sees: 'Break and drop the 3 in the top-right corner' (The Called Break), with the marked pocket ring at the bottom right of the screen. The same applies to The Massé, Jump the Blocker and Squirt ('top-right', shown bottom right), Throw It In ('bottom-left', shown top left), Side Off the Rail ('bottom-right', shown bottom left) and the Cut and throw lesson ('top-right', shown bottom right). The words are only right with the phone turned sideways.
- How to get there: Trick shots, The Called Break (or Massé, Jump the Blocker, Squirt, Throw It In, Side Off the Rail), phone upright. Read the card and compare it with the ringed pocket. Also Lessons, Cut and throw.
- Cause: The words are written for the sideways view (camera on the y = 0 side, screen right = +x, screen up = +y). The camera turns the table a quarter turn when upright: TableCamera.swift:181-182 (yaw = pi/2 when width < height). CameraFraming.swift:185-188 puts the camera on the +x side, with screen-right along world -z and screen-up along world -x. TableFrame.swift:33-35 maps table y to world -z. So on an upright phone, screen-right is table +y and screen-up is table x = 0. Pocket 3 (2.54, 1.27) (Parameters.swift 251-253; AuthoredTricks.swift 55 drop 3 into pocket 3) is bottom-right, pocket 0 (0, 0) is top-left and pocket 1 (2.54, 0) is bottom-left. The pitch is 89 degrees in the Lens and lower in the warm view, but the yaw is the same, so the answer is the same in both. Sideways, yaw is 0 and the words are correct. The words are fixed screen directions at TrickShots.swift:207-208, 278, 288, 298, 320, 334 and Lessons.swift:220 (goals: AuthoredTricks.swift:55, 142, 161, 177, 226, 244; AuthoredLessons cut drop pocket 3). Behind the 8-Ball (EightBallSituations.swift) uses table words (foot-left corner, head rail) that do not change with orientation, so top and bottom are the exception, not a house style.
- Fix: Replace the screen words (top-right, bottom-left, bottom-right) in TrickShots.swift and Lessons.swift with table words that stay true whichever way the phone is held, for example "the far corner beyond the rack", and update the matching entries in Localizable.xcstrings.

### 24. Pinch and double-tap zoom do nothing during a ride, then the table lands zoomed afterwards

- Severity: Likely
- Where: Any replay while the Ride camera is flying
- What the player sees: Pinching or double-tapping during the ride has no visible effect. When the ride rises back to the table, the view eases into a zoom the player had given up on.
- How to get there: Ride on, take a shot, pinch on the table while the chase view is up, and watch the end of the ride.
- Cause: TableCamera.swift 223-233 applies the hand zoom to the table pose first and then hands that pose to ShotCamera.override, which at full ride weight returns the ride pose and ignores it (ShotCamera.swift 228-233). TableZoom.pinchChanged and panChanged (TableZoom.swift 109-135) have no check for Ride and keep updating the goal.
- Fix: In TableZoom pinchChanged, panChanged and the double-tap handler, ignore the gesture while the model's rideActive is true (or call springBack when the ride ends), so a zoom never lands after the ride.


## The what-if replay

### 25. The what-if card swallows the card share on an upright phone and shrinks the table to a strip with balls about 5 points across

- Severity: Likely
- Where: Free play (or a judged trick shot / lesson / 8-ball try), phone upright, what-if card open after one nudge
- What the player sees: On open, the card shows its prompt and the table stays fairly big. After the first nudge, the sentences (up to six), a second nudge row on Spin, and Play both / Where they part / Keep this one (which wrap onto two rows) make the card about 490 to 600 pt tall. The bottom stack caps at its share, so the table reframes into roughly the top third of the screen. The cloth ends up about 250 pt long, the ghost balls are rings about 5 pt across, and the 12 pt parting diamond is bigger than the balls it marks. The card scrolls, and Play both and Keep this one sit below the fold. Reset, or nudging back to As played, shrinks the card, the table grows again, and the next nudge shrinks it again.
- How to get there: Launch, then Practice / free play. Aim and Shoot any non-break shot and wait for the balls to stop. Tap the branch icon beside Replay in the scrub row, then tap any + or chevron once.
- Cause: WhatIfCard is mounted in the phone bottom stack (ShowpieceView.swift:445) inside FittingScroll capped at height*0.62 minus playbackRowAllowance (ShowpieceView.swift:426, 431). The card has no slim or phone form: header, fixed line, picker, NudgeRows with 44 pt glass buttons, uncapped sentences and CardButtonRow (WhatIfViews.swift:57-76, 112-163; WhatIfWords.swift:287-295). The camera fits the playing area between the header and controlsTop (CameraFraming.swift:117-123, measured at ShowpieceView.swift:475). The overlay's ghosts and paths are sized in table metres while the diamond is a fixed 6 pt half-width (WhatIfOverlay.swift:103-122 vs 134-140). Estimated: about 91 pt per metre with the card vs about 227 without, so a ball radius of about 2.6 pt.
- Fix: On an upright phone, give WhatIfCard a compact form with a fixed reserved height: header and nudge row, a one-line result that expands on tap, and the action buttons in one icon row, so the table never reframes between nudges.

### 26. With Ride on, the violet other-future paths vanish entirely during the chase

- Severity: Likely
- Where: What-if open, Ride on, Play both (or Ride switched on while the card is up, which replays from zero)
- What the player sees: While the chase camera follows the cue ball, the dotted violet path of the other future's cue ball, faint forecast and strong travelled part alike, disappears completely, not just the part behind the camera. Only the hollow ghost ring is left. The paths come back only when the camera cranes up or rises to the overhead view.
- How to get there: In free play, shoot a shot. Tap the what-if icon and nudge Aim once. Tap Ride (it replays) or tap Play both with Ride already on.
- Cause: WhatIfOverlay passes each ball's whole sampled path to TablePathStroke (WhatIfOverlay.swift:103-110). TablePathStroke.line returns nil if any single point fails to project (GhostOverlay.swift:125-133). AimProjector.screen returns nil for any point with depth at or below 0.01 (AimGeometry.swift:420-424). The Ride camera sits behind and above the cue ball looking forward (ShotCamera.swift:7-10), so the path's start point falls behind it once the ball passes the camera's setback.
- Fix: In TablePathStroke.line, when a point fails to project, skip it and start a new subpath at the next point that does project (or clip the segment at the near plane), instead of returning nil for the whole path.

### 27. Nudge-row labels and readouts cut to an ellipsis in German, Spanish and Russian, sideways, and at larger text

- Severity: Likely
- Where: What-if card, Spin section (the Follow or draw and Side rows; also Aim with long readouts, and the Cue angle segment)
- What the player sees: "Nachläufer oder Rückläufer" shows as "Nachläufer od…" or "Nachläufer oder…", and "Efecto alto o bajo" ("Efecto alto o…") or "Накат или оттяжка" is cut once the readout reads "2,5 mm más arriba", which may itself be cut ("2,5 mm más…"). The player cannot read which setting the plus and minus buttons change. On a phone turned sideways (card about 264 pt inside), even English "Follow or draw" is cut. At the larger and accessibility text sizes, both the label and the readout ("0.25° left", "0,25° a la izquierda") turn into ellipses, because the row never stacks. The segmented picker's fourth segment ("Angolo della stecca", "Angle de la queue", "Ángulo del taco") is truncated on a raised-cue shot.
- How to get there: Set the language to German or Spanish. In free play, shoot a shot and let it come to rest, open the what-if (What if in the scrub row), choose Spin and tap + on Follow or draw once. Or turn the phone sideways, or raise the text size, with the card open.
- Cause: NudgeRow is an HStack of a label, two 44x44 glass circle buttons and a readout with minWidth 84 in monospaced caption type, plus a Spacer of at least 4 and four gaps of 8. Both Texts have lineLimit(1), with no minimumScaleFactor and no accessibility-size layout (WhatIfViews.swift:190-205, 219-229). The fixed parts take at least about 208 pt of the 346 pt card interior when upright (370 pt card with 12 pt glassCard padding each side), leaving roughly 100 to 130 points for the name, and about 56 pt sideways (column width 320, ShowpieceView.swift:125, 191). "Nachläufer oder Rückläufer" needs about 165 points and "Efecto alto o bajo" about 112, beside a read-out of about 122 points ("2,5 mm más arriba"). Segmented picker at WhatIfViews.swift:100-108.
- Fix: In NudgeRow, put the label on its own line above the minus, readout and plus row (a VStack with leading alignment, or ViewThatFits to fall back to that), and let the readout shrink a little (minimumScaleFactor about 0.8) or wrap at accessibility text sizes.

### 28. Turning on the Lens (or tapping Replay) with the what-if open pushes the what-if controls out of view and clips the caption strip

- Severity: Likely
- Where: Phone upright, what-if card open, then the Lens on (Physics Lens button, or Replay, which always turns the Lens on)
- What the player sees: The reserved caption strip (a title and three lines) slides in above the what-if card inside the already-scrolling card area. The nudge rows the player was using drop down, and Play both, Where they part and Keep this one go below the fold. During the guided Lens replay the mode cards turn slim, but the what-if card stays full height, so the table does not keep its height. Because the card area is now a scroll view, a caption longer than the strip has its upward overflow clipped (the S4 path), and the Lens event pill, clamped to the whole stage, can sit over the what-if card.
- How to get there: In free play, shoot a shot. Open the what-if and nudge once, then tap Replay (beside the what-if icon) or Physics Lens.
- Cause: CaptionStrip is placed first in the same FittingScroll as WhatIfCard (ShowpieceView.swift:438-445). replay(withLens:) sets the Lens and guided pacing (ShowpieceModel.swift:2531-2546). lensReplayCompact slims only the mode cards (ShowpieceView.swift:468, 490-497); WhatIfCard never reads that flag (WhatIfViews.swift:42-76).
- Fix: On a phone held upright, have the what-if card read the compact Lens-replay setting and fold to its slim form (header, the sentences and Play both), so it does not stack at full height under the caption strip.

### 29. Two cards do not step aside for the what-if: the stroke result line and ball in hand (with a lifted cue ball you cannot then move)

- Severity: Certain
- Where: Free play after a scratch (cue ball lifted), or after a finger-stroked shot whose stroke changed the result
- What the player sees: After a scratch, the cue ball is lifted and Your shot opens. The what-if icon still shows in the slim scrub row. Opening the what-if closes Your shot, which leaves the Ball in hand card and the what-if card stacked in the slot. The lifted ball can no longer be dragged, because the drag lives in the aiming layer that only exists while Your shot is open, and opening Your shot to move it throws the what-if away. After a stroked shot, the stroke result card and its Practise the straight stroke button stay under the what-if card. It vanishes when Play both starts and pops back when the replay ends, which shifts the card list.
- How to get there: In free play, shoot the cue ball into a pocket with object balls left, wait for rest, and tap the what-if icon in the scrub row. Or play a shot with a crooked finger stroke, then open the what-if.
- Cause: canOpen does not exclude placingCueBall (WhatIfFork.swift:218-227). The placement is lifted at rest (ShowpieceModel.swift:1002-1005, 2656-2658) and PlayTableLayer opens Your shot (PlayTableLayer.swift:48). open() closes the panel (WhatIfFork.swift:257). AimOverlay, which carries the lifted-ball drag (AimOverlay.swift:435), is mounted only while showShotPanel is set (ShowpieceView.swift:342-348). BallInHandCard.visible (FreePlayViews.swift:119-121) and StrokeResultCard.line (StrokeViews.swift:44-47) have no whatIf.isShowing check, unlike TableCleared, Highlight, IntroEnd and Comparison (FreePlayViews.swift:292, 373, 441; GhostOverlay.swift:174).
- Fix: Add !model.placingCueBall to WhatIfFork.canOpen, and add !model.whatIf.isShowing to the guard in StrokeResultCard.line.

### 30. The scrub bar's parting diamond hides under the playhead exactly when Where they part jumps to it

- Severity: Cosmetic
- Where: What-if open with a result that has a parting point
- What the player sees: After Where they part, the white 20 pt playhead sits exactly on the 10 pt violet diamond and hides it. The mark you jumped to disappears at the moment you arrive.
- How to get there: Open the what-if, nudge once, then tap Where they part.
- Cause: In ScrubBar.track, partingMark is drawn before the thumb Circle in the ZStack (ScrubBar.swift:79-90). Both are centred on the same x after jumpToParting scrubs to marker.time (WhatIfFork.swift:386-390; ScrubBar.swift:141-149).
- Fix: In ScrubBar.track, move partingMark(width:duration:) after the thumb Circle in the ZStack so the diamond draws on top of the playhead.

### 31. The scrub bar changes width every time a shot comes to rest and when the what-if opens

- Severity: Cosmetic
- Where: Phone, scrub row, after any free-play or judged shot
- What the player sees: At the end of each eligible shot, a branch icon appears beside Replay and the scrub bar shrinks by about 54 pt, so the playhead jumps left. It widens again the moment a replay starts, and again when the what-if card opens.
- How to get there: In free play, shoot any shot and watch the scrub row as the balls stop. Then tap Replay.
- Cause: WhatIfButton renders only while canOpen (which needs aimReady) and not isShowing, with a 44 pt minimum frame (WhatIfViews.swift:27-34). It sits in the scrub row's HStack beside the flexible ScrubBar (PlaybackControls.swift:194-205).
- Fix: Keep WhatIfButton always mounted in the scrub row and show or hide it with opacity and disabled (driven by canOpen and not isShowing), so its 44 pt slot is always reserved.


## Matches and free play

### 32. A legal match break with the Lens on freezes the game behind a bare heading

- Severity: Certain
- Where: Match against the computer (eight-ball or nine-ball), iPhone held upright, ruling right after a legal break, Lens on
- What the player sees: After the break plays out, the match card shows only a heading such as "Turn over" or "Keep shooting": no sentence, no Continue, no "Watch it in the Lens". Nothing moves on. The computer never takes its turn. If it is the player's turn, Shoot is greyed with "Read the ruling card first", but there is no card to read. The game only continues if the player happens to tap the heading, which looks like a label, or turns the Lens off.
- How to get there: Main menu > play eight-ball against the computer, phone upright. Before breaking, tap Physics Lens (or carry the Lens on from an earlier "Watch it in the Lens" through Rematch, which does not turn it off). Break with nothing fouled. Or the most common route: break with the Lens off, tap "Watch it in the Lens" on the break's ruling, and let the guided replay finish. The Lens stays on and the card is stuck as described.
- Cause: MatchMode.rulingShow (MatchMode.swift:451-456) makes a legal break against the computer a .banner ruling, and offerHighlight leaves a break's show as it is (528). tickClock keeps settleElapsed at zero while lensOfferWaits is true (MatchMode.swift:576-582: a break with offerLensReplay, ShowpieceModel.swift:1981-1985, which stays true for the whole ruling phase), so update() never auto-acknowledges (MatchMode.swift:431). The view hides the sentences and the lensOffer button under lensReplayCompact (MatchViews.swift:217, 226-230). On an upright phone that flag comes from ShowpieceView.swift:468, which feeds it lensCardsSlim (490-493): true for any match phase with the Lens on, not only during a guided replay (495-497). The only remaining exit is the plain-styled settleNow button around the heading (MatchViews.swift:214-225). Shoot is refused as rulingPending (ShowpieceModel.swift:1385).
- Fix: In MatchViews.swift routineRuling, move lensOffer out of the `if !lensReplayCompact` block so a banner ruling waiting for a tap always shows its own button; leave the slim layout from lensCardsSlim as it is.

### 33. Ball in hand card with a dead button appears on the computer's turn

- Severity: Certain
- Where: Match against the computer, any layout (worst on an upright phone, where it stacks in the bottom column), computer's turn after the player fouls
- What the player sees: After the player's foul and Continue, a "Ball in hand" card appears above the match card's "Thinking...". It says "Pick up the cue ball and put it anywhere free." and shows a lit "Pick up the cue ball" button. Tapping the button does nothing. The card stays up through the computer's thinking and lining up, until the computer strikes, and takes about a fifth of the column.
- How to get there: Eight-ball against the computer. On your turn, commit any foul, for example hit one of the computer's balls first or scratch. Tap Continue on the foul card. The computer now has ball in hand, and the card appears.
- Cause: BallInHandCard.visible (FreePlayViews.swift:119-121) is placingCueBall OR (ballInHand != none AND aimReady AND not tableCleared), with no check of whose turn it is. When the turn begins, beginMatchTurn (ShowpieceModel.swift:1586-1592), and showMatchTable before it (2036), copy the state's ball in hand into model.ballInHand for the computer's seat too. beginPlacingCueBall is then refused by canPlaceCueBall (1552-1556, personMayAct false), so nothing is lifted, but the card still shows the "Pick up the cue ball" branch (FreePlayViews.swift:196-203). The stage-and-confirm placement keeps ballInHand set in a match (1610), so the card lasts until strike() clears it (920).
- Fix: In BallInHandCard.visible, add "and model.computerTurnStage == .none" to the owed-ball clause, so it reads: model.placingCueBall || (model.ballInHand != .none && model.aimReady && !model.tableCleared && model.computerTurnStage == .none).

### 34. With the Lens on in a match, fouls and game-ending shots are never explained

- Severity: Certain
- Where: Match card on an upright phone with the Lens on: ruling card and result card
- What the player sees: A foul card says only "Foul" with Continue, never what the foul was or who gets ball in hand. A losing shot (for example the 8 down early) shows only "Computer (Hard) wins" and Continue. The result card after it also leaves out the reason, so the player never learns why the game ended. In five-pin and bar billiards, "How the points came" and the score are missing. "Why that shot" and "Watch it in the Lens" disappear too, even though the model still offers the replay.
- How to get there: In any match on an upright phone, turn the Lens on with Physics Lens (or leave it on after "Watch it in the Lens"). Play until you foul, or lose on the 8.
- Cause: rulingCard puts rulingSentences, pointsSection, whyIfComputers and lensOffer behind !lensReplayCompact (MatchViews.swift:193-206), and the routine ruling and settled line do the same (213-230, 140). The flag is lensCardsSlim from ShowpieceView.swift:468 / 490-493, true whenever the Lens is on in a match. MatchCard documents it as only "while a guided Lens replay plays" (MatchViews.swift:95-97, 190-191). result() skips the end reason whenever the ruling had a result, on the grounds that "the ruling card already said why" (MatchViews.swift:508-514). With the slim card that is false, so the reason is shown nowhere. offerLensReplay stays true meanwhile (ShowpieceModel.swift:1981-1985).
- Fix: In MatchCard.rulingCard and routineRuling, keep the ruling sentences and the points section outside the lensReplayCompact guard whenever the ruling is a foul or ends the game (r.fouled or r.result != nil), so that only the guided-replay slim form drops them.

### 35. End match and Your name vanish whenever the Lens is on in a match

- Severity: Certain
- Where: Match turn banner on an upright phone, aiming phase, Lens on
- What the player sees: The round "..." More menu disappears from the turn banner, and with it the only way to end the game or set the player's name. If the name field was open, it vanishes (and the keyboard drops) the moment the Lens comes on.
- How to get there: Start any match on an upright phone. Open More > Your name, then tap Physics Lens. Or simply turn the Lens on and look for End match.
- Cause: In the aiming phase the banner gets compact: lensReplayCompact (MatchViews.swift:135), which is lensCardsSlim (ShowpieceView.swift:468, 490-493). The header drops moreMenu when compact (MatchViews.swift:695, 706), and PlayerNamesEditor sits inside the same !compact block (643-644). The banner's own comment scopes compact to "While a shot plays: only the first line" (632).
- Fix: In TurnBanner, split the flag in two: the aiming slim form (MatchViews.swift:135) hides only the player rows, table-game lines and score, while the More menu and an open names editor stay; only the shooting phase keeps the true one-line compact form.

### 36. Your shot's Shoot row opens below the fold of the scrolling card column in a match

- Severity: Likely  (earlier lead S4)
- Where: Upright phone, eight-ball against the computer, the player's turn after the break, Your shot open
- What the player sees: The match card (who shoots, two player rows, the settled line, Why that shot, the call control with chips and Safety / pocket / Call it) already fills the card column, so the column turns into a scroller. Your shot's panel, including Shoot, is added under it, out of sight, and nothing hints that the column scrolls. Tapping Your shot lights the button and only the aim line changes. With the column at its cap, the table gets about a third of the screen, with balls only a few points across.
- How to get there: Eight-ball against the computer on an iPhone 17 Pro upright, default text size. Break, let the computer play a routine shot, then on your turn open Your shot. Ball in hand after a computer foul makes it worse: the Ball in hand card sits on top.
- Cause: The cards get at most geo.height x 0.62 - 124 (ShowpieceView.swift:426, 431), about 358 points on a 402 x 874 phone. The ShotPanel is the last child inside that FittingScroll (458-461). FittingScroll swaps to a bare ScrollView with no anchor or scroll-to (Surfaces.swift:46-53; there is no ScrollViewReader or defaultScrollAnchor in the bottom stack), so it opens at the top. By estimate, the match card with call control is about 330 points (MatchViews.swift:135-152, CallControl.swift:156-185), plus 10 points of spacing and a ShotPanel of about 100-135 points in two rows (ShotPanel.swift:124-138). That is roughly 470 points against the 358 cap. This corrects the seed: the caption strip's upward overflow belongs to the Lens finder, and this is the match-column consequence.
- Fix: Move the ShotPanel out of the FittingScroll so it is pinned between the scrolling cards and PlaybackControls in bottomStack.

### 37. Eight-ball player rows cut the name and group to a few letters

- Severity: Likely
- Where: Match turn banner, eight-ball, upright phone, Lens off
- What the player sees: The computer's row shows something like "Computer (Me...  Stripes: 7 l..." beside its seven ball icons. In French both are cut hard ("Ordinateur (Di...  Rayees : il e..."), so the player cannot read which group the computer has or how many balls are left.
- How to get there: Eight-ball against the computer at Medium or Hard. After the groups are set, look at the computer's row while it still has six or seven balls. Switch the device language to French to see it worst.
- Cause: playerRow puts the dot, the name (lineLimit 1), the group text (lineLimit 1), a spacer and one 16-point icon per ball left on a single line (MatchViews.swift:759-783). The card's content width is 346 points on a 402-point phone (16-point gutters and 12-point card padding). By estimate, "Computer (Medium)" (about 112 points) plus "Stripes: 7 left" (about 99) plus seven icons (about 124) plus spacing comes to about 365 points in English. In French, "Ordinateur (Difficile)" plus "%@ : il en reste %lld" comes to about 440.
- Fix: In playerRow, stack a VStack of the name+group texts (group allowed to wrap) beside the icons, or move the ball icons to their own line under the name and group when ViewThatFits finds the single line too wide.


## Trick shots, lessons and Behind the 8-Ball

### 38. Lessons: on an upright phone the key moment's idea is never shown; the lesson freezes on its moment with only a heading and Your turn

- Severity: Certain
- Where: Lessons, Watch it, then the slow Lens replay that stops on the lesson's moment (keyMoment), iPhone held upright
- What the player sees: The lesson plays its example, replays it slowly in the Lens and stops dead on the moment that matters. The lesson card then shows only 'Lesson N: Title' and a Your turn button. The 'The idea' heading and the lesson's idea sentence, the only reason the replay stopped there, never appear. Neither do Watch again or the 'Now slowed down in the Physics Lens. It stops on the moment that matters.' line during the replay. The idea only appears if the player happens to press Play and lets the replay run to its end.
- How to get there: Menu, Lessons, any lesson (for example Draw), Watch it. Wait for the real-speed example and the Lens replay. It pauses on the moment.
- Cause: LessonMode.tick() stops the replay with model.scrub(to:) and sets .keyMoment (LessonMode.swift:359-363). scrub leaves playing false, the clock short of the end (so aimReady is false) and chosenRate nil (ShowpieceModel.swift:2501-2506, 2531-2539), so model.guided stays true (ShowpieceModel.swift:3602-3608). lensReplayCompact is therefore true (ShowpieceView.swift:495-497). LessonCard then renders slim() (LessonViews.swift:133, 249-253), which shows only the header and turnButton for .replaying and .keyMoment. The idea is only in content() .keyMoment (LessonViews.swift:168-179).
- Fix: In LessonViews.swift body, use the full card when the lesson is paused on its moment: if compact && mode.phase != .keyMoment { slim(lesson) } else { content(lesson) }.

### 39. A long button label in a card's button row spills out past the card's leading edge at larger text, and in the sideways side column

- Severity: Likely
- Where: Trick judged card after a make (Watch yours in the Lens); lesson card after a missed or passed pass shot (Back to the lesson's stroke, Try the trick shot); same row helper in the 8-Ball card
- What the player sees: When one button is wider than the card, it is drawn at full width starting left of the card's edge. It sticks out of the glass, and on an upright phone past the screen's side gutter, so its start is cut off at the screen edge. Likely cases: French 'Revoir le tien dans la Lentille' at default size on a phone turned sideways (side column inner width about 264 points), and at extra-extra-large text upright (about 346 points). English 'Watch yours in the Lens' at extra-extra-large sideways. Spanish 'Volver al golpe de la lección' and Portuguese 'Experimenta a jogada de efeito' on the lesson card.
- How to get there: Set French (or English with Larger Text at the largest non-accessibility size). Trick shots, Stop Dead, Your turn, make it. Look at the result card's buttons, phone sideways or upright.
- Cause: TrickShotViews.swift:337-350 (and LessonViews.swift:349-362, EightBallViews.swift:643-656) use ViewThatFits(HStack, WrappingRow) below the accessibility sizes. ViewThatFits falls back to WrappingRow even when nothing fits. WrappingRow measures each child at .unspecified, keeps an over-wide child on its own line (Surfaces.swift:115-118) and places it at x = bounds.maxX - line.width, which goes negative, with its ideal width (Surfaces.swift:136-139). The labels are .lineLimit(1) and cannot wrap (TrickShotViews.swift:269; LessonViews.swift:388). The sideways column is min(columnWidth 320, 45% of width) minus 16-point padding (ShowpieceView.swift:125, 191; sideColumn .padding(16)) minus the card's 12-point padding.
- Fix: In WrappingRow.placeSubviews, give an over-wide child min(size.width, bounds.width) and start it no further left than bounds.minX, so the one-line label truncates inside the card.

### 40. The last try's contact mark is too small on a phone to read as a ring

- Severity: Likely
- Where: Try again on a trick shot, lesson or free-play retry, after See the contact, phone held upright
- What the player sees: See the contact stops the replay so the player can compare their contact with the last try's, which is marked by 'a small dashed ring with a dot'. At whole-table framing on a phone the ring has a radius of about three points (under two with Your shot open), the same size as the four-point dot inside it. It reads as a single speck beside or under the live ball, so the comparison it exists for cannot be seen.
- How to get there: Trick shots, Stop Dead, Your turn, shoot and miss, Try again, shoot again. On the result card, See the contact. Phone upright.
- Cause: GhostOverlay.swift:81-92 draws the ring at radius * 0.6 table metres (about 17 mm) with a 1.2-point dash [2,2], plus a fixed four-point dot. On an upright phone the table is about 170 points per metre with the slim cards and about 100 with the aiming panel (height-limited framing), giving about 3 points and about 1.7 points of radius. There is no minimum screen size anywhere in these drawings. TablePathStroke.ring (GhostOverlay.swift:136-145) is also exactly one ball radius for the 'Last try' rest ring.
- Fix: In GhostOverlay's contact mark and TablePathStroke.ring, work out the on-screen radius from the projector and keep it at least 7 points, and draw the dot at about a third of that ring radius.

### 41. Behind the 8-Ball: during the Lens replay of a scored try, the slim card shows the next try's number

- Severity: Certain
- Where: Behind the 8-Ball, scored try, Physics Lens replay button, phone held upright
- What the player sees: While the player's own try 1 replays in the Lens, the slim card's heading reads 'Try 2 of 3'. After try 3 it reads 'Practice' while replaying the try that counted. The full scorecard it replaces showed the right number.
- How to get there: Menu, Behind the 8-Ball, any situation, make a call and shoot. On the scored card tap the eye (Physics Lens replay). Phone upright.
- Cause: EightBallViews.swift:342-348: slim() uses header(s), which shows tryLabel(mode.nextTry) (EightBallViews.swift:607-611). In the scored phase nextTry is tries + 1 (EightBallMode.swift:135). The full card uses v.tryNumber (EightBallViews.swift:384). lensReplay() (EightBallMode.swift:330-335) starts a guided replay, so lensReplayCompact makes the card slim.
- Fix: Give header() an optional try number. In slim(), when the phase is .scored(v), pass v.tryNumber so the label is tryLabel(v.tryNumber) instead of tryLabel(mode.nextTry).


## Aiming and Your shot

### 42. Side-spin fork labels pile on top of each other and cover the contact picture

- Severity: Certain
- Where: Your shot, any still table after the break, phone upright, side spin set (Aim guide on, the default)
- What the player sees: With side spin set and the shot running up or down the table, the 'Cue aims here' pill and the two-line 'Ball goes here / 2.5° left' pill sit on top of each other. The cue's words show through the darker ball pill, and both pills cover the ghost ball, the magenta ring and the contact dot at the end of the line. In German ('Hier zielt das Queue' / 'Hier läuft die Kugel') they overlap almost completely. The two prongs themselves are only a point or two apart, so the fork reads as one line with a smudge of labels on it.
- How to get there: Launch, break, wait for the balls to stop, open Your shot. Drag the dot on the cue-ball picture to its left or right edge. Drag on the table to aim roughly straight along the table's length (top to bottom on an upright phone).
- Cause: AimOverlay.swift:790-804 pushes each pill sideways, away from the other prong: the cue pill 16 points one way and the ball pill 24 points the other (gap 16, and gap + 8). On a shot along the table the push is horizontal, so the centres end up about 40 points apart. drawPill (742-756) sizes each pill to its caption2 text plus 12 points: about 87 and 92 points wide in English, over 120 in German. That is roughly 45 points of overlap in English and 85 in German, all centred on the ghost ball (ballEnd is the guide's reach, the ghost centre). The fork is drawn from half a degree up (AimGeometry.swift:254), which is a point or two on screen at whole-table framing.
- Fix: In drawFork, place the two pills along the line instead of beside it: cue pill short of the end, ball pill past the ghost, each set back by its own half-length plus the ball radius on screen.

### 43. Two bridge marks behind the cue ball: the 3D ring and the old flat ring both draw

- Severity: Certain
- Where: Your shot open on any still table (free play, matches, lessons, trick shots without the rest), phone upright or sideways
- What the player sees: Two chalk rings sit behind the cue ball, each with its own dotted line to the ball. One lies on the cue line under the cue shaft. The other sits off to the shooter's left, beside the groove. Both turn magenta together for an awkward stance, so the player has two places to rest a bridge hand.
- How to get there: Launch, break, wait for the balls to stop, open Your shot and look just behind the cue ball.
- Cause: TableStage.swift:156 passes a BridgeMark every frame while the cue shows. TableStage.swift:253-260 puts its spot straight back along the cue (cue.from - back * strokeBridgeLength), and BridgeRing draws it in 3D. AimOverlay.swift:570 still calls drawBridgeMark (689-714), which draws the flat ring swung sideways off the cue line. BridgeRing.swift:6-9 says the 3D ring replaced the flat drawing, but the flat one was never removed. Both run under the same conditions: the cue shows, the balls are at rest, and the mechanical rest is not in use.
- Fix: Remove the drawBridgeMark call at AimOverlay.swift:570 and delete the now-unused function, leaving BridgeRing as the only bridge mark; if the ring should stay off the groove, move the swung-sideways spot math into TableStage.bridgeMark.

### 44. The table zooms and slides under the finger while aiming as the stance card comes and goes

- Severity: Likely
- Where: Your shot, free play or a match, phone upright, cue ball away from the rails
- What the player sees: Swinging the aim line round the cue ball makes a stance row ('Stretch...', 'Behind the back...', 'Use the rest') appear and disappear at the top of the shot panel. Each time, the panel grows or shrinks by a row and the table glides to a new size and position over about a third of a second, with the finger still on it. The aim then jumps to whatever table point is now under the finger, which can flip the stance and the row back again, so the table can pulse near a stance boundary.
- How to get there: Launch, break, wait for the balls to stop, open Your shot. Put a finger on the cloth and slowly swing the aim from across the table to along it, with the cue ball near the middle of the table.
- Cause: ShotPanel.swift:77 puts EquipmentCard in the phone's shot panel. StanceViews.swift:50-62 builds its rows from model.stance, and model.stance (ShowpieceModel.swift:3161-3167) is Reach.stance of the current aimDirection, so the row changes as the aim turns. ShowpieceView.swift:475 measures the bottom stack's top as controlsTop, which reaches the camera (ShowpieceView.swift:317, CameraFraming.swift:120). The camera eases to the new fit (TableCamera.swift:193-201) while AimOverlay.aimDrag (414-418) keeps mapping the same screen point through the moving camera.
- Fix: In ShotPanel on a phone, keep EquipmentCard's height reserved while Your shot is open (an empty plate when there are no rows), so controlsTop does not change as the stance flips under the aim.

### 45. Your shot stays full height while the shot rolls, so the table and balls stay small

- Severity: Likely
- Where: Your shot after striking a shot (not a break), phone upright, balls rolling
- What the player sees: After Shoot (or a push through the ball) the whole panel stays under the table while the balls run: the tip picture, the power bar, the greyed-out Shoot and the More button, plus the slim scrub row. None of them can be used until the balls stop. The table keeps the smaller framing it had for aiming, so the rolling balls, the cue's follow-through and the stroke trace are drawn about a third smaller than the space allows.
- How to get there: Launch, break, wait for the balls to stop, open Your shot, play any shot and watch it roll.
- Cause: ShotPanel.swift:166-167 closes the panel only for a break ('a shot keeps it open'). ShowpieceView.swift:458-461 keeps ShotPanel in the bottom stack whenever it is open. The only rule that steps it aside (lensReplayCompact, ShowpieceView.swift:495-497) covers guided Lens replays only. The table is fitted above the stack's measured top (controlsTop, line 475).
- Fix: In ShowpieceView.swift line 166, add "|| (model.openingStage == .none && !model.aimReady)" to panelWaits (it already excludes wide). The existing wait and restore logic then closes Your shot while a shot plays and reopens it when the balls stop.

### 46. Two different grooves drawn on top of each other at the hand-over

- Severity: Cosmetic
- Where: First launch hand-over (the player's own break), touch, phone upright
- What the player sees: Behind the glowing cue ball there are two overlapping faint bands: a wide one that starts outside the halo and narrows, and a narrow one that runs from the ball's centre. Each has its own dashed centre line, slightly out of step, so the line looks doubled and irregular. At the first aim or power change the wide band disappears and the narrow one stays, so the groove the first minute teaches changes shape at the first touch.
- How to get there: Fresh install, launch. The hand-over opens with Your shot open. Look behind the cue ball before touching anything.
- Cause: OpeningHandover.swift:150 draws drawGroove (164-191) while showsGroove (130-133) holds: half-width of a ball radius (at least 8 points), starting 1.6 radii behind the ball and tapering. At the same time, AimOverlay.swift:637-639 draws StrokeDrawing.drawHint because showsGrooveHint (766-770) passes explicitly at the hand-over ('|| model.openingStage == .handOver'). That hint is a constant half-width of grooveHalfWidth(0), starting at the ball (StrokeGesture.swift:854-877). AimOverlay is in the tree because OpeningLayer opens the panel (OpeningHandover.swift:120).
- Fix: In OpeningHandover.swift line 150, delete the drawGroove call (and the then-unused drawGroove and showsGroove), so AimOverlay's hint, which matches the real groove, is the only groove drawn.

### 47. Shot panel's button row cuts off the cue-angle and Shoot words at larger text and in longer languages

- Severity: Likely
- Where: Your shot after the break (cue angle shown), phone upright, French or Portuguese, or English at the larger text sizes
- What the player sees: The row under the tip picture and power bar (More, cue angle, Try again, Shoot) runs out of width. The cue-angle button shows '40° vers le h…' or '40° para c…'. At the accessibility text sizes, Shoot itself is clipped to a few letters beside the cue angle.
- How to get there: Settings, set the app language to French (or set a large text size). Launch, break, wait for the balls to stop, open Your shot, open the cue-angle menu and pick 40° up.
- Cause: ShotPanel.swift:124-138: twoRows is the last choice in ViewThatFits (line 82), so it is used even when it does not fit. Row two is More (about 44), cue angle, Try again (already icon-only), and Shoot, inside the 338 points left by the stack's 16-point gutters and the glass card's 16-point padding. CueAngleControl.swift:82-87 is the headline-font label with lineLimit(1) and no shorter form. Shoot is lineLimit(1) at ShotPanel.swift:169-172. At accessibility sizes, stacked (141-154) puts the same four in one row.
- Fix: In CueAngleMenu's label, wrap it in ViewThatFits with an icon-plus-degrees fallback (keeping the words as the accessibility value), and in ShotPanel's stacked layout give fireButton its own full-width row below More, cue angle and Try again.

### 48. Fine controls sheet covers a third of the table, including the end being aimed at

- Severity: Likely
- Where: More > Fine controls on an upright phone
- What the player sees: The sheet opens at half height. The comment says this leaves the table in view, but on an upright phone the table runs down to the panel. The lower third of the table (the end nearest the bottom of the screen, with its balls and often the aim's target or the cue ball) is behind the sheet while the player moves the aim, tip and side sliders.
- How to get there: Launch, break, open Your shot, tap the More (ellipsis) button, Fine controls.
- Cause: ShotPanel.swift:436-438 uses .presentationDetents([.medium, .large]) with background interaction up to medium. The table's framing (CameraFraming.swift:120) knows only the bottom stack's top, not the sheet, so the table is not reframed into the half that stays visible.
- Fix: On a regular phone, show the fine controls inline below the panel (as the folding phone already does), or give the sheet a short custom height and pass its top to the table framing so the table refits above it.

### 49. Fine controls: names and readouts squeezed into fixed columns

- Severity: Cosmetic
- Where: Fine controls sheet, phone upright, French, Italian or German
- What the player sees: The slider names wrap into two or three short lines in a narrow column ('Angolo della / stecca', 'Pointe de la / queue'). The readouts wrap too ('kräftig · Kugel / 3,4 m/s', 'Nachlauf, +8,5 / mm').
- How to get there: Settings, set the app language to Italian or German. Launch, break, open Your shot, More > Fine controls.
- Cause: ShotPanel.swift:484-486 sets fixed widths of 64 and 112 points (scaled from caption) for the name and readout columns (used at 500-504). The longest translations of 'Cue angle', 'Cue tip' and the readout strings run to about 115-140 points in that font.
- Fix: In SliderRow, wrap the two layouts in a ViewThatFits that tries the side-by-side row with the name and readout kept on one line (fixedSize horizontally) first, and falls back to the stacked layout already used at accessibility sizes (name and readout on a line above the slider).

### 50. Sideways with Your shot open, Lens, Ride, Your shot and the scrub bar move into the scroll and below the bottom of the side column, and the panel can land below the fold

- Severity: Likely
- Where: Phone turned sideways (side column), Your shot open, especially with a trick-shot, lesson or match card in the column
- What the player sees: The player taps Your shot in the pinned row at the bottom of the column. That whole row (pause, scrub bar, speed, Lens, Ride, Your shot) disappears from its pinned place and moves to the end of the scrolling cards, below the shot panel and the cards. The shot panel itself is added after the card and the caption area, below what the column shows, and the column does not scroll to it, so nothing visible changes in the column. In a window about 370-380 points tall the row lands below the edge. To turn the Lens on, close Your shot or scrub the replay, the player must first find the row and scroll the column down.
- How to get there: Turn the phone sideways. Menu > Trick shots > any shot > Your turn (or start a match, Play > Eight-ball), then tap Your shot.
- Cause: In the side column the PlaybackControls are pinned under the ScrollView only while showShotPanel is false (ShowpieceView.swift:563-567). When the panel opens they move inside the scrolling VStack after ShotPanel (552-557, 'they scroll with it'), which comes after WhatIf, Comparison, Opening, TrickShot, Lesson, EightBall, Play and Stroke cards and CaptionArea (541-551). There is no ScrollViewReader or scroll-to on open. This is the same hole the 0.7.5 coordinator closed for the upright phone, where tall cards scrolled the row away and left no way to turn the Lens off (ShowpieceView.swift:427-431, 464).
- Fix: In sideColumn, always pin PlaybackControls under the ScrollView when controlsInColumn is true, delete the in-scroll copy, and wrap the column in a ScrollViewReader that scrolls to ShotPanel when showShotPanel turns true.

### 51. Power percentage is drawn under the finger whenever the shot points down the screen

- Severity: Likely
- Where: Your shot, stroking on the cue ball with a finger, phone upright
- What the player sees: While pulling back, the live percentage pill always sits above the cue ball. When the aim points toward the bottom of the screen the pull goes upward, so the finger and hand sit right on the pill and the number cannot be read. Near the top of the table the pill also slides under the title row.
- How to get there: Launch, break, open Your shot, aim toward the bottom of the screen, then put a finger on the cue ball and pull back (upward).
- Cause: AimOverlay.swift:647-654 always places the badge at cueScreen.y - ringRadius - height - 14, whatever the groove direction, and never clamps it to the area below the header (headerBottom).
- Fix: Place the pill on the far side of the ball from the groove (cueScreen minus grooveFrame.back times the ring radius plus a gap), then clamp its frame below headerBottom and above controlsTop.

### 52. Ghost ball, target ring and contact dot are drawn at true ball size, a few points across on an upright phone

- Severity: Likely
- Where: Your shot, any still table, phone upright, default (fitted) framing
- What the player sees: At whole-table framing the ball is about 8 points across. The dashed ghost ball is a ring of about four dashes the size of a ball, the magenta target ring is about 11 points across, and the fixed 6-point contact dot covers most of where the two touch. The end-of-line ring for a miss is the same size. The contact picture the guide exists to show is hard to make out without pinching in.
- How to get there: Launch, break, open Your shot, aim at any ball without zooming.
- Cause: AimOverlay.swift:596-604 and 627-629 draw the ghost, ring and miss ring at the table's ball radius (and 1.3 times it), projected to screen with no minimum on-screen size. The fixed 6-point dot is at 603. TableZoom.swift:17-18 notes the balls are 'a few millimetres across' at this framing, and TableTouch.grabFloor (StrokeGesture.swift:69-71) already floors the grab ring for the same reason, but the drawings have no such floor.
- Fix: In AimOverlay draw, set the drawn radius for the ghost, target ring and miss ring to at least about 10 points (convert the floor to table metres with the projector's points per metre at the cue ball, as the grab ring does), and size the contact dot from that drawn radius instead of a fixed 6 points.

### 53. 'Calm zone ends' label spills over the shot buttons at the accessibility text sizes

- Severity: Likely
- Where: Your shot, the first three times the power bar shows its calm mark, phone upright, accessibility text sizes
- What the player sees: The small caret and 'Calm zone ends' under the power bar grow with the text but the room kept for them does not. At the largest sizes the label hangs down over the next row of the panel (More, cue angle, Shoot). It is also far wider than the bar and runs past the plus button.
- How to get there: Set an accessibility text size, fresh install (or reset the stored count), launch, break, open Your shot.
- Cause: AimGauges.swift:358-362: calmLabelRoom is a fixed 8 points, worked out at the default size only. The label's offset grows with the @ScaledMetric barHeight (line 309), the label is caption2 with fixedSize (300-303), and the leading clamp (306-308) can only pin it to the bar's left edge when it is wider than the bar.
- Fix: At accessibility sizes, show only the caret, or set calmLabelRoom with a ScaledMetric to barHeight minus the button gap plus the label's line height, and let the label wrap to the bar's width instead of using fixedSize.


## Menu, title row and turning the phone

### 54. Turning the phone while the menu is up throws away whatever menu screen was open

- Severity: Certain
- Where: Main menu on a regular iPhone, turned from upright to sideways or back, with the Play list, the replace-your-saved-game question, or a How to play, Options or Tables sheet open
- What the player sees: The open sheet slides away (How to play part-read, a rules page, a table's page in Tables, Options), the Play list jumps back to the main list, a pending 'Replace your saved game?' question disappears, and the whole menu card fades in again from nothing as if just opened.
- How to get there: Later launch, menu up. Tap Play (or How to play, then Rules > Eight-ball; or Tables > Bumper pool). Turn the phone sideways. Turn it back upright to see it happen again.
- Cause: Upright, the menu is drawn inside the stage (ShowpieceView.swift:174 menuOnStage, :378-380). Sideways, menuOverWindow (ShowpieceView.swift:163) is true, so the stage copy is removed and a second TitleScreen is built in the window-level ZStack (ShowpieceView.swift:210-215). These are two different views, so all of TitleScreen's own state is lost: shown, howToOpen, optionsOpen, tablesOpen, playListOpen (TitleScreen.swift:143-149). The sheets are attached to the view that goes away (TitleScreen.swift:198-200), so they are dismissed. onDisappear also clears playListOpen and pendingMatch (TitleScreen.swift:197).
- Fix: Build one TitleScreen for every layout that has no notebook (always in the window-level ZStack, with the stage copy removed), or move howToOpen, optionsOpen, tablesOpen and playListOpen up into ShowpieceView as bindings, so turning the phone never rebuilds the menu.

### 55. The main menu's Play entry reads 'Playback' in French, Spanish, Japanese, Korean and Arabic

- Severity: Certain
- Where: Main menu, top-highlighted entry, and the header of the Play list, in those languages
- What the player sees: The biggest, highlighted menu entry, which opens the games against the computer, says 'Lecture' (fr), 'Reproducir' (es), '再生' (ja), '재생' (ko) or 'تشغيل' (ar). These are media-player words for playback, not 'play a game'. The Play list's title shows the same wrong word.
- How to get there: Set the phone's language to French, Spanish, Japanese, Korean or Arabic, launch, and look at the main menu.
- Cause: The menu uses the plain key "Play" (TitleScreen.swift:267 MenuRow title, :368 listHeader). The same key is the transport button's label (PlaybackControls.swift:53 and :62, MacChrome.swift:409), and the catalog entry "Play" in App/Localizable.xcstrings has no comment and was translated in the playback sense. The same collision exists for the computer-level picker label "Level" (TitleScreen.swift:492). It shares a key with the cue-angle word 'Level' (CueAngleControl.swift:59, EightBallJudge.swift:1135), which is translated as flat ('Flach', 'À plat', '水平'). A segmented picker does not draw its label on iOS, so that one is only heard, not seen.
- Fix: Give the menu its own catalog key: change TitleScreen.swift:267 and :368 to use the key "Play a game" with the translator comment "Main menu entry: play a game against the computer" and the translations Jouer / Jugar / プレイ / 플레이 / العب, and do the same for the level picker's "Level" at :492.

### 56. Watch the intro keeps Your shot open over the break, snaps it shut at the slow replay, then pops it back over the intro's end card

- Severity: Certain  (earlier lead S18)
- Where: Watch the intro on an upright phone, started from the menu after playing with Your shot open
- What the player sees: While the opening break plays at full speed, the aiming panel (power, tip, a greyed Break or Shoot) sits under the table and squeezes the table into the top part of the screen, though nothing can be aimed. When the slow Lens replay starts, the panel suddenly closes by itself. When the replay ends, it springs open again under the intro's end card (Practice / Trick shots), stacking two cards and shrinking the table again.
- How to get there: Later launch: Play > Practice (Your shot opens). Tap the back button (Menu). Tap Watch the intro.
- Cause: The menu row calls only model.watchBreak() (TitleScreen.swift:281-284), and watchBreak never asks for the panel to close (ShowpieceModel.swift:662-685, no requestShotPanel(.close)). openMenu does not close it either (ShowpieceModel.swift:611-630). So showShotPanel stays true and ShotPanel stays in the bottom stack (ShowpieceView.swift:458-461). The seed's 'never closes' needs correcting: guided turns true only in .slowReplay (ShowpieceModel.swift:3602-3608). Then lensReplayCompact (ShowpieceView.swift:495-497) makes panelWaits true (:166), and the onChange at :222-229 closes the panel and sets panelWaiting. When the replay reaches explore at rest, aimReady ends the wait and the same onChange reopens the panel while IntroEndCard (FreePlayViews.swift:441) is showing.
- Fix: In ShowpieceModel.watchBreak, call requestShotPanel(.close) so Your shot is closed (and nothing is left waiting) when the intro starts.

### 57. Menu entry names are cut off with an ellipsis at larger text sizes and in long translations

- Severity: Likely
- Where: Main menu and Play list on an upright phone, at the larger text sizes, or in Italian
- What the player sees: Entry names end in '…', for example 'Behind the 8-…' or 'Coups spectacu…' next to their progress badge, and in Italian 'Biliardo all'italiana (5 bi…' in the Play list once a game has been played (the record badge takes the room).
- How to get there: Settings > Display > Text Size, one or two steps above default (or any accessibility size), then open the menu and the Play list. Or set Italian, play one five-pin game against the computer, and open Play.
- Cause: The row title is held to one line and may shrink to only 80 percent (TitleScreen.swift:568-571). The card is limited to the phone's width less 16-point margins and 28-point card padding (TitleScreen.swift:179-181, 240), which leaves about 314 points. Inside a large glass button that space is shared with a fixed 28-point icon, two 12-point gaps and a progress badge that never shrinks (TitleScreen.swift:563-589). Long run-time names come in verbatim, like NotebookWords.gameName(.fivePin) = 'Biliardo all'italiana (5 birilli)' (TitleScreen.swift:396-399, NotebookPanel.swift:79).
- Fix: In MenuRow, replace the title's lineLimit(1) and minimumScaleFactor(0.8) with lineLimit(2) and fixedSize(horizontal: false, vertical: true), so long names wrap instead of ending in an ellipsis.

### 58. The title row's status words are cut off while the Lens key appears during the intro

- Severity: Cosmetic
- Where: Upright phone, Watch the intro (or the first-launch opening), at the moment the table turns into the Lens
- What the player sees: For about a second the top-right status pill shows 'Now look at what the table is doing' cut to two lines ending in '…'. In German ('Schau dir jetzt an, was der Tisch macht') or Russian it is cut harder, while the Lens colour key squeezes in beside it.
- How to get there: Menu > Watch the intro, and watch the title row when the picture changes to the Lens after the break freezes.
- Cause: The status text is limited to two lines at caption size with no shrinking (ShowpieceView.swift:614-619). It shares one row, about 370 points wide, with the back button, the Lens key, a spacer and the Surface button (ShowpieceView.swift:593-613). The key appears as soon as lensOn (melt above one half, ShowpieceModel.swift:585), which is halfway through the .melt stage whose title is that long sentence (ShowpieceModel.swift:591, 2602-2608). The key's narrowest form still needs about 100 points (CaptionViews.swift:391-397).
- Fix: In stageTitle, give the .melt case a short title (for example "The Lens"), with matching short translations (ShowpieceModel.swift:591).


## Words and numbers in other languages

### 59. On-table title chip lands on the ball it names when the title is long

- Severity: Likely
- Where: Any guided Physics Lens replay on an upright iPhone 17 Pro (about 402 points wide): the ring around the ball and the glass chip carrying the caption's short title
- What the player sees: When the ball is anywhere near the middle of the table's width, the title chip is not beside the ring. It sits on top of it, covering the ball and half the ring. In English this happens for titles like "The cue hands over its speed" with the cue ball between roughly a third and two thirds of the width (where a break's cue ball usually is). In German ("Die Queue übergibt ihre Geschwindigkeit") or Italian ("L'effetto laterale sposta la bilia bianca dalla linea") it happens nearly everywhere on the table. At the larger text sizes the Italian chip is wider than the screen and runs off the right edge.
- How to get there: Normal launch, Trick shots, The Called Break, Watch it. The guided Lens replay holds on the strike beat, and the chip covers the cue ball. Switch the phone to German or Italian and it covers almost any ball the caption is about.
- Cause: CaptionViews.swift 526-541 (chipCenter): the chip goes right of the ring, or left if that fits. When neither side fits (ring.x + 28 + chip width > stage width - 8 on the right, and ring.x - 28 - chip width < 8 on the left), line 536 still picks right and line 538 clamps x to bounds.maxX - gap - w/2. The chip's left edge then lands inside the ring. y stays ring.y (539-540), so nothing moves it above or below the ball. The chip text is one line at fixed size (CaptionViews.swift 600-603), so a long translation cannot wrap. Caption titles run up to 53 characters in Italian and 47 in German against 38 in English.
- Fix: In chipCenter, when neither side fits, set c to the ring's x and ring.y - ringRadius - gap - h/2, or ring.y + ringRadius + gap + h/2 when that is below the top limit, instead of clamping sideways, and cap the chip width to the stage width minus twice the gap so long titles wrap.

### 60. Headline equation is big, wraps mid-equation, then vanishes when the hold ends

- Severity: Certain
- Where: Upright phone, guided Lens replay of a trick shot. The explanation strip above the playback row, on a held headline or signature beat (for The Called Break, the Throw beat)
- What the player sees: While the beat is held, a worked equation such as "tan θ = 0.052 / 1.234 → θ = 2.4°" appears at the top of the card in large italic serif even with Show the maths off. Beside the Continue button it does not fit on one line, so it breaks part-way through the sum. The moment the hold ends (Continue tapped, or the hold times out), the equation line disappears from the same caption that is still on screen, and the card's top drops by two lines of large type while the player is reading it.
- How to get there: Normal launch, Trick shots, The Called Break, Watch it. Wait for the guided replay to stop on Throw, then tap Continue. The caption stays up but its equation line goes.
- Cause: CaptionViews.swift 148-153: the equation line is drawn only when maths or headline is true, with no line limit in the visible copy, in Theme.equation (Theme.swift 52: title3 serif italic). CaptionViews.swift 304 reads headline from model.holdingHeadline, and ShowpieceModel.swift 3659-3661 makes that false as soon as heldBeat is cleared. The strip still shows the same caption afterwards, because it keeps the last one (CaptionViews.swift 303, 344-346), so only the equation line drops out. The hidden sizer (CaptionViews.swift 334) never sets headline, so on a headline beat with maths off this line gets no reserved room either. The worked strings are long: Captions.swift 594, 746, 756, 857.
- Fix: In CaptionStrip, decide headline by caption, not by the hold: model.holdingHeadline || model.pacePlan.beats.contains { $0.headline && $0.caption.id == caption?.id }. Give the strip's equation Text .lineLimit(1).minimumScaleFactor(0.6) in a smaller serif.

### 61. Aim read-out ignores the player's number style while the rest of the panel follows it

- Severity: Certain  (earlier lead S16)
- Where: Your shot, then the fine-controls sliders sheet (any table that is not racked). Also the worked equation for an off-centre strike
- What the player sees: On a phone set to German, French, Spanish, Italian, Portuguese or Russian, or to a comma region, the Aim row reads "+12.5°" (and "+12 mm") with a decimal point. On the rows just below, Power reads "fest · Kugel 3,4 m/s" and Cue tip reads "+2,5 mm" with a decimal comma, and the spoken values also use the language's comma. On the off-centre strike caption the worked line mixes both styles in one equation: "(0,57 + 0,17 + 2.5 · 0,57 · 0,30²)".
- How to get there: Set the phone to German (or Italian). Normal launch, play any shot so the rack is broken, open Your shot, then open the sliders sheet (More > Fine controls) and look at Aim against Power and Cue tip. For the equation, turn on Show the maths and hit an off-centre follow or draw shot, then watch it in the Lens.
- Cause: ShotPanel.swift 450 formats the aim with String(format: "%+.1f°") and no locale; 378 and AimOverlay.swift 648 do the same, while the accessibilityValue at ShotPanel.swift 457 passes Locale.current. PowerWords.swift 54 and 60, ShotPanel.swift 350 and Captions.swift 232 all format for the player's language. Captions.swift 594 hard-codes the literal "2.5" in a worked line whose other numbers come from f(), which uses the player's locale.
- Fix: At ShotPanel.swift:450, format the aim with model.aimDegrees.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always(includingZero: false))) + "°". At Captions.swift:594, replace the literal "2.5" with \(f(2.5)).

### 62. No plural forms anywhere in the string catalog: Russian and Arabic counts read wrong

- Severity: Certain
- Where: Any count sentence in Russian or Arabic, for example the Table cleared card in Practice
- What the player sees: In Russian, clearing the rack in three shots reads "Стол очищен за 3 ударов"; it should be "удара". Percent sentences in the Lens have the same problem, for example "сохраняет здесь 82 процентов"; it should be "процента". Arabic uses one plural form for every count. English avoids this only because the code branches on one against many, and that branch has nothing to give the two-to-four forms.
- How to get there: Set the phone to Russian. Normal launch, Practice, clear the rack in two, three or four shots. The Table cleared card shows the wrong noun form.
- Cause: App/Localizable.xcstrings has no "variations" entry at all: grep returns zero, and about one hundred count strings carry %lld with no plural variants. FreePlayViews.swift 355-356, TableGameWords.swift 134 and 164 and EightBallJudge.swift 1068-1076 fix only one against many in code. In the Lens, Captions.swift passes percentages as preformatted text (f(), line 232), so they cannot be pluralised at all. scripts/translation-check.py checks placeholders and register but not plural coverage.
- Fix: In Localizable.xcstrings, give "Cleared in %lld shots." (and the other count strings) plural variations for ru (one/few/many/other) and ar (zero/one/two/few/many/other), and drop the hand-coded one-versus-many branch so the catalog picks the form.

### 63. Russian Lens captions switch between Latin and Cyrillic units from one caption to the next

- Severity: Cosmetic
- Where: Physics Lens captions in Russian
- What the player sees: One caption says "на скорости 2,1 m/s" (pocketed, jaw, landing, rail captions). The next says "на скорости 2,1 м/с" (drop into the cup or hole, bumper). The strike caption spells it out as "метров в секунду". Centimetres show the same mix of "cm" and "см".
- How to get there: Set the phone to Russian. Normal launch, Trick shots, The Called Break, Watch it, and step through the beats.
- Cause: App/Localizable.xcstrings Russian values: 24 strings use Latin "m/s" and 14 use "м/с"; 5 use "cm" and 17 use "см". For example, "%@ drops in at %@ m/s." has the Russian "...на скорости %@ m/s", while "%@ drops into the hole at %@ m/s." has "...на скорости %2$@ м/с". The checker (scripts/translation-check.py) does not look at units.
- Fix: In App/Localizable.xcstrings, change every Russian value with Latin "m/s", "m/s²" or "cm" to "м/с", "м/с²" or "см", and add a check per language to scripts/translation-check.py that flags Latin unit spellings in Cyrillic translations.


## Judgment calls (the two skeptics disagreed)

Entries 64 and 65 are kept: both skeptics agreed on the facts (64 is in the Boss's own screenshot; for 65 the spin
arrowhead already lies flat, but the belt and ring are still hairlines). Entries 66 and 67 are dropped: tapping Ride during
a guided replay is written in the code as deliberate, and the notebook never appears on a regular phone.

### 64. On an upright phone the trick card hides 'The idea' for the whole explanation replay, leaving a lone button under empty glass, then jumps tall when the replay ends

- What the player sees: During the slow Lens replay, which exists to explain the shot, the trick card shows only the title, the difficulty and a lone right-aligned Your turn button on a second row. The rest of the full-width card is empty glass. The shot's one idea, Show the maths and Watch again are all missing. Your turn, the only button offered, skips the explanation. When the balls stop, the card suddenly grows to the full idea card (idea paragraph, maths, two buttons) under the caption strip, which is still up, and the table shrinks at that moment.
- Fix if taken: In slim() for the Explaining phase, show the idea line limited to two lines in the header row next to Your turn, so the card has real content and keeps the same height when the replay ends.
- Skeptic (stands): The route works on an upright phone. TrickShotMode.swift:256-271: when the answer finishes, the phase becomes Explaining, Ride goes off, and for any shot except the break the Lens replay starts. ShowpieceModel.swift:2531-2546: that replay sets the Lens target on, clears the fixed speed and resets the clock, so the balls are moving again; guided is true when the shot has beats (lines 3602-3610). ShowpieceView.swift:490-497: the compact condition holds (upright, after the opening, Lens on, guided, balls moving). The tips stay off during the replay because it is the mode's own demonstration (2541, 2550-2556), so the card is not hidden. TrickShotViews.swift:293-297: the slim card shows only the header and Your turn. When the balls stop the compact condition goes false and content() at 215-239 returns at full height.
- Skeptic (against): The code reading is accurate. slim() at TrickShotViews.swift:293-305 shows the header plus Your turn for .explaining. Compact is on while lensReplayCompact holds (ShowpieceView.swift:495-497, which needs !aimReady). The replay starts at TrickShotMode.swift:262-266, and content() comes back once aimReady is true. But this is the designed behaviour, not a defect. The doc comment at TrickShotViews.swift:290-292 and the one at ShowpieceView.swift:466-468 ("B3, item 13") say the slim card is deliberately "the shot's heading and the one button", "Your turn while the answer is ... explained", so the table keeps its height during the replay. CaptionStrip (ShowpieceView.swift:439-443) carries the explanation during the replay. The card growing when the balls stop is the trade that design accepts. No mis-wiring.

### 65. Spin marks shrink to hairlines on a phone, and from overhead the draw/follow belt is seen edge-on

- What the player sees: Balls are about 9 points across. The magenta slip belt is a vertical ring round the ball, so from the Lens's straight-down view it projects to a bar about 1 to 2 points wide across the ball. It sticks out only about a point and a half each side, with an arrowhead about 2.7 points long on top: nothing shows which way the ball is turning. The blue side-spin ring is a band about a point wide, 2 points outside the ball, with a 3-point arrowhead, so clockwise and anticlockwise english look the same. Draw, follow and english, central to the trick shots, are not readable.
- Fix if taken: In LensLayer.applySpin, set a minimum on-screen size for the belt, ring and arrowheads from the camera's points per metre, and lay the slip belt flat on the cloth (or tip it toward the camera) when the camera is near straight down.
- Skeptic (stands): Reachable: the Lens works on an upright phone (ShowpieceView.swift:438,492 have phone-upright Lens branches). The camera goes to 89 degrees once the Lens is fully in (TableCamera.swift:186, 80 with Reduce Motion), and the default framing shows the whole table. Spin markers draw for any visible ball once melt is above 0.02, with no phone check (LensLayer.swift:1035). The belt basis is up, slip axis, cross (LensLayer.swift:1064-1065), so its circle stands upright and is seen edge-on from overhead. All sizes are fractions of R, never screen points (LensLayer.swift:480-481, 1066-1071, 1083-1089). One overstatement: each marker has an arrowhead (LensLayer.swift:913-915) that does point the way of the spin, but it is only a few points long, so it is hard to read.
- Skeptic (against): The report is right that the belt's ring stands upright and is seen edge-on. But its arrowhead is made to lie flat on top of the ball, facing the overhead camera. The comment at LensLayer.swift:888-891 says so on purpose. At 1063-1064 the frame sends local x straight up, and the head spans local y and z, which are both level. So the head does show which way the ball turns. The side ring is level on the cloth. The half-turn flip at 1086-1087 reverses the sweep, so the head points the opposite way for clockwise english. The sizes are also too small: the code's own phone scale at 763 (0.013 m is about 3 points) puts the ball near 13 points and the head near 4. The marks are small, but neither is unreadable.

### 66. Tapping Ride during a guided Lens replay drops the held explanation, races on at real speed and jolts the layout

- What the player sees: The held explanation is let go at once. The replay runs on at about real speed, so the strip's captions on a break are replaced several times a second and never readable. The slim cards jump back to their full height in one frame, pushing the table up. The ride view's framing jumps with them instead of easing as the table's own framing does. The same unreadable captions appear whenever Replay is pressed with Ride already on, because that Lens replay is never guided.
- Fix if taken: In setRide, when turning Ride on while guided is true and the stage is explore, record it in rideHeldForGuidedReplay instead of setting rideOn, so Ride comes on when the replay ends (show the button lit from that held flag).
- Skeptic (stands): On a phone held upright the Ride button is always on screen and never disabled. The controls are placed with no condition (ShowpieceView.swift:464), Ride has no disabled state (PlaybackControls.swift:232, 268-270), and during a guided replay the shot panel stays closed, so the buttons row shows (ShowpieceView.swift:166). The free-play route works: Watch it in the Lens holds Ride off and starts a guided replay (ShowpieceModel.swift:3349-3355). Tapping Ride then clears the hold and turns Ride on (1034-1035). That makes the replay unguided (3607), drops the held caption and plays at the Ride curve, which is real speed except near the first contact (2632-2638; ShotCamera.swift:143-152). The slim cards depend on guided with no animation tied to it (ShowpieceView.swift:495-497, 466-474). The Ride-on plus Replay case is a deliberate design (comment at 3602-3603).
- Skeptic (against): The code is read correctly, but what it describes is the intended design, written down in the code. ShowpieceModel.swift 1032-1034: a deliberate Ride tap replaces the held Ride. Lines 3600-3602: Ride keeps its own slow-motion curve and does not mix with guided pacing. Line 2630: a held beat is let go once Ride turns on. PlaybackControls.swift 82-84: with Ride on, Replay deliberately makes no slow-motion promise. The camera jolt is hidden. In ShotCamera.swift 225-233 the ride blends in from the eased overhead view over half a second (engage starts at 0), so the frame where the cards snap shows the overhead pose. With Ride already on, Replay is never guided, so the cards never slim and nothing jumps. Unguided caption timing is the Lens's ordinary real-speed behaviour, not something Ride adds.

### 67. Notebook rows show the bare formula, never the worked numbers

- What the player sees: With Show the maths on, each notebook row shows only the formula ("p = m · v"). The caption card for the same moment shows the event's own numbers ("p = m · v = 0.170 kg · 6.20 m/s = 1.05 kg·m/s"), and even on headline beats the notebook row never does.
- Fix if taken: In App/NotebookStory.swift, replace caption.equation with CaptionContent.equationLine(caption) in the maths row (line 144) and in accessibilityValue (line 169). Leave the headline behaviour as it is.
- Skeptic (against): The code mismatch is real. NotebookStory.swift:143-147 draws the plain caption.equation, while CaptionViews.swift:167-169 prefers caption.worked. But a regular iPhone can never show the notebook, so this fails the phone reachability test. The notebook is only built when a division exists (ShowpieceView.swift:148,155,180-183). A division needs either a folding-phone hinge (ScreenLayout.fold) or NotebookGeometry.split. That split needs a width of at least 744 points (NotebookGeometry.swift:29,92) and, when sideways, a height of at least 500 (lines 32,94). An upright iPhone is about 402 points wide, and a sideways one about 402 tall, so split returns nothing either way. A regular phone has no hinge. The report itself says this is not an upright-phone screen. On a Duo, iPad or Mac the defect does exist: the notebook row should use CaptionContent.equationLine(caption).
- Skeptic (stands): Confirmed. App/NotebookStory.swift:143-147 draws caption.equation when maths is on, and line 169 gives VoiceOver the same bare text. App/CaptionViews.swift:167-169 (equationLine) prefers caption.worked. App/Captions.swift:89-92 says worked replaces the bare equation whenever Show the maths is on, and Captions.swift:545-864 fills worked for many events, so the gap shows up in real play. Nothing else in the notebook swaps in worked. NotebookPanel.swift:291/338 shows this list on the open Duo, iPad and Mac. The headline half of the report is weaker. The notebook lists every moment, while holdingHeadline is a pacing state for the card. That part is a design choice, not a contract break.


## Thrown out

- Shot panel pops open greyed at the start of the computer's turn, with its button unlit and dead: The route is real. A foul shows as a card (MatchMode.swift:452), and Continue runs beginTurn (MatchMode.swift:614), so the computer starts thinking (ShowpieceModel.swift:1838-1839). Nothing else closes the panel, so it comes back (ShowpieceView.swift:225-227). But this is the designed state for ever / The state is reachable, but it is the designed computer-turn look, not a bug from the foul card. ShotPanel.swift:85-87 and its header (lines 44-45, item 16) say the person's controls stay visible but greyed during the computer's turn, with a status line. PlaybackControls.swift:236-243 (L-A) delibera
- The 'Your first break' card is skipped in the same frame it is set (deliberate since 0.7.1, but its summary is lost): On every first launch the card is skipped in the same frame (ShowpieceModel.swift:2113-2117), but that is the intended 0.7.1 design (comment at 2114-2115, OpeningHandover.swift:29-33), so it is not a defect. The harm the report claims is mostly false. VoiceOver still speaks a summary of every finish / The code reading is right: at ShowpieceModel.swift:2113-2117 the stage is set to the first-break card and then immediately cleared by Keep playing, so the card at OpeningHandover.swift:240-296 never draws. But that was a deliberate 0.7.1 change (comments at 2114-2115 and OpeningHandover.swift:31-33)
- Earlier lead corrected: lens-replay: S21 partly: following the faster ball is right for the plain Energy handed off caption (its first sentence is about the mover); it is wrong only on Throw captions, whose sentence names the struck ball.
- Earlier lead corrected: ride: S10 (second half only): the Ride button staying lit after a ride ends is correct. Ride is a standing toggle for every later replay, not a one-shot action; the modes that switch it on for a demonstration (TrickShotMode.swift 266, EightBallMode.swift 368) switch it off again.
- Earlier lead corrected: ride: S23: not visible on the phone. MacChrome.swift 365 and TableScene.swift 74 are code comments. The only player-facing stale words are the Mac toolbar tooltip at MacChrome.swift 518 ('follows the balls at table height'), which shows only on the Mac. The catalog string 'During a replay the camera rides behind the cue ball and the ball it hits' in Localizable.xcstrings is referenced by no Swift file, so it is never shown.
- Earlier lead corrected: words-and-numbers: S16 as worded: the captions do not mix number styles inside a sentence. Captions.swift 231-243 formats every number with the player's own locale (String(format:locale: Locale.current) and .formatted), which follows the device region, as Apple's own apps do, so a comma in an English sentence on a comma-region phone is consistent and expected. The real defect is elsewhere: the aim read-out and one hard-coded 2.5 ignore the locale (ShotPanel.swift 450, 378; AimOverlay.swift 648; Captions.swift 594). That is reported as the corrected S16 finding.
