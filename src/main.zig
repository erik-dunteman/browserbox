const std = @import("std");
const assert = @import("std").debug.assert;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const program = try Program.init_from_file(allocator, "asm/bin/all_implemented.bin");
    defer program.deinit(allocator);
    var platform = Platform.new();
    try platform.run_program(&program);
}

const Platform = struct {
    registers: [32]u64,
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
            const op = try Op.from_word(word);
            try op.execute(self);
        }
    }
};

const Program = struct {
    instructions: []u32,

    pub fn init_from_file(allocator: std.mem.Allocator, path: []const u8) !Program {
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

fn print(comptime fmt: []const u8, args: anytype) !void {
    // Use stderr to avoid interfering with zig build test's IPC protocol on stdout
    const stderr = std.fs.File.stderr();
    var print_buf: [256]u8 = undefined;
    stderr.writeAll(std.fmt.bufPrint(&print_buf, fmt, args) catch return) catch {};
}

const RType = struct {
    op: RTypeOp,
    rd: u5,
    rs1: u5,
    rs2: u5,

    pub fn from_word(word: u32) !RType {
        try print("word: 0b{b:0>32}\n", .{word});
        const rd = word >> 7 & 0b11111; // 7:12 (exclusive of idx=12)
        const funct3 = word >> 12 & 0b111; // 12:15
        const rs1 = word >> 15 & 0b11111; // 15:20
        const rs2 = word >> 20 & 0b11111; // 20:25
        const funct7 = word >> 25;
        return RType{
            .op = try RTypeOp.from(
                @intCast(funct3),
                @intCast(funct7),
            ),
            .rd = @intCast(rd),
            .rs1 = @intCast(rs1),
            .rs2 = @intCast(rs2),
        };
    }

    fn eq(self: *const RType, other: *const RType) bool {
        return self.op == other.op and self.rd == other.rd and self.rs1 == other.rs1 and self.rs2 == other.rs2;
    }

    pub fn execute(self: *const RType, platform: *Platform) !void {
        try print("\t{s}\tr{d},\tr{d},\tr{d}\n", .{ @tagName(self.op), self.rd, self.rs1, self.rs2 });
        switch (self.op) {
            .add => {
                platform.registers[self.rd] = platform.registers[self.rs1] +% platform.registers[self.rs2]; // wrapping add
            },
            .sub => {
                platform.registers[self.rd] = platform.registers[self.rs1] -% platform.registers[self.rs2]; // wrapping subtract
            },
            .xor => {
                platform.registers[self.rd] = platform.registers[self.rs1] ^ platform.registers[self.rs2];
            },
            .or_ => {
                platform.registers[self.rd] = platform.registers[self.rs1] | platform.registers[self.rs2];
            },
            .and_ => {
                platform.registers[self.rd] = platform.registers[self.rs1] & platform.registers[self.rs2];
            },

            // zig protects against bit shifts that'd violate type casting
            // so we need to mask the shift amount down to u6 for u64 bit shifts
            .sll => {
                const shift: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
                platform.registers[self.rd] = platform.registers[self.rs1] << shift;
            },
            .srl => {
                const shift: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
                platform.registers[self.rd] = platform.registers[self.rs1] >> shift;
            },
            else => @panic("unimplemented rtype op in execute"),
        }
        try print("\tres:\tr{d} = {d}\n", .{ self.rd, platform.registers[self.rd] });
        // All R Type ops increment program counter
        platform.program_counter += 1;
    }
};

const RTypeOp = enum {
    add,
    sub,
    xor,
    or_,
    and_,
    sll,
    srl,
    sra,
    slt,
    sltu,

    pub fn from(funct3: u3, funct7: u7) !RTypeOp {
        switch (funct3) {
            0x0 => {
                switch (funct7) {
                    0x0 => return .add,
                    0x20 => return .sub,
                    else => @panic("unknown funct7 in 0x0 branch of rtype op from"),
                }
            },
            0x1 => return .sll,
            0x2 => return .slt,
            0x3 => return .sltu,
            0x4 => return .xor,
            0x5 => {
                switch (funct7) {
                    0x0 => return .srl,
                    0x20 => return .sra,
                    else => @panic("unknown funct7 in 0x5 branch of rtype op from"),
                }
            },
            0x6 => return .or_,
            0x7 => return .and_,
        }
    }
};

const IType = struct {
    op: ItypeOp,
    rd: u5,
    rs1: u5,
    imm: u12,

    pub fn from_word(word: u32) !IType {
        try print("word: 0b{b:0>32}\n", .{word});
        const rd = word >> 7 & 0b11111; // 7:12 (exclusive of idx=12)
        const funct3 = word >> 12 & 0b111; // 12:15
        const rs1 = word >> 15 & 0b11111; // 15:20
        const imm = word >> 20;
        return IType{
            .op = try ItypeOp.from(@intCast(funct3), @intCast(imm)),
            .rd = @intCast(rd),
            .rs1 = @intCast(rs1),
            .imm = @intCast(imm),
        };
    }

    fn eq(self: *const IType, other: *const IType) bool {
        return self.op == other.op and self.rd == other.rd and self.rs1 == other.rs1 and self.imm == other.imm;
    }

    pub fn execute(self: *const IType, platform: *Platform) !void {
        try print("\t{s}\tr{d},\tr{d},\t{d}\n", .{ @tagName(self.op), self.rd, self.rs1, self.imm });
        switch (self.op) {
            .addi => {
                platform.registers[self.rd] = platform.registers[self.rs1] + self.imm;
            },
            else => @panic("unknown itype op in execute"),
        }
        try print("\tres:\tr{d} = {d}\n", .{ self.rd, platform.registers[self.rd] });

        // All I Type ops increment program counter
        platform.program_counter += 1;
    }
};

const ItypeOp = enum {
    addi,
    xori,
    ori,
    andi,
    slli,
    srli,
    srai,
    slti,
    sltiu,

    pub fn from(funct3: u3, imm: u12) !ItypeOp {
        // some
        switch (funct3) {
            0x0 => return .addi,
            0x1 => return .slli,
            0x2 => return .slti,
            0x3 => return .sltiu,
            0x4 => return .xori,
            0x5 => {
                // 0x5 is a special case where upper bits of imm encode variant
                // imm[11:5] = 0000000 for SRLI, 0100000 for SRAI
                switch (imm >> 5) {
                    0x00 => return .srli,
                    0x20 => return .srai,
                    else => @panic("unknown imm in itype op"),
                }
            },
            0x6 => return .ori,
            0x7 => return .andi,
        }
    }
};

const Op = union(enum) {
    rtype: RType,
    itype: IType,

    pub fn from_word(word: u32) !Op {
        const op = word & 0b1111111; // 0:7
        switch (op) {
            0b0110011 => { // R-Type
                return Op{ .rtype = try RType.from_word(word) };
            },
            0b0010011 => { // I-Type
                return Op{ .itype = try IType.from_word(word) };
            },
            else => @panic("unknown opcode in op from word"),
        }
    }

    pub fn execute(self: *const Op, platform: *Platform) !void {
        switch (self.*) {
            .rtype => |rtype| {
                try rtype.execute(platform);
            },
            .itype => |itype| {
                try itype.execute(platform);
            },
        }
    }

    fn eq(self: *const Op, other: *const Op) bool {
        switch (self.*) {
            .rtype => |rtype| {
                return rtype.eq(&other.rtype);
            },
            .itype => |itype| {
                return itype.eq(&other.itype);
            },
        }
    }
};

test "parse ops" {
    const TestCase = struct { word: u32, expected: Op };
    const test_cases = [_]TestCase{
        .{ .word = 0x002081b3, .expected = .{ .rtype = RType{ .op = .add, .rd = 3, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x40208433, .expected = .{ .rtype = RType{ .op = .sub, .rd = 8, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020c2b3, .expected = .{ .rtype = RType{ .op = .xor, .rd = 5, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020e4b3, .expected = .{ .rtype = RType{ .op = .or_, .rd = 9, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020f633, .expected = .{ .rtype = RType{ .op = .and_, .rd = 12, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x00121333, .expected = .{ .rtype = RType{ .op = .sll, .rd = 6, .rs1 = 4, .rs2 = 1 } } },
        .{ .word = 0x00125533, .expected = .{ .rtype = RType{ .op = .srl, .rd = 10, .rs1 = 4, .rs2 = 1 } } },
        .{ .word = 0x40125533, .expected = .{ .rtype = RType{ .op = .sra, .rd = 10, .rs1 = 4, .rs2 = 1 } } },
        .{ .word = 0x0020a233, .expected = .{ .rtype = RType{ .op = .slt, .rd = 4, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020b3b3, .expected = .{ .rtype = RType{ .op = .sltu, .rd = 7, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x00500093, .expected = .{ .itype = IType{ .op = .addi, .rd = 1, .rs1 = 0, .imm = 5 } } },
        .{ .word = 0x00c0c213, .expected = .{ .itype = IType{ .op = .xori, .rd = 4, .rs1 = 1, .imm = 12 } } },
        .{ .word = 0x0050e413, .expected = .{ .itype = IType{ .op = .ori, .rd = 8, .rs1 = 1, .imm = 5 } } },
        .{ .word = 0x00c0f593, .expected = .{ .itype = IType{ .op = .andi, .rd = 11, .rs1 = 1, .imm = 12 } } },
        .{ .word = 0x00109293, .expected = .{ .itype = IType{ .op = .slli, .rd = 5, .rs1 = 1, .imm = 1 } } },
        .{ .word = 0x00115493, .expected = .{ .itype = IType{ .op = .srli, .rd = 9, .rs1 = 2, .imm = 1 } } },
        .{ .word = 0x40115693, .expected = .{ .itype = IType{ .op = .srai, .rd = 13, .rs1 = 2, .imm = 0x401 } } },
        .{ .word = 0x00a0a213, .expected = .{ .itype = IType{ .op = .slti, .rd = 4, .rs1 = 1, .imm = 10 } } },
        .{ .word = 0x00a0b493, .expected = .{ .itype = IType{ .op = .sltiu, .rd = 9, .rs1 = 1, .imm = 10 } } },
    };

    for (test_cases) |tc| {
        const parsed = try Op.from_word(tc.word);
        try std.testing.expect(parsed.eq(&tc.expected));
    }
}
