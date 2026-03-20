#!/usr/bin/env bash

# --- config ---
LOCATION=""
CACHE_FILE="/tmp/waybar-weather-cache"
CACHE_TTL=600
# --- icons ---
WIND_ICON=" "
SUNRISE_ICON=""
SUNSET_ICON="󰖚"
# --- colors (catppuccin mocha) ---
C_TEMP="#f38ba8"     # red - temperature
C_WIND="#d1d5db"     # sky - wind
C_HUMIDITY="#26c6da" # green - humidity
C_MOON="#cba6f7"     # mauve - moon
C_SUN="#f9e2af"      # yellow - sun time
C_RESET="#cdd6f4"    # text - default
# --------------

player_status=$(playerctl status 2>/dev/null)

if [[ "$player_status" == "Playing" ]]; then
  echo '{"text": "", "class": "hidden"}'
  exit 0
fi

now=$(date +%s)
if [[ -f "$CACHE_FILE" ]]; then
  cache_age=$((now - $(stat -c %Y "$CACHE_FILE")))
else
  cache_age=$CACHE_TTL
fi

if ((cache_age >= CACHE_TTL)); then
  raw=$(curl -sf --max-time 5 "https://wttr.in/${LOCATION}?format=%c+%t+%w+%h+%m|||%S|||%s" 2>/dev/null)
  if [[ -n "$raw" ]]; then
    echo "$raw" >"$CACHE_FILE"
  fi
fi

raw=$(cat "$CACHE_FILE" 2>/dev/null)

if [[ -z "$raw" ]]; then
  echo '{"text": "", "class": "hidden"}'
  exit 0
fi

# Parse fields
condition=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $1}' | awk '{print $1}')
temp=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $1}' | awk '{print $2}')
wind_full=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $1}' | awk '{print $3}')
humidity=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $1}' | awk '{print $4}')
moon=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $1}' | awk '{print $5}')
sunrise_raw=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $2}' | xargs)
sunset_raw=$(echo "$raw" | awk -F'\\|\\|\\|' '{print $3}' | xargs)

# Extract direction arrow + speed from wind_full e.g. "↗13km/h"
wind_dir=$(echo "$wind_full" | grep -oP '[↑↗→↘↓↙←↖]')
wind_speed=$(echo "$wind_full" | grep -oP '[\d]+km/h')

to_minutes() {
  local h=$(echo "$1" | cut -d: -f1 | sed 's/^0*//')
  local m=$(echo "$1" | cut -d: -f2 | sed 's/^0*//')
  echo $((${h:-0} * 60 + ${m:-0}))
}

to_12h() {
  date -d "$1" +"%I:%M %p" 2>/dev/null | sed 's/^0//'
}

now_minutes=$(to_minutes "$(date +%H:%M)")
sunrise_minutes=$(to_minutes "$sunrise_raw")
sunset_minutes=$(to_minutes "$sunset_raw")

if ((now_minutes < sunrise_minutes)); then
  sun_icon="$SUNRISE_ICON"
  sun_time=$(to_12h "$sunrise_raw")
elif ((now_minutes < sunset_minutes)); then
  sun_icon="$SUNSET_ICON"
  sun_time=$(to_12h "$sunset_raw")
else
  sun_icon="$SUNRISE_ICON"
  sun_time=$(to_12h "$sunrise_raw")
fi

# Build with pango color spans
text="<span>${condition}</span>"
text+=" <span color='${C_TEMP}'>${temp}</span>"
text+="  <span color='${C_WIND}'>${WIND_ICON}${wind_dir}${wind_speed}</span>"
text+="  <span color='${C_HUMIDITY}'>󰖎 ${humidity}</span>"
text+="  <span color='${C_MOON}'>${moon}</span>"
text+="  <span color='${C_SUN}'>${sun_icon}${sun_time}</span>"

echo "{\"text\": \"$text\", \"class\": \"visible\"}"
