
//#include <stdint.h>
#include <stm32f1xx.h>
#include <string.h>
#include "usart.h"
#include "common.h"
/*
实验板上的蓝色LED接B12 串到3.3v，高电平时灯灭，低电平灯亮
*/
#define CLOCK 72/8 //时钟=72M

#define UID ((uint32_t *)UID_BASE)
void RCC_DeInit(void);
/*------------------------------------------------------------
				  外部8M,则得到72M的系统时钟
------------------------------------------------------------*/
void Stm32_Clock_Init(void)
{
	uint8_t temp=0;
	uint8_t timeout=0;
	RCC_DeInit();
	//RCC->CR|=0x00010000;  //外部高速时钟使能HSEON
	BITBAND(RCC->CR)->bit[RCC_CR_HSEON_Pos] = 1;

	timeout=0;
	//while(!(RCC->CR>>17)&&timeout<200)timeout++;//等待外部时钟就绪
	while(!(RCC->CR >> RCC_CR_HSERDY_Pos) && timeout<200)timeout++;//等待外部时钟就绪

	//0-24M 等待0;24-48M 等待1;48-72M等待2;(非常重要!)
	FLASH->ACR|=0x32;//FLASH 2个延时周期

	// usart1/2 需要APB1/2的時鐘分頻爲1
	RCC->CFGR = 0X001D0000;//APB1/2=DIV1;AHB=DIV1;PLL=9*CLK;HSE作为PLL时钟源
	//RCC->CR|=0x01000000;  //PLLON
	BITBAND(RCC->CR)->bit[RCC_CR_PLLON_Pos]=1;

	timeout=0;
	//while(!(RCC->CR>>25)&&timeout<200)timeout++;//等待PLL锁定
	while(!(RCC->CR>>RCC_CR_PLLRDY_Pos)&&timeout<200)timeout++;//等待PLL锁定

	//RCC->CFGR|=0x00000002;//PLL作为系统时钟
	BITBAND(RCC->CFGR)->bit[RCC_CFGR_SW_Pos+1]=1;
	while(temp!=0x02&&timeout<200)     //等待PLL作为系统时钟设置成功
	{
		temp=RCC->CFGR>>2;
		timeout++;
		temp&=0x03;
	}
	// 设置 APB2 的 PRESCALER 为/1,
	//BITBAND(RCC->CFGR)->bit[RCC_CFGR_PPRE2_Pos+2]=0;

	// 在72Mhz，PLCLK必须除6 ，文档要求ADC频率不能超过14MHZ
	BITBAND(RCC->CFGR)->bit[RCC_CFGR_ADCPRE_Pos+1]=1;


	/* SysTick setting */
	//SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_TICKINT_Msk | SysTick_CTRL_ENABLE_Msk;
	// 系统计时用8分频, 声音延时用，最小单位1/32啪，
	//SysTick->CTRL = SysTick_CTRL_TICKINT_Msk | SysTick_CTRL_ENABLE_Msk;
	//SysTick->CTRL = 0;
	//SysTick_Config(281250);
	SysTick_Config(0x1000000);

}

/*------------------------------------------------------------
					  把所有时钟寄存器复位
------------------------------------------------------------*/
void RCC_DeInit(void)
{
	/* disable all interruption */
	/* NVIC_ICER0 */
	NVIC->ICER[0]=0xffffffff;
	/* NVIC_ICER1 */
	NVIC->ICER[1]=0xffffffff;
	/* NVIC_ICER1 */
	NVIC->ICER[2]=0xffffffff;
	/* enable all interruption */
	//NVIC->ISER[0]=0xffffffff;
	//NVIC->ISER[1]=0xffffffff;
	//NVIC->ISER[2]=0xffffffff;

	RCC->APB2RSTR = 0x00000000;//外设复位
	RCC->APB1RSTR = 0x00000000;
	RCC->AHBENR = 0x00000014;  //flash时钟,闪存时钟使能.DMA时钟关闭
	RCC->APB2ENR = 0x00000000; //外设时钟关闭.
	RCC->APB1ENR = 0x00000000;
	RCC->CR |= 0x00000001;     //使能内部高速时钟HSION
	RCC->CFGR &= 0xF8FF0000;   //复位SW[1:0],HPRE[3:0],PPRE1[2:0],PPRE2[2:0],ADCPRE[1:0],MCO[2:0]
	RCC->CR &= 0xFEF6FFFF;     //复位HSEON,CSSON,PLLON
	RCC->CR &= 0xFFFBFFFF;     //复位HSEBYP
	RCC->CFGR &= 0xFF80FFFF;   //复位PLLSRC, PLLXTPRE, PLLMUL[3:0] and USBPRE
	RCC->CIR = 0x00000000;     //关闭所有中断
}
void start_echo(void)
{
	for(int x=0;x<20;x++){
		for(uint32_t y=0;y<0x40000;y++){
			__NOP();
		}
		BITBAND(GPIOB->ODR)->bit[12] ++;
	}
	BITBAND(GPIOB->ODR)->bit[12] = 1;
}

