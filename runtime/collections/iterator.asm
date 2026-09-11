bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
%include "compiler/semantic/collections/public_slice.inc"
extern neboc_list_validate
extern neboc_ring_validate
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
 cmp r14,NEBOC_ITER_KIND_LIST
 jne .init_ring
 mov rdi,r12
 call neboc_list_validate
 test eax,eax
 jnz .init_done
 jmp .init_owner
.init_ring:
 cmp r14,NEBOC_ITER_KIND_RING
 jne .init_slice_validate
 mov rdi,r12
 call neboc_ring_validate
 test eax,eax
 jnz .init_done
.init_owner:
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .init_borrowed
 mov rax,NEBOC_LIST_BORROW_BIT
 or [r12+NEBOC_LIST_GENERATION_OFFSET],rax
 jmp .init_materialize
.init_slice_validate:
 test r12,7
 jnz .init_invalid_saved
 cmp qword [r12+8],NEBOC_LIST_MAX_ELEMENTS
 ja .init_source
 cmp qword [r12+16],0
 je .init_source
 cmp qword [r12+16],NEBOC_LIST_MAX_ELEMENT_SIZE
 ja .init_source
 cmp qword [r12+8],0
 je .init_slice_generation
 cmp qword [r12],0
 je .init_source
.init_slice_generation:
 cmp qword [r12+32],0
 je .init_source
.init_materialize:
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
.init_done:
 pop r14
 pop r13
 pop r12
 ret
.init_borrowed:
.init_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .init_done
.init_invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .init_done
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
 cmp rdx,NEBOC_ITER_KIND_LIST
 jb .next_stale
 cmp rdx,NEBOC_ITER_KIND_SLICE
 ja .next_stale
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

; size_hint(iterator*, out_remaining*) authenticates before publishing output.
NEBOC_ABI_FUNCTION neboc_iterator_size_hint
 test rdi,rdi
 jz .hint_invalid
 test rsi,rsi
 jz .hint_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_ITER_TOKEN_OFFSET]
 test r14,r14
 jz .hint_stale
 mov rdx,r14
 and edx,NEBOC_ITER_KIND_MASK
 and r14,-8
 cmp r14,[r12+NEBOC_ITER_OWNER_OFFSET]
 jne .hint_stale
 cmp rdx,NEBOC_ITER_KIND_LIST
 jb .hint_stale
 cmp rdx,NEBOC_ITER_KIND_SLICE
 ja .hint_stale
 cmp rdx,NEBOC_ITER_KIND_SLICE
 je .hint_slice
 mov rax,[r14+NEBOC_LIST_GENERATION_OFFSET]
 jmp .hint_generation
.hint_slice:
 mov rax,[r14+32]
.hint_generation:
 cmp rax,[r12+NEBOC_ITER_GENERATION_OFFSET]
 jne .hint_stale
 mov rax,[r12+NEBOC_ITER_LENGTH_OFFSET]
 mov rcx,[r12+NEBOC_ITER_INDEX_OFFSET]
 cmp rcx,rax
 ja .hint_stale
 sub rax,rcx
 mov [r13],rax
 xor eax,eax
 jmp .hint_done
.hint_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.hint_done:
 pop r14
 pop r13
 pop r12
 ret
.hint_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_iterator_release
 test rdi,rdi
 jz .release_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,[r12+NEBOC_ITER_TOKEN_OFFSET]
 test r13,r13
 jz .release_stale
 mov r14,r13
 and r13,-8
 and r14d,NEBOC_ITER_KIND_MASK
 cmp r13,[r12+NEBOC_ITER_OWNER_OFFSET]
 jne .release_stale
 cmp r14,NEBOC_ITER_KIND_LIST
 jb .release_stale
 cmp r14,NEBOC_ITER_KIND_SLICE
 ja .release_stale
 cmp r14,NEBOC_ITER_KIND_SLICE
 je .release_slice
 mov rax,[r13+NEBOC_LIST_GENERATION_OFFSET]
 cmp rax,[r12+NEBOC_ITER_GENERATION_OFFSET]
 jne .release_stale
 bt rax,63
 jnc .release_stale
 mov rcx,NEBOC_LIST_GENERATION_MASK
 and [r13+NEBOC_LIST_GENERATION_OFFSET],rcx
 jmp .release_commit
.release_slice:
 mov rax,[r13+32]
 cmp rax,[r12+NEBOC_ITER_GENERATION_OFFSET]
 jne .release_stale
.release_commit:
 mov qword [r12+NEBOC_ITER_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_ITER_OWNER_OFFSET],0
 xor eax,eax
 jmp .release_done
