// Copyright 2025 Flycast Project
// SPDX-License-Identifier: GPL-2.0-or-later

// Dual-mapping JIT path used on iOS 26+. Allocates an RX region with mmap and
// uses Mach vm_remap to obtain a writable alias of the same physical pages.
// The recompilers write to the RW alias; the dispatcher executes from the RX
// alias. cc_rx_offset = RX − RW is set so the CC_RW2RX/CC_RX2RW macros (in
// ngen.h, gated on TARGET_IPHONE) translate correctly.
//
// The original implementation registered the region with the iOS 26 Trusted
// Execution Monitor via brk #0x69 and suballocated from a 512MB lwmem pool.
// That path is required only on devices with real TXM hardware (A15+) and
// crashes on A13/A14 running iOS 26 because brk #0x69 is an undefined trap
// there. The simple per-allocation vm_remap below is what the iPhone 11
// (A13) / iOS 26.3 device actually used successfully via the old MAP_JIT
// path; it remains the safest default for iOS 26+ across hardware.
//
// On iOS 18 (and other 14-25 releases) this path is NOT used — the kernel's
// CodeSigning Monitor rejects vm_remap'd shared-memory JIT pages there and
// kills the process via CODESIGNING. iOS 14-25 go through vmem_no_txm.cpp
// (single-mapped MAP_JIT) instead. See ios_jit_manager.m for the dispatch.

#include "types.h"

#ifdef TARGET_IPHONE

#include <sys/mman.h>
#include <mach/mach.h>
#include <unistd.h>
#include "oslib/virtmem.h"
#include "log/Log.h"

namespace virtmem {

static bool vm_remap_dual(size_t size, u8** out_rx, u8** out_rw)
{
    u8* rx_ptr = static_cast<u8*>(mmap(nullptr, size, PROT_READ | PROT_EXEC,
                                       MAP_ANON | MAP_PRIVATE, -1, 0));
    if (rx_ptr == MAP_FAILED) {
        ERROR_LOG(VMEM, "TXM: mmap RX failed: %s", strerror(errno));
        return false;
    }

    vm_address_t rw_region = 0;
    vm_address_t target = reinterpret_cast<vm_address_t>(rx_ptr);
    vm_prot_t cur_protection = 0;
    vm_prot_t max_protection = 0;
    kern_return_t kr = vm_remap(
        mach_task_self(), &rw_region, size, 0,
        VM_FLAGS_ANYWHERE, mach_task_self(), target, FALSE,
        &cur_protection, &max_protection,
        VM_INHERIT_DEFAULT);
    if (kr != KERN_SUCCESS) {
        ERROR_LOG(VMEM, "TXM: vm_remap failed: 0x%x", kr);
        munmap(rx_ptr, size);
        return false;
    }

    u8* rw_ptr = reinterpret_cast<u8*>(rw_region);
    if (mprotect(rw_ptr, size, PROT_READ | PROT_WRITE) != 0) {
        ERROR_LOG(VMEM, "TXM: mprotect RW failed: %s", strerror(errno));
        munmap(rx_ptr, size);
        munmap(rw_ptr, size);
        return false;
    }

    *out_rx = rx_ptr;
    *out_rw = rw_ptr;
    return true;
}

bool prepare_jit_block_txm(void *code_area, size_t size, void **code_area_rwx)
{
    // Single-pointer API: TXM dual-mapping requires two distinct pointers,
    // so this path is unsuitable. Recompilers on iOS use the dual-pointer
    // variant; this exists only as a fallback shim.
    u8* rx = nullptr;
    u8* rw = nullptr;
    if (!vm_remap_dual(size, &rx, &rw))
        return false;
    *code_area_rwx = rw;
    INFO_LOG(VMEM, "TXM(single): RW=%p RX=%p (caller will execute via RW only)", rw, rx);
    return true;
}

void release_jit_block_txm(void *code_area, size_t size)
{
    if (code_area)
        munmap(code_area, size);
}

bool prepare_jit_block_txm_dual(void *code_area, size_t size,
                                void **code_area_rw, ptrdiff_t *rx_offset)
{
    u8* rx = nullptr;
    u8* rw = nullptr;
    if (!vm_remap_dual(size, &rx, &rw))
        return false;

    *code_area_rw = rw;
    *rx_offset = rx - rw;          // CC_RW2RX adds this to RW to get RX
    INFO_LOG(VMEM, "TXM(dual): RW=%p RX=%p offset=%td size=%zu",
             rw, rx, *rx_offset, size);
    return true;
}

void release_jit_block_txm_dual(void *code_area1, void *code_area2, size_t size)
{
    // The dual-pointer release contract is inconsistent across iOS callers:
    //   driver.cpp     passes (RW, RX)
    //   arm7_rec.cpp   passes (static_or_null, RW)  — RX leaks on this path
    //   dsp_arm64.cpp  passes (null_after_term, RW) — RX leaks on this path
    // Defensively munmap any non-null distinct pointers we receive.
    if (code_area1)
        munmap(code_area1, size);
    if (code_area2 && code_area2 != code_area1)
        munmap(code_area2, size);
}

} // namespace virtmem

#endif // TARGET_IPHONE
