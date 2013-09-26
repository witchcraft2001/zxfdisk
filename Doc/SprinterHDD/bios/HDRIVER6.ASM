
;========================================================
;R03  !25.07.2001! BUG FIX WITH RETURN ERROR CODE
;R02  !24.07.2001! ADD SECONDARY CHANEL
;R01  !16.08.2000! REMOVED "DI"

;Write
HDW_COM	EQU	#4153	;1F7H Command
HDW_DRV	EQU	#4152	;1F6H Drive Control

HDW_CLH	EQU	#0155	;1F5H Cylinder High
HDW_CLL	EQU	#0154	;1F4H Cylinder Low
HDW_SEC	EQU	#0153	;1F3H Sector
HDW_CNT	EQU	#0152	;1F2H Counter
HDW_ERR	EQU	#0151	;1F1H Error
HDW_DAT	EQU	#0150	;1F0H Data
;Read
HDR_CTL	EQU	#4053	;1F7H Status (Control)
HDR_DRV	EQU	#4052	;1F6H Drive Control

HDR_CLH	EQU	#0055	;1F5H Cylinder High
HDR_CLL	EQU	#0054	;1F4H Cylinder Low
HDR_SEC	EQU	#0053	;1F3H Sector
HDR_CNT	EQU	#0052	;1F2H Counter
HDR_ERR	EQU	#0051	;1F1H Error
HDR_DAT	EQU	#0050	;1F0H Data

BSY	EQU	7
RDY	EQU	6
DRQ	EQU	3
ERR	EQU	0

HDD	EQU	1

;EQU FOR IY+
DRVHD_H	EQU	0
SC_PT_H	EQU	1
HEADS_H	EQU	2
CYL_L_H	EQU	3
CYL_H_H	EQU	4
SPCLL_H	EQU	5
SPCLH_H	EQU	6
TYPE_H	EQU	7

IDE0	EQU	#C1C0
IDE1	EQU	#C1C8
IDE2	EQU	#C1D0
IDE3	EQU	#C1D8


;IDE0	 DB	 #FF	 ;DRIVE/HEAD REGISTER	      ;00
;	 DB	 #FF	 ;SECTORS PER TRACK	      ;01
;	 DB	 #FF	 ;HEADS			      ;02
;	 DB	 #FF	 ;CYLINDERS LOW		      ;03
;	 DB	 #FF	 ;CYLINDERS HIGH	      ;04
;	 DB	 #FF	 ;SECTOR PER CYLINDER LOW     ;05
;	 DB	 #FF	 ;SECTOR PER CYLINDER HIGH    ;06
;	 DB	 #FF	 ;RESERVED		      ;07

;IDE1	 DB	 #FF	 ;DRIVE/HEAD REGISTER	      ;00
;	 DB	 #FF	 ;SECTORS PER TRACK	      ;01
;	 DB	 #FF	 ;HEADS			      ;02
;	 DB	 #FF	 ;CYLINDERS LOW		      ;03
;	 DB	 #FF	 ;CYLINDERS HIGH	      ;04
;	 DB	 #FF	 ;SECTOR PER CYLINDER LOW     ;05
;	 DB	 #FF	 ;SECTOR PER CYLINDER HIGH    ;06
;	 DB	 #FF	 ;RESERVED		      ;07

RESETH:	XOR	A
	RET 

SELECTH	AND	#0F
	LD	IY,IDE0
	JR	Z,SELHH
	DEC	A
	LD	IY,IDE1

	IF	WITH_2IDE=1

	JR	Z,SELHH
	DEC	A	;R02
	LD	IY,IDE2	;R02
	JR	Z,SELHH ;R02
	DEC	A	;R02
	LD	IY,IDE3	;R02

	ENDIF

	JR	NZ,NODRIVE
SELHH	EXX 
	LD	C,PAGE3
	IN	B,(C)
	LD	A,SYSPAGE
	OUT	(C),A

	IF	WITH_2IDE=1
	
	LD	A,(IY+DRVHD_H)
	AND	#01
	LD	A,#01	;SECONDARY
	JR	NZ,SELCHAN
	LD	A,#21	;PRIMARY
