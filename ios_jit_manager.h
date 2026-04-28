// Copyright 2025 Flycast Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#ifdef __APPLE__
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR

#ifdef __cplusplus
extern "C" {
#endif

// JIT strategy types for different iOS device configurations
typedef enum {
    IOS_JIT_LEGACY,      // Older devices - debugger-based JIT
    IOS_JIT_MAP_JIT,     // Non-TXM devices - standard MAP_JIT
    IOS_JIT_TXM          // TXM devices (iOS 26+) - dual-mapped memory pool
} IOSJitType;

// Returns the iOS major version reported by NSProcessInfo
// (e.g. 14, 15, 18, 26). Used to choose the JIT strategy at runtime.
int ios_major_version(void);

// Returns true if device has TXM (iOS 26+ with TXM firmware)
bool ios_device_has_txm(void);

// Returns true if process is being debugged
bool ios_process_is_debugged(void);

// Returns true if running under Xcode (incompatible with TXM)
bool ios_running_under_xcode(void);

// Determines the appropriate JIT strategy for the current device
// This is the main function to call during initialization
IOSJitType ios_determine_jit_type(void);

// Returns a human-readable description of the JIT type
const char* ios_jit_type_description(IOSJitType type);

// Probes whether JIT is actually usable on the current device:
// allocates a JIT-eligible page, writes a single ARM64 `ret`,
// and tries to execute it under SIGBUS/SIGSEGV/SIGILL guards.
// Returns true only if the probe both allocated and successfully executed.
// Safe to call once at startup before any emulator init / signal handlers.
bool ios_jit_is_available(void);

#ifdef __cplusplus
}
#endif

#endif // TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
#endif // __APPLE__
