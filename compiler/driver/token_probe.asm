; Bounded read-only transport for the canonical lexer. Tooling consumes the
; exact token/source spans; it never reparses string/interpolation syntax.
bits 64
default rel
%include "compiler/lexer/lexer.inc"
%include "compiler/tokens/token.inc"
%define SOURCE_LIMIT 1048576
%define TOKEN_LIMIT 32768
extern neboc_lexer_scan
global _start
section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
header: resq 8
source: resb SOURCE_LIMIT+1
resb 15
tokens: resb TOKEN_LIMIT*NEBOC_TOKEN_SIZE
literals: resb SOURCE_LIMIT
section .text
_start:
 xor r12d,r12d
.read:
 xor eax,eax
 xor edi,edi
 lea rsi,[rel source]
 add rsi,r12
 mov edx,SOURCE_LIMIT+1
 sub rdx,r12
 syscall
 cmp rax,-4
 je .read
 test rax,rax
 js .fail
 jz .scan
 add r12,rax
 cmp r12,SOURCE_LIMIT
 jbe .read
 jmp .fail
.scan:
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],r12
 lea rax,[rel source]
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],1
 lea rax,[rel tokens]
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],TOKEN_LIMIT
 lea rax,[rel literals]
 mov [rel request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],SOURCE_LIMIT
 lea rdi,[rel request]
 call neboc_lexer_scan
 mov [rel header+32],rax
 mov rax,0x314e4b544f42454e
 mov [rel header],rax
 mov qword [rel header+8],1
 mov [rel header+16],r12
 mov rax,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel header+24],rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,64
 mov rdx,[rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel header+48],rdx
 add rax,rdx
 mov [rel header+56],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 mov [rel header+40],rax
 lea rsi,[rel header]
 mov edx,64
 call write_bytes
 lea rsi,[rel tokens]
 mov rdx,[rel header+24]
 imul rdx,NEBOC_TOKEN_SIZE
 call write_bytes
 lea rsi,[rel literals]
 mov rdx,[rel header+48]
 call write_bytes
 xor edi,edi
 jmp .exit
.fail:
 mov edi,1
.exit:
 mov eax,60
 syscall
write_bytes:
 test rdx,rdx
 jz .done
 mov eax,1
 mov edi,1
 syscall
 cmp rax,-4
 je write_bytes
 test rax,rax
 jle _start.fail
 add rsi,rax
 sub rdx,rax
 jmp write_bytes
.done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
