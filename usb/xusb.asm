; printbuf 可能有错误，


.include "c8051f320.h"
.include "usb.inc"
LED1			.equ	P1.0
LED2			.equ	P1.1
LED3			.equ	P1.2
LED4			.equ	P3.0


HID_REPORT_SIZE	.equ	0x35

; }}}

.area BITDATA1 (ABS,BIT)
input_flag:		.ds 1		;1 显示 input_char, 0 不显示
echo_broke:		.ds	1		;1 uart的输出中断链已经断开
new_income:		.ds 1		; 

usb_en:			.ds	1
full_buf:		.ds 1
; usb flag
configured:		.ds 1


.area XDATA (ABS)
.area DSEG (ABS,DATA)
.org 0x30
main_loop_cnt:	.ds 1

;===================================================================
; uart
buf_start_h:	.ds 1
buf_start:		.ds 1
buf_end:		.ds 1

input_char:		.ds 1
; end uart
;===================================================================


;===================================================================
; usb
ep0cmd:         .ds 8
m_cmint:		.ds 1
m_in1int:		.ds 1
m_out1int:		.ds 1
ep0_e0csr:		.ds 1

ep0_status:		.ds 1
ep1_status:		.ds 1
dev_status:		.ds 1
tx_size:		.ds 1

c_ptr:			.ds 2

; usb end
;===================================================================


.area HOME (ABS,CODE)
	ljmp	main			; 0x0000
;	.ds	1
	reti
	.ds	7					; 0x0003
	reti
.org 0x000b
	.ds	7					; 0x000b
	reti
.org 0x0013
	reti
.org 0x001b
	.ds	7
	reti
.org 0x0023
	push	psw					; 0x0023
	ljmp	uart0_int
	reti
.org 0x002b
	reti
.org 0x0033
	reti
.org 0x003b
	reti
.org 0x0043
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
	clr		usb_en

	acall	init_io
	setb	LED1
	setb	LED2
	setb	LED3
	clr		LED4
	acall	init
	acall	init_clk
	acall	init_uart
	acall	init_timer
	acall	init_interrupt

	acall	delay
	clr		LED2
	; clear buf
	mov		EMI0CN,#0
	mov		r0,#0
1$:
	clr		a
	movx	@r0,a
	inc		r0
	mov		a,r0
	jnz     1$

	acall	power_up_echo
	clr		LED3
	clr		RI0
	clr		TI0
	setb	echo_broke
	clr		full_buf
	clr		new_income
	clr		input_flag
	setb	EA
	mov		dptr,#str_cp
	acall	printstr
	mov		a,#0x55
	acall	put_hex
main_loop:
	acall	handler
	jnb		TF0,100$
	clr		TF0
	djnz	main_loop_cnt,100$
	cpl		LED1
	jnb		usb_en,1$
	cpl		LED2
1$:
	mov		main_loop_cnt,#50
100$:
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
short_delay:
	mov		r7,#0xff
	djnz	r7,.
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
;	mov		c,echo_broke
;	mov		LED3,c
	jbc		new_income,1$
	ret
1$:
	mov		a,input_char
	cjne	a,#'1',2$
	jb		usb_en,4$
	setb	usb_en
	acall	usb_start
	mov		dptr,#str_usb_start
	acall	printstr
	ajmp	feedline
2$:
	cjne	a,#'2',3$
	clr		usb_en
	clr		LED3
	mov		USB0XCN,#0
	mov		dptr,#str_usb_stop
	acall	printstr
	ajmp	feedline
3$:
	cjne	a,#'3',4$
	mov		r1,#ep0cmd
	mov		r5,#8
	ajmp	printbuf
4$:
	ret
str_usb_start:
	.db    9
	.ascii 'USB start'
str_usb_stop:
	.db    8
	.ascii 'USB stop'
;===================================================================
; uart cseg
inc_buf_start:
	inc		buf_start
	mov		a,buf_start
	jnz		1$
	mov		a,buf_start_h
	inc		a
	anl		a,#0x03
	mov		buf_start_h,a
