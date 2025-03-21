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

    volatile uint8_t *character_ram = (uint8_t *)0xf0f00000;
    volatile uint8_t *font_ram = (uint8_t *)0xf0e00000;

    character_ram[0] = 0;
    character_ram[1] = 1;
    character_ram[2] = 2;
    character_ram[3] = 3;

    character_ram[64] = 1;
    character_ram[128] = 2;
    character_ram[192] = 3;

    font_ram[0] = 0;
    font_ram[1] = 0;
    font_ram[2] = 0;
    font_ram[3] = 0x18;
    font_ram[4] = 0x18;
    font_ram[5] = 0;
    font_ram[6] = 0;
    font_ram[7] = 0;

    font_ram[8] = 0x00;
    font_ram[9] = 0x3c;
    font_ram[10] = 0x66;
    font_ram[11] = 0x7e;
    font_ram[12] = 0x66;
    font_ram[13] = 0x66;
    font_ram[14] = 0x66;
    font_ram[15] = 0x00;

    font_ram[16] = 0x00;
    font_ram[17] = 0x7e;
    font_ram[18] = 0x7e;
    font_ram[19] = 0x7e;
    font_ram[20] = 0x7e;
    font_ram[21] = 0x7e;
    font_ram[22] = 0x7e;
    font_ram[23] = 0x7e;

    font_ram[24] = 0x00;
    font_ram[25] = 0x18;
    font_ram[26] = 0x18;
    font_ram[27] = 0x18;
    font_ram[28] = 0x18;
    font_ram[29] = 0x18;
    font_ram[30] = 0x18;
    font_ram[31] = 0x00;

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
        led_set(led_cnt++);
    }

    return 0;
}
