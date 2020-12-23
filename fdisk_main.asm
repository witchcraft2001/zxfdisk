	device zxspectrum128
 DEFINE	MAIN 1
;Color settings
C_CMD	equ	6	;цвет команды
C_NORM	equ	7	;цвет нормального текста
C_WARN	equ	2	;цвет предупреждения
C_VAL	equ	5	;цвет значения
C_PRI	equ	4	;цвет первичных разделов
C_SEC	equ	3	;цвет вторичных разделов
C_EXT	equ	1	;Цвет расширенного раздела
C_DMP	equ	4	;цвет дампа

	include "fdisk_equs.inc"
	include "target.inc"
	include	"fdisk_macro.inc"

IMVector	EQU	#BE00
MAXMBRFIELDS	EQU	15	;максимальное количество записей MBR
MBRFIELDSIZE	equ	32	;размер записи
MBRUSFIELDSIZE	equ	8	;размер записи в таблице неиспользуемого пространства 4б - старт, 4б - длина
MAXMBRUS	equ	8	;макс.количество записей в MBRSUTable
 IF _TARGET=_ATM | _TARGET = _SPRINTER
MAXSHORTSNSHOW	equ	20	;максимальное количество знаков с/н, отображаемого в краткой инфе
MAXSHORTMODELSHOW	equ	30;максимальное количество знаков модели в краткой инфе !!!Кратно 2!!!
 ELSE
MAXSHORTSNSHOW	equ	12	;максимальное количество знаков с/н, отображаемого в краткой инфе
MAXSHORTMODELSHOW	equ	24;максимальное количество знаков модели в краткой инфе !!!Кратно 2!!! 
 ENDIF
	include "build.inc"
 define VERSION "0.2"
;Для сборки релиз-версии версии раскоментировать следующую строку
 ;DEFINE RELEASE 1
 IFNDEF RELEASE
  DEFINE DEBUG 1
 ENDIF

 IF _TARGET = _PROFI
 	DEFINE _TARGET_T "Profi"
_IM	EQU	1
 ENDIF
 IF _TARGET = _ATM
 	DEFINE _TARGET_T "ATM-Turbo2"
_IM	EQU	1

 ENDIF
 IF _TARGET = _ZX128
  	DEFINE _TARGET_T "ZX-Spectrum128K"
_IM	EQU	1
 ENDIF
 IF _TARGET = _SPRINTER
 	DEFINE _TARGET_T "Sprinter"
_IM	EQU	0
 ENDIF

;Для кросс-платформенности
 IF _TARGET=_ZX128 | _TARGET=_PROFI | _TARGET=_ATM
_ORG	equ	#6000
 ENDIF
 IF _TARGET=_SPRINTER
_ORG	equ	#8100
 ENDIF
	org	_ORG
FDISKSTART

;Драйвер контроллера жесткого диска
hDrvSign
	IF _TARGET=_PROFI
	include "drv\profi_drv.asm"
	ELSE
	 IF  _TARGET=_ATM
	include "drv\atm_drv.asm"
	 ELSE
	  IF _TARGET=_SPRINTER
	include "drv\sprinter_drv.asm"
	  ELSE
	;По-умолчанию включаем NemoIDE
	include "drv\nemo_drv.asm"
	  ENDIF
	 ENDIF
	ENDIF

hDrvVersion=hDrvSign+5
hDrvEntry=hDrvSign+32
_DRVORG=hDrvSign
 IF $-hDrvSign>=1024
	Display "WARNING! Driver size too big!!!"
 ENDIF

;выравниваем адрес по границе в 1кб (размер драйвера не должен превышать 1кб)

 IF _TARGET=_ZX128 | _TARGET=_PROFI | _TARGET=_ATM
	align	1024
 ENDIF

 IF _TARGET=_ZX128
font	insert "bins\64qua+.fnt"
 ELSE
	IF _TARGET =_PROFI
font	insert "bins\866_code_H.fnt"	
	ENDIF
 ENDIF

;------------------------------------------------------
;	***   Старт   ***
;------------------------------------------------------
MainStart
	di
	ld	sp,_ORG-1
	ld	hl,JMP_Table
	ld	de,#bf02
	ld	bc,JMP_TableEnd-JMP_Table
	ldir
 IF _TARGET = _SPRINTER
	ld	(idMem),a
	ld	(arrPages),hl
	ld	(ARGV),ix
 ENDIF
	INITCONSOLE
 IF _TARGET=_ZX128 | _TARGET=_PROFI | _TARGET=_ATM
	xor	a
	ld	(curShow),a 	
 	call	OpenPG
	call	IM2Init
 ENDIF
MainLoop
;добавить диалог выбора драйвера и загрузку его в ОЗУ

 IF _TARGET=_ZX128 | _TARGET=_PROFI | _TARGET=_ATM
	ld	hl,msgHello
	PCHARS

	call	LoadDriver
;Проверка сигнатуры драйвера
	ld	hl,msgSign
	ld	de,hDrvSign
	ld	b,4
.signchk
	ld	a,(de)
	cp	(hl)
	jp	nz,wrong
	inc	de
	inc	hl
	djnz	.signchk

;Драйвер наш - успокаиваемся!
;Печатаем информацию о драйвере
	ld	a,(DrvLoaded)
	ld	hl,strDrvFileName
	and	a
	jr	z,.ne1
	ld	hl,msgDrvLoad.name
