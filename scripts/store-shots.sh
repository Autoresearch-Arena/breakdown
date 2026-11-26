#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Take the raw App Store screenshots for one simulator in any number of languages. Each scene is the app opened
#          straight into one of its best moments by its own launch flags (store-shot.sh does one capture). The raw
#          shots land on the big drive, in raw/<device name>/<language>/<scene>.png; store/screenshots/compose.swift
#          then frames them with the headlines in store/screenshots/captions.json.
#          Usage: [SCENES="06 07a"] [DEVICE_LOCALE=1] store-shots.sh <device id> <device name> <language> [language...]
#          The app must already be installed on that simulator.
# Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, bug plan items 40 and 54: ten frames led by the Lens, then a
#          match against the computer, a lesson, the real-table card, a ruling, the stroke drill, the surfaces, the three
#          other tables keeping score, a Ride view of the room and Behind the 8-Ball's jump. The new scenes use the
#          app's -store launch flags (docs/v07-contracts.md 2.6). The real-table frame is captured first because the
#          uploaded folding-phone copy states numbers the game no longer uses. The two plain list screens are gone.)
# Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, plans/25-Nov-2026-front-door-and-table-view-plan.md
#          Stage 5 step 1: the store page leads with the unusual. The scenes are taken in the page's new order: the three
#          other tables (bar billiards mid-game among them) and the jump first, then the rest as before. File names are
#          unchanged, so compose.swift, the caption keys and SCENES= still match; the frame order itself is compose.swift's
#          frame list and the caption files' key order, changed to match. Wave 2 adds three scenes in front: the Lens on a
#          bumper pool shot, the strike panel with its figures, and the Shot of the day result (see the marked spot).
#          Take the iPad and folding-phone sets first and check them before the upright phone set; one simulator at a time.)
# Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: the three new scenes at the marked spot, 11 to 13,
#          with their -storeLensBumper, -storeStrike and -storeDaily flags. The page now has thirteen frames;
#          store-upload.py sends the first ten, so the drill, the surfaces and the Ride fall off the page's end.)
# Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 pictures: WAIT_EXTRA=<seconds> adds that much to every
#          scene's wait. The 13-inch iPad simulator needs about six more: at the usual waits the Lens on bumper pool was
#          still black and the strike scene was still settling its break.)
# Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 pictures: the real-table scene waits 26 seconds; at 16 the
#          massé was still rolling and the "On a real table" card had not come up.)
# SRP/DRY check: Pass - the scene list only. Capturing is store-shot.sh; framing is compose.swift.
set -e
here=${0:A:h}
device=$1; name=$2; shift 2
root="/Volumes/Team 4TB/breakdown-build/store-shots/raw/$name"
[[ -d "/Volumes/Team 4TB" ]] || { echo "The Team 4TB drive is not mounted."; exit 1 }
xcrun simctl status_bar "$device" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
# DEVICE_LOCALE=1 also sets the simulator's own language and region to each language and restarts it, so the parts of
# the screen the app does not draw (the iPad status bar's date) match. It takes a restart per language.
for lang in "$@"; do
  out="$root/$lang"
  if [[ -n $DEVICE_LOCALE ]]; then
    case $lang in
      en) loc=en_US ;; pt-BR) loc=pt_BR ;; pt) loc=pt_PT ;; zh-Hans) loc=zh_CN ;; ar) loc=ar_SA ;;
      ja) loc=ja_JP ;; ko) loc=ko_KR ;; *) loc=${lang}_${(U)lang} ;;
    esac
    xcrun simctl spawn "$device" defaults write .GlobalPreferences AppleLanguages -array "$lang"
    xcrun simctl spawn "$device" defaults write .GlobalPreferences AppleLocale -string "$loc"
    xcrun simctl shutdown "$device" >/dev/null 2>&1 || true
    xcrun simctl boot "$device"; xcrun simctl bootstatus "$device" -b >/dev/null
    xcrun simctl status_bar "$device" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
      --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
    sleep 5
  fi
  # SCENES="06 07a" limits a run to those scenes (by file-name prefix), to retake a few shots.
  shot() {
    local name=${2:t}
    if [[ -n $SCENES ]] && [[ " $SCENES " != *" ${name%%-*} "* ]]; then return; fi
    # WAIT_EXTRA lengthens every wait for a slower simulator (the first argument is the scene's wait).
    local wait=$(( $1 + ${WAIT_EXTRA:-0} )); shift
    "$here/store-shot.sh" "$device" "$lang" "$wait" "$@"
  }
  # The scenes are the app's own launch flags. The six -store flags (StoreScene in App/ShowpieceModel.swift) open their
  # scene straight away and hold it still, so they wait as long as the still aim scenes always have (6 to 8 seconds:
  # the launch, the table's first frame and, for a match or a ruling, the shot that leads to it being solved).
  #
  # 0.7.10 frontdoor: wave 2 adds its three scenes here, in this order, ahead of everything below: the Lens on a
  # bumper pool shot, the strike panel with its planned figures, and the Shot of the day result.
  # 0.7.10 wiring: the three scenes (App/StoreScenesDaily.swift). Each is struck and solved before it holds, as the
  # table-game scenes are, so each waits as long as they do.
  # 11 Bumper pool's first shot held just after its first contact, under the Physics Lens.
  shot 8  "$out/11-lens-bumper.png" -storeLensBumper
  # 12 Free play after the break: a shot lined up with draw and side, the strike panel showing its planned figures.
  shot 8  "$out/12-strike.png"     -storeStrike
  # 13 The Shot of the day made on its first try: the result card with the score and the streak (a throwaway record).
  shot 8  "$out/13-daily.png"      -storeDaily
  # 08 The three other tables, each a scored game halfway through, framed side by side (bar billiards among them).
  shot 8  "$out/08a-bumper.png"    -storeTableGame bumperPool
  shot 8  "$out/08b-fivepin.png"   -storeTableGame fivePin
  shot 8  "$out/08c-bar.png"       -storeTableGame barBilliards
  # 10 Behind the 8-Ball: the cue ball in the air over the 8, from the ride camera.
  shot 7  "$out/10-jump.png"       -eight tucked-behind-the-8 -eightPlay B -eightRide -pauseAt 0.20
  # 01 The Physics Lens on the opening break, held on a headline beat with its equation (the opening's slow replay;
  #    the same wait the Lens frame has always used, to be checked against 0.7.0's held beats when the set is re-shot).
  shot 10 "$out/01-lens.png"       -noTitle
  # 02 Eight-ball against the medium computer, mid-game, with its "Why that shot" card open.
  shot 8  "$out/02-match.png"      -storeMatch
  # 03 A lesson held on its key moment with its target band up (lesson 3 of 6, draw: the cue ball comes back).
  shot 7  "$out/03-lesson.png"     -storeLesson 3
  # 04 Behind the 8-Ball's full massé, made as called, with its "On a real table" card and the cloth's numbers.
  #    (Until 0.7.10 this was taken first, bug plan item 54: the folding-phone set uploaded before the physics retune
  #    stated old numbers. To retake it alone: SCENES="04" scripts/store-shots.sh <duo id> duo-inner ...)
  shot 26 "$out/04-real-table.png" -eight masse-for-the-win -eightPlay B -eightRealTable
  # 05 A two-player eight-ball ruling card after a foul: ball in hand.
  shot 8  "$out/05-ruling.png"     -storeRuling
  # 06 The straight-stroke drill with a measured stroke on its card (power is swing speed).
  shot 7  "$out/06-drill.png"      -storeDrill
  # 07 Two of the surfaces, framed side by side.
  shot 7  "$out/07a-ice.png"       -optionSurface ice -trickAim stop-dead
  shot 7  "$out/07b-moon.png"      -optionSurface moon -trickAim masse-curve
  # 09 A Ride replay held where the room and the lamp show.
  shot 7  "$out/09-ride.png"       -storeRide
done
xcrun simctl terminate "$device" com.voynichlabs.breakdown >/dev/null 2>&1 || true
