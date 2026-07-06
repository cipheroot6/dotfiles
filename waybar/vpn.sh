#!/bin/bash

# Define cache files in the config folder
CACHE_DIR="$HOME/.config/waybar/.vpn_cache"
mkdir -p "$CACHE_DIR"

CACHE_FILE="$CACHE_DIR/country"
IP_FILE="$CACHE_DIR/ip"

# Try to find a real tunnel interface first (like protonvpn, tun, wg, tap)
vpn_interface=$(ip link show | grep -E '(protonvpn|tun|wg|tap)' | grep -E 'state (UP|UNKNOWN)' | awk -F: '{print $2}' | awk '{print $1}' | head -n1)

# Fallback to leak protection interface if no tunnel is found (just to detect connection state)
if [ -z "$vpn_interface" ]; then
    vpn_interface=$(ip link show | grep 'ipv6leakintrf' | grep -E 'state (UP|UNKNOWN)' | awk -F: '{print $2}' | awk '{print $1}' | head -n1)
fi

if [ -z "$vpn_interface" ]; then
    # No VPN interface is active
    echo ""
    exit 0
fi

# Try to get country code locally from ProtonVPN's connection persistence JSON file first
PERSISTENCE_FILE="$HOME/.cache/Proton/VPN/connection/connection_persistence.json"
if [ -f "$PERSISTENCE_FILE" ]; then
    server_name=$(grep -o '"server_name":[^,]*' "$PERSISTENCE_FILE" 2>/dev/null | cut -d'"' -f4)
    if [ -n "$server_name" ]; then
        country_code=$(echo "$server_name" | cut -d- -f1 | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
        if [ -n "$country_code" ] && [ ${#country_code} -eq 2 ]; then
            echo "$country_code"
            exit 0
        fi
    fi
fi

# Get the IP address of the VPN interface to detect connection changes
current_ip=$(ip -o -4 addr show dev "$vpn_interface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
if [ -z "$current_ip" ]; then
    # Maybe it's IPv6 only
    current_ip=$(ip -o -6 addr show dev "$vpn_interface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
fi

# If we couldn't get an IP, we use "unknown"
if [ -z "$current_ip" ]; then
    current_ip="unknown"
fi

# Read cached values
cached_ip=""
cached_country=""
[ -f "$IP_FILE" ] && cached_ip=$(cat "$IP_FILE")
[ -f "$CACHE_FILE" ] && cached_country=$(cat "$CACHE_FILE")

# If IP matches cache and country is not empty, use cache
if [ "$current_ip" = "$cached_ip" ] && [ -n "$cached_country" ] && [ "$cached_country" != "VPN" ]; then
    echo "$cached_country"
    exit 0
fi

# Try to get country code locally from ProtonVPN status first
country_code=""
if command -v protonvpn &>/dev/null; then
    country_code=$(protonvpn status 2>/dev/null | grep -E '^Server:' | awk '{print $2}' | cut -d- -f1 | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
elif command -v protonvpn-cli &>/dev/null; then
    country_code=$(protonvpn-cli status 2>/dev/null | grep -E '^Server:' | awk '{print $2}' | cut -d- -f1 | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
elif command -v vpn &>/dev/null; then
    country_code=$(vpn status 2>/dev/null | grep -E '^Server:' | awk '{print $2}' | cut -d- -f1 | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
fi

# Fallback to public Geolocation APIs if local check failed
if [ -z "$country_code" ] || [ ${#country_code} -ne 2 ]; then
    for api in "https://ipinfo.io/country" "https://ifconfig.co/country-iso" "https://ipapi.co/country/"; do
        country_code=$(curl -s --max-time 2 "$api" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
        if [ -n "$country_code" ] && [ ${#country_code} -eq 2 ]; then
            break
        fi
    done
fi

# If everything failed, default to "VPN"
if [ -z "$country_code" ] || [ ${#country_code} -ne 2 ]; then
    country_code="VPN"
fi

# Update cache
echo "$current_ip" > "$IP_FILE"
echo "$country_code" > "$CACHE_FILE"

echo "$country_code"
