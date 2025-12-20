const std = @import("std");
const parser = @import("parser.zig");
const CSR = @import("modules/CSR.zig");
const PhysicalMemory = @import("modules/PhysicalMemory.zig");
const MMU = @import("modules/MMU.zig");
const print = @import("utils/print.zig").print;

const PYSICAL_MEMORY_SIZE = 1024; // 1KB, for now

pub const Self = @This();

registers: [32]u64,
csr: CSR,
program_end_address: usize,
program_start_address: usize,
program_counter: usize,
mmu: MMU, // 39 bit virtual memory addresses, used to look up physical memory address in PhysicalMemory given current page table pointed to by satp
memory: PhysicalMemory, // todo: WASM operates on 32-bit values natively, consider benchmarking if we store memory in 32b blocks

const start_address = 0x100; // 256 in decimal, program starts at this address

pub fn new() Self {
    return Self{
        .registers = .{0} ** 32,
        .csr = CSR.new(),
        .mmu = MMU.new(),
        .memory = PhysicalMemory.new(),
        .program_counter = start_address,
        .program_start_address = start_address,
        .program_end_address = start_address,
    };
}

pub fn run_program(self: *Self) !void {
    // Program starts at loaded address, loads, parses, executes on hardware
    while (self.program_counter < self.memory.data.len) {
        // instructions coming from disk are in little endian format
        const word = self.memory.load_word(self.program_counter);
        try print("Loaded word: {x}\n", .{word});
        const instruction = parser.parse_word(word);
        try instruction.execute(self);
    }
}
