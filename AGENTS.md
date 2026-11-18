# dotfiles

**Arch Linux** · **Hyprland** · **Catppuccin Mocha** · **Omarchy**

## OVERVIEW

Personal Arch Linux dotfiles organized by-app at top level. Built on the Omarchy desktop framework with Hyprland (Wayland compositor), Waybar status bar (featuring mobile & KDE Connect integration), Ghostty terminal, zsh shell, Starship prompt, custom QML Dynamic Island overlay with a dedicated Qt/QML Settings App, and a zero-disk-residue encryption vault.

## STRUCTURE

```
./
├── install.sh         # Automated installer (pacman/yay/paru pkgs, safe backups, symlinks, C++ build)
├── hypr/              # Hyprland WM config (split into modular .conf files)
│   ├── scripts/       # Shell helpers (wallpaper toggle, quickshell manager, focus-time)
│   └── shaders/       # 138 GLSL screen shaders (BROKEN - dead symlinks to /usr/share/aether/)
├── dynamic_island/    # QML/QuickShell Dynamic Island overlay app
│   ├── qml/           # Modular UI layers (core, island, controlcenter, productivity, workspace, extras)
│   ├── config-app/    # Standalone Qt6/QML configuration app (themes, fonts, wallpapers, shortcuts, TLP, AI)
│   ├── backend/       # C++ backends (SysBackend, WifiController, BluetoothPairingAgent, FileShelfModel, etc.)
│   ├── build_backend/ # Standalone CMake build target for backend plugins
│   ├── bin/           # Python lyrics proxy, volume mixer, clipboard helper, speedtest-cli, nmcli
│   ├── fonts/         # Bundled TTF fonts (Pacifico, DancingScript)
│   ├── open-settings.sh # Shell launcher for the Dynamic Island Config App
│   └── CMakeLists.txt # Root CMake build for IslandBackend and config-app
├── waybar/            # Status bar config + widgets (CAVA, vnstat, VPN, weather, KDE Connect phone & earbuds)
├── zsh/               # ZSH config (modular .zsh files under zsh/ + completion dir .zsh)
├── hyprland/          # DUPLICATE/STALE Hyprland config (see Anti-patterns)
├── scripts/           # Utility scripts (enc/dec vault v5.2, fuzzy finder)
├── fastfetch/         # System info display config
├── ghostty/           # Terminal emulator config
├── starship/          # Prompt config
├── cava/              # Audio visualizer config
└── bg/                # Wallpaper collection (64 curated images across bg/ and bg/wallpapers/)
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
| Waybar phone & earbuds widgets | `waybar/phone_*.sh`, `waybar/earbuds_battery.sh`, `waybar/mirror.sh` |
| ZSH aliases | `zsh/zsh/aliases.zsh` |
| ZSH env vars | `zsh/zsh/env.zsh` |
| Dynamic Island QML layers | `dynamic_island/qml/` (`core/`, `island/`, `controlcenter/`, `productivity/`, `workspace/`, `extras/`) |
| Dynamic Island Config App | `dynamic_island/config-app/` and `dynamic_island/open-settings.sh` |
| Dynamic Island C++ backends | `dynamic_island/backend/` and `dynamic_island/CMakeLists.txt` |
| Encryption tool | `scripts/enc` / `scripts/dec` |
| Automated bootstrap | `install.sh` |

## CONVENTIONS

- **Theme**: Catppuccin Mocha everywhere — colors defined in `hypr/mocha.config`; hardcoded hex in CSS/Starship/Waybar.
- **Fonts**: JetBrainsMono Nerd Font (Waybar), VictorMono Nerd Font (Ghostty), Inter & Lora (Dynamic Island Config App).
- **Icons**: Nerd Font icons throughout.
- **Transparency**: Semi-transparent windows (0.75/0.65), Waybar, and Ghostty (0.5 opacity).
- **Config layering**: Omarchy defaults → `~/.config/omarchy/theme/` → repo overrides (3-tier).
- **Keybind style**: Super-based, defined in `bindings.conf` (e.g., `SUPER + RETURN` terminal, `SUPER + A` Antigravity IDE, `SUPER + TAB` workspace overview).
- **Bootstrap automation**: Automated installer via `install.sh` (detects `yay`/`paru` or automatically bootstraps `yay-bin`, installs pacman and AUR packages, creates non-destructive backups of existing configurations in `~/.dotfiles_backup/`, sets executable permissions, symlinks configs into `~/.config/`, and compiles C++ plugins with CMake). Manual symlinking is also supported.

## ANTI-PATTERNS (THIS PROJECT)

- **`hypr/shaders/`**: All 138 `.glsl` files are broken symlinks pointing to `/usr/share/aether/shaders/` (the `aether` package is not installed). Dead weight.
- **`hyprland/` directory**: Duplicates `hypr/hyprlock.conf`, `hypr/looknfeel.conf`, `hypr/mocha.config` — stale migration artifact. Use `hypr/` exclusively.
- **Hardcoded paths**: `aliases.zsh` has absolute home paths and private IP addresses. `WorkspaceOverviewLayer.qml` historically referenced `/home/dan/`. Review before blindly copying.
- **File permissions**: Several directories and scripts carry permissive 0777 permissions from legacy transfers.
- **Cleaned artifacts**: Tracked large files (`proxy.log`, `lyricsmpris.orig`, `__pycache__/`, `.so` binaries) have been purged from git tracking, and `.gitignore` now ignores logs, pycache, build directories, and binaries.

## UNIQUE STYLES & ARCHITECTURE

- **Dynamic Island Overlay (QuickShell)**: Floating capsule morphing into 27+ modular UI layers across 6 functional subdirectories (`core`, `island`, `controlcenter`, `productivity`, `workspace`, `extras`), featuring synced lyrics (LRCLib + SQLite zstd cache via Python HTTP proxy on port 8765), per-app PulseAudio volume mixer, AI prompt interface with DuckDuckGo web search context, drag-and-drop file shelf / dropzone, and an interactive 900+ line QML Canvas desktop pet cat.
- **Dynamic Island Config Application (`config-app/`)**: Full Qt6/QML desktop configuration app with custom C++ backend (`backend.cpp`) for managing general preferences, wallpaper thumbnail selection, fonts, shortcuts, interaction rules, AI settings, and TLP power profiles.
- **Mobile Ecosystem & KDE Connect Integration**: Waybar widgets and system scripts for phone battery (`phone_battery.sh`), bluetooth earbuds battery (`earbuds_battery.sh`), phone notifications sync (`phone_notifications.sh`), wireless SFTP storage mounting (`phone_storage.sh`), and wireless screen mirroring via `scrcpy` with automatic ADB port resolution (`mirror.sh` & `phone_mirror.sh`).
- **Encryption Vault v5.2 (`scripts/enc` / `scripts/dec`)**: Zero-disk-footprint crypto pipeline operating exclusively in RAM (`/dev/shm`, capped at 100MiB), using Argon2id KDF, AES-256-GCM / ChaCha20, 10 compression algorithms, HMAC integrity verification, post-write decryption validation, and 5-layer path traversal guards.
- **QuickShell Watchdog (`hypr/scripts/qs_manager.sh`)**: QuickShell manager with background Bluetooth scan monitoring and workspace navigation.

## COMMANDS

- **Run Installer**: `./install.sh`
- **Build Dynamic Island C++ Plugins**:
  ```bash
  cmake -B dynamic_island/build -S dynamic_island && cmake --build dynamic_island/build
  ```
  *(or `cd dynamic_island/build_backend && mkdir -p build && cd build && cmake .. && make`)*
- **Launch Dynamic Island Settings**: `dynamic_island/open-settings.sh`
- **Encrypt / Decrypt Files**:
  ```bash
  scripts/enc -c aes-256-gcm -z zstd /path/to/target
  scripts/dec /path/to/target.enc
  ```

## NOTES

- **Omarchy dependency**: Required for default bindings, autostart, and desktop theming. Must be installed at `~/.local/share/omarchy/`.
- **Repo size**: ~245MB tracked (primarily high-resolution wallpapers in `bg/`).
- **Git**: `main` branch, rebase pull strategy.
