;---------------------------------------------------------
;	�������� ����� ������ �� ������� ��������
;---------------------------------------------------------
;�� ����� A - ����� ������
;�� ������ CY = 1 - ������� �����
DelRowFromMBR
	ex	af,af'
	ld	a,(partCount)
	scf
	and	a
	ret	z
	ex	af,af'
	push	af
	ld	de,MBRFIELDSIZE
	ld	hl,MBRTable
	and	a
	jr	z,.skip1
.n1	add	hl,de
	dec	a
	jr	nz,.n1
.skip1	push	hl	;������� ������
	add	hl,de	;��������� ������
	pop	de
;������������ ���������� �������, ������� ���� ����� ���������
	pop	bc
	inc	b
	ld	a,MAXMBRFIELDS
	sub	b
	and	a
	jr	z,.null
	exx
	ld	de,MBRFIELDSIZE
	ld	hl,0
.n2	add	hl,de
	dec	a
	jr	nz,.n2
	push	hl
	exx
	pop	bc
	ldir		;���������� ���� �� ���� ������ ����� �� �������
.null	ld	hl,partCount
	dec	(hl)
	ret

;---------------------------------------------------------
;	����������� ���������� ����� �� �����
;	(�������� ����� GetHDDPar)
;---------------------------------------------------------
CalcUnused
	ld	a,(partCount)
	ld	ix,MBRTable
	ld	de,MBRFIELDSIZE
	and	a
	jr	z,.cu1
	jr	.cu3
.cu2	add	ix,de
.cu3	dec	a
	jr	nz,.cu2
.cu1
;������ ������ ������� ������� �������
	ld	l,(ix)
	ld	h,(ix+1)
	
	ld	e,(ix+13)
	ld	d,(ix+14)
	and	a
	add	hl,de
	ex	de,hl
	ld	l,(ix+2)
	ld	h,(ix+3)
	ld	c,(ix+15)
	ld	b,(ix+16)
	adc	hl,bc
	push	hl
	pop	bc
;� BC:DE ����� ������� ������� �������
	ld	l,(ix+17)
	ld	h,(ix+18)
	and	a
	add	hl,de
	ex	de,hl
	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	push	hl
	pop	bc
;� BC:DE ����� �������, ��������� �� ��������� ��������
	ld	hl,(hddTotalSector+2)
	and	a
	sbc	hl,bc
	push	hl
	pop	bc
	ld	hl,(hddTotalSector)
	sbc	hl,de
	ex	de,hl
	ret

ShowMBRUS
	ld	ix,MBRUSTable
	ld	de,MBRUSFIELDSIZE
	ld	a,(cntMBRUS)
	and	a
	scf
	ret	z
	ld	b,0
	ld	c,a
.n1	call	ShowMBRUSRow
	add	ix,de
	inc	b
	dec	c
	jr	nz,.n1
	ret

;--------------------------------------------------
;���������� ������ �� ��������� ������ �� �����
;� IX - ������ � ������� MBRUSTable
;� C - ����� ������
;--------------------------------------------------
ShowMBRUSRow
	push	bc
	push	de
	ld	l,b
	inc	l
	ld	bc,msgMBRUSRow.num
	call	PRNUM
;������ ������
	ld	hl,msgMBRUSRow.start
	ld	a,(ix+3)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+2)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+1)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+0)
	call	ByteToHEX
;������ �����	
	ld	hl,msgMBRUSRow.len
	ld	a,(ix+7)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+6)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+5)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+4)
	call	ByteToHEX
;�� ������ � �������� �������� ����� � ��, ��
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,msgMBRUSRow.lenbytes
	ld	a,"M"
	call	PRNUMSEC
	ld	hl,msgMBRUSRow
	PCHARS
	pop	de
	pop	bc
	ret

CreateMBRUSforPRI
	xor	a
	ld	(cntMBRUS),a
	ld	hl,MBRUSTable
	ld	(tMBRUS),hl
	ld	de,MBRUSTable+1
	ld	bc,(MAXMBRUS*MBRUSFIELDSIZE)-1
	ld	(hl),a
	ldir
	ld	a,(partCount)
	and	a
	jp	z,CreateMBRUS.hddclear	;��� ��������
;��������, ����� ���� ������ ������ � ������� �� � ������ ������ �����
	ld	ix,MBRTable
.cr00	xor	a
	or	(ix+14)
	or	(ix+15)
	or	(ix+16)
;���� ������� 3 ����� ������ �������� !=0, �� �������� �� � ������ �����

