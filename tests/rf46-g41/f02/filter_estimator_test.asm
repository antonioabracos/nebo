; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F02 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/robotics/filter_estimator.inc"
extern nebo_filter_estimator_evaluate
section .data
records dq 16,32,48,64
invalid_record dq 1061441
section .bss
report resb NEBO_FILTER_ESTIMATOR_REPORT_SIZE
max_records resq NEBO_FILTER_ESTIMATOR_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_filter_estimator_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_FILTER_ESTIMATOR_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_FILTER_ESTIMATOR_REPORT_SUM],160
    jne fail
    mov rax,0xb88b9e0e1066e177
    cmp [report+NEBO_FILTER_ESTIMATOR_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_FILTER_ESTIMATOR_REPORT_MIN],16
    jne fail
    cmp qword [report+NEBO_FILTER_ESTIMATOR_REPORT_MAX],64
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_filter_estimator_evaluate
    cmp eax,NEBO_FILTER_ESTIMATOR_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_filter_estimator_evaluate
    cmp eax,NEBO_FILTER_ESTIMATOR_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_filter_estimator_evaluate
    cmp eax,NEBO_FILTER_ESTIMATOR_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_FILTER_ESTIMATOR_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_filter_estimator_evaluate
    cmp eax,NEBO_FILTER_ESTIMATOR_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_FILTER_ESTIMATOR_MAX_RECORDS
    lea rdx,[report]
    call nebo_filter_estimator_evaluate
    test eax,eax
    jnz fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
