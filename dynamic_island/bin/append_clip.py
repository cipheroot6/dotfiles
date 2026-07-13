#!/usr/bin/env python3
import subprocess
import json
import os
import sys

HISTORY_FILE = os.path.expanduser("~/.local/share/quickshell_clipboard.json")
MAX_ITEMS = 15

def get_current_clipboard():
    try:
        result = subprocess.run(['wl-paste', '--no-newline'], capture_output=True, text=True)
        return result.stdout.strip()
    except:
        return ""

def main():
    content = get_current_clipboard()
    if not content or len(content) > 1000: # Ignore very long texts or empty
        return
        
    try:
        if os.path.exists(HISTORY_FILE):
            with open(HISTORY_FILE, 'r') as f:
                history = json.load(f)
        else:
            history = []
    except:
        history = []
        
    # Remove duplicates
    history = [item for item in history if item != content]
    
    # Insert at beginning
    history.insert(0, content)
    
    # Keep only max items
    history = history[:MAX_ITEMS]
    
    with open(HISTORY_FILE, 'w') as f:
        json.dump(history, f)

if __name__ == "__main__":
    main()
