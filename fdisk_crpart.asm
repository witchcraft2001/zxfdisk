CreatePartition
	ld	hl,msgCrPartition
	PCHARS

	ld	a,(partCount)
;≈сли диск пустой, то возможно создать Pri, Ext & MFS
	and	a
	ld	c,%00000011
	jr	z,.crmenupart
	ld	bc,3*256
	ld	ix,MBRTable
.n1	call	NextPrimary
	jr	c,.n2
	djnz	.n1
.n2	ld	a,b
	and	a
	jr	z,.n5		;а если уже есть 4 примари партиций, то и расширенную не создашь!
	ld	c,1		;есть возможность создавать ѕримари разделы
.n3	ld	ix,MBRTable
	call	GetExtended	;ищем Extended раздел в MBR
	jr	c,.n4
	set	2,c		;имеетс€ EXT раздел, можно создавать SEC разделы
	jr	.n5
.n4	set	1,c		
.n5	ld	ix,MBRTable
	call	GetMFS		;ѕоиск раздела MFS
	jr	c,.n6
	set	3,c		;≈сть раздел 0x53 MFS, значит в нем можно создавать MOA LOC разделы
.n6

.crmenupart
	ld	a,c
	and	a
	jr	z,.notcr
	ld	ix,tabCreatePartCMD
	ld	de,CreatePRIPart
	ld	a,"p"
	bit	0,c
	ld	hl,msgCrPrimary		;Create Primary Partition
	call	nz,AddCMD
	ld	de,notImplemented
	ld	a,"e"
	bit	1,c
	ld	hl,msgCrExtended	;Create Extended partition
	call	nz,AddCMD
	ld	de,notImplemented
	ld	a,"s"
	bit	2,c
	ld	hl,msgCrSecondary	;create secondary partition
	call	nz,AddCMD
	ld	de,notImplemented
	ld	a,"m"
	bit	3,c
	ld	hl,msgCrMOALocal	;create MOA Local partition
	call	nz,AddCMD	
	ld	de,ShowPartition.continue
	ld	a,"q"
	ld	hl,msgQuit
	call	AddCMD
	ld	hl,tabCreatePartCMD
	jp	Prompt
.notcr	ld	hl,msgNotingCreate
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue

CreatePRIPart
	call	CreateMBRUSforPRI
	ld	hl,msgCrPrimaryTxt
	PCHARS
	ld	a,(cntMBRUS)
	and	a
	jr	nz,.c1
	ld	hl,msgNoFreeSpace
	PCHARS
	jp	.c2
.c1	ld	hl,msgListFS
	PCHARS
	call	ShowFSTable
	ld	hl,msgNewID	;¬вод id новой партиции
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,3
	call	EditString
	pop	hl
	jp	c,.ct2
	call	MRNUM
	ld	a,c
	ld	(bCrPartType),a
	and	a
	jp	z,.ct2
	cp	5
	jr	z,.c4
	cp	15
	jr	nz,.c3
.c4	
	ld	c,0
	ld	ix,MBRTable
.c6	call	GetExtended
	jr	c,.c5
	inc	c
	jr	.c6
.c5	ld	a,c
	and	a
	jr	z,.c3
	ld	hl,msgFoundExtended
	jp	DosError
.c3	ld	hl,msgSelMBRUS
	PCHARS
	call	ShowMBRUS
	ld	hl,msgEnterFreeSpace
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,3
	call	EditString
	pop	hl
	jp	c,.ct2
	call	MRNUM
	ld	a,(cntMBRUS)
	ld	b,a	
	ld	a,c
	and	a
	jr	z,.ct2
	cp	b
	jr	z,.ct3
	jr	c,.ct3
.ct2	ld	hl,msgInvalidParameter
.err	PCHARS
	_ANYKEY
	jp	ShowPartition.continue
.ct3	ld	(bCrSpace),a
	ld	hl,msgPartitionSize
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,5
	call	EditString
	pop	hl
	jr	c,.ct2
	call	MRNUM
	ld	a,c
	or	b
	jr	z,.ct2
;ѕереводим ћб в сектора
	xor	a
	ld	(dwCrPartSize),a
	dup	3
	rl	c
	rl	b
	rl	a
	edup	
	ld	(dwCrPartSize+3),a
	ld	(dwCrPartSize+1),bc
	ld	a,(bCrSpace)
	ld	ix,MBRUSTable
	ld	de,MBRUSFIELDSIZE
.cr4	dec	a
	jr	z,.cr3
	add	ix,de
	jr	.cr4
.cr3
	push	ix
;ѕровер€ем помещаетс€ ли введенный размер в заданную область?
	ld	de,(dwCrPartSize)
	ld	l,(ix+4)
	ld	h,(ix+5)
	ld	c,(ix+6)
	ld	b,(ix+7)
	push	bc
	exx
	pop	hl
	ld	de,(dwCrPartSize+2)
	call	Compare32
	ld	hl,msgSizeTooLarge
	jp	c,.err
