# 🌌 Cipheroot's Dotfiles

<p align="center">
  <strong>Arch Linux · Hyprland · Catppuccin Mocha · Omarchy</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white&labelColor=313244" alt="Arch Linux">
  <img src="https://img.shields.io/badge/WM-Hyprland-33ccff?style=for-the-badge&logo=hyprland&logoColor=white&labelColor=313244" alt="Hyprland">
  <img src="https://img.shields.io/badge/Framework-Omarchy-f5c2e7?style=for-the-badge&logo=linux&logoColor=white&labelColor=313244" alt="Omarchy">
  <img src="https://img.shields.io/badge/Theme-Catppuccin_Mocha-f5e0dc?style=for-the-badge&logo=catppuccin&logoColor=white&labelColor=313244" alt="Catppuccin">
  <img src="https://img.shields.io/badge/Shell-Zsh_%2B_Starship-fab387?style=for-the-badge&logo=gnubash&logoColor=white&labelColor=313244" alt="Zsh">
  <img src="https://img.shields.io/badge/Terminal-Ghostty-a6e3a1?style=for-the-badge&logo=alacritty&logoColor=white&labelColor=313244" alt="Ghostty">
</p>

<p align="center">
  <a href="#-highlights"><kbd>Highlights</kbd></a> •
  <a href="#-the-dynamic-island-quickshell"><kbd>Dynamic Island</kbd></a> •
  <a href="#-configuration-application"><kbd>Settings App</kbd></a> •
  <a href="#-mobile-ecosystem--kde-connect"><kbd>Mobile Integration</kbd></a> •
  <a href="#-the-encryption-vault-v52"><kbd>Encryption Vault</kbd></a> •
  <a href="#-keybindings"><kbd>Keybindings</kbd></a> •
  <a href="#-installation"><kbd>Installation</kbd></a> •
  <a href="#-file-structure"><kbd>File Structure</kbd></a>
</p>

---

Welcome to my daily-driver Arch Linux setup. Built on top of the **Omarchy** desktop framework and driven by the **Hyprland** Wayland compositor, every pixel is carefully styled in the **Catppuccin Mocha** color palette.

This environment blends fluid visuals with daily productivity: featuring a macOS-inspired **Dynamic Island** overlay built from scratch in QML and C++, a dedicated Qt/QML **Settings & Configuration App**, deep **KDE Connect & Mobile Ecosystem** status bar integration, and a military-grade RAM-only **Encryption Vault**.

---

## 🌟 Highlights

* **🏝️ Dynamic Island**: Floating top-bar capsule morphing into 27+ modular QML layers (media, synchronized lyrics, control center, AI assistant, clipboard history, pomodoro, workspace grid, and drag-and-drop file shelf).
* **⚙️ Dynamic Island Config App**: Full graphical settings utility written in Qt6/QML and C++ with wallpaper thumbnail previews, shortcut customization, typography tuning, and TLP power profile switching.
* **📱 Mobile Ecosystem & KDE Connect**: Waybar widgets and system triggers for phone battery, Bluetooth earbuds battery, notification sync, wireless SFTP storage mounting, and wireless `scrcpy` screen mirroring with automatic ADB port detection.
* **🔐 Encryption Vault (v5.2)**: High-security bash vault with zero SSD footprint, operating strictly inside a 100MiB RAM buffer (`/dev/shm`) with Argon2id KDF, AES-256-GCM / ChaCha20 ciphers, HMAC verification, and 10 compression formats.
* **🎨 Cohesive Aesthetics**: 35px rounded corners, tuned opacity levels, 60fps unicode CAVA visualizer, live `vnstat` network telemetry, and 64 curated wallpapers with instant hotkey cycling.

---

## 🏝️ The Dynamic Island (QuickShell)

The Dynamic Island sits at the top of the screen as an unobtrusive capsule and expands on demand into specialized modules:

### 🧩 Layer Architecture
Organized into 6 modular domains under `dynamic_island/qml/`:

