bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/programmer_type_semantic.inc"
%include "compiler/lowering/aggregates/programmer_type_ir.inc"
section .text
NEBOC_ABI_FUNCTION neboc_programmer_type_ir_lower
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_IR_HIR_OPCODE_OFFSET],0
 mov qword [r12+NEBOC_IR_LIR_OPCODE_OFFSET],0
 mov qword [r12+NEBOC_IR_ALLOCATION_OFFSET],0
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_DIAGNOSTIC_OFFSET],0
 mov rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_SEMANTIC_PTR_OFFSET]
 test rax,rax
 jz .invariant
 mov rdx,[rax+neboc_structs_enums_variants_e_tipos_do_programador_SEM_HASH_OFFSET]
 cmp rdx,[r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_SEMANTIC_HASH_OFFSET]
 jne .invariant
 mov rdx,[rax+neboc_structs_enums_variants_e_tipos_do_programador_SEM_RESULT_TYPE_OFFSET]
 cmp rdx,[r12+NEBOC_IR_NOMINAL_TYPE_OFFSET]
 jne .invariant
 cmp qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_TARGET_OFFSET],neboc_structs_enums_variants_e_tipos_do_programador_IR_TARGET_X86_64_SYSV
 jne .target
 mov rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET]
 cmp rax,NEBOC_IR_PRODUCT
 je .product
 cmp rax,NEBOC_IR_SUM
 je .sum
 cmp rax,NEBOC_IR_FIELD_ACCESS
 je .field
 jmp .invariant
.product:
 mov qword [r12+NEBOC_IR_HIR_OPCODE_OFFSET],NEBOC_HIR_PRODUCT_CONSTRUCT
 mov qword [r12+NEBOC_IR_LIR_OPCODE_OFFSET],NEBOC_LIR_AGGREGATE_INIT
 jmp .finish
.sum:
 mov qword [r12+NEBOC_IR_HIR_OPCODE_OFFSET],NEBOC_HIR_SUM_CONSTRUCT
 mov qword [r12+NEBOC_IR_LIR_OPCODE_OFFSET],NEBOC_LIR_TAGGED_INIT
 jmp .finish
.field:
 cmp qword [r12+NEBOC_IR_MEMBER_INDEX_OFFSET],8
 jae .invariant
 mov qword [r12+NEBOC_IR_HIR_OPCODE_OFFSET],NEBOC_HIR_FIELD_PROJECT
 mov qword [r12+NEBOC_IR_LIR_OPCODE_OFFSET],NEBOC_LIR_FIELD_LOAD
.finish:
 mov rax,[r12+NEBOC_IR_NOMINAL_TYPE_OFFSET]
 rol rax,13
 xor rax,[r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET]
 xor rax,[r12+NEBOC_IR_MEMBER_INDEX_OFFSET]
 mov [r12+NEBOC_IR_MANGLE_OFFSET],rax
 mov rdx,1469598103934665603
 mov rcx,1099511628211
 %assign off 0
 %rep 10
 xor rdx,[r12+off]
 imul rdx,rcx
 %assign off off+8
 %endrep
 mov [r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_HASH_OFFSET],rdx
 xor eax,eax
 jmp .done
.invariant:
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_DIAGNOSTIC_OFFSET],1
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.target:
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_IR_DIAGNOSTIC_OFFSET],2
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
