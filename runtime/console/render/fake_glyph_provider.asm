; Nebo deterministic headless FakeGlyphProvider — MF044
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/render/fake_glyph_provider.inc"

extern nebo_console_basic_validate_utf8

global nebo_fake_glyph_provider_init
global nebo_fake_glyph_provider_validate
global nebo_fake_glyph_provider_measure_utf8
global nebo_fake_glyph_utf8_next
global nebo_fake_glyph_provider_state_hash

section .text

; provider_init(provider*) -> status
nebo_fake_glyph_provider_init:
    test rdi, rdi
    jz .init_invalid
    mov qword [rdi+NEBO_FAKE_GLYPH_ADVANCE_OFFSET], NEBO_LAYOUT_GLYPH_ADVANCE
    mov qword [rdi+NEBO_FAKE_GLYPH_WIDTH_OFFSET], NEBO_LAYOUT_GLYPH_WIDTH
    mov qword [rdi+NEBO_FAKE_GLYPH_HEIGHT_OFFSET], NEBO_LAYOUT_GLYPH_HEIGHT
    mov qword [rdi+NEBO_FAKE_GLYPH_BASELINE_OFFSET], NEBO_LAYOUT_BASELINE
    mov qword [rdi+NEBO_FAKE_GLYPH_LINE_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    mov qword [rdi+NEBO_FAKE_GLYPH_COVERAGE_FLAGS_OFFSET], NEBO_FAKE_GLYPH_REQUIRED_COVERAGE
    mov qword [rdi+NEBO_FAKE_GLYPH_REPLACEMENT_CODEPOINT_OFFSET], NEBO_FAKE_GLYPH_REPLACEMENT_CODEPOINT
    mov qword [rdi+NEBO_FAKE_GLYPH_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; provider_validate(provider*) -> status
nebo_fake_glyph_provider_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_FAKE_GLYPH_ADVANCE_OFFSET], NEBO_LAYOUT_GLYPH_ADVANCE
    jne .validate_state
    cmp qword [rdi+NEBO_FAKE_GLYPH_WIDTH_OFFSET], NEBO_LAYOUT_GLYPH_WIDTH
    jne .validate_state
    cmp qword [rdi+NEBO_FAKE_GLYPH_HEIGHT_OFFSET], NEBO_LAYOUT_GLYPH_HEIGHT
    jne .validate_state
    cmp qword [rdi+NEBO_FAKE_GLYPH_BASELINE_OFFSET], NEBO_LAYOUT_BASELINE
    jne .validate_state
    cmp qword [rdi+NEBO_FAKE_GLYPH_LINE_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    jne .validate_state
    mov rax, [rdi+NEBO_FAKE_GLYPH_COVERAGE_FLAGS_OFFSET]
    and eax, NEBO_FAKE_GLYPH_REQUIRED_COVERAGE
    cmp eax, NEBO_FAKE_GLYPH_REQUIRED_COVERAGE
    jne .validate_state
    cmp qword [rdi+NEBO_FAKE_GLYPH_REPLACEMENT_CODEPOINT_OFFSET], NEBO_FAKE_GLYPH_REPLACEMENT_CODEPOINT
    jne .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; utf8_next(data*, remaining, out_codepoint*, out_bytes*) -> status
; Strict decoder for one scalar. Surrogates and overlong forms are rejected.
nebo_fake_glyph_utf8_next:
    test rdi, rdi
    jz .next_invalid
    test rsi, rsi
    jz .next_invalid
    test rdx, rdx
    jz .next_invalid
    test rcx, rcx
    jz .next_invalid
    mov qword [rdx], 0
    mov qword [rcx], 0
    movzx eax, byte [rdi]
    cmp eax, 0x80
    jb .next_ascii
    cmp eax, 0xC2
    jb .next_utf8_error
    cmp eax, 0xDF
    jbe .next_two
    cmp eax, 0xEF
    jbe .next_three
    cmp eax, 0xF4
    jbe .next_four
    jmp .next_utf8_error
.next_ascii:
    mov [rdx], rax
    mov qword [rcx], 1
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.next_two:
    cmp rsi, 2
    jb .next_utf8_error
    movzx r8d, byte [rdi+1]
    mov r9d, r8d
    and r9d, 0xC0
    cmp r9d, 0x80
    jne .next_utf8_error
    and eax, 0x1F
    shl eax, 6
    and r8d, 0x3F
    or eax, r8d
    mov [rdx], rax
    mov qword [rcx], 2
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.next_three:
    cmp rsi, 3
    jb .next_utf8_error
    movzx r8d, byte [rdi+1]
    movzx r9d, byte [rdi+2]
    mov r10d, r8d
    and r10d, 0xC0
    cmp r10d, 0x80
    jne .next_utf8_error
    mov r10d, r9d
    and r10d, 0xC0
    cmp r10d, 0x80
    jne .next_utf8_error
    cmp al, 0xE0
    jne .next_three_not_e0
    cmp r8b, 0xA0
    jb .next_utf8_error
.next_three_not_e0:
    cmp al, 0xED
    jne .next_three_not_ed
    cmp r8b, 0xA0
    jae .next_utf8_error
.next_three_not_ed:
    and eax, 0x0F
    shl eax, 12
    and r8d, 0x3F
    shl r8d, 6
    or eax, r8d
    and r9d, 0x3F
    or eax, r9d
    mov [rdx], rax
    mov qword [rcx], 3
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.next_four:
    cmp rsi, 4
    jb .next_utf8_error
    movzx r8d, byte [rdi+1]
    movzx r9d, byte [rdi+2]
    movzx r10d, byte [rdi+3]
    mov r11d, r8d
    and r11d, 0xC0
    cmp r11d, 0x80
    jne .next_utf8_error
    mov r11d, r9d
    and r11d, 0xC0
    cmp r11d, 0x80
    jne .next_utf8_error
    mov r11d, r10d
    and r11d, 0xC0
    cmp r11d, 0x80
    jne .next_utf8_error
    cmp al, 0xF0
    jne .next_four_not_f0
    cmp r8b, 0x90
    jb .next_utf8_error
.next_four_not_f0:
    cmp al, 0xF4
    jne .next_four_not_f4
    cmp r8b, 0x8F
    ja .next_utf8_error
.next_four_not_f4:
    and eax, 0x07
    shl eax, 18
    and r8d, 0x3F
    shl r8d, 12
    or eax, r8d
    and r9d, 0x3F
    shl r9d, 6
    or eax, r9d
    and r10d, 0x3F
    or eax, r10d
    cmp eax, 0x10FFFF
    ja .next_utf8_error
    mov [rdx], rax
    mov qword [rcx], 4
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.next_utf8_error:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret
.next_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; measure_utf8(provider*, data*, length, out_width*, out_glyph_count*) -> status
nebo_fake_glyph_provider_measure_utf8:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    test r15, r15
    jz .measure_invalid
    test rbx, rbx
    jz .measure_invalid
    mov qword [r15], 0
    mov qword [rbx], 0
    mov rdi, r12
    call nebo_fake_glyph_provider_validate
    test eax, eax
    jnz .measure_done
    test r14, r14
    jz .measure_empty
    test r13, r13
    jz .measure_invalid
    mov rdi, r13
    mov rsi, r14
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .measure_invalid_utf8
    mov qword [rsp+16], 0
    mov qword [rsp+24], 0
.measure_loop:
    mov rax, [rsp+16]
    cmp rax, r14
    jae .measure_counted
    lea rdi, [r13+rax]
    mov rsi, r14
    sub rsi, rax
    lea rdx, [rsp]
    lea rcx, [rsp+8]
    call nebo_fake_glyph_utf8_next
    test eax, eax
    jnz .measure_invalid_utf8
    mov rax, [rsp+8]
    add [rsp+16], rax
    inc qword [rsp+24]
    jo .measure_overflow
    jmp .measure_loop
.measure_counted:
    mov rax, [r12+NEBO_FAKE_GLYPH_ADVANCE_OFFSET]
    mul qword [rsp+24]
    test rdx, rdx
    jnz .measure_overflow
    mov [r15], rax
    mov rcx, [rsp+24]
    mov [rbx], rcx
    mov qword [r12+NEBO_FAKE_GLYPH_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .measure_done
.measure_empty:
    mov qword [r12+NEBO_FAKE_GLYPH_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .measure_done
.measure_invalid_utf8:
    mov qword [r12+NEBO_FAKE_GLYPH_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .measure_done
.measure_overflow:
    mov qword [r12+NEBO_FAKE_GLYPH_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .measure_done
.measure_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.measure_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; provider_state_hash(provider*, out_hash*) -> status
nebo_fake_glyph_provider_state_hash:
    test rdi, rdi
    jz .hash_invalid
    test rsi, rsi
    jz .hash_invalid
    mov eax, NEBO_LAYOUT_HASH_FNV1A32_OFFSET_BASIS
    xor edx, edx
.hash_field_loop:
    cmp edx, 7
    jae .hash_done
    mov r8, [rdi+rdx*8]
    mov ecx, 8
.hash_byte_loop:
    xor al, r8b
    imul rax, rax, NEBO_LAYOUT_HASH_FNV1A32_PRIME
    shr r8, 8
    dec ecx
    jnz .hash_byte_loop
    inc edx
    jmp .hash_field_loop
.hash_done:
    mov [rsi], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
