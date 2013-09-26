		device	zxspectrum128
		org #4100-#16
EXEHeader	db "EXE"
		db	0
		dw	LoaderStart-EXEHeader	;Header lenght
		dw	0
		dw	LoaderEnd-LoaderStart	;Primary Loader Lenght
		dw	0,0,0
		dw	LoaderStart	; Load address
		dw	LoaderStart	; Start address
		dw	LoaderStart-1	; Stack address
;		org 8100h
LoaderStart
		di
		ld	(wARG),	ix
		ld	a, (ix-3)
		ld	(curFile), a
		ld	hl, strHello	
		ld	c, 5Ch		; PCHARS
		rst	10h
		ld	c, 0		; Version
		rst	10h
		ld	a, d
		or	a
		jp	nz, continue
		ld	hl, strError
error		ld	c, 5Ch		;PCHARS
		rst	10h
exit		ld	bc, 0FF41h	;EXIT
		rst	10h

strError:	db "Incorrect DOS version, need DOS 1.00 or high.\r\n",0
strHello:	db "\r\n\r\n"
		db "FDISK for Sprinter v.0.2\r\n"
		db "by Mikhaltchenkov Dmitry aka Hard/WCG\r\n",0
strNoMemory:	db "Not enough memory.\r\n",0

continue
		ld	bc, 23Dh	; GETMEM
		rst	10h
		jr	nc, cont1
		ld	hl, strNoMemory
		jp	error
cont1
		ld	(idMem), a
		ld	hl, arrPages
		ld	c, 0C5h		; EMM_FN5
		rst	8
		ld	a, (arrPages)
		out	(0c2h),	a	; Page2
		ld	a, (arrPages+1)
		out	(0e2h),	a	; Page3
		ld	hl, #ffff - (main_end-main_start)
		ld	de, main_end-main_start	; File lenght
		ld	a, 0
curFile		equ	$-1
		ld	c, 13h		;READ
		rst	10h
		jp	c, exit
		di
		ld hl,#ffff - (main_end-main_start)
		ld de,FDISKSTART
		call DEC40
		ei
		ld	ix,0
wARG		equ	$-2
		ld	hl,(arrPages)
		ld	a,0
idMem		equ	$-1
		jp MainStart

arrPages	ds 2
		db 0
		
		include "libs\unmegalz.asm"
		include "fdisk_exp.inc"

LoaderEnd
		savebin	"out\loader.exe",EXEHeader,$-EXEHeader

main_start	incbin	"out\fdisk.bin.mlz"
main_end