.ne1
 ELSE
	ld	hl,strDrvFileName
 ENDIF
	ld	de,msgDriver.fn
	ld	bc,12
	ldir
	ld	hl,hDrvVersion
	ld	de,msgDriver.str
	ld	bc,27
	ldir
	CLS
MainNoDrvLoad

	ld	hl,msgHello
	PCHARS

	ld	hl,msgDriver
	PCHARS

	ld	hl,msgFindDrives
	PCHARS
;Обнуляем список операций
	xor	a
	ld	(cntOperations),a


;Инициируем приводы
	IF _IM = 1
	call	IM1SET
	ENDIF
	di
	ld	hl,Buffer
 IF _TARGET = _ZX128
	xor	a
 ENDIF
 IF _TARGET = _PROFI
	ld	a,#80
 ENDIF
 IF _TARGET = _ATM
	ld	a,%10101110
 ENDIF
	call	hDrvEntry
	db	0	;HDDInit
	ld	(statDrv),hl
	IF _IM = 1
	call	IM2SET
	ENDIF
	xor	a
	call	ShowStat
	ld	a,1
	call	ShowStat
	ld	hl,(statDrv)
	ld	de,#0101
	and	a
	sbc	hl,de
	jr	nz,.l1
;нет ни одного винта - предупреждаем и возвращаемся к выбору драйвера
.l4	ld	hl,msgHDDNotFound
	PCHARS
	jr	wr1
.l1	
	add	hl,de
	ld	de,#ffff
	and	a
	sbc	hl,de
	jr	z,.l4
;Найдено 1 или 2 устройства
	add	hl,de
	ld	a,l	;Есть оба устройства?
	or	h
	jr	z,.l3
	push	hl
	ld	hl,msgSelected
	PCHARS
	pop	hl
	ld	a,h
	ld	hl,msgMaster
	and	a
	jr	z,.l2
;Выбор мастера
	ld	a,1
	ld	hl,msgSlave
.l2	ld	(devSelected),a
	PCHARS
	ld	hl,msgDevice
	PCHARS
	ld	hl,msgAnyKeyQuit
	PCHARS
	ld	hl,0
	call	Prompt
	cp	"q"
	jp	z,dlgAppQuit
	ld	a,(devSelected)
	jr	selHDD
.l3
;Найдено 2 устройства, доверим выбор пользователю
	ld	hl,msgSelectDrive
	PCHARS
	ld	hl,tblMasterSlave
	jp	Prompt
	
;Сигнатура в драйвере не правильная
wrong	ld	hl,msgSignFail
	PCHARS
wr1	
	ld	hl,msgAnyKey
	PCHARS

	ld	hl,0
	call	Prompt
	CLS
	jp	MainLoop
jpMain	CLS		;Очистка экрана и возврат к началу
	jp	MainNoDrvLoad
tblMasterSlave
	db	"1"
	dw	hddMaster
	db	"2"
	dw	hddSlave
	db	"q"
	dw	dlgAppQuit
	db	0
tblLarge
	db	"y"
	dw	ShowPartition
	db	"n"
	dw	jpMain
	db	0

;---------------------------------------------------------
;	Выбор пользователем привода
;---------------------------------------------------------
hddMaster
	xor	a
	jr	selHDD

hddSlave
	ld	a,1
selHDD	ld	(devSelected),a
;Проверка размера жесткого диска
	ld	h,high Buffer
	and	a
	jr	z,.s1
	ld	h,high (Buffer+512)
.s1	ld	l,83*2+1	;83 word of Device Identify data
	ld	a,(hl)
	and	4	;Support LBA48?	w83 10bit==1 is supported
	jr	z,ShowPartition	;no - okay
	ld	l,60*2		;при lba48 должно присутствовать #0fffffff
	ld	a,(hl)
	inc	hl
	and	(hl)
	inc	hl
	and	(hl)
	inc	a
	jr	nz,ShowPartition
	inc	hl
	ld	a,(hl)
	cp	15
	jr	nz,ShowPartition
	ld	a,(hDrvSign+4)
	and	1		;Поддерживается LBA48?
	jr	nz,ShowPartition
	ld	hl,msgLarge
	PCHARS
	ld	hl,tblLarge
	jp	Prompt
;---------------------------------------------------------
;	Отображение партиций на винте
;---------------------------------------------------------
ShowPartition
	ld	a,(devSelected)
	push	af
	inc	a
	ld	(.s1),a
	IF _IM = 1
	call	IM1SET
	ENDIF
	call	hDrvEntry
.s1	db	0	;Установка текущим для операций Master или Slave
	IF _IM = 1
	call	IM2SET
	ENDIF
	call	CreateMBRTable	;анализ диска и построение таблицы BR в ОЗУ	
	pop	af
	call	GetHDDPar
	xor	a
	ld	(cntOperations),a

.continue
	CLS
	ld	a,(devSelected)
	ld	hl,msgMaster
	dec	a
	jr	nz,.n1
	ld	hl,msgSlave
.n1	PCHARS
	ld	hl,msgDevice
	PCHARS
	ld	hl,msgHDDShortInfo
	PCHARS
	ld	a,(partCount)
	and	a
	jr	nz,.s2
;Ошибка в МБР
	ld	hl,msgMBRNotFound
	PCHARS
	jr	.s0
.s2	ld	hl,msgMBRHead
	PCHARS
	ld	ix,MBRTable
	ld	a,(partCount)
	call	ShowPartitions