1. **Island Modes (`qml/island/`)**:
   * **Expanded Player**: Album artwork, track metadata, playback scrubbers, and live CAVA visualizer.
   * **Synchronized Lyrics**: Swipe right on the media player to view real-time lyrics synced with the audio track.
   * **Clock & Timers**: Compact clock with circular progress rings indicating active stopwatch or countdown timers.
   * **OSD & Split-Icon**: Transient audio volume, screen brightness, and CapsLock indicators without compositor stutters.
   * **Notifications**: Banner alerts for system notifications.
2. **Control Center (`qml/controlcenter/`)**:
   * macOS-style toggle panel with quick controls for WiFi, Bluetooth, output audio devices, and display brightness.
   * **Volume Mixer**: Per-application PulseAudio volume mixer.
   * **Clipboard History**: 15-item clipboard history viewer with instant recall.
3. **Productivity Suite (`qml/productivity/`)**:
   * **Pomodoro**: Configurable work/break interval timer (25/5 min default) with session counters.
   * **Stopwatch & Timer**: Multi-lap stopwatch and countdown timer with numpad input.
   * **Calendar**: Interactive monthly calendar with event navigation.
   * **TODO List Popup**: Markdown-backed checklist reading directly from `~/.local/share/todo.md`.
4. **Workspace Overview (`qml/workspace/`)**:
   * Live Hyprland workspace thumbnail grid (`SUPER + TAB`) allowing interactive window drag, focus, and close actions.
5. **Extras & Desktop Companion (`qml/extras/`)**:
   * **AI Prompt**: Integrated chat interface supporting local Ollama or OpenAI endpoints, enhanced with real-time DuckDuckGo web search context injection.
   * **Dropzone / File Shelf**: Quick file shelf layer backed by C++ `FileShelfModel` for drag-and-drop staging.
   * **Desktop Pet Cat**: An interactive animated desktop cat rendered entirely on a QML Canvas across 900+ lines of procedural logic.

### ⚡ Backends & Performance
To keep animations smooth at full monitor refresh rates, heavy work is offloaded to native plugins:
* **C++ Backend (`IslandBackend`)**: Built with Qt6, DBus, and udev to provide instant signals for battery health, audio streams, brightness control, Bluetooth pairing agent (`BluetoothPairingAgent.cpp`), and NetworkManager WiFi controller (`WifiController.cpp`).
* **Python Microservices (`dynamic_island/bin/`)**:
  * `clean_lyrics_proxy.py`: Local HTTP lyrics service (port 8765) querying LRCLib with SQLite zstd caching.
  * `ai_web_search.py`: Context retrieval for AI prompts.
  * `get_volume_mixer.py`: PulseAudio sink-inputs exporter.
  * `nmcli_backend.py` & `speedtest-cli`: Network discovery and speed testing.

---

## ⚙️ Configuration Application

A dedicated settings GUI (`dynamic-island-config-app`) makes customizing the island intuitive:

<p align="center">
  <img src="https://img.shields.io/badge/GUI-Qt6_QML-41CD52?style=for-the-badge&logo=qt&logoColor=white&labelColor=313244" alt="Qt6">
  <img src="https://img.shields.io/badge/Language-Modern_C%2B%2B-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white&labelColor=313244" alt="C++">
</p>

* **General**: Adjust island position, capsule padding, animation easing, and default states.
* **Wallpapers**: Interactive visual wallpaper browser with live thumbnail caching and automatic background applying.
* **Typography**: Preview and customize system fonts (bundled with Inter and Lora font families).
* **Shortcut Editor**: Configure Hyprland key combinations and QuickShell IPC triggers directly from the UI.
* **Interaction Settings**: Fine-tune swipe thresholds, edge-snap behaviors, and mouse hover triggers.
* **AI & Power**: Configure Ollama/OpenAI API tokens and adjust TLP battery profiles.

> **Launch Command**: Run `dynamic_island/open-settings.sh` or trigger the desktop shortcut.

---

## 📱 Mobile Ecosystem & KDE Connect

Waybar is extended with dedicated shell and Python integrations for mobile devices:

