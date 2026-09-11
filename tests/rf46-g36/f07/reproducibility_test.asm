bits 64
default rel
%include "runtime/scientific/reproducibility.inc"
extern nebo_scientific_context_digest
extern nebo_scientific_benchmark_report_u64
section .rodata
context db "RF46-SCICTX-v1;dtype=f64;round=nearest;threads=1;deterministic=1"
context_len equ $-context
samples dq 10,11,12,15,18
unsorted dq 2,1
section .bss
digest resq 1
report resb NEBO_REPRO_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[context]
    mov esi,context_len
    lea rdx,[digest]
    call nebo_scientific_context_digest
    test eax,eax
    jnz fail
    cmp qword [digest],0
    je fail
    lea rdi,[samples]
    mov esi,5
    lea rdx,[report]
    call nebo_scientific_benchmark_report_u64
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_REPRO_REPORT_MIN],10
    jne fail
    cmp qword [report+NEBO_REPRO_REPORT_MEDIAN],12
    jne fail
    cmp qword [report+NEBO_REPRO_REPORT_MAX],18
    jne fail
    mov qword [report],0x1234
    lea rdi,[unsorted]
    mov esi,2
    lea rdx,[report]
    call nebo_scientific_benchmark_report_u64
    cmp eax,NEBO_REPRO_INVALID
    jne fail
    cmp qword [report],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