;	ld	e,(ix+13)
;	ld	d,(ix+14)
;	ld	c,(ix+15)
;	ld	b,(ix+16)
	jr	z,.cr01
	ld	l,(ix+13)
	ld	h,(ix+14)
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	and	a
	sbc	hl,de
	ex	de,hl
	ld	c,(ix+15)
	ld	b,(ix+16)
	jr	nc,.cr02
	dec	bc
.cr02	exx
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	ld	b,d
	ld	c,d
	call	addMBRUSItem

.cr01	ld	ix,MBRTable
;���������� ��������� ����� ����� ������� ��������
.cr0	push	ix
	call	NextPrimary
	push	ix
	pop	iy
	pop	ix
;ix	- curr primary
;iy	- next primary
	jp	c,.nextcheck

	ld	l,(ix)
	ld	h,(ix+1)
	
	ld	e,(ix+13)
	ld	d,(ix+14)
	and	a
	add	hl,de
	ex	de,hl
	ld	l,(ix+2)
	ld	h,(ix+3)
	ld	c,(ix+15)
	ld	b,(ix+16)
	adc	hl,bc
	push	hl
	pop	bc
;� BC:DE ����� ������� ������� �������
	ld	l,(ix+17)	;������ �������
	ld	h,(ix+18)
	and	a
	add	hl,de
	push	hl		;������� ����� � ����

	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ex	de,hl		;������� ����� � DE
;���������� ����. ������ �� ��������

	ld	l,(iy)
	ld	h,(iy+1)
	
	ld	c,(iy+13)
	ld	b,(iy+14)
	and	a
	add	hl,bc
	push	hl		;������� ����� � ����
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	c,(iy+15)
	ld	b,(iy+16)
	adc	hl,bc		;������� ����� ������ ����. �������
	and	a
	sbc	hl,de		;
	jr	z,.cr1		;������� ����� ���������?
;�� ���������
;CY = 1 - ������ ������ "�������" �� ������
	jr	c,.incorrect1
;CY = 0	- ���� ��������� ����� ����� ���������
.cr5	push	hl
	pop	bc
	pop	hl
	pop	de
	sbc	hl,de
.cr52	ex	de,hl		;������ ���������� ������� � BC:DE
	call	addMBRUS

	jr	.cr2		;����������
.incorrect1
	ld	hl,msgIncorrect
	PCHARS
;	������� � ��������� � ����.����
;	jr .cr1	

.cr1	pop	hl
	pop	de
	and	a
	sbc	hl,de
	jr	z,.cr2		;����� ������� ������� ��������� �� ������ �������?
;���!
;CY = 1 - ������ ������ "�������" �� ������
;CY = 0	- ���� ��������� ����� ����� ���������
	jr	nc,.cr52
.cr2	push	iy	;��������� ��������� ����
	pop	ix
	jp	.cr0
.nextcheck
;���������� ��������� ������� ����� ���������� ������� �������
;� IX - ����� ���������� ������� �������
	ld	a,(ix+9)
	and	a
	jp	z,CreateMBRUS.hddclear
	ld	l,(ix)		;������ ������ �������
	ld	h,(ix+1)
	ld	c,(ix+13)	;����� �������
	ld	b,(ix+14)
	and	a
	add	hl,bc
	push	hl		;������� ����� � ����
	ld	l,(ix+2)	;������� ����� ������� ������� �������
	ld	h,(ix+3)
	ld	c,(ix+15)	;������� ����� ������� �������
	ld	b,(ix+16)
	adc	hl,bc		;������� ����� ������ ����. �������
	ex	de,hl
	ld	hl,(hddTotalSector)
	and	a
	pop	bc
	sbc	hl,bc
	push	hl
	ld	hl,(hddTotalSector+2)
	sbc	hl,de
	pop	de
	ld	a,h
	or	l
	or	d
	or	e
	jp	z,CreateMBRUS.countunused
	;ex	de,hl
	;� hl:de ������ ������� �� ������ ����������� ������� �� ����� �����
;	push	bc
	ex	de,hl
	;� hl ��. ����� ������� �������
	ld	c,(ix+0x0c+5)	;������ �������� ��.�����
	ld	b,(ix+0x0d+5)	;������ �������� ��.�����
	and	a
	sbc	hl,bc
	ex	de,hl
