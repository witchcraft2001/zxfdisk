;----------------------------------------------------
;	Изменение ID раздела
;----------------------------------------------------

ChangeTypeFS
	ld	hl,msgChangeTypeFS
	PCHARS
	ld	hl,msgPromptNumber
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,2
	call	EditString
	pop 	hl
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
;Проверка раздела - изменить ID у Extended нельзя!
	ld	(selPartition),a
	ld	ix,MBRTable
	ld	de,MBRFIELDSIZE
.ct5	dec	a
	jr	z,.ct4
	add	ix,de
	jr	.ct5
.ct4	ld	a,(ix+9)	;fs type
	cp	5
	jr	z,.ct6
	cp	15
	jr	z,.ct6
	push	ix
	ld	hl,msgListFS
	PCHARS
	call	ShowFSTable
	ld	hl,msgNewID
	PCHARS
	ld	hl,bufStr
	push	hl
	ld	a,3
	call	EditString
	pop	hl
	call	MRNUM
	pop	ix
	jr	c,.ct2
	ld	a,c
	and	a
	jr	z,.ct2
	cp	5
	jr	z,.notsetext
	cp	15
	jr	z,.notsetext
	ld	(ix+9),a
	ld	hl,cntOperations
	inc	(hl)
	jp	ShowPartition.continue	;Возврат
.ct6
;Выбран расширенный раздел - ошибка!
	ld	hl,msgExtNoModify
	PCHARS
	jp	hddCMD
.notsetext
	ld	hl,msgNoExt
	PCHARS
	jp	hddCMD
selPartition
	db	0	;номер партиции, выбранной для изменения ID
msgExtNoModify
	db	CR,LF,COL,C_WARN,"Can't modify ID of extended partition!",COL,C_NORM,CR,LF,EN
msgNoExt
	db	CR,LF,COL,C_WARN,"Can't set ID indicating the extended partition (such as #05, #15) on primary or secondary partition!",COL,C_NORM,CR,LF,EN
msgNewID
	db	CR,LF,"Enter a new partition ID: ",EN
msgListFS
	db	CR,LF,"List of common systems:",CR,LF,EN
msgChangeTypeFS
	db	"Modify ID (FS Type)",CR,LF,EN
