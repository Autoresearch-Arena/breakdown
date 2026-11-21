<!--
Author: Claude Fable 5.2 High
Edited: GPT 6.2 Astra High, 21-November-2026, added the retry and learning check to the order of work.
Date: 21-November-2026
PURPOSE: The front page for the twelve gap plans written on 21 November 2026 after a critical review of Breakdown
         against Apple Design Award standards. Says honestly where the game stands, what the gaps are, which plan
         covers each, the order to do them in and who can work at the same time. Start here.
SRP/DRY check: Pass - checked README, ROADMAP, the spec and every file in plans. This file only orders and links
         the other plans; it does not repeat their steps.
-->
# Closing the gaps: the order of work

## Where the game stands, honestly

The idea is award-shaped: a pool table that shows you its own physics, with an exact solver underneath, a slow-
motion Lens, a special layout for the folding phone and twelve languages. Very few games have a reason to exist
that clear.

What stands between it and an award is that it is wide and thin. In three weeks it grew four tables, six surfaces,
ten trick shots, twelve puzzles and a store listing, and the middle of the game was skipped over on the way:

1. You cannot play a game of pool. There are no turns, fouls, groups or endings. (Biggest gap.)
2. The physics the game sells is partly unproven. Rails are a simplified wall; side spin costs nothing; several key
   numbers are first guesses that were never checked against a real table; about half the planned tests are missing.
3. A wedged ball can stall the app, and pockets swallow anything.
4. Three of the four tables keep no score.
5. Sound is thin.

A second, deeper pass the same day added five more:

6. A new player never sees the opening. The game starts on a menu of seven buttons; the break-and-melt opening is
   sixth in the list. The lesson path the spec calls the spine of the game does not exist.
7. The look falls apart at the low Ride camera (no room, flat cloth, blocky pockets), and balls cannot be read on
   an upright phone.
8. iPad and Mac are a stretched phone. The iPad shows a third of the screen empty.
9. The controls are accessible but the table is not: a blind player is never told where a ball is or what a shot did.
10. Nothing runs the tests before a build ships, the app has no tests of its own, the App Store privacy file is
    missing, and the README describes a much older game.

Award winners are narrow and finished. The plans below make Breakdown finished. None of them makes it wider.

## The plans

| Order | Plan | What it closes | Size |
|---|---|---|---|
| 1 | 21-Nov-2026-physics-proof-plan.md, packages 1 to 3 | The safe switch for new physics, the missing tests, the real-world checks | Medium |
| 1 | 21-Nov-2026-pockets-and-jams-plan.md, part B | The stall on wedged balls | Small |
| 1 | 21-Nov-2026-rules-games-plan.md, packages 1 and 2 | Shared reading of a shot; free play finished | Medium |
| 2 | 21-Nov-2026-rails-plan.md | Real rails | Medium |
| 2 | 21-Nov-2026-cue-strike-plan.md | Side spin has a price; miscues | Medium |
| 2 | 21-Nov-2026-pockets-and-jams-plan.md, part A | Pockets that can refuse a ball | Small |
| 2 | 21-Nov-2026-rules-games-plan.md, packages 3 and 4 | Eight-ball and nine-ball for two | Large |
| 3 | 21-Nov-2026-physics-proof-plan.md, package 4 | Tune the numbers, re-author every trick shot and puzzle once, make new physics the default | Medium |
| 4 | 21-Nov-2026-rules-games-plan.md, packages 5 and 6 | Computer opponent, finishing touches | Large |
| 4 | 21-Nov-2026-sound-plan.md | Sound | Medium |
| 5 | 21-Nov-2026-other-tables-games-plan.md | Scores and rules on the other three tables | Large |
| 1 | 21-Nov-2026-release-safety-plan.md, packages 1 to 3 | Tests before every upload; app tests; privacy file | Small |
| 1 | 21-Nov-2026-first-minute-and-lessons-plan.md, packages 1 and 2 | The opening plays first; a menu a stranger can read | Small |
| 1 | 21-Nov-2026-ipad-and-mac-plan.md, package 1 | The notebook layout on every big screen | Medium |
| 2 | 21-Nov-2026-ipad-and-mac-plan.md, packages 2 to 4 | The Mac as a Mac, the iPad as an iPad | Medium |
| 2 | 21-Nov-2026-look-plan.md | A room, the table up close, readable balls | Large |
| 3 | 21-Nov-2026-accessibility-plan.md | The table spoken aloud; not by colour alone; controller | Medium |
| 4 | 21-Nov-2026-first-minute-and-lessons-plan.md, packages 3 and 4 | The six lessons (after new physics is the default) | Large |
| 1, then 4 | [Plan 14 · Learn from a retry](21-Nov-2026-learn-from-a-retry-plan.md) | Check the existing retry now, then use the first lesson to see whether a beginner can apply it to a different shot | Small playtest and a focused app change |

Rows with the same order number can be worked at the same time by different people.

## Why this order

- The physics switch comes first because every trick shot and puzzle was authored on today's exact physics. Any
  physics fix made without the switch breaks them without warning. With the switch, all physics fixes pile up
  behind it and the content is re-authored once, in order 3, instead of four times.
- The jam guard is safe to ship at once and removes a freeze players can hit today.
- The rules games touch the app, not the solver, so they run alongside the physics work without collisions. The one
  shared file is ShowpieceModel.swift; see below.
- The computer opponent waits for the new physics to be the default, or it would be tuned twice.
- The other tables wait for the match engine they reuse.
- The big-screen notebook layout goes early because every new screen in the other plans must be built as one of its
  pages; building it late means building those screens twice.
- The lessons wait for the new physics, like the trick shots, so they are authored once.

## Who may touch what at the same time

- Physics people work only in Packages/BreakdownCore, plus the captions and Lens event files named in their plan.
- Rules-games people work in App/Match, App/EightBall and the menu.
- ShowpieceModel.swift, the string catalog, CHANGELOG.md and the project version are shared. One person merges at a
  time; say in the team channel before you start on any of them.
- Nobody compiles the app in parallel. One iPhone build, one Mac build and the package tests after each merge, with
  build output on the Team 4TB drive.

## Decisions waiting for the Boss

One, and it can wait: on the Moon surface, is the game silent or does a low rumble come through the table (sound
plan). Everything else has been decided and the reasons are written where the decision is made. Nothing is hidden
or removed from the game while this work is done.

Direction from the Boss, 21 November 2026: iPhone-first was right and stays; iPad and Mac must look just as good.
Every plan that adds a screen must deliver it on all three.

## How we will know it worked

A person who has never seen the game can open it, play a full game of eight-ball against a friend or the computer,
bank a ball and see it come off the rail the way it would in a pool hall, pay a price for careless side spin, and
find nothing in any menu that is half-built.
