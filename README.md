# dotfiles

<p align="center">
  <strong>Arch Linux · Hyprland · Catppuccin Mocha · Omarchy</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/cipheroot/dotfiles?style=for-the-badge&logo=github&color=f5c2e7&labelColor=313244" alt="Stars">
  <img src="https://img.shields.io/github/last-commit/cipheroot/dotfiles?style=for-the-badge&logo=git&color=a6adc8&labelColor=313244" alt="Last Commit">
  <img src="https://img.shields.io/github/repo-size/cipheroot/dotfiles?style=for-the-badge&logo=files&color=89b4fa&labelColor=313244" alt="Repo Size">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white&labelColor=313244" alt="Arch Linux">
  <img src="https://img.shields.io/badge/WM-Hyprland-33ccff?style=for-the-badge&logo=hyprland&logoColor=white&labelColor=313244" alt="Hyprland">
  <img src="https://img.shields.io/badge/Theme-Catppuccin_Mocha-f5e0dc?style=for-the-badge&logo=catppuccin&logoColor=white&labelColor=313244" alt="Catppuccin">
</p>

A premium, highly-styled Arch Linux desktop setup built on the **Omarchy** framework. Features a custom macOS-style QML **Dynamic Island** overlay, a military-grade **Encryption Vault**, and a meticulously themed **Catppuccin Mocha** environment across every component.

<p align="center">
  <a href="#highlights"><kbd>Highlights</kbd></a>
  <a href="#tech-stack"><kbd>Tech Stack</kbd></a>
  <a href="#keybindings"><kbd>Keybindings</kbd></a>
  <a href="#installation"><kbd>Installation</kbd></a>
  <a href="#file-structure"><kbd>Structure</kbd></a>
</p>

---

## Table of Contents

