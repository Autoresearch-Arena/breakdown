# Behind the 8-Ball: challenge and scoring design

Author: Claude Opus 5.5 High, 21-November-2026
Status: design draft for the owner. It covers the rules the mode enforces, how it scores, the first twelve situations, and how it fits the app. It uses only pool physics, the standard rules and widely known generic shot names.

---

## 0. The idea in one paragraph

You walk up to an eight-ball game already in progress. Your opponent has left you hooked: the cue ball is tucked behind the 8 or behind their balls, and you cannot see your ball's natural pocket. You call one ball and one pocket, then get out with a kick, bank, jump, massé, or a bridge shot. You score for making the shot as you called it, for how hard it was, and for how good it looked. The name fits the table picture whichever origin story is true. In eight-ball, hitting the 8 first is a foul and pocketing it early loses. In the older game of Kelly pool, the spot behind the 8 was a dangerous place to be.

---

## 1. Rules the challenge enforces

### 1.1 Which ruleset, and why

The base is **the standard world rules for eight-ball**, with one tightening: **every shot is called**, whatever kind of shot it is.

- The world rules count touch fouls on every ball, not just the cue ball. That is the strictest choice and the easiest to judge, because the simulation records every contact.
- The world rules let a player skip calling an "obvious" shot. Many league rules say banks, kicks, combinations and non-incidental kisses are never obvious, and some extend that list to jump and massé shots. In this challenge almost every shot is a kick, bank, jump or massé, so always calling ball and pocket removes the "obvious" judgement altogether.
- "Slop counts" league rules (no calls except on the 8) and bar rules are rejected. They would make flukes count, which defeats a called-shot challenge.

### 1.2 The call

- Before the shot the player taps **one ball and one pocket**. Rails, kisses and the route are never part of the legal call, the same as the real rule.
- The player may call **Safety** instead. Scoring for a safety is in section 2.6.
- There is only one call per shot and no hedging. A second called ball is not possible in the interface.
- The groups are already assigned in every challenge, so the open-table rules never come into play.

### 1.3 Fouls (score zero for the attempt)

Each one is checked from the recorded simulation:

1. **Scratch.** The cue ball is pocketed or leaves the table.
2. **Wrong ball first.** The first object ball the cue ball touches must be from your group, or the 8 once your group is cleared. If the legal ball and an illegal ball are touched within one solver step of each other, the legal ball counts as first, as the rules say to do when the order cannot be told.
3. **No rail after contact.** After the first contact, either a ball is pocketed or some ball reaches a rail. A ball already resting on a rail only counts if it leaves the rail and comes back. A ball that is pocketed or leaves the table counts as reaching a rail.
4. **Object ball off the table.** A ball that touches the top of the rail and drops back onto the cloth has not left the table.
5. **Cue or bridge touches any object ball.** The rules name the bridge explicitly. Some league rules make it a foul if the obstacle ball moves at all on a jump or massé; the all-balls touch rule already covers that.
6. **Double hit or push.** There must be exactly one tip contact. The tip must leave the cue ball before the cue ball reaches the first object ball, unless the two balls are frozen together. This matters for close-range jumps and massés.
7. **Illegal jump.** A jump is legal only when the cue drives the ball down into the cloth: the cue angle is above a set minimum and the tip strikes above the ball's cloth contact point. A scoop, where the tip hits cloth and ball together, is a foul here. The real rules forgive an *accidental* miscue that hops the ball, but a simulation cannot tell accident from intent, so every scoop is treated as a foul.

Rules that do not apply to a simulation are left out: foot on the floor, shooting while balls are moving, cue-ball placement, and the three-foul rule (eight-ball does not use it).

### 1.4 Loss of game on the 8 (the challenge is failed and scores zero)

- pocketing the 8 on a foul, scratch included
- pocketing the 8 before your group is cleared
- pocketing the 8 in any pocket other than the one called
- driving the 8 off the table

Missing the 8, or fouling without pocketing it, is not a loss of game under the standard rules. In the challenge it is just a failed attempt.

### 1.5 Equipment

