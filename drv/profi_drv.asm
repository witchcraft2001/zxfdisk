 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	include "..\fdisk_equs.inc"
	include	"..\target.inc"
	org	_DRVORG
CurrentPage	equ	#5B5C
 ENDIF
;Драйвер основан на драйверах CDWALK и Fatal

PP_1F7W		EQU 0X07EB			;W РЕГИСТР КОМАНД
PP_1F7R		EQU 0X07CB			;R РЕГИСТР СОСТОЯНИЯ
PP_1F6W		EQU 0X06EB			;W CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
PP_1F6R		EQU 0X06CB			;R CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
PP_1F5W		EQU 0X05EB			;W CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
PP_1F5R		EQU 0X05CB			;R CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
PP_1F4W		EQU 0X04EB			;W CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
PP_1F4R		EQU 0X04CB			;R CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
PP_1F3W		EQU 0X03EB			;W CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
PP_1F3R		EQU 0X03CB			;R CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
PP_1F2W		EQU 0X02EB			;W СЧЕТЧИК СЕКТОРОВ
PP_1F2R		EQU 0X02CB			;R СЧЕТЧИК СЕКТОРОВ
PP_1F1W		EQU 0X01EB			;W ПОРТ СВОЙСТВ
PP_1F1R		EQU 0X01CB			;R ПОРТ ОШИБОК
PP_1F0W		EQU 0X00EB			;W ПОРТ ДАННЫХ МЛАДШИЕ 8 БИТ
PP_1F0R		EQU 0X00CB			;R ПОРТ ДАННЫХ МЛАДШИЕ 8 БИТ
PP_3F6		EQU 0X06AB			;W РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
PP_HIW		EQU 0XFFCB			;W ПОРТ ДАННЫХ СТАРШИЕ 8 БИТ
PP_HIR		EQU 0XFFEB			;R ПОРТ ДАННЫХ СТАРШИЕ 8 БИТ

DRVSTART
; IF _TARGET=_PROFI
;		db "hdrp0" ; сигнатура
; ELSE
		db "hdrv0" ; сигнатура
; ENDIF
.str		db "Profi IDE v0.1"
		ds 27-($-.str),32
;ОБЩАЯ ТОЧКА ВХОДА ДЛЯ РАБОТЫ С HDD
		EX AF,AF'
		EX (SP),HL
		LD A,(HL)
		INC HL
		EX (SP),HL
		and a
		jr nz,.f1
		ex af,af'
		and a
		jr z,.f2
		or 0x20
		ld (restore_mode),a
		and %11011111
		ld (restore_mode1),a
.f2		ex af,af'
.f1		ADD A,A
		PUSH HL
		LD HL,EXIT_HDDP		;п/п отключения режима CPM при выходе
		EX (SP),HL
		PUSH HL
		LD HL,TBLHDDN
		ADD A,L
		LD L,A
		LD A,H
		ADC A,0
		LD H,A
		LD A,(HL)
		INC HL
		LD H,(HL)
		LD L,A
		PUSH BC
		di
		LD BC,0XDFFD
		LD A,0X20
restore_mode	equ $-1
		OUT (C),A
;		ld b,#7f
;		ld a,(CurrentPage)
;		or 16
;		OUT (C),A
		POP BC
		EX AF,AF'
		EX (SP),HL
		RET

EXIT_HDDP	PUSH AF
		PUSH BC
		LD BC,0XDFFD
; IF _TARGET=_PROFI
;		ld a,(CurrentPage)
; ELSE
;		XOR A
; ENDIF
		ld a,0
restore_mode1	equ $-1
		OUT (C),A
;		ld b,#7f
;		ld a,(CurrentPage)
;		OUT (C),A
		POP BC
		POP AF
		RET

TBLHDDN		DW HDDPINIT
		DW HDDSETMASTER
		DW HDDSETSLAVE		
		DW HDDPOFF
		DW HDDPRDS			;READ SINGLE
		DW HDDPWTS			;Write single
		DW HDDPRDM			;READ MULTI
		DW HDDPWTM			;Write multi

MS		DB	0
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт)
;только для многоблочной записи/чтении

;НА ВЫХОДЕ:
;H-ДЛЯ MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-ДЛЯ SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
HDDPINIT	xor	a
		ld	(hddmaster_exist),a
		ld	(hddslave_exist),a
		CALL	HDDSETMASTER
		PUSH HL
		CALL IDP_DEV
		POP HL
		AND A
		CALL Z,INITP_91
		ld	(hddmaster_exist),a
		LD D,A
		PUSH DE
		CALL	HDDSETSLAVE
		LD DE,512
		ADD HL,DE
		PUSH HL
		CALL IDP_DEV
		POP HL
		AND A
		CALL Z,INITP_91
		POP HL
		LD L,A;0xff
		ld	(hddslave_exist),a
		XOR A

HDDPOFF		RET
;установка мастера текущим для всех последующих операций
HDDSETMASTER	ld	a,0
hddmaster_exist	equ	$-1
		and	a
		scf
		ret	nz
		LD	A,0XE0	;LBA+MASTER
HDDSET1		ld	(MS),A
		AND	A
		RET
;установка слейва текущим для всех последующих операций
HDDSETSLAVE	ld	a,0
hddslave_exist	equ	$-1
		and	a
		scf
		ret	nz
		LD	A,0XF0
		JR	HDDSET1

