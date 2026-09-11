; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF005 public Option/Result vertical bridge test
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/parser/option_result_vertical_parser.inc"
%include "compiler/semantic/types/option_result_vertical.inc"
%include "compiler/lowering/scalars/option_result_native_lowering.inc"
extern neboc_lexer_scan
extern neboc_option_result_vertical_parse
extern neboc_option_result_vertical_analyze
extern neboc_host_process_exit

section .rodata
positive_source: db 'start(){Option<Int>(Some(42)).maybe;maybe.isSome().flag;maybe.unwrapOr(7).value;}'
positive_source_len equ $-positive_source
negative_source: db 'start(){missing.isSome().flag;}'
negative_source_len equ $-negative_source
arity_option_missing_source: db 'start(){Option<>(Some(1)).value;}'
arity_option_missing_source_len equ $-arity_option_missing_source
arity_option_extra_source: db 'start(){Option<Int,Bool>(Some(1)).value;}'
arity_option_extra_source_len equ $-arity_option_extra_source
arity_result_missing_source: db 'start(){Result<Int>(Ok(1)).value;}'
arity_result_missing_source_len equ $-arity_result_missing_source
arity_result_extra_source: db 'start(){Result<Int,Bool,Char>(Ok(1)).value;}'
arity_result_extra_source_len equ $-arity_result_extra_source

section .bss align=16
lexer_request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb 128*NEBOC_TOKEN_SIZE
literal_bytes: resb 512
parse_request: resb NEBOC_VPARSE_REQUEST_SIZE
operations: resb NEBOC_VERTICAL_MAX_OPERATIONS*NEBOC_VOP_RECORD_SIZE
sem_request: resb NEBOC_VSEM_REQUEST_SIZE
symbols: resb neboc_option_result_null_externo_e_erros_tipados_VERTICAL_MAX_SYMBOLS*NEBOC_VSYM_RECORD_SIZE

section .text
global _start

