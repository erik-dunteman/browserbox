addi x1, x0, 3    # x1 = 3 # while cond
addi x2, x0, 0    # x2 = 0 # i = 0

# loop body while i < 3
loop:
addi x2, x2, 1    # x2++ increment val by one
blt  x2, x1, loop # if x2 < x1, branch to loop

# end of loop
addi x3, x0, 100  # x3 = 100 # celebrate!
