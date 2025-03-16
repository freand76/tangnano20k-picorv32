
#include <stdint.h>

#include "led_drv.h"

#define LED_ADDRESS 0xfe000000

static volatile uint32_t *led_reg = (uint32_t *)LED_ADDRESS;

void led_set(uint8_t led) {
    *led_reg = led;
}
