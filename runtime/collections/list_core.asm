; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-F02 bounded no-libc List core over caller-provided text_char_unicode_e_bytes storage.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/list_construction.inc"

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

; Configure the optional move-only lifecycle trailer on an empty List.
; move_fn(source*, destination*) -> Status and drop_fn(element*) -> Void.
NEBOC_ABI_FUNCTION neboc_list_configure_lifecycle
 test rsi,rsi
 jz .lifecycle_invalid
 test rdx,rdx
 jz .lifecycle_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .lifecycle_done
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 jne .lifecycle_source
 mov [r12+NEBOC_LIST_MOVE_FN_OFFSET],r13
 mov [r12+NEBOC_LIST_DROP_FN_OFFSET],r14
 xor eax,eax
 jmp .lifecycle_done
.lifecycle_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.lifecycle_done:
 pop r14
 pop r13
 pop r12
 ret
.lifecycle_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Move-only append. No descriptor state is committed unless move_fn succeeds.
NEBOC_ABI_FUNCTION neboc_list_move_push
 test rsi,rsi
 jz .move_push_invalid
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call neboc_list_validate
 test eax,eax
 jnz .move_push_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .move_push_source
 mov rbx,[r12+NEBOC_LIST_MOVE_FN_OFFSET]
 test rbx,rbx
 jz .move_push_source
 cmp qword [r12+NEBOC_LIST_DROP_FN_OFFSET],0
 je .move_push_source
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .move_push_limit
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r13
 call rbx
 test eax,eax
 jnz .move_push_done
 inc qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 xor eax,eax
 jmp .move_push_done
.move_push_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .move_push_done
.move_push_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.move_push_done:
 pop r13
 pop r12
 pop rbx
 ret
.move_push_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Move-only pop. The element remains live and length is unchanged if move_fn
; rejects the transfer.
NEBOC_ABI_FUNCTION neboc_list_move_pop
 test rsi,rsi
 jz .move_pop_invalid
 test rdx,rdx
 jz .move_pop_invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_list_validate
 test eax,eax
 jnz .move_pop_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .move_pop_source
 mov rbx,[r12+NEBOC_LIST_MOVE_FN_OFFSET]
 test rbx,rbx
 jz .move_pop_source
 cmp qword [r12+NEBOC_LIST_DROP_FN_OFFSET],0
 je .move_pop_source
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rax,rax
 jz .move_pop_ok
 dec rax
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,r13
 call rbx
 test eax,eax
 jnz .move_pop_done
 dec qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 mov qword [r14],1
.move_pop_ok:
 xor eax,eax
 jmp .move_pop_done
.move_pop_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.move_pop_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.move_pop_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Move-only clear runs the registered destructor exactly once for each live
; element, then clears storage and commits the new generation.
NEBOC_ABI_FUNCTION neboc_list_drop_clear
 push rbx
 push r12
 push r13
 mov r12,rdi
 call neboc_list_validate
 test eax,eax
 jnz .drop_clear_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .drop_clear_source
 mov r13,[r12+NEBOC_LIST_DROP_FN_OFFSET]
 test r13,r13
 jz .drop_clear_source
 cmp qword [r12+NEBOC_LIST_MOVE_FN_OFFSET],0
 je .drop_clear_source
 xor ebx,ebx
.drop_clear_loop:
 cmp rbx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .drop_clear_commit
 mov rax,rbx
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 call r13
 inc rbx
 jmp .drop_clear_loop
.drop_clear_commit:
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 xor eax,eax
 rep stosb
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 je .drop_clear_ok
 mov qword [r12+NEBOC_LIST_LENGTH_OFFSET],0
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
.drop_clear_ok:
 xor eax,eax
 jmp .drop_clear_done
.drop_clear_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.drop_clear_done:
 pop r13
 pop r12
 pop rbx
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

