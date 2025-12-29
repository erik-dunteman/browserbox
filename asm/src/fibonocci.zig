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

// produces
//
// ============================================================================
// _start() function
// ============================================================================
//
// --- function prologue: set up stack frame ---
//    0:   ff010113                addi    sp,sp,-16       // sp = sp - 16 (allocate 16 bytes on stack)
//    4:   00113423                sd      ra,8(sp)        // store return address at sp+8 (save ra before call)
//
// --- load x from static memory into a0 (first argument register) ---
//    8:   01002537                lui     a0,0x1002       // a0 = 0x1002 << 12 = 0x1002000 (load upper 20 bits)
//    c:   1e853503                ld      a0,488(a0)      // a0 = mem[a0 + 488] = mem[0x10021e8] (load x=10)
//
// --- call fib(n) using PC-relative addressing ---
//   10:   00000097                auipc   ra,0x0          // ra = PC + 0 = 0x10 (load current PC into ra)
//   14:   01c080e7                jalr    ra,28(ra)       // jump to ra+28=0x2c, save return addr in ra
//
// --- store result to memory at 0x1000 ---
//   18:   000015b7                lui     a1,0x1          // a1 = 0x1 << 12 = 0x1000 (build address)
//   1c:   00a5b023                sd      a0,0(a1)        // mem[a1 + 0] = a0 (store fib result at 0x1000)
//
// --- function epilogue: restore stack and return ---
//   20:   00813083                ld      ra,8(sp)        // ra = mem[sp + 8] (restore return address)
//   24:   01010113                addi    sp,sp,16        // sp = sp + 16 (deallocate stack frame)
//   28:   00008067                jalr    zero,0(ra)      // jump to ra (return from _start)
//
// ============================================================================
// fib(n) function - iterative fibonacci
// a0 = n (input), a1 = a, a2 = b, a3 = temp
// ============================================================================
//
// --- initialize loop variables ---
//   2c:   00000593                addi    a1,zero,0       // a1 = 0 (a = 0)
//   30:   00100613                addi    a2,zero,1       // a2 = 1 (b = 1)
//
// --- check if n == 0, skip loop if true ---
//   34:   00050c63                beq     a0,zero,0x4c    // if a0 == 0, jump to 0x4c (return a)
//
// --- loop body: compute next fibonacci number ---
//   38:   00060693                addi    a3,a2,0         // a3 = a2 (temp = b, save b before overwrite)
//   3c:   00c58633                add     a2,a1,a2        // a2 = a1 + a2 (b = a + b, this is "next")
//   40:   fff50513                addi    a0,a0,-1        // a0 = a0 - 1 (n--, decrement counter)
//   44:   00068593                addi    a1,a3,0         // a1 = a3 (a = temp, which was old b)
//   48:   fe0518e3                bne     a0,zero,0x38    // if a0 != 0, jump back to 0x38 (loop)
//
// --- return result in a0 ---
//   4c:   00058513                addi    a0,a1,0         // a0 = a1 (return a)
//   50:   00008067                jalr    zero,0(ra)      // jump to ra (return from fib)
