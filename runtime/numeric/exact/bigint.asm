; IA-ASSISTIDA-LLM-TOOLS-E-GERACAO-SEGURA-F01 bounded base-2^32 caller-owned BigInt core.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/numeric/exact/bigint.inc"

section .text

; rdi=object, rsi=capacity limbs, rdx=signed i64
NEBOC_ABI_FUNCTION nebo_bigint_from_i64
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .limit
    cmp rsi, NEBO_BIGINT_MAX_LIMBS
    ja .limit
    mov [rdi + NEBO_BIGINT_CAP], esi
    mov qword [rdi + NEBO_BIGINT_LIMBS], 0
    mov rax, rdx
    test rdx, rdx
    jz .zero
    mov dword [rdi + NEBO_BIGINT_SIGN], 1
    jns .magnitude
    mov dword [rdi + NEBO_BIGINT_SIGN], -1
    neg rax
.magnitude:
    mov [rdi + NEBO_BIGINT_LIMBS], eax
    shr rax, 32
    jz .one
    cmp rsi, 2
    jb .limit_reset
    mov [rdi + NEBO_BIGINT_LIMBS + 4], eax
    mov dword [rdi + NEBO_BIGINT_LEN], 2
    xor eax, eax
    ret
.one:
    mov dword [rdi + NEBO_BIGINT_LEN], 1
    xor eax, eax
    ret
.zero:
    mov dword [rdi + NEBO_BIGINT_SIGN], 0
    mov dword [rdi + NEBO_BIGINT_LEN], 0
    xor eax, eax
    ret
.limit_reset:
    mov dword [rdi + NEBO_BIGINT_SIGN], 0
    mov dword [rdi + NEBO_BIGINT_LEN], 0
.limit:
    mov eax, NEBO_BIGINT_LIMIT
    ret
.invalid:
    mov eax, NEBO_BIGINT_INVALID
    ret

; rdi=out, rsi=out capacity, rdx=a, rcx=b. Magnitudes only.
NEBOC_ABI_FUNCTION nebo_bigint_add_abs
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    test rsi, rsi
    jz .limit
    cmp rsi, NEBO_BIGINT_MAX_LIMBS
    ja .limit
    mov eax, [rdx + NEBO_BIGINT_LEN]
    mov r8d, [rcx + NEBO_BIGINT_LEN]
    cmp eax, r8d
    cmovb eax, r8d
    mov r9d, eax
    cmp r9, rsi
    ja .limit
    xor r10d, r10d
    xor r11d, r11d
.add_loop:
    cmp r10d, r9d
    jae .add_done
    xor eax, eax
    cmp r10d, [rdx + NEBO_BIGINT_LEN]
    jae .a_zero
    mov eax, [rdx + NEBO_BIGINT_LIMBS + r10*4]
.a_zero:
    xor r8d, r8d
    cmp r10d, [rcx + NEBO_BIGINT_LEN]
    jae .b_zero
    mov r8d, [rcx + NEBO_BIGINT_LIMBS + r10*4]
.b_zero:
    add rax, r8
    add rax, r11
    mov [rdi + NEBO_BIGINT_LIMBS + r10*4], eax
    shr rax, 32
    mov r11d, eax
    inc r10d
    jmp .add_loop
.add_done:
    test r11d, r11d
    jz .store_add
    cmp r10, rsi
    jae .limit
    mov [rdi + NEBO_BIGINT_LIMBS + r10*4], r11d
    inc r10d
.store_add:
    mov [rdi + NEBO_BIGINT_CAP], esi
    mov [rdi + NEBO_BIGINT_LEN], r10d
    xor eax, eax
    test r10d, r10d
    setnz al
    movzx eax, al
    mov [rdi + NEBO_BIGINT_SIGN], eax
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_BIGINT_INVALID
    ret
.limit:
    mov eax, NEBO_BIGINT_LIMIT
    ret

; rdi=out, rsi=out capacity, rdx=a, ecx=small multiplier.
NEBOC_ABI_FUNCTION nebo_bigint_mul_u32
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .limit
    cmp rsi, NEBO_BIGINT_MAX_LIMBS
    ja .limit
    mov r8d, [rdx + NEBO_BIGINT_LEN]
    cmp r8, rsi
    ja .limit
    test ecx, ecx
    jz .zero
    xor r9d, r9d
    xor r10d, r10d