;	ld	ix,MBRTable
;	ld	b,0
;	ld	a,(partCount)
;	ld	c,a
;.s3	call	ShowPartInfo
;	ld	de,MBRFIELDSIZE
;	add	ix,de
;	dec	c
;	jr	nz,.s3
.s0	ld	a,(partCount)
	ld	l,a
	ld	bc,msgPartCount.cnt
	call	PRNUM
 IFDEF RELEASE
 	ld	bc,(hddTotalSector+2)
 	ld	de,(hddTotalSector)
 	ld	hl,msgPartCount.total
 	xor	a
 	CALL	PRNUMSEC
 ELSE
;Вывод всего секторов
	ld	de,(hddTotalSector+2)
	ld	hl,msgPartCount.total
	ld	a,d
	call	ByteToHEX
	inc	hl
	ld	a,e
	call	ByteToHEX
	inc	hl
	ld	de,(hddTotalSector)
	ld	a,d
	call	ByteToHEX
	inc	hl
	ld	a,e
	call	ByteToHEX
 ENDIF
;Вывод неиспользуемых секторов	
	call	CreateMBRUS
;	call	CalcUnused
	push	bc
 IFDEF RELEASE
; 	ld	bc,(hddTotalSector+2)
 ;	ld	de,(hddTotalSector)
 	ld	hl,msgPartCount.unused
 	xor	a
 	CALL	PRNUMSEC
 ELSE

	ld	hl,msgPartCount.unused+4
	ld	a,d
	call	ByteToHEX
	inc	hl
	ld	a,e
	call	ByteToHEX
	pop	de
	ld	hl,msgPartCount.unused
	ld	a,d
	call	ByteToHEX
	inc	hl
	ld	a,e
	call	ByteToHEX
 ENDIF
	ld	hl,msgPartCount
	PCHARS
	ld	a,(cntOperations)
	and	a
	jr	z,hddCMD
	ld	l,a
	ld	bc,msgPending.cnt
	call	PRNUM
	ld	hl,msgPending
	PCHARS
hddCMD	ld	hl,msgMBRCommands
	PCHARS
	ld	hl,tabMBRCmd
	JP	Prompt
;	jp	wr1
tabMBRCmd
	db	"q"
	dw	partQuit
	db	"u"
	dw	DSector
	db	"i"
	dw	ChangeTypeFS
	db	"a"
	dw	SetBootable
	db	"b"
	dw	BackupPartitions
	db	"d"
	dw	DeletePart
	db	"s"
	dw	notImplemented
	db	"r"
	dw	RestorePartition
	db	"c"
	dw	CreatePartition
	db	"y"
	dw	notImplemented
	db	"f"
	dw	FormatPartition
	db	0

;--------------------------------------
;	Запрос на отмену совершенных операций
;	на выходе CY==1, если есть незавершенные операции и на запрос "отменить операции" дан отказ
;	cy==0, если нет незавершенных операций или дан утвердительный ответ на их отмену 
;--------------------------------------
dlgPending
	ld	a,(cntOperations)
	and	a		;нет отложенных операций
	ret	z
	ld	hl,msgPendingOps
	PCHARS
dlgYesNo
	ld	hl,tabYesNo
	jp	Prompt
dlgPendYes
	and	a
	ret
dlgPendNo
	scf
	ret

;--------------------------------------
;	Отработка выхода из менеджера партиций
;--------------------------------------
partQuit
	call	dlgPending
	jp	c,ShowPartition.continue
	jp	jpMain

dlgAppQuit
 ;IF _TARGET = _SPRINTER
;	jr	.exit
 ;ELSE
;	jp	jpMain
 ;ENDIF
  IF _IM = 1
  	call	IM1SET
  ENDIF
 IF _TARGET = _SPRINTER
.exit	ld	a,(idMem)
	ld	c,0x3e
	rst	16
	ld	bc,0x0041
	rst	16
 ELSE
