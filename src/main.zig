const std = @import("std");
const assert = @import("std").debug.assert;
const parser = @import("parser.zig");
const print = @import("io.zig").print;
const Platform = @import("Platform.zig");

test {
    // Reference imported modules to include their tests
    _ = parser;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 2) {
        try print("Target file not provided\n", .{});
        return;
    }
    var platform = Platform.new();

    const start_address = 0x100; // 256 in decimal
    const program_buf: []u8 = platform.memory.data[start_address..];
    var program_file = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
    try program_file.readAll(program_buf);
    program_file.close();

    try platform.run_program();
}
