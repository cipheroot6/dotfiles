#!/usr/bin/env python3
import subprocess
import re
import sys
import time
import json

# Global variables for caching totals
last_total_update = 0.0
cached_totals = ("0 B", "0 B", "0 B", "0 B", "0 B", "0 B")

def get_totals(interface):
    try:
        # Run vnstat --oneline for the interface to get database summary
        res = subprocess.run(["vnstat", "--oneline", "-i", interface], capture_output=True, text=True, check=True)
        fields = res.stdout.strip().split(";")
        if len(fields) >= 15:
            # Field 6 (index 5): Daily Total
            # Field 11 (index 10): Monthly Total
            # Field 4 (index 3): Daily RX, Field 5 (index 4): Daily TX
            # Field 9 (index 8): Monthly RX, Field 10 (index 9): Monthly TX
            daily_total = fields[5].strip()
            monthly_total = fields[10].strip()
            daily_rx = fields[3].strip()
            daily_tx = fields[4].strip()
            monthly_rx = fields[8].strip()
            monthly_tx = fields[9].strip()
            return daily_total, monthly_total, daily_rx, daily_tx, monthly_rx, monthly_tx
    except Exception:
        pass
    return "0 B", "0 B", "0 B", "0 B", "0 B", "0 B"

def get_totals_cached(interface):
    global last_total_update, cached_totals
    now = time.time()
    # Cache for 10 seconds to minimize CPU/IO overhead
    if now - last_total_update > 10.0:
        cached_totals = get_totals(interface)
        last_total_update = now
    return cached_totals

def parse_traffic(interface):
    # Run vnstat -l on the specified interface, line-buffered
    cmd = ["stdbuf", "-oL", "vnstat", interface, "-l"]
    
    # Regular expression to extract rx and tx values and their units
    pattern = re.compile(r"rx:\s*([0-9.]+)\s*(\S+).*?tx:\s*([0-9.]+)\s*(\S+)")

    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
    except Exception as e:
        # If vnstat fails to run, print error JSON and wait
        err_json = {
            "text": "Err",
            "tooltip": f"Error starting vnstat: {e}"
        }
        print(json.dumps(err_json), flush=True)
        time.sleep(5)
        return

    buffer = ""
    while True:
        # Check if process has terminated
        if proc.poll() is not None:
            break
            
        char = proc.stdout.read(1)
        if not char:
            break
        buffer += char
        
        # Process lines separated by ANSI cursor-movement codes or newlines
        if "\x1b[1G" in buffer:
            parts = buffer.split("\x1b[1G")
            for part in parts[:-1]:
                process_line(part, pattern, interface)
            buffer = parts[-1]
        elif "\n" in buffer:
            parts = buffer.split("\n")
            for part in parts[:-1]:
                process_line(part, pattern, interface)
            buffer = parts[-1]

    # If the process exited, wait 5 seconds before retrying
    time.sleep(5)

def process_line(line, pattern, interface):
    # Remove terminal escape sequences (ANSI codes)
    clean_line = re.sub(r"\x1b\[[0-9;]*[a-zA-Z]", "", line).strip()
    if not clean_line:
        return
    
    match = pattern.search(clean_line)
    if match:
        rx_val, rx_unit, tx_val, tx_unit = match.groups()
        
        # Strip '/s' from units to make it more compact
        rx_u = rx_unit.replace("/s", "")
        tx_u = tx_unit.replace("/s", "")
        
        # Get cached totals
        daily_total, monthly_total, daily_rx, daily_tx, monthly_rx, monthly_tx = get_totals_cached(interface)
        
        # Format compact display text: ↓Rx ↑Tx (Today's Total)
        # e.g., ↓12.4KiB ↑2.3KiB (2.25GiB)
        d_tot_clean = daily_total.replace(" ", "")
        display_text = f"↓{rx_val}{rx_u} ↑{tx_val}{tx_u} ({d_tot_clean})"
        
        # Build structured tooltip
        tooltip_text = (
            f"Interface: {interface}\n"
            f"─────────────────────────────\n"
            f"Today's Total: {daily_total}\n"
            f"  Received: {daily_rx}\n"
            f"  Sent: {daily_tx}\n"
            f"─────────────────────────────\n"
            f"Month's Total: {monthly_total}\n"
            f"  Received: {monthly_rx}\n"
            f"  Sent: {monthly_tx}"
        )
        
        # Output JSON line for Waybar
        json_output = {
            "text": display_text,
            "tooltip": tooltip_text
        }
        print(json.dumps(json_output), flush=True)

if __name__ == "__main__":
    # Default to wlan0 if no interface argument is provided
    interface = "wlan0"
    if len(sys.argv) > 1:
        interface = sys.argv[1]
        
    while True:
        try:
            parse_traffic(interface)
        except KeyboardInterrupt:
            sys.exit(0)
        except Exception:
            time.sleep(5)