;	push	bc
;	pop	hl
	ld	c,(ix+0x0e+5)	;������ �������� ��.�����
	ld	b,(ix+0x0f+5)	;������ �������� ��.�����
	sbc	hl,bc
	ld	a,h
	or	l
	or	d
	or	e
	jp	z,CreateMBRUS.countunused
	ld	b,h
	ld	c,l
	call	addMBRUS
	jp	CreateMBRUS.countunused

;---------------------------------------------------------
;	����������� ���������� ����� �� �����
;	(�������� ����� GetHDDPar)
;---------------------------------------------------------
;�������� MBRUSTable
;+0	4	Start (lba)
;+4	4	Lenght (sectors)
;---------------------------------------------------------

CreateMBRUS
	xor	a
	ld	(cntMBRUS),a
	ld	hl,MBRUSTable
	ld	(tMBRUS),hl
	ld	de,MBRUSTable+1
	ld	bc,(MAXMBRUS*MBRUSFIELDSIZE)-1
	ld	(hl),a
	ldir
	ld	a,(partCount)
	and	a
	jp	z,.hddclear	;��� ��������
;��������, ����� ���� ������ ������ � ������� �� � ������ ������ �����
	ld	ix,MBRTable
.cr00	xor	a
	or	(ix+14)
	or	(ix+15)
	or	(ix+16)
;���� ������� 3 ����� ������ �������� !=0, �� �������� �� � ������ �����

;	ld	e,(ix+13)
;	ld	d,(ix+14)
;	ld	c,(ix+15)
;	ld	b,(ix+16)
	jr	z,.cr011
	ld	l,(ix+13)
	ld	h,(ix+14)
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	and	a
	sbc	hl,de
	ex	de,hl
	ld	c,(ix+15)
	ld	b,(ix+16)
	jr	nc,.cr02
	dec	bc
.cr02	exx
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	ld	b,d
	ld	c,d
	call	addMBRUSItem
.cr011
	ld	ix,MBRTable
;���������� ��������� ����� ����� ������� ��������
.cr0	push	ix
	call	NextPrimary
	push	ix
	pop	iy
	pop	ix
;ix	- curr primary
;iy	- next primary
	jp	c,.nextcheck

	ld	l,(ix)
	ld	h,(ix+1)
	
	ld	e,(ix+13)
	ld	d,(ix+14)
	and	a
	add	hl,de
	ex	de,hl
	ld	l,(ix+2)
	ld	h,(ix+3)
	ld	c,(ix+15)
	ld	b,(ix+16)
	adc	hl,bc
	push	hl
	pop	bc
;� BC:DE ����� ������� ������� �������
	ld	l,(ix+17)	;������ �������
	ld	h,(ix+18)
	and	a
	add	hl,de
	push	hl		;������� ����� � ����

	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ex	de,hl		;������� ����� � DE
;���������� ����. ������ �� ��������

	ld	l,(iy)
	ld	h,(iy+1)
	
	ld	c,(iy+13)
	ld	b,(iy+14)
	and	a
	add	hl,bc
	push	hl		;������� ����� � ����
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	c,(iy+15)
	ld	b,(iy+16)
	adc	hl,bc		;������� ����� ������ ����. �������
	and	a
	sbc	hl,de		;
	jr	z,.cr1		;������� ����� ���������?
;�� ���������
;CY = 1 - ������ ������ "�������" �� ������
	jr	c,.incorrect1
;CY = 0	- ���� ��������� ����� ����� ���������
.cr5	push	hl
	pop	bc
	pop	hl
	pop	de
	sbc	hl,de
.cr52	ex	de,hl		;������ ���������� ������� � BC:DE
	call	addMBRUS

	jr	.cr2		;����������
.incorrect1
	ld	hl,msgIncorrect
	PCHARS
;	������� � ��������� � ����.����
;	jr .cr1	

.cr1	pop	hl
	pop	de
	and	a
	sbc	hl,de
	jr	z,.cr2		;����� ������� ������� ��������� �� ������ �������?
;���!
;CY = 1 - ������ ������ "�������" �� ������
;CY = 0	- ���� ��������� ����� ����� ���������
	jr	nc,.cr52
.cr2	push	iy	;��������� ��������� ����
	pop	ix
	jp	.cr0

.nextcheck
;��� ���� ��������� ������� ����������� �������� �� ��������� �����
	ld	ix,MBRTable
	call	GetExtended
	jp	c,.nextcheck1
	call	NextSecondary
.cr01	push	ix
	call	NextSecondary
	push	ix
	pop	iy
	pop	ix
	jr	c,.nextcheck1
