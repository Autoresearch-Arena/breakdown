<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
PURPOSE: How the five award-score plans of 25 November 2026 are built together as 0.7.10: who builds what in which
         wave, who owns which files, the rules every builder follows, and the merge order.
SRP/DRY check: Pass - the plans hold the designs (start at 25-Nov-2026-award-scores-order-plan.md); this page only
         holds the rules for building them at once. Modelled on 23-Nov-2026-v077-coordination.md.
-->
# 0.7.10: building the award-score plans at once

The Boss, 26 November 2026: "Get it all done." All five plans are built in one batch and ship as 0.7.10.

## Wave 1 (five builders at once, each in its own worktree)

| Builder | Plan | Stages |
| --- | --- | --- |
| words | [Fewer words and honest claims](25-Nov-2026-fewer-words-and-honest-claims-plan.md) | All (Part A row 6, the menu accent, is left to front door) |
| strike | [Strike panel and controls](25-Nov-2026-strike-panel-and-controls-plan.md) | All four |
| daily | [Shot of the day](25-Nov-2026-shot-of-the-day-plan.md) | Stages 1 and 2 |
| frontdoor | [Front door and table view](25-Nov-2026-front-door-and-table-view-plan.md) | Stages 1 to 4 (stage 5's scene order in scripts/store-shots.sh too; no simulator) |
| gamecenter | [Shot of the day](25-Nov-2026-shot-of-the-day-plan.md) stage 3, plus "Hide the board" from [Everyone can play](25-Nov-2026-everyone-can-play-plan.md) Part E item 2 | Stage 3 |

## Wave 2 (after wave 1 is merged and compiles)

| Builder | Plan | Stages |
| --- | --- | --- |
| bank | Shot of the day | Stage 4: trick and daily shots start on any table and surface; BreakProbe daily; the bank grown |
| everyone | Everyone can play | All parts except Part E item 2, covering the screens wave 1 added |
| wiring | All | The daily shot posts to Game Center; the daily shot plays with the strike panel (angle locked); the second launch opens on today's shot; the menu row sits in the Today group |

## Rules for every builder

1. Build your part, all of it. If the code disagrees with the plan, follow the code and say what you changed.
2. Write code only. Do not run xcodebuild, swift build or swift test, and do not boot a simulator. The coordinator
   compiles once after the merge, so write carefully and re-read every edit. (Wave 2's bank builder is the one
   exception: it may build and run the BreakProbe package tool alone, since the bank is found by running it.)
3. New code goes in new files. In a shared file keep each edit small and mark it with a comment that starts
   `// 0.7.10 <builder>:`.
4. Never edit App/Localizable.xcstrings. New English lines go in localization/pending/v0710-<builder>.json, in the
   format of the other files there, translated natively into all eleven other languages (es, fr, de, it, pt, pt-BR,
   ja, ko, zh-Hans, ru, ar), placeholders matching the English exactly. The coordinator runs
   scripts/localization-merge.py.
5. Do not edit CHANGELOG.md, ROADMAP.md, the version number or Breakdown.xcodeproj/project.pbxproj. Put your changelog
   entry (What / Why / How, credited to your model name and effort level) and any project-file change you need (new
   file groups are picked up by the project's synchronized folders; check that before asking for one) in your report.
6. Commit on your worktree's branch with the session's attribution lines, and report the branch name.
7. Follow CODING_STANDARDS.md: header on every new file, an Edited line on every shared file you touch.
8. No names of people, brands or sources in anything the player sees. No sound while a ball travels.

## Shared files

| Shared file | Wave 1 builders |
| --- | --- |
| App/ShowpieceModel.swift, App/ShowpieceView.swift | strike, daily, frontdoor, gamecenter |
| App/NotebookPanel.swift | strike (the aiming placeholder becomes the strike panel), frontdoor (Lens plan) |
| App/NotebookStory.swift, App/NotebookInfo.swift | words (captions, cloth card, zero tiles), strike (lifts the number tile, replaces the placeholder line) |
| App/TitleScreen.swift | frontdoor (one-line rows, three groups, accent), daily (one marked row above Play) |
| App/TrickShotMode.swift | daily (only if a small hook is needed) |
| App/GameSettings.swift | gamecenter (Hide the board) |
| App/Achievements/* | daily (three new achievements), gamecenter (report to Game Center) |

## Merge order

strike, words, frontdoor, daily, gamecenter. Then translations, one iPhone build, one Mac build, the package and app
tests, fixes. Then wave 2, merged the same way, then the changelog, the version to 0.7.10, the Game Center setup
script run once against App Store Connect, the first minute played on a fresh install and a second launch, and the
push (which ships the TestFlight build). The store listing is not uploaded until the Boss has read the English file.
