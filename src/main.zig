const std = @import("std");
const builtin = @import("builtin");
const assert = @import("std").debug.assert;
const parser = @import("parser.zig");
const print = @import("utils/print.zig").print;
const Platform = @import("Platform.zig");

test {
    // Reference imported modules to include their tests
    _ = parser;
}

pub fn main(init: std.process.Init.Minimal) !void {
    const allocator = comptime switch (builtin.target.cpu.arch) {
        .wasm32, .wasm64 => std.heap.wasm_allocator,
        else => std.heap.page_allocator,
    };
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

    var args_it = try std.process.Args.Iterator.initAllocator(init.args, allocator);
    defer args_it.deinit();
    _ = args_it.skip(); // program name

    const mode = try allocator.dupe(u8, args_it.next() orelse return usage(io));
    defer allocator.free(mode);
    const path = try allocator.dupe(u8, args_it.next() orelse return usage(io));
    defer allocator.free(path);

    var platform = try Platform.init(allocator, io);
    defer platform.deinit();

    if (std.mem.eql(u8, mode, "--binary")) {
        try platform.load_program_from_binary(path);
    } else if (std.mem.eql(u8, mode, "--elf")) {
        try platform.load_program_from_elf(path);
    } else {
        try print(io, "Invalid argument: {s}\n", .{mode});
        return;
    }

    try platform.run_program();
}

fn usage(io: std.Io) !void {
    try print(io, "Usage:\n\t--binary\tprogram.bin\n\t--elf\t\tprogram.elf\n", .{});
}

test "test built elf files" {
    const io = std.testing.io;
    var elf_dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "asm/elf", .{ .iterate = true }) catch @panic("Failed to open asm/elf directory");
    defer elf_dir.close(io);
    var iter = elf_dir.iterate();

    const allocator = std.testing.allocator;
    var platform = try Platform.init(allocator, io);
    defer platform.deinit();

    while (iter.next(io) catch @panic("Failed to iterate asm/elf directory")) |entry| {
        if (entry.kind != .file) continue;
        const ext = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, ext, ".elf")) continue;

        const elf_path = try std.fs.path.join(allocator, &[_][]const u8{ "asm/elf", entry.name });
        defer allocator.free(elf_path);
        try print(io, "\n\nLoading program from {s}\n", .{elf_path});
        try platform.load_program_from_elf(elf_path);
        try platform.run_program();
    }
}
