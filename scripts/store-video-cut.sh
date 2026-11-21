#!/bin/zsh
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Cut the gameplay video from the clips store-video.sh recorded. Each beat below is one stretch of one clip
#          (start and end in seconds, chosen by looking at the clips frame by frame); they are joined with hard cuts and
#          the game's own title music ("Pool Table Take", App/Audio) is laid under them, fading out at the end.
#          Two files per language, in /Volumes/Team 4TB/breakdown-build/store-video/final/<language>/:
#            app-preview-iphone-6.9.mp4  886x1920, 30 fps, under 30 seconds: the App Store preview size for 6.9" iPhones
#            breakdown-gameplay.mp4      1080x2346, 30 fps: the same cut at higher resolution, for the site and sharing
#          Usage: store-video-cut.sh <language> [language...]
# SRP/DRY check: Pass - cutting only; recording is store-video.sh. The beat times live here and nowhere else.
set -e
here=${0:A:h}
clips="/Volumes/Team 4TB/breakdown-build/store-video/clips"
final="/Volumes/Team 4TB/breakdown-build/store-video/final"
music="$here/../App/Audio/PoolTableTake.mp3"
[[ -d "/Volumes/Team 4TB" ]] || { echo "The Team 4TB drive is not mounted."; exit 1 }

# clip  start end   - what the viewer sees
beats=(
  01-jump    JUMP 4.2 # Behind the 8-Ball: the cue ball jumps the 8, ride camera (start per language, below)
  02-masse   4.75 8.7 # the full massé on tournament cloth, ride camera (after the camera's fade)
  02-masse  16.65 19.0 # made as called: the gold-medal scorecard, once fully faded in
  03-lens    3.0 8.8   # the break freezes and melts into the Physics Lens
  04-bridge  3.5 7.5   # the Long Bridge Draw off the bridge
  05-moon    3.4 6.8   # the massé on the Moon, after its fade from black
  07-fivepin 3.8 6.3   # the five-pin opening
  08-title   4.4 6.9   # the main menu to close
)
# The ride camera reaches the cloth at a slightly different moment in each language's recording (launch timing), so
# the jump beat starts where each clip's ride view begins, found frame by frame; it always lasts 4.2 seconds.
typeset -A jump_start=(en 4.4 es 5.0 fr 4.4 de 4.4 it 4.4 pt 4.4 pt-BR 4.4 ja 4.4 ko 4.4 zh-Hans 4.6 ru 4.8 ar 4.4)

for lang in "$@"; do
  inputs=(); filters=""; labels=""; n=0; total=0
  for (( i = 1; i <= ${#beats}; i += 3 )); do
    name=${beats[i]}; s=${beats[i+1]}; e=${beats[i+2]}
    if [[ $s == JUMP ]]; then s=${jump_start[$lang]:-3.8}; e=$(( s + e )); fi
    inputs+=(-i "$clips/$lang/$name.mp4")
    filters+="[${n}:v]trim=start=${s}:end=${e},setpts=PTS-STARTPTS,fps=30,scale=1080:-2:flags=lanczos,setsar=1[v$n];"
    labels+="[v$n]"
    total=$(( total + e - s )); n=$(( n + 1 ))
  done
  fade=$(( total - 1.5 ))
  out="$final/$lang"; mkdir -p "$out"
  filters+="${labels}concat=n=$n:v=1:a=0[v];[${n}:a]atrim=0:${total},afade=t=out:st=${fade}:d=1.5,volume=0.9[a];[v]fade=t=out:st=$(( total - 0.6 ))\:d=0.6[vf]"
  # The full-resolution cut (1080 wide keeps the phone's shape), then the store preview from it.
  ffmpeg -v error -y "${inputs[@]}" -i "$music" -filter_complex "$filters" -map "[vf]" -map "[a]" \
    -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 16 -preset slow -c:a aac -b:a 256k -ar 44100 -ac 2 \
    -movflags +faststart "$out/breakdown-gameplay.mp4"
  # App Store preview for 6.9-inch iPhones: exactly 886x1920 (the phone's shape is 886x1925, so 2-3 rows are trimmed).
  ffmpeg -v error -y -i "$out/breakdown-gameplay.mp4" -vf "scale=886:-2:flags=lanczos,crop=886:1920,setsar=1" \
    -r 30 -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -b:v 10M -maxrate 12M -bufsize 20M \
    -c:a aac -b:a 256k -ar 44100 -ac 2 -movflags +faststart "$out/app-preview-iphone-6.9.mp4"
  printf "%s: %.1f seconds\n" "$lang" "$total"
done
