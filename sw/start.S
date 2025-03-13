    .text
    .global _start

_start:

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
