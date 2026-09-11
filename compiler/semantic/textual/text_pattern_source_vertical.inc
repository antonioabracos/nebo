; G141 bounded source owner for Text concatenation and compiled Pattern
; operators.  Literal operands are consumed once, then the shared Assembly
; Text/Pattern runtime is called with caller-owned storage and explicit limits.

%define G141_FAMILY_KEY 0x5246323047313431
%define G141_CONCAT 0
%define G141_MATCH 1
%define G141_NON_MATCH 2
%define G141_TEXT_LIMIT 4096
%define G141_CONCAT_LIMIT 8192

extern nebo_text_concat_checked
extern nebo_pattern_compile
extern nebo_pattern_match
extern nebo_pattern_non_match
extern nebo_utf8_pattern_boundaries

section .rodata
g141_n_concat: db 'concat'
g141_n_concat_len equ $-g141_n_concat
g141_n_matches: db 'matches'
g141_n_matches_len equ $-g141_n_matches
g141_n_Pattern: db 'Pattern'
g141_n_Pattern_len equ $-g141_n_Pattern
g141_n_byteLength: db 'byteLength'
g141_n_byteLength_len equ $-g141_n_byteLength
g141_n_codepointCount: db 'codepointCount'
g141_n_codepointCount_len equ $-g141_n_codepointCount
g141_n_graphemeCount: db 'graphemeCount'
g141_n_graphemeCount_len equ $-g141_n_graphemeCount
g141_n_checksum: db 'checksum'
g141_n_checksum_len equ $-g141_n_checksum
g141_n_matched: db 'matched'
g141_n_matched_len equ $-g141_n_matched
g141_n_captureStart: db 'captureStart'
g141_n_captureStart_len equ $-g141_n_captureStart
g141_n_captureLength: db 'captureLength'
g141_n_captureLength_len equ $-g141_n_captureLength
g141_n_patternLength: db 'patternLength'
g141_n_patternLength_len equ $-g141_n_patternLength
g141_n_budget: db 'budget'
g141_n_budget_len equ $-g141_n_budget
g141_n_operatorId: db 'operatorId'
g141_n_operatorId_len equ $-g141_n_operatorId

section .bss align=16
g141_scratch_start:
g141_kind: resq 1
g141_left_ptr: resq 1
g141_left_len: resq 1
g141_right_ptr: resq 1
g141_right_len: resq 1
g141_pattern_ptr: resq 1
g141_pattern_len: resq 1
g141_pattern_mode: resq 1
g141_budget: resq 1
g141_byte_length: resq 1
g141_codepoints: resq 1
g141_graphemes: resq 1
g141_checksum: resq 1
g141_matched: resq 1
g141_operator_id: resq 1
g141_descriptor: resq 4
g141_capture: resq 2
g141_unicode_counts: resq 2
g141_concat_buffer: resb G141_CONCAT_LIMIT
g141_scratch_end:

section .text

g141_api_at:
 push rbx
 mov rbx,rdi
%macro G141_API_MATCH 1
 mov rdi,rbx
 lea rsi,[rel g141_n_%1]
 mov edx,g141_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G141_API_MATCH concat
 G141_API_MATCH matches
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G141_API_MATCH

g141_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT_CONCAT
 jb .identifier
 cmp eax,NEBOC_TOKEN_PATTERN_NON_MATCH
 jbe .yes
.identifier:
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call g141_api_at
 test eax,eax
 jz .next
 ; Portable G141 APIs are heads such as concat(...), never legacy instance
 ; methods such as Text.concat(...).  The latter remain owned by G055.
 test rbx,rbx
 jz .yes
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .yes
.next:
 inc rbx
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop rbx
 ret

g141_expect:
 sub rsp,8
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret

g141_expect_comma:
 mov edi,NEBOC_TOKEN_COMMA
 jmp g141_expect

g141_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call g141_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call g141_expect
.done:
 add rsp,8
 ret

; Consume one ordinary quoted Text token without hidden decoding.  Advanced
; raw/tagged forms and escapes are rejected in this bounded operator profile.
; Success: RAX=0, RDX=content pointer, RCX=content byte length.
g141_parse_text:
 push rbx
 push r12
 sub rsp,8
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .type
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rbx,rax
 mov r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[rbx+NEBOC_TOKEN_END_OFFSET]
 cmp r9,r8
 jb .syntax
 sub r9,r8
 cmp r9,2
 jb .syntax
 mov r12,[rel ls_source]
 add r12,r8
 cmp byte [r12],'"'
 jne .type
 cmp byte [r12+r9-1],'"'
 jne .type
 sub r9,2
 cmp r9,G141_TEXT_LIMIT
 ja .domain
 lea rdx,[r12+1]
 xor ecx,ecx
.plain:
 cmp rcx,r9
 jae .accepted
 cmp byte [rdx+rcx],0x5c
 je .type
 cmp byte [rdx+rcx],0
 je .type
 inc rcx
 jmp .plain
