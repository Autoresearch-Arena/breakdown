# Behind the 8-Ball: the builders' contract

Author: Claude Opus 5.5 High, 21-November-2026
Design (final, read it all first): docs/2026-11-21-behind-the-eight-ball-design.md

This folder is the whole mode. The skeleton compiles today: the menu entry opens an empty list, the judge scores
nothing, the views are minimal. Three builders now fill it in parallel. **Each builder edits only the file it owns.**
If you need a change to a shared type (EightBallTypes.swift) or to a file outside this folder, do not make it: write
it in your report so the merge can make it once.

Hard rules for every file: no real people, brands, leagues, governing bodies, sources or URLs, anywhere. Generic shot
names only (kick, bank, jump, massé, swerve, Z shot). New player text is `String(localized:)`, English, informal "you",
short and plain. Header per CODING_STANDARDS.md with an "Edited:" line, credited "Claude Opus 5.5 High". Do not
commit, change the version or the CHANGELOG, or boot a simulator. Build output only under
/Volumes/Team 4TB/breakdown-build/.

## Who owns what

| File | Owner | Job |
|---|---|---|
| EightBallTypes.swift | skeleton (frozen) | the shared types below |
| EightBallSituations.swift | **Situations builder** | the twelve situations of design section 3, checked in the solver |
| EightBallJudge.swift | **Judge builder** | design sections 1 and 2: fouls, loss, made as called, difficulty, style |
| EightBallMode.swift | **Views builder** | the flow (already working; refine only) |
| EightBallViews.swift | **Views builder** | the list, the card, the scored card, the real-table card, the rings |

Already wired outside this folder (do not redo): ShowpieceModel (eightBallMode, enterEightBallTable, physicsTable
forces the pool table while a situation is up, setTable leaves it alone, showsBridge and strokeUsesBridge cover both
modes), TitleScreen ("Behind the 8-Ball" under Trick shots in both menus; Free play, New free game and Watch the
break end the mode), ShowpieceView (EightBallTableLayer beside TrickTableLayer; EightBallCard beside TrickShotCard in
both layouts), TableStage and AimOverlay (the bridge follows model.showsBridge). Entering trick shots ends this mode
and the other way round. The App folder is a synchronised group: new .swift files here join the target on their own.

## Units and names (settle these once; do not re-derive)

- **Positions are always solver metres** in `EightBallSituation.setup`: x along the length 0 to 2.54 (head rail at 0),
  y across 0 to 1.27. Sixteen entries, index 0 the cue ball, 8 the 8-ball, pocketed balls at `NextShot.offTable`.
- **Author in diamonds** with `EightBallTable.layout(cue:eight:balls:)` (across 0 left rail to 4 right rail, along 0
  head to 8 foot, as the design writes them). It returns metres. One diamond is 2.54 / 8 m on both axes. The player
  stands at the head looking to the foot; left is +y (y = 1.27), right is y = 0.
- **Pockets** are `EightBallPocket`, raw value = the solver's pocket index (what `Timeline` events carry):
  headRight 0, footRight 1, headLeft 2, footLeft 3, rightSide 4, leftSide 5.
- **Strokes** are `TrickSettings`: aim in degrees counter-clockwise from the long axis, power = launch speed m/s,
  tipUp / tipSide in metres, elevation = the **sine** of the cue angle (nil = level). Same as the trick shots.
- **`attempt:` in the judge is the try number** (Int, 1-based): 1 is the first try, 2 and 3 cost a point each,
  above 3 is practice and is not stored. It is NOT a ShotAttempt.

## The types (EightBallTypes.swift)

- `EightBallGroup` solids / stripes: `balls`, `other`, `title`, `of(ball:)`.
- `EightBallPocket` (above) with `title`.
- `EightBallCall`: `.ball(Int, pocket: EightBallPocket)` or `.safety`; `.ball` and `.pocket` read it.
- `EightBallEscapeKind`: kick, bank, jump, masse, swerve, bridge, combination, carom, safety; `isHardTechnique`
  (jump, massé, swerve; a kick counts only off two or more rails, see `rails`).
- `RealTableNumbers(settings:surface:)`: aim degrees, speed m/s, elevation in **degrees** (converted from the sine),
  tip offsets, the surface and its sliding friction, rolling resistance and cushion restitution as the solver used
  them (from `PlaySurface.parameters`). Build it, never type the cloth numbers by hand.
- `RealTableCard`: `aim` (diamonds for kicks and banks, ball edge or gap for jumps and massés), `cue` (level, raised
  with the angle, steep, or on the bridge), `speed` (a felt comparison; the m/s is in `numbers`), `commonMiss`,
  `numbers`.
- `EightBallEscape`: `id` ("A", "B", "C"), `title`, `kind`, `alsoUses` (stacked techniques), `rails` (before first
  contact), `settings`, `call`, `usesBridge`, `rating` 1-5, `card`.
