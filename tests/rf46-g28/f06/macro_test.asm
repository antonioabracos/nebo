bits 64
default rel
%include "compiler/meta/code_model.inc"
%include "compiler/meta/macro.inc"
extern nebo_macro_invocation_validate,nebo_macro_trace_init,nebo_macro_trace_append
section .bss
state resb NEBO_MACRO_STATE_SIZE
entries resb NEBO_MACRO_TRACE_SIZE*2
trace resb NEBO_MACRO_TRACE_SIZE
section .text
global _start
_start:
 mov edi,2
 mov esi,NEBO_META_KIND_EXPRESSION
 mov edx,1
 mov r8d,NEBO_META_KIND_EXPRESSION
 mov r9d,1
 call nebo_macro_invocation_validate
 test eax,eax
 jnz fail
 lea rdi,[state]
 lea rsi,[entries]
 mov edx,2
 call nebo_macro_trace_init
 test eax,eax
 jnz fail
 mov qword [trace+NEBO_MACRO_TRACE_MACRO_ID],7
 mov qword [trace+NEBO_MACRO_TRACE_CALL_SPAN],11
 mov qword [trace+NEBO_MACRO_TRACE_OUTPUT_SPAN],12
 mov qword [trace+NEBO_MACRO_TRACE_DEPTH],2
 mov qword [trace+NEBO_MACRO_TRACE_NODES],10
 mov qword [trace+NEBO_MACRO_TRACE_BYTES],80
 lea rdi,[state]
 lea rsi,[trace]
 call nebo_macro_trace_append
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_MACRO_STATE_COUNT],1
 jne fail
 mov qword [trace+NEBO_MACRO_TRACE_DEPTH],33
 lea rdi,[state]
 lea rsi,[trace]
 call nebo_macro_trace_append
 cmp eax,NEBO_MACRO_STATUS_DEPTH
 jne fail
 cmp qword [state+NEBO_MACRO_STATE_COUNT],1
 jne fail
 mov edi,17
 mov esi,1
 mov edx,1
 mov r8d,1
 mov r9d,1
 call nebo_macro_invocation_validate
 cmp eax,NEBO_MACRO_STATUS_ARITY
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
