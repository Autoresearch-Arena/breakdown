<!--
Author: Claude Fable 5.2 Medium
Date: 25-November-2026
PURPOSE: Build plan for the two weakest award categories: inclusivity and social impact. Makes sure nothing in the game
         is told by colour alone, nothing needs a timed gesture, the controls can be mirrored for the left hand, the new
         screens from the other four plans are spoken and scale with text size, and a physics teacher has a page that
         tells them how to use the game in a lesson. Written for a junior developer. This plan goes last because it
         covers the screens the other plans add. Read plans/25-Nov-2026-award-scores-order-plan.md first.
SRP/DRY check: Pass - checked plans/21-Nov-2026-accessibility-plan.md (done: the table spoken aloud, controller play,
         larger text; this plan does not redo it), App/TableAccessLayer.swift and App/TableWords.swift (reused for the
         daily shot's mark), the three files that already read the "tell apart without colour" setting
         (App/LensTextures.swift, App/LensLayer.swift, App/TableStage.swift) and store/pages (privacy and support pages;
         the teachers' page is new).
-->
# Everyone can play

## In plain words

The base is good: a blind player is told where every ball is, the text grows with the system setting, a controller
works, and Reduce Motion is respected in most places. What is missing is smaller and specific.

The Lens tells sliding from rolling by magenta and cyan. Several actions are easiest with a quick, timed gesture.
The controls are laid out for a right hand. And the four other plans add new screens (the strike panel, the daily
shot, the board) that must be as usable as the old ones from the day they ship.

For social impact, the honest position is that a pool game will never lead this category. One thing is true and
unused: the game teaches school physics correctly and collects nothing. This plan tells teachers so.

## Part A: never by colour alone

1. **Read what exists.** `App/LensTextures.swift`, `App/LensLayer.swift` and `App/TableStage.swift` already check the
   system's "Differentiate Without Colour" setting. Write down what each does with it.
2. **Sliding and rolling.** Rolling paths are a solid line; sliding paths are a broken line. Make that the default
   for everyone, not only when the setting is on. It also reads better in a black-and-white screenshot.
3. **The legend chip** ("Sliding", "Rolling") shows the same solid and broken strokes beside its words.
4. **The scrub bar's marks** for impacts are told apart by shape as well as tint (`App/ScrubBar.swift`).
5. **New screens.** The daily shot's five try dots: a filled dot for a make, a cross for a miss, a ring for a try not
   yet used. The strike panel's planned and delivered figures each carry a one-word label; dim against bright is not
   enough.
6. **Solids and stripes** are already told apart by pattern. Check the target ball's badge names the ball by number
   as well as showing its colour.

Done when a greyscale screenshot of the Lens, the daily result card and the strike panel loses no information.

## Part B: no timed gesture needed

1. **Every shot can be played without the hand stroke.** The Shoot button plays the planned strike. Check this is
   true in every mode, the daily shot included, and that no achievement, lesson or score needs the stroke except the
   straight-stroke drill, which is about the stroke.
2. **No double tap needed.** Zooming on a ball by double tap also has a button or a menu entry on every layout.
3. **No two-finger gesture needed.** The bridge finger and pinch to zoom each have a control.
4. **Holding still is never required.** Nothing in the game fires because the player waited or failed to move in
   time.
5. **The keyboard and the controller reach everything new:** the strike panel's tiles, the daily card's buttons, the
   board. Follow `App/ControllerInput.swift` and `AimOverlay.handleKey`.

Done when the daily shot can be played from first row to shared result with a keyboard alone, and again with a
controller alone.

## Part C: either hand

1. **New option** in `App/GameSettings.swift`: "Controls on the left". Off by default.
2. With it on, the Shoot button, the tip picker and the power bar mirror to the other side on every layout, and on
   iPad on its side and the open folding phone the notebook half and the table half swap.
3. It is one flag read by the layout, set in one place. Do not add a second copy of any view.

## Part D: the new screens, spoken and scaled

1. **The mark.** The daily shot's mark is a place on the cloth. `App/TableAccessLayer.swift` gives every ball and
   pocket an element; add one for the mark, named and placed the way `App/TableWords.swift` places a ball ("the mark,
   near the foot rail, left of centre").
2. **The result,** spoken once when it appears: made on which try, how far from the mark, the score, the streak.
3. **The strike panel:** each tile is one element that reads its label, its figure and its unit in words ("Force,
   about one thousand seven hundred newtons"). After a shot it reads planned, then delivered.
4. **Text size.** At the largest sizes the strike panel's tiles go to one per row and scroll. Nothing shrinks its
   text to fit.
5. **Reduce Motion.** The menu's table does not turn, the caption list does not scroll by itself, the result card
   appears without a flourish.

## Part E: a page for teachers

1. **New file** `store/pages/teachers.md`, published on the studio site beside the privacy and support pages. One
   page. It says:
   - what the game shows that a physics class covers: momentum handed from ball to ball, friction turning a slide
     into a roll, energy lost at each hit, spin, the flight of a jumped ball, and how each changes on ice or on the
     Moon;
   - which of the six lessons and which Lens captions go with each topic;
   - that every figure on screen is in metric units and is worked out by the game, with the equation one tap away
     (Show the maths);
   - that the game has no account, no advertising and no purchases, collects nothing, and works with no internet;
   - how to turn the board off for a classroom (next item).
2. **New option** in `App/GameSettings.swift`: "Hide the board". With it on, the game never signs in to Game Center
   and the Board button is not drawn. The daily shot, the score and the streak still work.
3. **A link** to the page from How to play and from the support page.
4. **The store page** gains one line in its closing list: "For the curious and the classroom: the physics is shown
   in metric units, with its equations."

That line says what the game shows, not who uses it. Do not claim the game is used in schools until it is.

## What not to do

- Do not add a separate "accessible mode". Every item here changes the one game everyone plays.
- Do not shrink text to make a layout fit.
- Do not make any claim about who uses the game.
