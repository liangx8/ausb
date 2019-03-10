	.syntax unified
	@在makefile中指定cpu类型，如果与这个不符合，会编译失败
	.cpu cortex-m3
	.thumb


	.global Default_Handler
	.weak Reset_Handler
	.section .text_startup1
	.func Reset_Handler
	.type Reset_Handler, %function
	.thumb_func
	.align
Reset_Handler:
	bl system_init
	bl mcu_init
	/*这是短跳，如果main方法太远，会导致编译失败。必须在linker script中定义main方法的位置(参考stm32.ld和main.c中main的定义)*/
	b.n main
	.size Reset_Handler, . - Reset_Handler
	.pool
	.endfunc

	.section .text
	.func Default_Handler
	.type Default_Handler, %function
	.thumb_func
	.align
Default_Handler:
	b.n Default_Handler
	.size Default_Handler, . - Default_Handler
	.pool
	.endfunc
	
	.section .isr_vector,"a",%progbits

.long	_estack							/*!< -16 0x08000000 Top of stack*/
.long	Reset_Handler					/*!< -15 0x08000004 Reset Interrupt*/
.long	NMI_Handler						/*!< -14 0x08000008 2 Non Maskable Interrupt                             */
.long	0								/*!< -13 0x0800000c Reserved*/
.long	MemoryManagement_Handler		/*!< -12 0x08000010 4 Cortex-M3 Memory Management Interrupt              */
.long	BusFault_Handler				/*!< -11 0x08000014 5 Cortex-M3 Bus Fault Interrupt                      */
.long	UsageFault_Handler				/*!< -10 0x08000018 6 Cortex-M3 Usage Fault Interrupt                    */
.long	0								/*!< -9 0x0800001c Reserved*/
.long	0								/*!< -8 0x08000020 Reserved*/
.long	0								/*!< -7 0x08000024 Reserved*/
.long	0								/*!< -6 0x08000028 Reserved*/
.long	SVCall_Handler					/*!< -5 0x0800002c 11 Cortex-M3 SV Call Interrupt                       */
.long	DebugMonitor_Handler			/*!< -4 0x08000030 12 Cortex-M3 Debug Monitor Interrupt                 */
.long	0								/*!< -3 0x08000034 Reserved*/
.long	PendSV_Handler					/*!< -2 0x08000038 14 Cortex-M3 Pend SV Interrupt                       */
.long	SysTick_Handler					/*!< -1 0x0800003c 15 Cortex-M3 System Tick Interrupt                   */
.long	WWDG_Handler					/*!< 0 0x08000040 Window WatchDog Interrupt                            */
.long	PVD_Handler						/*!< 1 0x08000044 PVD through EXTI Line detection Interrupt            */
.long	TAMPER_Handler					/*!< 2 0x08000048 Tamper Interrupt                                     */
.long	RTC_Handler						/*!< 3 0x0800004c RTC global Interrupt                                 */
.long	FLASH_Handler					/*!< 4 0x08000050 FLASH global Interrupt                               */
.long	RCC_Handler						/*!< 5 0x08000054 RCC global Interrupt                                 */
.long	EXTI0_Handler					/*!< 6 0x08000058 EXTI Line0 Interrupt                                 */
.long	EXTI1_Handler					/*!< 7 0x0800005c EXTI Line1 Interrupt                                 */
.long	EXTI2_Handler					/*!< 8 0x08000060 EXTI Line2 Interrupt                                 */
.long	EXTI3_Handler					/*!< 9 0x08000064 EXTI Line3 Interrupt                                 */
.long	EXTI4_Handler					/*!< 10 0x08000068 EXTI Line4 Interrupt                                 */
.long	DMA1_Channel1_Handler			/*!< 11 0x0800006c DMA1 Channel 1 global Interrupt                      */
.long	DMA1_Channel2_Handler			/*!< 12 0x08000070 DMA1 Channel 2 global Interrupt                      */
.long	DMA1_Channel3_Handler			/*!< 13 0x08000074 DMA1 Channel 3 global Interrupt                      */
.long	DMA1_Channel4_Handler			/*!< 14 0x08000078 DMA1 Channel 4 global Interrupt                      */
.long	DMA1_Channel5_Handler			/*!< 15 0x0800007c DMA1 Channel 5 global Interrupt                      */
.long	DMA1_Channel6_Handler			/*!< 16 0x08000080 DMA1 Channel 6 global Interrupt                      */
.long	DMA1_Channel7_Handler			/*!< 17 0x08000084 DMA1 Channel 7 global Interrupt                      */
.long	ADC1_2_Handler					/*!< 18 0x08000088 ADC1 and ADC2 global Interrupt                       */
.long	USB_HP_CAN1_TX_Handler			/*!< 19 0x0800008c USB Device High Priority or CAN1 TX Interrupts       */
.long	USB_LP_CAN1_RX0_Handler			/*!< 20 0x08000090 USB Device Low Priority or CAN1 RX0 Interrupts       */
.long	CAN1_RX1_Handler				/*!< 21 0x08000094 CAN1 RX1 Interrupt                                   */
.long	CAN1_SCE_Handler				/*!< 22 0x08000098 CAN1 SCE Interrupt                                   */
.long	EXTI9_5_Handler					/*!< 23 0x0800009c External Line[9:5] Interrupts                        */
.long	TIM1_BRK_Handler				/*!< 24 0x080000a0 TIM1 Break Interrupt                                 */
.long	TIM1_UP_Handler					/*!< 25 0x080000a4 TIM1 Update Interrupt                                */
.long	TIM1_TRG_COM_Handler			/*!< 26 0x080000a8 TIM1 Trigger and Commutation Interrupt               */
.long	TIM1_CC_Handler					/*!< 27 0x080000ac TIM1 Capture Compare Interrupt                       */
.long	TIM2_Handler					/*!< 28 0x080000b0 TIM2 global Interrupt                                */
.long	TIM3_Handler					/*!< 29 0x080000b4 TIM3 global Interrupt                                */
.long	TIM4_Handler					/*!< 30 0x080000b8 TIM4 global Interrupt                                */
.long	I2C1_EV_Handler					/*!< 31 0x080000bc I2C1 Event Interrupt                                 */
.long	I2C1_ER_Handler					/*!< 32 0x080000c0 I2C1 Error Interrupt                                 */
.long	I2C2_EV_Handler					/*!< 33 0x080000c4 I2C2 Event Interrupt                                 */
.long	I2C2_ER_Handler					/*!< 34 0x080000c8 I2C2 Error Interrupt                                 */
.long	SPI1_Handler					/*!< 35 0x080000cc SPI1 global Interrupt                                */
.long	SPI2_Handler					/*!< 36 0x080000d0 SPI2 global Interrupt                                */
.long	USART1_Handler					/*!< 37 0x080000d4 USART1 global Interrupt                              */
.long	USART2_Handler					/*!< 38 0x080000d8 USART2 global Interrupt                              */
.long	USART3_Handler					/*!< 39 0x080000dc USART3 global Interrupt                              */
.long	EXTI15_10_Handler				/*!< 40 0x080000e0 External Line[15:10] Interrupts                      */
.long	RTCAlarm_Handler				/*!< 41 0x080000e4 RTC Alarm through EXTI Line Interrupt                */
.long	USBWakeUp_Handler				/*!< 42 0x080000e8 USB Device WakeUp from suspend through EXTI Line Interrupt */