- **Mechanical bridge.** Legal. Up to two may be used, and a second one rests on the head of the first. The bridge touching any ball is a foul. Using a bridge for a jump or massé is allowed, and stacking two bridges for a jump is a known tournament move.
- **Jump cue.** Legal under the world rules, and players may switch cues freely. Some leagues set a minimum cue length of 40 inches. Short jump cues make close-range jumps possible. The first version leaves the jump cue out (section 5).

---

## 2. Scoring

### 2.1 The on-screen sentence

> **Make it as called for 5, plus up to 5 for difficulty and up to 5 for style. A legal miss earns 1. A foul earns nothing. Each retry costs 1.**

A perfect shot scores 15. The 5 + 5 + 5 split matches the owner's three parts and is easy to explain. The retry rule follows the way artistic pool runs trick-shot events: three tries per shot, with full points on the first, one less on the second, and two less on the third. Artistic pool rates each shot's degree of difficulty in advance and makes that rating its point value, with no judged style mark. Our style score is therefore new, and is built from what players admire in a shot (section 2.4).

### 2.2 Part one: made as called (0 or 5)

All of these must be true:
- No foul, and no loss of game.
- The called ball ends in the called pocket.

Other balls of your group that drop also stay down, as in the real rules, but they add no points (section 2.5).

### 2.3 Part two: difficulty (1 to 5, only when made as called)

**The main measure is the success window.** Because the solver is deterministic, it can replay the player's shot with one input changed at a time. This is the shot's margin for error measured directly, not estimated from a formula.

How to measure:
1. Take the player's actual stroke.
2. For each input that applies, sweep it while holding the others fixed. The inputs are aim direction, speed, side spin, and cue elevation (elevation only for a jump or massé).
3. Each window is the width of the unbroken range of values around the player's value that still gives "made as called, no foul".
4. Compare each window with the same window for a **reference shot**: a slow, straight-in shot to a corner with the object ball halfway between the cue ball and the pocket. The geometry of aiming makes difficulty proportional to cue-ball-to-object-ball distance times object-ball-to-pocket distance, so the halfway position is the hardest straight shot.
5. **Tightness** is how many times the reference window has to be halved to shrink to the player's window, added up over the inputs.

Tightness to points (set the bands by solving the authored routes and tuning):

| Tightness | Difficulty points |
|---|---|
| looser than the reference | 1 |
| up to 2 halvings | 2 |
| up to 4 | 3 |
| up to 6 | 4 |
| more than 6 | 5 |

The window already accounts for everything that makes a shot hard: cut angle, distance, number of rails, pocket entry angle and speed, jump clearance, and curve. Those factors are recorded separately and **shown in the Physics Lens to explain the rating**, but they do not add points on their own. That way nothing is counted twice.

What the Lens lists:
- rails before the called ball is hit, and rails the called ball takes
- the cut angle on the called ball
- the cue-ball travel distance, and the object-ball travel distance to the pocket
- the narrowest gap passed through
- for a jump: airborne height, the blocker cleared, and the cue elevation
- for a massé: total curve
- the speed window, which shows how much speed control mattered

**Caps so luck cannot farm difficulty:**
- Each challenge has an authored rating, set in advance as artistic pool does, for each intended escape. That rating is shown before the shot. The measured rating can move at most one point away from the authored rating of the route the player actually took.
- A route nobody authored (the player found their own way) uses the measured rating, capped at the challenge's highest authored rating.
- **Edge-of-window rule:** if the player's stroke sits in the outer quarter of any of its windows, so it very nearly failed, difficulty drops by one and style scores zero. A narrow window hit near its centre is skill. A narrow window hit at its edge is mostly luck.

Cost: each window is a short bisection search on a deterministic solver. A dozen or so extra solves per input after the shot is probably fine, but this should be timed on the device before shipping.

### 2.4 Part three: style (0 to 5, only when made as called)

There is one point for each item below, capped at 5. All of them can be measured, and each one is something players admire in a real shot:

