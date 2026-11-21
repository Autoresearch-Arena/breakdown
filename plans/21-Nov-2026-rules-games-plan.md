<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for giving Breakdown real games of pool: a tidied free play, eight-ball and nine-ball with turns, fouls,
         ball in hand and an ending, for two people on one device, and later a computer opponent. Written for the
         junior developers who will build it: what exists today, what to reuse, the work packages in order and how
         each is checked.
SRP/DRY check: Pass - checked the spec (section 6), ROADMAP, App/EightBall and the other plans. Nothing else plans a
         rules game. This plan reuses the Behind the 8-Ball judge's foul reading instead of writing it twice.
-->
# Real games of pool: free play, eight-ball, nine-ball

## In plain words

Today "Play" gives you a rack and lets you shoot until you get bored. Nobody takes turns, nothing is a foul, the
game never ends, and a scratched cue ball is put back for you. Someone who downloads a pool game expects to be able
to play a game of pool. This plan adds that, in six packages. It is the biggest single gap between Breakdown and a
finished game.

Read the whole plan and App/EightBall/README.md before you touch a file. Ask before you build if anything is unclear.

DECISION (already made, recorded here): two people on one device first, computer opponent last. No online play.

## What exists today

- Free play lives in App/ShowpieceModel.swift: startGame, rerack, breakNow, shootNow, adoptLayout. The layout between
  shots is a list of sixteen positions; a ball that is gone sits at the off-table parking spot.
- The next layout is built in the package file NextShot.swift. A scratch puts the cue ball on the head spot, always.
- Free play forces a level cue (startGame sets the elevation to zero), so no jump or curve shots outside the puzzles.
- When the last ball drops nothing happens. shootNow simply refuses to do anything useful with an empty table.
- Behind the 8-Ball (App/EightBall) is a puzzle mode. Its judge already reads a recorded shot for: scratch, wrong ball
  first, no ball hit, no rail after contact, ball off the table, and loss of game on the eight. It also has the group
  type (solids, stripes), the pocket names, and a call-your-ball-and-pocket control in EightBallViews.swift.
- The rack code (package file Rack.swift) only knows the fifteen-ball triangle.

## Rules for this work

1. The rules engine is plain value types with no user interface and no RealityKit. It takes the layout before a shot,
   the recorded shot and the call, and returns a ruling. It must be testable from the package test command.
2. Never re-solve a shot to rule on it. Read the recorded timeline, as the judge does.
3. Do not copy the judge's foul reading. Move the shared part to one place and have both the judge and the new rules
   engine call it (package 1).
4. Rules text in the app is in our own words. No league, governing body, brand or person is named anywhere, in the
   app or in these files.
5. Every new word a player reads goes through the string catalog with all eleven translations in the same change.
6. On the open Duo, every new screen is a page of the side panel, never a sheet over the table.
7. Version numbers go up by one patch step per release. Each package ends with a CHANGELOG entry.
8. Builders write code only. The app is compiled once after a package is merged: one iPhone build, one Mac build and
   the package tests. Build output goes under the Team 4TB drive, never the internal drive.

## Package 1: one shared reading of a shot

Goal: one type that answers "what happened in this shot" for any rules.

Steps
1. In the package, add a new file ShotFacts in the BreakdownTimeline module. Given a timeline and the starting
   layout it reports: the first ball the cue ball touched and when; every ball pocketed, in order, with pocket and
   time; whether the cue ball was pocketed or left the table; any object ball that left the table; whether any ball
   reached a rail after the first contact; how many object balls reached a rail (needed for a legal break); where
   every ball came to rest.
2. Move the matching private functions out of EightBallJudge.swift (firstContact, railAfterContact and the scratch
   and off-table checks in outcome) so they call ShotFacts. Behaviour must not change.
3. Add package tests: one hand-built shot per fact, plus one check that the judge's existing escape check still
   prints the same verdicts as before the move (the README in App/EightBall says how to run it).

Done when: package tests pass and the escape check output is unchanged line for line.

## Package 2: free play, finished

Goal: free play is a pleasant practice table with no loose ends.

Steps
1. Ball in hand. After a scratch in free play the cue ball is not placed for the player. The table shows the cue
   ball lifted, the player drags it anywhere legal and drops it. Legal means on the bed and not overlapping a ball,
   a post, a pin or a hole. Add the legality check to NextShot.swift beside respotCueBall and test it there. Add the
   drag to the table touch handling in AimOverlay.swift; show a red tint while the spot is illegal; VoiceOver gets
   move-left, move-right, move-up, move-down actions and a spoken position.
2. Move the cue ball at any time. A "Move cue ball" control in the shot panel (ShotPanel.swift) enters the same
   placement state. Practice players use this constantly.
3. Table cleared. When only the cue ball is left, show a short card with the number of shots taken and two buttons:
   rack again, and back to the menu. Count shots in ShowpieceModel.
4. Open the raised cue in free play. Remove the forced level cue in startGame and playTable and show the same
   elevation control the trick shots use. The trick-shot panel already has it; reuse it, do not rebuild it.
5. Rack choices. Free play offers the fifteen-ball triangle, the nine-ball diamond (built in package 4) and "no
   rack, place balls" (every ball can be dragged with the placement control from step 1).
6. Undo last shot. Keep the layout from before the last shot and offer one step back.

Done when: on iPhone, Mac and the open Duo a player can scratch and place the cue ball, clear the table and see the
card, shoot a jump, and take a shot back. VoiceOver can do all of it.

## Package 3: eight-ball for two

Goal: a full game of eight-ball, passed back and forth on one device.

