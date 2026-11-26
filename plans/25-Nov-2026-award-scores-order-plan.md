<!--
Author: Claude Fable 5.2 Medium
Date: 25-November-2026
PURPOSE: The front page for the five plans written on 25 November 2026 after a hostile "Apple reviewer" read of
         Breakdown 0.7.9. Says what score each award category would get today, what score each plan is meant to
         reach, the order to do the plans in, who can work at the same time, and what we stop doing meanwhile.
         Written so a junior developer can start here and know which plan to open. Start here.
SRP/DRY check: Pass - checked plans/21-Nov-2026-award-gaps-order-plan.md (the earlier front page; its twelve plans are
         done and it stays as history) and ROADMAP.md (its "daily challenge" item is the Shot of the day plan below).
         This file only orders and links the five plans; it does not repeat their steps.
-->
# Raising the scores: the order of work

## Where the game stands (0.7.9, looked at on a clean iPhone 17 Pro and an iPad Pro)

The scores a hard Apple reviewer would give today, out of ten, and where each plan is meant to take them:

| Category | Today | Target | The plan that moves it |
|---|---|---|---|
| Delight and fun | 5 | 8 | Shot of the day |
| Innovation | 7 | 9 | Strike panel and controls (plan the strike in real units, planned against delivered) |
| Interaction | 5 | 8 | Strike panel and controls |
| Visuals and graphics | 6 | 8 | Front door and table view |
| Inclusivity | 5 | 7 | Everyone can play |
| Social impact | 2 | 4 | Everyone can play (the classroom page). This is the weakest category for a pool game and not where we win. |

Why the scores are what they are, in one line each:

- **Delight.** Nothing brings a player back tomorrow. There is a lot to do once and no reason to return.
- **Innovation.** The Physics Lens is new and good. It is only seen after a shot, and the player never sees the
  strike they are about to make in real units.
- **Interaction.** The controls are small and split between a gesture and a button, and on the iPad they are squeezed
  into a quarter of the screen while the half beside them is empty.
- **Visuals.** The table sits in a black void with wide dark bands above and below it. The menu is a wall of
  paragraphs that hides the table.
- **Inclusivity.** A strong base (the table is spoken aloud, larger text, controller, Reduce Motion). The Lens still
  leans on colour, and several actions need a timed gesture.
- **Social impact.** No story yet. A physics teacher could use this game and nothing invites them to.

## What changes in how we think about the game

Direction from the Boss, 25 November 2026:

1. **iPad and the folding iPhone come first.** The upright phone must work, and the design is not held back for it.
2. **The game is a quick daily habit.** Open it, try today's shot, see the board, leave. Trick shots and puzzle shots
   are the content for that.
3. **Nerd for nerds.** The player sees exactly what they are about to do to the ball, in real units, before they do
   it. The controls are large and plain, never fiddly.
4. **Only claims we can back up.** "Nothing is faked" and "real physics" come out of the store page and the game.
5. **Fewer words, never moving fast.** One short line per moment. The rest waits behind a tap.

## The plans, in order

| Order | Plan | What it delivers | Size |
|---|---|---|---|
| 1 | [Fewer words and honest claims](25-Nov-2026-fewer-words-and-honest-claims-plan.md) | The rough edges found in this review, short captions, a truthful store page | Small |
| 1 | [Strike panel and controls](25-Nov-2026-strike-panel-and-controls-plan.md) | The strike in real units before the shot; large plain controls on iPad and the folding phone | Medium |
| 2 | [Front door and table view](25-Nov-2026-front-door-and-table-view-plan.md) | A menu that does not hide the table; the table filling its half; no black void | Medium |
| 2 | [Shot of the day](25-Nov-2026-shot-of-the-day-plan.md), stages 1 and 2 | The daily shot, its score, the streak and the share card, with no sign-in | Large |
| 3 | [Shot of the day](25-Nov-2026-shot-of-the-day-plan.md), stages 3 and 4 | Game Center boards and achievements; a bigger bank on every table and surface | Large |
| 3 | [Everyone can play](25-Nov-2026-everyone-can-play-plan.md) | Not by colour alone, no timed gesture needed anywhere, a page for teachers | Medium |

Rows with the same order number can be worked at the same time by different people. Each plan ships as its own
patch version (0.7.10, then 0.7.11, and so on). Nobody jumps the version number.

## Why this order

- The words plan goes first because it is small, it removes things a reviewer notices in the first minute, and every
  later plan adds words that should follow its rules from the start.
- The strike panel goes first too because the daily shot is played with it. Building the daily shot on today's
  controls would mean laying its screen out twice.
- The front door waits for the strike panel because both change the notebook half of the big-screen layout
  (App/NotebookPanel.swift). One writer at a time on that file.
- The daily shot's first two stages need no sign-in and no store setup, so they can ship and be played while the
  Game Center setup is done.
- Everyone can play goes last because it has to cover the new screens the other plans add.

## Who can work at the same time

Two developers can work in parallel if they keep to these files:

- **Developer A:** the words plan, then the front door plan. Owns App/Captions.swift, App/CaptionViews.swift,
  App/NotebookStory.swift, App/TitleScreen.swift, App/CameraFraming.swift, the store folder.
- **Developer B:** the strike panel plan, then the Shot of the day plan. Owns App/ShotPanel.swift, App/AimGauges.swift,
  App/Phone/PhoneAimPanel.swift, the new App/Strike and App/Daily folders, the BreakProbe tool.
- **Shared, one writer at a time:** App/ShowpieceModel.swift, App/ShowpieceView.swift, App/NotebookPanel.swift,
  App/Localizable.xcstrings. Say in the team channel before you touch one of these, and keep the change small.

Each developer works on a branch and does not compile while writing. The coordinator merges, compiles once, runs the
four checks in scripts/testflight.py and pushes. The Boss tests on TestFlight himself.

## What we stop doing until these land

- No new tables, surfaces, game modes or replay features. The game is wide enough.
- No more passes on a single replay. The jump replay had two versions in two days.
- No store page claim that is not a plain fact a reviewer can check on the device.

## Apple features: which are worth it

| Feature | Verdict | Why |
|---|---|---|
| Game Center leaderboards | Yes | The daily board is the social hook. Apple's Games app shows friends' scores and lets them challenge each other, which is free promotion. |
| Game Center achievements | Yes | The achievements are built and already have permanent names made for this. |
| Apple Pencil as the cue | Already built, undersold | Hover aims and tilt raises the cue. It is not in the store page or the first-minute hint. The front door plan fixes that. |
| A home-screen widget | Later, small | Only useful once the daily shot exists: today's layout and the streak. Stage 5 of the daily plan. |
| Progress following the player between iPad, iPhone and Mac | Later | Game Center carries the achievements and scores. The streak can follow through iCloud once the daily shot has proved itself. |
| Shortcuts, Live Activities, playing over a call | No | None of them fits a one-minute pool shot. They would be boxes ticked, and reviewers can tell. |

## How we will know it worked

A person opens the game on an iPad for the first time and sees a table, not a wall of text. Within a minute they
have played today's shot with controls they did not have to be taught twice, seen the force they planned beside the
force they delivered, and seen where they stand on the board. The next day they open it again.
