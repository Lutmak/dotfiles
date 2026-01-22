#!/bin/bash
# Classify wallpapers by brightness using ffmpeg
# Outputs/updates JSON cache at ~/.cache/wallpaper-brightness.json

WALLPAPER_DIR="$HOME/wallpapers"
CACHE_FILE="$HOME/.cache/wallpaper-brightness.json"
BRIGHTNESS_THRESHOLD=100

# Ensure cache directory exists
mkdir -p "$(dirname "$CACHE_FILE")"

# Initialize cache if it doesn't exist
if [ ! -f "$CACHE_FILE" ]; then
    echo "{}" > "$CACHE_FILE"
fi

# Load existing cache
CACHE=$(cat "$CACHE_FILE")

# Find all video wallpapers using process substitution to avoid subshell
while read -r filepath; do
    [ -z "$filepath" ] && continue
    filename=$(basename "$filepath")

    # Check if already cached
    if echo "$CACHE" | jq -e --arg f "$filename" '.[$f]' >/dev/null 2>&1; then
        continue
    fi

    # Extract brightness using ffmpeg
    # -ss 1: seek to 1 second (avoid black intro frames)
    # scale=1:1: average all pixels into one
    # rawvideo rgb24: get raw RGB bytes
    RGB=$(ffmpeg -ss 1 -i "$filepath" -vf "scale=1:1:sws_flags=area" \
          -frames:v 1 -f rawvideo -pix_fmt rgb24 - 2>/dev/null | xxd -p)

    if [ -z "$RGB" ] || [ ${#RGB} -lt 6 ]; then
        echo "Warning: Could not analyze $filename" >&2
        continue
    fi

    R=$((16#${RGB:0:2}))
    G=$((16#${RGB:2:2}))
    B=$((16#${RGB:4:2}))
    BRIGHTNESS=$(( (R + G + B) / 3 ))

    if [ "$BRIGHTNESS" -gt "$BRIGHTNESS_THRESHOLD" ]; then
        CATEGORY="light"
    else
        CATEGORY="dark"
    fi

    echo "Classified: $filename -> brightness=$BRIGHTNESS, category=$CATEGORY" >&2

    # Update cache
    CACHE=$(echo "$CACHE" | jq --arg f "$filename" \
                               --argjson b "$BRIGHTNESS" \
                               --arg c "$CATEGORY" \
                               '. + {($f): {"brightness": $b, "category": $c}}')
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.webm" \))

# Write updated cache
echo "$CACHE" | jq '.' > "$CACHE_FILE"

echo "Cache updated at $CACHE_FILE"
