bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
extern neboc_lexer_scan
extern neboc_host_process_exit

section .rodata
s1: db '3.5'
s1_len equ $-s1
s2: db '0.125'
s2_len equ $-s2
s3: db '100.num'
s3_len equ $-s3
s4: db '3.5.value'
s4_len equ $-s4
s5: db '3.'
s5_len equ $-s5
s6: db '999999999999999999999999999999999999.0'
s6_len equ $-s6
s7: db '1e2'
s7_len equ $-s7
s8: db '12.3400'
s8_len equ $-s8

section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens_a: resb NEBOC_TOKEN_SIZE*32
tokens_b: resb NEBOC_TOKEN_SIZE*32
literals: resb 128
count_a: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne fail_usage
 mov rsi,[rsp+16]
 movzx ecx,byte [rsi]
 sub ecx,'0'
 cmp ecx,1
 jb fail_usage
 cmp ecx,8
 ja fail_usage
 cmp ecx,1
 je sc1
 cmp ecx,2
 je sc2
 cmp ecx,3
 je sc3
 cmp ecx,4
 je sc4
 cmp ecx,5
 je sc5
 cmp ecx,6
 je sc6
 cmp ecx,7
 je sc7
 jmp sc8

sc1:
 lea rdi,[rel s1]
 mov esi,s1_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],2
 jne fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne fail
 mov rax,0x0000000100000001
 cmp [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],rax
 jne fail
 jmp pass
sc2:
 lea rdi,[rel s2]
 mov esi,s2_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne fail
 mov rax,0x0000000100000003
 cmp [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],rax
 jne fail
 jmp pass
sc3:
 lea rdi,[rel s3]
 mov esi,s3_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],4
 jne fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne fail
 jmp pass
sc4:
 lea rdi,[rel s4]
 mov esi,s4_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne fail
 jmp pass
sc5:
 lea rdi,[rel s5]
 mov esi,s5_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne fail
 jmp pass
sc6:
 lea rdi,[rel s6]
 mov esi,s6_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne fail
 jmp pass
sc7:
 lea rdi,[rel s7]
 mov esi,s7_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 lea r8,[rel tokens_a]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne fail
 jmp pass
sc8:
 ; Preserve the first count in memory: r10 is caller-saved under SysV.
 lea rdi,[rel s8]
 mov esi,s8_len
 lea rdx,[rel tokens_a]
 call lex
 test eax,eax
 jnz exit
 mov rax,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel count_a],rax
 lea rdi,[rel s8]
 mov esi,s8_len
 lea rdx,[rel tokens_b]
 call lex
 test eax,eax
 jnz exit
 mov r10,[rel count_a]
 cmp r10,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jne fail
 imul r10,NEBOC_TOKEN_QWORDS
 lea rsi,[rel tokens_a]
 lea rdi,[rel tokens_b]
 mov rcx,r10
 cld
 repe cmpsq
 jne fail
 jmp pass

lex:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 lea rdi,[rel request]
 mov ecx,NEBOC_LEXER_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],r12
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],r13
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],1
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rbx
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],32
 lea rax,[rel literals]
 mov [rel request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],128
 mov qword [rel request+NEBOC_LEXER_REQUEST_STEP_BUDGET_OFFSET],4096
 lea rdi,[rel request]
 call neboc_lexer_scan
 pop r13
 pop r12
 pop rbx
 ret
pass:
 xor eax,eax
 jmp exit
fail_usage:
 mov eax,2
 jmp exit
fail:
 mov eax,1
exit:
 mov edi,eax
 call neboc_host_process_exit
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
