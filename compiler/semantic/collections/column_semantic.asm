; COLUMN-ROW-TABLE-E-DATASET-PF003 Column<Int>#4 semantic evaluator
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/column_contract.inc"
%include "compiler/semantic/collections/column_semantic.inc"
section .text
NEBOC_ABI_FUNCTION neboc_column_semantic_evaluate
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_COLUMN_SEM_DIAGNOSTIC_OFFSET],0
 mov rsi,[rdi+NEBOC_COLUMN_SEM_CELLS_OFFSET]
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_COLUMN_SEM_OPERATION_OFFSET]
 cmp rax,NEBOC_COLUMN_OP_INDEX
 je .index
 cmp rax,NEBOC_COLUMN_OP_LEN
 je .len
 cmp rax,NEBOC_COLUMN_OP_SUM
 je .sum
 cmp rax,NEBOC_COLUMN_OP_MIN
 je .min
 cmp rax,NEBOC_COLUMN_OP_MAX
 je .max
 cmp rax,NEBOC_COLUMN_OP_COUNT_MISSING
 je .zero
 jmp .invalid
.index:
 mov rax,[rdi+NEBOC_COLUMN_SEM_INDEX_OFFSET]
 cmp rax,3
 ja .bounds
 mov rax,[rsi+rax*8]
 jmp .ok
.len: mov eax,4
 jmp .ok
.sum:
 mov rax,[rsi]
 add rax,[rsi+8]
 jo .overflow
 add rax,[rsi+16]
 jo .overflow
 add rax,[rsi+24]
 jo .overflow
 jmp .ok
.min:
 mov rax,[rsi]
 cmp rax,[rsi+8]
 jle .min2
 mov rax,[rsi+8]
.min2: cmp rax,[rsi+16]
 jle .min3
 mov rax,[rsi+16]
.min3: cmp rax,[rsi+24]
 jle .ok
 mov rax,[rsi+24]
 jmp .ok
.max:
 mov rax,[rsi]
 cmp rax,[rsi+8]
 jge .max2
 mov rax,[rsi+8]
.max2: cmp rax,[rsi+16]
 jge .max3
 mov rax,[rsi+16]
.max3: cmp rax,[rsi+24]
 jge .ok
 mov rax,[rsi+24]
 jmp .ok
.zero: xor eax,eax
.ok:
 mov [rdi+NEBOC_COLUMN_SEM_OUTPUT_OFFSET],rax
 xor eax,eax
 ret
.bounds: mov eax,NEBOC_DIAG_BOUNDS
 jmp .reject
.overflow: mov eax,NEBOC_DIAG_OVERFLOW
.reject:
 mov [rdi+NEBOC_COLUMN_SEM_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
