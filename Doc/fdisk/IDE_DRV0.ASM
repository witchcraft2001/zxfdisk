
; Disk Driver Specification ver. 2.20
;[]===========================================================[]
;Procedure : Initialization
;
;Function  : Initialization device(s)
;
;Input	   : C = 00h
;	    IX - Environment
;Output	   : A = Amount	drive support
;	    HL = Size driver
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Open
;
;Function  : Open disk
;
;Input	   : C = 01h
;	     A - Drive
;Output	   : None
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Close
;
;Function  : Close disk
;
;Input	   : C = 02h
;	     A - Drive
;Output	   : None
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Media check
;
;Function  : Checking change line
;
;Input	   : C = 03h
;	     A - Drive
;Output	   : A = 00h disk no changed
;	     A = 0FFh disk changed
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Get BPB
;
;Function  : Get Block Parameters BIOS
;
;Input	   : C = 04h
;	    DE - Address
;Output	   : None
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Input
;
;Function  : Input from	disk
;
;Input	   : C = 05h
;	 HL:IX - Logical Block (sector)
;	    DE - Address
;	     B - Sector	count
;Output	   : None
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Output
;
;Function  : Output to disk
;
;Input	   : C = 06h
;	 HL:IX - Logical Block (sector)
;	    DE - Address
;	     B - Sector	count
;Output	   : None
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Removable
;
;Function  : Checking change line
;
;Input	   : C = 07h
;	     A - Drive
;Output	   : A = 00h Removable
;	     A = FFh Nonremovable
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Generic IOCTL
;
;Function  : Generic Input Output Control
;
;Input	   : C = 08h
;	     B - Subcommand
;	    DE = 55AAh Magic Number
;      Subcommand
;----------------------
;	  00h -	Get Device Parameters
;	  01h -	Read track
;	  02h -	Test track
;	  80h -	Set Device Parameters
;	  81h -	Write track
;	  82h -	Format track
;Output	   :
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Read Long
;
;Function  : Reading sectors from disk
;
;Input	   : C = 0Ah
;	 HL:IX - Logical Block (sector)
;	    DE - Address
;	     B - Sector	count
;	     A'- Page
;Output	   : A'- Next Page
;	 HL:IX - Next Logical Block (sector)
;	    DE - Next Address
;
;[]===========================================================[]
;[]===========================================================[]
;Procedure : Write Long
;
;Function  : Writing sectors to	disk
;
;Input	   : C = 0Bh
;	 HL:IX - Logical Block (sector)
;	    DE - Address
;	     B - Sector	count
;	     A'- Page
;Output	   : A'- Next Page
;	 HL:IX - Next Logical Block (sector)
;	    DE - Next Address
;
;[]===========================================================[]
;
; Errors:
;   0 (00h) - NO ERRORS
;   1 (01h) - BAD COMMAND
;   2 (02h) - BAD DRIVE	NUMBER
;   3 (03h) - UNKNOW FORMAT
;   4 (04h) - NOT READY
;   5 (05h) - SEEK ERROR
;   6 (06h) - SECTOR NOT FOUND
;   7 (07h) - CRC ERROR
;   8 (08h) - WRITE PROTECT
;   9 (09h) - READ ERROR
;  10 (0Ah) - WRITE ERROR
;  11 (0Bh) - FAILURE
;  12 (0Ch) - BUSY (DEVICE OPENED)
;  13 (0Dh) - RESERVED

LD_DSK	EQU	16

IDE0	EQU	0C1C0H
IDE1	EQU	0C1C8H
PART	EQU	#C000

HDDRIVE	INC	C
	DEC	C
	JP	Z,INIT_H	;#00
	DEC	C
	JP	Z,RESE_H	;#01
	DEC	C
	JP	Z,STAT_H	;#02
	DEC	C
	JP	Z,CHEK_H	;#03
	DEC	C
	JP	Z,GBPB_H	;#04
	DEC	C
	JP	Z,READH		;#05
	DEC	C
	JP	Z,WRITEH	;#06
	DEC	C
	JP	Z,REMOV_H	;#07
	DEC	C
	JP	Z,IOCTL_H	;#08
	DEC	C
	JP	Z,RESR_H	;#09
	DEC	C
	JP	Z,LREADH	;#0A
	DEC	C
	JP	Z,LWRITEH	;#0B
RESR_H	LD	A,1
	SCF 
	RET 