.accepted:
 mov rcx,r9
 inc qword [rel ls_cursor]
 xor eax,eax
 jmp .done
.type:
 mov eax,28
 jmp .done
.domain:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

g141_parse_head:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_BANG
 je .bang_matches
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G141_HEAD 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g141_n_%1]
 mov edx,g141_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G141_HEAD concat,concat
 G141_HEAD matches,match
 jmp .syntax
.bang_matches:
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g141_n_matches]
 mov edx,g141_n_matches_len
 call ls_token_match
 test eax,eax
 jz .syntax
 mov qword [rel g141_kind],G141_NON_MATCH
 jmp .advance
.concat:
 mov qword [rel g141_kind],G141_CONCAT
 jmp .advance
.match:
 mov qword [rel g141_kind],G141_MATCH
 jmp .advance
.advance:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call g141_expect
 ret
.syntax:
 mov rax,-1
 ret
%undef G141_HEAD

; Consume Pattern(Text, mode, stepBudget) and compile into caller-owned state.
g141_parse_pattern:
 sub rsp,8
 lea rsi,[rel g141_n_Pattern]
 mov edx,g141_n_Pattern_len
 call ls_expect_atom
 test eax,eax
 jz .type
 mov edi,NEBOC_TOKEN_LPAREN
 call g141_expect
 test eax,eax
 jnz .done
 call g141_parse_text
 test eax,eax
 jnz .done
 mov [rel g141_pattern_ptr],rdx
 mov [rel g141_pattern_len],rcx
 call g141_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 cmp rdx,1
 ja .domain
 mov [rel g141_pattern_mode],rdx
 call g141_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 cmp rdx,1000000
 ja .domain
 mov [rel g141_budget],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call g141_expect
 test eax,eax
 jnz .done
 mov rdi,[rel g141_pattern_ptr]
 mov rsi,[rel g141_pattern_len]
 lea rdx,[rel g141_unicode_counts]
 call nebo_utf8_pattern_boundaries
 test eax,eax
 jnz .domain
 mov rdi,[rel g141_pattern_ptr]
 mov rsi,[rel g141_pattern_len]
 mov rdx,[rel g141_pattern_mode]
 mov rcx,[rel g141_budget]
 lea r8,[rel g141_descriptor]
 call nebo_pattern_compile
 test eax,eax
 jnz .domain
 xor eax,eax
 jmp .done
.type:
 mov eax,28
 jmp .done
.domain:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret

g141_parse_body:
 sub rsp,8
 call g141_parse_text
 test eax,eax
 jnz .done
 mov [rel g141_left_ptr],rdx
 mov [rel g141_left_len],rcx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp qword [rel g141_kind],G141_CONCAT
 jne .pattern_separator
 cmp eax,NEBOC_TOKEN_TEXT_CONCAT
 je .consume_separator
 cmp eax,NEBOC_TOKEN_COMMA
 jne .type
 jmp .consume_separator
.pattern_separator:
 cmp eax,NEBOC_TOKEN_COMMA
 je .consume_separator
 cmp qword [rel g141_kind],G141_MATCH
 jne .expect_non_match
 cmp eax,NEBOC_TOKEN_PATTERN_MATCH
 je .consume_separator
 cmp eax,NEBOC_TOKEN_PATTERN_NON_MATCH
 jne .type
 mov qword [rel g141_kind],G141_NON_MATCH
 jmp .consume_separator
.expect_non_match:
 ; The portable !matches form already supplies negation and therefore accepts
 ; only its comma separator; combining it with !~ would double the operator.
 cmp eax,NEBOC_TOKEN_COMMA
 jne .type
.consume_separator:
 inc qword [rel ls_cursor]
 cmp qword [rel g141_kind],G141_CONCAT
 jne .pattern
 call g141_parse_text
 test eax,eax
 jnz .done
 mov [rel g141_right_ptr],rdx
 mov [rel g141_right_len],rcx
 jmp .close
.pattern:
 call g141_parse_pattern
 test eax,eax
 jnz .done
.close:
 mov edi,NEBOC_TOKEN_RPAREN
 call g141_expect
 jmp .done
.type:
 mov eax,28
.done:
 add rsp,8
 ret

g141_execute:
 sub rsp,8
 cmp qword [rel g141_kind],G141_CONCAT
 jne .pattern
 mov rdi,[rel g141_left_ptr]
 mov rsi,[rel g141_left_len]
 mov rdx,[rel g141_right_ptr]
 mov rcx,[rel g141_right_len]
 lea r8,[rel g141_concat_buffer]
 mov r9d,G141_CONCAT_LIMIT
 call nebo_text_concat_checked
 test edx,edx
 jnz .domain
 mov [rel g141_byte_length],rax
 lea rdi,[rel g141_concat_buffer]
 mov rsi,rax
 lea rdx,[rel g141_unicode_counts]
 call nebo_utf8_pattern_boundaries
 test eax,eax
 jnz .domain
 mov rax,[rel g141_unicode_counts]
 mov [rel g141_codepoints],rax
 mov rax,[rel g141_unicode_counts+8]
 mov [rel g141_graphemes],rax
 xor r8d,r8d
 xor r9d,r9d
 lea r10,[rel g141_concat_buffer]
