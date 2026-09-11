; Public Int sequential values: canonical List/Stack and circular ring owners.
; All descriptors and their bounded 16-element storage belong to caller frames.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_list_init
extern neboc_list_validate
extern neboc_list_reserve
extern neboc_list_growth_capacity
extern neboc_list_push
extern neboc_list_pop
extern neboc_list_at
extern neboc_list_get
extern neboc_list_insert
extern neboc_list_remove
extern neboc_list_swap_remove
extern neboc_list_clear
extern neboc_list_find
extern neboc_list_contains
extern neboc_list_map
extern neboc_list_filter
extern neboc_list_retain
extern neboc_list_stable_sort
extern neboc_list_deduplicate
extern neboc_stack_peek
extern neboc_ring_init
extern neboc_ring_validate
extern neboc_queue_enqueue
extern neboc_queue_dequeue
extern neboc_queue_front
extern neboc_deque_push_front
extern neboc_deque_push_back
extern neboc_deque_pop_front
extern neboc_deque_pop_back
extern neboc_ring_clear
extern neboc_iterator_init
extern neboc_iterator_next
extern neboc_iterator_take
extern neboc_iterator_skip
extern neboc_iterator_release
extern neboc_iterator_collect_list
extern neboc_iterator_enumerate
extern neboc_iterator_next_enumerated
extern nebo_runtime_trap
section .text
NEBOC_ABI_FUNCTION nebo_sequential_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,140
 jae .iterator
 cmp ebx,105
 jbe .constructor
 mov rdi,r12
 cmp ebx,132
 jae .list
 cmp ebx,122
 jb .list
 call neboc_ring_validate
 test eax,eax
 jnz .trap
 cmp ebx,130
 je .length
 cmp ebx,131
 je .ring_clear
 cmp ebx,122
 je .enqueue
 cmp ebx,123
 je .dequeue
 cmp ebx,124
 je .queue_peek
 cmp ebx,125
 je .push_front
 cmp ebx,126
 je .push_back
 cmp ebx,127
 je .pop_front
 cmp ebx,128
 je .pop_back
 jmp .trap
.list:
 call neboc_list_validate
 test eax,eax
 jnz .trap
 cmp ebx,110
 je .length
 cmp ebx,111
 je .capacity
 cmp ebx,112
 je .reserve
 cmp ebx,113
 je .push
 cmp ebx,114
 je .pop
 cmp ebx,115
 je .peek
 cmp ebx,116
 je .at
 cmp ebx,117
 je .get
 cmp ebx,118
 je .insert
 cmp ebx,119
 je .remove
 cmp ebx,120
 je .swap_remove
 cmp ebx,121
 je .clear
 cmp ebx,132
 je .contains
 cmp ebx,134
 je .find
 cmp ebx,135
 je .map_or_filter
 cmp ebx,136
 je .map_or_filter
 cmp ebx,137
 je .retain
 cmp ebx,138
 je .sort
 cmp ebx,139
 je .deduplicate
 jmp .trap
.clear:
 mov rdi,r12
 call neboc_list_clear
 jmp .void_status
.iterator:
 cmp ebx,143
 jbe .iterator_new
 cmp ebx,152
 je .iterator_auto_release
 cmp qword [r12+48],0
 jne .trap
 cmp ebx,144
 je .iterator_next
 cmp ebx,145
 je .iterator_enumerate
 cmp ebx,150
 je .iterator_next_enumerated
 cmp ebx,146
 je .iterator_take
 cmp ebx,147
 je .iterator_skip
 cmp ebx,149
 je .iterator_release
 cmp ebx,148
 je .iterator_collect
 jmp .trap
.iterator_new:
 mov rdi,r12
 mov rsi,r15
 mov edx,NEBOC_ITER_KIND_LIST
 cmp ebx,142
 jb .iterator_init
 mov edx,NEBOC_ITER_KIND_RING
.iterator_init:
 call neboc_iterator_init
 test eax,eax
 jnz .trap
 mov qword [r15+48],0
 mov qword [r15+56],0
 mov rax,r15
 jmp .done
