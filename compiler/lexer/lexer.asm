; Nebo Assembly — complete Core v0.1 lexer
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry_generated.inc"
%include "compiler/tokens/unicode_alias_contract.inc"
%include "compiler/source/utf8/unicode_source_security.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
extern neboc_token_keyword_kind
extern neboc_numeric_literal_contract_scan
extern neboc_char_literal_contract_scan

section .text
; lexer_scan(LexerRequest*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_lexer_scan
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,176
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_LEXER_REQUEST_SOURCE_OFFSET]
 mov r14,[r12+NEBOC_LEXER_REQUEST_LENGTH_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],1
 jb .invalid
 mov qword [r12+NEBOC_LEXER_REQUEST_COUNT_OFFSET],0
 mov qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 mov qword [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],0
 xor r15d,r15d
 xor ebx,ebx

.loop:
 cmp r15,r14
 jae .emit_eof
 mov qword [rsp+8],0
 mov qword [rsp+160],0
 mov qword [rsp+168],0
 movzx eax,byte [r13+r15]
 cmp al,32
 je .skip_one
 cmp al,9
 je .skip_one
 cmp al,10
 je .skip_one
 cmp al,13
 je .skip_one
 cmp al,'0'
 jb .not_digit
 cmp al,'9'
 jbe .integer
.not_digit:
 cmp al,39
 je .char
 cmp al,'"'
 je .text
 cmp al,0x80
 jae .unicode_identifier
 cmp al,'A'
 jb .operators
 cmp al,'Z'
 jbe .identifier
 cmp al,'a'
 jb .underscore
 cmp al,'z'
 jbe .identifier
.underscore:
 cmp al,'_'
 je .identifier
 jmp .operators

.identifier:
 mov r11,r15
 mov [rsp],r11
 inc r15
.id_continue:
 cmp r15,r14
 jae .id_done
 movzx eax,byte [r13+r15]
 cmp al,'A'
 jb .id_digit
 cmp al,'Z'
 jbe .id_take
 cmp al,'a'
 jb .id_underscore
 cmp al,'z'
 jbe .id_take
.id_digit:
 cmp al,'0'
 jb .id_done
 cmp al,'9'
 jbe .id_take
.id_underscore:
 cmp al,'_'
 jne .id_done
.id_take:
 inc r15
 jmp .id_continue
.id_done:
 mov r11,[rsp]
 lea rdi,[r13+r11]
 mov rsi,r15
 sub rsi,r11
 call neboc_token_keyword_kind
 mov r11,[rsp]
 test eax,eax
 jnz .id_keyword
 mov r10d,NEBOC_TOKEN_IDENTIFIER
 xor r9d,r9d
 jmp .emit
.id_keyword:
 mov r10d,eax
 xor r9d,r9d
 cmp r10d,NEBOC_TOKEN_KW_FOR
 jb .emit
 cmp r10d,NEBOC_TOKEN_KW_GENERIC
 ja .emit
 mov r9d,NEBOC_TOKEN_FLAG_DEFERRED
 jmp .emit

.unicode_identifier:
 ; P03 aliases are exact UTF-8 spellings and retain their source spans while
 ; lowering to the already-existing ASCII semantic token kind.
 mov r11,r15
 lea rax,[r15+2]
 cmp rax,r14
 ja .unicode_arithmetic_three
 cmp byte [r13+r15],0xc2
 jne .unicode_divide
 cmp byte [r13+r15+1],0xac
 jne .unicode_divide
 add r15,2
 mov r10d,NEBOC_UNICODE_ALIAS_NOT_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_divide:
 cmp byte [r13+r15],0xc3
 jne .unicode_arithmetic_three
 cmp byte [r13+r15+1],0xb7
 jne .unicode_arithmetic_three
 add r15,2
 mov r10d,NEBOC_UNICODE_ALIAS_DIVIDE_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_arithmetic_three:
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_range
 cmp byte [r13+r15],0xe2
 jne .unicode_range
 cmp byte [r13+r15+1],0x8a
 jne .unicode_relational_or_arithmetic
 cmp byte [r13+r15+2],0xbb
 je .unicode_xor
.unicode_relational_or_arithmetic:
 cmp byte [r13+r15+1],0x89
 jne .unicode_arithmetic_minus
 cmp byte [r13+r15+2],0xa0
 je .unicode_not_equal
 cmp byte [r13+r15+2],0xa4
 je .unicode_less_equal
 cmp byte [r13+r15+2],0xa5
 je .unicode_greater_equal
