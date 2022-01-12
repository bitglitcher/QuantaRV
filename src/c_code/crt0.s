/*
MIT License

Copyright (c) 2022 Benjamin Herrera Navarro

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

.section .init, "ax"
.global _start
.global _trap_handler

.equ REGBYTES, 4

.equ timecmp, 0x10000088
.equ timecmp_h, 0x1000008c
.equ time, 0x10000080
.equ time_h, 0x10000084

.macro push_context
    #reserve enough space to push registers into the stack
    addi sp, sp, -32*REGBYTES

    #Push all registers
    sw x1, 1*REGBYTES(sp)
    sw x2, 2*REGBYTES(sp)
    sw x3, 3*REGBYTES(sp)
    sw x4, 4*REGBYTES(sp)
    sw x5, 5*REGBYTES(sp)
    sw x6, 6*REGBYTES(sp)
    sw x7, 7*REGBYTES(sp)
    sw x8, 8*REGBYTES(sp)
    sw x9, 9*REGBYTES(sp)
    sw x10, 10*REGBYTES(sp)
    sw x11, 11*REGBYTES(sp)
    sw x12, 12*REGBYTES(sp)
    sw x13, 13*REGBYTES(sp)
    sw x14, 14*REGBYTES(sp)
    sw x15, 15*REGBYTES(sp)
    sw x16, 16*REGBYTES(sp)
    sw x17, 17*REGBYTES(sp)
    sw x18, 18*REGBYTES(sp)
    sw x19, 19*REGBYTES(sp)
    sw x20, 20*REGBYTES(sp)
    sw x21, 21*REGBYTES(sp)
    sw x22, 22*REGBYTES(sp)
    sw x23, 23*REGBYTES(sp)
    sw x24, 24*REGBYTES(sp)
    sw x25, 25*REGBYTES(sp)
    sw x26, 26*REGBYTES(sp)
    sw x27, 27*REGBYTES(sp)
    sw x28, 28*REGBYTES(sp)
    sw x29, 29*REGBYTES(sp)
    sw x30, 30*REGBYTES(sp)
    sw x31, 31*REGBYTES(sp)
.endm

.macro pop_context
    #Pop all registers
    lw x1, 1*REGBYTES(sp)
    lw x2, 2*REGBYTES(sp)
    lw x3, 3*REGBYTES(sp)
    lw x4, 4*REGBYTES(sp)
    lw x5, 5*REGBYTES(sp)
    lw x6, 6*REGBYTES(sp)
    lw x7, 7*REGBYTES(sp)
    lw x8, 8*REGBYTES(sp)
    lw x9, 9*REGBYTES(sp)
    lw x10, 10*REGBYTES(sp)
    lw x11, 11*REGBYTES(sp)
    lw x12, 12*REGBYTES(sp)
    lw x13, 13*REGBYTES(sp)
    lw x14, 14*REGBYTES(sp)
    lw x15, 15*REGBYTES(sp)
    lw x16, 16*REGBYTES(sp)
    lw x17, 17*REGBYTES(sp)
    lw x18, 18*REGBYTES(sp)
    lw x19, 19*REGBYTES(sp)
    lw x20, 20*REGBYTES(sp)
    lw x21, 21*REGBYTES(sp)
    lw x22, 22*REGBYTES(sp)
    lw x23, 23*REGBYTES(sp)
    lw x24, 24*REGBYTES(sp)
    lw x25, 25*REGBYTES(sp)
    lw x26, 26*REGBYTES(sp)
    lw x27, 27*REGBYTES(sp)
    lw x28, 28*REGBYTES(sp)
    lw x29, 29*REGBYTES(sp)
    lw x30, 30*REGBYTES(sp)
    lw x31, 31*REGBYTES(sp)
    
    #return stack pointer to where it was
    addi sp, sp, 32*REGBYTES
.endm

_start:
    .cfi_startproc
    .cfi_undefined ra
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    la sp, __stack_top
    add s0, sp, zero

    la t3, _vector_table
    addi t3, t3, 0b01 #Set vectored mode
    csrw mtvec, t3
    
    #enable global machine interrupts
    #li t0, 0b1000
    #csrs mstatus, t0 

    #load current time
    #la t0, time
    #lw t1, 0(t0)
    #lw t2, 4(t0)
    #offset loaded time by 0x1fff
    #li t3, 0x1fff #load offset
    #add t4, t1, t3 #Offset value
    
    #detect overflow
    #bltu t4, t2, .overflow
    #Otherwise just set_timecmp
    #j .set_timecmp 
    
    #.overflow:
    #add overflow to higher bits
    #add t2, t2, t4

#    .set_timecmp:
    #set timecmp
#    la t0, timecmp
#    sw t1, 0(t0)
#    sw t2, 4(t0)

    #enable machine timer interrupt
#    li t0, 0b10000000
#    csrs mie, t0

    jal ra, main

    ebreak
    .cfi_endproc




.align 2
_vector_table:
    # Trap handler
    j _trap_handler
    #_u_mode_soft_handler
    #mret
    #_s_mode_soft_handler
    mret
    #_m_mode_soft_handler
    mret
    #_u_mode_timer_handler
    mret
    #_s_mode_timer_handler
    mret
    mret
    mret
    #_m_mode_timer_handler
    j _m_mode_timer_handler
    #_u_mode_external_handler
    mret
    #_s_mode_external_handler
    mret
    #_m_mode_external_handler
    mret
#timer hadler

_m_mode_timer_handler:
    push_context
    #---- call C Code Handler ----
    call timer_interrupt_handler
    #---- end of C Code Handler ----
    pop_context
    #return from trap handler
    mret

#Trap handler
.align 2
_trap_handler:
    push_context
    #---- call C Code Handler ----
    #Read CSR for function arguments
    csrr a0, mepc
    csrr a1, mcause
    csrr a2, mtval
    call trap_handler
    #---- end of C Code Handler ----
    pop_context    
    #return from trap handler
    #Increment PC + 4
    addi sp, sp, -1*REGBYTES
    sw t0, 1*REGBYTES(sp)
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    lw t0, 1*REGBYTES(sp)
    addi sp, sp, 1*REGBYTES
    mret
