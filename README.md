<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 Game Center: the line on what is needed to play says the game
        itself sends nothing and Apple carries a signed-in player's daily board scores.)
Edited: Claude Opus 5.5 High, 21-November-2026 (rewritten to describe the game as it is in the code today, per
        plans/21-Nov-2026-release-safety-plan.md package 4: the old milestone text, which listed pocket jaws and spin
        controls as not built, is gone; added how the game is checked before every upload).
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, bug plan item 39: the lessons, the matches against a friend or
        the computer, the scored side tables and the stroke are in the game, so they move from "under way" to what you
        can play; eleven trick shots, not ten; the plan being worked on now is the 0.7.0 bug plan).
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the real games are played against the computer; the
        two-player option is no longer offered here as a selling point).
Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 words, plans/25-Nov-2026-fewer-words-and-honest-claims-plan.md
        Part C: only claims a reader can check on the device. "Real games" are full games; Behind the 8-Ball's card is
        described by what it gives (the aim, speed and spin the escape used), not as advice for a real table.)
PURPOSE: Explain the working game, how it is built and checked, how to build it, and where the project documents are.
SRP/DRY check: Pass - checked the app's code, the CHANGELOG, the spec and the plans; detail stays in those documents
        and is linked, not repeated.
-->
# Breakdown

A pool game for iPhone, iPad and Mac that lets you see the physics working.

Every shot is solved by the game's own physics solver before it plays: every path and number on screen is one it
worked out, and none is drawn by hand. After a shot the table can melt into a dark blueprint (the Physics Lens) where each ball leaves a glowing
path, arrows show speed and spin, and short notes explain where the energy went. You can scrub back and forth through
the shot, slow it down, ride along with the balls, and try it again to see what your change did.

- Spec (the original design record, with a note at the top on what is built): [docs/2026-11-02-breakdown-spec.md](docs/2026-11-02-breakdown-spec.md)
- What is being worked on now, and in what order: [plans/21-Nov-2026-bugs-after-0-6-6-plan.md](plans/21-Nov-2026-bugs-after-0-6-6-plan.md)
- Change log: [CHANGELOG.md](CHANGELOG.md)

Created for the repository owner with AI coding assistance. The original commit history preserves contributor credits.
Hosting under Autoresearch-Arena does not, by itself, establish legal ownership.

## What you can play today

- **Lessons.** Six short lessons (stop, follow, draw, cut, curve, jump), each showing the shot and why it works, then
  handing you the cue until you can play it yourself.
- **Full games.** Eight-ball and nine-ball with the full rules (calls, fouls, ball in hand, the 8 on the break), against
  the computer at easy, medium or hard, which shows why it chose each shot.
- **The stroke.** Power is how fast you swing: on a touch screen you pull back from the white ball and push through
  it, and a rushed or crooked stroke drifts. A straight-stroke drill measures yours.
- **Trick shots.** Eleven authored shots, each teaching one piece of physics: a called break, a stop shot, a long draw
  with the bridge, follow-through, a two-rail kick, a cross-side bank, a combination, throw, a massé, a jump and a
  draw-massé carom. Each says how forgiving it is, explains the idea and its equation once you have seen it, and tells
  you what to change after a miss.
- **Behind the 8-Ball.** Twelve puzzles in which you are hooked in a game of eight-ball and must find a legal way
  out (kicks, banks, jumps, massés, swerves, safeties). Each is scored for being legal, made as called, difficulty and
  style, and its card ("On a real table") gives the aim, speed and spin the escape used.
- **Free play.** Rack the balls and break, then keep shooting from wherever they stop, with aim, power, cue-tip height
  and side, a raised cue for jumps and massés, and the mechanical bridge.
- **Watch the intro.** The opening: a break at full speed, a freeze, the melt into the Physics Lens, then the same
  break in slow motion with its explanation.
- **Four tables.** The nine-foot pool table, bumper pool, five-pin billiards (no pockets, little pins in the middle)
  and bar billiards (holes in the bed, pegs that must not fall). The three other tables are full games with their own
  rules and score.
- **Ten surfaces.** Ordinary cloth, tournament cloth, dive-bar felt, ice, glass, rubber, cork, carpet, sand and the
  Moon, each changing grip, rolling, spin and bounce in a way the Lens shows.
