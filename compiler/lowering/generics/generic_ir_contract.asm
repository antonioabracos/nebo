; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF003 explicit monomorphization IR invariants
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/semantic/generics/generic_semantic.inc"
%include "compiler/lowering/generics/generic_ir_contract.inc"

section .text

generics_constraints_overload_e_dispatch_ir_error:
 mov [rdi+neboc_generics_constraints_overload_e_dispatch_IR_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_generic_ir_lower
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+NEBOC_IR_INSTANCE_ID_OFFSET]
 mov ecx,5
 xor eax,eax
 rep stosq
 cmp qword [r12+NEBOC_IR_DECLARATION_ID_OFFSET],0
 je .invariant
 cmp qword [r12+NEBOC_IR_SEMANTIC_KEY_OFFSET],0
 je .invariant
 mov rax,[r12+NEBOC_IR_TYPE_ID_OFFSET]
 mov rbx,rax
 cmp rax,[r12+NEBOC_IR_RECEIVER_TYPE_OFFSET]
 jne .invariant
 cmp rax,[r12+NEBOC_IR_RETURN_TYPE_OFFSET]
 jne .invariant
 cmp qword [r12+NEBOC_IR_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 jne .target
 cmp rbx,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 je .sse
 cmp rbx,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 je .integer
 cmp rbx,neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 je .integer
 cmp rbx,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 jne .invariant
.integer:
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_IR_ABI_CLASS_OFFSET],NEBOC_ABI_CLASS_INTEGER
 jmp .identity
.sse:
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_IR_ABI_CLASS_OFFSET],NEBOC_ABI_CLASS_SSE
.identity:
 mov rax,[r12+NEBOC_IR_SEMANTIC_KEY_OFFSET]
 mov [r12+NEBOC_IR_INSTANCE_ID_OFFSET],rax
 mov r8,1099511628211
 xor rax,[r12+NEBOC_IR_TARGET_ID_OFFSET]
 imul rax,r8
 xor rax,rbx
 imul rax,r8
 test rax,rax
 jnz .hash_ready
 mov eax,1
.hash_ready:
 mov [r12+NEBOC_IR_SYMBOL_HASH_OFFSET],rax
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_IR_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_IR_REQUIRED_FLAGS
 xor eax,eax
 jmp .done
.invariant:
 mov esi,NEBOC_DIAG_MONOMORPHIZATION_INVARIANT
 jmp .error
.target:
 mov esi,NEBOC_DIAG_UNSUPPORTED_TARGET
.error:
 mov rdi,r12
 call generics_constraints_overload_e_dispatch_ir_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
