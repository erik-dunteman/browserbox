export var outer_limit: u64 = 10;
export var inner_limit: u64 = 100;

export fn _start() void {
    const n: *volatile u64 = &outer_limit;
    const m: *volatile u64 = &inner_limit;
    outer_loop(n.*, m.*);
}

noinline fn outer_loop(n: u64, m: u64) void {
    for (0..n) |i| {
        inner_loop(i, m);
    }
}

noinline fn inner_loop(i: u64, m: u64) void {
    for (0..m) |j| {
        if (i < j) {
            const ptr: *volatile u64 = @ptrFromInt(0x1000 + i + j);
            ptr.* = i + j;
            break;
        }
    }
}
