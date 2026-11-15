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

# Find reachable phone device
target_dev=""
target_name=""

for dev in $devices; do
    dev_type=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev" org.kde.kdeconnect.device.type 2>/dev/null)
    target_dev="$dev"
    target_name=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev" org.kde.kdeconnect.device.name 2>/dev/null)
    if [[ "$dev_type" == "phone" ]]; then
        break
    fi
done

if [[ -z "$target_dev" ]]; then
    echo '{"text": "", "class": "disconnected", "tooltip": "No device found"}'
    exit 0
fi

# Get active notifications
notifs=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$target_dev/notifications" org.kde.kdeconnect.device.notifications.activeNotifications 2>/dev/null)

count=0
tooltip_lines=()
tooltip_lines+=("<b>${target_name:-Phone} Notifications</b>")
tooltip_lines+=("─────────────────────────────")

for n in $notifs; do
    app=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$target_dev/notifications/$n" org.kde.kdeconnect.device.notifications.notification.appName 2>/dev/null)
    title=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$target_dev/notifications/$n" org.kde.kdeconnect.device.notifications.notification.title 2>/dev/null)
    text=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$target_dev/notifications/$n" org.kde.kdeconnect.device.notifications.notification.text 2>/dev/null)
    
    clean_title=$(echo "$title" | tr '\n' ' ' | sed 's/  */ /g' | head -c 50)
    clean_text=$(echo "$text" | tr '\n' ' ' | sed 's/  */ /g' | head -c 50)
    
    # Skip if both app and title/text are empty
    [[ -z "$app" && -z "$clean_title" && -z "$clean_text" ]] && continue
    
    ((count++))
    if (( count <= 5 )); then
        desc="$clean_title"
        [[ -z "$desc" ]] && desc="$clean_text"
        tooltip_lines+=("• <b>${app:-App}:</b> ${desc}")
    fi
done

# If 0 notifications, hide the widget
if (( count == 0 )); then
    echo '{"text": "", "class": "hidden", "tooltip": "No notifications"}'
    exit 0
fi

if (( count > 5 )); then
    tooltip_lines+=("<i>+ $((count - 5)) more...</i>")
fi

tooltip=$(printf "%s\n" "${tooltip_lines[@]}")

if command -v jq &>/dev/null; then
    jq -n -c \
        --arg text "󰂚 $count" \
        --arg tooltip "$tooltip" \
        --arg class "has-notifications" \
        --argjson count "$count" \
        '{text: $text, tooltip: $tooltip, class: $class, count: $count}'
else
    printf '{\"text\": \"󰂚 %s\", \"tooltip\": \"%s\", \"class\": \"has-notifications\", \"count\": %s}\n' \
        "$count" "$tooltip" "$count"
fi

