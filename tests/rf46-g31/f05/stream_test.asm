bits 64
default rel
%include "runtime/reactive/stream.inc"
extern nebo_stream_init,nebo_stream_push,nebo_stream_pop,nebo_stream_cancel,nebo_stream_reduce_sum
section .bss
stream resb nebo_stream_STREAM_SIZE
buffer resq 3
value resq 1
section .text
global _start
_start:
 lea rdi,[stream]
 lea rsi,[buffer]
 mov edx,3
 mov ecx,NEBO_STREAM_POLICY_DROP_OLDEST
 call nebo_stream_init
 test eax,eax
 jnz fail
 lea rdi,[stream]
 mov esi,1
 call nebo_stream_push
 lea rdi,[stream]
 mov esi,2
 call nebo_stream_push
 lea rdi,[stream]
 mov esi,3
 call nebo_stream_push
 lea rdi,[stream]
 mov esi,4
 call nebo_stream_push
 test eax,eax
 jnz fail
 cmp qword [stream+NEBO_STREAM_DROPPED],1
 jne fail
 lea rdi,[stream]
 lea rsi,[value]
 call nebo_stream_reduce_sum
 test eax,eax
 jnz fail
 cmp qword [value],9
 jne fail
 lea rdi,[stream]
 lea rsi,[value]
 call nebo_stream_pop
 test eax,eax
 jnz fail
 cmp qword [value],2
 jne fail
 lea rdi,[stream]
 call nebo_stream_cancel
 test eax,eax
 jnz fail
 lea rdi,[stream]
 mov esi,5
 call nebo_stream_push
 cmp eax,NEBO_STREAM_STATUS_CANCELLED
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
