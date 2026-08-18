# browserbox

Browserbox is a risc-v emulator built with Zig to run in WASM.

```bash
# prerequisites
mise use -g zig@0.16.0        # or any install of zig 0.16.0
brew install wasmer

# build: native emulator, wasm32-wasi emulator, and the RISC-V ELF test programs
mkdir -p asm/elf
zig build # -> zig-out/bin/browserbox, zig-out/bin/browserbox.wasm, asm/elf/*.elf

# test: unit tests + run every ELF in asm/elf through the emulator
zig build test

# run fibonocci natively
zig build run -- --elf asm/elf/fibonocci.elf
./zig-out/bin/browserbox --elf asm/elf/fibonocci.elf

# run fibonocci in the wasm emulator under wasmer
wasmer run zig-out/bin/browserbox.wasm --volume .:/app --cwd /app -- --elf /app/asm/elf/fibonocci.elf
```

## Instruction set support

Freestanding builds targeting `riscv64` with `c`, `m`, `a`, `f`, `d` subtracted (see `build.zig`) should work.

| Set | Status | Notes |
| --- | --- | --- |
| RV32I base | ✅ all 40 | `ecall` / `ebreak` decode but execute as no-ops that don't advance PC |
| RV64I `*W` + `ld` / `sd` / `lwu` | ✅ all 12 | |
| Zifencei (`fence`, `fence.i`) | ✅ | no-ops, single-hart |
| Zicsr (`csrr[wsc]`, `csrr[wsc]i`) | ✅ | S-mode CSRs only: `sstatus` `sie` `stvec` `sscratch` `sepc` `scause` `stval` `sip` `satp` |
| Sv39 paging | ✅ | |
| Privileged (`mret`, `sret`, `uret`, `wfi`) | ⚠️ | decoded, panic on execute |
| M (mul / div) | ❌ | parser panics on unknown funct7 |
| A (atomics) | ❌ | |
| F / D (float) | ❌ | |
| C (compressed) | ❌ | |
