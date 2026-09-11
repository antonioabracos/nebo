; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF004 Option/Result native representation/runtime prototype — 48 scenarios
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/semantic/types/option_result_semantic.inc"
%include "compiler/lowering/scalars/option_result_ir_contract.inc"
%include "compiler/lowering/scalars/option_result_native_lowering.inc"
%include "runtime/scalars/option_result_runtime.inc"
extern neboc_option_result_native_lower
extern neboc_runtime_store_zero_payload
extern neboc_runtime_store_integer
extern neboc_runtime_store_float
extern neboc_runtime_load_tag
extern neboc_runtime_load_integer
extern neboc_runtime_load_float
extern neboc_runtime_tag_test
extern neboc_runtime_unwrap_integer
extern neboc_runtime_unwrap_float
extern neboc_runtime_validate_option
extern neboc_runtime_validate_result
extern neboc_runtime_roundtrip_integer_aggregate
extern neboc_runtime_roundtrip_sse_aggregate

section .rodata align=8
f_one: dq 0x3ff0000000000000
f_one_half: dq 0x3ff8000000000000
f_two: dq 0x4000000000000000

section .bss align=16
sem: resb neboc_option_result_null_externo_e_erros_tipados_SEM_REQUEST_SIZE
ir: resb neboc_option_result_null_externo_e_erros_tipados_IR_REQUEST_SIZE
native: resb neboc_option_result_null_externo_e_erros_tipados_NATIVE_REQUEST_SIZE
slot: resb 16
slot2: resb 16

section .text
clear_all:
 lea rdi,[rel sem]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_SEM_REQUEST_SIZE+neboc_option_result_null_externo_e_erros_tipados_IR_REQUEST_SIZE+neboc_option_result_null_externo_e_erros_tipados_NATIVE_REQUEST_SIZE+32)/8
 xor eax,eax
 rep stosq
 ret

