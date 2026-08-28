; RESOLVER-TYPECHECKER-E-SEMANTICA-F04 bounded native composition example.
bits 64
default rel
%include "runtime/portable/ebpf_verifier.inc"
extern nebo_ebpf_verify
section .data
example_program dq 0x00000001000000b7,0x0000000000000095
section .bss
example_report resb NEBO_EBPF_VERIFIER_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_program]
    mov esi,2
    lea rdx,[example_report]
    call nebo_ebpf_verify
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