1. **Hard technique.** The escape used a jump, a massé, or a kick off two or more rails. These are rarer and more spectacular than a one-rail kick or a plain cut.
2. **Stacked techniques.** Two different techniques in one shot, such as kick then bank, jump then carom, or kick then curve.
3. **Threaded.** The cue ball or the called ball passed within a quarter of a ball's width of a blocker without touching it, like a long bank that just slips past the 8.
4. **Shape.** The cue ball finishes with a makeable next shot on your next ball, or on the 8. Makeable means that shot's own success window is at least as wide as the reference shot. Most of the passing strokes inside the player's window must also leave shape, which shows the shape came from the stroke and not from a lucky bounce. Shape afterwards is what turns a great escape into a legendary one, and players frown on lucky shape.
5. **For the game.** The shot pocketed the 8, or your last group ball, to win the game or reach the 8. Stakes are part of why great shots are remembered.

**Style is zeroed when:**
- there was any foul
- the stroke was in the outer quarter of its window (section 2.3)
- the called ball dropped after an unplanned kiss (section 2.5)

**Not a style point:** using the mechanical bridge. The bridge is a tool for reach and is only shown when the shot needs it. Showmanship props count only when they are needed.

### 2.5 Flukes

| What happened | How it scores |
|---|---|
| Called ball went into a **different pocket** | Not made. If the shot was otherwise legal, it scores 1 for escaping. Your turn ends. |
| **Uncalled ball** of your own group dropped | It stays down and adds nothing. |
| **Opponent's ball** dropped | It stays down and counts for them. It adds nothing. |
| Called ball dropped in the called pocket **after a kiss or carom no authored route uses** | Kisses do not have to be called, so it counts as made and scores 5. Difficulty is set to 1 and style to 0. It counts, but it is not admired. |
| **8 in the wrong pocket**, the 8 dropped on a foul, or the 8 left the table | Game lost. Zero, and the challenge is failed. |

### 2.6 Safety

A declared safety cannot score the 5 for a make. It scores **3** if all of these are true: the hit was legal, there was no foul, and the opponent is left with no straight line from the cue ball to any of their legal balls. The solver can check that as the share of directions from the cue ball that reach a legal ball. Otherwise it scores the escape credit of 1. Good players choose a kick or jump safety when they cannot make a ball, so the game rewards the right decision without letting a safety outscore a real make.

### 2.7 Worked examples (for the help screen)

- A one-rail kick, made as called, rated 3, with shape on the 8: 5 + 3 + 1 = **9**.
- A massé around the blocker to win on the 8, rated 5, threading the blocker: 5 + 5 + 3 (hard technique, threaded, for the game) = **13**.
- The same massé made only on the second try: **12**.
- The called ball misses but the hit is legal: **1**.
- The 8 drops in the wrong pocket: **0**, and the challenge is failed.

---

## 3. The first twelve situations

### How the table is described

Positions are in **diamonds**:
- **Across** runs from 0 at the left long rail to 4 at the right long rail.
- **Along** runs from 0 at the head rail to 8 at the foot rail.
- The player stands at the head end looking toward the foot.
- The pockets are head-left (0,0), head-right (4,0), left side (0,4), right side (4,4), foot-left (0,8) and foot-right (4,8).
- A ball is about a fifth of a diamond wide.

The positions below are starting points. **Each layout must be checked in the solver when it is authored**:
- the natural line really is blocked
- every listed escape passes
- the windows give the authored ratings

Nudge balls until all three are true. Every layout has both groups on the table, as in a real game in progress. "Your group" means the player's group.

---

### 1. Tucked Behind the 8 (the title shot)
- **Story:** You're on solids with two left. Your opponent rolled the cue ball dead behind the 8.
- **Your balls:** 3 at (1.0, 5.0) and 6 at (3.6, 7.5).
- **Opponent:** stripes 9 (3.5, 6.8), 11 (0.5, 2.0), 12 (3.2, 1.4), 14 (1.6, 7.2), 15 (3.0, 5.4).
- **8:** (2.0, 3.0). **Cue ball:** (2.2, 2.6).
- **Already pocketed:** 1, 2, 4, 5, 7, 10, 13.
- **Hook:** the 8 sits on the straight line to the 3. The 3's natural pocket is foot-left, almost straight in.
- **Escapes:**
  - A: one-rail kick off the right long rail, cutting the 3 into the foot-left corner. Rated 3.
  - B: jump the 8, with the 8 only about half a diamond away, so it needs a steep jump. Rated 4.
  - C: declare a safety and kick to hit.
