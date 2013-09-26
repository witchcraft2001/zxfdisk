_ATM_SYMPG	equ	7
_ATM_ATRPG	equ	3

;Заливает экран атрибутом 7 и бордер 0, очищает экран
InitConsole
	xor	a
	out	(#fe),a
	ld	a,#10
	ld	(CurrentPage),a
	call	ClearScr
	LD	BC,#2A53
	PUSH	BC
	LD	BC,#FF77 ;выкл.теневые порты
	LD	A,%10101110 ;режим ATM 80x25
	JP	#3D2F
ReturnConsole
	LD	BC,#2A53
	PUSH	BC
	LD	BC,#FF77 ;выкл.теневые порты
	LD	A,%10101011 ;режим ZX
	JP	#3D2F

ClearScr
	ld	a,(CurrentPage)
	push	af
	ld 	a,_ATM_SYMPG
	call	OpenPG
	ld	hl,#c1c0
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,0x640
	ld	(hl),0
    	ldir
	ld	hl,#E1c0
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,0x640
	ld	(hl),0
    	ldir
	ld 	a,_ATM_ATRPG
	call	OpenPG
	ld	hl,#c1c0
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,0x640
	ld	(hl),7
    	ldir
	ld	hl,#e1c0
	ld	d,h
	ld	e,l
	inc	e
	ld	bc,0x640
	ld	(hl),7
    	ldir
	ld	hl,0
	ld	(COORDS),hl
	pop	af
	jp	OpenPG
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
Print
	ld a,(CurrentPage)
	push	af
.printlp
	ld a,(hl) 
	or a 
	jr z,.exit
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
	cp 80
	jr nc,.C13
	
.nextcrd
	ld (COORDS+1),a
.pskip	inc hl
	jr .printlp
.exit
	pop	af
	jp	OpenPG
.C1	
	jr  .pskip

.C13
        ld a,(COORDS)	;Y
	cp 24
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
;Вывод символа с восстановлением страниц (специально для профи, атм, у которых видео страницы не стандартные)	
PCH	ex	af,af'
	ld	a,(CurrentPage)
	push	af
	ex	af,af'
	call	PrintSym
	pop	af
	jp	OpenPG

;при печати включены страницы
;7ffd - 0a
;dffd - cf
PrintSym
	ld	e,a
	ld	bc,(COORDS)
	call	adr
	ld	bc,#7ffd
	ld	a,_ATM_SYMPG+8
	di
	out	(c),a
;	call	OpenPG
	ld	(hl),e
	ld	a,_ATM_ATRPG+8
	out	(c),a
;	call	OpenPG
	ld	a,h
	xor	%00100000
	ld	h,a
	bit	5,h
	jr	nz,.ps1
	inc	hl
.ps1	ld	a,(PrtAtr)
	ld	(hl),a
	ld	a,(CurrentPage)
	out	(c),a
	ei
	ret
adr	srl	b
	ld	hl,#c1c0
	jr	nc,.a1
	ld	hl,#e1c0
.a1	xor	a
	srl	c
	rr	a
	srl	c
	rr	a
	add	a,b
	ld	b,c
	ld	c,a
	add	hl,bc
	ret

DOWN8   ld a,e
        add a,64
        ld e,a
        ret nc
	inc d
        ret
ScrollUP
	ld	hl,#c1C0+64
	ld	de,#c1C0
.scroll
        ld b,25
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
        add a,64
        ld l,a
        jr nc,.SCR2
	inc h
.SCR2   pop bc
        djnz .SCR1
        ex de,hl
	push hl
	call .SCR3
	pop hl
	set 5,h
.SCR3   ld b,40
.SCR4   ld (hl),0
        inc l
        djnz .SCR4
        ret
CopyRow push hl:push de
	ld a,_ATM_SYMPG
	call OpenPG
;attrs
        ld bc,0xffff
        dup 40
        ldi
        edup
	ld	a,_ATM_ATRPG
	call	OpenPG
        pop	de
	pop	hl
	push	hl
        push    de
;scrn
        ld bc,0xffff
        dup 40
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
;	ex	af,af'
;	ld	a,(CurrentPage)
;	push	af
;	ex	af,af'
;	call	PrintSym
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
