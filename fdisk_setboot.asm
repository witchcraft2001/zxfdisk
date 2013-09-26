SetBootable
	ld	hl,msgSetBootable
	PCHARS
	ld	a,(partCount)
	and	a
	jr	nz,.sb0
	ld	hl,msgMBRTableIsNull
	PCHARS
	jp	hddCMD
.sb0
	ld	hl,msgPromptNumber
	PCHARS
	ld	hl,bufStr
	ld	a,2
	call	EditString
	ld	hl,bufStr
	call	MRNUM
	jr	c,.sb2
	ld	a,(partCount)
	ld	b,a	
	ld	a,c
	and	a
	jr	z,.sb2
.sb1	cp	b
	jr	z,.sb3
	jr	c,.sb3
.sb2	ld	hl,msgInvalidParameter
	PCHARS
	jp	hddCMD
.sb3	ld	ix,MBRTable
	ld	de,MBRFIELDSIZE
.sb5	dec	a
	jr	z,.sb4
	add	ix,de
	jr	.sb5
.sb4	ld	a,(ix)
	or	(ix+1)
	or	(ix+2)
	or	(ix+3)
	jr	nz,.extnoboot
	ld	a,(ix+9)
	cp	5
	jr	z,.extnoboot
	cp	15
	jr	z,.extnoboot
	ld	a,(ix+5)
	cp	#80
	jr	z,.bootable
;снимаем загрузочные флаги с других разделов
	ld	hl,MBRTable+5
	ld	a,(partCount)
.sb6	ld	(hl),0
	add	hl,de
	dec	a
	jr	nz,.sb6
	ld	a,#80
	ld	(ix+5),a
	ld	hl,cntOperations
	inc	(hl)
	jp	ShowPartition.continue	;Возврат
.bootable
	ld	hl,msgBootable
	PCHARS
	jp	hddCMD
	
.extnoboot
	ld	hl,msgNoBootable
	PCHARS
	jp	hddCMD
msgBootable
	db	CR,LF,"Bootable flag is already set for this partition!",CR,LF,EN
msgNoBootable
	db	CR,LF,COL,C_WARN,"Can not set the bootable flag for an extended or logical partition!",COL,C_NORM,CR,LF,EN
msgSetBootable
	db	"Set bootable flag on partition",CR,LF,EN