1. [Highlights](#highlights)
2. [Tech Stack](#tech-stack)
3. [Showcase](#showcase)
4. [Keybindings](#keybindings)
5. [Installation](#installation)
6. [File Structure](#file-structure)
7. [Notes & Caveats](#notes--caveats)
8. [Credits](#credits)

---

## Highlights

*   **Dynamic Island (QML/QuickShell)**
    *   macOS-style floating capsule that morphs into expanded panels for various system states.
    *   27 UI layers including ExpandedPlayer, ControlCenter, Notification, OSD, Calendar, Pomodoro, Timer, Stopwatch, AiPrompt, Clipboard, VolumeMixer, Lyrics, SystemInfo, PetCat, and WorkspaceOverview.
    *   State machine transitions between normal, expanded, control center, notification, and specialized tool modes.
    *   C++ backends for battery, audio, brightness, lyrics, Hyprland IPC, WiFi, and Bluetooth.
    *   Python backends for lyrics proxy (LRCLib + SQLite zstd cache), AI web search, volume mixer, and clipboard history.
    *   Desktop pet cat drawn on a Canvas with over 900 lines of logic.
    *   Control center with volume and brightness sliders, WiFi/BT toggles, and quick actions.

*   **Encryption Vault (v5.2)**
    *   High-security file encryption system using Argon2id KDF (t=3, m=16MiB, p=4).
    *   Supports 6 ciphers: AES-256-GCM (default), AES-256-CTR+HMAC, ChaCha20+HMAC, AES-128-CTR+HMAC, age, and none.
    *   10 compression algorithms including zstd, gzip, lz4, bzip2, xz, brotli, 7z/LZMA, zlib, and lzop.
    *   RAM-only processing in `/dev/shm` with a 100MiB limit to prevent disk traces.
    *   HMAC-SHA256 verification over header and ciphertext.
    *   Post-write verification that re-reads and trial-decrypts to ensure data integrity.

*   **Waybar Status Bar**
    *   Semi-transparent rounded modules with a custom Catppuccin Mocha color scheme.
    *   Custom widgets for CAVA (60fps unicode bars), VPN detection (ProtonVPN country detect + cache), weather (wttr.in + auto-hide during media), and live network traffic (vnstat).
    *   Uses JetBrainsMono Nerd Font Propo for a clean, modern look.

*   **Hyprland Configuration**
    *   Modular configuration split into specialized files for bindings, autostart, input, and look-and-feel.
    *   3-tier config layering: Omarchy defaults, theme settings, and user overrides.
    *   35px window rounding and custom opacity rules for different applications.
    *   78 RGB variables defined in `mocha.config` for consistent theming.

*   **Terminal Environment**
    *   Ghostty terminal with VictorMono Nerd Font, 0.5 opacity, and borderless design.
    *   Zsh shell with Oh My Zsh and Starship prompt.
    *   55 productivity aliases for eza, bat, fastfetch, git, and development helpers.
    *   Custom fastfetch config with a graphic logo and detailed system info.

---

## Tech Stack

| Component | Choice | Why |
| :--- | :--- | :--- |
| **Compositor** | Hyprland | Dynamic tiling, smooth animations, and Wayland native performance. |
| **Framework** | Omarchy | Provides a solid foundation for keybindings, autostart, and theme management. |
| **Colors** | Catppuccin Mocha | A soothing, high-contrast dark theme that is easy on the eyes. |
| **Terminal** | Ghostty | Fast, GPU-accelerated, and supports modern features like epoll async. |
| **Shell** | ZSH + Starship | Highly customizable prompt with fast execution and rich plugin support. |
| **Status Bar** | Waybar | Highly flexible CSS-based styling and support for custom script modules. |
| **Overlay** | QuickShell | Enables building complex, stateful UI components using QML and C++. |
| **Security** | Custom Scripts | Tailored encryption pipeline with Argon2id and AES-256-GCM for maximum privacy. |

---

## Showcase

### Dynamic Island

The centerpiece. A floating capsule at the top of your screen that morphs into 27 different UI layers based on system state:

| State | What You Get |
| :--- | :--- |
| **Normal** | Minimal capsule showing active workspace icon |
| **Music** | Album art, track info, controls, synced lyrics, 8-bar audio visualizer |
| **Control Center** | Volume/brightness sliders, WiFi/BT toggles, clock, quick actions |
| **Notifications** | Desktop notification display with dismiss |
| **Pomodoro** | 25/5 min timer with session counter |
| **AI Prompt** | Chat interface compatible with Ollama and OpenAI APIs |
| **Clipboard** | History viewer (15-item store) |
| **Workspace Overview** | Live Hyprland workspace grid with window thumbnails |

Swipe gestures reveal system info (CPU, RAM, disk, temperature) and a desktop pet cat drawn entirely on Canvas.

### Encryption Vault

A command-line encryption tool that treats your data like classified documents:

```bash
# Encrypt a directory
enc -l "my-secrets" -a 1 -c 1 secret_folder/

# Decrypt it
dec my-secrets.vault
```

**Security model**: All processing happens in RAM (`/dev/shm`) — nothing touches disk. The pipeline streams `tar | compress | openssl enc` so only one ciphertext file exists at a time. Decryption includes 5-layer traversal guards against path attacks.

### Waybar & CAVA

Semi-transparent rounded modules with Catppuccin Mocha colors per category:

| Widget | Behavior |
| :--- | :--- |
| **CAVA** | 60fps Unicode audio bars (`▁▂▃▄▅▆▇█`), flat when paused |
| **VPN** | ProtonVPN country detection with local cache |
| **Weather** | wttr.in forecasts, auto-hides during media playback |
| **Traffic** | vnstat live speeds + daily/monthly totals |

### Hyprland Compositor

- **35px window rounding** matching the Dynamic Island aesthetic
- **Opacity rules**: 0.75/0.65 default, 1.0/0.70 Ghostty, 0.60 Spotify
- **3-tier config**: Omarchy defaults → theme → user overrides
- **78 Catppuccin Mocha RGB variables** in `mocha.config`
- **138 GLSL shader effects** available (requires `aether` package)

### Terminal Environment

- **Ghostty**: VictorMono Nerd Font 12px, 50% opacity, borderless, epoll async
- **Zsh**: Oh My Zsh + Starship prompt + 55 productivity aliases
- **Fastfetch**: Custom logo, CPU temps, install age, magenta theme

---

## Keybindings

### Application Launchers

| Keybind | Action |
| :--- | :--- |
| `SUPER + Return` | Launch Terminal (Ghostty) |
| `SUPER + Alt + Return` | Launch Terminal + Tmux |
| `SUPER + Shift + Return` | Launch Web Browser |
| `SUPER + Shift + F` | Open File Manager (Nautilus) |
| `SUPER + Alt + Shift + F` | Open File Manager at CWD |
| `SUPER + Shift + D` | Launch Docker (lazydocker) |
| `SUPER + Shift + G` | Open Signal |
| `SUPER + X` | Open VS Code |
| `SUPER + A` | Open Antigravity |
| `SUPER + B` | Open Firefox |
| `SUPER + Alt + B` | Open Firefox Private |
| `SUPER + Shift + B` | Open Brave |
| `SUPER + M` | Open Spotify (adblock) |

### Web Apps

| Keybind | Action |
| :--- | :--- |
| `SUPER + Shift + A` | Open ChatGPT |
| `SUPER + Shift + Alt + A` | Open Grok |
| `SUPER + Shift + C` | Open Calendar (HEY) |
| `SUPER + Shift + E` | Open Email (HEY) |
| `SUPER + Shift + Y` | Open YouTube |
| `SUPER + Shift + Alt + G` | Open WhatsApp |
| `SUPER + Shift + P` | Open Google Photos |
| `SUPER + Shift + X` | Open X (Twitter) |
| `SUPER + Shift + Alt + X` | Compose X Post |

### Desktop & Widget Controls

| Keybind | Action |
| :--- | :--- |
| `SUPER + Q` | Toggle Wallpaper |
| `SUPER + E` | Next Wallpaper |
| `SUPER + T` | Toggle Focus Time |
| `SUPER + R` | Start Dynamic Island |
| `SUPER + Shift + R` | Kill Dynamic Island |
| `SUPER + Tab` | Workspace Overview |
| `SUPER + Shift + L` | Turn Off Display (DPMS) |
| `SUPER + Alt + Q` | Launch QuickShell |

### Media Controls

| Keybind | Action |
| :--- | :--- |
| `Ctrl + Space` / `SUPER + Z` | Play / Pause |
| `Ctrl + Alt + Right` | Next Track |
| `Ctrl + Alt + Left` | Previous Track |
| `Ctrl + Alt + Up` | Volume Up |
| `Ctrl + Alt + Down` | Volume Down |
| `Ctrl + Alt + M` | Toggle Mute |

### Screenshots

| Keybind | Action |
| :--- | :--- |
| `Print` | Screenshot area to clipboard |
| `SUPER + Print` | Screenshot area to file |
| `Shift + Print` | Screenshot full screen to clipboard |

---

## Installation

> **Prerequisites**: Arch Linux with Omarchy framework installed at `~/.local/share/omarchy/`

<details>
<summary><strong>Step 1: Core Dependencies</strong></summary>

```bash
# Window Manager & Desktop
sudo pacman -S hyprland waybar ghostty quickshell

# Shell & Prompt
sudo pacman -S zsh starship
# Oh My Zsh (manual install)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Theme
yay -S catppuccin-mocha-mauve-cursors

# Terminal Tools
sudo pacman -S eza bat fzf ueberzugpp vnstat jq
yay -S grimblast-git

# Audio
sudo pacman -S pipewire cava

# Framework
# Omarchy must be installed separately from ~/.local/share/omarchy/
```
</details>

<details>
<summary><strong>Step 2: Dynamic Island Dependencies</strong></summary>

```bash
# Qt6 for QML runtime
sudo pacman -S qt6-base qt6-declarative qt6-wayland

# Python backends
sudo pacman -S python python-cryptography imagemagick

# Compile C++ plugins (optional, pre-built .so files included)
cd dynamic_island/build_backend
mkdir build && cd build
cmake .. && make
```
</details>

<details>
<summary><strong>Step 3: Encryption Vault Dependencies</strong></summary>

```bash
# Core tools
sudo pacman -S openssl argon2 tar coreutils

# Optional: AES-256-GCM support
sudo pacman -S python-cryptography

# Optional: age format support
sudo pacman -S age

# Optional: compression algorithms
sudo pacman -S zstd lz4 brotli lzop p7zip gzip bzip2 xz
```
</details>

<details>
<summary><strong>Step 4: Waybar Widget Dependencies</strong></summary>

```bash
# Audio visualizer
sudo pacman -S cava

# Network traffic monitor
sudo pacman -S vnstat

# Weather (uses curl internally)
sudo pacman -S curl

# VPN detection (reads ProtonVPN config)
# No extra packages needed
```
</details>

<details>
<summary><strong>Step 5: Symlink Configuration</strong></summary>

```bash
# Clone the repository
git clone https://github.com/cipheroot/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core configurations
ln -sf ~/dotfiles/hypr ~/.config/hypr
ln -sf ~/dotfiles/waybar ~/.config/waybar
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/cava ~/.config/cava
ln -sf ~/dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# Zsh environment
ln -sf ~/dotfiles/zsh/zsh ~/.config/zsh
ln -sf ~/dotfiles/zsh/.zsh ~/.zsh

# Dynamic Island (QuickShell)
ln -sf ~/dotfiles/dynamic_island ~/.config/quickshell/dynamic_island
```
</details>

<details>
<summary><strong>Step 6: Autostart Services</strong></summary>

The following services launch automatically via `hypr/autostart.conf`:
- Catppuccin Mocha Mauve cursor
- KDE Connect daemon + indicator
- ydotoold (input automation)
- Hyprland plugins (`hyprpm load-all`)
- Hot corners script
- Dynamic Island (QuickShell)
</details>

---

## File Structure

```text
./
├── hypr/               # Hyprland WM config (modular .conf files)
│   ├── scripts/        # Shell helpers (wallpaper toggle, qs_manager)
│   └── shaders/        # 138 GLSL screen shaders (BROKEN symlinks)
├── dynamic_island/     # QML/QuickShell Dynamic Island overlay app
│   ├── bin/            # Python lyrics proxy + MPRIS tools
│   ├── IslandBackend/  # Compiled C++ QML plugin
│   └── ConnectivityBackend/ # Compiled C++ QML plugin
├── waybar/             # Status bar config + widget scripts
├── zsh/                # ZSH config (modular .zsh files)
├── scripts/            # Utility scripts (enc/dec vault, fuzzy finder)
├── fastfetch/          # System info display config
├── ghostty/            # Terminal emulator config
├── starship/           # Prompt config
├── cava/               # Audio visualizer config
└── bg/                 # Wallpaper collection (31 images)
```

---

## Notes & Caveats

*   **Broken Shaders**: The 138 GLSL shaders in `hypr/shaders/` are currently broken symlinks. They point to `/usr/share/aether/shaders/`, which requires the `aether` package to be installed.
*   **Stale Directory**: The `hyprland/` directory is a duplicate of `hypr/` and is likely stale. Use the `hypr/` directory for all active configurations.
*   **Hardcoded Paths**: Some aliases in `zsh/zsh/aliases.zsh` contain absolute home paths and private IP addresses. Please review these before use.
*   **Large Files**: This repository tracks some large files like `proxy.log` (1.5MB) and `lyricsmpris.orig` (9.9MB). These are committed artifacts that may be cleaned up in the future.
*   **Omarchy Dependency**: This setup requires the Omarchy framework to be installed in `~/.local/share/omarchy/` for keybindings and autostart to work correctly.

---

## Credits

*   **Omarchy**: For the desktop framework and core logic.
*   **Catppuccin**: For the Mocha color palette used throughout the system.
*   **Hyprland**: For the smooth and powerful Wayland compositor.
*   **QuickShell**: For the foundation of the Dynamic Island overlay.
*   **JetBrains & VictorMono**: For the excellent Nerd Fonts.

---
