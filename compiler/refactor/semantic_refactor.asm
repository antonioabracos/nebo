; SEMANTIC-REFACTOR-F07 semantic refactoring over resolved identities and F06 fix plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/semantic_refactor.inc"

extern neboc_fix_plan_validate_current_sources
extern neboc_fix_plan_preview
extern neboc_fix_plan_apply

section .text

refactor_prepare_common:
 ; rdi=request, ecx=operation, edx=required proof mask, r8=argument required.
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_REFACTOR_REQUEST_SUBJECT_OFFSET],0
 je .invalid
 test r8,r8
 jz .argument_ok
 cmp qword [rdi+NEBOC_REFACTOR_REQUEST_ARGUMENT_OFFSET],0
 je .invalid
.argument_ok:
 mov rax,[rdi+NEBOC_REFACTOR_REQUEST_SNAPSHOT_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_REFACTOR_REQUEST_CURRENT_SNAPSHOT_OFFSET]
 jne .stale
 mov rax,[rdi+NEBOC_REFACTOR_REQUEST_PROOFS_OFFSET]
 and rax,rdx
 cmp rax,rdx
 jne .unsafe
 cmp qword [rdi+NEBOC_REFACTOR_REQUEST_FIX_PLAN_OFFSET],0
 je .invalid
 mov r9,[rdi+NEBOC_REFACTOR_REQUEST_AFFECTED_COUNT_OFFSET]
 test r9,r9
 jz .invalid
 cmp r9,NEBOC_REFACTOR_MAX_FILES
 ja .limit
 mov r10,[rdi+NEBOC_REFACTOR_REQUEST_AFFECTED_FILES_OFFSET]
 test r10,r10
 jz .invalid
 xor eax,eax
 xor r8d,r8d
.files:
 mov rdx,[r10+rax*8]
 test rdx,rdx
 jz .invalid
 cmp rdx,r8
 jbe .invalid
 mov r8,rdx
 inc rax
 cmp rax,r9
 jb .files
 mov rax,[rdi+NEBOC_REFACTOR_REQUEST_API_IMPACT_OFFSET]
 cmp rax,NEBOC_REFACTOR_API_COMPATIBLE
 jb .invalid
 cmp rax,NEBOC_REFACTOR_API_BREAKING
 ja .invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rcx
 mov r14,rdx
 mov rdi,[r12+NEBOC_REFACTOR_REQUEST_FIX_PLAN_OFFSET]
 call neboc_fix_plan_validate_current_sources
 test eax,eax
 jnz .prepared_done
 mov [r12+NEBOC_REFACTOR_REQUEST_OPERATION_OFFSET],r13
 mov qword [r12+NEBOC_REFACTOR_REQUEST_PREPARED_OFFSET],1
 mov qword [r12+NEBOC_REFACTOR_REQUEST_AFFECTED_QUERIED_OFFSET],0
 mov qword [r12+NEBOC_REFACTOR_REQUEST_IMPACT_QUERIED_OFFSET],0
 mov qword [r12+NEBOC_REFACTOR_REQUEST_APPLIED_OFFSET],0
.prepared_done:
 pop r14
 pop r13
 pop r12
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.stale:
.unsafe:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro REFACTOR_OPERATION 4
NEBOC_ABI_FUNCTION %1
 mov ecx,%2
 mov edx,%3
 mov r8d,%4
 jmp refactor_prepare_common
%endmacro

