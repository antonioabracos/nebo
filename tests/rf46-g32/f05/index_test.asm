bits 64
default rel
%include "runtime/query/index.inc"
extern nebo_index_lookup,nebo_planner_choose
section .data
pairs dq 1,10, 3,30, 7,70, 9,90
section .bss
value resq 1
reason resq 1
section .text
global _start
_start:
 lea rdi,[pairs]
 mov esi,4
 mov edx,7
 lea rcx,[value]
 call nebo_index_lookup
 test eax,eax
 jnz fail
 cmp qword [value],70
 jne fail
 lea rdi,[pairs]
 mov esi,4
 mov edx,8
 lea rcx,[value]
 call nebo_index_lookup
 cmp eax,NEBO_INDEX_NOT_FOUND
 jne fail
 mov edi,100
 mov esi,1
 mov edx,1
 lea rcx,[reason]
 call nebo_planner_choose
 cmp eax,NEBO_PLAN_INDEX
 jne fail
 cmp qword [reason],NEBO_PLAN_REASON_EQUALITY_INDEX
 jne fail
 mov edi,4
 mov esi,1
 mov edx,1
 lea rcx,[reason]
 call nebo_planner_choose
 cmp eax,NEBO_PLAN_SCAN
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