; list_construct(desc*, request*)
; All request fields are validated before the destination descriptor is touched.
NEBOC_ABI_FUNCTION neboc_list_construct
 test rdi,rdi
 jz .construct_invalid
 test rsi,rsi
 jz .construct_invalid
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .construct_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov rbx,[r13+NEBOC_LIST_CONSTRUCT_MODE_OFFSET]
 cmp rbx,NEBOC_LIST_CONSTRUCT_FILL
 ja .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_CATEGORY_OFFSET],NEBOC_LIST_ELEMENT_CATEGORY_TRIVIAL_VALUE
 jne .construct_type
 mov rax,[r13+NEBOC_LIST_CONSTRUCT_TYPE_ID_OFFSET]
 cmp rax,NEBOC_LIST_TYPE_INT
 jb .construct_type
 cmp rax,NEBOC_LIST_TYPE_CHAR
 ja .construct_type
 mov r14,[r13+NEBOC_LIST_CONSTRUCT_ELEMENT_SIZE_OFFSET]
 test r14,r14
 jz .construct_invalid_saved
 cmp r14,NEBOC_LIST_MAX_ELEMENT_SIZE
 ja .construct_limit
 mov r15,[r13+NEBOC_LIST_CONSTRUCT_ELEMENT_ALIGN_OFFSET]
 test r15,r15
 jz .construct_invalid_saved
 cmp r15,NEBOC_LIST_MAX_ELEMENT_ALIGN
 ja .construct_limit
 lea rax,[r15-1]
 test r15,rax
 jnz .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_ALLOCATOR_OFFSET],0
 je .construct_invalid_saved
 mov rdx,[r13+NEBOC_LIST_CONSTRUCT_CAPACITY_OFFSET]
 cmp rdx,NEBOC_LIST_MAX_ELEMENTS
 ja .construct_limit
 mov rcx,[r13+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET]
 cmp rcx,rdx
 ja .construct_limit
 mov rax,r14
 imul rax,rdx
 jo .construct_limit
 cmp rax,NEBOC_LIST_MAX_BYTES
 ja .construct_limit
 test rdx,rdx
 jz .construct_zero_storage
 mov rax,[r13+NEBOC_LIST_CONSTRUCT_STORAGE_OFFSET]
 test rax,rax
 jz .construct_oom
 lea rcx,[r15-1]
 test rax,rcx
 jnz .construct_invalid_saved
 jmp .construct_mode
.construct_zero_storage:
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_STORAGE_OFFSET],0
 jne .construct_invalid_saved
.construct_mode:
 cmp rbx,NEBOC_LIST_CONSTRUCT_NEW
 jne .construct_allocated
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_CAPACITY_OFFSET],0
 jne .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET],0
 jne .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET],0
 jne .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_FILL_OFFSET],0
 jne .construct_invalid_saved
 mov rdi,r12
 mov rsi,r14
 mov rdx,r15
 mov rcx,[r13+NEBOC_LIST_CONSTRUCT_ALLOCATOR_OFFSET]
 call neboc_list_new
 jmp .construct_done
.construct_allocated:
 cmp rbx,NEBOC_LIST_CONSTRUCT_WITH_CAPACITY
 jne .construct_values
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET],0
 jne .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET],0
 jne .construct_invalid_saved
 cmp qword [r13+NEBOC_LIST_CONSTRUCT_FILL_OFFSET],0
 jne .construct_invalid_saved
 jmp .construct_init
.construct_values:
 mov rcx,[r13+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET]
 test rcx,rcx
 jz .construct_init
 cmp rbx,NEBOC_LIST_CONSTRUCT_FROM
 jne .construct_fill_pointer
 mov rax,[r13+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET]
 jmp .construct_value_pointer
.construct_fill_pointer:
 mov rax,[r13+NEBOC_LIST_CONSTRUCT_FILL_OFFSET]
.construct_value_pointer:
 test rax,rax
 jz .construct_invalid_saved
 lea rcx,[r15-1]
 test rax,rcx
 jnz .construct_invalid_saved
.construct_init:
 mov rdi,r12
 mov rsi,[r13+NEBOC_LIST_CONSTRUCT_STORAGE_OFFSET]
 mov rdx,[r13+NEBOC_LIST_CONSTRUCT_CAPACITY_OFFSET]
 mov rcx,r14
 mov r8,r15
 mov r9,[r13+NEBOC_LIST_CONSTRUCT_ALLOCATOR_OFFSET]
 call neboc_list_init
 test eax,eax
 jnz .construct_done
 mov r15,[r13+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET]
 test r15,r15
 jz .construct_ok
 cmp rbx,NEBOC_LIST_CONSTRUCT_FROM
 jne .construct_fill
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rsi,[r13+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET]
 mov rcx,r15
 imul rcx,r14
 rep movsb
 jmp .construct_commit
.construct_fill:
 xor ebx,ebx
.construct_fill_loop:
 cmp rbx,r15
 jae .construct_commit
 mov rax,rbx
 imul rax,r14
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,[r13+NEBOC_LIST_CONSTRUCT_FILL_OFFSET]
 mov rcx,r14
 rep movsb
 inc rbx
 jmp .construct_fill_loop
.construct_commit:
 mov [r12+NEBOC_LIST_LENGTH_OFFSET],r15
.construct_ok:
 xor eax,eax
 jmp .construct_done
.construct_type:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .construct_done
.construct_oom:
 mov eax,NEBOC_STATUS_OUT_OF_MEMORY
 jmp .construct_done
