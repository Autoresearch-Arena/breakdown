#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Builds and runs the camera framing check (main.swift here, with App/CameraFraming.swift and
#          App/NotebookGeometry.swift) as a small Mac command-line program. The program is written to the Team 4TB
#          build drive, never the internal drive; the check prints PASS or FAIL and exits non-zero on FAIL.
# SRP/DRY check: Pass - build-and-run only; the checks are in main.swift and CameraFraming.fitProblems.
set -euo pipefail
here="${0:A:h}"
repo="${here:h:h}"
out="/Volumes/Team 4TB/breakdown-build/framing-check"
if [[ ! -d "/Volumes/Team 4TB" ]]; then
  echo "The Team 4TB drive is not mounted; not building onto the internal drive." >&2
  exit 2
fi
mkdir -p "$out"
xcrun swiftc -O -o "$out/framing-check" "$here/main.swift" "$repo/App/CameraFraming.swift" "$repo/App/NotebookGeometry.swift"
"$out/framing-check"