- **Lesson:** the usual decision order is kick first, then curve, then jump. Hitting the 8 first is a foul. That is the name of the challenge.
- **Taught by:** Two-Rail Kick (the kick idea) and Jump the Blocker.

### 2. Frozen on the Rail
- **Story:** You're on stripes. Your 10 is frozen to the rail and two solids hide it.
- **Your balls:** 10 frozen to the right long rail at (3.9, 7.0), and 12 at (0.5, 7.4).
- **Opponent:** solids 1 (0.8, 2.5), 3 (2.95, 5.65), 5 (3.4, 6.3), 6 (1.5, 6.8).
- **8:** (2.0, 3.6). **Cue ball:** (2.4, 4.6).
- **Already pocketed:** 2, 4, 7, 9, 11, 13, 14, 15.
- **Hook:** the 3 clips the direct line to the 10. The 10's natural pocket is foot-right, straight down the rail.
- **Escapes:**
  - A: one-rail kick into the right rail just before the 10, so it rolls along the rail into the foot-right corner. This needs slow speed. Rated 3.
  - B: two-rail kick off the foot rail. Rated 4.
- **Lesson:** to kick a ball close to the rail, aim using the rail groove, not the diamonds. Too much speed and the ball will not hold the rail. Keep the tip on the vertical centreline, because even a little sidespin changes the rebound.
- **Taught by:** Two-Rail Kick and Stop Dead (speed control).

### 3. Jump a Diamond Out
- **Story:** You're on solids. An opponent ball sits a diamond in front of you.
- **Your balls:** 5 at (3.5, 3.7), near the right side pocket, and 2 at (0.6, 6.9).
- **Opponent:** stripes 9 (1.2, 6.0), 11 (2.5, 2.15), 13 (3.3, 7.4), 14 (0.4, 4.8).
- **8:** (2.4, 6.4). **Cue ball:** (2.0, 1.4), in the kitchen area.
- **Already pocketed:** 1, 3, 4, 6, 7, 10, 12, 15.
- **Hook:** the 11 blocks a cut of the 5 into the right side pocket. The cut is a moderate one.
- **Escapes:**
  - A: one-rail kick off the left long rail into the 5. Rated 3.
  - B: jump the 11 at a shallow angle and cut the 5 into the side. Rated 3, and it also earns the hard-technique style point.
- **Lesson:** jump when the blocker is far enough away to clear. More speed gives a longer jump and more elevation gives a shorter, higher one. A jump is risky near a rail because the cue ball can fly off the table.
- **Taught by:** Jump the Blocker.

### 4. Bend Around
- **Story:** You're on stripes. A solid half-covers the straight line to your 15, and kicking off the long rail is too steep.
- **Your balls:** 15 at (2.0, 4.6), and 11 at (3.5, 1.2).
- **Opponent:** solids 2 (0.4, 5.2), 4 (3.2, 6.9), 6 (1.45, 3.0), 7 (0.9, 7.6).
- **8:** (2.9, 2.4). **Cue ball:** (1.0, 2.0).
- **Already pocketed:** 1, 3, 5, 9, 10, 12, 13, 14.
- **Hook:** the 6 covers half the cue ball's path. The 15's natural pocket is foot-right, almost straight.
- **Escapes:**
  - A: semi-massé (swerve) past the left edge of the 6. Rated 3.
  - B: jump. Rated 3.
  - C: two-rail kick. Rated 4.
- **Lesson:** a semi-massé is a gentle bend at moderate elevation. It is the easiest curve and the usual fallback when the kick lanes are bad.
- **Taught by:** The Massé.

### 5. Kick for the Game
- **Story:** You've cleared your stripes. The 8 sits a ball off the left rail near the corner, and a solid blocks it.
- **Opponent:** solids 1 (1.0, 4.6), 4 (2.8, 6.4), 6 (3.5, 2.0), 7 (2.2, 7.6).
- **8:** (0.2, 6.8). **Cue ball:** (1.6, 3.0).
- **Already pocketed:** 2, 3, 5, and all stripes.
- **Hook:** the 1 sits on the line to the 8. The natural pocket is foot-left, down the rail.
- **Escapes:**
  - A: one-rail kick off the right long rail, cutting the 8 thin down the rail. Rated 3.
  - B: three-rail kick that comes down the left rail straight onto the 8, using a standard three-rail diamond system. Rated 5.
