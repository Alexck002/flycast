// Copyright 2025 Flycast Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>
#include "ios_jit_manager.h"

#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR

#include <unistd.h>
#include <sys/types.h>

#define CS_OPS_STATUS 0
#define CS_DEBUGGED 0x10000000

#ifdef __cplusplus
extern "C" {
#endif

int csops(pid_t pid, unsigned int ops, void* useraddr, size_t usersize);

#ifdef __cplusplus
}
#endif

static NSString* filePathAtPath(NSString* path, NSUInteger length) {
    NSError *error = nil;
    NSArray<NSString *> *items = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:path error:&error];
    if (!items) {
        return nil;
    }
    
    for (NSString *entry in items) {
        if (entry.length == length) {
            return [path stringByAppendingPathComponent:entry];
        }
    }
    return nil;
}

int ios_major_version(void) {
    static int cached = -1;
    if (cached < 0) {
        NSOperatingSystemVersion v = [[NSProcessInfo processInfo] operatingSystemVersion];
        cached = (int)v.majorVersion;
    }
    return cached;
}

bool ios_device_has_txm(void) {
    // Only check on iOS 26+
    if (@available(iOS 26, *)) {
        // Primary path: /System/Volumes/Preboot/<36>/boot/<96>/usr/.../Ap,TrustedExecutionMonitor.img4
        NSString* bootUUID = filePathAtPath(@"/System/Volumes/Preboot", 36);
        if (bootUUID) {
            NSString* bootDir = [bootUUID stringByAppendingPathComponent:@"boot"];
            NSString* ninetySixCharPath = filePathAtPath(bootDir, 96);
            if (ninetySixCharPath) {
                NSString* img = [ninetySixCharPath stringByAppendingPathComponent:
                    @"usr/standalone/firmware/FUD/Ap,TrustedExecutionMonitor.img4"];
                if (access(img.fileSystemRepresentation, F_OK) == 0) {
                    return true;
                }
            }
        }
        
        // Fallback path: /private/preboot/<96>/usr/.../Ap,TrustedExecutionMonitor.img4
        NSString* fallback = filePathAtPath(@"/private/preboot", 96);
        if (fallback) {
            NSString* img = [fallback stringByAppendingPathComponent:
                @"usr/standalone/firmware/FUD/Ap,TrustedExecutionMonitor.img4"];
            if (access(img.fileSystemRepresentation, F_OK) == 0) {
                return true;
            }
        }
    }
    
    return false;
}

bool ios_process_is_debugged(void) {
    int flags;
    if (csops(getpid(), CS_OPS_STATUS, &flags, sizeof(flags)) != 0) {
        return false;
    }
    return (flags & CS_DEBUGGED) != 0;
}

bool ios_running_under_xcode(void) {
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    
    // Check for Xcode-specific environment variables
    // Xcode sets these when running/debugging an app
    NSString* xcodeVersion = [environment objectForKey:@"XCODE_PRODUCT_BUILD_VERSION"];
    if (xcodeVersion != nil) {
        return true;
    }
    
    // Check for DYLD settings that Xcode uses
    NSString* dyldInsert = [environment objectForKey:@"DYLD_INSERT_LIBRARIES"];
    if (dyldInsert != nil && [dyldInsert containsString:@"/Xcode.app/"]) {
        return true;
    }
    
    // When debugging with Xcode, it often sets these
    if ([environment objectForKey:@"IDE_DISABLED_OS_ACTIVITY_DT_MODE"] != nil) {
        return true;
    }
    
    // For simulator builds, Xcode sets SIMULATOR_*
    if ([environment objectForKey:@"SIMULATOR_DEVICE_NAME"] != nil) {
        // Check if it's actually Xcode (not just simulator runtime)
        NSString* dyldLibraryPath = [environment objectForKey:@"DYLD_LIBRARY_PATH"];
        if (dyldLibraryPath != nil && [dyldLibraryPath containsString:@"/Xcode.app/"]) {
            return true;
        }
    }
    
    return false;
}

IOSJitType ios_determine_jit_type(void) {
    static bool initialized = false;
    static IOSJitType result = IOS_JIT_LEGACY;

    if (!initialized) {
        initialized = true;

        int major = ios_major_version();
        bool is_debugged = ios_process_is_debugged();

        NSLog(@"[Flycast JIT] Runtime detection: iOS major=%d, debugged=%@",
              major, is_debugged ? @"YES" : @"NO");

        // Strategy is chosen by iOS major version, not by TXM file detection,
        // because the latter is unreliable on devices without TXM hardware
        // (e.g. A13 / iPhone 11 running iOS 26.x). Behaviour by version:
        //   iOS 26+   : vm_remap dual-mapping. CodeSigning Monitor on
        //               iOS 26 accepts vm_remap'd JIT pages with CS_DEBUGGED.
        //   iOS 14-25 : single-mapped MAP_JIT with pthread_jit_write_protect_np.
        //               iOS 18 specifically rejects vm_remap'd JIT pages
        //               (CODESIGNING termination), so dual-mapping must be
        //               avoided here.
        //   iOS <14   : legacy RWX mmap (jailbreak / TrollStore).
        if (major >= 26) {
            NSLog(@"[Flycast JIT] iOS %d → TXM (vm_remap dual-mapping)", major);
            result = IOS_JIT_TXM;
        } else if (major >= 14) {
            NSLog(@"[Flycast JIT] iOS %d → MAP_JIT (single-mapped, pthread_jit_write_protect_np)", major);
            result = IOS_JIT_MAP_JIT;
        } else {
            NSLog(@"[Flycast JIT] iOS %d → LEGACY (RWX mmap)", major);
            result = IOS_JIT_LEGACY;
        }

        NSLog(@"[Flycast JIT] Selected strategy: %s", ios_jit_type_description(result));
    }

    return result;
}

// Detection only — never executes JIT'd code, since on iOS 18+ /
// iOS 26+ a page can be mapped r-x but the CodeSigning Monitor kills
// the process when an unsigned instruction is fetched. Such kills
// land in the CODESIGNING termination namespace and cannot be caught
// by SIGBUS/SIGSEGV/SIGILL handlers.
//
// Canonical signal that JIT is granted: csops() reports CS_DEBUGGED.
// All supported activation paths set this:
//   - TrollStore "Open with JIT" attaches debugserver -> CS_DEBUGGED
//   - StikDebug attaches a debugger                   -> CS_DEBUGGED
//   - JitStreamer / SideStore debug attach            -> CS_DEBUGGED
//   - AltKit's checkTryDebug() fork+ptrace            -> CS_DEBUGGED
bool ios_jit_is_available(void) {
    if (ios_device_has_txm()) {
        if (ios_running_under_xcode()) {
            NSLog(@"[Flycast JIT] TXM device under Xcode. JIT unavailable.");
            return false;
        }
        // iOS 26+ TXM devices: JIT only works with a non-Xcode debugger.
    }

    bool debugged = ios_process_is_debugged();
    if (!debugged) {
        NSLog(@"[Flycast JIT] CS_DEBUGGED not set. JIT not granted.");
    }
    return debugged;
}

const char* ios_jit_type_description(IOSJitType type) {
    switch (type) {
        case IOS_JIT_LEGACY:
            return "LEGACY (debugger-based JIT)";
        case IOS_JIT_MAP_JIT:
            return "MAP_JIT (standard dual-mapping)";
        case IOS_JIT_TXM:
            return "TXM (iOS 26+ dual-mapped pool)";
        default:
            return "UNKNOWN";
    }
}

#endif // TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
