bits 64
default rel
%include "runtime/crdt/crdt_list.inc"
extern nebo_rga_materialize,nebo_causal_stable_min
section .data
values dq 10,20,30,40
tombs db 0,1,0,0
local dq 5,3
peer dq 4,7
section .bss
visible resq 3
count resq 1
stable resq 2
section .text
global _start
_start:
 lea rdi,[values]
 lea rsi,[tombs]
 mov edx,4
 lea rcx,[visible]
 mov r8d,3
 lea r9,[count]
 call nebo_rga_materialize
 test eax,eax
 jnz fail
 cmp qword [count],3
 jne fail
 cmp qword [visible+8],30
 jne fail
 lea rdi,[local]
 lea rsi,[peer]
 mov edx,2
 lea rcx,[stable]
 call nebo_causal_stable_min
 cmp qword [stable],4
 jne fail
 cmp qword [stable+8],3
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