.weak NMI_Handler
.thumb_set NMI_Handler, Default_Handler
.weak MemoryManagement_Handler
.thumb_set MemoryManagement_Handler, Default_Handler
.weak BusFault_Handler
.thumb_set BusFault_Handler, Default_Handler
.weak UsageFault_Handler
.thumb_set UsageFault_Handler, Default_Handler
.weak SVCall_Handler
.thumb_set SVCall_Handler, Default_Handler
.weak DebugMonitor_Handler
.thumb_set DebugMonitor_Handler, Default_Handler
.weak PendSV_Handler
.thumb_set PendSV_Handler, Default_Handler
.weak SysTick_Handler
.thumb_set SysTick_Handler, Default_Handler
.weak WWDG_Handler
.thumb_set WWDG_Handler, Default_Handler
.weak PVD_Handler
.thumb_set PVD_Handler, Default_Handler
.weak TAMPER_Handler
.thumb_set TAMPER_Handler, Default_Handler
.weak RTC_Handler
.thumb_set RTC_Handler, Default_Handler
.weak FLASH_Handler
.thumb_set FLASH_Handler, Default_Handler
.weak RCC_Handler
.thumb_set RCC_Handler, Default_Handler
.weak EXTI0_Handler
.thumb_set EXTI0_Handler, Default_Handler
.weak EXTI1_Handler
.thumb_set EXTI1_Handler, Default_Handler
.weak EXTI2_Handler
.thumb_set EXTI2_Handler, Default_Handler
.weak EXTI3_Handler
.thumb_set EXTI3_Handler, Default_Handler
.weak EXTI4_Handler
.thumb_set EXTI4_Handler, Default_Handler
.weak DMA1_Channel1_Handler
.thumb_set DMA1_Channel1_Handler, Default_Handler
.weak DMA1_Channel2_Handler
.thumb_set DMA1_Channel2_Handler, Default_Handler
.weak DMA1_Channel3_Handler
.thumb_set DMA1_Channel3_Handler, Default_Handler
.weak DMA1_Channel4_Handler
.thumb_set DMA1_Channel4_Handler, Default_Handler
.weak DMA1_Channel5_Handler
.thumb_set DMA1_Channel5_Handler, Default_Handler
.weak DMA1_Channel6_Handler
.thumb_set DMA1_Channel6_Handler, Default_Handler
.weak DMA1_Channel7_Handler
.thumb_set DMA1_Channel7_Handler, Default_Handler
.weak ADC1_2_Handler
.thumb_set ADC1_2_Handler, Default_Handler
.weak USB_HP_CAN1_TX_Handler
.thumb_set USB_HP_CAN1_TX_Handler, Default_Handler
.weak USB_LP_CAN1_RX0_Handler
.thumb_set USB_LP_CAN1_RX0_Handler, Default_Handler
.weak CAN1_RX1_Handler
.thumb_set CAN1_RX1_Handler, Default_Handler
.weak CAN1_SCE_Handler
.thumb_set CAN1_SCE_Handler, Default_Handler
.weak EXTI9_5_Handler
.thumb_set EXTI9_5_Handler, Default_Handler
.weak TIM1_BRK_Handler
.thumb_set TIM1_BRK_Handler, Default_Handler
.weak TIM1_UP_Handler
.thumb_set TIM1_UP_Handler, Default_Handler
.weak TIM1_TRG_COM_Handler
.thumb_set TIM1_TRG_COM_Handler, Default_Handler
.weak TIM1_CC_Handler
.thumb_set TIM1_CC_Handler, Default_Handler
.weak TIM2_Handler
.thumb_set TIM2_Handler, Default_Handler
.weak TIM3_Handler
.thumb_set TIM3_Handler, Default_Handler
.weak TIM4_Handler
.thumb_set TIM4_Handler, Default_Handler
.weak I2C1_EV_Handler
.thumb_set I2C1_EV_Handler, Default_Handler
.weak I2C1_ER_Handler
.thumb_set I2C1_ER_Handler, Default_Handler
.weak I2C2_EV_Handler
.thumb_set I2C2_EV_Handler, Default_Handler
.weak I2C2_ER_Handler
.thumb_set I2C2_ER_Handler, Default_Handler
.weak SPI1_Handler
.thumb_set SPI1_Handler, Default_Handler
.weak SPI2_Handler
.thumb_set SPI2_Handler, Default_Handler
.weak USART1_Handler
.thumb_set USART1_Handler, Default_Handler
.weak USART2_Handler
.thumb_set USART2_Handler, Default_Handler
.weak USART3_Handler
.thumb_set USART3_Handler, Default_Handler
.weak EXTI15_10_Handler
.thumb_set EXTI15_10_Handler, Default_Handler
.weak RTCAlarm_Handler
.thumb_set RTCAlarm_Handler, Default_Handler
.weak USBWakeUp_Handler
.thumb_set USBWakeUp_Handler, Default_Handler
