#!/usr/bin/env python3
"""Remove an LC_LOAD_DYLIB / LC_LOAD_WEAK_DYLIB load command from a Mach-O binary."""
import struct
import sys

MH_MAGIC_64 = 0xFEEDFACF
MH_MAGIC = 0xFEEDFACE
LC_LOAD_DYLIB = 0xC
LC_LOAD_WEAK_DYLIB = 0x80000018


def remove_load_dylib(binary_path, dylib_name):
    with open(binary_path, "r+b") as f:
        magic = struct.unpack("<I", f.read(4))[0]
        if magic == MH_MAGIC_64:
            header_fmt = "<IiiIIIII"
            header_size = 32
        elif magic == MH_MAGIC:
            header_fmt = "<IiiIIII"
            header_size = 28
        else:
            print(f"Not a Mach-O binary (magic: {hex(magic)})")
            sys.exit(1)

        f.seek(0)
        header = list(struct.unpack(header_fmt, f.read(header_size)))
        ncmds = header[4]
        sizeofcmds = header[5]

        # Read all load commands
        f.seek(header_size)
        all_lc_data = f.read(sizeofcmds)

        offset = 0
        found = False
        remove_offset = 0
        remove_size = 0

        for i in range(ncmds):
            cmd, cmdsize = struct.unpack_from("<II", all_lc_data, offset)
            if cmd in (LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB):
                name_offset_field = struct.unpack_from("<I", all_lc_data, offset + 8)[0]
                name_end = all_lc_data.index(b"\x00", offset + name_offset_field)
                name = all_lc_data[offset + name_offset_field:name_end].decode("utf-8")
                if dylib_name in name:
                    found = True
                    remove_offset = offset
                    remove_size = cmdsize
                    cmd_type = "LC_LOAD_WEAK_DYLIB" if cmd == LC_LOAD_WEAK_DYLIB else "LC_LOAD_DYLIB"
                    print(f"Removing {cmd_type}: {name} (cmdsize={cmdsize})")
                    break
            offset += cmdsize

        if not found:
            print(f"Load command for '{dylib_name}' not found")
            sys.exit(1)

        # Remove the load command by shifting subsequent commands up
        new_lc_data = (
            all_lc_data[:remove_offset]
            + all_lc_data[remove_offset + remove_size:]
            + b"\x00" * remove_size  # zero-fill the freed space
        )

        # Update header
        header[4] = ncmds - 1
        header[5] = sizeofcmds - remove_size

        # Write back
        f.seek(0)
        f.write(struct.pack(header_fmt, *header))
        f.seek(header_size)
        f.write(new_lc_data)

    print(f"Done. Load commands: {ncmds} -> {ncmds - 1}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <binary> <dylib_name_substring>")
        sys.exit(1)
    remove_load_dylib(sys.argv[1], sys.argv[2])