.construct_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .construct_done
.construct_invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.construct_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.construct_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
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
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .reserve_borrow
 cmp r14,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jb .reserve_limit
 cmp r14,NEBOC_LIST_MAX_ELEMENTS
 ja .reserve_limit
 test r14,r14
 jz .reserve_limit
 test r13,r13
 jz .reserve_oom
 mov rcx,[r12+NEBOC_LIST_ELEMENT_ALIGN_OFFSET]
 dec rcx
 test r13,rcx
 jnz .reserve_limit
 mov rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 imul rax,r14
 jo .reserve_limit
 cmp rax,NEBOC_LIST_MAX_BYTES
 ja .reserve_limit
 mov rax,[r12+NEBOC_LIST_GENERATION_OFFSET]
 mov rcx,0x7fffffffffffffff
 cmp rax,rcx
 jae .reserve_limit
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
.reserve_borrow:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .reserve_done
.reserve_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.reserve_done:
 pop r14
 pop r13
 pop r12
 ret

; list_growth_capacity(desc*, required_total, out_capacity*)
; Computes max(4, old_capacity*2, required_total) without allocating.
NEBOC_ABI_FUNCTION neboc_list_growth_capacity
 test rdx,rdx
 jz .growth_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .growth_done
 cmp r13,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 ja .growth_expand
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 mov [r14],rax
 xor eax,eax
 jmp .growth_done
.growth_expand:
 cmp r13,NEBOC_LIST_MAX_ELEMENTS
 ja .growth_limit
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 shl rax,1
 jc .growth_limit
 cmp rax,4
 jae .growth_required
 mov eax,4
.growth_required:
 cmp rax,r13
 jae .growth_bounds
 mov rax,r13
.growth_bounds:
 cmp rax,NEBOC_LIST_MAX_ELEMENTS
 ja .growth_limit
 mov rcx,rax
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 jo .growth_limit
 cmp rcx,NEBOC_LIST_MAX_BYTES
 ja .growth_limit
 mov [r14],rax
 xor eax,eax
 jmp .growth_done
.growth_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.growth_done:
 pop r14
 pop r13
 pop r12
 ret
.growth_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
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
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .push_borrow
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .push_full
 mov rcx,0x7fffffffffffffff
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rcx
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
.push_borrow:
 test eax,eax
 jnz .push_done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.push_done:
 pop r13
 pop r12
 ret
.push_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_list_append
 jmp neboc_list_push

; list_insert(desc*, index, value*) preserves the value through alias-safe scratch.
NEBOC_ABI_FUNCTION neboc_list_insert
 test rdx,rdx
 jz .insert_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .insert_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .insert_borrow
 mov r15,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp r13,r15
 ja .insert_bounds
 cmp r15,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .insert_limit
 mov rcx,0x7fffffffffffffff
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rcx
 jae .insert_limit
 mov rdi,rsp
 mov rsi,r14
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov rbx,r15
 sub rbx,r13
 jz .insert_value
 imul rbx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 lea rdi,[rsi+rbx]
 add rsi,rbx
 dec rsi
 add rdi,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 dec rdi
 mov rcx,rbx
 std
 rep movsb
 cld
.insert_value:
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,rsp
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 inc qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 xor eax,eax
 jmp .insert_done
.insert_bounds:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .insert_done
.insert_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.insert_borrow:
 test eax,eax
 jnz .insert_done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.insert_done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.insert_invalid:
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
 call neboc_list_validate
 test eax,eax
 jnz .get_done
 mov qword [r15],0
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
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .set_borrow
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
.set_borrow:
 test eax,eax
 jnz .set_done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.set_done:
 pop r14
 pop r13
 pop r12
 ret
.set_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_remove(desc*, index, out*, found*) preserves order and zeros the old tail.
NEBOC_ABI_FUNCTION neboc_list_remove
 test rdx,rdx
 jz .remove_invalid
 test rcx,rcx
 jz .remove_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_list_validate
 test eax,eax
 jnz .remove_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .remove_borrow
 mov rbx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp r13,rbx
 jae .remove_empty
 mov rcx,0x7fffffffffffffff
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rcx
 jae .remove_limit
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r14
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov rcx,rbx
 dec rcx
 sub rcx,r13
 jz .remove_zero_tail
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,rdi
 add rsi,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
.remove_zero_tail:
 dec rbx
 mov rax,rbx
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 xor eax,eax
 rep stosb
 mov [r12+NEBOC_LIST_LENGTH_OFFSET],rbx
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 mov qword [r15],1
 xor eax,eax
 jmp .remove_done
.remove_empty:
 mov qword [r15],0
 xor eax,eax
 jmp .remove_done
.remove_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.remove_borrow:
 test eax,eax
 jnz .remove_done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.remove_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.remove_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_swap_remove(desc*, index, out*, found*) removes in O(1) by moving the
