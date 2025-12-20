const std = @import("std");

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    // Use stderr to avoid interfering with zig build test's IPC protocol on stdout
    const stderr = std.fs.File.stderr();
    var print_buf: [256]u8 = undefined;
    stderr.writeAll(std.fmt.bufPrint(&print_buf, fmt, args) catch return) catch {};
}
