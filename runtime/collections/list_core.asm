; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-F02 bounded no-libc List core over caller-provided text_char_unicode_e_bytes storage.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"

extern neboc_list_validate

section .text

; list_new(desc*, element_size, element_align, allocator_token)
NEBOC_ABI_FUNCTION neboc_list_new
 test rdi,rdi
 jz .new_invalid
 test rdi,7
 jnz .new_invalid
 test rsi,rsi
 jz .new_invalid
 cmp rsi,NEBOC_LIST_MAX_ELEMENT_SIZE
 ja .new_invalid
 test rdx,rdx
 jz .new_invalid
 cmp rdx,NEBOC_LIST_MAX_ELEMENT_ALIGN
 ja .new_invalid
 lea rax,[rdx-1]
 test rdx,rax
 jnz .new_invalid
 test rcx,rcx
 jz .new_invalid
 mov r8,rdi
 mov r9,rsi
 mov r10,rdx
 mov r11,rcx
 mov ecx,NEBOC_LIST_QWORDS
 xor eax,eax
 rep stosq
 mov [r8+NEBOC_LIST_ELEMENT_SIZE_OFFSET],r9
 mov [r8+NEBOC_LIST_ELEMENT_ALIGN_OFFSET],r10
 mov qword [r8+NEBOC_LIST_GENERATION_OFFSET],1
 mov [r8+NEBOC_LIST_ALLOCATOR_OFFSET],r11
 mov rax,NEBOC_LIST_MAGIC
 mov [r8+NEBOC_LIST_FLAGS_OFFSET],rax
 xor eax,eax
 ret
.new_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_init(desc*, storage*, capacity, element_size, element_align, allocator)
NEBOC_ABI_FUNCTION neboc_list_init
 push rbx
 push r12
 push r13
 mov r13,rdi
 mov rbx,rsi
 mov r12,rdx
 mov rsi,rcx
 mov rdx,r8
 mov rcx,r9
 call neboc_list_new
 test eax,eax
 jnz .init_done
 test r12,r12
 jz .init_zero
 test rbx,rbx
 jz .init_rollback
.init_zero:
 cmp r12,NEBOC_LIST_MAX_ELEMENTS
 ja .init_rollback
 mov rax,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 imul rax,r12
 jo .init_rollback
 cmp rax,NEBOC_LIST_MAX_BYTES
 ja .init_rollback
 mov [r13+NEBOC_LIST_DATA_OFFSET],rbx
 mov [r13+NEBOC_LIST_CAPACITY_OFFSET],r12
 xor eax,eax
 jmp .init_done
.init_rollback:
 mov rdi,r13
 mov ecx,NEBOC_LIST_QWORDS
 xor eax,eax
 rep stosq
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.init_done:
 pop r13
 pop r12
 pop rbx
 ret

; list_reserve(desc*, new_storage*, new_capacity)
NEBOC_ABI_FUNCTION neboc_list_reserve
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .reserve_done
 cmp r14,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jb .reserve_limit
 cmp r14,NEBOC_LIST_MAX_ELEMENTS
 ja .reserve_limit
 test r14,r14
 jz .reserve_limit
 test r13,r13
 jz .reserve_oom
 mov rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 imul rax,r14
 jo .reserve_limit
 cmp rax,NEBOC_LIST_MAX_BYTES
 ja .reserve_limit
 cmp r13,[r12+NEBOC_LIST_DATA_OFFSET]
 jne .reserve_copy
 cmp r14,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 je .reserve_ok
.reserve_copy:
 mov rdi,r13
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov [r12+NEBOC_LIST_DATA_OFFSET],r13
 mov [r12+NEBOC_LIST_CAPACITY_OFFSET],r14
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
.reserve_ok:
 xor eax,eax
 jmp .reserve_done
.reserve_oom:
 mov eax,NEBOC_STATUS_OUT_OF_MEMORY
 jmp .reserve_done
.reserve_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.reserve_done:
 pop r14
 pop r13
 pop r12
 ret

; list_push(desc*, value*)
NEBOC_ABI_FUNCTION neboc_list_push
 test rsi,rsi
 jz .push_invalid
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call neboc_list_validate
 test eax,eax
 jnz .push_done
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .push_full
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 inc qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 xor eax,eax
 jmp .push_done
.push_full:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.push_done:
 pop r13
 pop r12
 ret
.push_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_at(desc*, index, out*)
NEBOC_ABI_FUNCTION neboc_list_at
 test rdx,rdx
 jz .at_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .at_done
 cmp r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .at_bounds
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r14
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 xor eax,eax
 jmp .at_done
.at_bounds:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.at_done:
 pop r14
 pop r13
 pop r12
 ret
.at_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_get(desc*, index, out*, found*)
NEBOC_ABI_FUNCTION neboc_list_get
 test rcx,rcx
 jz .get_invalid
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],0
 call neboc_list_validate
 test eax,eax
 jnz .get_done
 cmp r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .get_ok
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call neboc_list_at
 test eax,eax
 jnz .get_done
 mov qword [r15],1
.get_ok:
 xor eax,eax
.get_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.get_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_set(desc*, index, value*)
NEBOC_ABI_FUNCTION neboc_list_set
 test rdx,rdx
 jz .set_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .set_done
 cmp r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .set_bounds
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,r14
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 xor eax,eax
 jmp .set_done
.set_bounds:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.set_done:
 pop r14
 pop r13
 pop r12
 ret
.set_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_pop(desc*, out*, found*)
NEBOC_ABI_FUNCTION neboc_list_pop
 test rdx,rdx
 jz .pop_invalid
 mov qword [rdx],0
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .pop_done
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rax,rax
 jz .pop_empty
 test r13,r13
 jz .pop_bad_out
 dec rax
 mov [r12+NEBOC_LIST_LENGTH_OFFSET],rax
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
 mov qword [r14],1
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
.pop_empty:
 xor eax,eax
 jmp .pop_done
.pop_bad_out:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.pop_done:
 pop r14
 pop r13
 pop r12
 ret
.pop_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_clear(desc*)
NEBOC_ABI_FUNCTION neboc_list_clear
 push r12
 mov r12,rdi
 call neboc_list_validate
 test eax,eax
 jnz .clear_done
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rcx,rcx
 jz .clear_ok
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 xor eax,eax
 rep stosb
 mov qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
.clear_ok:
 xor eax,eax
.clear_done:
 pop r12
 ret

; list_state(desc*, out_length*, out_capacity*)
NEBOC_ABI_FUNCTION neboc_list_state
 test rsi,rsi
 jz .state_invalid
 test rdx,rdx
 jz .state_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .state_done
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 mov [r13],rax
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 mov [r14],rax
 xor eax,eax
.state_done:
 pop r14
 pop r13
 pop r12
 ret
.state_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
