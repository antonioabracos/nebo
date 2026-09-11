; structs_enums_variants_e_tipos_do_programador-PF003 nominal product/sum semantic and explicit IR invariant tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/programmer_type_semantic.inc"
%include "compiler/lowering/aggregates/programmer_type_ir.inc"
extern neboc_programmer_type_semantic_analyze
extern neboc_programmer_type_ir_lower
extern neboc_host_process_exit

section .rodata align=8
; kind flags nominal concrete members recursion instances start end status diagnostic
semantic_cases:
 dq 1,15,0x101,0,2,0,1,0,10,NEBOC_STATUS_OK,0
 dq 2,15,0x102,0,2,0,1,0,10,NEBOC_STATUS_OK,0
 dq 4,15,0x103,0,1,0,1,0,10,NEBOC_STATUS_OK,0
 dq 3,15,0x104,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_BOOL,1,0,1,0,10,NEBOC_STATUS_OK,0
 dq 3,15,0x104,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_INT,1,0,2,0,10,NEBOC_STATUS_OK,0
 dq 3,15,0x104,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_FLOAT,1,0,3,0,10,NEBOC_STATUS_OK,0
 dq 3,15,0x104,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_CHAR,1,0,32,0,10,NEBOC_STATUS_OK,0
 dq 1,15,0,0,1,0,1,0,10,NEBOC_STATUS_INVALID_SOURCE,NEBOC_SEM_DIAG_NOMINAL_IDENTITY
 dq 5,15,0x105,0,1,0,1,0,10,NEBOC_STATUS_INVALID_SOURCE,NEBOC_SEM_DIAG_NOMINAL_IDENTITY
 dq 1,7,0x106,0,1,0,1,0,10,NEBOC_STATUS_INVALID_SOURCE,NEBOC_SEM_DIAG_UNRESOLVED_TYPE
 dq 3,15,0x107,neboc_structs_enums_variants_e_tipos_do_programador_TYPE_POSITIVE_INT,1,0,1,0,10,NEBOC_STATUS_INVALID_SOURCE,NEBOC_SEM_DIAG_CONSTRAINT
 dq 1,15,0x108,0,1,9,1,0,10,NEBOC_STATUS_INVALID_SOURCE,NEBOC_SEM_DIAG_RECURSION
 dq 1,15,0x109,0,1,0,33,0,10,NEBOC_STATUS_INVALID_SOURCE,NEBOC_SEM_DIAG_INSTANTIATION_LIMIT
 dq 1,15,0x10a,0,1,0,1,11,10,NEBOC_STATUS_INVALID_SOURCE,neboc_structs_enums_variants_e_tipos_do_programador_SEM_DIAG_SPAN_INVARIANT
semantic_case_count equ ($-semantic_cases)/(11*8)

section .bss align=16
sem: resb neboc_structs_enums_variants_e_tipos_do_programador_SEM_REQUEST_SIZE
ir: resb neboc_structs_enums_variants_e_tipos_do_programador_IR_REQUEST_SIZE

section .text
global _start
clear_sem:
 lea rdi,[rel sem]
 mov ecx,neboc_structs_enums_variants_e_tipos_do_programador_SEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ret
clear_ir:
 lea rdi,[rel ir]
 mov ecx,neboc_structs_enums_variants_e_tipos_do_programador_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_SEMANTIC_PTR_OFFSET],rax
 mov rax,[rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_HASH_OFFSET]
 mov [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_SEMANTIC_HASH_OFFSET],rax
 mov rax,[rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_RESULT_TYPE_OFFSET]
 mov [rel ir+NEBOC_IR_NOMINAL_TYPE_OFFSET],rax
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_TARGET_OFFSET],neboc_structs_enums_variants_e_tipos_do_programador_IR_TARGET_X86_64_SYSV
 ret
run_ir:
 lea rdi,[rel ir]
 call neboc_programmer_type_ir_lower
 ret
_start:
 mov r13d,1
 lea r14,[rel semantic_cases]
 mov r15d,semantic_case_count
.semantic_loop:
 call clear_sem
 xor ebx,ebx
