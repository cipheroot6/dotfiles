#!/usr/bin/env python3
import subprocess
import json
import sys

def get_wifi_device():
    try:
        out = subprocess.check_output(["nmcli", "-t", "-f", "device,type", "dev", "status"], text=True)
        for line in out.splitlines():
            parts = line.split(":")
            if len(parts) >= 2 and parts[1] == "wifi":
                return parts[0]
    except Exception:
        pass
    return "wlan0"

def get_status():
    try:
        out = subprocess.check_output(["nmcli", "radio", "wifi"], text=True).strip()
        print(json.dumps({"enabled": out == "enabled"}))
    except Exception:
        print(json.dumps({"enabled": False}))

def get_networks():
    try:
        out = subprocess.check_output(["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi"], text=True)
        networks = []
        seen_ssids = set()
        for line in out.splitlines():
            # Handle potential escaping in SSID by splitting from the right or using maxsplit if needed
            # Actually nmcli -t escapes colons in SSID with backslashes.
            # Easiest way is to split carefully. But simple split works for most SSIDs without colons.
            parts = line.split(":")
            if len(parts) >= 4:
                active = parts[0]
                ssid = parts[1]
                # If SSID contained colons, it might be split into more parts, but usually it doesn't.
                # Just to be safe, let's reverse split or similar, but for now simple split:
                if len(parts) > 4:
                    sec = ":".join(parts[-1:])
                    signal = parts[-2]
                    ssid = ":".join(parts[1:-2])
                else:
                    signal = parts[2]
                    sec = parts[3]
                
                # strip backslashes if any
                ssid = ssid.replace('\\:', ':')

                if not ssid or ssid in seen_ssids:
                    continue
                seen_ssids.add(ssid)
                networks.append({
                    "connected": active == "yes",
                    "name": ssid,
                    "signalStrength": int(signal) if signal.isdigit() else 0,
                    "security": 0 if not sec else 1
                })
        print(json.dumps(networks))
    except Exception:
        print(json.dumps([]))

def connect(ssid, password=None):
    try:
        if password:
            subprocess.run(["nmcli", "dev", "wifi", "connect", ssid, "password", password])
        else:
            subprocess.run(["nmcli", "dev", "wifi", "connect", ssid])
    except Exception:
        pass

def disconnect():
    try:
        dev = get_wifi_device()
        subprocess.run(["nmcli", "dev", "disconnect", dev])
    except Exception:
        pass

def toggle(state):
    try:
        subprocess.run(["nmcli", "radio", "wifi", state])
    except Exception:
        pass

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "status":
            get_status()
        elif cmd == "networks":
            get_networks()
        elif cmd == "connect":
            ssid = sys.argv[2] if len(sys.argv) > 2 else ""
            pwd = sys.argv[3] if len(sys.argv) > 3 else None
            connect(ssid, pwd)
        elif cmd == "disconnect":
            disconnect()
        elif cmd == "toggle":
            state = sys.argv[2] if len(sys.argv) > 2 else "on"
            toggle(state)
