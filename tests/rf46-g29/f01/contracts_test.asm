bits 64
default rel
%include "compiler/contracts/contracts.inc"
extern nebo_contracts_contract_validate,nebo_contract_decide
section .data
contract:
 dq NEBO_CONTRACT_KIND_REQUIRES,2,0,NEBO_CONTRACT_POLICY_RUNTIME,77
section .bss
explain resb NEBO_CONTRACT_EXPLAIN_SIZE
section .text
global _start
_start:
 lea rdi,[contract]
 call nebo_contracts_contract_validate
 test eax,eax
 jnz fail
 lea rdi,[contract]
 mov esi,NEBO_CONTRACT_PROOF_UNKNOWN
 mov edx,1
 lea rcx,[explain]
 call nebo_contract_decide
 test eax,eax
 jnz fail
 cmp qword [explain+NEBO_CONTRACT_EXPLAIN_ACTION],NEBO_CONTRACT_ACTION_RUNTIME_CHECK
 jne fail
 cmp qword [explain+NEBO_CONTRACT_EXPLAIN_SPAN],77
 jne fail
 lea rdi,[contract]
 mov esi,NEBO_CONTRACT_PROOF_UNKNOWN
 xor edx,edx
 lea rcx,[explain]
 call nebo_contract_decide
 cmp eax,NEBO_CONTRACT_STATUS_VIOLATION
 jne fail
 mov qword [contract+NEBO_CONTRACT_DESC_MODIFIES_COUNT],65
 lea rdi,[contract]
 call nebo_contracts_contract_validate
 cmp eax,NEBO_CONTRACT_STATUS_LIMIT
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
