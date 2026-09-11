bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/numeric_safety_api_contract.inc"
%include "compiler/semantic/types/numeric_safety_semantic.inc"
%include "compiler/lowering/scalars/numeric_safety_ir_contract.inc"
%include "compiler/lowering/scalars/numeric_safety_native_lowering.inc"
%include "runtime/scalars/numeric-safety/numeric_safety_runtime.inc"

extern neboc_numeric_safety_native_lower
extern neboc_numeric_safety_runtime_layout_get
extern neboc_numeric_safety_runtime_int_to_float
extern neboc_numeric_safety_runtime_is_finite
extern neboc_numeric_safety_runtime_is_nan
extern neboc_numeric_safety_runtime_is_infinite
extern neboc_numeric_safety_runtime_is_negative_zero
extern neboc_host_process_exit

section .bss align=16
sem: resb neboc_seguranca_numerica_conversoes_e_overflow_SEM_REQUEST_SIZE
ir: resb neboc_seguranca_numerica_conversoes_e_overflow_IR_REQUEST_SIZE
native: resb neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_REQUEST_SIZE
layout_ptr: resq 1
saved_hash: resq 1
saved_mxcsr: resd 1
active_mxcsr: resd 1
after_mxcsr: resd 1
saved_result_bits: resq 1

section .text

clear_contracts:
 lea rdi,[rel sem]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel ir]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel native]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 ret

