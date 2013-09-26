 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	org	_DRVORG
 ENDIF

DRVSTART

		db "hdrv0" ; сигнатура
.str		db "SprinterIDE v0.1"
		ds 27-($-.str),32
;ОБЩАЯ ТОЧКА ВХОДА ДЛЯ РАБОТЫ С HDD
		EX AF,AF'
		EX (SP),HL
		LD A,(HL)
		INC HL
		EX (SP),HL
		ADD A,A
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
		EX AF,AF'
		EX (SP),HL
		RET

TBLHDDN		DW HDDSPINIT
		DW HDDSETMASTER
		DW HDDSETSLAVE		
		DW HDDSPOFF
		DW HDDSPRDS			;READ SINGLE
		DW HDDSPWTS			;Write single
		DW HDDSPRDM			;READ MULTI
		DW HDDSPWTM			;Write multi

MS		DB	0
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт)
;только для многоблочной записи/чтении

SP_1F7W		EQU 0X4153			;W РЕГИСТР КОМАНД
SP_1F7R		EQU 0X4053			;R РЕГИСТР СОСТОЯНИЯ
SP_1F6W		EQU 0X4152			;W CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
SP_1F6R		EQU 0X4052			;R CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
SP_1F5W		EQU 0X0155			;W CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
SP_1F5R		EQU 0X0055			;R CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
SP_1F4W		EQU 0X0154			;W CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
SP_1F4R		EQU 0X0054			;R CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
SP_1F3W		EQU 0X0153			;W CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
SP_1F3R		EQU 0X0053			;R CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
SP_1F2W		EQU 0X0152			;W СЧЕТЧИК СЕКТОРОВ
SP_1F2R		EQU 0X0052			;R СЧЕТЧИК СЕКТОРОВ
SP_1F1W		EQU 0X0151			;W ПОРТ СВОЙСТВ
SP_1F1R		EQU 0X0051			;R ПОРТ ОШИБОК
SP_1F0W		EQU 0X0150			;W ПОРТ ДАННЫХ МЛАДШИЕ 8 БИТ
SP_1F0R		EQU 0X0050			;R ПОРТ ДАННЫХ МЛАДШИЕ 8 БИТ
;PP_HIW		EQU 0XFFCB			;W ПОРТ ДАННЫХ СТАРШИЕ 8 БИТ
;PP_HIR		EQU 0XFFEB			;R ПОРТ ДАННЫХ СТАРШИЕ 8 БИТ

;НА ВЫХОДЕ:
;H-ДЛЯ MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-ДЛЯ SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
HDDSPINIT	xor	a
		ld	(hddmaster_exist),a
		ld	(hddslave_exist),a
		CALL	HDDSETMASTER
		PUSH HL
		CALL IDSP_DEV
		POP HL
		AND A
		CALL Z,INITSP_91
		ld	(hddmaster_exist),a
		LD D,A
		PUSH DE
		CALL	HDDSETSLAVE
		LD DE,512
		ADD HL,DE
		PUSH HL
		CALL IDSP_DEV
		POP HL
		AND A
		CALL Z,INITSP_91
		POP HL
		LD L,A;0xff
		ld	(hddslave_exist),a
		XOR A

HDDSPOFF		RET
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

INITSP_91	PUSH HL
		LD L,49*2+1
		LD A,(HL)
		AND 2
		JR Z,.INIP_912
		LD BC,SP_1F2W
		LD L,0X0C
		LD A,(HL)
		OUT (C),A
		LD L,6
		LD BC,SP_1F6W
		LD D,(HL)
		DEC D
		LD A,(MS)
		AND %10110000
		OR D
		OUT (C),A
		LD BC,SP_1F7W
		LD A,0X91
		OUT (C),A
		LD BC,SP_1F7R
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

HDDSPRDS		LD A,1
HDDSPRDM		PUSH BC
		PUSH DE
		CALL SETSPREG
		EX AF,AF'
		LD BC,SP_1F7W
		LD A,0X20
		OUT (C),A 
		call W_DRQ
		EX AF,AF'
.HDDRD2		EX AF,AF'
		CALL READSPSEC
		call W_BSY
		EX AF,AF'
		DEC A
		JR NZ,.HDDRD2
		POP DE
		POP BC
		XOR A
		RET

HDDSPWTS		LD A,1
HDDSPWTM	  	PUSH BC
		PUSH DE
		CALL SETSPREG
		EX AF,AF'
		LD BC,SP_1F7W
	        LD A,#30
	        OUT (C),A
	        call W_DRQ
	        ex af,af'
.w1		ex af,af'
	        CALL WRITESPSEC
	        CALL W_BSY
	        ex af,af'
	        dec a
	        jr nz,.w1
	        pop de
	        pop BC
	        xor a
	        RET
W_DRQ		LD BC,SP_1F7R
.drq		IN A,(C)
		AND 0X88
		CP 8
		JR NZ,.drq
		RET
W_BSY		LD BC,SP_1F7R
.bsy		IN A,(C)
		AND 0X80
		JR NZ,.bsy
		ret

READSPSEC	LD A,0X40
		ld bc,SP_1F0R
.READSPSC1	REPT 8
		INI
		ENDM
		DEC A
		JR NZ,.READSPSC1
		RET

;SAVE SECTOR (512 BYTES)
WRITESPSEC	LD BC,SP_1F0W
		LD A,0X40
.WRSP_SEC1	REPT 8
		OUTI
		ENDM
		DEC A
		JR NZ,.WRSP_SEC1
		RET


SETSPREG		PUSH DE
		EX AF,AF'
		ld a,b	;LBA28 - отсекаем биты 4-7, т.к. в этой адресации они не поддерживаются
		and 15	
		LD D,a
		LD E,C
		LD BC,SP_1F6W
		LD A,(MS)
		OR D
		OUT (C),A
		call W_BSY
		LD BC,SP_1F5W
		OUT (C),E
		POP DE
		LD BC,SP_1F4W
		OUT (C),D
		LD BC,SP_1F3W
		OUT (C),E
		LD BC,SP_1F2W
		EX AF,AF'
		OUT (C),A
		RET

;HL-АДРЕС БУФЕРА СЕКТОРА ИДЕНТИФИКАЦИИ
;A=E0-ДЛЯ MASTER, A=F0-ДЛЯ SLAVE
IDSP_DEV		LD BC,SP_1F6W
		LD A,(MS)
		OUT (C),A
		LD BC,SP_1F7R
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
		LD BC,SP_1F5W
		OUT (C),A
		LD BC,SP_1F4W
		OUT (C),A
		LD A,0XEC
		LD BC,SP_1F7W
		OUT (C),A
		LD BC,SP_1F7R
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
.IDP_DEV2	LD BC,SP_1F4R
		IN E,(C)
		LD BC,SP_1F5R
		IN D,(C)
		LD A,D
		OR E
		JP Z,READSPSEC
		LD HL,0XEB14
		SBC HL,DE
		LD A,1
		RET Z
.NOP_DEV	LD A,0XFF
		RET

DRVEND
 IFNDEF	MAIN
	SAVEBIN	"..\out\spr_ide.drv",DRVSTART,DRVEND-DRVSTART
 ENDIF
