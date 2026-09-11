bits 64
default rel
%include "runtime/style_tokens.inc"
extern nebo_style_fallback_resolve
global _start
section .text
_start:
    lea rdi, [rel requested]
    lea rsi, [rel result]
    call nebo_style_fallback_resolve
    test eax, eax
    jnz fail
    test qword [rel result + NEBO_FALLBACK_APPLIED_PROFILE_OFFSET], NEBO_PROFILE_ASCII
    jz fail
    cmp qword [rel result + NEBO_FALLBACK_COLOR_ENABLED_OFFSET], 0
    jne fail
    lea rdi, [rel invalid]
    lea rsi, [rel untouched]
    call nebo_style_fallback_resolve
    cmp eax, NEBO_STYLE_INVALID
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
requested: dq NEBO_PROFILE_HIGH_CONTRAST, NEBO_STYLE_BLINK, 1, 0
    times 5 dq 0
invalid: dq 8, 0, 0, 0
    times 5 dq 0
untouched: times NEBO_FALLBACK_SIZE db 0xaa
section .bss
result: resb NEBO_FALLBACK_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
