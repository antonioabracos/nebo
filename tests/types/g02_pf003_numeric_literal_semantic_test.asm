; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF003 numeric literal semantic model and abstract IR invariant tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/semantic/types/numeric_literal_semantic.inc"
%include "compiler/lowering/scalars/numeric_literal_ir_contract.inc"
extern neboc_numeric_literal_contract_scan
extern neboc_numeric_literal_semantic_analyze
extern neboc_numeric_literal_ir_lower
extern neboc_host_process_exit

section .rodata
s_decimal: db '42'
s_binary: db '0b101010'
s_hex_upper: db '0x2A'
s_hex_lower: db '0x2a'
s_octal: db '0o52'
s_sep: db '1_000'
s_max: db '9223372036854775807'
s_min_mag: db '0x8000_0000_0000_0000'
s_invalid: db '0b102'

section .bss align=16
scan: resb NEBOC_NUMERIC_REQUEST_SIZE
sem: resb neboc_literais_numericos_bases_e_representacao_SEM_REQUEST_SIZE
ir: resb neboc_literais_numericos_bases_e_representacao_IR_REQUEST_SIZE
semantic_42: resq 1
provenance_first: resq 1
ir_42: resq 1

section .text

; prepare(source,length,context,token_index,start) -> status from semantic analysis
prepare:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 lea rdi,[rel scan]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov [rel scan+NEBOC_NUMERIC_SOURCE_OFFSET],r12
 mov [rel scan+NEBOC_NUMERIC_LENGTH_OFFSET],r13
 mov qword [rel scan+NEBOC_NUMERIC_SOURCE_ID_OFFSET],77
 mov [rel scan+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],rbx
 lea rdi,[rel scan]
 call neboc_numeric_literal_contract_scan
 mov [rsp],rax
 lea rdi,[rel sem]
 mov ecx,neboc_literais_numericos_bases_e_representacao_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel scan]
 mov [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SYNTAX_REQUEST_OFFSET],rax
 mov [rel sem+NEBOC_SEM_CONTEXT_FLAGS_OFFSET],r14
 mov [rel sem+NEBOC_SEM_AST_TOKEN_INDEX_OFFSET],r15
 mov qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_AST_SOURCE_ID_OFFSET],77
 mov [rel sem+NEBOC_SEM_AST_START_OFFSET],rbx
 add rbx,r13
 mov [rel sem+NEBOC_SEM_AST_END_OFFSET],rbx
 lea rdi,[rel sem]
 call neboc_numeric_literal_semantic_analyze
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

lower_ir:
 lea rdi,[rel ir]
 mov ecx,neboc_literais_numericos_bases_e_representacao_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_literais_numericos_bases_e_representacao_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rel ir]
 jmp neboc_numeric_literal_ir_lower

assert_common_42:
 cmp qword [rel sem+NEBOC_SEM_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel sem+NEBOC_SEM_SIGNED_VALUE_OFFSET],42
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_VALID
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_INT_CONSTANT
 jne fail
 cmp qword [rel sem+NEBOC_SEM_LIR_REPR_OFFSET],NEBOC_SEM_LIR_SIGNED_I64
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

