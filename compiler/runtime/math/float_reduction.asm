bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT 1048576

section .rodata align=16
reduction_abs_mask: dq 0x7fffffffffffffff, 0x7fffffffffffffff

section .text

; rdi=pointer to binary64, rsi=count, xmm0=identity.
; xmm0=result, eax=status. Order is always increasing source index.
global nebo_reduce_f64_sum_stable
nebo_reduce_f64_sum_stable:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .ok
    test rdi, rdi
    jz .domain
    xor ecx, ecx
.loop:
    addsd xmm0, [rdi + rcx*8]
    inc rcx
    cmp rcx, rsi
    jb .loop
.ok:
    movq rdx, xmm0
    mov rax, 0x7ff0000000000000
    and rdx, rax
    cmp rdx, rax
    je .precision
    xor eax, eax
    ret
.domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret
.precision:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_PRECISION
    ret

global nebo_reduce_f64_product_stable
nebo_reduce_f64_product_stable:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .ok
    test rdi, rdi
    jz .domain
    xor ecx, ecx
.loop:
    mulsd xmm0, [rdi + rcx*8]
    inc rcx
    cmp rcx, rsi
    jb .loop
.ok:
    movq rdx, xmm0
    mov rax, 0x7ff0000000000000
    and rdx, rax
    cmp rdx, rax
    je .precision
    xor eax, eax
    ret
.domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret
.precision:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_PRECISION
    ret

; Recursive adjacent-halves accumulation fixes a balanced reduction tree
; independently of host scheduling. xmm0 carries the explicit identity.
global nebo_reduce_f64_sum_pairwise
nebo_reduce_f64_sum_pairwise:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .pair_domain
    test rsi, rsi
    jz .pair_ok
    test rdi, rdi
    jz .pair_domain
    sub rsp, 16
    movsd [rsp], xmm0
    call .pair_tree
    addsd xmm0, [rsp]
    add rsp, 16
.pair_finite:
    movq rdx, xmm0
    mov rax, 0x7ff0000000000000
    and rdx, rax
    cmp rdx, rax
    je .pair_precision
.pair_ok:
    xor eax, eax
    ret
.pair_domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret
.pair_precision:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_PRECISION
    ret
.pair_tree:
    cmp rsi, 1
    jne .pair_split
    movsd xmm0, [rdi]
    ret
.pair_split:
    push rbx
    push r12
    push r13
    sub rsp, 16
    mov rbx, rdi
    mov r12, rsi
    mov r13, rsi
    shr r13, 1
    mov rsi, r13
    call .pair_tree
    movsd [rsp], xmm0
    lea rdi, [rbx + r13*8]
    mov rsi, r12
    sub rsi, r13
    call .pair_tree
    addsd xmm0, [rsp]
    add rsp, 16
    pop r13
    pop r12
    pop rbx
    ret

; Kahan compensated sum with fixed increasing-index order.
global nebo_reduce_f64_sum_kahan
nebo_reduce_f64_sum_kahan:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .kahan_domain
    test rsi, rsi
    jz .kahan_ok
    test rdi, rdi
    jz .kahan_domain
    pxor xmm1, xmm1                 ; compensation
    xor ecx, ecx
.kahan_loop:
    movsd xmm2, [rdi + rcx*8]
    subsd xmm2, xmm1                ; y = input - compensation
    movapd xmm3, xmm0
    addsd xmm3, xmm2                ; t = sum + y
    movapd xmm1, xmm3
    subsd xmm1, xmm0
    subsd xmm1, xmm2                ; c = (t - sum) - y
    movapd xmm0, xmm3
    inc rcx
    cmp rcx, rsi
    jb .kahan_loop
    movq rdx, xmm0
    mov rax, 0x7ff0000000000000
    and rdx, rax
    cmp rdx, rax
    je .kahan_precision
.kahan_ok:
    xor eax, eax
    ret
.kahan_domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret
.kahan_precision:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_PRECISION
    ret

; Neumaier compensated sum, also with one explicit increasing-index order.
global nebo_reduce_f64_sum_neumaier
nebo_reduce_f64_sum_neumaier:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .neumaier_domain
    test rsi, rsi
    jz .neumaier_ok
    test rdi, rdi
    jz .neumaier_domain
    pxor xmm1, xmm1                 ; compensation
    xor ecx, ecx
.neumaier_loop:
    movsd xmm2, [rdi + rcx*8]       ; x
    movapd xmm3, xmm0
    addsd xmm3, xmm2                ; t
    movapd xmm4, xmm0
    andpd xmm4, [rel reduction_abs_mask]
    movapd xmm5, xmm2
    andpd xmm5, [rel reduction_abs_mask]
    ucomisd xmm4, xmm5
    jb .neumaier_input_larger
    subsd xmm0, xmm3
    addsd xmm0, xmm2                ; (sum - t) + x
    addsd xmm1, xmm0
    jmp .neumaier_next
.neumaier_input_larger:
    subsd xmm2, xmm3
    addsd xmm2, xmm0                ; (x - t) + sum
    addsd xmm1, xmm2
.neumaier_next:
    movapd xmm0, xmm3
    inc rcx
    cmp rcx, rsi
    jb .neumaier_loop
    addsd xmm0, xmm1
    movq rdx, xmm0
    mov rax, 0x7ff0000000000000
    and rdx, rax
    cmp rdx, rax
    je .neumaier_precision
.neumaier_ok:
    xor eax, eax
    ret
.neumaier_domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret
.neumaier_precision:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_PRECISION
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