INITP_91	PUSH HL
		LD L,49*2+1
		LD A,(HL)
		AND 2
		JR Z,.INIP_912
		LD BC,PP_1F2W
		LD L,0X0C
		LD A,(HL)
		OUT (C),A
		LD L,6
		LD BC,PP_1F6W
		LD D,(HL)
		DEC D
		LD A,(MS)
		AND %10110000
		OR D
		OUT (C),A
		LD BC,PP_1F7W
		LD A,0X91
		OUT (C),A
		LD BC,PP_1F7R
		LD DE,0X4000
.INIP_911	DEC DE
		LD A,D
		OR E
		JR Z,.INIP_912
		IN A,(C)
		AND 0X80
		JR NZ,.INIP_911
		POP HL
		RET

.INIP_912	LD A,0XFF
		POP HL
		RET

HDDPRDS		LD A,1
HDDPRDM		PUSH BC
		PUSH DE
		CALL SETPREG
		EX AF,AF'
		LD BC,PP_1F7W
		LD A,0X20
		OUT (C),A 
		call W_DRQ
		EX AF,AF'
.HDDRD2		EX AF,AF'
		CALL READPSEC
		call W_BSY
		EX AF,AF'
		DEC A
		JR NZ,.HDDRD2
		POP DE
		POP BC
		XOR A
		RET

HDDPWTS		LD A,1
HDDPWTM	  	PUSH BC
		PUSH DE
		CALL SETPREG
		EX AF,AF'
		LD BC,PP_1F7W
	        LD A,#30
	        OUT (C),A
	        call W_DRQ
	        ex af,af'
.w1		ex af,af'
	        CALL WRITEPSEC
	        CALL W_BSY
	        ex af,af'
	        dec a
	        jr nz,.w1
	        pop de
	        pop BC
	        xor a
	        RET
W_DRQ		LD BC,PP_1F7R
.drq		IN A,(C)
		AND 0X88
		CP 8
		JR NZ,.drq
		RET
W_BSY		LD BC,PP_1F7R
.bsy		IN A,(C)
		AND 0X80
		JR NZ,.bsy
		ret

READPSEC	LD A,0X40
READPSC1	REPT 4
		LD BC,PP_1F0R
		IN E,(C)
		LD BC,PP_HIR
		IN D,(C)
		LD (HL),E
		INC HL
		LD (HL),D
		INC HL
		ENDM
		DEC A
		JR NZ,READPSC1
		RET

;SAVE SECTOR (512 BYTES)
WRITEPSEC	EXX
		PUSH HL
		LD HL,0
		ADD HL,SP
		EXX
		LD SP,HL
		LD A,0X40
WRP_SEC1	REPT 4
		POP DE
		LD BC,PP_HIW
		OUT (C),D
		LD BC,PP_1F0W
		OUT (C),E
		ENDM
		DEC A
		JR NZ,WRP_SEC1
		LD HL,0
		ADD HL,SP
		EXX
		LD SP,HL
		POP HL
		EXX
		RET


SETPREG		PUSH DE
		EX AF,AF'
		ld a,b	;LBA28 - отсекаем биты 4-7, т.к. в этой адресации они не поддерживаются
		and 15	
		LD D,a
		LD E,C
		LD BC,PP_1F6W
		LD A,(MS)
		OR D
		OUT (C),A
		call W_BSY
		LD BC,PP_1F5W
		OUT (C),E
		POP DE
		LD BC,PP_1F4W
		OUT (C),D
		LD BC,PP_1F3W
		OUT (C),E
		LD BC,PP_1F2W
		EX AF,AF'
		OUT (C),A
		RET

;HL-АДРЕС БУФЕРА СЕКТОРА ИДЕНТИФИКАЦИИ
;A=E0-ДЛЯ MASTER, A=F0-ДЛЯ SLAVE
IDP_DEV		LD BC,PP_1F6W
		LD A,(MS)
		OUT (C),A
		LD BC,PP_1F7R
		LD D,26
.IDP_DEV3	EI
		HALT
		DI
		DEC D
		JR Z,.NOP_DEV
		IN A,(C)
		BIT 7,A
		JR NZ,.IDP_DEV3
		AND A
		JR Z,.NOP_DEV
		INC A
		JR Z,.NOP_DEV
		XOR A
		LD BC,PP_1F5W
		OUT (C),A
		LD BC,PP_1F4W
		OUT (C),A
		LD A,0XEC
		LD BC,PP_1F7W
		OUT (C),A
		LD BC,PP_1F7R
.IDP_DEV1	IN A,(C)
		AND A
		JR Z,.NOP_DEV
		INC A
		JR Z,.NOP_DEV
		DEC A
		RRCA
		JR C,.IDP_DEV2
		RLCA
		AND 0X88
		CP 8
		JR NZ,.IDP_DEV1
.IDP_DEV2	LD BC,PP_1F4R
		IN E,(C)
		LD BC,PP_1F5R
		IN D,(C)
		LD A,D
		OR E
		JP Z,READPSEC
		LD HL,0XEB14
		SBC HL,DE
		LD A,1
		RET Z
.NOP_DEV	LD A,0XFF
		RET
DRVEND
 IFNDEF	MAIN
	SAVEBIN	"..\out\profiide.drv",DRVSTART,DRVEND-DRVSTART
 ENDIF
