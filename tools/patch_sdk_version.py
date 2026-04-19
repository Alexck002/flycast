#!/usr/bin/env python3
"""Patch the SDK version in LC_BUILD_VERSION of a Mach-O binary and Info.plist."""
import os
import plistlib
import struct
import sys

def encode_version(ver_str):
    parts = ver_str.split(".")
    major = int(parts[0])
    minor = int(parts[1]) if len(parts) > 1 else 0
    patch = int(parts[2]) if len(parts) > 2 else 0
    return (major << 16) | (minor << 8) | patch

def decode_version(v):
    return f"{(v >> 16) & 0xFFFF}.{(v >> 8) & 0xFF}.{v & 0xFF}"

LC_BUILD_VERSION = 0x32

def patch(binary_path, new_sdk_str):
    new_sdk = encode_version(new_sdk_str)

    with open(binary_path, "r+b") as f:
        magic = struct.unpack("<I", f.read(4))[0]
        if magic == 0xFEEDFACF:
            is_64 = True
        elif magic == 0xFEEDFACE:
            is_64 = False
        else:
            print(f"Not a Mach-O binary (magic: {hex(magic)})")
            sys.exit(1)

        # Read header
        f.seek(0)
        if is_64:
            hdr = struct.unpack("<IiiIIIII", f.read(32))
            header_size = 32
        else:
            hdr = struct.unpack("<IiiIIII", f.read(28))
            header_size = 28

        ncmds = hdr[4]
        offset = header_size
        patched = False

        for _ in range(ncmds):
            f.seek(offset)
            cmd, cmdsize = struct.unpack("<II", f.read(8))

            if cmd == LC_BUILD_VERSION:
                # LC_BUILD_VERSION: cmd, cmdsize, platform, minos, sdk, ntools
                f.seek(offset)
                cmd, cmdsize, platform, minos, sdk, ntools = struct.unpack("<IIIIII", f.read(24))
                old_sdk_str = decode_version(sdk)
                print(f"Found LC_BUILD_VERSION at offset {offset}")
                print(f"  platform: {platform}")
                print(f"  minos:    {decode_version(minos)}")
                print(f"  sdk:      {old_sdk_str} -> {new_sdk_str}")

                # Write new SDK version (at offset + 16)
                f.seek(offset + 16)
                f.write(struct.pack("<I", new_sdk))
                patched = True
                break

            offset += cmdsize

        if not patched:
            print("LC_BUILD_VERSION not found")
            sys.exit(1)

    print(f"Patched binary successfully")


def patch_info_plist(app_dir, new_sdk_str, sdk_build):
    """Patch all SDK-related fields in the app's Info.plist."""
    plist_path = os.path.join(app_dir, "Info.plist")
    if not os.path.exists(plist_path):
        print(f"Info.plist not found at {plist_path}")
        sys.exit(1)

    with open(plist_path, "rb") as f:
        plist = plistlib.load(f)

    fields = {
        "DTPlatformVersion": new_sdk_str,
        "DTSDKName": f"iphoneos{new_sdk_str}",
        "DTPlatformBuild": sdk_build,
        "DTSDKBuild": sdk_build,
    }
    # Remove Xcode version fields that can reveal the true build toolchain
    remove_fields = ["DTXcode", "DTXcodeBuild"]

    print("Patched Info.plist:")
    for key, new_val in fields.items():
        old_val = plist.get(key, "(not set)")
        plist[key] = new_val
        print(f"  {key}: {old_val} -> {new_val}")

    for key in remove_fields:
        if key in plist:
            old_val = plist[key]
            del plist[key]
            print(f"  {key}: {old_val} -> (removed)")

    with open(plist_path, "wb") as f:
        plistlib.dump(plist, f)


# Map of iOS version -> SDK build identifier (from Apple's release notes)
SDK_BUILDS = {
    "15.0": "19A339",
    "15.1": "19B74",
    "15.2": "19C56",
    "15.4": "19E240",
    "15.5": "19F77",
    "16.0": "20A360",
    "16.1": "20B72",
    "16.2": "20C52",
    "16.4": "20E238",
    "17.0": "21A326",
    "17.2": "21C52",
    "17.5": "21F79",
    "18.0": "22A3354",
    "18.2": "22C146",
}


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <binary> <sdk_version>")
        print(f"  binary: path to Mach-O binary (e.g. Payload/Flycast.app/Flycast)")
        print(f"  Supported versions: {', '.join(sorted(SDK_BUILDS.keys()))}")
        sys.exit(1)

    binary_path = sys.argv[1]
    new_sdk = sys.argv[2]

    sdk_build = SDK_BUILDS.get(new_sdk)
    if not sdk_build:
        print(f"Unknown SDK version '{new_sdk}'. Known versions: {', '.join(sorted(SDK_BUILDS.keys()))}")
        sys.exit(1)

    patch(binary_path, new_sdk)

    # Auto-detect the .app directory from the binary path
    app_dir = os.path.dirname(binary_path)
    if app_dir.endswith(".app"):
        patch_info_plist(app_dir, new_sdk, sdk_build)
