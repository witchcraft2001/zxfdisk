		device	zxspectrum128

CR	EQU	13
LF	EQU	10
EN	EQU	00
	include "DOS_EQU.asm"

	org #8100-#16
EXEHeader
	db "EXE"
	db	0
	dw	FdiskStart-EXEHeader	;Header lenght
	dw	0
	dw	FdiskEnd-FdiskStart	;Primary Loader Lenght
	dw	0,0,0
	dw	FdiskStart	; Load address
	dw	FdiskStart	; Start address
	dw	FdiskStart-1	; Stack address
FdiskStart
	di
	ld	hl,strHello
	ld	c, PCHARS	
	rst	10h
	;определение доступных устройств
	ld	c,5fh
	ld	ix,listDrives
	rst	8
	jr	c,exit
	ld	a,(ix)
	cp	2
	jr	c,exitNoDisks
	ld	a,(ix+2)
	and	a
	jr	z,exitNoDisks
	ld	l,a
	ld	bc,strHards
	call	PRNUM
	ld	hl,strHards
	ld	c,PCHARS
	rst	10h
	ld	b,(ix+2)
	xor	a
lpGetHDDPar
	push	af
	push	bc
	push	af
	or	#80
	ld	c,#58
	rst	8
	ld	bc,strHDDInfo.sec
	call	PRNUM
	ld	l,h
	ld	bc,strHDDInfo.head
	call	PRNUM
	ex	de,hl
	ld	bc,strHDDInfo.cyl
	call	PRNUM0
	pop	af
	inc	a
	ld	l,a
	ld	bc,strHDDInfo.drv
	call	PRNUM
	ld	hl,strHDDInfo
	ld	c,PCHARS
	rst	10h
	pop	bc
	pop	af
	inc	a
	djnz	lpGetHDDPar
exit	ld	hl,CRLF
exitMsg	ld	c, PCHARS	
	rst	10h
	ld	bc, EXIT
	rst	10h
exitNoDisks
	ld	hl,strNoDisks
	jr	exitMsg
	include	"prnum.asm"

strHello
	DB	CR,LF,"FDISK v.0.1 by Hard/WCG",CR,LF
CRLF	DB	CR,LF,EN
strHards
	db	"000 hard disks found!",CR,LF,EN
strNoDisks
	db	"Not found any hard disk",CR,LF,EN
strHDDInfo
	db	"Drive "
.drv	db	"000:",CR,LF,"    Cylinders: "
.cyl	db	"00000 Heads: "
.head	db	"000 Sectors: "
.sec	db	"000",CR,LF,EN
listDrives
	ds	16
FdiskEnd

	savebin "fdisk.exe",EXEHeader,FdiskEnd-EXEHeader