- **Jeopardy:** the 8 in any other pocket, or a scratch, loses the game. This is real behind-the-8-ball jeopardy, on purpose.
- **Lesson:** a kick to hit is far easier than a kick to pocket. A carom's margin for error is roughly ten times wider than a cut's.
- **Taught by:** Two-Rail Kick.

### 6. The Z Shot
- **Story:** Hill-hill, you're on stripes and hooked mid-table. Your 13 sits near the foot rail.
- **Your balls:** 13 at (1.5, 7.85), a ball off the foot rail, and 15 at (3.0, 1.2).
- **Opponent:** solids 2 (0.6, 6.4), 4 (2.27, 4.6), 6 (1.9, 5.8), 7 (3.5, 2.2).
- **8:** (1.2, 3.0). **Cue ball:** (2.6, 3.2).
- **Already pocketed:** 1, 3, 5, 9, 10, 11, 12, 14.
- **Hook:** the 4 and the 6 sit on the line to the 13. The 2 shuts the one-rail kick off the left rail. The 13's natural pocket is foot-left, along the foot rail.
- **Escapes:**
  - A: two-rail kick off the right long rail and the foot rail, a Z-shaped path that runs along the foot rail into the 13 and on into the foot-left corner, with a little running English. Rated 4.
  - B: three-rail kick. Rated 5.
  - The cue ball is past arm's reach from the head end, so **the bridge appears**.
- **Lesson:** mild running English on a two-rail kick holds the cue ball on the foot rail. A shot like this makes perhaps one time in ten, and getting shape on the next ball afterwards is what makes it great. The shape point is the point of this lesson.
- **Taught by:** Two-Rail Kick and The Long Bridge Draw.

### 7. Point-Blank
- **Story:** You're on your last stripe. The 8 is almost touching the cue ball.
- **Your ball:** 14 at (2.6, 6.9).
- **Opponent:** solids 1 (3.4, 3.1), 3 (0.6, 2.2), 6 (2.2, 4.9), 7 (3.7, 5.8).
- **8:** (1.3, 6.17), roughly two inches from the cue ball. **Cue ball:** (1.0, 6.0).
- **Already pocketed:** 2, 4, 5, and every stripe except the 14.
- **Hook:** the 8 sits on the line. The 14 is nearly straight into the foot-right corner.
- **Escapes:**
  - A: one-rail kick off the left rail. Rated 3. This is the percentage choice.
  - B: highly elevated close-range jump over the 8. Rated 5.
- **Rules in play:** the tip must leave the cue ball before it reaches anything, there is no scoop, and the cue must not touch the 8.
- **Lesson:** the closer the blocker, the steeper the jump has to be, and close jumps sit on the edge of the double-hit rule.
- **Taught by:** Jump the Blocker.

### 8. Massé for the Win
- **Story:** You're on the 8. It sits in the jaws of the foot-right corner, and an opponent ball sits dead between, about a foot from the cue ball.
- **Opponent:** stripes 9 (0.8, 2.6), 10 (1.6, 5.2), 12 (3.4, 7.2), 13 (0.5, 7.0).
- **8:** (3.85, 7.85). **Cue ball:** (2.9, 6.5).
- **Already pocketed:** 11, 14, 15, and all solids.
- **Hook:** the 12 is directly on the line to the 8.
- **Escapes:**
  - A: one-rail kick off the right long rail into the 8 in the jaws. Rated 3. This is the percentage play.
  - B: full massé around the 12. Rated 5.
- **Lesson:** the full massé is a last resort and the most spectacular escape. The kick is the honest answer. The massé scores more because it is harder, not because it is wiser. The Lens says so.
- **Taught by:** The Massé.

### 9. Jump Off the Bridge
- **Story:** You're on solids with two left. The cue ball is far out on the table, and a stripe sits half a diamond in front of it.
- **Your balls:** 4 at (0.9, 7.3) and 7 at (3.2, 3.0).
- **Opponent:** stripes 9 (1.75, 5.6), 11 (3.6, 1.0), 12 (2.3, 7.4), 15 (0.4, 3.0).
- **8:** (3.0, 5.2). **Cue ball:** (2.0, 5.0).
- **Already pocketed:** 1, 2, 3, 5, 6, 10, 13, 14.
- **Hook:** the 9 blocks a moderate cut of the 4 into the foot-left corner.
- **Escapes:**
  - A: one-rail kick off the left rail. Rated 3.
  - B: jump the 9 off the bridge and pocket the 4. Rated 4.
  - B can earn more: carom the cue ball off the 12 for shape on the 7, which adds the stacked-technique and shape points.
  - Reach and elevation together force **the bridge**.
