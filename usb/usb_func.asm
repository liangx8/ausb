.include "c8051f320.h"
.include "uart.h"
.include "usb.h"



.area DATA (ABS)
ep0cmd:         .ds 8
cmint:			.ds 1
in1int:			.ds 1
out1int:		.ds 1

ep0_e0csr:		.ds 1
.area HOME (CODE)
init_usb:
	mov		EIE1,#0b00000010
	ret
usb0_int:
; use bank 3
	push	acc
	push	b
	push	EMI0CN
	push	dpl
	push	dph
	

	mov		EMI0CN, #1
	
	setb	rs0
	setb	rs1
	
	mov		a,#CMINT
	acall	uread
	mov		cmint,b
	mov		a,#IN1INT
	acall	uread
	mov		in1int,b
	mov		a,#OUT1INT
	acall	uread
	mov		out1int,b
	
	mov		a,cmint
	jnb		acc+RSTINT,1$
	mov		a,#0x10
	acall	checkpoint
	acall	ureset
1$:
	jnb		acc+SOF,11$
	mov		a,#0x1a
	acall	checkpoint
	; SOF
11$:
	mov		a,in1int
	jnb		acc+EP0,2$
	mov		a,#0x11
	acall	checkpoint
	acall	endpoint0
2$:
	mov		a,in1int
	jnb		acc+IN1,3$
	mov		a,#0x12
	acall	checkpoint
3$:
	mov		a,out1int
	jnb		acc+OUT1,4$
	mov		a,#0x13
	acall	checkpoint
4$:
	
	mov		a,#0xf0
	acall	checkpoint
	pop		dph
	pop		dpl
	pop		EMI0CN
	pop		b
	pop		acc
	pop		psw
	reti
ureset:
	mov		a,#POWER
	mov		b,#0x81
	acall	uwrite
	ret
endpoint0:
	mov		a,#INDEX
	clr		b			; target ep0
	acall	uwrite
	mov		a,#E0CSR
	acall	uread
	mov		ep0_e0csr,b
	mov		a,b
	acall	printhex
	mov		a,ep0_e0csr
	jnb		acc+SUEND,1$
	mov		a,#0x41
	acall	checkpoint
	mov		a,#E0CSR
	mov		b,#(1 << SSUEND)
	acall	uwrite
1$:

	mov		a,ep0_e0csr
	jnb		acc+STSTL,2$
	mov		a,#0x42
	acall	checkpoint
	mov		a,#E0CSR
	clr		b
	acall	uwrite
2$:
	mov		a,ep0_e0csr
	jnb		acc+OPRDY,3$
	ajmp	handle_incoming_packet
;	mov		a,#E0CSR
;	acall	uread
;	mov		a,b
;	ajmp	printhex
3$:
; 写0 字节
	mov		a,#0x40
	acall	checkpoint
	ret
handle_incoming_packet:
	mov		r0,#ep0cmd
	clr		a				; endpoint 0
	mov		r7,#8
	acall	fifo_iread

	mov		a,#E0CSR
	mov		b,#(1<<SOPRDY)
	acall	uwrite

;	mov		r1,#ep0cmd
;	mov		a,#8
;	acall	printbuf
	
;	mov		a,#E0CNT
;	acall	uread
;	mov		a,b
;	acall	printhex
	
	mov		a,ep0cmd+bmRequestType
	jb		acc.7,setup_data_in
	; setup data out
	mov		a,ep0cmd + bRequest
	cjne	a,#SET_ADDRESS,1$
	mov		a,#0x30
	acall	checkpoint
	ajmp	set_address
1$:
setup_data_in:
	mov		a,ep0cmd + bRequest
	cjne	a,#GET_DESCRIPTOR,1$
	ajmp	get_descriptors
1$:
	
	ret
set_address:
	mov		a,#FADDR
	mov		b,ep0cmd + wValue
	acall	uwrite
	mov		a,#E0CSR
	mov		b,#(1<<INPRDY)
	ajmp	uwrite
;   ret
get_descriptors:
	mov		a,ep0cmd + wValue+1			;low byte
	cjne	a,#DSC_DEVICE,1$			; 1
	mov		a,#0x20
	acall	checkpoint
;	mov		a,#E0CSR
;	mov		b,#(1<<SOPRDY)
;	acall	uwrite

	mov		dptr,#descriptor
	clr		a
	mov		r7,#18
	acall	fifo_cwrite
	mov		a,#E0CSR
	mov		b,#((1<<DATAEND) | (1<< INPRDY))
	ajmp	uwrite
	
1$:
	cjne	a,#DSC_CONFIG,2$			; 2
	mov		a,#0x21
	acall	checkpoint
;	mov		a,#E0CSR
;	mov		b,#(1<<SOPRDY)
;	acall	uwrite
	mov		dptr,#descriptor_cfg
	mov		a,ep0cmd + wLength
	mov		r7,#0x20
	clr		c
	subb	a,r7
	jnc		11$
	mov		r7,ep0cmd + wLength
11$:
	clr		a
	acall	fifo_cwrite
	mov		a,#E0CSR
	mov		b,#((1<<DATAEND) | (1<< INPRDY))
	ajmp	uwrite
2$:
	cjne	a,#DSC_STRING,3$			; 3
	mov		a,#0x22
	acall	checkpoint
;	mov		a,#E0CSR
;	mov		b,#(1<<SOPRDY)
;	acall	uwrite
	mov		a,ep0cmd + wValue
	acall	get_strdesc					; 拿到a中索引值指向的String descriptor
	clr		a
	acall	fifo_cwrite
	mov		a,#E0CSR
	mov		b,#((1<<DATAEND) | (1<< INPRDY))
	ajmp	uwrite
3$:
	cjne	a,#DSC_QUALIFIER,4$			; 6
	mov		a,#0x23
	acall	checkpoint
	mov		a,#E0CSR
	mov		b,#(1<<SDSTL)
;	acall	uwrite
;	mov		a,#E0CSR
;	mov		b,#((1<<DATAEND) | (1<< INPRDY))
	ajmp	uwrite
4$:
	cjne	a,#DSC_INTERFACE,5$			; 4
	mov		a,#0x24
	ajmp	checkpoint
5$:
	cjne	a,#DSC_ENDPOINT,6$			; 5
	mov		a,#0x25
	ajmp	checkpoint
6$:
;81 06 00 22 00 00 41 00
	cjne	a,#DSC_HIDREPORT,7$			; 5
	mov		a,#0x26 
	acall	checkpoint
	mov		dptr,#descriptor_hid_report
	clr		a
	mov		r7,#0x35
	acall	fifo_cwrite
	mov		a,#E0CSR
	mov		b,#((1<<DATAEND) | (1<< INPRDY))
	acall	uwrite
7$:
	mov		r1,#ep0cmd
	mov		a,#8
	ajmp	printbuf
	ret
; 要求不能a超过127
get_strdesc:
	mov		dptr,#strdesc
	rl		a
	mov		r7,a
	movc	a,@a+dptr
	mov		r6,a
	mov		a,r7
	inc		a
	movc	a,@a+dptr
	mov		dpl,a
	mov		dph,r6
	clr		a
	movc	a,@a+dptr
	mov		r7,a
	ret
;*******************************************************
; usb_start
;*******************************************************
usb_start:
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
	add		a,#0x20			; end point index

	mov		USB0ADR,a
4$:
	mov		a,USB0ADR
	jb		acc.7,4$
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