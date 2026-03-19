# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make build      # Compile release binary (swift build -c release)
make run        # Run in development (swift run)
make app        # Build .app bundle via scripts/build-app.sh
make dmg        # Create distributable DMG
make install    # Copy .app to /Applications and create default config
make uninstall  # Remove from /Applications
make clean      # Remove .build/ and build/ directories
make config     # Create ~/.config/audiotier/config.json if missing
```

There are no tests or linting tools configured in this project.

## Architecture

AudioTier is a macOS menu bar app (Swift, AppKit, CoreAudio) that automatically switches default audio I/O devices based on a user-configured priority list. It runs as `LSUIElement` (no Dock icon).

**Layer structure:**

- `AudioManager.swift` — CoreAudio wrapper. Enumerates devices, gets/sets system defaults, registers a CoreAudio property listener for device list changes. Filters out virtual/aggregate devices (Zoom, etc.).
- `AudioTier.swift` — Business logic singleton (`AudioTier.shared`). Called when devices change; walks the priority list and sets the highest-priority connected device via `AudioManager`.
- `AppDelegate.swift` — Wires everything together. Builds the menu bar NSStatusItem, calls `AudioTier.applyPriorities()` on device changes, hot-reloads config using `DispatchSourceFileSystemObject`.
- `Config.swift` — Loads/saves `~/.config/audiotier/config.json` as `DeviceConfig` (Codable struct with `audioInput: [String]` and `audioOutput: [String]`).
- `ConfigWindow.swift` — Priority editor UI: two `NSTableView`s with drag-drop reordering, add/remove buttons backed by connected-device lists.

**Device switching flow:**
1. CoreAudio listener fires → `AppDelegate` calls `AudioTier.applyPriorities()`
2. `AudioTier` finds the first config-listed device that is currently connected
3. `AudioManager` sets it as system default via `kAudioHardwarePropertyDefaultInputDevice` / `kAudioHardwarePropertyDefaultOutputDevice`
4. A macOS user notification is posted and the menu is rebuilt

**Config file:** `~/.config/audiotier/config.json` — device names in priority order. The app hot-reloads this file on changes without restarting.

**Bundle ID:** `com.cod3hulk.audiotier` | **Minimum macOS:** 13.0 (Ventura)