uint8_t vwelcome[]={0x57,0x65,0x6c,0x63,0x6f,0x6d,0x65,0,0x0a,0x0d};

// `Welcome' size: 9
const uint8_t welcome[]={0x57,0x65,0x6c,0x63,0x6f,0x6d,0x65,0x0a,0x0d};

int main(void) __attribute__ ((section(".text_startup2"))); // __attribute__ ((naked));
// main方法使用了naked属性定义，因此不要在函数体内使用任何栈变量
union DWORD sqr;
int main(void)
{
	start_echo();
	usart1_puts(welcome,9);
	int idx=0;
	usart1_hex(0x12345678);
	while(1){
		int c;
		if ((c=usart1_get()) > 0){
			sqr.b[idx]=c;
			idx ++;
			if (idx==4) {
				idx=0;
				usart1_hex(sqr.dw);
			}
			vwelcome[7]=idx;
			usart1_puts(vwelcome,10);
		}
	}
}
/*page 160*/
/*
	a2/ TX2 CNF2 = 10 MODE2 = 11
	a3/ RX2 CNF3 = 01 MODE3 = 00
	ohters output push-pull */
#define GPIOA_CRL_VALUE GPIO_CRL_MODE0 | GPIO_CRL_MODE1 | GPIO_CRL_MODE2 | GPIO_CRL_MODE3 | GPIO_CRL_MODE4 | GPIO_CRL_MODE5 | GPIO_CRL_MODE6
/* 
	a9/ TX1  Alternate function out push-pull CNF9 = 10 MODE9=11
	a10/ RX1 input float CNF10= 01 MODE10 = 00

	a11,a12,a15 output push-pull
	a13,a14 swd port use default
	a7 adc1 ch7
*/
#define GPIOA_CRH_VALUE GPIO_CRH_MODE8 | GPIO_CRH_CNF9_1 | GPIO_CRH_MODE9 | GPIO_CRH_CNF10_0 | GPIO_CRH_MODE11 | GPIO_CRH_MODE12 | GPIO_CRH_CNF13_0 | GPIO_CRH_CNF14_0 | GPIO_CRH_MODE15
#define GPIOA_ODR_VALUE 0
//#define GPIOA_CRH_VALUE GPIO_CRH_MODE8 | GPIO_CRH_MODE9 | GPIO_CRH_CNF10_0 | GPIO_CRH_MODE11 | GPIO_CRH_MODE12 | GPIO_CRH_CNF13_0 | GPIO_CRH_CNF14_0 | GPIO_CRH_MODE15
/*
	all but B12,B13,B14 GPIOB output push-pull
	B12 button
	B13,B14 left and right
	B12,B13,B14,B15 work on CNF = 00 MODE=11 ODR=0 output push-pull
	b0 adc1 ch8
*/
#define GPIOB_CRL_VALUE GPIO_CRL_MODE1 | GPIO_CRL_MODE2 | GPIO_CRL_MODE3 | GPIO_CRL_MODE4 | GPIO_CRL_MODE5 | GPIO_CRL_MODE6 | GPIO_CRL_MODE7
#define GPIOB_CRH_VALUE GPIO_CRH_MODE8 | GPIO_CRH_MODE9 | GPIO_CRH_MODE10 | GPIO_CRH_MODE11 | GPIO_CRH_MODE12 | GPIO_CRH_MODE13 | GPIO_CRH_MODE14 | GPIO_CRH_MODE15
#define GPIOB_ODR_VALUE 0
/*
1 开启afio时钟
2 使能外设IO PORTa,b,c时钟
3 USART1 使能
*/
#define RCC_APB2ENR_VALUE RCC_APB2ENR_USART1EN | RCC_APB2ENR_IOPAEN | RCC_APB2ENR_IOPBEN | RCC_APB2ENR_IOPCEN | RCC_APB2ENR_AFIOEN
/*
 * 1 PWREN
 * 2 BKPEN
 */
#define RCC_APB1ENR_VALUE RCC_APB1ENR_PWREN | RCC_APB1ENR_BKPEN
//#define RCC_APB2ENR_VALUE RCC_APB2ENR_IOPAEN | RCC_APB2ENR_IOPBEN | RCC_APB2ENR_IOPCEN | RCC_APB2ENR_AFIOEN
void mcu_init(void)
{
	Stm32_Clock_Init();
	// page 145 at RM0008
	RCC->APB2ENR = RCC_APB2ENR_VALUE;
	RCC->APB1ENR = RCC_APB1ENR_VALUE;
	//AFIO->MAPR = (0x00FFFFFF & AFIO->MAPR)|0x04000000;          //关闭JTAG
	GPIOA->CRL = GPIOA_CRL_VALUE;
	GPIOA->CRH = GPIOA_CRH_VALUE;
	GPIOB->CRL = GPIOB_CRL_VALUE;
	GPIOB->CRH = GPIOB_CRH_VALUE;
	GPIOB->ODR = GPIOB_ODR_VALUE;
	GPIOC->CRH = GPIO_CRH_MODE13;
	usart1_config();
}
