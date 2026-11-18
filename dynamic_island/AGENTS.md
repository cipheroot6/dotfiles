# dynamic_island/

Custom QML/QuickShell Dynamic Island overlay for Hyprland — macOS-style floating capsule that morphs into expanded panels, backed by C++ plugins, a Python lyrics server, and a dedicated Qt6/QML Configuration App.

## STRUCTURE

```
dynamic_island/
├── shell.qml                    # Entry point: Scope → UserConfig → DynamicIslandWindow per screen
├── CMakeLists.txt               # Unified CMake build (IslandBackend QML module + config-app)
├── open-settings.sh             # Shell launcher for dynamic-island-config-app
├── dynamic-island-config-app    # Compiled settings app executable (Qt6/QML)
│
├── qml/                         # Modular QML UI layers
│   ├── core/
│   │   ├── DynamicIslandWindow.qml  # Core state machine (all island states & capsule transforms)
│   │   ├── UserConfig.qml           # Global config (fonts, pet toggle, mouse bindings, AI endpoint)
│   │   ├── HyprlandData.qml         # Hyprland IPC data provider (hyprctl clients/monitors/workspaces)
│   │   ├── WallpaperThumbnailCache.qml # ImageMagick wallpaper thumbnail generator
│   │   └── qmldir                   # Module registration for core components
│   ├── island/
│   │   ├── ClockLayer.qml           # Time display with stopwatch/timer indicator rings
│   │   ├── ExpandedPlayerLayer.qml  # Media player: album art, track info, controls, visualizer
│   │   ├── NotificationLayer.qml    # Desktop notification banner display
│   │   ├── OsdLayer.qml             # Volume/brightness/capslock progress + text
│   │   ├── SplitIconLayer.qml       # Transient icon-only capsule for status changes
│   │   ├── SwipeCavaBars.qml        # 8-bar audio visualizer component
│   │   ├── SwipeCustomInfoLayer.qml # Left-swipe system info (CPU, RAM, disk, temp, CAVA)
│   │   ├── SwipeDatePreviewLayer.qml# Date/time preview during side-swipe gestures
│   │   └── SwipeLyricsLayer.qml     # Right-swipe synchronized lyrics display
│   ├── controlcenter/
│   │   ├── ControlCenterLayer.qml   # macOS-style control center: volume/brightness, wifi/bt, clock
│   │   ├── ConnectivityDetailPanel.qml # WiFi/Bluetooth detail sub-panels (scan, connect, pairing)
│   │   ├── VolumeMixerLayer.qml     # Per-app volume mixer (PulseAudio)
│   │   └── ClipboardLayer.qml       # Clipboard history viewer (15 items)
│   ├── productivity/
│   │   ├── CalendarLayer.qml        # Monthly calendar with navigation
│   │   ├── PomodoroLayer.qml        # Pomodoro timer (25/5 min, session counter)
│   │   ├── StopwatchLayer.qml       # Stopwatch with lap times
│   │   ├── TimerLayer.qml           # Countdown timer with numpad input
│   │   └── TodoPopup.qml            # Markdown-based TODO list (reads ~/.local/share/todo.md)
│   ├── workspace/
│   │   ├── WorkspaceLayer.qml       # Workspace number label on capsule switch
│   │   ├── WorkspaceOverviewLayer.qml # Hyprland workspace overview grid
│   │   └── WorkspaceOverviewWindow.qml # Individual window thumbnail (drag/focus/close)
│   └── extras/
│       ├── AiPromptLayer.qml        # AI chat interface (Ollama/OpenAI compatible + DDG web search)
│       ├── DropzoneLayer.qml        # Drag-and-drop file shelf / dropzone layer
│       ├── PetCat.qml               # Animated desktop pet cat (900+ lines, Canvas-drawn)
│       └── save_cat.qml             # Cat animation save/export
│
├── config-app/                  # Dynamic Island Settings Application (Qt6 C++ & QML)
│   ├── Main.qml                 # Main window & navigation sidebar
│   ├── General.qml              # General behavior & capsule settings
│   ├── Wallpaper.qml            # Visual wallpaper selector & customizer
│   ├── WallpaperSettings.qml    # Wallpaper transition/caching settings
│   ├── FontSettings.qml         # Font selection & typography previews
│   ├── Shortcut.qml             # Interactive shortcut & keybinding editor
│   ├── Interaction.qml          # Gestures, edge triggers, click behaviors
│   ├── AI.qml                   # AI model, API keys, and endpoint configurations
│   ├── TlpSettings.qml          # TLP battery & power management settings
│   ├── ApplicationLauncherSettings.qml # App launcher preferences
│   ├── backend.cpp / .hpp       # C++ backend bridge (settings persistence, system control)
│   ├── CMakeLists.txt           # Build config for the config application
│   └── dynamic-island-config.desktop # Desktop launcher entry
│
├── backend/                     # Modern C++ backend source (IslandBackend QML module)
│   ├── BluetoothPairingAgent.cpp/.h # BlueZ DBus Bluetooth pairing agent
│   ├── CompositorBackend.cpp/.h     # Hyprland compositor hooks & window signals
│   ├── FileShelfModel.cpp/.h        # Drag-and-drop file shelf model for DropzoneLayer
│   ├── StyleTokensBackend.cpp/.h    # Dynamic design tokens & styling
│   ├── SysBackend.cpp/.h            # Battery, audio, brightness, lyrics pipe, Hyprland IPC
│   ├── SystemServices.cpp/.h        # Systemd / system service controllers
│   ├── UserConfigBackend.cpp/.h     # User configuration store & persistence
│   ├── WifiController.cpp/.h        # NetworkManager WiFi controller via DBus
│   └── WifiNetworkModel.cpp/.h      # WiFi network list model for QML
│
├── build_backend/               # Standalone CMake build target for SysBackend plugin
│   ├── SysBackend.h/.cpp
│   └── CMakeLists.txt
│
├── bin/                         # Python & shell backend helpers
│   ├── clean_lyrics_proxy.py    # HTTP lyrics proxy (port 8765, LRCLib + SQLite zstd cache)
│   ├── ai_web_search.py         # DuckDuckGo search for AI prompt context
│   ├── get_volume_mixer.py      # PulseAudio sink-inputs JSON exporter
│   ├── append_clip.py           # Clipboard history manager (15-item JSON store)
│   ├── lyricsmpris              # Shell wrapper for MPRIS synced lyrics engine
│   ├── network_stats.py         # Network telemetry monitor
│   ├── nmcli_backend.py         # NetworkManager CLI wrapper
│   └── speedtest-cli            # Network speed test utility
│
└── fonts/                       # Bundled TTF fonts (Pacifico, DancingScript)
```

