#!/bin/bash
pkill -f "FocusTime" 2>/dev/null
sleep 0.5
quickshell -p ~/.config/quickshell/focustime/shell.qml &
sleep 1
ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "FocusTime") | .address')
if [ -n "$ADDR" ]; then
    hyprctl dispatch togglefloating address:$ADDR
    hyprctl dispatch resizewindowpixel exact 900 720,address:$ADDR
    hyprctl dispatch movewindowpixel exact 510 180,address:$ADDR
fi