prepare_conversion:
 call clear_contracts
 mov qword [rel sem+NEBOC_SEM_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CONVERSION
 mov qword [rel sem+NEBOC_SEM_CONVERSION_POLICY_OFFSET],NEBOC_SEM_CONVERSION_I64_TO_F64_ROUND_TIES_EVEN
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CONVERSION
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_NUMERIC_CONVERSION
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_I64_TO_F64
 mov qword [rel sem+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_SIGNED_I64
 mov qword [rel sem+NEBOC_SEM_LIR_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_IEEE_BINARY64_BITS
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_NONE
 mov rax,0x1111111111111111
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET],rax
 mov qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET],NEBOC_IR_HIR_NUMERIC_CONVERSION
 mov qword [rel ir+NEBOC_IR_HIR_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 mov qword [rel ir+NEBOC_IR_HIR_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [rel ir+NEBOC_IR_HIR_OPERATION_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 mov qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_ABSTRACT_I64_TO_F64
 mov qword [rel ir+NEBOC_IR_LIR_OPERAND_REPR_OFFSET],NEBOC_IR_REPR_SIGNED_I64
 mov qword [rel ir+NEBOC_IR_LIR_RESULT_REPR_OFFSET],NEBOC_IR_REPR_IEEE_BINARY64_BITS
 mov qword [rel ir+NEBOC_IR_LIR_POLICY_OFFSET],NEBOC_SEM_CONVERSION_I64_TO_F64_ROUND_TIES_EVEN
 mov qword [rel ir+NEBOC_IR_LIR_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CONVERSION
 mov qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_NONE
 mov rax,0x2222222222222222
 mov [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET],rax
 ret

; rdi = classifier kind 1..4
prepare_classifier:
 push rdi
 call clear_contracts
 pop rdi
 mov rax,rdi
 inc rax
 mov [rel sem+NEBOC_SEM_METHOD_ID_OFFSET],rax
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CLASSIFIER
 mov [rel sem+NEBOC_SEM_CLASSIFIER_KIND_OFFSET],rdi
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CLASSIFIER
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_FLOAT_CLASSIFIER
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_F64_CLASSIFY
 mov qword [rel sem+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_IEEE_BINARY64_BITS
 mov qword [rel sem+NEBOC_SEM_LIR_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_CANONICAL_BOOL
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_NONE
 mov rax,0x3333333333333333
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET],rax
 mov qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET],NEBOC_IR_HIR_FLOAT_CLASSIFIER
 mov qword [rel ir+NEBOC_IR_HIR_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [rel ir+NEBOC_IR_HIR_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 mov rax,rdi
 inc rax
 mov [rel ir+NEBOC_IR_HIR_OPERATION_OFFSET],rax
 mov qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_ABSTRACT_F64_CLASSIFY
 mov qword [rel ir+NEBOC_IR_LIR_OPERAND_REPR_OFFSET],NEBOC_IR_REPR_IEEE_BINARY64_BITS
 mov qword [rel ir+NEBOC_IR_LIR_RESULT_REPR_OFFSET],NEBOC_IR_REPR_CANONICAL_BOOL
 mov [rel ir+NEBOC_IR_LIR_POLICY_OFFSET],rdi
 mov qword [rel ir+NEBOC_IR_LIR_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CLASSIFIER
 mov qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_NONE
 mov rax,0x4444444444444444
 mov [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET],rax
 ret

lower_native:
 lea rax,[rel sem]
 mov [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_TARGET_ID_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rel native]
 jmp neboc_numeric_safety_native_lower

assert_conversion_plan:
 cmp qword [rel native+NEBOC_NATIVE_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_OPERATION_KIND_OFFSET],NEBOC_NATIVE_OPERATION_CONVERSION
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_OPERAND_ABI_CLASS_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ABI_CLASS_INTEGER
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RESULT_ABI_CLASS_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ABI_CLASS_SSE
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_REGISTER_RDI
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RETURN_REGISTER_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_REGISTER_XMM0
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_CVTSI2SD_XMM_R64
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_ROUNDING_MODE_OFFSET],NEBOC_NATIVE_ROUNDING_MXCSR_RN_TIES_EVEN
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_INT_TO_FLOAT
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_SCRATCH_SIZE_OFFSET],16
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_SCRATCH_ALIGNMENT_OFFSET],4
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_FLAGS_OFFSET],NEBOC_NATIVE_FLAGS_CONVERSION
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

; rdi = classifier kind
assert_classifier_plan:
 cmp qword [rel native+NEBOC_NATIVE_OPERATION_KIND_OFFSET],NEBOC_NATIVE_OPERATION_CLASSIFIER
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_OPERAND_ABI_CLASS_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ABI_CLASS_SSE
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RESULT_ABI_CLASS_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ABI_CLASS_INTEGER
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_REGISTER_XMM0
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RETURN_REGISTER_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_REGISTER_RAX
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_BITWISE_F64_CLASSIFY
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_ROUNDING_MODE_OFFSET],NEBOC_NATIVE_ROUNDING_NONE
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_FLAGS_OFFSET],NEBOC_NATIVE_FLAGS_CLASSIFIER
 jne fail
 mov rax,rdi
 inc rax
 cmp [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_RUNTIME_HELPER_OFFSET],rax
 jne fail
 ret

; rdi = signed integer; rsi = expected binary64 bits
assert_to_float_bits:
 push rsi
 call neboc_numeric_safety_runtime_int_to_float
 pop rsi
 movq rax,xmm0
 cmp rax,rsi
 jne fail
 ret

; rdi = binary64 bits; rsi = expected Bool; rdx = helper address
assert_classifier_result:
 push rsi
 movq xmm0,rdi
 call rdx
 pop rsi
 cmp rax,rsi
 jne fail
 cmp rax,1
 ja fail
 ret

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne usage
 mov rsi,[rsp+16]
 movzx ecx,byte [rsi]
 sub ecx,'0'
 cmp ecx,1
 jb usage
 cmp ecx,9
 jbe .one_digit
 mov ecx,0
.one_digit:
 cmp byte [rsi+1],0
 je .number_ready
 movzx eax,byte [rsi+1]
 sub eax,'0'
 cmp eax,0
 jb usage
 cmp eax,9
 ja usage
 movzx ecx,byte [rsi]
 sub ecx,'0'
 imul ecx,ecx,10
 add ecx,eax
 cmp byte [rsi+2],0
 jne usage
.number_ready:
 cmp ecx,1
 jb usage
 cmp ecx,26
 ja usage
 mov r13d,ecx
 cmp ecx,1
 je scenario1
 cmp ecx,2
 je scenario2
 cmp ecx,3
 je scenario3
 cmp ecx,4
 je scenario4
 cmp ecx,5
 je scenario5
 cmp ecx,6
 je scenario6
 cmp ecx,7
 je scenario7
 cmp ecx,8
 je scenario8
 cmp ecx,9
 je scenario9
 cmp ecx,10
 je scenario10
 cmp ecx,11
 je scenario11
 cmp ecx,12
 je scenario12
 cmp ecx,13
 je scenario13
 cmp ecx,14
 je scenario14
 cmp ecx,15
 je scenario15
 cmp ecx,16
 je scenario16
 cmp ecx,17
 je scenario17
 cmp ecx,18
 je scenario18
 cmp ecx,19
 je scenario19
 cmp ecx,20
 je scenario20
 cmp ecx,21
 je scenario21
 cmp ecx,22
 je scenario22
 cmp ecx,23
 je scenario23
 cmp ecx,24
 je scenario24
 cmp ecx,25
 je scenario25
 jmp scenario26

scenario1:
 lea rdi,[rel layout_ptr]
 call neboc_numeric_safety_runtime_layout_get
 test eax,eax
 jnz fail
 mov rbx,[rel layout_ptr]
 test rbx,rbx
 jz fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_TARGET_OFFSET],NEBOC_RUNTIME_TARGET_X86_64_SYSTEMV_ELF_LINUX
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_INT_WIDTH_OFFSET],64
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_INT_SIZE_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_INT_ALIGNMENT_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_INT_ABI_CLASS_OFFSET],NEBOC_RUNTIME_ABI_CLASS_INTEGER
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_INT_PARAMETER_REGISTER_OFFSET],NEBOC_RUNTIME_REGISTER_RDI
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLOAT_WIDTH_OFFSET],64
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLOAT_SIZE_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLOAT_ALIGNMENT_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLOAT_ABI_CLASS_OFFSET],NEBOC_RUNTIME_ABI_CLASS_SSE
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLOAT_PARAMETER_REGISTER_OFFSET],NEBOC_RUNTIME_REGISTER_XMM0
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLOAT_RETURN_REGISTER_OFFSET],NEBOC_RUNTIME_REGISTER_XMM0
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_BOOL_WIDTH_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_BOOL_SIZE_OFFSET],1
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_BOOL_ALIGNMENT_OFFSET],1
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_BOOL_ABI_CLASS_OFFSET],NEBOC_RUNTIME_ABI_CLASS_INTEGER
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_BOOL_RETURN_REGISTER_OFFSET],NEBOC_RUNTIME_REGISTER_RAX
 jne fail
 cmp qword [rbx+NEBOC_RUNTIME_LAYOUT_FLAGS_OFFSET],NEBOC_RUNTIME_REQUIRED_FLAGS
 jne fail
 jmp pass
