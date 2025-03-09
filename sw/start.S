    .text
    .global _start

_start:
    /* zero-initialize all registers */

    addi x1, zero, 0
    addi x3, zero, 0
    addi x4, zero, 0
    addi x5, zero, 0

    lui x1, 0xff000
    addi x2, zero, 0xaa
    sw  x2, 0(x1)
    lui x1, 0xfe000
    addi x2, zero, 0x00
_loop:
    addi x2, x2, 0x01
    sw  x2, 0(x1)
    j _loop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