;�������� ��������� ��������

	ld	l,(ix)
	ld	h,(ix+1)
	
	ld	e,(ix+13)
	ld	d,(ix+14)
	and	a
	add	hl,de
	ex	de,hl
	ld	l,(ix+2)
	ld	h,(ix+3)
	ld	c,(ix+15)
	ld	b,(ix+16)
	adc	hl,bc
	push	hl
	pop	bc
;� BC:DE ����� ������� ������� �������
	ld	l,(ix+17)	;������ �������
	ld	h,(ix+18)
	and	a
	add	hl,de
	push	hl		;������� ����� � ����

	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ex	de,hl		;������� ����� � DE
;���������� ����. ������ �� ��������

	ld	l,(iy)		;������ ������ �������
	ld	h,(iy+1)
	
	ld	c,(iy+13)	;����� �������
	ld	b,(iy+14)
	and	a
	add	hl,bc
	push	hl		;������� ����� � ����
	ld	l,(iy+2)	;������� ����� ������� ������� �������
	ld	h,(iy+3)
	ld	c,(iy+15)	;������� ����� ������� �������
	ld	b,(iy+16)
	adc	hl,bc		;������� ����� ������ ����. �������
	and	a
	sbc	hl,de		;
	jr	z,.cr6		;������� ����� ���������?
;�� ���������
;CY = 1 - ������ ������ "�������" �� ������
	jr	c,.incorrect2
;CY = 0	- ���� ��������� ����� ����� ���������
.cr51	push	hl
	pop	bc
	pop	hl
	pop	de
	sbc	hl,de
.cr53	ex	de,hl		;������ ���������� ������� � BC:DE
	call	addMBRUS

	jr	.cr7		;����������

.incorrect2
	ld	hl,msgIncorrect
	PCHARS
;	������� � ��������� � ����.����
;	jr .cr1	

.cr6	pop	hl
	pop	de
	and	a
	sbc	hl,de
	jr	z,.cr7		;����� ������� ������� ��������� �� ������ �������?
;���!
;CY = 1 - ������ ������ "�������" �� ������
;CY = 0	- ���� ��������� ����� ����� ���������
	jr	nc,.cr53
.cr7	push	iy	;��������� ��������� ����
	pop	ix
	jp	.cr01


.nextcheck1
	call	GetLastPartition
	ld	a,(ix+9)
	and	a
	jp	z,.hddclear
	ld	l,(ix)		;������ ������ �������
	ld	h,(ix+1)
	ld	c,(ix+13)	;����� �������
	ld	b,(ix+14)
	and	a
	add	hl,bc
	push	hl		;������� ����� � ����
	ld	l,(ix+2)	;������� ����� ������� ������� �������
	ld	h,(ix+3)
	ld	c,(ix+15)	;������� ����� ������� �������
	ld	b,(ix+16)
	adc	hl,bc		;������� ����� ������ ����. �������
	ex	de,hl
	ld	hl,(hddTotalSector)
	and	a
	pop	bc
	sbc	hl,bc
	push	hl
	ld	hl,(hddTotalSector+2)
	sbc	hl,de
	pop	de
	ld	a,h
	or	l
	or	d
	or	e
	jr	z,.countunused
	;ex	de,hl
	;� hl:de ������ ������� �� ������ ����������� ������� �� ����� �����
;	push	bc
	ex	de,hl
	;� hl ��. ����� ������� �������
	ld	c,(ix+0x0c+5)	;������ �������� ��.�����
	ld	b,(ix+0x0d+5)	;������ �������� ��.�����
	and	a
	sbc	hl,bc
	ex	de,hl
;	push	bc
;	pop	hl
	ld	c,(ix+0x0e+5)	;������ �������� ��.�����
	ld	b,(ix+0x0f+5)	;������ �������� ��.�����
	sbc	hl,bc
	ld	a,h
	or	l
	or	d
	or	e
	jr	z,.countunused
	ld	b,h
	ld	c,l
	call	addMBRUS

.countunused
;������� ������ ���������� ���������� �����
	ld	hl,0
	ld	(tUnused),hl
	ld	(tUnused+2),hl
	ld	a,(cntMBRUS)
	ld	ix,MBRUSTable
	and	a
	jr	z,.l2
.l1	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,(tUnused+2)
	and	a
	add	hl,bc
	ld	(tUnused+2),hl
	ld	hl,(tUnused)
	ld	c,(ix+6)
	ld	b,(ix+7)
	adc	hl,bc
	ld	(tUnused),hl
	dec	a
	jr	nz,.l1
