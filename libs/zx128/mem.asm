CurrentPage	equ	#5B5C	;BANKM
OpenPG
	PUSH	BC
	LD	BC,32765
	or	16
	ld	(CurrentPage),a
	OUT	(C),A
	POP	BC
	RET