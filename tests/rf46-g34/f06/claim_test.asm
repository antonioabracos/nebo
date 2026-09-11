bits 64
default rel
%include "runtime/knowledge/claim.inc"
extern nebo_claim_classify
section .text
global _start
_start:
 mov edi,1
 mov esi,2
 xor edx,edx
 call nebo_claim_classify
 cmp eax,NEBO_CLAIM_SUPPORTED
 jne fail
 mov edi,1
 xor esi,esi
 mov edx,1
 call nebo_claim_classify
 cmp eax,NEBO_CLAIM_CONTRADICTED
 jne fail
 mov edi,1
 mov esi,1
 mov edx,1
 call nebo_claim_classify
 cmp eax,NEBO_CLAIM_AMBIGUOUS
 jne fail
 mov edi,1
 xor esi,esi
 xor edx,edx
 call nebo_claim_classify
 cmp eax,NEBO_CLAIM_UNKNOWN
 jne fail
 xor edi,edi
 call nebo_claim_classify
 cmp eax,NEBO_CLAIM_INVALID
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
