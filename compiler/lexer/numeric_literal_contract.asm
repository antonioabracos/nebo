; Nebo Assembly — LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF002 isolated numeric literal syntax contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/numeric_literal_contract.inc"

section .text

; digit_value(character, base) -> signed digit or -1
NEBOC_ABI_FUNCTION neboc_numeric_digit_value
 mov eax,-1
 cmp esi,NEBOC_NUMERIC_BASE_DECIMAL
 je .decimal
 cmp esi,NEBOC_NUMERIC_BASE_BINARY
 je .binary
 cmp esi,NEBOC_NUMERIC_BASE_OCTAL
 je .octal
 cmp esi,NEBOC_NUMERIC_BASE_HEX
 jne .done
 cmp dil,'0'
 jb .hex_upper
 cmp dil,'9'
 jbe .number
.hex_upper:
 cmp dil,'A'
 jb .hex_lower
 cmp dil,'F'
 ja .hex_lower
 movzx eax,dil
 sub eax,'A'-10
 ret
.hex_lower:
 cmp dil,'a'
 jb .done
 cmp dil,'f'
 ja .done
 movzx eax,dil
 sub eax,'a'-10
 ret
.decimal:
 cmp dil,'0'
 jb .done
 cmp dil,'9'
 ja .done
 jmp .number
.binary:
 cmp dil,'0'
 jb .done
 cmp dil,'1'
 ja .done
 jmp .number
.octal:
 cmp dil,'0'
 jb .done
 cmp dil,'7'
 ja .done
.number:
 movzx eax,dil
 sub eax,'0'
.done:
 ret

