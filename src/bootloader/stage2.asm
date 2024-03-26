org 0x0
bits 16

jmp main

msg db "<16 bit> entering 32 bit PM... Processing...", 0xd,0xa,0


main:
	cli
	mov	ax, 0x9000		; stack 0x9000-0xffff
	mov	ss, ax
	mov	bp, 0xFFFF
	mov	sp, bp
	sti

    mov	si, msg
	call	print16

;;;;;;;;;;;;;;;;;;;;;;; Load GDT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cli								; clear interrupts first!
	lgdt	[GDT_Descriptor]		; load GDT into GDTR

;;;;;;;;;;;;;;;;;;;;;;; switch to 32 bit protected mode ;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov eax,cr0
	or eax,1
	mov cr0,eax
	jmp code_seg:Enable_PM			; far jump

%include ".\src\bootloader\gdt.asm"
%include ".\src\bootloader\print.asm"


bits 32
Enable_PM:

    mov	ax, data_seg		; set data segments 
	mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

	mov ebp,0x90000
	mov esp,ebp

    mov ebx,PM_MODE
    call print_string_pm

halt:
    cli
    hlt

PM_MODE db "[!] 32-bit Protected mode loaded ",0