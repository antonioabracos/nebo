bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
%include "compiler/semantic/collections/public_slice.inc"
section .text
; iterator_init(owner*, iterator*, kind)
NEBOC_ABI_FUNCTION neboc_iterator_init
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 cmp rdx,NEBOC_ITER_KIND_LIST
 jb .init_invalid
 cmp rdx,NEBOC_ITER_KIND_SLICE
 ja .init_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r13
 mov ecx,NEBOC_ITER_QWORDS
 xor eax,eax
 rep stosq
 mov [r13+NEBOC_ITER_OWNER_OFFSET],r12
 mov rax,r12
 or rax,r14
 mov [r13+NEBOC_ITER_TOKEN_OFFSET],rax
 cmp r14,NEBOC_ITER_KIND_SLICE
 je .slice
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 mov [r13+NEBOC_ITER_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov [r13+NEBOC_ITER_STRIDE_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_GENERATION_OFFSET]
 mov [r13+NEBOC_ITER_GENERATION_OFFSET],rax
 jmp .init_ok
.slice:
 mov rax,[r12+8]
 mov [r13+NEBOC_ITER_LENGTH_OFFSET],rax
 mov rax,[r12+16]
 mov [r13+NEBOC_ITER_STRIDE_OFFSET],rax
 mov rax,[r12+32]
 mov [r13+NEBOC_ITER_GENERATION_OFFSET],rax
.init_ok:
 xor eax,eax
 pop r14
 pop r13
 pop r12
 ret
.init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
; next(iterator*, out*, found*)
NEBOC_ABI_FUNCTION neboc_iterator_next
 test rdi,rdi
 jz .next_invalid
 test rsi,rsi
 jz .next_invalid
 test rdx,rdx
 jz .next_invalid
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 mov rbx,[r12+NEBOC_ITER_TOKEN_OFFSET]
 test rbx,rbx
 jz .next_stale
 mov rdx,rbx
 and edx,NEBOC_ITER_KIND_MASK
 and rbx,-8
 cmp rbx,[r12+NEBOC_ITER_OWNER_OFFSET]
 jne .next_stale
 cmp rdx,NEBOC_ITER_KIND_SLICE
 je .next_slice_generation
 mov rax,[rbx+NEBOC_LIST_GENERATION_OFFSET]
 jmp .next_generation
.next_slice_generation:
 mov rax,[rbx+32]
.next_generation:
 cmp rax,[r12+NEBOC_ITER_GENERATION_OFFSET]
 jne .next_stale
 mov rcx,[r12+NEBOC_ITER_INDEX_OFFSET]
 cmp rcx,[r12+NEBOC_ITER_LENGTH_OFFSET]
 jae .next_end
 cmp rdx,NEBOC_ITER_KIND_LIST
 je .next_list
 cmp rdx,NEBOC_ITER_KIND_RING
 je .next_ring
 mov rsi,[rbx]
 mov rax,rcx
 imul rax,[r12+NEBOC_ITER_STRIDE_OFFSET]
 add rsi,rax
 jmp .next_copy
.next_list:
 mov rsi,[rbx+NEBOC_LIST_DATA_OFFSET]
 mov rax,rcx
 imul rax,[r12+NEBOC_ITER_STRIDE_OFFSET]
 add rsi,rax
 jmp .next_copy
.next_ring:
 add rcx,[rbx+NEBOC_RING_HEAD_OFFSET]
 cmp rcx,[rbx+NEBOC_LIST_CAPACITY_OFFSET]
 jb .ring_index
 sub rcx,[rbx+NEBOC_LIST_CAPACITY_OFFSET]
.ring_index:
 mov rsi,[rbx+NEBOC_LIST_DATA_OFFSET]
 imul rcx,[r12+NEBOC_ITER_STRIDE_OFFSET]
 add rsi,rcx
.next_copy:
 mov rdi,r13
 mov rcx,[r12+NEBOC_ITER_STRIDE_OFFSET]
 rep movsb
 inc qword [r12+NEBOC_ITER_INDEX_OFFSET]
 mov qword [r14],1
.next_end:
 xor eax,eax
 jmp .next_done
.next_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.next_done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.next_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_iterator_release
 test rdi,rdi
 jz .release_invalid
 mov qword [rdi+NEBOC_ITER_TOKEN_OFFSET],0
 xor eax,eax
 ret
.release_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
; mutation_gate(owner*, iterator*) rejects a still-live iterator over owner.
NEBOC_ABI_FUNCTION neboc_iterator_mutation_gate
 test rdi,rdi
 jz .gate_invalid
 test rsi,rsi
 jz .gate_invalid
 cmp qword [rsi+NEBOC_ITER_TOKEN_OFFSET],0
 je .gate_ok
 cmp rdi,[rsi+NEBOC_ITER_OWNER_OFFSET]
 jne .gate_ok
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.gate_ok:
 xor eax,eax
 ret
.gate_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
