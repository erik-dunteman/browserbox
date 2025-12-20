const std = @import("std");
const print = @import("../utils/print.zig").print;

// for now, make physical memory statically sized
const PHYSICAL_MEMORY_SIZE = 1024; // 1KB, for now, for debugability

pub const Self = @This();

data: [PHYSICAL_MEMORY_SIZE]u8 = undefined,

pub fn new() Self {
    return Self{
        .data = .{0} ** PHYSICAL_MEMORY_SIZE,
    };
}

pub fn display(self: *Self) !void {
    try print("Memory block data: len={d}\n", .{PHYSICAL_MEMORY_SIZE});
    for (self.data) |byte| {
        try print("{x} ", .{byte});
    }
    try print("\n", .{});
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
