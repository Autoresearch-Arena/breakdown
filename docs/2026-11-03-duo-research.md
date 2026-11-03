Author: Claude Sonnet 5.5 Medium
Date: 03-November-2026
PURPOSE: What is actually known about the iPhone Duo (checked on Apple's own pages today), what it means for the game, and the game ideas it opens. Written for the Boss; plain words first.

# iPhone Duo: what we know and what to make of it

## The short version

The Duo is a real, shipping phone with two screens and a hinge. Apple gives apps a way to read how far the phone is open, and a way to lay content out across the fold. The standout for us: propped open on a table, the upright half and the flat half are like a wall and a floor. A physics game can show the same scene from the front on the upright half and from above on the flat half, and the real gravity of the table matches the game's.

The surprise: Apple's own spec page does not list a depth scanner on the Duo. The scan-your-room smashing idea cannot assume the Duo does it. Photos from the two 48 megapixel cameras plus on-device depth guessing, or a scan made on a Pro iPhone and shared across, are the ways in.

## Facts (Apple Support tech specs page, Apple newsroom, 03-November-2026)

- Inner display 7.6 inch, 1878 by 2670 pixels, up to 120 Hz, nano-texture finish. Outer display 5.4 inch, 1398 by 2034 pixels, up to 120 Hz.
- Open: about 164.6 by 117.8 by 5.2 mm. Closed: about 84.1 by 117.8 by 11.3 mm. Weight 254 g either way.
- A20 Pro chip with a vapor chamber, Apple says up to 35 percent better sustained performance than iPhone 17 Pro. Touch ID, no Face ID.
- Rear: 48 MP main, 12 MP 2x telephoto, 48 MP ultra wide. Front: 12 MP outer, under-display inner camera.
- No depth scanner (LiDAR) in Apple's sensor list.
- iOS 27.1 SDK adds a hinge API (react to the display angle as it opens and closes), arrangement and reserved-region APIs (custom layouts across the fold or edge to edge), and "scene accessories" for showing content on both displays at once. Apps built for older SDKs run in a compatibility mode with unused blank space. Apple says all new apps need Duo screenshots from April 2027.
- Postures Apple names: closed (outer screen, pick-up-and-play), partially folded (table or counter, content split between the upright and resting halves), fully flat open, propped open hands-free.
- Games Apple highlights adapt controls to each posture, and play immersive open and pick-up-and-play closed.
- Not found: any Epic Games or Unreal Engine announcement of Duo support. The exact names of the hinge API types were not found in primary sources.

## What it means for the game

1. Two views of one world. Propped open, the upright half shows a side view and the flat half a view from above, like an engineering drawing. For pool, the top view is the shot and the side view shows spin, bounce and jump. For smashing, it shows the wall coming down and the floor mess at once.
2. The hinge as an honest dial. The angle of the phone can set the cue height or the tilt of a ramp, as a slow analog control. Nothing in the game should ask anyone to snap the phone shut.
3. Outer screen is the quick mode: one-hand replay and slow motion, a single shot challenge.
4. Fold or unfold mid-shot must never disturb the game. The recorded timeline is the truth, only the view changes.
5. Smashing without the depth scanner: take photos on the Duo, guess depth with on-device machine learning, or scan on a Pro iPhone and send the scene across. The dog models from the dog game are the easy first targets for smashing, since they need no scan at all.

## Engine decision (Boss, 03-November-2026): Unreal

The Boss prefers Unreal for its power, especially for the smashing phase. Things to settle early:
- Which Unreal version supports the iOS 27.1 SDK. Without the new SDK the game runs in the compatibility mode and wastes the screen.
- Reading the hinge angle needs a small native iOS plugin in Unreal; nobody has announced built-in support.
- The pool physics solver (pure Swift, tested, in this repo) should be ported to C++ rather than replaced by Unreal's physics, so the Lens still shows only numbers the game computed. The Swift tests carry over as the check on the port. Unreal's destruction physics is for the smashing phase.
- The running Swift app stays as the reference for how it should look and play.

Sources: Apple Support tech specs for iPhone Duo (support.apple.com/en-us/148588); Apple newsroom, Developers bring incredible new app experiences to iPhone Duo (October 2026); Apple Tech Talk 111461; 9to5Mac and TechRepublic coverage of iOS 27.1.
