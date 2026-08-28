bits 64
default rel
%include "runtime/knowledge/claim.inc"
%include "runtime/reasoning/incremental.inc"
extern nebo_claim_classify,nebo_explanation_init
section .bss
proof resb NEBO_EXPLAIN_SIZE
section .text
global _start
_start:
 mov edi,1
 mov esi,1
 xor edx,edx
 call nebo_claim_classify
 cmp eax,NEBO_CLAIM_SUPPORTED
 jne fail
 lea rdi,[proof]
 mov esi,8
 mov edx,103
 mov ecx,6
 mov r8d,1
 call nebo_explanation_init
 test eax,eax
 jnz fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
