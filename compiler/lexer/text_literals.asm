; Bounded Text literal scanner. No allocation and no template activation.
bits 64
default rel
%include "compiler/lexer/text_literals.inc"

global neboc_text_literal_scan
global neboc_text_literal_token
global neboc_raw_literal_scan
global neboc_text_segment_init

section .text
; rdi=source, rsi=byte length. eax=status, rdx=decoded length, rcx=error/source offset.
align 16
neboc_text_literal_scan:
 xor edx,edx
 xor ecx,ecx
 test rdi,rdi
 jz .null
 cmp rsi,2
 jb .unterminated
 cmp byte [rdi],'"'
 jne .unterminated
 cmp byte [rdi+rsi-1],'"'
 jne .unterminated
 mov rcx,1
 lea r8,[rsi-1]
.loop:
 cmp rcx,r8
 jae .ok
 mov al,[rdi+rcx]
 cmp al,10
 je .unterminated
 cmp al,0x5c
 jne .plain
 inc rcx
 cmp rcx,r8
 jae .unterminated
 mov al,[rdi+rcx]
 cmp al,'n'
 je .escaped
 cmp al,'r'
 je .escaped
 cmp al,'t'
 je .escaped
 cmp al,'0'
 je .escaped
 cmp al,0x5c
 je .escaped
 cmp al,'"'
 jne .bad_escape
.escaped:
 inc rdx
 inc rcx
 jmp .loop
.plain:
 inc rdx
 inc rcx
 jmp .loop
.ok:
 xor eax,eax
 xor ecx,ecx
 ret
.null:
 mov eax,NEBO_LITERAL_NULL
 ret
.unterminated:
 mov eax,NEBO_LITERAL_UNTERMINATED
 ret
.bad_escape:
 mov eax,NEBO_LITERAL_BAD_ESCAPE
 ret

; rdi=source, rsi=length, rdx=absolute start, rcx=out token.  The token keeps
; the original lexeme and exact half-open span; decoded bytes remain owned by
; the live lexer stage.  The output record is committed only on success.
align 16
neboc_text_literal_token:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test r14,r14
 jz .token_null
 call neboc_text_literal_scan
 test eax,eax
 jnz .token_error
 mov r15,rdx
 mov rax,r13
 add rax,r12
 jc .token_unterminated
 mov qword [r14+NEBO_TEXT_LITERAL_TOKEN_KIND_OFFSET],NEBO_TOKEN_TEXT_LITERAL
 mov [r14+NEBO_TEXT_LITERAL_TOKEN_LEXEME_OFFSET],rbx
 mov [r14+NEBO_TEXT_LITERAL_TOKEN_LENGTH_OFFSET],r12
 mov [r14+NEBO_TEXT_LITERAL_TOKEN_START_OFFSET],r13
 mov [r14+NEBO_TEXT_LITERAL_TOKEN_END_OFFSET],rax
 mov [r14+NEBO_TEXT_LITERAL_TOKEN_DECODED_LENGTH_OFFSET],r15
 mov qword [r14+NEBO_TEXT_LITERAL_TOKEN_DIAGNOSTIC_OFFSET],0
 xor eax,eax
 xor edx,edx
 jmp .token_done
.token_error:
 cmp eax,NEBO_LITERAL_BAD_ESCAPE
 je .token_bad_escape
.token_unterminated:
 mov eax,NEBO_LITERAL_UNTERMINATED
 mov edx,NEBO_LEX_003
 jmp .token_done
.token_bad_escape:
 mov edx,NEBO_LEX_004
 jmp .token_done
.token_null:
 mov eax,NEBO_LITERAL_NULL
 xor edx,edx
.token_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=source, rsi=length. Recognizes only triple-quote raw/multiline Text.
; eax=status, rcx=content start, rdx=content length. Template braces stay inactive.
align 16
neboc_raw_literal_scan:
 xor edx,edx
 xor ecx,ecx
 test rdi,rdi
 jz .raw_null
 cmp rsi,6
 jb .raw_unterminated
 cmp byte [rdi],'"'
 jne .raw_unterminated
 cmp byte [rdi+1],'"'
 jne .raw_unterminated
 cmp byte [rdi+2],'"'
 jne .raw_unterminated
 lea r8,[rsi-3]
 cmp byte [rdi+r8],'"'
 jne .raw_unterminated
 cmp byte [rdi+r8+1],'"'
 jne .raw_unterminated
 cmp byte [rdi+r8+2],'"'
 jne .raw_unterminated
 mov ecx,3
 mov rdx,rsi
 sub rdx,6
 xor eax,eax
 ret
.raw_null:
 mov eax,NEBO_LITERAL_NULL
 ret
.raw_unterminated:
 mov eax,NEBO_LITERAL_UNTERMINATED
 ret

; rdi=preserved literal bytes, rsi=length, rdx=absolute start, rcx=out
; TextSegment.  This is a lexical/AST foundation only: it performs no template
; interpolation, dedent or newline normalization.
align 16
neboc_text_segment_init:
 test rcx,rcx
 jz .segment_null
 test rsi,rsi
 jz .segment_commit
 test rdi,rdi
 jz .segment_null
.segment_commit:
 mov r8,rdx
 add r8,rsi
 jc .segment_range
 mov qword [rcx+NEBO_TEXT_SEGMENT_KIND_OFFSET],NEBO_TEXT_SEGMENT_LITERAL
 mov [rcx+NEBO_TEXT_SEGMENT_DATA_OFFSET],rdi
 mov [rcx+NEBO_TEXT_SEGMENT_LENGTH_OFFSET],rsi
 mov [rcx+NEBO_TEXT_SEGMENT_START_OFFSET],rdx
 mov [rcx+NEBO_TEXT_SEGMENT_END_OFFSET],r8
 xor eax,eax
 ret
.segment_null:
 mov eax,NEBO_LITERAL_NULL
 ret
.segment_range:
 mov eax,NEBO_LITERAL_UNTERMINATED
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
