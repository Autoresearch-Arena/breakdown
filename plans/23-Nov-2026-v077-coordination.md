<!--
Author: Claude Opus 5.5 High
Date: 23-November-2026
PURPOSE: How the five 0.7.7 features are built at the same time by five independent developers and merged by the
         coordinator: who owns what, the rules every builder follows, and the merge order.
SRP/DRY check: Pass - the five feature plans hold the designs; this page only holds the rules for building them together.
-->
# 0.7.7: building five features at once

The Boss picked five features on 23 November 2026. Each has its own plan, written by one planner and checked against
the code by an independent critic:

- [Lens clips to share](23-Nov-2026-clips-plan.md) (the Boss: "a huge priority")
- [Bullet time on the hit](23-Nov-2026-bullet-time-plan.md)
- [Same shot, every world](23-Nov-2026-every-world-plan.md)
- [Achievements](23-Nov-2026-achievements-plan.md) (the physics journal, made "more like an achievements list")
- [Make it again](23-Nov-2026-make-it-again-plan.md)

Each plan goes to its own developer in its own git worktree, branched from main at the commit that adds these plans.
Every developer reports back to the coordinator, who merges, compiles once, fixes what breaks, plays the first minute on
a fresh install and pushes (which ships the TestFlight build).

## Rules for every builder

1. Build your plan, all of it. If the code disagrees with the plan, follow the code and say what you changed in your
   report.
2. Write code only. Do not run xcodebuild, swift build or swift test, and do not boot a simulator: five builds at once
   swamp the Mac Mini. The coordinator compiles once after the merge, so write carefully and re-read your edits.
3. New code goes in new files. In a shared file, keep each edit small and mark it with a comment that starts
   `// 0.7.7 <feature>:` so the coordinator can find and merge it.
4. Never edit App/Localizable.xcstrings. Put every new English line in localization/pending/v077-<slug>.json, in the
   format of the other files there (`keys`, and `translations` as `culture`, `key`, `text`), translated natively into
   all eleven other languages (es, fr, de, it, pt, pt-BR, ja, ko, zh-Hans, ru, ar). Placeholders must match the
   English exactly. The coordinator runs scripts/localization-merge.py.
5. Do not edit CHANGELOG.md, ROADMAP.md, the version number or Breakdown.xcodeproj/project.pbxproj. Put your changelog
   entry (What / Why / How, credited to your model name and effort level) and any project-file setting you need in your
   report; the coordinator adds them.
6. Commit your work on your worktree's branch, with the attribution lines the session gives, and report the branch
   name.
7. Follow CODING_STANDARDS.md: header on every new file, an Edited line on every shared file you touch, real comments on
   the non-obvious parts.

## Shared files and who touches them

Several features hook into the same files. That is expected; the marked comments make the merge easy.

| Shared file | Features |
| --- | --- |
| App/ShowpieceModel.swift | all five |
| App/ShowpieceView.swift | bullet time, clips, achievements |
| App/NotebookPanel.swift | bullet time, clips, achievements, make it again |
| App/FreePlayViews.swift, App/FreePlayPhoneBlurbs.swift | clips, every world, make it again |
| App/MacChrome.swift | clips, every world, make it again |
| App/ControllerInput.swift | clips, every world, make it again |
| App/TableScene.swift, App/TableCamera.swift, App/ShotCamera.swift, App/LensLayer.swift | bullet time, clips |
| App/TrickShotMode.swift, App/TrickShotViews.swift, App/TrickSignature.swift | make it again |
| App/TitleScreen.swift | achievements |

Mac keyboard shortcuts, fixed here so nobody collides: Share Clip is Shift-Command-E, Every Surface is
Shift-Command-U, Make It Again is Shift-Command-S.

## The one known clash

The clips plan replaces the device-clock reads in the camera and Lens code with a small scene clock (SceneClock.now),
so the offscreen clip table can run on its own time. Bullet time edits the same functions. The bullet-time builder
writes its code as the plan says; at the merge, the coordinator routes any device-clock read bullet time adds through
SceneClock.now as well.

## Merge order

Clips first (the priority and the widest change), then bullet time, achievements, every world, make it again. Then the
translations, the changelog entries and the project-file line, the version to 0.7.7, one iPhone build, one Mac build,
the package and app tests, fixes, the first minute on a fresh install, and the push.
