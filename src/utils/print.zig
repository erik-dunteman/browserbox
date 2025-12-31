const std = @import("std");

pub fn print(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    // Use stderr to avoid interfering with zig build test's IPC protocol on stdout
    const stderr = std.Io.File.stderr();
    var fmt_buf: [256]u8 = undefined;
    var writer_buf: [256]u8 = undefined;
    var writer = stderr.writer(io, &writer_buf);
    writer.interface.writeAll(std.fmt.bufPrint(&fmt_buf, fmt, args) catch return) catch {};
    writer.interface.flush() catch {};
}

pub fn panic(comptime fmt: []const u8, args: anytype) void {
    var print_buf: [256]u8 = undefined;
    const msg = std.fmt.bufPrint(&print_buf, fmt, args) catch return;
    @panic(msg);
}
