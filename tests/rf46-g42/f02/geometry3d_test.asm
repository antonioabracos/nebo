; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F02 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/spatial/geometry3d.inc"
extern nebo_geometry3d_evaluate
section .data
records dq 19,38,57,76
invalid_record dq 1073729
section .bss
report resb NEBO_GEOMETRY3D_REPORT_SIZE
max_records resq NEBO_GEOMETRY3D_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_geometry3d_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_GEOMETRY3D_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_GEOMETRY3D_REPORT_SUM],190
    jne fail
    mov rax,0x489f5a873e9acd9b
    cmp [report+NEBO_GEOMETRY3D_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_GEOMETRY3D_REPORT_MIN],19
    jne fail
    cmp qword [report+NEBO_GEOMETRY3D_REPORT_MAX],76
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_geometry3d_evaluate
    cmp eax,NEBO_GEOMETRY3D_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_geometry3d_evaluate
    cmp eax,NEBO_GEOMETRY3D_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_geometry3d_evaluate
    cmp eax,NEBO_GEOMETRY3D_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_GEOMETRY3D_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_geometry3d_evaluate
    cmp eax,NEBO_GEOMETRY3D_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_GEOMETRY3D_MAX_RECORDS
    lea rdx,[report]
    call nebo_geometry3d_evaluate
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
