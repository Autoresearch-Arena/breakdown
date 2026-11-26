<!--
Author: Claude Fable 5.2 Medium
Date: 25-November-2026
Edited: Claude Opus 5.5 Medium, 25-November-2026 (checked against the code: trick shots only rack the pool table, the
        daily shot sets its own cue angle, the Pencil raises the cue only while stroking in free play and games, one
        app target, the first-minute check before every push, a returning player is never pulled off a game).
PURPOSE: Build plan for the Shot of the day: one authored shot each day, the same for every player in the world, with
         five tries, a score, a streak, a result card to share, and Game Center boards. This is the reason to open
         Breakdown every day. Written for a junior developer: every stage says which files to make, what goes in them,
         what to test and how to know the stage is done. Read plans/25-Nov-2026-award-scores-order-plan.md first.
SRP/DRY check: Pass - checked ROADMAP.md ("a daily challenge" is listed as not built), App/TrickShots.swift,
         App/TrickShotMode.swift and App/TrickShotJudge.swift (a daily shot is a trick shot with a date and a score, so
         these are reused, never copied), App/Achievements (ids were made for Game Center), App/Clips/ClipShare.swift
         (the only share sheet, reused) and Packages/BreakdownCore/Sources/BreakProbe (the authoring tool, extended).
-->
# Shot of the day

## In plain words

Every day there is one shot. It is the same shot for everyone, everywhere. You get five tries. The game scores you on
how few tries you needed and how close the white ball stopped to a mark on the cloth. You see your score, your streak
of days, and the board. You can share a small picture of your result that does not give the answer away. Then you are
done until tomorrow. A visit takes about a minute.

It works with no sign-in and no internet. The board needs Game Center, and the game only asks for that when the
player asks to see the board.

## Decisions already made (do not reopen these)

- **The same shot for everyone, chosen by the date.** The shots ship inside the app in a fixed order. Day one is the
  first shot in the list, day two the second, and so on. When the list runs out it starts again. No server.
- **The day is the date in Coordinated Universal Time,** not the player's local date. That way the shot and the board
  change at the same moment for everyone.
- **Five tries.** A try is one strike from the shot's own layout.
- **The answer is hidden until you finish.** There is no "Watch it" button before you have made the shot or used your
  five tries. After that the answer plays in the Lens like any trick shot.
- **Score.** Try points plus precision points. (Ties are left to Game Center.)
  - Try points: 1000 for the first try, 800, 600, 400, 200 for the fifth. Nothing if you never make it.
  - Precision points: 199 minus the distance from the white ball's resting place to the mark, counted in
    half-centimetres, never below zero. Only counted on the try that made it.
  - So the best possible score is 1199. Two players with the same score are ranked by who posted first; Game Center
    decides ties by its own rule.
- **The physics is exact, so a leaked answer gives a perfect score.** We accept that, the way a word puzzle accepts
  that its answer can be looked up. The board that matters is the friends board.
- **Streak.** Days in a row with a make. A missed day or five misses ends it.
- **No reminders, no notifications, no pop-ups.** The menu row shows today's state. That is all.
- **The week has a rhythm,** so players learn what to expect: Monday an easy pot with position, Tuesday a bank or a
  kick, Wednesday a combination, carom or throw, Thursday spin (draw, follow or side), Friday another table, Saturday
  a strange surface, Sunday a hard one (jump or massé).

## Stage 1: the bank and the pure pieces (no screens yet)

Goal: the game can answer "what is today's shot?" and "what did this attempt score?", with tests.

1. **New file** `Packages/BreakdownCore/Sources/BreakdownAuthored/AuthoredDaily.swift`. Follow the shape of
   `AuthoredTricks.swift` in the same folder. One entry per daily shot, in play order. Each entry holds: a permanent
   id (lowercase with dashes), the table, the surface, where every ball starts, the goal (which balls must drop and
   where, which ball must be hit first, a bank if one is needed), the mark where the white ball should stop, the
   authored answer (aim, power, tip up, tip side, cue angle), the measured windows, the difficulty, and the family
   (pot, bank, kick, combination, carom, throw, draw, follow, side, jump, massé).
2. **Seed it** with the thirteen trick shots and the twelve Behind the 8-Ball spots that already exist, each with a
   mark added. That gives twenty-five days to build and try the feature with. Stage 4 grows it.
3. **New file** `App/Daily/DailyShot.swift`. A small type that wraps one bank entry as a `TrickShot` (see
   `TrickShots.make` in `App/TrickShots.swift`) plus its surface, mark and family. Do not copy `TrickShot`'s fields.
4. **New file** `App/Daily/DailyBank.swift`. Two functions and nothing else:
   - the day number for a given moment: whole days between the fixed start date and that moment, both in Coordinated
     Universal Time;
   - the shot for a day number: the entry at that number, wrapping round at the end of the list.
   Take the clock as a parameter so tests can pass any date. The start date is a constant; set it to the release day
   of the version that ships stage 2.
