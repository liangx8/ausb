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
;; bRequest codes
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

;inc debug_cnt

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
acall inc_debug_cnt
acall record_other
	mov		a,b_cmint
	jnb		acc+RSTINT,1$
	acall	usb_reset
1$:
	mov		a,b_in1int
	jnb		acc+EP0,2$
	acall	endpoint0
2$:
	mov		a,b_in1int
	jnb		acc+IN1,3$
; endpoint1 in
3$:
	mov		a,b_out1int
	jnb		acc+OUT2,4$
; endpoint2 out
4$:
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
acall record_other
	jnb		acc+SUEND,2$
; handle setup end
	mov		r0,#E0CSR
	mov		a,#1 << SSUEND
	acall	uwrite
	mov		mstate,#DEV_IDLE
2$:
	mov		a,b
	jnb		acc+STSTL,3$
	mov		r0,#E0CSR
	clr		a
	acall	uwrite
	mov		mstate,#DEV_IDLE
3$:
	mov		a,b
	jnb		acc+OPRDY,1$
	acall	handle_incoming_packet
1$:
	mov		a,ep0_state
	cjne	a,#EP_TX,4$
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
4$:
	ret
handle_incoming_packet:
	mov		dptr,#setup_data
	clr		a					; end point0
	mov		r0,#8
	acall	fifo_read

acall inc_debug_cnt
acall record_setup

	mov		dptr,#setup_data
	movx	a,@dptr
	anl		a,#0b11100000		; hold 7~5 bits
	cjne	a,#0,hipa_1
; setup transfer out
; 00 05 02 00 00 00 00 00
; 8字节SETUP package
; 00 05 SET_ADDRESS, 02 地址为2
	mov		dptr,#setup_data+bRequest
	movx	a,@dptr
	cjne	a,#SET_ADDRESS,1$
;cpl GREEN_LED
	acall	uset_address
	ajmp	hipa_2
1$:
	cjne	a,#SET_INTERFACE,2$
	ajmp	hipa_2
2$:
	cjne	a,#SET_FEATURE,3$
	ajmp	hipa_2
3$:
	cjne	a,#SET_CONFIGURATION,4$
	
	ajmp	hipa_2
4$:
	cjne	a,#CLEAR_FEATURE,5$

	ajmp	hipa_2
5$:

hipa_1:
	cjne	a,#0x80,setup_tx_err
; descriptor transimit (device to host)
	mov		dptr,#setup_data+bRequest
	movx	a,@dptr
	cjne	a,#GET_DESCRIPTOR,2$

; GET_DESCRIPTOR, next step is expected a OUT transfer, SET_ADDRESS
; 80 06 00 01 00 00 40 00
; 第一次接收到的8字节SETUP package
; USB_20.PDF 253页
; 根据USB定义, wValue(Descriptor type and Descriptor index) = 0x0100 
; the wValue field specifies the descriptor type in the high byte
; the descriptor index in the low byte
; 所以,这里的 descriptor type 就是 DEVICE (table 9-5)
	mov		dptr,#setup_data+wValue+1   ; descriptor type in high byte
	movx	a,@dptr
	cjne	a,#DSC_DEVICE,11$

	mov		ep0data,#des_device			;byte low
	mov		ep0data+1,#des_device >> 8	;byte high
	mov		ep0_nbyte,#18				; length of descriptor
	mov		ep0_state,#EP_TX
;cpl GREEN_LED
	sjmp	hipa_2
11$:
	cjne	a,#DSC_CONFIGURATION,12$
	mov		dptr,#setup_data+wLength
	movx	a,@dptr
	mov		ep0_nbyte,#DES_CONFIG_LEN	; length of descriptor
	cjne	a,#DES_CONFIG_LEN, . + 3
	jnc		19$
	mov		ep0_nbyte,a
19$:

	mov		ep0data,#des_config			;byte low
	mov		ep0data+1,#des_config >> 8	;byte high

	mov		ep0_state,#EP_TX
;cpl GREEN_LED
	sjmp	hipa_2

12$:
; other get descriptor operations
	cjne	a,#DSC_STRING,13$
	mov		dptr,#setup_data+wValue
	movx	a,@dptr
	cjne	a,#1,121$
	mov		ep0_state,#EP_TX
	mov		ep0data,#string1
	mov		ep0data+1,#string1 >> 8
	mov		ep0_nbyte,#NUMSTRING1
	sjmp	hipa_2
121$:
	cjne	a,#2,122$
	mov		ep0_state,#EP_TX
	mov		ep0data,#string2
	mov		ep0data+1,#string2 >> 8
	mov		ep0_nbyte,#NUMSTRING2
	sjmp	hipa_2
122$:
	acall	get_desc_report
	sjmp	hipa_2
13$:
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
;	mov		a,ep0_state
;	cjne	a,#EP_ERROR,hipa_3
;	mov		a,#(1 << SOPRDY)+(1 << SDSTL)
;	sjmp	hipa_4
;hipa_3:
	mov		a,#(1 << SOPRDY)
