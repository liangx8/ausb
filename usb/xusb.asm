;; -*- mode: msc51; coding:utf-8 -*-
; $Id$
; $Time-stamp$
.include "c8051f320.h"
;; $include(c8051f320.inc)
; constants and micro {{{
PIN_BUTTON		.equ 	5
BUTTON			.equ 	p2+PIN_BUTTON
PIN_RED			.equ	2
PIN_GREEN		.equ	3
RED_LED			.equ	p2+PIN_RED
GREEN_LED		.equ	p2+PIN_GREEN

; SETUP structure
S_REQUEST_TYPE	.equ	0
S_REQUEST		.equ	1
S_VALUE			.equ	2
S_INDEX			.equ	4
S_LENGTH		.equ	6

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
;; request codes
GET_STATUS			.equ 0
CLEAR_FEATURE		.equ 1
SET_FEATURE			.equ 3
SET_ADDRESS			.equ 5
GET_DESCRIPTOR		.equ 6
SET_DESCRIPTOR		.equ 7
GET_CONFIGURATION	.equ 8
SET_CONFIGURATION	.equ 9
GET_INTERFACE		.equ 10
SET_INTERFACE		.equ 11
SYNCH_FRAME			.equ 12

;; descriptor types

DSC_CONFIGURATION				.equ 2
DSC_STRING						.equ 3
DSC_INTERFACE					.equ 4
DSC_ENDPOINT					.equ 5
DSC_DEVICE_QUALIFIER			.equ 6
DSC_OTHER_SPEED_CONFIGURATION	.equ 7
DSC_INTERFACE_POWER				.equ 8
; }}}
; bit definition {{{
.area BITDATA (ABS)
usb_en:			.ds	1
debug_start:	.ds 1
; dummy: dbit 1
; }}}
; variable definition {{{
.area XDATA (ABS)
setup_data:	.ds 8
.area DATA (ABS)
	. = . + 0x30
;dummy: .ds 1
;temp1:		.ds 1
b_cmint:	.ds 1
b_in1int:	.ds 1
b_out1int:	.ds 1

ep0data:	.ds 2
ep0_nbyte:	.ds 1
ep0_state:	.ds 1

ep1buf:		.ds 2
ep1_nbyte:	.ds 2
ep1_state:	.ds 1

ep2buf:		.ds 2
ep2_nbyte:	.ds 2
ep2_state:	.ds 1

mstate:		.ds 1		; machine state

debug_cnt:	.ds 1

; }}}
.area CODE (ABS)
	ljmp	main
.org	0x43
	push	psw
	ljmp	usb0_int
.org	0x7b
usb0_int:
; use bank 3
	push	acc
	setb	rs0
	setb	rs1
	setb	RED_LED
;	cpl		GREEN_LED
	mov		r0,#CMINT
	acall	uread
	mov		b_cmint,b
	mov		r0,#IN1INT
	acall	uread
	mov		b_in1int,b
	mov		r0,#OUT1INT
	acall	uread
	mov		b_out1int,b

	mov		a,b_cmint
	jnb		acc+RSTINT,usin_1
	acall	usb_reset
usin_1:
	mov		a,b_in1int
	jnb		acc+EP0,usin_2
	acall	endpoint0
usin_2:
	mov		a,b_in1int
	jnb		acc+IN1,usin_3
; endpoint1 in
usin_3:
	mov		a,b_out1int
	jnb		acc+OUT2,usin_4
; endpoint2 out
usin_4:

	clr		RED_LED
	pop		acc
	pop		psw
	reti