5. **New file** `App/Daily/DailyScore.swift`. One pure function: given which try made it (or none) and the distance
   from the mark, return the score using the rule above. No views, no model.
6. **New file** `App/Daily/DailyRecord.swift`. What the player has done, saved on the device as one small value under
   one `UserDefaults` key, the way `App/Achievements/AchievementRecord.swift` does it: for each day played, the tries
   used, whether it was made, the score; the current streak and the best streak.
7. **Tests** in `BreakdownTests`: `DailyBankTests` (day numbers across midnight and across the end of the list),
   `DailyScoreTests` (every try, zero distance, a far miss, never negative), `DailyRecordTests` (streak grows, breaks
   on a missed day, breaks on five misses, survives save and load).
8. **Extend the content check.** `BreakProbe verify` plays every trick shot and every escape exactly as the app
   carries it. Add the daily bank to the same check (`Packages/BreakdownCore/Sources/BreakProbe/ContentVerify.swift`)
   so a physics change can never ship a daily shot whose answer no longer works.

Done when: the package tests and the app tests pass, and `BreakProbe verify` reports every bank entry.

## Stage 2: the mode and its screens

Goal: a player can play today's shot from the menu, see a result, a streak and a share card. No sign-in.

1. **New file** `App/Daily/DailyMode.swift`, modelled on `App/TrickShotMode.swift`. Read that file first. Differences:
   - it starts today's shot only (`DailyBank`), on that shot's table and surface;
   - it counts tries and stops at five;
   - `watch()` is refused until the day is finished;
   - after each try it asks `TrickShotJudge.verdict` (already written) whether it was made, and on a miss shows the
     judge's one-sentence advice exactly as trick shots do;
   - on a make it measures the white ball's resting place against the mark, scores it with `DailyScore`, and writes
     `DailyRecord`.
   `TrickShotMode.begin` does not move the game to another table: it calls `ShowpieceModel.enterTrickTable`, which
   racks the pool table, and it never sets a surface. So in this stage every daily shot is on the pool table with
   tournament cloth. Other tables and surfaces wait for stage 4.
   - **The cue angle is the shot's own.** Like trick shots and Behind the 8-Ball, the daily shot sets its cue angle;
     the player cannot raise the cue there (see `raisedCueOpen` in `App/Stroke/StrokeGesture.swift`). On a jump or
     massé day the raised cue is part of the puzzle's setup, not a hint. The strike panel's angle dial shows the
     angle and is locked in this mode.
2. **The mark on the cloth.** Draw it where trick shots draw their target zone (`TrickShotMode.markers`): a small
   ring with a centre dot. After a make, draw a thin line from the white ball to the mark with the distance beside it.
3. **New file** `App/Daily/DailyViews.swift`:
   - the card while playing: the shot's goal in one line, five dots for the tries, nothing else;
   - the result card: made on which try, distance from the mark, score, streak, and three buttons: Watch the answer,
     Share, Board. Board is hidden until stage 3;
   - the already-played card, shown if the player opens it again the same day: the same result, plus the time until
     the next shot.
   On iPad and the open folding phone these live in the notebook half. Nothing covers the table.
4. **The menu row.** In `App/TitleScreen.swift`, add "Shot of the day" as the first row, above Play. Its mark (see
   `MenuRow.Mark`) shows today's state: not played, made on try 2, or missed, and the streak.
