const std = @import("std");
const panic = @import("../utils/print.zig").panic;
const print = @import("../utils/print.zig").print;
const Platform = @import("../Platform.zig");
pub const Self = @This();

const CSRCode = enum(u12) {
    Sstatus = 0x100,
    Sie = 0x104,
    Stvec = 0x105,
    Sscratch = 0x140,
    Sepc = 0x141,
    Scause = 0x142,
    Stval = 0x143,
    Sip = 0x144,
    Satp = 0x180,
};

// Supervisor trap setup
sstatus: u64,
sie: u64, // interrupt enable register
stvec: u64, // pc to jump to on trap. "trap vector"

// Supervisor trap handling
sscratch: u64, //
sepc: u64, // pc to return to after handling trap
scause: u64, // encoded reason, used to communicate between privilaged modes what to do
stval: u64, // extra info on cause
sip: u64, // interrupt pending

// Virtual memory flag
satp: u64, // page table pointer, physical memory address

pub fn init() Self {
    return Self{
        .sstatus = 0,
        .sie = 0,
        .stvec = 0,
        .sscratch = 0,
        .sepc = 0,
        .scause = 0,
        .stval = 0,
        .sip = 0,
        .satp = 0,
    };
}

pub fn display(self: *Self, io: std.Io) !void {
    try print(io, "CSR:\n\tsepc=0x{x}\n\tscause=0x{x}\n\tstval=0x{x}\n\tstvec=0x{x}\n\tsatp=0x{x}\n\tsie=0x{x}\n\tsip=0x{x}\n", .{ self.sepc, self.scause, self.stval, self.stvec, self.satp, self.sie, self.sip });
}

pub fn set(self: *Self, platform: *Platform, csr: u12, val: u64) void {
    const target: CSRCode = @enumFromInt(csr);
    switch (target) {
        .Sstatus => {
            self.sstatus = val;
        },
        .Sie => {
            self.sie = val;
        },
        .Stvec => {
            self.stvec = val;
        },
        .Sscratch => {
            self.sscratch = val;
        },
        .Sepc => {
            self.sepc = val;
        },
        .Scause => {
            self.scause = val;
        },
        .Stval => {
            self.stval = val;
        },
        .Sip => {
            self.sip = val;
        },
        .Satp => {
            platform.memory.mmu.enable(val);
            self.satp = val;
        },
    }
}

pub fn get(self: *Self, csr: u12) u64 {
    const target: CSRCode = @enumFromInt(csr);
    switch (target) {
        .Sstatus => {
            return self.sstatus;
        },
        .Sie => {
            return self.sie;
        },
        .Stvec => {
            return self.stvec;
        },
        .Sscratch => {
            return self.sscratch;
        },
        .Sepc => {
            return self.sepc;
        },
        .Scause => {
            return self.scause;
        },
        .Stval => {
            return self.stval;
        },
        .Sip => {
            return self.sip;
        },
        .Satp => {
            return self.satp;
        },
    }
}