;Commands for restart #18
INIT_H	PUSH	IY
	LD	HL,LOGDRV
	LD	(OFFSECT),HL

	LD	A,#80
	LD	(DRV),A
	LD	C,PAGE3
	IN	B,(C)
	LD	A,SYSPAGE
	OUT	(C),A
	LD	HL,IDE0
	CALL	YEP_DRV
	OUT	(C),B
	CALL	NZ,PARTIT

	LD	A,#81
	LD	(DRV),A
	LD	C,PAGE3
	IN	B,(C)
	LD	A,SYSPAGE
	OUT	(C),A
	LD	HL,IDE1
	CALL	YEP_DRV
	OUT	(C),B
	CALL	NZ,PARTIT

	POP	IY
	LD	HL,(OFFSECT)
	LD	DE,LOGDRV
	XOR	A
	SBC	HL,DE
	RET	Z
	LD	DE,LD_DSK
DRVCLC	INC	A
	SBC	HL,DE
	JR	NZ,DRVCLC
	AND	A
	RET 

YEP_DRV	LD	A,#FF
	CP	(HL)
	RET	NZ
	INC	HL
	CP	(HL)
	RET	NZ
	INC	HL
	CP	(HL)
	RET	NZ
	INC	HL
	CP	(HL)
	RET	NZ
	INC	HL
	CP	(HL)
	RET	NZ
	INC	HL
	CP	(HL)
	RET 

;+00	;SECTORS PER TRACK
;+01	;TRACKS	PER CYLLINDER
;+02	;RESERVED
;+03	;HDD/DRIVE/LBA
;+04	;SECTOR	PER CYLINDER LOW
;+05	;SECTOR	PER CYLINDER HIGH
;+06	;RESERVED
;+07	;RESERVED

DRVHD_H	EQU	0
SC_PT_H	EQU	1
HEADS_H	EQU	2
CYL_L_H	EQU	3
CYL_H_H	EQU	4
SPCLL_H	EQU	5
SPCLH_H	EQU	6


;IDE0	 DEFB	 #FF	 ;DRIVE/HEAD REGISTER	      ;00
;	 DEFB	 #FF	 ;SECTORS PER TRACK	      ;01
;	 DEFB	 #FF	 ;HEADS			      ;02
;	 DEFB	 #FF	 ;CYLINDERS LOW		      ;03
;	 DEFB	 #FF	 ;CYLINDERS HIGH	      ;04
;	 DEFB	 #FF	 ;SECTOR PER CYLINDER LOW     ;05
;	 DEFB	 #FF	 ;SECTOR PER CYLINDER HIGH    ;06
;	 DEFB	 #FF	 ;RESERVED		      ;07

;IDE1	 DEFB	 #FF	 ;DRIVE/HEAD REGISTER	      ;00
;	 DEFB	 #FF	 ;SECTORS PER TRACK	      ;01
;	 DEFB	 #FF	 ;HEADS			      ;02
;	 DEFB	 #FF	 ;CYLINDERS LOW		      ;03
;	 DEFB	 #FF	 ;CYLINDERS HIGH	      ;04
;	 DEFB	 #FF	 ;SECTOR PER CYLINDER LOW     ;05
;	 DEFB	 #FF	 ;SECTOR PER CYLINDER HIGH    ;06
;	 DEFB	 #FF	 ;RESERVED		      ;07

LOGDRV	DEFS	12*LD_DSK,#00
;+00	BYTE	MASTER/SLAVE PHISICAL DRIVE NUMBER #80/#81/...
;+01	LONG	SECTOR OFFSET
;+05	LONG	SIZE IN	SECTORS
;+09	FREE
;+15

SELHDD	PUSH	DE
	PUSH	BC
	PUSH	HL
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	EX	DE,HL
	LD	IY,LOGDRV
	ADD	IY,DE
	LD	C,(IY+1)
	LD	B,(IY+2)
	LD	E,(IY+3)
	LD	D,(IY+4)
	POP	HL
	ADD	IX,BC
	ADC	HL,DE
	LD	A,(IY+0)	;DRIVE NUMBER
	POP	BC
	POP	DE
	RET 

;	  00 - GET DEVICE PARAMETERS
;	  01 - READ TRACK
;	  02 - TEST TRACK
;	  80 - SET DEVICE PARAMETERS
;	  81 - WRITE TRACK
;	  82 - FORMAT TRACK


IOCTL_H	BIT	7,B
	JR	NZ,O_CTL_H
	INC	B
	DEC	B
	JP	Z,HGETPRM
	DEC	B
	JP	Z,HRDTRAC
	DEC	B
	JP	Z,HCHTRAC
	LD	A,1
	SCF 
	RET 