## WHERE TO LOOK

| Task | File |
|------|------|
| Island states/transitions | `qml/core/DynamicIslandWindow.qml` → `islandState` property |
| User settings (QML) | `qml/core/UserConfig.qml` → configurable properties |
| Settings App GUI | `config-app/Main.qml`, `dynamic_island/open-settings.sh` |
| Add new UI layer | Create `qml/<category>/<Name>Layer.qml`, add Loader in `DynamicIslandWindow.qml` |
| C++ backend signals | `backend/SysBackend.h`, `backend/WifiController.h`, `backend/BluetoothPairingAgent.h` |
| File drop shelf | `qml/extras/DropzoneLayer.qml`, `backend/FileShelfModel.cpp` |
| Lyrics system | `bin/clean_lyrics_proxy.py` (HTTP) + `backend/SysBackend.cpp` (pipe) |
| IPC from Hyprland | `shell.qml` → IpcHandler targets (overview, todo, pomodoro, etc.) |
| AI chat config | `qml/core/UserConfig.qml` / `config-app/AI.qml` (Ollama/OpenAI endpoints) |

## CONVENTIONS

- **Entry**: `shell.qml` → creates `UserConfig` singleton → spawns `DynamicIslandWindow` per screen via `Variants`.
- **State machine**: `islandState` string property drives all transitions (normal, expanded, control_center, notification, timer, stopwatch, pomodoro, aiprompt, clipboard, volume_mixer, dropzone).
- **Loader pattern**: All heavy layers use `Loader` — instantiated on demand, destroyed on collapse to keep compositor footprint minimal.
- **IPC**: `IpcHandler` targets for external control from Hyprland keybinds (e.g. `qs ipc -p ~/.config/quickshell/dynamic_island/shell.qml call overview toggle`).
- **C++ plugins**: Built via `CMakeLists.txt` into the `IslandBackend` QML module (providing SysBackend, WifiController, BluetoothPairingAgent, FileShelfModel).

## ANTI-PATTERNS

- **Hardcoded paths**: Verify user paths; replace any `/home/dan/` or `/home/cipheroot/` references with dynamic `StandardPaths` or environment lookups.
- **Font inconsistency**: Ensure fonts respect `UserConfig` or `FontSettings` rather than hardcoding static family names across widgets.
- **Color redundancy**: Maintain Catppuccin Mocha harmony; prefer centralized style tokens (`StyleTokensBackend` / `Theme.qml`) when adding new layers.
