; Shared local secure-envelope validator. It performs no tool/plugin action.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/secure_local_profile.inc"
section .text
NEBOC_ABI_FUNCTION neboc_secure_local_profile_validate
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 mov qword [rdi+SLP_DIAG],0
 mov qword [rdi+SLP_RESULT],0
 mov rax,[rdi+SLP_MODE]
 cmp rax,SLP_MODE_TOOL_STUB
 jb .type
 cmp rax,SLP_MODE_PLUGIN_DESCRIPTOR
 ja .type
 cmp qword [rdi+SLP_IDENTITY_HASH],0
 je .security
 cmp qword [rdi+SLP_SCHEMA_HASH],0
 je .security
 mov rax,[rdi+SLP_CAPABILITY_MASK]
 test rax,~7
 jnz .security
 mov rax,[rdi+SLP_BUDGET_LIMIT]
 test rax,rax
 jz .runtime
 cmp rax,SLP_MAX_BUDGET
 ja .runtime
 cmp [rdi+SLP_BUDGET_USED],rax
 ja .runtime
 mov rax,[rdi+SLP_APPROVAL_REQUIRED]
 cmp rax,1
 ja .type
 test rax,rax
 jz .approval_done
 cmp qword [rdi+SLP_APPROVAL_GRANTED],1
 jne .security
.approval_done:
 cmp qword [rdi+SLP_PRIVACY_FLAGS],SLP_REQUIRED_PRIVACY
 jne .security
 cmp qword [rdi+SLP_LINEAGE_HASH],0
 je .security
 cmp qword [rdi+SLP_OWNERSHIP_FLAGS],SLP_REQUIRED_OWNERSHIP
 jne .security
 cmp qword [rdi+SLP_ISOLATION_FLAGS],SLP_REQUIRED_ISOLATION
 jne .security
 cmp qword [rdi+SLP_EXTERNAL_ACTIONS],0
 jne .security
 mov rax,SLP_SEAL_MAGIC
 xor edx,edx
 mov ecx,13
.seal: xor rax,[rdi+rdx*8]
 inc edx
 loop .seal
 cmp rax,[rdi+SLP_SEAL]
 jne .security
 mov rax,[rdi+SLP_MODE]
 mov [rdi+SLP_RESULT],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.type: mov eax,1
 jmp .fail
.runtime: mov eax,2
 jmp .fail
.security: mov eax,3
.fail: mov [rdi+SLP_DIAG],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
