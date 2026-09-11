; G087 public-source runtime proof. Every mode reaches canonical Color owners
; and returns the source-derived seed only after checking observed values.
bits 64
default rel
%define NEBO_G087_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/color_source_probe.inc"
%include "runtime/color.inc"
%include "runtime/color_target.inc"

extern nebo_color_copy
extern nebo_color_rgb_lowering
extern nebo_color_rgba_lowering
extern nebo_color_hex_literal
extern nebo_color_parse_hex
extern nebo_color_channels
extern nebo_color_red
extern nebo_color_green
extern nebo_color_blue
extern nebo_color_alpha
extern nebo_color_with_alpha
extern nebo_color_is_opaque
extern nebo_color_equal
extern nebo_color_hash
extern nebo_color_to_hex
extern nebo_color_to_hex_with_alpha
extern nebo_color_target_validate
extern nebo_color_target_map

global nebo_g087_source_probe
global nebo_g087_negative_probe

section .rodata
g87_invalid_hex: db "#12G456"
g87_invalid_hex_len equ $-g87_invalid_hex

section .bss align=16
g87_color_a: resd 1
g87_color_b: resd 1
g87_color_c: resd 1
g87_channels: resd 1
g87_result: resb NEBO_COLOR_RESULT_SIZE
g87_text: resb NEBO_COLOR_HEX_RGBA_LENGTH
g87_target: resb NEBO_COLOR_TARGET_SIZE

section .text
; EDI=mode 1..10, ESI=non-zero source seed -> EAX=seed on success.
nebo_g087_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    cmp ebx, 255
    ja .failure
    cmp r12d, 1
    je .mode_1
    cmp r12d, 2
    je .mode_2
    cmp r12d, 3
    je .mode_3
    cmp r12d, 4
    je .mode_4
    cmp r12d, 5
    je .mode_5
    cmp r12d, 6
    je .mode_6
    cmp r12d, 7
    je .mode_7
    cmp r12d, 8
    je .mode_8
    cmp r12d, 9
    je .mode_9
    cmp r12d, 10
    je .mode_10
    jmp .failure

.mode_1:
    mov edi, ebx
    mov esi, 34
    mov edx, 51
    lea rcx, [rel g87_color_a]
    call nebo_color_rgb_lowering
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_color_b]
    call nebo_color_copy
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_b]
    call nebo_color_red
    cmp eax, ebx
    jne .failure
    mov edi, [rel g87_color_b]
    call nebo_color_is_opaque
    cmp eax, 1
    jne .failure
    jmp .success

.mode_2:
    mov edi, ebx
    mov esi, 2
    mov edx, 3
    lea rcx, [rel g87_color_a]
    call nebo_color_rgb_lowering
    test eax, eax
    jnz .failure
    cmp byte [rel g87_color_a], 0xff
    jne .failure
    mov edi, ebx
    mov esi, 5
    mov edx, 6
    mov ecx, 7
    lea r8, [rel g87_color_b]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_b]
    call nebo_color_alpha
    cmp eax, 7
    jne .failure
    jmp .success

.mode_3:
    call g87_make_roundtrip_text
    test eax, eax
    jnz .failure
    lea rdi, [rel g87_text]
    mov esi, NEBO_COLOR_HEX_RGBA_LENGTH
    lea rdx, [rel g87_color_b]
    call nebo_color_hex_literal
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    mov esi, [rel g87_color_b]
    call nebo_color_equal
    cmp eax, 1
    jne .failure
    jmp .success

.mode_4:
    call g87_make_roundtrip_text
    test eax, eax
    jnz .failure
    lea rdi, [rel g87_text]
    mov esi, NEBO_COLOR_HEX_RGBA_LENGTH
    lea rdx, [rel g87_result]
    call nebo_color_parse_hex
    test eax, eax
    jnz .failure
    cmp qword [rel g87_result + NEBO_COLOR_RESULT_IS_OK_OFFSET], 1
    jne .failure
    mov edi, [rel g87_color_a]
    mov esi, [rel g87_result + NEBO_COLOR_RESULT_VALUE_OFFSET]
    call nebo_color_equal
    cmp eax, 1
    jne .failure
    lea rdi, [rel g87_invalid_hex]
    mov esi, g87_invalid_hex_len
    lea rdx, [rel g87_result]
    call nebo_color_parse_hex
    test eax, eax
    jnz .failure
    cmp qword [rel g87_result + NEBO_COLOR_RESULT_IS_OK_OFFSET], 0
    jne .failure
    cmp qword [rel g87_result + NEBO_COLOR_RESULT_ERROR_INDEX_OFFSET], 3
    jne .failure
    jmp .success

.mode_5:
    mov edi, ebx
    mov esi, 11
    mov edx, 22
    lea rcx, [rel g87_color_a]
    call nebo_color_rgb_lowering
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_text]
    mov edx, NEBO_COLOR_HEX_RGB_LENGTH
    call nebo_color_to_hex
    test eax, eax
    jnz .failure
    cmp rdx, NEBO_COLOR_HEX_RGB_LENGTH
    jne .failure
    jmp .success

.mode_6:
    mov edi, ebx
    mov esi, 65
    mov edx, 129
    mov ecx, 193
    lea r8, [rel g87_color_a]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_channels]
    call nebo_color_channels
    test eax, eax
    jnz .failure
    movzx eax, byte [rel g87_channels]
    cmp eax, ebx
    jne .failure
    mov edi, [rel g87_color_a]
    call nebo_color_green
    cmp eax, 65
    jne .failure
    mov edi, [rel g87_color_a]
    call nebo_color_blue
    cmp eax, 129
    jne .failure
    mov edi, [rel g87_color_a]
    call nebo_color_alpha
    cmp eax, 193
    jne .failure
    mov edi, [rel g87_color_a]
    call nebo_color_hash
    mov r12, rax
    mov edi, [rel g87_color_a]
    call nebo_color_hash
    cmp rax, r12
    jne .failure
    jmp .success