;hipa_4:
	mov		r0,#E0CSR
	acall	uwrite
	ret

get_desc_report:
	cjne	a,#DSC_REPORT,hipa_2
	mov		ep0_state,#EP_TX
	mov		ep0data,#des_report
	mov		ep0data+1,#des_report >> 8
	mov		ep0_nbyte,#des_report_end-des_report
	ret
uset_address:
	mov		ep0_state,#EP_ERROR
	mov		dptr,#setup_data+wIndex
	movx	a,@dptr
	jnz		sead_1
	mov		dptr,#setup_data+wIndex+1
	movx	a,@dptr
	jnz		sead_1
	mov		dptr,#setup_data+wValue
	movx	a,@dptr
	mov		r0,#FADDR
	acall	uwrite

;1$:
;	mov		r0,#FADDR
;	acall	uread
;	mov		a,b
;	jb		acc.7,1$

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
	setb	GREEN_LED
	mov		USB0XCN,#0
	ret
; }}}
; function ustart {{{
ustart:
	clr		GREEN_LED
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

	mov		debug_cnt,#0
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
4$:
	mov		a,USB0ADR
	jb		acc.7,4$
3$:
	mov		a,r1
	jnz		1$
	mov		a,r0
	jnz		1$
	ret
1$:
	clr		a
	movc	a,@a+dptr
	mov		USB0DAT,a
2$:
	mov		a,USB0ADR
	jb		acc.7,2$
	inc		dptr
	clr		c
	mov		a,r0
	subb	a,#1
	mov		r0,a
	mov		a,r1
	subb	a,#0
	mov		r1,a

	sjmp	3$
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
	acall	clear_x

;	acall	ustart
;	acall	ustop

	setb	GREEN_LED
m1:
	acall	wait_button
	cpl		usb_en
	jb		usb_en,start_usb
	acall	ustop
	sjmp	m1
start_usb:

	acall	ustart
	sjmp	m1
clear_x:
	mov		EMI0CN,#0

	clr		a
	mov		r0,a
1$:
	clr		a
	movx	@r0,a
	inc		r0
	mov		a,r0
	jnz		1$
	mov		EMI0CN,#1
2$:
	clr		a
	movx	@r0,a
	inc		r0
	mov		a,r0
	jnz		2$
	mov		EMI0CN,#2
3$:
	clr		a
	movx	@r0,a
	inc		r0
	mov		a,r0
	jnz		3$
	mov		EMI0CN,#3
4$:
	clr		a
	movx	@r0,a
	inc		r0
	mov		a,r0
	jnz		4$
	mov		EMI0CN,#0
	ret

record_setup:

	mov		a,debug_cnt
	clr		c
	rlc		a
	mov		r0,a
	clr		a
	rlc		a
	mov		r1,a

;	clr		c
	mov		a,r0
	rlc		a
	mov		r0,a
	mov		a,r1
	rlc		a
	mov		r1,a

;	clr		c
;	mov		a,r0
;	rlc		a
;	mov		r0,a
;	mov		a,r1
;	rlc		a
;	mov		r1,a

;	clr		c
	mov		a,r0
	rlc		a
	mov		dpl,a
	mov		a,r1
	rlc		a
	mov		dph,a


	mov		r1,a
	mov		r2,#8
	mov		r0,#0
1$:
	movx	a,@r0
	movx	@dptr,a
	inc		r0
	inc		dptr
	dec		r2
	mov		a,r2
	jnz		1$
	ret

record_other:
	mov		a,debug_cnt
	clr		c
	rlc		a
	mov		r0,a
	clr		a
	rlc		a
	mov		r1,a

;	clr		c
	mov		a,r0
	rlc		a
	mov		r0,a
	mov		a,r1
	rlc		a
	mov		r1,a

;	clr		c
;	mov		a,r0
;	rlc		a
;	mov		r0,a
;	mov		a,r1
;	rlc		a
;	mov		r1,a

;	clr		c
	mov		a,r0
	rlc		a
	mov		dpl,a
	mov		a,r1
	rlc		a
	mov		dph,a

;	clr		c
;	mov		a,#8
;	addc	a,r0
;	mov		dpl,a
;	clr		a
;	addc	a,r1
;	mov		dph,a


;	mov		a,#0xff
;	movx	@dptr,a

;	inc		dptr
	mov		a,b_cmint
	movx	@dptr,a

	inc		dptr
	mov		a,b_in1int
	movx	@dptr,a

	inc		dptr
	mov		a,b_out1int
	movx	@dptr,a

	inc		dptr		; E0CSR
	mov		a,b
	movx	@dptr,a

	ret

inc_debug_cnt:

	mov		a,debug_cnt
	cjne	a,#60,1$
	ret
1$:
	inc		debug_cnt
	ret
test_recrd:
clr ea
	mov		dptr,#0
	mov		a,#1
1$:
	movx	@dptr,a
	inc		dptr
	inc		a
	cjne	a,#9,1$
	mov debug_cnt,#0
2$:
inc debug_cnt
	acall record_setup
mov a, debug_cnt
cjne a,#20,2$

	sjmp .
; }}}
; usb_20.pdf page 262
; 
des_device:
.db 18			; bLength
.db 1			; bDescriptorType
.db 0,1			; bcdUSB 0x100 USB 2.0
.db 0			; bDeviceClass
.db 0			; bDeviceSubClass premnent
.db 0			; bDeviceProtocol
.db 64			; bMaxPackerSize0
.db 4,4			; idVendor
.db 0,0xaa		; idProduct
.db 0x10,0		; bcdDevice
.db 0			; iManufacturer
.db 2			; iProduct
.db 1			; iSerialNumber
.db 1			; bNumConfigurations