.unicode_arithmetic_minus:
 cmp byte [r13+r15],0xe2
 jne .unicode_range
 cmp byte [r13+r15+1],0x88
 jne .unicode_range
 cmp byte [r13+r15+2],0xa7
 je .unicode_and
 cmp byte [r13+r15+2],0xa8
 je .unicode_or
 cmp byte [r13+r15+2],0x92
 jne .unicode_range
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_MINUS_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_and:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_AND_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_or:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_OR_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_less_equal:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_greater_equal:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_not_equal:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_NOT_EQUAL_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_xor:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_XOR_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jmp .emit
.unicode_range:
 ; U+2026 remains the sole range atom; no normalization or three-dot alias.
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_generic
 cmp byte [r13+r15],0xe2
 jne .unicode_generic
 cmp byte [r13+r15+1],0x80
 jne .unicode_generic
 cmp byte [r13+r15+2],0xa6
 je .range_ellipsis
.unicode_generic:
 mov r11,r15
 lea rax,[r15+2]
 cmp rax,r14
 ja .unicode_generic_three
 cmp byte [r13+r15],0xcc
 je .unicode_combining
 cmp byte [r13+r15],0xcd
 jne .unicode_generic_three
 cmp byte [r13+r15+1],0xaf
 ja .unicode_generic_three
.unicode_combining:
 mov qword [rsp+8],NEBOC_UNICODE_DIAG_COMBINING
.unicode_generic_three:
 ; Fullwidth ASCII forms are rejected, never normalized to an operator.
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_generic_consume
 cmp byte [r13+r15],0xe2
 jne .unicode_bom_check
 cmp byte [r13+r15+1],0x80
 jne .unicode_word_joiner_check
 movzx eax,byte [r13+r15+2]
 cmp eax,0x8b
 jb .unicode_bidi_check
 cmp eax,0x8f
 jbe .unicode_invisible
.unicode_word_joiner_check:
 cmp byte [r13+r15+1],0x81
 jne .unicode_bidi_check
 cmp byte [r13+r15+2],0xa0
 je .unicode_invisible
 jmp .unicode_bidi_check
.unicode_bom_check:
 cmp byte [r13+r15],0xef
 jne .unicode_bidi_check
 cmp byte [r13+r15+1],0xbb
 jne .unicode_bidi_check
 cmp byte [r13+r15+2],0xbf
 jne .unicode_bidi_check
.unicode_invisible:
 mov qword [rsp+8],NEBOC_UNICODE_DIAG_INVISIBLE
 jmp .unicode_generic_consume
.unicode_bidi_check:
 cmp byte [r13+r15],0xe2
 jne .unicode_fullwidth_check
 cmp byte [r13+r15+1],0x80
 jne .unicode_bidi_isolate_check
 movzx eax,byte [r13+r15+2]
 cmp eax,0xaa
 jb .unicode_fullwidth_check
 cmp eax,0xae
 jbe .unicode_bidi
.unicode_bidi_isolate_check:
 cmp byte [r13+r15+1],0x81
 jne .unicode_fullwidth_check
 movzx eax,byte [r13+r15+2]
 cmp eax,0xa6
 jb .unicode_fullwidth_check
 cmp eax,0xa9
 ja .unicode_fullwidth_check
.unicode_bidi:
 mov qword [rsp+8],NEBOC_UNICODE_DIAG_BIDI_CONTROL
 jmp .unicode_generic_consume
.unicode_fullwidth_check:
 cmp byte [r13+r15],0xef
 jne .unicode_generic_consume
 cmp byte [r13+r15+1],0xbc
 je .unicode_confusable
 cmp byte [r13+r15+1],0xbd
 jne .unicode_generic_consume
.unicode_confusable:
 mov qword [rsp+8],NEBOC_UNICODE_DIAG_CONFUSABLE
.unicode_generic_consume:
 inc r15
 ; Consume one well-formed-looking UTF-8 sequence as one lexical error.
 movzx eax,byte [r13+r11]
 mov ecx,1
 cmp al,0xc2
 jb .unicode_done
 cmp al,0xdf
 jbe .unicode_two
 cmp al,0xef
 jbe .unicode_three
 cmp al,0xf4
 jbe .unicode_four
 jmp .unicode_done
.unicode_two:
 mov ecx,2
 jmp .unicode_consume
.unicode_three:
 mov ecx,3
 jmp .unicode_consume
.unicode_four:
 mov ecx,4
