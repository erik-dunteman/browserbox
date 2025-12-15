const std = @import("std");
const assert = @import("std").debug.assert;
const parser = @import("parser.zig");
const print = @import("io.zig").print;

test {
    // Reference imported modules to include their tests
    _ = parser;
}

pub fn main() !void {
    const inst = parser.parse_word(0b00000000001000001000000110110011);
    try print("instruction: {any}\n", .{inst});

    // const allocator = std.heap.page_allocator;
    // const args = try std.process.argsAlloc(allocator);
    // defer std.process.argsFree(allocator, args);
    // if (args.len != 2) {
    //     try print("Target file not provided\n", .{});
    //     return;
    // }
    // const program = try Program.init_from_file(allocator, args[1]);
    // defer program.deinit(allocator);
    // var platform = Platform.new();
    // try platform.run_program(&program);
}

const Platform = struct {
    registers: [32]u64, // RV64 system has 64bit registers
    program_counter: usize,

    fn new() Platform {
        return Platform{
            .registers = undefined,
            .program_counter = 0,
        };
    }

    fn run_program(self: *Platform, program: *const Program) !void {
        while (self.program_counter < program.instructions.len) {
            try print("\n", .{});
            const word = program.instructions[self.program_counter];
            const instruction = try parser.parse_word(word);
            try instruction.execute(self);
        }
    }
};

const Program = struct {
    instructions: []u32,

    pub fn init_from_file(allocator: std.mem.Allocator, path: []const u8) !Program {
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

        return Program{ .instructions = instructions };
    }

    pub fn deinit(self: *const Program, allocator: std.mem.Allocator) void {
        allocator.free(self.instructions);
    }
};