; edi=HIR, esi=container, edx=success type, ecx=error type, r8d=variant/observer
prepare_valid:
 mov r9d,edi
 mov r10d,ecx
 call clear_all
 mov [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],r9
 mov [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET],r9
 mov [rel sem+NEBOC_SEM_RESULT_CONTAINER_OFFSET],rsi
 mov [rel ir+NEBOC_IR_CONTAINER_OFFSET],rsi
 mov [rel sem+NEBOC_SEM_RESULT_SUCCESS_TYPE_OFFSET],rdx
 mov [rel ir+NEBOC_IR_SUCCESS_TYPE_OFFSET],rdx
 mov [rel sem+NEBOC_SEM_RESULT_ERROR_TYPE_OFFSET],r10
 mov [rel ir+NEBOC_IR_ERROR_TYPE_OFFSET],r10
 mov [rel sem+NEBOC_SEM_VARIANT_OBSERVER_OFFSET],r8
 mov [rel ir+NEBOC_IR_VARIANT_OBSERVER_OFFSET],r8
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_NONE
 mov qword [rel ir+NEBOC_IR_ERROR_OFFSET],neboc_option_result_null_externo_e_erros_tipados_IR_ERROR_NONE
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_NONE
 mov qword [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_RUNTIME_METADATA_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_NONE
 mov qword [rel sem+NEBOC_SEM_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 mov qword [rel ir+NEBOC_IR_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 mov rax,0x1111111111111111
 mov [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET],rax
 mov rax,0x2222222222222222
 mov [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_HASH_OFFSET],rax
 cmp r9d,NEBOC_SEM_HIR_UNWRAP_OR
 je .lir_unwrap
 cmp r9d,NEBOC_SEM_HIR_OPTION_PREDICATE
 je .lir_tag
 cmp r9d,NEBOC_SEM_HIR_RESULT_PREDICATE
 je .lir_tag
 mov eax,NEBOC_SEM_LIR_TAGGED_CONSTRUCT
 jmp .lir
.lir_tag:
 mov eax,NEBOC_SEM_LIR_TAG_TEST
 jmp .lir
.lir_unwrap:
 mov eax,NEBOC_SEM_LIR_PAYLOAD_OR_FALLBACK
.lir:
 mov [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],rax
 mov [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_LIR_KIND_OFFSET],rax
 ret

lower:
 lea rax,[rel sem]
 mov [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_ID_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rel native]
 jmp neboc_option_result_native_lower

fail:
 mov edi,r15d
 mov eax,60
 syscall
 ud2
%macro CASE 1
 mov r15d,%1
%endmacro
%macro REQ_Z 0
 jne fail
%endmacro
%macro REQ_NZ 0
 je fail
%endmacro

; Convenience setup macros.
%macro PREP_OPTION 3
 mov edi,%1
 mov esi,NEBOC_CONTAINER_OPTION
 mov edx,%2
 xor ecx,ecx
 mov r8d,%3
 call prepare_valid
%endmacro
%macro PREP_RESULT 4
 mov edi,%1
 mov esi,NEBOC_CONTAINER_RESULT
 mov edx,%2
 mov ecx,%3
 mov r8d,%4
 call prepare_valid
%endmacro

global _start
_start:
 cld
 CASE 1
 xor edi,edi
 call neboc_option_result_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQ_Z
 CASE 2
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 lea rax,[rel sem]
 mov [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_ID_OFFSET],99
 lea rdi,[rel native]
 call neboc_option_result_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQ_Z
 CASE 3
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 REQ_Z
 CASE 4
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 mov qword [rel ir+NEBOC_IR_ERROR_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 REQ_Z
 CASE 5
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQ_Z
 CASE 6
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 mov qword [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_RUNTIME_METADATA_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQ_Z
 CASE 7
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET],0
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQ_Z
 CASE 8
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 mov qword [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET],NEBOC_SEM_HIR_OPTION_NONE
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQ_Z
 CASE 9
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser,NEBOC_VARIANT_SOME
 call lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQ_Z
 CASE 10
 PREP_OPTION 99,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 call lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQ_Z

 CASE 11
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_TAG_VALUE_OFFSET],1
 REQ_Z
 cmp qword [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SLOT_SIZE_OFFSET],16
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 REQ_Z
 CASE 12
 PREP_OPTION NEBOC_SEM_HIR_OPTION_NONE,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_NONE_VALUE
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_TAG_VALUE_OFFSET],0
 REQ_Z
 cmp qword [rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_STORE_ZERO_PAYLOAD
 REQ_Z
 CASE 13
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,NEBOC_VARIANT_SOME
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_ARGUMENT_PAYLOAD_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_XMM0
 REQ_Z
 CASE 14
 PREP_OPTION NEBOC_SEM_HIR_OPTION_SOME,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_SOME
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_ACTIVE_PAYLOAD_SIZE_OFFSET],1
 REQ_Z
 CASE 15
 PREP_OPTION NEBOC_SEM_HIR_OPTION_NONE,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,NEBOC_VARIANT_NONE_VALUE
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_ACTIVE_PAYLOAD_ALIGNMENT_OFFSET],4
 REQ_Z
 CASE 16
 PREP_RESULT NEBOC_SEM_HIR_RESULT_OK,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_TAG_VALUE_OFFSET],0
 REQ_Z
 CASE 17
 PREP_RESULT NEBOC_SEM_HIR_RESULT_ERR,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_ERR
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_TAG_VALUE_OFFSET],1
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_ACTIVE_PAYLOAD_SIZE_OFFSET],1
 REQ_Z
 CASE 18
 PREP_RESULT NEBOC_SEM_HIR_RESULT_OK,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,NEBOC_VARIANT_OK
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 REQ_Z
 CASE 19
 PREP_RESULT NEBOC_SEM_HIR_RESULT_OK,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_VARIANT_OK
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 REQ_Z
 CASE 20
 PREP_RESULT NEBOC_SEM_HIR_RESULT_ERR,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,NEBOC_VARIANT_ERR
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_ACTIVE_REPR_OFFSET],NEBOC_NATIVE_REPR_FLOAT_BINARY64
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 REQ_Z
 CASE 21
 PREP_OPTION NEBOC_SEM_HIR_OPTION_PREDICATE,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_OBSERVER_IS_SOME
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_TAG_VALUE_OFFSET],1
 REQ_Z
 CASE 22
 PREP_RESULT NEBOC_SEM_HIR_RESULT_PREDICATE,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_OBSERVER_IS_OK
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_TAG_VALUE_OFFSET],0
 REQ_Z
 CASE 23
 PREP_OPTION NEBOC_SEM_HIR_UNWRAP_OR,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_OBSERVER_UNWRAP_OR
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SCALAR_RETURN_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RAX
 REQ_Z
 CASE 24
 PREP_OPTION NEBOC_SEM_HIR_UNWRAP_OR,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,NEBOC_OBSERVER_UNWRAP_OR
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_FALLBACK_REGISTER_OFFSET],NEBOC_NATIVE_REGISTER_XMM1
 REQ_Z
 CASE 25
 PREP_RESULT NEBOC_SEM_HIR_UNWRAP_OR,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,NEBOC_OBSERVER_UNWRAP_OR
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SCALAR_RETURN_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_XMM0
 REQ_Z
 CASE 26
 PREP_RESULT NEBOC_SEM_HIR_UNWRAP_OR,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,NEBOC_OBSERVER_UNWRAP_OR
 call lower
 test eax,eax
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_SCALAR_RETURN_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_XMM0
 REQ_Z
 CASE 27
 cmp qword [rel native+NEBOC_NATIVE_TAG_OFFSET_OFFSET],0
 REQ_Z
 cmp qword [rel native+NEBOC_NATIVE_PAYLOAD_OFFSET_OFFSET],8
 REQ_Z
 CASE 28
 mov rax,[rel native+neboc_option_result_null_externo_e_erros_tipados_NATIVE_FLAGS_OFFSET]
 and rax,NEBOC_NATIVE_FLAG_PADDING_ZERO|NEBOC_NATIVE_FLAG_NO_NICHE|neboc_option_result_null_externo_e_erros_tipados_NATIVE_FLAG_NO_HEAP
 cmp rax,NEBOC_NATIVE_FLAG_PADDING_ZERO|NEBOC_NATIVE_FLAG_NO_NICHE|neboc_option_result_null_externo_e_erros_tipados_NATIVE_FLAG_NO_HEAP
 REQ_Z

 CASE 29
 lea rdi,[rel slot]
 mov rax,0xffffffffffffffff
 mov [rdi],rax
 mov [rdi+8],rax
 xor esi,esi
 call neboc_runtime_store_zero_payload
 cmp qword [rel slot],0
 REQ_Z
 cmp qword [rel slot+8],0
 REQ_Z
 CASE 30
 lea rdi,[rel slot]
 mov esi,1
 mov rdx,42
 call neboc_runtime_store_integer
 lea rdi,[rel slot]
 call neboc_runtime_load_tag
 cmp eax,1
 REQ_Z
 lea rdi,[rel slot]
 call neboc_runtime_load_integer
 cmp rax,42
 REQ_Z
 CASE 31
 lea rdi,[rel slot]
 mov esi,1
 mov edx,1
 call neboc_runtime_store_integer
 cmp qword [rel slot+8],1
 REQ_Z
 CASE 32
 lea rdi,[rel slot]
 mov esi,1
 mov edx,0x10ffff
 call neboc_runtime_store_integer
 cmp qword [rel slot+8],0x10ffff
 REQ_Z
 CASE 33
 lea rdi,[rel slot]
 mov esi,1
 movq xmm0,[rel f_one_half]
 call neboc_runtime_store_float
 lea rdi,[rel slot]
 call neboc_runtime_load_float
 movq rax,xmm0
 cmp rax,[rel f_one_half]
 REQ_Z
 CASE 34
 lea rdi,[rel slot]
 mov esi,1
 mov rdx,7
 call neboc_runtime_store_integer
 cmp byte [rel slot],1
 REQ_Z
 cmp qword [rel slot+8],7
 REQ_Z
 CASE 35
 lea rdi,[rel slot]
 mov esi,1
 call neboc_runtime_tag_test
 cmp eax,1
 REQ_Z
 CASE 36
 lea rdi,[rel slot]
 xor esi,esi
 call neboc_runtime_tag_test
 test eax,eax
 REQ_Z
 CASE 37
 lea rdi,[rel slot]
 mov esi,1
 call neboc_runtime_tag_test
 cmp eax,1
 REQ_Z
 CASE 38
 lea rdi,[rel slot]
 xor esi,esi
 call neboc_runtime_tag_test
 test eax,eax
 REQ_Z
 CASE 39
 lea rdi,[rel slot]
 mov esi,1
 mov edx,99
 call neboc_runtime_unwrap_integer
 cmp rax,7
 REQ_Z
 CASE 40
 lea rdi,[rel slot]
 xor esi,esi
 mov edx,99
 call neboc_runtime_unwrap_integer
 cmp rax,99
 REQ_Z
 CASE 41
 lea rdi,[rel slot]
 mov esi,1
 movq xmm0,[rel f_one_half]
 call neboc_runtime_store_float
 lea rdi,[rel slot]
 mov esi,1
 movq xmm0,[rel f_two]
 call neboc_runtime_unwrap_float
 movq rax,xmm0
 cmp rax,[rel f_one_half]
 REQ_Z
 CASE 42
 lea rdi,[rel slot]
 xor esi,esi
 movq xmm0,[rel f_two]
 call neboc_runtime_unwrap_float
 movq rax,xmm0
 cmp rax,[rel f_two]
 REQ_Z
 CASE 43
 mov edi,1
 mov rsi,42
 call neboc_runtime_roundtrip_integer_aggregate
 cmp eax,1
 REQ_Z
 cmp rdx,42
 REQ_Z
 CASE 44
 mov edi,1
 movq xmm0,[rel f_one]
 call neboc_runtime_roundtrip_sse_aggregate
 cmp eax,1
 REQ_Z
 movq rax,xmm0
 cmp rax,[rel f_one]
 REQ_Z
 CASE 45
 lea rdi,[rel slot]
 call neboc_runtime_validate_option
 cmp eax,1
 REQ_Z
 CASE 46
 lea rdi,[rel slot]
 call neboc_runtime_validate_result
 cmp eax,1
 REQ_Z
 CASE 47
 mov byte [rel slot+1],1
 lea rdi,[rel slot]
 call neboc_runtime_validate_result
 test eax,eax
 REQ_Z
 mov byte [rel slot+1],0
 CASE 48
 mov rax,0xffffffffffffffff
 mov [rel slot2],rax
 mov [rel slot2+8],rax
 lea rdi,[rel slot2]
 xor esi,esi
 call neboc_runtime_store_zero_payload
 cmp qword [rel slot2],0
 REQ_Z
 cmp qword [rel slot2+8],0
 REQ_Z

 xor edi,edi
 mov eax,60
 syscall
