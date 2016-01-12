 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	include "..\fdisk_equs.inc"
	include	"..\target.inc"
	org	_DRVORG
CurrentPage	equ	#5B5C
 ENDIF
;������� ������� �� ��������� CDWALK � Fatal

PP_1F7W		EQU 0X07EB			;W ������� ������
PP_1F7R		EQU 0X07CB			;R ������� ���������
PP_1F6W		EQU 0X06EB			;W CHS-����� ������ � ����/LBA ����� 24-27
PP_1F6R		EQU 0X06CB			;R CHS-����� ������ � ����/LBA ����� 24-27
PP_1F5W		EQU 0X05EB			;W CHS-������� 8-15/LBA ����� 16-23
PP_1F5R		EQU 0X05CB			;R CHS-������� 8-15/LBA ����� 16-23
PP_1F4W		EQU 0X04EB			;W CHS-������� 0-7/LBA ����� 8-15
PP_1F4R		EQU 0X04CB			;R CHS-������� 0-7/LBA ����� 8-15
PP_1F3W		EQU 0X03EB			;W CHS-����� �������/LBA ����� 0-7
PP_1F3R		EQU 0X03CB			;R CHS-����� �������/LBA ����� 0-7
PP_1F2W		EQU 0X02EB			;W ������� ��������
PP_1F2R		EQU 0X02CB			;R ������� ��������
PP_1F1W		EQU 0X01EB			;W ���� �������
PP_1F1R		EQU 0X01CB			;R ���� ������
PP_1F0W		EQU 0X00EB			;W ���� ������ ������� 8 ���
PP_1F0R		EQU 0X00CB			;R ���� ������ ������� 8 ���
PP_3F6		EQU 0X06AB			;W ������� ���������/����������
PP_HIW		EQU 0XFFCB			;W ���� ������ ������� 8 ���
PP_HIR		EQU 0XFFEB			;R ���� ������ ������� 8 ���

DRVSTART
; IF _TARGET=_PROFI
;		db "hdrp0" ; ���������
; ELSE
		db "hdrv0" ; ���������
; ENDIF
.str		db "Profi IDE v0.1"
		ds 27-($-.str),32
;����� ����� ����� ��� ������ � HDD
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
		LD HL,EXIT_HDDP		;�/� ���������� ������ CPM ��� ������
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
;������� ��������� �����:
;HL-����� �������� � ������
;BCDE-32-� ������ ����� �������
;A-���������� ������ (����=512 ����)
;������ ��� ������������ ������/������

;�� ������:
;H-��� MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-��� SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
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
;��������� ������� ������� ��� ���� ����������� ��������
HDDSETMASTER	ld	a,0
hddmaster_exist	equ	$-1
		and	a
		scf
		ret	nz
		LD	A,0XE0	;LBA+MASTER
HDDSET1		ld	(MS),A
		AND	A
		RET
;��������� ������ ������� ��� ���� ����������� ��������
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
		ld a,b	;LBA28 - �������� ���� 4-7, �.�. � ���� ��������� ��� �� ��������������
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

;HL-����� ������ ������� �������������
;A=E0-��� MASTER, A=F0-��� SLAVE
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
