#!/bin/zsh
# Author: Claude Opus 5.5 Medium
# Date: 26-November-2026
# PURPOSE: Take the raw App Store screenshots for the Mac (the APP_DESKTOP set, 2880 x 1800) in any number of languages.
#          The Mac has no simulator, so each scene is the built Mac app itself opened on this desktop by the same launch
#          flags store-shots.sh uses for the phone and iPad, its game window set to 1440 x 900 points (the store size's
#          16:10 shape, 2880 x 1800 on a Retina screen), captured alone by window number (screencapture -l, no shadow) and the app quit again.
#          The raw shots land on the big drive, in raw/mac/<language>/<scene>.png, where store/screenshots/compose.swift
#          frames them like every other device.
#          Usage: [SCENES="11 12"] store-shots-mac.sh <path to Breakdown.app> <language> [language...]
#          Build the app first, for example (unsigned is fine for local shots):
#            xcodebuild -project Breakdown.xcodeproj -scheme Breakdown -configuration Release -destination \
#              'generic/platform=macOS' -derivedDataPath "/Volumes/Team 4TB/breakdown-build/store-dd-081-mac" \
#              CODE_SIGNING_ALLOWED=NO build
#          Needs Screen Recording allowed for the terminal that runs it. Opens game windows on the screen in use while
#          it runs, so choose a quiet moment; a Retina screen gives the sharper (2x) capture. Tried and dropped: moving
#          the window with System Events (needs Accessibility, which this Mac does not give the terminal).
# Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 pictures: the window is 1440 x 900 points. The stored frame
#          must name the visible frame of a real screen (here the second, Retina one) or the app opens no window at all;
#          macOS still opens it on the screen in use, keeping only its offset and size. MAC_FRAME overrides it.)
# SRP/DRY check: Pass - the Mac capture only. The scene list and its waits are the same as scripts/store-shots.sh and
#          the pinned settings the same as scripts/store-shot.sh (both repeated here because those drive a simulator
#          through simctl, which cannot launch a Mac app); keep the three in step. Framing is compose.swift, uploading
#          scripts/store-upload.py mac.
set -e
app=${1:A}; shift
bin="$app/Contents/MacOS/Breakdown"
root="/Volumes/Team 4TB/breakdown-build/store-shots/raw/mac"
[[ -d "/Volumes/Team 4TB" ]] || { echo "The Team 4TB drive is not mounted."; exit 1 }
[[ -x $bin ]] || { echo "No Mac app at $app"; exit 1 }

# The window's size and place. The app restores its window from the stored value its WindowFrameMemory
# (App/MacChrome.swift) saves under "NSWindow Frame BreakdownGameWindow" ("x y w h" of the window, then the visible frame
# of the screen it was on). Handing that value over on the launch line instead leaves the app with no window at all, so
# it is written to the stored settings of the unsigned build (its own preferences file outside any sandbox container,
# so the Boss's installed copy is never touched) and the earlier value is put back when the run ends.
# The window is 1440 x 900 points, the Mac store size's own 16:10 shape. macOS opens it on whichever screen is in use
# (it keeps only the offset and size from the value), so the capture is 2880 x 1800 pixels on a Retina screen and
# 1440 x 900 on an ordinary one; compose.swift scales either into the 2880 x 1800 frame.
prefs=~/Library/Preferences/com.voynichlabs.breakdown.plist
key="NSWindow Frame BreakdownGameWindow"
old_frame=$(defaults read "$prefs" "$key" 2>/dev/null || true)
put_back() {
  if [[ -n $old_frame ]]; then defaults write "$prefs" "$key" "$old_frame"; else defaults delete "$prefs" "$key" >/dev/null 2>&1 || true; fi
}
trap put_back EXIT
frame="${MAC_FRAME:-2160 75 1440 900 1920 0 1920 1050 }"

