#!/bin/bash
### NVIDIA GPU MONITORS NAMES (but using AMD GPU for rendering)

# Wayland environment (needed when running from cron)
export WAYLAND_DISPLAY=wayland-1
export XDG_RUNTIME_DIR=/run/user/1000

killall mpvpaper 2>/dev/null
rm -f /tmp/mpv-socket-DP-2 /tmp/mpv-socket-HDMI-A-1 /tmp/mpv-socket-DP-1 2>/dev/null

# Configuration
WALLPAPER_DIR="$HOME/wallpapers"
CACHE_FILE="$HOME/.cache/wallpaper-brightness.json"
CLASSIFIER="$HOME/bin/classify_wallpapers.sh"

# 1. Ensure wallpaper cache is up to date
if [ ! -f "$CACHE_FILE" ]; then
    # No cache exists, run full classification
    "$CLASSIFIER"
else
    # Check for new wallpapers not in cache
    NEEDS_UPDATE=false
    for file in "$WALLPAPER_DIR"/*.mp4 "$WALLPAPER_DIR"/*.webm; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        if ! jq -e --arg f "$filename" '.[$f]' "$CACHE_FILE" >/dev/null 2>&1; then
            NEEDS_UPDATE=true
            break
        fi
    done
    if [ "$NEEDS_UPDATE" = true ]; then
        "$CLASSIFIER"
    fi
fi

# 2. Determine time-based category (Mexico City timezone)
HOUR=$(TZ="America/Mexico_City" date +%H)
HOUR=$((10#$HOUR))  # Remove leading zero for arithmetic

if [ "$HOUR" -ge 8 ] && [ "$HOUR" -lt 18 ]; then
    CATEGORY="light"
else
    CATEGORY="dark"
fi

# 3. Pick a random wallpaper from the appropriate category
if [ -f "$CACHE_FILE" ]; then
    # Get list of wallpapers matching the category
    WALLPAPER_LIST=$(jq -r --arg cat "$CATEGORY" \
        'to_entries | map(select(.value.category == $cat)) | .[].key' "$CACHE_FILE")

    if [ -n "$WALLPAPER_LIST" ]; then
        # Pick random from category
        WALLPAPER="$WALLPAPER_DIR/$(echo "$WALLPAPER_LIST" | shuf -n1)"
    else
        # Fallback: no wallpapers in category, pick from all
        WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.webm" \) | shuf -n1)
    fi
else
    # Fallback: no cache, pick randomly
    WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.webm" \) | shuf -n1)
fi

# Log selection for debugging
echo "$(date): Selected $CATEGORY wallpaper: $(basename "$WALLPAPER")" >> /tmp/waypaper.log

# Force AMD GPU for mpvpaper with environment variables
export DRI_PRIME=1
export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi

# 2. Launch mpvpaper on ALL monitors using AMD
mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-DP-1 loop panscan=1.0 --mute=yes --background-color='#000000' hwdec=vaapi gpu-api=opengl" DP-1 "$WALLPAPER" &
mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-DP-2 loop panscan=1.0 --mute=yes --background-color='#000000' hwdec=vaapi gpu-api=opengl" DP-2 "$WALLPAPER" &
mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-HDMI-A-1 loop panscan=1.0 --mute=yes --background-color='#000000' hwdec=vaapi gpu-api=opengl" HDMI-A-1 "$WALLPAPER" &

# 3. Pause lateral monitors to make them static
# Wait for sockets to be created (up to 5 seconds)
for i in {1..50}; do
    if [ -S /tmp/mpv-socket-DP-2 ] && [ -S /tmp/mpv-socket-HDMI-A-1 ]; then
        break
    fi
    sleep 0.1
done

echo '{ "command": ["set_property", "pause", true] }' | socat - /tmp/mpv-socket-DP-2 2>/dev/null
echo '{ "command": ["set_property", "pause", true] }' | socat - /tmp/mpv-socket-HDMI-A-1 2>/dev/null
