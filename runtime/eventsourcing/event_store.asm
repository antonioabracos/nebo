; GPU-E-COMPUTACAO-ACELERADA-F01 bounded append-only event store, expected version, replay.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/eventsourcing/event_store.inc"
section .text
NEBOC_ABI_FUNCTION nebo_event_store_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBO_EVENT_MAX
 ja .limit
 mov [rdi+NEBO_STORE_EVENTS],rsi
 mov [rdi+NEBO_STORE_CAPACITY],rdx
 mov qword [rdi+NEBO_STORE_COUNT],0
 xor eax,eax
 ret
.invalid: mov eax,NEBO_EVENT_INVALID
 ret
.limit: mov eax,NEBO_EVENT_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_event_append
 ; store,expected_version,event_id,value
 test rdi,rdi
 jz .invalid
 mov r8,[rdi+NEBO_STORE_COUNT]
 cmp rsi,r8
 jne .conflict
 cmp r8,[rdi+NEBO_STORE_CAPACITY]
 jae .limit
 mov r9,[rdi+NEBO_STORE_EVENTS]
 xor eax,eax
.scan:
 cmp rax,r8
 jae .write
 mov r10,rax
 shl r10,4
 cmp [r9+r10+NEBO_EVENT_ID],rdx
 je .duplicate
 inc rax
 jmp .scan
.write:
 mov r10,r8
 shl r10,4
 mov [r9+r10+NEBO_EVENT_ID],rdx
 mov [r9+r10+nebo_event_store_EVENT_VALUE],rcx
 inc r8
 mov [rdi+NEBO_STORE_COUNT],r8
 xor eax,eax
 ret
.invalid: mov eax,NEBO_EVENT_INVALID
 ret
.conflict: mov eax,NEBO_EVENT_CONFLICT
 ret
.limit: mov eax,NEBO_EVENT_LIMIT
 ret
.duplicate: mov eax,NEBO_EVENT_DUPLICATE
 ret

NEBOC_ABI_FUNCTION nebo_event_replay_sum
 ; store,prefix,out
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,[rdi+NEBO_STORE_COUNT]
 ja .limit
 mov r8,[rdi+NEBO_STORE_EVENTS]
 xor eax,eax
 xor ecx,ecx
.loop:
 cmp rax,rsi
 jae .done
 mov r9,rax
 shl r9,4
 add rcx,[r8+r9+nebo_event_store_EVENT_VALUE]
 inc rax
 jmp .loop
.done:
 mov [rdx],rcx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_EVENT_INVALID
 ret
.limit: mov eax,NEBO_EVENT_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
