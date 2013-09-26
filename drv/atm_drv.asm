 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	org	_DRVORG
 ENDIF
;Драйвер основан на драйверах CDWALK и Fatal (ProfiIDE)

PA_1F7W		EQU 0XFEEF			;W РЕГИСТР КОМАНД
PA_1F7R		EQU 0XFEEF			;R РЕГИСТР СОСТОЯНИЯ
PA_1F6W		EQU 0XFECF			;W CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
PA_1F6R		EQU 0XFECF			;R CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
PA_1F5W		EQU 0XFEAF			;W CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
PA_1F5R		EQU 0XFEAF			;R CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
PA_1F4W		EQU 0XFE8F			;W CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
PA_1F4R		EQU 0XFE8F			;R CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
PA_1F3W		EQU 0XFE6F			;W CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
PA_1F3R		EQU 0XFE6F			;R CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
PA_1F2W		EQU 0XFE4F			;W СЧЕТЧИК СЕКТОРОВ
PA_1F2R		EQU 0XFE4F			;R СЧЕТЧИК СЕКТОРОВ
PA_1F1W		EQU 0XFE2F			;W ПОРТ СВОЙСТВ
PA_1F1R		EQU 0XFE2F			;R ПОРТ ОШИБОК
PA_1F0W		EQU 0XFE0F			;W ПОРТ ДАННЫХ МЛАДШИЕ 8 БИТ
PA_1F0R		EQU 0XFE0F			;R ПОРТ ДАННЫХ МЛАДШИЕ 8 БИТ
PA_3F6		EQU 0XFEBE			;W РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
PA_HIW		EQU 0XFF0F			;W ПОРТ ДАННЫХ СТАРШИЕ 8 БИТ
PA_HIR		EQU 0XFF0F			;R ПОРТ ДАННЫХ СТАРШИЕ 8 БИТ

DRVSTART
;сигнатура
;+0 - hdrv
;+4 - версия:
;младшие биты	0 - поддержка LBA48 1 - да, 0 - нет
		db "hdrv0" ; сигнатура
.str		db "ATM IDE v0.1"
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
		ld (restore_mode),a		;установка конфигурационного порта
		ld (restore_mode1),a
.f2		ex af,af'		
.f1		ADD A,A
		PUSH HL
		LD HL,ATM_CPM_OFF		;п/п отключения режима CPM при выходе
		EX (SP),HL
		PUSH HL
		LD HL,TBLHDDA
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
		call ATM_CPM_ON
		POP BC
		EX AF,AF'
		EX (SP),HL
		RET

ATM_CPM_OFF
		PUSH	BC
		push	af
		ld	bc,ATM_CPM_OFF1
		push	bc
		LD	BC,#2A53
		PUSH	BC
		LD	BC,#FF77 ;выкл.теневые порты
		LD	A,%10101011 ;режим ZX
restore_mode	equ	$-1
		JP	#3D2F
ATM_CPM_OFF1	pop	af
		pop	bc
		ret

ATM_CPM_ON
		LD	BC,#2A53
		PUSH	BC
		LD	A,%10101011	;Вкл.теневые порты
restore_mode1	equ	$-1
		LD	BC,#4177
		JP	#3D2F

TBLHDDA		DW HDDAINIT
		DW HDDSETMASTER
		DW HDDSETSLAVE		
		DW HDDAOFF
		DW HDDARDS			;READ SINGLE
		DW HDDAWTS			;Write single
		DW HDDARDM			;READ MULTI
		DW HDDAWTM			;Write multi

MS		DB	0
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт)
;только для многоблочной записи/чтении

;НА ВЫХОДЕ:
;H-ДЛЯ MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-ДЛЯ SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
HDDAINIT	xor	a
		ld	(hddmaster_exist),a
		ld	(hddslave_exist),a
		CALL	HDDSETMASTER
		PUSH HL
		CALL IDA_DEV
		POP HL
		AND A
		CALL Z,INITA_91
		ld	(hddmaster_exist),a
		LD D,A
		PUSH DE
		CALL	HDDSETSLAVE
		LD DE,512
		ADD HL,DE
		PUSH HL
		CALL IDA_DEV
		POP HL
		AND A
		CALL Z,INITA_91
		POP HL
		LD L,A;0xff
		ld	(hddslave_exist),a
		XOR A

HDDAOFF		RET
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

