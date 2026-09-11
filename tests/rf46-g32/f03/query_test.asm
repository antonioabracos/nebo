bits 64
default rel
%include "runtime/query/query.inc"
extern nebo_query_plan_validate,nebo_query_filter_sum
section .data
values dq 3,10,7,12,2
section .bss
count resq 1
sum resq 1
section .text
global _start
_start:
 mov edi,8
 mov esi,2
 mov edx,4
 mov ecx,3
 call nebo_query_plan_validate
 test eax,eax
 jnz fail
 lea rdi,[values]
 mov esi,5
 mov edx,7
 mov ecx,2
 lea r8,[count]
 lea r9,[sum]
 call nebo_query_filter_sum
 test eax,eax
 jnz fail
 cmp qword [count],2
 jne fail
 cmp qword [sum],17
 jne fail
 mov edi,65
 xor esi,esi
 xor edx,edx
 mov ecx,1
 call nebo_query_plan_validate
 cmp eax,NEBO_QUERY_STATUS_LIMIT
 jne fail
 xor edi,edi
 jmp exit
fail:
 mov edi,1
exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