1$:
	ret
inc_buf_end:
	inc		buf_end
	mov		a,buf_end
	jnz		1$
	mov		a,EMI0CN
	inc		a
	anl		a,#0x03
	mov		EMI0CN,a
1$:
	ret
uart0_int:
	push	acc
	setb	rs0
	clr		rs1
	jbc		TI0,uart_out_done
	jbc		RI0,uart_in
uart_int_exit:
	pop		acc
	pop		psw
	reti
uart_in:
	mov		a,SBUF0
	mov		input_char,a
	setb	new_income
	jbc		echo_broke,go_input_char
	setb	input_flag
	sjmp	uart_int_exit
go_input_char:
	mov		SBUF0,input_char
	sjmp	uart_int_exit
uart_out_done:
; 优先显示串口输入
	jbc		input_flag,go_input_char
; 输出buf中的内容
	jbc		full_buf,1$
	mov		a,buf_start
	cjne	a,buf_end,1$
	mov		a,EMI0CN
	cjne	a,buf_start_h,1$
	setb	echo_broke
	sjmp	uart_int_exit
1$:
	;inc		buf_start
	acall	inc_buf_start
	mov		a,buf_start
	mov		r0,a
	push 	EMI0CN
	mov		EMI0CN,buf_start_h
	movx	a,@r0
	pop		EMI0CN
	mov		SBUF0,a
	sjmp	uart_int_exit
init_uart:
	; 8 bit ignore stop, ignore 9th bit
	mov		SCON0,#0b00010000
	; 115200 baudrates
	mov		TH1  ,#0xcc
	mov		TCON ,#0b01000000
	mov		TMOD ,#0b00100000
	mov		CKCON,#0b11111100
	mov		XBR0, #0x01
	mov		buf_end,a
	mov		buf_start,a
	clr		full_buf
	ret
; r7 char to buf
pipo_in:
	jb		full_buf,uart_trigger		; buffer full
	;inc		buf_end
	acall	inc_buf_end
	mov		a,buf_end
	cjne	a,buf_start,2$
	mov		a,EMI0CN
	cjne	a,buf_start_h,2$
	setb	full_buf
	setb	LED3
2$:
	mov		r0,a
	mov		a,r7
	movx	@r0,a
uart_trigger:
	jbc		echo_broke,1$
	ret
1$:
	;inc		buf_start
	acall	inc_buf_start
	mov		a,buf_start
	mov		r0,a
	push	EMI0CN
	mov		EMI0CN,buf_start_h
	movx	a,@r0
	pop		EMI0CN
	clr		full_buf
	mov		SBUF0,a
2$:
	ret
; a
checkpoint:
	mov		r5,a
	acall	feedline
	mov		r7,#'!'
	acall	pipo_in
	mov		a,r5
	ajmp	put_hex
	
; r1 address
; r5 count
printbuf:
	acall	feedline
1$:
	mov		a,@r1
	acall	put_hex
	inc		r1
	djnz	r5,1$
	ret
feedline:
	mov		r7,#'\n'
	acall	pipo_in
	mov		r7,#'\r'
	acall	pipo_in
	ret
; [in] a 
put_hex:
	mov		dptr,#hex_table
	mov		r6,a
	swap	a
	anl		a,#0x0f
	movc	a,@a+dptr
	mov		r7,a
	acall	pipo_in
	mov		a,#0x0f
	anl		a,r6
	movc	a,@a+dptr
	mov		r7,a
	acall	pipo_in
	mov		r7,#' '
	ajmp	pipo_in
; dptr string pointer
printstr:
	clr		a
	movc	a,@a+dptr
	mov		r6,a
1$:
	inc		dptr
	clr		a
	movc	a,@a+dptr
	mov		r7,a
	acall	pipo_in
	djnz	r6,1$
	ret
hex_table:
	.ascii	'0123456789abcdef'
str_cp:
	.db 2
	.ascii 'CP'

; uart code end
;===================================================================
;===================================================================
; usb code

