const std = @import("std");
const parser = @import("parser.zig");
const CSR = @import("modules/CSR.zig");
const PhysicalMemory = @import("modules/PhysicalMemory.zig");
const MMU = @import("modules/MMU.zig");
const Elf = @import("Elf.zig");
const print = @import("utils/print.zig").print;
const panic = @import("utils/print.zig").panic;

pub const Self = @This();

const BINARY_PROGRAM_START = 0x8000; // conservative, for now

allocator: std.mem.Allocator,
registers: [32]u64,
csr: CSR,
program_start: usize = undefined,
program_end: usize = undefined,
program_counter: usize = undefined,
memory: PhysicalMemory, // todo: WASM operates on 32-bit values natively, consider benchmarking if we store memory in 32b blocks

pub fn init(allocator: std.mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .registers = .{0} ** 32,
        .csr = CSR.init(),
        .memory = try PhysicalMemory.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.memory.deinit();
}

pub fn load_program_from_binary(self: *Self, path: []const u8) !void {
    // read into physical memory
    var program_file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer program_file.close();
    var program_buf: [1_000_000]u8 = undefined; // Max 1 MB file for now
    const len = try program_file.readAll(&program_buf);

    try self.memory.store_bytes(BINARY_PROGRAM_START, program_buf[0..len]);
    self.program_start = BINARY_PROGRAM_START;
    self.program_counter = BINARY_PROGRAM_START;
    self.registers[2] = BINARY_PROGRAM_START;
    self.program_end = BINARY_PROGRAM_START + len;
}

pub fn load_program_from_elf(self: *Self, path: []const u8) !void {
    // Parses program layout from ELF file
    // Performs the role of a bootloader
    var elf_file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer elf_file.close();

    const buf_size = 1_000_000; // Max 1 MB file for now
    var buf: [buf_size]u8 = undefined;
    const elf_len = try elf_file.readAll(buf[0..]);
    const elf_buf = buf[0..elf_len];
    const elf = try Elf.init(self.allocator, elf_buf);
    defer elf.deinit(self.allocator);

    // Set stack pointer to program start
    self.registers[2] = @as(usize, elf.entry_point);
    self.program_start = elf.entry_point;
    self.program_counter = elf.entry_point;

    // Perform loads as directed by headers
    for (elf.headers) |header| {
        if (header.header_type != .LOAD) {
            continue;
        }
        const data = elf_buf[header.offset .. header.offset + header.file_size];
        try self.memory.store_bytes(header.virtual_address, data);

        // If this loaded section includes entry_point, calculate program_end
        if (header.virtual_address <= elf.entry_point and header.virtual_address + header.file_size >= elf.entry_point) {
            self.program_end = header.virtual_address + header.file_size;
        }
    }
}

pub fn run_program(self: *Self) !void {
    try print("Running program from address 0x{x} to 0x{x}, program counter 0x{x}\n", .{ self.program_start, self.program_end, self.program_counter });
    // Program starts at loaded address, loads, parses, executes on hardware
    while (self.program_counter < self.program_end) {

        // instructions coming from disk are in little endian format
        const word = try self.memory.load_word(self.program_counter);
        const instruction = parser.parse_word(word) catch |err| switch (err) {
            error.UndefinedRegion => {
                if (self.program_counter == 0) {
                    // In our fibonocci compiled for freestanding OS, the compiler exits by setting PC to 0
                    // Let's handle that case explicitly
                    try print("PC set to 0x0 with no more instructions to execute. Exiting.\n", .{});
                    return;
                }
                try print("Program attempted to access undefined region. Exiting.\n", .{});
                return;
            },
            else => |e| return e,
        };
        try instruction.execute(self);
    }

    try print("Program exited successfully.\n", .{});
}