.iterator_next:
 cmp qword [r12+56],0
 jne .trap
 mov qword [r15+8],0
 mov rdi,r12
 lea rsi,[r15+8]
 mov rdx,r15
 call neboc_iterator_next
 jmp .constructor_status
.iterator_enumerate:
 mov rdi,r12
 call neboc_iterator_enumerate
 test eax,eax
 jnz .trap
 mov qword [r12+56],1
 jmp .void_ok
.iterator_next_enumerated:
 cmp qword [r12+56],1
 jne .trap
 mov qword [r15+8],0
 mov qword [r15+16],0
 mov rdi,r12
 lea rsi,[r15+8]
 lea rdx,[r15+16]
 mov rcx,r15
 call neboc_iterator_next_enumerated
 jmp .constructor_status
.iterator_take:
 test r13,r13
 js .trap
 mov rdi,r12
 mov rsi,r13
 call neboc_iterator_take
 jmp .void_status
.iterator_skip:
 test r13,r13
 js .trap
 mov rdi,r12
 mov rsi,r13
 call neboc_iterator_skip
 jmp .void_status
.iterator_auto_release:
 cmp qword [r12+48],1
 je .void_ok
.iterator_release:
 mov rdi,r12
 call neboc_iterator_release
 test eax,eax
 jnz .trap
 mov qword [r12+48],1
 jmp .void_ok
.iterator_collect:
 mov rdi,r15
 lea rsi,[r15+80]
 mov edx,16
 mov rax,[r12+NEBOC_ITER_OWNER_OFFSET]
 mov rcx,[r12+NEBOC_ITER_TOKEN_OFFSET]
 and ecx,NEBOC_ITER_KIND_MASK
 cmp ecx,NEBOC_ITER_KIND_LIST
 jne .iterator_capacity_ready
 cmp qword [rax+NEBOC_LIST_CAPACITY_OFFSET],rdx
 cmova rdx,[rax+NEBOC_LIST_CAPACITY_OFFSET]
.iterator_capacity_ready:
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov rsi,r15
 call neboc_iterator_collect_list
 jmp .constructor_status
.contains:
 mov [rsp],r13
 mov qword [r15],-1
 mov rdi,r12
 mov rsi,rsp
 lea rdx,[rel .equal_int]
 mov rcx,r15
 call neboc_list_contains
 ; This native facade returns the Bool as well as writing it, unlike the
 ; Status-returning mutation entry points. Authenticate both representations.
 cmp qword [r15],1
 ja .trap
 cmp rax,[r15]
 jne .trap
 mov rax,[r15]
 jmp .done
.find:
 mov rdi,r12
 mov rsi,rsp ; required nonnull needle; predicate bridge ignores it
 mov rdx,r13
 mov rcx,r15
 lea r8,[r15+8]
 call neboc_list_find
 test eax,eax
 jnz .trap
 jmp .option_from_native
.map_or_filter:
 mov rdi,r15
 lea rsi,[r15+80]
 mov edx,16
 cmp [r12+NEBOC_LIST_CAPACITY_OFFSET],rdx
 cmova rdx,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov rsi,r15
 mov rdx,r13
 cmp ebx,135
 jne .filter
 call neboc_list_map
 jmp .constructor_status
.filter:
 call neboc_list_filter
 jmp .constructor_status
.retain:
 mov rdi,r12
 mov rsi,r13
 call neboc_list_retain
 jmp .void_status
.sort:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 mov ecx,512
 call neboc_list_stable_sort
 jmp .void_status
.deduplicate:
 mov rdi,r12
 lea rsi,[rel .equal_int]
 call neboc_list_deduplicate
 jmp .void_status
.equal_int:
 mov rax,[rdi]
 cmp rax,[rsi]
 sete al
 movzx eax,al
 mov [rdx],rax
 xor eax,eax
 ret
.constructor:
 cmp ebx,100
 jb .trap
 cmp ebx,104
 jne .constructor_valid
 cmp r13,16
 ja .trap
.constructor_valid:
 mov rdi,r15
 mov ecx,40
 xor eax,eax
 rep stosq
 mov rdi,r15
 lea rsi,[r15+80]
 cmp ebx,102
 je .ring_constructor
 cmp ebx,103
 je .ring_constructor
 xor edx,edx
 cmp ebx,104
 jne .list_constructor
 mov rdx,r13