.exit
 IF _TARGET = _PROFI | _TARGET=_ATM
 	call	ReturnConsole
 ENDIF
 ;Проверка наличия в 7й папке резидента RC
        LD      A,#17     ;тестирование
        LD      BC,#7FFD  ;7-го банка на
        OUT     (C),A     ;наличие в нем
        LD      HL,(#C000);COMMANDER'а.
        LD      DE,#FF31
        XOR     A
        SBC     HL,DE     ;если найден,
        JP      Z,#C000   ;то запуск
        LD      A,#10
        OUT     (C),A
        AND     A
        SBC     HL,HL
        PUSH    HL        ;иначе рестарт
        JP      15649     ;TR-DOS 
 ENDIF

tabYesNo
	db	"y"
	dw	dlgPendYes
	db	"n"
	dw	dlgPendNo
	db	0

 IFUSED notImplemented
notImplemented
	ld	hl,msgNotImplemented
	PCHARS
	ld	hl,msgAnyKey
	PCHARS
	ld	hl,0
	call	Prompt
	jp	ShowPartition.continue
 ENDIF

;--------------------------------------
;	Вызов Dump Sector
;--------------------------------------

DSector
	ld	hl,msgDumpSector
	PCHARS
	ld	hl,msgPromptNumber0
	PCHARS
	ld	hl,bufStr
	ld	a,2
	call	EditString
	ld	hl,bufStr
	call	MRNUM
	jr	c,.inval
	ld	a,(partCount)
	ld	b,a	
	ld	a,c
	and	a
	jr	nz,.ds1
;показываем нулевой сектор
	ld	de,0
	ld	bc,0
	jp	dumpSector

.ds1	cp	b
	jr	z,.ds2
	jr	c,.ds2
.inval	ld	hl,msgInvalidParameter
	PCHARS
	jp	hddCMD

.ds2
	push	bc
	ld	hl,msgDumpSectorCR
	PCHARS
	ld	ix,MBRTable	;SectorBuffer+0x01be+8
.dmaster
	pop	bc
	ld	de,MBRFIELDSIZE
	jr	.ds4
.ds3	add	ix,de
.ds4	dec	c
	jr	nz,.ds3
;Номер первого сектора раздела
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
	;ld	e,(hl)
;	inc	l
;	ld	d,(hl)
;	inc	l
;	ld	c,(hl)
;	inc	l
;	ld	b,(hl)
	jp	dumpSector
		

;--------------------------------------
;	Вывод информации о партиции	
;--------------------------------------
;в IX - адрес описателя
;B - логический номер партиции
ShowPartInfo
	push	bc
	ld	l,b
	inc	l
	ld	bc,msgMBRRow.num
	call	PRNUM
	ld	a,(ix)
	or	(ix+1)
	or	(ix+2)
	or	(ix+3)
	ld	b,C_PRI
	ld	a,"P"	;Primary
	jr	z,.s1
	ld	a,(ix+9)
	cp	5
	jr	z,.ext1
	cp	15
	jr	z,.ext1
	ld	b,C_SEC
	ld	a,"S"	;Secondary
	jr	.s1
.ext1	ld	a,"E"	;Extended
	ld	b,C_EXT
.s1	ld	(msgMBRRow.num+4),a
	ld	a,b
	ld	(msgMBRRow+1),a
	ld	a,(ix+5)
	cp	#80
	ld	a,"*"	;Bootable
	jr	z,.s2
	ld	a,32
.s2	ld	(msgMBRRow.num+5),a
	ld	a,(ix+9)	;Type
	and	a
	jp	z,.err
	push	af
	ld	hl,msgMBRRow.id
	call	ByteToHEX
;	xor	a
;	ld	(HEXDEC),a
	pop	af
	ld	b,a
	ld	de,msgMBRRow.type
	call	GetFSName

;рассчет смещения сектора относительно текущего
	ld	l,(ix)		;номер сектора текущей записи
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
	add	hl,bc		;увеличиваем на 1, если был перенос из младшего слова
	ld	c,(ix+15)
	ld	b,(ix+16)
	add	hl,bc
	push	hl
	
	ld	a,e
;	ld	a,(ix+13)
	ld	hl,msgMBRRow.start+6
	call	ByteToHEX
;	ld	a,(ix+14)
	ld	a,d
	dec	hl
	dec	hl
	dec	hl
	call	ByteToHEX
	pop	de
;	ld	a,(ix+15)
	ld	a,e
	dec	hl
	dec	hl
	dec	hl
	call	ByteToHEX
;	ld	a,(ix+16)
	ld	a,d
	dec	hl
	dec	hl
	dec	hl
	call	ByteToHEX
;	ld	a,"#"	;вывод в 16-ричной системе
;	ld	(HEXDEC_PRNUM),a

 IF _TARGET=_ATM | _TARGET=_SPRINTER
	ld	hl,msgMBRRow.size
	ld	a,(ix+20)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+19)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+18)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+17)
	call	ByteToHEX
 ELSE
  IFDEF RELEASE
	ld	e,(ix+17)	;размер
	ld	d,(ix+18)
	ld	c,(ix+19)
	ld	b,(ix+20)
	ld	hl,msgMBRRow.size
	ld	a,"M"
	call	PRNUMSEC 
  ELSE
	ld	hl,msgMBRRow.size
	ld	a,(ix+20)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+19)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+18)
	call	ByteToHEX
	inc	hl
	ld	a,(ix+17)
	call	ByteToHEX
  ENDIF
 ENDIF
;	ld	l,(ix+17)	;размер
;	ld	h,(ix+18)
;	ld	bc,msgMBRRow.size+4
;	call	PRNUM0
;	ld	l,(ix+19)
;	ld	h,(ix+20)
;	ld	bc,msgMBRRow.size
;	call	PRNUM0
;	xor	a		;Возвращаемся к 10чной системе
;	ld	(HEXDEC_PRNUM),a

 IF _TARGET=_ATM | _TARGET=_SPRINTER
	ld	e,(ix+17)	;размер
	ld	d,(ix+18)
	ld	c,(ix+19)
	ld	b,(ix+20)
	ld	hl,msgMBRRow.sizeb
	ld	a,"M"
	call	PRNUMSEC
 ENDIF
	push	ix
	pop	hl
	ld	de,21
	add	hl,de
	ld	bc,11
	ld	de,msgMBRRow.label
	ldir
	

	ld	hl,msgMBRRow
	PCHARS
	pop	bc
	inc	b	;увеличиваем логический номер раздела
	and	a
	ret

.err	pop	bc
	scf
	ret

;--------------------------------------------
;	Вывод информации об устройстве
;	на основе сектора состояния
;--------------------------------------------
ShowStat
;Разбор Устройства
;A = 1 - SLAVE
;иные значения A - MASTER
	ld	(.bMaster+1),a
	ld	hl,msgMaster
	dec	a
	jr	nz,.n1
	ld	hl,msgSlave
