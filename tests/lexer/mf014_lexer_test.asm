bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
extern neboc_lexer_scan
extern neboc_host_process_exit
section .rodata
s1: db 'start(){a.b;}'
s1_len equ $-s1
s2: db 'start if else true false return'
s2_len equ $-s2
s3: db 'for when while switch loop break continue module import export async await match struct enum interface class generic'
s3_len equ $-s3
s4: db 'a alunoMusica resultado_1 _consoleInterno Aluno ALUNO'
s4_len equ $-s4
s12: db 'start // comment',10,' if'
s12_len equ $-s12
s14: db '== = != ! <= < >= > && || -> - + * / % : [ ]'
s14_len equ $-s14
s98: db '@a'
s98_len equ $-s98
expected1: dq NEBOC_TOKEN_KW_START,NEBOC_TOKEN_LPAREN,NEBOC_TOKEN_RPAREN,NEBOC_TOKEN_LBRACE,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_DOT,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_SEMICOLON,NEBOC_TOKEN_RBRACE,NEBOC_TOKEN_EOF
expected2: dq NEBOC_TOKEN_KW_START,NEBOC_TOKEN_KW_IF,NEBOC_TOKEN_KW_ELSE,NEBOC_TOKEN_KW_TRUE,NEBOC_TOKEN_KW_FALSE,NEBOC_TOKEN_KW_RETURN,NEBOC_TOKEN_EOF
expected3: dq NEBOC_TOKEN_KW_FOR,NEBOC_TOKEN_KW_WHEN,NEBOC_TOKEN_KW_WHILE,NEBOC_TOKEN_KW_SWITCH,NEBOC_TOKEN_KW_LOOP,NEBOC_TOKEN_KW_BREAK,NEBOC_TOKEN_KW_CONTINUE,NEBOC_TOKEN_KW_MODULE,NEBOC_TOKEN_KW_IMPORT,NEBOC_TOKEN_KW_EXPORT,NEBOC_TOKEN_KW_ASYNC,NEBOC_TOKEN_KW_AWAIT,NEBOC_TOKEN_KW_MATCH,NEBOC_TOKEN_KW_STRUCT,NEBOC_TOKEN_KW_ENUM,NEBOC_TOKEN_KW_INTERFACE,NEBOC_TOKEN_KW_CLASS,NEBOC_TOKEN_KW_GENERIC,NEBOC_TOKEN_EOF
expected3_flags: dq 0,NEBOC_TOKEN_FLAG_DEFERRED,0,NEBOC_TOKEN_FLAG_DEFERRED,0,0,0,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,NEBOC_TOKEN_FLAG_DEFERRED,0
expected4: dq NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_EOF
expected12: dq NEBOC_TOKEN_KW_START,NEBOC_TOKEN_KW_IF,NEBOC_TOKEN_EOF
; G143 made the declaration metadata prefix a live, non-expression token.
expected98: dq NEBOC_TOKEN_ANNOTATION,NEBOC_TOKEN_IDENTIFIER,NEBOC_TOKEN_EOF
expected14: dq NEBOC_TOKEN_EQUAL_EQUAL,NEBOC_TOKEN_RESERVED_EQUAL,NEBOC_TOKEN_BANG_EQUAL,NEBOC_TOKEN_BANG,NEBOC_TOKEN_LESS_EQUAL,NEBOC_TOKEN_LESS,NEBOC_TOKEN_GREATER_EQUAL,NEBOC_TOKEN_GREATER,NEBOC_TOKEN_AND_AND,NEBOC_TOKEN_OR_OR,NEBOC_TOKEN_RESERVED_ARROW,NEBOC_TOKEN_MINUS,NEBOC_TOKEN_PLUS,NEBOC_TOKEN_STAR,NEBOC_TOKEN_SLASH,NEBOC_TOKEN_PERCENT,NEBOC_TOKEN_RESERVED_COLON,NEBOC_TOKEN_RESERVED_LBRACKET,NEBOC_TOKEN_RESERVED_RBRACKET,NEBOC_TOKEN_EOF
section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*128
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
 cmp ecx,1
 je .case1
 cmp ecx,2
 je .case2
 cmp ecx,3
 je .case3
 cmp ecx,4
 je .case4
 cmp ecx,12
 je .case12
 cmp ecx,14
 je .case14
 cmp ecx,98
 je .case98
 jmp test_usage
