
	MACRO INITCONSOLE
	call	InitConsole
	ENDM


	MACRO CLS
	call	ClearScr
	ENDM
	
	MACRO PCHARS
	call	Print
	ENDM

	MACRO _ANYKEY
	ld	hl,msgAnyKey
	PCHARS
	ld	hl,0
	call	Prompt
	ENDM