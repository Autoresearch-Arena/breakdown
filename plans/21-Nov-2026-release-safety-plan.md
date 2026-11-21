<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for catching breakage before it reaches a phone: tests run before every upload, automated checks above
         the physics package, the privacy file the App Store requires, and stale documents brought up to date. Written
         for junior developers.
SRP/DRY check: Pass - checked .github/workflows/testflight.yml, scripts/testflight.py, the project file, the self-test
         launch flags in the app, README, ROADMAP and CHANGELOG.
-->
# Release safety

## In plain words

Every push to the main branch that changes the app is built and sent to TestFlight automatically. Nothing runs the
tests first. The only automated tests are for the physics package; the app itself has none, so a change that breaks
the menu, a trick shot or the scoring is found by whoever opens the build. The changelog already records one such
case: a polish change broke the build and the next change had to fix it. The project also has no privacy file, which
the App Store requires of any app that reads its own saved settings, as this one does. And the README and ROADMAP
describe a much earlier game: they list pocket jaws and spin controls as not built.

None of this is visible to a player, and all of it decides whether the other plans can land without breaking what
works.

## Package 1: tests before upload

1. In scripts/testflight.py, before the archive step, run the package tests with a scratch path on the Team 4TB
   drive. If they fail, stop, upload nothing, and print the failing test names.
2. Run the BreakProbe authoring checks for trick shots and puzzles in the same place. A physics change that breaks
   an authored shot must stop the upload.
3. The runner is the Mac Mini; keep it to one build at a time. Do not add parallel jobs.

## Package 2: checks above the physics

1. Add a unit test target to the Xcode project for app logic that needs no screen: the trick-shot judge, the
   eight-ball judge, FeelMapping, the camera framing maths (it has a harness already; move it into a test),
   CaptionEngine (spec test 16: each caption fires only on events that meet its rule), and later the rules engines.
2. The app has self-tests behind launch flags (the Lens scrub check, the Ride check, the aim script). Turn each into
   a test that launches nothing: call the same check function and assert on its result instead of printing.
3. One smoke test that launches the app with each of the store-shot launch flags in turn and fails if the app
   exits or logs an error within a few seconds. This is the cheapest guard against a broken screen. Run it on one
   simulator, after the merge, never in parallel.
4. Translation check: a script that fails if any string in the catalog lacks one of the twelve languages or has
   mismatched placeholders. scripts/localization-merge.py is the place to start from.

## Package 3: what the App Store needs

1. Add the privacy file to the app target declaring the saved-settings reason and that no data is collected.
   Read Apple's current page for the exact reason codes before writing it; do not guess.
2. Set the app category in the project (games, and the sub-categories that fit).
3. If the accessibility plan adds controller support, declare it in the project in the same change.
4. Check the launch screen, the icon set and the minimum system version against what the store listing says.

## Package 4: documents that tell the truth

1. README: replace "What runs today" with the game as it is (trick shots, Behind the 8-Ball, surfaces, tables, the
   Duo layout) and move the old milestone text out.
2. ROADMAP: replace with a pointer to the order-of-work plan of 21 November and delete items that are done.
3. Parameters.swift and Impacts.swift headers: fix what the rails plan and proof plan call out.
4. The spec stays as the design record; add a short note at its top listing which sections are built, which are
   planned in which plan, and which are dropped.

## Package 5: speed and stalls

1. Measure, on the oldest supported iPhone: launch to first frame, launch to menu, time to solve a break, frame
   rate during a break with the Lens on and with Ride on. Write the numbers into this plan under "Measured".
2. Anything that solves shots on the main thread is listed in the pockets-and-jams plan; this package only measures.
3. Memory: play fifty shots and switch table and surface ten times; memory must return to where it started.

## Done when

A failing test stops an upload, the app has its own test target with the judges and captions covered, the privacy
file is in the build, and the README describes the game that actually runs.
