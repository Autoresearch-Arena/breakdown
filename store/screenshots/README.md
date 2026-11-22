<!--
Author: Claude Opus 5.5 High
Date: 21-November-2026
PURPOSE: How Breakdown's App Store screenshots are made: the ten frames, how scripts/store-shots.sh captures the raw
         shots from the simulator, how compose.swift frames them with a headline, where the raw and finished files
         live, and the exact sizes App Store Connect takes. Nothing here has been uploaded.
Edited: Claude Opus 5.5 High, 21-November-2026 (retaking a few scenes, pinned launch settings, the gameplay video, and
         no Mac set for now.)
Edited: Claude Opus 5.5 High, 21-November-2026 (iPad frames 07 and 08 cropped to the tables and laid out large.)
Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo sets: duo-inner, the open screen, and duo-outer, the
         closed one; how to capture each and how their composite frames differ.)
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, bug plan items 40 and 54: the new ten frames and their -store
         launch flags, the one-time settings pinned for the new game, the iPad crop for the notebook layout, the
         real-table frame re-shot and replaced first, and uploading every device with scripts/store-upload.py.)
SRP/DRY check: Pass - this folder holds only the screenshot framing script and the headlines. The listing text is in
         store/listing; the scenes themselves are the app's own launch flags, listed once in scripts/store-shots.sh.
-->
# Store screenshots

Ten frames per language and device. Each frame is one moment of the game with a short headline above it.

| Frame | What it shows | Launch flags |
|---|---|---|
| 01-lens | The Physics Lens on the opening break, held on a headline beat with its equation | -noTitle |
| 02-match | Eight-ball against the medium computer mid-game, its "Why that shot" card open | -storeMatch |
| 03-lesson | Lesson 3 (draw) held on its key moment with its target band up | -storeLesson 3 |
| 04-real-table | Behind the 8-Ball's full massé made as called, with its "On a real table" card | -eight masse-for-the-win -eightPlay B -eightRealTable |
| 05-ruling | A two-player eight-ball ruling card after a foul | -storeRuling |
| 06-drill | The straight-stroke drill with a measured stroke on its card | -storeDrill |
| 07-surfaces | Two shots side by side: ice (07a-ice) and the Moon (07b-moon). On iPad, two large staggered table tiles | -optionSurface ice / moon with -trickAim |
| 08-tables | Three scored games halfway through: bumper pool (08a-bumper), five-pin (08b-fivepin), bar billiards (08c-bar). Side by side on iPhone and Mac; on iPad, five-pin large with the other two stacked beside it | -storeTableGame bumperPool / fivePin / barBilliards |
| 09-ride | A Ride replay held where the room and the lamp show | -storeRide |
| 10-jump | Behind the 8-Ball: the cue ball in the air over the 8, from the ride camera | -eight tucked-behind-the-8 -eightPlay B -eightRide -pauseAt 0.20 |

The six -store flags are the app's StoreScene (docs/v07-contracts.md 2.6): each skips the menu and the opening and
puts its scene up still. The frame list lives in three places that must agree: the scene list in
scripts/store-shots.sh, the `frames` table in compose.swift, and the keys of captions/<language>.json (which
scripts/store-upload.py also reads for the order).

### Replace the folding-phone real-table frame first

The open-Duo set already uploaded holds an "On a real table" frame that states the massé's aim, speed and tip and the
cloth's friction, roll and cushion numbers from before the physics retune. Replace that one frame before anything
else, once the 0.7.0 build is installed on the Duo simulator:

    SIM_DISPLAY=3 SCENES="04" scripts/store-shots.sh <duo id> duo-inner en es fr de it pt pt-BR ja ko zh-Hans ru ar
    swift store/screenshots/compose.swift duo-inner en es fr de it pt pt-BR ja ko zh-Hans ru ar
    ~/.appstoreconnect/venv/bin/python scripts/store-upload.py duo --frame 04-real-table

The upload swaps only that frame in each language's set, in the same place; the other nine stay until the whole set
is re-shot.

## Step one: capture the raw shots

`scripts/store-shots.sh <simulator id> <device name> <language> [language...]` opens the app on that simulator once per
scene, straight into the moment by the app's own launch flags, in the given language, with the status bar set to a
clean 9:41 and full signal. `scripts/store-shot.sh` does each single capture: it quits the app, launches it with sound muted and with its stored
settings pinned from the launch line (cloth, the pool table, no scores, no trick or lesson progress, an empty match
record, and every one-time thing already seen: the opening, the Lens tips, the aiming hint, the stance card's pulses;
a scene's own surface or table flag wins), removes any game left halfway (a file, so it cannot be pinned), waits for
the scene to settle and saves the screen. Pinning is used
because deleting stored settings between launches does not reliably take. The app must already be installed.

To retake only some scenes, name them by prefix: `SCENES="03 07a" scripts/store-shots.sh ...`.

Raw shots land on the Team 4TB drive, never in git:

    /Volumes/Team 4TB/breakdown-build/store-shots/raw/<device>/<language>/<scene>.png

Device names are `iphone-6.9`, `ipad-13`, `mac`, `duo-inner` and `duo-outer`. There is no Mac set yet: capturing the Mac app means opening game
windows over the desktop of whoever is using the Mac, so it waits for a time the Boss chooses. compose.swift already
frames Mac window captures of any size.

### The iPhone Duo (two sets from one simulator)

The Duo simulator has two screens, and posture is set with the simulator tool's `set_posture` (there is no command-line
way). Install a Release build, then run the capture once per screen with `SIM_DISPLAY` naming the screen (3 is the inner
display, 1 the outer one; `xcrun simctl io <device> screenshot` refuses to choose between them):

    # posture open, in its landscape orientation (951 x 669 points): the table fills the left half, the words the right
    SIM_DISPLAY=3 scripts/store-shots.sh <duo id> duo-inner en de ...
    # posture closed: the small outer screen, portrait
    SIM_DISPLAY=1 scripts/store-shots.sh <duo id> duo-outer en de ...

