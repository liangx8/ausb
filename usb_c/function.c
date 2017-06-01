#include <stdint.h>
#include <C8051F320.h>
#include "function.h"

__xdata uint8_t display_buf[256];

__code const char hex_table[]={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
__code const char msg_checkpoint[] = "check point";


uint8_t start,end;

void debug(void){
	uint8_t b=(uint8_t)&display_buf;
	SBUF0 = hex_table[(b>>4) & 0x0f];
		while(!TI0);
		TI0=0;
	SBUF0 = hex_table[b & 0x0f];
		while(!TI0);
		TI0=0;
		b=(uint8_t)&end;
	SBUF0 = hex_table[(b>>4) & 0x0f];
		while(!TI0);
		TI0=0;
	SBUF0 = hex_table[b & 0x0f];
		while(!TI0);
		TI0=0;
}
void fdcr(void)
{
	display_buf[end]='\n';
	end++;
	display_buf[end]='\r';
	end++;
}

void init_display(void){
	start=end=0;
}
void uart_cycle(void)
{
	while(start != end){
		SBUF0=display_buf[start];
		start ++;
		while(!TI0);
		TI0=0;
	}
}

void printbuf(uint8_t len,uint8_t *buf)
{
	fdcr();
	for(uint8_t i=0;i<len;i++){
		if(i){
			display_buf[end]=' ';
			end ++;
		}
		printhex(buf[i]);
	}
}
void printhex(uint8_t v)
{
	uint8_t b= v >> 4;
	display_buf[end]=hex_table[b & 0x0f];
	end ++;
	display_buf[end]=hex_table[v & 0x0f];
	end ++;
}

void checkpoint(uint8_t v)
{
	fdcr();
	for(uint8_t i=0;i< sizeof(msg_checkpoint);i++){
		display_buf[end]=msg_checkpoint[i];
		end ++;
	}
	printhex(v);
	
}