DES_CONFIG_LEN	.equ conf_end-des_config
des_config:
.db 0x09				; bLength
.db 0x02				; bDescriptorType
.db DES_CONFIG_LEN,0x00	; TotalLength (lsb first)
.db 0x01				; NumInterfaces
.db 0x55				; bConfigurationValue
.db 0x00				; iConfiguration
.db 0x80				; bmAttributes (no remote wakeup)
.db 0x0f				; MaxPower (*2mA)
; interface0
.db 0x09				; bLength
.db 0x04        		; bDescriptorType
.db 0x00        		; bInterfaceNumber
.db 0x00        		; bAlternateSetting
.db 0x02        		; bNumEndpoints
.db 0x03        		; bInterfaceClass
.db 0x00        		; bInterfaceSubClass
.db 0x00        		; bInterfaceProcotol
.db 0x00        		; iInterface
; HID descriptor
.db hid_report-.		; bLength
.db 0x21				; HID descriptor type
.db 0x11,0x01			; bcdHID
.db 0					; bCountoryCode
.db 1					; bNumDescriptor
.db 0x22				; Report descriptor type
.db des_report_end-des_report,0x00			; bDescriptorLength
hid_report:
; Begin Descriptor: Endpoint1, Interface0, Alternate0
.db 0x07                ; bLength
.db 0x05        		; bDescriptorType
.db 0x81        		; bEndpointAddress (ep1, IN)
.db 0x03        		; bmAttributes (Bulk)
.db 0x40, 0x00  		; wMaxPacketSize (lsb first)
.db 0x05        		; bInterval
;Begin Descriptor: Endpoint2, Interface0, Alternate0
.db 0x07                ; bLength
.db 0x05        		; bDescriptorType
.db 0x02        		; bEndpointAddress (ep2, OUT)
.db 0x03        		; bmAttributes (Bulk)
.db 0x40, 0x00  		; wMaxPacketSize (lsb first)
.db 0x05        		; bInterval
conf_end:
string1:
NUMSTRING1 .equ str1_end-.
.db NUMSTRING1			; bLength
.db 0x03				; string descriptor
.db 'S',0,'N',0,'0',0,'0',0,'1',0			; string
str1_end:
string2:
NUMSTRING2 .equ str2_end-.
.db NUMSTRING2			; bLength
.db 0x03				; string descriptor
.db 'D',0,'E',0,'M',0,'O',0		; string
str2_end:
des_report:
.db 0x06, 0x00, 0xff	;Usage Page(Vendor-defined)
.db 0x09, 0x01       	;Usage
.db 0xa1, 0x01		 	;Collection(Application)
.db 0xa1, 0x00			;  Collection(Physical)
; report 1
.db 0x09, 0x01       	;    Usage
.db 0x75, 0x08		 	;    Report Size(8)
.db 0x95, 0x40		 	;    Report Count(0x40)
.db 0x26, 0xff, 0x00    ;    Logical Maximum(255)
.db 0x15, 0x00          ;    Logical Minmum(0)
.db 0x85, 0x01          ;    Report ID(1)
;.db 0x95, 0x01          ;    Report Count(1)
.db 0x09, 0x01          ;    Usage
.db 0x81, 0x02          ;    Input Data,variable,absolute
; report 2
.db 0x09, 0x01       	;    Usage
.db 0x75, 0x08		 	;    Report Size(8)
.db 0x95, 0x40		 	;    Report Count(0x40)
.db 0x26, 0xff, 0x00    ;    Logical Maximum(255)
.db 0x15, 0x00          ;    Logical Minmum(0)
.db 0x85, 0x02          ;    Report ID(2)
.db 0x95, 0x40          ;    Report Count(0x40)
.db 0x09, 0x01          ;    Usage
.db 0x91, 0x02          ;    Output Data,variable,absolute
.db 0xc0  				;  End Collection(Physical)
.db 0xc0  				;End Collection(Application)
des_report_end:


; 最后的SETUP PACAKGE:
; 82 06 00 22 01 00 50 00
; 82 06: GET_DESCRIPTOR, Recipient: Endpoint
; 22: wValue(H) REPORT(descriptor type)
; 00; wValue(L) 0(descriptor index)
; 01: wIndex(L) interface 1
; 50 00: report descriptor 的长度, 原本 HID descriptor中断bDescriptorLength是0x10
; host 跟据 0x10+0x40, 然后向设备发出这个REQUEST

; vim: filetype=asm51 tabstop=4