O_CTL_H	RES	7,B
	INC	B
	DEC	B
	JP	Z,HSETPRM
	DEC	B
	JP	Z,HWRTRAC
	DEC	B
	JP	Z,HFRTRAC
	LD	A,1
	SCF 
	RET 

HRDTRAC	LD	A,11
	SCF 
	RET 

HCHTRAC	LD	B,L
	CALL	CHECKH
	RET 

HSETPRM	AND	A
	RET 

HWRTRAC	LD	A,11
	SCF 
	RET 

HFRTRAC	LD	A,11
	SCF 
	RET 

; HL:DE	- SECTORS ON LOGICAL DISK
; HL'	- CYLINDERS ON PHISICAL	DISK
; DE'	- HEADS	ON PHISICAL DISK
; BC'	- SECTORS PER TRACK ON PHISICAL	DISK
;  A'	- PHISICAL DRIVE NUMBER
;  A	- DRIVE/HEAD REGISTER PHISICAL DISK
;	D0...D3	- "0" RESERVED (MAY BE OTHER)
;	D4	- DEVICE MASTER/SLAVE
;	D5	- "1" RESERVED
;	D6	- ADDRESSING MODE LBA/CHS
;	D7	- "1" RESERVED

HGETPRM	EX	DE,HL
	LD	BC,#55AA
	AND	A
	SBC	HL,BC
	LD	L,A
	LD	A,11
	SCF 
	RET	NZ
	PUSH	IY
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	B,H
	LD	C,L
	LD	IY,LOGDRV
	ADD	IY,BC
	LD	E,(IY+5)
	LD	D,(IY+6)
	LD	L,(IY+7)
	LD	H,(IY+8)

	LD	A,(IY+0)
	LD	C,A
	LD	IY,IDE0
	AND	#0F
	JR	Z,GELH1
	LD	IY,IDE1
GELH1	IN	A,(PAGE3)
	PUSH	AF
	LD	A,SYSPAGE
	OUT	(PAGE3),A

	LD	A,(IY+DRVHD_H)	     ;HDD/DRV
	EXX 
	LD	L,(IY+CYL_L_H)	     ;CYLINDER LOW
	LD	H,(IY+CYL_H_H)	     ;CYLINDER HIGH
	LD	E,(IY+HEADS_H)	     ;HEADS
	LD	D,0
	LD	C,(IY+SC_PT_H)	     ;SECTORS
	LD	B,0
	EXX 
	EX	AF,AF'
	POP	AF
	OUT	(PAGE3),A
	LD	A,C
	EX	AF,AF'
	POP	IY
	AND	A
	RET 

REMOV_H	LD	A,1
	AND	A
	RET 

RESE_H	XOR	A
	RET 

STAT_H	XOR	A
	RET 

CHEK_H	LD	A,#FF
	AND	A
	RET 

;HL:IX - SECTOR
;   DE - ADDRESS

GBPB_H	PUSH	IY
	PUSH	DE
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	B,H
	LD	C,L
	LD	IY,LOGDRV
	ADD	IY,BC
	LD	E,(IY+1)
	LD	D,(IY+2)
	LD	L,(IY+3)
	LD	H,(IY+4)
	LD	LX,E
	LD	HX,D
	LD	A,(IY+0)
	POP	DE
	POP	IY
	LD	BC,#0155
	RST	#08
	RET 

;HL:IX - SECTOR
;   DE - ADDRESS
;    B - COUNTER
;    A'- PAGE

;READ SECTOR
LREADH	PUSH	IY
	CALL	SELHDD
	LD	C,#52	; A - HDD NUMBER +128
	RST	#08
	POP	IY
	RET 

;HL:IX - SECTOR
;   DE - ADDRESS
;    B - COUNTER
;    A'- PAGE

;WRITE SECTOR
LWRITEH	PUSH	IY
	CALL	SELHDD
	LD	C,#53	; A - HDD NUMBER +128
	RST	#08
	POP	IY
	RET 

;HL:IX - SECTOR
;   DE - ADDRESS
;    B - COUNTER

;WRITE SECTOR
WRITEH	PUSH	IY
	CALL	SELHDD
	LD	C,#56	; A - HDD NUMBER +128
	RST	#08
	POP	IY
	RET 

;HL:IX - SECTOR
;   DE - ADDRESS
;    B - COUNTER

;READ SECTOR
READH	PUSH	IY
	CALL	SELHDD
	LD	C,#55	; A - HDD NUMBER +128
	RST	#08
	POP	IY
	RET 

;HL:IX - SECTOR
;   DE - ADDRESS
;    B - COUNTER

