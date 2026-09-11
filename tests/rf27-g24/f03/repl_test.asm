bits 64
default rel
%include "compiler/repl/repl.inc"

section .rodata
source_a: db 'abc'
source_a_len equ $-source_a
source_b: db 'start(){}',10
source_b_len equ $-source_b

section .bss
align 16
session resb NEBO_REPL_SESSION_SIZE

section .text
global _start
_start:
    lea rdi,[session]
    call nebo_repl_session_init
    test eax,eax
    jnz .fail1
    lea rdi,[session]
    call nebo_repl_session_validate
    test eax,eax
    jnz .fail2
    cmp qword [session+NEBO_REPL_SESSION_GENERATION],1
    jne .fail3
    cmp qword [session+NEBO_REPL_SESSION_FLAGS],NEBO_REPL_REQUIRED_FLAGS
    jne .fail4

    lea rdi,[session]
    lea rsi,[source_a]
    mov edx,source_a_len
    mov ecx,NEBO_REPL_RECORD_EVALUATE
    mov r8d,1
    call nebo_repl_session_record
    test eax,eax
    jnz .fail5
    cmp qword [session+NEBO_REPL_SESSION_DECLARATIONS],1
    jne .fail6
    cmp qword [session+NEBO_REPL_SESSION_SOURCE_BYTES],source_a_len
    jne .fail7
    mov rax,[session+NEBO_REPL_SESSION_DIGEST]
    mov rbx,NEBO_REPL_FNV1A64_OFFSET
    cmp rax,rbx
    je .fail8

    lea rdi,[session]
    lea rsi,[source_b]
    mov edx,source_b_len
    mov ecx,NEBO_REPL_RECORD_LOAD
    mov r8d,1
    call nebo_repl_session_record
    test eax,eax
    jnz .fail9
    cmp qword [session+NEBO_REPL_SESSION_LOADS],1
    jne .fail10
    cmp qword [session+NEBO_REPL_SESSION_HISTORY],2
    jne .fail11

    ; Stale generation and invalid kind are rejected without ledger mutation.
    mov rbx,[session+NEBO_REPL_SESSION_HISTORY]
    lea rdi,[session]
    lea rsi,[source_a]
    mov edx,source_a_len
    mov ecx,NEBO_REPL_RECORD_EVALUATE
    xor r8d,r8d
    call nebo_repl_session_record
    cmp eax,NEBO_REPL_ERROR_STALE
    jne .fail12
    cmp rbx,[session+NEBO_REPL_SESSION_HISTORY]
    jne .fail12
    lea rdi,[session]
    lea rsi,[source_a]
    mov edx,source_a_len
    mov ecx,9
    mov r8d,1
    call nebo_repl_session_record
    cmp eax,NEBO_REPL_ERROR_KIND
    jne .fail13

    lea rdi,[session]
    call nebo_repl_session_reset
    test eax,eax
    jnz .fail14
    cmp qword [session+NEBO_REPL_SESSION_GENERATION],2
    jne .fail14
    cmp qword [session+NEBO_REPL_SESSION_HISTORY],0
    jne .fail14
    cmp qword [session+NEBO_REPL_SESSION_SOURCE_BYTES],0
    jne .fail14
    mov rax,[session+NEBO_REPL_SESSION_DIGEST]
    mov rbx,NEBO_REPL_FNV1A64_OFFSET
    cmp rax,rbx
    jne .fail14

    lea rdi,[session]
    lea rsi,[source_a]
    mov edx,source_a_len
    mov ecx,NEBO_REPL_RECORD_EVALUATE
    mov r8d,1
    call nebo_repl_session_record
    cmp eax,NEBO_REPL_ERROR_STALE
    jne .fail15

    inc qword [session+NEBO_REPL_SESSION_FLAGS]
    lea rdi,[session]
    call nebo_repl_session_validate
    cmp eax,NEBO_REPL_ERROR_CONTRACT
    jne .fail16

    xor edi,edi
    jmp .exit
%assign i 1
%rep 16
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall
