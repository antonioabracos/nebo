; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-F05 bounded circular Queue/Deque.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/ring_core.inc"
section .text
; ring_init(desc*, storage*, capacity, element_size, allocator, kind)
NEBOC_ABI_FUNCTION neboc_ring_init
 test rdi,rdi
 jz .init_invalid
 test rdi,7
 jnz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 cmp rdx,NEBOC_LIST_MAX_ELEMENTS
 ja .init_limit
 test rcx,rcx
 jz .init_invalid
 cmp rcx,NEBOC_LIST_MAX_ELEMENT_SIZE
 ja .init_limit
 mov rax,rcx
 imul rax,rdx
 jo .init_limit
 cmp rax,NEBOC_LIST_MAX_BYTES
 ja .init_limit
 test r8,r8
 jz .init_invalid
 cmp r9,NEBOC_RING_KIND_QUEUE
 je .queue
 cmp r9,NEBOC_RING_KIND_DEQUE
 jne .init_invalid
 mov r10,NEBOC_RING_DEQUE_MAGIC
 jmp .kind_ok
.queue:
 mov r10,NEBOC_RING_QUEUE_MAGIC
.kind_ok:
 mov r11,rdi
 push rsi
 push rdx
 push rcx
 push r8
 mov ecx,NEBOC_RING_QWORDS
 xor eax,eax
 rep stosq
 pop r8
 pop rcx
 pop rdx
 pop rsi
 mov [r11+NEBOC_LIST_DATA_OFFSET],rsi
 mov [r11+NEBOC_LIST_CAPACITY_OFFSET],rdx
 mov [r11+NEBOC_LIST_ELEMENT_SIZE_OFFSET],rcx
 mov qword [r11+NEBOC_LIST_ELEMENT_ALIGN_OFFSET],8
 mov qword [r11+NEBOC_LIST_GENERATION_OFFSET],1
 mov [r11+NEBOC_LIST_ALLOCATOR_OFFSET],r8
 mov [r11+NEBOC_LIST_FLAGS_OFFSET],r10
 xor eax,eax
 ret
.init_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ring_validate
 test rdi,rdi
 jz .validate_invalid
 mov rax,[rdi+NEBOC_LIST_FLAGS_OFFSET]
 mov rcx,NEBOC_RING_QUEUE_MAGIC
 cmp rax,rcx
 je .magic_ok
 mov rcx,NEBOC_RING_DEQUE_MAGIC
 cmp rax,rcx
 jne .validate_source
.magic_ok:
 mov rcx,[rdi+NEBOC_LIST_CAPACITY_OFFSET]
 test rcx,rcx
 jz .validate_source
 cmp rcx,NEBOC_LIST_MAX_ELEMENTS
 ja .validate_source
 cmp [rdi+NEBOC_LIST_LENGTH_OFFSET],rcx
 ja .validate_source
 cmp [rdi+NEBOC_RING_HEAD_OFFSET],rcx
 jae .validate_source
 cmp [rdi+NEBOC_RING_TAIL_OFFSET],rcx
 jae .validate_source
 cmp qword [rdi+NEBOC_LIST_DATA_OFFSET],0
 je .validate_source
 cmp qword [rdi+NEBOC_LIST_ELEMENT_SIZE_OFFSET],0
 je .validate_source
 xor eax,eax
 ret
.validate_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.validate_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; push_back(desc*, value*)
NEBOC_ABI_FUNCTION neboc_ring_push_back
 test rsi,rsi
 jz .pb_invalid
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call neboc_ring_validate
 test eax,eax
 jnz .pb_done
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .pb_full
 mov rax,[r12+NEBOC_RING_TAIL_OFFSET]
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov rax,[r12+NEBOC_RING_TAIL_OFFSET]
 inc rax
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jb .pb_tail
 xor eax,eax
.pb_tail:
 mov [r12+NEBOC_RING_TAIL_OFFSET],rax
 inc qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 xor eax,eax
 jmp .pb_done
.pb_full:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.pb_done:
 pop r13
 pop r12
 ret