; final element into the removed slot. The removed value is published only
; after all bounds/generation checks have succeeded.
NEBOC_ABI_FUNCTION neboc_list_swap_remove
 test rdx,rdx
 jz .swap_remove_invalid
 test rcx,rcx
 jz .swap_remove_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_list_validate
 test eax,eax
 jnz .swap_remove_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .swap_remove_borrow
 mov rbx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp r13,rbx
 jae .swap_remove_empty
 mov rax,NEBOC_LIST_GENERATION_MASK
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rax
 jae .swap_remove_limit
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r14
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 dec rbx
 cmp r13,rbx
 je .swap_remove_zero_tail
 mov rax,rbx
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
.swap_remove_zero_tail:
 mov rax,rbx
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 xor eax,eax
 rep stosb
 mov [r12+NEBOC_LIST_LENGTH_OFFSET],rbx
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 mov qword [r15],1
 xor eax,eax
 jmp .swap_remove_done
.swap_remove_empty:
 mov qword [r15],0
 xor eax,eax
 jmp .swap_remove_done
.swap_remove_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .swap_remove_done
.swap_remove_borrow:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.swap_remove_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.swap_remove_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; list_swap(desc*, a, b) is a unique non-structural mutation.
NEBOC_ABI_FUNCTION neboc_list_swap
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .swap_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .swap_borrow
 mov r15,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp r13,r15
 jae .swap_bounds
 cmp r14,r15
 jae .swap_bounds
 cmp r13,r14
 je .swap_ok
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,rsp
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov rax,r14
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rax,r13
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov rax,r14
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,rsp
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
.swap_ok:
 xor eax,eax
 jmp .swap_done
.swap_bounds:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.swap_borrow:
 test eax,eax
 jnz .swap_done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.swap_done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; list_pop(desc*, out*, found*)
NEBOC_ABI_FUNCTION neboc_list_pop
 test rdx,rdx
 jz .pop_invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .pop_done
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .pop_borrow
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rax,rax
 jz .pop_empty
 mov rcx,0x7fffffffffffffff
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rcx
 jae .pop_limit
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
 xor eax,eax
 jmp .pop_done
.pop_empty:
 mov qword [r14],0
 xor eax,eax
 jmp .pop_done
.pop_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .pop_done
.pop_bad_out:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.pop_borrow:
 test eax,eax
 jnz .pop_done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .clear_borrow
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rcx,rcx
 jz .clear_ok
 mov rax,0x7fffffffffffffff
 cmp [r12+NEBOC_LIST_GENERATION_OFFSET],rax
 jae .clear_limit
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
.clear_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .clear_done
.clear_borrow:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .clear_done

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

; Scalar queries validate the complete descriptor before publishing output.
NEBOC_ABI_FUNCTION neboc_list_length
 test rsi,rsi
 jz .length_invalid
 push r12
 mov r12,rsi
 call neboc_list_validate
 test eax,eax
 jnz .length_done
 mov rax,[rdi+NEBOC_LIST_LENGTH_OFFSET]
 mov [r12],rax
 xor eax,eax
.length_done:
 pop r12
 ret
.length_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_list_capacity
 test rsi,rsi
 jz .capacity_invalid
 push r12
 mov r12,rsi
 call neboc_list_validate
 test eax,eax
 jnz .capacity_done
 mov rax,[rdi+NEBOC_LIST_CAPACITY_OFFSET]
 mov [r12],rax
 xor eax,eax
.capacity_done:
 pop r12
 ret
.capacity_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_list_is_empty
 test rsi,rsi
 jz .empty_invalid
 push r12
 mov r12,rsi
 call neboc_list_validate
 test eax,eax
 jnz .empty_done
 xor eax,eax
 cmp qword [rdi+NEBOC_LIST_LENGTH_OFFSET],0
 sete al
 mov [r12],rax
 xor eax,eax
.empty_done:
 pop r12
 ret
.empty_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_list_first
 xor ecx,ecx
 jmp list_endpoint
NEBOC_ABI_FUNCTION neboc_list_last
 mov ecx,1
list_endpoint:
 test rsi,rsi
 jz .endpoint_invalid
 test rdx,rdx
 jz .endpoint_invalid
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_list_validate
 test eax,eax
 jnz .endpoint_done
 mov qword [r14],0
 mov rsi,[r12+NEBOC_LIST_LENGTH_OFFSET]
 test rsi,rsi
 jz .endpoint_ok
 test r15,r15
 jz .endpoint_index
 dec rsi
.endpoint_index:
 mov rax,rsi
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rdi,r13
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov qword [r14],1
.endpoint_ok:
 xor eax,eax
.endpoint_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.endpoint_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
