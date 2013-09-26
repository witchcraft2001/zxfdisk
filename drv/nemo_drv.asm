 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	include "..\fdisk_equs.inc"
	include	"..\target.inc"
	org	_DRVORG
 ENDIF
;LAST UPDATE: 09.02.2010 savelij
;LAST UPDATE: 29.08.2013 HARD - ПОФИКСИЛ РАБОТУ СО SLAVE-УСТРОЙСТВАМИ
DRVSTART
Hddinit		EQU 0
Hddoff		EQU 1
Hddrds		EQU 2
Hddrdm		EQU 3
NemoIDE
 ;IF _TARGET=_PROFI
;		db "hdrp0" ; сигнатура для Профи-версии
 ;ELSE
		db "hdrv0" ; сигнатура для универсального драйвера
 ;ENDIF
.str		db "NemoIDE v.0.2"
		ds 27-($-.str),32
;ОБЩАЯ ТОЧКА ВХОДА ДЛЯ РАБОТЫ С HDD NEMO
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

TBLHDDN		DW HDDINIT
		DW HDDSETMASTER
		DW HDDSETSLAVE		
		DW HDDOFF
		DW HDDRDS			;READ SINGLE
		DW HDDWTS			;Write single
		DW HDDRDM			;READ MULTI
		DW HDDWTM			;Write multi

MS		DB	0
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт)
;только для многоблочной записи/чтении

P_1F7		EQU 0XF0			;РЕГИСТР СОСТОЯНИЯ/РЕГИСТР КОМАНД
P_1F6		EQU 0XD0			;CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
P_1F5		EQU 0XB0			;CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
P_1F4		EQU 0X90			;CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
P_1F3		EQU 0X70			;CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
P_1F2		EQU 0X50			;СЧЕТЧИК СЕКТОРОВ
P_1F1		EQU 0X30			;ПОРТ ОШИБОК/СВОЙСТВ
P_1F0		EQU 0X10			;ПОРТ ДАННЫХ
P_3F6		EQU 0XC8			;РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
P_HI		EQU 0X11			;СТАРШИЕ 8 БИТ
PRT_RW		EQU P_1F0*256+P_HI	;ПОРТЫ ЧТЕНИЯ/ЗАПИСИ ОДНИМ СЛОВОМ

;НА ВЫХОДЕ:
;H-ДЛЯ MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-ДЛЯ SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
HDDINIT		xor	a
		ld	(hddmaster_exist),a
		ld	(hddslave_exist),a
		CALL	HDDSETMASTER
		PUSH HL
		CALL ID_DEV
		POP HL
		AND A
		CALL Z,INIT_91
		ld	(hddmaster_exist),a
		LD D,A
		PUSH DE
		CALL	HDDSETSLAVE
		LD DE,512
		ADD HL,DE
		PUSH HL
		CALL ID_DEV
		POP HL
		AND A
		CALL Z,INIT_91
		POP HL
		LD L,A;0xff
		ld	(hddslave_exist),a
		XOR A

HDDOFF		RET
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

INIT_91		PUSH HL
		LD L,49*2+1
		LD A,(HL)
		AND 2
		JR Z,INI_912
		LD BC,0XFF00+P_1F2
		LD L,0X0C
		LD A,(HL)
 		OUT (C),A
 		LD L,6
 		LD C,P_1F6
		LD	A,(MS)
		AND	%10110000
 		LD D,(HL)
		DEC D
		OR	D
		OUT (C),A
		LD C,P_1F7
		LD A,0X91
		OUT (C),A
		LD DE,0X1000
INI_911		DEC DE
		LD A,D
		OR E
		JR Z,INI_912
		IN A,(C)
		AND 0X80
		JR NZ,INI_911
		POP HL
		RET

INI_912		LD A,0XFF
		POP HL
		RET

HDDRDS		LD A,1
HDDRDM		PUSH BC
		PUSH DE
		CALL SETHREG
		EX AF,AF'
		LD C,P_1F7
		LD A,0X20
		OUT (C),A
		call W_DRQ
		EX AF,AF'
