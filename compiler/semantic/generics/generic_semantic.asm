; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF003 generic substitution and overload semantics
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/semantic/generics/generic_semantic.inc"

section .text

sem_scalar_allowed:
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 je .yes
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 je .yes
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 je .yes
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 je .yes
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret

sem_instance_key:
 mov rax,1469598103934665603
 mov r8,1099511628211
 xor rax,[rdi+NEBOC_SEM_DECLARATION_ID_OFFSET]
 imul rax,r8
 xor rax,[rdi+NEBOC_SEM_SUBSTITUTION_TYPE_OFFSET]
 imul rax,r8
 xor rax,[rdi+NEBOC_SEM_SELECTED_KIND_OFFSET]
 imul rax,r8
 test rax,rax
 jnz .store
 mov eax,1
.store:
 mov [rdi+NEBOC_SEM_INSTANCE_KEY_OFFSET],rax
 ret

generics_constraints_overload_e_dispatch_sem_error:
 mov [rdi+neboc_generics_constraints_overload_e_dispatch_SEM_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_generic_semantic_analyze
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+NEBOC_SEM_SELECTED_KIND_OFFSET]
 mov ecx,5
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_END_OFFSET]
 cmp rax,[r12+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_START_OFFSET]
 jb .span
 cmp qword [r12+NEBOC_SEM_DECLARATION_ID_OFFSET],0
 je .invalid
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_SEM_KIND_OFFSET]
 cmp rax,NEBOC_SEM_KIND_DECLARATION
 je .declaration
 cmp rax,NEBOC_SEM_KIND_CALL
 je .call
 jmp .invalid

.declaration:
 cmp qword [r12+neboc_generics_constraints_overload_e_dispatch_SEM_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 jne .receiver
 cmp qword [r12+NEBOC_SEM_BODY_RETURN_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 jne .return_type
 mov qword [r12+NEBOC_SEM_SELECTED_KIND_OFFSET],NEBOC_SELECTED_GENERIC
 mov qword [r12+NEBOC_SEM_SUBSTITUTION_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [r12+NEBOC_SEM_RANK_OFFSET],NEBOC_RANK_GENERIC
 jmp .success

.call:
 test qword [r12+neboc_generics_constraints_overload_e_dispatch_SEM_FLAGS_OFFSET],NEBOC_SEM_FLAG_REQUIRES_CONVERSION
 jnz .no_match
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_SEM_RECEIVER_TYPE_OFFSET]
 mov rbx,rax
 call sem_scalar_allowed
 test eax,eax
 jz .bound
 cmp qword [r12+NEBOC_SEM_BODY_RETURN_TYPE_OFFSET],0
 je .candidates
 cmp [r12+NEBOC_SEM_BODY_RETURN_TYPE_OFFSET],rbx
 jne .return_type
.candidates:
 mov rax,[r12+NEBOC_SEM_CONCRETE_CANDIDATES_OFFSET]
 cmp rax,1
 ja .ambiguous
 je .concrete
 mov rax,[r12+NEBOC_SEM_GENERIC_CANDIDATES_OFFSET]
 test rax,rax
 jz .no_match
 cmp rax,1
 jne .ambiguous
 mov rax,[r12+NEBOC_SEM_INSTANCE_LIMIT_OFFSET]
 test rax,rax
 jnz .have_limit
 mov eax,NEBOC_SEM_DEFAULT_INSTANCE_LIMIT
.have_limit:
 cmp [r12+NEBOC_SEM_INSTANCE_COUNT_OFFSET],rax
 jae .limit
 mov qword [r12+NEBOC_SEM_SELECTED_KIND_OFFSET],NEBOC_SELECTED_GENERIC
 mov [r12+NEBOC_SEM_SUBSTITUTION_TYPE_OFFSET],rbx
 mov qword [r12+NEBOC_SEM_RANK_OFFSET],NEBOC_RANK_GENERIC
 jmp .success
.concrete:
 mov qword [r12+NEBOC_SEM_SELECTED_KIND_OFFSET],NEBOC_SELECTED_CONCRETE
 mov [r12+NEBOC_SEM_SUBSTITUTION_TYPE_OFFSET],rbx
 mov qword [r12+NEBOC_SEM_RANK_OFFSET],NEBOC_RANK_CONCRETE

.success:
 mov rdi,r12
 call sem_instance_key
 xor eax,eax
 jmp .done
.receiver: mov esi,NEBOC_DIAG_RECEIVER_TYPE_PARAMETER_REQUIRED
 jmp .error
.return_type: mov esi,NEBOC_DIAG_RETURN_TYPE_PARAMETER_REQUIRED
 jmp .error
.bound: mov esi,NEBOC_DIAG_BOUND_NOT_SATISFIED
 jmp .error
.no_match: mov esi,NEBOC_DIAG_OVERLOAD_NO_MATCH
 jmp .error
.ambiguous: mov esi,NEBOC_DIAG_OVERLOAD_AMBIGUOUS
 jmp .error
.limit: mov esi,NEBOC_DIAG_INSTANTIATION_LIMIT
 jmp .error
.span: mov esi,neboc_generics_constraints_overload_e_dispatch_DIAG_SEMANTIC_SPAN_INVARIANT
.error:
 mov rdi,r12
 call generics_constraints_overload_e_dispatch_sem_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
