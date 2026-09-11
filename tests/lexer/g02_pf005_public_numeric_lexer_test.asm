bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
extern neboc_lexer_scan
extern neboc_host_process_exit
section .rodata
s1: db '1_000'
s2: db '0b101010'
s3: db '0o52'
s4: db '0x2A'
s5: db '0x7fff_ffff_ffff_ffff'
s6: db '0x'
s7: db '0b102'
s8: db '0x_1'
s9: db '1__0'
s10: db '0X2A'
s11: db '0q10'
s12: db '42i64'
s13: db '0x8000_0000_0000_0000'
s14: db '1_0.5'
s15: db '-0x8000_0000_0000_0000'
s16: db '0x2A.answer'
section .bss align=16
req: resb NEBOC_LEXER_REQUEST_SIZE
toks: resb 8*NEBOC_TOKEN_SIZE
literal: resb 64
current_case: resq 1
section .text
run:
 ; RDI source, RSI length
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 lea rdi,[rel req]
 mov ecx,NEBOC_LEXER_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel toks]
 mov ecx,8*NEBOC_TOKEN_QWORDS
 xor eax,eax
 rep stosq
 mov [rel req+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rbx
 mov [rel req+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],r12
 mov qword [rel req+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],77
 lea rax,[rel toks]
 mov [rel req+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel req+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],8
 lea rax,[rel literal]
 mov [rel req+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel req+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],64
 mov rax,r12
 imul rax,NEBOC_LEXER_DEFAULT_STEP_FACTOR
 add rax,64
 mov [rel req+NEBOC_LEXER_REQUEST_STEP_BUDGET_OFFSET],rax
 lea rdi,[rel req]
 call neboc_lexer_scan
 pop r12
 pop rbx
 ret
check_valid:
 ; RDI source, RSI len, RDX value, RCX flags
 push rbx
 push r12
 push r13
 mov rbx,rdx
 mov r12,rcx
 mov r13,rsi
 call run
 test eax,eax
 jnz fail
 cmp qword [rel req+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 cmp qword [rel req+NEBOC_LEXER_REQUEST_COUNT_OFFSET],2
 jne fail
 lea rax,[rel toks]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne fail
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rbx
 jne fail
 cmp [rax+NEBOC_TOKEN_FLAGS_OFFSET],r12
 jne fail
 cmp qword [rax+NEBOC_TOKEN_START_OFFSET],0
 jne fail
 cmp [rax+NEBOC_TOKEN_END_OFFSET],r13
 jne fail
 pop r13
 pop r12
 pop rbx
 ret
check_invalid:
 ; RDI source, RSI len, RDX diag, RCX err_start, R8 err_end
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdx
 mov r12,rcx
 mov r13,r8
 call run
 test eax,eax
 jnz fail
 cmp qword [rel req+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne fail
 lea rax,[rel toks]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID_NUMERIC_LITERAL
 jne fail
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rbx
 jne fail
 cmp [rax+NEBOC_TOKEN_START_OFFSET],r12
 jne fail
 cmp [rax+NEBOC_TOKEN_END_OFFSET],r13
 jne fail
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
global _start
_start:
 mov qword [rel current_case],1
 lea rdi,[rel s1]
 mov esi,5
 mov edx,1000
 mov ecx,NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR
 call check_valid
 mov qword [rel current_case],2
 lea rdi,[rel s2]
 mov esi,8
 mov edx,42
 mov ecx,NEBOC_TOKEN_FLAG_INT_BASE_BINARY
 call check_valid
 mov qword [rel current_case],3
 lea rdi,[rel s3]
 mov esi,4
 mov edx,42
 mov ecx,NEBOC_TOKEN_FLAG_INT_BASE_OCTAL
 call check_valid
 mov qword [rel current_case],4
 lea rdi,[rel s4]
 mov esi,4
 mov edx,42
 mov ecx,NEBOC_TOKEN_FLAG_INT_BASE_HEX
 call check_valid
 mov qword [rel current_case],5
 lea rdi,[rel s5]
 mov esi,21
 mov rdx,0x7fffffffffffffff
 mov ecx,NEBOC_TOKEN_FLAG_INT_BASE_HEX|NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR
 call check_valid
 mov qword [rel current_case],6
 lea rdi,[rel s6]
 mov esi,2
 mov edx,NEBOC_NUMERIC_DIAG_MISSING_DIGITS
 mov ecx,2
 mov r8d,2
 call check_invalid
 mov qword [rel current_case],7
 lea rdi,[rel s7]
 mov esi,5
 mov edx,NEBOC_NUMERIC_DIAG_INVALID_DIGIT
 mov ecx,4
 mov r8d,5
 call check_invalid
 mov qword [rel current_case],8
 lea rdi,[rel s8]
 mov esi,4
 mov edx,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR
 mov ecx,2
 mov r8d,3
 call check_invalid
 mov qword [rel current_case],9
 lea rdi,[rel s9]
 mov esi,4
 mov edx,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR
 mov ecx,1
 mov r8d,2
 call check_invalid
 mov qword [rel current_case],10
 lea rdi,[rel s10]
 mov esi,4
 mov edx,NEBOC_NUMERIC_DIAG_UPPERCASE_PREFIX
 mov ecx,1
 mov r8d,2
 call check_invalid
 mov qword [rel current_case],11
 lea rdi,[rel s11]
 mov esi,4
 mov edx,NEBOC_NUMERIC_DIAG_UNKNOWN_PREFIX
 mov ecx,1
 mov r8d,2
 call check_invalid
 mov qword [rel current_case],12
 lea rdi,[rel s12]
 mov esi,5
 mov edx,NEBOC_NUMERIC_DIAG_SUFFIX_UNAVAILABLE
 mov ecx,2
 mov r8d,3
 call check_invalid
 mov qword [rel current_case],13
 lea rdi,[rel s13]
 mov esi,21
 mov edx,NEBOC_NUMERIC_DIAG_OVERFLOW
 xor ecx,ecx
 mov r8d,21
 call check_invalid
 mov qword [rel current_case],14
 lea rdi,[rel s14]
 mov esi,5
 mov edx,NEBOC_NUMERIC_DIAG_FLOAT_SEPARATOR_UNAVAILABLE
 mov ecx,1
 mov r8d,2
 call check_invalid
 ; Unary INT64_MIN accepted: minus, integer, EOF.
 mov qword [rel current_case],15
 lea rdi,[rel s15]
 mov esi,22
 call run
 test eax,eax
 jnz fail
 cmp qword [rel req+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 cmp qword [rel req+NEBOC_LEXER_REQUEST_COUNT_OFFSET],2
 jne fail
 lea rax,[rel toks]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne fail
 cmp qword [rax+NEBOC_TOKEN_START_OFFSET],0
 jne fail
 cmp qword [rax+NEBOC_TOKEN_END_OFFSET],22
 jne fail
 mov rdx,0x8000000000000000
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rdx
 jne fail
 mov rdx,[rax+NEBOC_TOKEN_FLAGS_OFFSET]
 and rdx,NEBOC_TOKEN_FLAG_INT_BASE_MASK|NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 cmp rdx,NEBOC_TOKEN_FLAG_INT_BASE_HEX|NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 jne fail
 ; Literal span is preserved before receiver dot.
 mov qword [rel current_case],16
 lea rdi,[rel s16]
 mov esi,11
 call run
 test eax,eax
 jnz fail
 cmp qword [rel req+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 lea rax,[rel toks]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne fail
 cmp qword [rax+NEBOC_TOKEN_END_OFFSET],4
 jne fail
 xor edi,edi
 call neboc_host_process_exit
fail:
 mov rdi,[rel current_case]
 test rdi,rdi
 jnz .fail_exit
 mov edi,1
.fail_exit:
 call neboc_host_process_exit
