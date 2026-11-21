#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Record the gameplay video for the App Store preview and for sharing. Each clip is the app opened straight
#          into one of its best moments by its own launch flags (the same pinned, clean launch as the screenshots, via
#          store-shot.sh's settings), recorded from the simulator screen. scripts/store-video-cut.sh then trims the clips,
#          joins them and lays the title music under them.
#          Usage: [CLIPS="02 05"] store-video.sh <device id> <language> [language...]
#          Clips land in /Volumes/Team 4TB/breakdown-build/store-video/clips/<language>/NN-name.mp4.
# SRP/DRY check: Pass - recording only; cutting is store-video-cut.sh. The launch and its pinned settings are
#          store-shot.sh's (called with --launch-only), not a copy.
set -e
here=${0:A:h}
device=$1; shift
root="/Volumes/Team 4TB/breakdown-build/store-video/clips"
[[ -d "/Volumes/Team 4TB" ]] || { echo "The Team 4TB drive is not mounted."; exit 1 }
xcrun simctl status_bar "$device" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true

# clip <seconds> <output> [launch flags...]: start recording, launch the scene, stop after the given time.
# CLIPS="02 05" limits a run to those clips (by file-name prefix), to re-record a few.
clip() {
  local secs=$1 out=$2; shift 2
  local name=${out:t}
  if [[ -n $CLIPS ]] && [[ " $CLIPS " != *" ${name%%-*} "* ]]; then return; fi
  mkdir -p "${out:h}"
  xcrun simctl terminate "$device" com.voynichlabs.breakdown >/dev/null 2>&1 || true
  sleep 0.5
  xcrun simctl io "$device" recordVideo --codec=h264 --force "$out" >/dev/null 2>&1 &
  local rec=$!
  sleep 0.8
  "$here/store-shot.sh" --launch-only "$device" "$lang" "$@"
  sleep "$secs"
  kill -INT $rec; wait $rec 2>/dev/null || true
  echo "$out"
}

for lang in "$@"; do
  out="$root/$lang"
  # 01 Behind the 8-Ball: the jump over the 8, from the ride camera.
  clip 9  "$out/01-jump.mp4"    -eight tucked-behind-the-8 -eightPlay B -eightRide
  # 02 A full massé on tournament cloth from the ride camera, made as called, to the gold-medal scorecard.
  clip 20 "$out/02-masse.mp4"   -eight masse-for-the-win -eightPlay B -eightRide
  # 03 The opening break, freezing and melting into the Physics Lens.
  clip 16 "$out/03-lens.mp4"    -noTitle
  # 04 The Long Bridge Draw, played off the bridge.
  clip 10 "$out/04-bridge.mp4"  -trickPlay bridge-draw
  # 05 The massé on the Moon.
  clip 10 "$out/05-moon.mp4"    -optionSurface moon -trickPlay masse-curve
  # 07 The five-pin opening (bar billiards' opening is over too fast to read on video).
  clip 7  "$out/07-fivepin.mp4" -optionTable fivePin -aimDemoRack -rackShoot
  # 08 The main menu, for the closing shot.
  clip 6  "$out/08-title.mp4"
done
xcrun simctl terminate "$device" com.voynichlabs.breakdown >/dev/null 2>&1 || true