5. **New file** `App/Daily/DailyShare.swift`. Draw the result as a picture: the date, the day number, the table with
   the balls at their starting places and the mark (use `App/TrickPathThumb.swift`, without the answer's path), five
   dots for the tries, the score and the streak. Hand it to the share sheet in `App/Clips/ClipShare.swift`. Do not
   write a second share sheet.
6. **Achievements.** Shots made in the daily mode already count for the shot achievements, because
   `AchievementBook.noteShot` hears every strike the player makes. Add three collection achievements in
   `App/Achievements/Achievement.swift`: a streak of seven days, a streak of thirty, a first-try make.
7. **Words.** Every new sentence goes through `String(localized:)` and into a new file in `localization/pending` so
   the translation step picks it up. The upload check refuses a build with an untranslated string.
8. **Tests:** `DailyModeTests` (five tries then stop, answer refused before the end, a make writes the record, a
   second visit the same day shows the result and takes no more tries).

Done when: on a fresh install, Shot of the day is the first menu row, a make shows a score and a streak of one, the
share picture shows no answer, and opening it again shows the result and not a new try.

## Stage 3: Game Center

Goal: the daily board, the streak board, and the achievements reported to Game Center. Sign-in is never shown at
launch.

1. **Project setup.** Add the Game Center capability to the app target (it adds an entitlements entry). There is one
   target, and it builds for iPhone, iPad and Mac; check the entitlement is present in the Mac build too.
2. **Store setup, by script.** New file `scripts/gamecenter-setup.py`, in the style of `scripts/store-upload.py`. It
   turns Game Center on for the app record and creates:
   - a recurring leaderboard, id `breakdown.daily`, that resets every twenty-four hours at midnight Coordinated
     Universal Time, highest score first. Game Center's own rule decides ties; do not promise players a tie-break;
   - an all-time leaderboard, id `breakdown.streak`, highest first;
   - one achievement per entry in `Achievement.swift`, id `breakdown.` plus the game's own id. The comment at the top
     of that file says the ids were made for this and must never change.
   Names and descriptions come from the game's own translated words in all twelve languages. Each achievement needs a
   picture: draw its symbol on the game's dark ground with a small script, the way `store/screenshots/compose.swift`
   draws frames. If the App Store Connect interface refuses any step, write down the exact manual steps in
   `store/README.md` and do them by hand once.
3. **New file** `App/GameCenter/GameCenter.swift`. The only file that imports GameKit. It can: sign the player in when
   asked, post a daily score, post a streak, report an achievement, and open the board. Check Apple's current GameKit
   documentation for the exact call names before writing; they have changed between system versions.
4. **When sign-in happens.** Never at launch. The first time the player presses Board on a result card, the game
   signs in. From then on it signs in quietly at launch and posts scores by itself. If the player declines, the game
   never asks again by itself; the Board button stays and asks only when pressed.
5. **No floating badge.** Game Center can draw its own corner button over the game. Keep it off. Nothing covers the
   table.
6. **Posting.** After a make: post the score to `breakdown.daily` and the streak to `breakdown.streak`. If the device
   is offline, keep the score in `DailyRecord` marked unsent and post it at the next launch, but only while it is
   still the same day.
7. **Achievements.** In `AchievementBook`, wherever an achievement is saved as earned, also hand its id to
   `GameCenter`. On first sign-in, report everything already earned.
8. **Privacy.** `store/pages/privacy.md`, `store/README.md` and `README.md` all say the app has no network code.
   Rewrite those lines: the game itself sends nothing and collects nothing; if the player signs in to Game Center,
   Apple handles their scores under Apple's own terms. Check `App/PrivacyInfo.xcprivacy` still matches.
9. **Tests:** the pure part only. `GameCenterQueueTests`: an unsent score is kept, sent once, and dropped when the day
   has passed.

Done when: a make on a signed-in device appears on the daily board; a fresh install shows no sign-in at launch; the
Mac build does the same.

## Stage 4: a bank worth a daily habit

Goal: at least one hundred shots before the feature is announced, then thirty more each month.

1. **New command** `BreakProbe daily`, beside `BreakProbe tricks`
   (`Packages/BreakdownCore/Sources/BreakProbe/TrickAuthoring.swift` and `TrickSearch.swift` already do the hard part).
   For each family it builds candidate layouts from geometry, finds a strike that works, measures how forgiving the
   shot is in aim, power and tip, and rates it easy, medium or hard by the aim window, using the bands written at the
   top of `TrickAuthoring.swift`.
2. **Every candidate gets a mark.** The mark is where the answer leaves the white ball. For position shots, nudge the
   layout so that resting place is somewhere useful (near the next ball's line).
3. **A person looks at every shot** before it goes in the bank. The tool prints a small picture of each. Throw out
   anything ugly, trivial or too like the day before.
4. **Other tables and surfaces.** Friday shots are on bumper pool, five-pin or bar billiards; Saturday shots are on
   ice, glass, rubber, cork, carpet, sand or the Moon. If stage 2 found that trick shots cannot yet start on another
   table or on another surface, fix that first, here: `enterTrickTable` must rack the shot's own table and set its
   surface, for trick shots and daily shots alike.
5. **Order the bank by the weekly rhythm,** easy on Monday through hard on Sunday. Never two of the same family in a
   row.

Done when: the bank holds a hundred shots, `BreakProbe verify` plays them all, and no two neighbours share a family.

## Stage 5: later, only if the daily shot is being played

- A home-screen widget with today's layout and the streak. It needs its own target and a shared storage group.
- Yesterday's shot, replayable for practice with no score.
- The streak following the player between devices.
- After you finish, a picture of where everyone's white ball stopped. This needs a server, so it is a real decision
  for the Boss, not a default.

## What not to do

- Do not add a second way to judge a shot. `TrickShotJudge` decides made or missed.
- Do not show the answer, its path or its settings anywhere before the day is finished, including in the share
  picture and in VoiceOver's words.
- Do not ask for notifications.
- Do not let the menu, a card or a board cover the table on iPad or the open folding phone.
