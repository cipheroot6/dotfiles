#!/bin/bash

# Check if FocusTime is running
FOCUS_WIN=$(hyprctl clients -j | jq -r '.[] | select(.title == "FocusTime") | .address')

if [ -n "$FOCUS_WIN" ] && [ "$FOCUS_WIN" != "null" ]; then
    # Window exists - close it
    kill $(pgrep -f "quickshell.*focustime") 2>/dev/null
else
    # Start FocusTime
    quickshell -p ~/.config/quickshell/focustime/shell.qml &
    sleep 0.5
    
    # Wait for window to appear and resize
    for i in {1..10}; do
        FOCUS_WIN=$(hyprctl clients -j | jq -r '.[] | select(.title == "FocusTime") | .address')
        if [ -n "$FOCUS_WIN" ] && [ "$FOCUS_WIN" != "null" ]; then
            sleep 0.3
            hyprctl dispatch togglefloating address:$FOCUS_WIN
            hyprctl dispatch resizewindowpixel exact 900 720,address:$FOCUS_WIN
            hyprctl dispatch movewindowpixel exact 510 180,address:$FOCUS_WIN
            break
        fi
        sleep 0.2
    done
fi
