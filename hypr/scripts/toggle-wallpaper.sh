#!/bin/bash

WALL="$HOME/Videos/wallpapers/wall.mp4"
MONITOR="eDP-1"

if pgrep mpvpaper > /dev/null; then
    pkill mpvpaper
    swww img ~/Pictures/static.webp --transition-type none
else
    swww init >/dev/null 2>&1
    mpvpaper -o "loop" "$MONITOR" "$WALL" &
fi