.l2	ld	bc,(tUnused)
	ld	de,(tUnused+2)
	ret

.hddclear
;�� ����� �� ���������� ������ � MBR, ������ ���� ������!
	ld	a,(hddSectors)
	ld	l,a
	ld	h,0
	ld	iy,MBRUSTable
	ld	(iy),l
	ld	(iy+1),h
	ld	(iy+2),h
	ld	(iy+3),h
	ex	de,hl
	ld	hl,(hddTotalSector)
	and	a
	sbc	hl,de
	ld	(iy+4),l
	ld	(iy+5),h
	ld	hl,(hddTotalSector+2)
	ld	(iy+6),l
	ld	(iy+7),h
	ld	a,1
	ld	(cntMBRUS),a
	jr	.countunused

;�������� ������ � ����.�����
;bc:de - ������
;bc':de' - �����

addMBRUSItem
	exx
	call	CheckAdequacy
	exx
	ret	c
	push	iy
	ld	iy,(tMBRUS)
	ld	(iy+0),e
	ld	(iy+1),d
	ld	(iy+2),c
	ld	(iy+3),b
	push	iy
	exx
	pop	iy
	ld	(iy+4),e
	ld	(iy+5),d
	ld	(iy+6),c
	ld	(iy+7),b
	exx
	ld	hl,cntMBRUS
	inc	(hl)
	ld	de,8
	add	iy,de
	ld	(tMBRUS),iy
	pop	iy
	ret

;��������� 2� 32 ������ �����
;In:
;1 - hl:hl'
;2 - de:de'
;Out CY = 1 : 1<2,
;    CY = 0 : 1>2
Compare32
	exx
	push	hl
	and	a
	sbc	hl,de
	pop	hl
	exx
	push	hl
	sbc	hl,de
	pop	hl
	ret


;�������� �� ����������� ����� ���������� ����� ��� �������� ��������
;BC:DE - ������ �������
;out:
;CY =1 - ����� ������� ������ 0�1000 �������� (2��)
CheckAdequacy
	push	hl
	;push	bc
	push	de
	push	de
	pop	hl
	ld	de,0x1000
	and	a
	sbc	hl,de
	push	bc
	pop	hl
	ld	de,0
	sbc	hl,de
	pop	de
	;pop	bc
	pop	hl
	ret

;������ ���������� ������� � BC:DE
;IX ��������� �� ������ � ��������, �� ������� ���� ������ �����
addMBRUS
	call	CheckAdequacy
	ret	c
	push	iy
	ld	iy,(tMBRUS)
	ld	(iy+4),e
	ld	(iy+5),d
	ld	(iy+6),c
	ld	(iy+7),b

;������������ ��������� ������ ���������� �������

	ld	l,(ix)
	ld	h,(ix+1)
	
	ld	e,(ix+13)
	ld	d,(ix+14)
	and	a
	add	hl,de
	ex	de,hl
	ld	l,(ix+2)
	ld	h,(ix+3)
	ld	c,(ix+15)
	ld	b,(ix+16)
	adc	hl,bc
	push	hl
	pop	bc
;� BC:DE ����� ������� ������� �������
	ld	l,(ix+17)	;������ �������
	ld	h,(ix+18)
	and	a
	add	hl,de
	ld	(iy),l
	ld	(iy+1),h
	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ld	(iy+2),l
	ld	(iy+3),h
	ld	hl,cntMBRUS
	inc	(hl)
	ld	de,8
	add	iy,de
	ld	(tMBRUS),iy
	pop	iy
	ret

;������� ������� �������� �� �����
;IX - ������� ��������
;A - ���-�� ��������
ShowPartitions
	ld	b,0
	ld	c,a
.s3	call	ShowPartInfo
	ld	de,MBRFIELDSIZE
	add	ix,de
	dec	c
	jr	nz,.s3
	ret

;���������� � IX ����� ��������� ������ � MBRTable

GetLastPartition
	ld	ix,MBRTable
	ld	a,(partCount)
	ld	de,MBRFIELDSIZE
.n1	dec	a
	ret	z
	add	ix,de
	jr	.n1

;���������� ����� ������, ��������������� ������������ ������� � ���
;Z - ��!
;CY = 1 & A= 0 - ����� �� ������� ��� (����� ��������� �� EBR)
;CY = 1 & A = #FF - ����� �������

GetExtended
	ld	de,MBRFIELDSIZE
