; Public bounded reactive primitives shared by source programs and tools.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/public.inc"

section .text
NEBOC_ABI_FUNCTION nebo_signal_init
 test rdi,rdi
 jz .invalid
 mov [rdi+NEBO_SIGNAL_VALUE],rsi
 mov qword [rdi+NEBO_SIGNAL_VERSION],1
 mov qword [rdi+NEBO_SIGNAL_SUBSCRIBED],0
 mov qword [rdi+NEBO_SIGNAL_CANCELLED],0
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_signal_map_add
 ; source, destination, signed addend
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBO_SIGNAL_VALUE]
 add rax,rdx
 jo .overflow
 mov rdi,rsi
 mov rsi,rax
 jmp nebo_signal_init
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.overflow: mov eax,NEBO_REACTIVE_PUBLIC_OVERFLOW
 ret

NEBOC_ABI_FUNCTION nebo_signal_combine_add
 ; left, right, destination
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi+NEBO_SIGNAL_VALUE]
 add rax,[rsi+NEBO_SIGNAL_VALUE]
 jo .overflow
 mov rdi,rdx
 mov rsi,rax
 jmp nebo_signal_init
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.overflow: mov eax,NEBO_REACTIVE_PUBLIC_OVERFLOW
 ret

NEBOC_ABI_FUNCTION nebo_signal_distinct_set
 test rdi,rdi
 jz .invalid
 cmp [rdi+NEBO_SIGNAL_VALUE],rsi
 je .unchanged
 mov [rdi+NEBO_SIGNAL_VALUE],rsi
 inc qword [rdi+NEBO_SIGNAL_VERSION]
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.unchanged: mov eax,NEBO_REACTIVE_PUBLIC_UNCHANGED
 ret

NEBOC_ABI_FUNCTION nebo_signal_subscribe
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_SIGNAL_CANCELLED],0
 jne .invalid
 mov qword [rdi+NEBO_SIGNAL_SUBSCRIBED],1
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_signal_cancel
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBO_SIGNAL_SUBSCRIBED],0
 mov qword [rdi+NEBO_SIGNAL_CANCELLED],1
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_reactive_list_map_add
 ; input, count, output, addend
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBO_REACTIVE_PUBLIC_MAX_ITEMS
 ja .limit
 xor eax,eax
.loop:
 cmp rax,rsi
 jae .ok
 mov r8,[rdi+rax*8]
 add r8,rcx
 jo .overflow
 mov [rdx+rax*8],r8
 inc rax
 jmp .loop
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.limit: mov eax,NEBO_REACTIVE_PUBLIC_LIMIT
 ret
.overflow: mov eax,NEBO_REACTIVE_PUBLIC_OVERFLOW
 ret

NEBOC_ABI_FUNCTION nebo_reactive_list_filter_even
 ; input, count, output, output-count pointer
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBO_REACTIVE_PUBLIC_MAX_ITEMS
 ja .limit
 xor eax,eax
 xor r8d,r8d
.loop:
 cmp rax,rsi
 jae .done
 mov r9,[rdi+rax*8]
 test r9b,1
 jnz .next
 mov [rdx+r8*8],r9
 inc r8
.next: inc rax
 jmp .loop
.done:
 mov [rcx],r8
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.limit: mov eax,NEBO_REACTIVE_PUBLIC_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_reactive_list_sort_i64
 ; values, count -- stable insertion sort
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBO_REACTIVE_PUBLIC_MAX_ITEMS
 ja .limit
 mov r8,1
.outer:
 cmp r8,rsi
 jae .ok
 mov r9,[rdi+r8*8]
 mov r10,r8
.inner:
 test r10,r10
 jz .store
 mov r11,[rdi+r10*8-8]
 cmp r11,r9
 jle .store
 mov [rdi+r10*8],r11
 dec r10
 jmp .inner
.store:
 mov [rdi+r10*8],r9
 inc r8
 jmp .outer
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.limit: mov eax,NEBO_REACTIVE_PUBLIC_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_reactive_dict_init
 ; dictionary, keys, values, count, capacity
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp r8,NEBO_REACTIVE_PUBLIC_MAX_ITEMS
 ja .limit
 cmp rcx,r8
 ja .limit
 mov [rdi+NEBO_REACTIVE_DICT_KEYS],rsi
 mov [rdi+NEBO_REACTIVE_DICT_VALUES],rdx
 mov [rdi+NEBO_REACTIVE_DICT_COUNT],rcx
 mov [rdi+NEBO_REACTIVE_DICT_CAPACITY],r8
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.limit: mov eax,NEBO_REACTIVE_PUBLIC_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_signal_persist
 ; signal, store, stable key
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rsi+NEBO_REACTIVE_STORE_KEY],rdx
 mov rax,[rdi+NEBO_SIGNAL_VALUE]
 mov [rsi+NEBO_REACTIVE_STORE_VALUE],rax
 mov rax,[rdi+NEBO_SIGNAL_VERSION]
 mov [rsi+NEBO_REACTIVE_STORE_VERSION],rax
 mov qword [rsi+NEBO_REACTIVE_STORE_VALID],1
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_signal_restore
 ; signal, store, stable key
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBO_REACTIVE_STORE_VALID],1
 jne .missing
 cmp [rsi+NEBO_REACTIVE_STORE_KEY],rdx
 jne .missing
 mov rax,[rsi+NEBO_REACTIVE_STORE_VALUE]
 mov [rdi+NEBO_SIGNAL_VALUE],rax
 mov rax,[rsi+NEBO_REACTIVE_STORE_VERSION]
 mov [rdi+NEBO_SIGNAL_VERSION],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REACTIVE_PUBLIC_INVALID
 ret
.missing: mov eax,NEBO_REACTIVE_PUBLIC_MISSING
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
