const std = @import("std");
const builtin = @import("builtin");
const print = @import("../utils/print.zig").print;
const panic = @import("../utils/print.zig").panic;

pub const Self = @This();

pub const MAX_ADDRESS = std.math.maxInt(usize);
pub const MEMORY_PAGE = 1_000; // 1KB, TODO adjust to be more architecture friendly

// for now, make physical memory statically sized
// Struct attributes
allocator: std.mem.Allocator,
data: []u8 = undefined, // zig compiler doesn't accept statically baking in the physical memory size so we'll need to heap allocate

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .allocator = allocator,
    };
    self.data = try allocator.alloc(u8, MEMORY_PAGE);
    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.data);
}

pub fn display(self: *Self) !void {
    try print("Memory block data: len={d}\n", .{self.data.len});
}

pub fn load_byte(self: *Self, address: usize) !u8 {
    if (address > self.data.len) {
        return error.AddressOutOfBounds;
    }
    return self.data[address];
}

pub fn load_half(self: *Self, address: usize) !u16 {
    if (address + 1 > self.data.len) {
        return error.AddressOutOfBounds;
    }
    // store in big endian
    const buffer = self.data[address..][0..2];
    return std.mem.readInt(u16, buffer, .little);
}

pub fn load_word(self: *Self, address: usize) !u32 {
    if (address + 3 > self.data.len) {
        return error.AddressOutOfBounds;
    }
    const buffer = self.data[address..][0..4];
    return std.mem.readInt(u32, buffer, .little);
}

pub fn load_dword(self: *Self, address: usize) !u64 {
    if (address + 7 > self.data.len) {
        return error.AddressOutOfBounds;
    }
    const buffer = self.data[address..][0..8];
    return std.mem.readInt(u64, buffer, .little);
}

fn maybe_resize(self: *Self, max_address: usize) !void {
    if (max_address > self.data.len) {
        const new_len = ((max_address / MEMORY_PAGE) + 1) * MEMORY_PAGE;
        self.data = try self.allocator.realloc(self.data, new_len);
    }
}

pub fn store_byte(self: *Self, address: usize, value: u8) !void {
    try maybe_resize(self, address + 1);
    self.data[address] = value;
}

pub fn store_half(self: *Self, address: usize, value: u16) !void {
    try maybe_resize(self, address + 2);
    const buffer = self.data[address..][0..2];
    std.mem.writeInt(u16, buffer, value, .little);
}

pub fn store_word(self: *Self, address: usize, value: u32) !void {
    try maybe_resize(self, address + 4);
    const buffer = self.data[address..][0..4];
    std.mem.writeInt(u32, buffer, value, .little);
}

pub fn store_dword(self: *Self, address: usize, value: u64) !void {
    try maybe_resize(self, address + 8);
    const buffer = self.data[address..][0..8];
    std.mem.writeInt(u64, buffer, value, .little);
}

pub fn store_bytes(self: *Self, address: usize, data: []u8) !void {
    try maybe_resize(self, address + data.len);
    std.mem.copyForwards(u8, self.data[address..], data);
}
