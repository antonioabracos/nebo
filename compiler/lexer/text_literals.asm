; Bounded Text literal scanner. No allocation and no template activation.
bits 64
default rel
%include "compiler/lexer/text_literals.inc"

global neboc_text_literal_scan
global neboc_raw_literal_scan

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

section .note.GNU-stack noalloc noexec nowrite progbits
