<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for turning the three extra tables (bumper pool, five-pin billiards, bar billiards) from tables you can
         only knock balls around on into games with turns, scores and an ending. Written for junior developers.
SRP/DRY check: Pass - checked App/Tables (the three table files and README), TableKind.swift and the rules-games plan.
         This plan reuses that plan's match engine; it adds only each table's own rules.
Edited: 21-November-2026 by Claude Opus 5.5 High - added the three rule sheets (one simple, widely played version of
         each game) that BreakdownRules/Tables builds exactly.
-->
# The other tables become games

## In plain words

Bumper pool, five-pin and bar billiards look right and the balls behave on them, but nothing keeps score. The bar
billiards file even lists the points for each hole with a note that nothing reads them yet. Until each has its
rules, they are scenery. This plan finishes all three. They stay in the menu as they are while the work is done.

Depends on: the rules-games plan, packages 1 to 3 (shot facts, ball in hand, the match engine and its screens).

## What exists today

- Each table file in App/Tables fills in size, posts, pins, holes, a start layout and a default shot.
- The solver records post hits, pin falls (which pin, when, which ball) and bed-hole drops (pocket numbers six and
  up). The timeline can say which pins are down at any time.
- A pin knocked down has no sound or haptic. Nothing models a pin falling onto a ball or a ball leaving a hole.
- A scratched cue ball goes back to a fixed spot that may not suit these tables.
- The aim guide line runs past the end of the small tables.

## Rules for this work

The same eight rules as the rules-games plan. In addition: write each game's rule sheet in plain words first, as a
short section added to this plan, and get the Boss's yes before building. The rules of these games vary from place
to place; we pick one simple, widely played version each and say so in the app. No clubs, leagues or brands named.

## Package 1: what the engine needs

1. ShotFacts (from the rules-games plan) gains: pins knocked down with the ball that did it and the order; posts
   touched; bed-hole drops with the hole number.
2. MatchRules gains what these games need that pool does not: more than one cue ball (each player has their own in
   five-pin and bumper pool), balls that return to play after dropping (bar billiards), pins that are stood back up
   between shots, a running score per player, and a turn clock (bar billiards). Add these as optional parts of the
   protocol so eight-ball and nine-ball are untouched.
3. NextShot.swift assumes ball zero is the cue ball. Add the idea of "the ball this player strikes" to the shot
   builder and to the solver's strike (the strike is applied to ball zero in Simulation.swift; it needs a ball index
   on the strike, defaulting to zero so nothing old changes). Test that default behaviour is bit-for-bit the same.
4. Fix the aim guide length on small tables (AimOverlay.swift): stop it at the first thing it meets.
5. Sound and haptic for a pin falling and a ball dropping in a bed hole or cup (FeelMapping.swift).

## Package 2: bumper pool

Outline to confirm in the rule sheet: two players, five balls each, each player's cup at the far end. Both shoot
their marked ball first. Sink all five of your own in your cup to win. A ball in the wrong cup, or off the table,
is a foul with a stated penalty. Turns alternate; a sunk ball earns another shot.

Build: BumperPoolRules, the start layout check against the table file, the turn banner showing each side's balls
left, the result card. Tests: one per rule and a scripted game.

## Package 3: five-pin

Outline to confirm: two players, each with their own cue ball, one red object ball, five pins in the middle. You
must hit the other player's cue ball first. Points for pins knocked down by a ball other than your own cue ball,
more for the centre pin, more again if it falls alone; points for sending the other cue ball into the red. Knocking
pins with your own cue ball, or missing the other cue ball, gives the points to the other player. First to a set
total wins. Pins are stood up again after every shot.

Build: FivePinRules, pin reset between shots (the layout must carry "all pins standing" into the next solve), a
score line per player, a points-explained card after each shot. Tests as above.

## Package 4: bar billiards

Outline to confirm: one or two players, a timed game. Balls are played from the near end; each hole scores its own
value; a break continues while balls drop. A white peg down loses the points of that break; the black peg down
loses the whole score. When time runs out a bar stops balls returning and play ends when the last ball is gone.

Build: BarBilliardsRules using the hole values already in the table file, balls returning to hand after a drop,
the peg penalties, the clock (a real-time clock that pauses during replays and the Lens), single-player high score
stored on the device. Tests as above, with the clock injected so tests do not wait.

## Package 5: menu and store

Each table's entry in the Tables list shows its game and a "How to play" page. Update the store screenshot scene
for the tables (store/screenshots/README.md) to show a score on screen.

## Done when

Each of the three can be played from first shot to a result card, with its rules page, in every language, on
iPhone, Mac and the open Duo, and each game's rules have package tests.

## The rule sheets (what the code builds)

Written 21-Nov-2026 by Claude Opus 5.5 High. One simple, widely played version of each game. Each sheet is what
`Packages/BreakdownCore/Sources/BreakdownRules/Tables/` builds, rule for rule; the app shows the same rules on each
table's "How to play" page and says it is one common version.

### Bumper pool

1. Two players. Each has five balls: the first player the five that start round the near cup, the second player the
   five round the far cup. One ball of each five is marked.
2. You play your balls toward the cup at the far end from where they started.
3. You always strike one of your own balls: your marked ball while it is on the table, then your other balls one at a
   time, lowest number first. (Real tables let you choose; one fixed order keeps the controls simple.)
4. Sink one of your own balls in your cup and you shoot again. Otherwise the turn passes.
5. An opponent's ball knocked into their own cup stays down and counts for them.
6. Foul: any ball in the wrong cup, or any ball knocked off the table. That ball comes back to its starting spot (or
   the nearest free place) and the turn passes, even if you also sank one of your own.
7. The first side with all five balls in its cup wins, whoever sank the last one.

### Five-pin billiards

1. Two players. The first plays the white ball, the second the yellow. The red ball and the five pins are shared:
   four white pins and a red pin in the middle.
2. Turns alternate after every shot. Every ball is played where it lies.
3. Strike your own ball so that it hits the other player's ball first. Points come from what the other player's ball
   and the red do after that:
   - each white pin knocked down: 2 points;
   - the red pin: 4 points, or 10 if it is the only pin to fall;
   - the other player's ball hitting the red ball: 3 points.
4. Foul: your ball misses the other player's ball, hits the red first, knocks down a pin itself, or any ball leaves
   the table. Every point the shot made goes to the other player, and never less than 2 (one white pin).
5. Pins are stood up again after every shot. A ball resting where a pin stands, or knocked off the table, goes back
   to its spot (or the nearest free place).
6. First to 60 points wins.

### Bar billiards

1. One or two players, against a clock (fifteen minutes). Two players take breaks in turn and the higher score at the
   end wins; one player plays for a high score.
2. Every shot is played with a white ball from the tray, placed on the spot in the D. The red starts on its spot.
3. Your ball must hit another ball first. Each ball that then drops scores its hole: 200, 100, two 50s, and 30, 20,
   10, 20, 30 along the far row. The red scores double.
4. Your break goes on while every shot drops at least one ball. A shot that drops nothing ends it. A shot that hits
   no ball scores nothing, ends the break, and the ball goes back to the tray.
5. Knock down a white peg and the break ends and its points are lost. Knock down the black peg and the break ends
   and your whole score is lost.
6. Balls that drop come back to the tray; the red goes back on its spot. If every white is on the table, they all
   come back to the tray.
7. When time is up a bar drops: balls that drop stay down. Play goes on until no white is left to play; then the
   game ends.
