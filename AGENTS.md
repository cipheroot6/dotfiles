# dotfiles

**Arch Linux** · **Hyprland** · **Catppuccin Mocha** · **Omarchy**

## OVERVIEW

Personal Arch Linux dotfiles organized by-app at top level. Built on the Omarchy desktop framework with Hyprland (Wayland compositor), Waybar status bar, Ghostty terminal, zsh shell, Starship prompt, and a custom QML Dynamic Island overlay.

## STRUCTURE

```
./
├── hypr/              # Hyprland WM config (split into modular .conf files)
│   ├── scripts/       # Shell helpers (wallpaper toggle, quickshell manager)
│   └── shaders/       # 138 GLSL screen shaders (BROKEN - see Notes)
├── dynamic_island/    # QML/QuickShell Dynamic Island overlay app
│   ├── bin/           # Python lyrics proxy + MPRIS tools
│   ├── IslandBackend/      # Compiled C++ QML plugin (libIslandBackend.so)
│   └── ConnectivityBackend/ # Compiled C++ QML plugin
├── waybar/            # Status bar config + widget scripts
├── zsh/               # ZSH config (modular .zsh files)
├── hyprland/           # DUPLICATE/STALE Hyprland config (see Anti-patterns)
├── scripts/           # Utility scripts (enc/dec vault, fuzzy finder)
├── fastfetch/         # System info display config
├── ghostty/           # Terminal emulator config
├── starship/          # Prompt config
├── cava/              # Audio visualizer config
└── bg/                # Wallpaper collection (31 images)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Hyprland keybinds | `hypr/bindings.conf` |
| App autostart | `hypr/autostart.conf` |
| Monitor setup | `hypr/monitors.conf` |
| Theme colors | `hypr/mocha.config` (source of truth) |
| Waybar layout | `waybar/config.jsonc` |
| Waybar styling | `waybar/style.css` |
| ZSH aliases | `zsh/zsh/aliases.zsh` |
| ZSH env vars | `zsh/zsh/env.zsh` |
| Dynamic Island QML | `dynamic_island/*.qml` (27 files) |
| Encryption tool | `scripts/enc` / `scripts/dec` |

## CONVENTIONS

- **Theme**: Catppuccin Mocha everywhere — colors defined in `hypr/mocha.config`; hardcoded hex in CSS/Starship
- **Fonts**: JetBrainsMono Nerd Font (Waybar), VictorMono Nerd Font (Ghostty)
- **Icons**: Nerd Font icons throughout
- **Transparency**: Semi-transparent windows/Waybar/Ghostty
- **Config layering**: Omarchy defaults → `~/.config/omarchy/theme/` → repo overrides (3-tier)
- **Keybind style**: Super-based, defined in `bindings.conf`
- **No bootstrap automation**: Configs are manually copied/symlinked (no stow/chezmoi/install.sh)

## ANTI-PATTERNS (THIS PROJECT)

- **`hypr/shaders/`**: All 138 `.glsl` files are BROKEN symlinks pointing to `/usr/share/aether/shaders/` (aether not installed). Dead weight.
- **`hyprland/` directory**: Duplicates `hypr/hyprlock.conf`, `hypr/looknfeel.conf`, `hypr/mocha.config` — likely stale/migration artifact.
- **Tracked artifacts**: `proxy.log` (1.5MB), `lyricsmpris.orig` (9.9MB), `__pycache__/` — log files and backups committed.
- **`.gitignore` too minimal**: Only ignores `**/.stfolder`. Missing `__pycache__/`, `*.log`, `*.orig`, `*.bak`.
- **Hardcoded paths**: `aliases.zsh` has absolute home paths and private IP addresses.
- **World-writable dirs**: Many directories have 0777 permissions.

## UNIQUE STYLES

- Custom QML Dynamic Island overlay (macOS-style) with media player, notifications, OSD, workspace overview, pomodoro, timer, stopwatch, calendar, and desktop pet cat
- `scripts/enc` / `scripts/dec` — full encryption vault (Argon2id + AES-256-GCM/ChaCha20, HMAC-verified, RAM-only via /dev/shm)
- QuickShell manager (`hypr/scripts/qs_manager.sh`) with Bluetooth scan watchdog
- 138 curated Hyprland GLSL shader effects

## COMMANDS

No build/test commands exist. This is a config-only repo.

## NOTES

- **Omarchy dependency**: Required for keybindings, autostart, and theming. Install from `~/.local/share/omarchy/` first.
- **Symlink manually**: Configs go to `~/.config/<app>`. No automation provided.
- **Repo size**: ~166MB (mostly wallpapers in `bg/` + compiled `.so` files)
- **Git**: `main` branch, rebase pull strategy, histogram diff
