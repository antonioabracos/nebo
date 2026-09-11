; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F07 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/simulation/particles.inc"
extern nebo_particles_evaluate
section .data
records dq 35,70,105,140
invalid_record dq 1139265
section .bss
report resb NEBO_PARTICLES_REPORT_SIZE
max_records resq NEBO_PARTICLES_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_particles_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_PARTICLES_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_PARTICLES_REPORT_SUM],350
    jne fail
    mov rax,0xf6a2b96fc19810fa
    cmp [report+NEBO_PARTICLES_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_PARTICLES_REPORT_MIN],35
    jne fail
    cmp qword [report+NEBO_PARTICLES_REPORT_MAX],140
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_particles_evaluate
    cmp eax,NEBO_PARTICLES_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_particles_evaluate
    cmp eax,NEBO_PARTICLES_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_particles_evaluate
    cmp eax,NEBO_PARTICLES_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_PARTICLES_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_particles_evaluate
    cmp eax,NEBO_PARTICLES_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_PARTICLES_MAX_RECORDS
    lea rdx,[report]
    call nebo_particles_evaluate
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