.n1	PCHARS
	ld	hl,msgDevice
	PCHARS
.bMaster
	ld	a,0
	ld	hl,(statDrv)
	dec	a
	jr	nz,.n2
	ld	h,l
.n2	inc	h
	jr	z,.drvNotFound
	dec	h
	jr	z,.drvIsHDD
	ld	hl,msgNotHDD
	PCHARS
	ret
.drvNotFound
	ld	hl,msgNotFound
	PCHARS
	jr	.n4
.drvIsHDD
	ld	hl,msgFound
	PCHARS
	ld	hl,Buffer	;SerialNumber
	ld	a,(.bMaster+1)
	dec	a
	jr	nz,.n3
	ld	hl,Buffer+512	;SLAVE Serial Number
.n3	push	hl
	ld	a,10
	ld	b,20
	ld	de,msgHDDInfo.sn
	call	CopyVars
	pop	hl
	push	hl
	ld	de,msgHDDInfo.fw
	ld	b,8
	ld	a,23
	call	CopyVars
	pop	hl
	push	hl
	ld	de,msgHDDInfo.model
	ld	b,40
	ld	a,27
	call	CopyVars
	pop	hl
	push	hl
	ld	a,1
	call	GetWord
	ex	de,hl
	ld	bc,msgHDDInfo.cyl
	call	PRNUM0
	pop	hl
	push	hl
	ld	a,3
	call	GetWord
	ex	de,hl
	ld	bc,msgHDDInfo.head
	call	PRNUM
	pop	hl
	ld	a,6
	call	GetWord
	ex	de,hl
	ld	bc,msgHDDInfo.sec
	call	PRNUM	
	ld	hl,msgHDDInfo
	PCHARS
.n4	ld	hl,msgCRLF
	PCHARS
	ret

;---------------------------------------------------------
;	Извлекает информацию о количестве дорожек,
;	голов и секторов из статусного сектора винта
;---------------------------------------------------------
;
GetHDDPar
	ld	hl,Buffer	;SerialNumber
	ld	a,(devSelected)
	dec	a
	jr	nz,.n3
	ld	hl,Buffer+512	;SLAVE Serial Number
.n3	
	push	hl
	ld	a,1
	call	GetWord
	ld	(hddCylinders),de
	pop	hl
	push	hl
	ld	a,3
	call	GetWord
	ld	a,e
	ld	(hddHeads),a
	pop	hl
	push	hl
	ld	a,6
	call	GetWord
	ld	a,e
	ld	(hddSectors),a
	pop	hl
	push	hl
;кастрируем серийный номер - отображаем только последние 8 значащих символов
	ld	a,10
	ld	b,20
	ld	de,bufStr
	call	CopyVars
;пропускаем первые пробелы
	ld	bc,20*256
	ld	hl,bufStr
	ld	a,32
.n4	cp	(hl)
	jr	nz,.skip1
	inc	hl
	djnz	.n4
;а серийник-то пустой
	ld	hl,msgHDDShortInfo.sn
	ld	de,msgHDDShortInfo.sn+1
	ld	bc,MAXSHORTSNSHOW-1
	ld	(hl),a
	ldir
;доберемся до последних символов серийника
.skip2	cp	(hl)
	jr	z,.end1
.skip1	inc	hl
	inc	c
	djnz	.skip2
.end1
	dec	hl
	ld	de,msgHDDShortInfo.sn+MAXSHORTSNSHOW-1
	ld	a,c
	cp	MAXSHORTSNSHOW
	jr	nc,.copy
	ld	a,MAXSHORTSNSHOW
	sub	c
	ex	de,hl
.cp1	ld	(hl),32
	dec	a
	dec	hl
	jr	nz,.cp1
	ex	de,hl
	ld	b,0
	lddr
	jr	.next

.copy	ld	bc,MAXSHORTSNSHOW
;	ld	b,0
	lddr
.next	pop	hl
	push	hl
	ld	a,27
	ld	b,MAXSHORTMODELSHOW
	ld	de,msgHDDShortInfo.model
	call	CopyVars
	pop	hl
	;Total number of user addressable sectors (LBA mode only)
	ld	de,hddTotalSector
	ld	l,60*2
	ld	bc,4
	ldir

	ret	

;---------------------------------------------------------
;	Копирует и переворачивает данные из
;	сектора статуса дисковода в буфер
;---------------------------------------------------------
;HL - откуда
;DE - куда
;B - сколько
;A - смещение
CopyVars
	add	a,a
	add	a,l
	ld	l,a
	jr	nc,.cv1
	inc	h
.cv1	ld	a,b
	rra
.cv	ld	b,(hl)
	inc	l
	ld	c,(hl)
	inc	hl
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	ex	de,hl
	dec	a
	jr	nz,.cv
	ret

;---------------------------------------------------------
;	Вытягивает из сектора статуса слово
;---------------------------------------------------------
;HL - откуда
;A - смещение
;Output:
;DE - word
GetWord
	add	a,a
	add	a,l
	ld	l,a
	jr	nc,.g1
	inc	h
.g1	ld	e,(hl)
	inc	l
	ld	d,(hl)
	ret

; IF _TARGET = _ZX128 | _TARGET = _PROFI | _TARGET = _ATM
 IF _IM = 1
;---------------------------------------------------------
;	Установка прерываний 2го рода, формирование
;	таблицы вектора прерываний
;	http://www.zxpress.ru/article.php?id=8898
;---------------------------------------------------------
IM2Init
	DI
	LD	HL,IMVector ;ТABLE_ADR должно быть
	LD	A,H          ;кратно 256!
	LD	I,A
	LD	B,L
	INC	A