The rules we play, in our own words
- Break: the breaker must pocket a ball or drive four object balls to a rail, or the other player may accept the
  table or ask for a re-rack. A scratch on the break gives ball in hand behind the head line.
- The eight on the break is not a win or a loss: it is spotted, or re-racked, the breaker's choice.
- The table is open after the break. Groups are settled by the first called ball that is legally pocketed.
- Call ball and pocket on every shot after the break. Obvious shots still need the call; the control pre-selects the
  ball the cue is pointed at and the nearest pocket to its path so one tap confirms it.
- Legal shot: hit one of your own group first (the eight only when your group is gone), and then pocket any ball or
  send any ball to a rail.
- A foul gives the other player ball in hand anywhere.
- You keep shooting while you legally pocket the ball you called.
- You win by legally pocketing the eight in the called pocket after your group is gone. You lose by pocketing the
  eight early, in the wrong pocket, off the table, or on a shot with any foul.

Steps
1. New folder App/Match. File MatchRules: a protocol with three things: the rack to start from, the ruling for one
   shot (given match state, the call and ShotFacts), and whether a ball may be called.
2. File MatchState: whose turn, each player's group, balls left, ball-in-hand kind (none, anywhere, behind the head
   line), shot count, foul history, the result when the game is over. It is Codable.
3. File EightBallRules implementing the list above. The loss-on-the-eight cases must be one explicit table, as the
   judge has it; reuse EightBallGroup, EightBallPocket, EightBallCall and EightBallFoul from EightBallTypes.swift.
4. File MatchMode, an observable class shaped like EightBallMode.swift: it owns a MatchState, asks ShowpieceModel to
   load a layout and play a shot, and after the balls stop asks the rules for a ruling and applies it. Add it to the
   pool-table-only check in ShowpieceModel (the property onPoolTableOnly).
5. Spotting a ball: add a function to NextShot.swift that puts a ball on the foot spot or the nearest free place
   straight behind it. Test it.
6. Views in App/Match/MatchViews: a turn banner (who shoots, their group, balls left for each player as small ball
   icons), the call control (reuse the one in EightBallViews.swift by moving it to a shared file), a ruling card
   after each shot in plain words ("Foul: the cue ball hit a stripe first. Ball in hand for Player 2."), a hand-over
   card between turns, and a result card with rematch. Player names are editable, with defaults.
7. The Physics Lens, the replay controls and Ride keep working on every shot of a match. The ruling card waits until
   the replay is dismissed or finished.
8. Save and resume: write MatchState and the current layout to the app's support folder after every ruling and offer
   "Continue match" on the main menu (TitleScreen.swift).
9. Main menu: "Play" opens a short list: Practice (free play), Eight-ball, Nine-ball.

Tests (package test command; the rules need no app)
- One test per rule in the list above, each with a hand-built ShotFacts.
- A scripted full game: a list of rulings in, the right winner out.
- Every loss-on-the-eight case.

Done when: two people can play a whole game start to finish, with a re-rack offer after a bad break, on iPhone, Mac
and the open Duo, in every language, and the match survives quitting the app.

## Package 4: nine-ball for two

Steps
1. Rack.swift: add the nine-ball diamond (one at the front, nine in the middle, the rest seeded at random), using
   the same gap and jitter numbers. Balls ten to fifteen sit at the off-table spot. Add a break shot helper for it.
   Old racks must produce exactly the same positions as before; add a test that compares against today's output.
2. NineBallRules: the lowest ball on the table must be hit first; any ball legally pocketed keeps your turn; the nine
   legally pocketed at any time wins; the nine pocketed on a foul is spotted; a foul gives ball in hand anywhere;
   three fouls in a row by one player loses (warn them after the second). No push-out in this version.
3. No calls in nine-ball: hide the call control. The turn banner shows the ball that must be hit first, and the aim
   guide marks it.
4. Tests as in package 3.

Done when: a full nine-ball game can be played and saved like eight-ball.

## Package 5: a computer opponent

Start only when packages 1 to 4 are shipped and the Boss has played them.

Steps
1. File MatchOpponent in App/Match. For the balls it may hit, list the candidate shots: each legal ball into each
   pocket, straight, plus one-rail banks. For each candidate, sweep aim and speed in coarse steps and solve with the
   event budget (the cheap solve the judge uses). Score a candidate by whether the ball drops, the size of the window
   of aims that still make it, and whether the cue ball finishes with a clear path to another legal ball. This is
   the same window idea the judge uses; read its windows functions first and share what can be shared.
2. If nothing scores above a threshold, play a safety: the candidate that leaves the other player the smallest
   window.
3. Skill levels are physical, not fake: add seeded noise to aim, speed and tip position before the strike. Three
   levels. The seed comes from the match, so a saved match replays the same.
4. Run the search on a background task and show "Thinking..." (see how EightBallMode does its Scoring phase). It
   must never freeze the table.
5. Show its thinking: after the opponent's shot the ruling card offers "Why that shot", which lists in plain words
   what it aimed for and how wide the window was.

Done when: the opponent finishes a game on each level without a freeze, never fouls on purpose except as a safety,
and the easy level loses to a careful beginner.

## Package 6: finishing touches

- A rules page for each game inside How to play.
- Haptics and a sound for a foul, a turn change and a win (FeelMapping.swift, SoundBoard.swift, Haptics.swift).
- A small record of games played and won per game type, stored on the device, shown on the menu.
- Store screenshots and listing text for the new games (store/screenshots/README.md says how).

## What is not in this plan

Online play, leaderboards, tournaments, straight pool, one-pocket, snooker. Write them up if asked; do not start them.
