org 0x0
bits 16

start:
    jmp main

print:
    push si
    push ax
    push bx

    .loop:
        lodsb               
        or al, al           
        jz .done
        mov ah, 0x0E        
        mov bh, 0           
        int 0x10
        jmp .loop

    .done:
        pop bx
        pop ax
        pop si    
        ret
    

main:

    mov si,second_sector
    call print
    mov si, msg_hello
    call print
    ; in al,0x64              ; al = status register value
    ; and al,00000010b        ; Input buffer status (0 = empty, 1 = full)\
    ; mov si,check
    ; call print
    ; jz input                ; if status register second bit is 0 then their is no data in buffer
    ; in al,0x60

halt:
    cli
    hlt

second_sector: db "Teeeehhheeee you loaded kernal !!!",0xd,0xa,0
msg_hello: db "Knock Knock Kernal here... ", 0xd,0xa, 0
; check: db "A",0xd,0xa,0