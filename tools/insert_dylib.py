#!/usr/bin/env python3
"""Insert LC_LOAD_DYLIB load commands into a Mach-O binary."""
import struct
import sys


LC_LOAD_DYLIB = 0xC
LC_LOAD_WEAK_DYLIB = 0x80000018

MH_MAGIC_64 = 0xFEEDFACF
MH_MAGIC = 0xFEEDFACE


def align(n, alignment):
    return (n + alignment - 1) & ~(alignment - 1)


def insert_load_dylib(binary_path, dylib_path, weak=False):
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

        # Build the new load command
        cmd_type = LC_LOAD_WEAK_DYLIB if weak else LC_LOAD_DYLIB
        dylib_name = dylib_path.encode("utf-8") + b"\x00"
        # dylib_command: cmd(4) + cmdsize(4) + name_offset(4) + timestamp(4) +
        #                current_version(4) + compat_version(4) + name string
        name_offset = 24  # size of the fixed fields
        cmdsize = align(name_offset + len(dylib_name), 8 if magic == MH_MAGIC_64 else 4)
        padding = cmdsize - name_offset - len(dylib_name)

        load_cmd = struct.pack("<IIIIII",
                               cmd_type,
                               cmdsize,
                               name_offset,
                               0,          # timestamp
                               0x10000,    # current_version 1.0.0
                               0x10000)    # compat_version 1.0.0
        load_cmd += dylib_name + (b"\x00" * padding)

        # Check for space between end of load commands and first section
        load_cmds_end = header_size + sizeofcmds
        # Read what's after current load commands to see if there's padding
        f.seek(load_cmds_end)
        slack = f.read(cmdsize)
        if slack != b"\x00" * len(slack):
            print(f"Error: not enough space to insert load command ({cmdsize} bytes needed)")
            print(f"  There may not be enough padding after existing load commands.")
            print(f"  Try linking with -headerpad 0x1000 or use -headerpad_max_install_names.")
            sys.exit(1)

        # Write the new load command at the end of existing ones
        f.seek(load_cmds_end)
        f.write(load_cmd)

        # Update header: ncmds += 1, sizeofcmds += cmdsize
        header[4] = ncmds + 1
        header[5] = sizeofcmds + cmdsize
        f.seek(0)
        f.write(struct.pack(header_fmt, *header))

    print(f"Inserted {'LC_LOAD_WEAK_DYLIB' if weak else 'LC_LOAD_DYLIB'}: {dylib_path}")
    print(f"  cmdsize: {cmdsize}, total load commands: {ncmds + 1}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <binary> <dylib_path> [--weak]")
        sys.exit(1)

    weak = "--weak" in sys.argv
    insert_load_dylib(sys.argv[1], sys.argv[2], weak=weak)
