; Nebo Assembly — MF023 deterministic FunctionTable and signatures
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/function/function_table.inc"

section .text

; function_table_init(table*, entries*, capacity, positional_types*, positional_capacity)
NEBOC_ABI_FUNCTION neboc_function_table_init
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 test rcx,rcx
 jz .init_invalid
 test r8,r8
 jz .init_invalid
 mov [rdi+NEBOC_FUNCTION_TABLE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_FUNCTION_TABLE_COUNT_OFFSET],0
 mov [rdi+NEBOC_FUNCTION_TABLE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_FUNCTION_TABLE_STATE_OFFSET],NEBOC_FUNCTION_TABLE_STATE_MUTABLE
 mov [rdi+NEBOC_FUNCTION_TABLE_POSITIONALS_OFFSET],rcx
 mov qword [rdi+NEBOC_FUNCTION_TABLE_POSITIONAL_COUNT_OFFSET],0
 mov [rdi+NEBOC_FUNCTION_TABLE_POSITIONAL_CAPACITY_OFFSET],r8
 mov qword [rdi+NEBOC_FUNCTION_TABLE_HASH_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.init_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; function_table_reset(table*)
NEBOC_ABI_FUNCTION neboc_function_table_reset
 test rdi,rdi
 jz .reset_invalid
 cmp qword [rdi+NEBOC_FUNCTION_TABLE_DATA_OFFSET],0
 je .reset_invalid
 cmp qword [rdi+NEBOC_FUNCTION_TABLE_CAPACITY_OFFSET],0
 je .reset_invalid
 cmp qword [rdi+NEBOC_FUNCTION_TABLE_POSITIONALS_OFFSET],0
 je .reset_invalid
 cmp qword [rdi+NEBOC_FUNCTION_TABLE_POSITIONAL_CAPACITY_OFFSET],0
 je .reset_invalid
 mov qword [rdi+NEBOC_FUNCTION_TABLE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_FUNCTION_TABLE_POSITIONAL_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_FUNCTION_TABLE_HASH_OFFSET],0
 mov qword [rdi+NEBOC_FUNCTION_TABLE_STATE_OFFSET],NEBOC_FUNCTION_TABLE_STATE_MUTABLE
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.reset_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; function_table_append(table*, declaration*, out_function_id*)
NEBOC_ABI_FUNCTION neboc_function_table_append
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .append_invalid
 test r13,r13
 jz .append_invalid
 test r14,r14
 jz .append_invalid
 mov qword [r14],0
 cmp qword [r12+NEBOC_FUNCTION_TABLE_STATE_OFFSET],NEBOC_FUNCTION_TABLE_STATE_MUTABLE
 jne .append_invalid
 cmp qword [r13+NEBOC_FUNCTION_DECL_RECEIVER_TYPE_OFFSET],0
 je .append_invalid
 cmp qword [r13+NEBOC_FUNCTION_DECL_RETURN_TYPE_OFFSET],0
 je .append_invalid
 cmp qword [r13+NEBOC_FUNCTION_DECL_NODE_ID_OFFSET],0
 je .append_invalid
 cmp qword [r13+NEBOC_FUNCTION_DECL_SYMBOL_ID_OFFSET],0
 je .append_invalid
 mov rbx,[r12+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 cmp rbx,[r12+NEBOC_FUNCTION_TABLE_CAPACITY_OFFSET]
 jae .append_limit
 mov r15,[r13+NEBOC_FUNCTION_DECL_POSITIONAL_COUNT_OFFSET]
 mov r10,[r12+NEBOC_FUNCTION_TABLE_POSITIONAL_COUNT_OFFSET]
 mov r11,r10
 add r11,r15
 jc .append_limit
 cmp r11,[r12+NEBOC_FUNCTION_TABLE_POSITIONAL_CAPACITY_OFFSET]
 ja .append_limit
 test r15,r15
 jz .append_positionals_done
 cmp qword [r13+NEBOC_FUNCTION_DECL_POSITIONALS_PTR_OFFSET],0
 je .append_invalid
 mov rdi,[r12+NEBOC_FUNCTION_TABLE_POSITIONALS_OFFSET]
 lea rdi,[rdi+r10*8]
 mov rsi,[r13+NEBOC_FUNCTION_DECL_POSITIONALS_PTR_OFFSET]
 mov rcx,r15
 rep movsq
.append_positionals_done:
 mov rax,rbx
 imul rax,NEBOC_FUNCTION_ENTRY_SIZE
 add rax,[r12+NEBOC_FUNCTION_TABLE_DATA_OFFSET]
 mov rdx,[r13+NEBOC_FUNCTION_DECL_NAME_TOKEN_OFFSET]
 mov [rax+NEBOC_FUNCTION_ENTRY_NAME_TOKEN_OFFSET],rdx
 mov rdx,[r13+NEBOC_FUNCTION_DECL_RECEIVER_TYPE_OFFSET]
 mov [rax+NEBOC_FUNCTION_ENTRY_RECEIVER_TYPE_OFFSET],rdx
 mov [rax+NEBOC_FUNCTION_ENTRY_POSITIONAL_OFFSET_OFFSET],r10
 mov [rax+NEBOC_FUNCTION_ENTRY_POSITIONAL_COUNT_OFFSET],r15
 mov rdx,[r13+NEBOC_FUNCTION_DECL_RETURN_TYPE_OFFSET]
 mov [rax+NEBOC_FUNCTION_ENTRY_RETURN_TYPE_OFFSET],rdx
 mov rdx,[r13+NEBOC_FUNCTION_DECL_NODE_ID_OFFSET]
 mov [rax+NEBOC_FUNCTION_ENTRY_DECL_NODE_ID_OFFSET],rdx
 mov rdx,[r13+NEBOC_FUNCTION_DECL_SYMBOL_ID_OFFSET]
 mov [rax+NEBOC_FUNCTION_ENTRY_SYMBOL_ID_OFFSET],rdx
 mov rdx,[r13+NEBOC_FUNCTION_DECL_FLAGS_OFFSET]
 mov [rax+NEBOC_FUNCTION_ENTRY_FLAGS_OFFSET],rdx
 mov qword [rax+NEBOC_FUNCTION_ENTRY_KIND_OFFSET],NEBOC_FUNCTION_ENTRY_KIND_PUBLIC
 mov qword [rax+NEBOC_FUNCTION_ENTRY_OUTER_FUNCTION_ID_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_ENTRY_LEXICAL_ORDINAL_OFFSET],0
 inc rbx
 mov [rax+NEBOC_FUNCTION_ENTRY_ID_OFFSET],rbx
 mov [r12+NEBOC_FUNCTION_TABLE_COUNT_OFFSET],rbx
 mov [r12+NEBOC_FUNCTION_TABLE_POSITIONAL_COUNT_OFFSET],r11
 mov [r14],rbx
 xor eax,eax
 jmp .append_done
.append_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .append_done
.append_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.append_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; function_table_append_private(table*, declaration*, outer_function_id,
;                               lexical_ordinal, out_function_id*)
; The ordinary append remains byte-compatible at its call boundary.  This
; compiler-internal extension publishes the selected owner/ordinal metadata
; before freeze and never changes public lookup visibility.
NEBOC_ABI_FUNCTION neboc_function_table_append_private
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 test rbx,rbx
 jz .private_invalid
 test r12,r12
 jz .private_invalid
 test r13,r13
 jz .private_invalid
 cmp r14,NEBOC_FUNCTION_NESTED_MAX_ORDINAL
 jne .private_invalid
 test r15,r15
 jz .private_invalid
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r15
 call neboc_function_table_append
 test eax,eax
 jnz .private_done
 mov rax,[r15]
 test rax,rax
 jz .private_invalid
 dec rax
 imul rax,NEBOC_FUNCTION_ENTRY_SIZE
 add rax,[rbx+NEBOC_FUNCTION_TABLE_DATA_OFFSET]
 mov qword [rax+NEBOC_FUNCTION_ENTRY_KIND_OFFSET],NEBOC_FUNCTION_ENTRY_KIND_NESTED_PRIVATE
 mov [rax+NEBOC_FUNCTION_ENTRY_OUTER_FUNCTION_ID_OFFSET],r13
 mov [rax+NEBOC_FUNCTION_ENTRY_LEXICAL_ORDINAL_OFFSET],r14
 xor eax,eax
 jmp .private_done
.private_invalid:
 test r15,r15
 jz .private_invalid_status
 mov qword [r15],0
.private_invalid_status:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.private_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; function_table_get(table*, function_id, out_entry_ptr*)
NEBOC_ABI_FUNCTION neboc_function_table_get
 test rdi,rdi
 jz .get_invalid
 test rdx,rdx
 jz .get_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .get_invalid
 cmp rsi,[rdi+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 ja .get_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_FUNCTION_ENTRY_SIZE
 add rax,[rdi+NEBOC_FUNCTION_TABLE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; function_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_function_table_freeze
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 test r12,r12
 jz .freeze_invalid
 cmp qword [r12+NEBOC_FUNCTION_TABLE_STATE_OFFSET],NEBOC_FUNCTION_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov ebx,NEBOC_FUNCTION_HASH_FNV1A32_OFFSET_BASIS
 xor r13d,r13d
.freeze_entry_loop:
 cmp r13,[r12+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 jae .freeze_positional_start
 mov rax,r13
 imul rax,NEBOC_FUNCTION_ENTRY_SIZE
 add rax,[r12+NEBOC_FUNCTION_TABLE_DATA_OFFSET]
 xor r14d,r14d
.freeze_entry_qword:
 cmp r14,NEBOC_FUNCTION_ENTRY_QWORDS
 jae .freeze_entry_next
 mov rdx,[rax+r14*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_FUNCTION_HASH_FNV1A32_PRIME
 shr rdx,32
 xor ebx,edx
 imul ebx,ebx,NEBOC_FUNCTION_HASH_FNV1A32_PRIME
 inc r14
 jmp .freeze_entry_qword
.freeze_entry_next:
 inc r13
 jmp .freeze_entry_loop
.freeze_positional_start:
 xor r13d,r13d
 mov rax,[r12+NEBOC_FUNCTION_TABLE_POSITIONALS_OFFSET]
.freeze_positional_loop:
 cmp r13,[r12+NEBOC_FUNCTION_TABLE_POSITIONAL_COUNT_OFFSET]
 jae .freeze_done
 mov rdx,[rax+r13*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_FUNCTION_HASH_FNV1A32_PRIME
 inc r13
 jmp .freeze_positional_loop
.freeze_done:
 mov [r12+NEBOC_FUNCTION_TABLE_HASH_OFFSET],rbx
 mov qword [r12+NEBOC_FUNCTION_TABLE_STATE_OFFSET],NEBOC_FUNCTION_TABLE_STATE_FROZEN
 xor eax,eax
 jmp .freeze_return
.freeze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.freeze_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
