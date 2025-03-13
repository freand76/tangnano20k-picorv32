#include <stdbool.h>
#include <stdint.h>

static void print_str(char *str) {
    static uint32_t *uart = (uint32_t *)0xff000000;

    while (*str != 0) {
        if (*uart == 0) {
            continue;
        }

        *uart = *str;
        str++;
    }
}

void main(void) {
    uint32_t *led = (uint32_t *)0xfe000000;
    *led = ~0x12;

    print_str("Hello World\n");

    while (true) {
    }
}
