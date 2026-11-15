#!/usr/bin/env bash

# Check if qdbus is available and KDE Connect is running
if ! command -v qdbus &>/dev/null || ! qdbus org.kde.kdeconnect >/dev/null 2>&1; then
    echo '{"text": "", "class": "disconnected", "tooltip": "KDE Connect not running"}'
    exit 0
fi

# Get reachable paired devices
devices=$(qdbus org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices true true 2>/dev/null)
if [[ -z "$devices" ]] && command -v kdeconnect-cli &>/dev/null; then
    devices=$(kdeconnect-cli -a --id-only 2>/dev/null)
fi

if [[ -z "$devices" ]]; then
    echo '{"text": "", "class": "disconnected", "tooltip": "Phone disconnected"}'
    exit 0
fi

# Find target phone or reachable device with battery capability
target_dev=""
target_name=""

for dev in $devices; do
    has_battery=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev/battery" org.kde.kdeconnect.device.battery.hasBattery 2>/dev/null)
    dev_type=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev" org.kde.kdeconnect.device.type 2>/dev/null)
    if [[ "$has_battery" == "true" ]]; then
        target_dev="$dev"
        target_name=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev" org.kde.kdeconnect.device.name 2>/dev/null)
        if [[ "$dev_type" == "phone" ]]; then
            break
        fi
    fi
done

if [[ -z "$target_dev" ]]; then
    echo '{"text": "", "class": "disconnected", "tooltip": "No phone connected"}'
    exit 0
fi

# Query battery charge and charging state
charge=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$target_dev/battery" org.kde.kdeconnect.device.battery.charge 2>/dev/null)
is_charging=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$target_dev/battery" org.kde.kdeconnect.device.battery.isCharging 2>/dev/null)

# Verify valid charge level
if ! [[ "$charge" =~ ^[0-9]+$ ]] || (( charge < 0 )); then
    echo '{"text": "", "class": "disconnected", "tooltip": "Battery information unavailable"}'
    exit 0
fi

icon=""
status_text="Discharging"
classes=()

if [[ "$is_charging" == "true" ]]; then
    icon=" 󰚥"
    status_text="Charging"
    classes+=("charging")
    if (( charge >= 100 )); then
        status_text="Fully Charged"
        classes+=("plugged")
    fi
fi

if (( charge <= 15 )); then
    classes+=("critical")
elif (( charge <= 20 )); then
    classes+=("warning")
fi

class_str="${classes[*]}"
[[ -z "$class_str" ]] && class_str="normal"

tooltip=$(printf "<b>%s</b>\nBattery: %s%%\nStatus: %s" "${target_name:-Phone}" "$charge" "$status_text")

if command -v jq &>/dev/null; then
    jq -n -c \
        --arg text "$icon $charge%" \
        --arg tooltip "$tooltip" \
        --arg class "$class_str" \
        --argjson percentage "$charge" \
        '{text: $text, tooltip: $tooltip, class: $class, percentage: $percentage}'
else
    printf '{\"text\": \"%s %s%%\", \"tooltip\": \"%s\", \"class\": \"%s\", \"percentage\": %s}\n' \
        "$icon" "$charge" "$tooltip" "$class_str" "$charge"
fi

