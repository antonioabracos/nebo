bits 64
default rel
%include "runtime/probabilistic/exact_inference.inc"
extern nebo_prob_exact_enumerate_u64
section .data
weights dq 2,3,5
bad_weights dq 2,0,5
expected dq 0.3
section .bss
report resb NEBO_INFER_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[weights]
    mov esi,3
    mov edx,1
    lea rcx,[report]
    call nebo_prob_exact_enumerate_u64
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_INFER_REPORT_TOTAL_WEIGHT],10
    jne fail
    cmp qword [report+NEBO_INFER_REPORT_QUERY_WEIGHT],3
    jne fail
    mov rax,[expected]
    cmp [report+NEBO_INFER_REPORT_MARGINAL],rax
    jne fail
    mov qword [report],0x1234
    lea rdi,[bad_weights]
    mov esi,3
    xor edx,edx
    lea rcx,[report]
    call nebo_prob_exact_enumerate_u64
    cmp eax,NEBO_INFER_INVALID
    jne fail
    cmp qword [report],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