INITA_91	PUSH HL
		LD L,49*2+1
		LD A,(HL)
		AND 2
		JR Z,.INIP_912
		LD BC,PA_1F2W
		LD L,0X0C
		LD A,(HL)
		OUT (C),A
		LD L,6
		LD BC,PA_1F6W
		LD D,(HL)
		DEC D
		LD A,(MS)
		AND %10110000
		OR D
		OUT (C),A
		LD BC,PA_1F7W
		LD A,0X91
		OUT (C),A
		LD BC,PA_1F7R
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

HDDARDS		LD A,1
HDDARDM		PUSH BC
		PUSH DE
		CALL SETAREG
		EX AF,AF'
		LD BC,PA_1F7W
		LD A,0X20
		OUT (C),A 
		call W_DRQ
		EX AF,AF'
.HDDRD2		EX AF,AF'
		CALL READASEC
		call W_BSY
		EX AF,AF'
		DEC A
		JR NZ,.HDDRD2
		POP DE
		POP BC
		XOR A
		RET

HDDAWTS		LD A,1
HDDAWTM	  	PUSH BC
		PUSH DE
		CALL SETAREG
		EX AF,AF'
		LD BC,PA_1F7W
	        LD A,#30
	        OUT (C),A
	        call W_DRQ
	        ex af,af'
.w1		ex af,af'
	        CALL WRITEASEC
	        CALL W_BSY
	        ex af,af'
	        dec a
	        jr nz,.w1
	        pop de
	        pop BC
	        xor a
	        RET
W_DRQ		LD BC,PA_1F7R
.drq		IN A,(C)
		AND 0X88
		CP 8
		JR NZ,.drq
		RET
W_BSY		LD BC,PA_1F7R
.bsy		IN A,(C)
		AND 0X80
		JR NZ,.bsy
		ret

READASEC	LD A,0X40
		LD BC,PA_1F0R
.READPSC1	REPT 8
		ini
		ENDM
		DEC A
		JR NZ,.READPSC1
		RET

;SAVE SECTOR (512 BYTES)
WRITEASEC	ld a,0X40
		ld bc,PA_1F0W
.wr		dup 4
		inc HL
		outd
		outi
		inc HL
		edup
		dec a
		jr nz,.wr
		RET


SETAREG		PUSH DE
		EX AF,AF'
		ld a,b	;LBA28 - отсекаем биты 4-7, т.к. в этой адресации они не поддерживаются
		and 15	
		LD D,a
		LD E,C
		LD BC,PA_1F6W
		LD A,(MS)
		OR D
		OUT (C),A
		call W_BSY
		LD BC,PA_1F5W
		OUT (C),E
		POP DE
		LD BC,PA_1F4W
		OUT (C),D
		LD BC,PA_1F3W
		OUT (C),E
		LD BC,PA_1F2W
		EX AF,AF'
		OUT (C),A
		RET

;HL-АДРЕС БУФЕРА СЕКТОРА ИДЕНТИФИКАЦИИ
;A=E0-ДЛЯ MASTER, A=F0-ДЛЯ SLAVE
IDA_DEV		LD BC,PA_1F6W
		LD A,(MS)
		OUT (C),A
		LD BC,PA_1F7R
		LD D,26
.IDA_DEV3	EI
		HALT
		DI
		DEC D
		JR Z,.NOA_DEV
		IN A,(C)
		BIT 7,A
		JR NZ,.IDA_DEV3
		AND A
		JR Z,.NOA_DEV
		INC A
		JR Z,.NOA_DEV
		XOR A
		LD BC,PA_1F5W
		OUT (C),A
		LD BC,PA_1F4W
		OUT (C),A
		LD A,0XEC
		LD BC,PA_1F7W
		OUT (C),A
		LD BC,PA_1F7R
.IDA_DEV1	IN A,(C)
		AND A
		JR Z,.NOA_DEV
		INC A
		JR Z,.NOA_DEV
		DEC A
		RRCA
		JR C,.IDA_DEV2
		RLCA
		AND 0X88
		CP 8
		JR NZ,.IDA_DEV1
.IDA_DEV2	LD BC,PA_1F4R
		IN E,(C)
		LD BC,PA_1F5R
		IN D,(C)
		LD A,D
		OR E
		JP Z,READASEC
		LD HL,0XEB14
		SBC HL,DE
		LD A,1
		RET Z
.NOA_DEV	LD A,0XFF
		RET
DRVEND
 IFNDEF	MAIN
	SAVEBIN	"..\out\atmide.drv",DRVSTART,DRVEND-DRVSTART
 ENDIF
