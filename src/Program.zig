const std = @import("std");

pub const Self = @This();

instructions: []u32,

pub fn init_from_file(allocator: std.mem.Allocator, path: []const u8) !Self {
    // TODO: panics in wasm
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    const bytes = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(bytes);

    var instructions: []u32 = try allocator.alloc(u32, bytes.len / 4);

    // take four
    var windows = std.mem.window(u8, bytes, 4, 4);
    var i: usize = 0;
    while (windows.next()) |slice| {
        const word = std.mem.readInt(u32, slice[0..4], .little);
        instructions[i] = word;
        i += 1;
    }

    return Self{ .instructions = instructions };
}

pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.free(self.instructions);
}
