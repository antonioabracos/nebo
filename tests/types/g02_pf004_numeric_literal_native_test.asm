bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/semantic/types/numeric_literal_semantic.inc"
%include "compiler/lowering/scalars/numeric_literal_ir_contract.inc"
%include "compiler/lowering/scalars/numeric_literal_native_lowering.inc"
%include "runtime/scalars/int/numeric_literal_runtime.inc"

extern neboc_numeric_literal_contract_scan
extern neboc_numeric_literal_semantic_analyze
extern neboc_numeric_literal_ir_lower
extern neboc_numeric_literal_native_lower
extern neboc_int_runtime_layout_get
extern neboc_int_runtime_identity
extern neboc_int_runtime_stack_roundtrip
extern neboc_host_process_exit

section .rodata
s_decimal: db '42'
s_binary: db '0b101010'
s_hex: db '0x2A'
s_octal: db '0o52'
s_sep: db '0b10_1010'
s_max: db '0x7fff_ffff_ffff_ffff'
s_min_mag: db '0x8000_0000_0000_0000'

section .bss align=16
scan: resb NEBOC_NUMERIC_REQUEST_SIZE
sem: resb neboc_literais_numericos_bases_e_representacao_SEM_REQUEST_SIZE
ir: resb neboc_literais_numericos_bases_e_representacao_IR_REQUEST_SIZE
native: resb neboc_literais_numericos_bases_e_representacao_NATIVE_REQUEST_SIZE
layout_ptr: resq 1
stack_slot: resq 1
hash_42: resq 1

section .text

; prepare(source,length,context,start) -> semantic status
prepare:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,rcx
 lea rdi,[rel scan]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov [rel scan+NEBOC_NUMERIC_SOURCE_OFFSET],r12
 mov [rel scan+NEBOC_NUMERIC_LENGTH_OFFSET],r13
 mov qword [rel scan+NEBOC_NUMERIC_SOURCE_ID_OFFSET],88
 mov [rel scan+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],rbx
 lea rdi,[rel scan]
 call neboc_numeric_literal_contract_scan
 lea rdi,[rel sem]
 mov ecx,neboc_literais_numericos_bases_e_representacao_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel scan]
 mov [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SYNTAX_REQUEST_OFFSET],rax
 mov [rel sem+NEBOC_SEM_CONTEXT_FLAGS_OFFSET],r14
 mov qword [rel sem+NEBOC_SEM_AST_TOKEN_INDEX_OFFSET],1
 mov qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_AST_SOURCE_ID_OFFSET],88
 mov [rel sem+NEBOC_SEM_AST_START_OFFSET],rbx
 add rbx,r13
 mov [rel sem+NEBOC_SEM_AST_END_OFFSET],rbx
 lea rdi,[rel sem]
 call neboc_numeric_literal_semantic_analyze
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

lower_native:
 lea rdi,[rel ir]
 mov ecx,neboc_literais_numericos_bases_e_representacao_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_literais_numericos_bases_e_representacao_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rel ir]
 call neboc_numeric_literal_ir_lower
 test eax,eax
 jnz .ret
 lea rdi,[rel native]
 mov ecx,neboc_literais_numericos_bases_e_representacao_NATIVE_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_ID_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rel native]
 call neboc_numeric_literal_native_lower
.ret:
 ret

assert_plan_42:
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_SIGNED_VALUE_OFFSET],42
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_BIT_WIDTH_OFFSET],64
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_STORAGE_SIZE_OFFSET],8
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_STORAGE_ALIGNMENT_OFFSET],8
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_ABI_CLASS_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ABI_CLASS_INTEGER
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_REGISTER_RDI
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_RETURN_REGISTER_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_REGISTER_RAX
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET],NEBOC_NATIVE_IMMEDIATE_SIGN_EXTENDED_I32
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

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
 ja usage
 cmp byte [rsi+1],0
 je .number_ready
 cmp byte [rsi+2],0
 jne usage
 movzx eax,byte [rsi+1]
 sub eax,'0'
 cmp eax,0
 jb usage
 cmp eax,9
 ja usage
 imul ecx,ecx,10
 add ecx,eax
.number_ready:
 cmp ecx,12
 ja usage
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
 jmp scenario12

scenario1:
 lea rdi,[rel layout_ptr]
 call neboc_int_runtime_layout_get
 test eax,eax
 jnz fail
 mov rbx,[rel layout_ptr]
 test rbx,rbx
 jz fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_BIT_WIDTH_OFFSET],64
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_STORAGE_SIZE_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_STORAGE_ALIGNMENT_OFFSET],8
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_PARAMETER_CLASS_OFFSET],NEBOC_INT_RUNTIME_REGISTER_CLASS_GPR
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_PARAMETER_REGISTER_OFFSET],NEBOC_INT_RUNTIME_PARAMETER_REGISTER_RDI
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_RETURN_REGISTER_OFFSET],NEBOC_INT_RUNTIME_RETURN_REGISTER_RAX
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_RUNTIME_METADATA_OFFSET],0
 jne fail
 cmp qword [rbx+NEBOC_INT_RUNTIME_LAYOUT_FLAGS_OFFSET],NEBOC_INT_RUNTIME_REQUIRED_FLAGS
 jne fail
 jmp pass
