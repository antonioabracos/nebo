; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F03 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/robotics/control_core.inc"
extern nebo_control_core_evaluate
section .data
records dq 17,34,51,68
invalid_record dq 1065537
section .bss
report resb NEBO_CONTROL_CORE_REPORT_SIZE
max_records resq NEBO_CONTROL_CORE_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_control_core_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_CONTROL_CORE_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_CONTROL_CORE_REPORT_SUM],170
    jne fail
    mov rax,0xca4ebe0e1a962de2
    cmp [report+NEBO_CONTROL_CORE_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_CONTROL_CORE_REPORT_MIN],17
    jne fail
    cmp qword [report+NEBO_CONTROL_CORE_REPORT_MAX],68
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_control_core_evaluate
    cmp eax,NEBO_CONTROL_CORE_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_control_core_evaluate
    cmp eax,NEBO_CONTROL_CORE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_control_core_evaluate
    cmp eax,NEBO_CONTROL_CORE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_CONTROL_CORE_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_control_core_evaluate
    cmp eax,NEBO_CONTROL_CORE_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_CONTROL_CORE_MAX_RECORDS
    lea rdx,[report]
    call nebo_control_core_evaluate
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
