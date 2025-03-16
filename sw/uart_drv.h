#ifndef UART_DRV_H_
#define UART_DRV_H_

#include <stdint.h>

/* Print character to UART */
void uart_print_char(char chr);

/* Print string to UART */
void uart_print_str(char *str);

/* Print HEX-value to UART */
void uart_print_hex(uint32_t hexval);

#endif
