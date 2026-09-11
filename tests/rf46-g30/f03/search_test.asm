bits 64
default rel
%include "runtime/solver/search.inc"
extern nebo_solver_solve,nebo_solver_verify_assignment
section .data
model: dq 8,5,2,256
section .bss
result resb NEBO_SEARCH_RESULT_SIZE
section .text
global _start
_start:
 lea rdi,[model]
 lea rsi,[result]
 call nebo_solver_solve
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_SEARCH_STATE_SAT
 jne fail
 cmp qword [result+8],5
 jne fail
 cmp qword [result+24],1
 jne fail
 lea rdi,[model]
 mov rsi,[result+8]
 call nebo_solver_verify_assignment
 test eax,eax
 jnz fail
 lea rdi,[model]
 mov esi,2
 call nebo_solver_verify_assignment
 cmp eax,NEBO_SEARCH_STATUS_REJECTED
 jne fail
 mov qword [model+NEBO_SEARCH_MODEL_STEP_BUDGET],1
 mov qword [model+NEBO_SEARCH_MODEL_REQUIRED_MASK],128
 lea rdi,[model]
 lea rsi,[result]
 call nebo_solver_solve
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_SEARCH_STATE_TIMEOUT
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
