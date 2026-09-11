; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF004 native stack-slot prototype — 32 scenarios
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_semantic.inc"
%include "compiler/lowering/bindings/binding_ir_contract.inc"
%include "compiler/lowering/bindings/binding_native_lowering.inc"
extern neboc_binding_native_lower
extern neboc_runtime_store_bool
extern neboc_runtime_load_bool
extern neboc_runtime_store_i64
extern neboc_runtime_load_i64
extern neboc_runtime_store_f64
extern neboc_runtime_load_f64
extern neboc_runtime_store_ptr
extern neboc_runtime_load_ptr
extern neboc_runtime_store_char
extern neboc_runtime_load_char
section .data align=8
float_bits: dq 0x400c000000000000
pointer_value: dq 0x1122334455667788
section .bss align=16
sem: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_REQUEST_SIZE
ir: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_REQUEST_SIZE
native: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REQUEST_SIZE
native2: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REQUEST_SIZE
slot: resb 32
section .text
clear:
 lea rdi,[rel sem]
 mov ecx,(neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_REQUEST_SIZE+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_REQUEST_SIZE+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REQUEST_SIZE*2+32)/8
 xor eax,eax
 rep stosq
 ret
; edi operation, esi type, edx lir, ecx stack offset
prepare:
 push rbx
 push r12
 push r13
 push r14
 mov ebx,edi
 mov r12d,esi
 mov r13d,edx
 mov r14d,ecx
 call clear
 mov [rel sem+NEBOC_SEM_RESULT_OPERATION_OFFSET],rbx
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET],r12
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],r13
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CODE_OFFSET],0
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RUNTIME_METADATA_OFFSET],0
 mov rax,0x1111111111111111
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET],rax
 mov [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_OPERATION_OFFSET],rbx
 mov [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_LIR_KIND_OFFSET],r13
 mov qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_ERROR_CODE_OFFSET],0
 mov qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_RUNTIME_METADATA_OFFSET],0
 mov rax,0x2222222222222222
 mov [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_HASH_OFFSET],rax
 lea rax,[rel sem]
 mov [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_ID_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 mov [rel native+NEBOC_NATIVE_STACK_SLOT_OFFSET_OFFSET],r14
 mov [rel native+NEBOC_NATIVE_VALUE_TYPE_OFFSET],r12
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
lower: lea rdi,[rel native]
 jmp neboc_binding_native_lower
fail: mov edi,r15d
 mov eax,60
 syscall
ud2
%macro CASE 1
 mov r15d,%1
%endmacro
%macro REQUIRE_Z 0
 jne fail
%endmacro
%macro REQUIRE_NZ 0
 je fail
%endmacro

global _start
_start:
 cld
 CASE 1
 xor edi,edi
 call neboc_binding_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQUIRE_Z
 CASE 2
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_ID_OFFSET],99
 call lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQUIRE_Z
 CASE 3
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CODE_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 REQUIRE_Z
 CASE 4
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_ERROR_CODE_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 REQUIRE_Z
 CASE 5
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RUNTIME_METADATA_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 6
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_RUNTIME_METADATA_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 7
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_OPERATION_OFFSET],NEBOC_SEM_OPERATION_READ
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 8
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 mov qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_READ
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 9
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,4
 call prepare
 call lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQUIRE_Z
 CASE 10
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,99
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 11
 mov edi,NEBOC_SEM_OPERATION_TYPED_DECLARATION
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_DECLARE
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_RESERVE_SLOT_OFFSET],1
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_STORE_COUNT_OFFSET],0
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_STATE_ONLY_OFFSET],1
 REQUIRE_Z
 CASE 12
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_STORE_I64
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_STORE_COUNT_OFFSET],1
 REQUIRE_Z
 CASE 13
 mov edi,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_INITIALIZE_ONCE
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_RESERVE_SLOT_OFFSET],0
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_STORE_COUNT_OFFSET],1
 REQUIRE_Z
 CASE 14
 mov edi,NEBOC_SEM_OPERATION_READ
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_READ
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_LOAD_I64
 REQUIRE_Z
 CASE 15
 mov edi,NEBOC_SEM_OPERATION_DEFINITE_READ
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_DEFINITE_READ
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_LOAD_COUNT_OFFSET],1
 REQUIRE_Z
 CASE 16
 mov edi,NEBOC_SEM_OPERATION_FLOW_MERGE
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_FLOW_STATE_INTERSECTION
 xor ecx,ecx
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_STATE_ONLY_OFFSET],1
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],0
 REQUIRE_Z
 CASE 17
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_BOOL
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,1
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],1
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_STORE_U8
 REQUIRE_Z
 CASE 18
 mov edi,NEBOC_SEM_OPERATION_READ
 mov esi,NEBOC_BIND_TYPE_FLOAT
 mov edx,NEBOC_SEM_LIR_SYMBOL_READ
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],NEBOC_NATIVE_ABI_SSE
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_XMM0
 REQUIRE_Z
 CASE 19
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_TEXT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_REPRESENTATION_OFFSET],NEBOC_NATIVE_REPR_DESCRIPTOR_PTR
 REQUIRE_Z
 CASE 20
 mov edi,NEBOC_SEM_OPERATION_READ
 mov esi,NEBOC_BIND_TYPE_CHAR
 mov edx,NEBOC_SEM_LIR_SYMBOL_READ
 mov ecx,4
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],4
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_LOAD_U32_ZX
 REQUIRE_Z
 CASE 21
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_BYTES
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_REPRESENTATION_OFFSET],NEBOC_NATIVE_REPR_DESCRIPTOR_PTR
 REQUIRE_Z
 CASE 22
 cmp qword [rel native+NEBOC_NATIVE_RUNTIME_OBJECT_OFFSET],0
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_ALLOCATION_OFFSET],0
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_RUNTIME_METADATA_OFFSET],0
 REQUIRE_Z
 CASE 23
 mov edi,NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov esi,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov ecx,8
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 mov rbx,[rel native+NEBOC_NATIVE_PLAN_HASH_OFFSET]
 mov rax,0xaaaaaaaaaaaaaaaa
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET],rax
 mov rax,0xbbbbbbbbbbbbbbbb
 mov [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_HASH_OFFSET],rax
 lea rax,[rel sem]
 mov [rel native2+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native2+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native2+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_ID_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 mov qword [rel native2+NEBOC_NATIVE_STACK_SLOT_OFFSET_OFFSET],8
 mov qword [rel native2+NEBOC_NATIVE_VALUE_TYPE_OFFSET],NEBOC_BIND_TYPE_INT
 lea rdi,[rel native2]
 call neboc_binding_native_lower
 test eax,eax
 REQUIRE_Z
 cmp rbx,[rel native2+NEBOC_NATIVE_PLAN_HASH_OFFSET]
 REQUIRE_Z
 CASE 24
 lea rdi,[rel slot]
 mov esi,1
 call neboc_runtime_store_bool
 lea rdi,[rel slot]
 call neboc_runtime_load_bool
 cmp eax,1
 REQUIRE_Z
 CASE 25
 lea rdi,[rel slot]
 mov rsi,-42
 call neboc_runtime_store_i64
 lea rdi,[rel slot]
 call neboc_runtime_load_i64
 cmp rax,-42
 REQUIRE_Z
 CASE 26
 movq xmm0,[rel float_bits]
 lea rdi,[rel slot]
 call neboc_runtime_store_f64
 pxor xmm0,xmm0
 lea rdi,[rel slot]
 call neboc_runtime_load_f64
 movq rax,xmm0
 cmp rax,[rel float_bits]
 REQUIRE_Z
 CASE 27
 lea rdi,[rel slot]
 mov rsi,[rel pointer_value]
 call neboc_runtime_store_ptr
 lea rdi,[rel slot]
 call neboc_runtime_load_ptr
 cmp rax,[rel pointer_value]
 REQUIRE_Z
 CASE 28
 lea rdi,[rel slot]
 mov esi,0x1f600
 call neboc_runtime_store_char
 lea rdi,[rel slot]
 call neboc_runtime_load_char
 cmp eax,0x1f600
 REQUIRE_Z
 CASE 29
 mov edi,NEBOC_SEM_OPERATION_READ
 mov esi,NEBOC_BIND_TYPE_BOOL
 mov edx,NEBOC_SEM_LIR_SYMBOL_READ
 mov ecx,1
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_LOAD_U8_ZX
 REQUIRE_Z
 CASE 30
 mov edi,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION
 mov esi,NEBOC_BIND_TYPE_FLOAT
 mov edx,NEBOC_SEM_LIR_SYMBOL_INITIALIZE_ONCE
 mov ecx,16
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_STORE_F64
 REQUIRE_Z
 CASE 31
 mov edi,NEBOC_SEM_OPERATION_TYPED_DECLARATION
 mov esi,NEBOC_BIND_TYPE_CHAR
 mov edx,NEBOC_SEM_LIR_SYMBOL_DECLARE
 mov ecx,4
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_RESERVE_SLOT_OFFSET],1
 REQUIRE_Z
 CASE 32
 mov edi,NEBOC_SEM_OPERATION_DEFINITE_READ
 mov esi,NEBOC_BIND_TYPE_BYTES
 mov edx,NEBOC_SEM_LIR_SYMBOL_DEFINITE_READ
 mov ecx,24
 call prepare
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_LOAD_PTR
 REQUIRE_Z
 xor edi,edi
 mov eax,60
 syscall
