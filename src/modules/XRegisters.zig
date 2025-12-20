pub const Self = @This();

registers: [32]u64 = undefined,

pub fn new() Self {
    return Self{
        .registers = undefined,
    };
}
