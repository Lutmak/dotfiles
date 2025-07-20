#!/bin/bash

# Get battery information
battery_info=$(polychromatic-cli -d mouse -n "Razer Basilisk V3 Pro (Wireless)" -k | rg "Battery" | rg -o "\d+" --replace '$0')

# Check if the battery info is empty or equals 0
if [ -z "$battery_info" ] || [ "$battery_info" -eq 0 ]; then
    # Show charging icon if battery is 0 (assumed charging)
    echo '{"text": "󰍿", "tooltip": "Mouse is charging or disconnected", "class": "charging"}'
else
    # Determine battery icon based on level
    if [ "$battery_info" -ge 75 ]; then
        icon="󰂅"
        class="high"
    elif [ "$battery_info" -ge 50 ]; then
        icon="󰂀"
        class="medium"
    elif [ "$battery_info" -ge 25 ]; then
        icon="󰁾" 
        class="low"
    else
        icon="󰁺"
        class="critical"
    fi
    
    # Output JSON for Waybar
    echo "{\"text\": \"$icon $battery_info%\", \"tooltip\": \"Mouse Battery: $battery_info%\", \"class\": \"$class\"}"
fi