L1	LD	(HL),A
	INC	HL
	DJNZ	L1
	LD	(HL),A
	LD	L,H
	LD	(HL),#C3     ;JP
	INC	L
	LD	DE,IMER	;П/П обработки прерываний
	LD	(HL),E
	INC	L
	LD	(HL),D
	IM	2
	EI
	ret
IM2SET
	DI
	ld	a,high IMVector
	ld	i,a
	im	2
	ei
	ret
IM1SET
	DI
	ld	a,0x3f
	ld	I,a
	IM	1
	ei
	ret

IMER    PUSH	AF
        PUSH	BC
        PUSH	DE
        PUSH	HL
        EXX 
        EX	AF,AF'
        PUSH	AF
        PUSH	BC
        PUSH	DE
        PUSH	HL
        PUSH	IX
        PUSH	IY
;        ld	a,(CurrentPage)
 ;       push	af
  ;      xor	a
   ;	call	OpenPG
	ld	a,(curShow)
	and	a
	jr	z,.skip
	ld	a,(curIterate)
	inc	a
	and	15
	ld	(curIterate),a
	and	a
	jr	nz,.skip
	ld	a,(curState)
	xor	1
	ld	(curState),a
	ld	a,32
	jr	z,.s1
	ld	a,0x5f
.s1	call	PCH	;PrintCursor
.skip	LD	IY, 23610
	rst	0x38
;	pop	af
;	call	OpenPG
	POP	IY
        POP	IX
        POP	HL
        POP	DE
        POP	BC
        POP	AF
        EXX 
        EX	AF,AF'
        POP	HL
        POP	DE
        POP	BC
        POP	AF
	ei
        ret
 ENDIF

;---------------------------------------------------------

; Variables
partCount
	db	0 ;Количество обнаруженных партиций
devSelected
	db	0	;Выбранный пользователем драйв - 0 - Мастер, 1 - Слейв

;!!!==================================
;!!!Порядок следующих 4х полей не менять!!!
;!!!==================================
hddCylinders
	dw	0	;количество треков у драйва
hddHeads
	db	0	;количество голов
hddSectors
	db	0	;количество секторов
hddTotalSector
	dw	0,0	;Total number of user addressable sectors (LBA mode only)
;!!!==================================

statDrv	dw	0	;Статус приводов после INIT
cntOperations
	db	2	;счетчик операций по изменению MBR
cntMBRUS
	db	0	;количество записей в MBRUS (Space Unused)
 IF _TARGET = _SPRINTER
idMem	db	0
arrPages
	dw	0
ARGV	dw	0
 ENDIF
; IF _TARGET = _PROFI
;msgSign	db	"hdrp"
; ELSE
msgSign	db	"hdrv"	;сигнатура драйвера
strPartSign
	db	"partitions"	;сигнатура бэкапа партиций
; ENDIF
strDrvFileName
	db	"build in    "
bufStr	ds	64,0	;буфер для обработки строк
;---------------------------------------------------------

; Messages

msgHello
	db	CR,LF,"--== FDISK v",VERSION,".",BUILD_COUNT_T,"[",BUILD_DATE_NS_T,"] for ", _TARGET_T, " ==--",CR,LF
	db	"by Mikhaltchenkov Dmitry aka Hard/WCG",CR,LF
 IFDEF RELEASE
	db	"RELEASE-version, ",COL,C_WARN,"use it at your own risk!!!",COL,C_NORM,CR,LF
 ELSE
	db	COL,C_WARN,"This is DEBUG-version, use it at your own risk!!!",COL,C_NORM,CR,LF
 ENDIF

msgCRLF	db	CR,LF,EN
msgDriver
	db	"Loaded driver: ",COL,C_VAL,"["
.fn	ds	12,32
	db	"]",COL,C_NORM,CR,LF,"Driver string: ",COL,C_VAL,"["
.str	ds	27,32
	db	"]",COL,C_NORM,CR,LF,EN
msgSignFail
	db	"Driver wrong!",CR,LF,EN
msgFindDrives
	db	"Finding devices...",CR,LF,CR,LF,EN
msgNotFound
	db	"not found.",CR,LF,EN
msgFound
	db	":",CR,LF,EN

msgMaster
	db	"MASTER ",EN
msgSlave
	db	"SLAVE ",EN
msgDevice
	db	"device ",EN
msgNotHDD
	db	"is not HDD, skip.",CR,LF,CR,LF,EN
msgHDDInfo
	db	"  Model: ",COL,C_VAL,"["
.model	ds	40,32
	db	"]",COL,C_NORM,CR,LF,"  Serial Number: ",COL,C_VAL,"["
.sn	ds	20,32
	db	"]",COL,C_NORM," FW rev.: ",COL,C_VAL,"["
.fw	ds	8,32
	db	"]",COL,C_NORM,CR,LF
	db	"  Cylinders: ",COL,C_VAL,"["
.cyl	db	"00000]",COL,C_NORM," Heads: ",COL,C_VAL,"["
.head	db	"000]",COL,C_NORM," Sectors: ",COL,C_VAL,"["
.sec	db	"000]",COL,C_NORM,CR,LF
	db	EN
