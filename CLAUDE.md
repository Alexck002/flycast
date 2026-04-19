# Flycast iOS Build Guide

## Overview

Flycast is a Dreamcast/Naomi/Atomiswave emulator. This documents the iOS build process targeting TrollStore with JIT (ARM64 dynarec) support.

## Prerequisites

```bash
brew install cmake ninja ccache ldid
```

All other dependencies are vendored as git submodules. No Vulkan SDK needed (Vulkan is force-disabled for iOS).

Xcode must be selected (not just Command Line Tools):
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Submodules must be initialized:
```bash
git submodule update --init --recursive
```

## Build Commands

### Configure
```bash
cmake -B build-ios \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_BREAKPAD=NO \
  -G Xcode
```

### Build
```bash
cmake --build build-ios --config Release --target flycast -- -quiet
```

### Package IPA
The CMake `Flycast.IPA` target fails because it tries to `bitcode_strip` a non-existent `Frameworks/*.dylib` directory. Package manually instead:

```bash
cd build-ios
rm -rf Payload
mkdir -p Payload
cp -r Release-iphoneos/Flycast.app Payload/
python3 tools/patch_sdk_version.py Payload/Flycast.app/Flycast 15.1
ldid -Sshell/apple/emulator-ios/emulator/flycast.entitlements Payload/Flycast.app/Flycast
zip -r -q Release-iphoneos/Flycast.ipa Payload
```

The `patch_sdk_version.py` script patches both the Mach-O `LC_BUILD_VERSION` SDK field and the Info.plist `DTPlatformVersion`, `DTSDKName`, `DTPlatformBuild`, and `DTSDKBuild` fields to match the target iOS version. This is required when building with a newer Xcode than the target device (see Known Issues).

The entitlements path in the ldid command is relative to the repo root. If running from `build-ios/`, use the full path.

## TrollStore Entitlements

File: `shell/apple/emulator-ios/emulator/flycast.entitlements`

Current working entitlements for TrollStore on iPadOS 15.1 (A12Z):
- `com.apple.developer.kernel.extended-virtual-addressing` — full 64-bit address space for emulation
- `com.apple.developer.kernel.increased-memory-limit` — higher memory cap for emulation workloads
- `get-task-allow` — allows debugging and JIT attachment

JIT must be enabled at runtime via TrollStore's **"Open with JIT"** option (long-press the app in TrollStore's app list). This uses `PT_TRACE_ME`/debugserver to grant JIT permission without requiring banned entitlements.

### Entitlements that must NOT be used on iPadOS 15 A12+

The following entitlements are **banned by PPL (Page Protection Layer)** on iOS/iPadOS 15 with A12+ chips. Apps signed with any of these crash instantly on launch:
- `dynamic-codesigning` — banned, causes immediate AMFI rejection
- `com.apple.private.cs.debugger` — banned
- `com.apple.private.skip-library-validation` — banned

Additionally, `platform-application` causes AMFI to treat the app as a first-party Apple binary (`"is_first_party":1` in crash reports). On iPadOS 15.1 with A12Z (iPad Pro 2020), this triggers stricter code signing validation that `ldid` ad-hoc signatures cannot pass, resulting in an immediate `EXC_BREAKPOINT (SIGTRAP)` crash during initialization. Other emulators (MeloNX, DolphiniOS) may use `platform-application` on newer iOS versions or different TrollStore configurations where this validation is bypassed, but it is not safe for iPadOS 15.1 + A12Z + ldid signing.

The entitlements `com.apple.private.security.no-sandbox` and `com.apple.private.security.storage.AppDataContainers` are not banned by PPL but are unnecessary when `platform-application` is not used, as the app retains its normal sandbox container.

## JIT / Dynarec Details

Three JIT recompilers are enabled by default on ARM64 (defined in `core/build.h`):
- **FEAT_SHREC** — SH4 main CPU recompiler (`core/rec-ARM64/rec_arm64.cpp`)
- **FEAT_AREC** — ARM7 AICA sound CPU recompiler (`core/hw/arm7/arm7_rec.cpp`)
- **FEAT_DSPREC** — AICA DSP recompiler (`core/hw/aica/dsp_arm64.cpp`)

JIT memory allocation uses `mmap` with `PROT_READ | PROT_WRITE | PROT_EXEC` on iOS (`core/linux/posix_vmem.cpp:248-283`). The `JITWriteProtect()` function in `core/types.h` is a no-op on iOS (guarded by `#ifndef TARGET_IPHONE`), toggling write protection via `mprotect` instead (see per-recompiler `JITWriteProtect` overrides in `rec_arm64.cpp`, `arm7_rec_arm64.cpp`, `dsp_arm64.cpp`). JIT permission is granted at runtime via TrollStore's "Open with JIT" rather than through entitlements (see TrollStore Entitlements section).

The iOS Simulator disables all dynarec (`core/build.h:41-44`, `TARGET_NO_REC`).

## Build Configuration Notes

- Vulkan is force-disabled for iOS in `CMakeLists.txt:104-106`
- iOS uses OpenGL ES 3.0 (GLES + GLES3 defines)
- Swift 5.0 is enabled for AltKit integration
- Bundle ID: `com.flyinghead.Flycast`

## Known Issues

### Xcode SDK version vs older iPadOS
Building with a modern Xcode embeds that SDK version in both the binary's `LC_BUILD_VERSION` load command and the Info.plist (`DTPlatformVersion`, `DTSDKName`, `DTPlatformBuild`, `DTSDKBuild`). iPadOS performs stricter validation than iOS on iPhones — all these fields must be internally consistent and not claim an SDK newer than the device OS.

Use `tools/patch_sdk_version.py` to fix all fields at once:
```bash
python3 tools/patch_sdk_version.py Payload/Flycast.app/Flycast 15.1
```
This patches the Mach-O binary and Info.plist to consistently claim the specified SDK version (e.g., 15.1 with build `19B74`). It also removes `DTXcode`/`DTXcodeBuild` fields that reveal the true build toolchain. Supported target versions are listed with `--help`.

### Flycast.IPA CMake target
The automatic IPA target (`Flycast.IPA`) runs `bitcode_strip` on `Frameworks/*.dylib` which doesn't exist in the current build. Use the manual packaging steps above instead.

### std::filesystem and deployment target
The `tinygettext` dependency uses `std::filesystem::directory_iterator` which requires iOS 13.0+. Do not set the deployment target below 13.0.
