bits 64
default rel
%include "runtime/eventsourcing/event_store.inc"
extern nebo_event_store_init,nebo_event_append,nebo_event_replay_sum
section .bss
store resb NEBO_STORE_SIZE
events resb nebo_event_store_EVENT_SIZE*4
state resq 1
section .text
global _start
_start:
 lea rdi,[store]
 lea rsi,[events]
 mov edx,4
 call nebo_event_store_init
 test eax,eax
 jnz fail
 lea rdi,[store]
 xor esi,esi
 mov edx,101
 mov ecx,5
 call nebo_event_append
 test eax,eax
 jnz fail
 lea rdi,[store]
 xor esi,esi
 mov edx,102
 mov ecx,7
 call nebo_event_append
 cmp eax,NEBO_EVENT_CONFLICT
 jne fail
 lea rdi,[store]
 mov esi,1
 mov edx,102
 mov ecx,7
 call nebo_event_append
 test eax,eax
 jnz fail
 lea rdi,[store]
 mov esi,2
 lea rdx,[state]
 call nebo_event_replay_sum
 test eax,eax
 jnz fail
 cmp qword [state],12
 jne fail
 lea rdi,[store]
 mov esi,2
 mov edx,101
 mov ecx,9
 call nebo_event_append
 cmp eax,NEBO_EVENT_DUPLICATE
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