scenario2:
 call prepare_conversion
 call lower_native
 test eax,eax
 jnz fail
 call assert_conversion_plan
 jmp pass
scenario3:
 call prepare_conversion
 call lower_native
 test eax,eax
 jnz fail
 mov rax,[rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_HASH_OFFSET]
 mov [rel saved_hash],rax
 mov rax,0xaaaaaaaaaaaaaaaa
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET],rax
 mov rax,0xbbbbbbbbbbbbbbbb
 mov [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET],rax
 call lower_native
 test eax,eax
 jnz fail
 mov rax,[rel saved_hash]
 cmp rax,[rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_HASH_OFFSET]
 jne fail
 jmp pass
scenario4:
 mov edi,NEBOC_SEM_CLASSIFIER_FINITE
 call prepare_classifier
 call lower_native
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_CLASSIFIER_FINITE
 call assert_classifier_plan
 jmp pass
scenario5:
 mov ebx,NEBOC_SEM_CLASSIFIER_FINITE
.loop:
 mov rdi,rbx
 call prepare_classifier
 call lower_native
 test eax,eax
 jnz fail
 mov rdi,rbx
 call assert_classifier_plan
 inc ebx
 cmp ebx,NEBOC_SEM_CLASSIFIER_NEGATIVE_ZERO
 jbe .loop
 jmp pass
scenario6:
 xor edi,edi
 xor esi,esi
 call assert_to_float_bits
 jmp pass
scenario7:
 mov edi,1
 mov rsi,0x3ff0000000000000
 call assert_to_float_bits
 jmp pass
scenario8:
 mov rdi,-1
 mov rsi,0xbff0000000000000
 call assert_to_float_bits
 jmp pass
scenario9:
 mov edi,42
 mov rsi,0x4045000000000000
 call assert_to_float_bits
 jmp pass
scenario10:
 mov rdi,0x8000000000000000
 mov rsi,0xc3e0000000000000
 call assert_to_float_bits
 jmp pass
scenario11:
 mov rdi,0x7fffffffffffffff
 mov rsi,0x43e0000000000000
 call assert_to_float_bits
 jmp pass
scenario12:
 mov rdi,0x0020000000000000
 mov rsi,0x4340000000000000
 call assert_to_float_bits
 jmp pass
scenario13:
 mov rdi,0x0020000000000001
 mov rsi,0x4340000000000000
 call assert_to_float_bits
 jmp pass
