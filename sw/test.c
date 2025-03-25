#include <stdbool.h>
#include <stdint.h>

#include "led_drv.h"
#include "uart_drv.h"
#include "font_8x8.h"

int main(void) {
    uart_print_str("\n\nHello World\n");

    led_set(0x01);

    uint32_t *ram32 = (uint32_t *)0x01000000;
    uint16_t *ram16 = (uint16_t *)0x01000000;
    uint8_t *ram = (uint8_t *)0x01000000;

    *ram32 = 0x00000000;

    *ram++ = 0xda;
    *ram++ = 0xbe;
    *ram++ = 0xde;
    ;
    *ram++ = 0xfe;

    led_set(0x02);
    uart_print_hex(*ram32);
    uart_print_char('\n');
    led_set(0x12);
    ram32[2048] = 0x12345678;
    uart_print_char('\n');
    uart_print_hex(ram32[2048]);
    uart_print_char('\n');
    uart_print_hex(ram32[0]);
    uart_print_char('\n');
    led_set(0x13);
    ram = (uint8_t *)0x01000000;

    ram[3] = 0x11;
    ram[2] = 0x22;
    ram[1] = 0x33;
    ram[0] = 0x44;

    led_set(0x03);
    uart_print_hex(ram16[1]);
    uart_print_char('\n');

    led_set(0x04);
    uart_print_hex(*ram16);
    uart_print_char('\n');

    volatile uint8_t *font_ram = (uint8_t *)0x01000400;
    const uint8_t *font_ptr = &font_8x8[0][0];
    for (uint16_t idx = 0; idx < sizeof(font_8x8); idx++) {
        font_ram[idx] = font_ptr[idx];
    }

    volatile char *character_ram = (char *)0x01000800;

    volatile uint32_t *video_regs = (uint32_t *)0xf0000000;

    video_regs[0] = 0x01000800;
    video_regs[1] = 0x01000400;

    for (uint16_t idx = 0; idx < 1200; idx++) {
        character_ram[idx] = idx % 256;
    }

    uint8_t led_cnt = 0;

    while (true) {
        led_set(led_cnt++);
    }

    return 0;
}