scenario2:
 lea rdi,[rel s_decimal]
 mov esi,2
 xor edx,edx
 mov ecx,100
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 call assert_plan_42
 mov rdi,42
 call neboc_int_runtime_identity
 cmp rax,42
 jne fail
 mov rdi,42
 lea rsi,[rel stack_slot]
 call neboc_int_runtime_stack_roundtrip
 cmp rax,42
 jne fail
 cmp qword [rel stack_slot],42
 jne fail
 mov rax,[rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_HASH_OFFSET]
 mov [rel hash_42],rax
 jmp pass
scenario3:
 ; Compare decimal and binary native plans inside this independent process.
 lea rdi,[rel s_decimal]
 mov esi,2
 xor edx,edx
 mov ecx,201
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 mov rax,[rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_HASH_OFFSET]
 mov [rel hash_42],rax
 lea rdi,[rel s_binary]
 mov esi,8
 xor edx,edx
 mov ecx,200
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 call assert_plan_42
 mov rax,[rel hash_42]
 cmp rax,[rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_HASH_OFFSET]
 jne fail
 jmp pass
scenario4:
 lea rdi,[rel s_hex]
 mov esi,4
 xor edx,edx
 mov ecx,300
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 call assert_plan_42
 mov rdi,[rel native+NEBOC_NATIVE_SIGNED_VALUE_OFFSET]
 call neboc_int_runtime_identity
 cmp rax,42
 jne fail
 lea rdi,[rel s_octal]
 mov esi,4
 xor edx,edx
 mov ecx,301
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 call assert_plan_42
 jmp pass
scenario5:
 lea rdi,[rel s_sep]
 mov esi,9
 xor edx,edx
 mov ecx,400
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 call assert_plan_42
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_RUNTIME_METADATA_OFFSET],0
 jne fail
 jmp pass
scenario6:
 lea rdi,[rel s_decimal]
 mov esi,2
 mov edx,NEBOC_SEM_CONTEXT_EXPLICIT_INT
 mov ecx,500
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 call assert_plan_42
 jmp pass
scenario7:
 lea rdi,[rel s_decimal]
 mov esi,2
 mov edx,NEBOC_SEM_CONTEXT_UNARY_MINUS
 mov ecx,600
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 cmp qword [rel native+NEBOC_NATIVE_SIGNED_VALUE_OFFSET],-42
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET],NEBOC_NATIVE_IMMEDIATE_SIGN_EXTENDED_I32
 jne fail
 mov rdi,-42
 call neboc_int_runtime_identity
 cmp rax,-42
 jne fail
 jmp pass
scenario8:
 lea rdi,[rel s_max]
 mov esi,21
 xor edx,edx
 mov ecx,700
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 mov rax,0x7fffffffffffffff
 cmp [rel native+NEBOC_NATIVE_SIGNED_VALUE_OFFSET],rax
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET],NEBOC_NATIVE_IMMEDIATE_I64
 jne fail
 mov rdi,rax
 call neboc_int_runtime_identity
 mov rdx,0x7fffffffffffffff
 cmp rax,rdx
 jne fail
 jmp pass
scenario9:
 lea rdi,[rel s_min_mag]
 mov esi,21
 mov edx,NEBOC_SEM_CONTEXT_UNARY_MINUS
 mov ecx,800
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 mov rax,0x8000000000000000
 cmp [rel native+NEBOC_NATIVE_SIGNED_VALUE_OFFSET],rax
 jne fail
 cmp qword [rel native+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET],NEBOC_NATIVE_IMMEDIATE_I64
 jne fail
 test qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_FLAGS_OFFSET],NEBOC_NATIVE_FLAG_INT64_MIN
 jz fail
 mov rdi,rax
 call neboc_int_runtime_identity
 mov rdx,0x8000000000000000
 cmp rax,rdx
 jne fail
 jmp pass
scenario10:
 lea rdi,[rel s_min_mag]
 mov esi,21
 xor edx,edx
 mov ecx,900
 call prepare
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 call lower_native
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 lea rdi,[rel native]
 mov ecx,neboc_literais_numericos_bases_e_representacao_NATIVE_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_ID_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rel native]
 call neboc_numeric_literal_native_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_SEMANTIC_NOT_VALID
 jne fail
 jmp pass
scenario11:
 lea rdi,[rel s_decimal]
 mov esi,2
 xor edx,edx
 mov ecx,1000
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 inc qword [rel ir+NEBOC_IR_LIR_VALUE_OFFSET]
 lea rdi,[rel native]
 call neboc_numeric_literal_native_lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],NEBOC_NATIVE_ERROR_VALUE_MISMATCH
 jne fail
 jmp pass
scenario12:
 lea rdi,[rel s_binary]
 mov esi,8
 xor edx,edx
 mov ecx,1100
 call prepare
 test eax,eax
 jnz fail
 call lower_native
 test eax,eax
 jnz fail
 mov rbx,[rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_HASH_OFFSET]
 lea rdi,[rel native]
 call neboc_numeric_literal_native_lower
 test eax,eax
 jnz fail
 cmp rbx,[rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_HASH_OFFSET]
 jne fail
 mov qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_ID_OFFSET],99
 lea rdi,[rel native]
 call neboc_numeric_literal_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 cmp qword [rel native+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_TARGET_UNSUPPORTED
 jne fail
 jmp pass

pass:
 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,1
 jmp neboc_host_process_exit
usage:
 mov edi,64
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