.unicode_consume:
 mov edx,1
.unicode_loop:
 cmp edx,ecx
 jae .unicode_done
 cmp r15,r14
 jae .unicode_done
 movzx eax,byte [r13+r15]
 and eax,0xc0
 cmp eax,0x80
 jne .unicode_done
 inc r15
 inc edx
 jmp .unicode_loop
.unicode_done:
 mov r10d,NEBOC_TOKEN_INVALID_IDENTIFIER
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 cmp qword [rsp+8],0
 jne .unicode_diag_ready
 mov qword [rsp+8],NEBOC_LEX_DIAG_INVALID_CHARACTER
.unicode_diag_ready:
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit

.integer:
 mov r11,r15
 mov [rsp],r11
 ; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF005 public vertical integration. Candidate spellings containing an
 ; approved/invalid base prefix, separator, or suffix are validated by the
 ; bounded PF002 contract scanner. Ordinary decimal and strict Float spellings
 ; continue through the certified v0.1/tipos_primitivos_escalares paths below.
 lea rdi,[r13+r11]
 mov rsi,r14
 sub rsi,r11
 call lexer_candidate_length
 test rax,rax
 jz .legacy_decimal_or_float
 mov [rsp+168],rax
 lea rdi,[rsp+32]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov r11,[rsp]
 lea rax,[r13+r11]
 mov [rsp+32+NEBOC_NUMERIC_SOURCE_OFFSET],rax
 mov rax,[rsp+168]
 mov [rsp+32+NEBOC_NUMERIC_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rsp+32+NEBOC_NUMERIC_SOURCE_ID_OFFSET],rax
 mov [rsp+32+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],r11
 lea rdi,[rsp+32]
 call neboc_numeric_literal_contract_scan
 mov r11,[rsp]
 mov r15,r11
 add r15,[rsp+168]
 test eax,eax
 jnz ._numeric_error
 mov r10d,NEBOC_TOKEN_INTEGER
 mov r9,[rsp+32+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET]
 and r9,-257
 mov rax,[rsp+32+NEBOC_NUMERIC_VALUE_OFFSET]
 mov [rsp+8],rax
 test r9,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 jz .emit
 mov rdi,r12
 mov rsi,rbx
 call lexer_minus_is_unary
 test eax,eax
 jz ._intmin_not_unary
 ; Canonicalize the unary-minus INT64_MIN path into one signed integer token.
 ; This preserves the existing Int codegen contract and prevents a second NEG.
 dec rbx
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov r11,[rax+NEBOC_TOKEN_START_OFFSET]
 jmp .emit
._intmin_not_unary:
 mov qword [rsp+32+NEBOC_NUMERIC_ERROR_CODE_OFFSET],NEBOC_NUMERIC_DIAG_OVERFLOW
 mov rax,[rsp]
 mov [rsp+32+NEBOC_NUMERIC_ERROR_START_OFFSET],rax
 mov rdx,rax
 add rdx,[rsp+168]
 mov [rsp+32+NEBOC_NUMERIC_ERROR_END_OFFSET],rdx
._numeric_error:
 mov r10d,NEBOC_TOKEN_INVALID_NUMERIC_LITERAL
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov rax,[rsp+32+NEBOC_NUMERIC_ERROR_CODE_OFFSET]
 mov [rsp+8],rax
 mov rax,[rsp]
 add rax,[rsp+168]
 mov [rsp+160],rax
 mov r11,[rsp+32+NEBOC_NUMERIC_ERROR_START_OFFSET]
 mov r15,[rsp+32+NEBOC_NUMERIC_ERROR_END_OFFSET]
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.legacy_decimal_or_float:
 mov r11,[rsp]
 ; TIPOS-PRIMITIVOS-ESCALARES-PF003 strict decimal profile: [0-9]+ '.' [0-9]+.
 ; Pre-scan digits before Int accumulation so a very large integral component
 ; can still be classified as Float without producing an Int-overflow token.
 mov rax,r15
.number_digit_scan:
 cmp rax,r14
 jae .number_digits_done
 movzx ecx,byte [r13+rax]
 cmp cl,'0'
 jb .number_digits_done
 cmp cl,'9'
 ja .number_digits_done
 inc rax
 jmp .number_digit_scan
