#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 23-November-2026
# PURPOSE: Re-encodes the App Store preview clips (filmed by the game's own clip maker in the store size, 886 by 1920)
#          to the settings Apple's preview page asks for: H.264 High profile at about 10 Mbit/s, 30 frames a second,
#          stereo AAC at 256 kbit/s and 48 kHz, in a .mov, between 15 and 30 seconds. A clip outside that length is
#          refused here rather than at Apple.
#          Usage: scripts/store-preview-encode.sh  (reads store-previews/<language>/<shot>.mov, writes
#          store-previews/final/<language>/<n>-<shot>.mov in the order below)
# SRP/DRY check: Pass - the only preview encoder; scripts/store-preview-upload.py sends what this writes.
set -eu
root="/Volumes/Team 4TB/breakdown-build/store-previews"
[[ -d $root ]] || { echo "No previews filmed at $root."; exit 1 }
shots=(jump-over masse-curve two-rail-kick)
for dir in "$root"/*(/); do
  lang=${dir:t}
  [[ $lang == final ]] && continue
  mkdir -p "$root/final/$lang"
  n=1
  for shot in $shots; do
    src="$dir/$shot.mov"
    [[ -f $src ]] || { echo "$lang: $shot missing"; continue }
    length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$src")
    if (( length < 15 || length > 30 )); then echo "$lang: $shot is $length s, outside 15 to 30; skipped"; continue; fi
    ffmpeg -loglevel error -y -i "$src" -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 \
      -b:v 10M -maxrate 12M -bufsize 20M -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart \
      "$root/final/$lang/$n-$shot.mov"
    echo "$lang: $n-$shot ($length s)"
    n=$((n + 1))
  done
done
