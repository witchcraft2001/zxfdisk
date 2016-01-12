 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	org	_DRVORG
 ENDIF
;������� ������� �� ��������� CDWALK � Fatal (ProfiIDE)

PA_1F7W		EQU 0XFEEF			;W ������� ������
PA_1F7R		EQU 0XFEEF			;R ������� ���������
PA_1F6W		EQU 0XFECF			;W CHS-����� ������ � ����/LBA ����� 24-27
PA_1F6R		EQU 0XFECF			;R CHS-����� ������ � ����/LBA ����� 24-27
PA_1F5W		EQU 0XFEAF			;W CHS-������� 8-15/LBA ����� 16-23
PA_1F5R		EQU 0XFEAF			;R CHS-������� 8-15/LBA ����� 16-23
PA_1F4W		EQU 0XFE8F			;W CHS-������� 0-7/LBA ����� 8-15
PA_1F4R		EQU 0XFE8F			;R CHS-������� 0-7/LBA ����� 8-15
PA_1F3W		EQU 0XFE6F			;W CHS-����� �������/LBA ����� 0-7
PA_1F3R		EQU 0XFE6F			;R CHS-����� �������/LBA ����� 0-7
PA_1F2W		EQU 0XFE4F			;W ������� ��������
PA_1F2R		EQU 0XFE4F			;R ������� ��������
PA_1F1W		EQU 0XFE2F			;W ���� �������
PA_1F1R		EQU 0XFE2F			;R ���� ������
PA_1F0W		EQU 0XFE0F			;W ���� ������ ������� 8 ���
PA_1F0R		EQU 0XFE0F			;R ���� ������ ������� 8 ���
PA_3F6		EQU 0XFEBE			;W ������� ���������/����������
PA_HIW		EQU 0XFF0F			;W ���� ������ ������� 8 ���
PA_HIR		EQU 0XFF0F			;R ���� ������ ������� 8 ���

DRVSTART
;���������
;+0 - hdrv
;+4 - ������:
;������� ����	0 - ��������� LBA48 1 - ��, 0 - ���
		db "hdrv0" ; ���������
.str		db "ATM IDE v0.1"
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
		ld (restore_mode),a		;��������� ����������������� �����
		ld (restore_mode1),a
.f2		ex af,af'		
.f1		ADD A,A
		PUSH HL
		LD HL,ATM_CPM_OFF		;�/� ���������� ������ CPM ��� ������
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
		LD	BC,#FF77 ;����.������� �����
		LD	A,%10101011 ;����� ZX
restore_mode	equ	$-1
		JP	#3D2F
ATM_CPM_OFF1	pop	af
		pop	bc
		ret

ATM_CPM_ON
		LD	BC,#2A53
		PUSH	BC
		LD	A,%10101011	;���.������� �����
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
;������� ��������� �����:
;HL-����� �������� � ������
;BCDE-32-� ������ ����� �������
;A-���������� ������ (����=512 ����)
;������ ��� ������������ ������/������

;�� ������:
;H-��� MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-��� SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
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
		ld a,b	;LBA28 - �������� ���� 4-7, �.�. � ���� ��������� ��� �� ��������������
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

;HL-����� ������ ������� �������������
;A=E0-��� MASTER, A=F0-��� SLAVE
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
