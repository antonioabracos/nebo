; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE deterministic sRGB8 accessibility policy
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_accessibility.inc"
global nebo_color_luma8
global nebo_color_contrast_check
global nebo_color_pick_accessible
section .text
; edi=0xRRGGBBAA. Returns integer luma [0,255] using 299/587/114.
nebo_color_luma8:
    mov eax, edi
    shr eax, 24
    imul eax, eax, 299
    mov ecx, edi
    shr ecx, 16
    and ecx, 255
    imul ecx, ecx, 587
    add eax, ecx
    mov ecx, edi
    shr ecx, 8
    and ecx, 255
    imul ecx, ecx, 114
    add eax, ecx
    xor edx, edx
    mov ecx, 1000
    div ecx
    ret
; edi=foreground, esi=background, edx=minimum luma delta.
nebo_color_contrast_check:
    cmp edx, NEBO_CONTRAST_MAX_DELTA
    ja .invalid
    push rbx
    push r12
    push r13
    mov ebx, esi
    mov r12d, edx
    call nebo_color_luma8
    mov r8d, eax
    mov edi, ebx
    call nebo_color_luma8
    sub r8d, eax
    jns .absolute
    neg r8d
.absolute:
    cmp r8d, r12d
    jb .insufficient_saved
    xor eax, eax
    jmp .done
.insufficient_saved:
    mov eax, NEBO_CONTRAST_INSUFFICIENT
.done:
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
; edi=preferred, esi=fallback, edx=background, ecx=min delta, r8=out Color.
nebo_color_pick_accessible:
    test r8, r8
    jz .pick_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov ebx, edi
    mov r12d, esi
    mov r13d, edx
    mov r14d, ecx
    mov r15, r8
    mov esi, r13d
    mov edx, r14d
    call nebo_color_contrast_check
    test eax, eax
    jz .preferred
    cmp eax, NEBO_CONTRAST_INSUFFICIENT
    jne .pick_done
    mov edi, r12d
    mov esi, r13d
    mov edx, r14d
    call nebo_color_contrast_check
    test eax, eax
    jnz .no_fallback
    mov [r15], r12d
    xor eax, eax
    jmp .pick_done
.preferred:
    mov [r15], ebx
    jmp .pick_done
.no_fallback:
    mov eax, NEBO_CONTRAST_NO_FALLBACK
.pick_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.pick_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
