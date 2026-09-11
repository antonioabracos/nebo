; RESOLVER-TYPECHECKER-E-SEMANTICA-F05 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/portable/edge_budget.inc"
extern nebo_edge_budget_evaluate
section .data
records dq 13,26,39,52
invalid_record dq 1049153
section .bss
report resb NEBO_EDGE_BUDGET_REPORT_SIZE
max_records resq NEBO_EDGE_BUDGET_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_edge_budget_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_EDGE_BUDGET_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_EDGE_BUDGET_REPORT_SUM],130
    jne fail
    mov rax,0xd8ea04111dfb1fcc
    cmp [report+NEBO_EDGE_BUDGET_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_EDGE_BUDGET_REPORT_MIN],13
    jne fail
    cmp qword [report+NEBO_EDGE_BUDGET_REPORT_MAX],52
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_edge_budget_evaluate
    cmp eax,NEBO_EDGE_BUDGET_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_edge_budget_evaluate
    cmp eax,NEBO_EDGE_BUDGET_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_edge_budget_evaluate
    cmp eax,NEBO_EDGE_BUDGET_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_EDGE_BUDGET_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_edge_budget_evaluate
    cmp eax,NEBO_EDGE_BUDGET_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_EDGE_BUDGET_MAX_RECORDS
    lea rdx,[report]
    call nebo_edge_budget_evaluate
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
