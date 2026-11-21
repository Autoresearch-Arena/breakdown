<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for what a brand-new player meets in the first minute, and for the lesson path the spec calls the spine
         of the game, which was never built. Written for junior developers: what happens on first launch today, what
         should happen, the work packages in order and how each is checked.
SRP/DRY check: Pass - checked spec sections "What the first minute feels like", 6 and 10, TitleScreen.swift,
         ShowpieceModel.swift, AimOverlay.swift, TrickShotMode.swift and the other plans of this date. The trick shots
         stay as they are; lessons are a new, smaller thing that reuses their machinery.
-->
# The first minute, and the lessons

## In plain words

The spec promised that a new player opens the game, watches a break, sees the table melt into the physics view, and
is then handed the cue. That opening exists and it is the best thing in the game. But it is not what a new player
sees. Today the game opens on a menu of seven buttons laid over a still table, and the opening is one of them, sixth
in the list, called "Watch the break". The top button is "Trick shots", whose first entry is rated hard.

The spec also promised a lesson path (stun, follow, draw, throw, curve, jump), each a few minutes long: watch a
perfect example, try it three times with less help each time, then pass it unaided. None of it exists. A player who
does not already play pool has no way in, and the Physics Lens, which is the reason the game exists, is never
introduced: it is a button.

## What exists today (read in the code, not played)

- ShowpieceModel starts with the menu open. Nothing remembers whether this is the first launch.
- TitleScreen.swift lists: Trick shots, Behind the 8-Ball, Tables, Free play, Watch the break, How to play, Options.
- How to play is three paragraphs of text. It teaches the trick-shot flow only.
- The aiming tips (AimOverlay.swift, ShotPanel.swift) show once and are remembered. They are the only teaching in
  the game that happens at the moment it is needed.
- Trick shots remember which are done. Behind the 8-Ball remembers best totals and medals. Free play remembers
  nothing.
- Trick shot one is the called break; the list goes easy, hard, medium with no ramp.
- The power readout is in metres per second everywhere, which means nothing to a new player.

## Package 1: the opening is the opening

1. First launch plays the cold open, not the menu. Store a "seen the opening" flag. On first launch ShowpieceModel
   starts with the menu closed and runs the same path "Watch the break" uses.
2. When the slow-motion replay ends, the game hands over the cue with one line of text and one glowing control:
   "Your turn. Drag to aim, pull back, let go." This is the fresh rack in free play with the aiming tips showing.
3. After the player's first break plays through the same opening, the menu appears for the first time.
4. Every later launch opens on the menu as now, with a shorter, skippable cut of the opening behind it (the spec
   asks for this). "Watch the break" stays in the menu, renamed to say what it is: the intro.
5. Reduce Motion: the opening uses the existing still-camera path; check it reads well.
6. A tap anywhere skips the opening at any point and goes to step 2.

Done when: a fresh install goes launch, break, melt, replay, cue in hand, with no menu and no reading required.

## Package 2: a menu a stranger can read

1. Order the menu by what a new player should do next: Learn (the lessons, package 3), Play (free play and the
   games from the rules-games plan), Trick shots, Behind the 8-Ball, Tables, then How to play and Options.
2. Each entry gets one short line under its name saying what it is, and a small progress mark (lessons passed,
   trick shots done, medals).
3. "Continue" returns to whatever was on the table. Keep it first when something is in progress.
4. Power in plain words beside the number: soft, medium, firm, hard, break. Keep the number for those who want it.
5. Trick shots: sort by difficulty, easiest first, and renumber.

## Package 3: the lesson path

Six lessons in this order: stop shot, follow, draw, cut and throw, curve, jump. Each lesson has four beats.

- Watch: a perfect example plays, melts into the Lens, and stops on the one moment that matters with one caption.
- Guided try 1: the aim, power and tip are set for the player and locked; they only shoot. They see it work.
- Guided try 2: one control is unlocked (the one the lesson is about) with a target zone drawn on it.
- Guided try 3: all controls open, target zones faint.
- Pass shot: no help. Pass or try again. Passing marks the lesson done and suggests the trick shot that uses it.

Steps
1. Read TrickShotMode.swift, TrickShots.swift and TrickShotJudge.swift first. A lesson is a trick shot with stages.
   Add a Lesson type in a new file App/Lessons/Lessons.swift: a layout, the reference settings, the goal the judge
   checks, the control the lesson is about, the key event to stop on, and the text for each beat.
2. LessonMode, shaped like TrickShotMode, with the five beats as its phases. Reuse the judge for pass or fail.
3. Locking controls: ShotPanel.swift and AimOverlay.swift need a "which controls are open" value handed in. Draw a
   locked control dimmed with a lock mark, and say "locked for this step" to VoiceOver.
4. Target zones: on the tip gauge (AimGauges.swift) and the power bar, draw the band inside which the shot works.
   The judge already computes how forgiving a shot is (the windows); use those numbers, do not type them in.
5. The key moment: use the caption engine's own event for the idea (slide becomes roll, backspin reverses, the
   throw at contact). The lesson names which caption; the replay pauses there.
6. Author the six lessons with BreakProbe, the same way trick shots were authored, and add them to its authoring
   check so a physics change that breaks a lesson is caught.
7. On the open Duo, lesson text is a page of the side panel.
8. Progress is stored like trick-shot progress. Nothing is locked behind lessons: they teach, they do not gate.
9. Every string in all twelve languages in the same change.

Note on timing: the lessons depend on exact physics, like the trick shots. Author them after the physics proof
plan's package 4 makes the new physics the default, or they will be authored twice. Packages 1 and 2 above do not
depend on physics and can start at once.

Done when: someone who has never held a cue can go from launch to passing the stop-shot lesson without reading
anything outside the game, and all six lessons pass the authoring check.

## Package 4: explain the Lens once

The first time the Lens is on screen in a lesson, three short callouts appear one at a time, each pointing at the
thing: the orange path is the ball skidding, the blue path is the ball rolling, drag the bar to move through time.
Shown once, remembered, and replayable from Options beside "Show the aiming tips again".

## Not in this plan

Rewards, cosmetics, streaks, the daily challenge, predict-the-shot and the Physics Journal from the spec. They are
extra width. Finish the spine first.
