# Build a minimal page table at address 0x1000
# Identity map: virtual 0x0 -> physical 0x0

# Page table entry: PPN=0, flags=0xEF (V,R,W,X,U,A,D)
li   t0, 0xEF
li   t1, 0x1000
sd   t0, 0(t1)           # store PTE at page table root

# Set satp: mode=Sv39 (8), ASID=0, PPN=1 (0x1000 >> 12)
li   t0, 0x8000000000000001
csrw satp, t0

# See compilation output with:
# riscv64-unknown-elf-objdump -M no-aliases -d binary asm/o/enable_paging.o

# Which produces:
#    0:   0ef00293                addi    t0,zero,239
#    4:   00001337                lui     t1,0x1
#    8:   00533023                sd      t0,0(t1) # 1000 <.text+0x1000>
#    c:   fff0029b                addiw   t0,zero,-1
#   10:   03f29293                slli    t0,t0,0x3f
#   14:   00128293                addi    t0,t0,1
#   18:   18029073                csrrw   zero,satp,t0

