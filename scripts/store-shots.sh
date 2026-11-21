#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Take the raw App Store screenshots for one simulator in any number of languages. Each scene is the app opened
#          straight into one of its best moments by its own launch flags (store-shot.sh does one capture). The raw
#          shots land on the big drive, in raw/<device name>/<language>/<scene>.png; store/screenshots/compose.swift
#          then frames them with the headlines in store/screenshots/captions.json.
#          Usage: [SCENES="06 07a"] [DEVICE_LOCALE=1] store-shots.sh <device id> <device name> <language> [language...]
#          The app must already be installed on that simulator.
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
  # 01 Behind the 8-Ball: the cue ball in the air over the 8, from the ride camera.
  shot 7  "$out/01-jump.png"       -eight tucked-behind-the-8 -eightPlay B -eightRide -pauseAt 0.20
  # 02 The call made (the 3, foot-left corner) and the cue raised for the jump.
  shot 6  "$out/02-call.png"       -eight tucked-behind-the-8 -eightAim B
  # 03 A full massé on tournament cloth, made as called: the gold-medal scorecard.
  shot 16 "$out/03-score.png"      -eight masse-for-the-win -eightPlay B
  # 04 The same shot's "On a real table" card, with the cloth's numbers.
  shot 16 "$out/04-real-table.png" -eight masse-for-the-win -eightPlay B -eightRealTable
  # 05 The Physics Lens explaining the opening break.
  shot 10 "$out/05-lens.png"       -noTitle
  # 06 The Long Bridge Draw lined up: the 3D cue resting on the bridge.
  shot 7  "$out/06-bridge.png"     -trickAim bridge-draw
  # 07 Two of the surfaces, framed side by side.
  shot 7  "$out/07a-ice.png"       -optionSurface ice -trickAim stop-dead
  shot 7  "$out/07b-moon.png"      -optionSurface moon -trickAim masse-curve
  # 08 The three new tables, framed side by side.
  shot 6  "$out/08a-bumper.png"    -optionTable bumperPool -aimDemoRack
  shot 6  "$out/08b-fivepin.png"   -optionTable fivePin -aimDemoRack
  shot 6  "$out/08c-bar.png"       -optionTable barBilliards -aimDemoRack
  # 09 The trick-shot list, over a trick's table (over the main menu, the menu shows beside the sheet on iPad).
  shot 6  "$out/09-tricks.png"     -trick called-break -trickList
  # 10 The Behind the 8-Ball list, over a situation's table.
  shot 6  "$out/10-situations.png" -eight tucked-behind-the-8 -eightList
done
xcrun simctl terminate "$device" com.voynichlabs.breakdown >/dev/null 2>&1 || true
