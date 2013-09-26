;---------------------------------------------------------
;	Удаление одной строки из таблицы разделов
;---------------------------------------------------------
;на входе A - номер записи
;на выходе CY = 1 - таблица пуста
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
.skip1	push	hl	;текущая запись
	add	hl,de	;следующая запись
	pop	de
;рассчитываем количество записей, которые идут после указанной
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
	ldir		;перемещаем блок на одну запись вверх по таблице
.null	ld	hl,partCount
	dec	(hl)
	ret

;---------------------------------------------------------
;	Определение свободного места на винте
;	(вызывать после GetHDDPar)
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
;Расчет номера первого сектора раздела
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
;в BC:DE номер первого сектора раздела
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
;в BC:DE номер сектора, следующий за последним разделом
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
;отображает строку со свободным местом на диске
;в IX - строка в таблице MBRUSTable
;в C - номер строки
;--------------------------------------------------
ShowMBRUSRow
	push	bc
	push	de
	ld	l,b
	inc	l
	ld	bc,msgMBRUSRow.num
	call	PRNUM
;печать начала
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
;печать длины	
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
;из объема в секторах получаем объем в мб, гб
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
	jp	z,CreateMBRUS.hddclear	;нет разделов
;Проверим, может быть первый раздел в таблице не с самого начала диска
	ld	ix,MBRTable
.cr00	xor	a
	or	(ix+14)
	or	(ix+15)
	or	(ix+16)
;если старшие 3 байта начала партиции !=0, то партиция не в начале диска

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
;определяем свободное место среди примари разделов
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
;в BC:DE номер первого сектора раздела
	ld	l,(ix+17)	;Размер раздела
	ld	h,(ix+18)
	and	a
	add	hl,de
	push	hl		;младшее слово в стек

	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ex	de,hl		;старшее слово в DE
;рассчитали след. сектор за разделом

	ld	l,(iy)
	ld	h,(iy+1)
	
	ld	c,(iy+13)
	ld	b,(iy+14)
	and	a
	add	hl,bc
	push	hl		;младшее слово в стек
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	c,(iy+15)
	ld	b,(iy+16)
	adc	hl,bc		;старшее слово начала след. раздела
	and	a
	sbc	hl,de		;
	jr	z,.cr1		;старшие слова совпадают?
;не совпадают
;CY = 1 - первый раздел "налазит" на второй
	jr	c,.incorrect1
;CY = 0	- есть свободное место между разделами
.cr5	push	hl
	pop	bc
	pop	hl
	pop	de
	sbc	hl,de
.cr52	ex	de,hl		;размер свободного участка в BC:DE
	call	addMBRUS

	jr	.cr2		;продолжаем
.incorrect1
	ld	hl,msgIncorrect
	PCHARS
;	скипаем и переходим к след.паре
;	jr .cr1	

.cr1	pop	hl
	pop	de
	and	a
	sbc	hl,de
	jr	z,.cr2		;конец первого раздела указывает на начало второго?
;нет!
;CY = 1 - первый раздел "налазит" на второй
;CY = 0	- есть свободное место между разделами
	jr	nc,.cr52
.cr2	push	iy	;проверяем следующую пару
	pop	ix
	jp	.cr0
.nextcheck
;Определяем свободный участок после последнего примари раздела
;в IX - адрес последнего примари раздела
	ld	a,(ix+9)
	and	a
	jp	z,CreateMBRUS.hddclear
	ld	l,(ix)		;первый сектор раздела
	ld	h,(ix+1)
	ld	c,(ix+13)	;длина раздела
	ld	b,(ix+14)
	and	a
	add	hl,bc
	push	hl		;младшее слово в стек
	ld	l,(ix+2)	;старшее слово первого сектора раздела
	ld	h,(ix+3)
	ld	c,(ix+15)	;старшее слово размера раздела
	ld	b,(ix+16)
	adc	hl,bc		;старшее слово начала след. раздела
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
	;в hl:de размер области от начала предыдущего раздела до конца диска
;	push	bc
	ex	de,hl
	;в hl мл. слово размера области
	ld	c,(ix+0x0c+5)	;размер партиции мл.слово
	ld	b,(ix+0x0d+5)	;размер партиции мл.слово
	and	a
	sbc	hl,bc
	ex	de,hl
;	push	bc
;	pop	hl
	ld	c,(ix+0x0e+5)	;размер партиции ст.слово
	ld	b,(ix+0x0f+5)	;размер партиции ст.слово
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
;	Определение свободного места на винте
;	(вызывать после GetHDDPar)
;---------------------------------------------------------
;Описание MBRUSTable
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
	jp	z,.hddclear	;нет разделов
;Проверим, может быть первый раздел в таблице не с самого начала диска
	ld	ix,MBRTable
