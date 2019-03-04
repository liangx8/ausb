	.syntax unified
	@在makefile中指定cpu类型，如果与这个不符合，会编译失败
	.cpu cortex-m3
	.thumb


	.global Default_handler

	.section .init
	.weak Reset_handler
	.func Reset_handler
	.type Reset_handler, %function
	.thumb_func
	.align
Reset_handler:
	bl mcu_init
	/*这是短跳，如果main方法太远，会导致编译失败。必须在linker script中定义main方法的位置(参考stm32.ld和main.c中main的定义)*/
	b.n main
	.size Reset_handler, . - Reset_handler
	.pool
	.endfunc

	.func Default_handler
	.type Default_handler, %function
	.thumb_func
	.align
Default_handler:
	b.n Default_handler
	.size Default_handler, . - Default_handler
	.pool
	.endfunc
	
	.section .isr_vector,"a",%progbits

.long	_estack
.long	Reset_handler		/* 0x0800 0004 */
.long	NMI_handler		/* 0x0800 0008 */
.long	HardFault_handler		/* 0x0800 000c */
.long	MemManage_handler		/* 0x0800 0010 */
.long	BusFault_handler		/* 0x0800 0014 */
.long	UsageFault_handler		/* 0x0800 0018 */
.long	0		/* 0x0800 001c Reserved*/
.long	0		/* 0x0800 0020 Reserved*/
.long	0		/* 0x0800 0024 Reserved*/
.long	0		/* 0x0800 0028 Reserved*/
.long	SVCall_handler		/* 0x0800 002c */
.long	DebugMonitor_handler		/* 0x0800 0030 */
.long	0		/* 0x0800 0034 Reserved*/
.long	PendSV_handler		/* 0x0800 0038 */
.long	SysTick_handler		/* 0x0800 003c */
.long	WWDG_handler		/*  0 0x0800 0040 */
.long	PVD_handler		/*  1 0x0800 0044 */
.long	TAMPER_handler		/*  2 0x0800 0048 */
.long	RTC_handler		/*  3 0x0800 004c */
.long	FLASH_handler		/*  4 0x0800 0050 */
.long	RCC_handler		/*  5 0x0800 0054 */
.long	EXTI0_handler		/*  6 0x0800 0058 */
.long	EXTI1_handler		/*  7 0x0800 005c */
.long	EXTI2_handler		/*  8 0x0800 0060 */
.long	EXTI3_handler		/*  9 0x0800 0064 */
.long	EXTI4_handler		/* 10 0x0800 0068 */
.long	DMA1_CHN1_handler		/* 11 0x0800 006c */
.long	DMA1_CHN2_handler		/* 12 0x0800 0070 */
.long	DMA1_CHN3_handler		/* 13 0x0800 0074 */
.long	DMA1_CHN4_handler		/* 14 0x0800 0078 */
.long	DMA1_CHN5_handler		/* 15 0x0800 007c */
.long	DMA1_CHN6_handler		/* 16 0x0800 0080 */
.long	DMA1_CHN7_handler		/* 17 0x0800 0084 */
.long	ADC1_2_handler		/* 18 0x0800 0088 */
.long	USB_HP_CAN1_TX_handler		/* 19 0x0800 008c */
.long	USB_LP_CAN1_RX0_handler		/* 20 0x0800 0090 */
.long	CAN1_RX1_handler		/* 21 0x0800 0094 */
.long	CAN1_SCE_handler		/* 22 0x0800 0098 */
.long	EXTI9_5_handler		/* 23 0x0800 009c */
.long	TIM1_BRK_handler		/* 24 0x0800 00a0 */
.long	TIM1_UP_handler		/* 25 0x0800 00a4 */
.long	TIM1_TRG_COM_handler		/* 26 0x0800 00a8 */
.long	TIM1_CC_handler		/* 27 0x0800 00ac */
.long	TIM2_handler		/* 28 0x0800 00b0 */
.long	TIM3_handler		/* 29 0x0800 00b4 */
.long	TIM4_handler		/* 30 0x0800 00b8 */
.long	I2C1_EV_handler		/* 31 0x0800 00bc */
.long	I2C1_ER_handler		/* 32 0x0800 00c0 */
.long	I2C2_EV_handler		/* 33 0x0800 00c4 */
.long	I2C2_ER_handler		/* 34 0x0800 00c8 */
.long	SPI1_handler		/* 35 0x0800 00cc */
.long	SPI2_handler		/* 36 0x0800 00d0 */
.long	USART1_handler		/* 37 0x0800 00d4 */
.long	USART2_handler		/* 38 0x0800 00d8 */
.long	USART3_handler		/* 39 0x0800 00dc */
.long	EXTI15_10_handler		/* 40 0x0800 00e0 */
.long	RTCAlarm_handler		/* 41 0x0800 00e4 */
.long	USBWakeUp_handler		/* 42 0x0800 00e8 */
.long	0		/* 43 0x0800 00ec Reserved*/
.long	0		/* 44 0x0800 00f0 Reserved*/
.long	0		/* 45 0x0800 00f4 Reserved*/
.long	0		/* 46 0x0800 00f8 Reserved*/
.long	0		/* 47 0x0800 00fc Reserved*/
.long	0		/* 48 0x0800 0100 Reserved*/
.long	0		/* 49 0x0800 0104 Reserved*/
.long	TIM5_handler		/* 50 0x0800 0108 */
.long	SPI3_handler		/* 51 0x0800 010c */
.long	UART4_handler		/* 52 0x0800 0110 */
.long	UART5_handler		/* 53 0x0800 0114 */
.long	TIM6_handler		/* 54 0x0800 0118 */
.long	TIM7_handler		/* 55 0x0800 011c */
.long	DMA2_CHN1_handler		/* 56 0x0800 0120 */
.long	DMA2_CHN2_handler		/* 57 0x0800 0124 */
.long	DMA2_CHN3_handler		/* 58 0x0800 0128 */
.long	DMA2_CHN4_handler		/* 59 0x0800 012c */
.long	DMA2_CHN5_handler		/* 60 0x0800 0130 */
.long	ETH_handler		/* 61 0x0800 0134 */
.long	ETH_WKUP_handler		/* 62 0x0800 0138 */
.long	CAN2_TX_handler		/* 63 0x0800 013c */
.long	CAN2_RX0_handler		/* 64 0x0800 0140 */
.long	CAN2_RX1_handler		/* 65 0x0800 0144 */
.long	CAN2_SCE_handler		/* 66 0x0800 0148 */
.long	OTG_FS_handler		/* 67 0x0800 014c */