.mode_7:
    mov edi, 0x112233ff
    mov esi, ebx
    lea rdx, [rel g87_color_a]
    call nebo_color_with_alpha
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    call nebo_color_alpha
    cmp eax, ebx
    jne .failure
    mov edi, [rel g87_color_a]
    call nebo_color_is_opaque
    cmp ebx, 255
    sete dl
    movzx edx, dl
    cmp eax, edx
    jne .failure
    mov edi, [rel g87_color_a]
    mov esi, NEBO_COLOR_TARGET_HEADLESS
    mov edx, NEBO_COLOR_CAP_ALPHA
    lea rcx, [rel g87_target]
    call nebo_color_target_validate
    test eax, eax
    jnz .failure
    jmp .success

.mode_8:
    call g87_make_roundtrip_text
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_text]
    mov edx, NEBO_COLOR_HEX_RGB_LENGTH
    call nebo_color_to_hex
    test eax, eax
    jnz .failure
    cmp rdx, NEBO_COLOR_HEX_RGB_LENGTH
    jne .failure
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_text]
    mov edx, NEBO_COLOR_HEX_RGBA_LENGTH
    call nebo_color_to_hex_with_alpha
    test eax, eax
    jnz .failure
    cmp rdx, NEBO_COLOR_HEX_RGBA_LENGTH
    jne .failure
    jmp .success

.mode_9:
    call g87_property_roundtrip
    test eax, eax
    jnz .failure
    jmp .success

.mode_10:
    call g87_make_roundtrip_text
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_a]
    mov esi, ebx
    lea rdx, [rel g87_color_b]
    call nebo_color_with_alpha
    test eax, eax
    jnz .failure
    mov edi, [rel g87_color_b]
    mov esi, NEBO_COLOR_TARGET_LIVE
    mov edx, NEBO_COLOR_CAP_ALPHA | NEBO_COLOR_CAP_TRUECOLOR
    lea rcx, [rel g87_target]
    call nebo_color_target_map
    test eax, eax
    jnz .failure
    cmp qword [rel g87_target + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_LIVE_RGBA
    jne .failure
    mov eax, [rel g87_color_b]
    cmp qword [rel g87_target + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], rax
    jne .failure
    jmp .success

.success:
    mov eax, ebx
    jmp .done
.failure:
    mov eax, 187
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret

; Build a seed-dependent RGBA value and canonical Text.
g87_make_roundtrip_text:
    sub rsp, 8
    mov edi, ebx
    mov esi, 0x2a
    mov edx, 0x6c
    mov ecx, 0x9e
    lea r8, [rel g87_color_a]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz .done
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_text]
    mov edx, NEBO_COLOR_HEX_RGBA_LENGTH
    call nebo_color_to_hex_with_alpha
.done:
    add rsp, 8
    ret

; Differential/property loop across seed-derived channels.
g87_property_roundtrip:
    push r13
    xor r13d, r13d
.loop:
    cmp r13d, 16
    jae .ok
    mov edi, ebx
    add edi, r13d
    and edi, 0xff
    mov esi, r13d
    imul esi, 17
    and esi, 0xff
    mov edx, r13d
    imul edx, 29
    and edx, 0xff
    mov ecx, r13d
    imul ecx, 43
    and ecx, 0xff
    lea r8, [rel g87_color_a]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz .bad
    mov edi, [rel g87_color_a]
    lea rsi, [rel g87_text]
    mov edx, NEBO_COLOR_HEX_RGBA_LENGTH
    call nebo_color_to_hex_with_alpha
    test eax, eax
    jnz .bad
    lea rdi, [rel g87_text]
    mov esi, NEBO_COLOR_HEX_RGBA_LENGTH
    lea rdx, [rel g87_result]
    call nebo_color_parse_hex
    test eax, eax
    jnz .bad
    cmp qword [rel g87_result + NEBO_COLOR_RESULT_IS_OK_OFFSET], 1
    jne .bad
    mov edi, [rel g87_color_a]
    mov esi, [rel g87_result + NEBO_COLOR_RESULT_VALUE_OFFSET]
    call nebo_color_equal
    cmp eax, 1
    jne .bad
    inc r13d
    jmp .loop
.ok:
    xor eax, eax
    jmp .property_done
.bad:
    mov eax, 1
.property_done:
    pop r13
    ret

; Direct invalid/boundary checks used by the native group runner.
nebo_g087_negative_probe:
    mov edi, 256
    xor esi, esi
    xor edx, edx
    lea rcx, [rel g87_color_a]
    mov dword [rel g87_color_a], 0xaaaaaaaa
    call nebo_color_rgb_lowering
    cmp eax, NEBO_COLOR_CHANNEL_RANGE
    jne .negative_fail
    cmp dword [rel g87_color_a], 0xaaaaaaaa
    jne .negative_fail
    mov edi, 0x11223344
    mov esi, 256
    lea rdx, [rel g87_color_a]
    call nebo_color_with_alpha
    cmp eax, NEBO_COLOR_CHANNEL_RANGE
    jne .negative_fail
    lea rdi, [rel g87_invalid_hex]
    mov esi, g87_invalid_hex_len
    lea rdx, [rel g87_result]
    call nebo_color_parse_hex
    test eax, eax
    jnz .negative_fail
    cmp qword [rel g87_result + NEBO_COLOR_RESULT_IS_OK_OFFSET], 0
    jne .negative_fail
    xor eax, eax
    ret
.negative_fail:
    mov eax, 1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
