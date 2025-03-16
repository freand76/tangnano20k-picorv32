#include <stdbool.h>
#include <stdint.h>

#include "led_drv.h"
#include "uart_drv.h"

int main(void) {
    uart_print_str("\n\nHello World\n");

    led_set(0x01);

    uint32_t *ram32 = (uint32_t *)0x01000000;
    uint16_t *ram16 = (uint16_t *)0x01000000;
    uint8_t *ram = (uint8_t *)0x01000000;

    volatile uint32_t *video = (uint32_t *)0xf0000000;

    *ram32 = 0x00000000;

    *ram++ = 0xfe;
    *ram++ = 0xde;
    *ram++ = 0xbe;
    *ram++ = 0xda;

    led_set(0x02);
    uart_print_hex(*ram32);
    uart_print_char('\n');

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

    uint8_t led_cnt = 0;

    while (true) {
        while (video[1] > 480);
        video[0] = 0xff0000;
        while (video[1] < 40);
        video[0] = 0x000000;
        while (video[1] < 80);
        video[0] = 0x00ff00;
        while (video[1] < 120);
        video[0] = 0x0000ff;
        while (video[1] < 480);

        led_set(led_cnt++);
    }

    return 0;
}
