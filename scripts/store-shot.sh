#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Take one App Store screenshot. Launches Breakdown on a booted simulator in the given language with the
#          given launch flags (the app's own test hooks: -eight, -eightPlay, -trickPlay, -pauseAt and so on), waits for
#          the scene to settle, and saves the screen as a PNG. scripts/store-shots.sh runs it over every scene, language
#          and device. Sound is always muted.
#          Usage: store-shot.sh <device id> <language> <seconds to wait> <output.png> [launch flags...]
#             or: store-shot.sh --launch-only <device id> <language> [launch flags...]
#          Language is an App Store code (en, de, pt-BR, zh-Hans...); the locale is set to match.
# Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (SIM_DISPLAY: capture one screen of the two-screen iPhone Duo simulator.)
# SRP/DRY check: Pass - one capture only. The scene list lives in store-shots.sh; the scenes themselves are the app's
#          own launch flags, not copies of its logic.
set -e
# --launch-only <device> <language> [flags...]: do the clean, pinned launch and return at once (store-video.sh uses it).
launch_only=0
if [[ $1 == --launch-only ]]; then launch_only=1; shift; device=$1; lang=$2; shift 2
else device=$1; lang=$2; wait=$3; out=$4; shift 4; fi
case $lang in
  en) locale=en_US ;; pt-BR) locale=pt_BR ;; pt) locale=pt_PT ;; zh-Hans) locale=zh_CN ;; ar) locale=ar_SA ;;
  ja) locale=ja_JP ;; ko) locale=ko_KR ;; *) locale=${lang}_${(U)lang} ;;
esac
xcrun simctl terminate "$device" com.voynichlabs.breakdown >/dev/null 2>&1 || true
# Every shot starts clean. Stored values are pinned from the launch line (the argument domain wins over anything a
# previous scene stored, which deleting does not reliably clear): cloth, the pool table, no scores, no trick progress,
# and the one-time aiming hint already seen. A scene's own -optionSurface or -optionTable replaces the default.
pins=(-aimHintSeen '<true/>' -eightBallBest '<dict/>' -eightBallMedals '<dict/>' -trickShotsDone '')
(( ${@[(Ie)-optionSurface]} )) || pins+=(-optionSurface cloth)
(( ${@[(Ie)-optionTable]} )) || pins+=(-optionTable standard)
xcrun simctl launch "$device" com.voynichlabs.breakdown -muteSound -AppleLanguages "($lang)" -AppleLocale "$locale" "${pins[@]}" "$@" >/dev/null
(( launch_only )) && exit 0
sleep "$wait"
mkdir -p "${out:h}"
# SIM_DISPLAY picks one screen of a two-screen simulator (the iPhone Duo: 3 is the inner display, 1 the outer one).
xcrun simctl io "$device" screenshot ${SIM_DISPLAY:+--display=$SIM_DISPLAY} "$out" >/dev/null 2>&1
echo "$out"