.list_constructor:
 mov ecx,8
 mov r8d,8
 mov r9d,1 ; caller-owned allocator identity; no allocation is performed
 call neboc_list_init
 jmp .constructor_status
.ring_constructor:
 mov edx,16
 mov ecx,8
 mov r8d,1
 lea r9d,[ebx-101]
 call neboc_ring_init
.constructor_status:
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.length:
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jmp .done
.capacity:
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jmp .done
.reserve:
 test r13,r13
 js .trap
 add r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jc .trap
 cmp r13,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jbe .void_ok
 cmp r13,16
 ja .trap
 mov rdi,r12
 lea rsi,[r12+80]
 mov rdx,r13
 call neboc_list_reserve
 jmp .void_status
.push:
 call .grow
 mov [rsp],r13
 mov rdi,r12
 lea rsi,[rsp]
 call neboc_list_push
 jmp .void_status
.insert:
 cmp r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 ja .trap
 call .grow
 mov [rsp],r14
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_list_insert
 jmp .void_status
.grow:
 ; This call preserves both input values and the caller's receiver/result.
 sub rsp,8
 mov rsi,[r12+NEBOC_LIST_LENGTH_OFFSET]
 inc rsi
 cmp rsi,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jbe .grown
 cmp rsi,16
 ja .trap
 mov rax,NEBOC_LIST_GENERATION_MASK-2
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rax
 ja .trap
 mov rdi,r12
 mov rdx,rsp
 call neboc_list_growth_capacity
 test eax,eax
 jnz .trap
 mov rdx,[rsp]
 cmp rdx,16
 ja .trap
 mov rdi,r12
 lea rsi,[r12+80]
 call neboc_list_reserve
 test eax,eax
 jnz .trap
.grown:
 add rsp,8
 ret
.get:
 mov qword [r15+8],0
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r15+8]
 mov rcx,r15
 call neboc_list_get
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.at:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 call neboc_list_at
 test eax,eax
 jnz .trap
 mov rax,[r15]
 jmp .done
.remove:
 lea r11,[rel neboc_list_remove]
 jmp .indexed_take
.swap_remove:
 lea r11,[rel neboc_list_swap_remove]
.indexed_take:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 lea rcx,[r15+8]
 call r11
 jmp .found_status
.pop:
 lea r11,[rel neboc_list_pop]
 jmp .take
.peek:
 lea r11,[rel neboc_stack_peek]
 jmp .take
.enqueue:
 lea r11,[rel neboc_queue_enqueue]
 jmp .put
.push_front:
 lea r11,[rel neboc_deque_push_front]
 jmp .put
.push_back:
 lea r11,[rel neboc_deque_push_back]
.put:
 mov [rsp],r13
 mov rdi,r12
 lea rsi,[rsp]
 call r11
 jmp .void_status
.dequeue:
 lea r11,[rel neboc_queue_dequeue]
 jmp .take
.queue_peek:
 lea r11,[rel neboc_queue_front]
 jmp .take
.pop_front:
 lea r11,[rel neboc_deque_pop_front]
 jmp .take
.pop_back:
 lea r11,[rel neboc_deque_pop_back]
.take:
 mov qword [r15],0
 mov qword [r15+8],0
 mov rdi,r12
 mov rsi,r15
 lea rdx,[r15+8]
 call r11
.found_status:
 test eax,eax
 jnz .trap
 cmp ebx,114
 je .option_from_native
 cmp ebx,123
 je .option_from_native
 cmp qword [r15+8],1
 jne .trap
 mov rax,[r15]
 jmp .done
.option_from_native:
 mov rax,[r15]
 mov rdx,[r15+8]
 mov [r15],rdx
 mov [r15+8],rax
 mov rax,r15
 jmp .done
.ring_clear:
 mov rdi,r12
 call neboc_ring_clear
.void_status:
 test eax,eax
 jnz .trap
.void_ok:
 xor eax,eax
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 mov edi,49
 call nebo_runtime_trap
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
