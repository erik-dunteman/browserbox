const std = @import("std");
const assert = @import("std").debug.assert;
const parser = @import("parser.zig");
const print = @import("utils/print.zig").print;
const Platform = @import("Platform.zig");

test {
    // Reference imported modules to include their tests
    _ = parser;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    // if (args.len != 2) {
    //     try print("Target file not provided\n", .{});
    //     return;
    // }

    var platform = try Platform.init(allocator);

    try platform.load_program_from_elf("asm/elf/fib_riscv.elf");
    try platform.memory.display();
    try platform.run_program();
    try platform.memory.display();
}
