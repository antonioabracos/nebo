; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F01 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/spatial/geometry2d.inc"
extern nebo_geometry2d_evaluate
section .data
records dq 18,36,54,72
invalid_record dq 1069633
section .bss
report resb NEBO_GEOMETRY2D_REPORT_SIZE
max_records resq NEBO_GEOMETRY2D_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_geometry2d_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_GEOMETRY2D_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_GEOMETRY2D_REPORT_SUM],180
    jne fail
    mov rax,0xbc3ede980832e82c
    cmp [report+NEBO_GEOMETRY2D_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_GEOMETRY2D_REPORT_MIN],18
    jne fail
    cmp qword [report+NEBO_GEOMETRY2D_REPORT_MAX],72
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_geometry2d_evaluate
    cmp eax,NEBO_GEOMETRY2D_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_geometry2d_evaluate
    cmp eax,NEBO_GEOMETRY2D_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_geometry2d_evaluate
    cmp eax,NEBO_GEOMETRY2D_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_GEOMETRY2D_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_geometry2d_evaluate
    cmp eax,NEBO_GEOMETRY2D_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_GEOMETRY2D_MAX_RECORDS
    lea rdx,[report]
    call nebo_geometry2d_evaluate
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
