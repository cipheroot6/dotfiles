# dynamic_island/

Custom QML/QuickShell Dynamic Island overlay for Hyprland — macOS-style floating capsule that morphs into expanded panels.

## STRUCTURE

```
dynamic_island/
├── shell.qml                    # Entry point: Scope → UserConfig → DynamicIslandWindow per screen
├── UserConfig.qml               # Global config (fonts, pet toggle, mouse bindings, AI endpoint)
├── DynamicIslandWindow.qml      # Core state machine (~4000 lines, all island states)
├── HyprlandData.qml             # Hyprland IPC data provider (hyprctl clients/monitors/workspaces)
│
├── # UI Layers (27 files)
├── ExpandedPlayerLayer.qml      # Media player: album art, track info, controls, visualizer
├── ControlCenterLayer.qml       # macOS-style control center: volume/brightness, wifi/bt, clock
├── ConnectivityDetailPanel.qml  # WiFi/Bluetooth detail sub-panels (scan, connect, pairing)
├── NotificationLayer.qml        # Desktop notification display
├── OsdLayer.qml                 # Volume/brightness/capslock progress + text
├── SplitIconLayer.qml           # Transient icon-only capsule for status changes
├── ClockLayer.qml               # Time display with stopwatch/timer indicator rings
├── WorkspaceLayer.qml           # Workspace number label on capsule switch
├── CalendarLayer.qml            # Monthly calendar with navigation
├── AiPromptLayer.qml            # AI chat interface (Ollama/OpenAI compatible)
├── ClipboardLayer.qml           # Clipboard history viewer
├── VolumeMixerLayer.qml         # Per-app volume mixer (PulseAudio)
├── PomodoroLayer.qml            # Pomodoro timer (25/5 min, session counter)
├── TimerLayer.qml               # Countdown timer with numpad input
├── StopwatchLayer.qml           # Stopwatch with lap times
├── SwipeLyricsLayer.qml         # Right-swipe lyrics display
├── SwipeCustomInfoLayer.qml     # Left-swipe system info (CPU, RAM, disk, temp, CAVA)
├── SwipeCavaBars.qml            # 8-bar audio visualizer component
├── SwipeDatePreviewLayer.qml    # Date/time preview during side-swipe gestures
├── PetCat.qml                   # Animated desktop pet cat (929 lines, Canvas-drawn)
├── WorkspaceOverviewLayer.qml   # Hyprland workspace overview grid
├── WorkspaceOverviewWindow.qml  # Individual window thumbnail (drag/focus/close)
├── TodoPopup.qml                # Markdown-based TODO list (reads ~/.local/share/todo.md)
├── WallpaperThumbnailCache.qml  # ImageMagick wallpaper thumbnail generator
├── save_cat.qml                 # Cat animation save/export
│
├── IslandBackend/               # Deployed C++ plugin (SysBackend singleton)
│   ├── qmldir                   # Module registration
│   ├── libIslandBackend.so      # Compiled shared library (380KB)
│   └── IslandBackend.qmltypes   # QML type registry
│
├── ConnectivityBackend/         # Deployed C++ plugin (network management)
│   ├── qmldir                   # Module registration
│   └── libConnectivityBackendplugin.so  # Compiled plugin (1.6MB)
│
├── build_backend/               # C++ source + CMake build for IslandBackend
│   ├── SysBackend.h/.cpp        # Source: battery, audio, brightness, lyrics, Hyprland IPC
│   ├── CMakeLists.txt           # CMake build (Qt6, libudev, DBus)
│   └── build/                   # CMake build artifacts (gitignored)
│
├── bin/                         # Python backends
│   ├── clean_lyrics_proxy.py    # HTTP lyrics proxy (port 8765, LrcLib + SQLite cache)
│   ├── ai_web_search.py         # DuckDuckGo search for AI prompt context
│   ├── get_volume_mixer.py      # PulseAudio sink-inputs JSON exporter
│   ├── append_clip.py           # Clipboard history manager (15-item JSON store)
│   ├── lyricsmpris              # Shell wrapper for lyricsmpris.patched
│   └── lyricsmpris.patched      # MPRIS synced lyrics engine (9.9MB, gitignored)
│
├── fonts/                       # TTF fonts (Pacifico, DancingScript)
├── test_subs/                   # Subtitle .json3 test files (untracked)
└── cat.png                      # Pet cat sprite
```

## WHERE TO LOOK

| Task | File |
|------|------|
| Island states/transitions | `DynamicIslandWindow.qml` → `islandState` property |
| User settings | `UserConfig.qml` → all configurable properties |
| Add new UI layer | Create `*Layer.qml`, add Loader in `DynamicIslandWindow.qml` |
| C++ backend signals | `build_backend/SysBackend.h` → Q_PROPERTY + Q_SIGNAL |
| Lyrics system | `bin/clean_lyrics_proxy.py` (HTTP) + `IslandBackend/SysBackend.cpp` (pipe) |
| IPC from Hyprland | `shell.qml` → IpcHandler targets (overview, todo, pomodoro, etc.) |
| AI chat config | `UserConfig.qml` → ollamaEndpoint, ollamaModel, ollamaApiKey |

## CONVENTIONS

- **Entry**: `shell.qml` → creates `UserConfig` singleton → spawns `DynamicIslandWindow` per screen via `Variants`
- **State machine**: `islandState` string property drives all transitions (normal/expanded/control_center/notification/timer/stopwatch/pomodoro/aiprompt/clipboard/volume_mixer)
- **Loader pattern**: All heavy layers use `Loader` — instantiated on demand, destroyed on collapse
- **IPC**: `IpcHandler` targets for external control from Hyprland keybinds
- **C++ plugins**: IslandBackend (SysBackend) for system signals, ConnectivityBackend for network

## ANTI-PATTERNS

- **No source for ConnectivityBackend**: Only compiled `.so` in repo. Source is elsewhere or lost.
- **Hardcoded paths**: `/home/dan/` in WorkspaceOverviewLayer.qml (WRONG USER), `/home/cipheroot/` in 5+ files
- **Font inconsistency**: UserConfig defines fonts but TimerLayer/StopwatchLayer/PomodoroLayer/TodoPopup hardcode `"JetBrainsMono Nerd Font"`
- **Color inconsistency**: Each QML component defines its own Catppuccin colors (no shared palette singleton)
- **Build artifacts tracked**: `build_backend/build/` was tracked before .gitignore update
- **Large binaries**: `lyricsmpris.orig`/`.patched` (10MB each) tracked before .gitignore update
- **Scratch files**: `test_subs/`, `test_*.qml/py/js` should be gitignored
