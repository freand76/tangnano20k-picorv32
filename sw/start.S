    .text
    .global _start

_start:
    addi x2, zero, 0x00
_loop:
    /* Print a number to LED */
    lui x1, %hi(0xfe000000)
    addi x2, x2, 0x01
    sw  x2, 0(x1)

    /* Print a number to UART */
    lui x3, %hi(0xff000000)
    andi x4, x2, 0x7
    addi x4, x4, 0x30
    sw  x4, 0(x3)

    /* Wait a while */
    lui x5, %hi(0xfffff000)
subloop:
    addi x5, x5, 1
    bnez x5, subloop
    j _loop

    nop
    nop
    nop
