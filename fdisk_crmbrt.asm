;�������� � ��� ������� �������� ���������� �����
;MBRTableFields:
;+0	4bytes	LBA offset
;+4	1	number of field in table
;+5	16	Partition Table Entry
;+21	11	����� ����, ���� ����������

CreateMBRTable
	xor	a
	ld	(chMBRTable),a	;���� ��������� MBR-�������
	ld	(partCount),a
;clear table
	ld	hl,MBRTable
	ld	de,MBRTable+1
	ld	(hl),a
	ld	bc,MAXMBRFIELDS*MBRFIELDSIZE-1
	ldir

	ld	hl,SectorBuffer
	exx
	ld	de,0	; lba 32-48 == 0
	exx
	ld	de,0
	ld	bc,0
	ld	(cLBAhigh),bc
	ld	(cLBAlow),de
	IF _IM = 1
	call	IM1SET
	ENDIF
	call	hDrvEntry	;������ 1�� ������� � �����
	db	4
	IF _IM = 1
	call	IM2SET
	ENDIF
	ld	hl,(SectorBuffer+510)
	ld	de,#AA55
	and	a
	sbc	hl,de
	ld	a,255
	scf
	ret	nz	;������������ ��������� BR
	ld	ix,SectorBuffer+0x01be	;������ ������� �������� � MBR �������
	ld	b,4
	ld	c,0
.lp1	call	CheckTableEntry
	jr	c,.exit		;CY =1 ���� ������� �����������
	ld	de,16
	add	ix,de
	inc	c
	djnz	.lp1
.exit	
;���������� ��������� ������� �� ������� ����������� �������� � ��������� ���� �� ���...
	ld	ix,MBRTable
.searchext
	ld	a,(ix+9)	;Partition type descriptor
	and	a
	jr	z,.exit2
	cp	5
	jr	z,.extend1
	cp	15
	jr	nz,.noext1
.extend1
;������� �������� ������� ������������ ��������
	ld	l,(ix)
	ld	h,(ix+1)
	
	ld	e,(ix+13)
	ld	d,(ix+14)
	and	a
	add	hl,de
	ld	bc,0
	jr	nc,.e1
	ld	bc,1
.e1	ex	de,hl
	ld	l,(ix+2)
	ld	h,(ix+3)
	add	hl,bc		;����������� �� 1, ���� ��� ������� �� �������� �����
	ld	c,(ix+15)
	ld	b,(ix+16)
	add	hl,bc
	push	hl
	pop	bc
	exx
	ld	de,0		;lba 32-48 == 0
	exx
	ld	(cLBAhigh),bc
	ld	(cLBAlow),de
	IF _IM = 1
	call	IM1SET
	ENDIF
	ld	hl,SectorBuffer
	call	hDrvEntry	;������ 1�� ������� � �����
	db	4
	IF _IM = 1
	call	IM2SET
	ENDIF
	ld	hl,(SectorBuffer+510)
	ld	de,#AA55
	and	a
	sbc	hl,de
	jr	nz,.noext1
	push	ix
	ld	bc,2*256
	ld	ix,SectorBuffer+0x01be	;������ ������� �������� � EBR �������
.lp2	call	CheckTableEntry
	jr	c,.endext
	ld	de,16
	add	ix,de
	inc	c
	djnz	.lp2
.endext	pop	ix
.noext1	ld	de,MBRFIELDSIZE
	add	ix,de
	jr	.searchext
.exit2	ld	a,(partCount)
	and	a
	ret
;��������� ������ � ������� MBR, �� ������� ��������� HL, ���� ��� ������������� �����������, �� �������� � ������� � ���
;hl - ����� ������
CheckTableEntry
	ld	a,(ix)
	and	a
	jr	z,.n1
	cp	0x80
	scf
	ret	nz
.n1	ld	a,(ix+4)	;Partition type descriptor
	and	a
	scf
	ret	z
	ld	a,(partCount)
	ld	de,MBRFIELDSIZE
	ld	hl,MBRTable
	and	a
	jr	z,.n2
.n3	add	hl,de
	dec	a
	jr	nz,.n3
.n2	ld	de,(cLBAlow)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	de,(cLBAhigh)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(hl),c
	inc	hl
	push	ix
	pop	de
	ex	de,hl
	push	bc
	ld	bc,16
	ldir
	ld	a,(ix+4)
;����������� ����� ����
	ld	hl,txtExtended
	cp	5
	jr	z,.n4
	cp	15
	jr	z,.n4
	cp	1
	jr	z,.n5
	cp	4
	jr	z,.n5
	cp	6
	jr	z,.n5
;	cp	7	;NTFS
;	jr	z,.n5	;
	cp	0x0b
	jr	z,.n5
	cp	0x0c
	jr	z,.n5
	cp	0x0e
	ld	hl,txtNoLabel
	jr	nz,.n4
.n5	push	de
;������������ ��������� ������ �������
	ld	e,(ix+8)
	ld	d,(ix+9)
	ld	hl,(cLBAlow)
	add	hl,de
	ex	de,hl	
	ld	hl,(cLBAhigh)
	ld	c,(ix+10)
	ld	b,(ix+11)
	adc	hl,bc
	push	hl
	pop	bc
	exx
	ld	de,0		;lba 32-47 == 0
	exx
	IF _IM = 1
	call	IM1SET
	ENDIF
	ld	hl,SectorBuffer1
	call	hDrvEntry
	db	4	;������ ������ ������ ������� FAT, ���� ������ �������� ����
	IF _IM = 1
	call	IM2SET
	ENDIF
	ld	hl,(SectorBuffer1+510)
	ld	de,#aa55	;��������� ��������� boot-sector-�
	and	a
	sbc	hl,de
	ld	hl,txtNoLabel
	jr	nz,.n6
	ld	hl,(SectorBuffer1+54)	;FAT12/16?
	ld	de,0x4146	;"FA" �� ��������� FAT
	and	a
	sbc	hl,de
	ld	hl,SectorBuffer1+43
	jr	z,.n6
	ld	hl,(SectorBuffer1+82)
	and	a
	sbc	hl,de
	ld	hl,txtNoLabel
	jr	nz,.n6
	ld	hl,SectorBuffer1+71
.n6	pop	de
.n4	ld	bc,11
	ldir
	pop	bc
	ld	hl,partCount
	inc	(hl)
	and	a
	ret
txtNoLabel
	db	"<NO LABEL> "	;����� ��-���������
txtExtended
	db	"Extended   "	;����� ��� ������������ �������
cLBAhigh
	dw	0	;������� ������� ������� (��� ����������� ������������ ������� �������)
cLBAlow	dw	0
chMBRTable
	db	0	;���� ��������� MBR-�������
;partCount
;	db	0	;���������� �������