/*.weak Reset_handler
.thumb_set Reset_handler,Default_handler
*/
.weak NMI_handler
.thumb_set NMI_handler,Default_handler
.weak HardFault_handler
.thumb_set HardFault_handler,Default_handler
.weak MemManage_handler
.thumb_set MemManage_handler,Default_handler
.weak BusFault_handler
.thumb_set BusFault_handler,Default_handler
.weak UsageFault_handler
.thumb_set UsageFault_handler,Default_handler
.weak SVCall_handler
.thumb_set SVCall_handler,Default_handler
.weak DebugMonitor_handler
.thumb_set DebugMonitor_handler,Default_handler
.weak PendSV_handler
.thumb_set PendSV_handler,Default_handler
.weak SysTick_handler
.thumb_set SysTick_handler,Default_handler
.weak WWDG_handler
.thumb_set WWDG_handler,Default_handler
.weak PVD_handler
.thumb_set PVD_handler,Default_handler
.weak TAMPER_handler
.thumb_set TAMPER_handler,Default_handler
.weak RTC_handler
.thumb_set RTC_handler,Default_handler
.weak FLASH_handler
.thumb_set FLASH_handler,Default_handler
.weak RCC_handler
.thumb_set RCC_handler,Default_handler
.weak EXTI0_handler
.thumb_set EXTI0_handler,Default_handler
.weak EXTI1_handler
.thumb_set EXTI1_handler,Default_handler
.weak EXTI2_handler
.thumb_set EXTI2_handler,Default_handler
.weak EXTI3_handler
.thumb_set EXTI3_handler,Default_handler
.weak EXTI4_handler
.thumb_set EXTI4_handler,Default_handler
.weak DMA1_CHN1_handler
.thumb_set DMA1_CHN1_handler,Default_handler
.weak DMA1_CHN2_handler
.thumb_set DMA1_CHN2_handler,Default_handler
.weak DMA1_CHN3_handler
.thumb_set DMA1_CHN3_handler,Default_handler
.weak DMA1_CHN4_handler
.thumb_set DMA1_CHN4_handler,Default_handler
.weak DMA1_CHN5_handler
.thumb_set DMA1_CHN5_handler,Default_handler
.weak DMA1_CHN6_handler
.thumb_set DMA1_CHN6_handler,Default_handler
.weak DMA1_CHN7_handler
.thumb_set DMA1_CHN7_handler,Default_handler
.weak ADC1_2_handler
.thumb_set ADC1_2_handler,Default_handler
.weak USB_HP_CAN1_TX_handler
.thumb_set USB_HP_CAN1_TX_handler,Default_handler
.weak USB_LP_CAN1_RX0_handler
.thumb_set USB_LP_CAN1_RX0_handler,Default_handler
.weak CAN1_RX1_handler
.thumb_set CAN1_RX1_handler,Default_handler
.weak CAN1_SCE_handler
.thumb_set CAN1_SCE_handler,Default_handler
.weak EXTI9_5_handler
.thumb_set EXTI9_5_handler,Default_handler
.weak TIM1_BRK_handler
.thumb_set TIM1_BRK_handler,Default_handler
.weak TIM1_UP_handler
.thumb_set TIM1_UP_handler,Default_handler
.weak TIM1_TRG_COM_handler
.thumb_set TIM1_TRG_COM_handler,Default_handler
.weak TIM1_CC_handler
.thumb_set TIM1_CC_handler,Default_handler
.weak TIM2_handler
.thumb_set TIM2_handler,Default_handler
.weak TIM3_handler
.thumb_set TIM3_handler,Default_handler
.weak TIM4_handler
.thumb_set TIM4_handler,Default_handler
.weak I2C1_EV_handler
.thumb_set I2C1_EV_handler,Default_handler
.weak I2C1_ER_handler
.thumb_set I2C1_ER_handler,Default_handler
.weak I2C2_EV_handler
.thumb_set I2C2_EV_handler,Default_handler
.weak I2C2_ER_handler
.thumb_set I2C2_ER_handler,Default_handler
.weak SPI1_handler
.thumb_set SPI1_handler,Default_handler
.weak SPI2_handler
.thumb_set SPI2_handler,Default_handler
.weak USART1_handler
.thumb_set USART1_handler,Default_handler
.weak USART2_handler
.thumb_set USART2_handler,Default_handler
.weak USART3_handler
.thumb_set USART3_handler,Default_handler
.weak EXTI15_10_handler
.thumb_set EXTI15_10_handler,Default_handler
.weak RTCAlarm_handler
.thumb_set RTCAlarm_handler,Default_handler
.weak USBWakeUp_handler
.thumb_set USBWakeUp_handler,Default_handler
.weak TIM5_handler
.thumb_set TIM5_handler,Default_handler
.weak SPI3_handler
.thumb_set SPI3_handler,Default_handler
.weak UART4_handler
.thumb_set UART4_handler,Default_handler
.weak UART5_handler
.thumb_set UART5_handler,Default_handler
.weak TIM6_handler
.thumb_set TIM6_handler,Default_handler
.weak TIM7_handler
.thumb_set TIM7_handler,Default_handler
.weak DMA2_CHN1_handler
.thumb_set DMA2_CHN1_handler,Default_handler
.weak DMA2_CHN2_handler
.thumb_set DMA2_CHN2_handler,Default_handler
.weak DMA2_CHN3_handler
.thumb_set DMA2_CHN3_handler,Default_handler
.weak DMA2_CHN4_handler
.thumb_set DMA2_CHN4_handler,Default_handler
.weak DMA2_CHN5_handler
.thumb_set DMA2_CHN5_handler,Default_handler
.weak ETH_handler
.thumb_set ETH_handler,Default_handler
.weak ETH_WKUP_handler
.thumb_set ETH_WKUP_handler,Default_handler
.weak CAN2_TX_handler
.thumb_set CAN2_TX_handler,Default_handler
.weak CAN2_RX0_handler
.thumb_set CAN2_RX0_handler,Default_handler
.weak CAN2_RX1_handler
.thumb_set CAN2_RX1_handler,Default_handler
.weak CAN2_SCE_handler
.thumb_set CAN2_SCE_handler,Default_handler
.weak OTG_FS_handler
.thumb_set OTG_FS_handler,Default_handler
	
	/*stm32f101/2/3/5xxx */

