@REM @echo off
nasm "%CD%\src\bootloader\boot.asm" -f bin -o "%CD%\build\bootloader.bin"
nasm "%CD%\src\kernal\kernal.asm" -f bin -o "%CD%\build\kernal.bin"
nasm "%CD%\src\bootloader\stage2.asm" -f bin -o "%CD%\build\stage2.bin"

@REM create floppy image

@REM 1.44 MB (2880 sectors * 512 bytes per sector)
echo Creating floppy_M.img disk image and formating it to fat12
echo 1.44 MB (2880 sectors * 512 bytes per sector)

@REM create fat file system on the floppy image and set volume label
imdisk -a -o rw -t file -m X: -f "%CD%\build\floppy_M.img" -s 1474560 -S 512 -p "/fs:fat /q" -u 11
imdisk -l -m X:
imdisk -D -m X:
echo Floppy disk image formatted to FAT12 and dismounted.
gcc overwrite.c -o "%CD%\build\overwrite.exe"
"%CD%\build\overwrite.exe" ".\build\floppy_M.img" ".\build\bootloader.bin"

imdisk -a -o rw -t file -m X: -f "%CD%\build\floppy_M.img" -s 1474560 -S 512 -u 11
copy /b "%CD%\build\kernal.bin" X:\
copy /b "%CD%\build\stage2.bin" X:\
imdisk -l -m X:
imdisk -D -m X:

@REM qemu-system-i386 -s -S -fda "%CD%\build\floppy_M.img"
qemu-system-i386 -fda "%CD%\build\floppy_M.img"

pause