- **Lesson:** a raised bridge gives the steep cue angle a jump needs when the cue ball is out of reach. Jump, pocket the ball, and carom for shape in one stroke, and it is a shot you rarely see.
- **Taught by:** Jump the Blocker, The Long Bridge Draw, and Combination Chain (the carom).

### 10. Kick-Bank Cross-Side
- **Story:** You're on stripes. Your 13 sits a ball off the right rail, level with the side pockets.
- **Your balls:** 13 at (3.7, 4.0) and 10 at (0.7, 1.5).
- **Opponent:** solids 2 (2.68, 5.75), 3 (1.4, 7.0), 5 (3.5, 6.9), 6 (0.9, 3.0).
- **8:** (2.2, 2.0). **Cue ball:** (2.2, 6.6).
- **Already pocketed:** 1, 4, 7, 9, 11, 12, 14, 15.
- **Hook:** the 2 blocks the direct line.
- **Escapes:**
  - A: one-rail kick off the left rail, driving the 13 straight into the right side pocket. Rated 3.
  - B: one-rail kick, then bank the 13 off the right rail back across into the left side pocket. Rated 5.
- **Lesson:** a bank is never "obvious" and must be called. Throw from the cut shortens or lengthens a bank. A kick then a bank stacks two sources of error.
- **Taught by:** Two-Rail Kick and Cross-Side Bank.

### 11. Full-Table Swerve
- **Story:** You're on stripes. Your 9 sits by the head-left corner. A cluster of solids fills the middle of the table and the left rail is crowded.
- **Your balls:** 9 at (0.4, 0.5) and 14 at (3.4, 6.0).
- **Opponent:** solids 1 (1.6, 3.8), 3 (2.1, 4.3), 4 (1.8, 4.6), 5 (0.3, 3.2), 7 (0.5, 5.5).
- **8:** (2.6, 2.2). **Cue ball:** (2.6, 7.0).
- **Already pocketed:** 2, 6, 10, 11, 12, 13, 15.
- **Hook:** there is no sight line to the 9.
- **Escapes:**
  - A: three-rail kick around the cluster. Rated 4.
  - B: full-table swerve that arcs around the cluster and passes near the 8 without touching it, called head-left. Rated 5.
- **Lesson:** a swerve that runs the length of the table can pocket a ball you cannot see. The longer the path, the more the curve depends on cloth and speed, so it rewards a feel for both.
- **Taught by:** The Massé and Two-Rail Kick.

### 12. No Way to Make It
- **Story:** You're on solids. The 1 is frozen on the foot rail behind stripes, and the 6 is tied up with the 10 and 11. The cue ball is behind the 8 near the head rail.
- **Your balls:** 1 at (2.0, 7.9) and 6 at (1.1, 5.9).
- **Opponent:** stripes 9 (1.8, 7.5), 10 (1.25, 5.75), 11 (0.95, 6.1), 13 (2.4, 7.55), 14 (3.4, 4.2).
- **8:** (2.5, 1.0). **Cue ball:** (2.4, 0.6).
- **Already pocketed:** 2, 3, 4, 5, 7, 12, 15.
- **Hook:** authoring must confirm that every route to pocket a ball has a window far below the reference shot.
- **Escapes:**
  - A: call Safety and kick softly to the 1, leaving the cue ball behind the stripes. This scores 3 if the opponent ends up hooked.
  - B: three-rail kick to pocket the 1, the hero shot. Rated 5.
- **Lesson:** when you cannot make a ball, pick the safety that leaves you the favourite. A kick safety with easy contact often hands the opponent a foul and the game back to you.
- **Taught by:** Two-Rail Kick and Stop Dead.

The order above rises gently in difficulty. The named generic shots and the game-winners sit later, where the stakes feel earned.

