bits 64
default rel
%include "runtime/replication/version_vector.inc"
extern nebo_vv_compare,nebo_vv_checkpoint
section .data
a dq 2,1,0
b dq 2,3,0
c dq 3,1,0
section .bss
copy resq 3
section .text
global _start
_start:
 lea rdi,[a]
 lea rsi,[b]
 mov edx,3
 call nebo_vv_compare
 cmp eax,NEBO_VV_BEFORE
 jne fail
 lea rdi,[b]
 lea rsi,[c]
 mov edx,3
 call nebo_vv_compare
 cmp eax,NEBO_VV_CONCURRENT
 jne fail
 lea rdi,[a]
 lea rsi,[copy]
 mov edx,3
 call nebo_vv_checkpoint
 test eax,eax
 jnz fail
 lea rdi,[a]
 lea rsi,[copy]
 mov edx,3
 call nebo_vv_compare
 cmp eax,NEBO_VV_EQUAL
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
