;--------------------------------------------------
;Ожидание нажатия клавиш, переход в подпрограмму, обработки горячей клавиши
;HL - таблица клавиш и адресов обработчиков
;--------------------------------------------------
Prompt	ld	(.keys+1),hl
	ld	hl,msgPrompt
	PCHARS	
;	call	CursorOn

.key	ld	c,0x32	;ECHOKEY
	ei
	rst	0x10
	ld	b,e
.keys	ld	hl,0
	ld	a,l
	or	h
	ret	z
;	jp	z,CursorOff	;таблица не задана - выход
.keys1	ld	a,(hl)
	and	a
	jr	z,.key
	inc	hl
	cp	b
	jr	z,.found
	inc	hl
	inc	hl
	jr	.keys1
.found	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	jp	(hl)
;	call	CursorOff
;	ld	a,(23560)
;	ld	a,b
;	jp	PrintSym
;--------------------------------------------------
;Ввод текста
;hl - адрес буфера
;a - макс количество символов
;Выход:
;hl - адрес начала буфера
;a - кол-во введенных симв
;C = 1 - выход по бряку
;--------------------------------------------------
EditString
	ld	(.edMax),a
	ld	(.edBuf),hl
	push	hl
	pop	de
	inc	de
	ld	c,a
	ld	b,0
	ld	(hl),32
	ldir
	xor	a
	ld	(.edCur),a
	ld	(hl),b
	ld	de,(COORDS)
	ld	(.edCRDS),de
.k2	
	;call	CursorOff

	ld	de,(.edCRDS)
	ld	(COORDS),de
	ld	hl,(.edBuf)
	PCHARS
	ld	de,(.edCRDS)
	ld	a,(.edCur)
	add	a,d
	ld	d,a
	ld	(COORDS),de
;	call	CursorOn
.key
	ld	c,0x32
	ei
	rst	0x10
	ld	a,b
	cp	0x0c
	jr	z,.del
	cp	13
	jr	z,.enter
	ld	b,a
	ld	hl,(.edBuf)
	ld	a,(.edCur)
	ld	c,a
	ld	a,(.edMax)
	cp	c
	jr	z,.k2
	ld	a,c
	add	a,l
	ld	l,a
	jr	nc,.k1
	inc	h
.k1	ld	(hl),b
	ld	a,(.edMax)
	ld	c,a
	ld	a,(.edCur)
	cp	c
	jr	nc,.k2
	inc	a
	ld	(.edCur),a
	jr	.k2
.del	ld	a,(.edCur)
	and	a
	jr	z,.k2
	dec	a
	ld	(.edCur),a
	ld	hl,(.edBuf)
	add	a,l
	ld	l,a
	jr	nc,.k3
	inc	h
.k3	ld	(hl),32
	jr	.k2
.enter	
	;call	CursorOff
	ld	a,(.edCur)
	ld	hl,(.edBuf)
	and	a
	ret
.break
    	ld  hl,(.edBuf)
    	xor a
    	scf
    	ret    
.edMax	db	0	;макс символов
.edBuf	dw	0	;буфер для текста
.edCRDS	dw	0	;сохраненные координаты
.edCur	db	0	;тек символ