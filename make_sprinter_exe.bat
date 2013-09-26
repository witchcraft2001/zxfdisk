@echo _TARGET	equ	_SPRINTER>target.inc
build.exe
C:\asm\sjasm\sjasmplus.exe --exp=fdisk_exp.inc --lst=fdisk_sprinter.lst --lstlab fdisk_main.asm
if errorlevel 1 goto ERR
echo Ok!

Echo Compressing main file...
tools\MegaLZ\Exe\Win32\MegaLZ.exe out\fdisk.bin
echo Ok!
Echo Building loader...
C:\asm\sjasm\sjasmplus.exe --lst=loader.lst --lstlab libs\sprinter\loader.asm
if errorlevel 1 goto ERR
echo Ok!
Echo Building EXE-file...
if errorlevel 1 goto ERR
copy out\loader.exe /B + out\fdisk.bin.mlz /B out\fdisk.exe
del /Q out\loader.exe out\fdisk.bin.mlz out\fdisk.bin out\*.drv
echo Ok!
goto END
:ERR
pause
echo ошибки компиляции...

:END

pause 0