.copy_inputs:
 mov rax,[r14+rbx*8]
 lea rdx,[rel sem]
 mov [rdx+rbx*8],rax
 inc ebx
 cmp ebx,9
 jb .copy_inputs
 lea rdi,[rel sem]
 call neboc_programmer_type_semantic_analyze
 cmp eax,[r14+9*8]
 jne .fail
 mov rax,[r14+10*8]
 cmp [rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_DIAGNOSTIC_OFFSET],rax
 jne .fail
 cmp qword [r14+9*8],NEBOC_STATUS_OK
 jne .semantic_error
 cmp qword [rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_RESULT_TYPE_OFFSET],0
 je .fail
.semantic_error:
 cmp qword [rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_HASH_OFFSET],0
 je .fail
 add r14,11*8
 inc r13d
 dec r15d
 jnz .semantic_loop

 ; Identical semantic requests are deterministic.
 call clear_sem
 mov qword [rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_KIND_OFFSET],NEBOC_SEM_KIND_PRODUCT
 mov qword [rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_FLAGS_OFFSET],neboc_structs_enums_variants_e_tipos_do_programador_SEM_FLAGS_REQUIRED
 mov qword [rel sem+NEBOC_SEM_NOMINAL_ID_OFFSET],0x201
 mov qword [rel sem+NEBOC_SEM_MEMBER_COUNT_OFFSET],2
 mov qword [rel sem+NEBOC_SEM_INSTANTIATION_COUNT_OFFSET],1
 mov qword [rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_SOURCE_END_OFFSET],10
 lea rdi,[rel sem]
 call neboc_programmer_type_semantic_analyze
 test eax,eax
 jnz .fail
 mov r12,[rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_HASH_OFFSET]
 lea rdi,[rel sem]
 call neboc_programmer_type_semantic_analyze
 test eax,eax
 jnz .fail
 cmp r12,[rel sem+neboc_structs_enums_variants_e_tipos_do_programador_SEM_HASH_OFFSET]
 jne .fail
 inc r13d

 ; Product construction lowering.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_PRODUCT
 call run_ir
 test eax,eax
 jnz .fail
 cmp qword [rel ir+NEBOC_IR_HIR_OPCODE_OFFSET],NEBOC_HIR_PRODUCT_CONSTRUCT
 jne .fail
 cmp qword [rel ir+NEBOC_IR_LIR_OPCODE_OFFSET],NEBOC_LIR_AGGREGATE_INIT
 jne .fail
 cmp qword [rel ir+NEBOC_IR_ALLOCATION_OFFSET],0
 jne .fail
 inc r13d
 ; Sum construction lowering.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_SUM
 call run_ir
 test eax,eax
 jnz .fail
 cmp qword [rel ir+NEBOC_IR_HIR_OPCODE_OFFSET],NEBOC_HIR_SUM_CONSTRUCT
 jne .fail
 cmp qword [rel ir+NEBOC_IR_LIR_OPCODE_OFFSET],NEBOC_LIR_TAGGED_INIT
 jne .fail
 inc r13d
 ; Field access at the upper supported member index.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_FIELD_ACCESS
 mov qword [rel ir+NEBOC_IR_MEMBER_INDEX_OFFSET],7
 call run_ir
 test eax,eax
 jnz .fail
 cmp qword [rel ir+NEBOC_IR_HIR_OPCODE_OFFSET],NEBOC_HIR_FIELD_PROJECT
 jne .fail
 cmp qword [rel ir+NEBOC_IR_LIR_OPCODE_OFFSET],NEBOC_LIR_FIELD_LOAD
 jne .fail
 inc r13d
 ; Member index bound.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_FIELD_ACCESS
 mov qword [rel ir+NEBOC_IR_MEMBER_INDEX_OFFSET],8
 call run_ir
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_DIAGNOSTIC_OFFSET],1
 jne .fail
 inc r13d
 ; Semantic hash binding.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_PRODUCT
 inc qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_SEMANTIC_HASH_OFFSET]
 call run_ir
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 inc r13d
 ; Nominal identity binding.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_PRODUCT
 inc qword [rel ir+NEBOC_IR_NOMINAL_TYPE_OFFSET]
 call run_ir
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 inc r13d
 ; Only the frozen x86-64 System V target is accepted.
 call clear_ir
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_KIND_OFFSET],NEBOC_IR_PRODUCT
 mov qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_TARGET_OFFSET],2
 call run_ir
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne .fail
 cmp qword [rel ir+neboc_structs_enums_variants_e_tipos_do_programador_IR_DIAGNOSTIC_OFFSET],2
 jne .fail
 inc r13d
 ; Null guards.
 xor edi,edi
 call neboc_programmer_type_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 call neboc_programmer_type_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
