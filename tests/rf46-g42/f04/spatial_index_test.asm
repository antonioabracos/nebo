; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F04 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/spatial/spatial_index.inc"
extern nebo_spatial_index_evaluate
section .data
records dq 21,42,63,84
invalid_record dq 1081921
section .bss
report resb NEBO_SPATIAL_INDEX_REPORT_SIZE
max_records resq NEBO_SPATIAL_INDEX_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_spatial_index_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_SPATIAL_INDEX_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_SPATIAL_INDEX_REPORT_SUM],210
    jne fail
    mov rax,0x2636a2872b2ed969
    cmp [report+NEBO_SPATIAL_INDEX_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_SPATIAL_INDEX_REPORT_MIN],21
    jne fail
    cmp qword [report+NEBO_SPATIAL_INDEX_REPORT_MAX],84
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_spatial_index_evaluate
    cmp eax,NEBO_SPATIAL_INDEX_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_spatial_index_evaluate
    cmp eax,NEBO_SPATIAL_INDEX_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_spatial_index_evaluate
    cmp eax,NEBO_SPATIAL_INDEX_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_SPATIAL_INDEX_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_spatial_index_evaluate
    cmp eax,NEBO_SPATIAL_INDEX_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_SPATIAL_INDEX_MAX_RECORDS
    lea rdx,[report]
    call nebo_spatial_index_evaluate
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
