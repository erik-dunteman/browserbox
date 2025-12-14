const std = @import("std");
const assert = @import("std").debug.assert;

var stdout: std.fs.File = undefined;

pub fn main() !void {
    stdout = std.fs.File.stdout();
    try print("hello world\n", .{});

    // todo add load from file
    var program = Program{
        .instructions = .{
            .{ 0x93, 0x00, 0x50, 0x00 },
            .{ 0x13, 0x01, 0x30, 0x00 },
            .{ 0xb3, 0x81, 0x20, 0x00 },
        },
        .program_counter = 0,
    };

    try program.run();
}

const Program = struct {
    instructions: [3][4]u8,
    program_counter: usize,

    fn run(self: *Program) !void {
        while (self.program_counter < self.instructions.len) {
            const instruction = self.instructions[self.program_counter];
            const to_exec = try decode(instruction);
            try self.execute(to_exec);
        }
    }

    fn execute(self: *Program, op: Op) !void {
        _ = op;
        self.program_counter += 1;
    }
};

fn print(comptime fmt: []const u8, args: anytype) !void {
    var print_buf: [256]u8 = undefined;
    try stdout.writeAll(try std.fmt.bufPrint(&print_buf, fmt, args));
}

fn decode(instruction: [4]u8) !Op {
    const word = std.mem.readInt(u32, &instruction, .little);
    try print("decoded: 0b{b:0>32}\n", .{word});

    const opmask = 0b00000000_00000000_00000000_01111111;
    const op = word & opmask;
    switch (op) {
        0b0110011 => { // R-Type
            return try decode_r_type(word);
        },
        0b0010011 => { // I-Type
            return try decode_i_type(word);
        },
        else => @panic("unknown opcode"),
    }
}

fn decode_r_type(word: u32) !Op {
    const rd = word >> 7 & 0b11111; // 7:12 (exclusive of idx=12)
    const funct3 = word >> 12 & 0b111; // 12:15
    const rs1 = word >> 15 & 0b11111; // 15:20
    const rs2 = word >> 20 & 0b11111; // 20:25
    const funct7 = word >> 25;
    try print("R-Type\n", .{});
    switch (funct3) {
        0x0 => {
            switch (funct7) {
                0x0 => {
                    try print("\tadd\n", .{});
                    try print("\t\tr{d} = r{d} + r{d}\n", .{ rd, rs1, rs2 });
                    return Op{ .add = Op_Add{
                        .rd = @intCast(rd),
                        .rs1 = @intCast(rs1),
                        .rs2 = @intCast(rs2),
                    } };
                },
                // sub goes here
                else => @panic("unknown funct7"),
            }
        },
        else => @panic("unknown funct3"),
    }
}

fn decode_i_type(word: u32) !Op {
    const rd = word >> 7 & 0b11111; // 7:12 (exclusive of idx=12)
    const funct3 = word >> 12 & 0b111; // 12:15
    const rs1 = word >> 15 & 0b11111; // 15:20
    const imm = word >> 20;
    try print("I-Type\n", .{});
    switch (funct3) {
        0x0 => {
            try print("\taddi\n", .{});
            try print("\t\tr{d} = r{d} + {d}\n", .{ rd, rs1, imm });
            return Op{ .addi = Op_Addi{
                .rd = @intCast(rd),
                .rs1 = @intCast(rs1),
                .imm = @intCast(imm),
            } };
        },
        else => @panic("unknown funct3"),
    }
}

const Op = union(enum) {
    addi: Op_Addi,
    add: Op_Add,
};

const Op_Addi = struct {
    rd: u5,
    rs1: u5,
    imm: u12,
};

const Op_Add = struct {
    rd: u5,
    rs1: u5,
    rs2: u5,
};