.number_digits_done:
 mov [rsp+24],rax
 cmp rax,r14
 jae .integer_accumulation_start
 cmp byte [r13+rax],'.'
 jne .integer_accumulation_start
 lea rdx,[rax+1]
 cmp rdx,r14
 jae .integer_accumulation_start
 movzx ecx,byte [r13+rdx]
 cmp cl,'0'
 jb .integer_accumulation_start
 cmp cl,'9'
 ja .integer_accumulation_start
 ; Payload packs decimal digit counts: high32=integer, low32=fraction.
 mov rcx,rax
 sub rcx,r11
 inc rax
 mov r15,rax
.float_fraction_scan:
 cmp r15,r14
 jae .float_done
 movzx edx,byte [r13+r15]
 cmp dl,'0'
 jb .float_done
 cmp dl,'9'
 ja .float_done
 inc r15
 jmp .float_fraction_scan
.float_done:
 mov rdx,r15
 sub rdx,rax
 shl rcx,32
 or rcx,rdx
 mov [rsp+8],rcx
 mov r10d,NEBOC_TOKEN_FLOAT
 xor r9d,r9d
 mov r11,[rsp]
 jmp .emit
.integer_accumulation_start:
 mov r15,r11
 xor eax,eax
.integer_loop:
 cmp r15,r14
 jae .integer_done
 movzx ecx,byte [r13+r15]
 cmp cl,'0'
 jb .integer_done
 cmp cl,'9'
 ja .integer_done
 sub ecx,'0'
 mov rdx,922337203685477580
 cmp rax,rdx
 ja .integer_overflow_consume
 jne .integer_accumulate
 cmp ecx,8
 ja .integer_overflow_consume
.integer_accumulate:
 imul rax,rax,10
 add rax,rcx
 inc r15
 jmp .integer_loop
.integer_done:
 mov [rsp+8],rax
 mov rdx,0x8000000000000000
 cmp rax,rdx
 jne .integer_regular
 test rbx,rbx
 jz .integer_overflow_emit
 mov rcx,rbx
 dec rcx
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [rcx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .integer_overflow_emit
 mov r10d,NEBOC_TOKEN_INTEGER
 mov r9d,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 mov r11,[rsp]
 jmp .emit
.integer_regular:
 mov r10d,NEBOC_TOKEN_INTEGER
 xor r9d,r9d
 mov r11,[rsp]
 jmp .emit
.integer_overflow_consume:
 inc r15
.integer_overflow_more:
 cmp r15,r14
 jae .integer_overflow_emit
 movzx ecx,byte [r13+r15]
 cmp cl,'0'
 jb .integer_overflow_emit
 cmp cl,'9'
 ja .integer_overflow_emit
 inc r15
 jmp .integer_overflow_more
.integer_overflow_emit:
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_INT_OVERFLOW
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_INT_OVERFLOW
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit

.char:
 mov r11,r15
 mov [rsp],r11
 lea rdi,[r13+r11]
 mov rsi,r14
 sub rsi,r11
 call lexer_char_candidate_length
 test rax,rax
 jz .operators
 mov [rsp+24],rax
 lea rdi,[rsp+32]
 mov ecx,NEBOC_CHAR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov r11,[rsp]
 lea rax,[r13+r11]
 mov [rsp+32+NEBOC_CHAR_SOURCE_OFFSET],rax
 mov rax,[rsp+24]
 mov [rsp+32+NEBOC_CHAR_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rsp+32+NEBOC_CHAR_SOURCE_ID_OFFSET],rax
 mov [rsp+32+NEBOC_CHAR_ABSOLUTE_START_OFFSET],r11
 lea rdi,[rsp+32]
 call neboc_char_literal_contract_scan
 mov r11,[rsp]
 mov r15,r11
 add r15,[rsp+24]
 test eax,eax
 jnz .char_error
 mov r10d,NEBOC_TOKEN_CHAR
 mov r9,[rsp+32+NEBOC_CHAR_TOKEN_FLAGS_OFFSET]
 and r9,~neboc_text_char_unicode_e_bytes_TOKEN_FLAG_SYNTAX_ONLY
 or r9,NEBOC_TOKEN_FLAG_CHAR_DECODED
 mov rax,[rsp+32+NEBOC_CHAR_SCALAR_OFFSET]
 mov [rsp+8],rax
 jmp .emit
.char_error:
 mov r10d,NEBOC_TOKEN_INVALID_CHAR_LITERAL
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov rax,[rsp+32+NEBOC_CHAR_DIAGNOSTIC_OFFSET]
 mov [rsp+8],rax
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit

.text:
 mov r11,r15
 mov [rsp],r11
 inc r15
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET]
 test rax,rax
 jz .limit
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET]
 ja .limit
 mov [rsp+16],rcx
