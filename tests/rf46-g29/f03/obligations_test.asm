bits 64
default rel
%include "compiler/verification/obligations.inc"
extern nebo_obligation_evaluate,nebo_obligations_validate_count
section .bss
result resb NEBO_OBLIGATION_RESULT_SIZE
section .text
global _start
_start:
 mov edi,NEBO_OBLIGATION_OVERFLOW_ADD
 mov rsi,40
 mov rdx,2
 lea rcx,[result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_OBLIGATION_STATE_PROVED
 jne fail
 cmp qword [result+8],42
 jne fail
 mov edi,NEBO_OBLIGATION_BOUNDS
 mov rsi,9
 mov rdx,4
 lea rcx,[result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_OBLIGATION_STATE_FAILED
 jne fail
 mov edi,NEBO_OBLIGATION_CLEANUP
 mov esi,3
 mov edx,1
 lea rcx,[result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_OBLIGATION_STATE_RUNTIME
 jne fail
 mov edi,257
 call nebo_obligations_validate_count
 cmp eax,NEBO_OBLIGATION_STATUS_LIMIT
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
