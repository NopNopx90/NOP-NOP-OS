bits 16
print16:
  push si
    push ax

    .label:
        lodsb ; load a byte in al from memory location pointed by ds:si
        or al,al ; detect null character
        jz .done 

        mov ah,0x0e
        int 0x10
        jmp .label
    
    .done:
    pop ax
    pop si
    ret


bits 32
VID_MEM equ 0xb8000
WHITE_ON_BLACK equ 0x0f

print_string_pm :
pusha
mov edx , VID_MEM ; Set edx to the start of vid mem.

pm_print:
    mov al , [ebx] ; Store the buffer at EBX in AL
    mov ah , WHITE_ON_BLACK ; Store the attributes in AH
    cmp al , 0 ; if end of string
    je .end ; jump to done
    mov [edx] , ax
    inc ebx      ; Increment EBX
    add edx , 2 ; Move to next character cell in vid mem.
    jmp pm_print
    .end:
        popa
        ret 