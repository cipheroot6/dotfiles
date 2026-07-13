# hypr/

Hyprland Wayland compositor config — modular `.conf` split per concern.

## STRUCTURE

```
hypr/
├── hyprland.conf          # Entry point: sources Omarchy defaults → user overrides
├── bindings.conf          # Super-based keybinds (apps, music, screenshots, QS)
├── autostart.conf         # Startup: KDE Connect, ydotoold, hyprpm, QS, hot corners
├── input.conf             # KB repeat 40/600, numlock, touchpad clickfinger
├── looknfeel.conf         # 35px rounding, opacity per app class (0.75/0.65)
├── monitors.conf          # Display config with Retina scaling notes
├── mocha.config           # 78 Catppuccin Mocha RGB variables (source of truth)
├── hypridle.conf          # Idle/lock/suspend timeouts
├── hyprlock.conf          # Lock screen with time/date/avatar (Catppuccin themed)
├── hyprpaper.conf         # Wallpaper preload/display
├── hyprsunset.conf        # Night light (disabled by default)
├── xdph.conf              # XDG Desktop Portal config
├── scripts/               # Shell helpers (quickshell manager, wallpaper toggle, focus-time)
│   └── quickshell/focustime/  # FocusTime QML popup + Python daemon
└── shaders/               # 138 GLSL effects (ALL BROKEN — dead symlinks to /usr/share/aether/)
```

## WHERE TO LOOK

| File | Purpose |
|------|---------|
| `hyprland.conf` | Orchestrator — reads in order: Omarchy defaults → theme → user overrides |
| `bindings.conf` | All keybindings with `$mainMod = SUPER` |
| `mocha.config` | Single source of truth for all Catppuccin Mocha color values |
| `autostart.conf` | Apps launched on Hyprland start |
| `scripts/qs_manager.sh` | QuickShell watchdog + workspace navigation (173 lines) |

## CONVENTIONS

- **3-tier config**: Omarchy defaults → `~/.config/omarchy/current/theme/` → `~/.config/hypr/*.conf`
- **All configs sourced** from `hyprland.conf` (never `exec-once` directly)
- **Keybinds**: `$mainMod = SUPER`, organized by category (apps, music, screenshots, QS)
- **Windows**: `rounding = 35`, window rules for opacity by app class

## ANTI-PATTERNS

- **`shaders/` directory**: All 138 `.glsl` files are broken symlinks to `/usr/share/aether/shaders/`. Install `aether` or remove the directory.
- **Commented-out alternatives** in `bindings.conf`, `input.conf`, `monitors.conf`, `looknfeel.conf` — noisy dead documentation.
