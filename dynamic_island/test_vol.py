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
            current_app['name'] = line.split('=')[1].strip().strip('"')
        elif line.startswith('Volume:'):
            # Parse volume e.g. aux0: 61440 /  94% / -1.68 dB
            vol = line.split('/')[1].strip().replace('%', '')
            current_app['volume'] = int(vol)
        elif line.startswith('Mute:'):
            current_app['mute'] = line.split(':')[1].strip() == 'yes'
            
    if current_app:
        apps.append(current_app)
    return apps

print(json.dumps(get_sink_inputs()))
