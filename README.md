# Cipheroot's Dotfiles

<p align="center">
  <strong>Arch Linux · Hyprland · Catppuccin Mocha · Omarchy</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white&labelColor=313244" alt="Arch Linux">
  <img src="https://img.shields.io/badge/WM-Hyprland-33ccff?style=for-the-badge&logo=hyprland&logoColor=white&labelColor=313244" alt="Hyprland">
  <img src="https://img.shields.io/badge/Theme-Catppuccin_Mocha-f5e0dc?style=for-the-badge&logo=catppuccin&logoColor=white&labelColor=313244" alt="Catppuccin">
</p>

Welcome to my daily-driver Arch Linux setup. It's built on top of the Omarchy framework, runs on Hyprland, and is completely saturated in Catppuccin Mocha (because who doesn't love purple?). 

I've spent way too much time tweaking this setup. The crown jewel is my custom **Dynamic Island**—a macOS-style overlay that I built from scratch using QML and QuickShell. I also built a completely custom, RAM-only **Encryption Vault** script for my files.

---

## 🏝️ The Dynamic Island (QuickShell)

This isn't just a gimmick to look like macOS; it's practically the nerve center of my desktop. It's a floating capsule at the top of the screen that morphs into **27 different UI layers** depending on what's happening.

*   **Media & Lyrics:** Shows album art and playback controls, but the coolest part is the synced lyrics. I built a Python backend proxy that hits LRCLib, caches results in a SQLite zstd database, and feeds them to the island.
*   **Productivity Tools:** Fully integrated Pomodoro timer (25/5 min sessions), Stopwatch, Calendar, and a 15-item Clipboard history viewer.
*   **AI Prompt:** I baked a chat interface directly into the island that can talk to Ollama and OpenAI APIs.
*   **Workspace Overview:** A live Hyprland workspace grid that shows real-time window thumbnails.
*   **The Backends:** To make all this run smoothly without lagging the compositor, I had to write custom **C++ backends** (for battery, audio, brightness, lyrics, Hyprland IPC, WiFi, and Bluetooth) and **Python backends** (for the lyrics proxy, AI web search, and volume mixer).
*   **Desktop Pet:** Swipe on the island and you'll find a desktop pet cat drawn entirely on a QML Canvas using over 900 lines of logic. Because why not?

## 🔐 The Encryption Vault (v5.2)

I needed a way to encrypt sensitive stuff without leaving traces on the disk, so I wrote my own bash-based vault pipeline (`scripts/enc` & `dec`). It treats data like classified documents.

*   **Zero Disk Footprint:** All processing happens entirely in RAM (`/dev/shm`), strictly capped at 100MiB. It streams `tar | compress | openssl enc`, meaning only the final ciphertext file ever touches your actual SSD.
*   **The Crypto:** It uses an **Argon2id KDF** (t=3, m=16MiB, p=4) and supports 6 ciphers. My default is **AES-256-GCM**, but it also falls back to AES-256-CTR+HMAC, ChaCha20+HMAC, etc.
*   **Compression:** Supports 10 different algorithms (zstd, gzip, lz4, bzip2, xz, brotli, 7z/LZMA, zlib, lzop).
*   **Verification:** It runs HMAC-SHA256 verification over the header and ciphertext, and even does a post-write trial decryption to ensure the data isn't corrupted before you delete the originals. It also has 5-layer traversal guards to prevent path extraction attacks.

## 🎨 UI & Aesthetics

Everything is designed to be cohesive, semi-transparent, and heavily rounded.

*   **Hyprland:** I use a massive 35px window rounding to match the Dynamic Island. Window opacities are carefully tuned (0.75/0.65 for most apps, 1.0/0.70 for the terminal, 0.60 for Spotify). 
*   **Waybar:** Custom rounded modules styled with JetBrainsMono Nerd Font Propo. It features a 60fps unicode CAVA visualizer (`▁▂▃▄▅▆▇█`), live `vnstat` network traffic, weather (`wttr.in`) that auto-hides when media is playing, and a ProtonVPN country detector with local caching.
*   **Terminal Environment:** I use **Ghostty** (0.5 opacity, borderless) rendering the VictorMono Nerd Font at 12px. The shell is **Zsh** paired with the **Starship** prompt and 55 custom aliases to keep things fast.

---

## ⌨️ Keybindings

My whole workflow revolves around the `SUPER` key. 

