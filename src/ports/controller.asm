input:
    ; 0x60	Read/Write	Data Port
    ; 0x64	Read	Status Register
    ; 0x64	Write	Command Register

    in al,0x64              ; al = status register value
    and al,00000010b        ; Input buffer status (0 = empty, 1 = full)\
    jz input                ; if status register second bit is 0 then their is no data in buffer
    in al,0x60