# The Breakdown window owned by one process: its window number, for screencapture -l. Layer 0 is an ordinary window
# (the menu bar and the Dock are other layers); the largest one is the game window, not a sheet or a tooltip.
window_of() {
  swift -e "import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let mine = list.filter { (\$0[kCGWindowOwnerPID as String] as? Int) == $1 && (\$0[kCGWindowLayer as String] as? Int) == 0 }
func area(_ w: [String: Any]) -> Double { let b = w[kCGWindowBounds as String] as? [String: Double] ?? [:]; return (b[\"Width\"] ?? 0) * (b[\"Height\"] ?? 0) }
if let w = mine.max(by: { area(\$0) < area(\$1) }) { print(w[kCGWindowNumber as String] as? Int ?? 0) }" 2>/dev/null
}

# The settings pinned for every shot, as scripts/store-shot.sh pins them on the simulator (see the reasons there).
pins=(-aimHintSeen '<true/>' -eightBallBest '<dict/>' -eightBallMedals '<dict/>' -trickShotsDone '' -lessonsDone ''
      -seenOpening '<true/>' -lensTipsSeen '<true/>' -equipmentCardPulses '<integer>3</integer>'
      -notebookPanelShown '<true/>' -matchRecord '<data>eyJieUtpbmQiOnt9LCJieUxldmVsIjp7fX0=</data>')

for lang in "$@"; do
  out="$root/$lang"
  case $lang in
    en) loc=en_US ;; pt-BR) loc=pt_BR ;; pt) loc=pt_PT ;; zh-Hans) loc=zh_CN ;; ar) loc=ar_SA ;;
    ja) loc=ja_JP ;; ko) loc=ko_KR ;; *) loc=${lang}_${(U)lang} ;;
  esac
  # One capture: launch, wait for the scene to settle, save the window, quit. SCENES works as in store-shots.sh.
  shot() {
    local wait=$1 file=$2; shift 2
    local name=${file:t}
    if [[ -n $SCENES ]] && [[ " $SCENES " != *" ${name%%-*} "* ]]; then return; fi
    pkill -f "$bin" >/dev/null 2>&1 || true; sleep 1
    # A game left halfway is a file, not a setting. An unsigned build is not sandboxed, so it lives in the user's own
    # Application Support folder (a signed copy keeps its games in its container, which this never touches).
    rm -f ~/Library/"Application Support"/Breakdown/match.json
    local extra=()
    (( ${@[(Ie)-optionSurface]} )) || extra+=(-optionSurface cloth)
    (( ${@[(Ie)-optionTable]} || ${@[(Ie)-storeTableGame]} )) || extra+=(-optionTable standard)
    # Opened through Launch Services (open -n): the binary started straight from a shell runs but never gets a
    # window on this desktop. Its process is then found by its path.
    # The app saves its frame again when it closes, so the size is written before every launch.
    defaults write "$prefs" "$key" "$frame"
    open -n "$app" --args -muteSound -AppleLanguages "($lang)" -AppleLocale "$loc" "${pins[@]}" "${extra[@]}" "$@"
    sleep "$wait"
    local pid=$(pgrep -f "$bin" | head -1)
    local id=$(window_of $pid)
    mkdir -p "$out"
    if [[ -n $id && $id != 0 ]]; then
      screencapture -x -o -l "$id" "$file"
      echo "$file $(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixel/{printf "%s ", $2}')"
    else
      echo "warning: no Breakdown window for $file"
    fi
    [[ -n $pid ]] && kill $pid >/dev/null 2>&1 || true
  }
  # The scenes, in the store page's order, with the same flags and waits as scripts/store-shots.sh.
  shot 8  "$out/11-lens-bumper.png" -storeLensBumper
  shot 8  "$out/12-strike.png"     -storeStrike
  shot 8  "$out/13-daily.png"      -storeDaily
  shot 8  "$out/08a-bumper.png"    -storeTableGame bumperPool
  shot 8  "$out/08b-fivepin.png"   -storeTableGame fivePin
  shot 8  "$out/08c-bar.png"       -storeTableGame barBilliards
  shot 7  "$out/10-jump.png"       -eight tucked-behind-the-8 -eightPlay B -eightRide -pauseAt 0.20
  shot 10 "$out/01-lens.png"       -noTitle
  shot 8  "$out/02-match.png"      -storeMatch
  shot 7  "$out/03-lesson.png"     -storeLesson 3
  shot 16 "$out/04-real-table.png" -eight masse-for-the-win -eightPlay B -eightRealTable
  shot 8  "$out/05-ruling.png"     -storeRuling
  shot 7  "$out/06-drill.png"      -storeDrill
  shot 7  "$out/07a-ice.png"       -optionSurface ice -trickAim stop-dead
  shot 7  "$out/07b-moon.png"      -optionSurface moon -trickAim masse-curve
  shot 7  "$out/09-ride.png"       -storeRide
done
pkill -f "$bin" >/dev/null 2>&1 || true
