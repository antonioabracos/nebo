; MEDIA-IMAGEM-AUDIO-E-VIDEO-F05 bounded local stream with backpressure and cancellation.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/stream.inc"
section .text
NEBOC_ABI_FUNCTION nebo_stream_init
 test rdi,rdi
 jz .invalid_init
 mov qword [rdi+nebo_stream_STREAM_BUFFER],0
 mov qword [rdi+nebo_stream_STREAM_CAPACITY],0
 mov qword [rdi+nebo_stream_STREAM_HEAD],0
 mov qword [rdi+nebo_stream_STREAM_TAIL],0
 mov qword [rdi+nebo_stream_STREAM_COUNT],0
 mov qword [rdi+nebo_stream_STREAM_CANCELLED],0
 mov qword [rdi+NEBO_STREAM_DROPPED],0
 test rsi,rsi
 jz .invalid_init
 test rdx,rdx
 jz .invalid_init
 cmp rdx,nebo_stream_STREAM_MAX_CAPACITY
 ja .limit_init
 cmp rcx,NEBO_STREAM_POLICY_REJECT
 je .policy_ok
 cmp rcx,NEBO_STREAM_POLICY_DROP_OLDEST
 jne .invalid_init
.policy_ok:
 mov [rdi+nebo_stream_STREAM_BUFFER],rsi
 mov [rdi+nebo_stream_STREAM_CAPACITY],rdx
 mov [rdi+NEBO_STREAM_POLICY],rcx
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_STREAM_STATUS_INVALID
 ret
.limit_init: mov eax,NEBO_STREAM_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_stream_push
 test rdi,rdi
 jz .invalid_push
 cmp qword [rdi+nebo_stream_STREAM_CANCELLED],0
 jne .cancelled_push
 mov rcx,[rdi+nebo_stream_STREAM_COUNT]
 cmp rcx,[rdi+nebo_stream_STREAM_CAPACITY]
 jb .store
 cmp qword [rdi+NEBO_STREAM_POLICY],NEBO_STREAM_POLICY_DROP_OLDEST
 jne .backpressure
 mov rax,[rdi+nebo_stream_STREAM_HEAD]
 inc rax
 xor edx,edx
 div qword [rdi+nebo_stream_STREAM_CAPACITY]
 mov [rdi+nebo_stream_STREAM_HEAD],rdx
 dec rcx
 inc qword [rdi+NEBO_STREAM_DROPPED]
.store:
 mov rax,[rdi+nebo_stream_STREAM_TAIL]
 mov r8,[rdi+nebo_stream_STREAM_BUFFER]
 mov [r8+rax*8],rsi
 inc rax
 xor edx,edx
 div qword [rdi+nebo_stream_STREAM_CAPACITY]
 mov [rdi+nebo_stream_STREAM_TAIL],rdx
 inc rcx
 mov [rdi+nebo_stream_STREAM_COUNT],rcx
 xor eax,eax
 ret
.invalid_push: mov eax,NEBO_STREAM_STATUS_INVALID
 ret
.cancelled_push: mov eax,NEBO_STREAM_STATUS_CANCELLED
 ret
.backpressure: mov eax,NEBO_STREAM_STATUS_BACKPRESSURE
 ret

NEBOC_ABI_FUNCTION nebo_stream_pop
 test rsi,rsi
 jz .invalid_pop
 mov qword [rsi],0
 test rdi,rdi
 jz .invalid_pop
 cmp qword [rdi+nebo_stream_STREAM_COUNT],0
 je .empty_pop
 mov rax,[rdi+nebo_stream_STREAM_HEAD]
 mov rcx,[rdi+nebo_stream_STREAM_BUFFER]
 mov r8,[rcx+rax*8]
 mov [rsi],r8
 inc rax
 xor edx,edx
 div qword [rdi+nebo_stream_STREAM_CAPACITY]
 mov [rdi+nebo_stream_STREAM_HEAD],rdx
 dec qword [rdi+nebo_stream_STREAM_COUNT]
 xor eax,eax
 ret
.invalid_pop: mov eax,NEBO_STREAM_STATUS_INVALID
 ret
.empty_pop: mov eax,NEBO_STREAM_STATUS_EMPTY
 ret

NEBOC_ABI_FUNCTION nebo_stream_cancel
 test rdi,rdi
 jz .invalid_cancel
 mov qword [rdi+nebo_stream_STREAM_CANCELLED],1
 xor eax,eax
 ret
.invalid_cancel: mov eax,NEBO_STREAM_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_stream_reduce_sum
 ; non-consuming snapshot reduction
 test rsi,rsi
 jz .invalid_reduce
 mov qword [rsi],0
 test rdi,rdi
 jz .invalid_reduce
 mov rcx,[rdi+nebo_stream_STREAM_COUNT]
 mov r8,[rdi+nebo_stream_STREAM_HEAD]
 mov r9,[rdi+nebo_stream_STREAM_BUFFER]
 xor eax,eax
 xor r10d,r10d
.reduce_loop:
 cmp rax,rcx
 jae .reduce_done
 add r10,[r9+r8*8]
 jo .overflow_reduce
 inc r8
 xor edx,edx
 mov r11,r8
 mov rax,r11
 div qword [rdi+nebo_stream_STREAM_CAPACITY]
 mov r8,rdx
 ; restore processed count from output scratch
 mov rax,[rsi]
 inc rax
 mov [rsi],rax
 jmp .reduce_loop
.reduce_done: mov [rsi],r10
 xor eax,eax
 ret
.invalid_reduce: mov eax,NEBO_STREAM_STATUS_INVALID
 ret
.overflow_reduce: mov qword [rsi],0
 mov eax,NEBO_STREAM_STATUS_OVERFLOW
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
