; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-F05 fixed no-libc bounded arena
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/memory/bounded_arena.inc"

section .text

; arena_init(arena*, reservation*, capacity) -> Status
NEBOC_ABI_FUNCTION neboc_bounded_arena_init
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_MAX_ARENA_CAPACITY
 ja .invalid
 mov r8,rdi
 mov ecx,NEBOC_ARENA_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_ARENA_MAGIC
 mov [r8+NEBOC_ARENA_MAGIC_OFFSET],rax
 mov [r8+neboc_text_char_unicode_e_bytes_ARENA_BASE_OFFSET],rsi
 mov [r8+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET],rdx
 mov qword [r8+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET],1
 mov rdi,r8
 sub rsp,8
 call rf27g04_arena_rehash
 add rsp,8
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; layout_check(layout*, cursor, capacity, result*) -> Status. This pure check is
; also the overflow proof for cursor values outside a concrete bounded arena.
NEBOC_ABI_FUNCTION neboc_layout_check
 test rdi,rdi
 jz .invalid_direct
 test rcx,rcx
 jz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r15
 mov ecx,neboc_text_char_unicode_e_bytes_RESULT_QWORDS
 xor eax,eax
 rep stosq
 mov rbx,[r12+neboc_text_char_unicode_e_bytes_LAYOUT_SIZE_OFFSET]
 test rbx,rbx
 jz .size
 cmp rbx,NEBOC_MAX_REQUEST
 ja .size
 mov rdx,[r12+neboc_text_char_unicode_e_bytes_LAYOUT_ALIGNMENT_OFFSET]
 test rdx,rdx
 jz .alignment
 cmp rdx,NEBOC_MAX_ALIGNMENT
 ja .alignment
 lea rax,[rdx-1]
 test rdx,rax
 jnz .alignment
 mov r8,r13
 add r8,rax
 jc .overflow
 not rax
 and r8,rax
 mov r9,r8
 add r9,rbx
 jc .overflow
 cmp r9,r14
 ja .exhausted
 mov [r15+NEBOC_RESULT_BLOCK_OFFSET_OFFSET],r8
 mov [r15+NEBOC_RESULT_BLOCK_SIZE_OFFSET],rbx
 mov [r15+NEBOC_RESULT_BLOCK_ALIGNMENT_OFFSET],rdx
 mov [r15+NEBOC_RESULT_END_OFFSET],r9
 xor eax,eax
 jmp .done
.size:
 mov esi,NEBOC_ARENA_DIAG_SIZE
 jmp .error
.alignment:
 mov esi,NEBOC_ARENA_DIAG_ALIGNMENT
 jmp .error
.exhausted:
 mov esi,NEBOC_ARENA_DIAG_EXHAUSTED
 jmp .error
.overflow:
 mov esi,NEBOC_ARENA_DIAG_OVERFLOW
.error:
 mov rdi,r15
 call rf27g04_result_error
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; arena_allocate(arena*, layout*, result*) -> Status/Result<Block,Error>.
NEBOC_ABI_FUNCTION neboc_bounded_arena_allocate
 test rdx,rdx
 jz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 call rf27g04_arena_validate
 test eax,eax
 jnz .internal
 test r13,r13
 jz .internal
 mov rdi,r13
 mov rsi,[r12+NEBOC_ARENA_CURSOR_OFFSET]
 mov rdx,[r12+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET]
 mov rcx,r14
 call neboc_layout_check
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_RESULT_END_OFFSET]
 mov [r12+NEBOC_ARENA_CURSOR_OFFSET],rax
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET]
 jbe .high_water_ready
 mov [r12+neboc_text_char_unicode_e_bytes_ARENA_HIGH_WATER_OFFSET],rax
.high_water_ready:
 inc qword [r12+NEBOC_BOUNDED_ARENA_ALLOCATION_COUNT_OFFSET]
 mov rax,[r12+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET]
 mov [r14+NEBOC_RESULT_BLOCK_GENERATION_OFFSET],rax
 mov qword [r12+NEBOC_ARENA_LAST_DIAGNOSTIC_OFFSET],0
 mov rdi,r12
 call rf27g04_arena_rehash
 xor eax,eax
 jmp .done
.internal:
 mov rdi,r14
 mov esi,NEBOC_ARENA_DIAG_INTERNAL
 call rf27g04_result_error
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; arena_reset(arena*, result*) -> Status. Reset is atomic and generation-based.
NEBOC_ABI_FUNCTION neboc_bounded_arena_reset
 test rsi,rsi
 jz .invalid_direct
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 call rf27g04_arena_validate
 test eax,eax
 jnz .internal
 cmp qword [r12+NEBOC_ARENA_LIVE_BORROWS_OFFSET],0
 jne .borrowed
 mov rax,[r12+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET]
 inc rax
 jz .internal
 mov qword [r12+NEBOC_ARENA_CURSOR_OFFSET],0
 mov [r12+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET],rax
 mov qword [r12+NEBOC_BOUNDED_ARENA_ALLOCATION_COUNT_OFFSET],0
 inc qword [r12+NEBOC_BOUNDED_ARENA_RESET_COUNT_OFFSET]
 mov qword [r12+NEBOC_ARENA_LAST_DIAGNOSTIC_OFFSET],0
 mov rdi,r13
 mov ecx,neboc_text_char_unicode_e_bytes_RESULT_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET]
 mov [r13+NEBOC_RESULT_BLOCK_GENERATION_OFFSET],rax
 mov rdi,r12
 call rf27g04_arena_rehash
 xor eax,eax
 jmp .done
