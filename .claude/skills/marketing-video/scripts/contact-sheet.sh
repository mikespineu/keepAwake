#!/usr/bin/env bash
# Extracts frames from a rendered video and puts them side by side, so they can be checked at a glance.
# Usage: contact-sheet.sh <video.mp4> <frame> [<frame> ...]   (OUT=/path/sheet.png to choose the output)
set -euo pipefail

video="$1"; shift
out="${OUT:-/tmp/contact-sheet.png}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

inputs=()
for frame in "$@"; do
	ffmpeg -loglevel error -y -i "$video" -vf "select=eq(n\,$frame),scale=540:-1" -vframes 1 "$tmp/$frame.png"
	inputs+=(-i "$tmp/$frame.png")
done

if [ "$#" -eq 1 ]; then
	cp "$tmp/$1.png" "$out"
else
	ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex "hstack=inputs=$#" "$out"
fi
echo "$out"