; RDI=source, RSI=length -> status. Leaves populated vertical buffers.
run_vertical:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 lea rdi,[rel lexer_request]
 mov ecx,NEBOC_LEXER_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel tokens]
 mov ecx,(128*NEBOC_TOKEN_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel literal_bytes]
 mov ecx,512/8
 xor eax,eax
 rep stosq
 lea rdi,[rel parse_request]
 mov ecx,NEBOC_VPARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel operations]
 mov ecx,(NEBOC_VERTICAL_MAX_OPERATIONS*NEBOC_VOP_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel sem_request]
 mov ecx,NEBOC_VSEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel symbols]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_VERTICAL_MAX_SYMBOLS*NEBOC_VSYM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 mov [rel lexer_request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],r12
 mov [rel lexer_request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],r13
 mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],1
 lea rax,[rel tokens]
 mov [rel lexer_request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],128
 lea rax,[rel literal_bytes]
 mov [rel lexer_request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],512
 mov rax,r13
 imul rax,NEBOC_LEXER_DEFAULT_STEP_FACTOR
 add rax,64
 mov [rel lexer_request+NEBOC_LEXER_REQUEST_STEP_BUDGET_OFFSET],rax
 lea rdi,[rel lexer_request]
 call neboc_lexer_scan
 test eax,eax
 jnz .done
 cmp qword [rel lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .invalid_source
 mov [rel parse_request+NEBOC_VPARSE_SOURCE_OFFSET],r12
 mov [rel parse_request+NEBOC_VPARSE_SOURCE_LENGTH_OFFSET],r13
 lea rax,[rel tokens]
 mov [rel parse_request+NEBOC_VPARSE_TOKENS_OFFSET],rax
 mov rax,[rel lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel parse_request+NEBOC_VPARSE_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel operations]
 mov [rel parse_request+NEBOC_VPARSE_OPERATIONS_OFFSET],rax
 mov qword [rel parse_request+NEBOC_VPARSE_OPERATION_CAPACITY_OFFSET],NEBOC_VERTICAL_MAX_OPERATIONS
 lea rdi,[rel parse_request]
 call neboc_option_result_vertical_parse
 test eax,eax
 jnz .done
 cmp qword [rel parse_request+NEBOC_VPARSE_FOUND_OFFSET],1
 jne .invalid_source
 mov [rel sem_request+NEBOC_VSEM_SOURCE_OFFSET],r12
 mov [rel sem_request+NEBOC_VSEM_SOURCE_LENGTH_OFFSET],r13
 lea rax,[rel tokens]
 mov [rel sem_request+NEBOC_VSEM_TOKENS_OFFSET],rax
 mov rax,[rel lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel sem_request+NEBOC_VSEM_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel operations]
 mov [rel sem_request+NEBOC_VSEM_OPERATIONS_OFFSET],rax
 mov rax,[rel parse_request+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 mov [rel sem_request+NEBOC_VSEM_OPERATION_COUNT_OFFSET],rax
 lea rax,[rel symbols]
 mov [rel sem_request+NEBOC_VSEM_SYMBOLS_OFFSET],rax
 mov qword [rel sem_request+NEBOC_VSEM_SYMBOL_CAPACITY_OFFSET],neboc_option_result_null_externo_e_erros_tipados_VERTICAL_MAX_SYMBOLS
 lea rdi,[rel sem_request]
 call neboc_option_result_vertical_analyze
 jmp .done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

_start:
 lea rdi,[rel positive_source]
 mov esi,positive_source_len
 call run_vertical
 test eax,eax
 jnz .fail_1
 cmp qword [rel parse_request+NEBOC_VPARSE_OPERATION_COUNT_OFFSET],3
 jne .fail_2
 cmp qword [rel sem_request+NEBOC_VSEM_OPERATION_VALIDATED_OFFSET],3
 jne .fail_3
 cmp qword [rel sem_request+NEBOC_VSEM_SYMBOL_COUNT_OFFSET],3
 jne .fail_4
 cmp qword [rel sem_request+NEBOC_VSEM_FRAME_SIZE_OFFSET],32
 jne .fail_5
 lea rax,[rel operations]
 cmp qword [rax+NEBOC_VOP_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_STORE_INTEGER
 jne .fail_6
 add rax,NEBOC_VOP_RECORD_SIZE
 cmp qword [rax+NEBOC_VOP_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_TAG_TEST
 jne .fail_7
 add rax,NEBOC_VOP_RECORD_SIZE
 cmp qword [rax+NEBOC_VOP_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_UNWRAP_INTEGER
 jne .fail_8
 lea rdi,[rel negative_source]
 mov esi,negative_source_len
 call run_vertical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail_9
 cmp qword [rel sem_request+NEBOC_VSEM_ERROR_CODE_OFFSET],NEBOC_DIAG_UNKNOWN_BINDING
 jne .fail_10
 lea rdi,[rel arity_option_missing_source]
 mov esi,arity_option_missing_source_len
 call run_vertical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail_11
 cmp qword [rel parse_request+NEBOC_VPARSE_ERROR_CODE_OFFSET],NEBOC_DIAG_TYPE_ARITY
 jne .fail_12
 lea rdi,[rel arity_option_extra_source]
 mov esi,arity_option_extra_source_len
 call run_vertical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail_13
 cmp qword [rel parse_request+NEBOC_VPARSE_ERROR_CODE_OFFSET],NEBOC_DIAG_TYPE_ARITY
 jne .fail_14
 lea rdi,[rel arity_result_missing_source]
 mov esi,arity_result_missing_source_len
 call run_vertical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail_15
 cmp qword [rel parse_request+NEBOC_VPARSE_ERROR_CODE_OFFSET],NEBOC_DIAG_TYPE_ARITY
 jne .fail_16
 lea rdi,[rel arity_result_extra_source]
 mov esi,arity_result_extra_source_len
 call run_vertical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail_17
 cmp qword [rel parse_request+NEBOC_VPARSE_ERROR_CODE_OFFSET],NEBOC_DIAG_TYPE_ARITY
 jne .fail_18
 xor edi,edi
 jmp neboc_host_process_exit
.fail_1: mov edi,1
 jmp neboc_host_process_exit
.fail_2: mov edi,2
 jmp neboc_host_process_exit
.fail_3: mov edi,3
 jmp neboc_host_process_exit
.fail_4: mov edi,4
 jmp neboc_host_process_exit
.fail_5: mov edi,5
 jmp neboc_host_process_exit
.fail_6: mov edi,6
 jmp neboc_host_process_exit
.fail_7: mov edi,7
 jmp neboc_host_process_exit
.fail_8: mov edi,8
 jmp neboc_host_process_exit
.fail_9: mov edi,9
 jmp neboc_host_process_exit
.fail_10: mov edi,10
 jmp neboc_host_process_exit
.fail_11: mov edi,11
 jmp neboc_host_process_exit
.fail_12: mov edi,12
 jmp neboc_host_process_exit
.fail_13: mov edi,13
 jmp neboc_host_process_exit
.fail_14: mov edi,14
 jmp neboc_host_process_exit
.fail_15: mov edi,15
 jmp neboc_host_process_exit
.fail_16: mov edi,16
 jmp neboc_host_process_exit
.fail_17: mov edi,17
 jmp neboc_host_process_exit
.fail_18: mov edi,18
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