; function usb_reset {{{
usb_reset:
	mov		mstate,#DEV_WAIT
	mov		r0,#POWER
	mov		a,#0
	acall	uwrite
	mov		ep0_state,#EP_IDLE
	ret
; }}}
; function endpoint0 {{{
endpoint0:
	mov		r0,#INDEX
	clr		a
	acall	uwrite
	mov		r0,#E0CSR
	acall	uread
	mov		a,b
; handle setup end
	jnb		acc+SUEND,enp0_2
	mov		r0,#E0CSR
	mov		a,#1 << SSUEND
	acall	uwrite
	mov		mstate,#DEV_IDLE
enp0_2:
	mov		a,b
	jnb		acc+STSTL,enp0_3
	mov		r0,#E0CSR
	clr		a
	acall	uwrite
	mov		mstate,#DEV_IDLE
enp0_3:
	mov		a,b
	jnb		acc+OPRDY,enp0_1
	acall	handle_incoming_packet
enp0_1:
	mov		a,ep0_state
	cjne	a,#EP_TX,enp0_4
	mov		dpl,ep0data
	mov		dph,ep0data+1
	mov		r0,ep0_nbyte
	mov		r1,#0
	mov		a,#0			; endpoint0
	acall	fifo_cwrite
	mov		a,#(1 << DATAEND )+ (1 << INPRDY)
	mov		r0,#E0CSR
	acall	uwrite
	mov		ep0_state,#EP_IDLE
enp0_4:

	ret
handle_incoming_packet:
	mov		dptr,#setup_data
	clr		a					; end point0
	mov		r0,#8
	acall	fifo_read
	mov		dptr,#setup_data
	movx	a,@dptr
	anl		a,#0b11100000		; hold 7~5 bits
	cjne	a,#0,hipa_1
; setup transfer out
	mov		dptr,#setup_data+S_REQUEST
	movx	a,@dptr
	cjne	a,#SET_ADDRESS,1$
;cpl GREEN_LED
	acall	uset_address
	sjmp	hipa_2
1$:
	cjne	a,#SET_INTERFACE,2$
	sjmp	hipa_2
2$:
	cjne	a,#SET_FEATURE,3$
	sjmp	hipa_2
3$:
	cjne	a,#SET_CONFIGURATION,4$
	sjmp	hipa_2
4$:
	cjne	a,#CLEAR_FEATURE,5$
	sjmp	hipa_2
5$:

hipa_1:
	cjne	a,#0x80,setup_tx_err
; descriptor transimit (device to host)
	mov		dptr,#setup_data+S_REQUEST
	movx	a,@dptr
	cjne	a,#GET_DESCRIPTOR,1$
; GET_DESCRIPTOR, next step is expected a OUT transfer, SET_ADDRESS
	mov		ep0data,#descriptor			;byte low
	mov		ep0data+1,#descriptor >> 8	;byte high
	mov		ep0_nbyte,#18				; length of descriptor
	mov		ep0_state,#EP_TX
;cpl GREEN_LED
	sjmp	hipa_2
1$:
; other get operations
;cpl GREEN_LED
	cjne	a,#GET_STATUS,2$
	sjmp	hipa_2
2$:
	cjne	a,#GET_CONFIGURATION,3$
;cpl GREEN_LED
	sjmp	hipa_2
3$:
	cjne	a,#GET_INTERFACE,setup_tx_err
	sjmp	hipa_2
setup_tx_err:
	mov		ep0_state,#EP_ERROR
hipa_2:
	mov		a,ep0_state
	cjne	a,#EP_ERROR,hipa_3
	mov		a,#(1 << SOPRDY)+(1 << SDSTL)
	sjmp	hipa_4
hipa_3:
	mov		a,#(1 << SOPRDY)
hipa_4:
	mov		r0,#E0CSR
	acall	uwrite
	ret

uset_address:
	mov		ep0_state,#EP_ERROR
	mov		dptr,#setup_data+S_INDEX
	movx	a,@dptr
	jnz		sead_1
	mov		dptr,#setup_data+S_INDEX+1
	movx	a,@dptr
	jnz		sead_1
	mov		dptr,#setup_data+S_VALUE
	movx	a,@dptr
	mov		r0,#FADDR
	acall	uwrite
	mov		ep0_state,#EP_IDLE
sead_1:
	ret
; }}}
; delay routines {{{
delay5us:
	mov		r2,#10
	djnz	r2, .
	ret
delay5000ms:
	mov		r4,#20
de50ms_2:
	mov		r3,#0
de50ms_1:
	mov		r2,#0
	djnz	r2, .
	djnz	r3,de50ms_1
	djnz	r4,de50ms_2
	ret
; }}}
; initialization routines {{{
init_interrupt:
; EUSB0 = 1
	mov		EIE1,#0b00000010
	setb	ea
	ret
init_usb_clk:
;	mov		CLKMUL,#0
	mov		CLKMUL,#0x80
	acall	delay5us
	mov		CLKMUL,#0xc0
iucl_1:
	mov		a,CLKMUL
	jnb		acc.5,iucl_1
	mov		CLKSEL,#2
	ret
init_sys:
; choose 12000000Hz
; IFCN1:0=11 sysclk derived from internal oscillator divided by 1
	mov		OSCICN,#0b10000011
insy_1:
	mov		a,OSCICN
	jnb		acc.6,insy_1
	ret
init_io:
	mov		P2MDIN,#(1 << PIN_RED) + (1 << PIN_GREEN) + (1 << PIN_BUTTON)
	mov		P2MDOUT,# ~ (1 << PIN_BUTTON)
	mov		P2SKIP,#0xff
	mov		p2,#(1 << PIN_BUTTON)
	mov		XBR0,#0
	mov		XBR1,#0x40

	ret
; }}}
; function ustop {{{
ustop:
	mov		USB0XCN,#0
	ret
; }}}
; function ustart {{{
ustart:
	mov		r0,#POWER
	mov		a,#8
	acall	uwrite
	mov		r0,#IN1IE
	mov		a,#0x0f
	acall	uwrite
	mov		r0,#OUT1IE
	mov		a,#0x0f
	acall	uwrite
	mov		r0,#CMIE
	mov		a,#4
	acall	uwrite

	mov		USB0XCN,#0b11000000
	mov		USB0XCN,#0b11100000

	mov		r0,#CLKREC
	mov		a,#0x80
	acall	uwrite

	mov		r0,#POWER
	clr		a
	acall	uwrite

	ret
; }}}
; function fifo_read,fifo_write {{{
; [in] dptr xram address
; [in] a endpoint number 0,1,2
; [in] r0 length of data
fifo_read:
	add		a,#0x20
	mov		USB0ADR,a
	orl		a,#0b11000000
	mov		USB0ADR,a
fire_1:
	mov		a,USB0ADR
	jb		acc.7,fire_1
	mov		a,USB0DAT
	movx	@dptr,a
	inc		dptr
	djnz	r0,fire_1
	mov		USB0ADR,#0
	ret
; [in] dptr code address
; [in] a endpoint number 0,1,2
; [in] r0,r1 length of data
fifo_cwrite:
	add		a,#0x20
	mov		USB0ADR,a
ficw_4:
	mov		a,USB0ADR
	jb		acc.7,ficw_4
ficw_3:
	mov		a,r1
	jnz		ficw_1
	mov		a,r0
	jnz		ficw_1
	ret
ficw_1:
	clr		a
	movc	a,@a+dptr
	mov		USB0DAT,a
ficw_2:
	mov		a,USB0ADR
	jb		acc.7,ficw_2
	inc		dptr
	clr		c
	mov		a,r0
	subb	a,#1
	mov		r0,a
	mov		a,r1
	subb	a,#0
	mov		r1,a

	sjmp	ficw_3
; }}}