- **Replay tools.** Play and pause, speeds from a tenth to full, a scrub bar marked at every impact, the Ride camera
  that follows the balls at table height, and Try again, which lays your last attempt over the table as a ghost and
  says what changed between the two.
- **The folding iPhone.** Opened up, the table fills one half and the other half is a live notebook: the explanation
  of the shot as it plays, its numbers, the surface and the controls, with nothing ever covering the table. Closed, it
  plays like any iPhone.
- **Twelve languages,** sound made from the impacts themselves, haptics on iPhone, and opening music picked at random
  from three tracks each launch.

Not in the game yet: the what-if fork in the Lens (nudge a shot and see the other future beside the real one), the
spec's prediction and break challenges, a daily challenge, and a computer opponent for the three other tables. The
spec's status note lists what is built and what is missing, section by section.

## How it is built

SwiftUI for the screens, RealityKit for the 3D table, and generated audio. A local Swift package,
`Packages/BreakdownCore`, holds everything that needs no screen: the physics solver, the recorded shot that playback
reads, the shared reading of what happened in a shot, and the rules of the match games. The solver is event-driven: it
works out the exact moment of every contact, so nothing can pass through anything, and the same shot always comes out
the same. There are no remote package dependencies and no bought asset packs.

- [Roadmap](ROADMAP.md)
- [Dependencies, research references and rights scope](THIRD_PARTY_NOTICES.md)
- [MIT license](LICENSE)

## How it is checked

Every push to the main branch that changes the app is built on the Mac Mini and sent to TestFlight by
`scripts/testflight.py`, the iPhone and iPad app and the Mac app from the same push. Before it builds anything, that
script runs four checks, one after the other, and stops, uploading nothing, if any fails:

1. Every string the app shows is translated in all twelve languages, with the same placeholders as the English
   (`scripts/translation-check.py`).
2. The physics package's tests: the solver against hand-worked answers, the spec's test list, pockets, jumps, the
   other tables, the shared shot reading, the match building blocks, and checks against things anyone can see on a
   real table. Tests marked as expected failures report, but do not stop an upload.
3. Every authored trick shot and Behind the 8-Ball escape is played exactly as the app carries it and must still
   work (`BreakProbe verify`). A physics change that breaks authored content cannot reach a phone.
4. The app's own tests, on one iPhone simulator.

The developer tool `BreakProbe` (in the package) also authors trick shots and puzzles, and runs the tuning sweep that
tries the guessed physics numbers against the real-table checks (`BreakProbe sweep`).

## Build and run

Use a Mac with full Xcode selected as the active developer tools, not only the command-line tools. The package needs
Swift tools 6.2; the app targets iOS 26 and macOS 26. Windows and Linux cannot build the Apple user interface.

On the shared Mac Mini, all build output goes on the Team 4TB drive, never the internal drive. Run the physics tests:

```sh
swift test --package-path Packages/BreakdownCore --scratch-path "/Volumes/Team 4TB/breakdown-build/spm"
```

Check every authored shot (add `2` to try them on the new physics generation):

```sh
swift run -c release --package-path Packages/BreakdownCore --scratch-path "/Volumes/Team 4TB/breakdown-build/spm" BreakProbe verify
```

Open `Breakdown.xcodeproj` in Xcode, select the Breakdown scheme, choose My Mac or an installed iPhone simulator and
press Run. A physical iPhone needs your own signing team; no signing credentials belong in Git. For build-only checks
without signing, pass an output folder on the Team 4TB drive:

```sh
xcodebuild -project Breakdown.xcodeproj -scheme Breakdown -destination 'generic/platform=iOS Simulator' -derivedDataPath "/Volumes/Team 4TB/breakdown-build/dd-ios" CODE_SIGNING_ALLOWED=NO build
```

No server, account, key or environment file is needed to build or play. The game itself sends nothing anywhere; the
daily board is Apple's Game Center, and only if a player chooses to sign in (the game asks only when Board is pressed)
does Apple carry their scores, under Apple's own terms. Build success is not a substitute for looking
at the game and touching the controls on a device.
