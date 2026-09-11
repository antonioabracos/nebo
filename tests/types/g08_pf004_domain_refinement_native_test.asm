; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF004 native plan and runtime conformance
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/domain/domain_refinement_native_contract.inc"
%include "runtime/domain/positive_int_runtime.inc"
extern neboc_domain_refinement_native_plan
extern nebo_positive_int_try
extern nebo_positive_int_is_ok
extern nebo_positive_int_is_err
extern nebo_positive_int_unwrap_or
extern neboc_host_process_exit

section .data align=8
success_values: dq 1,2,7,42,9223372036854775807
failure_values: dq 0,-1,-2,-9223372036854775808

section .bss align=16
ir: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_REQUEST_SIZE
native: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REQUEST_SIZE

section .text
global _start
_start:
 mov r13d,1
 lea r14,[rel success_values]
 mov r15d,5
.success:
 mov rdi,[r14]
 call nebo_positive_int_try
 test rax,rax
 jnz .fail
 cmp rdx,[r14]
 jne .fail
 add r14,8
 inc r13d
 dec r15d
 jnz .success
 lea r14,[rel failure_values]
 mov r15d,4
.failure:
 mov rdi,[r14]
 call nebo_positive_int_try
 cmp rax,1
 jne .fail
 cmp rdx,1
 jne .fail
 add r14,8
 inc r13d
 dec r15d
 jnz .failure
 ; predicates, four cases
 xor edi,edi
 call nebo_positive_int_is_ok
 cmp eax,1
 jne .fail
 inc r13d
 mov edi,1
 call nebo_positive_int_is_ok
 test eax,eax
 jnz .fail
 inc r13d
 xor edi,edi
 call nebo_positive_int_is_err
 test eax,eax
 jnz .fail
 inc r13d
 mov edi,1
 call nebo_positive_int_is_err
 cmp eax,1
 jne .fail
 inc r13d
 ; unwrap success and failure
 xor edi,edi
 mov esi,7
 mov edx,9
 call nebo_positive_int_unwrap_or
 cmp eax,7
 jne .fail
 inc r13d
 mov edi,1
 mov esi,1
 mov edx,9
 call nebo_positive_int_unwrap_or
 cmp eax,9
 jne .fail
 inc r13d
 ; fabricate a valid closed PF003 IR record
 lea rdi,[rel ir]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_HASH_OFFSET],808
 ; valid TRY plan
 lea rdi,[rel native]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel ir]
 mov [rel native+NEBOC_NATIVE_IR_PTR_OFFSET],rax
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_IR_HASH_OFFSET],808
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_TARGET_OFFSET],1
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET],1
 mov qword [rel native+NEBOC_NATIVE_INPUT_TYPE_OFFSET],3
 mov qword [rel native+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],268435468
 lea rdi,[rel native]
 call neboc_domain_refinement_native_plan
 test eax,eax
 jnz .fail
 cmp qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_SIZE_OFFSET],16
 jne .fail
 cmp qword [rel native+NEBOC_NATIVE_HELPER_OFFSET],1
 jne .fail
 cmp qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_FLAGS_OFFSET],63
 jne .fail
 inc r13d
 ; valid predicate plan
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET],2
 mov qword [rel native+NEBOC_NATIVE_INPUT_TYPE_OFFSET],268435468
 mov qword [rel native+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],2
 lea rdi,[rel native]
 call neboc_domain_refinement_native_plan
 test eax,eax
 jnz .fail
 cmp qword [rel native+NEBOC_NATIVE_HELPER_OFFSET],2
 jne .fail
 inc r13d
 ; valid unwrap plan
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET],4
 mov qword [rel native+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],12
 mov qword [rel native+NEBOC_NATIVE_PAYLOAD_OFFSET],9
 lea rdi,[rel native]
 call neboc_domain_refinement_native_plan
 test eax,eax
 jnz .fail
 cmp qword [rel native+NEBOC_NATIVE_HELPER_OFFSET],4
 jne .fail
 inc r13d
 ; unsupported target
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_TARGET_OFFSET],2
 lea rdi,[rel native]
 call neboc_domain_refinement_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_DIAGNOSTIC_OFFSET],3
 jne .fail
 inc r13d
 ; unsupported op
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_TARGET_OFFSET],1
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET],99
 lea rdi,[rel native]
 call neboc_domain_refinement_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_DIAGNOSTIC_OFFSET],4
 jne .fail
 inc r13d
 ; hash mismatch
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET],1
 mov qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_IR_HASH_OFFSET],809
 lea rdi,[rel native]
 call neboc_domain_refinement_native_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_DIAGNOSTIC_OFFSET],2
 jne .fail
 inc r13d
 ; null guard is final case
 xor edi,edi
 call neboc_domain_refinement_native_plan
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
