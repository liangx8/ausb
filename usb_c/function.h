#ifndef __FUNCTION_H
#define __FUNCTION_H

void init_display(void);
void uart_cycle(void);

void printbuf(uint8_t len,uint8_t *buf);
void printhex(uint8_t v);

void checkpoint(uint8_t v);

#endif