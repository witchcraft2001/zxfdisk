GetFSName
	ld	hl,tabFS
.g1
	ld	a,(hl)
	and	a
	jr	z,.notfound
	cp	b
	jr	z,.found
.g2	inc	hl
	ld	a,(hl)
	and	a
	jr	nz,.g2
	inc	hl
	jr	.g1
;найдено
.found	ld	c,16
	inc	hl
.f1	ld	a,(hl)
	and	a
	jr	z,.f2
	ld	(de),a
	inc	hl
	inc	de
	dec	c
	jr	nz,.f1
	and	a
	ret
.f2	ld	a,32
.f3	ld	(de),a
	inc	de
	dec	c
	jr	nz,.f3
	and	a
	ret
.notfound
	ld	hl,strUnknownFS
	ld	bc,10
	ldir
	ld	b,6
	ld	a,32
.n1	ld	(de),a
	inc	de
	djnz	.n1
	scf
	ret

ShowFSTable
	ld	hl,tabFS
.loop	ld	a,(hl)
	and	a
	ret	z
	inc	hl
	push	hl
	ld	hl,bufStr
	ld	de,bufStr+1
	ld	(hl),32
	ld	bc,28
	ldir
	inc	hl
	ld	(hl),0
	ld	l,a
	ld	bc,bufStr+3
	call	PRNUM
	ld	hl,bufStr
	ld	(hl),COL
	inc	hl
	ld	(hl),C_CMD
	inc	hl
	ld	(hl),"["
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	(hl),"]"
	inc	hl
	inc	hl
	ld	(hl),COL
	inc	hl
	ld	(hl),C_NORM
	pop	hl
	ld	de,bufStr+11
.lp1	ld	a,(hl)
	inc	hl
	and	a
	jr	z,.lp2
	ld	(de),a
	inc	de
	jr	.lp1
.lp2	push	hl
	ld	hl,bufStr
	PCHARS
	ld	a,0
.sf1	equ	$-1
	xor	1
	ld	(.sf1),a
	jr	nz,.lp3
	ld	hl,msgCRLF
	PCHARS
.lp3	pop	hl
	jr	.loop

strTabs	db	" ",EN
strUnknownFS
	db	"Unknown FS",0
tabFS
	db	1
	;	"0123456789abcdef"
	db	"FAT12",0
	db	4
	db	"FAT16 (<32M)",0
	db	5
	db	"Extended",0
	db	6
	db	"FAT16 (>=32M)",0
	db	7
	db	"HPFS/NTFS",0
	db	0x0b
	db	"FAT32",0
	db	0x0c
	db	"FAT32, LBA",0
	db	0x0e
	db	"FAT16, LBA",0
	db	0x0f
	db	"Extended",0
	db	0x52
	db	"CP/M",0
	db	0x53
	db	"MOA FS-Scorpion",0
	db	0x82
	db	"Linux swap",0
	db	0x83
	db	"Linux native",0
	db	0x85
	db	"Linux extended",0
;Конец таблицы
	db	0