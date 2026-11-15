#!/usr/bin/env bash

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
        avahi_line=$(timeout 2 avahi-browse -r -t -p _adb-tls-connect._tcp 2>/dev/null | grep -E '^=.*IPv4' | head -n1)
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

# Check if phone is connected via KDE Connect
phone_connected=false
dev_name="Galaxy"
if command -v qdbus &>/dev/null && qdbus org.kde.kdeconnect >/dev/null 2>&1; then
    devices=$(qdbus org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices true true 2>/dev/null)
    if [[ -n "$devices" ]]; then
        phone_connected=true
        first_dev=$(echo "$devices" | head -n1)
        name=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$first_dev" org.kde.kdeconnect.device.name 2>/dev/null)
        [[ -n "$name" ]] && dev_name="$name"
    fi
fi

# Fallback: check if ADB already has device connected
if [[ "$phone_connected" != "true" ]]; then
    if adb devices 2>/dev/null | grep -q "device$"; then
        phone_connected=true
    fi
fi

if [[ "$phone_connected" != "true" ]]; then
    echo '{"text": "", "class": "disconnected", "tooltip": "Phone disconnected"}'
    exit 0
fi

# Check if scrcpy is currently running
if pgrep -x scrcpy >/dev/null; then
    text="󰍹"
    class="active"
    tooltip=$(printf "<b>%s Mirror</b>\nStatus: Mirroring Active\nClick to stop mirroring" "$dev_name")
else
    target=$(get_target)
    if [[ -n "$target" ]]; then
        # Try to resolve friendly display name for target (e.g. IP:PORT)
        display_ep="$target"
        if [[ "$target" == *"._tcp"* ]]; then
            socket_port=$(ss -tpn 2>/dev/null | grep "adb" | awk '{print $5}' | grep -oE '192\.168\.[0-9]+\.[0-9]+:[0-9]+' | head -n1)
            [[ -n "$socket_port" ]] && display_ep="$socket_port"
        fi

        text="󰍹"
        class="ready"
        tooltip=$(printf "<b>%s Mirror</b>\nStatus: Ready (%s)\nClick to start mirroring" "$dev_name" "$display_ep")
    else
        text="󰍹"
        class="inactive"
        tooltip=$(printf "<b>%s Mirror</b>\nStatus: Wireless debugging not detected\nClick to try connecting" "$dev_name")
    fi
fi

if command -v jq &>/dev/null; then
    jq -n -c \
        --arg text "$text" \
        --arg tooltip "$tooltip" \
        --arg class "$class" \
        '{text: $text, tooltip: $tooltip, class: $class}'
else
    printf '{\"text\": \"%s\", \"tooltip\": \"%s\", \"class\": \"%s\"}\n' "$text" "$tooltip" "$class"
fi

