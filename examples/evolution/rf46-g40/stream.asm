bits 64
default rel
%include "runtime/protocol/stream.inc"
extern nebo_client_open_stream
section .bss
stream resb nebo_ast_hir_lir_planner_e_otimizacao_STREAM_SIZE
storage resq 4
section .text
global _start
_start:
    lea rdi,[stream]
    lea rsi,[storage]
    mov edx,4
    mov ecx,8
    mov r8d,10
    xor r9d,r9d
    call nebo_client_open_stream
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