| Module | Script | Description |
| :--- | :--- | :--- |
| **Phone Battery** | `waybar/phone_battery.sh` | Queries battery level and charging status over KDE Connect DBus. Automatically hides when disconnected. |
| **Earbuds Battery** | `waybar/earbuds_battery.sh` | Monitors Bluetooth earbuds battery levels via BlueZ and UPower. Auto-hides when disconnected. |
| **Notifications** | `waybar/phone_notifications.sh` | Shows an unread notification counter badge synced from your phone. |
| **Phone Storage** | `waybar/phone_storage.sh` | Mounts and opens your phone's storage in the file manager wirelessly via KDE Connect SFTP. |
| **Screen Mirror** | `waybar/mirror.sh` & `phone_mirror.sh` | Launches low-latency wireless phone screen mirroring using `scrcpy`, auto-detecting the wireless ADB port or pairing via KDE Connect. |

---

## 🔐 The Encryption Vault (v5.2)

Located in `scripts/enc` and `scripts/dec`, this custom encryption pipeline treats confidential data with zero SSD footprint:

* **Zero Disk Residue**: All packaging, compression, and encryption execute strictly within RAM (`/dev/shm`), capped at 100MiB. Plaintext data never touches physical storage blocks.
* **Cryptographic Foundation**: Key derivation uses **Argon2id** ($t=3$, $m=16\text{MiB}$, $p=4$). Encryption defaults to **AES-256-GCM** with authenticated data, supporting AES-256-CTR+HMAC and ChaCha20+HMAC fallbacks.
* **Multi-Format Compression**: Supports 10 compression algorithms: `zstd`, `gzip`, `lz4`, `bzip2`, `xz`, `brotli`, `7z/LZMA`, `zlib`, and `lzop`.
* **Integrity Validation**: Computes HMAC-SHA256 checksums over headers and ciphertext, executing a post-write trial decryption in RAM to verify integrity before original files are removed.
* **Path Traversal Defense**: 5-layer sanitization shields against archive extraction attacks.

```bash
# Encrypt a file or folder into RAM-only vault
scripts/enc -c aes-256-gcm -z zstd /path/to/confidential

# Decrypt an encrypted vault file
scripts/dec /path/to/confidential.enc
```

---

## 🎨 UI & Aesthetics

* **Hyprland Compositor**: 35px window rounding matching the Dynamic Island capsule curvature. Opacities are individually tuned per window class (0.75 active / 0.65 inactive for most apps, 1.0/0.70 for terminals, 0.60 for Spotify).
* **Waybar Status Bar**: Custom semi-transparent dark rounded modules styled with JetBrainsMono Nerd Font Propo. Displays 60fps CAVA visualizer bars (`▁▂▃▄▅▆▇█`), live `vnstat` network rates, ProtonVPN status with local country cache, and weather (`wttr.in`) that gracefully collapses when media is playing.
* **Terminal**: **Ghostty** (0.5 opacity, borderless) rendering VictorMono Nerd Font at 12px. The shell is **Zsh** paired with the **Starship** prompt and 55 custom aliases.
* **Wallpapers**: 64 curated wallpapers stored in `bg/` with instantaneous switching via `SUPER + Q` and `SUPER + E`.

---

## ⌨️ Keybindings

The primary modifier key is `SUPER`.

### 🚀 Applications
| Keybind | Action |
| :--- | :--- |
| `SUPER + Return` | Ghostty Terminal |
| `SUPER + Alt + Return` | Ghostty Terminal with Tmux Session |
| `SUPER + Shift + Return` | Default Browser (Omarchy) |
| `SUPER + A` | Antigravity AI IDE |
| `SUPER + X` | VS Code |
| `SUPER + B` | Firefox |
| `SUPER + Alt + B` | Firefox (Private Window) |
| `SUPER + Shift + B` | Brave Browser |
| `SUPER + M` | Spotify (with ad-block preload) |
| `SUPER + Shift + F` | Nautilus File Manager |
| `SUPER + Alt + Shift + F` | Nautilus at current terminal directory |
| `SUPER + Shift + D` | Lazydocker TUI |
| `SUPER + Shift + G` | Signal Desktop |

