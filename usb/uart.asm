.include "c8051f320.h"
.include "uart.h"
LED3			.equ	P1.2

.area DATA (ABS)
buf_start:		.ds 1
buf_end:		.ds 1
.area HOME (CODE)

mov_pointer:
	push	acc
	mov		a,buf_end
	inc		a
	cjne	a,buf_start,1$
	setb	LED3
	sjmp	2$
1$:
	clr		LED3
	mov		buf_end,a
2$:
	pop		acc
	ret
init_uart:
	; 8 bit ignore stop, ignore 9th bit
	mov		SCON0,#0b00010000
	; 115200 baudrates
	mov		TH1  ,#0xcc
	mov		TCON ,#0b01000000
	mov		TMOD ,#0b00100000
	mov		CKCON,#0b11111100
	mov		XBR0, #0x01
	ret
put_xbuf_to_uart:
;	mov		EMI0CN,#1


	mov		a,buf_start
	cjne	a,buf_end,101$
	ret
101$:
	inc		buf_start
	mov		r0,a
	movx	a,@r0
	mov		SBUF0,a
102$:
	jbc		TI0,103$
	sjmp	102$
103$:
	cjne	a,#0x0a,put_xbuf_to_uart
	mov		SBUF0,#0x0d
104$:
	jbc		TI0,put_xbuf_to_uart
	sjmp	104$

uart_pipo:
	jbc		RI0,117$
	ret
117$:
	mov		r7,SBUF0
	mov		SBUF0,r7
	acall	redirect
101$:
	jbc		TI0,118$
	sjmp	101$
118$:
	ret
redirect:
	clr		a
	jmp		@a+dptr
printhex:
	mov		r7,a
	swap	a
	anl		a,#0x0f
	mov		dptr,#hex_table
	movc	a,@a+dptr
	mov		r0,buf_end
	acall	mov_pointer
	movx	@r0,a
	mov		a,r7
	anl		a,#0x0f
	;mov		dptr,#hex_table
	movc	a,@a+dptr
	mov		r0,buf_end
	acall	mov_pointer
	movx	@r0,a
	ret
fdcr:
	mov		r0,buf_end
	acall	mov_pointer
	mov		a,#0x0a
	movx	@r0,a
	ret
checkpoint:
	mov		r6,a
	acall	fdcr
	mov		dptr,#str_cp
	acall	printstr
	mov		a,r6
	sjmp	printhex
	
; dptr 字串地址
printstr:
	clr		a
	movc	a,@a+dptr
	inc		dptr
	mov		r7,a
100$:
	clr		a
	movc	a,@a+dptr
	inc		dptr
	mov		r0,buf_end
	acall	mov_pointer
	movx	@r0,a
	djnz	r7,100$
	ret
; [in]r1 数据地址
; [in]a 长度
printbuf:
	mov		r6,a
	acall	fdcr
100$:
	mov		a,@r1
	inc		r1
	acall	printhex
	mov		r0,buf_end
	acall mov_pointer
	mov		a,#' '
	movx	@r0,a
	djnz	r6,100$
	ret
hex_table:
	.ascii	'0123456789abcdef'
str_cp:
	.db 1
	.ascii 'X'