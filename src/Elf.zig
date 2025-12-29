const std = @import("std");
const print = @import("utils/print.zig").print;

pub const Self = @This();

// ELF header follows the below layout:
// [0..4]      Magic: 0x7f 'E' 'L' 'F'   (identifies this as ELF)
// [4]         Class: 1=32bit, 2=64bit
// [5]         Endianness: 1=little, 2=big
// [6]         ELF version (always 1)
// [7]         OS/ABI (usually 0)
// [8..16]     Padding (ignore)
// [16..18]    Type: 1=relocatable, 2=executable, 3=shared
// [18..20]    Machine: 0xF3 = RISC-V
// [20..24]    Version (always 1)
// [24..32]    Entry point (where to start executing)
// [32..40]    Program header offset (where segment table starts)
// [40..48]    Section header offset (ignore for loading)
// [48..52]    Flags (RISC-V ISA extensions)
// [52..54]    This header's size (64 for ELF64)
// [54..56]    Program header entry size (56 for ELF64)
// [56..58]    Program header count (how many segments)
// [58..60]    Section header entry size (ignore)
// [60..62]    Section header count (ignore)
// [62..64]    Section name string table index (ignore)

// Program headers follow the below layout:
// [0..4]      Type: 1=LOAD (the only one you care about)
// [4..8]      Flags: 1=X, 2=W, 4=R (combine: 5=R+X, 6=R+W)
// [8..16]     Offset (where in file to read from)
// [16..24]    VirtAddr (where in memory to write to)
// [24..32]    PhysAddr (usually same as VirtAddr, ignore)
// [32..40]    FileSiz (how many bytes to copy from file)
// [40..48]    MemSiz (how much memory to allocate)
// [48..56]    Align (ignore for emulator)

pub const ProgramHeader = struct {
    header_type: HeaderType,
    flags: u32,
    offset: u64, // starting index in elf file
    file_size: u64, // length in elf file
    virtual_address: u64, // target address in memory

    // We only support LOAD headers
    pub const HeaderType = enum {
        LOAD,
        UNSUPPORTED,
    };

    pub fn parse(header_buf: []u8) !ProgramHeader {
        const header_type = std.mem.readInt(u32, header_buf[0..4], .little);
        return ProgramHeader{
            .header_type = switch (header_type) {
                1 => .LOAD,
                else => .UNSUPPORTED,
            },
            .flags = std.mem.readInt(u32, header_buf[4..8], .little),
            .offset = std.mem.readInt(u64, header_buf[8..16], .little),
            .virtual_address = std.mem.readInt(u64, header_buf[16..24], .little),
            .file_size = std.mem.readInt(u64, header_buf[32..40], .little),
        };
    }

    pub fn display(self: *const ProgramHeader) !void {
        try print("Header type: {s}\n", .{@tagName(self.header_type)});
        try print("Flags: 0x{x}\n", .{self.flags});
        try print("Offset: 0x{x}\n", .{self.offset});
        try print("File size: 0x{x}\n", .{self.file_size});
        try print("Virtual address: 0x{x}\n\n", .{self.virtual_address});
    }
};

entry_point: u64,
headers: []ProgramHeader,

pub fn init(allocator: std.mem.Allocator, elf_buf: []u8) !Self {
    // 0-4th bytes are magic number 0x7f + ELF
    const expected = [_]u8{ 0x7f, 'E', 'L', 'F' };
    if (!std.mem.eql(u8, elf_buf[0..4], &expected)) {
        @panic("Invalid ELF file: magic number not found");
    }

    // 5th byte communicates 32/64 variant
    if (elf_buf[4] != 0x02) {
        @panic("Invalid ELF file: only 64-bit ELF files are supported");
    }

    // 6th bytes is endianness, assert little endian
    if (elf_buf[5] != 0x01) {
        @panic("Invalid ELF file: only little endian ELF files are supported");
    }

    const program_header_count = std.mem.readInt(u16, elf_buf[56..58], .little);
    const entry_point = std.mem.readInt(u64, elf_buf[24..32], .little);

    var headers = try allocator.alloc(ProgramHeader, program_header_count);

    for (0..program_header_count) |i| {
        const start = 64 + i * 56;
        const end = 64 + (i + 1) * 56;
        const header_buf = elf_buf[start..end];
        const header = try ProgramHeader.parse(header_buf);
        headers[i] = header;
    }

    return Self{
        .entry_point = entry_point,
        .headers = headers,
    };
}

pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.free(self.headers);
}

pub fn display(self: *const Self) !void {
    try print("Entry point: 0x{x}\n", .{self.entry_point});
    try print("Program headers:\n", .{});
    for (self.headers) |header| {
        try header.display();
    }
}
