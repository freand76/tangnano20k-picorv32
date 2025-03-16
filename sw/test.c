#include <stdbool.h>
#include <stdint.h>

static void print_char(char chr) {
    static volatile uint32_t *uart = (uint32_t *)0xff000000;
    while (*uart == 0x00000000) {
    }
    *uart = chr;
}

static void print_str(char *str) {
    while (*str != 0) {
        print_char(*str);
        str++;
    }
}

static void print_hex(uint32_t hexval) {
    static char nibble2char[16] = "0123456789abcdef";

    uint32_t bit_shift = 32;
    while (bit_shift != 0) {
        bit_shift -= 4;
        uint32_t nibble = (hexval >> bit_shift) & 0xf;
        char chr = nibble2char[nibble];
        print_char(chr);
    }
}

void main(void) {
    uint32_t *led = (uint32_t *)0xfe000000;
    *led = ~0x12;

    uint32_t *ram32 = (uint32_t *)0x01000000;
    uint16_t *ram16 = (uint16_t *)0x01000000;
    uint8_t *ram = (uint8_t *)0x01000000;

    *ram32 = 0x00000000;

    *ram++ = 0xfe;
    *ram++ = 0xde;
    *ram++ = 0xbe;
    *ram++ = 0xda;

    print_hex(*ram32);

    ram = (uint8_t *)0x01000000;

    ram[3] = 0x11;
    ram[2] = 0x22;
    ram[1] = 0x33;
    ram[0] = 0x44;

    *led = ~0x11;
    print_hex(ram16[1]);
    *led = ~0x13;
    print_hex(*ram16);
    *led = ~0x10;

    // print_str("Hello World\n");

    while (true) {
    }
}
