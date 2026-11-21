<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
Edited: Claude Opus 5.5 High, 21-November-2026 (rewritten to describe the game as it is in the code today, per
        plans/21-Nov-2026-release-safety-plan.md package 4: the old milestone text, which listed pocket jaws and spin
        controls as not built, is gone; added how the game is checked before every upload).
PURPOSE: Explain the working game, how it is built and checked, how to build it, and where the project documents are.
SRP/DRY check: Pass - checked the app's code, the CHANGELOG, the spec and the plans; detail stays in those documents
        and is linked, not repeated.
-->
# Breakdown

A pool game for iPhone, iPad and Mac that lets you see the physics working.

Every shot is solved by our own physics engine before it plays, so every number the game shows you is one it really
computed. After a shot the table can melt into a dark blueprint (the Physics Lens) where each ball leaves a glowing
path, arrows show speed and spin, and short notes explain where the energy went. You can scrub back and forth through
the shot, slow it down, ride along with the balls, and try it again to see what your change did.

- Spec (the original design record, with a note at the top on what is built): [docs/2026-11-02-breakdown-spec.md](docs/2026-11-02-breakdown-spec.md)
- What is being worked on now, and in what order: [plans/21-Nov-2026-award-gaps-order-plan.md](plans/21-Nov-2026-award-gaps-order-plan.md)
- Change log: [CHANGELOG.md](CHANGELOG.md)

Created for the repository owner with AI coding assistance. The original commit history preserves contributor credits.
Hosting under Autoresearch-Arena does not, by itself, establish legal ownership.

## What you can play today

- **Trick shots.** Ten authored shots, each teaching one piece of physics: a called break, a stop shot, a long draw
  with the bridge, follow-through, a two-rail kick, a cross-side bank, a combination, throw, a massé and a jump. Each
  says how forgiving it is, explains the idea and its equation once you have seen it, and tells you what to change
  after a miss.
- **Behind the 8-Ball.** Twelve puzzles in which you are hooked in a game of eight-ball and must find a legal way
  out (kicks, banks, jumps, massés, swerves, safeties). Each is scored for being legal, made as called, difficulty and
  style, and shows how the same escape is played on a real table.
- **Free play.** Rack the balls and break, then keep shooting from wherever they stop, with aim, power, cue-tip height
  and side, a raised cue for jumps and massés, and the mechanical bridge.
- **Watch the break.** The opening: a break at full speed, a freeze, the melt into the Physics Lens, then the same
  break in slow motion with its explanation.
- **Four tables.** The nine-foot pool table, bumper pool, five-pin billiards (no pockets, little pins in the middle)
  and bar billiards (holes in the bed, pegs that must not fall). On the three newer tables you can shoot and watch the
  physics; they do not keep score yet.
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

Under way, not yet in the game: full matches of eight-ball and nine-ball for two players, scoring on the other
tables, real rails and a real cue strike behind a physics switch, and lessons. The order of work is in the plans
folder.

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
`scripts/testflight.py`. Before it builds anything, that script now runs two checks and stops, uploading nothing, if
either fails:

1. The physics package's tests: the solver against hand-worked answers, the spec's test list, pockets, jumps, the
   other tables, the shared shot reading, the match building blocks, and eleven checks against things anyone can see
   on a real table. The real-table checks that wait on the planned physics work and tuning are marked as expected
   failures: they report, but do not stop an upload.
2. Every authored trick shot and Behind the 8-Ball escape is played exactly as the app carries it and must still
   work (`BreakProbe verify`). A physics change that breaks authored content cannot reach a phone.

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

No server, account, key or environment file is needed to build or play. Build success is not a substitute for looking
at the game and touching the controls on a device.
