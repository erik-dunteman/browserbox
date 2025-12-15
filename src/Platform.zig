const std = @import("std");
const parser = @import("parser.zig");
const Program = @import("Program.zig");
const print = @import("io.zig").print;

const MEMORY_PAGE_SIZE = 128; // 128 bytes

pub const Self = @This();

registers: [32]u64, // RV64 system has 64bit registers
memory: MemoryBlock, // todo: WASM operates on 32-bit values natively, consider benchmarking if we store memory in 32b blocks
program_counter: usize,

pub fn new() Self {
    return Self{
        .registers = undefined,
        .memory = MemoryBlock{ .data = undefined },
        .program_counter = 0,
    };
}

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    try self.memory.init(allocator);
}

pub fn deinit(self: *Self) void {
    self.memory.deinit();
}

pub fn run_program(self: *Self, program: *const Program) !void {
    while (self.program_counter < program.instructions.len * 4) {
        try print("\n", .{});
        if (self.program_counter % 4 != 0) {
            @panic("Program counter is not aligned to 4 bytes");
        }
        const pc_address = self.program_counter / 4; // each instruction is 4 bytes
        const word = program.instructions[pc_address];
        const instruction = parser.parse_word(word);
        try instruction.execute(self);
    }
}

const MemoryBlock = struct {
    allocator: std.mem.Allocator = undefined,
    data: std.ArrayList(u8) = undefined, // TODO: since WASM natively stores in 32bit, consider blocking by that

    pub fn init(self: *MemoryBlock, allocator: std.mem.Allocator) !void {
        try print("Initializing memory block with size {}\n", .{MEMORY_PAGE_SIZE});
        self.allocator = allocator;
        self.data = try std.ArrayList(u8).initCapacity(allocator, MEMORY_PAGE_SIZE);
        try print("Memory block data: len={d}\n", .{self.data.items.len});
    }

    pub fn deinit(self: *MemoryBlock) void {
        self.data.deinit(self.allocator);
    }

    pub fn display(self: *MemoryBlock) !void {
        try print("Memory block data: len={d}\n", .{self.data.items.len});
        for (self.data.items) |byte| {
            try print("{x} ", .{byte});
        }
        try print("\n", .{});
    }

    pub fn load_byte(self: *MemoryBlock, address: usize) u8 {
        return self.data.items[address];
    }

    pub fn load_half(self: *MemoryBlock, address: usize) u16 {
        // store in big endian
        const buffer: *[2]u8 = self.data.items[address..][0..2];
        return std.mem.readInt(u16, buffer, .big);
    }

    pub fn load_word(self: *MemoryBlock, address: usize) u32 {
        const buffer: *[4]u8 = self.data.items[address..][0..4];
        return std.mem.readInt(u32, buffer, .big);
    }

    pub fn grow_to_fit(self: *MemoryBlock, address: usize, byte_width: usize) !void {
        // ensure we have valid memory for this address
        // add in pagesize increments as needed
        if (address >= self.data.items.len) {
            const total_pages = ((address + byte_width + 1) / MEMORY_PAGE_SIZE) + 1;
            try self.data.resize(self.allocator, total_pages * MEMORY_PAGE_SIZE);
        }
    }

    pub fn store_byte(self: *MemoryBlock, address: usize, value: u8) !void {
        try self.grow_to_fit(address, 1);

        const buffer: [1]u8 = .{value};
        try self.data.replaceRange(self.allocator, address, 1, &buffer);
        try self.display();
    }

    pub fn store_half(self: *MemoryBlock, address: usize, value: u16) !void {
        try self.grow_to_fit(address, 2);

        var buffer: [2]u8 = undefined;
        std.mem.writeInt(u16, &buffer, value, .big);
        try self.data.insertSlice(self.allocator, address, &buffer);
    }

    pub fn store_word(self: *MemoryBlock, address: usize, value: u32) !void {
        try self.grow_to_fit(address, 4);

        var buffer: [4]u8 = undefined;
        std.mem.writeInt(u32, &buffer, value, .big);
        try self.data.insertSlice(self.allocator, address, &buffer);
    }
};
