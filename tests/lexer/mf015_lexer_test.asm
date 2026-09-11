bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
extern neboc_lexer_scan
extern neboc_host_process_exit

section .rodata
s5: db 0xc3,0xa9,'x'
s5_len equ $-s5
s6: db '9223372036854775807 -9223372036854775808'
s6_len equ $-s6
s7: db '9223372036854775808 18446744073709551615'
s7_len equ $-s7
s8: db 34,'A',92,'n',92,'r',92,'t',92,92,92,34,0xc3,0xa9,34
s8_len equ $-s8
s9: db '"Ola/n"'
s9_len equ $-s9
s10: db 34,'b','a','d',92,'q',34,' ','a','f','t','e','r'
s10_len equ $-s10
s11: db '"unterminated'
s11_len equ $-s11
s13: db '/* block */ start'
s13_len equ $-s13
s15: db 'start(){-9223372036854775808.valor;',34,'A',92,'n',34,'.console();}'
s15_len equ $-s15
fuzz0: db 0xff,0,0xc0,0xaf,34,92,'q','/','*','x','*','/'
fuzz0_len equ $-fuzz0
fuzz1: db '"',0xe2,0x82,' ',0x80,'123999999999999999999999999999'
fuzz1_len equ $-fuzz1
fuzz_table: dq fuzz0,fuzz0_len,fuzz1,fuzz1_len

section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens_a: resb NEBOC_TOKEN_SIZE*256
tokens_b: resb NEBOC_TOKEN_SIZE*256
literals_a: resb 1024
literals_b: resb 1024
saved_count: resq 1
saved_errors: resq 1
saved_literals: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rsi,[rsp+16]
 xor ecx,ecx
.parse:
 movzx eax,byte [rsi]
 test al,al
 jz .dispatch
 sub al,'0'
 cmp al,9
 ja test_usage
 imul ecx,ecx,10
 movzx eax,al
 add ecx,eax
 inc rsi
 jmp .parse
.dispatch:
 cmp ecx,5
 je scenario5
 cmp ecx,6
 je scenario6
 cmp ecx,7
 je scenario7
 cmp ecx,8
 je scenario8
 cmp ecx,9
 je scenario9
 cmp ecx,10
 je scenario10
 cmp ecx,11
 je scenario11
 cmp ecx,13
 je scenario13
 cmp ecx,15
 je scenario15
 cmp ecx,99
 je scenario99
 jmp test_usage

scenario5:
 lea rdi,[rel s5]
 mov esi,s5_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID_IDENTIFIER
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_DIAG_LEX_INVALID_CHARACTER
 jne test_fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario6:
 lea rdi,[rel s6]
 mov esi,s6_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],4
 jne test_fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne test_fail
 mov rax,0x7fffffffffffffff
 cmp [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],rax
 jne test_fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne test_fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne test_fail
 mov rax,0x8000000000000000
 cmp [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],rax
 jne test_fail
 test qword [r8+NEBOC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 jz test_fail
 xor eax,eax
 jmp test_exit

scenario7:
 lea rdi,[rel s7]
 mov esi,s7_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],2
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INT_OVERFLOW
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_DIAG_LEX_INT_OVERFLOW
 jne test_fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INT_OVERFLOW
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario8:
 lea rdi,[rel s8]
 mov esi,s8_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],8
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],8
 jne test_fail
 mov rax,0xa9c3225c090d0a41
 cmp [rel literals_a],rax
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario9:
 lea rdi,[rel s9]
 mov esi,s9_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],5
 jne test_fail
 cmp byte [rel literals_a+3],'/'
 jne test_fail
 cmp byte [rel literals_a+4],'n'
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario10:
 lea rdi,[rel s10]
 mov esi,s10_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID_ESCAPE
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_DIAG_LEX_INVALID_ESCAPE
 jne test_fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario11:
 lea rdi,[rel s11]
 mov esi,s11_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_UNTERMINATED_TEXT
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_DIAG_LEX_UNTERMINATED_TEXT
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario13:
 lea rdi,[rel s13]
 mov esi,s13_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 ; G164 activates nested block comments as canonical trivia. The comment is
 ; discarded by the token stream and the following keyword remains visible.
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne test_fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],2
 jne test_fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario15:
 lea rdi,[rel s15]
 mov esi,s15_len
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 test eax,eax
 jnz test_exit
 mov rax,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel saved_count],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 mov [rel saved_errors],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel saved_literals],rax
 lea rdi,[rel s15]
 mov esi,s15_len
 lea rdx,[rel tokens_b]
 lea rcx,[rel literals_b]
 call lex_source
 test eax,eax
 jnz test_exit
 mov rax,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 cmp rax,[rel saved_count]
 jne test_fail
 mov rax,[rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 cmp rax,[rel saved_errors]
 jne test_fail
 mov rax,[rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rax,[rel saved_literals]
 jne test_fail
 mov rcx,[rel saved_count]
 imul rcx,NEBOC_TOKEN_QWORDS
 lea rsi,[rel tokens_a]
 lea rdi,[rel tokens_b]
 repe cmpsq
 jne test_fail
 mov rcx,[rel saved_literals]
 lea rsi,[rel literals_a]
 lea rdi,[rel literals_b]
 repe cmpsb
 jne test_fail
 xor eax,eax
 jmp test_exit

scenario99:
 lea rbx,[rel fuzz_table]
 mov r12d,2
.fuzz_loop:
 test r12d,r12d
 jz .fuzz_good
 mov rdi,[rbx]
 mov rsi,[rbx+8]
 lea rdx,[rel tokens_a]
 lea rcx,[rel literals_a]
 call lex_source
 cmp eax,NEBOC_STATUS_OK
 je .fuzz_next
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
.fuzz_next:
 add rbx,16
 dec r12d
 jmp .fuzz_loop
.fuzz_good:
 xor eax,eax
 jmp test_exit

; lex_source(source,length,tokens,literal_buffer)
lex_source:
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rdi
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],rsi
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],15
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rdx
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],256
 mov qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_LEXER_REQUEST_FLAGS_OFFSET],0
 mov [rel request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rcx
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],1024
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],0
 mov qword [rel request+NEBOC_LEXER_REQUEST_STEP_BUDGET_OFFSET],0
 sub rsp,8
 lea rdi,[rel request]
 call neboc_lexer_scan
 add rsp,8
 ret

test_fail:
 mov eax,1
test_exit:
 mov edi,eax
 jmp neboc_host_process_exit
test_usage:
 mov edi,99
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