; function uwrite,uread {{{
; [in] r0,addr
; [out] b value
uread:
	mov		a,r0
	setb	acc.7
	mov		USB0ADR,a
ur_1:
	mov		a,USB0ADR
	jb		acc.7,ur_1
	mov		b,USB0DAT
	ret
; [in] r0 addr
; [in] a data
uwrite:
	mov		USB0ADR,r0
	mov		USB0DAT,a
uw_1:
	mov		a,USB0ADR
	jb		acc.7,uw_1
	ret
; }}}
; function wait_button {{{
wait_button:
	jb		BUTTON, .
	jnb		BUTTON, .
	acall	delay5000ms
	ret
; }}}
; main {{{
main:
	clr		ea
	mov		sp,#0xcf
	mov		psw,#0

	anl		PCA0MD,#0b10111111
	mov		VDM0CN,#0b10000000
	acall	init_sys
	acall	init_io
	acall	init_usb_clk
	acall	init_interrupt
	clr		usb_en
;	acall	ustart
;	acall	ustop
clr debug_start

m1:
	acall	wait_button
	cpl		usb_en
	jb		usb_en,start_usb
	acall	ustop
	sjmp	m1
start_usb:

mov debug_cnt,#0
	acall	ustart
	sjmp	m1
; }}}
descriptor:
.db 18			; bLength
.db 1			; bDescriptorType
.db 0,2			; bcdUSB 0x100 USB 2.0
.db 0			; bDeviceClass
.db 0			; bDeviceSubClass premnent
.db 0			; bDeviceProtocol
.db 64			; bMaxPackerSize0
.db 0,0x40		; idVendor
.db 0,0xaa		; idProduct
.db 0,0			; bcdDevice
.db 0			; iManufacturer
.db 0			; iProduct
.db 0			; iSerialNumber
.db 1			; bNumConfigurations

; vim: filetype=asm51 tabstop=4
