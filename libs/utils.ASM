;-----------T--------------------------------------------------¬
;¦ PRNUM    ¦ В L-число, в BC-адрес в памяти                   ¦
;¦ PRNUM0   ¦ В HL-число, в BC-адрес в памяти                  ¦
;¦          ¦ Регистры HL,DE,IX не изменяются                  ¦
;+----------+--------------------------------------------------+
;¦Пребразование 8-ми и 16-ти битных чисел в текстовый формат в ¦
;¦системе DEC/HEX (переменная HEXDEC=0 или HEXDEC="#")         ¦
;L--------------------------------------------------------------

PRNUM		push de
		ld   e,2
		ld   h,0
		jr   PRNUM1
PRNUM0		push de
		ld   e,4
PRNUM1		push hl
		ld   a,(HEXDEC_PRNUM)
		ld   (bc),a
		and  a
		ld   a,(NUMFILL_PRNUM)
		ld   d,a
		ld   a,#0A
		jr   z,PRN1	;98CF
		ld   d,#30
		ld   a,#10
		dec  e
		inc  bc
PRN1		ex   af,af'	;98CF
		ld   a,d
PRN2		ld   (bc),a
		inc  bc
		dec  e
		jr   nz,PRN2	;98D1
PRN6		push bc		;98D6
		ex   af,af'
		ld   c,a
		ex   af,af'
		xor  a
		ld   de,#0001
PRN4		sla  l		;98DE
		rl   h
		rla
		cp   c
		jr   c,PRN3	;98EF
		sub  c
		sli  e
		rl   d
		jr   nc,PRN4	;98DE
		jr   PRN7	;98F5
PRN3		sla  e		;98EF
		rl   d
		jr   nc,PRN4	;98DE
PRN7		ex   de,hl	;98F5
		pop  bc
		cp   #0A
		ld   e,#37
		jr   nc,PRN5	;98FF
		ld   e,#30
PRN5		add  a,e	;98FF
		ld   (bc),a
		dec  bc
		ld   a,h
		or   l
		jr   nz,PRN6	;98D6
		pop  hl
		pop  de
		ret
NUMFILL_PRNUM	DB	#20
HEXDEC_PRNUM	DB	0	;#00 - DEC, "#" - HEX

;hl - АДРЕС РАЗМЕЩЕНИЯ
;НА ВЫХОДЕ В bc ПОЛУЧЕННОЕ ЧИСЛО
MRNUM 	push hl
	ld b,5
.lp1	ld a,(hl)
	and a
	jr z,.end
	cp " "
	jr z,.next
	cp "#"
	jr z,.next
	cp "0"
	jr c,.err
	cp "9"
	jr c,.next
	cp "A"
	jr c,.err
	cp "F"
	jr c,.next
	cp "a"
	jr c,.err
	cp "f"+1
	jr nc,.err
.next	inc hl
	djnz .lp1
.end	pop hl
	jr .conv
.err	pop hl
	scf
	ld bc,0
	ret
.conv	ld ix,0
CONVM1  ld a,(hl)
        inc hl 
        cp "#"-1
        jr c,CONVM1
        cp "#"
        ld e,15
        jr z,CONVM2
        cp "%"
        ld e,1
        jr z,CONVM2
        ld e,9
        dec hl 
CONVM2  ld a,e 
        ld (CONVB+1),a 
        ld e,255
        push hl
CONVM21 ld a,(hl)
        inc hl
        inc e 
        cp "0"
        jr nc,CONVM21
        pop hl 
CONVM3  ld a,(hl) 
        inc hl
        cp "9"+1
        jr c,M_0_9
        cp "F"+1
        jr c,M_A_F
M_a_f   sub "a"-10
        jr CONVST
M_0_9   sub "0"
        jr CONVST
M_A_F   sub "A"-10
CONVST  ld b,0
        ld c,a 
        add ix,bc 
        push ix
        pop bc 
        dec e 
        ret z 
CONVB   ld a,9
CONVM4  add ix,bc 
        dec a 
        jr nz,CONVM4
        jr CONVM3

;Переводит число в A в HEX вид и помещает в HL
ByteToHEX
	ld	b,a
	and	240
	rrca
	rrca
	rrca
	rrca
	call	.bt3
	inc	hl
	ld	a,b
	and	15
.bt3	cp	10
	jr	c,.bt1
	add	a,"A"-10
	jr	.bt2
.bt1	add	a,"0"
.bt2	ld	(hl),a
	ret

;Печатает размер в Кб, Мб, Гб. 
;на входе
;HL - адрес, куда поместить
;BC:DE - число секторов, которое надо напечатать
;A - символ "K","M","G" - до какой величины приводить число, 
;    или 0 - приводит число до той величины, пока оно не будет занимать макс.5 знаков
PRNUMSEC
	srl	b
	rr	c
	rr	d
	rr	e
	jr	PRNUMBYTES

;Печатает размер в Кб, Мб, Гб. 
;на входе
;HL - адрес, куда поместить
;BC:DE - число байт, которое надо напечатать
;A - символ "K","M","G" - до какой величины приводить число, 
;    или 0 - приводит число до той величины, пока оно не будет занимать макс.5 знаков
PRNUMBYTES
	ex	af,af'
	push	hl
	ex	de,hl
	ld	de,msgMBtxt
	jr	.p3
.p2	
	srl	b
	rr	c
	rr	h
	rr	l
	srl	b
	rr	c
	rr	h
	rr	l
;	srl	b
;	rr	c
;	rr	h
;	rr	l
.p3	
	ex	af,af'
	and	a
	jr	z,.p6
	ex	de,hl
	cp	(hl)		;Дошли до нужного значения "К", "М","Г"?
	ex	de,hl
	jr	z,.p4
	ex	af,af'
	jr	.p7
.p6	ex	af,af'
	ld	a,c
	or	b
	jr	z,.p1
.p7	inc	de
	ld	a,h		;а может уже 0?
	or	l
	or	b
	or	c
	jr	z,.p5
	ld	l,h
	ld	h,c
	ld	c,b
	ld	b,0
	jr	.p2
.p5	ld	de,msgMBtxt
.p4	ex	af,af'
.p1
	pop	bc
	push	bc
	call	PRNUM0
	pop	hl
	ld	a,(de)
	ld	de,6
	add	hl,de
	ld	(hl),a
	inc	hl
	ld	(hl),"b"
	ret

msgMBtxt
	db	"KMG"