.text_loop:
 cmp r15,r14
 jae .text_unterminated
 movzx eax,byte [r13+r15]
 cmp al,'"'
 je .text_done
 cmp al,10
 je .text_unterminated
 cmp al,13
 je .text_unterminated
 cmp al,92
 je .text_escape
 mov dl,al
 inc r15
 jmp .text_append
.text_escape:
 inc r15
 cmp r15,r14
 jae .text_unterminated
 movzx eax,byte [r13+r15]
 inc r15
 cmp al,'n'
 je .escape_n
 cmp al,'r'
 je .escape_r
 cmp al,'t'
 je .escape_t
 cmp al,92
 je .escape_slash
 cmp al,'"'
 je .escape_quote
 jmp .text_invalid_escape
.escape_n:
 mov dl,10
 jmp .text_append
.escape_r:
 mov dl,13
 jmp .text_append
.escape_t:
 mov dl,9
 jmp .text_append
.escape_slash:
 mov dl,92
 jmp .text_append
.escape_quote:
 mov dl,'"'
.text_append:
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET]
 jae .text_limit
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET]
 mov [rax+rcx],dl
 inc rcx
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rcx
 jmp .text_loop
.text_done:
 inc r15
 mov rax,[rsp+16]
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 sub rcx,rax
 mov edx,0xffffffff
 cmp rax,rdx
 ja .text_limit
 cmp rcx,rdx
 ja .text_limit
 shl rax,32
 mov edx,ecx
 or rax,rdx
 mov [rsp+8],rax
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_TEXT
 mov r9d,NEBOC_TOKEN_FLAG_TEXT_DECODED
 jmp .emit
.text_invalid_escape:
 mov rax,[rsp+16]
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rax
.text_invalid_scan:
 cmp r15,r14
 jae .text_invalid_emit
 mov al,[r13+r15]
 cmp al,10
 je .text_invalid_emit
 cmp al,13
 je .text_invalid_emit
 inc r15
 cmp al,'"'
 jne .text_invalid_scan
.text_invalid_emit:
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_INVALID_ESCAPE
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_INVALID_ESCAPE
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.text_unterminated:
 mov rax,[rsp+16]
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rax
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_UNTERMINATED_TEXT
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_UNTERMINATED_TEXT
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.text_limit:
 mov rax,[rsp+16]
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rax
 jmp .limit

.operators:
 mov r11,r15
 inc r15
 cmp al,'/'
 je .slash
 cmp al,'('
 je .k_lparen
 cmp al,')'
 je .k_rparen
 cmp al,'{'
 je .k_lbrace
 cmp al,'}'
 je .k_rbrace
 cmp al,','
 je .k_comma
 cmp al,';'
 je .k_semicolon
 cmp al,'.'
 je .dot
 cmp al,'+'
 je .k_plus
 cmp al,'-'
 je .minus
 cmp al,'*'
 je .k_star
 cmp al,'%'
 je .k_percent
 cmp al,'^'
 je .k_caret
 cmp al,'?'
 je .question
 cmp al,'='
 je .equal
 cmp al,'!'
 je .bang
 cmp al,'<'
 je .less
 cmp al,'>'
 je .greater
 cmp al,'&'
 je .and
 cmp al,'|'
 je .or
 cmp al,':'
 je .k_colon
 cmp al,'['
 je .k_lbracket
 cmp al,']'
 je .k_rbracket
 jmp .invalid_char
.slash:
 cmp r15,r14
 jae .k_slash
 cmp byte [r13+r15],'/'
 je .line_comment
 cmp byte [r13+r15],'*'
 je .block_comment
 jmp .k_slash
.line_comment:
 inc r15
.line_comment_loop:
 cmp r15,r14
 jae .loop
 mov al,[r13+r15]
 cmp al,10
 je .loop
 cmp al,13
 je .loop
 inc r15
 jmp .line_comment_loop
.block_comment:
 inc r15
.block_comment_loop:
 cmp r15,r14
 jae .block_comment_emit
 mov al,[r13+r15]
 cmp al,'*'
 jne .block_comment_next
 lea rax,[r15+1]
 cmp rax,r14
 jae .block_comment_next
 cmp byte [r13+r15+1],'/'
 jne .block_comment_next
 add r15,2
 jmp .block_comment_emit
.block_comment_next:
 inc r15
 jmp .block_comment_loop