### Launching Stuff
| Keybind | Action |
| :--- | :--- |
| `SUPER + Return` | Ghostty Terminal |
| `SUPER + Alt + Return` | Ghostty + Tmux |
| `SUPER + X` | VS Code |
| `SUPER + B` | Firefox |
| `SUPER + Alt + B` | Firefox (Private) |
| `SUPER + Shift + B` | Brave Browser |
| `SUPER + M` | Spotify (ad-blocked) |
| `SUPER + Shift + F` | Nautilus (File Manager) |
| `SUPER + Alt + Shift + F` | Nautilus at current working directory |
| `SUPER + Shift + D` | Lazydocker |

### Web Apps & AI
| Keybind | Action |
| :--- | :--- |
| `SUPER + Shift + A` | ChatGPT |
| `SUPER + Shift + Alt + A` | Grok |
| `SUPER + Shift + Y` | YouTube |
| `SUPER + Shift + X` | X (Twitter) |
| `SUPER + Shift + Alt + X` | Compose X Post |
| `SUPER + Shift + C` | Calendar (HEY) |
| `SUPER + Shift + E` | Email (HEY) |

### System & Island Controls
| Keybind | Action |
| :--- | :--- |
| `SUPER + R` | Start / Restart Dynamic Island |
| `SUPER + Shift + R` | Kill Dynamic Island |
| `SUPER + Alt + Q` | Launch QuickShell |
| `SUPER + Tab` | Workspace Overview |
| `SUPER + T` | Toggle Focus/Pomodoro Time |
| `SUPER + Q` | Toggle Wallpaper |
| `SUPER + E` | Next Wallpaper |
| `SUPER + Shift + L` | Turn Off Display (DPMS) |

### Media & Screenshots
| Keybind | Action |
| :--- | :--- |
| `Ctrl + Space` / `SUPER + Z` | Play / Pause |
| `Ctrl + Alt + Right/Left` | Next / Previous Track |
| `Ctrl + Alt + Up/Down` | Volume Up / Down |
| `Ctrl + Alt + M` | Mute |
| `Print` | Screenshot area to clipboard |
| `SUPER + Print` | Screenshot area to file |
| `Shift + Print` | Screenshot full screen to clipboard |

---

## 🛠️ File Structure

The repo is mostly organized by app. 

```text
./
├── hypr/               # Core WM config (bindings, monitors, autostart)
├── dynamic_island/     # All the QML magic, C++ plugins, and Python proxies
├── waybar/             # Bar config and widget scripts
├── zsh/                # Shell config (split into modular .zsh files)
├── scripts/            # Utils (this is where the enc/dec vault lives)
├── ghostty/            # Terminal emulator config
├── starship/           # Prompt config
├── cava/               # Audio visualizer config
├── fastfetch/          # Neofetch replacement config
└── bg/                 # 31 hand-picked wallpapers
```

**A few caveats if you're digging through the code:**
1. You'll see a `hyprland/` directory at the root. Ignore it—it's a stale backup. The active config is in `hypr/`.
2. The `hypr/shaders/` folder contains 138 GLSL screen shaders, but the symlinks are currently broken because they rely on an uninstalled package.
3. My Zsh aliases (`zsh/zsh/aliases.zsh`) contain some hardcoded absolute paths and private IP addresses. Don't blindly copy-paste that file!

## 📥 Installation

Because this setup relies on the [Omarchy](https://github.com/omarchy) framework for its 3-tier config layering (Omarchy defaults → Theme → User overrides), this is **not** a plug-and-play installation. 

If you want to replicate this, you'll need Arch Linux and Omarchy installed at `~/.local/share/omarchy/`.

1. **Install the ecosystem:**
   ```bash
   sudo pacman -S hyprland waybar ghostty quickshell zsh starship eza bat fzf vnstat pipewire cava qt6-base qt6-declarative qt6-wayland python
   ```
2. **Clone and link:**
   Bring down the repo and symlink the folders (e.g., `ln -sf ~/dotfiles/hypr ~/.config/hypr`) into your `~/.config` directory. 
3. **Compile the Island Backends:**
   If the Dynamic Island complains about missing C++ plugins, cd into `dynamic_island/build_backend`, run `cmake .. && make`, and ensure the `.so` files are correctly placed.

---

*Shoutout to the creators of Hyprland, QuickShell, and Catppuccin for making Linux ricing so damn fun.*
