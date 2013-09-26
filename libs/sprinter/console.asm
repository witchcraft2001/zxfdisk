;Заливает экран атрибутом 7 и бордер 0, очищает экран
InitConsole
ClearScr
	ld	bc,0x0756
	ld	de,0
	ld	hl,0x1e50
	ld	a,32
	RST	0x10
	ld	de,0
	ld	c,0x52
	rst	0x10
	ld	de,0
	ld	(COORDS),DE
	ret
;Печать строки
Print
.printlp
	ld a,(hl) 
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
	ld a,(COORDS)
	inc a
	cp 80
	jr nc,.C13
	
.nextcrd
	ld (COORDS),a
.pskip	inc hl
	jr .printlp
.C1	
	jr  .pskip

.C13
        ld a,(COORDS+1)	;Y
	cp 30
	jr c,.noscroll
	push	hl
	call ScrollUP
	pop	hl
	jr .prtNullX
.noscroll
	inc a
	ld (COORDS+1),a
.prtNullX
	xor a
	ld (COORDS),a
	jr .pskip
.C16
;Set attribute
	inc hl
	ld  a,(hl)
	ld  (PrtAtr),a
	jr  .pskip

;при печати включены страницы
;7ffd - 0a
;dffd - cf
PrintSym
	ex	af,af'
	ld	de,(COORDS)
	ld	a,(PrtAtr)
	ld	b,a
	ex	af,af'
	ld	c,0x58
	rst	0x10
	ret
ScrollUP
	ld	de,0
	ld	hl,0x1e50
	ld	bc,0x0155
	xor	a
	rst	0x10
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
PrintCursor
	call	PrintSym
	ret
curShow	db	0
curIterate
	db	0
curState
	db	0


COORDS	DW	0	;Y,X
PrtAtr  db  7