.block_comment_emit:
 mov r10d,NEBOC_TOKEN_UNSUPPORTED_BLOCK_COMMENT
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_UNSUPPORTED_BLOCK_COMMENT
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.minus:
 cmp r15,r14
 jae .k_minus
 cmp byte [r13+r15],'>'
 jne .k_minus
 inc r15
 mov r10d,NEBOC_OPERATOR_TOKEN_ARROW
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.equal:
 cmp r15,r14
 jae .k_equal
 cmp byte [r13+r15],'='
 jne .k_equal
 inc r15
 mov r10d,NEBOC_TOKEN_EQUAL_EQUAL
 xor r9d,r9d
 jmp .emit
.bang:
 cmp r15,r14
 jae .k_bang
 cmp byte [r13+r15],'='
 jne .k_bang
 inc r15
 mov r10d,NEBOC_TOKEN_BANG_EQUAL
 xor r9d,r9d
 jmp .emit
.less:
 cmp r15,r14
 jae .k_less
 lea rax,[r15+3]
 cmp rax,r14
 ja .less_not_range
 cmp byte [r13+r15],0xe2
 jne .less_not_range
 cmp byte [r13+r15+1],0x80
 jne .less_not_range
 cmp byte [r13+r15+2],0xa6
 jne .less_not_range
 add r15,3
 cmp r15,r14
 jae .range_exclusive_start
 cmp byte [r13+r15],'<'
 jne .range_exclusive_start
 inc r15
 mov r10d,NEBOC_TOKEN_RANGE_EXCLUSIVE
 xor r9d,r9d
 jmp .emit
.range_exclusive_start:
 mov r10d,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 xor r9d,r9d
 jmp .emit
.less_not_range:
 cmp byte [r13+r15],'='
 jne .k_less
 lea rax,[r15+1]
 cmp rax,r14
 jae .less_equal
 cmp byte [r13+r15+1],'>'
 jne .less_equal
 add r15,2
 mov r10d,NEBOC_TOKEN_SPACESHIP
 xor r9d,r9d
 jmp .emit
.less_equal:
 inc r15
 mov r10d,NEBOC_TOKEN_LESS_EQUAL
 xor r9d,r9d
 jmp .emit
.greater:
 cmp r15,r14
 jae .k_greater
 cmp byte [r13+r15],'='
 jne .k_greater
 inc r15
 mov r10d,NEBOC_TOKEN_GREATER_EQUAL
 xor r9d,r9d
 jmp .emit
.and:
 cmp r15,r14
 jae .invalid_char
 cmp byte [r13+r15],'&'
 jne .invalid_char
 inc r15
 mov r10d,NEBOC_TOKEN_AND_AND
 xor r9d,r9d
 jmp .emit
.or:
 cmp r15,r14
 jae .invalid_char
 cmp byte [r13+r15],'|'
 jne .invalid_char
 inc r15
 mov r10d,NEBOC_TOKEN_OR_OR
 xor r9d,r9d
 jmp .emit
.range_ellipsis:
 mov r11,r15
 add r15,3
 cmp r15,r14
 jae .range_inclusive
 cmp byte [r13+r15],'<'
 jne .range_inclusive
 inc r15
 mov r10d,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 xor r9d,r9d
 jmp .emit
.range_inclusive:
 mov r10d,NEBOC_TOKEN_RANGE_INCLUSIVE
 xor r9d,r9d
 jmp .emit
.question:
 cmp r15,r14
 jae .k_question
 cmp byte [r13+r15],'?'
 je .question_coalesce
 cmp byte [r13+r15],'.'
 jne .k_question
 inc r15
 mov r10d,NEBOC_TOKEN_OPTIONAL_CHAIN
 xor r9d,r9d
 jmp .emit
.question_coalesce:
 inc r15
 cmp r15,r14
 jae .question_plain_coalesce
 cmp byte [r13+r15],'='
 jne .question_plain_coalesce
 inc r15
 mov r10d,NEBOC_TOKEN_OPTION_ASSIGN
 xor r9d,r9d
 jmp .emit
.question_plain_coalesce:
 mov r10d,NEBOC_TOKEN_COALESCE
 xor r9d,r9d
 jmp .emit
.dot:
 cmp r15,r14
 jae .k_dot
 cmp byte [r13+r15],'.'
 jne .k_dot
 inc r15
 mov r10d,NEBOC_TOKEN_LATERAL_FLOW
 xor r9d,r9d
 jmp .emit
