#!/usr/bin/env bash

# Helper function to get the first reachable phone device
get_phone_dev() {
    if ! command -v qdbus &>/dev/null || ! qdbus org.kde.kdeconnect >/dev/null 2>&1; then
        return 1
    fi
    local devices
    devices=$(qdbus org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices true true 2>/dev/null)
    if [[ -z "$devices" ]] && command -v kdeconnect-cli &>/dev/null; then
        devices=$(kdeconnect-cli -a --id-only 2>/dev/null)
    fi
    [[ -z "$devices" ]] && return 1

    for dev in $devices; do
        local dev_type
        dev_type=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev" org.kde.kdeconnect.device.type 2>/dev/null)
        if [[ "$dev_type" == "phone" ]]; then
            echo "$dev"
            return 0
        fi
    done
    echo "$devices" | head -n1
}

ACTION="${1:-status}"

case "$ACTION" in
    --open|open)
        dev=$(get_phone_dev)
        if [[ -z "$dev" ]]; then
            notify-send -u low "KDE Connect" "No phone connected to browse storage" 2>/dev/null
            exit 1
        fi

        is_mounted=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev/sftp" org.kde.kdeconnect.device.sftp.isMounted 2>/dev/null)
        if [[ "$is_mounted" != "true" ]]; then
            qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev/sftp" org.kde.kdeconnect.device.sftp.mountAndWait >/dev/null 2>&1
        fi

        mount_point=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev/sftp" org.kde.kdeconnect.device.sftp.mountPoint 2>/dev/null)
        target_dir="$mount_point"
        if [[ -d "$mount_point/storage" ]]; then
            target_dir="$mount_point/storage"
        fi

        if [[ -d "$target_dir" ]]; then
            xdg-open "$target_dir" >/dev/null 2>&1 &
        else
            notify-send -u normal "KDE Connect" "Could not access phone storage at $target_dir" 2>/dev/null
        fi
        exit 0
        ;;

    --unmount|unmount)
        dev=$(get_phone_dev)
        if [[ -n "$dev" ]]; then
            qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev/sftp" org.kde.kdeconnect.device.sftp.unmount >/dev/null 2>&1
            notify-send -u low "KDE Connect" "Phone storage unmounted" 2>/dev/null
        fi
        exit 0
        ;;

    status|*)
        dev=$(get_phone_dev)
        if [[ -z "$dev" ]]; then
            echo '{"text": "", "class": "disconnected", "tooltip": "Phone disconnected"}'
            exit 0
        fi

        dev_name=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev" org.kde.kdeconnect.device.name 2>/dev/null)
        is_mounted=$(qdbus org.kde.kdeconnect "/modules/kdeconnect/devices/$dev/sftp" org.kde.kdeconnect.device.sftp.isMounted 2>/dev/null)

        if [[ "$is_mounted" == "true" ]]; then
            tooltip=$(printf "<b>%s Storage</b>\nStatus: Mounted\nLeft-click: Open in File Manager\nRight-click: Unmount" "${dev_name:-Phone}")
            if command -v jq &>/dev/null; then
                jq -n -c \
                    --arg text "󰉋" \
                    --arg tooltip "$tooltip" \
                    --arg class "mounted" \
                    '{text: $text, tooltip: $tooltip, class: $class}'
            else
                printf '{\"text\": \"󰉋\", \"tooltip\": \"%s\", \"class\": \"mounted\"}\n' "$tooltip"
            fi
        else
            tooltip=$(printf "<b>%s Storage</b>\nStatus: Not mounted\nLeft-click: Mount & Open\nRight-click: Refresh" "${dev_name:-Phone}")
            if command -v jq &>/dev/null; then
                jq -n -c \
                    --arg text "󰉋" \
                    --arg tooltip "$tooltip" \
                    --arg class "unmounted" \
                    '{text: $text, tooltip: $tooltip, class: $class}'
            else
                printf '{\"text\": \"󰉋\", \"tooltip\": \"%s\", \"class\": \"unmounted\"}\n' "$tooltip"
            fi
        fi
        ;;
esac

