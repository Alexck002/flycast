# Flycast iOS Build Guide

## Overview

Flycast is a Dreamcast/Naomi/Atomiswave emulator. This documents the iOS build process targeting TrollStore (iOS 14–15.x) and SideStore/AltStore + StikDebug (iOS 16+ including iOS 26.x) with JIT (ARM64 dynarec) support.

## Status (2026-04-27)

Flycast confirmed running at 60 FPS across the full iOS support matrix:

| iOS | Device class | Loader / JIT activation | JIT strategy | State |
|-----|--------------|------------------------|--------------|-------|
| 14.6 | iPhone (unc0ver jailbreak) | TrollStore "Open with JIT" | LEGACY (RWX `mmap`) | **Working** |
| 15.1 | iPhone (Dopamine jailbreak) | TrollStore "Open with JIT" | LEGACY (RWX `mmap`) | **Working** |
| 18.2 | iPhone 16 Pro Max (iPhone17,2) | SideStore + StikDebug debugger-attach | MAP_JIT (single-mapped, `pthread_jit_write_protect_np`) | **Working** |
| 26.3 | iPhone 11 (A13) | SideStore + StikDebug debugger-attach | TXM (vm_remap dual-mapping) | **Working** |

The runtime selects strategy purely by iOS major version (`ios_jit_manager.m::ios_determine_jit_type`), not by TXM file detection — that detection was unreliable on devices without TXM hardware (e.g. A13 / iPhone 11 on iOS 26.x).

## Fix history

### iOS 26 EXC_BREAKPOINT during init (fixed 2026-04-26)

**Root cause:** `core/hw/sh4/dyna/ngen.h` — the `CC_RW2RX` / `CC_RX2RW` macros were the identity function on iOS because they were gated only on `FEAT_NO_RWX_PAGES` (Switch-only). The dual-mapping JIT path correctly populated `cc_rx_offset = RX − RW`, but the SH4 dispatcher then ran `CC_RW2RX(block->code)` and got the **non-executable RW alias** back unchanged. Executing at the RW address triggered SIGBUS, which the fault handler couldn't recover from, ending in `die("segfault")` → `EXC_BREAKPOINT (SIGTRAP)`.

**Fix:** added `TARGET_IPHONE` to the gating in `ngen.h`:

```c
#if defined(FEAT_NO_RWX_PAGES) || defined(TARGET_IPHONE)
    extern ptrdiff_t cc_rx_offset;
    #define CC_RW2RX(ptr) (void*)(((uintptr_t)(ptr)) + cc_rx_offset)
    #define CC_RX2RW(ptr) (void*)(((uintptr_t)(ptr)) - cc_rx_offset)
#else
    #define CC_RW2RX(ptr) (ptr)
    #define CC_RX2RW(ptr) (ptr)
#endif
```

The MAP_JIT (single-mapped) path returns `rx_offset = 0`, so on iOS 14–25 the macros are still effectively identity transformations.

### iOS 18.2 CODESIGNING / Invalid Page on game launch (fixed 2026-04-27)

**Symptom:** with StikDebug attached and `CS_DEBUGGED` set, the app opened to the menu fine; selecting a game crashed with `EXC_BAD_ACCESS / KERN_PROTECTION_FAILURE` and `CODESIGNING / Invalid Page` in the termination namespace, faulting in a `vm_remap`-aliased shared-memory page.

**Root cause:** the dual-mapping path (`mmap(PROT_READ|PROT_EXEC) + vm_remap` for the RW alias) produced shared-memory pages whose code-signing status iOS 18.2's CodeSigning Monitor rejected at instruction fetch even with `CS_DEBUGGED`. iOS 26.3 (with TXM) and iOS 14/15 (RWX) take different paths that don't hit this rejection.

**Fix:** route iOS 14–25 down a single-mapped `MAP_JIT` strategy with `pthread_jit_write_protect_np()` for W↔X toggling; keep `vm_remap` dual-mapping only on iOS 26+. Selection happens in `ios_determine_jit_type()` based purely on iOS major version.

**Note:** CODESIGNING kills are *not* deliverable as `SIGBUS`/`SIGSEGV`/`SIGILL` — the kernel terminates the process before any user-space signal handler runs. The startup `ios_jit_is_available()` is detection-only via `csops() & CS_DEBUGGED`; it never executes JIT'd code (an execute-probe can't be guarded against the CodeSigning Monitor).

### iOS 26.3 brk #0x69 trap on A13/A14 (fixed 2026-04-27)

The earlier TXM path registered the JIT pool with the iOS 26 Trusted Execution Monitor via `brk #0x69` and suballocated from a 512 MB lwmem pool. That trap is undefined on devices without TXM hardware (A13/A14) and crashed the iPhone 11 on iOS 26.3 immediately after the JIT path activated. Replaced with a plain per-allocation `vm_remap` dual-mapping in `vmem_txm.cpp` — works across all iOS 26+ hardware (TXM and non-TXM). The `lwmem.c` / `lwmem_sys_apple.c` files remain in the build but are dead code and can be removed in a future cleanup.