%macro SIMPLE_KIND 2
.%1:
 mov r10d,%2
 xor r9d,r9d
 jmp .emit
%endmacro
SIMPLE_KIND k_lparen,NEBOC_OPERATOR_TOKEN_LPAREN
SIMPLE_KIND k_rparen,NEBOC_OPERATOR_TOKEN_RPAREN
SIMPLE_KIND k_lbrace,NEBOC_OPERATOR_TOKEN_LBRACE
SIMPLE_KIND k_rbrace,NEBOC_OPERATOR_TOKEN_RBRACE
SIMPLE_KIND k_comma,NEBOC_OPERATOR_TOKEN_COMMA
SIMPLE_KIND k_semicolon,NEBOC_OPERATOR_TOKEN_SEMICOLON
SIMPLE_KIND k_dot,NEBOC_OPERATOR_TOKEN_DOT
SIMPLE_KIND k_plus,NEBOC_TOKEN_PLUS
SIMPLE_KIND k_minus,NEBOC_TOKEN_MINUS
SIMPLE_KIND k_star,NEBOC_TOKEN_STAR
SIMPLE_KIND k_slash,NEBOC_TOKEN_SLASH
SIMPLE_KIND k_percent,NEBOC_TOKEN_PERCENT
SIMPLE_KIND k_caret,NEBOC_TOKEN_CARET
SIMPLE_KIND k_question,NEBOC_TOKEN_QUESTION
SIMPLE_KIND k_bang,NEBOC_TOKEN_BANG
SIMPLE_KIND k_less,NEBOC_OPERATOR_TOKEN_LESS
SIMPLE_KIND k_greater,NEBOC_OPERATOR_TOKEN_GREATER
.k_equal:
 mov r10d,NEBOC_TOKEN_RESERVED_EQUAL
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.k_colon:
 mov r10d,NEBOC_OPERATOR_TOKEN_COLON
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.k_lbracket:
 mov r10d,NEBOC_OPERATOR_TOKEN_LBRACKET
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.k_rbracket:
 mov r10d,NEBOC_OPERATOR_TOKEN_RBRACKET
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.invalid_char:
 mov r10d,NEBOC_TOKEN_INVALID_CHARACTER
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_INVALID_CHARACTER
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
.emit:
 cmp rbx,[r12+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET]
 jae .limit
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov [rax+NEBOC_TOKEN_KIND_OFFSET],r10
 mov [rax+NEBOC_TOKEN_FLAGS_OFFSET],r9
 mov rdx,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rax+NEBOC_TOKEN_SOURCE_ID_OFFSET],rdx
 mov [rax+NEBOC_TOKEN_START_OFFSET],r11
 mov [rax+NEBOC_TOKEN_END_OFFSET],r15
 mov rdx,[rsp+8]
 mov [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rdx
 inc rbx
 mov [r12+NEBOC_LEXER_REQUEST_COUNT_OFFSET],rbx
 mov rdx,[rsp+160]
 test rdx,rdx
 cmovnz r15,rdx
 jmp .loop
.skip_one:
 inc r15
 jmp .loop
.emit_eof:
 mov r11,r14
 mov r15,r14
 mov r10d,NEBOC_TOKEN_EOF
 xor r9d,r9d
 mov qword [rsp+8],0
 cmp rbx,[r12+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET]
 jae .limit
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov [rax+NEBOC_TOKEN_KIND_OFFSET],r10
 mov [rax+NEBOC_TOKEN_FLAGS_OFFSET],r9
 mov rdx,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rax+NEBOC_TOKEN_SOURCE_ID_OFFSET],rdx
 mov [rax+NEBOC_TOKEN_START_OFFSET],r11
 mov [rax+NEBOC_TOKEN_END_OFFSET],r15
 mov qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],0
 inc rbx
 mov [r12+NEBOC_LEXER_REQUEST_COUNT_OFFSET],rbx
 mov eax,NEBOC_STATUS_OK
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,176
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF005 candidate detector.
; source*, remaining -> RAX candidate length or zero for ordinary decimal/Float.
lexer_candidate_length:
 push rbx
 push r12
 push r13
 xor ebx,ebx
 xor r12d,r12d
 test rdi,rdi
 jz .candidate_none
 test rsi,rsi
 jz .candidate_none
 cmp rsi,2
 jb .candidate_loop
 cmp byte [rdi],'0'
 jne .candidate_loop
 movzx eax,byte [rdi+1]
 cmp al,'A'
 jb .candidate_prefix_lower
 cmp al,'Z'
 jbe .candidate_trigger_prefix
