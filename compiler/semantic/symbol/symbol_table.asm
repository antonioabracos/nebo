; Nebo Assembly — MF021 deterministic SymbolTable
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/symbol/symbol_table.inc"

section .text

; symbol_table_init(table*, entries*, capacity)
NEBOC_ABI_FUNCTION neboc_symbol_table_init
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 mov [rdi+NEBOC_SYMBOL_TABLE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_SYMBOL_TABLE_COUNT_OFFSET],0
 mov [rdi+NEBOC_SYMBOL_TABLE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_SYMBOL_TABLE_STATE_OFFSET],NEBOC_SYMBOL_TABLE_STATE_MUTABLE
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.init_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; symbol_table_reset(table*)
NEBOC_ABI_FUNCTION neboc_symbol_table_reset
 test rdi,rdi
 jz .reset_invalid
 cmp qword [rdi+NEBOC_SYMBOL_TABLE_DATA_OFFSET],0
 je .reset_invalid
 cmp qword [rdi+NEBOC_SYMBOL_TABLE_CAPACITY_OFFSET],0
 je .reset_invalid
 mov qword [rdi+NEBOC_SYMBOL_TABLE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_SYMBOL_TABLE_STATE_OFFSET],NEBOC_SYMBOL_TABLE_STATE_MUTABLE
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.reset_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; symbol_table_append(table*, name_token_index, kind, decl_node_id, scope_id,
;                     out_symbol_id*)
NEBOC_ABI_FUNCTION neboc_symbol_table_append
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .append_invalid
 test r9,r9
 jz .append_invalid
 mov qword [r9],0
 cmp qword [rbx+NEBOC_SYMBOL_TABLE_STATE_OFFSET],NEBOC_SYMBOL_TABLE_STATE_MUTABLE
 jne .append_invalid
 test rdx,rdx
 jz .append_invalid
 cmp rdx,NEBOC_SYMBOL_KIND_COUNT
 ja .append_invalid
 test rcx,rcx
 jz .append_invalid
 mov r10,[rbx+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 cmp r10,[rbx+NEBOC_SYMBOL_TABLE_CAPACITY_OFFSET]
 jae .append_limit
 mov r11,[rbx+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 test r11,r11
 jz .append_invalid
 mov rax,r10
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 add rax,r11
 mov [rax+NEBOC_SYMBOL_ENTRY_NAME_TOKEN_OFFSET],rsi
 mov [rax+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],rdx
 mov [rax+NEBOC_SYMBOL_ENTRY_DECL_NODE_ID_OFFSET],rcx
 mov [rax+NEBOC_SYMBOL_ENTRY_SCOPE_ID_OFFSET],r8
 mov qword [rax+NEBOC_SYMBOL_ENTRY_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_NONE
 inc r10
 mov [rax+NEBOC_SYMBOL_ENTRY_ID_OFFSET],r10
 mov [rbx+NEBOC_SYMBOL_TABLE_COUNT_OFFSET],r10
 mov [r9],r10
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

; symbol_table_get(table*, symbol_id, out_entry_ptr*)
NEBOC_ABI_FUNCTION neboc_symbol_table_get
 test rdi,rdi
 jz .get_invalid
 test rdx,rdx
 jz .get_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .get_invalid
 cmp rsi,[rdi+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 ja .get_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 add rax,[rdi+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; symbol_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_symbol_table_freeze
 test rdi,rdi
 jz .freeze_invalid
 cmp qword [rdi+NEBOC_SYMBOL_TABLE_STATE_OFFSET],NEBOC_SYMBOL_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov qword [rdi+NEBOC_SYMBOL_TABLE_STATE_OFFSET],NEBOC_SYMBOL_TABLE_STATE_FROZEN
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.freeze_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