init_interrupt:
	mov		EIE1,#0b00000010	; usb0 interrupt
	setb	ES0					; uart0 interrupt
	setb	PS0					; uart0 priority
	ret
usb0_int:
; use bank 2
	push	acc
	push	b
	push	dpl
	push	dph
	clr		rs0
	setb	rs1

	mov		a,#CMINT
	acall	uread
	mov		m_cmint,b
	mov		a,#IN1INT
	acall	uread
	mov		m_in1int,b
	mov		a,#OUT1INT
	acall	uread
	mov		m_out1int,b

	mov		a,m_cmint
	jnb		acc+RSTINT,1$
	mov		a,#0x10
	acall	checkpoint
	acall	ureset
	sjmp	999$
1$:
	jnb		acc+SUSINT,11$
	mov		a,#0x14
	acall	checkpoint
	sjmp	999$
11$:
	mov		a,m_in1int
	jnb		acc+EP0,2$
	mov		a,#0x11
	acall	checkpoint
	acall	endpoint0
	sjmp	999$
2$:
; bus hound 分析，host会在clear_feature后发一个IN1  的request,
	jnb		acc+IN1,3$
	mov		a,#0x12
	acall	checkpoint
	acall	force_stall
	sjmp	999$
3$:
	mov		a,m_out1int
	jnb		acc+OUT2,4$
	mov		a,#0x13
	acall	checkpoint
	acall	force_stall
	sjmp	999$
4$:

	mov		a,m_cmint
	acall	put_hex
	mov		a,m_in1int
	acall	put_hex
	mov		a,m_out1int
	acall	put_hex
	mov		a,#0x7f
	acall	checkpoint
999$:
	pop		dph
	pop		dpl
	pop		b
	pop		acc
	pop		psw
	reti
ureset:
	mov		a,#POWER
	mov		b,#0x81
	mov		ep0_status,#EP_IDLE
	mov		ep1_status,#EP_IDLE
	ajmp	uwrite

endpoint0:
	mov		a,#INDEX
	clr		b			; target ep0
	acall	uwrite
	mov		a,#E0CSR
	acall	uread
	mov		ep0_e0csr,b

	mov		a,b
	jnb		acc+STSTL,1$
	mov		a,#0x42
	acall	checkpoint
	mov		ep0_status,#EP_IDLE
	mov		a,#E0CSR
	clr		b
	ajmp	uwrite
1$:

	jnb		acc+SUEND,2$
	mov		a,#0x41
	acall	checkpoint
	mov		ep0_status,#EP_IDLE
	mov		a,#E0CSR
	mov		b,#((1 << SSUEND) | (1<<DATAEND))
	acall	uwrite
;	mov		a,ep0_e0csr
2$:

	mov		a,#EP_ADDRESS
	cjne	a,ep0_status,3$
	mov		a,#0x1f
	acall	checkpoint
	mov		ep0_status,#EP_IDLE
	mov		a,#FADDR
	mov		b,ep0cmd + wValue
	acall	uwrite
	mov		a,#E0CSR
;	mov		b,#((1<<SOPRDY)|(1<<DATAEND))  ; refer to http://community.silabs.com/t5/8-bit-MCU/when-writing-to-FADDR/td-p/63747
                                           ; DATAEND is re
	mov		b,#(1<<SOPRDY)
	acall	uwrite
3$:
	mov		a,#EP_IDLE
	cjne	a,ep0_status,4$

	mov		a,ep0_e0csr
	jnb		acc+OPRDY,4$
	acall	handle_incoming_packet
	
4$:
	mov		a,#EP_TX
	cjne	a,ep0_status,5$
	mov		a,#E0CSR
	mov		b,#(1<<SOPRDY)
	acall	uwrite
	clr		a					; set fifo address to endpoint0
	acall	fifo_cwrite
	mov		a,#E0CSR
	mov		b,#((1<<DATAEND)|(1<<INPRDY))
	acall	uwrite
	mov		ep0_status,#EP_IDLE
	mov		a,tx_size
	ajmp	put_hex
