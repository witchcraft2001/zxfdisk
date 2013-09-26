;Заливает экран атрибутом 7 и бордер 0, очищает экран
InitConsole
	xor	a
	out	(#fe),a

ClearScr
	ld	hl,#4000
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,6144
	ld	(hl),l
	ldir
	ld  (hl),7
    	ld  bc,767
    	ldir
	ld	hl,0
	ld	(COORDS),hl
	ret
;Пауза
PAUSE1  ld a,1
PAUSE   ei 
        ld hl,23672
        ld (hl),0
WAIT1	   	ei:halt
	cp (hl) 
	ret z 
	jr WAIT1
;Печать строки 64 символа
Print   ld a,(hl) 
	        or a 
	        ret z
	        cp  1
	        jr  z,.C1
		cp 10
		jr z,.pskip
	        cp 13
	        jr z,.C13
	        cp  16
	        jr  z,.C16
		cp 32
		jr z,.skipSym
	        push hl
	        call PrintSym
	        pop hl
.skipSym
		ld a,(COORDS+1)
		inc a
		cp 64
		jr nc,.C13
	
.nextcrd
		ld (COORDS+1),a
.pskip	    inc hl
	    jr Print
.C1	    ld  a,(PrintSym.xor1)
	    and a
	    jr  z,.inv
	    xor a
		ld  (PrintSym.xor1),a
;	    ld  (PrintSym.xor1+1),a
	    ld  (PrintSym.xor2),a
;	    ld  (PrintSym.xor2+1),a
	    jr  .pskip
.inv
;	    ld  a,0xEE  ;XOR N
;	    ld  (PrintSym.xor1),a
;	    ld  (PrintSym.xor2),a
	    ld  a,240
	    ld  (PrintSym.xor1),a
	    cpl
	    ld  (PrintSym.xor2),a
	    jr  .pskip


.C13
        ld a,(COORDS)	;Y
	cp 23
	jr c,.noscroll
	push	hl
	call ScrollUP
	pop	hl
	jr .prtNullX
.noscroll
	inc a
	ld (COORDS),a
.prtNullX
	xor a
	ld (COORDS+1),a
	jr .pskip
.C16
;Set attribute
	    inc hl
	    ld  a,(hl)
	    ld  (PrtAtr),a
	    jr  .pskip
PCH
PrintSym
	    ex  af,af'
	    ld  de,(COORDS)
	    call    COORD
.setatr
	    ld  b,h
	    ld a,h
	    rrca
	    rrca
	    rrca
	    and 3
	    or 88
	    ld h,a
	    ld  a,(PrtAtr)
	    ld  (hl),a
	    ld  h,b
	    ex  af,af'
	    ld  e,a
	    ld  d,high font
	    ld  a,(ShiftSymb)
	    and a
	    jr  z,.lp2
		ld	b,0
.xor1		equ	$-1
.lp1
	    dup 8
	    ld  a,(de)
	    and 240
	    ld  c,a
	    ld  a,(hl)
	    and 15
	    or  c
	    xor b
	    ld  (hl),a
	    inc h
	    inc d
	    edup
	    org $-2
	    ret
.lp2	    ld b,0
.xor2	    equ $-1
	    dup 8
	    ld  a,(de)
	    and 15
	    ld  c,a
	    ld  a,(hl)
	    and 240
	    or  c
	    xor b
	    ld  (hl),a
	    inc h
	    inc d
	    edup
	    org $-2
	    ret
DOWND   inc d
        ld a,d
        and 7
        ret nz
        ld a,e
        add a,32
        ld e,a
        ret c
        ld a,d
        sub 8
        ld d,a
        ret 
ADRZ    ld a,l
        and 7
        rrca
        rrca
        rrca
        add a,h
        ld h,l
        ld l,a
        ld a,h
        and #18
        or #40
        ld h,a
        ret
ADRATR  ld a,l
        and 7
        rrca
        rrca
        rrca
        add a,h
        ld h,l
        ld l,a
        ld a,h
        and #18
        rrca
        rrca
        rrca
        or #58
        ld h,a
        ret 
DOWN8   ld a,e
        add a,32
        ld e,a
        ret nc
        ld a,d
        add a,8
        ld d,a
        ret
COORD   srl d 
        ld a,0
        jr c,LF1
        ld a,1
LF1     ld (ShiftSymb),a
        ld a,e
        and 7
        rrca
        rrca
        rrca
        add a,d
        ld l,a
        ld a,e
        and #18
        or #40
        ld h,a
        ret 

ScrollUP
	ld hl,#4020
	ld de,#4000
        ld b,23
.SCR1    push bc
        call CopyRow
        ld e,l
        ld d,h
        ld a,l
        add a,32
        ld l,a
        jr nc,.SCR2
        ld a,8
        add a,h
        ld h,a
.SCR2    pop bc
        djnz .SCR1
        ld c,8
        ex de,hl 
.SCR3    ld b,32
        push hl 
.SCR4    ld (hl),0
        inc l
        djnz .SCR4
        pop hl
        inc h
        dec c
        jr nz,.SCR3
        ret
CopyRow push hl:push de
        ld bc,0xffff
        ld a,4
.SCR5    ;push bc
        dup 32
        ldi
        edup
        dec de
        dec hl
        inc d
        inc h
        dup 32
        ldd
        edup
        ;pop bc
        inc hl
        inc de
        inc d
        inc h
        dec a
        jp nz,.SCR5
        pop de
        push    de
        ld a,d
        rrca
        rrca
        rrca
        and 3
        or 88
        ld d,a
        ld  bc,32
        push    de
        pop hl
        add hl,bc
        dup 32
        ldi
        edup

        pop de:pop hl
        ret 

CursorOn
	ld	a,1
	ld	(curShow),a
	xor	a
	ld	(curState),a
	ld	(curIterate),a
	ret

CursorOff
	xor	a
	ld	(curShow),a
	ld	a,32
	jp	PCH
;PrintCursor
;	JP	PrintSym

curShow	db	0
curIterate
	db	0
curState
	db	0

COORDS	DW	0	;Y,X
PrtAtr  db  7
ShiftSymb
	db	0