# Flycast iOS

<img src="shell/linux/flycast.png" alt="flycast logo" width="150"/>

iOS port of [Flycast](https://github.com/flyinghead/flycast) — a Sega Dreamcast, Naomi, Naomi 2, and Atomiswave emulator with full ARM64 dynarec (JIT). Confirmed running at 60 FPS across iOS 14.6, 15.1, 18.2, and 26.3.

The iOS-specific JIT and build work in this fork was developed with assistance from [Anthropic](https://www.anthropic.com/)'s **Claude** (via [Claude Code](https://claude.com/claude-code)).

## Compatibility

| iOS | Install method | JIT activation |
|---|---|---|
| 14.x – 15.x (jailbreak) | TrollStore | "Open with JIT" |
| 16.x – 25.x | SideStore / AltStore | StikDebug |
| 26.x | SideStore / AltStore | StikDebug |

iOS 14.0 minimum.

## Installation

### TrollStore (iOS 14 – 15.x)
1. Download the latest `Flycast.ipa` from [Releases](../../releases).
2. Open it with TrollStore and install.
3. Long-press the Flycast icon → **Open with JIT**.
4. Launch the app.

### SideStore / AltStore + StikDebug (iOS 16+, including iOS 26)
1. Install [SideStore](https://sidestore.io) or [AltStore](https://altstore.io), and [StikDebug](https://github.com/0xilis/StikDebug).
2. Sideload `Flycast.ipa`.
3. In StikDebug, attach to Flycast to grant JIT.
4. Launch the app.

If JIT isn't active when you start a game, Flycast will show a reminder.

## Building from source

### Prerequisites

```bash
brew install cmake ninja ccache ldid
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
git submodule update --init --recursive
```

Full Xcode is required (not just Command Line Tools).

### Configure & build

```bash
cmake -B build-ios \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_BREAKPAD=NO \
  -G Xcode

cmake --build build-ios --config Release --target flycast -- -quiet
```

### Package the IPA

```bash
cd build-ios
rm -rf Payload && mkdir Payload
cp -r Release-iphoneos/Flycast.app Payload/
python3 ../tools/patch_sdk_version.py Payload/Flycast.app/Flycast 15.1
ldid -S../shell/apple/emulator-ios/emulator/flycast.entitlements Payload/Flycast.app/Flycast
zip -r -q Release-iphoneos/Flycast.ipa Payload
```

`patch_sdk_version.py` rewrites the binary's `LC_BUILD_VERSION` and the Info.plist `DT*` keys so the IPA installs on iOS versions older than the Xcode SDK used to build it.

See [`CLAUDE.md`](CLAUDE.md) for the full build and JIT architecture notes.

## Credits

- **[flyinghead](https://github.com/flyinghead)** and all Flycast contributors — the emulator itself.
- **[skmp](https://github.com/skmp)** and the original [reicast](https://github.com/skmp/reicast-emulator) project Flycast derives from.
- **[TheArcadeStriker's Flycast wiki](https://github.com/TheArcadeStriker/flycast-wiki/wiki)** — configuration and feature documentation.
- TrollStore, SideStore, AltStore, and StikDebug authors — JIT enablement on stock iOS.
- [Anthropic](https://www.anthropic.com/) — **Claude** assisted the iOS-specific JIT and build work in this fork.

Join the upstream Flycast community on the [official Discord](https://discord.gg/X8YWP8w) for general emulator discussion. iOS-specific issues belong on this fork's issue tracker.
