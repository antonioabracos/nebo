; IA-ASSISTIDA-LLM-TOOLS-E-GERACAO-SEGURA-F02 exact rational and explicit rounding subset.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/numeric/exact/decimal_rational.inc"
section .text

; rdi=out {i64 numerator,u64 denominator}, rsi=numerator, rdx=denominator.
NEBOC_ABI_FUNCTION nebo_rational_normalize_i64
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov r8, rsi
    mov r9, rdx
    test r9, r9
    jns .den_positive
    neg r9
    jo .overflow
    neg r8
    jo .overflow
.den_positive:
    test r8, r8
    jz .zero
    mov rax, r8
    test rax, rax
    jns .abs_ready
    neg rax
    jo .overflow
.abs_ready:
    mov rcx, r9
.gcd:
    test rcx, rcx
    jz .reduce
    xor edx, edx
    div rcx
    mov rax, rcx
    mov rcx, rdx
    jmp .gcd
.reduce:
    mov rcx, rax
    mov rax, r8
    cqo
    idiv rcx
    mov [rdi], rax
    mov rax, r9
    xor edx, edx
    div rcx
    mov [rdi + 8], rax
    xor eax, eax
    ret
.zero:
    mov qword [rdi], 0
    mov qword [rdi + 8], 1
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_EXACT_INVALID
    ret
.overflow:
    mov eax, NEBO_EXACT_OVERFLOW
    ret

; rdi=out, rsi=a rational, rdx=b rational.
NEBOC_ABI_FUNCTION nebo_rational_add_i64
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp qword [rsi + 8], 0
    je .invalid
    cmp qword [rdx + 8], 0
    je .invalid
    mov rax, [rsi]
    imul rax, [rdx + 8]
    jo .overflow
    mov r8, rax
    mov rax, [rdx]
    imul rax, [rsi + 8]
    jo .overflow
    add r8, rax
    jo .overflow
    mov r9, [rsi + 8]
    imul r9, [rdx + 8]
    jo .overflow
    mov rax, r8
    test rax, rax
    jns .abs_ready
    neg rax
    jo .overflow
.abs_ready:
    mov rcx, r9
.gcd:
    test rcx, rcx
    jz .reduce
    xor edx, edx
    div rcx
    mov rax, rcx
    mov rcx, rdx
    jmp .gcd
.reduce:
    mov rcx, rax
    mov rax, r8
    cqo
    idiv rcx
    mov [rdi], rax
    mov rax, r9
    xor edx, edx
    div rcx
    mov [rdi + 8], rax
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_EXACT_INVALID
    ret
.overflow:
    mov eax, NEBO_EXACT_OVERFLOW
    ret

; Positive bounded decimal quotient: n,d,mode,out_i64,report{exact,dir,rem}.
NEBOC_ABI_FUNCTION nebo_decimal_round_u64
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    test r8, r8
    jz .invalid
    cmp edx, NEBO_ROUND_EXACT
    ja .invalid
    mov r9d, edx
    mov r10, rcx
    mov r11, r8
    mov rax, rdi
    xor edx, edx
    div rsi
    mov rcx, rdx
    test rcx, rcx
    jz .exact
    cmp r9d, NEBO_ROUND_EXACT
    je .inexact
    xor r8d, r8d
    cmp r9d, NEBO_ROUND_AWAY_ZERO
    je .round_up
    cmp r9d, NEBO_ROUND_CEILING
    je .round_up
    cmp r9d, NEBO_ROUND_HALF_UP
    je .half_up
    cmp r9d, NEBO_ROUND_HALF_EVEN
    je .half_even
    jmp .store_inexact
.half_up:
    mov rdx, rcx
    add rdx, rcx
    cmp rdx, rsi
    jae .round_up
    jmp .store_inexact
.half_even:
    mov rdx, rcx
    add rdx, rcx
    cmp rdx, rsi
    ja .round_up
    jb .store_inexact
    test al, 1
    jz .store_inexact
.round_up:
    inc rax
    mov r8d, 1
.store_inexact:
    mov [r10], rax
    mov dword [r11], 0
    mov [r11 + 4], r8d
    mov [r11 + 8], rcx
    xor eax, eax
    ret
.exact:
    mov [r10], rax
    mov dword [r11], 1
    mov dword [r11 + 4], 0
    mov qword [r11 + 8], 0
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_EXACT_INVALID
    ret
.inexact:
    mov eax, NEBO_EXACT_INEXACT
    ret

; rdi=signed i64, rsi=out f64, rdx=report {exact,lost_bits}.
NEBOC_ABI_FUNCTION nebo_exact_i64_to_f64
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cvtsi2sd xmm0, rdi
    movsd [rsi], xmm0
    cvttsd2si rax, xmm0
    xor ecx, ecx
    cmp rax, rdi
    sete cl
    mov [rdx], ecx
    mov rax, rdi
    test rax, rax
    jns .abs_ready
    neg rax
.abs_ready:
    xor ecx, ecx
    test rax, rax
    jz .lost_done
    bsr rcx, rax
    inc ecx
    sub ecx, 53
    jns .lost_done
    xor ecx, ecx
.lost_done:
    mov [rdx + 4], ecx
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_EXACT_INVALID
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