.case1:
 lea rdi,[rel s1]
 mov esi,s1_len
 lea rdx,[rel expected1]
 mov ecx,10
 call run_case
 test eax,eax
 jnz test_exit
 ; exact spans for first/basic stream
 lea r8,[rel tokens]
 cmp qword [r8+NEBOC_TOKEN_START_OFFSET],0
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_END_OFFSET],5
 jne test_fail
 lea r8,[r8+NEBOC_TOKEN_SIZE*9]
 cmp qword [r8+NEBOC_TOKEN_START_OFFSET],13
 jne test_fail
 cmp qword [r8+NEBOC_TOKEN_END_OFFSET],13
 jne test_fail
 xor eax,eax
 jmp test_exit
.case2:
 lea rdi,[rel s2]
 mov esi,s2_len
 lea rdx,[rel expected2]
 mov ecx,7
 call run_case
 jmp test_exit
.case3:
 lea rdi,[rel s3]
 mov esi,s3_len
 lea rdx,[rel expected3]
 mov ecx,19
 call run_case
 test eax,eax
 jnz test_exit
 lea r8,[rel tokens]
 lea r10,[rel expected3_flags]
 ; Active control keywords are executable; reserved/future keywords remain deferred.
 xor r9d,r9d
.defer_loop:
 cmp r9d,19
 jae .defer_done
 mov rax,[r10+r9*8]
 cmp qword [r8+NEBOC_TOKEN_FLAGS_OFFSET],rax
 jne test_fail
 add r8,NEBOC_TOKEN_SIZE
 inc r9d
 jmp .defer_loop
.defer_done:
 xor eax,eax
 jmp test_exit
.case4:
 lea rdi,[rel s4]
 mov esi,s4_len
 lea rdx,[rel expected4]
 mov ecx,7
 call run_case
 jmp test_exit
.case12:
 lea rdi,[rel s12]
 mov esi,s12_len
 lea rdx,[rel expected12]
 mov ecx,3
 call run_case
 jmp test_exit
.case98:
 lea rdi,[rel s98]
 mov esi,s98_len
 lea rdx,[rel expected98]
 mov ecx,3
 call run_case
 jmp test_exit
.case14:
 lea rdi,[rel s14]
 mov esi,s14_len
 lea rdx,[rel expected14]
 mov ecx,20
 call run_case
 jmp test_exit
; run_case(source,length,expected,count)
run_case:
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rdi
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],rsi
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],7
 lea rax,[rel tokens]
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],128
 mov qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 sub rsp,24
 mov [rsp],rdx
 mov [rsp+8],rcx
 lea rdi,[rel request]
 call neboc_lexer_scan
 mov rdx,[rsp]
 mov rcx,[rsp+8]
 add rsp,24
 test eax,eax
 jnz .ret
 cmp [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],rcx
 jne .bad
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 lea r8,[rel tokens]
 xor r9d,r9d
.check_loop:
 cmp r9,rcx
 jae .good
 mov rax,[rdx+r9*8]
 cmp [r8+NEBOC_TOKEN_KIND_OFFSET],rax
 jne .bad
 cmp qword [r8+NEBOC_TOKEN_SOURCE_ID_OFFSET],7
 jne .bad
 mov rax,[r8+NEBOC_TOKEN_START_OFFSET]
 cmp rax,[r8+NEBOC_TOKEN_END_OFFSET]
 ja .bad
 add r8,NEBOC_TOKEN_SIZE
 inc r9
 jmp .check_loop
.good:
 xor eax,eax
.ret:
 ret
.bad:
 mov eax,1
 ret

run_case_allow_one_error:
 sub rsp,24
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rdi
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],rsi
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],7
 lea rax,[rel tokens]
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],128
 mov qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 lea rdi,[rel request]
 call neboc_lexer_scan
 mov rdx,[rsp]
 mov rcx,[rsp+8]
 add rsp,24
 test eax,eax
 jnz .ret_recovery
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne .bad_recovery
 cmp [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],rcx
 jne .bad_recovery
 lea r8,[rel tokens]
 xor r9d,r9d
.check_recovery:
 cmp r9,rcx
 jae .good_recovery
 mov rax,[rdx+r9*8]
 cmp [r8+NEBOC_TOKEN_KIND_OFFSET],rax
 jne .bad_recovery
 add r8,NEBOC_TOKEN_SIZE
 inc r9
 jmp .check_recovery
.good_recovery:
 xor eax,eax
.ret_recovery:
 ret
.bad_recovery:
 mov eax,1
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
