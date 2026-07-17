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
├── traffic.py          # Network traffic monitor (vnstat live + daily/monthly totals)
└── .vpn_cache/         # VPN IP/country cache files
```

## WHERE TO LOOK

| Task | File |
|------|------|
| Add/remove modules | `config.jsonc` → left/center/right arrays |
| Change colors/styling | `style.css` → Catppuccin Mocha hex values |
| Widget behavior | `cava.sh`, `vpn.sh`, `weather.sh`, `traffic.py` |
| VPN cache logic | `vpn.sh` → reads ProtonVPN JSONs, queries ipinfo/ifconfig.co |
| Weather hide logic | `weather.sh` → checks playerctl, sets `.hidden` class |

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
