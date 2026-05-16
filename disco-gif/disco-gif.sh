#!/bin/bash

shopt -s nocasematch

VIDEO_LINK="$1"
VIDEO_NAME="$(basename $VIDEO_LINK)"

GIF_NAME="${VIDEO_NAME%.*}.gif"
GIF_DEST="$HOME/media/$GIF_NAME"

TMP_PATH="$(mktemp -d /tmp/disco-gif.XXXXXX)"

VIDEO_DEST="$TMP_PATH/$VIDEO_NAME"
PALLETE_PATH="$TMP_PATH/palette.png"

if [ -z "$VIDEO_LINK" ]; then
    echo "[ERROR] No gif link provided. Aborting."
    exit 1
fi

if ! [[ $VIDEO_NAME =~ .*\.(mp4|mov|mkv|avi|webm)$ ]]; then
    echo "[ERORR] Unsupported file format. Aborting."
    exit 1
fi

echo "Downloading the video"
wget -q "$VIDEO_LINK" -O "$VIDEO_DEST"

echo "Creating palette"
ffmpeg -hide_banner -loglevel error -i "$VIDEO_DEST" -vf "fps=10,scale=320:-1:flags=lanczos,palettegen" "$PALLETE_PATH"
echo "Converting video to gif"
ffmpeg -hide_banner -loglevel error -i "$VIDEO_DEST" -i "$PALLETE_PATH" -filter_complex "fps=10,scale=320:-1:flags=lanczos[x];[x][1:v]paletteuse" "$GIF_DEST"
echo "Done"
