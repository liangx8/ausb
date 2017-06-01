.include "c8051f320.h"
.include "uart.h"
.include "usb.h"
LED1			.equ	P1.0
LED2			.equ	P1.1
LED3			.equ	P1.2
LED4			.equ	P3.0
; SETUP structure
;bmRequestType	.equ	0
bRequest		.equ	1
wValue			.equ	2
wIndex			.equ	4
wLength			.equ	6

; endpoint state
EP_IDLE			.equ	0
EP_TX			.equ	1
EP_ERROR		.equ	2
EP_HALTED		.equ	3
EP_RX			.equ	4

; machine state
DEV_IDLE		.equ	0
DEV_WAIT		.equ	1
DEV_RX_FILE		.equ	2
DEV_TX_FILE		.equ	3
DEV_TX_ACK		.equ	4
DEV_ERROR		.equ	5

; }}}
; USB CONSTANTS {{{

;; descriptor types
DSC_DEVICE						.equ 1
DSC_CONFIGURATION				.equ 2
DSC_STRING						.equ 3
DSC_INTERFACE					.equ 4
DSC_ENDPOINT					.equ 5
DSC_DEVICE_QUALIFIER			.equ 6
DSC_OTHER_SPEED_CONFIGURATION	.equ 7
DSC_INTERFACE_POWER				.equ 8
; HID descriptor types
DSC_REPORT						.equ 0x22
DSC_HID							.equ 0x21
DSC_PHYSICAL					.equ 0x23

.area BITDATA (ABS)
usb_en:			.ds	1

.area XDATA (ABS)
.area DATA (ABS)
	. = . + 0x30
main_loop_cnt:	.ds 1


.area HOME (CODE)
	ljmp	main
;	.ds	1
	reti
	.ds	7
	reti
	.ds	7
	reti
	.ds	7
	reti
	.ds	7
	reti
	.ds	7
	reti
	.ds	7
	reti
	.ds	7
	reti
	.ds	7
	push	psw
	ljmp	usb0_int
	.ds 3
	reti
	.ds 7
	reti
	.ds 7
	reti
	.ds 7
	reti
	.ds 7
	reti
	.ds 7
	reti
	.ds 7
init_io:
	; set led
	mov		P3MDIN, #1
	; set push-pull
	mov		P3MDOUT,#1
	mov		P1MDIN, #0b00000111
	mov		P1MDOUT,#0b00000111
	; All led off
	mov		P1,     #0
	mov		P2MDIN, #0xff
	mov		P2MDOUT,#0b00001100
	mov		P0SKIP, #0b11001111
	mov		P1SKIP, #0xff
	mov		P2SKIP, #0xff
	ret
init:
	; 时钟和电压
	anl		PCA0MD, #0b10111111
	; 使用 12000000Hz
	; IFCN1:0=11 sysclk derived from internal oscillator divided by 1
	mov		VDM0CN, #0b10000000
	; 等待电压稳定
	mov		OSCICN, #0b10000011
001$:
	mov		a,OSCICN
	jnb		acc.6,001$

	mov		XBR0,   #0
	mov		XBR1,   #0x40 ; enable cross bar
	ret
init_clk:
	mov		CLKMUL, #0
	
	mov		CLKMUL, #0x80
  ;while(--delay);
	acall	delay
	mov		CLKMUL, #0xc0
1$:
	mov		a,CLKMUL
	jnb		acc.5,1$
  ;while(CLKMUL & (1 << MULRDY));
	mov		CLKSEL,#0
	ret
init_timer:
	mov		a,TMOD
	; T0
	; 16bit mode 
	setb	acc.0
	clr		acc.1
	clr		acc.2
	clr		acc.3
	mov		TMOD,a
	mov		a,CKCON
	setb	acc.2
	mov		CKCON,a
	setb	TR0
	ret
main:
	mov		sp,#0xaf
	mov		psw,#0

	acall	init_io
	setb	LED1
	setb	LED2
	setb	LED3
	clr		LED4
	acall	init
	acall	init_clk
	acall	init_uart
	acall	init_timer
	acall	init_usb

	acall	delay
	clr		LED2
	; clear buf
	mov		EMI0CN,#1
	mov		r0,#0
1$:
	clr		a
	movx	@r0,a
	inc		r0
	mov		a,r0
	jnz     1$

	acall	power_up_echo
	clr		LED3
	setb	EA
main_loop:
	jnb		TF0,100$
	clr		TF0
	djnz	main_loop_cnt,100$
	cpl		LED1
	cpl		LED2
	mov		main_loop_cnt,#50
100$:
	acall	put_xbuf_to_uart
	mov		dpl,#handler
	mov		dph,#(handler>>8)
	acall	uart_pipo
	sjmp	main_loop
; main_loop end
delay:
	mov		r7,#0xff
1$:
	mov		r6,#0xff
2$:
	djnz	r6,2$
	djnz	r7,1$
	ret
power_up_echo:

	jnb		TF0, power_up_echo
	clr		TF0
	mov		a,r7
	anl		a,#0x0f
	jnz		102$
	cpl		LED1
	cpl		LED2
102$:
	djnz	r7,power_up_echo
	ret
handler:
; r7 作为参数
	
	cjne	r7,#'1',100$
	acall	fdcr
	mov		dptr,#str_usb_start
	acall	printstr
	ajmp	usb_start
100$:
	cjne	r7,#'2',101$
	acall	fdcr
	mov		dptr,#str_usb_stop
	acall	printstr
	mov		USB0XCN,#0
	ret
101$:
	cjne	r7,#'3',102$
	mov		a,#0x45
	ajmp	checkpoint
102$:
	cjne	r7,#'4',103$
	mov		a,#0x46
	ajmp	checkpoint
103$:
	ret
str_usb_start:
	.db    9
	.ascii 'USB start'
str_usb_stop:
	.db    8
	.ascii 'USB stop'