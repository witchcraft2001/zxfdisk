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