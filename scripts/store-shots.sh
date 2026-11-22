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
    "$here/store-shot.sh" "$device" "$lang" "$@"
  }
  # The scenes are the app's own launch flags. The six -store flags (StoreScene in App/ShowpieceModel.swift) open their
  # scene straight away and hold it still, so they wait as long as the still aim scenes always have (6 to 8 seconds:
  # the launch, the table's first frame and, for a match or a ruling, the shot that leads to it being solved).
  #
  # 04 first, on purpose (bug plan item 54): the "On a real table" card states the shot's aim, speed and tip and the
  # cloth's numbers, and the set already uploaded for the folding phone shows numbers from before the physics retune.
  # Re-shoot and re-upload this frame before any other: SCENES="04" scripts/store-shots.sh <duo id> duo-inner ...
  # 04 Behind the 8-Ball's full massé, made as called, with its "On a real table" card and the cloth's numbers.
  shot 16 "$out/04-real-table.png" -eight masse-for-the-win -eightPlay B -eightRealTable
  # 01 The Physics Lens on the opening break, held on a headline beat with its equation (the opening's slow replay;
  #    the same wait the Lens frame has always used, to be checked against 0.7.0's held beats when the set is re-shot).
  shot 10 "$out/01-lens.png"       -noTitle
  # 02 Eight-ball against the medium computer, mid-game, with its "Why that shot" card open.
  shot 8  "$out/02-match.png"      -storeMatch
  # 03 A lesson held on its key moment with its target band up (lesson 3 of 6, draw: the cue ball comes back).
  shot 7  "$out/03-lesson.png"     -storeLesson 3
  # 05 A two-player eight-ball ruling card after a foul: ball in hand.
  shot 8  "$out/05-ruling.png"     -storeRuling
  # 06 The straight-stroke drill with a measured stroke on its card (power is swing speed).
  shot 7  "$out/06-drill.png"      -storeDrill
  # 07 Two of the surfaces, framed side by side.
  shot 7  "$out/07a-ice.png"       -optionSurface ice -trickAim stop-dead
  shot 7  "$out/07b-moon.png"      -optionSurface moon -trickAim masse-curve
  # 08 The three other tables, each a scored game halfway through, framed side by side.
  shot 8  "$out/08a-bumper.png"    -storeTableGame bumperPool
  shot 8  "$out/08b-fivepin.png"   -storeTableGame fivePin
  shot 8  "$out/08c-bar.png"       -storeTableGame barBilliards
  # 09 A Ride replay held where the room and the lamp show.
  shot 7  "$out/09-ride.png"       -storeRide
  # 10 Behind the 8-Ball: the cue ball in the air over the 8, from the ride camera.
  shot 7  "$out/10-jump.png"       -eight tucked-behind-the-8 -eightPlay B -eightRide -pauseAt 0.20
done
xcrun simctl terminate "$device" com.voynichlabs.breakdown >/dev/null 2>&1 || true
