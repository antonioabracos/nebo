; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE normalized ColorMap/colorBy descriptor
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/colormap.inc"
global nebo_colormap_normalize
section .text
; rdi=immutable stops, rsi=count, rdx=colorBy kind, rcx=out descriptor.
nebo_colormap_normalize:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rsi, 2
    jb .invalid
    cmp rsi, NEBO_COLORMAP_MAX_STOPS
    ja .capacity
    cmp rdx, NEBO_COLOR_BY_INDEX
    jb .invalid
    cmp rdx, NEBO_COLOR_BY_MAX
    ja .invalid
    mov r8d, [rdi + NEBO_COLORMAP_STOP_POSITION_OFFSET]
    xor r9d, r9d
    inc r9
.validate:
    cmp r9, rsi
    jae .commit
    mov r10d, [rdi + r9 * NEBO_COLORMAP_STOP_SIZE + NEBO_COLORMAP_STOP_POSITION_OFFSET]
    cmp r10d, NEBO_COLORMAP_POSITION_MAX
    ja .invalid
    cmp r10d, r8d
    jbe .order
    mov r8d, r10d
    inc r9
    jmp .validate
.commit:
    mov [rcx + NEBO_COLORMAP_DESC_STOPS_OFFSET], rdi
    mov [rcx + NEBO_COLORMAP_DESC_COUNT_OFFSET], rsi
    mov [rcx + NEBO_COLORMAP_DESC_COLOR_BY_OFFSET], rdx
    mov qword [rcx + NEBO_COLORMAP_DESC_STATE_OFFSET], NEBO_COLORMAP_READY
    xor eax, eax
    ret
.order:
    mov eax, NEBO_COLORMAP_ORDER
    ret
.capacity:
    mov eax, NEBO_COLOR_CAPACITY
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
