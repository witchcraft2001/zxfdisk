;----------------------------------------------------
;	”даление раздела
;----------------------------------------------------

DeletePart
	ld	hl,msgDeletePart
	PCHARS
	ld	hl,msgPromptNumber
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
.ct3	dec	a
	call	DelRowFromMBR		;удаление раздела из таблицы
	ld	hl,cntOperations
	inc	(hl)
	ld	hl,msgOK
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue

msgDeletePart
	db	"Delete partition...",CR,LF,EN
