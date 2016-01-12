	device zxspectrum128
	include "fdisk_exp.inc"
	org #5d3b-17

;��������� hobeta, savehob �� ������������ ��� ��� ����� ������ ���������

hobeta
	db "boot    B"
	dw line_end-begin
	dw line_end-begin
	db 0,high ((end-begin)+4)
	dw 0	;����������� �����

	;org #5d3b

begin
	db 0,1			;����� ������
	dw line_end-line_start	;����� ������ � ������
line_start
	db #f9,#c0,#30	;randomize usr 0
	db #0e,#00,#00	;�����
	dw code_start
	db #00,#3a,#ea	;:rem


code_start
	ld sp,#5fff

	;������� ������

	halt
	xor	a
	out (#fe),a
	ld hl,23295
	ld de,23294
	ld bc,768
	ld (hl),0
	lddr

	ld a,#10
	ld bc,#7ffd
	out (c),a
;�������� ������ � #6000 (page5)
	ld de,(23796)
	ld b,high ((main_end-main_start)+255)
	ld c,#05
	ld hl,#ffff - (main_end-main_start)
	call 15635

	di
	ld hl,#ffff - (main_end-main_start)
	ld de,FDISKSTART
	call DEC40

	ei
	jp MainStart
	include "libs\unmegalz.asm"

line_end

	display "Basic length ",/d,$-begin," bytes"

	db #80,#aa,#01,#00	;����� ������ ��� ����������

	ds (($-1-begin)&255)^255,0
end

	display "File size ",/d,end-begin," bytes"

	savebin "out\boot.$b",hobeta,end-hobeta

	org	#8000
main_start
	incbin "out\fdisk.bin.mlz"
main_end

;high (%~z1+255)