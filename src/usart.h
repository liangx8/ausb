#ifndef USART_H
#define USART_H

void usart1_config(void);
void usart1_puts(const uint8_t *,uint32_t);
int usart1_get(void);
void usart1_hex(uint32_t c);


#endif