.mul_loop:
    cmp r9d, r8d
    jae .mul_done
    mov eax, [rdx + NEBO_BIGINT_LIMBS + r9*4]
    imul rax, rcx
    add rax, r10
    mov [rdi + NEBO_BIGINT_LIMBS + r9*4], eax
    shr rax, 32
    mov r10, rax
    inc r9d
    jmp .mul_loop
.mul_done:
    test r10, r10
    jz .store_mul
    cmp r9, rsi
    jae .limit
    mov [rdi + NEBO_BIGINT_LIMBS + r9*4], r10d
    inc r9d
.store_mul:
    mov [rdi + NEBO_BIGINT_CAP], esi
    mov [rdi + NEBO_BIGINT_LEN], r9d
    mov eax, [rdx + NEBO_BIGINT_SIGN]
    mov [rdi + NEBO_BIGINT_SIGN], eax
    xor eax, eax
    ret
.zero:
    mov [rdi + NEBO_BIGINT_CAP], esi
    mov dword [rdi + NEBO_BIGINT_SIGN], 0
    mov dword [rdi + NEBO_BIGINT_LEN], 0
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_BIGINT_INVALID
    ret
.limit:
    mov eax, NEBO_BIGINT_LIMIT
    ret

; rdi=quotient, rsi=capacity, rdx=a, ecx=divisor, r8=remainder u32.
NEBOC_ABI_FUNCTION nebo_bigint_divmod_u32
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test r8, r8
    jz .invalid
    test ecx, ecx
    jz .div_zero
    mov r10, rdx
    mov r11d, ecx
    mov r9d, [r10 + NEBO_BIGINT_LEN]
    cmp r9, rsi
    ja .limit
    xor edx, edx
.div_loop:
    test r9d, r9d
    jz .div_done
    dec r9d
    mov eax, [r10 + NEBO_BIGINT_LIMBS + r9*4]
    div r11d
    mov [rdi + NEBO_BIGINT_LIMBS + r9*4], eax
    jmp .div_loop
.div_done:
    mov [r8], edx
    mov eax, [r10 + NEBO_BIGINT_LEN]
.normalize:
    test eax, eax
    jz .store_div
    cmp dword [rdi + NEBO_BIGINT_LIMBS + rax*4 - 4], 0
    jne .store_div
    dec eax
    jmp .normalize
.store_div:
    mov [rdi + NEBO_BIGINT_CAP], esi
    mov [rdi + NEBO_BIGINT_LEN], eax
    xor ecx, ecx
    test eax, eax
    jz .sign_done
    mov ecx, [r10 + NEBO_BIGINT_SIGN]
.sign_done:
    mov [rdi + NEBO_BIGINT_SIGN], ecx
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_BIGINT_INVALID
    ret
.limit:
    mov eax, NEBO_BIGINT_LIMIT
    ret
.div_zero:
    mov eax, NEBO_BIGINT_DIV_ZERO
    ret

; rdi=a, rsi=out bit length.
NEBOC_ABI_FUNCTION nebo_bigint_bit_length
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov eax, [rdi + NEBO_BIGINT_LEN]
    test eax, eax
    jz .zero
    dec eax
    mov edx, [rdi + NEBO_BIGINT_LIMBS + rax*4]
    test edx, edx
    jz .invalid
    bsr edx, edx
    imul eax, eax, 32
    lea eax, [rax + rdx + 1]
    mov [rsi], eax
    xor eax, eax
    ret
.zero:
    mov dword [rsi], 0
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_BIGINT_INVALID
    ret

; rdi=a, rsi=b, returns gcd in rax (u64 reference subset).
NEBOC_ABI_FUNCTION nebo_bigint_gcd_u64
    mov rax, rdi
    mov rcx, rsi
.gcd_loop:
    test rcx, rcx
    jz .gcd_done
    xor edx, edx
    div rcx
    mov rax, rcx
    mov rcx, rdx
    jmp .gcd_loop
.gcd_done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
