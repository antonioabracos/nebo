; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F01 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/simulation/ecs_storage.inc"
extern nebo_ecs_storage_evaluate
section .data
records dq 29,58,87,116
invalid_record dq 1114689
section .bss
report resb NEBO_ECS_STORAGE_REPORT_SIZE
max_records resq NEBO_ECS_STORAGE_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_ecs_storage_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_ECS_STORAGE_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_ECS_STORAGE_REPORT_SUM],290
    jne fail
    mov rax,0xed3ec341768c8ba8
    cmp [report+NEBO_ECS_STORAGE_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_ECS_STORAGE_REPORT_MIN],29
    jne fail
    cmp qword [report+NEBO_ECS_STORAGE_REPORT_MAX],116
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_ecs_storage_evaluate
    cmp eax,NEBO_ECS_STORAGE_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_ecs_storage_evaluate
    cmp eax,NEBO_ECS_STORAGE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_ecs_storage_evaluate
    cmp eax,NEBO_ECS_STORAGE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_ECS_STORAGE_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_ecs_storage_evaluate
    cmp eax,NEBO_ECS_STORAGE_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_ECS_STORAGE_MAX_RECORDS
    lea rdx,[report]
    call nebo_ecs_storage_evaluate
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
