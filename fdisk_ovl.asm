	phase	0xbf02
_ClearScreen
	jp	ClearScr
_PrintChar
	jp	Print
_ScrollUP
	jp	ScrollUP
_CursorOn
	jp	CursorOn
_CursorOff
	jp	CursorOff
_AddCMD	jp	AddCMD
_SelectCMD			;заглушка для будущей подпрограммы выбора пунктов меню
	ret
	db	0,0
_Prompt	jp	Prompt
_EditString
	jp	EditString
_PRNUM	jp	PRNUM
_PRNUM0	jp	PRNUM0
_SetDEC	ret
	db	0,0
_SetHEX	ret
	db	0,0
_MRNUM	jp	MRNUM
_ByteToHEX
	jp	ByteToHEX
_PRNUMSEC
	jp	PRNUMSEC
_PRNUMBYTES
	jp	PRNUMBYTES
_OpenPG	jp	OpenPG
_ShowPartitions
	jp	ShowPartitions
_GetLastPartition
	jp	GetLastPartition
_GetExtended
	jp	GetExtended
_NextSecondary
	jp	NextSecondary
_CheckSecondary
	jp	CheckSecondary
_CheckPrimary
	jp	CheckPrimary
_NextPrimary
	jp	NextPrimary
_ShowMBRUS
	jp	ShowMBRUS
	ent