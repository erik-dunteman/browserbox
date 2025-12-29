const std = @import("std");
const Platform = @import("Platform.zig");
const print = @import("utils/print.zig").print;
const extend = @import("utils/extend.zig");

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
            // x[rd] = x[rs1] + x[rs2]
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] +% platform.registers[self.rs2];
            }
            platform.program_counter += 4;
        }
    },

    sub: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] - x[rs2]
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] -% platform.registers[self.rs2];
            }
            platform.program_counter += 4;
        }
    },

    xor: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] ^ x[rs2]
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] ^ platform.registers[self.rs2];
            }
            platform.program_counter += 4;
        }
    },

    or_: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] | x[rs2]
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] | platform.registers[self.rs2];
            }
            platform.program_counter += 4;
        }
    },

    and_: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] & x[rs2]
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] & platform.registers[self.rs2];
            }
            platform.program_counter += 4;
        }
    },

    sll: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: *const @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] << x[rs2]
            if (self.rd != 0) {
                const shift_amt: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
                platform.registers[self.rd] = platform.registers[self.rs1] << shift_amt;
            }
            platform.program_counter += 4;
        }
    },

    srl: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] >>u x[rs2]
            if (self.rd != 0) {
                const shift_amt: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
                platform.registers[self.rd] = platform.registers[self.rs1] >> shift_amt;
            }
            platform.program_counter += 4;
        }
    },

    sra: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] >>s x[rs2]
            if (self.rd != 0) {
                const shift_amt: u6 = @intCast(platform.registers[self.rs2] & 0b11_1111);
                const signed_val: i64 = @bitCast(platform.registers[self.rs1]);
                platform.registers[self.rd] = @bitCast(signed_val >> shift_amt);
            }
            platform.program_counter += 4;
        }
    },

    slt: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] <s x[rs2]
            if (self.rd != 0) {
                const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
                const rs2_signed: i64 = @bitCast(platform.registers[self.rs2]);
                platform.registers[self.rd] = if (rs1_signed < rs2_signed) 1 else 0;
            }
            platform.program_counter += 4;
        }
    },

    sltu: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] <u x[rs2]
            if (self.rd != 0) {
                platform.registers[self.rd] = if (platform.registers[self.rs1] < platform.registers[self.rs2]) 1 else 0;
            }
            platform.program_counter += 4;
        }
    },

    addi: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] + sext(immediate)
            // try print("addi, rd: {d}, rs1: {d}, imm: {d}\n", .{ self.rd, self.rs1, self.imm });
            // try print("PC before everything: {d}\n", .{platform.program_counter});
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                // try print("imm_extended: {d}\n", .{imm_extended});
                platform.registers[self.rd] = platform.registers[self.rs1] +% imm_extended;
                // try print("registers[rd]: {d}\n", .{platform.registers[self.rd]});
            }
            // try print("PC after everything: {d}\n", .{platform.program_counter});
            platform.program_counter += 4;
            // try print("PC after increment: {d}\n", .{platform.program_counter});
        }
    },

    xori: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] ^ sext(immediate)
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                platform.registers[self.rd] = platform.registers[self.rs1] ^ imm_extended;
            }
            platform.program_counter += 4;
        }
    },

    ori: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] | sext(immediate)
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                platform.registers[self.rd] = platform.registers[self.rs1] | imm_extended;
            }
            platform.program_counter += 4;
        }
    },

    andi: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] & sext(immediate)
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                platform.registers[self.rd] = platform.registers[self.rs1] & imm_extended;
            }
            platform.program_counter += 4;
        }
    },

    slli: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] << shamt
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] << self.shift_amt;
            }
            platform.program_counter += 4;
        }
    },

    srli: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] >>u shamt
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.registers[self.rs1] >> self.shift_amt;
            }
            platform.program_counter += 4;
        }
    },

    srai: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u6,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] >>s shamt
            if (self.rd != 0) {
                const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
                platform.registers[self.rd] = @bitCast(rs1_signed >> self.shift_amt);
            }
            platform.program_counter += 4;
        }
    },

    slti: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] <s sext(immediate)
            if (self.rd != 0) {
                const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
                const imm_extended = extend.sign_extend(u12, self.imm);
                const imm_signed: i64 = @bitCast(imm_extended);
                platform.registers[self.rd] = if (rs1_signed < imm_signed) 1 else 0;
            }
            platform.program_counter += 4;
        }
    },

    sltiu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = x[rs1] <u sext(immediate)
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                platform.registers[self.rd] = if (platform.registers[self.rs1] < imm_extended) 1 else 0;
            }
            platform.program_counter += 4;
        }
    },

    lb: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(M[x[rs1] + sext(offset)][7:0])
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                const address = platform.registers[self.rs1] +% imm_extended;
                const byte_signed: i8 = @bitCast(platform.memory.load_byte(@intCast(address)));
                const data_signed: i64 = @intCast(byte_signed);
                platform.registers[self.rd] = @bitCast(data_signed);
            }
            platform.program_counter += 4;
        }
    },

    lh: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(M[x[rs1] + sext(offset)][15:0])
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                const address = platform.registers[self.rs1] +% imm_extended;
                const half_signed: i16 = @bitCast(platform.memory.load_half(@intCast(address)));
                const data_signed: i64 = @intCast(half_signed);
                platform.registers[self.rd] = @bitCast(data_signed);
            }
            platform.program_counter += 4;
        }
    },

    lw: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(M[x[rs1] + sext(offset)][31:0])
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                const address = platform.registers[self.rs1] +% imm_extended;
                const word: u32 = platform.memory.load_word(@intCast(address));
                platform.registers[self.rd] = extend.sign_extend(u32, word);
            }
            platform.program_counter += 4;
        }
    },

    lbu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = M[x[rs1] + sext(offset)][7:0]
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                const address = platform.registers[self.rs1] +% imm_extended;
                const byte = platform.memory.load_byte(@intCast(address));
                platform.registers[self.rd] = extend.zero_extend(u8, byte);
            }
            platform.program_counter += 4;
        }
    },

    lhu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = M[x[rs1] + sext(offset)][15:0]
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                const address = platform.registers[self.rs1] +% imm_extended;
                const half = platform.memory.load_half(@intCast(address));
                platform.registers[self.rd] = extend.zero_extend(u16, half);
            }
            platform.program_counter += 4;
        }
    },

    // Store Instructions (S-type, opcode 0100011)

    sb: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // M[x[rs1] + sext(offset)] = x[rs2][7:0]
            const imm_extended = extend.sign_extend(u12, self.imm);
            const address = platform.registers[self.rs1] +% imm_extended;
            const to_store: u8 = @intCast(platform.registers[self.rs2] & 0xFF);
            try platform.memory.store_byte(@intCast(address), to_store);
            platform.program_counter += 4;
        }
    },

    sh: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // M[x[rs1] + sext(offset)] = x[rs2][15:0]
            const imm_extended = extend.sign_extend(u12, self.imm);
            const address = platform.registers[self.rs1] +% imm_extended;
            const to_store: u16 = @intCast(platform.registers[self.rs2] & 0xFFFF);
            try platform.memory.store_half(@intCast(address), to_store);
            platform.program_counter += 4;
        }
    },

    sw: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // M[x[rs1] + sext(offset)] = x[rs2][31:0]
            const imm_extended = extend.sign_extend(u12, self.imm);
            const address = platform.registers[self.rs1] +% imm_extended;
            const to_store: u32 = @intCast(platform.registers[self.rs2] & 0xFFFFFFFF);
            try platform.memory.store_word(@intCast(address), to_store);
            platform.program_counter += 4;
        }
    },

    // Branch Instructions (B-type, opcode 1100011)

    beq: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // if (x[rs1] == x[rs2]) pc += sext(offset)
            if (platform.registers[self.rs1] == platform.registers[self.rs2]) {
                const signed_offset: i13 = @bitCast(self.imm);
                const pc_u64: u64 = @intCast(platform.program_counter);
                const off_u64: u64 = @bitCast(@as(i64, signed_offset));
                platform.program_counter = @intCast(pc_u64 +% off_u64);
            } else {
                platform.program_counter += 4;
            }
        }
    },

    bne: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // if (x[rs1] != x[rs2]) pc += sext(offset)
            if (platform.registers[self.rs1] != platform.registers[self.rs2]) {
                const signed_offset: i13 = @bitCast(self.imm);
                const new_pc = @as(i64, @intCast(platform.program_counter)) + @as(i64, @intCast(signed_offset));
                platform.program_counter = @intCast(new_pc);
            } else {
                platform.program_counter += 4;
            }
        }
    },

    blt: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // if (x[rs1] <s x[rs2]) pc += sext(offset)
            const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
            const rs2_signed: i64 = @bitCast(platform.registers[self.rs2]);
            if (rs1_signed < rs2_signed) {
                const signed_offset: i13 = @bitCast(self.imm);
                const new_pc = @as(i64, @intCast(platform.program_counter)) + @as(i64, @intCast(signed_offset));
                platform.program_counter = @intCast(new_pc);
            } else {
                platform.program_counter += 4;
            }
        }
    },

    bge: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // if (x[rs1] >=s x[rs2]) pc += sext(offset)
            const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
            const rs2_signed: i64 = @bitCast(platform.registers[self.rs2]);
            if (rs1_signed >= rs2_signed) {
                const signed_offset: i13 = @bitCast(self.imm);
                const new_pc = @as(i64, @intCast(platform.program_counter)) + @as(i64, @intCast(signed_offset));
                platform.program_counter = @intCast(new_pc);
            } else {
                platform.program_counter += 4;
            }
        }
    },

    bltu: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // if (x[rs1] <u x[rs2]) pc += sext(offset)
            if (platform.registers[self.rs1] < platform.registers[self.rs2]) {
                const signed_offset: i13 = @bitCast(self.imm);
                const new_pc = @as(i64, @intCast(platform.program_counter)) + @as(i64, @intCast(signed_offset));
                platform.program_counter = @intCast(new_pc);
            } else {
                platform.program_counter += 4;
            }
        }
    },

    bgeu: struct {
        rs1: u5,
        rs2: u5,
        imm: u13,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // if (x[rs1] >=u x[rs2]) pc += sext(offset)
            if (platform.registers[self.rs1] >= platform.registers[self.rs2]) {
                const signed_offset: i13 = @bitCast(self.imm);
                const new_pc = @as(i64, @intCast(platform.program_counter)) + @as(i64, @intCast(signed_offset));
                platform.program_counter = @intCast(new_pc);
            } else {
                platform.program_counter += 4;
            }
        }
    },

    // Jump Instructions

    jal: struct {
        rd: u5,
        imm: u21,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = pc+4; pc += sext(offset)
            if (self.rd != 0) {
                platform.registers[self.rd] = platform.program_counter + 4;
            }
            const signed_offset: i21 = @bitCast(self.imm);
            const pc_u64: u64 = @intCast(platform.program_counter);
            const off_u64: u64 = @bitCast(@as(i64, signed_offset));
            platform.program_counter = @intCast(pc_u64 +% off_u64);
        }
    },

    jalr: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // t =pc+4; pc=(x[rs1]+sext(offset))&∼1; x[rd]=t
            const t = platform.program_counter + 4;
            const imm_extended = extend.sign_extend(u12, self.imm);
            var new_pc: u64 = platform.registers[self.rs1] +% imm_extended;
            new_pc &= ~@as(u64, 1);
            if (self.rd != 0) {
                platform.registers[self.rd] = t;
            }
            platform.program_counter = @intCast(new_pc);
        }
    },

    // Upper Immediate Instructions (U-type)

    lui: struct {
        rd: u5,
        imm: u20,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(immediate[31:12] << 12)
            if (self.rd != 0) {
                // try print("lui, rd: {d}, imm: 0b{b}\n", .{ self.rd, self.imm });
                const val_u32: u32 = @as(u32, self.imm) << 12;
                // try print("val_u32: 0b{b}\n", .{val_u32});
                const extended = extend.sign_extend(u32, val_u32);
                // try print("extended: 0b{b}\n", .{extended});
                platform.registers[self.rd] = extended;
                // try print("registers[rd]: 0b{b}\n", .{platform.registers[self.rd]});
            }
            platform.program_counter += 4;
        }
    },

    auipc: struct {
        rd: u5,
        imm: u20,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = pc + sext(immediate[31:12] << 12)
            if (self.rd != 0) {
                const off_u32: u32 = @as(u32, self.imm) << 12;
                const off_extended = extend.sign_extend(u32, off_u32);
                platform.registers[self.rd] = platform.program_counter +% off_extended;
            }
            platform.program_counter += 4;
        }
    },

    // CSR Instructions (I-type)
    csrrw: struct {
        rd: u5,
        rs1: u5,
        csr: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // t = CSRs[csr]; CSRs[csr] = x[rs1]; x[rd] = t
            if (self.rd != 0) {
                const old_csr = platform.csr.get(self.csr);
                platform.csr.set(self.csr, platform.registers[self.rs1]);
                platform.registers[self.rd] = old_csr;
            } else {
                platform.csr.set(self.csr, platform.registers[self.rs1]);
            }
            platform.program_counter += 4;
        }
    },

    csrrs: struct {
        rd: u5,
        rs1: u5,
        csr: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // t = CSRs[csr]; CSRs[csr] = t | x[rs1]; x[rd] = t
            const old_csr = platform.csr.get(self.csr);
            if (self.rd != 0) {
                platform.registers[self.rd] = old_csr;
            }
            if (self.rs1 != 0) {
                platform.csr.set(self.csr, old_csr | platform.registers[self.rs1]);
            }
            platform.program_counter += 4;
        }
    },

    csrrc: struct {
        rd: u5,
        rs1: u5,
        csr: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // t = CSRs[csr]; CSRs[csr] = t &∼x[rs1]; x[rd] = t
            const old_csr = platform.csr.get(self.csr);
            if (self.rd != 0) {
                platform.registers[self.rd] = old_csr;
            }
            if (self.rs1 != 0) {
                platform.csr.set(self.csr, old_csr & ~platform.registers[self.rs1]);
            }
            platform.program_counter += 4;
        }
    },

    csrrwi: struct {
        rd: u5,
        uimm: u5,
        csr: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = CSRs[csr]; CSRs[csr] = zimm
            const zimm: u64 = @intCast(self.uimm);
            if (self.rd != 0) {
                const old_csr = platform.csr.get(self.csr);
                platform.csr.set(self.csr, zimm);
                platform.registers[self.rd] = old_csr;
            } else {
                platform.csr.set(self.csr, zimm);
            }
            platform.program_counter += 4;
        }
    },

    csrrsi: struct {
        rd: u5,
        uimm: u5,
        csr: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // t = CSRs[csr]; CSRs[csr] = t | zimm; x[rd] = t
            const zimm: u64 = @intCast(self.uimm);
            const old_csr = platform.csr.get(self.csr);
            if (self.rd != 0) {
                platform.registers[self.rd] = old_csr;
            }
            if (self.uimm != 0) {
                platform.csr.set(self.csr, old_csr | zimm);
            }
            platform.program_counter += 4;
        }
    },

    csrrci: struct {
        rd: u5,
        uimm: u5,
        csr: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // t = CSRs[csr]; CSRs[csr] = t &∼zimm; x[rd] = t
            const zimm: u64 = @intCast(self.uimm);
            const old_csr = platform.csr.get(self.csr);
            if (self.rd != 0) {
                platform.registers[self.rd] = old_csr;
            }
            if (self.uimm != 0) {
                platform.csr.set(self.csr, old_csr & ~zimm);
            }
            platform.program_counter += 4;
        }
    },

    // Environment Instructions (I-type, opcode 1110011)

    ecall: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // RaiseException(EnvironmentCall)
            _ = self;
            _ = platform;
        }
    },

    ebreak: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // RaiseException(Breakpoint)
            _ = self;
            _ = platform;
        }
    },

    fence: struct {
        pred: u4,
        succ: u4,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // Fence(pred, succ)
            _ = self;
            platform.program_counter += 4;
        }
    },

    fence_i: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // Fence(Store, Fetch)
            _ = self;
            platform.program_counter += 4;
        }
    },

    wfi: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // while (noInterruptsPending) idle
            _ = self;
            _ = platform;
            @panic("wfi instruction not implemented");
        }
    },

    mret: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // ExceptionReturn(Machine)
            _ = self;
            _ = platform;
            @panic("mret instruction not implemented");
        }
    },

    sret: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // ExceptionReturn(User)
            _ = self;
            _ = platform;
            @panic("sret instruction not implemented");
        }
    },

    uret: struct {
        pub fn execute(self: @This(), platform: *Platform) !void {
            // ExceptionReturn(User)
            _ = self;
            _ = platform;
            @panic("uret instruction not implemented");
        }
    },

    // RV64I instructions
    addiw: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext((x[rs1] + sext(immediate))[31:0])
            if (self.rd != 0) {
                const imm_signed: i64 = @as(i12, @bitCast(self.imm));
                const rs1_signed: i64 = @bitCast(platform.registers[self.rs1]);
                const result_32: i32 = @truncate(rs1_signed +% imm_signed);
                platform.registers[self.rd] = @bitCast(@as(i64, result_32));
            }
            platform.program_counter += 4;
        }
    },
    slliw: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext((x[rs1] << shamt)[31:0])
            if (self.rd != 0) {
                const val_32: u32 = @truncate(platform.registers[self.rs1]);
                const shifted: u32 = val_32 << self.shift_amt;
                const result_signed: i32 = @bitCast(shifted);
                platform.registers[self.rd] = @bitCast(@as(i64, result_signed));
            }
            platform.program_counter += 4;
        }
    },
    srliw: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(x[rs1][31:0] >>u shamt)
            if (self.rd != 0) {
                const val_32: u32 = @truncate(platform.registers[self.rs1]);
                const shifted: u32 = val_32 >> self.shift_amt;
                const result_signed: i32 = @bitCast(shifted);
                platform.registers[self.rd] = @bitCast(@as(i64, result_signed));
            }
            platform.program_counter += 4;
        }
    },
    sraiw: struct {
        rd: u5,
        rs1: u5,
        shift_amt: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(x[rs1][31:0] >>s shamt)
            if (self.rd != 0) {
                const val_32: i32 = @bitCast(@as(u32, @truncate(platform.registers[self.rs1])));
                const shifted: i32 = val_32 >> self.shift_amt;
                platform.registers[self.rd] = @bitCast(@as(i64, shifted));
            }
            platform.program_counter += 4;
        }
    },
    addw: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext((x[rs1] + x[rs2])[31:0])
            if (self.rd != 0) {
                const val1_32: u32 = @truncate(platform.registers[self.rs1]);
                const val2_32: u32 = @truncate(platform.registers[self.rs2]);
                const sum_32: u32 = val1_32 +% val2_32;
                const result_signed: i32 = @bitCast(sum_32);
                platform.registers[self.rd] = @bitCast(@as(i64, result_signed));
            }
            platform.program_counter += 4;
        }
    },
    subw: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext((x[rs1] - x[rs2])[31:0])
            if (self.rd != 0) {
                const val1_32: u32 = @truncate(platform.registers[self.rs1]);
                const val2_32: u32 = @truncate(platform.registers[self.rs2]);
                const diff_32: u32 = val1_32 -% val2_32;
                const result_signed: i32 = @bitCast(diff_32);
                platform.registers[self.rd] = @bitCast(@as(i64, result_signed));
            }
            platform.program_counter += 4;
        }
    },
    sllw: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext((x[rs1] << x[rs2][4:0])[31:0])
            if (self.rd != 0) {
                const val_32: u32 = @truncate(platform.registers[self.rs1]);
                const shift_amt: u5 = @truncate(platform.registers[self.rs2]);
                const shifted: u32 = val_32 << shift_amt;
                const result_signed: i32 = @bitCast(shifted);
                platform.registers[self.rd] = @bitCast(@as(i64, result_signed));
            }
            platform.program_counter += 4;
        }
    },
    srlw: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(x[rs1][31:0] >>u x[rs2][4:0])
            if (self.rd != 0) {
                const val_32: u32 = @truncate(platform.registers[self.rs1]);
                const shift_amt: u5 = @truncate(platform.registers[self.rs2]);
                const shifted: u32 = val_32 >> shift_amt;
                const result_signed: i32 = @bitCast(shifted);
                platform.registers[self.rd] = @bitCast(@as(i64, result_signed));
            }
            platform.program_counter += 4;
        }
    },
    sraw: struct {
        rd: u5,
        rs1: u5,
        rs2: u5,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = sext(x[rs1][31:0] >>s x[rs2][4:0])
            if (self.rd != 0) {
                const val_32: i32 = @bitCast(@as(u32, @truncate(platform.registers[self.rs1])));
                const shift_amt: u5 = @truncate(platform.registers[self.rs2]);
                const shifted: i32 = val_32 >> shift_amt;
                platform.registers[self.rd] = @bitCast(@as(i64, shifted));
            }
            platform.program_counter += 4;
        }
    },
    lwu: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = M[x[rs1] + sext(offset)][31:0]
            if (self.rd != 0) {
                const imm_extended = extend.sign_extend(u12, self.imm);
                const address = platform.registers[self.rs1] +% imm_extended;
                const word: u32 = platform.memory.load_word(@intCast(address));
                platform.registers[self.rd] = extend.zero_extend(u32, word);
            }
            platform.program_counter += 4;
        }
    },
    ld: struct {
        rd: u5,
        rs1: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // x[rd] = M[x[rs1] + sext(offset)][63:0]
            if (self.rd != 0) {
                // try print("ld, rd: {d}, rs1: {d}, imm: 0b{b}\n", .{ self.rd, self.rs1, self.imm });
                const imm_extended = extend.sign_extend(u12, self.imm);
                // try print("imm_extended: 0b{b}\n", .{imm_extended});
                // try print("RS1: 0b{b}\n", .{platform.registers[self.rs1]});
                const address = platform.registers[self.rs1] +% imm_extended;
                // try print("address: 0b{b}\n", .{address});
                const dword = platform.memory.load_dword(@intCast(address));
                // try print("dword: 0x{x}\n", .{dword});
                platform.registers[self.rd] = dword;
                // try print("registers[rd]: 0x{x}\n", .{platform.registers[self.rd]});
            }
            platform.program_counter += 4;
        }
    },
    sd: struct {
        rs1: u5,
        rs2: u5,
        imm: u12,

        pub fn execute(self: @This(), platform: *Platform) !void {
            // M[x[rs1] + sext(offset)] = x[rs2][63:0]
            // try print("PC before everything: {d}\n", .{platform.program_counter});
            // try print("RS1: {d}\n", .{platform.registers[self.rs1]});
            // try print("IMM: {d}\n", .{self.imm});
            const imm_extended = extend.sign_extend(u12, self.imm);
            // try print("IMM extended: {d}\n", .{imm_extended});
            const address = platform.registers[self.rs1] +% imm_extended;
            // try print("Address: {d}\n", .{address});
            // try print("RS2: {d}\n", .{platform.registers[self.rs2]});
            try platform.memory.store_dword(@intCast(address), platform.registers[self.rs2]);
            // try print("PC before increment: {d}\n", .{platform.program_counter});
            platform.program_counter += 4;
            // try print("PC after increment: {d}\n", .{platform.program_counter});
        }
    },
};
