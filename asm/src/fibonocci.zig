// This is the main entry point for the risc-v executable.
// Intended to be used for testing

export var x: u64 = 10;

export fn _start() void {
    // Use volatile static args to prevent them getting folded in during optimization
    const n: *volatile u64 = &x;
    const result = fib(n.*);

    // Write result to memory to prevent it getting optimized away
    const ptr: *volatile u64 = @ptrFromInt(0x1000);
    ptr.* = result;
}

noinline fn fib(n: u64) u64 {
    var a: u64 = 0;
    var b: u64 = 1;

    for (0..n) |_| {
        const next = a + b;
        a = b;
        b = next;
    }

    return a;
}
