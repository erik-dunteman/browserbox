const panic = @import("../utils/print.zig").panic;
const print = @import("../utils/print.zig").print;
const Platform = @import("../Platform.zig");
pub const Self = @This();

const CSRCode = enum(u12) {
    Sepc = 0x141,
    Scause = 0x142,
    Stval = 0x143,
    Stvec = 0x105,
    Satp = 0x180,
    Sie = 0x104,
    Sip = 0x144,
};

sepc: u64,
scause: u64,
stval: u64,
stvec: u64,
satp: u64, // page table pointer, physical memory address
sie: u64,
sip: u64,

pub fn init() Self {
    return Self{
        .sepc = 0,
        .scause = 0,
        .stval = 0,
        .stvec = 0,
        .satp = 0,
        .sie = 0,
        .sip = 0,
    };
}

pub fn display(self: *Self) !void {
    try print("CSR:\n\tsepc=0x{x}\n\tscause=0x{x}\n\tstval=0x{x}\n\tstvec=0x{x}\n\tsatp=0x{x}\n\tsie=0x{x}\n\tsip=0x{x}\n", .{ self.sepc, self.scause, self.stval, self.stvec, self.satp, self.sie, self.sip });
}

pub fn set(self: *Self, platform: *Platform, csr: u12, val: u64) void {
    const target: CSRCode = @enumFromInt(csr);
    switch (target) {
        .Sepc => {
            self.sepc = val;
        },
        .Scause => {
            self.scause = val;
        },
        .Stval => {
            self.stval = val;
        },
        .Stvec => {
            self.stvec = val;
        },
        .Satp => {
            platform.memory.mmu.enable(val);
            self.satp = val;
        },
        .Sie => {
            self.sie = val;
        },
        .Sip => {
            self.sip = val;
        },
    }
}

pub fn get(self: *Self, csr: u12) u64 {
    const target: CSRCode = @enumFromInt(csr);
    switch (target) {
        .Sepc => {
            return self.sepc;
        },
        .Scause => {
            return self.scause;
        },
        .Stval => {
            return self.stval;
        },
        .Stvec => {
            return self.stvec;
        },
        .Satp => {
            return self.satp;
        },
        .Sie => {
            return self.sie;
        },
        .Sip => {
            return self.sip;
        },
    }
}