5$:
	mov		a,ep0_e0csr
	acall	put_hex
	mov		a,#0x40
	ajmp	checkpoint
	;ret
handle_incoming_packet:
	mov		r0,#ep0cmd
	clr		a				; endpoint 0
	mov		r7,#8
	acall	fifo_iread

;	mov		a,#E0CSR
;	mov		b,#(1<<SOPRDY)
;	acall	uwrite

	mov		r1,#ep0cmd
	mov		r5,#8
	acall	printbuf

;	acall	short_delay


	mov		a,ep0cmd+bmRequestType
	anl		a,#0x7f
	; 如果 (bmRequestType & 0x7f) == 0x21 就是HID 的专门请求,参考 HID1_11.pdf 7.2 Class-Specific Requests
	cjne	a,#DSC_HID,standard_request
	; Class-Specific Request(for HID)
	mov		a,ep0cmd + bRequest
	cjne	a,#GET_REPORT,1$
	mov		a,#0x50
	acall	force_stall
	ajmp	checkpoint
1$:
	cjne	a,#SET_REPORT,2$
	mov		a,#0x51
	ajmp	checkpoint
2$:
	cjne	a,#GET_IDLE,3$
	mov		a,#0x52
	ajmp	checkpoint
3$:
	cjne	a,#SET_IDLE,4$
	mov		a,#0x53
	acall	checkpoint
	ajmp	set_idle
4$:
	cjne	a,#GET_PROTOCOL,5$
	mov		a,#0x54
	ajmp	checkpoint
5$:
	cjne	a,#SET_PROTOCOL,6$
	mov		a,#0x55
	ajmp	checkpoint
6$:
	acall	force_stall
	mov		a,#0x56
	ajmp	checkpoint
standard_request:
	mov		a,ep0cmd+bmRequestType
	jb		acc.7,setup_data_in
	; setup data out
	mov		a,ep0cmd + bRequest
	cjne	a,#SET_ADDRESS,1$
	mov		a,#0x30
	acall	checkpoint
	ajmp	set_address
1$:
	cjne	a,#SET_CONFIGURATION,2$
	mov		a,#0x31
	acall	checkpoint
	ajmp	set_configuration
2$:
	cjne	a,#CLEAR_FEATURE,3$
	mov		a,#0x32
	acall	checkpoint
	ajmp	clear_feature
3$:
	ret

setup_data_in:
	mov		ep0_status,#EP_TX
	mov		a,ep0cmd + bRequest
	cjne	a,#GET_DESCRIPTOR,20$
	acall	get_descriptors
	mov		a,#EP_STALL
	cjne	a,ep0_status,10$
20$:
	cjne	a,#GET_STATUS,30$
	mov		a,#0x35
	ajmp	checkpoint
30$:
	acall	force_stall
	mov		a,#0x56
	ajmp	checkpoint
10$:
	ret

clear_feature:
	jb		configured,2$
1$:
	ajmp	force_stall
2$:
	mov		a,ep0cmd + bmRequestType
	cjne	a,#IN_ENDPOINT,1$
	mov		a,ep0cmd + wIndex
	cjne	a,#IN_EP1,3$
	mov		a,#0x33
	acall	checkpoint
	
	mov		a,#INDEX
	mov		b,#1
	acall	uwrite
	mov		a,#EINCSRL
	mov		b,#1<<IN_CLRDT
	acall	uwrite
	mov		ep1_status,#EP_IDLE
3$:	

	mov		a,#INDEX
	clr		b				; RESET endpoint to 0
	acall	uwrite
	mov		a,#E0CSR
	mov		b,#((1<<SOPRDY)|(1 << DATAEND))
	ajmp	uwrite
set_address:
	mov		ep0_status,#EP_ADDRESS
;	mov		a,#FADDR
;	mov		b,ep0cmd + wValue
;	acall	uwrite
	mov		a,#E0CSR
	mov		b,#((1<<SOPRDY)|(1 << DATAEND))
	ajmp	uwrite
;   ret
set_configuration:
	setb	configured
	mov		a,#E0CSR
	mov		b,#((1<<SOPRDY)|(1 << DATAEND))
	;mov		ep0_status,#EP_IDLE
	ajmp	uwrite
