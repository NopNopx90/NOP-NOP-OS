org 0x7c00
bits 16

;;;;;;;;; FAT12 headers ;;;;;;;;;
jmp short main                ; 2 bytes (EB 3C)
nop                            ; 1 byte (90)

;;;;;;;;; BPB (BIOS Parameter Block) ;;;;;;;;;;

oem_identifier: db "MSDOS5.0"   ; 8 bytes
bps: dw 512                     ; 2 bytes
sectors_per_cluster: db 1       ; 1 byte
reserved_sectors: dw 1          ; 2 bytes
fat_count: db 2                 ; 1 bytes
; root_dir_entry_count: dw 512    ; 2 bytes
root_dir_entry_count: dw 0E0h    ; 2 bytes
sectors_count: dw 2880          ; 2 bytes   1.44 MB (2880 sectors * 512 bytes per sector)
media_discriptor_type: db 0F0h  ; 1 byte    3.5-inch single sided
; 0xF0
; 3.5-inch (90 mm) double sided, 80 tracks per side, 18 or 36 sectors per track (1440 KB, known as "1.44 MB"; or 2880 KB, known as "2.88 MB").
; Single sided (Altos MS-DOS 2.11 only)
sectors_per_fat: dw 9            ; 2 bytes
sectors_per_track: dw 63         ; 2 bytes
heads_count: dw 1                ; 2 bytes
hidden_sect_count: dd 0          ; 4 bytes
large_sect_count: dd 0           ; 4 bytes

;;;;;;;;; Extended Boot Record ;;;;;;;;;;
drive_num: db 0                  ; 1 byte
flags_win_nt: db 0               ; 1 byte
ebr_signature: db 29h            ; 1 byte
volume_id: db 0x21, 0x27, 0x79, 0x91 ; 4 bytes
volume_label: db "NOP NOP  OS"   ; 11 bytes
sys_id_string: db "FAT12   "     ; 8 bytes


main:
    ; data segments
    xor ax,ax
    mov ds,ax
    mov es,ax

    ; stack segment and sp(stack pointer)
    mov ss,ax
    mov sp,0x7c00

    mov [drive_num], dl
    push es
    mov ah, 08h
    int 13h
    ; jc stop_boot
    pop es

    and cl, 0x3F                    ; mask off upper 2 bits
    xor ch, ch
    mov [sectors_per_track], cx     
    inc dh                          ; DH = number of heads (0 based)
    mov [heads_count], dh      


;;;;;;;;;;;;;;;;;;;; Reading root dir ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LBA = reserved sector + (sectors_per_fat * fat_count)
    xor ax,ax
    mov ax,word [sectors_per_fat]
    mov bl,byte [fat_count]
    xor bh,bh
    mul bx
    add ax,word [reserved_sectors]
    push ax

; RootDirSize= ( dir_entry_count * 32 )/bps ;
    xor cx,cx
    xor dx,dx
    mov ax,0x0020
    mul word [root_dir_entry_count] ; AX*dir_entry_count = DX:AX
                               ; AX = 32*dir_entry_count
    div word [bps]             ; AX = (32*dir_entry_count) / bps
    cmp dx,0
    je .remainder_zero
    inc ax
.remainder_zero:
    mov cl,al ; sectors to read 
    pop ax       ; lba = 19

    xor dx,dx
    mov dx,ax
    add dx,cx    
    mov word [Data_region_begin],dx        ; save it for later use
    xor dx,dx

    mov dl,byte [drive_num]
    mov bx,0x7e00
    call disk_read_chs

;;;;;;;;;;;; search file ;;;;;;;;;;;;;
    mov cx,word [root_dir_entry_count]
    mov di,0x7e00
    .find:
        push cx
        mov cx,11
        mov si,filename
        push di
    rep cmpsb
        pop di
        je load_file
        pop cx
        add di,32
        loop .find
        jmp stop_boot

load_file:
;;;;;;;;; read fat ;;;;;;;;;;;

    ; byte 26-27 --> LowFirstCluster
    ; byte 28-32 --> File_size
    mov dx,[di + 0x1A]
    mov word [cluster],dx

    mov ax,word [reserved_sectors]
    mov cl,[sectors_per_fat]
    mov bx,0x7e00
    mov dl,byte [drive_num]
    call disk_read_chs
    xor ax,ax
    

    ; set segment and offset
    mov bx,0x50           ; Segment: 0x50
    mov es,bx
    xor bx,bx               ; offset: 0
    push bx

