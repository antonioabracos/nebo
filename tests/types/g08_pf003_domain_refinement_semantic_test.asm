; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF003 semantic and IR invariant tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/domain_refinement_semantic.inc"
%include "compiler/lowering/domain/domain_refinement_ir_contract.inc"
extern neboc_domain_refinement_semantic_analyze
extern neboc_domain_refinement_ir_lower
extern neboc_host_process_exit

section .bss align=16
sem: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_REQUEST_SIZE
ir: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_REQUEST_SIZE

section .text
global _start
clear_sem:
 lea rdi,[rel sem]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_SOURCE_END_OFFSET],10
 ret
run_sem_ok:
 lea rdi,[rel sem]
 call neboc_domain_refinement_semantic_analyze
 test eax,eax
 ret
run_sem_error:
 lea rdi,[rel sem]
 call neboc_domain_refinement_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 ret
_start:
 mov r13d,1
 ; positive conversion
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],1
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],3
 mov qword [rel sem+NEBOC_SEM_RECEIVER_LITERAL_OFFSET],1
 mov qword [rel sem+NEBOC_SEM_RECEIVER_VALUE_OFFSET],7
 mov qword [rel sem+NEBOC_SEM_API_RESULT_TYPE_OFFSET],268435468
 mov qword [rel sem+NEBOC_SEM_API_TAG_OFFSET],0
 mov qword [rel sem+NEBOC_SEM_API_PAYLOAD_OFFSET],7
 call run_sem_ok
 jnz .fail
 cmp qword [rel sem+NEBOC_SEM_REFINED_VALUE_OFFSET],7
 jne .fail
 inc r13d
 ; error conversion
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],1
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],3
 mov qword [rel sem+NEBOC_SEM_RECEIVER_LITERAL_OFFSET],1
 mov qword [rel sem+NEBOC_SEM_RECEIVER_VALUE_OFFSET],0
 mov qword [rel sem+NEBOC_SEM_API_RESULT_TYPE_OFFSET],268435468
 mov qword [rel sem+NEBOC_SEM_API_TAG_OFFSET],1
 mov qword [rel sem+NEBOC_SEM_API_PAYLOAD_OFFSET],1
 call run_sem_ok
 jnz .fail
 cmp qword [rel sem+NEBOC_SEM_ERROR_PAYLOAD_OFFSET],1
 jne .fail
 inc r13d
 ; unwrap result
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],4
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],268435468
 mov qword [rel sem+NEBOC_SEM_API_RESULT_TYPE_OFFSET],12
 mov qword [rel sem+NEBOC_SEM_API_PAYLOAD_OFFSET],9
 call run_sem_ok
 jnz .fail
 cmp qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RESULT_TYPE_OFFSET],12
 jne .fail
 inc r13d
 ; predicate
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],2
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],268435468
 mov qword [rel sem+NEBOC_SEM_API_RESULT_TYPE_OFFSET],2
 mov qword [rel sem+NEBOC_SEM_API_PAYLOAD_OFFSET],1
 call run_sem_ok
 jnz .fail
 inc r13d
 ; receiver type error
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],1
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],9
 call run_sem_error
 jne .fail
 cmp qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAGNOSTIC_OFFSET],1
 jne .fail
 inc r13d
 ; literal required
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],1
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],3
 call run_sem_error
 jne .fail
 cmp qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAGNOSTIC_OFFSET],2
 jne .fail
 inc r13d
 ; span invariant
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_SOURCE_START_OFFSET],11
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_SOURCE_END_OFFSET],10
 call run_sem_error
 jne .fail
 cmp qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAGNOSTIC_OFFSET],4
 jne .fail
 inc r13d
 ; build a fresh valid semantic result for IR
 call clear_sem
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],1
 mov qword [rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],3
 mov qword [rel sem+NEBOC_SEM_RECEIVER_LITERAL_OFFSET],1
 mov qword [rel sem+NEBOC_SEM_RECEIVER_VALUE_OFFSET],7
 mov qword [rel sem+NEBOC_SEM_API_RESULT_TYPE_OFFSET],268435468
 mov qword [rel sem+NEBOC_SEM_API_PAYLOAD_OFFSET],7
 call run_sem_ok
 jnz .fail
 lea rdi,[rel ir]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_KIND_OFFSET],1
 lea rax,[rel sem]
 mov [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_SEMANTIC_PTR_OFFSET],rax
 mov rax,[rel sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_HASH_OFFSET]
 mov [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_SEMANTIC_HASH_OFFSET],rax
 mov qword [rel ir+NEBOC_IR_INPUT_TYPE_OFFSET],3
 mov qword [rel ir+NEBOC_IR_OUTPUT_TYPE_OFFSET],268435468
 mov qword [rel ir+NEBOC_IR_TAG_OFFSET],0
 mov qword [rel ir+NEBOC_IR_PAYLOAD_OFFSET],7
 mov qword [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_OFFSET],1
 lea rdi,[rel ir]
 call neboc_domain_refinement_ir_lower
 test eax,eax
 jnz .fail
 cmp qword [rel ir+NEBOC_IR_SLOT_SIZE_OFFSET],16
 jne .fail
 cmp qword [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_FLAGS_OFFSET],31
 jne .fail
 inc r13d
 ; unsupported target
 mov qword [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_OFFSET],2
 lea rdi,[rel ir]
 call neboc_domain_refinement_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_DIAGNOSTIC_OFFSET],5
 jne .fail
 inc r13d
 ; null guards
 xor edi,edi
 call neboc_domain_refinement_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 call neboc_domain_refinement_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