msgSelectDrive
	db	CR,LF,"Select device: ",COL,C_CMD,"[1] ",COL,C_NORM,"- Master, ",COL,C_CMD,"[2] ",COL,C_NORM,"- Slave",CR,LF,EN
msgPrompt
	db	">",EN
msgHDDNotFound
	db	CR,LF,"Not detected any HDD's...",CR,LF,EN
msgSelected
	db	CR,LF,"Selected ",EN
msgAnyKey
	db	CR,LF,"Press any key to continue...",CR,LF,EN
msgAnyKeyQuit
	db	CR,LF,"Press any key to continue ( ",COL,C_CMD,"[Q] ",COL,C_NORM,"- Quit )...",CR,LF,EN
msgReadMBR
	db	"Reading MBR...",CR,LF,EN
msgHDDShortInfo
	db	COL,C_VAL,"["
.model	ds	MAXSHORTMODELSHOW,32
	db	"]",COL,C_NORM,", s/n: ",COL,C_VAL,"["
.sn	ds	MAXSHORTSNSHOW,32
	db	"]",COL,C_NORM,CR,LF,EN
msgMBRNotFound
	db	"MBR Signature not found",CR,LF,EN
msgMBRHead
	db	"Num Fl Label       ID FS type          Start    "
 ;------------------------------------
 IFDEF RELEASE
  IF _TARGET=_SPRINTER | _TARGET=_ATM 
  ;Для 80симв в строке пеечатаем дополнительную колонку
	db	"Size,sec"
  ELSE
  ;В Релиз-версии для 64симв в строке печатаем только одну колонку Размер в Мб
  	db	"Size    "
  ENDIF
 ELSE
 ;В Дебуг-версии для 64симв в строке печатаем только одну колонку Размер в сек
 	db	"Size,sec"
 ENDIF
 ;------------------------------------

 IF _TARGET=_SPRINTER | _TARGET=_ATM
 	db	" Size"
 ENDIF
 	db	CR,LF
	db	"--- -- ----------- -- ---------------- -------- --------"
 IF _TARGET=_SPRINTER | _TARGET=_ATM
 	db	" --------"
 ENDIF
	db	CR,LF,EN
msgMBRRow
	db	COL,C_PRI
.num	db	"000    "
.label	db	"<NO LABEL>  "
.id	db	"00 "
.type	db	"                 "
.start	db	"00000000 "
.size	db	"        "
 IF _TARGET=_SPRINTER | _TARGET=_ATM
 	db	" "
.sizeb 	db	"00000 Mb"
 ENDIF
	db	COL,C_NORM,CR,LF,EN
msgPartCount
	db	CR,LF,"Found ",COL,C_VAL,"["
.cnt	db	"000] ",COL,C_NORM,"partitions. Total: ",COL,C_VAL,"["
.total	db	"00000 Mb] ",COL,C_NORM,"Unused: ",COL,C_VAL,"["
.unused	db	"00000 Mb]",COL,C_NORM,CR,LF
	db	"Legend Fl: ",COL,C_PRI,"P - Primary",COL,C_NORM,", ",COL,C_EXT,"E - Extended",COL,C_NORM,", ",COL,C_SEC,"S - Secondary,",COL,C_NORM," * - Active",CR,LF,EN
msgMBRCommands
	db	CR,LF,"Select command: ",COL,C_CMD,"[C] ",COL,C_NORM,"- Create part. "
	db	COL,C_CMD,"[D] ",COL,C_NORM,"- Delete part. "
	db	COL,C_CMD,"[I] ",COL,C_NORM,"- Modify ID "
	db	COL,C_CMD,"[A] ",COL,C_NORM,"- Set Active "
	db	COL,C_CMD,"[F] ",COL,C_NORM,"- Format "
	db	COL,C_CMD,"[S] ",COL,C_NORM,"- Show S.M.A.R.T. "
	db	COL,C_CMD,"[U] ",COL,C_NORM,"- Dump sector "
	db	COL,C_CMD,"[B] ",COL,C_NORM,"- Backup part.table "
	db	COL,C_CMD,"[R] ",COL,C_NORM,"- Restore part.table "
	db	COL,C_CMD,"[Y] ",COL,C_NORM,"- Apply all operations "
msgQuit
	db	COL,C_CMD,"[Q] ",COL,C_NORM,"- Quit",CR,LF,EN
msgPromptNumber0
	db	CR,LF,"Enter number of partition (0 - show first sector of drive): ",EN
msgPromptNumber
	db	CR,LF,"Enter number of partition: ",EN
msgDumpSectorCR
	db	CR,LF
msgDumpSector
	db	"Dumping sector of partition",CR,LF,EN
msgInvalidParameter
	db	CR,LF,COL,C_WARN,"Invalid parameter!",COL,C_NORM,CR,LF,EN
msgMBRTableIsNull
	db	CR,LF,"Partition table is empty, operation aborted!", CR,LF,EN
msgLarge
	db	CR,LF,COL,C_WARN,"This HDD too large for use with LBA28 and not currently supported in this version, "
	db	"continued operation may lead to the destruction of data on the your disk!",COL,C_NORM
	db	CR,LF,"You wish to continue? (y/n)",CR,LF,EN
msgPending
	db	COL,C_WARN,"Pending operations: ["
.cnt	db	"000]",COL,C_NORM,CR,LF,EN
msgPendingOps
	db	CR,LF,COL,C_WARN,"There are pending operations, you really want to discard them? (y/n) ",COL,C_NORM,EN
