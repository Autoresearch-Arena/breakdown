<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for making Breakdown look and feel as good on iPad and Mac as it does on iPhone. The game was designed
         iPhone first, on purpose, and that was right; this plan gives the two larger screens their own designed
         layouts instead of a stretched phone. Written for junior developers.
SRP/DRY check: Pass - checked ShowpieceView.swift, Surfaces.swift (ScreenLayout), MacChrome.swift, DuoPanel.swift,
         DuoStory.swift, DuoInfo.swift, TableCamera.swift, CameraFraming.swift and the look plan. The look plan's
         package 4 is replaced by this plan and now points here.
-->
# iPad and Mac, done properly

## In plain words

The Boss's direction (21 November 2026): leading with the iPhone was right and the iPhone looks good; iPad and Mac
must look just as good. Today they do not. The iPad capture shows the table on the left two thirds of the screen and
a nearly empty black column on the right with one small card in its corner. The Mac has a proper toolbar and menus,
but its window is the same phone layout made wide, and no Mac store pictures were ever made because nobody has
studied the Mac build on screen.

The good news is that the right design already exists in the code. The open folding phone has a full "notebook"
beside the table: the live step-by-step story of the shot, its numbers, the surface and table cards, and every menu
as a page of that panel so nothing covers the table. That is exactly what a big screen wants.

## What exists today

- ShowpieceView.swift picks the layout. ScreenLayout (in Surfaces.swift) has two tests: wide (a side column) and
  short (a phone on its side). A fold gets the notebook panel; nothing else does.
- DuoPanel.swift, DuoStory.swift and DuoInfo.swift build the notebook and its pages.
- TableCamera.swift fits the table into the free space it is given, at an angle chosen for the screen's shape.
- MacChrome.swift: window toolbar, Playback menu, keyboard shortcuts. The window has a minimum and default size.
- Aiming is by drag on the table, with arrow keys as a fallback. No pointer hover, no scroll wheel, no trackpad
  gestures, no Apple Pencil thought.
- Menus, lists and options open as sheets over the table on iPad and Mac.

## Rules

1. One codebase, three designed layouts: phone, notebook (iPad, Mac, open fold), and the closed fold. No layout is a
   stretched version of another.
2. On the notebook layout nothing ever covers the table. Menus, lists, rules and options are pages of the panel.
3. Every layout decision reads the space the window actually has, never the device name, so iPad split view, Stage
   Manager and a resized Mac window all work. Load the app-resizability skill's guidance before changing layout
   code if it is available in your session.
4. The iPhone layouts must not change. Capture them before and after.

## Package 1: the notebook on every big screen

1. Rename the Duo panel's role in the code from "fold" to "notebook" where it is not about the hinge, and let
   ShowpieceView choose it by available width: any window wide enough for the table plus a readable column of text
   (set the threshold by measuring, start near the width of an iPad mini held upright).
2. A fold places the split on the hinge. Without a hinge, the split is a proportion: table side gets what the table
   needs at the best camera angle, the panel gets the rest, within a minimum and maximum panel width.
3. Orientation of the table follows the space: when the table side is wider than tall the table lies along the
   long side; otherwise it stands upright. CameraFraming.swift already chooses angle by shape; extend it, and add
   cases to its test harness for the common iPad and Mac window shapes.
4. Very wide windows (a Mac at full screen, an iPad in landscape): the panel splits into two columns, story on one
   and numbers and controls on the other, as the propped-open fold already does.
5. Narrow windows (iPad split view at one third, a small Mac window): fall back to the phone layout cleanly.
6. The panel's text sizes are comfortable at arm's length on an iPad and at desk distance on a Mac. Check the
   largest and smallest system text sizes.

Done when: the empty black column in the iPad capture is a full notebook, and dragging a Mac window from its
smallest to full screen passes through phone, notebook and two-column notebook with no jump, clip or overlap.

## Package 2: the Mac as a Mac

1. Pointer: hovering the table shows the aim line following the pointer before any click; click and drag back sets
   power; release shoots. Scroll or two-finger slide fine-tunes the aim. Pinch zooms the table (the look plan adds
   zoom). Hover highlights on every control.
2. Keyboard: everything reachable without a pointer. The shortcuts in MacChrome.swift stay; add tip position, power,
   call a pocket, next and previous explained moment, and show them in the menus.
3. Menus: a Game menu (new game of each kind, tables, surfaces), a View menu (Lens, Ride, zoom, panel on and off),
   Playback as now, and a Help menu that opens How to play.
4. Options open as a proper settings window from the app menu, with the standard shortcut.
5. Window: remembers its size and place; full screen works; a second window is either supported properly (each with
   its own game) or prevented, not left to chance.
6. Sound: follows the Mac's output; no haptics, so anything a haptic says must also be seen or heard.

## Package 3: the iPad as an iPad

1. Split view and Stage Manager at every size, including the smallest, with live resizing.
2. Hardware keyboard and trackpad get the Mac's package 2 behaviour; they share the code.
3. Apple Pencil: hover shows the aim line, as the pointer does; drawing back sets power.
4. Both orientations are designed, not just allowed. Rotating mid-shot keeps the shot playing.
5. The larger touch area allows two-handed play: aim with one hand on the table, power and tip under the other
   thumb at the panel's lower edge. Place those two controls there.

## Package 4: prove it and show it

1. Add iPad and Mac window shapes to the camera framing tests.
2. Capture the standard six views (see the look plan) on an iPad in both orientations and on a Mac window at three
   sizes, before and after each package, and keep the pairs on the Team 4TB drive.
3. Make the Mac store picture set and refresh the iPad set (store/screenshots/README.md). The Mac set was skipped
   earlier because capturing meant opening windows over the desktop; capture a single window by its id instead.
4. Every plan of this date that adds a screen (rules games, lessons, other tables) must show that screen as a
   notebook page on iPad and Mac. Reviewers check this on every pull request.

## Done when

The Boss opens the game on his iPad and his Mac and neither has an empty region, a sheet over the table, or a
control that only works by touch.
