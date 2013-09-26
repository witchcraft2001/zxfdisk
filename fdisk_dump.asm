dumpSector	
;Установим по умолчанию первый сектор винта, потом прикручу нахождение первого сектора партиции
;	ld	bc,0
;	ld	de,0
dmpSector
	IF _IM = 1
	call	IM1SET
	ENDIF
	ld	(dSectorNumHigh),bc
	ld	(dSectorNumLow),de
	exx
	ld	de,0		;lba 32-47 == 0
	exx
	ld	hl,SectorBuffer
	call	hDrvEntry
	db	4	;read single sector
	IF _IM = 1
	call	IM2SET
	ENDIF
dmpShowFirstPage
	ld	b,0
	ld	a,16
dmpShowPage
	push	bc
	push	af
	CLS
	ld	de,(dSectorNumHigh)
	ld	a,d
	ld	hl,msgSectorNum.num+1
	call	ByteToHEX
	ld	a,e
	inc	hl
	call	ByteToHEX
	ld	de,(dSectorNumLow)
	ld	a,d
	inc	hl
	call	ByteToHEX
	ld	a,e
	inc	hl
	call	ByteToHEX
	ld	hl,msgSectorNum
	PCHARS
	pop	af
	pop	bc
	call	ShowDump
	ld	hl,msgDumpCmd
	PCHARS
	ld	hl,tblDumpCmd
	jp	Prompt
dmpShowSecPage
	ld	a,16
	ld	b,a
	jr	dmpShowPage

;Показывает дамп
;На входе:
;B - смещение
;A - количество строк
ShowDump
	push	bc
	add	a,b
	ld	(.sdrows),a
	ld	a,"#"
	ld	(HEXDEC_PRNUM),a
	ld	hl,(dSectorNumLow)
	ld	bc,msgSectorNum.num+4
	call	PRNUM0
	ld	hl,(dSectorNumHigh)
	ld	bc,msgSectorNum.num
	call	PRNUM0	

	pop	bc
;	ld	b,0
.loop1	ld	hl,SectorBuffer
	push	bc
	push	hl
	ld	l,b
	ld	h,0
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ld	bc,msgDumpRow.offset
	call	PRNUM0
	ex	de,hl
	pop	hl
	add	hl,de
	push	hl
	ld	c,16
	ld	de,msgDumpRow.dump
.loop	ld	a,(hl)
	ex	de,hl
	;push	bc
	call	ByteToHEX
	;pop	bc	
	inc	hl
	bit	0,c
	jr	z,.lp1
	inc	hl
.lp1	ex	de,hl
	inc	hl
	dec	c
	jr	nz,.loop
	pop	hl
	ld	b,16
	ld	de,msgDumpRow.txt
.lp2	ld	a,(hl)
	cp	32
	jr	nc,.lp3
	ld	a,"?"
.lp3	ld	(de),a
	inc	hl
	inc	de
	djnz	.lp2
;	push	hl
	ld	hl,msgDumpRow
	PCHARS
;	pop	hl
	pop	bc
	inc	b
	ld	a,b
	cp	32
.sdrows	equ	$-1
	jp	c,.loop1
	xor	a
	ld	(HEXDEC_PRNUM),a
	ret
dmpNextSector
	ld	bc,(dSectorNumHigh)
	ld	hl,(dSectorNumLow)
	ld	de,1
	add	hl,de
	ex	de,hl
	jp	nc,dmpSector
	inc	bc
	jp	dmpSector
dmpPrevSector
	ld	bc,(dSectorNumHigh)
	ld	de,(dSectorNumLow)
	ld	a,e
	or	d
	or	b
	or	c
	jp	z,dmpSector
	ex	de,hl
	ld	de,1
	sbc	hl,de
	ex	de,hl
	jp	nc,dmpSector
	dec	bc
	jp	dmpSector
dSectorNumHigh
	dw	0
dSectorNumLow
	dw	0
msgDumpRow
	db	COL,C_DMP
.offset	db	"#0000  "
.dump	db	"0000 0000 0000 0000 0000 0000 0000 0000  "
.txt	db	"0123456789ABCDEF",COL,C_NORM
 IF _TARGET = _SPRINTER | _TARGET=_ATM
	db	CR,LF
 ENDIF
	db	EN

msgSectorNum
	db	"Sector number: ",COL,C_VAL,"["
.num	db	"#00000000]",COL,C_NORM,CR,LF,CR,LF,EN
msgDumpCmd
	db	CR,LF,"Select command: ",COL,C_CMD,"[1] ",COL,C_NORM,"- First page ",COL,C_CMD,"[2] ",COL,C_NORM,"- Second page ",COL,C_CMD,"[P] ",COL,C_NORM,"- Prev. sector ",COL,C_CMD,"[N] ",COL,C_NORM,"- Next sector ",COL,C_CMD,"[Q] ",COL,C_NORM,"- Quit",CR,LF,EN
tblDumpCmd
	db	"1"
	dw	dmpShowFirstPage
	db	"2"
	dw	dmpShowSecPage
	db	"q"
	dw	ShowPartition.continue
	db	"p"
	dw	dmpPrevSector
	db	"n"
	dw	dmpNextSector