; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF002 isolated Char literal syntax/diagnostic contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/text_char_literal_contract.inc"

section .text

; char_hash(request*)
char_hash:
 mov r8,[rdi+NEBOC_CHAR_SOURCE_OFFSET]
 mov r9,[rdi+NEBOC_CHAR_LENGTH_OFFSET]
 mov rax,1469598103934665603
 mov r10,1099511628211
 xor ecx,ecx
.bytes:
 cmp rcx,r9
 jae .fields
 movzx edx,byte [r8+rcx]
 xor rax,rdx
 imul rax,r10
 inc rcx
 jmp .bytes
.fields:
 xor rax,[rdi+NEBOC_CHAR_TOKEN_KIND_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CHAR_TOKEN_FLAGS_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CHAR_SCALAR_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CHAR_DIAGNOSTIC_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CHAR_ERROR_START_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CHAR_ERROR_END_OFFSET]
 imul rax,r10
 mov [rdi+NEBOC_CHAR_HASH_OFFSET],rax
 ret

; char_error(request*, diagnostic, relative_start, relative_end)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
char_error:
 mov [rdi+NEBOC_CHAR_DIAGNOSTIC_OFFSET],rsi
 mov qword [rdi+NEBOC_CHAR_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID
 mov qword [rdi+NEBOC_CHAR_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_ERROR
 mov rax,[rdi+NEBOC_CHAR_ABSOLUTE_START_OFFSET]
 mov [rdi+NEBOC_CHAR_TOKEN_START_OFFSET],rax
 add rax,[rdi+NEBOC_CHAR_LENGTH_OFFSET]
 mov [rdi+NEBOC_CHAR_TOKEN_END_OFFSET],rax
 mov rax,[rdi+NEBOC_CHAR_ABSOLUTE_START_OFFSET]
 add rax,rdx
 mov [rdi+NEBOC_CHAR_ERROR_START_OFFSET],rax
 mov rax,[rdi+NEBOC_CHAR_ABSOLUTE_START_OFFSET]
 add rax,rcx
 mov [rdi+NEBOC_CHAR_ERROR_END_OFFSET],rax
 call char_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; neboc_char_literal_contract_scan(request*) -> StatusCode
; The input is one complete candidate Char lexeme. Public lexer integration is
; deliberately absent in PF002.
%undef call
NEBOC_ABI_FUNCTION neboc_char_literal_contract_scan
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+NEBOC_CHAR_SOURCE_OFFSET]
 mov r14,[r12+NEBOC_CHAR_LENGTH_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+NEBOC_CHAR_TOKEN_KIND_OFFSET]
 mov ecx,(NEBOC_CHAR_REQUEST_SIZE-NEBOC_CHAR_TOKEN_KIND_OFFSET)/8
 xor eax,eax
 rep stosq

 ; Source-level BOM is forbidden.
 cmp r14,3
 jb .opening_quote
 cmp byte [r13],0xef
 jne .opening_quote
 cmp byte [r13+1],0xbb
 jne .opening_quote
 cmp byte [r13+2],0xbf
 jne .opening_quote
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_BOM_FORBIDDEN
 xor edx,edx
 mov ecx,3
 call char_error
 jmp .done

.opening_quote:
 cmp byte [r13],39
 je .closing_quote
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_EXPECTED_OPEN_QUOTE
 xor edx,edx
 mov ecx,1
 call char_error
 jmp .done

.closing_quote:
 cmp r14,2
 jb .unterminated
 mov rax,r14
 dec rax
 cmp byte [r13+rax],39
 jne .unterminated
 mov r15,r14
 sub r15,2
 test r15,r15
 jz .empty
 lea rbx,[r13+1]

 ; Basic escapes are exactly two bytes between the quotes.
 cmp byte [rbx],92
 jne .decode_utf8
 cmp r15,2
 jne .invalid_escape
 movzx eax,byte [rbx+1]
 cmp al,'n'
 je .escape_n
 cmp al,'r'
 je .escape_r
 cmp al,'t'
 je .escape_t
 cmp al,92
 je .escape_backslash
 cmp al,39
 je .escape_quote
 jmp .invalid_escape
.escape_n:
 mov edx,10
 jmp .success_escape
.escape_r:
 mov edx,13
 jmp .success_escape
.escape_t:
 mov edx,9
 jmp .success_escape
.escape_backslash:
 mov edx,92
 jmp .success_escape
.escape_quote:
 mov edx,39
.success_escape:
 mov qword [rsp],2
 jmp .success

.decode_utf8:
 movzx eax,byte [rbx]
 cmp al,10
 je .physical_newline
 cmp al,13
 je .physical_newline
 cmp al,0x80
 jb .ascii
 cmp al,0xc2
 jb .invalid_utf8_first
 cmp al,0xdf
 jbe .two_byte
 cmp al,0xe0
 je .three_e0
 cmp al,0xec
 jbe .three_general
 cmp al,0xed
 je .three_ed
 cmp al,0xef
 jbe .three_general
 cmp al,0xf0
 je .four_f0
 cmp al,0xf3
 jbe .four_general
 cmp al,0xf4
 je .four_f4
 jmp .out_of_range_first

.ascii:
 movzx edx,al
 mov qword [rsp],1
 jmp .check_count

.two_byte:
 cmp r15,2
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0x80
 jb .invalid_utf8_second
 cmp cl,0xbf
 ja .invalid_utf8_second
 movzx edx,al
 and edx,0x1f
 shl edx,6
 movzx ecx,cl
 and ecx,0x3f
 or edx,ecx
 mov qword [rsp],2
 jmp .check_count

.three_e0:
 cmp r15,3
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0xa0
 jb .invalid_utf8_second
 cmp cl,0xbf
 ja .invalid_utf8_second
 jmp .three_finish
.three_ed:
 cmp r15,3
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0xa0
 jae .surrogate_second
 cmp cl,0x80
 jb .invalid_utf8_second
 jmp .three_finish
.three_general:
 cmp r15,3
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0x80
 jb .invalid_utf8_second
 cmp cl,0xbf
 ja .invalid_utf8_second
.three_finish:
 movzx r8d,byte [rbx+2]
 cmp r8b,0x80
 jb .invalid_utf8_third
 cmp r8b,0xbf
 ja .invalid_utf8_third
 movzx edx,byte [rbx]
 and edx,0x0f
 shl edx,12
 movzx ecx,byte [rbx+1]
 and ecx,0x3f
 shl ecx,6
 or edx,ecx
 movzx ecx,byte [rbx+2]
 and ecx,0x3f
 or edx,ecx
 mov qword [rsp],3
 jmp .check_count

.four_f0:
 cmp r15,4
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0x90
 jb .invalid_utf8_second
 cmp cl,0xbf
 ja .invalid_utf8_second
 jmp .four_finish
.four_f4:
 cmp r15,4
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0x90
 jae .out_of_range_second
 cmp cl,0x80
 jb .invalid_utf8_second
 jmp .four_finish
.four_general:
 cmp r15,4
 jb .invalid_utf8_at_end
 movzx ecx,byte [rbx+1]
 cmp cl,0x80
 jb .invalid_utf8_second
 cmp cl,0xbf
 ja .invalid_utf8_second
.four_finish:
 movzx r8d,byte [rbx+2]
 cmp r8b,0x80
 jb .invalid_utf8_third
 cmp r8b,0xbf
 ja .invalid_utf8_third
 movzx r9d,byte [rbx+3]
 cmp r9b,0x80
 jb .invalid_utf8_fourth
 cmp r9b,0xbf
 ja .invalid_utf8_fourth
 movzx edx,byte [rbx]
 and edx,0x07
 shl edx,18
 movzx ecx,byte [rbx+1]
 and ecx,0x3f
 shl ecx,12
 or edx,ecx
 movzx ecx,byte [rbx+2]
 and ecx,0x3f
 shl ecx,6
 or edx,ecx
 movzx ecx,byte [rbx+3]
 and ecx,0x3f
 or edx,ecx
 mov qword [rsp],4

.check_count:
 cmp [rsp],r15
 jne .multiple
.success:
 mov qword [r12+NEBOC_CHAR_TOKEN_KIND_OFFSET],NEBOC_TOKEN_CHAR_PROVISIONAL
 mov qword [r12+NEBOC_CHAR_TOKEN_FLAGS_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TOKEN_FLAG_CHAR_DECODED|neboc_text_char_unicode_e_bytes_TOKEN_FLAG_SYNTAX_ONLY
 mov rax,[r12+NEBOC_CHAR_ABSOLUTE_START_OFFSET]
 mov [r12+NEBOC_CHAR_TOKEN_START_OFFSET],rax
 mov [r12+NEBOC_CHAR_PAYLOAD_START_OFFSET],rax
 inc qword [r12+NEBOC_CHAR_PAYLOAD_START_OFFSET]
 add rax,r14
 mov [r12+NEBOC_CHAR_TOKEN_END_OFFSET],rax
 dec rax
 mov [r12+NEBOC_CHAR_PAYLOAD_END_OFFSET],rax
 mov [r12+NEBOC_CHAR_SCALAR_OFFSET],rdx
 mov qword [r12+NEBOC_CHAR_SCALAR_COUNT_OFFSET],1
 mov rdi,r12
 call char_hash
 xor eax,eax
 jmp .done

.unterminated:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_UNTERMINATED
 mov rdx,r14
 mov rcx,r14
 call char_error
 jmp .done
.empty:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_EMPTY
 mov edx,1
 mov ecx,1
 call char_error
 jmp .done
.multiple:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_MULTIPLE_SCALARS
 mov rdx,[rsp]
 inc rdx
 mov rcx,r14
 dec rcx
 call char_error
 jmp .done
.invalid_escape:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_INVALID_ESCAPE
 mov edx,1
 mov ecx,r14d
 dec ecx
 call char_error
 jmp .done
.physical_newline:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_PHYSICAL_NEWLINE
 mov edx,1
 mov ecx,2
 call char_error
 jmp .done
.invalid_utf8_first:
 mov edx,1
 jmp .invalid_utf8_one
.invalid_utf8_second:
 mov edx,2
 jmp .invalid_utf8_one
.invalid_utf8_third:
 mov edx,3
 jmp .invalid_utf8_one
.invalid_utf8_fourth:
 mov edx,4
.invalid_utf8_one:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_INVALID_UTF8
 mov ecx,edx
 inc ecx
 call char_error
 jmp .done
.invalid_utf8_at_end:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_INVALID_UTF8
 mov rdx,r14
 dec rdx
 mov rcx,r14
 dec rcx
 call char_error
 jmp .done
.surrogate_second:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_SURROGATE
 mov edx,1
 mov ecx,4
 call char_error
 jmp .done
.out_of_range_first:
 mov edx,1
 jmp .out_of_range
.out_of_range_second:
 mov edx,1
.out_of_range:
 mov rdi,r12
 mov esi,NEBOC_CHAR_DIAG_OUT_OF_RANGE
 mov ecx,r14d
 dec ecx
 call char_error
 jmp .done
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

; neboc_char_literal_parse_contract(scan*, ast*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_char_literal_parse_contract
 test rdi,rdi
 jz .bad
 test rsi,rsi
 jz .bad
 cmp qword [rdi+NEBOC_CHAR_TOKEN_KIND_OFFSET],NEBOC_TOKEN_CHAR_PROVISIONAL
 jne .source_bad
 cmp qword [rdi+NEBOC_CHAR_DIAGNOSTIC_OFFSET],NEBOC_CHAR_DIAG_NONE
 jne .source_bad
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBOC_CHAR_AST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rsi+NEBOC_CHAR_AST_KIND_OFFSET],NEBOC_AST_CHAR_LITERAL_PROVISIONAL
 mov qword [rsi+NEBOC_CHAR_AST_FLAGS_OFFSET],NEBOC_AST_FLAG_SYNTAX_ONLY
 mov rax,[r8+NEBOC_CHAR_SOURCE_ID_OFFSET]
 mov [rsi+NEBOC_CHAR_AST_SOURCE_ID_OFFSET],rax
 mov rax,[r8+NEBOC_CHAR_TOKEN_START_OFFSET]
 mov [rsi+NEBOC_CHAR_AST_START_OFFSET],rax
 mov rax,[r8+NEBOC_CHAR_TOKEN_END_OFFSET]
 mov [rsi+NEBOC_CHAR_AST_END_OFFSET],rax
 mov rax,[r8+NEBOC_CHAR_SCALAR_OFFSET]
 mov [rsi+NEBOC_CHAR_AST_SCALAR_OFFSET],rax
 mov rax,[r8+NEBOC_CHAR_HASH_OFFSET]
 mov [rsi+NEBOC_CHAR_AST_TOKEN_HASH_OFFSET],rax
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[rsi+NEBOC_CHAR_AST_KIND_OFFSET]
 imul rax,rcx
 xor rax,[rsi+NEBOC_CHAR_AST_SOURCE_ID_OFFSET]
 imul rax,rcx
 xor rax,[rsi+NEBOC_CHAR_AST_START_OFFSET]
 imul rax,rcx
 xor rax,[rsi+NEBOC_CHAR_AST_END_OFFSET]
 imul rax,rcx
 xor rax,[rsi+NEBOC_CHAR_AST_SCALAR_OFFSET]
 imul rax,rcx
 xor rax,[rsi+NEBOC_CHAR_AST_TOKEN_HASH_OFFSET]
 imul rax,rcx
 mov [rsi+NEBOC_CHAR_AST_HASH_OFFSET],rax
 xor eax,eax
 ret
.source_bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