;	ret
get_descriptors:
	mov		a,ep0cmd + wValue+1			;low byte
	cjne	a,#DSC_DEVICE,1$			; 1
	mov		a,#0x20
	acall	checkpoint

	mov		c_ptr,#descriptor_device
	mov		c_ptr+1,#descriptor_device >> 8
	mov		tx_size,#18
	ret
1$:
	cjne	a,#DSC_CONFIG,2$			; 2
	mov		a,#0x21
	acall	checkpoint
;	mov		a,#E0CSR
;	mov		b,#(1<<SOPRDY)
;	acall	uwrite
	mov		c_ptr,#descriptor_cfg
	mov		c_ptr+1,#descriptor_cfg >> 8
	mov		tx_size,#0x29
	mov		a,ep0cmd + wLength
	cjne	a,tx_size,. + 3
	jnc		11$
	mov		tx_size,a
11$:
	ret
2$:
	cjne	a,#DSC_STRING,3$			; 3

	mov		a,#0x22
	acall	checkpoint
;	mov		a,#E0CSR
;	mov		b,#(1<<SOPRDY)
;	acall	uwrite
	mov		a,ep0cmd + wValue
	acall	get_strdesc					; 拿到a中索引值指向的String descriptor
	ret
3$:
	cjne	a,#DSC_QUALIFIER,4$			; 6
	mov		a,#0x23
	acall	checkpoint
	mov		ep0_status,#EP_STALL
	ret
4$:
	cjne	a,#DSC_INTERFACE,5$			; 4
	mov		ep0_status,#EP_STALL
	mov		a,#0x24
	ajmp	checkpoint
5$:
	cjne	a,#DSC_ENDPOINT,6$			; 5
	mov		ep0_status,#EP_STALL
	mov		a,#0x25
	ajmp	checkpoint
6$:
;81 06 00 22 00 00 75 00
	cjne	a,#DSC_HIDREPORT,7$			; 5
	mov		a,#0x26 
	acall	checkpoint
	mov		c_ptr,#descriptor_hid_report
	mov		c_ptr+1,#descriptor_hid_report>>8
	mov		tx_size,#HID_REPORT_SIZE
	ret
7$:
	;mov		r1,#ep0cmd
	;mov		a,#8
	;ajmp	printbuf
	ret
force_stall:
	mov		a,#INDEX
	clr		b
	acall	uwrite
	mov		ep0_status,#EP_STALL
	mov		a,#E0CSR
	mov		b,#1<<SDSTL
	ajmp	uwrite
set_idle:
	mov		a,#EP_STALL
	cjne	a,ep0_status,1$
	ret
1$:
	mov		b,#((1<<DATAEND)|(1<<SOPRDY))
	mov		a,#E0CSR
	ajmp	uwrite

; 要求不能a超过127
get_strdesc:
	mov		dptr,#strdesc
	rl		a
	mov		r7,a
	movc	a,@a+dptr
	mov		c_ptr+1,a
	mov		a,r7
	inc		a
	movc	a,@a+dptr
	mov		c_ptr,a

	mov		dpl,c_ptr
	mov		dph,c_ptr+1
	clr		a
	movc	a,@a+dptr
	mov		tx_size,a
	ret
;*******************************************************
; usb_start
;*******************************************************
usb_start:
	clr		configured
	mov		ep0_status,#EP_IDLE
	mov		ep1_status,#EP_IDLE
	mov		a,#POWER
	mov		b,#8
	acall	uwrite
	mov		a,#IN1IE
	mov		b,#0x07			; enable all IN endpoint interrupts
	acall	uwrite
	mov		a,#OUT1IE
	mov		b,#0x07			; enable all OUT endpoint interrupts
	acall	uwrite
	mov		a,#CMIE
	mov		b,#0x07			; enable all common interrupts
	acall	uwrite
