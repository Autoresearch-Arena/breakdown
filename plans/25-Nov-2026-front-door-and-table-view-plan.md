<!--
Author: Claude Fable 5.2 Medium
Date: 25-November-2026
Edited: Claude Opus 5.5 Medium, 25-November-2026 (checked against the code: trick shots only rack the pool table, the
        daily shot sets its own cue angle, the Pencil raises the cue only while stroking in free play and games, one
        app target, the first-minute check before every push, a returning player is never pulled off a game).
PURPOSE: Build plan for what a reviewer sees first and most: the main menu and the ordinary view of the table, on
         iPad and the open folding iPhone first. The menu stops hiding the table and stops being a wall of paragraphs;
         the table fills its half of the screen and stops floating in a black void; the store page leads with the
         game's most unusual tables. Written for a junior developer.
         Read plans/25-Nov-2026-award-scores-order-plan.md first.
SRP/DRY check: Pass - checked App/TitleScreen.swift (the menu and its MenuRow), App/NotebookPanel.swift (big screens
         keep everything off the table already), App/CameraFraming.swift (the only place the table's fit is worked
         out), App/TableRoom.swift (the room exists and is not seen from the usual camera), scripts/store-shots.sh (the
         screenshot scenes) and the memory notes on the first minute (calm, pool table first, lessons never pushed) and
         the folding phone (table alone on one half).
-->
# The front door and the table view

## In plain words

Two things were weak in the review.

The menu. On the upright phone it is a glass card that covers the whole table. Each row is a title and a three- or
four-line paragraph, so only four of its ten rows fit on the screen. A reviewer's first look at the game's front
door is a page of small grey text.

The table. On the iPad the pool table sits in the upper half with dark empty bands above and below it and nothing
around it but black. The room that was built for the Ride camera cannot be seen from the usual camera. The most
unusual things the game has, the bumper pool, five-pin and bar billiards tables, are three rows down a menu.

This plan fixes both. It does not add any feature.

## Decisions already made

- **iPad and the open folding phone are designed first.** The upright phone gets the same ideas in less room.
- **The very first launch does not change.** A new player still lands on the racked pool table with one line on how
  to shoot. That was the Boss's call after 0.7.0 and it works. If he would now rather a first launch opened on a more
  unusual table, that is one line to change in step 3 of Stage 1.
- **From the second launch on, the game opens on today's shot,** on whatever table that shot uses, but only when
  today's shot is not yet played and no game is in progress. A game in progress reopens where it was left; a shot
  already played today opens on the last table played. Until the Shot of the day plan ships, it opens on the last
  table played. Nothing is pushed: no card, no lesson, just the table set up.
- **Nothing covers the table on big screens.** That rule already exists and stays.

## Stage 1: the menu

1. **One line per row.** In `App/TitleScreen.swift`, `MenuRow` draws a title and a paragraph. On every layout draw
   the title, its symbol and its count mark only. The paragraph moves to the accessibility hint (so VoiceOver still
   reads it) and to How to play. The intro paragraph under the game's name goes too; the name and "watch the physics
   think" stay.
2. **Three short groups** in place of one list of ten:
   - **Today:** Shot of the day (when it exists), Continue.
   - **Play:** Play a game, Trick shots, Behind the 8-Ball, Tables.
   - **More:** Learn, Achievements, How to play, Options, Watch the intro.
   The whole menu must fit on an iPhone 17 Pro screen without scrolling at the default text size.
3. **The table stays in view behind it.** On the upright phone the menu becomes a sheet over the lower half, not a
   card over everything. Above it the table shows today's shot laid out, or the last table played. On big screens
   the menu is already in the notebook half; check that the table half shows the same thing and is not dimmed.
4. **Tables are shown, not listed.** The Tables row opens four pictures of the tables side by side (pool, bumper
   pool, five-pin, bar billiards), each drawn by the real table builder at a small size, with its name under it. The
   list it replaces is `App/TableList.swift`.
