// Copyright 2025 Flycast Project
// SPDX-License-Identifier: GPL-2.0-or-later

// MAP_JIT mode for non-TXM iOS devices (iOS 14-25).
// Uses a SINGLE-MAPPED MAP_JIT region — write protection is toggled per-thread
// via pthread_jit_write_protect_np(). This is the standard Apple-supported
// path documented for iOS 14+ JIT.
//
// History: previously this path used vm_remap to create paired RW/RX aliases
// of the same physical pages (analogous to the TXM iOS 26+ path). On iOS 18.2
// the kernel CodeSigning Monitor rejects instruction fetches from those
// vm_remap-aliased shared-memory pages even with CS_DEBUGGED, terminating the
// process via the CODESIGNING namespace before any signal handler runs.
// Reverting to single-mapped MAP_JIT restores iOS 18.2 functionality while
// keeping the iOS 26+ TXM dual-mapping path unaffected (see vmem_txm.cpp).

#include "types.h"

#ifdef TARGET_IPHONE

#include <sys/mman.h>
#include <pthread.h>
#include <unistd.h>
#include "oslib/virtmem.h"
#include "log/Log.h"

#ifndef MAP_JIT
#define MAP_JIT 0x800
#endif

namespace virtmem {

// Set when MAP_JIT was actually accepted by the kernel. Determines whether
// pthread_jit_write_protect_np() is the correct W↔X toggle (true) or whether
// mprotect() must be used because the page is plain RWX (false — TrollStore /
// jailbreak fallback).
bool g_uses_pthread_jit_write_protect = false;

static void* try_mmap_map_jit(size_t size)
{
    void* ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE | PROT_EXEC,
                     MAP_ANON | MAP_PRIVATE | MAP_JIT, -1, 0);
    return ptr;
}

static void* try_mmap_rwx(size_t size)
{
    void* ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE | PROT_EXEC,
                     MAP_ANON | MAP_PRIVATE, -1, 0);
    return ptr;
}

bool prepare_jit_block_map_jit(void *code_area, size_t size, void **code_area_rwx)
{
    INFO_LOG(VMEM, "MAP_JIT: Allocating single-mapped block size=%zu", size);

    void* ptr = try_mmap_map_jit(size);
    if (ptr != MAP_FAILED) {
        g_uses_pthread_jit_write_protect = true;
        INFO_LOG(VMEM, "MAP_JIT: Allocated MAP_JIT region at %p", ptr);
    } else {
        WARN_LOG(VMEM, "MAP_JIT: mmap with MAP_JIT failed (%s); trying RWX fallback", strerror(errno));
        ptr = try_mmap_rwx(size);
        if (ptr == MAP_FAILED) {
            ERROR_LOG(VMEM, "MAP_JIT: RWX fallback also failed: %s", strerror(errno));
            return false;
        }
        g_uses_pthread_jit_write_protect = false;
        INFO_LOG(VMEM, "MAP_JIT: Allocated RWX fallback region at %p", ptr);
    }

    *code_area_rwx = ptr;
    return true;
}

void release_jit_block_map_jit(void *code_area, size_t size)
{
    INFO_LOG(VMEM, "MAP_JIT: Releasing single-mapped block at %p size=%zu", code_area, size);
    munmap(code_area, size);
}

bool prepare_jit_block_map_jit_dual(void *code_area, size_t size,
                                    void **code_area_rw, ptrdiff_t *rx_offset)
{
    // Single-mapped: RW pointer == RX pointer, so rx_offset is 0 and the
    // CC_RW2RX / CC_RX2RW macros (in ngen.h, gated on TARGET_IPHONE) become
    // identity transformations. The TARGET_IPHONE guard in ngen.h must stay,
    // since the iOS 26+ TXM path returns a non-zero rx_offset.
    void* ptr = nullptr;
    if (!prepare_jit_block_map_jit(code_area, size, &ptr))
        return false;

    *code_area_rw = ptr;
    *rx_offset = 0;
    INFO_LOG(VMEM, "MAP_JIT: Single-map %p, rx_offset=0", ptr);
    return true;
}

void release_jit_block_map_jit_dual(void *code_area_rx, void *code_area_rw, size_t size)
{
    // Single-mapped: code_area_rx == code_area_rw. Free once.
    if (code_area_rw)
        munmap(code_area_rw, size);
}

// Returns true when the active MAP_JIT region requires per-thread write
// protect toggling instead of mprotect-based RW↔RX swaps.
bool map_jit_uses_pthread_write_protect()
{
    return g_uses_pthread_jit_write_protect;
}

} // namespace virtmem

#endif // TARGET_IPHONE
