; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-F02 authenticated ownership lowering plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/memory/move_copy_clone.inc"
%include "compiler/lowering/memory/move_copy_clone_plan.inc"

section .text

; lower(semantic_request*, plan*) -> Status
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_move_copy_clone_lower
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdi,7
 jnz .invalid
 test rsi,7
 jnz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_SEM_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],0
 jne .source
 mov rax,neboc_text_char_unicode_e_bytes_LAYOUT_ID
 cmp [r12+NEBOC_SEM_LAYOUT_ID_OFFSET],rax
 jne .source
 cmp qword [r12+NEBOC_SEM_EVENT_COUNT_OFFSET],NEBOC_OWNERSHIP_MAX_EVENTS
 ja .source
 mov rdi,r12
 call semantic_hash
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_HASH_OFFSET]
 jne .source
 mov rdi,r13
 mov ecx,neboc_text_char_unicode_e_bytes_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,neboc_text_char_unicode_e_bytes_PLAN_MAGIC
 mov [r13+neboc_text_char_unicode_e_bytes_PLAN_MAGIC_OFFSET],rax
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_HASH_OFFSET]
 mov [r13+neboc_text_char_unicode_e_bytes_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_OPERATION_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_OPERATION_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_SYMBOL_COUNT_OFFSET],rax
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_memory_native_vertical]
 mov [r13+neboc_text_char_unicode_e_bytes_PLAN_RESULT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_RESULT_VALUE_OFFSET]
 mov [r13+neboc_text_char_unicode_e_bytes_PLAN_RESULT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_COPY_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_COPY_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_MOVE_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_MOVE_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_CLONE_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_CLONE_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_CLEANUP_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_CLEANUP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_CLEANUP_ORDER_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_CLOSED_OWNER_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_SAFETY_PROOF_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_SAFETY_PROOF_HASH_OFFSET],rax
 lea rsi,[r12+NEBOC_SEM_EVENT_COUNT_OFFSET]
 lea rdi,[r13+NEBOC_PLAN_EVENT_COUNT_OFFSET]
 mov ecx,1+NEBOC_OWNERSHIP_MAX_EVENTS*6
 rep movsq
 mov rdi,r13
 mov ecx,neboc_text_char_unicode_e_bytes_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+neboc_text_char_unicode_e_bytes_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov rcx,[rdi+NEBOC_SEM_FOUND_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_OPERATION_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_memory_native_vertical]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_RESULT_VALUE_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_COPY_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_MOVE_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLONE_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLEANUP_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_SAFETY_PROOF_HASH_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_LAYOUT_ID_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov r9,NEBOC_SEM_EVENT_COUNT_OFFSET
.events:
 mov rcx,[rdi+r9]
 xor rax,rcx
 imul rax,r8
 add r9,8
 cmp r9,neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_driver_cli_linux_x86_64_native_vertical
 jb .events
 ret

hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done: ret

section .note.GNU-stack noalloc noexec nowrite progbits