.load_stage2:
    pop bx                  ; buffer

    ; lba = Data_region_begin + (current cluster - 2 )*sectors_per_cluster
    mov ax,word [cluster]
    sub ax,2
    mul byte [sectors_per_cluster]
    add ax,word [Data_region_begin]     ; ax = lba

    xor cx,cx
    mov cl,byte [sectors_per_cluster]
    mov dl,[drive_num]
    call disk_read_chs

    xor ax,ax
    mov ax,[sectors_per_cluster]
    mul word [bps]
    add bx,ax
    push bx

;;;;; process next cluster ;;;;
    xor ax,ax
    mov ax,word [cluster]    ; ax = index
    mov dx,ax                 
    mov cx,3
    mul cx
    shr ax, 0x0001
    mov bx, 0x7e00            ; fat location
    add bx, ax                  ; index the fat
    mov ax,word [bx]
    test dx, 0x0001
    jnz .odd

;;;;;;;;; each cluster is 12 bits ;;;;;;;
    .even:
        and ax,0xfff
        jmp .Eof

    .odd:
        shr  ax,0x4

    .Eof:
        mov word [cluster],ax
        cmp ax,0xFF8
        jb .load_stage2

    mov dl,[drive_num]
    mov ax,0x50
    mov ds,ax
    mov es,ax
    jmp 0x50:0x0
    jmp halt


stop_boot:
    mov si,read_disk_failure
    call print
    mov si,press_any_key
    call print
    mov ah,0
    int 0x16        ; press key
    jmp 0xffff:0    ; jump to bios beginning to reboot

halt:
    cli         ; clear interrupt flag
    hlt


;;;;;;;;;; LBA to CHS ;;;;;;;;;;
; ax: LBA address
; return:
; cx: 6 bits for sector [0-5]
; cx: 10 bits for cylinder [6-15]
; dh: 8 bits for head

lba_to_chs:
    push ax
    push dx
    
    xor dx,dx
    div word [sectors_per_track]  ; LBA / (Sectors per Track)    quotient=AX and remainder=DX
                                 ; AX = LBA/sectors per Track
                                 ; DX = LBA % sectors per track

    inc dx                       ; DX = (LBA % sectors per track) + 1 = Sectors
    mov cx,dx

    xor dx,dx
    div word [heads_count]        ; AX = (LBA/sectors per Track) / heads  = Cylinder
                                 ; DX = (LBA/sectors per Track) % heads  = Head

    mov dh,dl                    ; dh = head
                                 ; CX =       ___CH___ ___CL___
                                 ; cylinder = 76543210 98
                                 ; sector   =            543210
    mov ch,al
    shl ah,6
    or cl,ah                     ; upper 2 bytes of cylinder in cl

    pop ax
    mov dl,al                    ; restore lower bytes of DX
    pop ax
    ret


;;;;;;;;;;;;;;;;;; Reading sectors with a CHS address ;;;;;;;;;;;;;;;;;;
;
; AX =  LBA address
; CL = Sector | ((cylinder >> 2) & 0xC0)  (upto 128)
; DL = drive number
; ES:BX = buffer:
;
; return:
;       AH = status  (see INT 13,STATUS)
;       AL = number of sectors read
;       CF = 0 if successful
;          = 1 if error

disk_read_chs:
    pusha

    push cx                       ; number of sectors to read
    call lba_to_chs               ; if AX=LBA=1 then 
                                  ; CL = sector number = (lba % sectors per track) + 1 = (1 % 63)+1 = 2 
                                  ; CH = cylinder = {( LBA / sectors per track ) / head count } = (1/63) / 1 = 0
                                  ; DH = head = {( LBA / sectors per track ) % head count } = (0/63) / 1 = 0
                                  ; CHS = 0,0,2

    pop ax                        ; Al = number of sectors to read

    mov ah, 0x2
    ;  - BIOS disk reads should be retried at least three times and the
	;    controller should be call reset: upon error detection

    mov di,3 ; retry 3 times
    .retry:
        pusha               
        stc             ; CF cleared = success 
        int 0x13        

        jnc .success
        popa 
        call reset
        
        dec di 
        test di,di
        jnz .retry
        jmp stop_boot

    .success:
        popa
        popa
        ret

;   parameters:
;       dl= drive number
reset:
    pusha
    mov si,reseting
    call print

    mov ah,0
    stc
    int 13h
    jc stop_boot
    popa
    ret

print:
    push si
    push ax

    .label:
        lodsb ; load a byte in al from memory location pointed by ds:si
        or al,al
        jz .done 

        mov ah,0x0e
        int 0x10
        jmp .label
    
    .done:
    pop ax
    pop si
    ret


read_disk_failure: db "Read Dsk Fail",0xd,0xa,0
press_any_key: db "Any key to Reboot",0xd,0xa,0
reseting: db "Dsk Reset",0xd,0xa,0
filename: db "STAGE2  BIN"
Data_region_begin: dw 0
cluster: dw 0

times 510-($-$$) db 0
dw 0xAA55