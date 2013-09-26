;Форматирование разделов
FormatPartition
	ld	hl,msgFormatPartition
	PCHARS
	ld	a,(cntOperations)
	and	a
	jr	z,.ct4
	ld	hl,msgApplyBeforeThisOps
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue
.ct4	ld	hl,msgPromptNumber
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,2
	call	EditString
	pop 	hl
	jp	c,ShowPartition.continue
	call	MRNUM
	jr	c,.ct2
	ld	a,(partCount)
	ld	b,a	
	ld	a,c
	and	a
	jr	z,.ct2
.ct1	cp	b
	jr	z,.ct3
	jr	c,.ct3
.ct2	ld	hl,msgInvalidParameter
	PCHARS
	jp	hddCMD
.ct3
	ld	a,c
	call	GetMBRROWbyNum
	ld	a,(ix+9)	;ID
	ld	b,a
	push	af
	ld	de,msgFormatFS.type
	call	GetFSName
	ld	hl,msgFormatFS
	PCHARS
	pop	af
	cp	5
	jr	z,ExtPartFormat
	cp	15
	jr	z,ExtPartFormat
	cp	0x53
	jr	z,FormatMOA
	jr	UnknownFS
FormatMOA
	;Форматирование локальных разделов MOA FS
	jp	notImplemented
ExtPartFormat
	ld	hl,msgFormatExt
	jr	ErrFormat
UnknownFS
	ld	hl,msgNotSupported
ErrFormat
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue
msgFormatFS
	db	CR,LF,"Type: ",COL,C_VAL,"["
.type	db	"0123456789Abcdef]",COL,C_NORM,CR,LF,EN
msgFormatExt
	db	CR,LF,COL,C_WARN,"Extended partition can not be formatted!",COL,C_NORM,CR,LF,EN
msgNotSupported
	db	CR,LF,COL,C_WARN,"This file system is not supported!",COL,C_NORM,CR,LF,EN
msgFormatPartition
	db	"Format partition...",CR,LF,EN

