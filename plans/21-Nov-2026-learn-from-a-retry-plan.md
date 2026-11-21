<!--
Author: GPT 6.2 Astra High
Date: 21-November-2026
PURPOSE: Plan 14 gives the team a way to check whether a player can learn from a missed shot and use that idea on a different shot. It connects the existing retry, Physics Lens and first lesson.
SRP/DRY check: Pass - reviewed the 13 plans from this date, the original spec, the recorded attempt, the retry comparison, the trick-shot flow and the existing retry demo.
-->
# Plan 14 · Can the player use what the last shot taught them?

Suppose a beginner pots the 3 but the cue ball rolls too far. They open the Physics Lens, find the moment of contact and try again. The payoff comes one shot later. Given a different straight pot, can they choose where to hit the cue ball and say where it will go?

The [lesson plan](21-Nov-2026-first-minute-and-lessons-plan.md) takes a player from watching a shot to passing it unaided. The [physics plan](21-Nov-2026-physics-proof-plan.md) checks that the ball behaves correctly. A player could pass both teams’ finished work by remembering a slider position. Use one stop shot to find out what the player understood while it is still cheap to change the other five lessons.

## How two developers can start today

| Owner | Work on their branch | Handoff |
|---|---|---|
| GPT 6.2 Astra High | Section 2 and the recorded facts for section 3. Own ShotAttempt, the retry and seek actions in ShowpieceModel, and the BreakProbe checks for the two layouts. | Supply the comparison facts, an optional first-contact time from the current shot and an action that pauses there. When the current shot misses every ball, the contact time is absent. |
| Other developer | Section 3’s result card, contact button, ghost, VoiceOver and translations. Prepare the second exercise and the questions in section 4. Own the views, lesson flow and string catalog. | Use Stop Dead as the first entry point while the lesson is being written. Show the contact action when its time exists. Use the same view in the lesson. |

Agree on the names and types of those few values first. Each developer can then implement and push independently. The [work order](21-Nov-2026-award-gaps-order-plan.md) describes the single final build. The observations in sections 1 and 4 are playtest work. Either can use an available build and a willing player. Development can start immediately.

## 1. Try the experiment on the build we have

Start in order 1, alongside the opening work. Use the existing **Stop Dead** trick shot on tournament cloth. Before the session, play it through and pick a repeatable miss that pots the object ball and sends the cue ball past its target. Save the settings and build number in the session notes so the next developer can reproduce it.

Hand the phone to someone new to Breakdown. Show them the missed shot and ask, “Where did you want the white ball to stop? What would you try next?” Let them find the replay, inspect the contact and take a second shot. Record where they looked, what change they expected to help, what happened and the first place they needed a hint. Write down their words. A player who understands the shot but cannot operate the tip control has found a different problem from one who can make the shot and cannot explain it.

Use this first pass to choose the smallest change. If nobody finds the replay, fix the way back to contact before adding more explanation there. If they find contact but cannot read the ball’s motion, work on that moment. Keep the build and task the same when checking the change with fresh players.

## 2. Make a retry an honest comparison

There is a concrete error to cover before relying on the feedback. The app passes cue elevation to the solver, but the saved attempt omits it. The comparison also treats small changes to aim or power and nearby finish positions as unremarkable. When both descriptions come back empty, it can say “Same shot, same result” without establishing either claim. [Shot recording and retry](../App/ShowpieceModel.swift) · [Comparison wording](../App/ShotAttempt.swift)

1. At the existing solve point, retain the effective shot input with the attempt. Restore layout, cue settings including elevation, and the seed used for any physical variation when retrying. Keep the recording’s display identifier separate. A deliberately changed table, cloth or physics generation starts a fresh comparison. Reuse the current table and surface reset paths.
2. Reserve exact-repeat wording for matching physical inputs and matching recorded motion and events, including vertical travel. A change too small to describe can get a modest outcome such as “Both tries left the cue ball near the same spot.” If the player changes several controls, report the observed differences and leave the cause open.
3. Extend the existing retry demo and the app tests from [release safety](21-Nov-2026-release-safety-plan.md). Cover an untouched break, a raised cue retried after moving the elevation control, a small power change that ends in the same area, and switching cloth between attempts. When the cue-strike plan adds seeded miscues, repeat a miscue with identical inputs. Check what the player reads as well as what the solver records.

**Done when** an untouched retry reproduces its recorded shot, a changed elevation or power is never described as identical, and changing cloth clears the old comparison.

## 3. Explain one difference at the table

Build the interaction around the existing Stop Dead shot now. Tune the final pair of shots on the chosen physics settings and connect the same interaction to the first lesson.

1. Pick two tries from the same straight-on layout where the object ball drops both times. Keep aim and speed fixed and vary tip height. Use the recorded cue-ball motion just before and after object-ball contact to select a pair where it clearly runs forward on one try and stops close to contact on the other. Check both with the existing shot-authoring tool.
2. Give the player a way to revisit that contact from the existing result card. Seek the current recording to the event. Use the last-try trail and finish marker to show where the earlier ball went. If the earlier contact needs a measurement, read it at that recording’s own contact time. Describe the difference in one sentence supported by the recordings. A miss that never touches the object ball gets its own literal outcome.
3. Keep one result card. Trick-shot mode already dismisses the general comparison while its own feedback is visible. Reuse that convention in the lesson. Keep the spoken comparison available through VoiceOver, follow Reduce Motion for the camera, and put the action on the existing notebook page on wide screens. Translate the complete sentences in the same change. [Retry overlay and card](../App/GhostOverlay.swift) · [Trick-shot flow](../App/TrickShotMode.swift)

**Done when** the player can go from a miss to the relevant contact, inspect it, change one control and shoot again without losing the layout. Verify the sequence on iPhone, iPad and Mac, including one pass using spoken feedback alone.

## 4. Check the next shot

Prepare a second straight pot on the same cloth with a different cue-to-object distance. Use the authoring tool to verify that copying the demonstration settings misses the new finish zone and that a reachable adjustment succeeds. Keep aim fixed for this check so a missed pot does not mask what the player learned about tip height. The facilitator can load the layout for this exercise.

Try the finished lesson with five people new to Breakdown. Before showing the lesson, ask each what the cue ball will do after contact on a straight pot and record their answer and pool experience. After the lesson, give them the second layout with the guides off. Before they shoot, ask them to choose an adjustment and predict the cue ball’s direction after contact. Allow two tries. Record the prediction, whether they reached the zone, whether they needed a hint, and whether they could point to or describe the evidence in the replay.

Use four of five unaided predictions in the right direction with a matching adjustment as the working target for this small round. Report finishes separately, and identify players who already knew the answer at the start. If only experienced players succeed, try the revision with beginners. If predictions improve but shots still miss, inspect the controls and the target tolerance before rewriting the explanation. If players finish by copying settings, change the second layout and verify it again.

**Done when** the team records the build, both layouts, the counts and any repeated obstacle here. If the round missed the target, change the part that tripped people up and rerun the task with fresh players. Use the finding when authoring follow and draw.