- `EightBallSituation`: `id`, `number`, `title`, `story`, `setup` (metres), `group` (yours), `surface`, `escapes`,
  `lesson`, `taughtBy` (TrickShots ids). Derived: `yourBallsLeft`, `onTheEight`, `legalBalls`, `usesBridge`,
  `topRating`.
- `EightBallFoul`: scratch, wrongBallFirst, noBallHit, noRailAfterContact, objectBallOffTable,
  cueOrBridgeTouchedBall, doubleHit, illegalJump. Any foul scores 0.
- `EightBallLoss`: eightOnFoul, eightEarly, eightWrongPocket, eightOffTable. Scores 0, challenge failed.
- `EightBallStylePoint`: hardTechnique, stacked, threaded, shape, forTheGame (named on the scored card).
- `EightBallVerdict`: the judge fills `madeAsCalled`, `fouls`, `loss`, `difficulty` (1-5 when made, else 0),
  `style` (named points), `safetyLeftHooked`, `matchedEscape`, `nearEdge`, `fluke`, `tryNumber`, `line` (one short
  sentence). **`total` and `medal` are computed, never set**: legal make = 5 + difficulty + min(style, 5); legal
  safety that hooks = 3; other legal miss = 1; foul or loss = 0; minus 1 per retry (try 2 and 3), never below 0.
  Medal only for a legal make that is not practice: bronze, silver at 10, gold at 13.
  `cappingStyle(at:)` caps style (the mode applies `hintStyleCap` 2 after a watched hint). `neutral(call:tryNumber:)`.
- `EightBallMedal` bronze / silver / gold, Comparable.

## How they connect

1. Menu > Behind the 8-Ball sets `eightBallMode.listOpen`; `EightBallTableLayer` hosts the sheet (`EightBallList`).
2. `EightBallMode.begin(_:)` ends trick shots, closes the menu, calls `model.setSurface(situation.surface)` (so the
   Surface menu, the 3D cloth and the solver agree; the player may still change it), loads `setup` through
   `model.loadTrickLayout`, phase `.looking`.
3. `.looking` > `startCalling()` > `.calling`: `pick(ball:)` then `pick(pocket:)`, or `callSafety()` > `.aiming` (the
   shot panel opens through `wantsAiming` / `aimingRequests`, applied by the layer). `watch(_ escape:)` is the hint
   (`.watching`, ride camera, caps style at 2 for this visit) and returns to `.looking`.
4. The player shoots with the normal controls (elevation from `model.shotElevation`). `update()`, called by the layer
   on `aimReady` and `timelineVersion`, moves `.aiming` > `.playing`, then judges once per recording that started
   from `setup`:
   `EightBallJudge.judge(timeline:call:situation:settings:surface:attempt:)` with `surface: model.physicsSurface`.
5. `.scored(verdict)`; the best total and best medal per id go to UserDefaults ("eightBallBest", "eightBallMedals");
   `celebrations` bumps on a medal. `tryAgain()` keeps the call; `next()` goes on; `end()` leaves.
6. The views read `mode.phase`, `mode.current`, `mode.call`, `mode.pendingBall`, `mode.markers` (called ball and
   pocket, as solver indices), `mode.lastVerdict`, `best(_:)`, `medal(_:)`, `runningTotal`, `nextTry`. The escape's
   `card` for the scored card: the `matchedEscape`, or the escape whose call matches, or the top-rated one.
7. `end()` puts back the surface the player had before entering (captured on a fresh entry only, so `next()` from a
   tournament-cloth situation to a dive-bar one does not record tournament cloth as theirs).
8. **No call, no verdict:** a shot taken with no call (the panel opened some other way in `.looking`) plays as
   practice: it is not judged and uses no try. The views should steer the player to Make your call first.

## Notes for each builder

- **Situations:** every layout is a full table in progress (both groups and the 8), never three balls on a bare
  table. Check in the real solver that the natural line is blocked and every listed escape passes with its call and
  no foul; nudge balls until it does. Record measured windows in a comment as TrickShots does. Set some situations on
  `.tournament` or `.diveBar` where the design's cloth point lands best, and say so in the card.
  `taughtBy` ids must exist in TrickShots.all.
- **Judge:** read only the timeline and the settings. Re-solve for window sweeps with the same table and surface
  parameters the app uses (`TableKind.standard.apply`, then `surface.apply`, as ShowpieceModel.solve does), and keep
  the sweep cheap. Signature is fixed. `surface` is the live one (the player may change it mid-situation); the
  authored ratings were set on `situation.surface`, so apply the "within one of the authored rating" cap only when
  `surface == situation.surface`, otherwise use the measured rating alone (still capped at 5).
- **Views:** keep the table big: one compact glass card, standard controls, Dynamic Type, VoiceOver labels, Reduce
  Motion. Ball and pocket taps for the call are the layer's job (hit-test on the table only while `.calling`). The
  real-table card shows the plain words and the numbers side by side, cloth numbers included when the surface is not
  plain cloth. With `EightBallSituations.all` empty the list must say so plainly.