### 🌐 Web Apps & AI
| Keybind | Action |
| :--- | :--- |
| `SUPER + Shift + A` | ChatGPT Web App |
| `SUPER + Shift + Alt + A` | Grok Web App |
| `SUPER + Shift + C` | HEY Calendar |
| `SUPER + Shift + E` | HEY Email |
| `SUPER + Shift + Y` | YouTube |
| `SUPER + Shift + Alt + G` | WhatsApp Web |
| `SUPER + Shift + P` | Google Photos |
| `SUPER + Shift + X` | X (Twitter) |
| `SUPER + Shift + Alt + X` | Compose New X Post |

### 🏝️ Dynamic Island & System
| Keybind | Action |
| :--- | :--- |
| `SUPER + R` | Start / Restart Dynamic Island |
| `SUPER + Shift + R` | Kill Dynamic Island |
| `SUPER + Tab` | Toggle Workspace Overview (Window Thumbnails) |
| `SUPER + T` | Toggle FocusTime Screen Tracker |
| `SUPER + Q` | Toggle Wallpaper View |
| `SUPER + E` | Cycle Next Wallpaper |
| `SUPER + Alt + Q` | Launch QuickShell root |
| `SUPER + Shift + L` | Turn Off Display (DPMS) |

### 🎵 Media & Volume
| Keybind | Action |
| :--- | :--- |
| `Ctrl + Space` / `SUPER + Z` | Play / Pause Track |
| `Ctrl + Alt + Right` / `Left` | Next / Previous Track |
| `Ctrl + Alt + Up` / `Down` | Volume Up / Down |
| `Ctrl + Alt + M` | Mute / Unmute Audio |

### 📸 Screenshots
| Keybind | Action |
| :--- | :--- |
| `Print` | Screenshot selected area to clipboard |
| `SUPER + Print` | Screenshot selected area to file (`~/Pictures`) |
| `Shift + Print` | Screenshot entire screen to clipboard |

---

## 🛠️ File Structure

```text
./
├── install.sh             # Automated installation & bootstrapping script
├── hypr/                  # Hyprland WM config (modular .conf files & scripts)
│   ├── bindings.conf      # Super-based application, media, and island bindings
│   ├── autostart.conf     # Autostart daemon rules (KDE Connect, ydotoold, QS)
│   ├── mocha.config       # Catppuccin Mocha master color palette
│   └── scripts/           # QS manager, wallpaper switcher, focus-time toggles
├── dynamic_island/        # QuickShell Dynamic Island overlay
│   ├── qml/               # Modular QML UI layers (core, island, controlcenter, etc.)
│   ├── config-app/        # Qt6/QML graphical configuration app
│   ├── backend/           # C++ plugins (SysBackend, Wifi, Bluetooth, FileShelf)
│   ├── bin/               # Python microservices (lyrics proxy, volume mixer, speedtest)
│   ├── fonts/             # Bundled typography assets
│   ├── open-settings.sh   # Launcher script for settings application
│   └── CMakeLists.txt     # Unified build file for IslandBackend & config-app
├── waybar/                # Status bar config, styling, and mobile integration
│   ├── config.jsonc       # Module layout and grouping
│   ├── style.css          # Catppuccin Mocha stylesheet
│   └── *.sh / *.py        # Phone battery, earbuds, mirror, CAVA, VPN, traffic scripts
├── zsh/                   # Modular Zsh configurations (aliases, env, keybinds, tools)
├── scripts/               # System utilities (enc/dec vault v5.2, fuzzy finder)
├── ghostty/               # Ghostty terminal emulator config
├── starship/              # Starship prompt configuration
├── cava/                  # CAVA audio visualizer config
├── fastfetch/             # System information display config
├── hyprland/              # Stale backup directory (reference only; use hypr/)
└── bg/                    # Curated collection of 64 wallpapers (including bg/wallpapers/)
```

---

## 📥 Installation

This configuration is built for **Arch Linux** using the **Omarchy** desktop framework.

### Prerequisites
1. **Arch Linux** installed and running.
2. The **Omarchy** framework cloned to `~/.local/share/omarchy/`:
   ```bash
   git clone https://github.com/omarchy/omarchy.git ~/.local/share/omarchy
   ```
3. Standard internet access (the installer will automatically bootstrap `yay-bin` if neither `yay` nor `paru` is present).

