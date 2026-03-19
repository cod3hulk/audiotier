<p align="center">
  <img src="assets/icon.png" alt="AudioTier icon" width="200">
</p>

# AudioTier

A lightweight macOS menu bar app that automatically switches your default audio input and output devices based on a configurable priority list.

The name is a play on words: **Audio** + **Tier** (priority levels) — and in German, *Tier* means *animal*, which explains the cute creature in the app icon.

When you dock or undock your MacBook, AudioTier detects which devices are connected and sets the system default to the highest-priority available device — no manual switching needed.

## Features

- **Automatic switching** — monitors device connect/disconnect events via CoreAudio and applies your priority list instantly
- **Priority-based config** — define a ranked list of preferred devices for both input and output; the highest-priority connected device wins
- **Menu bar UI** — shows current active devices, lets you manually override, and includes a built-in config editor
- **macOS notifications** — notifies you when a device switch occurs
- **Config hot-reload** — edit `~/.config/audiotier/config.json` and changes apply immediately

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+ (included with Xcode 15+)

## Build

```bash
# Build the release binary
make build

# Build the .app bundle (includes icon generation)
make app

# Build a distributable DMG
make dmg
```

## Install

```bash
# Copy AudioTier.app to /Applications
make install
```

Or build the DMG with `make dmg` and drag the app to Applications from the disk image.

## Configuration

On first launch, AudioTier generates a config file at `~/.config/audiotier/config.json` listing all connected devices. Reorder the lists to set your priority — the first device in each list is the highest priority.

```json
{
    "audioInput": [
        "Scarlett Solo 4th Gen",
        "MacBook Pro Microphone"
    ],
    "audioOutput": [
        "AirPods Pro 2",
        "MacBook Pro Speakers"
    ]
}
```

You can edit this file directly or use **Edit Config...** from the menu bar icon.

## Uninstall

```bash
make uninstall
```
