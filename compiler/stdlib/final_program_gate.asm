; Authenticated bounded internal verification gate for LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/final_program_gate.inc"
section .text
NEBOC_ABI_FUNCTION neboc_final_program_gate_validate
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 mov qword [rdi+FPG_DIAG],0
 mov qword [rdi+FPG_RESULT],0
 mov rax,[rdi+FPG_GROUP]
 cmp rax,FPG_FIRST_GROUP
 jb .type
 cmp rax,FPG_LAST_GROUP
 ja .type
 sub eax,FPG_FIRST_GROUP
 mov ecx,eax
 mov eax,1
 shl rax,cl
 mov rdx,[rdi+FPG_PHASE_MASK]
 test rdx,~FPG_ALL_PHASES
 jnz .type
 test rdx,rax
 jz .type
 mov rax,[rdi+FPG_NEGATIVE_COUNT]
 test rax,rax
 jz .type
 cmp rax,FPG_MAX_NEGATIVES
 ja .runtime
 mov rax,[rdi+FPG_RESOURCE_LIMIT]
 test rax,rax
 jz .runtime
 cmp rax,FPG_MAX_RESOURCE
 ja .runtime
 cmp [rdi+FPG_RESOURCE_USED],rax
 ja .runtime
 cmp qword [rdi+FPG_IDENTITY_HASH],0
 je .security
 cmp qword [rdi+FPG_LINEAGE_HASH],0
 je .security
 cmp qword [rdi+FPG_EXTERNAL_MUTATIONS],0
 jne .security
 cmp qword [rdi+FPG_PRIVACY_FLAGS],1
 jne .security
 mov rax,[rdi+FPG_DETERMINISM_RUNS]
 cmp rax,2
 jb .runtime
 cmp rax,FPG_MAX_REPLAYS
 ja .runtime
 cmp qword [rdi+FPG_RESERVED],0
 jne .security
 mov rax,FPG_SEAL_MAGIC
 xor edx,edx
 mov ecx,10
.seal:
 xor rax,[rdi+rdx*8]
 inc edx
 loop .seal
 cmp rax,[rdi+FPG_SEAL]
 jne .security
 mov rax,[rdi+FPG_GROUP]
 mov [rdi+FPG_RESULT],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.type: mov eax,1
 jmp .fail
.runtime: mov eax,2
 jmp .fail
.security: mov eax,3
.fail:
 mov [rdi+FPG_DIAG],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