### Method 1: Automated Setup (Recommended)
Clone the repository and run the automated installer:
```bash
git clone https://github.com/cipheroot/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

**What `install.sh` handles automatically:**
1. Detects `yay` or `paru` (or automatically bootstraps `yay-bin` from the AUR if neither is installed).
2. Installs official repository packages (`hyprland`, `waybar`, `ghostty`, `zsh`, `starship`, `qt6`, `pipewire`, `cava`, etc.).
3. Installs required AUR packages (`quickshell`, `catppuccin-mocha-mauve-cursors`, `grimblast-git`, `ueberzugpp`).
4. Sets executable permissions on all shell scripts, Python helpers, and compiled binaries.
5. **Safely backs up** any existing configuration directories and files to `~/.dotfiles_backup/<timestamp>/` before symlinking.
6. Symlinks configurations into `~/.config/` (`hypr`, `waybar`, `ghostty`, `cava`, `fastfetch`, `zsh`, `starship`, `dynamic_island`, and `~/.zshrc`).
7. Compiles the Dynamic Island C++ backend plugins and settings app via CMake.

### Method 2: Manual Installation
<details>
<summary>Click to view manual step-by-step commands</summary>

1. **Install Core Packages:**
   ```bash
   sudo pacman -S --needed hyprland waybar ghostty zsh starship eza bat fzf vnstat jq \
       pipewire cava qt6-base qt6-declarative qt6-wayland python python-cryptography imagemagick \
       openssl argon2 tar coreutils age zstd lz4 brotli lzop p7zip gzip bzip2 xz curl cmake make gcc
   yay -S --needed quickshell catppuccin-mocha-mauve-cursors grimblast-git ueberzugpp
   ```

2. **Symlink Directories:**
   ```bash
   ln -sfn ~/dotfiles/hypr ~/.config/hypr
   ln -sfn ~/dotfiles/waybar ~/.config/waybar
   ln -sfn ~/dotfiles/ghostty ~/.config/ghostty
   ln -sfn ~/dotfiles/cava ~/.config/cava
   ln -sfn ~/dotfiles/fastfetch ~/.config/fastfetch
   ln -sfn ~/dotfiles/zsh/zsh ~/.config/zsh
   ln -sfn ~/dotfiles/zsh/.zsh ~/.zsh
   ln -sfn ~/dotfiles/starship/starship.toml ~/.config/starship.toml
   mkdir -p ~/.config/quickshell
   ln -sfn ~/dotfiles/dynamic_island ~/.config/quickshell/dynamic_island
   ```

3. **Build C++ Island Plugins:**
   ```bash
   cmake -B ~/dotfiles/dynamic_island/build -S ~/dotfiles/dynamic_island
   cmake --build ~/dotfiles/dynamic_island/build
   ```

4. **Change Shell:**
   ```bash
   chsh -s $(which zsh)
   ```
</details>

---

## ⚠️ Notes & Caveats

* **GLSL Shaders**: Symlinks in `hypr/shaders/` point to `/usr/share/aether/shaders/` and require the `aether` package.
* **Config Directory**: The root `hyprland/` folder is a stale backup; all active Hyprland configurations are located in `hypr/`.
* **Shell Aliases**: `zsh/zsh/aliases.zsh` contains personalized aliases with local paths and IP addresses. Review this file before adopting it as your own.
* **Tracked Binaries Cleaned**: Large logs and precompiled `.so` files have been purged from version control; builds are now generated cleanly via CMake.

---

## 👏 Credits & Acknowledgments

* **[Omarchy](https://github.com/omarchy)** for the foundational desktop configuration framework.
* **[Catppuccin](https://github.com/catppuccin/catppuccin)** for the iconic Mocha color palette.
* **[Hyprland](https://github.com/hyprwm/Hyprland)** for the fluid Wayland compositor.
* **[QuickShell](https://github.com/outfoxxed/quickshell)** for enabling flexible, reactive desktop widget authoring in QML.
* **[KDE Connect](https://kdeconnect.kde.org/)** & **[scrcpy](https://github.com/Genymobile/scrcpy)** for mobile device bridging.