.cr00	xor	a
	or	(ix+14)
	or	(ix+15)
	or	(ix+16)
;если старшие 3 байта начала партиции !=0, то партиция не в начале диска

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
;определяем свободное место среди примари разделов
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
;в BC:DE номер первого сектора раздела
	ld	l,(ix+17)	;Размер раздела
	ld	h,(ix+18)
	and	a
	add	hl,de
	push	hl		;младшее слово в стек

	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ex	de,hl		;старшее слово в DE
;рассчитали след. сектор за разделом

	ld	l,(iy)
	ld	h,(iy+1)
	
	ld	c,(iy+13)
	ld	b,(iy+14)
	and	a
	add	hl,bc
	push	hl		;младшее слово в стек
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	c,(iy+15)
	ld	b,(iy+16)
	adc	hl,bc		;старшее слово начала след. раздела
	and	a
	sbc	hl,de		;
	jr	z,.cr1		;старшие слова совпадают?
;не совпадают
;CY = 1 - первый раздел "налазит" на второй
	jr	c,.incorrect1
;CY = 0	- есть свободное место между разделами
.cr5	push	hl
	pop	bc
	pop	hl
	pop	de
	sbc	hl,de
.cr52	ex	de,hl		;размер свободного участка в BC:DE
	call	addMBRUS

	jr	.cr2		;продолжаем
.incorrect1
	ld	hl,msgIncorrect
	PCHARS
;	скипаем и переходим к след.паре
;	jr .cr1	

.cr1	pop	hl
	pop	de
	and	a
	sbc	hl,de
	jr	z,.cr2		;конец первого раздела указывает на начало второго?
;нет!
;CY = 1 - первый раздел "налазит" на второй
;CY = 0	- есть свободное место между разделами
	jr	nc,.cr52
.cr2	push	iy	;проверяем следующую пару
	pop	ix
	jp	.cr0

.nextcheck
;тут надо проверить таблицу расширенных разделов на свободное место
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
;проверка вторичных разделов

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
;в BC:DE номер первого сектора раздела
	ld	l,(ix+17)	;Размер раздела
	ld	h,(ix+18)
	and	a
	add	hl,de
	push	hl		;младшее слово в стек

	ld	l,(ix+19)
	ld	h,(ix+20)
	adc	hl,bc
	ex	de,hl		;старшее слово в DE
;рассчитали след. сектор за разделом

	ld	l,(iy)		;первый сектор раздела
	ld	h,(iy+1)
	
	ld	c,(iy+13)	;длина раздела
	ld	b,(iy+14)
	and	a
	add	hl,bc
	push	hl		;младшее слово в стек
	ld	l,(iy+2)	;старшее слово первого сектора раздела
	ld	h,(iy+3)
	ld	c,(iy+15)	;старшее слово размера раздела
	ld	b,(iy+16)
	adc	hl,bc		;старшее слово начала след. раздела
	and	a
	sbc	hl,de		;
	jr	z,.cr6		;старшие слова совпадают?
;не совпадают
;CY = 1 - первый раздел "налазит" на второй
	jr	c,.incorrect2
;CY = 0	- есть свободное место между разделами
.cr51	push	hl
	pop	bc
	pop	hl
	pop	de
	sbc	hl,de
.cr53	ex	de,hl		;размер свободного участка в BC:DE
	call	addMBRUS

	jr	.cr7		;продолжаем

.incorrect2
	ld	hl,msgIncorrect
	PCHARS
;	скипаем и переходим к след.паре
;	jr .cr1	

.cr6	pop	hl
	pop	de
	and	a
	sbc	hl,de
	jr	z,.cr7		;конец первого раздела указывает на начало второго?
;нет!
;CY = 1 - первый раздел "налазит" на второй
;CY = 0	- есть свободное место между разделами
	jr	nc,.cr53
.cr7	push	iy	;проверяем следующую пару
	pop	ix
	jp	.cr01


.nextcheck1
	call	GetLastPartition
	ld	a,(ix+9)
	and	a
	jp	z,.hddclear
	ld	l,(ix)		;первый сектор раздела
	ld	h,(ix+1)
	ld	c,(ix+13)	;длина раздела
	ld	b,(ix+14)
	and	a
	add	hl,bc
	push	hl		;младшее слово в стек
	ld	l,(ix+2)	;старшее слово первого сектора раздела
	ld	h,(ix+3)
	ld	c,(ix+15)	;старшее слово размера раздела
	ld	b,(ix+16)
	adc	hl,bc		;старшее слово начала след. раздела
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
	;в hl:de размер области от начала предыдущего раздела до конца диска
