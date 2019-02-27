#include <stdint.h>
#include <stm32f1xx.h>
#include "common.h"
/*
	USART1 缺省引脚 TX/PA9 RX/PA10 RM0008 page 185 
	串口的设定参考                 RM0008 page 166 table 24 USARTs
	TX Alternate function push-pull
	RX Input floating(!@#$%^ 非常奇怪，居然不是Alternate function)
	波特率的设定 page 803
	72Mhz的 115200 的USARTDIV值是 39.0625
	39 是 DIV_Mantissa值
	DIV_Fraction值 = 16 * 0.0625 = 1， 最接近的值是 1
	因此 USART_BBR(page 825) = 0x271
	36Mhz 115200 19.5 USART_BBR = 0x138
 */
struct {
	uint16_t in;
	uint8_t head;
	uint8_t tail;
	uint8_t buf[256];

}u1;
int usart1_get(void){
	if(0xff00 & u1.in){
		u1.in=0;
		return u1.in & 0xff;
	} else {
		return -1;
	}
}
void usart1_config(void)
{
	NVIC_EnableIRQ(USART1_IRQn);
	NVIC_SetPriority(USART1_IRQn,2);
	// 设备的频率还需要设置RCC->CFGR.PPRE1/2的分频才能准确
	// 由于设备的频率被设置成/2分频了。因此之前BRR被设置错误了
	USART1->BRR = 0x271; // 115200 baudrate at 72Mhz
	// page 826
	USART1->CR1 = USART_CR1_RE | USART_CR1_RXNEIE | USART_CR1_TE;
	BITBAND(USART1->CR1)->bit[USART_CR1_UE_Pos]=1;
	u1.tail=0;
	u1.head=0;
}

void USART1_handler(void)
{
	if ((USART1->SR & USART_SR_RXNE) == USART_SR_RXNE){
		u1.in=(USART1->DR | 0x8000);
		return;
	}
//	if((USART1->SR & USART_SR_TXE) == USART_SR_TXE){
//		u1.out(&u1,&USART1->DR);
//	}
}
void usart1_event(void){
	if(u1.tail != u1.head){
		if(USART1->SR & USART_SR_TXE){
			USART1->DR=u1.buf[u1.tail];
			u1.tail++;
		}
	}
}