SELCHAN	OUT	(#BC),A	;R02

	ENDIF
	
	LD	A,(IY+TYPE_H)
	CP	HDD
	LD	A,(IY+DRVHD_H)
	OUT	(C),B
	LD	BC,HDW_DRV
	RES	0,A
	OUT	(C),A
	EXX 
	RET	Z
NODRIVE	LD	A,2
	SCF 
	RET 

;[]===========================================================[]
;Function: Get Current Media Parameters
;	A - Disk
;Return:
;	H - Heads
;	L - Sectors
;      DE - Cylinders
;      IX - Capacity sector in bytes
;	B - Flags
;[]===========================================================[]
GETMEDH	CALL	SELECTH
	RET	C
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,SYSPAGE
	OUT	(PAGE3),A
	LD	L,(IY+SC_PT_H)
	LD	H,(IY+HEADS_H)
	LD	E,(IY+CYL_L_H)
	LD	D,(IY+CYL_H_H)
	LD	B,(IY+DRVHD_H)
	LD	IX,512
	EX	AF,AF'
	OUT	(PAGE3),A
	EX	AF,AF'
	AND	A
	RET 

;[]===========================================================[]
;Function: Set Current Media Parameters
;	A - Disk
;	H - Heads
;	L - Sectors
;      DE - Cylinders
;      IX - Capacity sector in bytes
;	B - Flags
;Return: None
;[]===========================================================[]
SETMEDH	CALL	SELECTH
	RET	C
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,SYSPAGE
	OUT	(PAGE3),A
	LD	(IY+SC_PT_H),L
	LD	(IY+HEADS_H),H
	LD	(IY+CYL_L_H),E
	LD	(IY+CYL_H_H),D
	LD	(IY+DRVHD_H),B
	EX	AF,AF'
	OUT	(PAGE3),A
	EX	AF,AF'
	AND	A
	RET 

;[]===========================================================[]
;Function: Read	Sectors
;	A - Disk
;   HL:IX - Sector
;      DE - Address
;	B - Sector counter
;Return:
;   HL:IX - Sector + Sector counter
;      DE - Address + (Sector counter *	Size sector)
;[]===========================================================[]
;READ SECTOR(S)
READH	EX	AF,AF'
	IN	A,(PAGE3)
	EX	AF,AF'
;[]===========================================================[]
;Function: Long	Read Sectors
;	A - Disk
;   HL:IX - Sector
;      DE - Address
;	B - Sector counter
;	A'- Memory ID Block
;Return:
;   HL:IX - Sector + Sector counter
;      DE - Address + (Sector counter *	Size sector)
;[]===========================================================[]
;LONG READ SECTOR(S)
LREADH:	PUSH	IY
	EXX 
	LD	C,Y_PORT
	IN	B,(C)
	PUSH	BC
	LD	E,#C0
	OUT	(C),E
	EXX 
	PUSH	BC
	PUSH	IX
	PUSH	HL
	CALL	RDS000
	EX	DE,HL
	JP	C,HERRRD0
	LD	A,XH
	EX	AF,AF'
	POP	HL
	POP	IX
	POP	BC
	XOR	A
	CP	B
	LD	C,B
	LD	B,A
	JR	NZ,RNOT256
	INC	B
	ADD	IX,BC
	LD	B,C
	ADC	HL,BC
	EX	AF,AF'
	JR	RST8RDR

RNOT256	ADD	IX,BC
	LD	C,B
	ADC	HL,BC
	EX	AF,AF'
	JR	RST8RDR

HERRRD0	LD	B,A
	LD	C,XL
	LD	A,XH
	EX	AF,AF'
	POP	HL
	POP	IX
	PUSH	BC
	LD	B,0
	ADD	IX,BC
	LD	C,B
	ADC	HL,BC
	POP	BC
	POP	AF
	SUB	C
	LD	C,A
	LD	A,B
	LD	B,C
	SCF		;R03
	EX	AF,AF'	;R03
RST8RDR	EXX 
	POP	BC
	OUT	(C),B
	EXX 
	POP	IY
	EX	AF,AF'
	RET 

;READ SECTOR(S)
RDS000:	CALL	SELECTH
	RET	C
	EXX 
	LD	DE,#C140	;WAIT BUSY=0 & READY=1 & ERR=0
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	EX	AF,AF'
	PUSH	AF
	PUSH	DE
	CALL	PRESET
	POP	HL
	POP	AF
	LD	XL,0
	LD	XH,A
	LD	BC,HDW_COM
	LD	A,#020		;READ WITH RETRY
	OUT	(C),A
;SAVE HL!
RDS002:	EXX 
	LD	DE,#8908   ;WAIT BUSY=0 & DRQ=1 & ERR=0
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	NOP		    ;R01 REMOVED "DI"
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,XH
	OUT	(PAGE3),A
	LD	BC,HDR_DAT
	LD	D,#20
RDS003:	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	INI 
	DEC	D
	JR	NZ,RDS003
	EX	AF,AF'
	OUT	(PAGE3),A
	EI 
;
	LD	A,H
	OR	L
	JR	NZ,W44
	LD	HL,#C000
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,SYSPAGE
	OUT	(PAGE3),A
	LD	D,#C2
	LD	E,XH
	LD	A,(DE)
	LD	XH,A
	EX	AF,AF'
	OUT	(PAGE3),A
W44
;
	INC	XL	    ;INC LOADED	SECTORS
	EXX 
	LD	DE,#C140   ;WAIT BUSY=0 & ERR=0 & READY=1
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	LD	BC,HDR_CTL
	IN	A,(C)
	BIT	DRQ,A
	JR	NZ,RDS002
	XOR	A
	RET 

;[]===========================================================[]
;Function: Write Sectors
;	A - Disk
;   HL:IX - Sector
;      DE - Address
;	B - Sector counter
;Return:
;   HL:IX - Sector + Sector counter
;      DE - Address + (Sector counter *	Size sector)
;[]===========================================================[]
;WRITE SECTOR(S)
WRITEH	EX	AF,AF'
	IN	A,(PAGE3)
	EX	AF,AF'
;[]===========================================================[]
;Function: Long	Write Sectors
;	A - Disk
;   HL:IX - Sector
;      DE - Address
;	B - Sector counter
;	A'- Memory ID Block
;Return:
;   HL:IX - Sector + Sector counter
;      DE - Address + (Sector counter *	Size sector)
;[]===========================================================[]
;WRITE SECTOR(S)
LWRITEH:
	PUSH	IY
	EXX 
	LD	C,Y_PORT
	IN	B,(C)
	PUSH	BC
	LD	E,#C0
	OUT	(C),E
	EXX 
	PUSH	IX
	PUSH	HL
	PUSH	BC
	CALL	WRS000
	EX	DE,HL
	JP	C,HERRWR0
	LD	A,XH
	EX	AF,AF'
	POP	HL
	POP	IX
	POP	BC
	XOR	A
	CP	B
	LD	C,B
	LD	B,A
	JR	NZ,WNOT256
	INC	B
	ADD	IX,BC
	LD	B,C
	ADC	HL,BC
	EX	AF,AF'
	JR	RST8WRR

WNOT256	ADD	IX,BC
	LD	C,B
	ADC	HL,BC
	EX	AF,AF'
	JR	RST8WRR

HERRWR0	LD	B,A
	LD	C,XL
	LD	A,XH
	EX	AF,AF'
	POP	HL
	POP	IX
	PUSH	BC
	LD	B,0
	ADD	IX,BC
	LD	C,B
	ADC	HL,BC
	POP	BC
	POP	AF
	SUB	C
	LD	C,A
	LD	A,B
	LD	B,C
	SCF		;R03
	EX	AF,AF'	;R03
RST8WRR	EXX 
	POP	BC
	OUT	(C),B
	EXX 
	POP	IY
	EX	AF,AF'
	RET 

;WRITE SECTOR(S)
WRS000:	CALL	SELECTH
	RET	C
	EXX 
	LD	DE,#C140	;WAIT BUSY=0 & READY=1 & ERR=0
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	EX	AF,AF'
	PUSH	AF
	PUSH	DE
	PUSH	BC
	LD	D,#1D
	LD	C,#F6
	CALL	BIOS
	POP	BC
	AND	1
	JR	Z,NOWP
	POP	HL
	POP	AF
	EX	AF,AF'
	LD	XL,0
	LD	A,8	;WRITE PROTECT
	SCF 
	RET 
NOWP	CALL	PRESET
	POP	HL
	POP	AF
	LD	XL,0
	LD	XH,A
	LD	BC,HDW_COM
	LD	A,#30		;WRITE WITH RETRY
	OUT	(C),A
;SAVE HL!
WRS002:	EXX 
	LD	DE,#8908   ;WAIT BUSY=0 & DRQ=1 & ERR=0
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	DI 
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,XH
	OUT	(PAGE3),A
	LD	BC,HDW_DAT
	LD	D,#20
WRS003:	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	OUTI 
	DEC	D
	JR	NZ,WRS003
	EX	AF,AF'
	OUT	(PAGE3),A
	EI 
;
	LD	A,H
	OR	L
	JR	NZ,W33
	LD	HL,#C000
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,SYSPAGE
	OUT	(PAGE3),A
	LD	D,#C2
	LD	E,XH
	LD	A,(DE)
	LD	XH,A
	EX	AF,AF'
	OUT	(PAGE3),A
W33:
;
	INC	XL	    ;INC SAVED SECTORS
	EXX 
	LD	DE,#C140   ;WAIT BUSY=0 & ERR=0 & READY=1
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	LD	BC,HDR_CTL
	IN	A,(C)
	BIT	DRQ,A
	JR	NZ,WRS002
	XOR	A
	RET 

;[]===========================================================[]
;Function: Verify Sectors
;	A - Disk
;   HL:IX - Sector
;	B - Sector counter
;Return: None
;[]===========================================================[]
;VERIFY	SECTOR(S)
VERIFYH:
	PUSH	IY
	EXX 
	LD	C,Y_PORT
	IN	B,(C)
	PUSH	BC
	LD	E,#C0
	OUT	(C),E
	EXX 
	PUSH	IX
	PUSH	HL
	CALL	VRS000
	POP	HL
	POP	IX
	EXX 
	POP	BC
	OUT	(C),B
	EXX 
	POP	IY
	RET 

;VERIFY	SECTOR(S)
VRS000:	CALL	SELECTH
	RET	C
	EXX 
	LD	DE,#C140	;WAIT BUSY=0 & READY=1 & ERR=0
	LD	BC,HDR_CTL
	CALL	WAITPRT
	EXX 
	RET	C
	PUSH	DE
	CALL	PRESET
	POP	HL
	LD	BC,HDW_COM
	LD	A,#40		;VERIFY	WITH RETRY
	OUT	(C),A
VRS002:	LD	BC,HDR_CTL
	IN	A,(C)
	BIT	ERR,A
	JR	Z,VRS003
	SCF 
	RET 
VRS003:	LD	DE,#C140   ;WAIT BUSY=0 & ERR=0 & READY=1
	LD	BC,HDR_CTL
	CALL	WAITPRT
	RET	C
	XOR	A
	RET 

; HL:IX	- LBA SECTOR
;     B	- SECTOR COUNTER

PRESET:	LD	A,B
	LD	BC,HDW_CNT
	OUT	(C),A
	IN	A,(PAGE3)
	EX	AF,AF'
	LD	A,SYSPAGE
	OUT	(PAGE3),A
	LD	A,(IY+DRVHD_H)
	LD	BC,HDW_DRV
	OUT	(C),A
	BIT	6,A
	LD	E,XL
	LD	D,XH
	CALL	Z,LBA_CHS
	LD	BC,HDW_SEC
	OUT	(C),E		;LBA 0..7
	LD	BC,HDW_CLL
	OUT	(C),D		;LBA 8..15
	LD	BC,HDW_CLH
	OUT	(C),L		;LBA 16..23
	LD	BC,HDW_DRV
	DEC	B
	IN	A,(C)
	AND	#F0
	OR	H		;LBA 24..27
	INC	B
	OUT	(C),A
	EX	AF,AF'
	OUT	(PAGE3),A
	AND	A
	RET 

; HL:DE	- SECTOR OFFSET

LBA_CHS:
	LD	C,(IY+SPCLL_H)
	LD	B,(IY+SPCLH_H)
;	HL:DE /	BC => DE:IX HL-OSTATOK
DIV32X:	LD	XH,D
	LD	XL,E
	EX	DE,HL
	LD	HL,0
	LD	A,#20
DIV011:	ADD	IX,IX
	EX	DE,HL
	ADC	HL,HL
	EX	DE,HL
	ADC	HL,HL
	SBC	HL,BC
	JR	NC,DIV012
	ADD	HL,BC
	DEC	A
	JR	NZ,DIV011
	JR	DIV014
DIV012:	INC	IX
	DEC	A
	JR	NZ,DIV011
DIV014:	LD	E,(IY+SC_PT_H)
	LD	D,0
	XOR	A
CHS005:	INC	A
	SBC	HL,DE
	JR	NC,CHS005
	ADD	HL,DE
	DEC	A
	LD	H,A
	LD	E,L
	INC	E
	LD	D,XL
	LD	A,XH
	LD	L,A
	RET 

; D - MASK
; E - PATTERN
; BC - PORT

WAITPRT:
	LD	HL,#0000
WAITP0:	IN	A,(C)
;	CP	#FF
;	JR	Z,WAITP1
	AND	D
	CP	E
	JR	NZ,WAITP2
	AND	A
	RET 

WAITP2:	DEC	HL
	LD	A,L
	OR	H
	JP	NZ,WAITP0
WAITP1:	LD	A,4
	SCF 
	RET 

;=======================================================