**Startup safety guard:** `AppDelegate.mm` `didFinishLaunchingWithOptions` schedules a 4-second deferred `csops(CS_DEBUGGED)` check; if JIT still isn't granted at that point (giving AltKit's `checkTryDebug()` time to run via `FlycastViewController` `viewDidLoad`), a `UIAlertController` shows: *"JIT is required. Please activate JIT via StikDebug or AltStore before launching a game."*

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
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_BREAKPAD=NO \
  -G Xcode
```

The minimum is **iOS 14.0**, required for `MAP_JIT` + `pthread_jit_write_protect_np()` so JIT works on iOS 26+ via debugger-attach mechanisms (StikDebug, JitStreamer). iOS 15.1 jailbreak with TrollStore continues to work — the JIT path falls back to legacy RWX `mmap` if `MAP_JIT` is rejected (see `core/linux/posix_vmem.cpp`).

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

Current working entitlements (TrollStore on iPadOS 14.6/15.1 A12Z **and** SideStore/StikDebug on iOS 26.3):
- `com.apple.developer.kernel.increased-memory-limit` — higher memory cap for emulation workloads
- `com.apple.security.cs.allow-jit` — allow `MAP_JIT` mappings on iOS 14+
- `com.apple.security.cs.allow-unsigned-executable-memory` — required alongside `allow-jit` so unsigned JIT pages can execute
- `get-task-allow` — allows debugger / JIT-helper attachment (required by both TrollStore "Open with JIT" and StikDebug)

JIT permission is granted **at runtime**, not by an entitlement:
- **TrollStore (iOS 14–15.x):** long-press the app → "Open with JIT" (uses `PT_TRACE_ME` / debugserver).
- **iOS 16+ / iOS 26.x:** sideload via SideStore or AltStore, then attach with **StikDebug** to grant JIT.

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

JIT memory allocation on iOS lives in `core/linux/posix_vmem.cpp::prepare_jit_block` (iOS path) and the `vmem_*.cpp` strategy files. `vmem_dispatch.cpp` selects one of three strategies at runtime, dispatched purely on iOS major version (`ios_jit_manager.m::ios_determine_jit_type`):

1. **TXM dual-mapping** (`vmem_txm.cpp`, iOS 26+): per-allocation `mmap(PROT_READ|PROT_EXEC) + vm_remap` to obtain a writable alias of the same physical pages. `cc_rx_offset = RX − RW` is set so the recompilers write to the RW alias and the dispatcher executes from the RX alias. No `brk #0x69` TXM monitor registration — that trap is undefined on A13/A14.
2. **`MAP_JIT` mmap** (`vmem_no_txm.cpp`, iOS 14–25): single-mapped `mmap(MAP_JIT)`; W↔X toggled per-thread with `pthread_jit_write_protect_np()` (resolved via `dlsym` because the SDK marks it `__API_UNAVAILABLE(ios)` even though it exists at runtime). Falls back to plain RWX `mmap` if `MAP_JIT` is rejected (TrollStore jailbreak case). `rx_offset = 0` so `CC_RW2RX/CC_RX2RW` are identity.
3. **Legacy RWX** (`vmem_legacy.cpp`, iOS <14): plain RWX `mmap` with `mprotect`-based W↔X.

`vmem_dispatch.cpp` exposes `virtmem::ios_jit_write_protect(base, len, enable)` which selects the right toggle mechanism per strategy (no-op for TXM, `pthread_jit_write_protect_np` for MAP_JIT, `mprotect` for LEGACY/fallback). The per-recompiler `jitWriteProtect` overrides in `rec_arm64.cpp`, `arm7_rec_arm64.cpp`, and `dsp_arm64.cpp` all route through this. `JITWriteProtect()` in `core/types.h` is a no-op on iOS.

**Critical invariant:** the SH4 dispatcher and any code that converts between RW (writable) and RX (executable) pointers **must** use `CC_RW2RX` / `CC_RX2RW` from `ngen.h`. These macros are gated on `defined(FEAT_NO_RWX_PAGES) || defined(TARGET_IPHONE)`. Removing `TARGET_IPHONE` from that guard reintroduces the iOS 26 EXC_BREAKPOINT crash documented above.

JIT permission is granted at runtime via TrollStore's "Open with JIT" (iOS 14–15.x) or StikDebug debugger attach (iOS 16+ / iOS 26.x), not through entitlements.

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
The `tinygettext` dependency uses `std::filesystem::directory_iterator` which requires iOS 13.0+. The current minimum is iOS 14.0 (raised for `MAP_JIT` / `pthread_jit_write_protect_np`); do not set the deployment target below 14.0.
