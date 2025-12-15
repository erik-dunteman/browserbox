// reference: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
// reference: https://msyksphinz-self.github.io/riscv-isadoc/
// we make small adjustments to fit RV64

const std = @import("std");
const Instruction = @import("instructions.zig").Instruction;
const print = @import("io.zig").print;

pub fn parse_word(word: u32) Instruction {
    return WordFormat.from_word(word).into_instruction();
}

// 32 bit words are parsed according to these formats
const Format = enum { R, I, S, B, U, J };

// Opcodes determine which format to use. Some opcodes use the same format.
const opcode_to_format: [128]?Format = blk: {
    var table: [128]?Format = .{null} ** 128;
    table[0b0110011] = .R; // op (add, sub, xor, etc.)
    table[0b0010011] = .I; // op_i (addi, etc.)
    table[0b0000011] = .I; // load
    table[0b0100011] = .S; // store
    table[0b1100011] = .B; // branch
    table[0b1101111] = .J; // jal
    table[0b1100111] = .I; // jalr
    table[0b0110111] = .U; // lui
    table[0b0010111] = .U; // auipc
    table[0b1110011] = .I; // env (ecall, ebreak)
    break :blk table;
};

// All formats
const WordFormat = union(enum) {

    // Convert a 32 bit word to a WordFormat
    pub fn from_word(word: u32) WordFormat {
        const opcode = word & 0b1111111;
        const format = opcode_to_format[opcode] orelse {
            var buf: [64]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "unsupported opcode: 0b{b:0>7}", .{opcode}) catch {
                @panic("failed to print opcode");
            };
            @panic(msg);
        };

        // All enum variants are packed structs in the same order the bits show up in the word
        // So we can directly bitcast
        return switch (format) {
            .R => .{ .R = @bitCast(word) },
            .I => .{ .I = @bitCast(word) },
            .S => .{ .S = @bitCast(word) },
            .B => .{ .B = @bitCast(word) },
            .U => .{ .U = @bitCast(word) },
            .J => .{ .J = @bitCast(word) },
        };
    }

    pub fn into_instruction(self: @This()) Instruction {
        switch (self) {
            inline else => |inner| {
                return inner.into_instruction();
            },
        }
    }

    // Each format as a packed struct in LSB order, allowing direct bitcast from word

    R: packed struct {
        opcode: u7, // 0:6
        rd: u5, // 7:11
        funct3: u3, // 12:14
        rs1: u5, // 15:19
        rs2: u5, // 20:24
        funct7: u7, // 25:31

        fn into_instruction(self: @This()) Instruction {
            switch (self.funct3) {
                0x0 => {
                    switch (self.funct7) {
                        0x0 => return .{ .add = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                        0x20 => return .{ .sub = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                        else => @panic("unknown funct7 in 0x0 branch of R-type instruction parse"),
                    }
                },
                0x1 => return .{ .sll = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                0x2 => return .{ .slt = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                0x3 => return .{ .sltu = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                0x4 => return .{ .xor = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                0x5 => {
                    switch (self.funct7) {
                        0x0 => return .{ .srl = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                        0x20 => return .{ .sra = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                        else => @panic("unknown funct7 in 0x5 branch of R-type instruction parse"),
                    }
                },
                0x6 => return .{ .or_ = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
                0x7 => return .{ .and_ = .{ .rd = self.rd, .rs1 = self.rs1, .rs2 = self.rs2 } },
            }
        }
    },

    I: packed struct {
        opcode: u7, // 0:6
        rd: u5, // 7:11
        funct3: u3, // 12:14
        rs1: u5, // 15:19
        imm: u12, // 20:31

        fn into_instruction(self: @This()) Instruction {
            switch (self.opcode) {
                0b0010011 => { // ALU immediate
                    switch (self.funct3) {
                        0x0 => return .{ .addi = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x1 => {
                            // note: shift_amt is found in the lowest 6 bits of the imm (in a RV64 system, it's 5 bits for RV32)
                            const shift_amt: u6 = @truncate(self.imm);
                            return .{ .slli = .{ .rd = self.rd, .rs1 = self.rs1, .shift_amt = shift_amt } };
                        },
                        0x2 => return .{ .slti = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x3 => return .{ .sltiu = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x4 => return .{ .xori = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x5 => {
                            // the lower 6 bits are the shift amount (RV64I uses 6 bits, RV32I uses 5)
                            const shift_amt: u6 = @truncate(self.imm);
                            // the upper 6 bits are an extra flag indicating the instruction variant
                            // RV64I: srli uses 0x00, srai uses 0x10 (bit 10 set)
                            switch (self.imm >> 6) {
                                0b000000 => return .{ .srli = .{ .rd = self.rd, .rs1 = self.rs1, .shift_amt = shift_amt } },
                                0b010000 => return .{ .srai = .{ .rd = self.rd, .rs1 = self.rs1, .shift_amt = shift_amt } },
                                else => @panic("unknown imm in 0x5 branch of I-type ALU instruction"),
                            }
                        },
                        0x6 => return .{ .ori = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x7 => return .{ .andi = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                    }
                },
                0b0000011 => { // Load
                    switch (self.funct3) {
                        0x0 => return .{ .lb = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x1 => return .{ .lh = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x2 => return .{ .lw = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x4 => return .{ .lbu = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        0x5 => return .{ .lhu = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } },
                        else => @panic("unknown funct3 in Load instruction"),
                    }
                },
                0b1100111 => { // jalr
                    return .{ .jalr = .{ .rd = self.rd, .rs1 = self.rs1, .imm = self.imm } };
                },
                0b1110011 => { // Environment
                    switch (self.imm) {
                        0x0 => return .{ .ecall = .{} },
                        0x1 => return .{ .ebreak = .{} },
                        else => @panic("unknown imm in Environment instruction"),
                    }
                },
                else => @panic("unknown opcode in I-type instruction"),
            }
        }
    },

    S: packed struct {
        opcode: u7, // 0:6
        imm_4_0: u5, // 7:11
        funct3: u3, // 12:14
        rs1: u5, // 15:19
        rs2: u5, // 20:24
        imm_11_5: u7, // 25:31

        fn imm(self: @This()) u12 {
            return @as(u12, self.imm_11_5) << 5 | self.imm_4_0;
        }

        fn into_instruction(self: @This()) Instruction {
            switch (self.funct3) {
                0x0 => return .{ .sb = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x1 => return .{ .sh = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x2 => return .{ .sw = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                else => @panic("unknown funct3 in S-type instruction"),
            }
        }
    },

    B: packed struct {
        opcode: u7,
        imm_11: u1,
        imm_4_1: u4,
        funct3: u3,
        rs1: u5,
        rs2: u5,
        imm_10_5: u6,
        imm_12: u1,

        fn imm(self: @This()) u13 {
            return @as(u13, self.imm_12) << 12 |
                @as(u13, self.imm_11) << 11 |
                @as(u13, self.imm_10_5) << 5 |
                @as(u13, self.imm_4_1) << 1;
        }

        fn into_instruction(self: @This()) Instruction {
            switch (self.funct3) {
                0x0 => return .{ .beq = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x1 => return .{ .bne = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x4 => return .{ .blt = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x5 => return .{ .bge = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x6 => return .{ .bltu = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                0x7 => return .{ .bgeu = .{ .rs1 = self.rs1, .rs2 = self.rs2, .imm = self.imm() } },
                else => @panic("unknown funct3 in B-type instruction"),
            }
        }
    },

    U: packed struct {
        opcode: u7,
        rd: u5,
        imm_31_12: u20,
        // Note: no imm() helper - the << 12 shift is part of lui/auipc execution semantics, not decoding

        fn into_instruction(self: @This()) Instruction {
            switch (self.opcode) {
                0b0110111 => return .{ .lui = .{ .rd = self.rd, .imm = self.imm_31_12 } },
                0b0010111 => return .{ .auipc = .{ .rd = self.rd, .imm = self.imm_31_12 } },
                else => @panic("unknown opcode in U-type instruction"),
            }
        }
    },

    J: packed struct {
        opcode: u7,
        rd: u5,
        imm_19_12: u8,
        imm_11: u1,
        imm_10_1: u10,
        imm_20: u1,

        fn imm(self: @This()) u21 {
            return @as(u21, self.imm_20) << 20 |
                @as(u21, self.imm_19_12) << 12 |
                @as(u21, self.imm_11) << 11 |
                @as(u21, self.imm_10_1) << 1;
        }

        fn into_instruction(self: @This()) Instruction {
            return .{ .jal = .{ .rd = self.rd, .imm = self.imm() } };
        }
    },
};

test "parse instructions" {
    const TestCase = struct { word: u32, expected: Instruction };
    const test_cases = [_]TestCase{
        // ALU Instructions (R-type, opcode 0110011)
        .{ .word = 0x002081b3, .expected = .{ .add = .{ .rd = 3, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x40208433, .expected = .{ .sub = .{ .rd = 8, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020c2b3, .expected = .{ .xor = .{ .rd = 5, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020e4b3, .expected = .{ .or_ = .{ .rd = 9, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020f633, .expected = .{ .and_ = .{ .rd = 12, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x00121333, .expected = .{ .sll = .{ .rd = 6, .rs1 = 4, .rs2 = 1 } } },
        .{ .word = 0x00125533, .expected = .{ .srl = .{ .rd = 10, .rs1 = 4, .rs2 = 1 } } },
        .{ .word = 0x40125533, .expected = .{ .sra = .{ .rd = 10, .rs1 = 4, .rs2 = 1 } } },
        .{ .word = 0x0020a233, .expected = .{ .slt = .{ .rd = 4, .rs1 = 1, .rs2 = 2 } } },
        .{ .word = 0x0020b3b3, .expected = .{ .sltu = .{ .rd = 7, .rs1 = 1, .rs2 = 2 } } },
        // ALU instructions (I-type, opcode 0010011)
        .{ .word = 0x00500093, .expected = .{ .addi = .{ .rd = 1, .rs1 = 0, .imm = 5 } } },
        .{ .word = 0x00c0c213, .expected = .{ .xori = .{ .rd = 4, .rs1 = 1, .imm = 12 } } },
        .{ .word = 0x0050e413, .expected = .{ .ori = .{ .rd = 8, .rs1 = 1, .imm = 5 } } },
        .{ .word = 0x00c0f593, .expected = .{ .andi = .{ .rd = 11, .rs1 = 1, .imm = 12 } } },
        .{ .word = 0x00109293, .expected = .{ .slli = .{ .rd = 5, .rs1 = 1, .shift_amt = 1 } } },
        .{ .word = 0x00115493, .expected = .{ .srli = .{ .rd = 9, .rs1 = 2, .shift_amt = 1 } } },
        .{ .word = 0x40115693, .expected = .{ .srai = .{ .rd = 13, .rs1 = 2, .shift_amt = 1 } } },
        .{ .word = 0x00a0a213, .expected = .{ .slti = .{ .rd = 4, .rs1 = 1, .imm = 10 } } },
        .{ .word = 0x00a0b493, .expected = .{ .sltiu = .{ .rd = 9, .rs1 = 1, .imm = 10 } } },
        // Load instructions (I-type, opcode 0000011)
        .{ .word = 0x00810083, .expected = .{ .lb = .{ .rd = 1, .rs1 = 2, .imm = 8 } } },
        .{ .word = 0x01019103, .expected = .{ .lh = .{ .rd = 2, .rs1 = 3, .imm = 16 } } },
        .{ .word = 0x02022183, .expected = .{ .lw = .{ .rd = 3, .rs1 = 4, .imm = 32 } } },
        .{ .word = 0x0402c203, .expected = .{ .lbu = .{ .rd = 4, .rs1 = 5, .imm = 64 } } },
        .{ .word = 0x08035283, .expected = .{ .lhu = .{ .rd = 5, .rs1 = 6, .imm = 128 } } },
        // Store instructions (S-type, opcode 0100011)
        .{ .word = 0x00208423, .expected = .{ .sb = .{ .rs1 = 1, .rs2 = 2, .imm = 8 } } },
        .{ .word = 0x00311823, .expected = .{ .sh = .{ .rs1 = 2, .rs2 = 3, .imm = 16 } } },
        .{ .word = 0x0241a023, .expected = .{ .sw = .{ .rs1 = 3, .rs2 = 4, .imm = 32 } } },
        // Branch instructions (B-type, opcode 1100011)
        .{ .word = 0x00208463, .expected = .{ .beq = .{ .rs1 = 1, .rs2 = 2, .imm = 8 } } },
        .{ .word = 0x00209863, .expected = .{ .bne = .{ .rs1 = 1, .rs2 = 2, .imm = 16 } } },
        .{ .word = 0x0220c063, .expected = .{ .blt = .{ .rs1 = 1, .rs2 = 2, .imm = 32 } } },
        .{ .word = 0x0420d063, .expected = .{ .bge = .{ .rs1 = 1, .rs2 = 2, .imm = 64 } } },
        .{ .word = 0x0820e063, .expected = .{ .bltu = .{ .rs1 = 1, .rs2 = 2, .imm = 128 } } },
        .{ .word = 0x1020f063, .expected = .{ .bgeu = .{ .rs1 = 1, .rs2 = 2, .imm = 256 } } },
        // Jump instructions
        .{ .word = 0x100000ef, .expected = .{ .jal = .{ .rd = 1, .imm = 256 } } }, // J-type, opcode 1101111
        .{ .word = 0x040100e7, .expected = .{ .jalr = .{ .rd = 1, .rs1 = 2, .imm = 64 } } }, // I-type, opcode 1100111
        // Upper immediate instructions (U-type)
        .{ .word = 0x123450b7, .expected = .{ .lui = .{ .rd = 1, .imm = 0x12345 } } }, // opcode 0110111
        .{ .word = 0xabcde117, .expected = .{ .auipc = .{ .rd = 2, .imm = 0xabcde } } }, // opcode 0010111
        // Environment instructions (I-type, opcode 1110011)
        .{ .word = 0x00000073, .expected = .{ .ecall = .{} } },
        .{ .word = 0x00100073, .expected = .{ .ebreak = .{} } },
    };

    for (test_cases) |tc| {
        const parsed = parse_word(tc.word);
        try std.testing.expectEqual(tc.expected, parsed);
    }
}
