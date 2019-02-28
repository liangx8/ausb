#ifndef USART_H
#define USART_H

void usart1_config(void);
void usart1_puts(const uint8_t *,uint32_t);
void usart1_putsz(const uint8_t *);
void usart1_hex(uint32_t);
int usart1_get(void); // usart_asm.S
void hex_str(char *buf,uint32_t value,uint32_t size);


#endif