;CHECK SECTOR
CHECKH	PUSH	IY
	CALL	SELHDD
	LD	C,#54	; A - HDD NUMBER +128
	RST	#08
	POP	IY
	RET 

;-----------------
EASYDOS
MEDIDOS
HIGHDOS	LD	E,(IY+08)
	LD	D,(IY+09)
	LD	L,(IY+10)
	LD	H,(IY+11)
	LD	IX,(CURSECL)
	ADD	IX,DE
	LD	DE,(CURSECH)
	ADC	HL,DE
	LD	D,HX
	LD	E,LX
	LD	IX,(OFFSECT)
	LD	(IX+1),E	;BPB SECTOR
	LD	(IX+2),D
	LD	(IX+3),L
	LD	(IX+4),H
;	LD	DE,(CURSECL)
;	LD	HL,(CURSECH)
;	LD	(IX+1),E	;START DISK
;	LD	(IX+2),D
;	LD	(IX+3),L
;	LD	(IX+4),H
	LD	E,(IY+12)
	LD	D,(IY+13)
	LD	L,(IY+14)
	LD	H,(IY+15)
	LD	(IX+5),E       ;SIZE DISK
	LD	(IX+6),D
	LD	(IX+7),L
	LD	(IX+8),H
	LD	A,(DRV)
	LD	(IX+0),A
	LD	DE,LD_DSK      ;  DSKITEM
	ADD	IX,DE
	LD	(OFFSECT),IX
NXTPART	LD	DE,#10
	ADD	IY,DE
	POP	BC
	DJNZ	DOSAGA
	AND	A
	RET 

PARTIT	IN	A,(PAGE3)
	PUSH	AF
	LD	A,#FF
	OUT	(PAGE3),A
	CALL	PARTIT1
	POP	AF
	OUT	(PAGE3),A
	RET 

PARTIT1	LD	IX,0
	LD	DE,0
PARTIT2	LD	(CURSECL),DE
	LD	(CURSECH),IX
	CALL	LOADSEC
	LD	HL,(PART+510)
	LD	DE,#AA55
	AND	A
	SBC	HL,DE
	JR	NZ,NODEFIN
	LD	IY,PART+#01BE
	LD	B,4
DOSAGA	PUSH	BC
	LD	A,(IY+4)
	CP	5
	JR	NZ,NOEXTDS
SUBLEV	PUSH	IY
	LD	DE,(CURSECL)
	LD	IX,(CURSECH)
	PUSH	DE
	PUSH	IX
	CALL	EXTDOS
	POP	IX
	POP	DE
	LD	(CURSECL),DE
	LD	(CURSECH),IX
	CALL	LOADSEC
	POP	IY
	JP	NXTPART
NOEXTDS	CP	#0F
	JP	Z,SUBLEV
	CP	#0E
	JP	Z,HIGHDOS
	CP	6
	JP	Z,HIGHDOS
	CP	4
	JP	Z,MEDIDOS
	CP	1
	JP	Z,EASYDOS
	POP	BC
	OR	A
	RET	Z
NODEFIN	SCF 
	RET 

EXTDOS
	LD	HL,(EXTDOSL)
	LD	DE,(EXTDOSH)
	LD	A,L
	OR	H
	OR	E
	OR	D
	LD	E,(IY+08)
	LD	D,(IY+09)
	LD	L,(IY+10)
	LD	H,(IY+11)
	JP	NZ,EXTDOS2
	LD	(EXTDOSL),DE
	LD	(EXTDOSH),HL
	LD	IX,(EXTDOSH)
	JP	PARTIT2

EXTDOS2	LD	IX,(EXTDOSL)
	ADD	IX,DE
	PUSH	IX
	LD	DE,(EXTDOSH)
	ADC	HL,DE
	PUSH	HL
	POP	IX
	POP	DE
	JP	PARTIT2

LOADSEC	PUSH	IY
	LD	IX,(CURSECL)
	LD	HL,(CURSECH)
	LD	DE,PART
	LD	BC,#0155
	LD	A,(DRV)
	RST	#08
	POP	IY
	RET 

DRV	DEFB	#00	;PHISICAL DRIVE	NUMBER

CURSECL	DEFW	#0000	;CURRENT SECTOR	LOADED
CURSECH	DEFW	#0000

EXTDOSL	DEFW	#0000	;CURRENT PARTITION TABLE
EXTDOSH	DEFW	#0000

OFFSECT	DEFW	LOGDRV	;POINTER ON CURRENT DISK RECORD

;=======================================================