; 注意有以下的修改，
	mov		USB0XCN,#0xe0	; 原来是0B110000, 和接下来一行
	;mov		USB0XCN,#0b11100000

	mov		a,#CLKREC
	mov		b,#0x89         ; 原来是 0X80
	acall	uwrite

	mov		a,#POWER
	mov		b,#1			; 原来是0
	acall	uwrite	
	ret

	
; function uwrite,uread
; [in] a,addr
; [out] b value
uread:
	setb	acc.7
	mov		USB0ADR,a
1$:
	mov		a,USB0ADR
	jb		acc.7,1$
	mov		b,USB0DAT
	ret
; [in] a addr
; [in] b data
uwrite:
	setb	acc.7
	mov		USB0ADR,a
1$:
	mov		a,USB0ADR
	jb		acc.7,1$
	mov		USB0DAT,b
	ret
; [in] r0 ram address
; [in] a endpoint number 0,1,2
; [in] r7 length of data
fifo_iread:
	add		a,#0x20
	mov		USB0ADR,a
	orl		a,#0b11000000
	mov		USB0ADR,a
fire_1:
	mov		a,USB0ADR
	jb		acc.7,fire_1
	mov		a,USB0DAT
	mov		@r0,a
	inc		r0
	djnz	r7,fire_1
	mov		USB0ADR,#0
	ret
; [in] dptr code address
; [in] a endpoint number 0,1,2
; [r7] length
fifo_cwrite:
	mov		dpl,c_ptr
	mov		dph,c_ptr+1
	add		a,#0x20			; end point index

	mov		USB0ADR,a
4$:
	mov		a,USB0ADR
	jb		acc.7,4$
	mov		r7,tx_size
3$:

	clr		a
	movc	a,@a+dptr
	inc		dptr
	mov		USB0DAT,a
2$:
	mov		a,USB0ADR
	jb		acc.7,2$
	djnz	r7,3$
	ret

; usb code end
;===================================================================


;===================================================================
; usb descriptors data
descriptor_device:
.db   18                        ; bLength
.db   0x01                      ; bDescriptorType
.db   0x10, 0x01                ; bcdUSB (lsb first)
.db   0x00                      ; bDeviceClass
.db   0x00                      ; bDeviceSubClass
.db   0x00                      ; bDeviceProtocol
.db   EP0_PACKET_SIZE           ; bMaxPacketSize0
.db   0x89, 0x19                ; idVendor (lsb first)
.db   0x64, 0x00                ; idProduct (lsb first)
.db   0x00, 0x00                ; bcdDevice (lsb first)
.db   0x01                      ; iManufacturer
.db   0x02                      ; iProduct
.db   0x03                      ; iSerialNumber
.db   0x01                      ; bNumConfigurations

descriptor_cfg:

.db   0x09                      ; Length
.db   0x02                      ; Type
.db   0x29, 0x00                ; TotalLength (lsb first) 9 + 9 + 9 + 7 +7
.db   0x01                      ; NumInterfaces
.db   0x01                      ; bConfigurationValue
.db   0x04                      ; iConfiguration
.db   0x80                      ; bmAttributes (no remote wakeup)
.db   0x20                      ; MaxPower (*2mA)

   ; Begin Descriptor: Interface0, Alternate0
.db   0x09                      ; bLength
.db   0x04                      ; bDescriptorType
.db   0x00                      ; bInterfaceNumber
.db   0x00                      ; bAlternateSetting
.db   0x02                      ; bNumEndpoints
.db   0x03                      ; bInterfaceClass
.db   0x00                      ; bInterfaceSubClass
.db   0x00                      ; bInterfaceProcotol
.db   0x05                      ; iInterface
; HID Descriptor
.db   9							; bLength
.db   0x21						; bDescriptorType
.db   0x01,0x01					; bcdHID
.db   0							; bCountryCode
.db   1							; bNumDescriptors
.db   0x22						; bDescriptorType
.db   HID_REPORT_SIZE,0x00		; wDescriptorLength(report)
; IN endpoint1
.db   7							; bLength
.db   5							; bDescriptorType
.db   0x81						; bEndpointAddress
.db   0x03						; bmAttributes(Interrupt)
.db   0xff & EP1_PACKET_SIZE,EP1_PACKET_SIZE>>8		; MaxPacketSize
.db   10						; bInterval
; OUT endpoint1
.db   0x07                      ; bLength
.db   0x05                      ; bDescriptorType
.db   0x02                      ; bEndpointAddress
.db   0x03                      ; bmAttributes
.db   0xff & EP2_PACKET_SIZE,EP2_PACKET_SIZE>>8		; MaxPacketSize (LITTLE ENDIAN)
.db   10                        ; bInterval


