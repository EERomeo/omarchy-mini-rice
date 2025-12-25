#!/bin/bash

# SAFETY RULE:
# If Hyprlock is active when the script starts, abort immediately.
if [[ `pgrep -f $0` != "$$" ]]; then
        echo "Another instance of shell already exist! Exiting"
        exit
fi

# Save current workspace BEFORE switching
prev_ws=$(hyprctl -j activeworkspace | jq -r '.id')

# Switch to an empty workspace (10)
hyprctl dispatch workspace 10

# Hide Waybar using Omarchy's toggle
omarchy-toggle-waybar

# Hide cursor
hyprctl keyword cursor:invisible true

# Record initial mouse position
prev_coords="$(hyprctl -j cursorpos | jq -r '.x, .y' | tr '\n' ' ')"

# Wait for user activity (mouse or keyboard)
# 100ms polling for minimal CPU usage
while true; do
    # If a key is pressed → exit screensaver
    read -s -N 1 -t 0.5 key && break

    # Mouse movement detection
    coords=$(hyprctl -j cursorpos | jq -r '.x, .y' | tr '\n' ' ')
    if [[ "$coords" != "$prev_coords" ]]; then
        break
    fi
done

# SAFETY RULE:
# If the system locked DURING the screensaver, do not restore anything.
if pidof hyprlock >/dev/null; then
    exit 0
fi

# Show Waybar again
omarchy-toggle-waybar

# Show cursor again
hyprctl keyword cursor:invisible false

# Return to original workspace (only if it exists)
if hyprctl -j workspaces | jq -r '.[].id' | grep -q "^$prev_ws$"; then
    hyprctl dispatch workspace "$prev_ws"
fi

exit 0

