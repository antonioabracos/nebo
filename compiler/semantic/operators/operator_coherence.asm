; Bounded coherence/orphan validation for one operator implementation table.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
; coherence_validate(implementations, count) -> status, EDX diagnostic,
; R8=index of the first invalid or colliding implementation.
NEBOC_ABI_FUNCTION neboc_operator_coherence_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .invalid_argument
 test r13,r13
 jz .invalid_argument
 cmp r13,NEBOC_OPERATOR_MAX_CANDIDATES
 ja .limit
 xor r14d,r14d
.outer:
 cmp r14,r13
 jae .valid
 mov r15,r14
 imul r15,NEBOC_OPERATOR_IMPL_SIZE
 add r15,r12
 mov rax,[r15+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET]
 test rax,rax
 jz .coherence_error
 cmp rax,NEBOC_OPERATOR_PROTOCOL_COUNT
 ja .coherence_error
 cmp qword [r15+NEBOC_OPERATOR_IMPL_LEFT_TYPE_OFFSET],0
 je .coherence_error
 cmp qword [r15+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET],0
 je .coherence_error
 cmp qword [r15+NEBOC_OPERATOR_IMPL_OWNER_TYPE_OFFSET],0
 je .coherence_error
 cmp qword [r15+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET],0
 je .coherence_error
 cmp qword [r15+NEBOC_OPERATOR_IMPL_CONSTRAINTS_OFFSET],NEBOC_OPERATOR_MAX_CONSTRAINTS
 ja .limit_at_current
 cmp qword [r15+NEBOC_OPERATOR_IMPL_SPECIFICITY_OFFSET],0
 je .coherence_error
 mov rax,[r15+NEBOC_OPERATOR_IMPL_EFFECTS_OFFSET]
 test rax,rax
 jz .coherence_error
 test rax,~NEBOC_OPERATOR_EFFECT_ALL
 jnz .coherence_error
 mov rax,[r15+NEBOC_OPERATOR_IMPL_REQUIRED_CAPABILITIES_OFFSET]
 test rax,rax
 jz .coherence_error
 test rax,~NEBOC_OPERATOR_CAPABILITY_ALL
 jnz .coherence_error

 mov rax,[r15+NEBOC_OPERATOR_IMPL_FLAGS_OFFSET]
 mov rdx,rax
 and rdx,NEBOC_OPERATOR_IMPL_FLAG_ACTIVE|NEBOC_OPERATOR_IMPL_FLAG_INACTIVE
 cmp rdx,NEBOC_OPERATOR_IMPL_FLAG_ACTIVE
 je .state_ok
 cmp rdx,NEBOC_OPERATOR_IMPL_FLAG_INACTIVE
 jne .coherence_error
.state_ok:
 mov rdx,rax
 and rdx,NEBOC_OPERATOR_IMPL_FLAG_BUILTIN|NEBOC_OPERATOR_IMPL_FLAG_USER
 cmp rdx,NEBOC_OPERATOR_IMPL_FLAG_BUILTIN
 je .owner_ok
 cmp rdx,NEBOC_OPERATOR_IMPL_FLAG_USER
 jne .coherence_error
 mov rdx,[r15+NEBOC_OPERATOR_IMPL_OWNER_TYPE_OFFSET]
 cmp rdx,[r15+NEBOC_OPERATOR_IMPL_LEFT_TYPE_OFFSET]
 je .owner_ok
 cmp rdx,[r15+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET]
 jne .coherence_error
.owner_ok:
 test rax,NEBOC_OPERATOR_IMPL_FLAG_COHERENT
 jz .coherence_error
 test rax,NEBOC_OPERATOR_IMPL_FLAG_EXACT_TYPES
 jz .coherence_error

 mov rax,[r15+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET]
 cmp rax,NEBOC_OPERATOR_PROTOCOL_NEGATE
 je .unary
 cmp rax,NEBOC_OPERATOR_PROTOCOL_LOGICAL_NOT
 je .unary
 cmp qword [r15+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET],0
 je .coherence_error
 jmp .pair_scan
.unary:
 cmp qword [r15+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET],0
 jne .coherence_error

.pair_scan:
 lea rbx,[r14+1]
.inner:
 cmp rbx,r13
 jae .next_outer
 mov rax,rbx
 imul rax,NEBOC_OPERATOR_IMPL_SIZE
 add rax,r12
 mov rdx,[r15+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET]
 cmp rdx,[rax+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET]
 je .collision_at_inner
 mov rdx,[r15+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET]
 cmp rdx,[rax+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET]
 jne .next_inner
 mov rdx,[r15+NEBOC_OPERATOR_IMPL_LEFT_TYPE_OFFSET]
 cmp rdx,[rax+NEBOC_OPERATOR_IMPL_LEFT_TYPE_OFFSET]
 jne .next_inner
 mov rdx,[r15+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET]
 cmp rdx,[rax+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET]
 je .collision_at_inner
.next_inner:
 inc rbx
 jmp .inner
.next_outer:
 inc r14
 jmp .outer

.valid:
 xor eax,eax
 xor edx,edx
 xor r8d,r8d
 jmp .done
.collision_at_inner:
 mov r8,rbx
 jmp .coherence_status
.coherence_error:
 mov r8,r14
.coherence_status:
 mov edx,NEBOC_OPERATOR_DIAG_COHERENCE_VIOLATION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit_at_current:
 mov r8,r14
.limit:
 mov edx,NEBOC_OPERATOR_DIAG_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_argument:
 xor edx,edx
 xor r8d,r8d
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