REFACTOR_OPERATION neboc_refactor_rename,NEBOC_REFACTOR_RENAME,(NEBOC_REFACTOR_PROOF_IDENTITY|NEBOC_REFACTOR_PROOF_SCOPE|NEBOC_REFACTOR_PROOF_ATTACHMENTS),1
REFACTOR_OPERATION neboc_refactor_extract_function,NEBOC_REFACTOR_EXTRACT_FUNCTION,(NEBOC_REFACTOR_PROOF_SCOPE|NEBOC_REFACTOR_PROOF_EFFECTS|NEBOC_REFACTOR_PROOF_OWNERSHIP|NEBOC_REFACTOR_PROOF_EVALUATION_ORDER|NEBOC_REFACTOR_PROOF_CAPTURES|NEBOC_REFACTOR_PROOF_CLEANUP|NEBOC_REFACTOR_PROOF_ATTACHMENTS),1
REFACTOR_OPERATION neboc_refactor_inline_function,NEBOC_REFACTOR_INLINE_FUNCTION,(NEBOC_REFACTOR_PROOF_IDENTITY|NEBOC_REFACTOR_PROOF_EFFECTS|NEBOC_REFACTOR_PROOF_OWNERSHIP|NEBOC_REFACTOR_PROOF_EVALUATION_ORDER|NEBOC_REFACTOR_PROOF_CAPTURES|NEBOC_REFACTOR_PROOF_CLEANUP),0
REFACTOR_OPERATION neboc_refactor_extract_binding,NEBOC_REFACTOR_EXTRACT_BINDING,(NEBOC_REFACTOR_PROOF_SCOPE|NEBOC_REFACTOR_PROOF_EFFECTS|NEBOC_REFACTOR_PROOF_OWNERSHIP|NEBOC_REFACTOR_PROOF_EVALUATION_ORDER|NEBOC_REFACTOR_PROOF_CLEANUP),1
REFACTOR_OPERATION neboc_refactor_move_item,NEBOC_REFACTOR_MOVE_ITEM,(NEBOC_REFACTOR_PROOF_IDENTITY|NEBOC_REFACTOR_PROOF_VISIBILITY|NEBOC_REFACTOR_PROOF_NO_CYCLE|NEBOC_REFACTOR_PROOF_ATTACHMENTS),1
REFACTOR_OPERATION neboc_refactor_change_signature,NEBOC_REFACTOR_CHANGE_SIGNATURE,(NEBOC_REFACTOR_PROOF_IDENTITY|NEBOC_REFACTOR_PROOF_EFFECTS|NEBOC_REFACTOR_PROOF_OWNERSHIP|NEBOC_REFACTOR_PROOF_OVERLOADS),1
REFACTOR_OPERATION neboc_refactor_organize_imports,NEBOC_REFACTOR_ORGANIZE_IMPORTS,(NEBOC_REFACTOR_PROOF_IDENTITY|NEBOC_REFACTOR_PROOF_IMPORT_EFFECTS|NEBOC_REFACTOR_PROOF_NO_CYCLE),0
REFACTOR_OPERATION neboc_refactor_convert_copy_to_borrow,NEBOC_REFACTOR_COPY_TO_BORROW,(NEBOC_REFACTOR_PROOF_IDENTITY|NEBOC_REFACTOR_PROOF_OWNERSHIP|NEBOC_REFACTOR_PROOF_LIFETIME),0
REFACTOR_OPERATION neboc_refactor_convert_if_to_match,NEBOC_REFACTOR_IF_TO_MATCH,(NEBOC_REFACTOR_PROOF_SCOPE|NEBOC_REFACTOR_PROOF_EFFECTS|NEBOC_REFACTOR_PROOF_EVALUATION_ORDER|NEBOC_REFACTOR_PROOF_CLEANUP|NEBOC_REFACTOR_PROOF_COVERAGE),0

NEBOC_ABI_FUNCTION neboc_refactor_affected_files
 ; rdi=prepared request, rsi=bounded output descriptor.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_REFACTOR_REQUEST_PREPARED_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_REFACTOR_REQUEST_AFFECTED_COUNT_OFFSET]
 cmp rax,[rsi+NEBOC_REFACTOR_FILES_CAPACITY_OFFSET]
 ja .limit
 mov rdx,[rsi+NEBOC_REFACTOR_FILES_ITEMS_OFFSET]
 test rdx,rdx
 jz .invalid
 mov r9,rdi
 mov r8,rsi
 mov rcx,rax
 mov rsi,[r9+NEBOC_REFACTOR_REQUEST_AFFECTED_FILES_OFFSET]
 mov rdi,rdx
 rep movsq
 mov [r8+NEBOC_REFACTOR_FILES_COUNT_OFFSET],rax
 mov qword [r9+NEBOC_REFACTOR_REQUEST_AFFECTED_QUERIED_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_refactor_public_api_impact
 ; rdi=prepared request, rsi=qword output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_REFACTOR_REQUEST_PREPARED_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_REFACTOR_REQUEST_API_IMPACT_OFFSET]
 mov [rsi],rax
 mov qword [rdi+NEBOC_REFACTOR_REQUEST_IMPACT_QUERIED_OFFSET],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_refactor
 ; rdi=request, rsi=mode (preview=0), rdx=preview, rcx=capability, r8=policy.
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_REFACTOR_REQUEST_PREPARED_OFFSET],1
 jne .invalid
 cmp rsi,NEBOC_REFACTOR_CLI_APPLY
 ja .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov rdi,[rbx+NEBOC_REFACTOR_REQUEST_FIX_PLAN_OFFSET]
 call neboc_fix_plan_validate_current_sources
 test eax,eax
 jnz .done
 cmp r12,NEBOC_REFACTOR_CLI_APPLY
 je .apply
 mov rdi,[rbx+NEBOC_REFACTOR_REQUEST_FIX_PLAN_OFFSET]
 mov rsi,r13
 call neboc_fix_plan_preview
 jmp .done
.apply:
 cmp qword [rbx+NEBOC_REFACTOR_REQUEST_AFFECTED_QUERIED_OFFSET],1
 jne .invalid_saved
 cmp qword [rbx+NEBOC_REFACTOR_REQUEST_IMPACT_QUERIED_OFFSET],1
 jne .invalid_saved
 cmp qword [rbx+NEBOC_REFACTOR_REQUEST_API_IMPACT_OFFSET],NEBOC_REFACTOR_API_BREAKING
 je .unsafe
 cmp r14,NEBOC_FIX_CAPABILITY_APPLY
 jne .invalid_saved
 cmp r15,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 jne .invalid_saved
 mov rdi,[rbx+NEBOC_REFACTOR_REQUEST_FIX_PLAN_OFFSET]
 mov rsi,r14
 mov rdx,r15
 call neboc_fix_plan_apply
 test eax,eax
 jnz .done
 mov qword [rbx+NEBOC_REFACTOR_REQUEST_APPLIED_OFFSET],1
 jmp .done
.unsafe:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
