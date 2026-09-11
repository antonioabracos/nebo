bits 64
default rel
%include "runtime/workflow/saga.inc"
extern nebo_retry_delay
extern nebo_idempotency_lookup
extern nebo_saga_compensation_order
extern nebo_saga_terminal_status
section .data
keys dq 11,101,22,202,33,303
section .bss
value resq 1
order resq 4
section .text
global _start
_start:
 mov edi,10
 mov esi,3
 mov edx,8
 lea rcx,[value]
 call nebo_retry_delay
 test eax,eax
 jnz fail
 cmp qword [value],80
 jne fail
 lea rdi,[keys]
 mov esi,3
 mov edx,22
 lea rcx,[value]
 call nebo_idempotency_lookup
 test eax,eax
 jnz fail
 cmp qword [value],202
 jne fail
 mov edi,4
 lea rsi,[order]
 mov edx,4
 call nebo_saga_compensation_order
 test eax,eax
 jnz fail
 cmp qword [order],3
 jne fail
 cmp qword [order+24],0
 jne fail
 xor edi,edi
 call nebo_saga_terminal_status
 cmp eax,NEBO_SAGA_COMPENSATED
 jne fail
 mov edi,1
 call nebo_saga_terminal_status
 cmp eax,NEBO_SAGA_STUCK
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