; numeric_literal_contract_scan(request*) -> StatusCode
; This is deliberately not called by neboc_lexer_scan in PF002.
NEBOC_ABI_FUNCTION neboc_numeric_literal_contract_scan
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+NEBOC_NUMERIC_SOURCE_OFFSET]
 mov r14,[r12+NEBOC_NUMERIC_LENGTH_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 ; Clear all outputs, preserving input fields 0..31.
 lea rdi,[r12+NEBOC_NUMERIC_TOKEN_KIND_OFFSET]
 mov ecx,(NEBOC_NUMERIC_REQUEST_SIZE-NEBOC_NUMERIC_TOKEN_KIND_OFFSET)/8
 xor eax,eax
 rep stosq
 mov qword [rsp],NEBOC_NUMERIC_BASE_DECIMAL
 mov qword [rsp+8],0
 mov qword [rsp+16],-1
 xor r15d,r15d
 xor ebx,ebx

 ; Prefix classification.
 cmp r14,2
 jb .scan_loop
 cmp byte [r13],'0'
 jne .scan_loop
 movzx eax,byte [r13+1]
 cmp al,'b'
 je .prefix_binary
 cmp al,'x'
 je .prefix_hex
 cmp al,'o'
 je .prefix_octal
 cmp al,'B'
 je .uppercase_prefix
 cmp al,'X'
 je .uppercase_prefix
 cmp al,'O'
 je .uppercase_prefix
 cmp al,'A'
 jb .prefix_lower_alpha
 cmp al,'Z'
 jbe .unknown_prefix
.prefix_lower_alpha:
 cmp al,'a'
 jb .scan_loop
 cmp al,'z'
 jbe .unknown_prefix
 jmp .scan_loop
.prefix_binary:
 mov qword [rsp],NEBOC_NUMERIC_BASE_BINARY
 mov qword [rsp+8],NEBOC_TOKEN_FLAG_INT_BASE_BINARY | neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 mov r15d,2
 jmp .prefix_requires_digit
.prefix_octal:
 mov qword [rsp],NEBOC_NUMERIC_BASE_OCTAL
 mov qword [rsp+8],NEBOC_TOKEN_FLAG_INT_BASE_OCTAL | neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 mov r15d,2
 jmp .prefix_requires_digit
.prefix_hex:
 mov qword [rsp],NEBOC_NUMERIC_BASE_HEX
 mov qword [rsp+8],NEBOC_TOKEN_FLAG_INT_BASE_HEX | neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 mov r15d,2
.prefix_requires_digit:
 cmp r15,r14
 jae .missing_digits
 cmp byte [r13+r15],'_'
 je .separator_error
 jmp .scan_loop

.scan_loop:
 cmp r15,r14
 jae .finish
 movzx edi,byte [r13+r15]
 mov esi,[rsp]
 call neboc_numeric_digit_value
 test eax,eax
 js .not_digit
 mov r10d,eax
 ; Checked accumulation with one reserved magnitude: 2^63 is returned with
 ; INT_MIN_MAGNITUDE and remains a later unary-minus semantic decision.
 mov rcx,[rsp]
 cmp rcx,10
 je .limit_decimal
 cmp rcx,2
 je .limit_binary
 cmp rcx,8
 je .limit_octal
 mov rdx,0x0800000000000000
 xor r11d,r11d
 jmp .check_limit
.limit_binary:
 mov rdx,0x4000000000000000
 xor r11d,r11d
 jmp .check_limit
.limit_octal:
 mov rdx,0x1000000000000000
 xor r11d,r11d
 jmp .check_limit
.limit_decimal:
 mov rdx,922337203685477580
 mov r11d,8
.check_limit:
 cmp rbx,rdx
 ja .overflow
 jne .accumulate
 cmp r10d,r11d
 ja .overflow
.accumulate:
 imul rbx,rcx
 add rbx,r10
 inc qword [r12+NEBOC_NUMERIC_DIGIT_COUNT_OFFSET]
 inc r15
 jmp .scan_loop

.not_digit:
 movzx eax,byte [r13+r15]
 cmp al,'_'
 je .separator
 cmp al,'.'
 je .dot
 cmp al,'0'
 jb .suffix_or_invalid
 cmp al,'9'
 jbe .invalid_digit
.suffix_or_invalid:
 cmp al,'A'
 jb .lower_suffix
 cmp al,'Z'
 jbe .suffix
.lower_suffix:
 cmp al,'a'
 jb .invalid_digit
 cmp al,'z'
 jbe .suffix
 jmp .invalid_digit
.suffix:
 cmp qword [r12+NEBOC_NUMERIC_DIGIT_COUNT_OFFSET],0
 je .invalid_digit
 mov r10d,NEBOC_NUMERIC_DIAG_SUFFIX_UNAVAILABLE
 mov r11,r15
 jmp .error_one
.dot:
 cmp qword [r12+NEBOC_NUMERIC_SEPARATOR_COUNT_OFFSET],0
 je .invalid_digit
 mov r10d,NEBOC_NUMERIC_DIAG_FLOAT_SEPARATOR_UNAVAILABLE
 mov r11,[rsp+16]
 jmp .error_one
.separator:
 cmp qword [r12+NEBOC_NUMERIC_DIGIT_COUNT_OFFSET],0
 je .separator_error
 lea rax,[r15+1]
 cmp rax,r14
 jae .separator_error
 movzx edi,byte [r13+rax]
 mov esi,[rsp]
 call neboc_numeric_digit_value
 test eax,eax
 js .separator_error
 cmp qword [rsp+16],-1
 jne .separator_seen
 mov [rsp+16],r15
.separator_seen:
 inc qword [r12+NEBOC_NUMERIC_SEPARATOR_COUNT_OFFSET]
 or qword [rsp+8],NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR | neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
 inc r15
 jmp .scan_loop

.finish:
 cmp qword [r12+NEBOC_NUMERIC_DIGIT_COUNT_OFFSET],0
 je .missing_digits
 mov rax,[r12+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET]
 mov [r12+NEBOC_NUMERIC_TOKEN_START_OFFSET],rax
 add rax,r14
 mov [r12+NEBOC_NUMERIC_TOKEN_END_OFFSET],rax
 mov qword [r12+NEBOC_NUMERIC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 mov rax,[rsp+8]
 mov rdx,0x8000000000000000
 cmp rbx,rdx
 jne .store_flags
 or rax,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
.store_flags:
 mov [r12+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET],rax
 mov [r12+NEBOC_NUMERIC_VALUE_OFFSET],rbx
 mov rax,[rsp]
 mov [r12+NEBOC_NUMERIC_BASE_OFFSET],rax
 call .hash_result
 xor eax,eax
 jmp .done

.uppercase_prefix:
 mov r10d,NEBOC_NUMERIC_DIAG_UPPERCASE_PREFIX
 mov r11d,1
 jmp .error_one
.unknown_prefix:
 mov r10d,NEBOC_NUMERIC_DIAG_UNKNOWN_PREFIX
 mov r11d,1
 jmp .error_one
.missing_digits:
 mov r10d,NEBOC_NUMERIC_DIAG_MISSING_DIGITS
 mov r11,r14
 jmp .error_zero
.separator_error:
 mov r10d,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR
 mov r11,r15
 jmp .error_one
.invalid_digit:
 mov r10d,NEBOC_NUMERIC_DIAG_INVALID_DIGIT
 mov r11,r15
 jmp .error_one
.overflow:
 mov r10d,NEBOC_NUMERIC_DIAG_OVERFLOW
 mov r11,r15
 jmp .error_one

.error_one:
 mov rax,[r12+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET]
 add rax,r11
 mov [r12+NEBOC_NUMERIC_ERROR_START_OFFSET],rax
 inc rax
 mov [r12+NEBOC_NUMERIC_ERROR_END_OFFSET],rax
 jmp .error_common
.error_zero:
 mov rax,[r12+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET]
 add rax,r11
 mov [r12+NEBOC_NUMERIC_ERROR_START_OFFSET],rax
 mov [r12+NEBOC_NUMERIC_ERROR_END_OFFSET],rax
.error_common:
 mov [r12+NEBOC_NUMERIC_ERROR_CODE_OFFSET],r10
 mov qword [r12+NEBOC_NUMERIC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID
 mov qword [r12+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_ERROR
 mov rax,[r12+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET]
 mov [r12+NEBOC_NUMERIC_TOKEN_START_OFFSET],rax
 add rax,r14
 mov [r12+NEBOC_NUMERIC_TOKEN_END_OFFSET],rax
 call .hash_result
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done

.hash_result:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor edx,edx
.hash_source:
 cmp rdx,r14
 jae .hash_fields
 movzx r10d,byte [r13+rdx]
 xor rax,r10
 imul rax,rcx
 inc rdx
 jmp .hash_source
.hash_fields:
 xor rax,[r12+NEBOC_NUMERIC_TOKEN_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NUMERIC_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NUMERIC_BASE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NUMERIC_ERROR_CODE_OFFSET]
 imul rax,rcx
 mov [r12+NEBOC_NUMERIC_HASH_OFFSET],rax
 ret

.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
