addi x1, x0, 5    # x1 = 5
addi x2, x0, 3    # x2 = 3
add  x3, x1, x2   # x3 = 8
sb   x3, 0(x0)    # store x3 in memory at address 0
sb   x2, 1(x0)    # store x2 in memory at address 1
sb   x1, 8(x0)    # store x1 in memory at address 8