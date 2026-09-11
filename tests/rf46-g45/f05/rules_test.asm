bits 64
default rel
%include "runtime/rules/rules.inc"
extern nebo_rules_validate
extern nebo_rules_evaluate
section .data
rules dq 1,7,100,1, 1,7,200,5, 2,9,300,2
conflict dq 1,7,100,5, 1,7,200,5
cycle dq 9,1,9,1
section .bss
decision resq 3
section .text
global _start
_start:
 lea rdi,[rules]
 mov esi,3
 call nebo_rules_validate
 test eax,eax
 jnz fail
 lea rdi,[rules]
 mov esi,3
 mov edx,1
 mov ecx,7
 lea r8,[decision]
 call nebo_rules_evaluate
 test eax,eax
 jnz fail
 cmp qword [decision],200
 jne fail
 cmp qword [decision+8],5
 jne fail
 cmp qword [decision+16],1
 jne fail
 lea rdi,[conflict]
 mov esi,2
 mov edx,1
 mov ecx,7
 lea r8,[decision]
 call nebo_rules_evaluate
 cmp eax,NEBO_RULE_CONFLICT
 jne fail
 lea rdi,[cycle]
 mov esi,1
 call nebo_rules_validate
 cmp eax,NEBO_RULE_CYCLE
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