scenario14:
 mov rdi,-9007199254740993
 mov rsi,0xc340000000000000
 call assert_to_float_bits
 jmp pass
scenario15:
 sub rsp,16
 stmxcsr [rsp]
 mov eax,[rsp]
 mov [rel saved_mxcsr],eax
 or eax,0x6000
 mov [rsp+4],eax
 mov [rel active_mxcsr],eax
 ldmxcsr [rsp+4]
 mov rdi,0x0020000000000001
 call neboc_numeric_safety_runtime_int_to_float
 movq rax,xmm0
 mov [rel saved_result_bits],rax
 stmxcsr [rsp+8]
 mov eax,[rsp+8]
 mov [rel after_mxcsr],eax
 ldmxcsr [rsp]
 add rsp,16
 mov eax,[rel active_mxcsr]
 cmp eax,[rel after_mxcsr]
 jne fail
 mov rax,0x4340000000000000
 cmp rax,[rel saved_result_bits]
 jne fail
 jmp pass
scenario16:
 mov rdi,0x3ff8000000000000
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_finite]
 call assert_classifier_result
 jmp pass
scenario17:
 xor edi,edi
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_finite]
 call assert_classifier_result
 mov rdi,1
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_finite]
 call assert_classifier_result
 jmp pass
scenario18:
 mov rdi,0x7ff0000000000000
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_finite]
 call assert_classifier_result
 mov rdi,0x7ff8000000000001
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_finite]
 call assert_classifier_result
 jmp pass
scenario19:
 mov rdi,0x7ff8000000000001
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_nan]
 call assert_classifier_result
 jmp pass
scenario20:
 sub rsp,16
 stmxcsr [rsp]
 mov eax,[rsp]
 mov [rel saved_mxcsr],eax
 add rsp,16
 mov rdi,0x7ff0000000000001
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_nan]
 call assert_classifier_result
 sub rsp,16
 stmxcsr [rsp]
 mov eax,[rsp]
 mov [rel after_mxcsr],eax
 add rsp,16
 mov eax,[rel saved_mxcsr]
 cmp eax,[rel after_mxcsr]
 jne fail
 jmp pass
scenario21:
 mov rdi,0x7ff0000000000000
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_nan]
 call assert_classifier_result
 mov rdi,0x3ff0000000000000
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_nan]
 call assert_classifier_result
 jmp pass
scenario22:
 mov rdi,0x7ff0000000000000
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_infinite]
 call assert_classifier_result
 mov rdi,0xfff0000000000000
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_infinite]
 call assert_classifier_result
 jmp pass
scenario23:
 mov rdi,0x7ff8000000000001
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_infinite]
 call assert_classifier_result
 mov rdi,0x3ff0000000000000
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_infinite]
 call assert_classifier_result
 jmp pass
scenario24:
 mov rdi,0x8000000000000000
 mov esi,1
 lea rdx,[rel neboc_numeric_safety_runtime_is_negative_zero]
 call assert_classifier_result
 xor edi,edi
 xor esi,esi
 lea rdx,[rel neboc_numeric_safety_runtime_is_negative_zero]
 call assert_classifier_result
 jmp pass
scenario25:
 call prepare_conversion
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_API_INVALID
 call lower_native
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ERROR_SEMANTIC_NOT_VALID
 jne fail
 call prepare_conversion
 inc qword [rel ir+NEBOC_IR_LIR_POLICY_OFFSET]
 call lower_native
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ERROR_CONTRACT_MISMATCH
 jne fail
 call prepare_conversion
 mov qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_TARGET_ID_OFFSET],99
 lea rax,[rel sem]
 mov [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_IR_REQUEST_OFFSET],rax
 lea rdi,[rel native]
 call neboc_numeric_safety_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 cmp qword [rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_ERROR_TARGET_UNSUPPORTED
 jne fail
 jmp pass
scenario26:
 call prepare_conversion
 call lower_native
 test eax,eax
 jnz fail
 mov rax,[rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_HASH_OFFSET]
 mov [rel saved_hash],rax
 call lower_native
 test eax,eax
 jnz fail
 mov rax,[rel saved_hash]
 cmp rax,[rel native+neboc_seguranca_numerica_conversoes_e_overflow_NATIVE_HASH_OFFSET]
 jne fail
 mov edi,42
 mov rsi,0x4045000000000000
 call assert_to_float_bits
 jmp pass

pass:
 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r13d
 jmp neboc_host_process_exit
usage:
 mov edi,64
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
