 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	org	_DRVORG
 ENDIF
DRVSTART
		db "hdrv0" ; сигнатура
.str		db "SMUC v.0.2 (std)"
		ds 27-($-.str),32

;LAST UPDATE: 23.02.2010 savelij

;ОБЩАЯ ТОЧКА ВХОДА ДЛЯ РАБОТЫ С HDD SMUC
		DI
		EX AF,AF'
		EX (SP),HL
		LD A,(HL)
		INC HL
		EX (SP),HL
		ADD A,A
		PUSH HL
		LD HL,TBLHDDS
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

TBLHDDS		DW HDSINIT
		DW HDDSETMASTER
		DW HDDSETSLAVE		
		DW HDSOFF
		DW HDSRDS		;READ SINGLE
		DW HDSWTS			;write single
		DW HDSRDM		;READ MULTI
		dw HDSWTM			;write multi
MS		DB	0

;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт)
;только для многоблочной записи/чтении

PS1F7		EQU 0XFF			;0XFFBE ;РЕГИСТР СОСТОЯНИЯ/РЕГИСТР КОМАНД
PS1F6		EQU 0XFE			;0XFEBE ;CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
PS1F5		EQU 0XFD			;0XFDBE ;CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
PS1F4		EQU 0XFC			;0XFCBE ;CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
PS1F3		EQU 0XFB			;0XFBBE ;CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
PS1F2		EQU 0XFA			;0XFABE ;СЧЕТЧИК СЕКТОРОВ
PS1F1		EQU 0XF9			;0XF9BE ;ПОРТ ОШИБОК/СВОЙСТВ
PS1F0		EQU 0XF8			;0XF8BE ;ПОРТ ДАННЫХ
PS3F6		EQU 0XFE			;0XFEBE ;РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
PSHI		EQU 0XD8			;0XD8BE ;СТАРШИЕ 8 БИТ
PRTSRW		EQU PS1F0*256+PSHI	;ПОРТЫ ЧТЕНИЯ/ЗАПИСИ ОДНИМ СЛОВОМ
LOW_PRT		EQU 0XBE			;МЛАДШИЙ БАЙТ АДРЕСА SMUC IDE
SMUCSYS		EQU 0XFFBA		;СИСТЕМНЫЙ ПОРТ SMUC
SMUCVER		EQU 0X5FBA		;ПОРТ ВЕРСИИ SMUC

;НА ВЫХОДЕ:
;H-ДЛЯ MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-ДЛЯ SLAVE  0-HDD, 1-CDROM, 0XFF-NONE

;Проверка наличия смука
HDSINIT		xor	a
		ld	(hddmaster_exist),a
		ld	(hddslave_exist),a
		PUSH HL
		EX DE,HL
		LD HL,0X3FF0
		LD BC,6
		CALL LDIRRET
		POP HL
		LD B,6
		LD DE,CPINOUT
HDSINI1		LD A,(DE)
		CP (HL)
		INC DE
		INC HL
		JR NZ,HDSINI2
		DJNZ HDSINI1
		LD BC,SMUCVER
		DEC SP
		DEC SP
		POP HL
		CALL SINPRT
		INC A
		JR NZ,HDSINI0

HDSINI2		LD HL,0XFFFF
		XOR A
		ld	(hddmaster_exist),a
		ld	(hddslave_exist),a
		RET
;собственно смук есть, проверка дисководов
HDSINI0		LD BC,SMUCSYS
		LD A,0X77
		CALL SOUTPRT
		PUSH HL
		CALL	HDDSETMASTER
;		LD A,0XE0
		CALL IDSDEV
		POP HL
		AND A
		CALL Z,INITS91
		ld	(hddmaster_exist),a
		LD D,A
		PUSH DE
		CALL	HDDSETSLAVE
		LD DE,512
		ADD HL,DE
;		LD A,0XF0
		PUSH HL
		CALL IDSDEV
		POP HL
		AND A
		CALL Z,INITS91
		ld	(hddslave_exist),a
		POP HL
		LD L,A
		XOR A

HDSOFF		RET
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

INITS91		PUSH HL
		LD L,49*2+1
		LD A,(HL)
		AND 2
		JR Z,INIS912
		LD BC,(PS1F2*0X0100)+LOW_PRT
		LD L,0X0C
		LD A,(HL)
		CALL SOUTPRT
		LD L,6
		LD B,PS1F6
		ld	a,(hl)
		dec	a
		and	15
		ld	d,a
		ld	a,(MS)
		or	d
		CALL SOUTPRT
		LD B,PS1F7
		LD A,0X91
		CALL SOUTPRT
		LD DE,0X1000
INIS911		DEC DE
		LD A,D
		OR E
		JR Z,INIS912
		CALL SINPRT
		AND 0X80
		JR NZ,INIS911
		POP HL
		RET

INIS912		LD A,0XFF
		POP HL
		RET

