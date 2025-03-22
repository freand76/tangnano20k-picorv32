    .text
    .global _start
	.global main

_start:

    addi x1, zero, 0
    addi x2, zero, 0
    addi x3, zero, 0
    addi x4, zero, 0
    addi x5, zero, 0
    addi x6, zero, 0
    addi x7, zero, 0
    addi x8, zero, 0
    addi x9, zero, 0
    addi x10, zero, 0
    addi x11, zero, 0
    addi x12, zero, 0
    addi x13, zero, 0
    addi x14, zero, 0
    addi x15, zero, 0
    addi x16, zero, 0
    addi x17, zero, 0
    addi x18, zero, 0
    addi x19, zero, 0
    addi x20, zero, 0
    addi x21, zero, 0
    addi x22, zero, 0
    addi x23, zero, 0
    addi x24, zero, 0
    addi x25, zero, 0
    addi x26, zero, 0
    addi x27, zero, 0
    addi x28, zero, 0
    addi x29, zero, 0
    addi x30, zero, 0
    addi x31, zero, 0

    lui sp, %hi(0x01002000)
    add sp, sp, %lo(0x01002000)

    jal ra, main

    addi x2, zero, 0x00
    addi x9, zero, 9
    lui x1, %hi(0xfe000000)
_led_loop:
    /* Print a number to LED */
    sw  x2, 0(x1)

    addi x2, x2, 0x01
    addi x9, x9, -1
    bnez x9, _led_loop

    addi x2, zero, 0x00
    addi x9, zero, 10
    lui x3, %hi(0xff000000)
_uart_loop:
    /* Print a number to UART */
    addi x4, x2, 0x30
    sw  x4, 0(x3)
_uart_wait_done_loop:
    lw  x5, 0(x3)
    beqz x5, _uart_wait_done_loop

    addi x2, x2, 0x01
    addi x9, x9, -1
    bnez x9, _uart_loop

    /* Wait a while */
    lui x5, %hi(0xfffff000)
subloop:
    addi x5, x5, 1
    bnez x5, subloop
    j _led_loop

    nop
    nop
    nop
