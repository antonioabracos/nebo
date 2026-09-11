bits 64
default rel
%include "compiler/verification/proof.inc"
extern nebo_proof_verify,nebo_proof_compose
section .data
left dq 10,100,200,300,1,1,NEBO_PROOF_VERSION
right dq 11,100,200,301,2,1,NEBO_PROOF_VERSION
section .bss
combined resb NEBO_PROOF_SIZE
section .text
global _start
_start:
 lea rdi,[left]
 mov esi,100
 mov edx,200
 call nebo_proof_verify
 test eax,eax
 jnz fail
 lea rdi,[left]
 mov esi,101
 mov edx,200
 call nebo_proof_verify
 cmp eax,NEBO_PROOF_STATUS_CHANGED
 jne fail
 lea rdi,[left]
 lea rsi,[right]
 lea rdx,[combined]
 call nebo_proof_compose
 test eax,eax
 jnz fail
 cmp qword [combined+NEBO_PROOF_ASSUMPTION_MASK],3
 jne fail
 cmp qword [combined+NEBO_PROOF_ASSUMPTION_COUNT],2
 jne fail
 mov qword [right+NEBO_PROOF_SPEC_HASH],201
 lea rdi,[left]
 lea rsi,[right]
 lea rdx,[combined]
 call nebo_proof_compose
 cmp eax,NEBO_PROOF_STATUS_INCOMPATIBLE
 jne fail
 cmp qword [combined],0
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