; 53 = 0x35
descriptor_hid_report:
.db    0x06, 0x00, 0xff              ; USAGE_PAGE (Vendor Defined Page 1)
.db    0x09, 0x01                    ; USAGE (Vendor Usage 1)
.db    0xa1, 0x01                    ; COLLECTION (Application)
.db    0x85, 0x01                    ;   REPORT_ID (1)
.db    0x95, 0x40                    ;   REPORT_COUNT (64)
.db    0x75, 0x08                    ;   REPORT_SIZE (8)
.db    0x26, 0xff, 0x00              ;   LOGICAL_MAXIMUM (255)
.db    0x15, 0x00                    ;   LOGICAL_MINIMUM (0)
.db    0x09, 0x01                    ;   USAGE (Vendor Usage 1)
.db    0x91, 0x02                    ;   OUTPUT (Data,Var,Abs)
.db    0x85, 0x02                    ;   REPORT_ID (2)
.db    0x95, 0x40                    ;   REPORT_COUNT (64)
.db    0x75, 0x08                    ;   REPORT_SIZE (8)
.db    0x26, 0xff, 0x00              ;   LOGICAL_MAXIMUM (255)
.db    0x15, 0x00                    ;   LOGICAL_MINIMUM (0)
.db    0x09, 0x01                    ;   USAGE (Vendor Usage 1)
.db    0x81, 0x02                    ;   INPUT (Data,Var,Abs)
.db    0x85, 0x03                    ;   REPORT_ID (3)
.db    0x95, 0x01                    ;   REPORT_COUNT (1)
.db    0x75, 0x08                    ;   REPORT_SIZE (8)
.db    0x26, 0xff, 0x00              ;   LOGICAL_MAXIMUM (255)
.db    0x15, 0x00                    ;   LOGICAL_MINIMUM (0)
.db    0x09, 0x01                    ;   USAGE (Vendor Usage 1)
.db    0xb1, 0x02                    ;   FEATURE (Data,Var,Abs)
.db    0xc0                          ; END_COLLECTION

strdesc:
.dw locale_zone,manufacturer,product,serial_number,configuration,interface

locale_zone:
.db	  4					; Length
.db   3					; Type
.db   9,4				; 第一个string descriptor,定义国家地区的代码



manufacturer:
.db	8					;bLength
.db	 0x03				; Type
.db	'X',0
.db	'X',0
.db	'D',0

product:
.db	16				;bLength
.db	 0x03				; Type
.db	'P',0
.db	'r',0
.db	'o',0
.db	'd',0
.db	'u',0
.db	'c',0
.db	't',0
serial_number:
.db	20				;bLength
.db	 0x03				; Type
.db	'S',0
.db	'N',0
.db	'N',0
.db	'6',0
.db	'4',0
.db	'8',0
.db	'9',0
.db	'1',0
.db	'9',0

configuration :
.db	28				;bLength
.db	 0x03				; Type
.db	'C',0
.db	'o',0
.db	'n',0
.db	'f',0
.db	'i',0
.db	'g',0
.db	'u',0
.db	'r',0
.db	'a',0
.db	't',0
.db	'i',0
.db	'o',0
.db	'n',0

interface:
.db	20				;bLength
.db	 0x03				; Type
.db	'I',0
.db	'n',0
.db	't',0
.db	'e',0
.db	'r',0
.db	'f',0
.db	'a',0
.db	'c',0
.db	'e',0
; usb descriptors data end
;===================================================================
