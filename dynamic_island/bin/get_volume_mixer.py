#!/usr/bin/env python3
import subprocess
import json

def get_sink_inputs():
    try:
        output = subprocess.check_output(['pactl', 'list', 'sink-inputs'], text=True)
    except:
        return []
        
    apps = []
    current_app = {}
    for line in output.splitlines():
        line = line.strip()
        if line.startswith('Sink Input #'):
            if current_app:
                apps.append(current_app)
            current_app = {'id': line.split('#')[1]}
        elif line.startswith('application.name ='):
            name = line.split('=')[1].strip().strip('"')
            # Handle duplicates or long names
            if len(name) > 20:
                name = name[:17] + "..."
            current_app['name'] = name
        elif line.startswith('Volume:'):
            # Parse volume e.g. aux0: 61440 /  94% / -1.68 dB
            try:
                vol = line.split('/')[1].strip().replace('%', '')
                current_app['volume'] = int(vol)
            except:
                current_app['volume'] = 100
        elif line.startswith('Mute:'):
            current_app['mute'] = line.split(':')[1].strip() == 'yes'
            
    if current_app:
        apps.append(current_app)
        
    # Filter out anything without a name
    return [a for a in apps if 'name' in a]

if __name__ == "__main__":
    print(json.dumps(get_sink_inputs()))
