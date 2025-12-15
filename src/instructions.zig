// reference: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
// reference: https://msyksphinz-self.github.io/riscv-isadoc/
// we make small adjustments to fit RV64
const std = @import("std");
const Platform = @import("main.zig").Platform;

pub const Instruction = union(enum) {
    pub fn execute(self: Instruction, platform: *Platform) !void {
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
            platform.registers[self.rd] = platform.registers[self.rs1] + platform.registers[self.rs2];
        }
    },

    sub: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] - platform.registers[self.rs2];
        }
    },

    xor: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] ^ platform.registers[self.rs2];
        }
    },

    or_: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    and_: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    sll: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: *const @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    srl: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    sra: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    slt: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    sltu: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    addi: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            platform.registers[self.rd] = platform.registers[self.rs1] + self.imm;
        }
    },

    xori: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    ori: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    andi: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    slli: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    srli: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    srai: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    slti: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    sltiu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    // Load Instructions (I-type, opcode 0000011)

    lb: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    lh: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    lw: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    lbu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    lhu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    // Store Instructions (S-type, opcode 0100011)

    sb: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    sh: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
        }
    },

    sw: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            _ = self;
            _ = platform;
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
