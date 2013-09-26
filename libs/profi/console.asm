ReturnConsole
	ld	bc,#DFFD
	xor	a
	out	(c),a
	ret

;Заливает экран атрибутом 7 и бордер 0, очищает экран
InitConsole
	xor	a
	out	(#fe),a
	ld	hl,#c000
	call	OpenPGDF
;Проверка 1 мегабайта (цвета)
	ld 	a,2
	call	OpenPG
	ld	a,(hl)
	push	af
	ld	a,2
	ld	(hl),a
	ld	a,7	
	call	OpenPGDF
	ld	a,7
	ld	(hl),a
	xor	a
	call	OpenPGDF
	ld	a,(hl)
	cp	2
	ld	a,7
	jr	z,.color
	xor	a
.color	
	ld	(PrtAtr),a
	pop	af
	ld	(hl),a
	xor	a
	call	OpenPGDF
	xor	a
	call	OpenPG	
ClearScr
	ld a,(CurrentPage7F)
	push	af
	ld	a,(CurrentPage)
	push	af
	ld 	a,6
	call	OpenPG
	xor	a	
	call	OpenPGDF
	ld	hl,#c000
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,16383
	ld	(hl),l
    	call	_fast_ldir
	ld	a,(PrtAtr)
	and	a
	jr	z,.skipatr
	ld 	a,2
	call	OpenPG
	ld	a,7	
	call	OpenPGDF
	ld	hl,#c000
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,16383
	ld	(hl),7
    	call	_fast_ldir
.skipatr
	ld	hl,0
	ld	(COORDS),hl
	jp	Print.exit	
;Пауза
PAUSE1  ld a,1
PAUSE   ei 
        ld hl,23672
        ld (hl),0
WAIT1	   	ei:halt
	cp (hl) 
	ret z 
	jr WAIT1

_fast_ldir
	xor a
	sub c
	and 63
	add a,a
	ld (.jump),a
.jump=$+1
	jr nz,.loop
.loop
	dup 64
	ldi
	edup
	jp pe,.loop
	ret

;Печать строки 64 символа
Print
	ld a,(CurrentPage7F)
	push	af
;	ld	a,6
;	call	OpenPG
	ld	a,(CurrentPage)
	push	af
;	xor	a
;	call	OpenPGDF
.printlp
	ld a,(hl) 
	or a 
	jr	z,.exit
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
.pskip	inc hl
	jr .printlp
.exit	pop	af
	call	OpenPGDF
	pop	af
	call	OpenPG
	ret
.C1	ld  a,(PrintSym.xor1)
	and a
	jr  z,.inv
	xor a
	ld  (PrintSym.xor1),a
;	    ld  (PrintSym.xor1+1),a
	    
;	ld  (PrintSym.xor2),a
;	    ld  (PrintSym.xor2+1),a
	jr  .pskip
.inv
;	    ld  a,0xEE  ;XOR N
;	    ld  (PrintSym.xor1),a
;	    ld  (PrintSym.xor2),a
	ld  a,240
	ld  (PrintSym.xor1),a
;	cpl
;	ld  (PrintSym.xor2),a
	jr  .pskip


.C13
        ld a,(COORDS)	;Y
	cp 29
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
	ld  a,(PrtAtr)
	and a
	jr  z,.pskip
	ld  a,(hl)
	ld  (PrtAtr),a
	jr  .pskip
;Вывод символа с восстановлением страниц (специально для профи, атм, у которых видео страницы не стандартные)	
PCH	ex	af,af'
	ld	a,(CurrentPage)
	push	af
	ld	a,(CurrentPage7F)
	push	af
	ex	af,af'
	call	PrintSym
	pop	af
	call	OpenPG
	pop	af
	jp	OpenPGDF

;при печати включены страницы
;7ffd - 0a
;dffd - cf
PrintSym
	ld	h,high font
	ld	l,a
	ld	bc,(COORDS)
;	ld	de, тут адрес в которую впечатана страница экрана
;	srl	b
;	jr	nc,.ps1
	call	adr
;	jr	.ps2
;.ps1	call	adr
;	ld	bc,#2000
;	ex	de,hl
;	add	hl,bc
;	ex	de,hl
;.ps2	
;ld	b,8
	ld	a,6
	call	OpenPG
	xor	a
	call	OpenPGDF
	push	de
	ld	c,0
.xor1	equ	$-1
.ps3	dup	8
	ld	a,(hl)
	xor	c
	ld	(de),a
	inc	h
	inc	d
	edup
	org	$-2
	pop	de
	ld	a,2
	call	OpenPG
	ld	a,7
	call	OpenPGDF
	ld	a,(PrtAtr)	;Цветной профик?
	and	a
	ret	z
	dup	8
	ld	(de),a
	inc	d
	edup
	org	$-1
	ret
adr	srl	b
	ld	d,#c0
	jr	c,.a1
	ld	d,#e0
.a1	ld	a,c
	and	7
	rrca
	rrca
	rrca
	add	a,b
	ld	e,a
	ld	a,c
	or	d
	and	0xf8
	ld	d,a
	ret
DOWN8   ld a,e
        add a,32
        ld e,a
        ret nc
        ld a,d
        add a,8
        ld d,a
        ret
ScrollUP
	ld	hl,#c020
	ld	de,#c000
.scroll
        ld b,29
.SCR1    push bc
        call CopyRow
	push	de
	push	hl
	set 5,d
	set 5,h
        call CopyRow
	pop	hl
	pop	de
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
        ex de,hl	
        ld c,8
	push	hl
	call	.SCR3
	pop	hl
	set	5,h
	ld	c,8
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
	ld	a,(PrtAtr)
	and	a
	jp	z,.skipatr
	ld	a,2
	call	OpenPG
	ld	a,7
	call	OpenPGDF
;attrs
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
.skipatr
	ld	a,6
	call	OpenPG
	xor	a
	call	OpenPGDF
        pop	de
	pop	hl
	push	hl
        push    de
;scrn
        ld bc,0xffff
        ld a,4
.SCR6    ;push bc
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
        jp nz,.SCR6
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
;	ex	af,af'
;	ld a,(CurrentPage7F)
;	push	af
;	ld	a,6
;	call	OpenPG
;	ld	a,(CurrentPage)
;	push	af
;	xor	a
;	call	OpenPGDF
;	ex	af,af'
;	call	PrintSym
;	pop	af
;	call	OpenPGDF
;	pop	af
;	call	OpenPG
;	ret
curShow	db	0
curIterate
	db	0
curState
	db	0


COORDS	DW	0	;Y,X
PrtAtr  db  7