;—оздаем запись в таблице
	ld	c,(ix+0)
	ld	b,(ix+1)
	ld	l,(ix+2)
	ld	h,(ix+3)
	call	LBAtoCHS
	ld	(dCrCylinder),hl
	ld	a,c
	ld	(bCrHead),a
	ld	a,b
	ld	(bCrSector),a
	ld	a,(partCount)
	inc	a
	call	GetMBRROWbyNum
	sub	a
	ld	(ix+0),a
	ld	(ix+1),a
	ld	(ix+2),a
	ld	(ix+3),a
	dec	a
	ld	(ix+4),a	;Number of partition, #ff - временный номер, после сортировки помен€етс€ на верный
	xor	a
	ld	(ix+5),a	;active
;	ld	a,(bCrHead)
	ld	(ix+6),c	;head
	ld	a,b	;(bCrSector)
	and	63
	ld	b,a
	ld	a,h	;(dCrCylinder+1)
	and	3
	rrca
	rrca
	or	b
	ld	(ix+7),a	;Sector+H.Cylinder
	ld	a,l	;(dCrCylinder)
	ld	(ix+8),a	;L.Cylinder
	ld	a,(bCrPartType)
	ld	(ix+9),a	;PartID
	pop	iy
;в iy у нас строка MBRUSTable
;расчитываем адрес CHS конца раздела
	ld	hl,(dwCrPartSize)
	ld	c,(iy+0)
	ld	b,(iy+1)
	add	hl,bc
	push	hl
	ld	hl,(dwCrPartSize+2)
	ld	c,(iy+2)
	ld	b,(iy+3)
	adc	hl,bc
	pop	bc
	and	a
	dec	bc
	jr	nc,.decHLBC
	dec	hl
.decHLBC
	call	LBAtoCHS
	ld	(ix+10),c	;head
	ld	a,b	;(bCrSector)
	and	63
	ld	b,a
	ld	a,h	;(dCrCylinder+1)
	and	3
	rrca
	rrca
	or	b
	ld	(ix+11),a	;Sector+H.Cylinder
	ld	a,l	;(dCrCylinder)
	ld	(ix+12),a	;L.Cylinder
;LBA	начало
	ld	a,(iy+0)
	ld	(ix+13),a
	ld	a,(iy+1)
	ld	(ix+14),a
	ld	a,(iy+2)
	ld	(ix+15),a
	ld	a,(iy+3)
	ld	(ix+16),a
	ld	hl,(dwCrPartSize)
	ld	(ix+17),l
	ld	(ix+18),h
	ld	hl,(dwCrPartSize+2)
	ld	(ix+19),l
	ld	(ix+20),h
	ld	de,21
	push	ix
	pop	hl
	add	hl,de
	ex	de,hl
	ld	hl,txtNoLabel
	ld	bc,11
	ldir
	ld	hl,partCount
	inc	(hl)
	ld	hl,cntOperations
	inc	(hl)
	ld	hl,msgOK
	PCHARS
.c2	_ANYKEY
	jp	ShowPartition.continue
dCrTemp	dw	0
dCrCylinder
	dw	0
bCrHead	db	0
bCrSector
	db	0
bCrSpace
	db	0
bCrPartType
	db	0
dwCrPartSize
	dw	0,0
tabCreatePartCMD
	ds	3*4
	db	0
msgSizeTooLarge
	db	CR,LF,COL,C_WARN,"The entered size too large!",COL,C_NORM,CR,LF,EN
msgEnterFreeSpace
	db	CR,LF,"Enter number of free space for new partition: ",EN
msgPartitionSize
	db	CR,LF,"Enter size of partition, Mb: ",EN
msgCrPrimaryTxt
	db	"Create PRIMARY partition...",CR,LF,EN
msgCrSecondaryTxt
	db	"Create SECONDARY partition...",CR,LF,EN
msgCrExtendedTxt
	db	"Create EXTENDED partition...",CR,LF,EN
msgFoundExtended
	db	CR,LF,COL,C_WARN,"Extended partition must be the only one!",COL,C_NORM,CR,LF,EN
msgSelMBRUS
	db	CR,LF,"Select free space on disk for new partition:",CR,LF,CR,LF
	db	"        Start    Size,sec Size",CR,LF
	db	"        -------- -------- --------",CR,LF,EN
msgNotingCreate
	db	CR,LF,COL,C_WARN,"Can't create any partition on this disk!",COL,C_NORM,CR,LF,EN
msgCrPartition
	db	"Create partition...",CR,LF
	db	CR,LF,"Select command: ",EN
msgCrPrimary
	db	COL,C_CMD,"[P] ",COL,C_NORM,"- "
.txt	db	"Create PRI part. ",EN
msgCrExtended
	db	COL,C_CMD,"[E] ",COL,C_NORM,"- "
.txt	db	"Create EXT part. ",EN
msgCrSecondary
	db	COL,C_CMD,"[S] ",COL,C_NORM,"- "
.txt	db	"Create SEC part. ",EN
msgCrMOALocal
	db	COL,C_CMD,"[M] ",COL,C_NORM,"- "
.txt	db	"Create MOA Local part. ",EN
msgNoFreeSpace
	db	CR,LF,COL,C_WARN,"Not enought free space!",COL,C_NORM,CR,LF,EN
