const std = @import("std");
const print = @import("../utils/print.zig").print;
const panic = @import("../utils/print.zig").panic;

pub const Self = @This();

// for now, make physical memory statically sized
// const PHYSICAL_MEMORY_SIZE = 1024; // 1KB, for now, for debugability
const PHYSICAL_MEMORY_SIZE = 0x1_0000_0000; // 4GB RAM

// Struct attributes
data: []u8 = undefined, // zig compiler doesn't accept statically baking in the physical memory size so we'll need to heap allocate

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{};
    self.data = try allocator.alloc(u8, PHYSICAL_MEMORY_SIZE);
    return self;
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
}

pub fn display(self: *Self) !void {
    try print("Memory block data: len={d}\n", .{PHYSICAL_MEMORY_SIZE});
    // for (self.data) |byte| {
    //     try print("{x} ", .{byte});
    // }
    // try print("\n", .{});
    _ = self;
}

pub fn load_byte(self: *Self, address: usize) u8 {
    return self.data[address];
}

pub fn load_half(self: *Self, address: usize) u16 {
    // store in big endian
    const buffer = self.data[address..][0..2];
    return std.mem.readInt(u16, buffer, .little);
}

pub fn load_word(self: *Self, address: usize) u32 {
    const buffer = self.data[address..][0..4];
    return std.mem.readInt(u32, buffer, .little);
}

pub fn load_dword(self: *Self, address: usize) u64 {
    const buffer = self.data[address..][0..8];
    return std.mem.readInt(u64, buffer, .little);
}

pub fn store_byte(self: *Self, address: usize, value: u8) !void {
    self.data[address] = value;
}

pub fn store_half(self: *Self, address: usize, value: u16) !void {
    const buffer = self.data[address..][0..2];
    std.mem.writeInt(u16, buffer, value, .little);
}

pub fn store_word(self: *Self, address: usize, value: u32) !void {
    const buffer = self.data[address..][0..4];
    std.mem.writeInt(u32, buffer, value, .little);
}

pub fn store_dword(self: *Self, address: usize, value: u64) !void {
    if (address + 8 > PHYSICAL_MEMORY_SIZE) {
        panic("Attempt to store dword outside of physical memory: {d} + 8 > {d}", .{ address, PHYSICAL_MEMORY_SIZE });
    }
    const buffer = self.data[address..][0..8];
    std.mem.writeInt(u64, buffer, value, .little);
}

pub fn store_bytes(self: *Self, address: usize, data: []u8) !void {
    if (address + data.len > PHYSICAL_MEMORY_SIZE) {
        panic("Attempt to store bytes outside of physical memory: {d} + {d} > {d}", .{ address, data.len, PHYSICAL_MEMORY_SIZE });
    }
    std.mem.copyForwards(u8, self.data[address..], data);
}
