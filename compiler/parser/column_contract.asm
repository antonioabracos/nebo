; COLUMN-ROW-TABLE-E-DATASET-PF002 isolated Column<Int>#4 syntax/API contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/column_contract.inc"
section .text
NEBOC_ABI_FUNCTION neboc_column_contract_validate
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_COLUMN_DIAGNOSTIC_OFFSET],0
 mov rax,[rdi+NEBOC_COLUMN_ERROR_HINT_OFFSET]
 test rax,rax
 jnz .hint
 cmp qword [rdi+NEBOC_COLUMN_FLAGS_OFFSET],NEBOC_COLUMN_FLAGS_REQUIRED
 jne .dtype
 mov rax,[rdi+NEBOC_COLUMN_OPERATION_OFFSET]
 cmp rax,NEBOC_COLUMN_OP_COUNT_MISSING
 ja .join
 cmp rax,NEBOC_COLUMN_OP_LITERAL
 je .literal
 cmp rax,NEBOC_COLUMN_OP_INDEX
 je .index
 cmp qword [rdi+NEBOC_COLUMN_ARGUMENT_COUNT_OFFSET],0
 jne .arity
 xor eax,eax
 ret
.literal:
 cmp qword [rdi+NEBOC_COLUMN_ARGUMENT_COUNT_OFFSET],4
 jne .arity
 xor eax,eax
 ret
.index:
 cmp qword [rdi+NEBOC_COLUMN_ARGUMENT_COUNT_OFFSET],1
 jne .arity
 mov rax,[rdi+NEBOC_COLUMN_INDEX_OFFSET]
 cmp rax,3
 ja .bounds
 xor eax,eax
 ret
.hint:
 cmp rax,NEBOC_DIAG_OVERFLOW
 ja .invalid
 mov [rdi+NEBOC_COLUMN_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.arity: mov eax,NEBOC_DIAG_ARITY
 jmp .reject
.dtype: mov eax,NEBOC_DIAG_DTYPE
 jmp .reject
.bounds: mov eax,NEBOC_DIAG_BOUNDS
 jmp .reject
.join: mov eax,NEBOC_DIAG_JOIN
.reject:
 mov [rdi+NEBOC_COLUMN_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
