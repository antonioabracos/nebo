; Nebo Assembly — TIPO-PUBLICO-COLOR-CONSTRUCTORS-PARSING-E-ABI target-factual Color alpha validation
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_target.inc"
global nebo_color_target_validate
global nebo_color_target_map
section .text
; edi=Color, rsi=target, rdx=capability mask, rcx=out target descriptor.
nebo_color_target_validate:
    test rcx, rcx
    jz .invalid
    cmp rsi, NEBO_COLOR_TARGET_HEADLESS
    je .target_ok
    cmp rsi, NEBO_COLOR_TARGET_ANSI
    je .target_ok
    cmp rsi, NEBO_COLOR_TARGET_LIVE
    jne .invalid
.target_ok:
    mov eax, edi
    and eax, 0xff
    cmp eax, NEBO_COLOR_OPAQUE_ALPHA
    je .commit
    cmp rsi, NEBO_COLOR_TARGET_ANSI
    je .alpha_unsupported
    test rdx, NEBO_COLOR_CAP_ALPHA
    jz .alpha_unsupported
.commit:
    mov [rcx + NEBO_COLOR_TARGET_COLOR_OFFSET], edi
    mov [rcx + NEBO_COLOR_TARGET_KIND_OFFSET], rsi
    mov [rcx + NEBO_COLOR_TARGET_CAPABILITIES_OFFSET], rdx
    mov qword [rcx + NEBO_COLOR_TARGET_STATE_OFFSET], NEBO_COLOR_TARGET_VALID
    xor eax, eax
    ret
.alpha_unsupported:
    mov eax, NEBO_COLOR_ALPHA_UNSUPPORTED
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
; edi=Color, rsi=target, rdx=capability mask, rcx=out mapping descriptor.
nebo_color_target_map:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov ebx, edi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    call nebo_color_target_validate
    test eax, eax
    jnz .map_done
    cmp r12, NEBO_COLOR_TARGET_HEADLESS
    je .headless
    cmp r12, NEBO_COLOR_TARGET_LIVE
    je .live
    test r13, NEBO_COLOR_CAP_TRUECOLOR
    jz .ansi256
    mov qword [r14 + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_ANSI_TRUECOLOR
    mov eax, ebx
    shr eax, 8
    mov [r14 + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], rax
    xor eax, eax
    jmp .map_done
.ansi256:
    mov eax, ebx
    shr eax, 24
    imul eax, eax, 5
    add eax, 127
    xor edx, edx
    mov ecx, 255
    div ecx
    imul r15d, eax, 36
    mov eax, ebx
    shr eax, 16
    and eax, 255
    imul eax, eax, 5
    add eax, 127
    xor edx, edx
    div ecx
    imul eax, eax, 6
    add r15d, eax
    mov eax, ebx
    shr eax, 8
    and eax, 255
    imul eax, eax, 5
    add eax, 127
    xor edx, edx
    div ecx
    add eax, r15d
    add eax, 16
    mov qword [r14 + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_ANSI256
    mov [r14 + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], rax
    xor eax, eax
    jmp .map_done
.headless:
    mov qword [r14 + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_HEADLESS_RGBA
    jmp .rgba
.live:
    mov qword [r14 + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_LIVE_RGBA
.rgba:
    mov [r14 + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], rbx
    xor eax, eax
.map_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
