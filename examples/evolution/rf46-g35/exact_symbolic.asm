bits 64
default rel
%include "runtime/symbolic/symbolic.inc"
extern nebo_symbolic_eval_dual_i64
section .data
nodes:
    dd NEBO_SYMBOLIC_SYMBOL,0,0,0
    dq 0
    dd NEBO_SYMBOLIC_CONST,0,0,0
    dq 1
    dd NEBO_SYMBOLIC_ADD,0,1,0
    dq 0
section .bss
workspace resq 6
result resq 2
section .text
global _start
_start:
    lea rdi,[nodes]
    mov esi,3
    xor edx,edx
    mov ecx,41
    lea r8,[workspace]
    lea r9,[result]
    call nebo_symbolic_eval_dual_i64
    test eax,eax
    jnz fail
    cmp qword [result],42
    jne fail
    cmp qword [result+8],1
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