msgOK	db	CR,LF,"OK.",CR,LF,EN
msgApplyBeforeThisOps
	db	CR,LF,COL,C_WARN,"Should be applied all operations before execute this command!",COL,C_NORM,CR,LF,EN
 IFUSED msgNotImplemented
msgNotImplemented
	db	CR,LF,COL,C_WARN,"This feature is not implemented in this version, sorry :(",COL,C_NORM,CR,LF,EN
 ENDIF
;---------------------------------------------------------

 IF _TARGET=_ZX128 | _TARGET=_PROFI | _TARGET=_ATM
;Вызов TR-DOS с автоматическим управлением прерываниями
;Добавлен перехват управления в случае RIA-ошибки
;источник Adventurer #07 - Обмен опытом - Обработка ошибок TR DOS.
_trdos	ex	af,af'
	ld	a,i
	push	af
	call	IM1SET
	di
	PUSH	HL
	LD	HL,(23613) ; Сохр. ERR_SP
	LD	(.err2+1),HL
	LD	HL,.err1
	EX	(SP),HL
	LD	(23613),SP
	XOR	A
	LD	(23823),A
	LD	(23824),A
	LD	(23570),A
	ex	af,af'
	JP	15635
.err1	call	IM2SET
	pop	af
	jp	po,$+4
	ei
.err2	LD	HL,0
	LD	(23613),HL ; восст. ERR_SP
	LD	A,6
	LD	(23570),A
	LD	A,(23823)	;Код ошибки TR-DOS
	AND    	A
	RET	Z
	scf
	RET
	
;-------------------------------------------
;	Вывод сообщения об ошибке и
;	возврат управления в ShowPartition.continue
;-------------------------------------------
GeneralDosError
	ld	hl,msgDosError
DosError
	PCHARS
	_ANYKEY
	jp	ShowPartition.continue

msgDosError
	db	CR,LF,COL,C_WARN,"Disk error has occurred!",COL,C_NORM,CR,LF,EN
msgDOSDirFull
	db	CR,LF,COL,C_WARN,"Directory is full!",COL,C_NORM,CR,LF,EN
msgDOSNoFree
	db	CR,LF,COL,C_WARN,"No free space on disk!",COL,C_NORM,CR,LF,EN

	IF _TARGET=_PROFI
	include "libs\profi\console.asm"
	include	"libs\profi\mem.asm"
	ELSE
	 IF _TARGET=_ATM
	 include	"libs\atm\console.asm"
	 include	"libs\atm\mem.asm"
	 ELSE
	 include "libs\zx128\console.asm"
	 include	"libs\zx128\mem.asm"
	 ENDIF
	ENDIF
	include	"fdisk_loaddrv.asm"
	include	"libs\keys.asm"
 ELSE
  IF _TARGET=_SPRINTER
	include "libs\sprinter\console.asm"
	include	"libs\sprinter\keys.asm"
  ENDIF
 ENDIF

	include "libs\utils.asm"
	include	"fdisk_fstypes.asm"
	include "fdisk_dump.asm"
	include	"fdisk_crmbrt.asm"
	include	"fdisk_func.asm"
	include	"fdisk_chtype.asm"
	include	"fdisk_setboot.asm"
	include	"fdisk_backup.asm"
	include	"fdisk_delpart.asm"
	include "fdisk_crpart.asm"
	include	"fdisk_format.asm"
	include	"libs\math.asm"

JMP_Table
	include	"fdisk_ovl.asm"
JMP_TableEnd
MainEnd

	align 256

MBRTable=$	;hDrvSign+1024						;таблица MBR
MBRUSTable=MBRTable+(MAXMBRFIELDS*MBRFIELDSIZE)	;таблица неиспользуемого пространства

;должна быть выровнена по 256
Buffer=#c000							;Буфер для сектора статуса винтов 2*512
;(((MBRUSTable+(MAXMBRUS*MBRUSFIELDSIZE))/256)+1)*256			;Буфер для сектора статуса винтов 2*512
SectorBuffer=Buffer+1024					;буфер для чтения/записи сектора
SectorBuffer1=SectorBuffer+512					;буфер 2 для чтения/записи сектора
SectorBuffer2=SectorBuffer1+512					;буфер 3 для чтения/записи сектора

MainSize=MainEnd-FDISKSTART
; IF _TARGET=_ZX128 | _TARGET=_PROFI | _TARGET=_ATM
;  IFNDEF RELEASE
;//	savesna	"fdisk_main.sna",MainStart
	savebin	"out\fdisk.bin",FDISKSTART,$-FDISKSTART
; ENDIF
	export	_DRVORG
	export	FDISKSTART
	export	MainStart
	export	MainSize

;Для генерации ридми-файла:
hlpString
	db	"                      FDISK by Hard/WCG",CR,LF
	db	"---------------------------------------------------------------",CR,LF
	db	"Version:  ",VERSION, CR,LF
	db	"Build:    ",BUILD_COUNT_T,CR,LF
	db	"Date:     ",BUILD_DATE_T, " ", BUILD_TIME_T,CR,LF
	db	"Platform: ", _TARGET_T,CR,LF
	db	"Autor:    Mikhaltchenkov Dmitry aka Hard/WitchCraft Group",CR,LF
	db	"E-Mail:   mikhaltchenkov@gmail.com",CR,LF
	db	"---------------------------------------------------------------",CR,LF,CR,LF
	SAVEBIN	"out\header.txt",hlpString,$-hlpString