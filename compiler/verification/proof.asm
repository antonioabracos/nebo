; REDE-E-PROTOCOLOS-F05 versioned proof objects bound to code/specification hashes.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/verification/proof.inc"
section .text
NEBOC_ABI_FUNCTION nebo_proof_verify
 ; proof, current subject hash, current specification hash
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_PROOF_FORMAT_VERSION],NEBO_PROOF_VERSION
 jne .version
 cmp qword [rdi+NEBO_PROOF_PROPERTY],0
 je .invalid
 cmp qword [rdi+NEBO_PROOF_EVIDENCE_HASH],0
 je .invalid
 cmp qword [rdi+NEBO_PROOF_ASSUMPTION_COUNT],NEBO_PROOF_MAX_ASSUMPTIONS
 ja .assumptions
 cmp [rdi+NEBO_PROOF_SUBJECT_HASH],rsi
 jne .changed
 cmp [rdi+NEBO_PROOF_SPEC_HASH],rdx
 jne .changed
 xor eax,eax
 ret
.invalid: mov eax,NEBO_PROOF_STATUS_INVALID
 ret
.version: mov eax,NEBO_PROOF_STATUS_VERSION
 ret
.changed: mov eax,NEBO_PROOF_STATUS_CHANGED
 ret
.assumptions: mov eax,NEBO_PROOF_STATUS_ASSUMPTIONS
 ret

NEBOC_ABI_FUNCTION nebo_proof_compose
 ; left, right, output; failure atomic
 test rdx,rdx
 jz .invalid_compose
 push rbx
 mov rbx,rdx
 mov rcx,NEBO_PROOF_SIZE/8
 xor eax,eax
 mov rdx,rbx
.clear:
 mov [rdx],rax
 add rdx,8
 loop .clear
 test rdi,rdi
 jz .invalid_pop
 test rsi,rsi
 jz .invalid_pop
 mov rax,[rdi+NEBO_PROOF_SUBJECT_HASH]
 cmp rax,[rsi+NEBO_PROOF_SUBJECT_HASH]
 jne .incompatible
 mov rax,[rdi+NEBO_PROOF_SPEC_HASH]
 cmp rax,[rsi+NEBO_PROOF_SPEC_HASH]
 jne .incompatible
 mov rax,[rdi+NEBO_PROOF_ASSUMPTION_MASK]
 or rax,[rsi+NEBO_PROOF_ASSUMPTION_MASK]
 mov [rbx+NEBO_PROOF_ASSUMPTION_MASK],rax
 popcnt rcx,rax
 cmp rcx,NEBO_PROOF_MAX_ASSUMPTIONS
 ja .assumptions_pop
 mov [rbx+NEBO_PROOF_ASSUMPTION_COUNT],rcx
 mov rax,[rdi+NEBO_PROOF_PROPERTY]
 xor rax,[rsi+NEBO_PROOF_PROPERTY]
 rol rax,17
 mov [rbx+NEBO_PROOF_PROPERTY],rax
 mov rax,[rdi+NEBO_PROOF_SUBJECT_HASH]
 mov [rbx+NEBO_PROOF_SUBJECT_HASH],rax
 mov rax,[rdi+NEBO_PROOF_SPEC_HASH]
 mov [rbx+NEBO_PROOF_SPEC_HASH],rax
 mov rax,[rdi+NEBO_PROOF_EVIDENCE_HASH]
 xor rax,[rsi+NEBO_PROOF_EVIDENCE_HASH]
 mov [rbx+NEBO_PROOF_EVIDENCE_HASH],rax
 mov qword [rbx+NEBO_PROOF_FORMAT_VERSION],NEBO_PROOF_VERSION
 xor eax,eax
 pop rbx
 ret
.invalid_pop: mov eax,NEBO_PROOF_STATUS_INVALID
 pop rbx
 ret
.incompatible: mov eax,NEBO_PROOF_STATUS_INCOMPATIBLE
 pop rbx
 ret
.assumptions_pop: mov eax,NEBO_PROOF_STATUS_ASSUMPTIONS
 pop rbx
 ret
.invalid_compose: mov eax,NEBO_PROOF_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
