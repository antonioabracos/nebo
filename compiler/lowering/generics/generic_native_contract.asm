; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF004 scalar-generic native call/return plan
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/semantic/generics/generic_semantic.inc"
%include "compiler/lowering/generics/generic_ir_contract.inc"
%include "compiler/lowering/generics/generic_native_contract.inc"

section .text
NEBOC_ABI_FUNCTION neboc_generic_native_plan
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 lea rdi,[r12+NEBOC_NATIVE_HELPER_ID_OFFSET]
 mov ecx,7
 xor eax,eax
 rep stosq
 cmp qword [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 jne .unsupported_target
 cmp qword [r12+NEBOC_NATIVE_IR_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_IR_REQUIRED_FLAGS
 jne .invariant
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_TYPE_ID_OFFSET]
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 je .float
 cmp qword [r12+NEBOC_NATIVE_IR_ABI_CLASS_OFFSET],NEBOC_ABI_CLASS_INTEGER
 jne .invariant
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 je .bool
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 je .int
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 jne .invariant
 mov eax,NEBOC_NATIVE_HELPER_CHAR
 jmp .integer_plan
.bool:
 mov eax,NEBOC_NATIVE_HELPER_BOOL
 jmp .integer_plan
.int:
 mov eax,NEBOC_NATIVE_HELPER_INT
.integer_plan:
 mov [r12+NEBOC_NATIVE_HELPER_ID_OFFSET],rax
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_RDI
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_RETURN_REGISTER_OFFSET],neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_RAX
 jmp .finish
.float:
 cmp qword [r12+NEBOC_NATIVE_IR_ABI_CLASS_OFFSET],NEBOC_ABI_CLASS_SSE
 jne .invariant
 mov qword [r12+NEBOC_NATIVE_HELPER_ID_OFFSET],NEBOC_NATIVE_HELPER_FLOAT
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_XMM0
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_RETURN_REGISTER_OFFSET],neboc_generics_constraints_overload_e_dispatch_NATIVE_REGISTER_XMM0
.finish:
 mov qword [r12+NEBOC_NATIVE_VALUE_WIDTH_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_STACK_BYTES_OFFSET],0
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_NATIVE_REQUIRED_FLAGS
 xor eax,eax
 jmp .done
.unsupported_target:
 mov eax,NEBOC_DIAG_UNSUPPORTED_TARGET
 jmp .error
.invariant:
 mov eax,NEBOC_DIAG_NATIVE_ABI_INVARIANT
.error:
 mov [r12+neboc_generics_constraints_overload_e_dispatch_NATIVE_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
