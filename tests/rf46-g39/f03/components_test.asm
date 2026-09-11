; RESOLVER-TYPECHECKER-E-SEMANTICA-F03 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/portable/components.inc"
extern nebo_components_evaluate
section .data
records dq 11,22,33,44
invalid_record dq 1040961
section .bss
report resb NEBO_COMPONENTS_REPORT_SIZE
max_records resq NEBO_COMPONENTS_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_components_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_COMPONENTS_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_COMPONENTS_REPORT_SUM],110
    jne fail
    mov rax,0x71e63410e3e5682e
    cmp [report+NEBO_COMPONENTS_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_COMPONENTS_REPORT_MIN],11
    jne fail
    cmp qword [report+NEBO_COMPONENTS_REPORT_MAX],44
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_components_evaluate
    cmp eax,NEBO_COMPONENTS_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_components_evaluate
    cmp eax,NEBO_COMPONENTS_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_components_evaluate
    cmp eax,NEBO_COMPONENTS_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_COMPONENTS_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_components_evaluate
    cmp eax,NEBO_COMPONENTS_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_COMPONENTS_MAX_RECORDS
    lea rdx,[report]
    call nebo_components_evaluate
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