.pb_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; push_front(desc*, value*) -- Deque only.
NEBOC_ABI_FUNCTION neboc_ring_push_front
 test rsi,rsi
 jz .pf_invalid
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call neboc_ring_validate
 test eax,eax
 jnz .pf_done
 mov rax,NEBOC_RING_DEQUE_MAGIC
 cmp [r12+NEBOC_LIST_FLAGS_OFFSET],rax
 jne .pf_invalid_source
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .pf_full
 mov rax,[r12+NEBOC_RING_HEAD_OFFSET]
 test rax,rax
 jnz .pf_dec
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
.pf_dec:
 dec rax
 mov [r12+NEBOC_RING_HEAD_OFFSET],rax
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 inc qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 xor eax,eax
 jmp .pf_done
.pf_full:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .pf_done
.pf_invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.pf_done:
 pop r13
 pop r12
 ret
.pf_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; pop_front(desc*, out*, found*)
NEBOC_ABI_FUNCTION neboc_ring_pop_front
 test rsi,rsi
 jz .popf_invalid
 test rdx,rdx
 jz .popf_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_ring_validate
 test eax,eax
 jnz .popf_done
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 je .popf_ok
 mov rax,[r12+NEBOC_RING_HEAD_OFFSET]
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 push rcx
 push rsi
 rep movsb
 pop rdi
 pop rcx
 xor eax,eax
 rep stosb
 mov rax,[r12+NEBOC_RING_HEAD_OFFSET]
 inc rax
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jb .popf_head
 xor eax,eax
.popf_head:
 mov [r12+NEBOC_RING_HEAD_OFFSET],rax
 dec qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 mov qword [r14],1
.popf_ok:
 xor eax,eax
.popf_done:
 pop r14
 pop r13
 pop r12
 ret
.popf_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; pop_back(desc*, out*, found*) -- Deque only.
NEBOC_ABI_FUNCTION neboc_ring_pop_back
 test rsi,rsi
 jz .popb_invalid
 test rdx,rdx
 jz .popb_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_ring_validate
 test eax,eax
 jnz .popb_done
 mov rax,NEBOC_RING_DEQUE_MAGIC
 cmp [r12+NEBOC_LIST_FLAGS_OFFSET],rax
 jne .popb_source
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 je .popb_ok
 mov rax,[r12+NEBOC_RING_TAIL_OFFSET]
 test rax,rax
 jnz .popb_dec
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
.popb_dec:
 dec rax
 mov [r12+NEBOC_RING_TAIL_OFFSET],rax
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 push rcx
 push rsi
 rep movsb
 pop rdi
 pop rcx
 xor eax,eax
 rep stosb
 dec qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 mov qword [r14],1
.popb_ok:
 xor eax,eax
 jmp .popb_done
.popb_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.popb_done:
 pop r14
 pop r13
 pop r12
 ret
.popb_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; peek_front/back share checked logical endpoints without mutation.
NEBOC_ABI_FUNCTION neboc_ring_peek_front
 xor ecx,ecx
 jmp ring_peek
NEBOC_ABI_FUNCTION neboc_ring_peek_back
 mov ecx,1
ring_peek:
 test rsi,rsi
 jz .peek_invalid
 test rdx,rdx
 jz .peek_invalid
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 call neboc_ring_validate
 test eax,eax
 jnz .peek_done
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 je .peek_ok
 test r15,r15
 jz .peek_front_index
 mov rax,[r12+NEBOC_RING_TAIL_OFFSET]
 test rax,rax
 jnz .peek_back_dec
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
.peek_back_dec:
 dec rax
 jmp .peek_copy
.peek_front_index:
 mov rax,[r12+NEBOC_RING_HEAD_OFFSET]
.peek_copy:
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov qword [r14],1
.peek_ok:
 xor eax,eax
.peek_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.peek_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ring_clear
 push r12
 mov r12,rdi
 call neboc_ring_validate
 test eax,eax
 jnz .clear_done
 mov rcx,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 xor eax,eax
 rep stosb
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 je .clear_reset
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
.clear_reset:
 mov qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 mov qword [r12+NEBOC_RING_HEAD_OFFSET],0
 mov qword [r12+NEBOC_RING_TAIL_OFFSET],0
 xor eax,eax
.clear_done:
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