.candidate_prefix_lower:
 cmp al,'a'
 jb .candidate_loop
 cmp al,'z'
 jbe .candidate_trigger_prefix
 jmp .candidate_loop
.candidate_trigger_prefix:
 mov r12d,1
.candidate_loop:
 cmp rbx,rsi
 jae .candidate_done
 movzx eax,byte [rdi+rbx]
 cmp al,'0'
 jb .candidate_alpha_upper
 cmp al,'9'
 jbe .candidate_take
.candidate_alpha_upper:
 cmp al,'A'
 jb .candidate_alpha_lower
 cmp al,'Z'
 jbe .candidate_alpha
.candidate_alpha_lower:
 cmp al,'a'
 jb .candidate_underscore
 cmp al,'z'
 jbe .candidate_alpha
.candidate_underscore:
 cmp al,'_'
 je .candidate_trigger_take
 cmp al,'.'
 jne .candidate_done
 test r12d,r12d
 jz .candidate_done
 lea rax,[rbx+1]
 cmp rax,rsi
 jae .candidate_done
 movzx edx,byte [rdi+rax]
 cmp dl,'0'
 jb .candidate_done
 cmp dl,'9'
 ja .candidate_done
 inc rbx
 jmp .candidate_done
.candidate_alpha:
 ; Preserve the certified tipos_primitivos_escalares tokenization of decimal exponent-like spellings
 ; such as `1e2`: the exponent feature remains deferred, so the legacy lexer
 ; must continue producing INTEGER + IDENTIFIER rather than a literais_numericos_bases_e_representacao suffix error.
 ; Based literals (for example 0xE2) already have r12d set and still use literais_numericos_bases_e_representacao.
 cmp al,'e'
 je .candidate_maybe_legacy_exponent
 cmp al,'E'
 jne .candidate_mark_alpha
.candidate_maybe_legacy_exponent:
 test r12d,r12d
 jnz .candidate_mark_alpha
 test rbx,rbx
 jz .candidate_mark_alpha
 jmp .candidate_none
.candidate_mark_alpha:
 mov r12d,1
 jmp .candidate_take
.candidate_trigger_take:
 mov r12d,1
.candidate_take:
 inc rbx
 jmp .candidate_loop
.candidate_done:
 test r12d,r12d
 jz .candidate_none
 mov rax,rbx
 jmp .candidate_ret
.candidate_none:
 xor eax,eax
.candidate_ret:
 pop r13
 pop r12
 pop rbx
 ret

; request*, emitted_token_count -> EAX 1 when the immediately preceding minus
; is in a syntactically unary position, otherwise zero.
lexer_minus_is_unary:
 test rdi,rdi
 jz .minus_no
 test rsi,rsi
 jz .minus_no
 mov rax,rsi
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .minus_no
 cmp rsi,1
 je .minus_yes
 sub rax,NEBOC_TOKEN_SIZE
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_LPAREN
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_LBRACE
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_COMMA
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_SEMICOLON
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_PLUS
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_MINUS
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_STAR
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_SLASH
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_PERCENT
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_CARET
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_INCLUSIVE
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_EQUAL_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_BANG_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_LESS
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_LESS_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_GREATER
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_GREATER_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_AND_AND
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_OR_OR
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_KW_RETURN
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RESERVED_EQUAL
 je .minus_yes
.minus_no:
 xor eax,eax
 ret
.minus_yes:
 mov eax,1
 ret

; source*, remaining -> complete Char candidate length. The closing quote is
; consumed even across a physical newline so the decoder can emit its precise
; diagnostic. An unterminated candidate consumes the remaining source.
lexer_char_candidate_length:
 test rdi,rdi
 jz .none
 test rsi,rsi
 jz .none
 cmp byte [rdi],39
 jne .none
 mov eax,1
 xor edx,edx
.loop:
 cmp rax,rsi
 jae .remaining
 mov cl,[rdi+rax]
 test edx,edx
 jnz .escaped
 cmp cl,92
 je .escape
 cmp cl,39
 je .closed
 inc rax
 jmp .loop
.escape:
 mov edx,1
 inc rax
 jmp .loop
.escaped:
 xor edx,edx
 inc rax
 jmp .loop
.closed:
 inc rax
 ret
.remaining:
 mov rax,rsi
 ret
.none:
 xor eax,eax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
