#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: The cheapest guard against a broken screen. Opens Breakdown on ONE simulator once per App Store screenshot
#          scene, each straight into its moment by the app's own launch flags, and fails if the app quits or crashes
#          within a few seconds, or logs an error of its own, or prints a self-check FAIL. Scenes run one after another,
#          never in parallel. The scene list is not copied: it is read from the "shot" lines of scripts/store-shots.sh,
#          and every launch goes through scripts/store-shot.sh --launch-only, so the pinned settings, the language and
#          the muted sound are exactly the screenshot run's.
#          Usage: scripts/smoke-test.sh <simulator id> [seconds per scene, default 6]
#          The simulator must be booted and the app installed on it (build and install first; this script never builds).
#          Output: one line per scene, PASS or FAIL with the reason; each scene's captured log is kept under
#          /Volumes/Team 4TB/breakdown-build/smoke/<date-time>/<scene>.log. Exit 0 only when every scene passed.
#          What counts as an error: the process gone before the time is up (a crash or an exit), a message of error or
#          fault level sent by the app's own code (the app binary, which includes the physics package), any message
#          containing "Fatal error" (a Swift trap), or a self-check verdict "-> FAIL". Errors and faults logged by
#          system frameworks inside the app (audio, graphics) are not counted: the simulator produces them on every
#          launch, so counting them would fail every scene.
# SRP/DRY check: Pass - checked scripts/store-shot.sh (one launch or capture, reused here) and scripts/store-shots.sh
#          (the scene list, read here). This script only launches, watches and reports.
set -u
here=${0:A:h}
device=${1:?usage: smoke-test.sh <simulator id> [seconds per scene]}
seconds=${2:-6}
bundle=com.voynichlabs.breakdown
[[ -d "/Volumes/Team 4TB" ]] || { echo "The Team 4TB drive is not mounted."; exit 1 }
out="/Volumes/Team 4TB/breakdown-build/smoke/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

# The scenes: every "shot <wait> "$out/<name>.png" <flags...>" line in store-shots.sh. Field 3 is the picture's path
# (its file name, without .png, names the scene); everything after it is the launch flags.
scenes=("${(@f)$(grep -E '^[[:space:]]*shot[[:space:]]+[0-9]+' "$here/store-shots.sh")}")
(( ${#scenes} > 0 )) || { echo "No scenes found in store-shots.sh."; exit 1 }

# The app's process id on the simulator, from the simulator's launchd list ("-" or nothing when it is not running).
app_pid() {
  xcrun simctl spawn "$device" launchctl list 2>/dev/null | awk -v b="UIKitApplication:$bundle" 'index($3, b) == 1 { print $1; exit }'
}

failed=0
for line in "${scenes[@]}"; do
  words=(${(z)line})
  name=${words[3]//\"/}
  name=${${name:t}%.png}
  flags=("${(@)words[4,-1]}")
  log="$out/$name.log"
  # Watch the app's log from before the launch, so nothing printed at start-up is missed. The predicate keeps only
  # what this check judges by; the full stream would be mostly system chatter.
  xcrun simctl spawn "$device" log stream --style compact --level debug --predicate \
    'process == "Breakdown" AND (((messageType == error OR messageType == fault) AND senderImagePath CONTAINS "Breakdown.app") OR eventMessage CONTAINS "Fatal error" OR eventMessage CONTAINS "-> FAIL")' \
    > "$log" 2>&1 &
  watcher=$!
  sleep 1
  reason=""
  if ! "$here/store-shot.sh" --launch-only "$device" en "${flags[@]}"; then
    reason="the launch itself failed"
  else
    sleep 1
    pid=$(app_pid)
    [[ -z $pid || $pid == "-" ]] && reason="not running a second after launch"
    # Check every second that it is still the same running process for the rest of the wait.
    for (( s = 1; s < seconds; s++ )); do
      [[ -n $reason ]] && break
      sleep 1
      now=$(app_pid)
      [[ $now != $pid ]] && reason="quit or crashed after about $(( s + 1 )) seconds"
    done
  fi
  kill $watcher 2>/dev/null; wait $watcher 2>/dev/null
  # log stream prints a "Filtering the log data..." banner first; any other line is a matching message.
  hits=$(grep -v -e '^Filtering the log data' -e '^Timestamp' "$log" | grep -c .)
  if [[ -z $reason && $hits -gt 0 ]]; then reason="$hits error line(s) in the log"; fi
  if [[ -z $reason ]]; then
    echo "PASS $name"
  else
    echo "FAIL $name: $reason (log: $log)"
    failed=$(( failed + 1 ))
  fi
done
xcrun simctl terminate "$device" $bundle >/dev/null 2>&1 || true
echo "$(( ${#scenes} - failed )) of ${#scenes} scenes passed."
(( failed == 0 ))