Do not use `DEVICE_LOCALE=1` on the Duo: restarting the simulator can reset its posture, and the Duo status bar shows
nothing that changes with the language. Raw shots are 2853 x 2007 (inner) and 1398 x 2034 (outer). The Duo needs its own
screenshots from April 2027 for apps built with the iOS 27.1 SDK or later.

## Step two: frame them

    swift store/screenshots/compose.swift <device> <language> [language...]

For example `swift store/screenshots/compose.swift iphone-6.9 en de ja`. Each frame gets a near-black gradient, a soft
felt-green glow behind the shot, a short cyan bar, the headline in white heavy rounded type (at most two lines,
shrunk until every headline of that language fits, so the whole set uses one size), and the shot below with rounded
corners and a soft shadow. Frames 07 and 08 put their two or three shots side by side, the same height, gently
staggered. Shots are scaled to fit, never cropped or stretched, with one exception: on iPad, frames 07 and 08 use only
the table area of each raw shot (the notebook panel and the status bar are cut away by a fixed crop that keeps the
whole table with its rails and pockets). The iPad set is shot upright,
where the notebook panel is a band under the table, so the crop keeps the full width and the top 62 percent (the
table's share of a 13-inch iPad's height, worked out from NotebookGeometry). There, 07 shows two large
staggered tiles and 08 shows five-pin large on the leading side with bumper pool above bar billiards beside it. Arabic is drawn right to left; Japanese, Korean,
Chinese and Cyrillic use the system's own fonts for those scripts. A missing raw shot skips that frame with a warning.

Headlines come from `captions/<language>.json`, one key per frame (`01-lens` ... `10-jump`, with `07-surfaces`
and `08-tables` for the side-by-side frames), in every language.

On the Duo, every frame is one whole screen. Frames 07 and 08, which show several tables, crop each raw shot to its table
(on the inner screen, the table's own half, left of the fold, mirrored for Arabic; on the outer screen, the table's
strip above the controls). The inner frames stand the tiles side by side, the same height; the outer frames cannot
(whole portrait screens side by side would each be tiny), so frame 07 stacks its two tiles in a gentle zigzag and frame 08
puts one tile on top and two side by side beneath it. On the outer screen the status column on the right and, for the
surface shots, the trick-shot card under the table are cropped away. The crops are the `tableCrops` and `frameCrops`
tables in compose.swift.

Optional flags, for testing:

- `--raw-root <folder>` reads raw shots from another folder (laid out as `<device>/<language>/`).
- `--out-root <folder>` writes finished frames somewhere else.
- `--captions <file or folder>` uses another headline file (for every language given) or folder of `<language>.json`.

Finished frames also live on the drive, never in git:

    /Volumes/Team 4TB/breakdown-build/store-shots/final/<device>/<language>/<NN-frame>.png

## Sizes

Every finished frame is exactly the App Store Connect size, an opaque PNG (no alpha channel, which App Store Connect
rejects) in sRGB:

| Device | Size (pixels) |
|---|---|
| iphone-6.9 | 1320 x 2868, portrait |
| ipad-13 | 2064 x 2752, portrait |
| mac | 2880 x 1800, landscape |
| duo-inner | 2853 x 2007, landscape (the open iPhone Duo; 2007 x 2853 portrait is also accepted, not used) |
| duo-outer | 1398 x 2034, portrait (the closed iPhone Duo) |

Check one with `sips -g pixelWidth -g pixelHeight -g hasAlpha <file>`.

## The gameplay video

`scripts/store-video.sh <simulator id> <language> [language...]` records one clip per beat (the same clean, pinned
launch, recorded from the simulator screen) into `/Volumes/Team 4TB/breakdown-build/store-video/clips/<language>/`.
`CLIPS="02"` re-records only some clips. `scripts/store-video-cut.sh <language> [language...]` trims the beats (their
times are listed in that script), joins them with hard cuts, lays the title music under them with a fade at the end,
and writes two files to `/Volumes/Team 4TB/breakdown-build/store-video/final/<language>/`:

| File | Size | Use |
|---|---|---|
| app-preview-iphone-6.9.mp4 | 886 x 1920, 30 fps, under 30 seconds | App Store preview for 6.9-inch iPhones |
| breakdown-gameplay.mp4 | 1080 x 2346, 30 fps | The same cut at higher resolution, for the site and sharing |

The beats: the jump over the 8 from the ride camera, the full massé from the ride camera, the gold-medal scorecard,
the break melting into the Physics Lens, the Long Bridge Draw, the massé on the Moon, the five-pin opening, and the
main menu. Bar billiards is left out of the video because its opening shot is over too fast to read.

## Uploading

`scripts/store-upload.py <iphone-6.9|ipad-13|mac|duo> [language...]` puts a device's frames into App Store Connect
for every language, in the frame list's order (it needs the team key in `~/.appstoreconnect/`). iPhone, iPad and Duo
frames go on the app record's iOS version, Mac frames on its macOS version (scripts/testflight.py adds the Mac to the
record with the first Mac build). `--frame <name>` replaces one frame in place instead of the whole set. The Duo is one
display type (APP_IPHONE_DUO) that takes either screen's size, but Apple allows only ten screenshots per language in
it, so the ten are a choice: edit `DUO_PICKS` in the script. On 21-November-2026 the ten open-screen frames of the old
list went up for all twelve languages; their real-table frame is the one to replace first (above).
The iPhone, iPad and Mac frames are not uploaded yet, and there is no Mac set until the Mac app is captured by window.
