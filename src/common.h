#ifndef COMMON_H
#define COMMON_H

typedef struct {
  volatile uint32_t bit[32];
} _BitBand;



#define GPIO_ON(p,n) (p)->BSRR = 1 << (n)
#define GPIO_OFF(p,n) (p)->BRR = 1 << (n)
// bit band PM0056 page 24
// 注意：内存bit band不能使用这个宏,因为编译器会把代码设计得很复杂
#define BITBAND(p) ((_BitBand *)(((uint32_t)(&(p)) & 0xfff00000) + 0x2000000 + (( (uint32_t) (&(p)) & 0x000fffff) * 32)))

// 內存的bitband由於编译器的原因，必须设计为在运行时计算位置
_BitBand *ramBitBand(void *);


void ncopy(uint8_t *dst,const uint8_t *src,uint32_t size);

#endif
