 IFNDEF MAIN
	device	zxspectrum128
	include "..\fdisk_exp.inc"
	org	_DRVORG
 ENDIF
DRVSTART
;LAST UPDATE: 09.02.2010 savelij
;29.08.2013 HARD - �������� ������ �� SLAVE-������������
;03.09.2013 HARD - ������� ��������� ����� CY ��� ������ ��������������� ��� ����� ����������
;03.09.2013 HARD - ������� ��������� LBA48, ������ �������������� ������ �� 32 ���, ����� �������� ������������ �������������� ��������, ��� ����� � �������. �� ���������!!!
Hddinit		EQU 0
Hddoff		EQU 1
Hddrds		EQU 2
Hddrdm		EQU 3
;���������
;+0 - hdrv
;+4 - ������:
;������� ����	0 - ��������� LBA48 1 - ��, 0 - ���
NemoIDE
		db "hdrv1" ; ���������
.str		db "NemoIDE v.0.2 (exp.LBA48)"
		ds 27-($-.str),32
;����� ����� ����� ��� ������ � HDD NEMO
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
		dw HDDWTS				;write single
		DW HDDRDM			;READ MULTI
		dw HDDWTM				;write multi

MS		DB	0	;������� ������ 0 - ������, 1 - �����
LBA48Cur	db	0	;��������� �������� ��������� lba48
;������� ��������� �����:
;HL-����� �������� � ������
;BCDE � DE'-48 ������ ����� ������� (DE - 0-15, BC - 16-31, DE' - 32-48)
;A-���������� ������ (����=512 ����)
;������ ��� ������������ ������/������

P_1F7		EQU 0XF0			;������� ���������/������� ������
P_1F6		EQU 0XD0			;CHS-����� ������ � ����/LBA ����� 24-27
P_1F5		EQU 0XB0			;CHS-������� 8-15/LBA ����� 16-23
P_1F4		EQU 0X90			;CHS-������� 0-7/LBA ����� 8-15
P_1F3		EQU 0X70			;CHS-����� �������/LBA ����� 0-7
P_1F2		EQU 0X50			;������� ��������
P_1F1		EQU 0X30			;���� ������/�������
P_1F0		EQU 0X10			;���� ������
P_3F6		EQU 0XC8			;������� ���������/����������
P_HI		EQU 0X11			;������� 8 ���
PRT_RW		EQU P_1F0*256+P_HI	;����� ������/������ ����� ������

;�� ������:
;H-��� MASTER 0-HDD, 1-CDROM, 0XFF-NONE
;L-��� SLAVE  0-HDD, 1-CDROM, 0XFF-NONE
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
		ld	a,b
		ld	(LBA48M),a
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
		ld	a,b
		ld	(LBA48S),a
		XOR A

HDDOFF		RET
;��������� ������� ������� ��� ���� ����������� ��������
HDDSETMASTER	ld	a,0
hddmaster_exist	equ	$-1
		and	a
		scf
		ret	nz
		LD	A,0XE0		;LBA + Master
		ld	b,0
LBA48M		equ	$-1
HDDSET1		ld	(MS),A
		ld	a,b
		ld	(LBA48Cur),a
		AND	A
		RET
;��������� ������ ������� ��� ���� ����������� ��������
HDDSETSLAVE	ld	a,0
hddslave_exist	equ	$-1
		and	a
		scf
		ret	nz
		LD	A,0XF0		;LBA + Slave
		ld	b,0
LBA48S		equ	$-1
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
		ld	l,83*2+1	;���������� ��������� lba48
		ld	a,(hl)
		and	4
		ld	b,0
		jr	z,.i1
		ld	b,1
.i1		xor	a
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
		ld	a,(LBA48Cur)
		and	a
		LD A,0X20	;Read sector(s)
		jr	z,.lba28
		ld	a,0x24	;Read sector(s) ext
		
.lba28		OUT (C),A
		call W_DRQ
		EX AF,AF'
HDDRD2		EX AF,AF'
		CALL READSEC
		call W_BSY
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
		ld	a,(LBA48Cur)
		and	a
		LD A,0X30	;Read sector(s)
		jr	z,.lba28
		ld	a,0x34	;Read sector(s) ext
		
.lba28		OUT (C),A
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
;������ 512� ������
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
;������ 512� ������ �� HDD
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
		ld	a,(LBA48Cur)
		and	a
		jr	nz,.lba48
		ld	a,b		;Hard 8:23 03.09.2013
		and	%00001111	;
		LD D,a			;
		LD E,C
		LD BC,0XFF00+P_1F6
		LD	A,(MS)		;Master/Slave
		OR	D
		OUT (C),A
		LD C,P_1F7
.SETHRE1	IN A,(C)
		AND 0X80
		JR NZ,.SETHRE1
		LD C,P_1F5
		OUT (C),E
		POP DE
		LD C,P_1F4
		OUT (C),D
		LD C,P_1F3
		OUT (C),E
.setseccnt	LD C,P_1F2
		EX AF,AF'
		OUT (C),A
		RET
.lba48		ld	a,b	;��������� LBA48
		exx
		ld	b,a
		exx
		ld	e,c
		ld	bc,0xff00+P_1F6
		ld	a,(MS)
		out	(c),a
		ld	c,P_1F7
.SETHRE2	IN	A,(C)
		AND	0X80
		JR	NZ,.SETHRE2
		ld	c,P_1F5	;LBA 23-16 | 47-40
		exx
		ld	a,d	;de' - LBA 47:40 - 39-32
		exx
		out	(c),a
		nop		;�� ������ ������
		out	(c),e	;c - 23-16	;de - LBA 15-8 - 7-0
		pop	de
		ld	c,P_1F4	;LBA 15-8 | 39-32
		exx
		ld	a,e
		exx
		out	(c),a
		nop
		out	(c),d
		ld	c,P_1F3	;LBA 7-0 | 31-24
		exx
		ld	a,b
		exx
		out	(c),a
		nop
		out	(c),e
		jr	.setseccnt
		
		
		
		

;HL-����� ������ ������� �������������
;A=E0-��� MASTER, A=F0-��� SLAVE
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
	SAVEBIN	"..\out\ni_lba48.drv",DRVSTART,DRVEND-DRVSTART
 ENDIF
