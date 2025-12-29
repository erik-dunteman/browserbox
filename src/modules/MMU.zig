const panic = @import("../utils/print.zig").panic;
const print = @import("../utils/print.zig").print;
const PhysicalMemory = @import("PhysicalMemory.zig");
pub const Self = @This();

enabled: bool = false,
root_ppn: u64 = 0,

pub fn init() Self {
    return Self{};
}

// Sv39 page size constants (bit shifts)
const PAGE_BITS = 12; // 4 KiB page
const MEGAPAGE_BITS = 21; // 2 MiB megapage
const GIGAPAGE_BITS = 30; // 1 GiB gigapage

const SATPConfig = packed struct {
    ppn: u44, // physical page number
    asid: u16,
    mode: u4,

    pub fn parse(satp: u64) SATPConfig {
        const config: SATPConfig = @bitCast(satp);
        if (config.mode != 8) {
            panic("Invalid SATP mode: {d}", .{config.mode});
        }
        return config;
    }
};

pub fn enable(self: *Self, satp: u64) void {
    const config: SATPConfig = SATPConfig.parse(satp);
    self.root_ppn = config.ppn;
    self.enabled = true;
}

const PageTableEntry = packed struct {
    valid: u1,
    read: u1,
    write: u1,
    execute: u1,
    user: u1,
    global: u1,
    accessed: u1,
    dirty: u1,
    rsw: u2,
    ppn: u44,
    reserved: u10,

    pub inline fn is_leaf(self: *const PageTableEntry) bool {
        return self.read == 1 or self.write == 1 or self.execute == 1;
    }

    pub inline fn is_valid(self: *const PageTableEntry) bool {
        return self.valid == 1;
    }
};

const VirtualAddress = packed struct {
    // 39 bit virtual address
    offset: u12,
    vpn0: u9,
    vpn1: u9,
    vpn2: u9,

    // 25 bit sign extension
    sign_ext: u25,

    pub fn parse(address: u64) VirtualAddress {
        const virt: VirtualAddress = @bitCast(address);
        // validate that sign_ext is correct using top bit of vpn2
        const top_bit = virt.vpn2 >> 8;
        const expected_sign_ext: u25 = if (top_bit == 1) ~@as(u25, 0) else 0;
        if (virt.sign_ext != expected_sign_ext) {
            panic("Invalid virtual address sign extension: expected 0x{x}, got 0x{x}", .{ expected_sign_ext, virt.sign_ext });
        }
        return virt;
    }
};

pub fn translate_address(self: *Self, memory: *PhysicalMemory, virtual_address: u64) !u64 {
    if (!self.enabled) {
        return virtual_address;
    }

    const virt = VirtualAddress.parse(virtual_address);

    // Traverse to level 2
    const pte_2_address = (self.root_ppn << PAGE_BITS) + (virt.vpn2 * 8);
    const pte_2_raw = try memory.load_dword_physical(pte_2_address);
    const pte_2: PageTableEntry = @bitCast(pte_2_raw);
    if (!pte_2.is_valid()) {
        panic("Page fault: PTE 2 is not valid", .{});
    }
    if (pte_2.is_leaf()) {
        // Gigapage (1 GiB): physical address from entry ppn[43:18] and virtual address[29:0]
        const ppn_high: u64 = @as(u64, pte_2.ppn >> 18);
        const physical_address: u64 = (ppn_high << GIGAPAGE_BITS) | (@as(u64, virt.vpn1) << MEGAPAGE_BITS) | (@as(u64, virt.vpn0) << PAGE_BITS) | virt.offset;
        return physical_address;
    }

    // Else traverse to level 1
    const pte_1_address = (@as(u64, pte_2.ppn) << PAGE_BITS) + (virt.vpn1 * 8);
    const pte_1_raw = try memory.load_dword_physical(pte_1_address);
    const pte_1: PageTableEntry = @bitCast(pte_1_raw);
    if (!pte_1.is_valid()) {
        panic("Page fault: PTE 1 is not valid", .{});
    }
    if (pte_1.is_leaf()) {
        // Megapage (2 MiB): physical address from entry ppn[43:9] and virtual address[20:0]
        const ppn_high: u64 = @as(u64, pte_1.ppn >> 9);
        const physical_address: u64 = (ppn_high << MEGAPAGE_BITS) | (@as(u64, virt.vpn0) << PAGE_BITS) | virt.offset;
        return physical_address;
    }

    // Else traverse to level 0
    const pte_0_address = (@as(u64, pte_1.ppn) << PAGE_BITS) + (virt.vpn0 * 8);
    const pte_0_raw = try memory.load_dword_physical(pte_0_address);
    const pte_0: PageTableEntry = @bitCast(pte_0_raw);
    if (!pte_0.is_valid()) {
        panic("Page fault: PTE 0 is not valid", .{});
    }
    if (pte_0.is_leaf()) {
        // Page (4 KiB): physical address from full entry ppn and virtual address[11:0]
        const physical_address: u64 = (@as(u64, pte_0.ppn) << PAGE_BITS) | virt.offset;
        return physical_address;
    }

    // Else return error
    return error.PageFault;
}
