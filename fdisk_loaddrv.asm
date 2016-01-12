LoadDriver
	call	FindDrv
	ld	(DrvCnt),a
	and	a
	scf
	ret	z		;��� �� ������ �������� � �������� - ���������� ����������
	ld	hl,msgDrvFounded
	PCHARS
	call	GetFirstDrvName
	ret	c		;error
	ld	a,(DrvCnt)
	ld	b,a
.lp0	push	bc
	ld	a,(DrvCnt)
	add	a,"1"
	sub	b
	ld	(msgDrvNames.num),a

	push	ix
	pop	hl
	ld	de,msgDrvNames.name
	ld	bc,8
	ldir
	inc	de
	ld	c,3
	ldir
	ld	hl,msgDrvNames
	PCHARS
	call	GetNextDrvName
	pop	bc
	djnz	.lp0
;���� ������ � ������� ��������
.lp1
	ld	hl,msgDrvSelect
	PCHARS
	ld	hl,bufStr
	ld	a,2
	call	EditString
	ld	hl,bufStr
	call	MRNUM
	jr	c,.inval
	ld	a,(DrvCnt)
	ld	b,a	
	ld	a,c	;������ 0 - ������������ ����������
	ld	(DrvLoaded),a
	and	a
	scf
	ret	z
	cp	b
	jr	z,.ld1
	jr	c,.ld1
.inval	ld	hl,msgInvalidParameter
	PCHARS
	jr	.lp1
.ld1	call	GetDrvSpec
	push	ix
	pop	hl
	ld	de,msgDrvLoad.name
	ld	bc,8
	ldir
	inc	de
	ld	c,3
	ldir
	ld	hl,msgDrvLoad
	PCHARS
;	call	IM1SET
	ld	e,(ix+0x0e)	;sec
	ld	d,(ix+0x0f)	;trk
	ld	b,(ix+0x0d)	;lenght
	ld	c,5
	ld	hl,_DRVORG
;	di
	call	_trdos	;������ �������
;	call	IM2SET
	and	a
	ret
	
DrvCnt	db	0	;���������� ��������� ���������
DrvLoaded
	db	0
msgDrvSelect
	db	CR,LF,"Select driver: ",EN
msgDrvNames
	db	COL,C_CMD,"["
.num	db	"0] ",COL,C_NORM,"- "
.name	db	"FILENAME.ext",CR,LF,EN
msgDrvFounded
	db	"Available drivers:",CR,LF,EN
msgDrvLoad
	db	CR,LF,"Loading driver: ",COL,C_VAL,"["
.name	db	"FILENAME.ext]",COL,C_NORM,CR,LF,EN
FindDrv
	;������ ������� �������
	ld	hl,Buffer	;������������ ����� ������� ������� ������ � ������ ��������
	ld	bc,8*256+5
	ld	de,0
	;call	IM1SET
	;di
	call	_trdos	;15635
	;call	IM2SET
	ld	bc,128*256	;128 ���������
	ld	ix,Buffer
	ld	de,16
.loop	ld	a,(ix)
	and	a
	jr	z,.end
	dec	a		;���� ������?
	jr	z,.next
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"d"
	jr	nz,.next
	ld	a,(ix+9)
	cp	"r"
	jr	nz,.next
	ld	a,(ix+10)
	cp	"v"
	jr	nz,.next
	inc	c		;������� ��������� ������
.next	add	ix,de
	djnz	.loop
.end	ld	a,c
	and	a
	ret
GetFirstDrvName
	ld	ix,Buffer
	ld	a,(ix)
	and	a
	jr	z,GetNextDrvName.end
	dec	a		;���� ������?
	jr	z,GetNextDrvName
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"d"
	jr	nz,GetNextDrvName
	ld	a,(ix+9)
	cp	"r"
	jr	nz,GetNextDrvName
	ld	a,(ix+10)
	cp	"v"
	jr	nz,GetNextDrvName
	and	a
	ret
;�� ����� ix - ���.������, �� ������ - ����.
;CY = 1 - ����� ��������
GetNextDrvName
	ld	de,16
	ld	bc,Buffer+2048	;����� ��������� ��������

.next	add	ix,de
	push	ix
	pop	hl
	and	a
	sbc	hl,bc		;��������� ����� ��������?
	jr	z,.end
	ld	a,(ix)
	and	a
	jr	z,.end
	dec	a		;���� ������?
	jr	z,.next
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"d"
	jr	nz,.next
	ld	a,(ix+9)
	cp	"r"
	jr	nz,.next
	ld	a,(ix+10)
	cp	"v"
	jr	nz,.next
	and	a
	ret
.end	scf
	ret
;������� ��������� �� ������������ ����� ��������, ����� � �
GetDrvSpec
	ld	de,16
	ld	ix,Buffer
	ld	b,a
.loop	ld	a,(ix)
	and	a
	jr	z,.end
	dec	a		;���� ������?
	jr	z,.next
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"d"
	jr	nz,.next
	ld	a,(ix+9)
	cp	"r"
	jr	nz,.next
	ld	a,(ix+10)
	cp	"v"
	jr	nz,.next
	inc	c		;������� ��������� ������
.next	add	ix,de
	djnz	.loop
	ret
.end	scf
	ret