.borrowed:
 mov rdi,r13
 mov esi,NEBOC_ARENA_DIAG_RESET_BORROWED
 call rf27g04_result_error
 jmp .done
.internal:
 mov rdi,r13
 mov esi,NEBOC_ARENA_DIAG_INTERNAL
 call rf27g04_result_error
.done:
 add rsp,8
 pop r13
 pop r12
 ret
.invalid_direct:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_borrow_begin
 push r12
 mov r12,rdi
 call rf27g04_arena_validate
 test eax,eax
 jnz .done
 cmp qword [r12+NEBOC_ARENA_LIVE_BORROWS_OFFSET],-1
 je .limit
 inc qword [r12+NEBOC_ARENA_LIVE_BORROWS_OFFSET]
 mov rdi,r12
 call rf27g04_arena_rehash
 xor eax,eax
.done:
 pop r12
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done

NEBOC_ABI_FUNCTION neboc_arena_borrow_end
 push r12
 mov r12,rdi
 call rf27g04_arena_validate
 test eax,eax
 jnz .done
 cmp qword [r12+NEBOC_ARENA_LIVE_BORROWS_OFFSET],0
 je .invalid
 dec qword [r12+NEBOC_ARENA_LIVE_BORROWS_OFFSET]
 mov rdi,r12
 call rf27g04_arena_rehash
 xor eax,eax
.done:
 pop r12
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done

; Individual arena block deallocation is never supported; repeated attempts
; are deterministic double-free diagnostics and never rewind the arena.
NEBOC_ABI_FUNCTION neboc_arena_deallocate
 test rdx,rdx
 jz .invalid_direct
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rdx
 mov rdi,r12
 call rf27g04_arena_validate
 test eax,eax
 jnz .internal
 mov rdi,r13
 mov esi,NEBOC_ARENA_DIAG_DOUBLE_FREE
 call rf27g04_result_error
 jmp .done
.internal:
 mov rdi,r13
 mov esi,NEBOC_ARENA_DIAG_INTERNAL
 call rf27g04_result_error
.done:
 add rsp,8
 pop r13
 pop r12
 ret
.invalid_direct:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

rf27g04_arena_validate:
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 mov rax,NEBOC_ARENA_MAGIC
 cmp [rdi+NEBOC_ARENA_MAGIC_OFFSET],rax
 jne .invalid
 cmp qword [rdi+neboc_text_char_unicode_e_bytes_ARENA_BASE_OFFSET],0
 je .invalid
 mov rax,[rdi+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_MAX_ARENA_CAPACITY
 ja .invalid
 cmp [rdi+NEBOC_ARENA_CURSOR_OFFSET],rax
 ja .invalid
 cmp qword [rdi+neboc_text_char_unicode_e_bytes_ARENA_GENERATION_OFFSET],0
 je .invalid
 sub rsp,8
 call rf27g04_arena_hash
 add rsp,8
 cmp rax,[rdi+NEBOC_ARENA_STATE_HASH_OFFSET]
 jne .invalid
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; result*, diagnostic -> status
rf27g04_result_error:
 mov r8,rdi
 mov r9,rsi
 mov ecx,neboc_text_char_unicode_e_bytes_RESULT_QWORDS
 xor eax,eax
 rep stosq
 mov qword [r8+NEBOC_RESULT_TAG_OFFSET],neboc_text_char_unicode_e_bytes_RESULT_ERR
 mov [r8+neboc_text_char_unicode_e_bytes_RESULT_DIAGNOSTIC_OFFSET],r9
 cmp r9,NEBOC_ARENA_DIAG_EXHAUSTED
 je .oom
 cmp r9,NEBOC_ARENA_DIAG_OVERFLOW
 je .limit
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.oom:
 mov eax,NEBOC_STATUS_OUT_OF_MEMORY
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

; Stable FNV over pointer-free arena state from capacity through reset count.
rf27g04_arena_hash:
 push rbx
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ebx,ebx
.loop:
 cmp ebx,56
 jae .done
 movzx ecx,byte [rdi+neboc_text_char_unicode_e_bytes_ARENA_CAPACITY_OFFSET+rbx]
 xor rax,rcx
 imul rax,r8
 inc ebx
 jmp .loop
.done:
 pop rbx
 ret

rf27g04_arena_rehash:
 push rdi
 call rf27g04_arena_hash
 pop rdi
 mov [rdi+NEBOC_ARENA_STATE_HASH_OFFSET],rax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
