; Nebo Assembly — MF021 explicit lexical ScopeTable
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/scope/scope_table.inc"

section .text

; scope_table_init(table*, entries*, capacity)
NEBOC_ABI_FUNCTION neboc_scope_table_init
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 mov [rdi+NEBOC_SCOPE_TABLE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_SCOPE_TABLE_COUNT_OFFSET],0
 mov [rdi+NEBOC_SCOPE_TABLE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_SCOPE_TABLE_STATE_OFFSET],NEBOC_SCOPE_TABLE_STATE_MUTABLE
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.init_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; scope_table_reset(table*)
NEBOC_ABI_FUNCTION neboc_scope_table_reset
 test rdi,rdi
 jz .reset_invalid
 cmp qword [rdi+NEBOC_SCOPE_TABLE_DATA_OFFSET],0
 je .reset_invalid
 cmp qword [rdi+NEBOC_SCOPE_TABLE_CAPACITY_OFFSET],0
 je .reset_invalid
 mov qword [rdi+NEBOC_SCOPE_TABLE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_SCOPE_TABLE_STATE_OFFSET],NEBOC_SCOPE_TABLE_STATE_MUTABLE
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.reset_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; scope_table_append(table*, parent_scope_id, kind, owner_node_id, out_scope_id*)
NEBOC_ABI_FUNCTION neboc_scope_table_append
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .append_invalid
 test r8,r8
 jz .append_invalid
 mov qword [r8],0
 cmp qword [rbx+NEBOC_SCOPE_TABLE_STATE_OFFSET],NEBOC_SCOPE_TABLE_STATE_MUTABLE
 jne .append_invalid
 test rdx,rdx
 jz .append_invalid
 cmp rdx,NEBOC_SCOPE_KIND_COUNT
 ja .append_invalid
 mov r9,[rbx+NEBOC_SCOPE_TABLE_COUNT_OFFSET]
 cmp r9,[rbx+NEBOC_SCOPE_TABLE_CAPACITY_OFFSET]
 jae .append_limit
 cmp rsi,r9
 ja .append_invalid
 mov r10,[rbx+NEBOC_SCOPE_TABLE_DATA_OFFSET]
 test r10,r10
 jz .append_invalid
 xor r11d,r11d
 test rsi,rsi
 jz .depth_ready
 mov rax,rsi
 dec rax
 imul rax,NEBOC_SCOPE_ENTRY_SIZE
 add rax,r10
 mov r11,[rax+NEBOC_SCOPE_ENTRY_DEPTH_OFFSET]
 inc r11
.depth_ready:
 mov rax,r9
 imul rax,NEBOC_SCOPE_ENTRY_SIZE
 add rax,r10
 mov [rax+NEBOC_SCOPE_ENTRY_PARENT_ID_OFFSET],rsi
 mov [rax+NEBOC_SCOPE_ENTRY_KIND_OFFSET],rdx
 mov [rax+NEBOC_SCOPE_ENTRY_OWNER_NODE_ID_OFFSET],rcx
 mov [rax+NEBOC_SCOPE_ENTRY_DEPTH_OFFSET],r11
 mov qword [rax+NEBOC_SCOPE_ENTRY_FIRST_SYMBOL_ID_OFFSET],0
 mov qword [rax+NEBOC_SCOPE_ENTRY_SYMBOL_COUNT_OFFSET],0
 inc r9
 mov [rbx+NEBOC_SCOPE_TABLE_COUNT_OFFSET],r9
 mov [r8],r9
 xor eax,eax
 jmp .append_done
.append_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .append_done
.append_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.append_done:
 pop rbx
 cld
 ret

; scope_table_get(table*, scope_id, out_entry_ptr*)
NEBOC_ABI_FUNCTION neboc_scope_table_get
 test rdi,rdi
 jz .get_invalid
 test rdx,rdx
 jz .get_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .get_invalid
 cmp rsi,[rdi+NEBOC_SCOPE_TABLE_COUNT_OFFSET]
 ja .get_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_SCOPE_ENTRY_SIZE
 add rax,[rdi+NEBOC_SCOPE_TABLE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; scope_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_scope_table_freeze
 test rdi,rdi
 jz .freeze_invalid
 cmp qword [rdi+NEBOC_SCOPE_TABLE_STATE_OFFSET],NEBOC_SCOPE_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov qword [rdi+NEBOC_SCOPE_TABLE_STATE_OFFSET],NEBOC_SCOPE_TABLE_STATE_FROZEN
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.freeze_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
