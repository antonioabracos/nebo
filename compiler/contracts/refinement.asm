; REDE-E-PROTOCOLOS-F02 bounded signed interval refinements and certificates.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/contracts/refinement.inc"
section .text
NEBOC_ABI_FUNCTION nebo_refinement_validate
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBO_REFINEMENT_DESC_MIN]
 cmp rax,[rdi+NEBO_REFINEMENT_DESC_MAX]
 jg .range
 cmp qword [rdi+NEBO_REFINEMENT_DESC_PREDICATE_ID],0
 je .predicate
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REFINEMENT_STATUS_INVALID
 ret
.range: mov eax,NEBO_REFINEMENT_STATUS_RANGE
 ret
.predicate: mov eax,NEBO_REFINEMENT_STATUS_PREDICATE
 ret

NEBOC_ABI_FUNCTION nebo_refinement_refine
 ; descriptor, signed value, subject hash, certificate output
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 mov qword [rcx+8],0
 mov qword [rcx+16],0
 test rdi,rdi
 jz .invalid
 cmp rsi,[rdi+NEBO_REFINEMENT_DESC_MIN]
 jl .range
 cmp rsi,[rdi+NEBO_REFINEMENT_DESC_MAX]
 jg .range
 test rdx,rdx
 jz .invalid
 mov [rcx+NEBO_REFINEMENT_CERT_VALUE],rsi
 mov rax,[rdi+NEBO_REFINEMENT_DESC_PREDICATE_ID]
 mov [rcx+NEBO_REFINEMENT_CERT_PREDICATE_ID],rax
 mov [rcx+NEBO_REFINEMENT_CERT_SUBJECT_HASH],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REFINEMENT_STATUS_INVALID
 ret
.range: mov eax,NEBO_REFINEMENT_STATUS_RANGE
 ret

NEBOC_ABI_FUNCTION nebo_refinement_is
 ; descriptor, signed value -> bool; malformed descriptors are false
 test rdi,rdi
 jz .false
 cmp rsi,[rdi+NEBO_REFINEMENT_DESC_MIN]
 jl .false
 cmp rsi,[rdi+NEBO_REFINEMENT_DESC_MAX]
 jg .false
 mov eax,1
 ret
.false: xor eax,eax
 ret

NEBOC_ABI_FUNCTION nebo_refinement_assume
 ; explicit capability, proof id
 cmp rdi,NEBO_REFINEMENT_CAP_ASSUME_UNSAFE
 jne .denied
 test rsi,rsi
 jz .denied
 xor eax,eax
 ret
.denied: mov eax,NEBO_REFINEMENT_STATUS_ASSUMPTION
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
