CurrentPage	equ	#5B5C	;BANKM
CurrentPage7F	db 0
OpenPG
	PUSH	BC
	LD	BC,32765
	or	%00011000
	ld	(CurrentPage7F),a
	OUT	(C),A
	POP	BC
	RET 
OpenPGDF
	PUSH	BC
	LD	BC,#DFFD
	or	#80
	ld	(CurrentPage),a
	OUT	(C),A
	POP	BC
	RET 
