const std = @import("std");
const parser = @import("parser.zig");
const CSR = @import("modules/CSR.zig");
const PhysicalMemory = @import("modules/PhysicalMemory.zig");
const XRegisters = @import("modules/XRegisters.zig");
const MMU = @import("modules/MMU.zig");
const print = @import("../io.zig").print;

const PYSICAL_MEMORY_SIZE = 1024; // 1KB, for now

pub const Self = @This();

registers: XRegisters,
csr: CSR,
mmu: MMU, // 39 bit virtual memory addresses, used to look up physical memory address in PhysicalMemory given current page table pointed to by satp
memory: PhysicalMemory, // todo: WASM operates on 32-bit values natively, consider benchmarking if we store memory in 32b blocks
program_counter: usize,

pub fn new() Self {
    return Self{
        .registers = XRegisters.new(),
        .csr = CSR.new(),
        .mmu = MMU.new(),
        .memory = PhysicalMemory.new(),
        .program_counter = 0,
    };
}

pub fn load_program(self: *Self, start_address: usize, program: []u8) !void {
    for (program, 0..) |byte, i| {
        try self.memory.store_byte(start_address + i, byte);
    }

    self.program_counter = start_address;
}

pub fn run_program(self: *Self) !void {
    // Program starts at loaded address, loads, parses, executes on hardware
    while (self.program_counter < self.memory.data.len) {
        const word = self.memory.load_word(self.program_counter);
        const instruction = parser.parse_word(word);
        try instruction.execute(self);
    }
}
