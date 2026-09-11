bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT   1048576
%define NEBO_REDUCTION_MAX_WORKERS 64
%define NEBO_PARALLEL_OPT_IN       1

section .text

; rdi=count, esi=requested workers, edx=explicit capability.
; eax=effective workers, edx=canonical merge levels, ecx=status.
global nebo_deterministic_parallel_plan
nebo_deterministic_parallel_plan:
    cmp edx, NEBO_PARALLEL_OPT_IN
    jne .domain
    cmp rdi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test esi, esi
    jz .domain
    cmp esi, NEBO_REDUCTION_MAX_WORKERS
    ja .domain
    mov eax, esi
    test rdi, rdi
    jz .empty
    cmp rax, rdi
    jbe .levels
    mov eax, edi
.levels:
    lea r8d, [eax - 1]
    xor r9d, r9d
.level_loop:
    test r8d, r8d
    jz .ok
    shr r8d, 1
    inc r9d
    jmp .level_loop
.empty:
    mov eax, 1
    xor r9d, r9d
.ok:
    mov edx, r9d
    xor ecx, ecx
    ret
.domain:
    xor eax, eax
    xor edx, edx
    mov ecx, NEBO_QUANTITY_ERR_DOMAIN
    ret

; rdi=i64 pointer, rsi=count, edx=requested workers, ecx=explicit capability,
; r8=optional three-qword report {workers,merge-levels,count}.
; rax=value, edx=status. Fixed contiguous chunks are reduced once and their
; partials are merged by a canonical adjacent binary tree.
global nebo_reduce_i64_sum_parallel_deterministic
nebo_reduce_i64_sum_parallel_deterministic:
    cmp ecx, NEBO_PARALLEL_OPT_IN
    jne .reduce_domain
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .reduce_domain
    test edx, edx
    jz .reduce_domain
    cmp edx, NEBO_REDUCTION_MAX_WORKERS
    ja .reduce_domain
    test rsi, rsi
    jz .reduce_empty
    test rdi, rdi
    jz .reduce_domain
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 512
    mov rbx, rdi
    mov r12, rsi
    mov r13d, edx
    cmp r13, r12
    jbe .workers_ready
    mov r13, r12
.workers_ready:
    mov r14, r8
    mov rax, r12
    xor edx, edx
    div r13
    mov r11, rax                    ; base chunk length
    mov r10, rdx                    ; leading chunks with one extra item
    xor r9d, r9d                    ; worker index
    xor ecx, ecx                    ; source index
.chunk_loop:
    cmp r9, r13
    jae .merge_begin
    mov rdi, r11
    cmp r9, r10
    jae .chunk_length_ready
    inc rdi
.chunk_length_ready:
    xor r8d, r8d
    xor esi, esi
.item_loop:
    cmp rsi, rdi
    jae .chunk_store
    add r8, [rbx + rcx*8]
    jo .reduce_overflow_saved
    inc rcx
    inc rsi
    jmp .item_loop
.chunk_store:
    mov [rsp + r9*8], r8
    inc r9
    jmp .chunk_loop
.merge_begin:
    mov rsi, r13                    ; active partial count
    xor r15d, r15d                  ; merge levels
.merge_level:
    cmp rsi, 1
    jbe .reduce_success
    xor edi, edi                    ; output index
    xor ecx, ecx                    ; input index
.merge_pair:
    cmp rcx, rsi
    jae .merge_finish
    mov rax, [rsp + rcx*8]
    lea rdx, [rcx + 1]
    cmp rdx, rsi
    jae .merge_store
    add rax, [rsp + rdx*8]
    jo .reduce_overflow_saved
.merge_store:
    mov [rsp + rdi*8], rax
    inc rdi
    add rcx, 2
    jmp .merge_pair
.merge_finish:
    mov rsi, rdi
    inc r15
    jmp .merge_level
.reduce_success:
    mov rax, [rsp]
    test r14, r14
    jz .reduce_success_no_report
    mov [r14], r13
    mov [r14 + 8], r15
    mov [r14 + 16], r12
.reduce_success_no_report:
    xor edx, edx
    jmp .reduce_done
.reduce_overflow_saved:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
.reduce_done:
    add rsp, 512
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.reduce_empty:
    test r8, r8
    jz .reduce_empty_no_report
    mov qword [r8], 1
    mov qword [r8 + 8], 0
    mov qword [r8 + 16], 0
.reduce_empty_no_report:
    xor eax, eax
    xor edx, edx
    ret
.reduce_domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
