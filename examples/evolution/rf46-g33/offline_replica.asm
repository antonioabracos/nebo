bits 64
default rel
%include "runtime/replication/version_vector.inc"
%include "runtime/crdt/crdt_core.inc"
extern nebo_vv_compare,nebo_crdt_merge_max
section .data
left dq 2,1
right dq 1,3
section .bss
merged resq 2
section .text
global _start
_start:
 lea rdi,[left]
 lea rsi,[right]
 mov edx,2
 call nebo_vv_compare
 cmp eax,NEBO_VV_CONCURRENT
 jne fail
 lea rdi,[left]
 lea rsi,[right]
 lea rdx,[merged]
 mov ecx,2
 call nebo_crdt_merge_max
 cmp qword [merged],2
 jne fail
 cmp qword [merged+8],3
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
