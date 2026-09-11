bits 64
default rel
%include "compiler/contracts/refinement.inc"
extern nebo_refinement_validate,nebo_refinement_refine,nebo_refinement_is,nebo_refinement_assume
section .data
desc: dq -10,10,99,7
section .bss
cert resb NEBO_REFINEMENT_CERT_SIZE
section .text
global _start
_start:
 lea rdi,[desc]
 call nebo_refinement_validate
 test eax,eax
 jnz fail
 lea rdi,[desc]
 mov rsi,5
 mov rdx,1234
 lea rcx,[cert]
 call nebo_refinement_refine
 test eax,eax
 jnz fail
 cmp qword [cert+NEBO_REFINEMENT_CERT_VALUE],5
 jne fail
 cmp qword [cert+NEBO_REFINEMENT_CERT_PREDICATE_ID],99
 jne fail
 lea rdi,[desc]
 mov rsi,11
 call nebo_refinement_is
 test eax,eax
 jnz fail
 lea rdi,[desc]
 mov rsi,11
 mov rdx,1234
 lea rcx,[cert]
 call nebo_refinement_refine
 cmp eax,NEBO_REFINEMENT_STATUS_RANGE
 jne fail
 cmp qword [cert],0
 jne fail
 xor edi,edi
 mov esi,1
 call nebo_refinement_assume
 cmp eax,NEBO_REFINEMENT_STATUS_ASSUMPTION
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
