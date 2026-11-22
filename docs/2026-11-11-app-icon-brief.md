<!--
Author: Claude Sonnet 5.5 Medium
Date: 11-November-2026
PURPOSE: Brief for generating the real Breakdown app icon, replacing the placeholder.
SRP/DRY check: Pass — only the icon brief; look and feel comes from the spec, which is linked rather than repeated.
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the approved momentum artwork is the icon again on every device;
        the Mac sizes in the same set are made from the one picture, so replacing it means remaking them).
-->
# Breakdown app icon brief

## What it should show

The look of the game's own cold open: a dark blueprint table, a faint grid, and glowing ball paths. Orange paths where a ball slides, cyan where it rolls. One bright white ball at the centre of the break with paths fanning out from it. Simple enough to read at the size of a thumbnail. See the [spec](2026-11-02-breakdown-spec.md) for the visual language.

## Hard requirements from Apple

- One square PNG, 1024 by 1024 pixels.
- No transparency at all (no alpha channel). Fill the whole square.
- No rounded corners, no border, no shadow around the edge. iOS rounds the corners itself.
- sRGB colour.
- No text, no words, no Apple or device imagery.
- Keep the important shapes inside the middle 80 percent; the corners get cut.

## Nice to have

- Still clear when shrunk to the smallest home-screen size.
- Optional second version for dark mode and a third in a single colour for tinted mode. Not required for TestFlight.

## Where it goes

Replace `App/Assets.xcassets/AppIcon.appiconset/icon.png` with the new file under the same name, then upload a new build with a higher build number.

The same set also feeds the Mac. Its smaller Mac files (`icon-mac-16.png` up to `icon-mac-512.png`, each with an `@2x` partner except the largest, which uses `icon.png` itself) are shrunk copies of that one picture, so remake them whenever it changes, for example with `sips -z 16 16 icon.png --out icon-mac-16.png` for each size. Keep this set the only app icon: a layered icon document named AppIcon anywhere in the App folder would take over on every device.
