BackupPartitions
	ld	hl,msgBackup
	PCHARS
;	call	dlgPending
;	jp	c,ShowPartition.continue
.reentername
	ld	hl,msgBackupEnter
	PCHARS
	ld	hl,bufStr
	ld	a,8
	call	EditString
	jp	c,ShowPartition.continue
;�������� �����
	ld	hl,SectorBuffer
	ld	d,h
	ld	e,l
	inc	de
	ld	(hl),0
	ld	bc,1023
	ldir
;�������� ����� �������

;���������� �����
	ld	de,SectorBuffer+16
	ld	hl,strPartSign
	ld	bc,10
	ldir
	ld	a,"0"
	ld	(de),a
	inc	de
	ld	hl,Buffer	;SerialNumber
	ld	a,(devSelected)
	dec	a
	jr	nz,.n3
	ld	hl,Buffer+512	;SLAVE Serial Number
.n3	
	push	hl
;������
	ld	a,27
	ld	b,40
	call	CopyVars
	pop	hl
;�������� �����
	ld	a,10
	ld	b,20
	call	CopyVars

;�������� ��������� �����
	ld	hl,hddCylinders
	ld	bc,8
	ldir

	ld	a,(partCount)
	ld	(de),a
	inc	de
	ld	hl,0
	ld	bc,MBRFIELDSIZE
.b1	add	hl,bc
	dec	a
	jr	nz,.b1
;	ld	(dFileSize),hl
	ld	b,h
	ld	c,l
	ld	hl,MBRTable
	ldir
	ld	hl,SectorBuffer+16
	ex	de,hl
	and	a
	sbc	hl,de
	ld	(dFileSize),hl
;������������ �����

;����� �����
	ld	de,SectorBuffer
	ld	hl,bufStr
	ld	bc,8
	ldir
	ex	de,hl
	ld	(hl),"m"
	inc	hl
	ld	(hl),"b"
	inc	hl
	ld	(hl),"r"
;	ld	de,23773	;���������� �����
	ld	hl,SectorBuffer
	ld	c,0x13
	call	_trdos
	ld	a,11		;���������� �������� ��� ������
	ld	(23814),a
	ld	c,0x0a
	call	_trdos
;	jp	c,GeneralDosError
	inc	c
	jr	z,.nofile
	;���� ����������, ������������ ����?
	ld	hl,msgFileExist
	PCHARS
	ld	hl,tabYesNo
	call	Prompt
	jp	c,.reentername
	;��������
	ld	c,0x12
	call	_trdos
	jp	c,GeneralDosError
.nofile
	;�������� ������ �����
	
	;������ ����.������ � ���
	ld	hl,SectorBuffer2
	ld	de,8
	ld	bc,0x0105
	call	_trdos
	jp	c,GeneralDosError

	ld	a,(dFileSize+1)
	inc	a
	ld	(SectorBuffer+0x0d),a	;sectors

	ld	hl,(SectorBuffer2+0xe5)	;���������� ��������� ��������
	ld	e,a
	ld	d,0
	and	a
	sbc	hl,de	
	ld	(SectorBuffer2+0xe5),hl
	ld	hl,msgDOSNoFree
	jp	c,DosError

	ld	hl,(dFileSize)
	ld	(SectorBuffer+0x0b),hl	;size
	ld	de,(SectorBuffer2+0xe1)	;������ ����.������ � ����
	ld	(SectorBuffer+0x0e),de

	ld	c,0x13			;set file descriptor
	ld	hl,SectorBuffer
	call	_trdos

	ld	a,(SectorBuffer2+0xE4)	;���-�� ������ �� �������
	cp	128
	ld	hl,msgDOSDirFull
	jp	nc,DosError
	ld	c,0x09
	call	_trdos
	jp	c,GeneralDosError

	ld	a,(SectorBuffer2+0xE4)	;���-�� ������ �� �������
	inc	a
	ld	(SectorBuffer2+0xE4),a
	ld	de,(SectorBuffer2+0xe1)
	ld	a,(SectorBuffer+0x0d)
;	ld	a,(dFileSize+1)
;	inc	a
	add	a,e
	cp	16
	jr	c,.nocarry
	sub	16
	inc	d
.nocarry
	ld	e,a
	ld	(SectorBuffer2+0xe1),de

	ld	de,(SectorBuffer+0x0e)	;������ ������ � ���� �����
	ld	hl,SectorBuffer+16
	ld	a,(SectorBuffer+0x0d)
	;����� ����
	ld	b,a
	ld	c,6
	call	_trdos
	jp	c,GeneralDosError

	ld	hl,SectorBuffer2
	ld	bc,0x0106
	ld	de,8
	call	_trdos
	jp	c,GeneralDosError
	ld	hl,msgOK
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue

