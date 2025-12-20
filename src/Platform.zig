const std = @import("std");
const parser = @import("parser.zig");
const CSR = @import("modules/CSR.zig");
const PhysicalMemory = @import("modules/PhysicalMemory.zig");
const MMU = @import("modules/MMU.zig");
const print = @import("utils/print.zig").print;

pub const Self = @This();
const PROGRAM_START = 0x200;

registers: [32]u64,
csr: CSR,
program_start: usize = PROGRAM_START,
program_end: usize = PROGRAM_START,
program_counter: usize = PROGRAM_START,
mmu: MMU, // 39 bit virtual memory addresses, used to look up physical memory address in PhysicalMemory given current page table pointed to by satp
memory: PhysicalMemory, // todo: WASM operates on 32-bit values natively, consider benchmarking if we store memory in 32b blocks

pub fn new() Self {
    return Self{
        .registers = .{0} ** 32,
        .csr = CSR.new(),
        .mmu = MMU.new(),
        .memory = PhysicalMemory.new(),
    };
}

pub fn load_program_from_file(self: *Self, path: []const u8) !void {
    // read into physical memory
    var program_file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer program_file.close();
    const program_buf: []u8 = self.memory.data[self.program_counter..];
    const len = try program_file.readAll(program_buf);

    // bookkeep program addresses
    self.program_end = self.program_start + len;
}

pub fn run_program(self: *Self) !void {
    // Program starts at loaded address, loads, parses, executes on hardware
    while (self.program_counter < self.program_end) {
        // instructions coming from disk are in little endian format
        const word = self.memory.load_word(self.program_counter);
        try print("Loaded word: {x}\n", .{word});
        const instruction = parser.parse_word(word);
        try instruction.execute(self);
    }
}
