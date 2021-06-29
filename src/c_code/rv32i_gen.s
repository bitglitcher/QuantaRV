_start:

add_0:
    li x16, 0x55febe80
    li x19, 0xf2e33d2c
    add x24, x16, x19
    li x16, 0x48e1fbac
    bne x16, x24, add_fail_0
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, add_pass_0
add_fail_0:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '0'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
add_halt_0:
    bne x1, zero, add_halt_0
add_pass_0:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '0'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_1
entry_1:
sub_1:
    li x25, 0x5d739385
    li x26, 0x9e608825
    sub x30, x25, x26
    li x25, -0x40ecf4a0
    bne x25, x30, sub_fail_1
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, sub_pass_1
sub_fail_1:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'U'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'B'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '1'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
sub_halt_1:
    bne x1, zero, sub_halt_1
sub_pass_1:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'U'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'B'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '1'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_2
entry_2:
sll_2:
    li x1, 0x76a6a313
    li x3, 0x1711f635
    sll x18, x1, x3
    li x1, 0x62600000
    bne x1, x18, sll_fail_2
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, sll_pass_2
sll_fail_2:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '2'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
sll_halt_2:
    bne x1, zero, sll_halt_2
sll_pass_2:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '2'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_3
entry_3:
slt_3:
    li x8, 0xd98377fc
    li x28, 0xde529e48
    slt x2, x8, x28
    li x8, 0x1
    bne x8, x2, slt_fail_3
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, slt_pass_3
slt_fail_3:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'T'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '3'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
slt_halt_3:
    bne x1, zero, slt_halt_3
slt_pass_3:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'T'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '3'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_4
entry_4:
sltu_4:
    li x23, 0xb2b8558c
    li x28, 0xdb02da75
    sltu x28, x23, x28
    li x23, 0x1
    bne x23, x28, sltu_fail_4
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, sltu_pass_4
sltu_fail_4:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'T'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'U'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '4'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
sltu_halt_4:
    bne x1, zero, sltu_halt_4
sltu_pass_4:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'T'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'U'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '4'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_5
entry_5:
xor_5:
    li x10, 0x930e8542
    li x19, 0x77849f48
    xor x24, x10, x19
    li x10, -0x1b75e5f6
    bne x10, x24, xor_fail_5
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, xor_pass_5
xor_fail_5:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'X'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'O'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '5'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
xor_halt_5:
    bne x1, zero, xor_halt_5
xor_pass_5:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'X'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'O'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '5'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_6
entry_6:
srl_6:
    li x15, 0xd749b013
    li x12, 0xa774aa81
    srl x30, x15, x12
    li x15, 0x6ba4d809
    bne x15, x30, srl_fail_6
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, srl_pass_6
srl_fail_6:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '6'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
srl_halt_6:
    bne x1, zero, srl_halt_6
srl_pass_6:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '6'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_7
entry_7:
sra_7:
    li x21, 0x9bc51348
    li x27, 0x70037c57
    sra x30, x21, x27
    li x21, 0xffffff37
    bne x21, x30, sra_fail_7
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, sra_pass_7
sra_fail_7:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '7'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
sra_halt_7:
    bne x1, zero, sra_halt_7
sra_pass_7:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '7'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_8
entry_8:
or_8:
    li x2, 0x246be4fc
    li x26, 0x87e28762
    or x22, x2, x26
    li x2, -0x58141802
    bne x2, x22, or_fail_8
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, or_pass_8
or_fail_8:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'O'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '8'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
or_halt_8:
    bne x1, zero, or_halt_8
or_pass_8:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'O'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'R'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '8'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_9
entry_9:
and_9:
    li x28, 0x4a0315bb
    li x15, 0x2a2523c8
    and x26, x28, x15
    li x28, 0xa010188
    bne x28, x26, and_fail_9
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, and_pass_9
and_fail_9:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'N'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '9'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'F'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'I'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'L'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    ebreak
    mv x1, zero
    addi x1, x1, 1
and_halt_9:
    bne x1, zero, and_halt_9
and_pass_9:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'N'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '9'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'P'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'A'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
    bne x1, zero, entry_10
entry_10:
    li x1, 0xffff
    mv x2, zero
    addi x2, x2, 'T'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'E'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'T'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'S'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, ' '
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'D'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'O'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'N'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, 'E'
    sb x2, 0(x1)
    mv x2, zero
    addi x2, x2, '\n'
    sb x2, 0(x1)
    mv x1, zero
    addi x1, x1, 1
done_halt:
    bne x1, zero, done_halt