RestorePartition
	ld	hl,msgRestore
	PCHARS
	call	dlgPending
	jp	c,ShowPartition.continue

	call	FindMBRFiles
	jp	c,GeneralDosError
	ld	(bFilesCount),a
	and	a
	jr	nz,.rest
	ld	hl,msgNoFiles
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue
.rest	ld	hl,msgFounded
	PCHARS
	call	GetFirstMBRName
	jp	c,ShowPartition.continue
	;ret	c		;error
	ld	a,(bFilesCount)
	ld	b,a
.lp0	push	bc
	ld	a,(bFilesCount)
	inc	a
	sub	b
	push	af
	ld	l,a
	ld	bc,msgNames.num
	call	PRNUM
	push	ix
	pop	hl
	ld	de,msgNames.name
	ld	bc,8
	ldir
	inc	de
	ld	c,3
	ldir
	ld	hl,msgNames
	PCHARS
	pop	af
	and	1
	jr	nz,.lp1
	ld	hl,msgCRLF
	PCHARS
.lp1	call	GetNextMBRName
	pop	bc
	djnz	.lp0
	ld	a,(bFilesCount)
	and	1
	jr	z,.n1
	ld	hl,msgCRLF
	PCHARS
.n1	ld	hl,msgNumber
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,3
	call	EditString
	pop	hl
	jp	c,ShowPartition.continue
	call	MRNUM
	jr	c,.inval
	ld	a,(bFilesCount)
	ld	b,a	
	ld	a,c
	and	a
	scf
	jr	z,.inval
	cp	b
	jr	z,.ld1
	jr	c,.ld1
.inval	ld	hl,msgInvalidParameter

	PCHARS
	_ANYKEY
	jp	ShowPartition.continue

.ld1	call	GetMBRSpec
	ld	e,(ix+0x0e)	;sec
	ld	d,(ix+0x0f)	;trk
	ld	a,(ix+0x0d)	;lenght
	cp	3
	ld	hl,msgFileBig
	jp	nc,DosError
	ld	b,a		;������ �����
	ld	c,5
	ld	hl,SectorBuffer
	call	_trdos
	jp	c,GeneralDosError
	ld	hl,strPartSign
	ld	de,SectorBuffer
	ld	b,10
	call	Compare
	jr	nc,.ok1
	ld	hl,msgNotBackup
	jp	DosError
.ok1
;���������� ���������� �� �����
	ld	hl,SectorBuffer+11
	ld	de,msgBackInfo.model
	ld	bc,40
	ldir
	ld	hl,SectorBuffer+51
	ld	de,msgBackInfo.sn
	ld	bc,20
	ldir
	ld	hl,(SectorBuffer+71)
	ld	bc,msgBackInfo.cyl
	call	PRNUM0
	ld	a,(SectorBuffer+73)
	ld	l,a
	ld	bc,msgBackInfo.head
	call	PRNUM
	ld	a,(SectorBuffer+74)
	ld	l,a
	ld	bc,msgBackInfo.sec
	call	PRNUM	
	ld	a,(SectorBuffer+79)
	ld	l,a
	ld	bc,msgBackInfo.recs
	call	PRNUM
	ld	hl,msgBackInfo
	PCHARS
	ld	ix,SectorBuffer+80
	ld	a,(SectorBuffer+79)
	ld	c,a
	ld	b,0
.ss3	call	ShowPartInfo
	ld	de,MBRFIELDSIZE
	add	ix,de
	dec	c
	jr	nz,.ss3


;���������� ��������� �����
	ld	hl,Buffer	;SerialNumber
	ld	a,(devSelected)
	dec	a
	jr	nz,.n3
	ld	hl,Buffer+512	;SLAVE Serial Number
.n3	push	hl
;������
	ld	a,27
	ld	b,40
	ld	de,bufStr
	push	de
	call	CopyVars
	pop	de
	ld	hl,SectorBuffer+11
	ld	b,40
	call	Compare
	pop	hl
	jp	c,.different
;�������� �����
	ld	a,10
	ld	b,20
	ld	de,bufStr
	push	de
	call	CopyVars
	pop	de
	ld	b,20
	ld	hl,SectorBuffer+51
	call	Compare
	jp	c,.different

	ld	hl,msgBackLoad
	PCHARS
	call	dlgYesNo
	jp	c,ShowPartition.continue
;clear table
	ld	hl,MBRTable
	ld	de,MBRTable+1
	ld	(hl),0
	ld	bc,MAXMBRFIELDS*MBRFIELDSIZE-1
	ldir
;��������� ������ � ������� �� �����
	ld	a,(SectorBuffer+79)	;���������� ������� � �����
	ld	(partCount),a

	ld	de,MBRFIELDSIZE
	ld	hl,0
.s1	add	hl,de
	dec	a
	jr	nz,.s1
	ld	b,h
	ld	c,l	
	ld	hl,SectorBuffer+80
	ld	de,MBRTable
	ldir
	ld	a,1
	ld	(cntOperations),a
	ld	hl,msgOK
.s3	PCHARS
	_ANYKEY
	jp	ShowPartition.continue
.different
	ld	hl,msgDifferent
	jr	.s3
