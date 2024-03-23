GDT_start:
    null_descriptor:            ; each segment descriptor is 8 bytes
        dd 0
        dd 0

    Code_SegmentDescriptor:
        dw 0xffff               ; limit (16 bits)
        dw 0                    ; base (16 bits)
        db 0                    ; base (8 bits)
        db 10011010b            ; present:1
                                ; privilage: 00 (ring 0)
                                ; Descriptor type: 1 (code/data segment)
                                ; Type: code = 1    , confirm = 0 (Lower priv may not call code in this segment)
                                ; , readable = 1    , access = 0
        db 11001111b            ; other flags and last 4 bits of limit
        db 0                    ; base (8 bits)

    Data_SegmentDescriptor:
        dw 0xffff               ; limit (16 bits)
        dw 0                    ; base (16 bits)
        db 0                    ; base (4 bits)
        db 10010010b            ; present:1
                                ; privilage: 00 (ring 0)
                                ; Descriptor type: 1 (code/data segment)
                                ; Type: code = 0    , direction = 0 (Lower priv may not call code in this segment)
                                ; , writable = 1    , access = 0
        db 11001111b            ; other flags and last 4 bits of limit
        db 0                    ; base (8 bits)
GDT_end:

GDT_Descriptor:
    dw GDT_end - GDT_start - 1  ; size
    dd GDT_start                ; base


code_seg equ Code_SegmentDescriptor - GDT_start
data_seg equ Data_SegmentDescriptor - GDT_start