5. **The accent colour.** The highlighted row uses the game's own accent, not the system's blue. (Also listed in the
   words plan as a rough edge; do it once, here or there.)

Done when: the menu fits on one upright phone screen, the table is visible behind it, and no row has more than one
line of text at the default size.

## Stage 2: the table fills its half

All of this is in `App/CameraFraming.swift`, which works out where the camera sits from the measured space. It is
pure maths with its own check tool (`Tools/framing-check`). Change the numbers there, not in the views.

1. **Measure first.** Run the framing check for an iPad upright, an iPad on its side and the open folding phone, and
   write down how much of the table half's height the table covers on each. In this review's iPad pictures it was
   roughly two thirds, with dark bands above and below.
2. **Fit to the short side.** Choose the camera's steepness per screen shape (`warmElevation` already does this) so
   the table, rails included, comes within a small margin of all four edges of its half. On an upright iPad that
   means a steeper look down than today.
3. **The other tables.** Bumper pool, five-pin and bar billiards are different shapes. Check each fills its half the
   same way.
4. **Turned on its side.** On an iPad on its side and on the open folding phone, the table takes the larger part and
   the notebook the smaller. Check the split still leaves the strike panel (from the strike panel plan) room for its
   tiles.

Done when: on each of the three screen shapes, for each of the four tables, the table's outer edge comes within a
small, equal margin of the edges of its half.

## Stage 3: no black void

The room was built for the low Ride camera (`App/TableRoom.swift`: walls, a floor, a lamp over the table). From the
usual camera, looking down, none of it shows and the table floats on black.

1. **Let the floor show.** Around the table the floor should be visible, lit by the lamp and falling off into dark
   at the edges of the view, so the table sits on something. Check why it reads as black today: the floor's own
   colour, the light's reach, or the camera's far edge.
2. **The lamp's pool of light** on the cloth is there but faint. It should be clearly brighter in the middle of the
   table than at the corners, on every surface.
3. **Do not add furniture or decoration.** A floor and light are enough. Anything more is a new art job.
4. **Check the frame rate** on an iPhone 17 Pro after the change. If lighting the floor costs frames during a break,
   bake the falloff into the floor's picture.

Done when: a still of the ordinary table view on an iPad shows a lit floor around the table and no pure black
inside the frame.

## Stage 4: the Lens keeps its bearings

In this review the Lens on the iPad, at the first moment of the break, showed one ball and an empty grid across the
whole table half. Zooming in on the action is right. Losing the table is not.

1. Whenever the Lens camera is zoomed in past the point where a pocket or a rail is visible, draw a small plan of the
   whole table in a corner of the table half, with a box marking what the camera is looking at and the ball as a dot.
2. It uses the Lens's own line colours. It takes no touches. It fades out when the camera pulls back.
3. The Ride view gets the same small plan (`App/RideMap.swift` already draws one; reuse it).

Done when: at no point in the opening break replay is it unclear where on the table the camera is.

## Stage 5: the store page leads with the unusual

1. `scripts/store-shots.sh` lists the screenshot scenes in order. New order: the Lens on a bumper pool shot; the
   strike panel with its figures; the Shot of the day result; bar billiards mid-game; a jump seen side on; then the
   rest.
2. Take the iPad and folding-phone sets first and check them before the upright phone set.
3. Add one line to the listing (`store/listing/en.json` and the eleven others) for the stylus: hover to aim, and
   stand the Pencil up as you stroke to raise the cue in free play and games. It is built and nobody is told. Word it
   no wider than that; the trick-shot modes set their own angle.
4. One simulator at a time. Shut each one down before starting the next.

Done when the first three pictures on the store page could not be mistaken for any other pool game.

## What not to do

- Do not change the first launch.
- Do not add a room full of objects.
- Do not put the menu, a card or a picture over the table on iPad or the open folding phone.
- Do not hide any mode. Every mode keeps a row.
