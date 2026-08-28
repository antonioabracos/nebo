bits 64
default rel
%include "runtime/protocol/schema.inc"
extern nebo_field_required
extern nebo_protocol_define
extern nebo_message_define
section .bss
protocol resb NEBO_PROTOCOL_SIZE
field resb nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE
section .text
global _start
_start:
    lea rdi,[field]
    mov esi,1
    mov edx,1
    call nebo_field_required
    test eax,eax
    jnz fail
    lea rdi,[protocol]
    mov esi,1
    lea rdx,[field]
    mov ecx,1
    xor r8d,r8d
    xor r9d,r9d
    call nebo_protocol_define
    test eax,eax
    jnz fail
    lea rdi,[protocol]
    call nebo_message_define
    mov edi,eax
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
