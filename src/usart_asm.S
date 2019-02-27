	.syntax unified
	.text
	.global usart1_hex,hex_str,usart1_puts,usart1_putsz


	.func usart1_hex
	.thumb_func
	.type usart1_hex, %function
	.align
usart1_hex:
	bx		lr
	.size usart1_hex,. - usart1_hex
	.endfunc

	.align
hex_table:
	.ascii "0123456789abcdef"


	.func hex_str
	.thumb_func
	.type hex_str, %function
	.align
hex_str:
	push	{r4,lr}
	adr		r4,hex_table
	subs	r0,#1
	adds	r3,r0,r2			@ buf 尾 r0 buf 首
1:
	and		r2,r1,#0x0f
	ldrb	r2,[r4,r2]
	lsrs	r1,r1,#4
	strb	r2,[r3],#-1			@ r3 -1
	cmp		r3,r0
	bne		1b
	
	pop		{r4,pc}
	.size hex_str,. - hex_str
	.endfunc

	.func usart1_putsz
	.thumb_func
	.type usart1_putsz, %function
	.align
usart1_putsz:
	bx		lr
	.size usart1_putsz,. - usart1_putsz
	.endfunc


	.func usart1_puts
	.thumb_func
	.type usart1_puts, %function
	.align
usart1_puts:
	bx		lr
	.size usart1_puts,. - usart1_puts
	.endfunc

	.pool
	


	/*
	push 相当于 stmdb  decrease before 入栈前减地址
	pop 相当于 ldmia   increase after  出栈后加地址
	*/
