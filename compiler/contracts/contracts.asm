; REDE-E-PROTOCOLOS-F01 bounded contract descriptor, static decision and runtime fallback.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/contracts/contracts.inc"
section .text
NEBOC_ABI_FUNCTION nebo_contracts_contract_validate
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBO_CONTRACT_DESC_KIND]
 test rax,rax
 jz .kind
 cmp rax,NEBO_CONTRACT_KIND_INVARIANT
 ja .kind
 cmp qword [rdi+NEBO_CONTRACT_DESC_MODIFIES_COUNT],NEBO_CONTRACT_MAX_MODIFIES
 ja .limit
 cmp rax,NEBO_CONTRACT_KIND_INVARIANT
 jne .policy
 cmp qword [rdi+NEBO_CONTRACT_DESC_DECREASES],0
 je .measure
.policy:
 mov rax,[rdi+NEBO_CONTRACT_DESC_POLICY]
 cmp rax,NEBO_CONTRACT_POLICY_REJECT_UNKNOWN
 je .ok
 cmp rax,NEBO_CONTRACT_POLICY_RUNTIME
 je .ok
 jmp .invalid
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_CONTRACT_STATUS_INVALID
 ret
.kind: mov eax,NEBO_CONTRACT_STATUS_KIND
 ret
.limit: mov eax,NEBO_CONTRACT_STATUS_LIMIT
 ret
.measure: mov eax,NEBO_CONTRACT_STATUS_MEASURE
 ret

NEBOC_ABI_FUNCTION nebo_contract_decide
 ; descriptor, proof state, runtime condition, explain output
 test rcx,rcx
 jz .invalid
 mov qword [rcx+NEBO_CONTRACT_EXPLAIN_KIND],0
 mov qword [rcx+NEBO_CONTRACT_EXPLAIN_ACTION],0
 mov qword [rcx+NEBO_CONTRACT_EXPLAIN_SPAN],0
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBO_CONTRACT_DESC_KIND]
 mov [rcx+NEBO_CONTRACT_EXPLAIN_KIND],rax
 mov rax,[rdi+NEBO_CONTRACT_DESC_SPAN]
 mov [rcx+NEBO_CONTRACT_EXPLAIN_SPAN],rax
 cmp rsi,NEBO_CONTRACT_PROOF_PROVED
 je .proved
 cmp rsi,NEBO_CONTRACT_PROOF_UNKNOWN
 jne .invalid
 cmp qword [rdi+NEBO_CONTRACT_DESC_POLICY],NEBO_CONTRACT_POLICY_RUNTIME
 jne .unproved
 test rdx,rdx
 jz .violation
 mov qword [rcx+NEBO_CONTRACT_EXPLAIN_ACTION],NEBO_CONTRACT_ACTION_RUNTIME_CHECK
 xor eax,eax
 ret
.proved:
 mov qword [rcx+NEBO_CONTRACT_EXPLAIN_ACTION],NEBO_CONTRACT_ACTION_PROVED
 xor eax,eax
 ret
.invalid: mov eax,NEBO_CONTRACT_STATUS_INVALID
 ret
.unproved: mov eax,NEBO_CONTRACT_STATUS_UNPROVED
 ret
.violation: mov eax,NEBO_CONTRACT_STATUS_VIOLATION
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