.n1	call	CheckPrimary
	ret	c
	ld	a,(ix+9)
	cp	5
	ret	z
	cp	15
	ret	z
	add	ix,de
	jr	.n1

;���������� ����� ������, ��������������� MFS ������� � ���
;Z - ��!
;CY = 1 & A= 0 - ����� �� ������� ��� (����� ��������� �� EBR)
;CY = 1 & A = #FF - ����� �������

GetMFS
	ld	de,MBRFIELDSIZE
.n1	add	ix,de
	call	CheckPrimary
	ret	c
	ld	a,(ix+9)
	cp	0x53
	ret	z
	jr	.n1

;���������� ����. ������ � ��������� ��������	
NextSecondary
	ld	de,MBRFIELDSIZE
.n1	add	ix,de
	call	CheckSecondary
	ret	c
	ld	a,(ix+9)
	cp	5
	jr	z,.n1
	cp	15
	jr	z,.n1
.n2	and	a
	ret

;�������� ������ ������� - secondary ������  ��� ���
; CY = 1 & A = 0 �� secondary
; CY = 1 & A = #FF ������- ��������� ����� �������
; CY = 0, A = FS Type - secondary ������

CheckSecondary
	ld	a,(ix)
	or	(ix+1)
	or	(ix+2)
	or	(ix+3)
	scf
	ret	z
	ld	a,(ix+9)
	and	a
	jr	z,cpend
	ret
;�������� ������ ������� - ������� ������  ��� ���
; CY = 1 & A = 0 �� �������
; CY = 1 & A = #FF ������- ��������� ����� �������
; CY = 0, A = FS Type - ������� ������
CheckPrimary
	ld	a,(ix)
	or	(ix+1)
	or	(ix+2)
	or	(ix+3)
	ld	a,0
	scf
	ret	nz
	ld	a,(ix+9)	;fs type
	and	a
	ret	nz
cpend	ld	a,#ff		;����� �������
	scf
	ret

;���������� ����� ������, ��������� �� �������, � ������� ��������� �������� ������� ��������
NextPrimary
	ld	de,MBRFIELDSIZE
.n1	add	ix,de
	call	CheckPrimary
	ret	nz
	ret	c
	jr	.n1

;���������� ����� ������ MBR � �������, �� ����� �������� ��������� A (� 1)
GetMBRROWbyNum
	ld	ix,MBRTable
	ld	de,MBRFIELDSIZE
.g1	dec	a
	ret	z
	add	ix,de
	jr	.g1


;��������� LBA-����� � CHS
;Input HL:BC - LBA
;Output HL - Cylinder, B - Sector, C - Head
LBAtoCHS
;������ CHS
;���������� ��������� LBA-����� � CHS
; cylinder = LBA / (heads_per_cylinder * sectors_per_track)
; temp = LBA % (heads_per_cylinder * sectors_per_track)
; head = temp / sectors_per_track
; sector = temp % sectors_per_track + 1

	push	hl
	push	bc
;������� heads*sectors
	ld	a,(hddHeads)
	ld	c,a
	ld	b,0
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	call	MUL16
;� BC heads*sectors
	push	bc
	pop	de
;������� cylinder �� ������������� �������, � DE - heads*sectors
;	ld	c,(ix+0)
;	ld	b,(ix+1)
;	ld	l,(ix+2)
;	ld	h,(ix+3)
	pop	bc
	pop	hl
	call	DIV_HLBC_DE
;hl - temp
;bc - cylinder
;	ld	(dCrTemp),hl
	push	bc

;	ld	(dCrCylinder),bc
	push	hl
	pop	bc
;������� ����� ������ �� ������� temp/sectors
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	call	DIV16
;bc - head
;hl - sector-1
	inc	l
	ld	b,l
;	ld	(bCrHead),a
;	ld	a,l
;	inc	a
;	ld	(bCrSector),a
	pop	hl
;CHS ���������!!!
	ret

tMBRUS	dw	0	;���������� ��� �������� ��������� �� ���. ������ � MBRUSTable
tUnused	dw	0,0
msgMBRUSRow
	db	COL,C_CMD,"["
.num	db	"000] ",COL,C_NORM,"- "
.start	db	"00000000 "
.len	db	"00000000 "
.lenbytes
	db	"00000 "
.mb	db	"Mb",CR,LF,EN
msgIncorrect
	db	CR,LF,COL,C_WARN,"Incorrect sequence of partition in MBR",COL,C_NORM,CR,LF,EN