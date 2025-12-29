export fn _start() void {
    const a: u64 = 5;
    const b: u64 = 3;
    const result = multiply(a, b);
    const ptr: *volatile u64 = @ptrFromInt(0x1000);
    ptr.* = result;
}

noinline fn multiply(a: u64, b: u64) u64 {
    return a * b;
}
