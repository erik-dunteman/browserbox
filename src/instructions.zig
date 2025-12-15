// reference: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
// reference: https://msyksphinz-self.github.io/riscv-isadoc/
// we make small adjustments to fit RV64
const std = @import("std");
const Platform = @import("Platform.zig");
const print = @import("io.zig").print;

pub const Instruction = union(enum) {
    pub fn execute(self: Instruction, platform: *Platform) !void {
        try print("Executing instruction: {any}\n", .{self});
        switch (self) {
            // forces all enum variants to have an .execute function
            inline else => |inner| {
                try inner.execute(platform);
            },
        }
    }

    // Enum variants

    add: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // wrapping add
            platform.registers[self.rd] = platform.registers[self.rs1] +% platform.registers[self.rs2];
            platform.program_counter += 4;
        }
    },

    sub: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // wrapping subtract
            platform.registers[self.rd] = platform.registers[self.rs1] -% platform.registers[self.rs2];
            platform.program_counter += 4;
        }
    },

    xor: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] ^ platform.registers[self.rs2];
            platform.program_counter += 4;
        }
    },

    or_: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] | platform.registers[self.rs2];
            platform.program_counter += 4;
        }
    },

    and_: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] & platform.registers[self.rs2];
            platform.program_counter += 4;
        }
    },

    sll: struct {
        rd: u5,
        rs1: u5,
        rs2: u6,

        pub fn execute(self: *const @This(), platform: *Platform) !void {
            // zig protects against bit shift_amts that'd violate type casting
            const shift_amt: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
            platform.registers[self.rd] = platform.registers[self.rs1] << shift_amt;
            platform.program_counter += 4;
        }
    },

    srl: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const shift_amt: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
            platform.registers[self.rd] = platform.registers[self.rs1] >> shift_amt;
            platform.program_counter += 4;
        }
    },

    sra: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Requires MSB Extends implementation
            // Zig automatically performs MSB extends on signed types
            // So typecaset to i64 before doing bit shift
            const shift_amt: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
            const signed_val: i64 = @bitCast(platform.registers[self.rs1]);
            platform.registers[self.rd] = @bitCast(signed_val >> shift_amt);
            platform.program_counter += 4;
        }
    },

    slt: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Comparison of twos-compliment signed ints
            const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
            const rs2_signed: i64 = @bitCast(platform.registers[self.rs2]);
            platform.registers[self.rd] = if (rs1_signed < rs2_signed) 1 else 0;
            platform.program_counter += 4;
        }
    },

    sltu: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Comparison of unsigned ints
            platform.registers[self.rd] = if (platform.registers[self.rs1] < platform.registers[self.rs2]) 1 else 0;
            platform.program_counter += 4;
        }
    },

    addi: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] +% self.imm;
            platform.program_counter += 4;
        }
    },

    xori: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] ^ self.imm;
            platform.program_counter += 4;
        }
    },

    ori: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] | self.imm;
            platform.program_counter += 4;
        }
    },

    andi: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] & self.imm;
            platform.program_counter += 4;
        }
    },

    slli: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // shift amt is precomputed during parse due to imm being partially used for flags
            platform.registers[self.rd] = platform.registers[self.rs1] << self.shift_amt;
            platform.program_counter += 4;
        }
    },

    srli: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] >> self.shift_amt;
            platform.program_counter += 4;
        }
    },

    srai: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Requires MSB Extends implementation
            const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
            platform.registers[self.rd] = @bitCast(rs1_signed >> self.shift_amt);
            platform.program_counter += 4;
        }
    },

    slti: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Comparison of twos-compliment signed ints
            const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
            const imm_signed: i64 = @bitCast(@as(i64, self.imm));
            platform.registers[self.rd] = if (rs1_signed < imm_signed) 1 else 0;
            platform.program_counter += 4;
        }
    },

    sltiu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Comparison of unsigned ints
            platform.registers[self.rd] = if (platform.registers[self.rs1] < self.imm) 1 else 0;
            platform.program_counter += 4;
        }
    },

    lb: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            // cast first to signed, so widening sign-extends
            const byte_signed: i8 = @bitCast(platform.memory.load_byte(address));
            // widen to fit into register
            const data_signed: i64 = @intCast(byte_signed);
            // cast back to unsigned to store in register
            platform.registers[self.rd] = @bitCast(data_signed);
            platform.program_counter += 4;
        }
    },

    lh: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const half_signed: i16 = @bitCast(platform.memory.load_half(address));
            const data_signed: i64 = @intCast(half_signed);
            platform.registers[self.rd] = @bitCast(data_signed);
            platform.program_counter += 4;
        }
    },

    lw: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const word: u32 = platform.memory.load_word(address);
            platform.registers[self.rd] = @intCast(word);
            platform.program_counter += 4;
        }
    },

    lbu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const byte = platform.memory.load_byte(address);
            platform.registers[self.rd] = @intCast(byte); // zero-extends
            platform.program_counter += 4;
        }
    },

    lhu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const half = platform.memory.load_half(address);
            platform.registers[self.rd] = @intCast(half); // zero-extends
            platform.program_counter += 4;
        }
    },

    // Store Instructions (S-type, opcode 0100011)

    sb: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const to_store: u8 = @intCast(platform.registers[self.rs2] & 0xFF); // take lowest byte
            try platform.memory.store_byte(address, to_store);
            platform.program_counter += 4;
        }
    },

    sh: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const to_store: u16 = @intCast(platform.registers[self.rs2] & 0xFFFF); // take lowest half
            try platform.memory.store_half(address, to_store);
            platform.program_counter += 4;
        }
    },

    sw: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            const address = platform.registers[self.rs1] + self.imm;
            const to_store: u32 = @intCast(platform.registers[self.rs2] & 0xFFFFFFFF); // take lowest word
            try platform.memory.store_word(address, to_store);
            platform.program_counter += 4;
        }
    },

    // Branch Instructions (B-type, opcode 1100011)

    beq: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    bne: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    blt: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    bge: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    bltu: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    bgeu: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    // Jump Instructions

    jal: struct {
        rd: u5,
        imm: u21,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    jalr: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    // Upper Immediate Instructions (U-type)

    lui: struct {
        rd: u5,
        imm: u20,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    auipc: struct {
        rd: u5,
        imm: u20,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    // Environment Instructions (I-type, opcode 1110011)

    ecall: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    ebreak: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },
};
