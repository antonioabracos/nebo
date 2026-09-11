bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT 1048576

section .text

; rdi=i64 pointer, rsi=count, rdx=scale, rcx=bias, r8=identity.
; Applies value*scale+bias exactly once, then sums in source order.
global nebo_reduce_i64_affine_map_sum
nebo_reduce_i64_affine_map_sum:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .domain
    mov r9, rdx
    mov r10, rcx
    mov r11, r8
    xor ecx, ecx
.loop:
    mov rax, [rdi + rcx*8]
    imul rax, r9
    jo .overflow
    add rax, r10
    jo .overflow
    add r11, rax
    jo .overflow
    inc rcx
    cmp rcx, rsi
    jb .loop
    mov rax, r11
    xor edx, edx
    ret
.empty:
    mov rax, r8
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; rdi=i64 pointer, rsi=count, rdx=non-zero divisor, rcx=remainder,
; r8=scale, r9=bias.  Filter is tested before one affine mapping; accepted
; values are summed from identity zero without materializing an intermediate.
global nebo_reduce_i64_filter_map_sum
nebo_reduce_i64_filter_map_sum:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .filter_domain
    test rdx, rdx
    jz .filter_domain
    test rsi, rsi
    jz .filter_empty
    test rdi, rdi
    jz .filter_domain
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    xor r10d, r10d
    xor r11d, r11d
.filter_loop:
    mov rax, [rbx + r10*8]
    mov r8, rax
    cmp r13, -1
    jne .filter_divide
    xor edx, edx
    jmp .filter_remainder
.filter_divide:
    cqo
    idiv r13
.filter_remainder:
    cmp rdx, r14
    jne .filter_next
    mov rax, r8
    imul rax, r15
    jo .filter_overflow_saved
    add rax, r9
    jo .filter_overflow_saved
    add r11, rax
    jo .filter_overflow_saved
.filter_next:
    inc r10
    cmp r10, r12
    jb .filter_loop
    mov rax, r11
    xor edx, edx
    jmp .filter_done
.filter_overflow_saved:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
.filter_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.filter_empty:
    xor eax, eax
    xor edx, edx
    ret
.filter_domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