.checksum_loop:
 cmp r9,[rel g141_byte_length]
 jae .checksum_done
 imul r8,r8,33
 movzx eax,byte [r10+r9]
 add r8,rax
 xor edx,edx
 mov rax,r8
 mov ecx,251
 div rcx
 mov r8,rdx
 inc r9
 jmp .checksum_loop
.checksum_done:
 inc r8
 mov [rel g141_checksum],r8
 mov qword [rel g141_operator_id],74
 xor eax,eax
 jmp .done
.pattern:
 mov rdi,[rel g141_left_ptr]
 mov rsi,[rel g141_left_len]
 lea rdx,[rel g141_unicode_counts]
 call nebo_utf8_pattern_boundaries
 test eax,eax
 jnz .domain
 mov rdi,[rel g141_left_ptr]
 mov rsi,[rel g141_left_len]
 lea rdx,[rel g141_descriptor]
 lea rcx,[rel g141_capture]
 cmp qword [rel g141_kind],G141_MATCH
 jne .non_match
 call nebo_pattern_match
 mov qword [rel g141_operator_id],75
 jmp .pattern_done
.non_match:
 call nebo_pattern_non_match
 mov qword [rel g141_operator_id],76
.pattern_done:
 test edx,edx
 jnz .domain
 mov [rel g141_matched],rax
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
.done:
 add rsp,8
 ret

g141_parse_observer:
 sub rsp,8
 mov edi,NEBOC_TOKEN_DOT
 call g141_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 cmp qword [rel g141_kind],G141_CONCAT
 jne .pattern_observer
%macro G141_CONCAT_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g141_n_%1]
 mov edx,g141_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G141_CONCAT_OBSERVER byteLength,byte_length
 G141_CONCAT_OBSERVER codepointCount,codepoints
 G141_CONCAT_OBSERVER graphemeCount,graphemes
 G141_CONCAT_OBSERVER checksum,checksum
 G141_CONCAT_OBSERVER operatorId,operator_id
 jmp .type
.pattern_observer:
%macro G141_PATTERN_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g141_n_%1]
 mov edx,g141_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G141_PATTERN_OBSERVER matched,matched
 G141_PATTERN_OBSERVER captureStart,capture_start
 G141_PATTERN_OBSERVER captureLength,capture_length
 G141_PATTERN_OBSERVER patternLength,pattern_length
 G141_PATTERN_OBSERVER budget,budget
 G141_PATTERN_OBSERVER operatorId,operator_id
 jmp .type
.byte_length: mov rdx,[rel g141_byte_length]
 jmp .consume
.codepoints: mov rdx,[rel g141_codepoints]
 jmp .consume
.graphemes: mov rdx,[rel g141_graphemes]
 jmp .consume
.checksum: mov rdx,[rel g141_checksum]
 jmp .consume
.matched: mov rdx,[rel g141_matched]
 jmp .consume
.capture_start: mov rdx,[rel g141_capture]
 jmp .consume
.capture_length: mov rdx,[rel g141_capture+8]
 jmp .consume
.pattern_length: mov rdx,[rel g141_pattern_len]
 jmp .consume
.budget: mov rdx,[rel g141_budget]
 jmp .consume
.operator_id: mov rdx,[rel g141_operator_id]
.consume:
 push rdx
 inc qword [rel ls_cursor]
 call g141_empty_call
 pop rdx
 jmp .done
.type:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret
%undef G141_CONCAT_OBSERVER
%undef G141_PATTERN_OBSERVER

g141_parse_term:
 call g141_parse_head
 test eax,eax
 jnz .done
 call g141_parse_body
 test eax,eax
 jnz .done
 call g141_execute
 test eax,eax
 jnz .done
 call g141_parse_observer
.done:
 ret

g141_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call .clear_term
 call g141_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
.plus_loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 call .clear_term
 call g141_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 add [rsp],rdx
 jo .overflow
 jmp .plus_loop
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,G141_FAMILY_KEY
 call ls_success
 jmp .done
.semantic:
 call .record_error_token
 mov edi,eax
 call ls_error
 jmp .done
.overflow:
 call .record_error_token
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 call .record_error_token
 mov edi,24
 call ls_error
 jmp .done
.clear_term:
 lea rdi,[rel g141_scratch_start]
 mov ecx,(g141_scratch_end-g141_scratch_start)/8
 xor eax,eax
 rep stosq
 ret
.record_error_token:
 mov r8,rax
 mov rcx,[rel ls_cursor]
 cmp rcx,[rel ls_token_count]
 jb .error_token_ready
 mov rcx,[rel ls_token_count]
 test rcx,rcx
 jz .error_token_ready
 dec rcx
.error_token_ready:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rcx
 mov rax,r8
 ret
.done:
 add rsp,16
 pop rbx
 ret
