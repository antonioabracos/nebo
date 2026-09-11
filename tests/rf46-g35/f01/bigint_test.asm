bits 64
default rel
%include "runtime/numeric/exact/bigint.inc"
extern nebo_bigint_from_i64
extern nebo_bigint_add_abs
extern nebo_bigint_mul_u32
extern nebo_bigint_divmod_u32
extern nebo_bigint_bit_length
extern nebo_bigint_gcd_u64

section .bss
a resb 48
b resb 48
c resb 48
d resb 48
remainder resd 1
bits_out resd 1

section .text
global _start
_start:
    lea rdi, [a]
    mov esi, 8
    mov rdx, 0x1ffffffff
    call nebo_bigint_from_i64
    test eax, eax
    jnz fail
    lea rdi, [b]
    mov esi, 8
    mov edx, 2
    call nebo_bigint_from_i64
    test eax, eax
    jnz fail
    lea rdi, [c]
    mov esi, 8
    lea rdx, [a]
    lea rcx, [b]
    call nebo_bigint_add_abs
    test eax, eax
    jnz fail
    cmp dword [c + NEBO_BIGINT_LEN], 2
    jne fail
    cmp dword [c + NEBO_BIGINT_LIMBS], 1
    jne fail
    cmp dword [c + NEBO_BIGINT_LIMBS + 4], 2
    jne fail
    lea rdi, [d]
    mov esi, 8
    lea rdx, [c]
    mov ecx, 3
    call nebo_bigint_mul_u32
    test eax, eax
    jnz fail
    cmp dword [d + NEBO_BIGINT_LIMBS], 3
    jne fail
    cmp dword [d + NEBO_BIGINT_LIMBS + 4], 6
    jne fail
    lea rdi, [c]
    mov esi, 8
    lea rdx, [d]
    mov ecx, 5
    lea r8, [remainder]
    call nebo_bigint_divmod_u32
    test eax, eax
    jnz fail
    cmp dword [remainder], 4
    jne fail
    cmp dword [c + NEBO_BIGINT_LIMBS], 0x33333333
    jne fail
    cmp dword [c + NEBO_BIGINT_LIMBS + 4], 1
    jne fail
    lea rdi, [c]
    lea rsi, [bits_out]
    call nebo_bigint_bit_length
    test eax, eax
    jnz fail
    cmp dword [bits_out], 33
    jne fail
    mov edi, 84
    mov esi, 30
    call nebo_bigint_gcd_u64
    cmp rax, 6
    jne fail
    ; Division by zero must not alter the sentinel output.
    mov dword [b + NEBO_BIGINT_LIMBS], 0xdecafbad
    lea rdi, [b]
    mov esi, 8
    lea rdx, [d]
    xor ecx, ecx
    lea r8, [remainder]
    call nebo_bigint_divmod_u32
    cmp eax, NEBO_BIGINT_DIV_ZERO
    jne fail
    cmp dword [b + NEBO_BIGINT_LIMBS], 0xdecafbad
    jne fail
    xor edi, edi
    jmp exit
fail:
    mov edi, 1
exit:
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