;	push	bc
	ex	de,hl
	;в hl мл. слово размера области
	ld	c,(ix+0x0c+5)	;размер партиции мл.слово
	ld	b,(ix+0x0d+5)	;размер партиции мл.слово
	and	a
	sbc	hl,bc
	ex	de,hl
;	push	bc
;	pop	hl
	ld	c,(ix+0x0e+5)	;размер партиции ст.слово
	ld	b,(ix+0x0f+5)	;размер партиции ст.слово
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
;Подсчет общего количества свободного места
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
;на винте не обнаружены записи в MBR, значит винт пустой!
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

;Добавить запись о своб.месте
;bc:de - начало
;bc':de' - длина

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

;Сравнение 2х 32 битных чисел
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


;Проверка на достаточную длину свободного места для создания партиции
;BC:DE - длинна раздела
;out:
;CY =1 - длина раздела меньше 0х1000 секторов (2Мб)
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

;размер свободного участка в BC:DE
;IX указывает на запись с разделом, за которым идет пустое место
addMBRUS
	call	CheckAdequacy
	ret	c
	push	iy
	ld	iy,(tMBRUS)
	ld	(iy+4),e
	ld	(iy+5),d
	ld	(iy+6),c
	ld	(iy+7),b

;рассчитываем начальный сектор свободного участка

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
;в BC:DE номер первого сектора раздела
	ld	l,(ix+17)	;Размер раздела
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

;Выводит листинг партиций на экран
;IX - таблица партиций
;A - кол-во партиций
ShowPartitions
	ld	b,0
	ld	c,a
.s3	call	ShowPartInfo
	ld	de,MBRFIELDSIZE
	add	ix,de
	dec	c
	jr	nz,.s3
	ret

;Возвращает в IX адрес последней записи в MBRTable

GetLastPartition
	ld	ix,MBRTable
	ld	a,(partCount)
	ld	de,MBRFIELDSIZE
.n1	dec	a
	ret	z
	add	ix,de
	jr	.n1

;Возвращает адрес записи, соотвутствующей расширенному разделу в МБР
;Z - ОК!
;CY = 1 & A= 0 - вышли за пределы МБР (адрес указывает на EBR)
;CY = 1 & A = #FF - конец таблицы

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

;Возвращает адрес записи, соотвутствующей MFS разделу в МБР
;Z - ОК!
;CY = 1 & A= 0 - вышли за пределы МБР (адрес указывает на EBR)
;CY = 1 & A = #FF - конец таблицы

GetMFS
	ld	de,MBRFIELDSIZE
.n1	add	ix,de
	call	CheckPrimary
	ret	c
	ld	a,(ix+9)
	cp	0x53
	ret	z
	jr	.n1

;Возвращает след. запись с секондари разделом	
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

;Проверка записи раздела - secondary раздел  или нет
; CY = 1 & A = 0 не secondary
; CY = 1 & A = #FF ошибка- достигнут конец таблицы
; CY = 0, A = FS Type - secondary раздел

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
;Проверка записи раздела - примари раздел  или нет
; CY = 1 & A = 0 не примари
; CY = 1 & A = #FF ошибка- достигнут конец таблицы
; CY = 0, A = FS Type - примари раздел
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
cpend	ld	a,#ff		;конец таблицы
	scf
	ret

;Возвращает адрес записи, следующей за текущей, в которой находится описание примари партиции
NextPrimary
	ld	de,MBRFIELDSIZE
.n1	add	ix,de
	call	CheckPrimary
	ret	nz
	ret	c
	jr	.n1

;Возвращает адрес записи MBR в таблице, на номер которого указывает A (с 1)
GetMBRROWbyNum
	ld	ix,MBRTable
	ld	de,MBRFIELDSIZE
.g1	dec	a
	ret	z
	add	ix,de
	jr	.g1


;перевести LBA-адрес в CHS
;Input HL:BC - LBA
;Output HL - Cylinder, B - Sector, C - Head
LBAtoCHS
;Расчет CHS
;Необходимо перевести LBA-адрес в CHS
; cylinder = LBA / (heads_per_cylinder * sectors_per_track)
; temp = LBA % (heads_per_cylinder * sectors_per_track)
; head = temp / sectors_per_track
; sector = temp % sectors_per_track + 1

	push	hl
	push	bc
;Считаем heads*sectors
	ld	a,(hddHeads)
	ld	c,a
	ld	b,0
	ld	a,(hddSectors)
	ld	e,a
	ld	d,0
	call	MUL16
;в BC heads*sectors
	push	bc
	pop	de
;Считаем cylinder по вышеуказанной формуле, в DE - heads*sectors
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
;считаем номер головы по формуле temp/sectors
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
;CHS рассчитан!!!
	ret

tMBRUS	dw	0	;переменная для хранения указателя на тек. запись в MBRUSTable
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