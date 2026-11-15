# waybar/

Custom Waybar status bar config + 4 widget scripts for Hyprland.

## STRUCTURE

```
waybar/
├── config.jsonc        # Module layout (left/center/right groups)
├── style.css           # Catppuccin Mocha styling, semi-transparent rounded
├── cava.sh             # Audio visualizer (60fps unicode bars from CAVA raw output)
├── vpn.sh              # VPN country detection (ProtonVPN + geolocation API fallback)
├── weather.sh          # Weather widget (wttr.in, Pango markup, auto-hides during media)
├── traffic.py              # Network traffic monitor (vnstat live + daily/monthly totals)
├── phone_battery.sh        # Phone battery widget (KDE Connect DBus/CLI, auto-hides when disconnected)
├── earbuds_battery.sh      # Bluetooth earbuds battery widget (BlueZ/UPower, auto-hides when disconnected)
├── phone_notifications.sh  # Phone notifications badge (KDE Connect DBus, auto-hides when 0)
├── phone_storage.sh        # Phone wireless storage mount/open (KDE Connect SFTP)
├── phone_mirror.sh         # Phone screen mirror Waybar status monitor
├── mirror.sh               # Phone screen mirror launcher (scrcpy + auto-detected ADB wireless port)
└── .vpn_cache/             # VPN IP/country cache files
```

## WHERE TO LOOK

| Task | File |
|------|------|
| Add/remove modules | `config.jsonc` → left/center/right arrays |
| Change colors/styling | `style.css` → Catppuccin Mocha hex values |
| Widget behavior | `cava.sh`, `vpn.sh`, `weather.sh`, `traffic.py`, `phone_*.sh`, `earbuds_battery.sh`, `mirror.sh` |
| VPN cache logic | `vpn.sh` → reads ProtonVPN JSONs, queries ipinfo/ifconfig.co |
| Weather hide logic | `weather.sh` → checks playerctl, sets `.hidden` class |
| Phone & earbuds logic | `phone_battery.sh`, `earbuds_battery.sh`, `phone_notifications.sh`, `phone_storage.sh`, `phone_mirror.sh`, `mirror.sh` |

## CONVENTIONS

- **Font**: JetBrainsMono Nerd Font Propo, 12px
- **Background**: `rgba(20, 20, 30, 0.5)` semi-transparent dark
- **Border radius**: 12-16px per module
- **Colors**: mauve `#cba6f7` (network/weather/mpris), sky `#89dceb` (memory), green `#a6e3a1` (disk), yellow `#f9e2af` (temp), red `#f38ba8` (critical)
- **Hidden modules**: Weather and MPRIS use `.hidden`/`.paused` CSS classes (collapse to zero size)
- **Module groups**: `group/right1` (always visible), `group/center2-expander` (drawer with updates)
- **Scripts output JSON**: Waybar custom modules expect JSON with `text`, `tooltip`, `class` fields

## ANTI-PATTERNS

- **Hardcoded colors**: CSS and scripts hardcode Catppuccin hex values (NOT derived from `hypr/mocha.config`)
- **Hardcoded paths**: `vpn.sh` and `traffic.py` reference absolute paths
- **Cache not gitignored**: `.vpn_cache/` directory should be in `.gitignore`
- **No requirements.txt**: `traffic.py` depends on Python but has no dependency declaration
