#!/bin/bash

# If scrcpy is already running, toggle it off when invoked with --toggle
if [[ "$1" == "--toggle" ]] && pgrep -x scrcpy >/dev/null; then
    pkill -x scrcpy
    notify-send -u low "Phone Mirror" "Mirroring stopped" 2>/dev/null
    exit 0
fi

# Function to auto-detect target device or wireless debugging endpoint
get_target() {
    # 1. Existing active ADB device (already connected/authorized)
    local active_serial
    active_serial=$(adb devices 2>/dev/null | awk '$2 == "device" {print $1}' | head -n1)
    if [[ -n "$active_serial" ]]; then
        echo "$active_serial"
        return 0
    fi

    # 2. Check established ADB TCP socket
    local socket_ep
    socket_ep=$(ss -tpn 2>/dev/null | grep "adb" | awk '{print $5}' | grep -oE '192\.168\.[0-9]+\.[0-9]+:[0-9]+' | head -n1)
    if [[ -n "$socket_ep" ]]; then
        echo "$socket_ep"
        return 0
    fi

    # 3. Check adb mdns services
    local mdns_ep
    mdns_ep=$(adb mdns services 2>/dev/null | grep -E '_adb-tls-connect\._tcp|_adb\._tcp' | awk '{print $NF}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | head -n1)
    if [[ -n "$mdns_ep" ]]; then
        echo "$mdns_ep"
        return 0
    fi

    # 4. Check avahi-browse (mDNS)
    if command -v avahi-browse &>/dev/null; then
        local avahi_line
        avahi_line=$(timeout 2.5 avahi-browse -r -t -p _adb-tls-connect._tcp 2>/dev/null | grep -E '^=.*IPv4' | head -n1)
        if [[ -n "$avahi_line" ]]; then
            local ip port
            ip=$(echo "$avahi_line" | cut -d';' -f8)
            port=$(echo "$avahi_line" | cut -d';' -f9)
            if [[ -n "$ip" && -n "$port" ]]; then
                echo "${ip}:${port}"
                return 0
            fi
        fi
    fi

    return 1
}

TARGET=$(get_target)

# Fallback: if not found and running interactively in terminal, prompt for port
if [[ -z "$TARGET" ]]; then
    if [ -t 0 ]; then
        read -p "Could not auto-detect port. Enter phone port: " PORT
        if [[ -n "$PORT" ]]; then
            TARGET="192.168.1.42:$PORT"
        fi
    fi
fi

if [[ -z "$TARGET" ]]; then
    notify-send -u critical "Phone Mirror" "Wireless debugging not detected. Enable Wireless Debugging on your phone." 2>/dev/null
    echo "Error: Wireless debugging port not found." >&2
    exit 1
fi

# If target is an IP:PORT format and not already in adb devices, connect to it
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    if ! adb devices 2>/dev/null | grep -q "$TARGET.*device$"; then
        echo "Connecting to $TARGET..."
        notify-send -u low "Phone Mirror" "Connecting to $TARGET..." 2>/dev/null
        adb connect "$TARGET" >/dev/null 2>&1
    fi
fi

echo "Mirroring device: $TARGET..."
notify-send -u low "Phone Mirror" "Starting screen mirror..." 2>/dev/null

# If called from Waybar or non-terminal, run in background
if [ ! -t 0 ] || [[ "$1" == "--toggle" ]]; then
    setsid scrcpy -s "$TARGET" -S -w >/dev/null 2>&1 &
else
    scrcpy -s "$TARGET" -S -w
fi