HDDRD2		EX AF,AF'
		CALL READSEC
		LD C,P_1F7
HDDRD3		IN A,(C)
		AND 0X80
		JR NZ,HDDRD3
		EX AF,AF'
		DEC A
		JR NZ,HDDRD2
		POP DE
		POP BC
		XOR A
		RET

HDDWTS		LD A,1
HDDWTM	  	PUSH BC
		PUSH DE
		CALL SETHREG
		EX AF,AF'
		LD C,P_1F7
	        LD A,#30
	        OUT (C),A
	        call W_DRQ
	        ex af,af'
.w1		ex af,af'
	        CALL WRITESEC
	        CALL W_BSY
	        ex af,af'
	        dec a
	        jr nz,.w1
	        pop de
	        pop BC
	        xor a
	        RET
W_DRQ		LD BC,0XFF00+P_1F7
.drq		IN A,(C)
		AND 0X88
		CP 8
		JR NZ,.drq
		RET
W_BSY		LD BC,0xFF00+P_1F7
.bsy		IN A,(C)
		AND 0X80
		JR NZ,.bsy
		ret
;чтение 512б данных
READSEC		LD C,P_1F0
		ld a,#40
.rs1		dup	4
		INI
		INC C
		INI
		DEC C
		edup
        	DEC A:JR NZ,.rs1
        	RET
 ;запись 512б данных на HDD
WRITESEC   	LD C,P_HI
		LD a,#40
.ss1     	dup	4
		INC HL
		OUTI
		DEC C
		dec HL
	        DEC HL

	        OUTI
	        INC C
	        INC HL
	        edup
	        DEC a
	        JR NZ,.ss1
	        RET 

SETHREG		PUSH DE
		EX AF,AF'
		ld	a,b	;LBA28 - отсекаем биты 4-7, т.к. в этой адресации они не поддерживаются
		and	15	
		LD D,a
		LD E,C
		LD BC,0XFF00+P_1F6
		LD	A,(MS)
		OR	D
		OUT (C),A
		LD C,P_1F7
SETHRE1		IN A,(C)
		AND 0X80
		JR NZ,SETHRE1
		LD C,P_1F5
		OUT (C),E
		POP DE
		LD C,P_1F4
		OUT (C),D
		LD C,P_1F3
		OUT (C),E
		LD C,P_1F2
		EX AF,AF'
		OUT (C),A
		RET

;HL-АДРЕС БУФЕРА СЕКТОРА ИДЕНТИФИКАЦИИ
;A=E0-ДЛЯ MASTER, A=F0-ДЛЯ SLAVE
ID_DEV		LD BC,0XFF00+P_1F6
		LD	A,(MS)
		OUT (C),A
		LD C,P_1F7
		IN A,(C)
		AND A
		JR Z,NO_DEV
		INC A
		JR Z,NO_DEV
		XOR A
		LD C,P_1F5
		OUT (C),A
		LD C,P_1F4
		OUT (C),A
		LD A,0XEC
		LD C,P_1F7
		OUT (C),A
		LD C,P_1F7
ID_DEV1		IN A,(C)
		AND A
		JR Z,NO_DEV
		INC A
		JR Z,NO_DEV
		DEC A
		RRCA
		JR C,ID_DEV2
		RLCA
		AND 0X88
		CP 8
		JR NZ,ID_DEV1
ID_DEV2		LD C,P_1F4
		IN E,(C)
		LD C,P_1F5
		IN D,(C)
		LD A,D
		OR E
		JP Z,READSEC
		LD HL,0XEB14
		SBC HL,DE
		LD A,1
		RET Z
NO_DEV		LD A,0XFF
		RET
DRVEND
 IFNDEF	MAIN
	SAVEBIN	"..\out\nemoide.drv",DRVSTART,DRVEND-DRVSTART
 ENDIF
