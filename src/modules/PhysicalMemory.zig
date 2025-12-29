const std = @import("std");
const builtin = @import("builtin");
const print = @import("../utils/print.zig").print;
const panic = @import("../utils/print.zig").panic;
const MMU = @import("MMU.zig");

pub const Self = @This();

pub const MAX_ADDRESS = std.math.maxInt(usize);
pub const MEMORY_PAGE = 1_000; // 1KB, TODO adjust to be more architecture friendly

// for now, make physical memory statically sized
// Struct attributes
allocator: std.mem.Allocator,
mmu: MMU,
data: []u8 = undefined, // zig compiler doesn't accept statically baking in the physical memory size so we'll need to heap allocate

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .allocator = allocator,
        .mmu = MMU.init(),
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

pub fn load_byte(self: *Self, address: u64) !u8 {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    if (physical_address >= self.data.len) {
        return error.AddressOutOfBounds;
    }
    return self.data[physical_address];
}

pub fn load_half(self: *Self, address: u64) !u16 {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    if (physical_address + 1 >= self.data.len) {
        return error.AddressOutOfBounds;
    }
    const buffer = self.data[physical_address..][0..2];
    return std.mem.readInt(u16, buffer, .little);
}

pub fn load_word(self: *Self, address: u64) !u32 {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    if (physical_address + 3 >= self.data.len) {
        return error.AddressOutOfBounds;
    }
    const buffer = self.data[physical_address..][0..4];
    return std.mem.readInt(u32, buffer, .little);
}

pub fn load_dword(self: *Self, address: u64) !u64 {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    if (physical_address + 7 >= self.data.len) {
        return error.AddressOutOfBounds;
    }
    const buffer = self.data[physical_address..][0..8];
    return std.mem.readInt(u64, buffer, .little);
}

pub fn load_dword_physical(self: *Self, address: u64) !u64 {
    // Used by MMU for page table walks (bypasses translation)
    const physical_address: usize = @intCast(address);
    if (physical_address + 7 >= self.data.len) {
        return error.AddressOutOfBounds;
    }
    return std.mem.readInt(u64, self.data[physical_address..][0..8], .little);
}

fn maybe_resize(self: *Self, max_address: usize) !void {
    if (max_address > self.data.len) {
        const new_len = ((max_address / MEMORY_PAGE) + 1) * MEMORY_PAGE;
        self.data = try self.allocator.realloc(self.data, new_len);
    }
}

pub fn store_byte(self: *Self, address: u64, value: u8) !void {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    try maybe_resize(self, physical_address + 1);
    self.data[physical_address] = value;
}

pub fn store_half(self: *Self, address: u64, value: u16) !void {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    try maybe_resize(self, physical_address + 2);
    const buffer = self.data[physical_address..][0..2];
    std.mem.writeInt(u16, buffer, value, .little);
}

pub fn store_word(self: *Self, address: u64, value: u32) !void {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    try maybe_resize(self, physical_address + 4);
    const buffer = self.data[physical_address..][0..4];
    std.mem.writeInt(u32, buffer, value, .little);
}

pub fn store_dword(self: *Self, address: u64, value: u64) !void {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    try maybe_resize(self, physical_address + 8);
    const buffer = self.data[physical_address..][0..8];
    std.mem.writeInt(u64, buffer, value, .little);
}

pub fn store_bytes(self: *Self, address: u64, data: []u8) !void {
    const physical_address: usize = @intCast(try self.mmu.translate_address(self, address));
    try maybe_resize(self, physical_address + data.len);
    std.mem.copyForwards(u8, self.data[physical_address..], data);
}