.release_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.release_done:
 pop r14
 pop r13
 pop r12
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
 mov rax,[rsi+NEBOC_ITER_TOKEN_OFFSET]
 and rax,-8
 cmp rax,rdi
 jne .gate_ok
 mov rax,[rdi+NEBOC_LIST_GENERATION_OFFSET]
 cmp rax,[rsi+NEBOC_ITER_GENERATION_OFFSET]
 jne .gate_ok
 bt rax,63
 jnc .gate_ok
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.gate_ok:
 xor eax,eax
 ret
.gate_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; enumerate(iter*) authenticates the iterator. The indexed value is produced
; by next_enumerated so the base Iterator ABI remains reusable.
NEBOC_ABI_FUNCTION neboc_iterator_enumerate
 sub rsp,8
 lea rsi,[rsp]
 call neboc_iterator_size_hint
 add rsp,8
 ret

; next_enumerated(iter*, out_index*, out_value*, found*) publishes the current
; monotonic index and delegates element authentication/copying to next().
NEBOC_ABI_FUNCTION neboc_iterator_next_enumerated
 test rdi,rdi
 jz .enumerated_invalid
 test rsi,rsi
 jz .enumerated_invalid
 test rdx,rdx
 jz .enumerated_invalid
 test rcx,rcx
 jz .enumerated_invalid
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rax,[r12+NEBOC_ITER_INDEX_OFFSET]
 push rax
 mov rsi,r14
 mov rdx,r15
 call neboc_iterator_next
 pop rdx
 test eax,eax
 jnz .enumerated_done
 cmp qword [r15],0
 je .enumerated_done
 mov [r13],rdx
.enumerated_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.enumerated_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; skip(iter*, count) advances without reading or materializing elements.
NEBOC_ABI_FUNCTION neboc_iterator_skip
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 lea rsi,[rsp]
 call neboc_iterator_size_hint
 test eax,eax
 jnz .skip_done
 mov rax,[rsp]
 cmp r13,rax
 cmova r13,rax
 add [r12+NEBOC_ITER_INDEX_OFFSET],r13
 xor eax,eax
.skip_done:
 add rsp,8
 pop r13
 pop r12
 ret

; take(iter*, count) narrows the authenticated remaining range lazily.
NEBOC_ABI_FUNCTION neboc_iterator_take
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 lea rsi,[rsp]
 call neboc_iterator_size_hint
 test eax,eax
 jnz .take_done
 mov rax,[rsp]
 cmp r13,rax
 cmova r13,rax
 add r13,[r12+NEBOC_ITER_INDEX_OFFSET]
 mov [r12+NEBOC_ITER_LENGTH_OFFSET],r13
 xor eax,eax
.take_done:
 add rsp,8
 pop r13
 pop r12
 ret

; collect(iter*, destination_empty_list*) validates all capacity and type
; requirements before consuming the iterator or mutating the destination.
NEBOC_ABI_FUNCTION neboc_iterator_collect_list
 test rdi,rdi
 jz .collect_invalid
 test rsi,rsi
 jz .collect_invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,40
 mov r12,rdi
 mov r13,rsi
 mov rax,[r12+NEBOC_ITER_INDEX_OFFSET]
 mov [rsp+16],rax
 lea rsi,[rsp]
 call neboc_iterator_size_hint
 test eax,eax
 jnz .collect_done
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .collect_done
 bt qword [r13+NEBOC_LIST_GENERATION_OFFSET],63
 jc .collect_source
 cmp qword [r13+NEBOC_LIST_LENGTH_OFFSET],0
 jne .collect_source
 mov rax,[rsp]
 cmp rax,[r13+NEBOC_LIST_CAPACITY_OFFSET]
 ja .collect_limit
 cmp rax,NEBOC_LIST_MAX_ELEMENTS
 ja .collect_limit
 cmp qword [r12+NEBOC_ITER_STRIDE_OFFSET],0
 je .collect_source
 mov rcx,[r12+NEBOC_ITER_STRIDE_OFFSET]
 cmp rcx,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 jne .collect_source
 xor ebx,ebx
.collect_loop:
 cmp rbx,[rsp]
 jae .collect_ok
 mov rax,rbx
 imul rax,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov r14,[r13+NEBOC_LIST_DATA_OFFSET]
 add r14,rax
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rsp+8]
 call neboc_iterator_next
 test eax,eax
 jnz .collect_fail
 cmp qword [rsp+8],1
 jne .collect_source
 inc rbx
 jmp .collect_loop
.collect_ok:
 mov rax,[rsp]
 mov [r13+NEBOC_LIST_LENGTH_OFFSET],rax
 test rax,rax
 jz .collect_success
 inc qword [r13+NEBOC_LIST_GENERATION_OFFSET]
.collect_success:
 xor eax,eax
 jmp .collect_done
.collect_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .collect_fail
.collect_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.collect_fail:
 mov rcx,[rsp+16]
 mov [r12+NEBOC_ITER_INDEX_OFFSET],rcx
.collect_done:
 add rsp,40
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.collect_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
