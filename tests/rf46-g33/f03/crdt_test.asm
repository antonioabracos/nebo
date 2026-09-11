bits 64
default rel
%include "runtime/crdt/crdt_core.inc"
extern nebo_crdt_merge_max,nebo_pn_counter_value
section .data
a dq 2,0,4
state_b dq 1,3,4
negative dq 0,1,0
section .bss
ab resq 3
ba resq 3
value resq 1
section .text
global _start
_start:
 lea rdi,[a]
 lea rsi,[state_b]
 lea rdx,[ab]
 mov ecx,3
 call nebo_crdt_merge_max
 lea rdi,[state_b]
 lea rsi,[a]
 lea rdx,[ba]
 mov ecx,3
 call nebo_crdt_merge_max
 mov ecx,3
 xor eax,eax
.eq:
 cmp rax,rcx
 jae .value
 mov r8,[ab+rax*8]
 cmp r8,[ba+rax*8]
 jne fail
 inc rax
 jmp .eq
.value:
 lea rdi,[ab]
 lea rsi,[negative]
 mov edx,3
 lea rcx,[value]
 call nebo_pn_counter_value
 test eax,eax
 jnz fail
 cmp qword [value],8
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
