; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F03 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/spatial/mesh.inc"
extern nebo_mesh_evaluate
section .data
records dq 20,40,60,80
invalid_record dq 1077825
section .bss
report resb NEBO_MESH_REPORT_SIZE
max_records resq NEBO_MESH_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_mesh_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_MESH_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_MESH_REPORT_SUM],200
    jne fail
    mov rax,0x33adee758832f486
    cmp [report+NEBO_MESH_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_MESH_REPORT_MIN],20
    jne fail
    cmp qword [report+NEBO_MESH_REPORT_MAX],80
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_mesh_evaluate
    cmp eax,NEBO_MESH_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_mesh_evaluate
    cmp eax,NEBO_MESH_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_mesh_evaluate
    cmp eax,NEBO_MESH_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_MESH_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_mesh_evaluate
    cmp eax,NEBO_MESH_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_MESH_MAX_RECORDS
    lea rdx,[report]
    call nebo_mesh_evaluate
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
