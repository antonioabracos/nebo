bits 64
default rel
%include "runtime/protocol/resilience.inc"
extern nebo_rpc_policy_retry
extern nebo_rpc_policy_timeout
section .bss
policy resb nebo_ast_hir_lir_planner_e_otimizacao_POLICY_SIZE
section .text
global _start
_start:
    lea rdi,[policy]
    mov esi,3
    mov edx,NEBO_RPC_METHOD_IDEMPOTENT
    call nebo_rpc_policy_retry
    test eax,eax
    jnz fail
    lea rdi,[policy]
    mov esi,100
    call nebo_rpc_policy_timeout
    mov edi,eax
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
