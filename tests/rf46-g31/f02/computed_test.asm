bits 64
default rel
%include "runtime/reactive/computed.inc"
extern nebo_computed_init,nebo_computed_add_dependency,nebo_computed_invalidate,nebo_computed_recompute_sum
section .data
values dq 10,20,30
section .bss
node resb NEBO_COMPUTED_SIZE
report resb NEBO_COMPUTED_REPORT_SIZE
section .text
global _start
_start:
 lea rdi,[node]
 mov esi,1
 call nebo_computed_init
 test eax,eax
 jnz fail
 lea rdi,[node]
 xor esi,esi
 call nebo_computed_add_dependency
 test eax,eax
 jnz fail
 lea rdi,[node]
 mov esi,2
 call nebo_computed_add_dependency
 test eax,eax
 jnz fail
 lea rdi,[node]
 mov esi,77
 call nebo_computed_invalidate
 test eax,eax
 jnz fail
 lea rdi,[node]
 lea rsi,[values]
 mov edx,3
 lea rcx,[report]
 call nebo_computed_recompute_sum
 test eax,eax
 jnz fail
 cmp qword [node],40
 jne fail
 cmp qword [node+NEBO_COMPUTED_VERSION],2
 jne fail
 cmp qword [report+NEBO_COMPUTED_REPORT_DEPENDENCIES],2
 jne fail
 cmp qword [report+NEBO_COMPUTED_REPORT_REASON],77
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
