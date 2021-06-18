.section .init, "ax"
.global _start
_start:
#    addi x2,  x2, 0xab
#    addi x1,  x1, 0xab
#    addi x3,  x3, 0xab
#    addi x4,  x4, 0xab
#    addi x5,  x5, 0xab
#    addi x6,  x6, 0xab
#    addi x7,  x7, 0xab
#    addi x8,  x8, 0xab
#    addi x9,  x9, 0xab
#    addi x10, x10, 0xab
#    addi x11, x11, 0xab
#    addi x12, x12, 0xab
#    addi x13, x13, 0xab
#    addi x14, x14, 0xab
#    addi x15, x15, 0xab
#    addi x16, x16, 0xab
#    addi x17, x17, 0xab
#    addi x18, x18, 0xab
#    addi x19, x19, 0xab
#    addi x20, x20, 0xab
#    addi x21, x21, 0xab
#    addi x22, x22, 0xab
#    addi x23, x23, 0xab
#    addi x24, x24, 0xab
#    addi x25, x25, 0xab
#    addi x26, x26, 0xab
#    addi x27, x27, 0xab
#    addi x28, x28, 0xab
#    addi x29, x29, 0xab
#    addi x30, x30, 0xab
#    addi x31, x31, 0xab
#    add  x1, x1,  x1
#    add  x2, x2,  x2
#    add  x3, x3,  x3
#    add  x4, x4,  x4
#    add  x5, x5,  x5
#    add  x6, x6,  x6
#    add  x7, x7,  x7
#    add  x9, x9,  x9
#    add  x8, x8,  x8
#    add  x11, x11, x11
#    add  x10, x10, x10
#    add  x13, x13, x13
#    add  x12, x12, x12
#    add  x15, x15, x15
#    add  x14, x14, x14
#    add  x17, x17, x17
#    add  x16, x16, x16
#    add  x19, x19, x19
#    add  x18, x18, x18
#    add  x21, x21, x21
#    add  x20, x20, x20
#    add  x23, x23, x23
#    add  x22, x22, x22
#    add  x25, x25, x25
#    add  x24, x24, x24
#    add  x27, x27, x27
#    add  x26, x26, x26
#    add  x29, x29, x29
#    add  x28, x28, x28
#    add  x31, x31, x31
#    add  x30, x30, x30
#    lui  x2,  0xcae
#    lui  x1,  0xcae
#    lui  x4,  0xcae
#    lui  x3,  0xcae
#    lui  x6,  0xcae
#    lui  x5,  0xcae
#    lui  x8,  0xcae
#    lui  x7,  0xcae
#    lui  x10, 0xcae
#    lui  x9,  0xcae
#    lui  x12, 0xcae
#    lui  x11, 0xcae
#    lui  x14, 0xcae
#    lui  x13, 0xcae
#    lui  x16, 0xcae
#    lui  x15, 0xcae
#    lui  x18, 0xcae
#    lui  x17, 0xcae
#    lui  x20, 0xcae
#    lui  x19, 0xcae
#    lui  x22, 0xcae
#    lui  x21, 0xcae
#    lui  x24, 0xcae
#    lui  x23, 0xcae
#    lui  x26, 0xcae
#    lui  x25, 0xcae
#    lui  x28, 0xcae
#    lui  x27, 0xcae
#    lui  x30, 0xcae
#    lui  x29, 0xcae
#    auipc  x1,  0xcae
#    lui  x31, 0xcae
#    auipc  x3,  0xcae
#    auipc  x2,  0xcae
#    auipc  x5,  0xcae
#    auipc  x4,  0xcae
#    auipc  x7,  0xcae
#    auipc  x6,  0xcae
#    auipc  x9,  0xcae
#    auipc  x8,  0xcae
#    auipc  x11, 0xcae
#    auipc  x10, 0xcae
#    auipc  x13, 0xcae
#    auipc  x12, 0xcae
#    auipc  x15, 0xcae
#    auipc  x14, 0xcae
#    auipc  x17, 0xcae
#    auipc  x16, 0xcae
#    auipc  x19, 0xcae
#    auipc  x18, 0xcae
#    auipc  x21, 0xcae
#    auipc  x20, 0xcae
#    auipc  x23, 0xcae
#    auipc  x22, 0xcae
#    auipc  x25, 0xcae
#    auipc  x24, 0xcae
#    auipc  x27, 0xcae
#    auipc  x26, 0xcae
#    auipc  x29, 0xcae
#    auipc  x28, 0xcae
#
#    auipc  x30, 0xcae
#    auipc  x31, 0xcae
#
#    init_fibonnaci:
#
#    mv x1, zero;
#
#    mv x2, zero; 
#    addi x2, x2, 1;
#
#    fibonnaci_loop:
#
#    add x3, x2, x1
#
#    mv x2, x1
#
#    mv x1, x3
#
#    lui x10, %hi(fibonnaci_loop)
#    addi x10, x10, %lo(fibonnaci_loop)    jalr zero, 0(x10)

    .cfi_startproc
    .cfi_undefined ra
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    la sp, __stack_top
    add s0, sp, zero
    jal ra, main
    ebreak
    .cfi_endproc
    .end