pub const Self = @This();

sepc: u64,
scause: u64,
stval: u64,
stvec: u64,
satp: u64, // page table pointer, physical memory address
sie: u64,
sip: u64,

pub fn new() Self {
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
