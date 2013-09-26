;=============================
;	16-bit multiply
;	Tim Paterson
;=============================
MUL16	ld	hl,0
MUL_HLBC_DE
	ld	a,b
	ld	b,0x11
	jr	.l1
.l2	jr	nc,.l3
	add	hl,de
.l3	rr	h
	rr	l
.l1	rra
	rr	c
	djnz	.l2
	ld	b,a
	ret

;=============================
;	16-bit divide
;	Tim Paterson
;=============================
;Делит HLBC на DE
;на выходе HL - остаток, BC - частное
DIV16	ld	hl,0
DIV_HLBC_DE
	ld	a,b
	ld	b,0x10
	rl	c
	rla
.l1	rl	l
	rl	h
	jr	c,.l2
	sbc	hl,de
	jr	nc,.l3
	add	hl,de
.l3	ccf
.l4	rl	c
	rla
	djnz	.l1
	ld	b,a
	ret
.l2	or	a
	sbc	hl,de
	jr	.l4
