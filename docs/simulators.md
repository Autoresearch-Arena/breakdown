<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
PURPOSE: Which iOS simulators to use for Breakdown on the Mac Mini, and which never to boot, after an iPad simulator
         on the older iOS 26.5 runtime put SpringBoard (its home screen) in a crash loop during the 0.8.1 store
         pictures. Read this before any script or helper boots a simulator (store pictures, layout checks, the app
         tests the TestFlight runner runs).
SRP/DRY check: Pass - the only page on simulator choice; store/screenshots/README.md covers how pictures are taken.
-->
# Simulators for Breakdown

## Use only iOS 27.2

On 26 November 2026 a store-picture run booted "iPad Pro 13-inch (M5)" on the **iOS 26.5** runtime
(569C3AEE-AB2A-4ABF-88D1-6472CE5071F6). SpringBoard, the simulator's home screen, crashed over and over (sixteen
crash reports in a few minutes, a trap inside SpringBoard itself, not in Breakdown). The game targets iOS 26, but its
pictures and checks are taken on 27.2, where it runs cleanly.

Use these, and nothing on iOS 26.5:

| Device | Runtime | Id |
| --- | --- | --- |
| Breakdown iPhone 17 Pro iOS 27.2 | iOS 27.2 | CCAA9331-38CE-41F6-A69A-7E7F08760C2D |
| iPad Pro 13-inch (M5) | iOS 27.2 | 3A2EBCEE-A3C9-447E-AAAA-EC508D22B37C |

If a size is missing (a 6.9-inch iPhone for the store pictures), create it on the iOS 27.2 runtime
(`xcrun simctl create "<name>" "<device type>" com.apple.CoreSimulator.SimRuntime.iOS-27-2`). Never pick a device by
name alone: two devices can share a name on different runtimes, as the two "iPad Pro 13-inch (M5)" do.

## Rules on the Mac Mini

- One simulator booted at a time; shut it down before the next and when done (`xcrun simctl shutdown all`).
- After booting, look for new `SpringBoard-*.ips` files in `~/Library/Logs/DiagnosticReports`. One is enough: shut the
  simulator down and use another rather than carrying on.
- Mute the Mac before launching the game (`osascript -e "set volume output muted true"`) and unmute after; the game
  plays its title music on every launch.
- No sleep-and-poll loops longer than two minutes while waiting on a simulator; kill a hung capture and move on.