HDSRDS		LD A,1
HDSRDM		PUSH BC
		PUSH DE
		CALL SETSREG
		EX AF,AF'
		LD B,PS1F7
		LD A,0X20
		CALL SOUTPRT
		call W_DRQ
		EX AF,AF'
.read1		PUSH AF
		CALL RDCSSEC
		call W_BSY
		POP AF
		DEC A
		JR NZ,.read1
		POP DE
		POP BC
		XOR A
		RET

HDSWTS		LD A,1
HDSWTM		PUSH BC
		PUSH DE
		CALL SETSREG
		EX AF,AF'
		LD B,PS1F7
		LD A,0X30
		CALL SOUTPRT
		call W_DRQ
		EX AF,AF'
.write1		PUSH AF
		CALL WRSSEC
		call W_BSY
		POP AF
		DEC A
		JR NZ,.write1
		POP DE
		POP BC
		XOR A
		RET

RDCSSEC		LD DE,PRTSRW
		LD A,0X40
RDCSSC1		EX AF,AF'
		rept 4
		LD B,D
		CALL SINPRT
		LD (HL),A
		INC HL
		LD B,E
		CALL SINPRT
		LD (HL),A
		INC HL
		endm
		EX AF,AF'
		DEC A
		JR NZ,RDCSSC1
		RET

WRSSEC   	LD DE,PRTSRW
		ld a,#40
		
.wr		ex af,af'
		dup 4
		ld b,e
	     	INC HL
	     	LD A,(HL)
	     	CALL SOUTPRT
	        LD B,d
	        DEC HL
	        LD A,(HL)
	        CALL SOUTPRT
	        INC HL
	        INC HL
	        edup
	        ex af,af'
	        DEC a:JR NZ,.wr
	        RET

W_DRQ		LD B,PS1F7
.drq		CALL SINPRT
		AND 0X88
		CP 8
		JR NZ,.drq
		RET
W_BSY		LD B,PS1F7
.bsy		CALL SINPRT
		AND 0X80
		JR NZ,.bsy
		ret

SETSREG		PUSH DE
		EX AF,AF'
		ld	a,b	;LBA28 - отсекаем биты 4-7, т.к. в этой адресации они не поддерживаются
		and	15
		LD D,a
		LD E,C
		LD BC,(PS1F6*0X0100)+LOW_PRT
		ld	a,(MS)
		or	d
		CALL SOUTPRT
		LD B,PS1F5
		LD A,E
		CALL SOUTPRT
		POP DE
		LD B,PS1F4
		LD A,D
		CALL SOUTPRT
		LD B,PS1F3
		LD A,E
		CALL SOUTPRT
		LD B,PS1F2
		EX AF,AF'

SOUTPRT		PUSH HL
		LD HL,0X3FF0
		EX (SP),HL
		JP 0X3D2F

LDIRRET		PUSH HL
		LD HL,0X180D
		EX (SP),HL
		JP 0X3D2F

CPINOUT		OUT (C),A
		RET
		IN A,(C)
		RET

SINPRT		PUSH HL
		LD HL,0X3FF3
		EX (SP),HL
		JP 0X3D2F

;HL-АДРЕС БУФЕРА СЕКТОРА ИДЕНТИФИКАЦИИ
;A=E0-ДЛЯ MASTER, A=F0-ДЛЯ SLAVE
IDSDEV		LD BC,(PS1F6*0X0100)+LOW_PRT
		ld	a,(MS)
		CALL SOUTPRT
		LD B,PS1F7
		LD D,26
IDSDEV2		EI
		HALT
		DI
		DEC D
		JR Z,NOSDEV
		CALL SINPRT
		BIT 7,A
		JR NZ,IDSDEV2
		AND A
		JR Z,NOSDEV
		INC A
		JR Z,NOSDEV
		XOR A
		LD B,PS1F5
		CALL SOUTPRT
		LD B,PS1F4
		CALL SOUTPRT
		LD A,0XEC
		LD B,PS1F7
		CALL SOUTPRT
		LD B,PS1F7
ISDEV3		CALL SINPRT
		AND A
		JR Z,NOSDEV
		INC A
		JR Z,NOSDEV
		DEC A
		RRCA
		JR C,IDSDEV1
		RLCA
		AND 0X88
		CP 8
		JR NZ,ISDEV3
IDSDEV1		LD B,PS1F4
		CALL SINPRT
		LD E,A
		LD B,PS1F5
		CALL SINPRT
		LD D,A
		OR E
		JP Z,RDCSSEC
		LD HL,0XEB14
		LD A,1
		SBC HL,DE
		RET Z
NOSDEV		LD A,0XFF
		RET
DRVEND
 IFNDEF	MAIN
	SAVEBIN	"..\out\smucide.drv",DRVSTART,DRVEND-DRVSTART
 ENDIF