;----------------------------------------
;	��������� ���� �����
;----------------------------------------
Compare	ld	a,(de)
	cp	(hl)
	scf
	ret	nz
	inc	de
	inc	hl
	djnz	Compare
	and	a
	ret

;----------------------------------------
;	��������� ��� ������ ������ MBR
;----------------------------------------
FindMBRFiles
	;������ ������� �������
	ld	hl,SectorBuffer	;������������ ����� ������� ������� ������ � ������ ��������
	ld	bc,8*256+5
	ld	de,0
	call	_trdos
	ret	c
	ld	bc,128*256	;128 ���������
	ld	ix,SectorBuffer
	ld	de,16
.loop	ld	a,(ix)
	and	a
	jr	z,.end
	dec	a		;���� ������?
	jr	z,.next
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"m"
	jr	nz,.next
	ld	a,(ix+9)
	cp	"b"
	jr	nz,.next
	ld	a,(ix+10)
	cp	"r"
	jr	nz,.next
	inc	c		;������� ��������� ������
.next	add	ix,de
	djnz	.loop
.end	ld	a,c
	and	a
	ret
GetFirstMBRName
	ld	ix,SectorBuffer
	ld	a,(ix)
	and	a
	jr	z,GetNextMBRName.end
	dec	a		;���� ������?
	jr	z,GetNextMBRName
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"m"
	jr	nz,GetNextMBRName
	ld	a,(ix+9)
	cp	"b"
	jr	nz,GetNextMBRName
	ld	a,(ix+10)
	cp	"r"
	jr	nz,GetNextMBRName
	and	a
	ret
;�� ����� ix - ���.������, �� ������ - ����.
;CY = 1 - ����� ��������
GetNextMBRName
	ld	de,16
	ld	bc,SectorBuffer+2048	;����� ��������� ��������

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
	cp	"m"
	jr	nz,.next
	ld	a,(ix+9)
	cp	"b"
	jr	nz,.next
	ld	a,(ix+10)
	cp	"r"
	jr	nz,.next
	and	a
	ret
.end	scf
	ret
;������� ��������� �� ������������ ����� ��������, ����� � �
GetMBRSpec
	ld	de,16
	ld	ix,SectorBuffer
	ld	c,a
	ld	b,128		;���-�� ������
.loop	ld	a,(ix)
	and	a
	jr	z,.end
	dec	a		;���� ������?
	jr	z,.skip
	ld	a,(ix+8)	;�������� ���������� drv
	cp	"m"
	jr	nz,.skip
	ld	a,(ix+9)
	cp	"b"
	jr	nz,.skip
	ld	a,(ix+10)
	cp	"r"
	jr	nz,.skip
	dec	c
	ret	z
.skip
.next	add	ix,de
	djnz	.loop
.end	scf
	ret
;--------------------------------------------------
dFileSize
	dw	0
bFilesCount
	db	0

;--------------------------------------------------
msgNames
	db	COL,C_CMD,"["
.num	db	"000] ",COL,C_NORM,"- "
.name	db	"FILENAME.ext    ",EN

msgFounded
	db	CR,LF,"Available files:",CR,LF,EN
msgNoFiles
	db	CR,LF,COL,C_WARN,"No *.MBR files found on this disk!",COL,C_NORM,CR,LF,EN
msgDifferent
	db	CR,LF,COL,C_WARN,"This file for a different HDD! Operation aborted!",COL,C_NORM,CR,LF,EN
msgNumber
	db	CR,LF,"Enter number of file to load: ",EN
msgFileExist
	db	CR,LF,COL,C_WARN,"File exist! Owerwrite? (y/n): ",COL,C_NORM,CR,LF,EN
msgFileBig
	db	CR,LF,COL,C_WARN,"File too big!",COL,C_NORM,CR,LF,EN
msgRestore
	db	"Restore Partition Table from File...",CR,LF,EN
msgBackup
	db	"Backup Partition Table to File...",CR,LF,EN
msgBackupEnter
	db	CR,LF,"Enter file name: ",EN
msgBackInfo
	db	CR,LF,"Information on selected file:"
	db	CR,LF,"  Model: ",COL,C_VAL,"["
.model	ds	40,32
	db	"]",COL,C_NORM,CR,LF,"  Serial Number: ",COL,C_VAL,"["
.sn	ds	20,32
	db	"]",COL,C_NORM,CR,LF
	db	"  Cylinders: ",COL,C_VAL,"["
.cyl	db	"00000]",COL,C_NORM," Heads: ",COL,C_VAL,"["
.head	db	"000]",COL,C_NORM," Sectors: ",COL,C_VAL,"["
.sec	db	"000]",COL,C_NORM,CR,LF,"  Partitions: ",COL,C_VAL,"["
.recs	db	"000]",COL,C_NORM,CR,LF
	db	"Partition list:",CR,LF,EN
msgBackLoad
	db	CR,LF,COL,C_WARN,"Are you sure want to load this file? (y/n): ",COL,C_NORM
	db	EN
msgNotBackup
	db	CR,LF,COL,C_WARN,"This is not backup file!",COL,C_NORM,CR,LF,EN