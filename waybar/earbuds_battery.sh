#!/usr/bin/env bash

# Helper to query battery for a given MAC address
get_bluetooth_battery() {
    local mac="$1"
    local pct=""

    # 1. Try bluetoothctl info
    local info
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    if [[ -n "$info" ]]; then
        pct=$(echo "$info" | grep -i "Battery Percentage" | grep -oE '\([0-9]+\)|[0-9]+%' | tr -d '()% ' | head -n1)
        if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ ]]; then
            echo "$pct"
            return 0
        fi
    fi

    # 2. Try busctl on BlueZ system bus
    local mac_formatted="${mac//:/_}"
    local bus_pct
    bus_pct=$(busctl get-property org.bluez "/org/bluez/hci0/dev_${mac_formatted}" org.bluez.Battery1 Percentage 2>/dev/null | awk '{print $2}')
    if [[ -n "$bus_pct" && "$bus_pct" =~ ^[0-9]+$ ]]; then
        echo "$bus_pct"
        return 0
    fi

    # 3. Try UPower device lookup
    if command -v upower &>/dev/null; then
        local up_dev
        up_dev=$(upower -e 2>/dev/null | grep -i "${mac_formatted}" | head -n1)
        if [[ -n "$up_dev" ]]; then
            pct=$(upower -i "$up_dev" 2>/dev/null | awk -F: '/percentage/ {print $2}' | tr -d ' %' | head -n1)
            if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ ]]; then
                echo "$pct"
                return 0
            fi
        fi
    fi

    return 1
}

ACTION="${1:-status}"

# Disconnect action on right click
if [[ "$ACTION" == "--disconnect" ]]; then
    connected=$(bluetoothctl devices Connected 2>/dev/null | head -n1)
    if [[ -n "$connected" ]]; then
        mac=$(echo "$connected" | awk '{print $2}')
        bluetoothctl disconnect "$mac" >/dev/null 2>&1
        notify-send -u low "Bluetooth" "Disconnected $mac" 2>/dev/null
    fi
    exit 0
fi

# Find connected Bluetooth audio/earbuds device
connected_devs=$(bluetoothctl devices Connected 2>/dev/null)

if [[ -z "$connected_devs" ]]; then
    echo '{"text": "", "class": "disconnected", "tooltip": "No earbuds connected"}'
    exit 0
fi

target_mac=""
target_name=""
target_pct=""

# Iterate over connected devices and find audio/earbud device
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d' ' -f3-)

    # Check if it has battery
    pct=$(get_bluetooth_battery "$mac")

    target_mac="$mac"
    target_name="$name"
    target_pct="$pct"
    break
done <<< "$connected_devs"

if [[ -z "$target_mac" ]]; then
    echo '{"text": "", "class": "disconnected", "tooltip": "No earbuds connected"}'
    exit 0
fi

# Earbud icon from Nerd Fonts (mdi-earbuds U+F0970)
icon="󰥰"
class="normal"

if [[ -n "$target_pct" && "$target_pct" =~ ^[0-9]+$ ]]; then
    if (( target_pct <= 15 )); then
        class="critical"
    elif (( target_pct <= 20 )); then
        class="warning"
    else
        class="normal"
    fi

    text="$icon $target_pct%"
    tooltip=$(printf "<b>%s</b>\nBattery: %s%%\nStatus: Connected\nLeft-click: Bluetooth Manager\nRight-click: Disconnect" "${target_name:-Earbuds}" "$target_pct")

    if command -v jq &>/dev/null; then
        jq -n -c \
            --arg text "$text" \
            --arg tooltip "$tooltip" \
            --arg class "$class" \
            --argjson percentage "$target_pct" \
            '{text: $text, tooltip: $tooltip, class: $class, percentage: $percentage}'
    else
        printf '{\"text\": \"%s\", \"tooltip\": \"%s\", \"class\": \"%s\", \"percentage\": %s}\n' \
            "$text" "$tooltip" "$class" "$target_pct"
    fi
else
    # Connected but battery level not reported
    text="$icon"
    tooltip=$(printf "<b>%s</b>\nStatus: Connected\nLeft-click: Bluetooth Manager\nRight-click: Disconnect" "${target_name:-Earbuds}")

    if command -v jq &>/dev/null; then
        jq -n -c \
            --arg text "$text" \
            --arg tooltip "$tooltip" \
            --arg class "normal" \
            '{text: $text, tooltip: $tooltip, class: $class}'
    else
        printf '{\"text\": \"%s\", \"tooltip\": \"%s\", \"class\": \"%s\"}\n' "$text" "$tooltip"
    fi
fi

