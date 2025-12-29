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

pub fn main() !void {
    const allocator = comptime switch (builtin.target.cpu.arch) {
        .wasm32 => std.heap.wasm_allocator,
        .wasm64 => std.heap.wasm_allocator,
        else => std.heap.page_allocator,
    };

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 3) {
        try print("Usage:\n\t--binary\tprogram.bin\n\t--elf\t\tprogram.elf\n", .{});
        return;
    }

    var platform = try Platform.init(allocator);
    defer platform.deinit();

    if (std.mem.eql(u8, args[1], "--binary")) {
        try platform.load_program_from_binary(args[2]);
    } else if (std.mem.eql(u8, args[1], "--elf")) {
        try platform.load_program_from_elf(args[2]);
    } else {
        try print("Invalid argument: {s}\n", .{args[1]});
        return;
    }

    try platform.run_program();
}

test "test built elf files" {
    const elf_dir = std.fs.cwd().openDir("asm/elf", .{ .iterate = true }) catch @panic("Failed to open asm/elf directory");
    var iter = elf_dir.iterate();

    const allocator = std.testing.allocator;
    var platform = try Platform.init(allocator);
    defer platform.deinit();

    while (iter.next() catch @panic("Failed to iterate asm/elf directory")) |entry| {
        if (entry.kind != .file) continue;
        const ext = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, ext, ".elf")) continue;

        const elf_path = try std.fs.path.join(allocator, &[_][]const u8{ "asm/elf", entry.name });
        defer allocator.free(elf_path);
        try platform.load_program_from_elf(elf_path);
        try platform.run_program();
    }
}
