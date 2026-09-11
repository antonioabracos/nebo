bits 64
default rel
%include "runtime/symbolic/symbolic.inc"
extern nebo_symbolic_eval_dual_i64
%macro NODE 4
    dd %1,%2,%3,0
    dq %4
%endmacro
section .data
; 2 + x*x at x=3.
nodes:
    NODE NEBO_SYMBOLIC_CONST,0,0,2
    NODE NEBO_SYMBOLIC_SYMBOL,7,0,0
    NODE NEBO_SYMBOLIC_MUL,1,1,0
    NODE NEBO_SYMBOLIC_ADD,0,2,0
bad_nodes:
    NODE NEBO_SYMBOLIC_ADD,0,0,0
section .bss
workspace resq 8
pair_out resq 2
section .text
global _start
_start:
    lea rdi,[nodes]
    mov esi,4
    mov edx,7
    mov ecx,3
    lea r8,[workspace]
    lea r9,[pair_out]
    call nebo_symbolic_eval_dual_i64
    test eax,eax
    jnz fail
    cmp qword [pair_out],11
    jne fail
    cmp qword [pair_out+8],6
    jne fail
    mov qword [pair_out],0x1234
    lea rdi,[bad_nodes]
    mov esi,1
    mov edx,7
    mov ecx,3
    lea r8,[workspace]
    lea r9,[pair_out]
    call nebo_symbolic_eval_dual_i64
    cmp eax,NEBO_SYMBOLIC_INVALID
    jne fail
    cmp qword [pair_out],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
