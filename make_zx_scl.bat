echo off
Echo Building main file...
@echo _TARGET	equ	_ZX128>target.inc
call make_zx.bat
if errorlevel 1 goto ERR
cd drv
call make_nemo_drv.bat
call make_nemo_drv_lba48.bat
call make_smuc_drv.bat
call make_profi_drv.bat
call make_atm_drv.bat
cd ..
if errorlevel 1 goto ERR
echo Ok!

Echo Compressing main file...
tools\MegaLZ\Exe\Win32\MegaLZ.exe out\fdisk.bin
echo Ok!
Echo Building loader...
C:\asm\sjasm\sjasmplus.exe --lst=loader.lst --lstlab libs\loader.asm
if errorlevel 1 goto ERR
echo Ok!
copy out\header.txt /B + readme.txt /B out\readme.txt
Echo Building SCL-file...
tools\trdtool # out\fdisk.scl
tools\trdtool + out\fdisk.scl out\boot.$b
tools\trdtool + out\fdisk.scl out\fdisk.bin.mlz
tools\monoscl out\fdisk.scl
tools\trdtool + out\fdisk.scl out\nemoide.drv
tools\trdtool + out\fdisk.scl out\ni_lba48.drv
tools\trdtool + out\fdisk.scl out\smucide.drv
tools\trdtool + out\fdisk.scl out\profiide.drv
tools\trdtool + out\fdisk.scl out\atmide.drv
tools\trdtool + out\fdisk.scl out\readme.txt
tools\trdtool + out\fdisk.scl history.txt
if errorlevel 1 goto ERR
del /Q out\boot.$b out\fdisk.bin.mlz out\fdisk.bin out\*.drv
echo Ok!
goto END
:ERR
pause
echo ошибки компиляции...

:END

pause 0