assert_ir_42:
 call lower_ir
 test eax,eax
 jnz fail
 cmp qword [rel ir+NEBOC_IR_HIR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel ir+NEBOC_IR_HIR_VALUE_OFFSET],42
 jne fail
 cmp qword [rel ir+neboc_literais_numericos_bases_e_representacao_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_IMMEDIATE_I64
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_WIDTH_OFFSET],64
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_SIGNED_OFFSET],1
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_VALUE_OFFSET],42
 jne fail
 cmp qword [rel ir+neboc_literais_numericos_bases_e_representacao_IR_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

global _start
_start:
 ; 1. Decimal implicit: canonical Int constant and abstract IR.
 lea rdi,[rel s_decimal]
 mov esi,2
 xor edx,edx
 mov ecx,3
 mov r8d,100
 call prepare
 test eax,eax
 jnz fail
 call assert_common_42
 call assert_ir_42
 mov rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel semantic_42],rax
 mov rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel provenance_first],rax
 mov rax,[rel ir+neboc_literais_numericos_bases_e_representacao_IR_HASH_OFFSET]
 mov [rel ir_42],rax

 ; 2. Decimal explicit Int(...) has identical semantics/IR, distinct provenance.
 lea rdi,[rel s_decimal]
 mov esi,2
 mov edx,NEBOC_SEM_CONTEXT_EXPLICIT_INT
 mov ecx,9
 mov r8d,200
 call prepare
 test eax,eax
 jnz fail
 call assert_common_42
 call assert_ir_42
 mov rax,[rel semantic_42]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel ir_42]
 cmp rax,[rel ir+neboc_literais_numericos_bases_e_representacao_IR_HASH_OFFSET]
 jne fail
 mov rax,[rel provenance_first]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 je fail
 test qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET],NEBOC_SEM_FLAG_EXPLICIT_INT
 jz fail

 ; 3. Binary spelling normalizes to same semantic and IR hashes.
 lea rdi,[rel s_binary]
 mov esi,8
 xor edx,edx
 mov ecx,4
 mov r8d,300
 call prepare
 test eax,eax
 jnz fail
 call assert_common_42
 call assert_ir_42
 mov rax,[rel semantic_42]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel ir_42]
 cmp rax,[rel ir+neboc_literais_numericos_bases_e_representacao_IR_HASH_OFFSET]
 jne fail
 cmp qword [rel sem+NEBOC_SEM_PROVENANCE_BASE_OFFSET],2
 jne fail

 ; 4. Hex uppercase digits normalize to 42.
 lea rdi,[rel s_hex_upper]
 mov esi,4
 xor edx,edx
 mov ecx,5
 mov r8d,400
 call prepare
 test eax,eax
 jnz fail
 call assert_common_42
 mov rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel provenance_first],rax

 ; 5. Hex lowercase digits are semantically equal but provenance-distinct.
 lea rdi,[rel s_hex_lower]
 mov esi,4
 xor edx,edx
 mov ecx,5
 mov r8d,400
 call prepare
 test eax,eax
 jnz fail
 call assert_common_42
 mov rax,[rel semantic_42]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel provenance_first]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 je fail

 ; 6. Octal spelling normalizes to same semantic value.
 lea rdi,[rel s_octal]
 mov esi,4
 xor edx,edx
 mov ecx,6
 mov r8d,500
 call prepare
 test eax,eax
 jnz fail
 call assert_common_42
 cmp qword [rel sem+NEBOC_SEM_PROVENANCE_BASE_OFFSET],8
 jne fail

 ; 7. Separator metadata remains compile-time only.
 lea rdi,[rel s_sep]
 mov esi,5
 xor edx,edx
 mov ecx,7
 mov r8d,600
 call prepare
 test eax,eax
 jnz fail
 cmp qword [rel sem+NEBOC_SEM_SIGNED_VALUE_OFFSET],1000
 jne fail
 cmp qword [rel sem+NEBOC_SEM_PROVENANCE_SEPARATORS_OFFSET],1
 jne fail
 test qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET],NEBOC_SEM_FLAG_SEPARATOR_PROVENANCE
 jz fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_OFFSET],0
 jne fail
 call lower_ir
 test eax,eax
 jnz fail
 cmp qword [rel ir+neboc_literais_numericos_bases_e_representacao_IR_RUNTIME_METADATA_OFFSET],0
 jne fail

 ; 8. Unary minus on ordinary magnitude produces checked signed constant.
 lea rdi,[rel s_decimal]
 mov esi,2
 mov edx,NEBOC_SEM_CONTEXT_UNARY_MINUS
 mov ecx,8
 mov r8d,700
 call prepare
 test eax,eax
 jnz fail
 cmp qword [rel sem+NEBOC_SEM_SIGNED_VALUE_OFFSET],-42
 jne fail
 test qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET],NEBOC_SEM_FLAG_UNARY_MINUS
 jz fail

 ; 9. INT64_MAX remains valid.
 lea rdi,[rel s_max]
 mov esi,19
 xor edx,edx
 mov ecx,9
 mov r8d,800
 call prepare
 test eax,eax
 jnz fail
 mov rax,0x7fffffffffffffff
 cmp [rel sem+NEBOC_SEM_SIGNED_VALUE_OFFSET],rax
 jne fail

 ; 10. Reserved 2^63 under unary minus becomes INT64_MIN.
 lea rdi,[rel s_min_mag]
 mov esi,21
 mov edx,NEBOC_SEM_CONTEXT_UNARY_MINUS
 mov ecx,10
 mov r8d,900
 call prepare
 test eax,eax
 jnz fail
 mov rax,0x8000000000000000
 cmp [rel sem+NEBOC_SEM_SIGNED_VALUE_OFFSET],rax
 jne fail
 test qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET],NEBOC_SEM_FLAG_INT64_MIN
 jz fail
 call lower_ir
 test eax,eax
 jnz fail

 ; 11. Positive 2^63 is a semantic overflow with whole-token span.
 lea rdi,[rel s_min_mag]
 mov esi,21
 xor edx,edx
 mov ecx,11
 mov r8d,1000
 call prepare
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_POSITIVE_MAGNITUDE_OVERFLOW
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SOURCE_DIAG_OFFSET],NEBOC_NUMERIC_DIAG_OVERFLOW
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_START_OFFSET],1000
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_END_OFFSET],1021
 jne fail
 call lower_ir
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 ; 12. Scanner diagnostic is propagated with its exact offending-byte span.
 lea rdi,[rel s_invalid]
 mov esi,5
 xor edx,edx
 mov ecx,12
 mov r8d,1100
 call prepare
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_SYNTAX_INVALID
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SOURCE_DIAG_OFFSET],NEBOC_NUMERIC_DIAG_INVALID_DIGIT
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_START_OFFSET],1104
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_END_OFFSET],1105
 jne fail

 ; 13. AST span tampering is an internal invariant failure.
 lea rdi,[rel s_binary]
 mov esi,8
 xor edx,edx
 mov ecx,13
 mov r8d,1200
 call prepare
 test eax,eax
 jnz fail
 inc qword [rel sem+NEBOC_SEM_AST_END_OFFSET]
 lea rdi,[rel sem]
 call neboc_numeric_literal_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_ERROR_SPAN_INVARIANT
 jne fail

 ; 14. Base flag tampering is an internal provenance failure.
 lea rdi,[rel s_binary]
 mov esi,8
 xor edx,edx
 mov ecx,14
 mov r8d,1300
 call prepare
 test eax,eax
 jnz fail
 mov qword [rel scan+NEBOC_NUMERIC_BASE_OFFSET],16
 lea rdi,[rel sem]
 call neboc_numeric_literal_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_PROVENANCE_INVARIANT
 jne fail

 ; 15. Unknown context bits are rejected as an internal contract error.
 lea rdi,[rel s_decimal]
 mov esi,2
 mov edx,8
 mov ecx,15
 mov r8d,1400
 call prepare
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CONTEXT_INVARIANT
 jne fail

 ; 16. Exact repeated request is deterministic.
 lea rdi,[rel s_binary]
 mov esi,8
 xor edx,edx
 mov ecx,16
 mov r8d,1500
 call prepare
 test eax,eax
 jnz fail
 mov rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel semantic_42],rax
 mov rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel provenance_first],rax
 call lower_ir
 test eax,eax
 jnz fail
 mov rax,[rel ir+neboc_literais_numericos_bases_e_representacao_IR_HASH_OFFSET]
 mov [rel ir_42],rax
 lea rdi,[rel sem]
 call neboc_numeric_literal_semantic_analyze
 test eax,eax
 jnz fail
 mov rax,[rel semantic_42]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel provenance_first]
 cmp rax,[rel sem+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 jne fail
 call lower_ir
 test eax,eax
 jnz fail
 mov rax,[rel ir_42]
 cmp rax,[rel ir+neboc_literais_numericos_bases_e_representacao_IR_HASH_OFFSET]
 jne fail

 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
