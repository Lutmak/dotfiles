#!/bin/bash
### AMD GPU MONITORS NAMES
killall mpvpaper 2>/dev/null
rm -f /tmp/mpv-socket-DP-5 /tmp/mpv-socket-HDMI-A-3 /tmp/mpv-socket-DP-4 2>/dev/null
# 1. Set random wallpaper on main monitor
waypaper --random --monitor DP-4

# 2. Get the wallpaper for DP-4 (2nd position in the comma-separated list)
MAIN_WALLPAPER=$(grep "wallpaper = " ~/.config/waypaper/config.ini | cut -d'=' -f2 | cut -d',' -f2 | sed 's/^ *//')

# 3. Set same wallpaper on lateral monitors using direct mpvpaper
mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-DP-5 loop panscan=1.0 --mute=yes --background-color='#000000'" DP-5 "$MAIN_WALLPAPER" &
mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-HDMI-A-3 loop panscan=1.0 --mute=yes --background-color='#000000'" HDMI-A-3 "$MAIN_WALLPAPER" &

# 4. Pause lateral monitors to make them static
sleep .3
echo 'set pause yes' | socat - /tmp/mpv-socket-DP-5 2>/dev/null &
echo 'set pause yes' | socat - /tmp/mpv-socket-HDMI-A-3 2>/dev/null &


### NVIDIA GPU MONITORS NAMES
#killall mpvpaper 2>/dev/null
#rm -f /tmp/mpv-socket-DP-3 /tmp/mpv-socket-HDMI-A-2 /tmp/mpv-socket-DP-2 2>/dev/null
## 1. Set random wallpaper on main monitor
#waypaper --random --monitor DP-2

## 2. Get the wallpaper for DP-2 (2nd position in the comma-separated list)
#MAIN_WALLPAPER=$(grep "wallpaper = " ~/.config/waypaper/config.ini | cut -d'=' -f2 | cut -d',' -f2 | sed 's/^ *//')

## 3. Set same wallpaper on lateral monitors using direct mpvpaper
#mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-DP-3 loop panscan=1.0 --mute=yes --background-color='#000000'" DP-3 "$MAIN_WALLPAPER" &
#mpvpaper --fork -o "input-ipc-server=/tmp/mpv-socket-HDMI-A-2 loop panscan=1.0 --mute=yes --background-color='#000000'" HDMI-A-2 "$MAIN_WALLPAPER" &

## 4. Pause lateral monitors to make them static
#sleep .3
#echo 'set pause yes' | socat - /tmp/mpv-socket-DP-3 2>/dev/null &
#echo 'set pause yes' | socat - /tmp/mpv-socket-HDMI-A-2 2>/dev/null &
