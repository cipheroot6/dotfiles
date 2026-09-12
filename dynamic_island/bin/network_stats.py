#!/usr/bin/env python3
import subprocess
import json
import sys
import os

def ping():
    try:
        # Ping 1.1.1.1 3 times
        out = subprocess.check_output(["ping", "-c", "3", "1.1.1.1"], text=True)
        # Parse output for latency and loss
        # ... 3 packets transmitted, 3 received, 0% packet loss, time 2003ms
        # rtt min/avg/max/mdev = 15.011/15.543/16.032/0.418 ms
        loss = "0"
        avg_latency = "0"
        for line in out.splitlines():
            if "packet loss" in line:
                # 3 packets transmitted, 3 received, 0% packet loss
                parts = line.split(",")
                for p in parts:
                    if "packet loss" in p:
                        loss = p.strip().split("%")[0]
            elif "min/avg/max" in line or "rtt" in line:
                # rtt min/avg/max/mdev = 15.0/16.0/17.0/1.0 ms
                stats = line.split("=")[1].strip().split()[0]
                avg_latency = stats.split("/")[1]
                # round to int
                avg_latency = str(int(float(avg_latency)))
        print(json.dumps({"latency": avg_latency, "loss": loss}))
    except Exception as e:
        print(json.dumps({"latency": "N/A", "loss": "N/A"}))

def speedtest():
    try:
        # Run local speedtest-cli with json output
        script_dir = os.path.dirname(os.path.realpath(__file__))
        st_path = os.path.join(script_dir, "speedtest-cli")
        
        # We use --json and --secure
        out = subprocess.check_output([sys.executable, st_path, "--json", "--secure"], text=True)
        # wait, speedtest-cli --json outputs valid json
        data = json.loads(out)
        
        download_bps = data.get("download", 0)
        upload_bps = data.get("upload", 0)
        
        download_mbps = download_bps / 1000000.0
        upload_mbps = upload_bps / 1000000.0
        
        print(json.dumps({
            "download": f"{download_mbps:.1f}",
            "upload": f"{upload_mbps:.1f}",
            "ping": f"{data.get('ping', 0):.1f}"
        }))
    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "ping":
            ping()
        elif cmd == "speedtest":
            speedtest()
