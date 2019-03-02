	.syntax unified
	.text
	.global usart1_put_byte,usart1_puts,usart1_hex
/*
struct u1
struct {
	uint16_t in;
	uint8_t head;
	uint8_t tail;
	uint8_t buf[256];

}u1;
*/
	.equ	in,   0
	.equ	head, 2
	.equ	tail, 3
	.equ	buf,  4
	.equ	BB_USART1_CR1,  0x42270180
/**
 * 把一字节放到缓存中，如果缓存满(MAX - 1)，就会阻塞
 * r0, one byte
 */
	.func usart1_put_byte
	.thumb_func
	.type usart1_put_byte, %function
	.align
usart1_put_byte:
	ldr		r1,=u1
	adds	r3,r1,#buf
	ldrb	r2,[r1,#head]
	strb	r0,[r3,r2]
	adds	r2,r2,#1
	uxtb	r2,r2
1:
	ldrb	r3,[r1,#tail]
	cmp		r2,r3
	beq		1b				@ 缓存已经满？Y 跳1阻塞，N 往下走
	strb	r2,[r1,#head]
 @ BITBAND(USART1->CR1)->bit[USART_CR1_TXEIE_pos]=1
	ldr		r2,=#BB_USART1_CR1
	movs	r3,#1
	strb	r3,[r2,#28]

	bx		lr
	.size usart1_put_byte, . - usart1_put_byte
	.endfunc

	.func usart1_puts
	.thumb_func
	.type usart1_puts, %function
	.align
usart1_puts:
	cbz		r1,2f
	push	{r4,r5,lr}
	add		r5,r0,r1
	mov		r4,r0
@	ldr		r1,=u1
1:
	ldrb	r0,[r4],#1
	bl		usart1_put_byte
	cmp		r4,r5
	bne		1b
	pop		{r4,r5,pc}
2:
	bx		lr
	.size usart1_puts, . - usart1_puts
	.endfunc



	.func usart1_hex
	.thumb_func
	.type usart1_hex, %function
	.align
usart1_hex:
	push	{r4,r5,r6,lr}
	mov		r4,r0
	movs	r5,#4
	adr		r6,#hex_table
1:
	lsrs	r0,r4,#4
	ands	r0,r0,#0x0f
	ldr		r0,[r6,r0]
	bl		usart1_put_byte
	ands	r0,r4,#0x0f
	ldr		r0,[r6,r0]
	bl		usart1_put_byte
	movs	r0,#' '
	bl		usart1_put_byte
	lsrs	r4,r4,#8
	subs	r5,#1
	bne		1b
	pop		{r4,r5,r6,pc}
	.size usart1_hex,. - usart1_hex
	.endfunc
	.pool
	.align
hex_table:
	.ascii "0123456789abcdef"




	/*
	push 相当于 stmdb  decrease before 入栈前减地址
	pop 相当于 ldmia   increase after  出栈后加地址
	*/