---

## 4. How it fits the app

- **Trick shots stay the lessons.** Each of the ten trick shots already shows the answer, explains it in the Lens with one idea on the card, and then lets you try it. That flow is untouched.
  - Two-Rail Kick, Cross-Side Bank, The Massé, Jump the Blocker and The Long Bridge Draw teach the escapes.
  - Stop Dead, Follow-Through Train and Combination Chain teach the shape and carom points.
  - Each challenge card lists the trick shots that teach it ("Taught by" above).
- **Behind the 8-Ball is the exam.** The flow differs from a trick shot in one way: the answer is **not** shown first.
  1. Look at the table and read the one-line story.
  2. Make the call: tap a ball, then a pocket, or tap Safety.
  3. Aim and shoot, with the same cue, spin and elevation controls.
  4. See the scorecard: 5 plus difficulty plus style, with each style point named.
  5. The Physics Lens replays your shot and explains the difficulty with the measured factors (rails, cut, gap, jump height, curve, speed window). It then replays the escape you did not take and labels it with its rating, so a player who kicked sees the massé, and the other way round.
- **The judge.** The trick shot judge already detects a scratch, the wrong first ball, the wrong pocket and a ball that stayed up. Behind the 8-Ball adds the called-shot rules in section 1, the loss-of-game checks on the 8, the window sweep, and the style checks. All of them read the same recorded timeline.
- **The bridge.** As in the trick shots, the 3D bridge and its small label appear only when the authored escape needs reach. The challenge card gets one short line, for example "Too far to reach: the bridge is legal, and touching a ball with it is a foul". The bridge scores no style by itself.
- **Fairness.** Every escape's rating comes from the same solver the player shoots with, so a rating shown in advance is a promise the physics keeps.

### 4.1 Take it to a real table

The point of the mode is that a player walks away able to make these shots on a real table. So every challenge ends with a short "On a real table" card for the escape just played, written for someone standing at a table, and keeping the real numbers next to the plain words (the numbers are part of the appeal):

- **Where to aim, in table terms.** Kicks and banks name the diamonds (aim at the second diamond on the long rail; the mirror-image system), jumps and massés name the ball's edge or the gap to clear. The solver's aim in degrees stays beside it.
- **How the cue is held.** Level, raised for a jump (with the angle), steep for a massé, or on the bridge (head flat about a hand's width back, cue in the notch, fingers light on the butt, short level stroke). The 3D cue on screen already shows this pose.
- **How hard.** The measured speed in m/s, plus a felt comparison ("about a firm lag", "a break-speed hit").
- **What goes wrong.** The commonest miss for this escape (scooping a jump into a foul, over-hitting a kick so it runs long, a massé that curves late on slick cloth).

**Cloth matters, and the mode says so.** Some situations are set on Tournament cloth or Dive-bar felt (both in the Surface menu since 0.5.12, with measured ranges: sliding friction 0.15 against 0.3, rolling resistance 0.005 against 0.015, cushion restitution 0.9 against 0.65). The same escape is then a different shot: on slick tournament cloth draw and massé curves take late and balls run long; on worn bar felt draw dies early, kicks come off dead rails short, and you hit harder. The card shows both numbers so the player understands why their local bar table plays differently.

---

## 5. Decisions taken (the owner can overturn any)

1. **Point scale:** 5 + 5 + 5, because it explains in one sentence.
2. **Retries:** three tries, one point off each, as in artistic pool. Practice stays unlimited and unscored.
3. **Safety:** 3 points for a legal safety that leaves the opponent with no direct shot, so playing safe is a real choice.
4. **Jump cue:** not in the first version. The full cue's steepest legal jump limits close-range jumps, which is true to a bar player's kit.
5. **Stacked bridges:** not in the first version. The Jump Off the Bridge situation uses one bridge.
6. **Hints:** the authored escape can be watched before shooting, and watching it caps that challenge's style at 2.
7. **Extra loss rules:** the standard world rules only. No league extras.
8. **Play on:** not in the first version. Each challenge is one shot. A run-out mode can come later.
9. **Totals:** a medal per challenge (bronze for making it, silver at 10 points, gold at 13) and a running total. No online leaderboard.
10. **The name:** the title card tells both stories in one line each.
