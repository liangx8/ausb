#include <stdint.h>


#define SRAM_BIT_BAND_BASE 0x22000000
#define assert(x) do {} while(0)
uint32_t ramBitBand(uint32_t p){
	uint32_t tmp=(p & 0xfffff) * 32;
	return tmp+SRAM_BIT_BAND_BASE;
}
void ncopy(uint8_t *dst,const uint8_t *src,uint32_t size)
{
	for(uint32_t i=0;i<size;i++)
		dst[i]=src[i];

}
