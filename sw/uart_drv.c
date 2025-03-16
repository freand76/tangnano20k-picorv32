#include <stdint.h>

#include "uart_drv.h"

#define UART_ADDRESS 0xff000000

static volatile uint32_t *uart_reg = (uint32_t *)UART_ADDRESS;

static inline void wait_uart_ready(void) {
    while (*uart_reg == 0x00000000) {
    }
}

static inline void send_char_to_uart(char chr) {
    *uart_reg = chr;
}

void uart_print_char(char chr) {
    wait_uart_ready();
    send_char_to_uart(chr);
}

void uart_print_str(char *str) {
    while (*str != 0) {
        uart_print_char(*str);
        str++;
    }
}

void uart_print_hex(uint32_t hexval) {
    static char nibble2char[16] = "0123456789abcdef";

    uint32_t bit_shift = 32;
    while (bit_shift != 0) {
        bit_shift -= 4;
        uint32_t nibble = (hexval >> bit_shift) & 0xf;
        char chr = nibble2char[nibble];
        uart_print_char(chr);
    }
}
