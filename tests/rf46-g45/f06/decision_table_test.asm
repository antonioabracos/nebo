bits 64
default rel
%include "runtime/rules/decision_table.inc"
extern nebo_decision_table_decide
extern nebo_decision_table_coverage
section .data
rows dq 0,9,100, 10,19,200, 20,29,300
overlap dq 0,10,100, 10,20,200
gap_rows dq 0,9,100, 11,20,200
section .bss
decision resq 2
section .text
global _start
_start:
 lea rdi,[rows]
 mov esi,3
 mov edx,15
 mov ecx,NEBO_DECISION_HIT_UNIQUE
 lea r8,[decision]
 call nebo_decision_table_decide
 test eax,eax
 jnz fail
 cmp qword [decision],200
 jne fail
 cmp qword [decision+8],1
 jne fail
 lea rdi,[rows]
 mov esi,3
 xor edx,edx
 mov ecx,29
 call nebo_decision_table_coverage
 test eax,eax
 jnz fail
 lea rdi,[overlap]
 mov esi,2
 mov edx,10
 mov ecx,NEBO_DECISION_HIT_UNIQUE
 lea r8,[decision]
 call nebo_decision_table_decide
 cmp eax,NEBO_DECISION_CONFLICT
 jne fail
 lea rdi,[gap_rows]
 mov esi,2
 xor edx,edx
 mov ecx,20
 call nebo_decision_table_coverage
 cmp eax,NEBO_DECISION_GAP
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
