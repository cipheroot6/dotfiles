# 🌌 Catppuccin Omarchy Dotfiles

<p align="center">
  <img src="https://img.shields.io/badge/OS-Arch%20Linux-1793D1?logo=arch-linux&logoColor=white&style=flat-square" alt="OS: Arch Linux" />
  <img src="https://img.shields.io/badge/WM-Hyprland-33ccff?logo=hyprland&logoColor=white&style=flat-square" alt="WM: Hyprland" />
  <img src="https://img.shields.io/badge/Theme-Catppuccin%20Mocha-F5E0DC?style=flat-square" alt="Theme: Catppuccin Mocha" />
  <img src="https://img.shields.io/badge/Framework-Omarchy-BD93F9?style=flat-square" alt="Framework: Omarchy" />
</p>

A premium, highly-styled Arch Linux desktop setup. Built on the **Omarchy** desktop framework, this repository contains configurations for **Hyprland** (Wayland compositor), **Waybar** (modular status bar), **Ghostty** (terminal), **zsh** (shell with Starship), and a custom macOS-style QML **Dynamic Island** overlay.

---

## 📌 Table of Contents
1. [Component Highlights](#-component-highlights)
   - [Custom QML Dynamic Island](#1-custom-qml-dynamic-island-overlay)
   - [In-Memory Encryption Vault](#2-in-memory-encryption-vault)
   - [Fuzzy Finder with Kitty Previews](#3-terminal-fuzzy-finder)
   - [Waybar & Status Widgets](#4-modular-waybar-status-bar)
   - [Ghostty & Zsh Environment](#5-ghostty--zsh-terminal-environment)
   - [Acoustics & Visualizer (CAVA)](#6-cava-audio-visualizer)
   - [Hyprland Look & Feel](#7-hyprland-compositor-styling)
2. [Keybindings Reference](#%EF%B8%8F-keybindings-reference)
3. [File Architecture](#-file-architecture)
4. [Installation & Symlink Guide](#%EF%B8%8F-installation--configuration)
5. [Repository Notes & Limitations](#-notes--known-caveats)

---

## 🎨 Component Highlights

### 1. Custom QML Dynamic Island Overlay
The centerpiece of this desktop setup is a macOS-style floating capsule built in **QML/QuickShell** (`dynamic_island/`). 

* **Stateful Architecture**: Spawns a resting capsule that morphs into expanded panels depending on active actions (Music, Calendar, Pomodoro, Notifications, Volume/Brightness OSDs).
* **Workspace Overview**: A customized layout widget providing live previews of Hyprland workspaces.
* **Lyrics Proxy Server (`clean_lyrics_proxy.py`)**: Runs in the background (port `8765`) to stream music lyrics directly to the Dynamic Island panel.
  - *Caching Engine*: Stores retrieved lyrics using `zstd` compression in a local SQLite3 cache database (`~/.cache/quickshell/lyricsmpris/cache.db`).
  - *Title Normalization*: Uses regex to clean brackets, remove junk suffixes (like `- official video`, `slowed + reverb`, or `- Topic`), and extract primary artists.
  - *Fuzzy Matcher*: Falls back to the LRCLib API search (`api.lrclib.net`) to locate synced/plain lyrics if an exact match fails.
* **Pet Cat (`PetCat.qml`)**: A digital desktop pet cat integrated right inside the Dynamic Island workspace.
* **Flexible Configuration (`UserConfig.qml`)**: Exposes customizable properties:
  - Font families (defaults to `VictorMono Nerd Font` for icons and `Inter Display` for UI elements).
  - Enable/disable desktop pet (`petEnabled`).
  - Mouse button bindings (e.g., Left click toggles the Expanded Player, Right click toggles the Control Center panel).
  - Quick action integrations for Wifi menus, Bluetooth indicators, and Pomodoro states.

---

### 2. In-Memory Encryption Vault
Located in `scripts/enc` and `scripts/dec`, this is a high-security file encryption system.

* **Key Derivation (KDF)**: Uses Argon2id (`t=3, m=2^14 KiB (16 MiB), p=4`) to generate a 64-byte key.
* **Supported Ciphers**: Native AES-256-GCM (via Python Cryptography with authenticated header binding via AAD), AES-256-CTR + HMAC-SHA256, and ChaCha20 + HMAC-SHA256. 
* **RAM-Safe Processing**: All encryption and decryption pipelines stream data directly via UNIX pipes (`tar | compress | openssl`). Intermediate decrypted files never touch physical disks; temporary folders exist exclusively in `/dev/shm` (tmpfs RAM-disk) and are securely shredded/zeroed using `shred -uz` on exit.
* **Hard Memory Budget**: Aborts processing if the payload exceeds 100MB to prevent out-of-memory crashes on systems with small RAM-disks.
* **Tar Traversal Guards**: The decryptor runs dry-run scans (`tar -tf`) to identify and refuse extraction of absolute paths or directory traversal attempts (e.g., `../`).

---

### 3. Terminal Fuzzy Finder
A customized workspace search script (`scripts/fuzyfinder.sh`).
* **Kitty Image Protocol**: Integrates with `ueberzugpp` and `fzf` to draw image previews directly in the terminal interface.
* **Syntax Highlighting**: Uses `bat` for code files, JSON, XML, and text.
* **PDF Previews**: Automatically converts PDF files to readable text via `pdftotext` on-the-fly inside the preview pane.

---

### 4. Modular Waybar Status Bar
A custom semi-transparent bar featuring custom network, audio, and utility scripts:
* **CAVA Widget (`cava.sh`)**: Translates raw 60fps CAVA output into a dynamically updating Unicode audio bar (`▁ ▂ ▃ ▄ ▅ ▆ ▇ █`). The bar defaults to a flat, resting configuration (`▁ ▁ ▁ ▁ ▁ ▁`) when audio playback is paused.
* **VPN Interface (`vpn.sh`)**: Automatically searches for active tunnel ports (`protonvpn`, `tun`, `wg`, `tap`). It caches your IP address locally, reading ProtonVPN connection persistence JSONs or querying geolocator APIs (`ipinfo.io`, `ifconfig.co`) to display your active VPN country code in Waybar without redundant HTTP requests.
* **Traffic Speed (`traffic.py`)**: Interrogates the `vnstat -l` daemon asynchronously. Outputs formatted interface download/upload speeds (e.g. `↓12.4KiB ↑2.3KiB`) and logs your total network bandwidth usage for both today and the current month.
* **Weather Module (`weather.sh`)**: Periodically pulls weather forecasts from `wttr.in` and outputs styled Pango markup. It automatically hides when a media player is active to prevent status bar overcrowding.

---

### 5. Ghostty & Zsh Terminal Environment
* **Ghostty (`ghostty/config`)**:
  - Uses `VictorMono Nerd Font` (size 12, italic style).
  - Semi-transparent window background (`opacity = 0.5`) with borderless design.
  - Integrates performance optimization (`async-backend = epoll`) to eliminate interface latency under Hyprland.
* **Zsh Launch Cycle (`zsh/.zsh`)**:
  - Acts as a custom shell profile that loads Oh My Zsh (Robbyrussell theme) and sources modular configs in `~/.config/zsh/`.
  - Configures autosuggestions and history substring search plug-ins.
  - Launches `fastfetch` automatically on new terminal sessions.
* **System Spec Dashboard (`fastfetch/config.jsonc`)**:
  - Formatted with magenta keys.
  - Renders a custom graphic logo (`logo.png`) via Kitty-direct graphics protocol.
  - Displays host information, active media player, CPU temperatures, and installation age (calculated dynamically in days since your root directory creation).

---

### 6. CAVA Audio Visualizer
* **Visual Styling (`cava/config`)**:
  - Configured for stereo, 60 FPS Pipewire input.
  - Custom vertical gradient transitioning from deep purple at the bottom to hot pink and white at the top (`#3d0066` → `#5e1a99` → `#8833cc` → `#b84dcc` → `#d966cc` → `#ff64d1` → `#ff99e0` → `#ffffff`).
  - Slight EQ adjustments: boosted bass, cut mid-tones, and boosted trebles for visual responsiveness.

---

### 7. Hyprland Compositor Styling
* **Window Decorations (`hypr/looknfeel.conf`)**:
  - Extreme rounded window corners (`rounding = 35`) matching the rounded elements of the Dynamic Island layout.
  - Custom transparency rules: Standard windows default to `0.75` active / `0.65` inactive opacity. Ghostty is set to `1.0` active / `0.70` inactive. Spotify runs at `0.60` transparency.
* **Autostart Services (`hypr/autostart.conf`)**:
  - Standardizes paths and exports `OMARCHY_PATH`.
  - Loads cursor configurations (`catppuccin-mocha-mauve-cursors`).
  - Initializes `kdeconnectd` indicators, `ydotoold` input automation daemons, custom hot-corners script, and loads Hyprland plug-ins (`hyprpm load-all`).

---

## ⌨️ Keybindings Reference

These keybindings are configured in `hypr/bindings.conf`:

### Application Launchers
| Binding | Action | Command / Target |
|---------|--------|------------------|
| `Super + Return` | Launch Terminal | Ghostty |
| `Super + Alt + Return` | Launch Terminal + Tmux | Ghostty running Tmux |
| `Super + Shift + Return` | Open Web Browser | Omarchy Browser |
| `Super + Shift + F` | Open File Manager | Nautilus |
| `Super + Alt + Shift + F` | File Manager at CWD | Nautilus initialized at terminal CWD |
| `Super + X` | Launch IDE | VS Code |
| `Super + B` | Launch Firefox | Firefox |
| `Super + Alt + B` | Launch Private Firefox | Firefox Private Window |
| `Super + Shift + B` | Launch Brave | Brave Browser |
| `Super + M` | Launch Spotify | Spotify (adblock-enabled) |
| `Super + Shift + A` | Launch ChatGPT WebApp | ChatGPT |
| `Super + Shift + Y` | Launch YouTube WebApp | YouTube |
| `Super + Shift + E` | Launch Email WebApp | HEY Email |
| `Super + Shift + C` | Launch Calendar WebApp | HEY Calendar |
| `Super + Shift + Alt + G` | Launch WhatsApp WebApp | WhatsApp Web |
| `Super + Shift + P` | Launch Photos WebApp | Google Photos |
| `Super + Shift + X` | Launch X WebApp | X (Twitter) |

### Desktop & Widget Controls
| Binding | Action | Target / Command |
|---------|--------|------------------|
| `Super + Q` | Wallpaper Toggle | `~/.scripts/wall-toggle.sh` |
| `Super + E` | Next Wallpaper | `~/.scripts/wall-next.sh` |
| `Super + T` | Focus Time Toggle | Screen time tracker daemon |
| `Super + R` | Start Dynamic Island | Launch QuickShell (Dynamic Island) |
| `Super + Shift + R` | Kill Dynamic Island | Terminate all QuickShell instances |
| `Super + Tab` | Workspace Overview | Toggle Workspace Overview Layer |
| `Print` | Screenshot Area (Copy) | `grimblast copy area` |
| `Super + Print` | Screenshot Area (Save) | `grimblast save area` |
| `Shift + Print` | Screenshot Screen (Copy) | `grimblast copy screen` |
| `Super + Shift + L` | Screen sleep | Turn off displays via `dpms` |

### Media Controls
| Binding | Action |
|---------|--------|
| `Ctrl + Space` / `Super + Z` | Play / Pause |
| `Ctrl + Alt + Right` | Next Track |
| `Ctrl + Alt + Left` | Previous Track |
| `Ctrl + Alt + Up` | Volume Up |
| `Ctrl + Alt + Down` | Volume Down |
| `Ctrl + Alt + M` | Mute Toggle |

---

## 📂 File Architecture

```
.
├── bg/                        # Wallpaper collection (31 high-res files)
├── cava/                      # CAVA audio visualizer layout configuration
├── dynamic_island/            # QML & QuickShell Dynamic Island application
│   ├── IslandBackend/              # Compiled C++ QML helper plugin (libIslandBackend.so)
│   ├── ConnectivityBackend/        # Compiled C++ QML network plugin (libConnectivityBackend.so)
│   ├── bin/                        # Python lyrics proxy + MPRIS tools
│   └── *.qml                       # QML layouts (Calendar, Pomodoro, PetCat, etc.)
├── fastfetch/                 # Fastfetch system info layout and graphic assets
├── ghostty/                   # Ghostty terminal styling and behavior configuration
├── hypr/                      # Main Hyprland configuration directory
│   ├── scripts/                    # Wallpaper switchers & window manager utilities
│   └── shaders/                    # GLSL screen shaders (broken symlinks, see Notes)
├── scripts/                   # System utilities (Vault scripts, Fuzzy Finder)
├── starship/                  # Starship shell prompt configuration
├── waybar/                    # Status bar configurations and custom python/bash widgets
└── zsh/                       # Shell configurations (.zshrc startup wrapper and modular files)
```

---

## ⚙️ Installation & Configuration

### Symlink Targets
Configurations are designed to be placed inside `~/.config/`. Clone the repository and establish symlinks manually:

```bash
# Core Configurations
ln -sf ~/dotfiles/hypr ~/.config/hypr
ln -sf ~/dotfiles/waybar ~/.config/waybar
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/cava ~/.config/cava
ln -sf ~/dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# Zsh Environment Setup
ln -sf ~/dotfiles/zsh/zsh ~/.config/zsh
ln -sf ~/dotfiles/zsh/.zsh ~/.zsh
```

---

## ⚠️ Notes & Known Caveats

* **Omarchy Framework**: Keybindings, autostart sequences, and theme layouts require Omarchy configurations to be present in `~/.local/share/omarchy/`.
* **Broken Shaders**: The 138 GLSL shaders located inside `hypr/shaders/` are broken symlinks pointing to `/usr/share/aether/shaders/` and will not work unless the Aether shaders package is installed.
* **Stale Folder**: The `hyprland/` directory is duplicate/stale metadata (remnants of older versions). Focus only on `hypr/` for actual configurations.
* **Large Files**: The repository contains large pre-compiled binary plugins (`lyricsmpris.orig` and `lyricsmpris.patched` inside `dynamic_island/bin/` are ~10MB each) and background images (`bg/` folder).
* **System Specific Paths**: Some alias configs in `zsh/zsh/aliases.zsh` reference absolute paths for `/home/cipheroot/` and local network IP addresses (`192.168.1.*`). Be sure to customize these for your system.
